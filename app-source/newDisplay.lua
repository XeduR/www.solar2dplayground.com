local M = {}

local _type = type

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

local function _notGroup(t)
    return not (_type(t) == "table" and t[1]._proxy)
end

-- Change all default display functions that create display objects or groups to insert
-- said display objects/groups to a default group to prevent them from overlapping the UI.
function M.init()
    
    function display.newGroup()
        local object = _newGroup()
        M._group :insert(object)
        return object
    end
        
    function display.newText(...)
        local t = {...}
        local object = _newText(...)
        -- Support for both, modern and legacy syntax.
        if #t == 1 and not t.parent or #t > 1 and _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end
        
    function display.newEmbossedText(...)
        local t = {...}
        local object = _newEmbossedText(...)
        if #t == 1 and not t.parent or #t > 1 and _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newContainer(...)
        local t = {...}
        local object = _newContainer(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newSnapshot(...)
        local t = {...}
        local object = _newSnapshot(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newRect(...)
        local t = {...}
        local object = _newRect(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newRoundedRect(...)
        local t = {...}
        local object = _newRoundedRect(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newCircle(...)
        local t = {...}
        local object = _newCircle(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newLine(...)
        local t = {...}
        local object = _newLine(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newPolygon(...)
        local t = {...}
        local object = _newPolygon(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newSprite(...)
        local t = {...}
        local object = _newSprite(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newImage(...)
        local t = {...}
        local object = _newImage(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newImageRect(...)
        local t = {...}
        local object = _newImageRect(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end

    function display.newMesh(...)
        local t = {...}
        local object = _newMesh(...)
        if _notGroup(t[1]) then
            M._group :insert(object)
        end
        return object
    end
    
end

return M