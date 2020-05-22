display.setStatusBar( display.HiddenStatusBar )
-- if system.getInfo( "platform" ) ~= "html5" then
--     local disclaimer = display.newText({
--         text = "In order to run this project, you need to create an HTML5 build and deploy it.",
--         width = 800,
--         x = display.contentCenterX,
--         y = display.contentCenterY,
--         font = native.systemFontBold,
--         fontSize = 36,
--         align = "center",
--     })
-- else
    timer = nil -- Using "newTimer" temporarily until PR is committed to Solar2D core.
    timer = require( "newTimer" )
    local lfs = require( "lfs" )
    -- local _inputCode = require( "inputCode" )
    local printToDisplay = require( "printToDisplay" )
    printToDisplay.setStyle({
        y = 0,
        bgColor = {0,0,0,0.8},
        width = 300,
        height = 640,
        buttonSize = 40,
        fontSize = 18,
        paddingRow = 10,
    })
    
    local instructions
    local imageListGroup = display.newGroup()
    local btn, imageList = {}, {}
    local _tostring = tostring
    local _min = math.min
    local btnX = display.screenOriginX+4
    local controlsEnabled = true
    local consoleOpen = false
    local imagesOpen = false
    
    -- Persisting assets aren't cleared when the code is run.
    local persistingAsset = {}
    printToDisplay._keep = persistingAsset
    
    local function myUnhandledErrorListener( event )
        controlsEnabled = true
        print( event.errorMessage )
        return iHandledTheError
    end

    Runtime:addEventListener("unhandledError", myUnhandledErrorListener)
    
    -- Insert "physics state" to physics library calls.
    local physics = require("physics")
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
    local _globals = {}
    for i, j in pairs( _G ) do
        _globals[i] = true
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
        for name, entry in pairs( _G ) do
            if not _globals[name] then
                local t = type( entry )
                if t == "function" then
                    functions[#functions+1] = name
                else
                    if t == "table" then
                        if _G[name].removeSelf then
                            _G[name]:removeSelf()
                        end
                    end
                    _G[name] = nil
                end
            end
        end
        -- And finally remove all functions.
        for name = 1, #functions do
            _G[functions[name]] = nil
        end
        -- And remove any remaining display objects/groups.
        local stage = display.getCurrentStage()
        for i = stage.numChildren, 1, -1 do
            if not persistingAsset[_tostring(stage[i])] then
                stage[i]:removeSelf()
                stage[i] = nil
            end
        end
    end
    
    local function removeInstructions()
        if instructions then
            instructions:removeSelf()
            instructions = nil
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
            imageListGroup.isVisible = not imageListGroup.isVisible
            imageListGroup:toFront()
            imagesOpen = not imagesOpen
        end
        return true
    end
    
    local function _toggleConsole( event )
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
    
    local function _runCode( event )
        if controlsEnabled and event.phase == "began" then
            controlsEnabled = false
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
            
            if imagesOpen then showImages( {phase="began"}) end
            clearEverything()
            -- local code = _inputCode.getCode()
            
            local code = "--sample code by Michael Wilson\n-- Change the background to grey\ndisplay.setDefault( \"background\", 0.1 )\n\nlocal x, y = display.contentCenterX, display.contentCenterY -- source of flame\nlocal rnd = math.random\n\n-- Run every frame\nlocal function enterFrame()\n  local flame = display.newCircle(x,y, math.random(32,64))\n  flame:setFillColor(rnd() + 0.5, rnd() + 0.2, 0)\n  flame.blendMode = \"add\"\n  flame.alpha = 0.5\n\n  -- kill the particle when done\n  local function die()\n    display.remove(flame)\n  end\n\n  -- start a transition\n  transition.to(flame, {\n      delta = true, -- move from current location\n      time = 1000, -- in 1.0 seconds\n      x = rnd(-16,16), -- wiggle\n      y = rnd(-384, -256), -- go up\n      xScale = -0.9, -- shrink\n      yScale = -0.9,\n      onComplete = die, -- and die\n      })\nend\n\n-- Called when a mouse event has been received.\nlocal function mouse( event )\n  x, y = event.x or x, event.y or y -- take a new x,y or keep the old x,y\nend\n\n-- Add the mouse and enterFrame events\nRuntime:addEventListener( \"mouse\", mouse )\nRuntime:addEventListener( \"enterFrame\", enterFrame )"
            if code then -- No code will be returned if the app is run directly and not via an Iframe.
                assert(loadstring( code ))()
                -- Return the UI to the front
                local stage = display.getCurrentStage()
                for i = stage.numChildren, 1, -1 do
                    if persistingAsset[_tostring(stage[i])] then
                        stage[i]:toFront()
                    end
                end
            end
            -- Add a small delay to prevent possible issues from spamming _runCode()
            timer.performWithDelay( 50, function() controlsEnabled = true end )
        end
        return true
    end
    
    local function _scrollImages( event )
        if event.phase == "began" then
            
        elseif event.phase == "moved" then
            
        end
        return true
    end
    
    -- Traverse image folders (apart from the ui) and list them as usable images
    local container = display.newContainer( 780, 600 )
    persistingAsset[_tostring(imageListGroup)] = true
    persistingAsset[_tostring(container)] = true
    imageList[1] = display.newImageRect( imageListGroup, "ui/window.png", 800, 600 )
    imageList[1]:addEventListener( "touch", _scrollImages )
    imageList[1].x, imageList[1].y = 480, 320
    imageList[2] = display.newImageRect( imageListGroup, "ui/buttonsGreen.png", 48, 48 )
    imageList[2]:addEventListener( "touch", showImages )
    imageList[2].x, imageList[2].y = imageList[1].x+imageList[1].width*0.5-32, imageList[1].y-imageList[1].height*0.5+32
    imageList[3] = display.newText( imageListGroup, "Scroll to view all useable images (not yet scrollable)", 480, 52, nil, 28 )
    
    -- TODO: add container and scroll through events using this
    for i = 1, 3 do
        persistingAsset[_tostring(imageList[i])] = true
    end
    
    local imageColumn, imageRow = 0, 1
    local imageFolder = system.pathForFile( "img/", system.ResourceDirectory )
    for file in lfs.dir( imageFolder ) do
        if file ~= "." and file ~= ".." then
            local filename = "img/" .. file
            local x, y = 240+imageColumn*240, imageRow*200
            imageList[#imageList+1] = display.newImage( imageListGroup, filename, x, y )
            if imageList[#imageList].width > 180 or imageList[#imageList].height > 120 then
                local xScale = 160 / imageList[#imageList].width
                local yScale = 120 / imageList[#imageList].height
                local scale = _min( xScale, yScale )
                imageList[#imageList].xScale, imageList[#imageList].yScale = scale, scale
            end
            imageList[#imageList].anchorY = 1
            imageList[#imageList].name = display.newText( imageListGroup, "\"" .. filename .. "\"", x, y+12, nil, 16 )
            imageList[#imageList].name.anchorY = 0
            imageList[#imageList].size = display.newText( imageListGroup, "width: ".. imageList[#imageList].width .. ", height: " .. imageList[#imageList].height, x, y+40, nil, 16 )
            imageList[#imageList].size.anchorY = 0
            persistingAsset[_tostring(imageList[#imageList])] = true
            imageColumn = imageColumn+1
            if imageColumn == 3 then
                imageRow = imageRow+1
                imageColumn = 0
            end
        end
    end
    imageListGroup.isVisible = false
    
    local btnData = {
        {"ui/buttonRun.png", _runCode },
        {"ui/buttonImages.png", showImages },
        {"ui/buttonConsole.png", _toggleConsole }
    }
    for i = 1, 3 do
        btn[i] = display.newImageRect( btnData[i][1], 48, 48 )
        btn[i].anchorX, btn[i].anchorY = 0, 0
        btn[i].x, btn[i].y = btnX, (i == 1 and display.screenOriginY+4 or btn[i-1].y+btn[i].height+4)
        btn[i]:addEventListener( "touch", btnData[i][2] )
        persistingAsset[_tostring(btn[i])] = true
    end
    
    instructions = display.newImageRect( "ui/instructions.png", 428, 128 )
    instructions.anchorX, instructions.anchorY = 0, 0
    instructions.x = btn[1].x + btn[1].width + 4
    instructions.y = btn[1].y + 12
-- end