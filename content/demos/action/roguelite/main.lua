-- Roguelite Action Demo (Hades-style)
-- Real-time room-based combat with perks and boss fights
-- Controls: WASD to move, Left Click to attack, Shift to dash
-- Clear rooms, pick perks, fight bosses every 5 rooms
-- Run with: cargo run -- content/demos/action/roguelite

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local player = { x = 400, y = 300, w = 18, h = 18, speed = 180, hp = 100, maxHp = 100,
    atk = 12, atkRange = 40, atkCooldown = 0, atkDuration = 0, atkAngle = 0,
    dashSpeed = 500, dashing = false, dashTimer = 0, dashCooldown = 0, dashDir = { x = 0, y = 0 },
    iframes = 0, facing = 0, bonusAtk = 0, bonusSpeed = 0 }
local enemies = {}
local roomNum = 0
local roomCleared = false
local wavesLeft = 0
local waveTimer = 0
local state = "combat" -- combat, perkSelect, gameOver
local perks = {}
local perkOptions = {}
local score = 0
local bestScore = 0
local killCount = 0
local bossRoom = false

local ARENA_X, ARENA_Y, ARENA_W, ARENA_H = 80, 60, 640, 480

local perkPool = {
    { name = "+20 Max HP", apply = function() player.maxHp = player.maxHp + 20; player.hp = player.hp + 20 end },
    { name = "+5 Attack", apply = function() player.bonusAtk = player.bonusAtk + 5 end },
    { name = "+30 Speed", apply = function() player.bonusSpeed = player.bonusSpeed + 30 end },
    { name = "Heal 30 HP", apply = function() player.hp = clamp(player.hp + 30, 0, player.maxHp) end },
    { name = "+15 Max HP, +3 Atk", apply = function() player.maxHp = player.maxHp + 15; player.hp = player.hp + 15; player.bonusAtk = player.bonusAtk + 3 end },
    { name = "Fast Dash", apply = function() player.dashSpeed = player.dashSpeed + 100 end },
}

local function spawnEnemy(kind)
    local side = math.random(1, 4)
    local ex, ey
    if side == 1 then ex = ARENA_X + 20; ey = math.random(ARENA_Y + 20, ARENA_Y + ARENA_H - 20)
    elseif side == 2 then ex = ARENA_X + ARENA_W - 20; ey = math.random(ARENA_Y + 20, ARENA_Y + ARENA_H - 20)
    elseif side == 3 then ex = math.random(ARENA_X + 20, ARENA_X + ARENA_W - 20); ey = ARENA_Y + 20
    else ex = math.random(ARENA_X + 20, ARENA_X + ARENA_W - 20); ey = ARENA_Y + ARENA_H - 20 end
    local e = { x = ex, y = ey, w = 16, h = 16, speed = 60, hp = 8 + roomNum * 2, maxHp = 8 + roomNum * 2,
        atk = 5 + roomNum, atkCooldown = 0, kind = kind or "normal", hitTimer = 0 }
    if kind == "fast" then e.speed = 120; e.hp = 5 + roomNum; e.maxHp = e.hp; e.w = 12; e.h = 12
    elseif kind == "boss" then e.w = 36; e.h = 36; e.hp = 60 + roomNum * 15; e.maxHp = e.hp; e.atk = 15 + roomNum * 2; e.speed = 40 end
    enemies[#enemies + 1] = e
end

local function startRoom()
    roomNum = roomNum + 1
    enemies = {}
    roomCleared = false
    bossRoom = (roomNum % 5 == 0)
    if bossRoom then
        wavesLeft = 0; spawnEnemy("boss"); spawnEnemy("normal")
    else
        wavesLeft = math.random(1, 2)
        local count = 2 + math.floor(roomNum / 2)
        for _ = 1, count do
            spawnEnemy(math.random() > 0.6 and "fast" or "normal")
        end
    end
    waveTimer = 0
    player.x = ARENA_X + ARENA_W / 2; player.y = ARENA_Y + ARENA_H / 2
    state = "combat"
end

local function offerPerks()
    -- Present 3 randomly-chosen perks from the pool after each room is cleared.
    -- The loop draws without replacement (duplicate index check) so the same perk
    -- cannot appear twice in one offer — even if the pool is small.
    perkOptions = {}
    local indices = {}
    while #indices < 3 and #indices < #perkPool do
        local idx = math.random(1, #perkPool)
        local dupe = false
        for _, v in ipairs(indices) do if v == idx then dupe = true end end
        if not dupe then indices[#indices + 1] = idx end
    end
    for _, idx in ipairs(indices) do perkOptions[#perkOptions + 1] = perkPool[idx] end
    state = "perkSelect"
end

local function resetGame()
    player.hp = 100; player.maxHp = 100; player.bonusAtk = 0; player.bonusSpeed = 0; player.dashSpeed = 500
    roomNum = 0; score = 0; killCount = 0; perks = {}; enemies = {}
    startRoom()
end

function lurek.init()
    lurek.window.setTitle("Roguelite Action")
    lurek.gfx.setBackgroundColor(0.06, 0.05, 0.1)
    startRoom()
end

function lurek.process(dt)
    if state == "gameOver" or state == "perkSelect" then return end
    -- Player movement
    local mx, my = 0, 0
    if lurek.keyboard.isDown("w") then my = -1 end
    if lurek.keyboard.isDown("s") then my = 1 end
    if lurek.keyboard.isDown("a") then mx = -1 end
    if lurek.keyboard.isDown("d") then mx = 1 end
    local spd = player.speed + player.bonusSpeed
    -- Dash
    player.dashCooldown = clamp(player.dashCooldown - dt, 0, 9)
    player.iframes = clamp(player.iframes - dt, 0, 9)
    if player.dashing then
        player.dashTimer = player.dashTimer - dt
        player.x = player.x + player.dashDir.x * player.dashSpeed * dt
        player.y = player.y + player.dashDir.y * player.dashSpeed * dt
        if player.dashTimer <= 0 then player.dashing = false end
    else
        local len = math.sqrt(mx * mx + my * my)
        if len > 0 then mx = mx / len; my = my / len end
        player.x = player.x + mx * spd * dt
        player.y = player.y + my * spd * dt
    end
    player.x = clamp(player.x, ARENA_X + 4, ARENA_X + ARENA_W - player.w - 4)
    player.y = clamp(player.y, ARENA_Y + 4, ARENA_Y + ARENA_H - player.h - 4)
    -- Attack cooldown
    player.atkCooldown = clamp(player.atkCooldown - dt, 0, 9)
    player.atkDuration = clamp(player.atkDuration - dt, 0, 9)
    -- Attack hit detection: a circular hitbox emanates from the point in front of the
    -- player (offset by atkRange in the attack direction). Any enemy whose centre falls
    -- within atkRange of that point is hit. The `hitTimer` guard (0.2 s cooldown per
    -- enemy) prevents the same swing from hitting the same enemy multiple times.
    -- atkDuration is zeroed after the first frame of hit-detection so each click
    -- produces exactly one hit event (melee sweep, not sustained contact).
    if player.atkDuration > 0.08 then
        local ax = player.x + player.w / 2 + math.cos(player.atkAngle) * player.atkRange
        local ay = player.y + player.h / 2 + math.sin(player.atkAngle) * player.atkRange
        for _, e in ipairs(enemies) do
            local edx = ax - (e.x + e.w / 2)
            local edy = ay - (e.y + e.h / 2)
            if math.sqrt(edx * edx + edy * edy) < player.atkRange then
                if e.hitTimer <= 0 then
                    e.hp = e.hp - (player.atk + player.bonusAtk)
                    e.hitTimer = 0.2  -- brief immunity to prevent double-registration
                end
            end
        end
        player.atkDuration = 0 -- one swing = one hit; reset to avoid repeat checks
    end
    -- Enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e.hitTimer = clamp(e.hitTimer - dt, 0, 9)
        e.atkCooldown = clamp((e.atkCooldown or 0) - dt, 0, 9)
        -- Move toward player
        local edx = player.x - e.x; local edy = player.y - e.y
        local elen = math.sqrt(edx * edx + edy * edy)
        if elen > 1 then
            e.x = e.x + (edx / elen) * e.speed * dt
            e.y = e.y + (edy / elen) * e.speed * dt
        end
        e.x = clamp(e.x, ARENA_X + 2, ARENA_X + ARENA_W - e.w - 2)
        e.y = clamp(e.y, ARENA_Y + 2, ARENA_Y + ARENA_H - e.h - 2)
        -- Attack player on contact
        if player.iframes <= 0 and not player.dashing then
            local ox = math.abs((player.x + player.w / 2) - (e.x + e.w / 2))
            local oy = math.abs((player.y + player.h / 2) - (e.y + e.h / 2))
            if ox < (player.w + e.w) / 2 and oy < (player.h + e.h) / 2 and (e.atkCooldown or 0) <= 0 then
                player.hp = player.hp - e.atk
                player.iframes = 0.5
                e.atkCooldown = 1.0
                if player.hp <= 0 then
                    state = "gameOver"
                    if score > bestScore then bestScore = score end
                end
            end
        end
        -- Remove dead
        if e.hp <= 0 then
            table.remove(enemies, i)
            score = score + (e.kind == "boss" and 50 or 10)
            killCount = killCount + 1
        end
    end
    -- Wave spawning
    if #enemies == 0 and wavesLeft > 0 then
        wavesLeft = wavesLeft - 1
        local count = 2 + math.floor(roomNum / 3)
        for _ = 1, count do spawnEnemy(math.random() > 0.5 and "fast" or "normal") end
    end
    -- Room cleared
    if #enemies == 0 and wavesLeft <= 0 and not roomCleared then
        roomCleared = true
        offerPerks()
    end
end

function lurek.render()
    -- Arena
    lurek.gfx.setColor(0.1, 0.1, 0.15)
    lurek.gfx.rectangle("fill", ARENA_X, ARENA_Y, ARENA_W, ARENA_H)
    lurek.gfx.setColor(0.3, 0.25, 0.4)
    lurek.gfx.rectangle("line", ARENA_X, ARENA_Y, ARENA_W, ARENA_H)
    -- Door indicator
    if roomCleared then
        lurek.gfx.setColor(0.2, 0.8, 0.3, 0.7 + 0.3 * math.sin(lurek.time.getTime() * 4))
        lurek.gfx.rectangle("fill", ARENA_X + ARENA_W / 2 - 15, ARENA_Y - 8, 30, 10)
    end
    -- Enemies
    for _, e in ipairs(enemies) do
        if e.hitTimer > 0 then lurek.gfx.setColor(1, 1, 1)
        elseif e.kind == "boss" then lurek.gfx.setColor(0.8, 0.1, 0.6)
        elseif e.kind == "fast" then lurek.gfx.setColor(1, 0.6, 0.1)
        else lurek.gfx.setColor(0.9, 0.2, 0.2) end
        lurek.gfx.rectangle("fill", e.x, e.y, e.w, e.h)
        -- HP bar
        lurek.gfx.setColor(0.3, 0.3, 0.3); lurek.gfx.rectangle("fill", e.x, e.y - 6, e.w, 3)
        lurek.gfx.setColor(0.9, 0.2, 0.2); lurek.gfx.rectangle("fill", e.x, e.y - 6, e.w * (e.hp / e.maxHp), 3)
    end
    -- Player
    local blink = player.iframes > 0 and math.sin(lurek.time.getTime() * 25) > 0
    if not blink then
        if player.dashing then lurek.gfx.setColor(0.5, 0.8, 1, 0.7)
        else lurek.gfx.setColor(0.3, 0.8, 1) end
        lurek.gfx.rectangle("fill", player.x, player.y, player.w, player.h)
    end
    -- Attack arc
    if player.atkDuration > 0 then
        lurek.gfx.setColor(1, 1, 0.5, 0.6)
        local ax = player.x + player.w / 2 + math.cos(player.atkAngle) * 20
        local ay = player.y + player.h / 2 + math.sin(player.atkAngle) * 20
        lurek.gfx.circle("fill", ax, ay, player.atkRange * 0.6)
    end
    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.7); lurek.gfx.rectangle("fill", 0, 0, 800, 28)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("HP: " .. math.floor(player.hp) .. "/" .. player.maxHp .. "  Room: " .. roomNum .. "  Score: " .. score .. "  Kills: " .. killCount, 10, 6)
    -- HP bar
    lurek.gfx.setColor(0.2, 0.2, 0.2); lurek.gfx.rectangle("fill", 580, 6, 150, 16)
    lurek.gfx.setColor(0.1, 0.7, 0.3); lurek.gfx.rectangle("fill", 580, 6, 150 * clamp(player.hp / player.maxHp, 0, 1), 16)
    -- Room info
    if bossRoom and #enemies > 0 then
        lurek.gfx.setColor(1, 0.3, 0.6); lurek.gfx.print("!! BOSS !!", 370, 35, 1.5)
    end
    -- Perk selection
    if state == "perkSelect" then
        lurek.gfx.setColor(0, 0, 0, 0.8); lurek.gfx.rectangle("fill", 150, 180, 500, 220)
        lurek.gfx.setColor(1, 0.9, 0.3); lurek.gfx.print("ROOM CLEARED! Choose a perk:", 250, 200, 1.2)
        for i, p in ipairs(perkOptions) do
            local bx, by = 180, 230 + (i - 1) * 50
            lurek.gfx.setColor(0.2, 0.2, 0.3); lurek.gfx.rectangle("fill", bx, by, 440, 40)
            lurek.gfx.setColor(0.3, 0.4, 0.6); lurek.gfx.rectangle("line", bx, by, 440, 40)
            lurek.gfx.setColor(1, 1, 1); lurek.gfx.print("[" .. i .. "] " .. p.name, bx + 15, by + 12)
        end
    end
    -- Game over
    if state == "gameOver" then
        lurek.gfx.setColor(0, 0, 0, 0.85); lurek.gfx.rectangle("fill", 0, 0, 800, 600)
        lurek.gfx.setColor(1, 0.2, 0.2); lurek.gfx.print("GAME OVER", 300, 220, 2.5)
        lurek.gfx.setColor(1, 1, 1); lurek.gfx.print("Score: " .. score .. "  |  Best: " .. bestScore .. "  |  Rooms: " .. roomNum, 240, 310, 1.2)
        lurek.gfx.print("Press R to restart", 320, 360)
    end
    lurek.gfx.setColor(0.5, 0.5, 0.5); lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 730, 580)
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if state == "gameOver" and key == "r" then resetGame(); return end
    if state == "perkSelect" then
        local idx = tonumber(key)
        if idx and idx >= 1 and idx <= #perkOptions then
            perkOptions[idx].apply()
            perks[#perks + 1] = perkOptions[idx].name
            startRoom()
        end
        return
    end
    if (key == "lshift" or key == "rshift") and not player.dashing and player.dashCooldown <= 0 then
        local dx, dy = 0, 0
        if lurek.keyboard.isDown("w") then dy = -1 end
        if lurek.keyboard.isDown("s") then dy = 1 end
        if lurek.keyboard.isDown("a") then dx = -1 end
        if lurek.keyboard.isDown("d") then dx = 1 end
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then dx = dx / len; dy = dy / len else dx = 1 end
        player.dashing = true; player.dashTimer = 0.15; player.dashCooldown = 0.6
        player.dashDir = { x = dx, y = dy }; player.iframes = 0.2
    end
end

function lurek.mousepressed(mx, my, button)
    if state ~= "combat" then return end
    if button == 1 and player.atkCooldown <= 0 then
        player.atkAngle = math.atan2(my - (player.y + player.h / 2), mx - (player.x + player.w / 2))
        player.atkCooldown = 0.3; player.atkDuration = 0.15
    end
end
