-- Vertical Climber: Doodle Jump-style procedural platformer
-- A/D to move, auto-bounce on platforms, avoid enemies
-- Run with: cargo run -- content/demos/action/vertical_climber

local function lerp(a, b, t) return a + (b - a) * t end

local SCREEN_W, SCREEN_H = 800, 600
local PLAYER_W, PLAYER_H = 24, 24
local PLAT_W, PLAT_H = 70, 12
local GRAVITY = 600
local JUMP_VEL = -420
local SPRING_VEL = -650
local MOVE_SPEED = 350

local player = {}
local platforms = {}
local enemies = {}
local springs = {}
local camera_y = 0
local score = 0
local high_score = 0
local game_over = false
local next_plat_y = 0

local NORMAL, MOVING, CRUMBLING = 1, 2, 3
local plat_colors = {
    [NORMAL]    = {0.3, 0.8, 0.3},
    [MOVING]    = {0.3, 0.5, 0.9},
    [CRUMBLING] = {0.8, 0.6, 0.2},
}

local function spawn_platform(y)
    local x = math.random(20, SCREEN_W - PLAT_W - 20)
    local kind = NORMAL
    local r = math.random()
    if r < 0.15 then kind = CRUMBLING
    elseif r < 0.30 then kind = MOVING
    end
    local p = { x = x, y = y, kind = kind, dir = 1, alive = true }
    platforms[#platforms + 1] = p

    -- Chance for spring
    if math.random() < 0.12 then
        springs[#springs + 1] = { x = x + PLAT_W / 2 - 6, y = y - 12, w = 12, h = 12, plat = p }
    end

    -- Chance for enemy
    if math.random() < 0.08 and y < -200 then
        enemies[#enemies + 1] = {
            x = math.random(20, SCREEN_W - 30),
            y = y - 30, w = 20, h = 20,
            vx = math.random() < 0.5 and 80 or -80
        }
    end
end

local function init_game()
    player = { x = SCREEN_W / 2, y = SCREEN_H - 100, vx = 0, vy = 0 }
    platforms = {}
    enemies = {}
    springs = {}
    camera_y = 0
    score = 0
    game_over = false
    next_plat_y = SCREEN_H - 50

    -- Generate initial platforms
    while next_plat_y > -SCREEN_H do
        spawn_platform(next_plat_y)
        next_plat_y = next_plat_y - math.random(50, 90)
    end
    -- Guaranteed starting platform
    platforms[1] = { x = SCREEN_W / 2 - PLAT_W / 2, y = SCREEN_H - 50, kind = NORMAL, alive = true }
end

function lurek.init()
    init_game()
end

function lurek.process(dt)
    if game_over then return end

    -- Input
    player.vx = 0
    if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then player.vx = -MOVE_SPEED end
    if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then player.vx = MOVE_SPEED end

    -- Physics
    player.vy = player.vy + GRAVITY * dt
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Screen wrap
    if player.x < -PLAYER_W then player.x = SCREEN_W end
    if player.x > SCREEN_W then player.x = -PLAYER_W end

    -- Platform collision (only when falling)
    if player.vy > 0 then
        for _, p in ipairs(platforms) do
            if p.alive then
                local px = player.x + PLAYER_W / 2
                local py = player.y + PLAYER_H
                if px > p.x and px < p.x + PLAT_W and
                   py > p.y and py < p.y + PLAT_H + player.vy * dt then
                    player.y = p.y - PLAYER_H
                    player.vy = JUMP_VEL
                    if p.kind == CRUMBLING then p.alive = false end
                end
            end
        end

        -- Spring collision
        for _, s in ipairs(springs) do
            if s.plat.alive then
                local px = player.x + PLAYER_W / 2
                local py = player.y + PLAYER_H
                if px > s.x and px < s.x + s.w and py > s.y and py < s.y + s.h + 10 then
                    player.vy = SPRING_VEL
                    player.y = s.y - PLAYER_H
                end
            end
        end
    end

    -- Enemy collision
    for _, e in ipairs(enemies) do
        e.x = e.x + e.vx * dt
        if e.x < 0 or e.x > SCREEN_W - e.w then e.vx = -e.vx end
        if player.x < e.x + e.w and player.x + PLAYER_W > e.x and
           player.y < e.y + e.h and player.y + PLAYER_H > e.y then
            game_over = true
            if score > high_score then high_score = score end
        end
    end

    -- Moving platforms
    for _, p in ipairs(platforms) do
        if p.kind == MOVING and p.alive then
            p.x = p.x + 80 * p.dir * dt
            if p.x < 10 then p.dir = 1 end
            if p.x > SCREEN_W - PLAT_W - 10 then p.dir = -1 end
        end
    end

    -- Camera follows player upward
    local target_cam = player.y - SCREEN_H / 3
    if target_cam < camera_y then
        camera_y = lerp(camera_y, target_cam, 8 * dt)
    end

    -- Score = max height
    local height = math.floor(-player.y / 10)
    if height > score then score = height end

    -- Generate new platforms above
    while next_plat_y > camera_y - SCREEN_H do
        spawn_platform(next_plat_y)
        next_plat_y = next_plat_y - math.random(45, 85)
    end

    -- Cleanup below screen
    local bottom = camera_y + SCREEN_H + 100
    local new_plats = {}
    for _, p in ipairs(platforms) do
        if p.y < bottom then new_plats[#new_plats + 1] = p end
    end
    platforms = new_plats

    local new_enemies = {}
    for _, e in ipairs(enemies) do
        if e.y < bottom then new_enemies[#new_enemies + 1] = e end
    end
    enemies = new_enemies

    -- Fall death
    if player.y > camera_y + SCREEN_H + 50 then
        game_over = true
        if score > high_score then high_score = score end
    end
end

function lurek.keypressed(key)
    if key == "space" and game_over then init_game() end
    if key == "escape" then lurek.signal.quit() end
end

function lurek.render()
    lurek.gfx.setBackgroundColor(0.12, 0.12, 0.2)

    -- Platforms
    for _, p in ipairs(platforms) do
        if p.alive then
            local c = plat_colors[p.kind]
            lurek.gfx.setColor(c[1], c[2], c[3], 1)
            lurek.gfx.rectangle("fill", p.x, p.y - camera_y, PLAT_W, PLAT_H)
        end
    end

    -- Springs
    for _, s in ipairs(springs) do
        if s.plat.alive then
            lurek.gfx.setColor(1, 0.3, 0.3, 1)
            lurek.gfx.rectangle("fill", s.x, s.y - camera_y, s.w, s.h)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        lurek.gfx.setColor(0.9, 0.2, 0.2, 1)
        lurek.gfx.rectangle("fill", e.x, e.y - camera_y, e.w, e.h)
        -- Eyes
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.circle("fill", e.x + 5, e.y + 6 - camera_y, 3)
        lurek.gfx.circle("fill", e.x + 15, e.y + 6 - camera_y, 3)
    end

    -- Player
    lurek.gfx.setColor(1, 0.85, 0.2, 1)
    lurek.gfx.rectangle("fill", player.x, player.y - camera_y, PLAYER_W, PLAYER_H)
    -- Eyes
    lurek.gfx.setColor(0, 0, 0, 1)
    lurek.gfx.circle("fill", player.x + 7, player.y + 8 - camera_y, 3)
    lurek.gfx.circle("fill", player.x + 17, player.y + 8 - camera_y, 3)

    -- HUD
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Score: " .. score, 10, 10, 1.2)
    lurek.gfx.print("High: " .. high_score, 10, 32)
    lurek.gfx.print("FPS: " .. lurek.time.getFPS(), SCREEN_W - 90, 10)

    if game_over then
        lurek.gfx.setColor(0, 0, 0, 0.6)
        lurek.gfx.rectangle("fill", 0, SCREEN_H / 2 - 60, SCREEN_W, 120)
        lurek.gfx.setColor(1, 0.3, 0.3, 1)
        lurek.gfx.print("GAME OVER", SCREEN_W / 2 - 80, SCREEN_H / 2 - 40, 2)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print("Score: " .. score .. "  High: " .. high_score,
            SCREEN_W / 2 - 90, SCREEN_H / 2 + 10, 1.2)
        lurek.gfx.print("Press SPACE to restart", SCREEN_W / 2 - 90, SCREEN_H / 2 + 40)
    end
end
