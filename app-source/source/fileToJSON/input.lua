-- Sample project by Ed Maurina (aka The Roaming Gamer)
-- [Code adapted for Playground by Eetu Rantanen]

display.setDefault( "background", 0.4, 0.85, 1 )

-- Localising frequently used global functions.
local mRand = math.random
local newImageRect = display.newImageRect

-- Creating a shorthand for adding Runtime listeners.
local listen = function( name, listener ) 
	Runtime:addEventListener( name, listener ) 
end

local physics = require("physics")
physics.start()
physics.setGravity(0,60)

local centerX  = display.contentCenterX
local centerY  = display.contentCenterY
local leftEdge  = display.screenOriginX
local rightEdge = display.actualContentWidth - display.screenOriginX

local gameIsRunning = true
local horizSpeed    = 500
local jumpSpeed 	= 1000
local offsetCamera  = 200
local pickupCount   = 0
local distance      = 0

function display.newGroup2( insertInto )
	local group = display.newGroup()
	if( insertInto ) then insertInto:insert( group ) end
	return group
end
local layers = display.newGroup2()
layers.world = display.newGroup2( layers )
layers.background = display.newGroup2( layers.world )
layers.content = display.newGroup2( layers.world )
layers.overlay = display.newGroup2( layers )

-- Creating a rough physics shape for the player character to make the collisions more accurate.
local player = newImageRect( layers.content, "img/jump.png", 117, 117 )
player.x, player.y = centerX, centerY + 100
player.startY = player.y
player.moveLeft, player.moveRight = 0, 0
physics.addBody( player, "dynamic", { bounce = 0.1, shape = { -54, 20, -54, 0, 0, -56, 52, -56, 40, 42, 20, 56, -20, 56 } } )
player.isFixedRotation = true

-- Create a table to use for "camera tracking" purposes.
local camera = { y=player.y+offsetCamera, lastY=player.y }

scoreBack = display.newRect( layers.overlay, centerX, 20, 140, 44 )
scoreBack:setFillColor( 0.125, 0.125, 0.125 )

local scoreLabel = display.newText( layers.overlay, 0, scoreBack.x, scoreBack.y, "fnt/adventpro-regular.ttf", 36 )
scoreLabel:setFillColor(1,1,0)

local function gameover()
	if gameIsRunning then
		gameIsRunning = false
		display.setDefault( "background", 0.82, 0.17, 0.12 )
		player.moveLeft, player.moveRight = 0, 0
		player:removeEventListener("preCollision")
		player:removeEventListener("collision")
		Runtime:removeEventListener( "enterFrame", player )
		-- A delay of 1ms will run the following call the next frame.
		timer.performWithDelay( 1,
			function()
				player.isSensor = true
				player:setFillColor( 1, 0, 0 )
				player.rotation = mRand(-45,45)
			end
		)
	end
end

function scoreLabel:update()
	self.text = pickupCount + distance
end

function player.preCollision( self, event )
	local contact 		= event.contact
	local other 		= event.other
	if( other.isDanger or other.isPickup ) then
		-- skip
	elseif( contact and contact.isEnabled ) then
		if( (self.y - other.y) > -(self.contentHeight/2 + other.contentHeight/2 - 1) ) then
			contact.isEnabled = false
		end
	end	
	return false
end; player:addEventListener("preCollision")

function player.collision( self, event )
	local other = event.other
	if( event.phase == "began" ) then
		local vx, vy = self:getLinearVelocity()
		if( other.isDanger ) then
			gameover()
		
		elseif( other.isPickup ) then
			pickupCount = pickupCount + 100
			scoreLabel:update()
			display.remove(other)
		
		elseif( other.isSpring and not other.open and vy > 0 ) then
			self:setLinearVelocity( vx, -jumpSpeed * 1.25 )
			other.open = true
			timer.performWithDelay( 50,  function() other:setFillColor( 0.5, 0.7 ) end )
		
		elseif( other.isPlatform and vy > 0 ) then
			self:setLinearVelocity( vx, -jumpSpeed  )
		end
	end
	return false
end; player:addEventListener("collision")

local lastY
local lastX
local function createGameObject( x, y, objectType )
	x = x or lastX
	y = y or lastY
	if( not gameIsRunning ) then return nil end
	local obj
	if( objectType == "platform" ) then
		obj = newImageRect( layers.background, "img/platformBase"..math.random(2) ..".png", 192, 72 )
		obj.x = x
		obj.isPlatform = true
		obj.anchorY = 0
		physics.addBody( obj, "static", { bounce = 0 } )
		lastX = x
		lastY = y

	elseif( objectType == "spring" ) then
		obj = newImageRect( layers.background, "img/spaceSprint.png", 58, 58 )
		obj.rotation = -90
		obj.x = x + mRand(-40, 40)
		obj.isSpring = true
		obj.anchorY = 1
		physics.addBody( obj, "static", { bounce = 0, radius = 29 } )
	
	elseif( objectType == "pickup" ) then
		obj = newImageRect( layers.background, "img/gemRedStroked.png", 48, 48 )
		obj.x = x + mRand(-40, 40)
		obj.isPickup = true
		obj.anchorY = 1
		physics.addBody( obj, "static", { bounce = 0 } )
		obj.isSensor = true
	
	elseif( objectType == "danger" ) then
		obj = newImageRect( layers.background, "img/blobGreen.png", 72, 48 )
		obj.x = x + mRand(-40, 40)
		obj.isDanger = true
		obj.anchorY = 1
		physics.addBody( obj, "static", { bounce = 0 } )
		obj.isSensor = true
		
	end
	obj.y = y
end

local function levelGen( noItems )
	while lastY > (player.y - display.actualContentHeight * 0.75) do
		if not gameIsRunning then break end
		createGameObject( centerX + mRand( -400, 400 ) , lastY - mRand( 100, 200 ), "platform" )
		-- Generate other item too?
		if( not noItems and mRand( 1, 100 ) > 20 ) then
			local items = { "danger", "pickup", "pickup", "spring", "spring", "spring"  }
			createGameObject( nil, nil, items[mRand(1,#items)] )
		end
	end
end

function player.enterFrame( self )
	camera.y = player.y + offsetCamera
	
	if( camera.y < camera.lastY ) then
		layers.world.y = layers.world.y + (camera.lastY - camera.y)
		camera.lastY = camera.y
		levelGen()
	end
	
	if player.contentBounds.yMax >= display.actualContentHeight then
		gameover()
	end

	local dist = math.round(self.startY - self.y)
	if( dist > distance ) then 
		distance = dist 
		scoreLabel:update()
	end
	
	if(self.x >= rightEdge) then
		self.x = leftEdge + self.x - rightEdge
	elseif(self.x <= leftEdge) then
		self.x = rightEdge + self.x - leftEdge
	end

	local vx, vy = self:getLinearVelocity()
	vx = 0
	vx = vx - self.moveLeft * horizSpeed
	vx = vx + self.moveRight * horizSpeed
	self:setLinearVelocity( vx, vy )
end; listen( "enterFrame", player )

createGameObject( player.x, player.y + 100, "platform" )
levelGen(true)

-- Create mouse and keyboard listeners to control the character, and prevent the
-- player from using one control method if they are currently using the other one.
local holdingKey, holdingMouse
Runtime:addEventListener( "key", function(event)
	if not holdingMouse then
		local key = event.keyName
		if event.phase == "down" then
			if key == "a" or key == "left" then
				player.moveLeft, player.moveRight = 1, 0
				holdingKey = key
			elseif key == "d" or key == "right" then
				player.moveLeft, player.moveRight = 0, 1
				holdingKey = key
			end
		else
			if holdingKey and holdingKey == key then
				player.moveLeft, player.moveRight = 0, 0
				holdingKey = nil
			end
		end
	end
end )

Runtime:addEventListener( "touch", function(event)
	if gameIsRunning and not holdingKey then
		if event.phase == "began" or event.phase == "moved" then
			holdingMouse = true
			if event.x >= centerX then
				player.moveLeft, player.moveRight = 0, 1
			else
				player.moveLeft, player.moveRight = 1, 0
			end
		else
			player.moveLeft, player.moveRight = 0, 0
			holdingMouse = false
		end
	end
end )
