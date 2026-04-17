-- Shadow of the Beast — Amiga 500 Classic (Lurek2D demo)
-- Atmospheric side-scrolling action inspired by Psygnosis' stunning 1989 Amiga title.
-- The Beast Man fights through layers of parallax landscapes to break the curse.
-- Run with: cargo run -- content/demos/retro/shadow_beast

-- ── Constants ────────────────────────────────────────────────────────────

local W, H     = 800, 600
local GRAVITY  = 700
local JUMP_VEL = -420
local WALK_SPD = 130
local ENEMY_SPD = 60
local ATTACK_RANGE = 60
local HEALTH_MAX = 5
local SCROLL_SPEED = 80

-- ── Parallax layers ───────────────────────────────────────────────────────
-- Layer: color, speed_factor, elements
local LAYERS = {
    { r=0.05, g=0.02, b=0.15, factor=0.0  }, -- static sky
    { r=0.08, g=0.03, b=0.22, factor=0.15 }, -- far mountains
    { r=0.12, g=0.04, b=0.30, factor=0.30 }, -- mid trees
    { r=0.15, g=0.06, b=0.38, factor=0.55 }, -- near hills
    { r=0.18, g=0.08, b=0.28, factor=1.0  }, -- ground
}

-- Moon
local MOON = { x = 620, y = 90, r = 55 }

-- ── State ─────────────────────────────────────────────────────────────────

local player    = {}
local enemies   = {}
local attacks   = {}   -- Player hit sparks
local world_x   = 0
local score, health = 0, HEALTH_MAX
local game_state = "playing"
local anim = 0
local spawn_timer = 3
local attack_cd = 0
local stage = 1   -- 1..3 stages, each with a boss

-- Decorative trees/shapes per layer
local layer_trees = {}

local function build_layer_trees()
    layer_trees = {}
    math.randomseed(99)
    for li = 2, 4 do
        layer_trees[li] = {}
        local count = 10 + math.random(6)
        for _ = 1, count do
            layer_trees[li][#layer_trees[li]+1] = {
                x = math.random(-100, W + 400),
                h = 30 + math.random(50),
                w = 8 + math.random(20),
            }
        end
    end
    math.randomseed(os.time())
end

-- Ground level (drawn procedurally)
local GROUND_Y = H - 90

-- ── Helpers ───────────────────────────────────────────────────────────────

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

-- ── Reset ─────────────────────────────────────────────────────────────────

local function reset()
    player = { x = 100, y = GROUND_Y - 46, w = 30, h = 46,
               vx = 0, vy = 0, on_ground = false, facing = 1,
               attacking = false, attack_frame = 0 }
    enemies = {}; attacks = {}
    world_x = 0; spawn_timer = 3; attack_cd = 0; stage = 1
    score = 0; health = HEALTH_MAX
    game_state = "playing"
    build_layer_trees()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.05, 0.02, 0.15)
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt
    attack_cd = math.max(0, attack_cd - dt)

    -- Player movement
    local mv = 0
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then mv = 1 end
    if lurek.input.isKeyDown("left")  or lurek.input.isKeyDown("a") then mv = -1 end
    if mv ~= 0 then player.facing = mv end
    player.vx = mv * WALK_SPD

    -- Scroll world when player moves right past center
    if player.x > W * 0.55 and mv > 0 then
        world_x = world_x + SCROLL_SPEED * dt
        player.x = W * 0.55
        -- Scroll layer tree positions
        for li = 2, 4 do
            if layer_trees[li] then
                for _, t in ipairs(layer_trees[li]) do
                    t.x = t.x - SCROLL_SPEED * dt * LAYERS[li].factor
                    if t.x < -100 then t.x = t.x + W + 300 end
                end
            end
        end
    else
        player.x = clamp(player.x + player.vx * dt, 20, W - 20)
    end

    -- Gravity
    if not player.on_ground then player.vy = player.vy + GRAVITY * dt end
    player.y = player.y + player.vy * dt
    if player.y + player.h >= GROUND_Y then
        player.y = GROUND_Y - player.h; player.vy = 0; player.on_ground = true
    else
        player.on_ground = false
    end

    -- Attack flash duration
    if player.attacking then
        player.attack_frame = player.attack_frame + dt
        if player.attack_frame > 0.25 then player.attacking = false end
    end

    -- Attack vs enemies
    if player.attacking then
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            if e.alive then
                local dx = math.abs((e.x + e.w/2) - (player.x + player.w/2))
                if dx < ATTACK_RANGE + player.w/2 and math.abs(e.y - player.y) < 40 then
                    e.hp = e.hp - 1
                    attacks[#attacks+1] = { x = e.x + e.w/2, y = e.y + 10, life = 0.4 }
                    if e.hp <= 0 then e.alive = false; score = score + (e.boss and 500 or 100) end
                end
            end
        end
    end

    -- Enemy spawning
    spawn_timer = spawn_timer - dt
    if spawn_timer <= 0 then
        spawn_timer = 3 + math.random() * 2 - stage * 0.5
        enemies[#enemies+1] = {
            x = W + 40, y = GROUND_Y - 40, w = 28, h = 40,
            vx = -ENEMY_SPD, vy = 0, hp = 2, alive = true, boss = false
        }
    end

    -- Boss after 5 kills
    local kills = 0
    for _, e in ipairs(enemies) do if not e.alive then kills = kills + 1 end end
    if kills >= stage * 5 then
        local has_boss = false
        for _, e in ipairs(enemies) do if e.boss and e.alive then has_boss = true; break end end
        if not has_boss then
            enemies[#enemies+1] = {
                x = W + 60, y = GROUND_Y - 80, w = 60, h = 80,
                vx = -ENEMY_SPD * 0.5, vy = 0, hp = 8, alive = true, boss = true
            }
        end
    end

    -- Enemy movement
    for _, e in ipairs(enemies) do
        if e.alive then
            e.x = e.x + e.vx * dt
            -- Reverse near edges
            if e.x < 20 then e.vx = math.abs(e.vx) end
            if e.x > W - 40 then e.vx = -math.abs(e.vx) end
            -- Player contact
            if math.abs((e.x + e.w/2) - (player.x + player.w/2)) < (e.w + player.w)/2 - 6 and
               math.abs(e.y - player.y) < 40 then
                health = health - 1
                e.x = e.x + (e.x < player.x and -60 or 60)
                if health <= 0 then game_state = "gameover" end
            end
        end
    end

    -- Attack hit effects
    for i = #attacks, 1, -1 do
        attacks[i].life = attacks[i].life - dt
        if attacks[i].life <= 0 then table.remove(attacks, i) end
    end

    -- Stage clear
    local all_beaten = kills >= stage * 5
    if all_beaten then
        local boss_alive = false
        for _, e in ipairs(enemies) do if e.boss and e.alive then boss_alive = true; break end end
        if not boss_alive and kills >= stage * 5 then
            score = score + stage * 1000
            stage = stage + 1
            if stage > 3 then game_state = "win"
            else spawn_timer = 4 end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Sky
    lurek.render.setColor(LAYERS[1].r, LAYERS[1].g, LAYERS[1].b)
    lurek.render.rectangle("fill", 0, 0, W, H)

    -- Moon
    lurek.render.setColor(0.9, 0.85, 0.65)
    lurek.render.circle("fill", MOON.x, MOON.y, MOON.r)
    lurek.render.setColor(LAYERS[1].r, LAYERS[1].g + 0.01, LAYERS[1].b + 0.02)
    lurek.render.circle("fill", MOON.x + 18, MOON.y - 10, MOON.r * 0.85)

    -- Parallax layers (mountains / trees / hills)
    for li = 2, 4 do
        local lc = LAYERS[li]
        if layer_trees[li] then
            local horizon = H * (0.3 + (li - 2) * 0.12)
            for _, t in ipairs(layer_trees[li]) do
                local dark = li / 5
                lurek.render.setColor(lc.r, lc.g, lc.b)
                lurek.render.rectangle("fill", t.x, horizon, t.w, H - horizon)
                lurek.render.rectangle("fill", t.x + t.w/2 - t.w * 0.3, horizon - t.h, t.w * 0.6, t.h)
            end
        end
    end

    -- Ground
    lurek.render.setColor(0.12, 0.08, 0.05)
    lurek.render.rectangle("fill", 0, GROUND_Y, W, H - GROUND_Y)
    lurek.render.setColor(0.25, 0.14, 0.28)
    lurek.render.rectangle("fill", 0, GROUND_Y, W, 6)

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local sz = e.boss and 1.8 or 1
            local gx = e.x + e.w/2
            -- Body
            lurek.render.setColor(0.5 * sz, 0.2, 0.05)
            lurek.render.rectangle("fill", e.x, e.y, e.w, e.h)
            -- Head
            lurek.render.setColor(0.35, 0.15, 0.04)
            lurek.render.circle("fill", gx, e.y + e.h * 0.25, e.w * 0.4)
            -- Eyes
            lurek.render.setColor(1, 0.1, 0)
            lurek.render.circle("fill", gx - 4, e.y + e.h * 0.22, 4)
            lurek.render.circle("fill", gx + 4, e.y + e.h * 0.22, 4)
            -- HP bar
            if e.boss then
                lurek.render.setColor(0.4, 0, 0)
                lurek.render.rectangle("fill", e.x, e.y - 10, e.w, 6)
                lurek.render.setColor(0.9, 0.1, 0.1)
                lurek.render.rectangle("fill", e.x, e.y - 10, e.w * (e.hp / 8), 6)
            end
        end
    end

    -- Attack sparks
    for _, a in ipairs(attacks) do
        local t = a.life / 0.4
        lurek.render.setColor(1, 0.8, 0.2, t)
        lurek.render.circle("fill", a.x, a.y, 10 * t)
    end

    -- Player (beast man)
    if player.attacking then
        lurek.render.setColor(0.9, 0.7, 0.2, 0.5)
        lurek.render.circle("fill", player.x + player.w/2 + player.facing * 25, player.y + 15, 18)
    end
    -- Body
    lurek.render.setColor(0.55, 0.42, 0.28)
    lurek.render.rectangle("fill", player.x + 4, player.y + 16, player.w - 8, player.h - 16)
    -- Head
    lurek.render.setColor(0.6, 0.45, 0.3)
    lurek.render.circle("fill", player.x + player.w/2, player.y + 13, 13)
    -- Horn / beast features
    lurek.render.setColor(0.3, 0.2, 0.1)
    lurek.render.rectangle("fill", player.x + player.w/2 - 2, player.y, 4, 10)
    -- Eyes
    lurek.render.setColor(0.9, 0.5, 0.1)
    local ex2 = player.x + (player.facing > 0 and player.w - 7 or 7)
    lurek.render.circle("fill", ex2, player.y + 11, 3)

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.65)
    lurek.render.rectangle("fill", 0, 0, W, 28)
    lurek.render.setColor(0.8, 0.4, 1)
    lurek.render.print("SHADOW OF THE BEAST", 8, 4, 1.8)
    lurek.render.setColor(1, 0.8, 0.2)
    lurek.render.print("Score: " .. score, W/2 - 50, 4, 1.6)
    -- Health orbs
    for i = 1, HEALTH_MAX do
        local hx = W - 24 * i - 5
        lurek.render.setColor(i <= health and 0.9 or 0.3, i <= health and 0.2 or 0.2, i <= health and 0.1 or 0.2)
        lurek.render.circle("fill", hx + 10, 14, 9)
    end
    lurek.render.setColor(0.6, 0.4, 0.9)
    lurek.render.print("Stage " .. stage .. "/3", W/2 + 70, 4, 1.6)

    lurek.render.setColor(0.5, 0.4, 0.65, 0.65)
    lurek.render.print("[A/D] Walk  [Space/W] Jump  [X] Attack  Defeat all beasts each stage!", 8, H - 20, 1.3)

    -- Overlay
    if game_state == "gameover" then
        lurek.render.setColor(0, 0, 0, 0.8)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(0.9, 0.3, 0.8)
        lurek.render.print("THE BEAST CLAIMS YOU", W/2 - 150, H/2 - 25, 2.5)
        lurek.render.setColor(1, 0.8, 0.2)
        lurek.render.print("Score: " .. score, W/2 - 50, H/2 + 20, 2)
        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Press R to restart", W/2 - 100, H/2 + 55, 2)
    elseif game_state == "win" then
        lurek.render.setColor(0, 0, 0, 0.78)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(0.7, 0.3, 1)
        lurek.render.print("CURSE BROKEN!", W/2 - 110, H/2 - 30, 3)
        lurek.render.setColor(1, 0.9, 0.5)
        lurek.render.print("Score: " .. score, W/2 - 50, H/2 + 20, 2)
        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Press R to play again", W/2 - 110, H/2 + 55, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "up" or key == "w") and player.on_ground then
        player.vy = JUMP_VEL
    end
    if key == "x" and attack_cd <= 0 then
        player.attacking = true; player.attack_frame = 0
        attack_cd = 0.45
    end
end
