-- Galaga — Classic Arcade (Luna2D demo)
-- Destroy the insect fleet as they swoop down in diving attack patterns.
-- Left/Right to move, Space to shoot. Each cleared wave increases speed.
-- Run with: cargo run -- demos/arcade/galaga

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local PLAYER_SPEED = 300
local BULLET_SPEED = 500
local ENEMY_COLS, ENEMY_ROWS = 10, 4
local ENEMY_W, ENEMY_H = 42, 34
local DIVE_SPEED = 220
local MAX_BULLETS = 2

-- ── State ────────────────────────────────────────────────────────────────

local player = {}
local bullets = {}
local enemies = {}
local enemy_bullets = {}
local score, lives, wave = 0, 3, 1
local shoot_cd = 0
local game_state = "playing"
local anim_timer = 0
local enemy_shoot_timer = 1.0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function init_wave()
    enemies = {}
    local base_x = (W - ENEMY_COLS * (ENEMY_W + 6)) / 2
    local base_y = 60
    for row = 1, ENEMY_ROWS do
        for col = 1, ENEMY_COLS do
            local ex = base_x + (col-1) * (ENEMY_W + 6)
            local ey = base_y + (row-1) * (ENEMY_H + 6)
            enemies[#enemies+1] = {
                x = ex, y = ey,
                home_x = ex, home_y = ey,
                alive = true,
                row = row,
                -- Dive state
                diving = false,
                dive_x = 0, dive_y = 0,
                dive_vx = 0, dive_vy = 0,
                dive_phase = 0,
                dive_timer = math.random() * 4,
            }
        end
    end
    bullets = {}
    enemy_bullets = {}
    enemy_shoot_timer = 1.5
    game_state = "playing"
end

local function reset()
    player = { x = W/2 - 16, y = H - 70, w = 32, h = 24 }
    score = 0; lives = 3; wave = 1
    init_wave()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0, 0, 0.05)
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.process(dt)
    if game_state ~= "playing" then return end
    anim_timer = anim_timer + dt
    shoot_cd = math.max(0, shoot_cd - dt)

    -- Player movement
    if luna.input.isKeyDown("left") or luna.input.isKeyDown("a") then
        player.x = math.max(0, player.x - PLAYER_SPEED * dt)
    end
    if luna.input.isKeyDown("right") or luna.input.isKeyDown("d") then
        player.x = math.min(W - player.w, player.x + PLAYER_SPEED * dt)
    end

    -- Player bullets
    for i = #bullets, 1, -1 do
        bullets[i].y = bullets[i].y - BULLET_SPEED * dt
        if bullets[i].y < 0 then table.remove(bullets, i) end
    end

    -- Enemy bullets
    for i = #enemy_bullets, 1, -1 do
        local eb = enemy_bullets[i]
        eb.x = eb.x + eb.vx * dt
        eb.y = eb.y + eb.vy * dt
        if eb.y > H then table.remove(enemy_bullets, i) end
    end

    -- Count alive enemies
    local alive_list = {}
    for _, e in ipairs(enemies) do
        if e.alive then alive_list[#alive_list+1] = e end
    end
    if #alive_list == 0 then
        wave = wave + 1
        init_wave()
        return
    end

    -- Enemy movement and dive
    local wave_speed = 1 + (wave - 1) * 0.15
    for _, e in ipairs(enemies) do
        if not e.alive then goto continue end
        if e.diving then
            e.dive_phase = e.dive_phase + dt
            -- Sine-wave path
            e.x = e.dive_x + math.sin(e.dive_phase * 3) * 80
            e.y = e.y + DIVE_SPEED * wave_speed * dt
            -- Return to formation when off screen
            if e.y > H + 20 then
                e.x = e.home_x; e.y = e.home_y
                e.diving = false
                e.dive_timer = 2 + math.random() * 3
            end
        else
            -- Formation sway
            e.x = e.home_x + math.sin(anim_timer * 0.8 + e.home_x * 0.015) * 18
            -- Decide to dive
            e.dive_timer = e.dive_timer - dt
            if e.dive_timer <= 0 then
                e.diving = true
                e.dive_x = e.x
                e.dive_phase = 0
            end
        end
        ::continue::
    end

    -- Enemy shooting
    enemy_shoot_timer = enemy_shoot_timer - dt
    if enemy_shoot_timer <= 0 and #alive_list > 0 then
        enemy_shoot_timer = 0.8 + math.random() * 1.2
        local shooter = alive_list[math.random(#alive_list)]
        local angle = math.atan2(player.y - shooter.y, player.x - shooter.x)
        enemy_bullets[#enemy_bullets+1] = {
            x = shooter.x + ENEMY_W/2,
            y = shooter.y + ENEMY_H,
            vx = math.cos(angle) * 200,
            vy = math.sin(angle) * 220,
            w = 5, h = 10
        }
    end

    -- Bullet vs enemy
    for bi = #bullets, 1, -1 do
        local b = bullets[bi]
        for _, e in ipairs(enemies) do
            if e.alive and b.x > e.x and b.x < e.x + ENEMY_W and
               b.y > e.y and b.y < e.y + ENEMY_H then
                e.alive = false
                table.remove(bullets, bi)
                score = score + (e.diving and 160 or (e.row == 1 and 80 or 50))
                break
            end
        end
    end

    -- Enemy bullet vs player
    for bi = #enemy_bullets, 1, -1 do
        if not enemy_bullets[bi] then break end
        local eb = enemy_bullets[bi]
        if eb.x < player.x + player.w and eb.x + eb.w > player.x and
           eb.y < player.y + player.h and eb.y + eb.h > player.y then
            table.remove(enemy_bullets, bi)
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" end
        end
    end

    -- Enemy collision with player
    for _, e in ipairs(alive_list) do
        if e.diving and e.x < player.x + player.w and e.x + ENEMY_W > player.x and
           e.y < player.y + player.h and e.y + ENEMY_H > player.y then
            e.alive = false
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.render()
    -- Stars
    math.randomseed(99)
    for i = 1, 100 do
        local blink = (math.sin(anim_timer * 3 + i) + 1) / 2
        luna.gfx.setColor(blink, blink, blink, 0.5)
        luna.gfx.circle("fill", math.random(W), math.random(H), 1)
    end
    math.randomseed(os.time())

    -- HUD
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("GALAGA", W/2 - 35, 5, 2)
    luna.gfx.setColor(0.8, 0.9, 1)
    luna.gfx.print("Score: " .. score, 8, 8, 1.5)
    luna.gfx.setColor(1, 0.4, 0.4)
    luna.gfx.print("Lives: " .. lives, W - 100, 8, 1.5)
    luna.gfx.setColor(0.6, 0.6, 0.8)
    luna.gfx.print("Wave " .. wave, W - 80, H - 20, 1.5)

    -- Player ship
    luna.gfx.setColor(0.4, 0.8, 1.0)
    -- Fuselage
    luna.gfx.rectangle("fill", player.x + 10, player.y, 12, player.h)
    -- Wings
    luna.gfx.rectangle("fill", player.x, player.y + 10, player.w, 10)
    -- Cockpit
    luna.gfx.setColor(0.8, 1.0, 1.0)
    luna.gfx.circle("fill", player.x + player.w/2, player.y + 6, 5)

    -- Enemy bullets
    luna.gfx.setColor(1, 0.5, 0.1)
    for _, eb in ipairs(enemy_bullets) do
        luna.gfx.rectangle("fill", eb.x, eb.y, eb.w, eb.h)
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local pulsate = 0.7 + math.sin(anim_timer * 4 + e.home_x) * 0.3
            if e.row == 1 then
                luna.gfx.setColor(0.9 * pulsate, 0.2, 0.8 * pulsate)
            elseif e.row == 2 then
                luna.gfx.setColor(0.1, 0.8 * pulsate, 0.9 * pulsate)
            else
                luna.gfx.setColor(0.8 * pulsate, 0.8 * pulsate, 0.1)
            end
            -- Wing/body shape
            luna.gfx.rectangle("fill", e.x + 4, e.y + 6, ENEMY_W - 8, ENEMY_H - 12)
            luna.gfx.rectangle("fill", e.x, e.y + 14, ENEMY_W, 10)
            -- Antennae
            luna.gfx.line(e.x + ENEMY_W/2 - 6, e.y + 6, e.x + ENEMY_W/2 - 12, e.y)
            luna.gfx.line(e.x + ENEMY_W/2 + 6, e.y + 6, e.x + ENEMY_W/2 + 12, e.y)
        end
    end

    -- Player bullets
    luna.gfx.setColor(0.9, 1, 0.5)
    for _, b in ipairs(bullets) do
        luna.gfx.rectangle("fill", b.x, b.y, 4, 14)
    end

    -- Overlay
    if game_state == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.2, 0.2)
        luna.gfx.print("GAME OVER", W/2 - 80, H/2 - 30, 3)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Score: " .. score, W/2 - 50, H/2 + 10, 2)
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to restart", W/2 - 100, H/2 + 45, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then reset() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "z") and shoot_cd <= 0 and #bullets < MAX_BULLETS then
        bullets[#bullets+1] = { x = player.x + player.w/2 - 2, y = player.y - 4, w = 4, h = 14 }
        shoot_cd = 0.2
    end
end
