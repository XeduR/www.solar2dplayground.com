-- Sample code by Michael Wilson

-- Change the background to grey.
display.setDefault( "background", 0.1 )

local x, y = display.contentCenterX, display.contentCenterY -- Source of flame.
local rnd = math.random

-- Run every frame.
local function enterFrame()
    local flame = display.newCircle(x,y, math.random(32,64))
    flame:setFillColor(rnd() + 0.5, rnd() + 0.2, 0)
    flame.blendMode = "add"
    flame.alpha = 0.5

    -- Kill the particle when done.
    local function die()
        display.remove(flame)
    end

    -- Start a transition.
    transition.to(flame, {
        delta = true, -- Move from current location.
        time = 1000, -- In 1.0 seconds.
        x = rnd(-16,16), -- Wiggle.
        y = rnd(-384, -256), -- Go up.
        xScale = -0.9, -- Shrink.
        yScale = -0.9,
        onComplete = die, -- And die.
    })
end

-- Called when a mouse event has been received.
local function mouse( event )
    x, y = event.x or x, event.y or y -- Take a new x,y or keep the old x,y.
end

-- Add the mouse and enterFrame events.
Runtime:addEventListener( "mouse", mouse )
Runtime:addEventListener( "enterFrame", enterFrame )