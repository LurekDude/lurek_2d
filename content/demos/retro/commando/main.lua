-- Commando — C-64 Classic (Lurek2D demo)
-- Vertical-scrolling top-down shooter inspired by Capcom's 1985 arcade classic.
-- Shoot enemies, rescue POWs, and advance through the jungle level.
-- Run with: cargo run -- content/demos/retro/commando

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local SCROLL_SPEED = 60
local PLAYER_SPEED = 160
local BULLET_SPEED = 400
local ENEMY_SPAWN_RATE = 1.8
local GRENADE_RADIUS = 60

-- ── Tone palettes ─────────────────────────────────────────────────────────

local JUNGLE_TILES = { {0.12,0.28,0.08}, {0.08,0.22,0.05}, {0.18,0.35,0.1}, {0.1,0.3,0.07} }

-- ── State ─────────────────────────────────────────────────────────────────

local player = {}
local bullets = {}
local grenades = {}
local enemies = {}
local pows  = {}
local world_y = 0
local score, lives, grenades_left = 0, 3, 3
local game_state = "playing"
local shoot_cd = 0
local enemy_timer = 0
local pow_timer = 6
local anim_timer = 0
local distance = 0

-- Procgen ground tiles (background grass pattern)
local tiles = {}
math.randomseed(42)
for i = 1, 80 do
    tiles[i] = {
        x = math.random(W),
        y = math.random(-200, H + 200),
        w = 8 + math.random(16), h = 6 + math.random(10),
        c = JUNGLE_TILES[math.random(#JUNGLE_TILES)]
    }
end
math.randomseed(os.time())

-- ── Helpers ──────────────────────────────────────────────────────────────

local function reset()
    player = { x = W/2 - 12, y = H - 80, w = 24, h = 32 }
    bullets = {}; grenades = {}; enemies = {}; pows = {}
    world_y = 0; shoot_cd = 0; enemy_timer = 0; pow_timer = 6
    game_state = "playing"; distance = 0
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.08, 0.18, 0.05)
    score = 0; lives = 3; grenades_left = 3
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end

    anim_timer = anim_timer + dt
    shoot_cd = math.max(0, shoot_cd - dt)
    distance = distance + SCROLL_SPEED * dt
    world_y = world_y + SCROLL_SPEED * dt

    -- Player movement
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a") then
        player.x = math.max(10, player.x - PLAYER_SPEED * dt)
    end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then
        player.x = math.min(W - player.w - 10, player.x + PLAYER_SPEED * dt)
    end
    if lurek.input.isKeyDown("up") or lurek.input.isKeyDown("w") then
        player.y = math.max(H * 0.3, player.y - PLAYER_SPEED * dt)
    end
    if lurek.input.isKeyDown("down") or lurek.input.isKeyDown("s") then
        player.y = math.min(H - player.h - 10, player.y + PLAYER_SPEED * dt)
    end

    -- Player bullets
    for i = #bullets, 1, -1 do
        bullets[i].y = bullets[i].y - BULLET_SPEED * dt
        if bullets[i].y < 0 then table.remove(bullets, i) end
    end

    -- Grenades
    for i = #grenades, 1, -1 do
        local g = grenades[i]
        g.timer = g.timer - dt
        g.x = g.x + g.vx * dt
        g.y = g.y - 60 * dt + 120 * (1 - g.timer / 0.8)
        if g.timer <= 0 then
            -- Explosion
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                local dx = (e.x + e.w/2) - g.x
                local dy = (e.y + e.h/2) - g.y
                if dx*dx + dy*dy < GRENADE_RADIUS * GRENADE_RADIUS then
                    table.remove(enemies, j)
                    score = score + 150
                end
            end
            table.remove(grenades, i)
        end
    end

    -- Enemy spawning
    enemy_timer = enemy_timer - dt
    if enemy_timer <= 0 then
        enemy_timer = ENEMY_SPAWN_RATE - math.min(1.4, distance / 3000)
        local side = math.random(3)  -- 1=left, 2=right, 3=top
        local ex = side == 1 and 10 or (side == 2 and W - 30 or math.random(50, W - 50))
        local ey = side == 3 and -40 or math.random(H * 0.1, H * 0.5)
        enemies[#enemies+1] = {
            x = ex, y = ey, w = 22, h = 28,
            vx = (player.x - ex) / (1.5 + math.random()),
            vy = (player.y - ey) / (1.5 + math.random()),
            shoot_cd = 1 + math.random()
        }
    end

    -- POW spawning
    pow_timer = pow_timer - dt
    if pow_timer <= 0 then
        pow_timer = 8 + math.random() * 6
        pows[#pows+1] = { x = math.random(30, W - 60), y = -30, w = 20, h = 24, alive = true }
    end

    -- Enemy movement & shooting
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        -- Move toward player
        local dx = player.x + player.w/2 - (e.x + e.w/2)
        local dy = player.y + player.h/2 - (e.y + e.h/2)
        local dist = math.sqrt(dx*dx + dy*dy)
        local spd = 50 + distance / 200
        if dist > 5 then
            e.x = e.x + (dx / dist) * spd * dt
            e.y = e.y + (dy / dist) * spd * dt
        end
        e.shoot_cd = e.shoot_cd - dt
        if e.shoot_cd <= 0 and dist < 350 then
            e.shoot_cd = 1.5 + math.random()
            bullets[#bullets+1] = {
                x = e.x + e.w/2, y = e.y + e.h/2,
                vx = (dx / dist) * 180, vy = (dy / dist) * 180,
                enemy = true, w = 5, h = 8
            }
        end
        -- Scroll with world
        e.y = e.y + SCROLL_SPEED * dt
        -- Remove if off screen low
        if e.y > H + 50 then table.remove(enemies, i) end
    end

    -- Enemy bullets movement
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.enemy then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if b.y > H or b.y < 0 or b.x < 0 or b.x > W then
                table.remove(bullets, i)
            end
        end
    end

    -- POWs scroll
    for i = #pows, 1, -1 do
        local p = pows[i]
        p.y = p.y + SCROLL_SPEED * dt
        if p.y > H + 40 then table.remove(pows, i)
        elseif p.alive then
            -- Player picks up POW
            if player.x < p.x + p.w and player.x + player.w > p.x and
               player.y < p.y + p.h and player.y + player.h > p.y then
                p.alive = false; score = score + 500; lives = lives + 1
            end
        end
    end

    -- Bullet vs enemy
    for bi = #bullets, 1, -1 do
        if not bullets[bi] or bullets[bi].enemy then goto cont end
        local b = bullets[bi]
        for ei = #enemies, 1, -1 do
            local e = enemies[ei]
            if b.x > e.x and b.x < e.x + e.w and b.y > e.y and b.y < e.y + e.h then
                table.remove(enemies, ei)
                table.remove(bullets, bi)
                score = score + 100
                break
            end
        end
        ::cont::
    end

    -- Enemy bullet or enemy vs player
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then break end
        local b = bullets[bi]
        if b.enemy and b.x > player.x and b.x < player.x + player.w and
           b.y > player.y and b.y < player.y + player.h then
            table.remove(bullets, bi)
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" else reset() end
            return
        end
    end
    for _, e in ipairs(enemies) do
        if e.x < player.x + player.w - 4 and e.x + e.w > player.x + 4 and
           e.y < player.y + player.h - 4 and e.y + e.h > player.y + 4 then
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" else reset() end
            return
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Background jungle tiles (scroll with world)
    for _, t in ipairs(tiles) do
        local sy = (t.y + world_y) % (H + 200) - 50
        lurek.gfx.setColor(t.c[1], t.c[2], t.c[3])
        lurek.gfx.rectangle("fill", t.x, sy, t.w, t.h)
    end

    -- Road stripe
    lurek.gfx.setColor(0.4, 0.35, 0.2, 0.3)
    local roffset = world_y % 60
    for ry = -roffset, H, 60 do
        lurek.gfx.rectangle("fill", W/2 - 20, ry, 40, 30)
    end

    -- POWs
    for _, p in ipairs(pows) do
        if p.alive then
            lurek.gfx.setColor(1, 0.8, 0.1)
            lurek.gfx.rectangle("fill", p.x, p.y, p.w, p.h)
            lurek.gfx.setColor(0, 0, 0)
            lurek.gfx.print("POW", p.x + 1, p.y + 6, 1.1)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        lurek.gfx.setColor(0.6, 0.2, 0.1)
        lurek.gfx.rectangle("fill", e.x + 2, e.y + 8, e.w - 4, e.h - 8)
        lurek.gfx.setColor(0.75, 0.55, 0.35)
        lurek.gfx.circle("fill", e.x + e.w/2, e.y + 8, 9)
        lurek.gfx.setColor(0.4, 0.2, 0)
        lurek.gfx.rectangle("fill", e.x, e.y, e.w, 7)
    end

    -- Enemy bullets
    lurek.gfx.setColor(1, 0.4, 0.1)
    for _, b in ipairs(bullets) do
        if b.enemy then
            lurek.gfx.rectangle("fill", b.x - 2, b.y - 4, b.w, b.h)
        end
    end

    -- Player
    lurek.gfx.setColor(0.2, 0.35, 0.7)
    lurek.gfx.rectangle("fill", player.x + 4, player.y + 10, player.w - 8, player.h - 10)
    lurek.gfx.setColor(0.85, 0.65, 0.4)
    lurek.gfx.circle("fill", player.x + player.w/2, player.y + 10, 11)
    lurek.gfx.setColor(0.3, 0.3, 0.1)
    lurek.gfx.rectangle("fill", player.x, player.y, player.w, 8)
    -- Gun
    lurek.gfx.setColor(0.4, 0.4, 0.4)
    lurek.gfx.rectangle("fill", player.x + player.w/2 - 2, player.y - 10, 4, 14)

    -- Player bullets
    lurek.gfx.setColor(1, 1, 0.4)
    for _, b in ipairs(bullets) do
        if not b.enemy then
            lurek.gfx.rectangle("fill", b.x - 2, b.y, 4, 12)
        end
    end

    -- Grenades
    lurek.gfx.setColor(0, 0.8, 0.1)
    for _, g in ipairs(grenades) do
        lurek.gfx.circle("fill", g.x, g.y, 8)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.55)
    lurek.gfx.rectangle("fill", 0, 0, W, 28)
    lurek.gfx.setColor(0.9, 0.8, 0.2)
    lurek.gfx.print("COMMANDO", 8, 5, 1.8)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Score: " .. score, W/2 - 50, 5, 1.6)
    lurek.gfx.setColor(1, 0.4, 0.4)
    lurek.gfx.print("Lives: " .. lives, W - 100, 5, 1.5)
    lurek.gfx.setColor(0.4, 1, 0.4)
    lurek.gfx.print("Grenades: " .. grenades_left, W/2 + 60, 5, 1.5)

    -- Overlay
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.72)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(1, 0.2, 0.2)
        lurek.gfx.print("MISSION FAILED", W/2 - 110, H/2 - 25, 3)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if game_state ~= "playing" then return end
    if key == "space" and shoot_cd <= 0 then
        bullets[#bullets+1] = { x = player.x + player.w/2, y = player.y - 10, enemy = false }
        shoot_cd = 0.22
    end
    if key == "z" and grenades_left > 0 then
        grenades_left = grenades_left - 1
        grenades[#grenades+1] = {
            x = player.x + player.w/2, y = player.y,
            vx = (math.random() - 0.5) * 100,
            timer = 0.8
        }
    end
end
