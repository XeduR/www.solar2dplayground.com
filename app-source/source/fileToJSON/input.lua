-- Sample code by Eetu Rantanen

-- Change the background to grey.
display.setDefault( "background", 0.2 )
local instructions = display.newText( "Use wasd or arrows to move. Press space to jump", 480, 120, "fonts/OpenSansRegular.ttf", 32 )

-- Image fills that will be used for enterFrame animations for the knight.
local frameMove1 = { type = "image", filename = "img/walk1.png" }
local frameMove2 = { type = "image", filename = "img/walk2.png" }
local frameIdle = { type = "image", filename = "img/stand.png" }
local frameJump = { type = "image", filename = "img/jump.png" }

-- Declaring multiple similar variables on the same line to reduce repetition.
local movementDirection, state1, inAir = "right", true, false
-- The knight's start/previous x location, as well as movement speed, jump height and jump duration.
local prevX, moveSpeed, jumpHeight, jumpDuration = 480, 8, 80, 200
local knightGroup = display.newGroup() -- By adding the knight and his shadow to a group, we can handle both at the same time.

local shadow = display.newCircle( knightGroup, prevX, 396, 46 )
shadow:setFillColor(0,0.5) -- Give the shadow a 50% transparent black fill colour.
shadow.yScale = 0.5 -- Adjust the yScale to give the shadow the proper perspective.

local knight = display.newRect( knightGroup, prevX, 320, 156, 156 )
knight.fill = frameIdle

local action = {}
local framesBetweenChange, currentFrame = 4, 1
local function moveCharacter()
	local keyDown = false
	-- See if one of the selected action buttons is down and move the knight.
	if action["a"] or action["left"] then
		knightGroup:translate( -moveSpeed, 0 )
		keyDown = true
	end
	if action["d"] or action["right"] then
		knightGroup:translate( moveSpeed, 0 )
		keyDown = true
	end
	if action["w"] or action["up"] then
		knightGroup:translate( 0, -moveSpeed )
		keyDown = true
	end
	if action["s"] or action["down"] then
		knightGroup:translate( 0, moveSpeed )
		keyDown = true
	end
	if keyDown then -- Only animate if one of the keys is pressed.
		if movementDirection == "right" and knightGroup.x < prevX then
			movementDirection = "left"
			knight.xScale = -1
		elseif movementDirection == "left" and knightGroup.x > prevX then
			movementDirection = "right"
			knight.xScale = 1
		end
		currentFrame = currentFrame+1
		if currentFrame > framesBetweenChange then
			state1 = not state1 -- Changes true to false and vice versa.
			currentFrame = 1
		end
		if not inAir then
			if state1 then -- Change the shadow scale and knight.y to make the knight "wobble".
				knight.fill = frameMove2
				knight.y = shadow.y-76
				shadow.xScale, shadow.yScale = 1, 0.5
			else
				knight.fill = frameMove1
				knight.y = shadow.y-78
				shadow.xScale, shadow.yScale = 1.05, 0.45
			end
		end
		prevX = knightGroup.x
	elseif not inAir then -- If the knight isn't moving or in the air, then toggle idle frame.
		knight.fill = frameIdle
	end
end

local function onKeyEvent( event )
	if event.phase == "down" then
		action[event.keyName] = true
		if event.keyName == "space" and not inAir then
			inAir = true
			knight.fill = frameJump
			-- Use transitions to jump the knight up and down, as well as animate the shadow.
			transition.to( knight, { time=jumpDuration*0.5, y=knight.y-jumpHeight, onComplete=function()
				transition.to( knight, { time=jumpDuration*0.5, y=knight.y+jumpHeight, onComplete=function()
					inAir = false
					knight.fill = frameIdle
				end })
			end })
			transition.to( shadow, { time=jumpDuration*0.5, alpha=0.3, xScale=0.8, yScale=0.3, onComplete=function()
				transition.to( shadow, { time=jumpDuration*0.5, alpha=0.5, xScale=1, yScale=0.5 })
			end })
		end
	else
		action[event.keyName] = false
	end
end

Runtime:addEventListener( "enterFrame", moveCharacter )
Runtime:addEventListener( "key", onKeyEvent )