-- Classic Grid Roguelike Demo
-- Turn-based dungeon crawler with fog of war, combat, and permadeath
-- Controls: Arrow keys to move (one step per press), R to restart on death
-- Bump into enemies to attack. Find stairs (>) to descend.
-- Run with: cargo run -- content/demos/rpg/roguelike

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local TILE_SIZE = 24
local MAP_W, MAP_H = 30, 24
local VIEW_RADIUS = 5
local map = {}
local revealed = {}
local player = {}
local enemies = {}
local pickups = {}
local messages = {}
local floor_num = 1
local gameOver = false
local turnCount = 0

local FLOOR, WALL, STAIRS = 0, 1, 2

local function addMsg(text)
    table.insert(messages, 1, text)
    if #messages > 5 then table.remove(messages) end
end

local function inBounds(x, y) return x >= 1 and x <= MAP_W and y >= 1 and y <= MAP_H end

local function carveRoom(x1, y1, x2, y2)
    for y = y1, y2 do for x = x1, x2 do
        if inBounds(x, y) then map[y][x] = FLOOR end
    end end
end

local function carveHCorridor(x1, x2, y)
    local a, b = clamp(x1, 1, MAP_W), clamp(x2, 1, MAP_W)
    if a > b then a, b = b, a end
    for x = a, b do if inBounds(x, y) then map[y][x] = FLOOR end end
end

local function carveVCorridor(y1, y2, x)
    local a, b = clamp(y1, 1, MAP_H), clamp(y2, 1, MAP_H)
    if a > b then a, b = b, a end
    for y = a, b do if inBounds(x, y) then map[y][x] = FLOOR end end
end

local function generateDungeon()
    map = {}; revealed = {}; enemies = {}; pickups = {}
    for y = 1, MAP_H do
        map[y] = {}; revealed[y] = {}
        for x = 1, MAP_W do map[y][x] = WALL; revealed[y][x] = false end
    end
    -- Room placement: try 8 random rectangles, reject any that overlap an existing
    -- room (with a 1-cell buffer). Store each accepted room's bounding box and centre
    -- so corridors can connect them without searching.
    local rooms = {}
    for _ = 1, 8 do
        local rw = math.random(4, 8)
        local rh = math.random(3, 6)
        local rx = math.random(2, MAP_W - rw - 1)
        local ry = math.random(2, MAP_H - rh - 1)
        local overlap = false
        for _, r in ipairs(rooms) do
            if rx <= r.x2 + 1 and rx + rw >= r.x1 - 1 and ry <= r.y2 + 1 and ry + rh >= r.y1 - 1 then overlap = true; break end
        end
        if not overlap then
            carveRoom(rx, ry, rx + rw, ry + rh)
            rooms[#rooms + 1] = { x1 = rx, y1 = ry, x2 = rx + rw, y2 = ry + rh,
                cx = math.floor(rx + rw / 2), cy = math.floor(ry + rh / 2) }
        end
    end
    -- Connect adjacent rooms with L-shaped corridors.
    -- Randomly pick either H-then-V or V-then-H to avoid monotonous layouts.
    for i = 2, #rooms do
        local a, b = rooms[i - 1], rooms[i]
        if math.random() > 0.5 then
            carveHCorridor(a.cx, b.cx, a.cy); carveVCorridor(a.cy, b.cy, b.cx)
        else
            carveVCorridor(a.cy, b.cy, a.cx); carveHCorridor(a.cx, b.cx, b.cy)
        end
    end
    -- Player always starts in the first room's centre; stairs are in the last room.
    player = { x = rooms[1].cx, y = rooms[1].cy, hp = 10, maxHp = 10, atk = 3, kills = 0 }
    local lr = rooms[#rooms]
    map[lr.cy][lr.cx] = STAIRS
    -- Scale enemy count with floor depth so later floors are progressively harder.
    for i = 2, #rooms do
        local r = rooms[i]
        local count = math.random(1, 2 + math.floor(floor_num / 2))
        for _ = 1, count do
            local ex = math.random(r.x1 + 1, r.x2 - 1)
            local ey = math.random(r.y1 + 1, r.y2 - 1)
            if map[ey][ex] == FLOOR then
                enemies[#enemies + 1] = { x = ex, y = ey, hp = 2 + floor_num, maxHp = 2 + floor_num, atk = 1 + math.floor(floor_num / 2), char = "E" }
            end
        end
    end
    -- Skip first and last rooms for pickups: start room is too forgiving, last room has stairs.
    for i = 2, #rooms - 1 do
        if math.random() > 0.4 then
            local r = rooms[i]
            pickups[#pickups + 1] = { x = math.random(r.x1, r.x2), y = math.random(r.y1, r.y2), kind = "hp", amount = 3 }
        end
    end
end

-- updateFOV: marks all cells within VIEW_RADIUS of the player as permanently revealed.
-- Uses a circular mask (dx²+dy² ≤ r²) rather than a square so the visible area
-- looks natural. Revealed cells stay visible even after the player walks away —
-- this is the classic "remember explored tiles" pattern for dungeon crawlers.
-- (For a true shadow-casting FOV, replace this with a Bresenham ray-march.)
local function updateFOV()
    for dy = -VIEW_RADIUS, VIEW_RADIUS do
        for dx = -VIEW_RADIUS, VIEW_RADIUS do
            if dx * dx + dy * dy <= VIEW_RADIUS * VIEW_RADIUS then
                local tx, ty = player.x + dx, player.y + dy
                if inBounds(tx, ty) then revealed[ty][tx] = true end
            end
        end
    end
end

local function enemyAt(x, y)
    for i, e in ipairs(enemies) do if e.x == x and e.y == y then return i, e end end
    return nil, nil
end

local function tryMove(dx, dy)
    if gameOver then return end
    local nx, ny = player.x + dx, player.y + dy
    if not inBounds(nx, ny) then return end
    -- Check enemy
    local ei, enemy = enemyAt(nx, ny)
    if enemy then
        enemy.hp = enemy.hp - player.atk
        addMsg("You hit enemy for " .. player.atk .. " damage!")
        if enemy.hp <= 0 then
            table.remove(enemies, ei)
            player.kills = player.kills + 1
            addMsg("Enemy defeated!")
        end
    elseif map[ny][nx] ~= WALL then
        player.x = nx; player.y = ny
        -- Check stairs
        if map[ny][nx] == STAIRS then
            floor_num = floor_num + 1
            addMsg("Descended to floor " .. floor_num .. "!")
            generateDungeon()
        end
        -- Check pickups
        for i = #pickups, 1, -1 do
            local p = pickups[i]
            if p.x == player.x and p.y == player.y then
                player.hp = clamp(player.hp + p.amount, 0, player.maxHp)
                addMsg("Picked up health potion! +" .. p.amount .. " HP")
                table.remove(pickups, i)
            end
        end
    end
    -- Enemy turns
    for _, e in ipairs(enemies) do
        local dist = math.abs(e.x - player.x) + math.abs(e.y - player.y)
        if dist <= VIEW_RADIUS + 2 then
            local edx, edy = 0, 0
            if math.abs(player.x - e.x) > math.abs(player.y - e.y) then
                edx = player.x > e.x and 1 or -1
            else
                edy = player.y > e.y and 1 or -1
            end
            local enx, eny = e.x + edx, e.y + edy
            if enx == player.x and eny == player.y then
                player.hp = player.hp - e.atk
                addMsg("Enemy hits you for " .. e.atk .. " damage!")
                if player.hp <= 0 then gameOver = true; addMsg("You died on floor " .. floor_num .. "!") end
            elseif inBounds(enx, eny) and map[eny][enx] == FLOOR and not enemyAt(enx, eny) then
                e.x = enx; e.y = eny
            end
        end
    end
    turnCount = turnCount + 1
    updateFOV()
end

function lurek.init()
    lurek.window.setTitle("Roguelike Dungeon")
    lurek.gfx.setBackgroundColor(0.05, 0.05, 0.08)
    generateDungeon()
    updateFOV()
    addMsg("Find the stairs (>) to descend. Arrow keys to move.")
end

function lurek.process(dt) end

function lurek.render()
    local offsetX = 400 - player.x * TILE_SIZE
    local offsetY = 300 - player.y * TILE_SIZE
    -- Draw map
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local dx = x - player.x; local dy = y - player.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local visible = dist <= VIEW_RADIUS
            if revealed[y][x] then
                local bright = visible and 1.0 or 0.35
                local t = map[y][x]
                if t == WALL then
                    lurek.gfx.setColor(0.25 * bright, 0.22 * bright, 0.3 * bright)
                    lurek.gfx.rectangle("fill", offsetX + (x - 1) * TILE_SIZE, offsetY + (y - 1) * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
                elseif t == FLOOR then
                    lurek.gfx.setColor(0.12 * bright, 0.12 * bright, 0.15 * bright)
                    lurek.gfx.rectangle("fill", offsetX + (x - 1) * TILE_SIZE, offsetY + (y - 1) * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
                elseif t == STAIRS and visible then
                    lurek.gfx.setColor(0.1, 0.1, 0.15)
                    lurek.gfx.rectangle("fill", offsetX + (x - 1) * TILE_SIZE, offsetY + (y - 1) * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
                    lurek.gfx.setColor(1, 0.9, 0.3)
                    lurek.gfx.print(">", offsetX + (x - 1) * TILE_SIZE + 6, offsetY + (y - 1) * TILE_SIZE + 4)
                end
                -- Pickups
                if visible then
                    for _, p in ipairs(pickups) do
                        if p.x == x and p.y == y then
                            lurek.gfx.setColor(0.2, 0.9, 0.3)
                            lurek.gfx.circle("fill", offsetX + (x - 1) * TILE_SIZE + TILE_SIZE / 2, offsetY + (y - 1) * TILE_SIZE + TILE_SIZE / 2, 5)
                        end
                    end
                end
            end
        end
    end
    -- Draw enemies (only visible)
    for _, e in ipairs(enemies) do
        local dx = e.x - player.x; local dy = e.y - player.y
        if math.sqrt(dx * dx + dy * dy) <= VIEW_RADIUS then
            lurek.gfx.setColor(0.9, 0.2, 0.2)
            lurek.gfx.rectangle("fill", offsetX + (e.x - 1) * TILE_SIZE + 3, offsetY + (e.y - 1) * TILE_SIZE + 3, TILE_SIZE - 7, TILE_SIZE - 7)
            lurek.gfx.setColor(1, 1, 1)
            lurek.gfx.print("E", offsetX + (e.x - 1) * TILE_SIZE + 6, offsetY + (e.y - 1) * TILE_SIZE + 4)
        end
    end
    -- Draw player
    lurek.gfx.setColor(0.3, 0.7, 1)
    lurek.gfx.rectangle("fill", offsetX + (player.x - 1) * TILE_SIZE + 2, offsetY + (player.y - 1) * TILE_SIZE + 2, TILE_SIZE - 5, TILE_SIZE - 5)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("@", offsetX + (player.x - 1) * TILE_SIZE + 6, offsetY + (player.y - 1) * TILE_SIZE + 4)
    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.7); lurek.gfx.rectangle("fill", 0, 0, 800, 30)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("HP: " .. player.hp .. "/" .. player.maxHp .. "  Floor: " .. floor_num .. "  Kills: " .. player.kills .. "  Turn: " .. turnCount, 10, 8)
    -- HP bar
    lurek.gfx.setColor(0.3, 0.3, 0.3); lurek.gfx.rectangle("fill", 600, 8, 120, 14)
    lurek.gfx.setColor(0.8, 0.2, 0.2); lurek.gfx.rectangle("fill", 600, 8, 120 * (player.hp / player.maxHp), 14)
    -- Messages
    for i, msg in ipairs(messages) do
        lurek.gfx.setColor(1, 1, 0.8, 1.0 - (i - 1) * 0.2)
        lurek.gfx.print(msg, 10, 560 - (i - 1) * 16)
    end
    if gameOver then
        lurek.gfx.setColor(0, 0, 0, 0.75); lurek.gfx.rectangle("fill", 200, 220, 400, 120)
        lurek.gfx.setColor(1, 0.2, 0.2); lurek.gfx.print("YOU DIED", 330, 240, 2)
        lurek.gfx.setColor(1, 1, 1); lurek.gfx.print("Floor " .. floor_num .. " | Kills: " .. player.kills .. " | Turns: " .. turnCount, 280, 290)
        lurek.gfx.print("Press R to restart", 330, 315)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if gameOver then
        if key == "r" then
            floor_num = 1; turnCount = 0; gameOver = false; messages = {}
            generateDungeon(); updateFOV()
            addMsg("A new adventure begins...")
        end
        return
    end
    if key == "up" then tryMove(0, -1)
    elseif key == "down" then tryMove(0, 1)
    elseif key == "left" then tryMove(-1, 0)
    elseif key == "right" then tryMove(1, 0) end
end
