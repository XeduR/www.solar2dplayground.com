-- Sample code by Jonathan Sharp.

-- Require and start the physics engine.
local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 ) -- Zero gravity.

local cx, cy = display.contentCenterX, display.contentCenterY -- Screen center coordinates.
local predatorSize, preySize, dangerZone, time = 45, 24, 200, 500 -- Object and time variables.
local angleBetween, distanceBetween, moveTo, getRandomTarget -- Forward references to movement functions.

local background = display.newRect(
    display.safeScreenOriginX,
    display.safeScreenOriginY,
    display.safeActualContentWidth,
    display.safeActualContentHeight
)
background.x = cx ; background.y = cy
background:setFillColor( 0, 0.68, 0.99, 0.5 )

-- Help text.
local text = display.newText( {text = "Tap to Feed Me!", x = display.contentCenterX, y = display.contentCenterY/4, fontSize = 32 } )
local textTrans = transition.to( text, { delay = 2000, time=1200, alpha = 0, onComplete=
	function() 
		display.remove( text ) ; text = nil
	end} )

local predator = display.newImageRect( "img/shapeBall.png", predatorSize, predatorSize )
predator.x = cx ; predator.y = cy
predator:setFillColor( 0.8, 0.4, 0.4)
physics.addBody( predator, "dynamic", {radius = predatorSize * 0.5})
predator.linearDamping = 1

function predator:move( )
	-- queryRegion returns a list of display objects within its bounds.
	local querytList = physics.queryRegion( 0, 0, display.safeActualContentWidth, display.safeActualContentHeight )
	local closestMeasure = 10000 -- Ridiculously large so every object will be closer.
	local targetFood = false -- If prey are available, targetFood will be set to a prey object.
	if querytList then
		for i=1,#querytList do
			local object = querytList[i]
			if object ~= predator and object ~= background then -- Exclude the predator and the background.
				local prey = object
				prey:setFillColor( 0.2, 0.8, 0.4 )
				local foodDistance = distanceBetween( predator, prey)
				if foodDistance < closestMeasure then -- Find the closest prey by comparison.
					closestMeasure = foodDistance
					targetFood = prey -- targetFood represents the closest prey.
				end
				if foodDistance < dangerZone then -- If the predator is close, set the prey to runaway.
					prey.runAway = true
				else
					prey.runAway = false
				end
			end
		end
	end
	
	if targetFood ~= false then -- targetFood equals the closest prey.
		moveTo(predator, targetFood, 1.4)
		targetFood:setFillColor(1,1,0.2)
	else -- If targetFood is false - no prey found - make a random movement.
		local randomTarget = getRandomTarget() 
		moveTo(predator, randomTarget)
	end
end
predator.timer = timer.performWithDelay( time, predator.move, -1 )

function predator.collision( event )
	if event.phase == 'began' then
		if event.other.type == "prey" then event.other:die() end
	end
end

local function makeFood( event ) -- Generate food where background is touched.
	if event.phase == "began" then -- Triggered during "began" phase only.
		local prey = display.newImageRect( "img/shapeBall.png", preySize, preySize )
		prey.x = event.x ; prey.y = event.y
		prey:setFillColor( 0.2, 0.8, 0.4, 0.8 )
		physics.addBody( prey, "dynamic", {radius = preySize*0.5})
		prey.linearDamping = 1
		prey.runAway = false -- When prey.runAway equals true, the prey will run from the predator.
		prey.type = "prey"

		function prey:die(  )
			local deathCircle = display.newImageRect( "img/shapeBall.png", preySize, preySize )
			deathCircle.x = self.x ; deathCircle.y = self.y
			deathCircle:setFillColor(1,1,0.2)
			deathCircle.blendMode = "add"
			timer.cancel( self.timer )
			display.remove( self ) ; self = nil

			local trans1 = transition.to( deathCircle, { time=200, alpha = 0, xScale=3, yScale=3, onComplete=
				function() 
					display.remove( deathCircle ) ; deathCircle = nil
				end} )
		end

		local function move( )
			if prey.runAway == true and distanceBetween(prey, predator) < dangerZone * 2 then
				moveTo(prey, predator, -1.2)
			else
				local randomTarget = getRandomTarget()
				moveTo(prey, randomTarget)
			end	
		end

		prey.timer = timer.performWithDelay( time, move, -1 )
	end
end

-- Add touch listener to the background.
background:addEventListener( "touch", makeFood )
-- Add event listener to the predator collisions.
predator:addEventListener( "collision", predator.collision )

-----------------------------------------------------------------------
--- Functions for movement ---
-----------------------------------------------------------------------
-- Find angle.
function angleBetween( object, target )
	local angle = math.atan2( target.y - object.y, target.x - object.x)
	return angle -- Returns angle in radians.
end

-- Find distance.
function distanceBetween( object, target)
	local xfactor = object.x - target.x
	local yfactor = object.y - target.y
	local distance = math.sqrt( xfactor * xfactor + yfactor * yfactor )
	return distance
end

-- Physics movement - object moves toward target with an optional force factor (force can be negative).
function moveTo( object, target, force) 
	local angle = angleBetween(object, target)
	local force = force or 1  -- Use -1 to move away from target.
	local xForce = math.cos(angle) * force * object.mass
	local yforce = math.sin(angle) * force * object.mass

	object:applyLinearImpulse( xForce, yforce, object.x, object.y )
end

-- Generate a random target to move toward using moveTo().
function getRandomTarget(  )
	local randomTarget = {
		x = math.random(display.safeActualContentWidth), 
		y = math.random(display.safeActualContentHeight)
	}
	return randomTarget
end