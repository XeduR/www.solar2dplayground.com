---------------------------------------------------------------------------
--     _____                  _         ______                           --
--    / ___/____  __  _______(_)____   / ____/___ _____ ___  ___  _____  --
--    \__ \/ __ \/ / / / ___/ / ___/  / / __/ __ `/ __ `__ \/ _ \/ ___/  --
--   ___/ / /_/ / /_/ / /  / / /__   / /_/ / /_/ / / / / / /  __(__  )   --
--  /____/ .___/\__, /_/  /_/\___/   \____/\__,_/_/ /_/ /_/\___/____/    --
--      /_/    /____/                                                    --
--                                                                       --
--  © 2020-2021 Spyric Games Ltd.        Last Updated: 29 December 2021  --
---------------------------------------------------------------------------
--  License: MIT                                                         --
---------------------------------------------------------------------------

-- Spyric Print To Display is a simple to use Solar2D plugin for displaying
-- print() outputs on an in-app console as well as in the simulator console.
-- This makes debugging on devices easier as no external tools are needed.

--==============================================================================
-- Important! Important! Important! Important! Important! Important! Important!
--==============================================================================
-- If you want to make changes to this module and you need to use debug prints,
-- then make sure to use _print() inside of these functions because using the
-- regular print() inside the wrong function will result in an infinite loop.
--==============================================================================

-- NB!  Solar2D Playground uses a special, customised version of the Spyric Print to Display plugin.
--      If you wish to use Spyric Print to Display in your own projects, then you should download its
--      standard version, which has no dependencies, from Spyric Games's public plugins repository at:
--      https://github.com/SpyricGames/Solar2D-Plugins-Public/tree/main/Print-To-Display

local printToDisplay = {}
printToDisplay.autoscroll = true

local printToBrowser = system.getInfo( "environment" ) ~= "simulator" and require( "printToBrowser" )

-- Localised functions.
local _print = print
local concat = table.concat
local match = string.match
local find = string.find
local gsub = string.gsub
local sub = string.sub
local len = string.len
local tostring = tostring
local type = type

-- Localised console variables.
local blockTouch = true
local canScroll = false
local printList = {}
local scrollThreshold = 0
local currentY = 0
local textX = 0
local textWidth = 0
local paddingRow = 0
local fontSize = 0
local textColor
local textColorError
local textColorWarning
local font
local useHighlighting
local activeWhenHidden

-- Console display objects.
local container = nil
local background = nil
local output = nil
local buttonGroup = nil

----------------------------------------------
-- Default visual parameters:
----------------------------------------------
-- NB! These should be edited only via passing
-- a table as an argument to start() function.
----------------------------------------------
local style = {
    -- Console (general):
    x = display.screenOriginX,
    y = display.screenOriginY,
    width = display.actualContentWidth/3,
    height = display.actualContentHeight,
    alpha = 0.9,
    bgColor = { 0 },
    anchorX = 0,
    anchorY = 0,
    -- Console (text):
    font = native.systemFont,
    fontSize = 14,
    textColor = { 0.9 },
    textColorError = { 0.9, 0, 0 },
    textColorWarning = { 0.9, 0.75, 0 },
    paddingRow = 4,
    paddingLeft = 10,
    paddingRight = 10,
    paddingTop = 10,
    paddingBottom = 10,
    -- Console (functional):
    useHighlighting = true,
    activeWhenHidden = true,
    blockTouch = true,
    -- Buttons:
    buttonPos = "right",
    buttonSize = 32,
    buttonRounding = 4,
    buttonPadding = 10,
    buttonBaseColor = { 0.2 },
    buttonIconColor = { 0.8 },
}
----------------------------------------------

-- Scroll the text in the console.
local maxY, objectStart, eventStart = 0
local function scroll( event )
    if event.phase == "began" then
        display.getCurrentStage():setFocus( event.target )
        event.target.isTouched = true
        objectStart, eventStart = output.y, event.y
    elseif event.phase == "moved" then
        if event.target.isTouched then
            local d = event.y - eventStart
            local toY = objectStart + d
            if toY <= 0 and toY >= -maxY then
                printToDisplay.autoscroll = false
                printToDisplay.controls.scroll.fill = printToDisplay.controls.scroll.resume
                output.y = toY
            else
                objectStart = output.y
                eventStart = event.y
                if toY <= 0 then
                    printToDisplay.autoscroll = true
                    printToDisplay.controls.scroll.fill = printToDisplay.controls.scroll.pause
                end
            end
        end
    else
        display.getCurrentStage():setFocus( nil )
        event.target.isTouched = false
    end
    return blockTouch
end

-- Output a print to the in-app console.
local function outputToConsole( ... )
    for i = 1, arg.n do
        printList[i] = tostring( arg[i] )
    end

    -- Break the console outputs to separate lines to prevent running out of texture memory.
    local tempString, paragraph, finalParagraph = gsub( concat( printList, "    " ), "\t", "    " ), "", ""
    local singleParagraph = not find( tempString, "([^\n]*)\n(.*)" )
    repeat
        -- If there is only a single paragraph, then there will be no looping.
        if singleParagraph then
            paragraph, tempString = tempString or "", nil
        else
            paragraph, tempString = match( tempString, "([^\n]*)\n(.*)" )
            -- During the final loop, there's a chance that match will not return a paragraph
            -- even though there would be one more to go. For these cases, we'll store the last
            -- tempString and use it as the finalParagraph if one can't be found via match.
            if tempString then
                finalParagraph = tempString
            end
            if not paragraph then
                paragraph = finalParagraph
            end
        end

        if paragraph then
            local log = display.newText({
                parent = output,
                text = paragraph,
                x = textX,
                y = currentY,
                width = textWidth,
                align = "left",
                height = 0,
                font = font,
                fontSize = fontSize
            })

            log.anchorX, log.anchorY = 0, 0
            currentY = log.y + log.height + paddingRow

            if useHighlighting then
                if find( log.text, "ERROR:" ) == 1 then
                    log.fill = textColorError
                elseif find( log.text, "WARNING:" ) == 1 then
                    log.fill = textColorWarning
                else
                    log.fill = textColor
                end
            else
                log.fill = textColor
            end

            local newY = log.y + log.height
            if not canScroll and newY >= scrollThreshold then
                background:addEventListener( "touch", scroll )
                canScroll = true
            end

            if canScroll then
                maxY = newY - scrollThreshold
                if printToDisplay.autoscroll then
                    output.y = -maxY
                end
            end
        end

    until tempString == nil or len( tempString ) == 0

    -- Reduce, reuse and recycle.
    for i = 1, arg.n do
        printList[i] = nil
    end
end

-- Button event listener.
local function controls( event )
    if event.phase == "began" then
        -- Toggle auto scroll on or off.
        if event.target.id == "autoscroll" then
            printToDisplay.autoscroll = not printToDisplay.autoscroll
            printToDisplay.buttonScroll.fill = printToDisplay.autoscroll and printToDisplay.buttonScroll.resume or printToDisplay.buttonScroll.pause
            if printToDisplay.autoscroll then output.y = -maxY end

        -- Clear all text.
        elseif event.target.id == "clear" then
            background:removeEventListener( "touch", scroll )
            printToDisplay.buttonScroll.fill = printToDisplay.buttonScroll.resume
            canScroll = false
            printToDisplay.autoscroll = true

            display.remove( output )
            output = display.newGroup()
            container:insert( output, true )
            currentY = style.paddingTop-style.height*0.5
            output.y = 0

        end
    end
    return true
end

-- Modify the original print function to also print to browser and display consoles (if available).
-- print() is set inside resetPrint() so that it can be restored if the user accidentally messes with it.
function printToDisplay.resetPrint()
    function print( ... )
        if container then outputToConsole( ... ) end
        if printToBrowser then printToBrowser.log( ... ) end
        _print( ... )
    end
end

-- Create the in-app console and start sending print() to the in-app console as well.
function printToDisplay.start(...)
    if container then
        print( "\nSpyric Print to Display: console has already started.\n" )
    else
        local t = {...}
        local startVisible = type(t[1]) ~= "boolean" or t[1]
        local customStyle = type(t[#t]) == "table" and t[#t] or {}

        -- Update style with user input.
        for i, v in pairs( customStyle ) do
            style[i] = v
        end

        -- Localise style properties.
        local x = style.x
        local y = style.y
        local width = style.width
        local height = style.height
        local anchorX = style.anchorX
        local anchorY = style.anchorY
        local alpha = style.alpha
        local buttonSize = style.buttonSize
        local buttonRounding = style.buttonRounding
        local buttonPadding = style.buttonPadding
        local buttonBaseColor = style.buttonBaseColor
        local buttonIconColor = style.buttonIconColor
        local paddingTop = style.paddingTop
        local paddingBottom = style.paddingBottom
        local paddingLeft = style.paddingLeft
        local paddingRight = style.paddingRight

        -- Assign initial console properties (localised for speed).
        scrollThreshold = (height-(paddingTop+paddingBottom))*0.5
        currentY = paddingTop-height*0.5
        textWidth = width - (paddingLeft + paddingRight)
        paddingRow = style.paddingRow
        textX = paddingLeft-width*0.5
        textColor = style.textColor
        textColorError = style.textColorError
        textColorWarning = style.textColorWarning
        fontSize = style.fontSize
        font = style.font
        useHighlighting = style.useHighlighting
        activeWhenHidden = style.activeWhenHidden
        blockTouch = style.blockTouch
        printToDisplay.autoscroll = true
        canScroll = false

        -- Create the console's container.
        container = display.newContainer( width, height )
        container.anchorX, container.anchorY = anchorX, anchorY
        container.x, container.y = x, y
        container.alpha = alpha
        
        -- Add a reference for the Playground.
        printToDisplay.ui = container

        -- Create the console's background.
        background = display.newRect( container, 0, 0, width, height )
        background.fill = style.bgColor

        -- Create the console output group.
        output = display.newGroup()
        container:insert( output, true )

        -- Calculate the position of the buttons based on the style anchors and button positioning.
        local buttonY, buttonX = y-anchorY*height+buttonSize*0.5, 0
        if style.buttonPos == "left" then
            buttonX = x-anchorX*width-buttonSize*0.5
        else
            buttonX = x+(1-anchorX)*width+buttonSize*0.5
        end

        -- Add all other buttons inside a single group to easily control them.
        buttonGroup = display.newGroup()

        -- Auto scroll button:
        ----------------------------
        buttonScroll = display.newGroup()
        buttonGroup:insert( buttonScroll )

        local buttonScroll = display.newRect( buttonGroup, 0, 0, buttonSize, buttonSize )
        buttonScroll.x, buttonScroll.y = buttonX, buttonY
        buttonScroll.pause = {
            type = "image",
            filename = "ui/buttonPause.png"
        }
        buttonScroll.resume = {
            type = "image",
            filename = "ui/buttonResume.png"
        }
        buttonScroll.alpha = alpha
        buttonScroll:addEventListener( "touch", controls )
        buttonScroll.id = "autoscroll"
        buttonScroll.fill = buttonScroll.resume
        
        -- Add a reference for the Playground.
        printToDisplay.buttonScroll = buttonScroll

        -- Clear button:
        ----------------------------
        local buttonClear = display.newImageRect( buttonGroup, "ui/buttonClear.png", buttonSize, buttonSize )
        buttonClear.x, buttonClear.y = buttonX, buttonScroll.y + buttonScroll.height + buttonPadding
        buttonClear.alpha = alpha
        buttonClear:addEventListener( "touch", controls )
        buttonClear.id = "clear"
        
        -- Add a reference for the Playground.
        printToDisplay.buttonClear = buttonClear

        ----------------------------

        local parent = customStyle.parent
        if parent then
            parent:insert( container )
            parent:insert( buttonGroup )
        end

        outputToConsole( "SOLAR2D PLAYGROUND v" .. system.getInfo( "build" ) )
        outputToConsole( "print() will output text here and in your browser console (F12).\n " )
        
        buttonGroup.isVisible = false
        container.isVisible = false
        output.isVisible = false
    end
end

function printToDisplay.show()
    buttonGroup.isVisible = true
    container.isVisible = true
    output.isVisible = true
end

function printToDisplay.hide()
    buttonGroup.isVisible = false
    container.isVisible = false
    output.isVisible = false
end

printToDisplay.resetPrint()

return printToDisplay
