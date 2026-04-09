-- Farming / Life Simulation Demo
-- Top-down farming with crops, seasons, day/night cycle, and economy
-- Controls: WASD to move, Click soil to plant/harvest, N to advance day
-- Number keys 1-3 to select crop, B to buy seeds, S to sell harvest
-- Run with: cargo run -- content/demos/simulation/farming_sim

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local TILE = 32
local FARM_X, FARM_Y = 6, 4
local FARM_W, FARM_H = 8, 6
local MAP_W, MAP_H = 24, 18

local farmer = { x = 12, y = 9, speed = 5 }
local day = 1
local season = 1
local seasonNames = { "Spring", "Summer", "Autumn", "Winter" }
local seasonLen = 12
local dayTimer = 0
local dayDuration = 8
local autoTime = false
local money = 50
local selectedCrop = 1

local crops = {
    { name = "Wheat",   growTime = 3, seedCost = 5,  sellPrice = 12, color = { 0.9, 0.8, 0.2 } },
    { name = "Tomato",  growTime = 5, seedCost = 8,  sellPrice = 22, color = { 0.9, 0.2, 0.15 } },
    { name = "Pumpkin", growTime = 8, seedCost = 12, sellPrice = 40, color = { 0.9, 0.5, 0.1 } },
}

local inventory = {
    seeds = { 5, 3, 1 },
    harvest = { 0, 0, 0 },
}

local tiles = {}     -- tiles[y][x] = { soil = bool, crop = nil or { type, plantDay, grown } }
local shopOpen = false

local function initTiles()
    tiles = {}
    for y = 1, MAP_H do
        tiles[y] = {}
        for x = 1, MAP_W do
            local isFarm = (x >= FARM_X and x < FARM_X + FARM_W and y >= FARM_Y and y < FARM_Y + FARM_H)
            tiles[y][x] = { soil = isFarm, crop = nil }
        end
    end
end

local function getSeasonColor()
    if season == 1 then return 0.25, 0.55, 0.2   -- spring green
    elseif season == 2 then return 0.3, 0.6, 0.15 -- summer
    elseif season == 3 then return 0.5, 0.4, 0.2  -- autumn
    else return 0.6, 0.65, 0.7 end                -- winter
end

local function getDayNightFactor()
    -- Dawn/midday/dusk curve: multiply all colours by this factor each frame
    local t = (dayTimer / dayDuration)
    if t < 0.25 then return lerp(0.4, 1.0, t / 0.25)       -- dawn
    elseif t < 0.75 then return 1.0                                     -- day
    else return lerp(1.0, 0.4, (t - 0.75) / 0.25) end       -- dusk
end

local function advanceDay()
    day = day + 1
    dayTimer = 0
    if ((day - 1) % seasonLen) == 0 then
        season = (season % 4) + 1
    end
    -- Grow crops
    -- Winter doubles growTime, making it risky to plant slow crops in Autumn
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local t = tiles[y][x]
            if t.crop and not t.crop.grown then
                local elapsed = day - t.crop.plantDay
                local growTime = crops[t.crop.type].growTime
                if season == 4 then growTime = growTime * 2 end -- winter slows
                if elapsed >= growTime then t.crop.grown = true end
            end
        end
    end
end

function lurek.init()
    lurek.window.setTitle("Farming Simulator")
    lurek.gfx.setBackgroundColor(0.2, 0.45, 0.15)
    initTiles()
end

function lurek.process(dt)
    -- Farmer movement
    local fx, fy = 0, 0
    if lurek.keyboard.isDown("w") or lurek.keyboard.isDown("up") then fy = -1 end
    if lurek.keyboard.isDown("s") or lurek.keyboard.isDown("down") then fy = 1 end
    if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then fx = -1 end
    if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then fx = 1 end
    farmer.x = clamp(farmer.x + fx * farmer.speed * dt, 1, MAP_W)
    farmer.y = clamp(farmer.y + fy * farmer.speed * dt, 1, MAP_H)
    -- Day timer
    if autoTime then
        dayTimer = dayTimer + dt
        if dayTimer >= dayDuration then advanceDay() end
    end
end

function lurek.render()
    local dnf = getDayNightFactor()
    local sr, sg, sb = getSeasonColor()
    -- Update background for day/night
    lurek.gfx.setBackgroundColor(sr * dnf * 0.5, sg * dnf * 0.5, sb * dnf * 0.5)
    -- Draw ground
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local t = tiles[y][x]
            local px, py = (x - 1) * TILE, (y - 1) * TILE
            if t.soil then
                lurek.gfx.setColor(0.35 * dnf, 0.22 * dnf, 0.1 * dnf)
                lurek.gfx.rectangle("fill", px, py, TILE - 1, TILE - 1)
                -- Crops
                if t.crop then
                    local c = crops[t.crop.type]
                    if t.crop.grown then
                        lurek.gfx.setColor(c.color[1] * dnf, c.color[2] * dnf, c.color[3] * dnf)
                        lurek.gfx.circle("fill", px + TILE / 2, py + TILE / 2, 10)
                        lurek.gfx.setColor(0, 0.4 * dnf, 0)
                        lurek.gfx.rectangle("fill", px + TILE / 2 - 1, py + 4, 2, TILE / 2 - 4)
                    else
                        local progress = (day - t.crop.plantDay) / c.growTime
                        local sz = lerp(3, 10, clamp(progress, 0, 1))
                        lurek.gfx.setColor(0.2 * dnf, 0.6 * dnf, 0.15 * dnf)
                        lurek.gfx.circle("fill", px + TILE / 2, py + TILE / 2, sz)
                        lurek.gfx.setColor(0.3 * dnf, 0.4 * dnf, 0.1 * dnf)
                        lurek.gfx.rectangle("fill", px + TILE / 2 - 1, py + TILE / 2, 2, TILE / 2 - 2)
                    end
                end
            else
                lurek.gfx.setColor(sr * dnf, sg * dnf, sb * dnf)
                lurek.gfx.rectangle("fill", px, py, TILE - 1, TILE - 1)
            end
        end
    end
    -- Farm border
    lurek.gfx.setColor(0.6 * dnf, 0.4 * dnf, 0.2 * dnf)
    lurek.gfx.rectangle("line", (FARM_X - 1) * TILE - 2, (FARM_Y - 1) * TILE - 2, FARM_W * TILE + 4, FARM_H * TILE + 4)
    -- Farmer
    lurek.gfx.setColor(0.2 * dnf, 0.5 * dnf, 0.9 * dnf)
    local fpx = (farmer.x - 1) * TILE
    local fpy = (farmer.y - 1) * TILE
    lurek.gfx.rectangle("fill", fpx + 4, fpy + 4, TILE - 8, TILE - 8)
    -- Head
    lurek.gfx.setColor(0.9 * dnf, 0.75 * dnf, 0.55 * dnf)
    lurek.gfx.circle("fill", fpx + TILE / 2, fpy + 6, 6)
    -- Hat
    lurek.gfx.setColor(0.6 * dnf, 0.3 * dnf, 0.1 * dnf)
    lurek.gfx.rectangle("fill", fpx + 6, fpy, TILE - 12, 5)
    -- HUD Panel
    lurek.gfx.setColor(0, 0, 0, 0.75)
    lurek.gfx.rectangle("fill", 0, MAP_H * TILE, 800, 600 - MAP_H * TILE)
    -- Day/Season info
    lurek.gfx.setColor(1, 1, 0.8)
    lurek.gfx.print("Day " .. day .. " | " .. seasonNames[season] .. " (Day " .. (((day - 1) % seasonLen) + 1) .. "/" .. seasonLen .. ")", 10, MAP_H * TILE + 6)
    lurek.gfx.print("Money: $" .. money, 10, MAP_H * TILE + 24)
    -- Time bar
    local tbx, tby = 350, MAP_H * TILE + 6
    lurek.gfx.setColor(0.2, 0.2, 0.3); lurek.gfx.rectangle("fill", tbx, tby, 120, 12)
    lurek.gfx.setColor(1, 0.8, 0.2); lurek.gfx.rectangle("fill", tbx, tby, 120 * (dayTimer / dayDuration), 12)
    lurek.gfx.setColor(1, 1, 1); lurek.gfx.print(autoTime and "Auto" or "Manual (N)", tbx + 130, tby)
    -- Inventory
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Seeds:", 10, MAP_H * TILE + 44)
    for i, c in ipairs(crops) do
        local sel = (i == selectedCrop)
        if sel then lurek.gfx.setColor(1, 1, 0.3) else lurek.gfx.setColor(0.7, 0.7, 0.7) end
        lurek.gfx.print("[" .. i .. "] " .. c.name .. ": " .. inventory.seeds[i], 10 + (i - 1) * 160, MAP_H * TILE + 60)
    end
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Harvest:", 10, MAP_H * TILE + 78)
    for i, c in ipairs(crops) do
        lurek.gfx.setColor(c.color[1], c.color[2], c.color[3])
        lurek.gfx.print(c.name .. ": " .. inventory.harvest[i], 80 + (i - 1) * 160, MAP_H * TILE + 78)
    end
    -- Controls hint
    lurek.gfx.setColor(0.5, 0.5, 0.6)
    lurek.gfx.print("B=Buy seeds  S=Sell harvest  T=Toggle auto-time  1/2/3=Select crop  Click=Plant/Harvest", 10, MAP_H * TILE + 98)
    -- Shop overlay
    if shopOpen then
        lurek.gfx.setColor(0, 0, 0, 0.85); lurek.gfx.rectangle("fill", 200, 150, 400, 250)
        lurek.gfx.setColor(0.8, 0.7, 0.3); lurek.gfx.print("SEED SHOP", 340, 160, 1.3)
        lurek.gfx.setColor(1, 1, 1); lurek.gfx.print("Money: $" .. money, 340, 185)
        for i, c in ipairs(crops) do
            local by = 210 + (i - 1) * 55
            lurek.gfx.setColor(0.15, 0.15, 0.2); lurek.gfx.rectangle("fill", 220, by, 360, 45)
            lurek.gfx.setColor(c.color[1], c.color[2], c.color[3])
            lurek.gfx.print(c.name .. " Seeds", 235, by + 5, 1.1)
            lurek.gfx.setColor(0.7, 0.7, 0.7)
            lurek.gfx.print("Cost: $" .. c.seedCost .. "/seed  |  Grow: " .. c.growTime .. " days  |  Sells: $" .. c.sellPrice, 235, by + 24)
            lurek.gfx.setColor(0.3, 0.8, 0.3)
            lurek.gfx.print("[" .. i .. "] Buy", 520, by + 10)
        end
        lurek.gfx.setColor(0.6, 0.6, 0.6); lurek.gfx.print("Press B to close shop", 320, 380)
    end
    lurek.gfx.setColor(0.5, 0.5, 0.5); lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 730, 580)
end

function lurek.mousepressed(mx, my, button)
    if shopOpen or button ~= 1 then return end
    local tx = math.floor(mx / TILE) + 1
    local ty = math.floor(my / TILE) + 1
    if tx < 1 or tx > MAP_W or ty < 1 or ty > MAP_H then return end
    local t = tiles[ty][tx]
    if not t.soil then return end
    if t.crop and t.crop.grown then
        -- Harvest
        inventory.harvest[t.crop.type] = inventory.harvest[t.crop.type] + 1
        t.crop = nil
    elseif not t.crop then
        -- Plant
        if inventory.seeds[selectedCrop] > 0 then
            inventory.seeds[selectedCrop] = inventory.seeds[selectedCrop] - 1
            t.crop = { type = selectedCrop, plantDay = day, grown = false }
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "n" and not autoTime then advanceDay() end
    if key == "t" then autoTime = not autoTime end
    if key == "1" then selectedCrop = 1 end
    if key == "2" then selectedCrop = 2 end
    if key == "3" then selectedCrop = 3 end
    if key == "b" then
        if shopOpen then
            shopOpen = false
        else
            shopOpen = true
        end
    end
    -- Buy in shop
    if shopOpen then
        for i = 1, #crops do
            if key == tostring(i) and money >= crops[i].seedCost then
                money = money - crops[i].seedCost
                inventory.seeds[i] = inventory.seeds[i] + 1
            end
        end
    end
    -- Sell all harvest
    if key == "s" and not shopOpen then
        for i = 1, #crops do
            money = money + inventory.harvest[i] * crops[i].sellPrice
            inventory.harvest[i] = 0
        end
    end
end
