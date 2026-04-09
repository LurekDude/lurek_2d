-- Metroidvania Exploration Demo
-- Side-scrolling platformer with multiple rooms, abilities, and enemies
-- Controls: WASD/Arrows to move, Space to jump, Shift to dash (when unlocked)
-- Collect items to unlock abilities. Explore all rooms!
-- Run with: cargo run -- demos/action/metroidvania

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local player = { x = 100, y = 200, w = 16, h = 24, vx = 0, vy = 0, speed = 150, jumpForce = -350,
    grounded = false, hp = 5, maxHp = 5, hasDash = false, dashing = false, dashTimer = 0, dashCooldown = 0,
    facing = 1, invincible = 0 }
local gravity = 800
local roomW, roomH = 320, 240
local currentRoom = { x = 0, y = 0 }
local visited = {}
local items = {}
local enemies = {}
local camera = nil
local tileSize = 16
local gameOver = false
local score = 0

-- Room layouts: 1=solid, 2=platform, 3=dash-gate, 4=item(dash), 5=hp-item, 6=enemy-spawn
local roomData = {
    ["0,0"]  = { tiles = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,0,0,0,0,0,2,2,2,2,0,0,0,2,2,2,0,0,0,0},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    }},
    ["1,0"]  = { tiles = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,1},
        {0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,2,2,2,2,2,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    }},
    ["0,-1"] = { tiles = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,3,3,3,0,0,2,2,2,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    }},
}

local function roomKey(rx, ry) return rx .. "," .. ry end

local function loadRoom(rx, ry)
    local key = roomKey(rx, ry)
    visited[key] = true
    items = {}
    enemies = {}
    local rd = roomData[key]
    if not rd then return end
    for row = 1, #rd.tiles do
        for col = 1, #rd.tiles[row] do
            local v = rd.tiles[row][col]
            local wx, wy = (col - 1) * tileSize, (row - 1) * tileSize
            if v == 4 then items[#items + 1] = { x = wx, y = wy, w = 12, h = 12, kind = "dash", alive = true }
            elseif v == 5 then items[#items + 1] = { x = wx, y = wy, w = 10, h = 10, kind = "hp", alive = true }
            elseif v == 6 then enemies[#enemies + 1] = { x = wx, y = wy + 4, w = 14, h = 14, vx = 40, hp = 2, alive = true }
            end
        end
    end
end

local function getTile(rx, ry, col, row)
    local rd = roomData[roomKey(rx, ry)]
    if not rd or row < 1 or row > #rd.tiles or col < 1 or col > #rd.tiles[1] then return 1 end
    return rd.tiles[row][col]
end

local function isSolid(rx, ry, px, py, pw, ph)
    local c1 = math.floor(px / tileSize) + 1
    local c2 = math.floor((px + pw - 1) / tileSize) + 1
    local r1 = math.floor(py / tileSize) + 1
    local r2 = math.floor((py + ph - 1) / tileSize) + 1
    for r = r1, r2 do
        for c = c1, c2 do
            local t = getTile(rx, ry, c, r)
            if t == 1 or t == 2 or (t == 3 and not player.hasDash) then return true end
        end
    end
    return false
end

function luna.init()
    luna.window.setTitle("Metroidvania Exploration")
    luna.gfx.setBackgroundColor(0.08, 0.06, 0.12)
    camera = luna.camera.new(800, 600)
    camera:setZoom(2.5)
    loadRoom(0, 0)
end

function luna.process(dt)
    if gameOver then return end
    player.invincible = clamp(player.invincible - dt, 0, 9)
    -- Movement
    player.vx = 0
    if luna.keyboard.isDown("a") or luna.keyboard.isDown("left") then player.vx = -player.speed; player.facing = -1 end
    if luna.keyboard.isDown("d") or luna.keyboard.isDown("right") then player.vx = player.speed; player.facing = 1 end
    -- Dash
    player.dashCooldown = clamp(player.dashCooldown - dt, 0, 9)
    if player.dashing then
        player.dashTimer = player.dashTimer - dt
        player.vx = player.facing * 400
        player.vy = 0
        if player.dashTimer <= 0 then player.dashing = false end
    else
        player.vy = player.vy + gravity * dt
    end
    -- Move X
    local nx = player.x + player.vx * dt
    if not isSolid(currentRoom.x, currentRoom.y, nx, player.y, player.w, player.h) then player.x = nx end
    -- Move Y
    local ny = player.y + player.vy * dt
    player.grounded = false
    if isSolid(currentRoom.x, currentRoom.y, player.x, ny, player.w, player.h) then
        if player.vy > 0 then player.grounded = true end
        player.vy = 0
    else
        player.y = ny
    end
    -- Room transitions
    if player.x + player.w > roomW then currentRoom.x = currentRoom.x + 1; player.x = 2; loadRoom(currentRoom.x, currentRoom.y)
    elseif player.x < 0 then currentRoom.x = currentRoom.x - 1; player.x = roomW - player.w - 2; loadRoom(currentRoom.x, currentRoom.y)
    elseif player.y + player.h > roomH then currentRoom.y = currentRoom.y + 1; player.y = 2; loadRoom(currentRoom.x, currentRoom.y)
    elseif player.y < 0 then currentRoom.y = currentRoom.y - 1; player.y = roomH - player.h - 2; loadRoom(currentRoom.x, currentRoom.y) end
    -- Items
    for _, it in ipairs(items) do
        if it.alive and player.x < it.x + it.w and player.x + player.w > it.x and player.y < it.y + it.h and player.y + player.h > it.y then
            it.alive = false; score = score + 1
            if it.kind == "dash" then player.hasDash = true end
            if it.kind == "hp" then player.hp = clamp(player.hp + 1, 0, player.maxHp) end
        end
    end
    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            e.x = e.x + e.vx * dt
            local ec = math.floor(e.x / tileSize) + 1
            local er = math.floor((e.y + e.h) / tileSize) + 1
            if isSolid(currentRoom.x, currentRoom.y, e.x + (e.vx > 0 and e.w or -2), e.y, 2, e.h) then e.vx = -e.vx end
            -- hit player
            if player.invincible <= 0 and not player.dashing and player.x < e.x + e.w and player.x + player.w > e.x and player.y < e.y + e.h and player.y + player.h > e.y then
                player.hp = player.hp - 1; player.invincible = 1
                if player.hp <= 0 then gameOver = true end
            end
        end
    end
end

-- Polyfill: camera:apply()/reset() via graphics transform stack
local function camera_apply()
    local x, y = camera:getPosition()
    local z    = camera:getZoom()
    luna.gfx.push()
    luna.gfx.scale(z, z)
    luna.gfx.translate(-x, -y)
end
local function camera_reset()
    luna.gfx.pop()
end

function luna.render()
    camera:setPosition(player.x - 120, player.y - 80)
    camera_apply()
    -- Draw room tiles
    local rd = roomData[roomKey(currentRoom.x, currentRoom.y)]
    if rd then
        for row = 1, #rd.tiles do
            for col = 1, #rd.tiles[row] do
                local v = rd.tiles[row][col]
                local tx, ty = (col - 1) * tileSize, (row - 1) * tileSize
                if v == 1 then luna.gfx.setColor(0.3, 0.25, 0.4); luna.gfx.rectangle("fill", tx, ty, tileSize, tileSize)
                elseif v == 2 then luna.gfx.setColor(0.4, 0.5, 0.3); luna.gfx.rectangle("fill", tx, ty, tileSize, 4)
                elseif v == 3 then
                    if player.hasDash then luna.gfx.setColor(0.2, 0.2, 0.2, 0.3) else luna.gfx.setColor(0.8, 0.2, 0.2) end
                    luna.gfx.rectangle("fill", tx, ty, tileSize, tileSize)
                end
            end
        end
    end
    -- Items
    for _, it in ipairs(items) do
        if it.alive then
            if it.kind == "dash" then luna.gfx.setColor(0.2, 0.8, 1) else luna.gfx.setColor(0, 1, 0.4) end
            luna.gfx.rectangle("fill", it.x + 2, it.y + 2, it.w, it.h)
        end
    end
    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then luna.gfx.setColor(0.9, 0.2, 0.2); luna.gfx.rectangle("fill", e.x, e.y, e.w, e.h) end
    end
    -- Player
    local blink = player.invincible > 0 and math.sin(luna.time.getTime() * 20) > 0
    if not blink then
        if player.dashing then luna.gfx.setColor(0.5, 0.8, 1) else luna.gfx.setColor(0.3, 0.9, 0.4) end
        luna.gfx.rectangle("fill", player.x, player.y, player.w, player.h)
        -- Eyes
        luna.gfx.setColor(1, 1, 1)
        local ex = player.facing > 0 and player.x + 9 or player.x + 3
        luna.gfx.rectangle("fill", ex, player.y + 5, 4, 4)
    end
    camera_reset()
    -- HUD
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("HP: " .. player.hp .. "/" .. player.maxHp, 10, 10)
    luna.gfx.print("Room: " .. currentRoom.x .. "," .. currentRoom.y, 10, 26)
    luna.gfx.print("Score: " .. score, 10, 42)
    if player.hasDash then luna.gfx.setColor(0.2, 0.8, 1); luna.gfx.print("[DASH]", 10, 58) end
    -- Minimap
    luna.gfx.setColor(0, 0, 0, 0.6)
    luna.gfx.rectangle("fill", 700, 10, 80, 80)
    for key, _ in pairs(visited) do
        local parts = {}; for p in key:gmatch("[^,]+") do parts[#parts + 1] = tonumber(p) end
        local mx = 740 + parts[1] * 18
        local my = 50 + parts[2] * 18
        if parts[1] == currentRoom.x and parts[2] == currentRoom.y then luna.gfx.setColor(0.3, 0.9, 0.4)
        else luna.gfx.setColor(0.5, 0.5, 0.6) end
        luna.gfx.rectangle("fill", mx, my, 14, 14)
    end
    if gameOver then
        luna.gfx.setColor(0, 0, 0, 0.7); luna.gfx.rectangle("fill", 0, 0, 800, 600)
        luna.gfx.setColor(1, 0.2, 0.2); luna.gfx.print("GAME OVER - Press R to restart", 260, 280, 1.5)
    end
    luna.gfx.setColor(0.5, 0.5, 0.5); luna.gfx.print("FPS: " .. luna.time.getFPS(), 700, 580)
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if gameOver and key == "r" then
        player.x = 100; player.y = 200; player.hp = 5; player.hasDash = false; player.vx = 0; player.vy = 0
        currentRoom = { x = 0, y = 0 }; visited = {}; score = 0; gameOver = false; loadRoom(0, 0)
    end
    if not gameOver then
        if key == "space" and player.grounded then player.vy = player.jumpForce; player.grounded = false end
        if (key == "lshift" or key == "rshift") and player.hasDash and not player.dashing and player.dashCooldown <= 0 then
            player.dashing = true; player.dashTimer = 0.15; player.dashCooldown = 0.8
        end
    end
end
