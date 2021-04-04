display.setStatusBar( display.HiddenStatusBar )
audio.setVolume( 0.5 )

require("disabledAPI")
local lfs = require( "lfs" )
local inputCode
local environment = system.getInfo( "environment" )
if environment ~= "simulator" then
    inputCode = require( "inputCode" )
end
local newDisplay = require( "newDisplay" )
local printToDisplay = require( "printToDisplay" )
local createWindow = require("createWindow")
local fontLoader = require( "spyricFontLoader" )
fontLoader.preload( "fnt" )

local button, imageList, logo = {}, {}
local buttonX = display.screenOriginX+4
local consoleOpen = false
local defaultFont = "fnt/OpenSansRegular.ttf"

-- Setting up all groups and the console.
local groupList = {
    ["Images"] = display.newGroup(),
    ["SFX"] = display.newGroup(),
    ["Fonts"] = display.newGroup()
}
-- groupGlobal contains all user generated display objects/groups.
local groupGlobal = display.newGroup()
local groupButtons = display.newGroup()
local container = display.newContainer( 780, 490 )
local tooltip = display.newGroup()
-- persistingGroups won't get removed during cleanup.
local persistingGroups = {
    groupGlobal = groupGlobal,
    groupButtons = groupButtons,
    container = container,
    tooltip = tooltip,
}
for i, v in pairs(groupList) do
    container:insert(v)
    v.scroll = { y=0, maxY=0 }
    v.isVisible = false
    v.window = display.newGroup()
    v.window.isVisible = false
    persistingGroups[i] = v
    persistingGroups[i] = v.window
end
createWindow.createTooltip( tooltip )
container:translate( 480, 360 )
newDisplay._group = groupGlobal
newDisplay:init()
printToDisplay.setStyle({
    parent = groupButtons,
    y = 0,
    bgColor = {0,0,0,0.8},
    width = 300,
    height = 640,
    buttonSize = 40,
    fontSize = 18,
    font = defaultFont,
    paddingRow = 10,
})

-- Add physics states to built-in physics calls for cleanup purposes.
physics = require("physics")
local _pState = "stop"
local _pStart = physics.start 
local _pPause = physics.pause 
local _pStop = physics.stop
function physics.start()
    _pState = "start"
    _pStart()
end
function physics.pause()
    _pState = "pause"
    _pPause()
end
function physics.stop()
    _pState = "stop"
    _pStop()
end

-- To prevent Runtime listeners from hanging around, we insert any newly created
-- Runtime listeners to a table so that we can automatically remove them later.
local _addEventListener = Runtime.addEventListener
local _removeEventListener = Runtime.removeEventListener
local _runtimeListeners = {}

function Runtime.addEventListener( ... )
    local t = {...}
    -- Check that the new Runtime element isn't a table, i.e. a timer or a transition. 
    if type( t[3] ) ~= "table" then
        _runtimeListeners[#_runtimeListeners+1] = { t[2], t[3] }
    end
    _addEventListener( ... )
end

function Runtime.removeEventListener( ... )
    local t = {...}
    for i = 1, #_runtimeListeners do
        if _runtimeListeners[i][1] == t[1] then
            table.remove( _runtimeListeners, i )
            break
        end
    end
    _removeEventListener( ... )
end

-- This sandbox project relies on loadstring(), so we'll need to keep a list of all original _G
-- table entries so that we don't accidentally remove them along with whatever the user creates.
-- Furthermore, all original global entries are checked and restored after every reset.
local _globals, _origGlobals = {}, {}
for index, value in pairs( _G ) do
    _origGlobals[index] = value
    _globals[index] = true
end

-- Clear all display objects, stop all timers, transitions and runtime event listeners, i.e. perform a complete reset.
local function clearEverything()
    if _pState ~= "stop" then
        physics.stop()
    end
    transition.cancelAll()
    timer.cancelAll()
    -- Start by removing Runtime listeners.
    for i = #_runtimeListeners, 1, -1 do
        Runtime:removeEventListener( _runtimeListeners[i][1], _runtimeListeners[i][2] )
    end
    -- Then remove all display objects and variables.
    local functions = {}
    for index, value in pairs( _G ) do
        if not _globals[index] then
            local t = type( value )
            if t == "function" then
                functions[#functions+1] = index
            else
                if t == "table" then
                    if _G[index].removeSelf then
                        _G[index]:removeSelf()
                    end
                end
                _G[index] = nil
            end
        end
    end
    -- Reset any possible changes to the global tables/libraries.
    for index, value in pairs( _origGlobals ) do
        -- "print" is already customised via printToDisplay plugin,
        -- so it will be reset via the plugin unlike other globals.
        if index == "print" then
            printToDisplay.resetPrint()
        elseif value ~= _G[index] then
            _G[index] = value
        end
    end
    -- Remove all functions.
    for name = 1, #functions do
        _G[functions[name]] = nil
    end
    -- And finally clear all non-UI display objects/groups.
    for i = groupGlobal.numChildren, 1, -1 do
        groupGlobal[i]:removeSelf()
        groupGlobal[i] = nil
    end
    local stage = display.getCurrentStage()
    for i = stage.numChildren, 1, -1 do
        local t = stage[i]
        -- Don't remove persistingGroups.
        local isPersistingGroup = false
        for _, v in pairs(persistingGroups) do
            if v == t then
                isPersistingGroup = true
                break
            end
        end
        if not isPersistingGroup then
            stage[i]:removeSelf()
            stage[i] = nil
        end
    end
end

local function removeInstructions()
    if logo then
        for i = 1, #button do
            button[i].text:removeSelf()
            button[i].text = nil
        end
        logo:removeSelf()
        logo = nil
    end
end

local function toggleAssets( event )
    if event.phase == "began" then
        -- Bring active window to front and hide all inactive windows.
        local id = event.target and event.target.id or "_noActiveWindow"
        local isVisible
        for i, v in pairs( groupList ) do
            if i == id then
                isVisible = not v.isVisible
                v.isVisible = isVisible
                v.window.isVisible = isVisible
                createWindow.windowOpen = isVisible
                createWindow.activeWindow = v
                v:toFront()
                v.window:toFront()
            else
                v.isVisible = false
                v.window.isVisible = false
            end
        end
        if not isVisible then
            createWindow.windowOpen = false
        end
        container:toFront()
        tooltip:toFront()

        removeInstructions()
        if consoleOpen then
            for i = 1, #button do
                button[i].x = buttonX
            end
            printToDisplay.stop()
            consoleOpen = false
        end
    end
    return true
end

local function toggleConsole( event )
    if event.phase == "began" then
        removeInstructions()
        if createWindow.windowOpen then toggleAssets( {phase="began"} ) end
        if consoleOpen then
            for i = 1, #button do
                button[i].x = buttonX
            end
            printToDisplay.stop()
        else
            printToDisplay.start()
            for i = 1, #button do
                button[i].x = button[i].x + 300
            end
            printToDisplay.controls.scroll.y = button[#button].y + 72
            printToDisplay.controls.clear.y = printToDisplay.controls.scroll.y + printToDisplay.controls.scroll.height+3
        end
        consoleOpen = not consoleOpen
    end
    return true
end

local function runCode( event )
    if event.phase == "began" then
        removeInstructions()
        -- Reset default display values.
        display.setDefault( "anchorX", 0.5 )
        display.setDefault( "anchorY", 0.5 )
        display.setDefault( "isAnchorClamped", true )
        display.setDefault( "background", 0, 0, 0 )
        display.setDefault( "fillColor", 1, 1, 1 )
        display.setDefault( "strokeColor", 1, 1, 1 )
        display.setDefault( "lineColor", 1, 1, 1 )
        display.setDefault( "isNativeTextBoxFontSizeScaled", true )
        display.setDefault( "isNativeTextFieldFontSizeScaled", true )
        display.setDefault( "magTextureFilter", "linear" )
        display.setDefault( "minTextureFilter", "linear" )
        display.setDefault( "textureWrapX", "clampToEdge" )
        display.setDefault( "textureWrapY", "clampToEdge" )
        audio.setVolume( 0.5 )

        if createWindow.windowOpen then toggleAssets( {phase="began"}) end
        clearEverything()
        local code = inputCode and inputCode.getCode()
        if code then -- No code will be returned if the app is run directly and not via an Iframe.
            ---------------------------------------------------------------------------------------------------------------------------------
            -- NB!  "pcall" and "xpcall" aren't used here by design. While we could avoid crashes caused due to errors in the initial code,
            --      we won't be able to obtain a useful stack trace by using the aforementioned functions. Instead, by letting the app crash,
            --      Solar2D will send a more descriptive stack trace to the browser (one that is of actual use to the user). This will also
            --      make the crashes behave similarly, which improves the predictability of the Playground's behaviour.
            loadstring(code)()
            ---------------------------------------------------------------------------------------------------------------------------------
        else
            print( "WARNING: In order to run this project, you need to build it for HTML5 and deploy it via Iframe." )
        end
    end
    return true
end

-- Listen for sample project button presses from the website.
local function projectListener()
    runCode({phase="began"})
end

-- Create the custom asset menu windows.
for windowName, windowGroup in pairs( groupList ) do
    createWindow.new( windowName, windowGroup, toggleAssets )
end

-- Create the fixed UI buttons.
local buttonData = {
    {"ui/buttonRun.png", "← Press here to run your code", runCode },
    {"ui/buttonImages.png", "← View a list of useable images",  toggleAssets },
    {"ui/buttonSFX.png", "← View a list of useable audio",  toggleAssets },
    {"ui/buttonFonts.png", "← View a list of useable fonts",  toggleAssets },
    {"ui/buttonConsole.png", "← Press here to show console",  toggleConsole }
}
for i = 1, #buttonData do
    button[i] = display.newImageRect( groupButtons, buttonData[i][1], 48, 48 )
    button[i].anchorX, button[i].anchorY = 0, 0
    button[i].x, button[i].y = buttonX, (i == 1 and display.screenOriginY+4 or button[i-1].y+button[i].height+4)
    button[i].id = buttonData[i][1]:sub(10,-5)
    button[i]:addEventListener( "touch", buttonData[i][3] )
    button[i].text = display.newText( groupButtons, buttonData[i][2], button[i].x + button[i].width + 8, button[i].y + (environment ~= "simulator" and 8 or 0), defaultFont, 28 )
    button[i].text.anchorX, button[i].text.anchorY = 0, 0
end

logo = display.newImageRect( groupButtons, "ui/logo.png", 640, 110 )
logo.x, logo.y = 480, 320

if environment ~= "simulator" then inputCode.addEventListener( projectListener ) end