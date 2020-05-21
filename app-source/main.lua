display.setStatusBar( display.HiddenStatusBar )
if system.getInfo( "platform" ) ~= "html5" then
    local disclaimer = display.newText({
        text = "In order to run this project, you need to create an HTML5 build and deploy it.",
        width = 800,
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = native.systemFontBold,
        fontSize = 36,
        align = "center",
    })
else
    -- Using "newTimer" temporarily until PR is committed to Solar2D core.
    timer = nil
    timer = require( "newTimer" )
    local _lfs = require( "lfs" )
    local _inputCode = require( "inputCode" )
    local _printToDisplay = require( "printToDisplay" )
    _printToDisplay.setStyle({
        y = 0,
        bgColor = {0,0,0,0.8},
        width = 300,
        height = 640,
        buttonSize = 40,
        fontSize = 18,
        paddingRow = 10,
    })
    
    local _instructions
    local _imageListGroup = display.newGroup()
    local _btn, _imageList = {}, {}
    local _tostring = tostring
    local _min = math.min
    local _btnX = display.screenOriginX+4
    local _controlsEnabled = true
    local _consoleOpen = false
    local _imagesOpen = false
    
    -- Persisting assets aren't cleared when the code is run.
    local _persistingAsset = {}
    _printToDisplay._keep = _persistingAsset
    
    local function myUnhandledErrorListener( event )
        _controlsEnabled = true
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
        _runtimeListeners[#_runtimeListeners+1] = { t[2], t[3] }
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
    local function _clearEverything()
        if _pState ~= "stop" then
            physics.stop()
        end
        transition.cancel()
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
            if not _persistingAsset[_tostring(stage[i])] then
                stage[i]:removeSelf()
                stage[i] = nil
            end
        end
    end
    
    local function _removeInstructions()
        if _instructions then
            _instructions:removeSelf()
            _instructions = nil
        end
    end
    
    local function _showImages( event )
        if event.phase == "began" then
            _removeInstructions()
            if _consoleOpen then
                for i = 1, 3 do
                    _btn[i].x = _btnX
                end
                _printToDisplay.stop()
                _consoleOpen = false
            end
            _imageListGroup.isVisible = not _imageListGroup.isVisible
            _imageListGroup:toFront()
            _imagesOpen = not _imagesOpen
        end
        return true
    end
    
    local function _toggleConsole( event )
        if event.phase == "began" then
            _removeInstructions()
            if _imagesOpen then _showImages( {phase="began"}) end
            if _consoleOpen then
                for i = 1, 3 do
                    _btn[i].x = _btnX
                end
                _printToDisplay.stop()
            else
                _printToDisplay.start()
                for i = 1, 3 do
                    _btn[i].x = _btn[i].x + 300
                end
                _printToDisplay.controls.scroll.y = _btn[3].y + 72
                _printToDisplay.controls.clear.y = _printToDisplay.controls.scroll.y + _printToDisplay.controls.scroll.height+3
            end
            _consoleOpen = not _consoleOpen
        end
        return true
    end
    
    local function _runCode( event )
        if _controlsEnabled and event.phase == "began" then
            _controlsEnabled = false
            _removeInstructions()
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
            
            if _imagesOpen then _showImages( {phase="began"}) end
            _clearEverything()            
            local code = _inputCode.getCode()
            if code then -- No code will be returned if the app is run directly and not via an Iframe.
                assert(loadstring( code ))()
                -- Return the UI to the front
                local stage = display.getCurrentStage()
                for i = stage.numChildren, 1, -1 do
                    if _persistingAsset[_tostring(stage[i])] then
                        stage[i]:toFront()
                    end
                end
            end
            -- Add a small delay to prevent possible issues from spamming _runCode()
            timer.performWithDelay( 50, function() _controlsEnabled = true end )
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
    local _container = display.newContainer( 780, 600 )
    _persistingAsset[_tostring(_imageListGroup)] = true
    _persistingAsset[_tostring(_container)] = true
    _imageList[1] = display.newImageRect( _imageListGroup, "ui/window.png", 800, 600 )
    _imageList[1]:addEventListener( "touch", _scrollImages )
    _imageList[1].x, _imageList[1].y = 480, 320
    _imageList[2] = display.newImageRect( _imageListGroup, "ui/buttonsGreen.png", 48, 48 )
    _imageList[2]:addEventListener( "touch", _showImages )
    _imageList[2].x, _imageList[2].y = _imageList[1].x+_imageList[1].width*0.5-32, _imageList[1].y-_imageList[1].height*0.5+32
    _imageList[3] = display.newText( _imageListGroup, "Scroll to view all useable images (not yet scrollable)", 480, 52, nil, 28 )
    
    -- TODO: add container and scroll through events using this
    for i = 1, 3 do
        _persistingAsset[_tostring(_imageList[i])] = true
    end
    
    local _column, _row = 0, 1
    local _imageFolder = system.pathForFile( "img/", system.ResourceDirectory )
    for file in lfs.dir( _imageFolder ) do
        if file ~= "." and file ~= ".." then
            local filename = "img/" .. file
            local x, y = 240+_column*240, _row*200
            _imageList[#_imageList+1] = display.newImage( _imageListGroup, filename, x, y )
            if _imageList[#_imageList].width > 180 or _imageList[#_imageList].height > 120 then
                local xScale = 160 / _imageList[#_imageList].width
                local yScale = 120 / _imageList[#_imageList].height
                local scale = _min( xScale, yScale )
                _imageList[#_imageList].xScale, _imageList[#_imageList].yScale = scale, scale
            end
            _imageList[#_imageList].anchorY = 1
            _imageList[#_imageList].name = display.newText( _imageListGroup, "\"" .. filename .. "\"", x, y+12, nil, 16 )
            _imageList[#_imageList].name.anchorY = 0
            _imageList[#_imageList].size = display.newText( _imageListGroup, "width: ".. _imageList[#_imageList].width .. ", height: " .. _imageList[#_imageList].height, x, y+40, nil, 16 )
            _imageList[#_imageList].size.anchorY = 0
            _persistingAsset[_tostring(_imageList[#_imageList])] = true
            _column = _column+1
            if _column == 3 then
                _row = _row+1
                _column = 0
            end
        end
    end
    _imageListGroup.isVisible = false
    
    local _btnData = {
        {"ui/buttonRun.png", _runCode },
        {"ui/buttonImages.png", _showImages },
        {"ui/buttonConsole.png", _toggleConsole }
    }
    for i = 1, 3 do
        _btn[i] = display.newImageRect( _btnData[i][1], 48, 48 )
        _btn[i].anchorX, _btn[i].anchorY = 0, 0
        _btn[i].x, _btn[i].y = _btnX, (i == 1 and display.screenOriginY+4 or _btn[i-1].y+_btn[i].height+4)
        _btn[i]:addEventListener( "touch", _btnData[i][2] )
        _persistingAsset[_tostring(_btn[i])] = true
    end
    
    _instructions = display.newImageRect( "ui/instructions.png", 428, 128 )
    _instructions.anchorX, _instructions.anchorY = 0, 0
    _instructions.x = _btn[1].x + _btn[1].width + 4
    _instructions.y = _btn[1].y + 12
end