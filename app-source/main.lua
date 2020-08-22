display.setStatusBar( display.HiddenStatusBar )
timer = nil -- Using "newTimer" temporarily until PR is committed to Solar2D core.
timer = require( "newTimer" )

require("disabledAPI")
local lfs = require( "lfs" )
local inputCode, printToBrowser, playgroundCrashed
local environment = system.getInfo( "environment" )
if environment ~= "simulator" then
    inputCode = require( "inputCode" )
    printToBrowser = require( "printToBrowser" )
    playgroundCrashed = require( "playgroundCrashed" )
end
local newDisplay = require( "newDisplay" )
local printToDisplay = require( "printToDisplay" )
local fontLoader = require( "spyricFontLoader" )
fontLoader.preload( "fonts" ) 

local instructions, logo
local btn, imageList = {}, {}
local _tostring = tostring
local _min = math.min
local btnX = display.screenOriginX+4
local consoleOpen = false
local imagesOpen = false
local font = "fonts/OpenSansRegular.ttf"

-- TODO: add more custom fonts, audio effects/bg music
-- TODO: investigate having the Playground shut down the project on error.
--          - This take a screenshot of the app, give it a red tint (or red borders), wipe everything
--            and then let the user resume. There is currently an issue if an error occurs inside event
--            listeners, like touch event in "Crate" as it can trigger hundreds of error messages.

-- groupGlobal contains all user generated display objects/groups
local groupGlobal = display.newGroup()
local groupButtons = display.newGroup()
local groupWindow = display.newGroup()
local groupList = display.newGroup()
local container = display.newContainer( 780, 500 )
container:insert(groupList)
container:translate( 480, 350 )
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
    font = "fonts/OpenSansRegular.ttf",
    paddingRow = 10,
})

-- Insert "physics state" to physics library calls.
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


local maxY, objectStart, eventStart = 2140
local function scrollImagesWindow( event )
    if event.phase == "began" then
        display.getCurrentStage():setFocus( event.target )
        event.target.isTouched = true
        objectStart, eventStart = groupList.y, event.y
    elseif event.phase == "moved" then
        if event.target.isTouched then
            local d = event.y - eventStart
            local toY = objectStart + d
            if toY <= 0 and toY >= -maxY then
                groupList.y = toY
            else
                objectStart = groupList.y
                eventStart = event.y
            end
            imageList[4].y = imageList[4].yStart - (groupList.y/maxY)*430
        end
    else
        display.getCurrentStage():setFocus( nil )
        event.target.isTouched = false
    end
    return true
end

local function scrollImagesHandle( event )
    if event.phase == "began" then
        display.getCurrentStage():setFocus( event.target )
        event.target.isTouched = true
        objectStart, eventStart = groupList.y, event.y
    elseif event.phase == "moved" then
        if event.target.isTouched then
            local d = event.y - eventStart
            local toY = objectStart + d
            if event.y <= 116 then
                eventStart = event.y
                event.target.y = 116
                groupList.y = 0
            elseif event.y >= 546 then
                eventStart = event.y
                event.target.y = 546
                groupList.y = -maxY
            else
                event.target.y = event.y
                groupList.y = -((event.y-116)/430)*maxY
            end
        end
    else
        display.getCurrentStage():setFocus( nil )
        event.target.isTouched = false
    end
    return true
end

local scrollRate = 30
-- Scroll direction seems to be reversed with browsers or for HTML5 builds.
if environment ~= "simulator" then
    scrollRate = -scrollRate
end
local function mouseScroll( event )
    if event.type == "scroll" then
        if imagesOpen then
            local dY
            if event.scrollY > 0 then
                dY = scrollRate
            else
                dY = -scrollRate
            end
            local toY = groupList.y - dY
            if dY < 0 and toY >= 0 then
                groupList.y = 0
            elseif dY > 0 and toY <= -maxY then
                groupList.y = -maxY
            else
                groupList.y = toY
            end
            imageList[4].y = imageList[4].yStart - (groupList.y/maxY)*430
        end
    end
end
Runtime:addEventListener( "mouse", mouseScroll )

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
    transition.pause()
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
        -- "print" will be may be altered due to printToDisplay plugin, so ignore it.
        if index ~= "print" and value ~= _G[index] then
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
        if t ~= groupGlobal and t ~= groupButtons and t ~= groupWindow and t ~= container then
            stage[i]:removeSelf()
            stage[i] = nil
        end
    end
end

local function removeInstructions()
    if instructions then
        instructions:removeSelf()
        instructions = nil
        logo:removeSelf()
        logo = nil
    end
end

local function showImages( event )
    if event.phase == "began" then
        removeInstructions()
        if consoleOpen then
            for i = 1, 3 do
                btn[i].x = btnX
            end
            printToDisplay.stop()
            consoleOpen = false
        end
        groupWindow.isVisible = not groupWindow.isVisible
        groupList.isVisible = not groupList.isVisible
        groupWindow:toFront()
        groupList:toFront()
        container:toFront()
        imagesOpen = not imagesOpen
    end
    return true
end

local function toggleConsole( event )
    if event.phase == "began" then
        removeInstructions()
        if imagesOpen then showImages( {phase="began"}) end
        if consoleOpen then
            for i = 1, 3 do
                btn[i].x = btnX
            end
            printToDisplay.stop()
        else
            printToDisplay.start()
            for i = 1, 3 do
                btn[i].x = btn[i].x + 300
            end
            printToDisplay.controls.scroll.y = btn[3].y + 72
            printToDisplay.controls.clear.y = printToDisplay.controls.scroll.y + printToDisplay.controls.scroll.height+3
        end
        consoleOpen = not consoleOpen
    end
    return true
end

local function errorListener()
    if playgroundCrashed then
        playgroundCrashed.reportCrash()
    end
    return true
end
Runtime:addEventListener( "unhandledError", errorListener )

local function runCode( event )
    if event.phase == "began" then
        removeInstructions()
        display.newRect(123,x)
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
        
        if imagesOpen then showImages( {phase="began"}) end
        clearEverything()
        local code = inputCode and inputCode.getCode()
        if code then -- No code will be returned if the app is run directly and not via an Iframe.
            local valid, errorMessage = pcall(loadstring(code))
            if not valid then
                local _, loc = string.find(errorMessage, '"]:%S')
                if loc then errorMessage = "Error on line " .. errorMessage:sub(loc) end
                printToBrowser.alert(errorMessage)
                print(errorMessage)
            end
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

imageList[1] = display.newRoundedRect( groupWindow, 480, 320, 800, 600, 8 )
imageList[1]:setFillColor(0,0.9)
imageList[1]:addEventListener( "touch", scrollImagesWindow )
imageList[2] = display.newImageRect( groupWindow, "ui/buttonsGreen.png", 48, 48 )
imageList[2]:addEventListener( "touch", showImages )
imageList[2].x, imageList[2].y = imageList[1].x+imageList[1].width*0.5-32, imageList[1].y-imageList[1].height*0.5+32
imageList[3] = display.newText( groupWindow, "Scroll to view all useable images", 480, 50, font, 28 )
imageList[4] = display.newRoundedRect( groupWindow, imageList[2].x, imageList[2].y+imageList[2].height+16, 16, 32, 16 )
imageList[4]:addEventListener( "touch", scrollImagesHandle )
imageList[4].yStart = imageList[4].y
imageList[4]:setFillColor(1,0.8)

-- Traverse image folder and list them as usable images
local imageColumn, imageRow, imageCount = 0, 1, 0
local imageFontSize = 18
local imageFolder = system.pathForFile( "img/", system.ResourceDirectory )
for file in lfs.dir( imageFolder ) do
    if file ~= "." and file ~= ".." then
        imageCount = imageCount+1
        local filename = "img/" .. file
        local x, y = -240+imageColumn*240, -350+imageRow*220
        imageList[#imageList+1] = display.newImage( groupList, filename, x, y )
        if imageList[#imageList].width > 180 or imageList[#imageList].height > 120 then
            local xScale = 160 / imageList[#imageList].width
            local yScale = 120 / imageList[#imageList].height
            local scale = _min( xScale, yScale )
            imageList[#imageList].xScale, imageList[#imageList].yScale = scale, scale
        end
        imageList[#imageList].anchorY = 1
        imageList[#imageList].name = display.newText( groupList, "\"" .. filename .. "\"", x, y+12, font, imageFontSize )
        imageList[#imageList].name.anchorY = 0
        imageList[#imageList].size = display.newText( groupList, "width: ".. imageList[#imageList].width .. ", height: " .. imageList[#imageList].height, x, y+40, font, imageFontSize )
        imageList[#imageList].size.anchorY = 0
        imageColumn = imageColumn+1
        if imageColumn == 3 then
            imageRow = imageRow+1
            imageColumn = 0
        end
    end
end
groupWindow.isVisible = false
groupList.isVisible = false
-- The first 6 images are always shown, even without scrolling. For
-- every additional starting line, increase the max scrolling area.
maxY = math.ceil((imageCount-6)/3)*216

local btnData = {
    {"ui/buttonRun.png", runCode },
    {"ui/buttonImages.png", showImages },
    {"ui/buttonConsole.png", toggleConsole }
}
for i = 1, 3 do
    btn[i] = display.newImageRect( groupButtons, btnData[i][1], 48, 48 )
    btn[i].anchorX, btn[i].anchorY = 0, 0
    btn[i].x, btn[i].y = btnX, (i == 1 and display.screenOriginY+4 or btn[i-1].y+btn[i].height+4)
    btn[i]:addEventListener( "touch", btnData[i][2] )
end

instructions = display.newImageRect( groupButtons, "ui/instructions.png", 428, 128 )
instructions.anchorX, instructions.anchorY = 0, 0
instructions.x = btn[1].x + btn[1].width + 4
instructions.y = btn[1].y + 12

logo = display.newImageRect( groupButtons, "ui/logo.png", 640, 110 )
logo.x, logo.y = 480, 320

if environment ~= "simulator" then inputCode.addEventListener( projectListener ) end