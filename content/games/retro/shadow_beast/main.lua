-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

-- ============================================================================
-- Shadow of the Beast — Lurek2D
-- ============================================================================
-- Category : retro
-- Source   : content/games/retro/shadow_beast/main.lua
-- Run with : cargo run -- content/games/retro/shadow_beast
-- ============================================================================
-- Atmospheric side-scrolling action game inspired by Psygnosis' 1989 Amiga
-- masterpiece. Battle through a dark parallax world of creatures and bosses.
--
-- Controls: A/D move, Space/W jump, F attack, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600

local GRAVITY       = 900
local JUMP_VEL      = -440
local WALK_SPEED    = 160
local PLAYER_W      = 24
local PLAYER_H      = 32

local ATTACK_RANGE  = 60
local ATTACK_CD     = 0.3
local ATTACK_DMG    = 1
local PLAYER_MAX_HP = 5

local GROUND_Y      = 520

local ENEMY_GROUND_SPEED = 80
local ENEMY_FLY_SPEED    = 60
local ENEMY_SWOOP_SPEED  = 200

local BASE_SPAWN_CD   = 2.5
local MIN_SPAWN_CD    = 0.6
local BOSS_INTERVAL   = 3000
local BOSS_HP         = 10
local BOSS_W          = 56
local BOSS_H          = 64
local BOSS_SPEED      = 45

local IFRAMES_DUR     = 1.0
local KILL_SCORE      = 100
local BOSS_KILL_SCORE = 500

-- ---------------------------------------------------------------------------
-- Parallax layer definitions
-- ---------------------------------------------------------------------------
local PARALLAX = {
    { speed = 0.0,  color = {0.04, 0.02, 0.12} },  -- sky (static)
    { speed = 0.15, color = {0.08, 0.04, 0.18} },  -- far mountains
    { speed = 0.3,  color = {0.10, 0.06, 0.22} },  -- mid trees
    { speed = 0.55, color = {0.12, 0.08, 0.20} },  -- near hills
    { speed = 1.0,  color = {0.14, 0.09, 0.16} },  -- ground
}

-- ---------------------------------------------------------------------------
-- States
-- ---------------------------------------------------------------------------
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- ---------------------------------------------------------------------------
-- Game variables
-- ---------------------------------------------------------------------------
local player = {
    x = 200, y = GROUND_Y, vx = 0, vy = 0,
    on_ground = true, facing = 1, anim = 0,
    hp = PLAYER_MAX_HP, iframes = 0,
    attacking = false, attack_timer = 0, attack_cd = 0,
    flash = 0,
}
local scroll_x     = 0
local distance      = 0
local score          = 0
local speed_mult     = 1.0
local spawn_timer    = 0
local boss_active    = false
local next_boss_dist = BOSS_INTERVAL

local enemies    = {}
local particles  = {}
local atmo_motes = {}

local cam        = nil
local death_tween = nil
local hit_tween   = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function spawn_particles(px, py, r, g, b, count, speed_mult_p)
    speed_mult_p = speed_mult_p or 1
    for _ = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local spd = (30 + math.random() * 120) * speed_mult_p
        table.insert(particles, {
            x = px, y = py,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.2 + math.random() * 0.5,
            max_life = 0.7,
            r = r, g = g, b = b,
            size = 1 + math.random() * 3,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function draw_particles()
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        rect("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

-- Atmospheric floating motes
local function init_atmo_motes()
    atmo_motes = {}
    for _ = 1, 40 do
        table.insert(atmo_motes, {
            x = math.random() * SCREEN_W,
            y = math.random() * SCREEN_H,
            vx = -5 + math.random() * 10,
            vy = -15 + math.random() * -5,
            size = 1 + math.random() * 2,
            alpha = 0.1 + math.random() * 0.3,
            phase = math.random() * math.pi * 2,
        })
    end
end

local function update_atmo_motes(dt)
    for _, m in ipairs(atmo_motes) do
        m.phase = m.phase + dt * 1.5
        m.x = m.x + (m.vx + math.sin(m.phase) * 8) * dt
        m.y = m.y + m.vy * dt
        if m.y < -10 then m.y = SCREEN_H + 10; m.x = math.random() * SCREEN_W end
        if m.x < -10 then m.x = SCREEN_W + 10 end
        if m.x > SCREEN_W + 10 then m.x = -10 end
    end
end

local function draw_atmo_motes()
    for _, m in ipairs(atmo_motes) do
        lurek.render.setColor(0.6, 0.5, 0.8, m.alpha)
        circ("fill", m.x, m.y, m.size)
    end
end

-- ---------------------------------------------------------------------------
-- Enemy constructors
-- ---------------------------------------------------------------------------
local function make_ground_enemy(world_x)
    return {
        kind = "ground", x = world_x, y = GROUND_Y,
        w = 20, h = 28, hp = 1,
        vx = -ENEMY_GROUND_SPEED, anim = 0, alive = true, flash = 0,
    }
end

local function make_fly_enemy(world_x)
    local hover_y = 300 + math.random() * 120
    return {
        kind = "fly", x = world_x, y = hover_y,
        w = 22, h = 18, hp = 1,
        vx = -ENEMY_FLY_SPEED, anim = 0, alive = true, flash = 0,
        hover_y = hover_y, swoop = false, swoop_timer = 1.5 + math.random() * 2,
    }
end

local function make_spike(world_x)
    return {
        kind = "spike", x = world_x, y = GROUND_Y - 12,
        w = 24, h = 12, hp = 999,
        vx = 0, anim = 0, alive = true, flash = 0,
    }
end

local function make_boss(world_x)
    return {
        kind = "boss", x = world_x, y = GROUND_Y - BOSS_H + 28,
        w = BOSS_W, h = BOSS_H, hp = BOSS_HP,
        vx = -BOSS_SPEED, anim = 0, alive = true, flash = 0,
        attack_timer = 2.0, phase = 0,
    }
end

-- ---------------------------------------------------------------------------
-- Reset / Init
-- ---------------------------------------------------------------------------
local function reset_game()
    player.x = 200
    player.y = GROUND_Y
    player.vx = 0
    player.vy = 0
    player.on_ground = true
    player.facing = 1
    player.anim = 0
    player.hp = PLAYER_MAX_HP
    player.iframes = 0
    player.attacking = false
    player.attack_timer = 0
    player.attack_cd = 0
    player.flash = 0

    scroll_x = 0
    distance = 0
    score = 0
    speed_mult = 1.0
    spawn_timer = 1.5
    boss_active = false
    next_boss_dist = BOSS_INTERVAL

    enemies = {}
    particles = {}
    death_tween = nil
    hit_tween = nil
    init_atmo_motes()
end

-- ---------------------------------------------------------------------------
-- Load
-- ---------------------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("Shadow of the Beast — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.02, 0.15)

    lurek.input.bind("left", "a")
    lurek.input.bind("right", "d")
    lurek.input.bind("jump", {"space", "w"})
    lurek.input.bind("attack", "f")
    lurek.input.bind("confirm", "return")
    lurek.input.bind("quit", "escape")

    cam = lurek.camera.new()
    reset_game()
end

-- ---------------------------------------------------------------------------
-- Player update
-- ---------------------------------------------------------------------------
local function hurt_player(dmg)
    if player.iframes > 0 then return end
    player.hp = player.hp - (dmg or 1)
    player.iframes = IFRAMES_DUR
    player.flash = 0.3
    spawn_particles(player.x, player.y - PLAYER_H / 2, 1.0, 0.2, 0.2, 10, 1.0)
    if player.hp <= 0 then
        current_state = STATE.GAME_OVER
        spawn_particles(player.x, player.y - PLAYER_H / 2, 0.8, 0.1, 0.1, 25, 1.5)
    end
end

local function update_player(dt)
    -- Horizontal movement
    player.vx = 0
    if lurek.input.keyboard.isDown("left") then
        player.vx = -WALK_SPEED
        player.facing = -1
    end
    if lurek.input.keyboard.isDown("right") then
        player.vx = WALK_SPEED
        player.facing = 1
    end

    -- Jump
    if player.on_ground and lurek.input.wasActionPressed("jump") then
        player.vy = JUMP_VEL
        player.on_ground = false
        spawn_particles(player.x, GROUND_Y, 0.4, 0.3, 0.5, 6, 0.5)
    end

    -- Attack
    if lurek.input.wasActionPressed("attack") and player.attack_cd <= 0 then
        player.attacking = true
        player.attack_timer = 0.15
        player.attack_cd = ATTACK_CD
        spawn_particles(
            player.x + player.facing * 30, player.y - PLAYER_H / 2,
            1.0, 0.8, 0.3, 6, 0.8
        )
    end

    if player.attack_timer > 0 then
        player.attack_timer = player.attack_timer - dt
        if player.attack_timer <= 0 then player.attacking = false end
    end
    if player.attack_cd > 0 then
        player.attack_cd = player.attack_cd - dt
    end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Ground collision
    if player.y >= GROUND_Y then
        player.y = GROUND_Y
        player.vy = 0
        player.on_ground = true
    end

    -- Keep player in view (centered-ish)
    player.x = clamp(player.x, 60, SCREEN_W - 60)

    -- Scroll world
    local scroll_speed = (60 + speed_mult * 40)
    scroll_x = scroll_x + scroll_speed * dt
    distance = distance + scroll_speed * dt

    -- Increase difficulty over time
    speed_mult = 1.0 + distance / 5000

    -- I-frames
    if player.iframes > 0 then
        player.iframes = player.iframes - dt
    end
    if player.flash > 0 then
        player.flash = player.flash - dt
    end

    -- Walking anim
    if math.abs(player.vx) > 10 then
        player.anim = player.anim + dt * 8
    else
        player.anim = 0
    end
end

-- ---------------------------------------------------------------------------
-- Enemy update
-- ---------------------------------------------------------------------------
local function update_enemies(dt)
    local i = 1
    while i <= #enemies do
        local e = enemies[i]
        if not e.alive then
            table.remove(enemies, i)
        else
            -- Move
            if e.kind == "ground" then
                e.x = e.x + e.vx * speed_mult * dt - (60 + speed_mult * 40) * dt
                e.anim = e.anim + dt * 5
            elseif e.kind == "fly" then
                e.x = e.x + e.vx * speed_mult * dt - (60 + speed_mult * 40) * dt
                e.swoop_timer = e.swoop_timer - dt
                if e.swoop then
                    e.y = e.y + ENEMY_SWOOP_SPEED * dt
                    if e.y >= GROUND_Y - 30 then
                        e.swoop = false
                        e.swoop_timer = 1.5 + math.random() * 2
                        e.y = e.hover_y
                    end
                else
                    e.y = e.hover_y + math.sin(e.anim) * 15
                    if e.swoop_timer <= 0 then e.swoop = true end
                end
                e.anim = e.anim + dt * 3
            elseif e.kind == "spike" then
                e.x = e.x - (60 + speed_mult * 40) * dt
            elseif e.kind == "boss" then
                e.x = e.x + e.vx * dt - (60 + speed_mult * 40) * dt * 0.3
                e.anim = e.anim + dt * 2
                e.attack_timer = e.attack_timer - dt
                if e.attack_timer <= 0 then
                    e.attack_timer = 1.5
                    e.phase = e.phase + 1
                    -- Boss lunge toward player
                    if e.x > player.x then e.vx = -BOSS_SPEED * 2
                    else e.vx = BOSS_SPEED * 2 end
                end
            end

            -- Flash decay
            if e.flash > 0 then e.flash = e.flash - dt end

            -- Player melee hit check
            if player.attacking and e.kind ~= "spike" then
                local ax = player.x + (player.facing > 0 and 0 or -ATTACK_RANGE)
                local ay = player.y - PLAYER_H
                if rect_overlap(ax, ay, ATTACK_RANGE, PLAYER_H, e.x - e.w / 2, e.y - e.h, e.w, e.h) then
                    e.hp = e.hp - ATTACK_DMG
                    e.flash = 0.15
                    spawn_particles(e.x, e.y - e.h / 2, 1.0, 0.9, 0.3, 8, 1.0)
                    if e.hp <= 0 then
                        e.alive = false
                        if e.kind == "boss" then
                            score = score + BOSS_KILL_SCORE
                            boss_active = false
                            spawn_particles(e.x, e.y - e.h / 2, 1.0, 0.3, 0.1, 30, 1.5)
                        else
                            score = score + KILL_SCORE
                            spawn_particles(e.x, e.y - e.h / 2, 0.8, 0.2, 0.6, 15, 1.2)
                        end
                    end
                end
            end

            -- Contact damage to player
            if e.alive then
                local px = player.x - PLAYER_W / 2
                local py = player.y - PLAYER_H
                if rect_overlap(px, py, PLAYER_W, PLAYER_H, e.x - e.w / 2, e.y - e.h, e.w, e.h) then
                    if e.kind == "boss" then
                        hurt_player(2)
                    else
                        hurt_player(1)
                    end
                end
            end

            -- Remove if off screen left
            if e.x < -80 then
                if e.kind == "boss" then boss_active = false end
                table.remove(enemies, i)
            else
                i = i + 1
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Spawner
-- ---------------------------------------------------------------------------
local function update_spawner(dt)
    spawn_timer = spawn_timer - dt
    if spawn_timer <= 0 then
        local cd = math.max(MIN_SPAWN_CD, BASE_SPAWN_CD / speed_mult)
        spawn_timer = cd

        local roll = math.random()
        if roll < 0.45 then
            table.insert(enemies, make_ground_enemy(SCREEN_W + 40))
        elseif roll < 0.75 then
            table.insert(enemies, make_fly_enemy(SCREEN_W + 40))
        else
            table.insert(enemies, make_spike(SCREEN_W + 40))
        end
    end

    -- Boss spawning
    if distance >= next_boss_dist and not boss_active then
        boss_active = true
        next_boss_dist = next_boss_dist + BOSS_INTERVAL
        table.insert(enemies, make_boss(SCREEN_W + 60))
    end
end

-- ---------------------------------------------------------------------------
-- Parallax drawing
-- ---------------------------------------------------------------------------
local function draw_parallax()
    -- Layer 0: Sky gradient (static)
    local c = PARALLAX[1].color
    lurek.render.setColor(c[1], c[2], c[3], 1)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Moon
    local moon_x = 600 - scroll_x * 0.02
    lurek.render.setColor(0.9, 0.85, 0.7, 0.9)
    circ("fill", moon_x, 100, 50)
    -- Moon glow
    lurek.render.setColor(0.9, 0.85, 0.7, 0.15)
    circ("fill", moon_x, 100, 80)
    lurek.render.setColor(0.9, 0.85, 0.7, 0.06)
    circ("fill", moon_x, 100, 120)

    -- Layer 1: Far mountains
    local c1 = PARALLAX[2].color
    local off1 = (scroll_x * PARALLAX[2].speed) % SCREEN_W
    lurek.render.setColor(c1[1], c1[2], c1[3], 1)
    for ix = -1, 2 do
        local bx = ix * 400 - off1
        -- Mountain silhouettes
        lurek.render.triangle("fill",
            bx, 450, bx + 200, 280, bx + 400, 450)
        lurek.render.triangle("fill",
            bx + 150, 450, bx + 320, 310, bx + 500, 450)
    end
    rect("fill", 0, 450, SCREEN_W, 150)

    -- Layer 2: Mid trees
    local c2 = PARALLAX[3].color
    local off2 = (scroll_x * PARALLAX[3].speed) % 200
    lurek.render.setColor(c2[1], c2[2], c2[3], 1)
    for ix = -1, 5 do
        local tx = ix * 200 - off2
        -- Tree trunk
        rect("fill", tx + 90, 400, 12, 80)
        -- Tree canopy
        lurek.render.triangle("fill", tx + 60, 420, tx + 96, 340, tx + 132, 420)
        lurek.render.triangle("fill", tx + 65, 390, tx + 96, 320, tx + 127, 390)
    end
    rect("fill", 0, 480, SCREEN_W, 120)

    -- Layer 3: Near hills
    local c3 = PARALLAX[4].color
    local off3 = (scroll_x * PARALLAX[4].speed) % 300
    lurek.render.setColor(c3[1], c3[2], c3[3], 1)
    for ix = -1, 4 do
        local hx = ix * 300 - off3
        lurek.render.triangle("fill", hx, 520, hx + 150, 440, hx + 300, 520)
    end
    rect("fill", 0, 500, SCREEN_W, 100)

    -- Layer 4: Ground
    local c4 = PARALLAX[5].color
    lurek.render.setColor(c4[1], c4[2], c4[3], 1)
    rect("fill", 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y)

    -- Ground detail lines
    local off4 = (scroll_x * PARALLAX[5].speed) % 60
    lurek.render.setColor(0.18, 0.12, 0.22, 0.5)
    for ix = -1, 15 do
        local gx = ix * 60 - off4
        rect("fill", gx, GROUND_Y, 30, 2)
        rect("fill", gx + 15, GROUND_Y + 8, 20, 1)
    end
end

-- ---------------------------------------------------------------------------
-- Draw player
-- ---------------------------------------------------------------------------
local function draw_player()
    local px = player.x
    local py = player.y
    local blink = player.iframes > 0 and math.floor(player.iframes * 12) % 2 == 0

    if blink then return end

    local fr, fg, fb = 0.6, 0.4, 0.7
    if player.flash > 0 then fr, fg, fb = 1.0, 0.3, 0.3 end

    -- Legs (two rectangles, animate walk)
    local leg_offset = math.sin(player.anim) * 4
    lurek.render.setColor(fr * 0.7, fg * 0.7, fb * 0.7, 1)
    rect("fill", px - 7, py - 10 + leg_offset, 5, 10)
    rect("fill", px + 2, py - 10 - leg_offset, 5, 10)

    -- Body
    lurek.render.setColor(fr, fg, fb, 1)
    rect("fill", px - 10, py - PLAYER_H + 6, 20, 18)

    -- Head
    lurek.render.setColor(fr * 1.1, fg * 1.1, fb * 0.9, 1)
    rect("fill", px - 6, py - PLAYER_H - 2, 12, 10)

    -- Eyes (two red dots)
    lurek.render.setColor(1.0, 0.2, 0.1, 1)
    if player.facing > 0 then
        rect("fill", px, py - PLAYER_H + 1, 2, 2)
        rect("fill", px + 4, py - PLAYER_H + 1, 2, 2)
    else
        rect("fill", px - 6, py - PLAYER_H + 1, 2, 2)
        rect("fill", px - 2, py - PLAYER_H + 1, 2, 2)
    end

    -- Attack arm extension
    if player.attacking then
        lurek.render.setColor(fr, fg, fb, 1)
        local arm_x = player.facing > 0 and px + 10 or px - 30
        rect("fill", arm_x, py - PLAYER_H + 10, 20, 6)
        -- Fist
        lurek.render.setColor(1.0, 0.8, 0.3, 0.8)
        local fist_x = player.facing > 0 and px + 28 or px - 32
        rect("fill", fist_x, py - PLAYER_H + 8, 6, 8)
    end
end

-- ---------------------------------------------------------------------------
-- Draw enemies
-- ---------------------------------------------------------------------------
local function draw_enemies()
    for _, e in ipairs(enemies) do
        local er, eg, eb = 0.3, 0.15, 0.35
        if e.flash > 0 then er, eg, eb = 1.0, 1.0, 1.0 end

        if e.kind == "ground" then
            -- Dark creature silhouette
            lurek.render.setColor(er, eg, eb, 1)
            rect("fill", e.x - e.w / 2, e.y - e.h, e.w, e.h)
            -- Glowing eyes
            lurek.render.setColor(0.9, 0.3, 0.1, 1)
            rect("fill", e.x - 5, e.y - e.h + 5, 3, 3)
            rect("fill", e.x + 3, e.y - e.h + 5, 3, 3)

        elseif e.kind == "fly" then
            -- Wing shape
            lurek.render.setColor(er * 0.8, eg * 0.8, eb * 1.2, 1)
            local wing = math.sin(e.anim * 6) * 6
            lurek.render.triangle("fill",
                e.x - 16, e.y - wing, e.x, e.y - e.h / 2, e.x - 4, e.y)
            lurek.render.triangle("fill",
                e.x + 16, e.y - wing, e.x, e.y - e.h / 2, e.x + 4, e.y)
            -- Body
            lurek.render.setColor(er, eg, eb, 1)
            rect("fill", e.x - 5, e.y - 12, 10, 12)
            -- Eye
            lurek.render.setColor(1.0, 0.6, 0.1, 1)
            rect("fill", e.x - 2, e.y - 10, 4, 3)

        elseif e.kind == "spike" then
            -- Three spike triangles
            lurek.render.setColor(0.4, 0.2, 0.3, 1)
            lurek.render.triangle("fill",
                e.x - 12, GROUND_Y, e.x - 4, GROUND_Y - 14, e.x + 4, GROUND_Y)
            lurek.render.triangle("fill",
                e.x - 4, GROUND_Y, e.x + 4, GROUND_Y - 18, e.x + 12, GROUND_Y)
            lurek.render.triangle("fill",
                e.x + 4, GROUND_Y, e.x + 12, GROUND_Y - 12, e.x + 20, GROUND_Y)

        elseif e.kind == "boss" then
            -- Large beast silhouette
            lurek.render.setColor(er * 1.5, eg, eb * 1.3, 1)
            rect("fill", e.x - e.w / 2, e.y - e.h, e.w, e.h)
            -- Horns
            lurek.render.setColor(0.5, 0.2, 0.3, 1)
            lurek.render.triangle("fill",
                e.x - 20, e.y - e.h, e.x - 28, e.y - e.h - 20, e.x - 12, e.y - e.h)
            lurek.render.triangle("fill",
                e.x + 20, e.y - e.h, e.x + 28, e.y - e.h - 20, e.x + 12, e.y - e.h)
            -- Eyes
            lurek.render.setColor(1.0, 0.1, 0.0, 1)
            rect("fill", e.x - 14, e.y - e.h + 14, 6, 5)
            rect("fill", e.x + 8, e.y - e.h + 14, 6, 5)
            -- HP bar
            local bar_w = 50
            local hp_frac = e.hp / BOSS_HP
            lurek.render.setColor(0.2, 0.0, 0.0, 0.8)
            rect("fill", e.x - bar_w / 2, e.y - e.h - 12, bar_w, 6)
            lurek.render.setColor(0.9, 0.1, 0.1, 0.9)
            rect("fill", e.x - bar_w / 2, e.y - e.h - 12, bar_w * hp_frac, 6)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Update (process)
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("confirm") then
            current_state = STATE.PLAYING
            reset_game()
        end
        update_atmo_motes(dt)

    elseif current_state == STATE.PLAYING then
        update_player(dt)
        update_enemies(dt)
        update_spawner(dt)
        update_particles(dt)
        update_atmo_motes(dt)

        -- Distance scoring
        score = score + math.floor(dt * 10 * speed_mult)

    elseif current_state == STATE.GAME_OVER then
        update_particles(dt)
        update_atmo_motes(dt)
        if lurek.input.wasActionPressed("confirm") then
            current_state = STATE.PLAYING
            reset_game()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render (world)
-- ---------------------------------------------------------------------------
function lurek.draw()
    draw_parallax()

    if current_state == STATE.TITLE then
        draw_atmo_motes()

    elseif current_state == STATE.PLAYING then
        draw_atmo_motes()
        draw_enemies()
        draw_player()
        draw_particles()

    elseif current_state == STATE.GAME_OVER then
        draw_atmo_motes()
        draw_enemies()
        draw_particles()
        -- Dead player on ground
        lurek.render.setColor(0.4, 0.2, 0.3, 0.6)
        rect("fill", player.x - 16, GROUND_Y - 8, 32, 8)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI (HUD, titles, overlays)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state == STATE.TITLE then
        -- Title
        lurek.render.setColor(0.85, 0.7, 0.95, 1)
        text_("SHADOW OF THE BEAST", SCREEN_W / 2 - 150, 180, 32)
        lurek.render.setColor(0.6, 0.45, 0.7, 0.8)
        text_("A Lurek2D Tribute to Psygnosis", SCREEN_W / 2 - 140, 225, 16)
        -- Controls
        lurek.render.setColor(0.5, 0.4, 0.6, 0.7)
        text_("A/D  Move   |   SPACE  Jump   |   F  Attack", SCREEN_W / 2 - 180, 340, 14)
        -- Prompt
        local pulse = 0.5 + 0.5 * math.abs(math.sin(lurek.timer.getTime() * 2.5))
        lurek.render.setColor(0.8, 0.6, 0.9, pulse)
        text_("Press ENTER to begin", SCREEN_W / 2 - 90, 420, 18)

    elseif current_state == STATE.PLAYING then
        -- HP icons
        for i = 1, PLAYER_MAX_HP do
            if i <= player.hp then
                lurek.render.setColor(0.9, 0.2, 0.2, 1)
            else
                lurek.render.setColor(0.3, 0.1, 0.1, 0.5)
            end
            rect("fill", 10 + (i - 1) * 22, 10, 16, 16)
            -- Cross on HP icon
            if i <= player.hp then
                lurek.render.setColor(1.0, 0.5, 0.5, 1)
                rect("fill", 14 + (i - 1) * 22, 13, 8, 2)
                rect("fill", 17 + (i - 1) * 22, 12, 2, 6)
            end
        end

        -- Score
        lurek.render.setColor(0.8, 0.7, 0.9, 1)
        text_("SCORE: " .. score, SCREEN_W - 180, 12, 16)

        -- Distance
        lurek.render.setColor(0.6, 0.5, 0.7, 0.8)
        text_("DIST: " .. math.floor(distance), SCREEN_W - 180, 32, 14)

        -- Boss warning
        if boss_active then
            local flash = math.abs(math.sin(lurek.timer.getTime() * 4))
            lurek.render.setColor(1.0, 0.2, 0.1, flash * 0.8)
            text_("!! BOSS !!", SCREEN_W / 2 - 40, 50, 20)
        end

    elseif current_state == STATE.GAME_OVER then
        -- Fade overlay
        lurek.render.setColor(0.0, 0.0, 0.0, 0.6)
        rect("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(0.9, 0.3, 0.3, 1)
        text_("GAME OVER", SCREEN_W / 2 - 80, 220, 32)

        lurek.render.setColor(0.7, 0.5, 0.8, 1)
        text_("Score: " .. score, SCREEN_W / 2 - 50, 280, 20)
        text_("Distance: " .. math.floor(distance), SCREEN_W / 2 - 70, 310, 16)

        local pulse = 0.5 + 0.5 * math.abs(math.sin(lurek.timer.getTime() * 2.5))
        lurek.render.setColor(0.6, 0.5, 0.7, pulse)
        text_("Press ENTER to try again", SCREEN_W / 2 - 110, 380, 18)
    end
end
