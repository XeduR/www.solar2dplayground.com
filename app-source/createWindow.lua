local window = {}

local defaultFont = "font/OpenSansRegular.ttf"
local scrollRate = 30

window.activeWindow = nil
window.windowOpen = nil

-- Handle asset window scrolling when the window background is touched.
local objectStart, eventStart
local function scrollImagesWindow( event )
    if event.phase == "began" then
        display.getCurrentStage():setFocus( event.target )
        event.target.isTouched = true
        objectStart, eventStart = window.activeWindow.y, event.y
    elseif event.phase == "moved" then
        if event.target.isTouched then
            local d = event.y - eventStart
            local toY = objectStart + d
            local maxY = window.activeWindow.scroll.maxY
            if toY <= 0 and toY >= -maxY then
                window.activeWindow.y = toY
            else
                objectStart = window.activeWindow.y
                eventStart = event.y
            end
            window.activeWindow.scrollHandle.y = window.activeWindow.scrollHandle.yStart - (window.activeWindow.y/maxY)*430
        end
    else
        display.getCurrentStage():setFocus( nil )
        event.target.isTouched = false
    end
    return true
end

-- Handle asset window scrolling when the scroll handle is touched.
local function scrollImagesHandle( event )
    if event.phase == "began" then
        display.getCurrentStage():setFocus( event.target )
        event.target.isTouched = true
        objectStart, eventStart = window.activeWindow.y, event.y
    elseif event.phase == "moved" then
        if event.target.isTouched then
            local d = event.y - eventStart
            local toY = objectStart + d
            local maxY = window.activeWindow.scroll.maxY
            if event.y <= 116 then
                eventStart = event.y
                event.target.y = 116
                window.activeWindow.y = 0
            elseif event.y >= 546 then
                eventStart = event.y
                event.target.y = 546
                window.activeWindow.y = -maxY
            else
                event.target.y = event.y
                window.activeWindow.y = -((event.y-116)/430)*maxY
            end
        end
    else
        display.getCurrentStage():setFocus( nil )
        event.target.isTouched = false
    end
    return true
end

-- Scroll direction seems to be reversed with browsers/HTML5 builds.
if system.getInfo( "environment" ) ~= "simulator" then
    scrollRate = -scrollRate
end
-- Handle asset window scrolling when mouse wheel is scrolled.
local function mouseScroll( event )
    if window.windowOpen and event.type == "scroll" then
        local dY
        if event.scrollY > 0 then
            dY = scrollRate
        else
            dY = -scrollRate
        end
        local toY = window.activeWindow.y - dY
        local maxY = window.activeWindow.scroll.maxY
        if dY < 0 and toY >= 0 then
            window.activeWindow.y = 0
        elseif dY > 0 and toY <= -maxY then
            window.activeWindow.y = -maxY
        else
            window.activeWindow.y = toY
        end
        window.activeWindow.scrollHandle.y = window.activeWindow.scrollHandle.yStart - (window.activeWindow.y/maxY)*430
    end
end
Runtime:addEventListener( "mouse", mouseScroll )

-- Create and automatically populate asset windows.
function window.new( windowName, group, toggleAssets )
    local background = display.newRoundedRect( group.window, 480, 320, 800, 600, 8 )
    background:setFillColor(0,0.9)
    background:addEventListener( "touch", scrollImagesWindow )
    
    local buttonClose = display.newImageRect( group.window, "ui/buttonClose.png", 48, 48 )
    buttonClose:addEventListener( "touch", toggleAssets )
    buttonClose.x, buttonClose.y = background.x+background.width*0.5-32, background.y-background.height*0.5+32
    
    local title = display.newText( group.window, "", 480, 50, defaultFont, 28 )
    local copyright = display.newText( group.window, "", 480, title.y, defaultFont, 20 )
    copyright:setFillColor( 0.93, 0.67, 0.07 )
    copyright.y = title.y + title.height*0.5 + 4
    copyright.anchorY = 0
    
    group.scrollHandle = display.newRoundedRect( group.window, buttonClose.x, buttonClose.y+buttonClose.height+16, 16, 32, 16 )
    group.scrollHandle:addEventListener( "touch", scrollImagesHandle )
    group.scrollHandle.yStart = group.scrollHandle.y
    group.scrollHandle:setFillColor(1,0.8)
    
    -- Traverse the asset folders create scrollable lists of them to the menu window.
    local imageColumn, imageRow, assetCount = 0, 1, 0
    if windowName == "Images" then
        title.text = "Scroll to view all useable images"
        copyright.text = "These images are courtesy of Ponywolf."
        
        local imageFontSize = 18
        local folder = "img/"
        local imageFolder = system.pathForFile( folder, system.ResourceDirectory )
        for file in lfs.dir( imageFolder ) do
            if file ~= "." and file ~= ".." then
                assetCount = assetCount+1
                local filename = folder .. file
                local x, y = -240+imageColumn*240, -350+imageRow*220
                local asset = display.newImage( group, filename, x, y )
                if asset.width > 180 or asset.height > 120 then
                    local xScale = 160 / asset.width
                    local yScale = 120 / asset.height
                    local scale = math.min( xScale, yScale )
                    asset.xScale, asset.yScale = scale, scale
                end
                asset.anchorY = 1
                asset.name = display.newText( group, "\"" .. filename .. "\"", x, y+12, defaultFont, imageFontSize )
                asset.name.anchorY = 0
                asset.size = display.newText( group, "width: ".. asset.width .. ", height: " .. asset.height, x, y+40, defaultFont, imageFontSize )
                asset.size.anchorY = 0
                imageColumn = imageColumn+1
                if imageColumn == 3 then
                    imageRow = imageRow+1
                    imageColumn = 0
                end
            end
        end
        group.scroll.maxY = math.ceil((assetCount-6)/3)*216
    elseif windowName == "SFX" then
        title.text = "Scroll to view all useable sound effects and music"
        copyright.text = "TBD"
        -- TODO: Download Kenney audio pack & some BG music, if he has some.
        
        
        local folder = "sfx/"
        local imageFolder = system.pathForFile( folder, system.ResourceDirectory )
        for file in lfs.dir( imageFolder ) do
            if file ~= "." and file ~= ".." then
                assetCount = assetCount+1
                
                local filename = folder .. file
                -- print( filename )
                -- local x, y = -240+imageColumn*240, -350+imageRow*220
                -- local asset = display.newImage( group, filename, x, y )
                -- if asset.width > 180 or asset.height > 120 then
                --     local xScale = 160 / asset.width
                --     local yScale = 120 / asset.height
                --     local scale = math.min( xScale, yScale )
                --     asset.xScale, asset.yScale = scale, scale
                -- end
                -- asset.anchorY = 1
                -- asset.name = display.newText( group, "\"" .. filename .. "\"", x, y+12, defaultFont, imageFontSize )
                -- asset.name.anchorY = 0
                -- asset.size = display.newText( group, "width: ".. asset.width .. ", height: " .. asset.height, x, y+40, defaultFont, imageFontSize )
                -- asset.size.anchorY = 0
                imageColumn = imageColumn+1
                if imageColumn == 3 then
                    imageRow = imageRow+1
                    imageColumn = 0
                end
            end
        end
        group.scroll.maxY = math.ceil((assetCount-6)/3)*216
        
    elseif windowName == "Fonts" then
        title.text = "Scroll to view all useable fonts"
        copyright.text = "TBD"
        
    end
end

return window