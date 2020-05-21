-- Change the background to grey
display.setDefault( "background", 0.1 )

local x, y = display.contentCenterX, display.contentCenterY -- source of flame
local rnd = math.random

-- Run every frame
local function enterFrame()
  local flame = display.newCircle(x,y, math.random(32,64))
  flame:setFillColor(rnd() + 0.5, rnd() + 0.2, 0)
  flame.blendMode = "add"
  flame.alpha = 0.5

  -- kill the particle when done
  local function die()
    display.remove(flame)
  end

  -- start a transition
  transition.to(flame, {
      delta = true, -- move from current location
      time = 1000, -- in 1.0 seconds
      x = rnd(-16,16), -- wiggle
      y = rnd(-384, -256), -- go up
      xScale = -0.9, -- shrink
      yScale = -0.9,
      onComplete = die, -- and die
      })
end

-- Called when a mouse event has been received.
local function mouse( event )
  x, y = event.x or x, event.y or y -- take a new x,y or keep the old x,y
end

-- Add the mouse and enterFrame events
Runtime:addEventListener( "mouse", mouse )
Runtime:addEventListener( "enterFrame", enterFrame )