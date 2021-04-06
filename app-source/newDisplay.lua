local M = {}

local _type = type

local _activeListeners = {}

local _newGroup = display.newGroup
local _newContainer = display.newContainer
local _newSnapshot = display.newSnapshot
local _newText = display.newText
local _newEmbossedText = display.newEmbossedText
local _newRect = display.newRect
local _newRoundedRect = display.newRoundedRect
local _newCircle = display.newCircle
local _newLine = display.newLine
local _newPolygon = display.newPolygon
local _newSprite = display.newSprite
local _newImage = display.newImage
local _newImageRect = display.newImageRect
local _newMesh = display.newMesh
local _capture = display.capture
local _captureBounds = display.captureBounds
local _captureScreen = display.captureScreen

local function _notGroup(t)
    return not (_type(t) == "table" and t[1]._proxy)
end

local function _insert(parent, t)
    if _notGroup(parent) then
        M._group:insert(t)
    end
end

-- Store a list of all event listeners for all display objects for removal.
local function _captureListener(t)
    local addListener = t.addEventListener
    t.addEventListener = function(...)
        local args = {...}
        _activeListeners[#_activeListeners+1] = { parent = args[1], type = args[2], listener = args[3] }
        addListener(...)
    end
end

function M.removeActiveListeners()
    for i = 1, #_activeListeners do
        local t = _activeListeners[i]
        t.parent:removeEventListener( t.type, t.listener )
        _activeListeners[i] = nil
    end
end

-- Change all default display functions that create display objects or groups to insert
-- said display objects/groups to a default group to prevent them from overlapping the UI.
function M.init()
    
    function display.newGroup()
        local object = _newGroup()
        M._group:insert(object)
        _captureListener( object )
        return object
    end
    
    function display.newText(...)
        local t = {...}
        local object = _newText(...)
        -- Support for both, modern and legacy syntax.
        if #t == 1 and not t[1].parent or #t > 1 and _notGroup(t[1]) then
            M._group:insert(object)
        end
        _captureListener( object )
        return object
    end
        
    function display.newEmbossedText(...)
        local t = {...}
        local object = _newEmbossedText(...)
        if #t == 1 and not t[1].parent or #t > 1 and _notGroup(t[1]) then
            M._group:insert(object)
        end
        _captureListener( object )
        return object
    end

    function display.newContainer(...)
        local t = {...}
        local object = _newContainer(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newSnapshot(...)
        local t = {...}
        local object = _newSnapshot(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newRect(...)
        local t = {...}
        local object = _newRect(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newRoundedRect(...)
        local t = {...}
        local object = _newRoundedRect(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newCircle(...)
        local t = {...}
        local object = _newCircle(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newLine(...)
        local t = {...}
        local object = _newLine(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newPolygon(...)
        local t = {...}
        local object = _newPolygon(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newSprite(...)
        local t = {...}
        local object = _newSprite(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newImage(...)
        local t = {...}
        local object = _newImage(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newImageRect(...)
        local t = {...}
        local object = _newImageRect(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.newMesh(...)
        local t = {...}
        local object = _newMesh(...)
        _insert( t[1], object )
        _captureListener( object )
        return object
    end

    function display.capture(...)
        local t = {...}
        if #t > 1 then
            local typeParam = _type(t[2])
            if typeParam == "boolean" then
                t[2] = false
            elseif typeParam == "table" then
                t[2].saveToPhotoLibrary = false
            end 
        end
        local object = _capture(...)
        M._group:insert(object)
        _captureListener( object )
        return object
    end
    
    function display.captureBounds(...)
        local t = {...}
        t[2] = false
        local object = _captureBounds(...)
        M._group:insert(object)
        _captureListener( object )
        return object
    end
    
    function display.captureScreen()
        local object = _captureScreen(false)
        M._group:insert(object)
        _captureListener( object )
        return object
    end
    
end

return M