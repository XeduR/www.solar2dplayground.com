-- Sample code by Eetu Rantanen

display.setDefault( "background", 0.55, 0, 0.2 )

local transitionTime = 150
local images = { "img/spaceWrench.png", "img/spaceGun.png", "img/spaceGrenade.png", "img/spaceKey.png", "img/spaceExtinguisher.png", "img/spaceCup.png" }

-- Save time by creating one function to handle flipping all tokens.
local function flip( target, time, listener )
    local offset = 64
    if target.path.x1 == 64 then offset = 0 end
    transition.to( target.path, { time=time, x1=offset, x2=offset, x3=-offset, x4=-offset, onComplete=listener } )
end

local canTouch, previous = true
local function checkResult( target )
    if not previous then
        previous = target
        canTouch = true
    else
        if target.id == previous.id then
            -- In this sample code, nothing actually gets removed, they are just hidden.
            transition.to( target.front, { time=450, alpha=0 } )
            transition.to( previous.front, { time=450, alpha=0, onComplete=function()
                previous = nil
                canTouch = true
            end } )
        else
            timer.performWithDelay( 300, function() -- Wait before flipping the tokens.
                 -- First hide the front, then reveal the back.
                flip( target.front, 250, function() flip( target, 250 ) end )
                flip( previous.front, 250, function() flip( previous, 250, function()
                        previous = nil
                        canTouch = true
                    end )
                end )
            end )
        end
    end
end

local function touchListener( event )
    if canTouch and event.phase == "began" then
        canTouch = false -- Prevent further touches until the transitions have finished.
        flip( event.target, 200, function() -- First hide the back, then reveal the front.
            flip( event.target.front, 200, function() checkResult( event.target ) end )
        end )
    end
end

local token, n = {}, 1
for i = 1, 12 do
    token[i] = display.newImage( images[n], 270+math.floor((i-1)/3)*140, 180+math.fmod((i-1),3)*140 )
    flip( token[#token], 0 )
    token[i].back = display.newImage( "img/spaceMonster.png", token[i].x, token[i].y )
    token[i].back.front = token[i] -- Add a refence to the front side of the token.
    token[i].back.id = n -- This id will be used to identify correct pairs.
    token[i].back:addEventListener( "touch", touchListener )
    n = n+1
    if n > 6 then
        n = 1
    end
end

for i = 1, 12 do -- Shuffle the tokens around.
    local target = math.random(12)
    local xNew, yNew = token[target].x, token[target].y
    token[target].x, token[target].y, token[target].back.x, token[target].back.y = token[i].x, token[i].y, token[i].x, token[i].y
    token[i].x, token[i].y, token[i].back.x, token[i].back.y = xNew, yNew, xNew, yNew
end