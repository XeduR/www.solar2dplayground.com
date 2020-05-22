local M = {}

-- NB! This is entirely WIP.
-- The idea is that perhaps all display objects would be forced to a group,
-- so that newly created objects don't simply pop in front of the UI elements.

local _newGroup = display.newGroup
local _newText = display.newText
local _newEmbossedText = display.newEmbossedText
local _newRect = display.newRect
local _newRoundedRect = display.newRoundedRect
local _newImageRect = display.newImageRect
local _newCircle = display.newCircle
local _newContainer = display.newContainer
local _newImage = display.newImage
local _newLine = display.newLine
local _newMesh = display.newMesh
local _newPolygon = display.newPolygon
local _newSnapshot = display.newSnapshot
local _newSprite = display.newSprite
local _newMesh = display.newMesh

local _group
-- functions where [group] isn't optional first
-- ::: newGroup, newText, _newEmbossedText

function M.initGroup( group )
    _group = group
    
    function display.newGroup()
        local t = _newGroup()
        if t then _group:insert(t) end
        return t
    end
        
    -- function display.newRect(...)
    --     local t = _newRect(...)
    --     -- if t then group:insert(t) end
    --     return t
    -- end
    
end

return M