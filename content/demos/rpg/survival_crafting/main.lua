-- Survival Crafting — Lurek2D Demo
-- WASD to move, click to mine, C to craft, P to place wall
-- Run with: cargo run -- content/demos/rpg/survival_crafting

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local TILE = 32
local COLS, ROWS = 25, 18
local map = {}
local player = { gx = 12, gy = 9, hp = 100, hunger = 100 }
local inventory = { wood = 0, stone = 0, berry = 0, pickaxe = 0, wall = 0 }
local dayTime, dayLength = 0, 60
local dayNum = 1
local enemies = {}
local mining = { active = false, gx = 0, gy = 0, progress = 0, needed = 1.0 }
local craftOpen = false
local recipes = {
    { name = "pickaxe", needs = { wood = 2, stone = 3 }, gives = "pickaxe" },
    { name = "wall",    needs = { wood = 4 },            gives = "wall" },
}
local moveCD = 0

local tileColors = {
    grass = { 0.3, 0.65, 0.2 },
    stone = { 0.5, 0.5, 0.5 },
    tree  = { 0.15, 0.45, 0.1 },
    water = { 0.2, 0.35, 0.75 },
    berry = { 0.5, 0.2, 0.5 },
    wall  = { 0.6, 0.55, 0.4 },
}

local function genMap()
    for y = 1, ROWS do
        map[y] = {}
        for x = 1, COLS do
            local r = math.random()
            if r < 0.05 then map[y][x] = "water"
            elseif r < 0.15 then map[y][x] = "stone"
            elseif r < 0.28 then map[y][x] = "tree"
            elseif r < 0.33 then map[y][x] = "berry"
            else map[y][x] = "grass"
            end
        end
    end
    map[player.gy][player.gx] = "grass"
end

local function isNight()
    return dayTime > dayLength * 0.6
end

local function adj(gx, gy)
    local dx = math.abs(gx - player.gx)
    local dy = math.abs(gy - player.gy)
    return dx + dy == 1
end

local function spawnEnemy()
    local ex, ey
    for _ = 1, 20 do
        ex = math.random(1, COLS)
        ey = math.random(1, ROWS)
        if map[ey][ex] == "grass" and (math.abs(ex - player.gx) + math.abs(ey - player.gy)) > 6 then
            table.insert(enemies, { gx = ex, gy = ey, hp = 2, cd = 0 })
            return
        end
    end
end

function lurek.init()
    lurek.window.setTitle("Survival Crafting")
    lurek.gfx.setBackgroundColor(0.1, 0.1, 0.15)
    genMap()
end

function lurek.process(dt)
    -- day cycle
    dayTime = dayTime + dt
    if dayTime >= dayLength then
        dayTime = dayTime - dayLength
        dayNum = dayNum + 1
    end

    -- hunger
    player.hunger = player.hunger - dt * 1.5
    if player.hunger <= 0 then
        player.hunger = 0
        player.hp = player.hp - dt * 10
    end

    -- movement
    moveCD = moveCD - dt
    if not craftOpen and moveCD <= 0 then
        local dx, dy = 0, 0
        if lurek.keyboard.isDown("w") then dy = -1
        elseif lurek.keyboard.isDown("s") then dy = 1
        elseif lurek.keyboard.isDown("a") then dx = -1
        elseif lurek.keyboard.isDown("d") then dx = 1
        end
        if dx ~= 0 or dy ~= 0 then
            local nx, ny = player.gx + dx, player.gy + dy
            if nx >= 1 and nx <= COLS and ny >= 1 and ny <= ROWS then
                local t = map[ny][nx]
                if t ~= "water" and t ~= "tree" and t ~= "stone" and t ~= "wall" then
                    player.gx, player.gy = nx, ny
                    moveCD = 0.15
                end
            end
        end
    end

    -- mining
    if mining.active then
        mining.progress = mining.progress + dt
        if mining.progress >= mining.needed then
            local t = map[mining.gy][mining.gx]
            if t == "tree" then inventory.wood = inventory.wood + 2
            elseif t == "stone" then inventory.stone = inventory.stone + 2
            elseif t == "berry" then
                inventory.berry = inventory.berry + 1
                player.hunger = clamp(player.hunger + 25, 0, 100)
            end
            map[mining.gy][mining.gx] = "grass"
            mining.active = false
        end
    end

    -- enemies at night
    if isNight() then
        if #enemies < 3 and math.random() < dt * 0.5 then spawnEnemy() end
        for _, e in ipairs(enemies) do
            e.cd = e.cd - dt
            if e.cd <= 0 then
                local edx = player.gx > e.gx and 1 or (player.gx < e.gx and -1 or 0)
                local edy = player.gy > e.gy and 1 or (player.gy < e.gy and -1 or 0)
                if math.abs(edx) >= math.abs(edy) then edy = 0 else edx = 0 end
                local nx, ny = e.gx + edx, e.gy + edy
                if nx >= 1 and nx <= COLS and ny >= 1 and ny <= ROWS and map[ny][nx] ~= "water" and map[ny][nx] ~= "wall" then
                    e.gx, e.gy = nx, ny
                end
                if e.gx == player.gx and e.gy == player.gy then
                    player.hp = player.hp - 10
                end
                e.cd = 0.6
            end
        end
    else
        enemies = {}
    end
end

function lurek.render()
    -- darkness overlay intensity
    local nightAlpha = 0
    if isNight() then
        nightAlpha = clamp((dayTime - dayLength * 0.6) / (dayLength * 0.15), 0, 0.55)
    end

    -- tiles
    for y = 1, ROWS do
        for x = 1, COLS do
            local t = map[y][x]
            local c = tileColors[t] or tileColors.grass
            lurek.gfx.setColor(c[1], c[2], c[3], 1)
            lurek.gfx.rectangle("fill", (x - 1) * TILE, (y - 1) * TILE, TILE - 1, TILE - 1)
        end
    end

    -- enemies
    lurek.gfx.setColor(0.9, 0.15, 0.15, 1)
    for _, e in ipairs(enemies) do
        lurek.gfx.rectangle("fill", (e.gx - 1) * TILE + 4, (e.gy - 1) * TILE + 4, TILE - 8, TILE - 8)
    end

    -- player
    lurek.gfx.setColor(0.2, 0.5, 1, 1)
    lurek.gfx.circle("fill", (player.gx - 0.5) * TILE, (player.gy - 0.5) * TILE, 12)

    -- mining bar
    if mining.active then
        local bx = (mining.gx - 1) * TILE
        local by = (mining.gy - 1) * TILE - 8
        lurek.gfx.setColor(0.3, 0.3, 0.3, 1)
        lurek.gfx.rectangle("fill", bx, by, TILE, 6)
        lurek.gfx.setColor(0, 1, 0.3, 1)
        lurek.gfx.rectangle("fill", bx, by, TILE * (mining.progress / mining.needed), 6)
    end

    -- night overlay
    if nightAlpha > 0 then
        lurek.gfx.setColor(0, 0, 0.05, nightAlpha)
        lurek.gfx.rectangle("fill", 0, 0, 800, 600)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.6)
    lurek.gfx.rectangle("fill", 0, ROWS * TILE, 800, 40)
    lurek.gfx.setColor(1, 1, 1, 1)
    local dayStr = isNight() and "NIGHT" or "Day"
    lurek.gfx.print(dayStr .. " " .. dayNum .. "  HP:" .. math.floor(player.hp) .. "  Hunger:" .. math.floor(player.hunger), 10, ROWS * TILE + 5)
    lurek.gfx.print("Wood:" .. inventory.wood .. " Stone:" .. inventory.stone .. " Berry:" .. inventory.berry .. " Pick:" .. inventory.pickaxe .. " Wall:" .. inventory.wall, 10, ROWS * TILE + 22)

    -- craft menu
    if craftOpen then
        lurek.gfx.setColor(0, 0, 0, 0.8)
        lurek.gfx.rectangle("fill", 250, 150, 300, 200)
        lurek.gfx.setColor(1, 1, 0.6, 1)
        lurek.gfx.print("CRAFTING (1-2 to craft, C to close)", 260, 160)
        for i, r in ipairs(recipes) do
            local parts = {}
            for k, v in pairs(r.needs) do parts[#parts + 1] = k .. "x" .. v end
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.print(i .. ") " .. r.name .. " = " .. table.concat(parts, " + "), 270, 185 + i * 22)
        end
    end
end

local function tryCraft(idx)
    local r = recipes[idx]
    if not r then return end
    for k, v in pairs(r.needs) do
        if (inventory[k] or 0) < v then return end
    end
    for k, v in pairs(r.needs) do inventory[k] = inventory[k] - v end
    inventory[r.gives] = inventory[r.gives] + 1
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "c" then craftOpen = not craftOpen; return end
    if craftOpen then
        if key == "1" then tryCraft(1) end
        if key == "2" then tryCraft(2) end
        return
    end
    if key == "p" and inventory.wall > 0 then
        -- place wall in front (right)
        local px = player.gx + 1
        if px <= COLS and map[player.gy][px] == "grass" then
            map[player.gy][px] = "wall"
            inventory.wall = inventory.wall - 1
        end
    end
end

function lurek.mousepressed(x, y, button)
    if craftOpen then return end
    local gx = math.floor(x / TILE) + 1
    local gy = math.floor(y / TILE) + 1
    if gx < 1 or gx > COLS or gy < 1 or gy > ROWS then return end
    if not adj(gx, gy) then return end
    local t = map[gy][gx]
    if t == "tree" or t == "stone" or t == "berry" then
        mining = { active = true, gx = gx, gy = gy, progress = 0, needed = (t == "stone" and inventory.pickaxe > 0) and 0.5 or 1.0 }
    end
end
