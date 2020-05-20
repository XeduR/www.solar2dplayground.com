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
    
    -- TODO: add updated timer framework and overwrite the default until the default timer is updated to the new one.
    -- TODO: add the UI elements to a group that is in front of everything.
    -- TODO: see about introducing pcall for loadstring events.
    -- TODO: add custom runtimer error handler.
    -- TODO: add the image selection window.
    
    local _btn = {}
    local _tostring = tostring
    local _btnX = display.screenOriginX+4
    local _consoleOpen = false
    local _imagesOpen = false
    local _started = true
    
    -- Persisting assets aren't cleared when the code is run.
    local _persistingAsset = {}
    _printToDisplay._keep = _persistingAsset
    
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
        -- timer.cancelAll() -- TODO: uncomment after my timer framework update has been added to Solar2D core.
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
    
    local function _toggleConsole( event )
        if _started and event.phase == "began" then
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
                _printToDisplay.controls.scroll.y = _btn[3].y + 70
                _printToDisplay.controls.scrollSymbol.y = _printToDisplay.controls.scroll.y
                _printToDisplay.controls.clear.y = _printToDisplay.controls.scroll.y + _printToDisplay.controls.scroll.height + 10
                _printToDisplay.controls.clearSymbol.y = _printToDisplay.controls.clear.y
            end
            _consoleOpen = not _consoleOpen
        end
        return true
    end
    
    local function _showImages( event )
        if _started and event.phase == "began" then
            print( "This doesn't work yet." )
            _imagesOpen = not _imagesOpen
        end
        return true
    end
    
    local function _runCode( event )
        if event.phase == "began" then
            _started = true
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
            
            -- if _imagesOpen then _showImages( {phase="began"}) end
            _clearEverything()            
            local code = _inputCode.getCode()
            -- No code will be returned if the app is run directly and not via an Iframe.
            if code then
                assert(loadstring( code ))()
                for i = 1, 3 do
                    _btn[i]:toFront() 
                end           
            end
        end
        return true
    end
    
    local _btnData = {
        {"images/buttonRun.png", _runCode },
        {"images/buttonConsole.png", _toggleConsole },
        {"images/buttonImages.png", _showImages }
    }
    for i = 1, 3 do
        _btn[i] = display.newImageRect( _btnData[i][1], 48, 48 )
        _btn[i].anchorX, _btn[i].anchorY = 0, 0
        _btn[i].x, _btn[i].y = _btnX, (i == 1 and display.screenOriginY+4 or _btn[i-1].y+_btn[i].height+4)
        _btn[i]:addEventListener( "touch", _btnData[i][2] )
        _persistingAsset[_tostring(_btn[i])] = true
    end
    
    local _instructions = display.newImageRect( "images/instructions.png", 428, 128 )
    _instructions.anchorX, _instructions.anchorY = 0, 0
    _instructions.x = _btn[1].x + _btn[1].width + 4
    _instructions.y = _btn[1].y + 12
end