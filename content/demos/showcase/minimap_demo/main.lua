-- Minimap Demo
-- Demonstrates lurek.minimap: terrain, fog, objects, pings, markers, viewport
-- Run with: cargo run -- content/demos/showcase/minimap_demo

local minimap
local playerX, playerY = 50, 50
local speed = 60

function lurek.init()
    -- Create a 100x100 grid minimap displayed at 200x200 pixels
    minimap = lurek.minimap.newMinimap(100, 100, 200, 200)

    -- Set up terrain types with colors
    minimap:setTerrainColor(0, 0.2, 0.5, 0.2) -- grass (green)
    minimap:setTerrainColor(1, 0.4, 0.3, 0.2) -- dirt (brown)
    minimap:setTerrainColor(2, 0.3, 0.5, 0.8) -- water (blue)
    minimap:setTerrainColor(3, 0.6, 0.6, 0.6) -- stone (grey)

    -- Generate a simple terrain map
    for x = 1, 100 do
        for y = 1, 100 do
            local nx = x / 20
            local ny = y / 20
            local val = math.sin(nx) * math.cos(ny)
            if val < -0.3 then
                minimap:setTerrain(x, y, 2) -- water
            elseif val < 0.0 then
                minimap:setTerrain(x, y, 1) -- dirt
            elseif val > 0.6 then
                minimap:setTerrain(x, y, 3) -- stone
            else
                minimap:setTerrain(x, y, 0) -- grass
            end
        end
    end

    -- Enable fog of war
    minimap:setFogEnabled(true)
    minimap:setFogColor(0, 0, 0, 0.7)

    -- Reveal a circle around the player start
    revealFog(playerX, playerY, 15)

    -- Add object types
    local unitType = minimap:addObjectType("player", 0, 1, 0)      -- green
    local enemyType = minimap:addObjectType("enemy", 1, 0, 0)       -- red
    local buildingType = minimap:addObjectType("building", 0.5, 0.5, 1) -- light blue

    -- Place player
    minimap:setObject(1, playerX, playerY, unitType, 0)
    minimap:setOwnerColor(0, 0, 1, 0)

    -- Place some enemies
    minimap:setObject(10, 70, 30, enemyType, 1)
    minimap:setObject(11, 20, 80, enemyType, 1)
    minimap:setObject(12, 85, 75, enemyType, 1)
    minimap:setOwnerColor(1, 1, 0, 0)

    -- Place some buildings
    minimap:setObject(20, 50, 50, buildingType, 0)
    minimap:setObject(21, 35, 20, buildingType, 0)

    -- Add markers
    minimap:addMarker(50, 50, "Base", 0, 0, 1)
    minimap:addMarker(85, 75, "Enemy Camp", 1, 0.5, 0)

    -- Set up viewport (visible area indicator)
    updateViewport()

    -- Set initial zoom and center
    minimap:setCenter(playerX, playerY)
end

function revealFog(cx, cy, radius)
    for dx = -radius, radius do
        for dy = -radius, radius do
            if dx * dx + dy * dy <= radius * radius then
                local x = cx + dx
                local y = cy + dy
                if x >= 1 and x <= 100 and y >= 1 and y <= 100 then
                    minimap:setFogLevel(x, y, 2)
                end
            end
        end
    end
end

function updateViewport()
    -- Assume camera shows 40x30 tile area
    minimap:setViewportRect(playerX - 20, playerY - 15, 40, 30)
end

function lurek.process(dt)
    -- Move player with arrow keys
    local moved = false
    if lurek.keyboard.isDown("left") then
        playerX = math.max(1, playerX - speed * dt)
        moved = true
    end
    if lurek.keyboard.isDown("right") then
        playerX = math.min(100, playerX + speed * dt)
        moved = true
    end
    if lurek.keyboard.isDown("up") then
        playerY = math.max(1, playerY - speed * dt)
        moved = true
    end
    if lurek.keyboard.isDown("down") then
        playerY = math.min(100, playerY + speed * dt)
        moved = true
    end

    if moved then
        -- Update player object position
        minimap:setObject(1, playerX, playerY, 1, 0)
        minimap:setCenter(playerX, playerY)
        updateViewport()
        revealFog(math.floor(playerX), math.floor(playerY), 10)
    end

    -- Update minimap (handles ping expiry)
    minimap:update(dt)
end

function lurek.keypressed(key)
    if key == "p" then
        -- Add a ping at player position
        minimap:addPing(playerX, playerY, 2.0, 1, 1, 0)
    elseif key == "m" then
        -- Toggle color mode
        if minimap:getColorMode() == "terrain" then
            minimap:setColorMode("political")
        else
            minimap:setColorMode("terrain")
        end
    elseif key == "f" then
        -- Toggle fog
        minimap:setFogEnabled(not minimap:isFogEnabled())
    elseif key == "z" then
        -- Cycle zoom
        local z = minimap:getZoom()
        if z < 2 then
            minimap:setZoom(z + 0.5)
        else
            minimap:setZoom(1)
        end
    elseif key == "escape" then
        lurek.signal.quit()
    end
end

function lurek.render()
    -- Draw game world background
    lurek.gfx.setBackgroundColor(0.15, 0.15, 0.2)
    lurek.gfx.clear(0.15, 0.15, 0.2)

    -- Draw simple game world representation
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Game World", 10, 10)
    lurek.gfx.print(string.format("Player: %.0f, %.0f", playerX, playerY), 10, 30)

    -- Draw player indicator in game world
    local wx = playerX * 5
    local wy = playerY * 4 + 60
    lurek.gfx.setColor(0, 1, 0)
    lurek.gfx.circle("fill", wx, wy, 6)

    -- Draw minimap background (top-right corner)
    local mx, my = 580, 10
    lurek.gfx.setColor(0.1, 0.1, 0.1, 0.8)
    lurek.gfx.rectangle("fill", mx - 2, my - 2, 204, 204)

    -- Draw minimap border
    lurek.gfx.setColor(0.5, 0.5, 0.5)
    lurek.gfx.rectangle("line", mx - 2, my - 2, 204, 204)

    -- Draw HUD text
    lurek.gfx.setColor(1, 1, 1, 0.8)
    lurek.gfx.print("Controls:", 10, 520)
    lurek.gfx.print("Arrows=Move  P=Ping  M=Mode  F=Fog  Z=Zoom", 10, 540)
    lurek.gfx.print(string.format("Mode: %s | Fog: %s | Zoom: %.1fx | Pings: %d",
        minimap:getColorMode(),
        minimap:isFogEnabled() and "ON" or "OFF",
        minimap:getZoom(),
        minimap:getPingCount()),
        10, 560)
    lurek.gfx.print(string.format("Objects: %d | Markers: %d",
        minimap:getObjectCount(),
        minimap:getMarkerCount()),
        10, 580)
end
