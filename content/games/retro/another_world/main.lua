-- ============================================================================
-- Another World — Lurek2D
-- ============================================================================
-- Category : retro
-- Source   : content/games/retro/another_world/main.lua
-- Run with : cargo run -- content/games/retro/another_world
-- ============================================================================
-- Cinematic puzzle-platformer inspired by Eric Chahi's 1991 masterpiece.
-- Navigate alien landscapes, fight hostile creatures with a three-mode
-- energy gun, and survive through atmosphere and wits.
--
-- Controls: A/D move, Space/W jump, F fire/shield/super-shot, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local GRAVITY       = 700
local JUMP_VEL      = -420
local WALK_SPEED    = 130
local PLAYER_W      = 16
local PLAYER_H      = 36

local SHOT_SPEED    = 500
local SHOT_LIFE     = 1.2
local SUPER_SPEED   = 350
local SUPER_LIFE    = 2.0
local SHIELD_DURATION = 2.5
local MAX_SHIELDS   = 3
local CHARGE_SHIELD = 0.35
local CHARGE_SUPER  = 0.9

local ALIEN_SPEED   = 50
local ALIEN_W       = 18
local ALIEN_H       = 34
local ALIEN_FIRE_CD = 2.2
local ALIEN_PROJ_SPEED = 200

-- ---------------------------------------------------------------------------
-- States
-- ---------------------------------------------------------------------------
local STATE = { TITLE = 1, INTRO = 2, PLAYING = 3, DEAD = 4, GAME_OVER = 5 }
local current_state = STATE.TITLE

-- ---------------------------------------------------------------------------
-- Game variables
-- ---------------------------------------------------------------------------
local player = { x = 120, y = 0, vx = 0, vy = 0, on_ground = false, facing = 1, anim = 0 }
local lives = 3
local current_scene = 1
local shots = {}
local shields = {}
local charge_timer = 0
local charging = false
local dead_timer = 0
local fade_alpha = 0
local fade_dir = 0
local fade_target_scene = nil
local intro_timer = 0
local intro_line = 1

local aliens = {}
local alien_projectiles = {}
local particles = {}
local cam = nil

-- ---------------------------------------------------------------------------
-- Scene definitions (5 scenes)
-- ---------------------------------------------------------------------------
local scenes = {}

local function make_platform(x, y, w, h)
    return { x = x, y = y, w = w, h = h or 16 }
end

local function make_alien(x, y, patrol_l, patrol_r)
    return {
        x = x, y = y, hp = 2, facing = -1,
        patrol_l = patrol_l, patrol_r = patrol_r,
        fire_cd = 1.0 + math.random() * 1.5,
        anim = 0, alive = true,
    }
end

local function build_scenes()
    scenes = {
        -- Scene 1: Arrival
        {
            caption = "A failed experiment... a portal to another world.",
            platforms = {
                make_platform(0, 520, 800, 80),
                make_platform(200, 420, 120),
                make_platform(450, 360, 150),
                make_platform(650, 300, 150),
            },
            aliens_def = {
                { x = 500, y = 486, patrol_l = 400, patrol_r = 600 },
            },
            exit_right = 2,
            moon_x = 650, moon_y = 80,
            spawn_x = 120, spawn_y = 400,
        },
        -- Scene 2: Cliffs
        {
            caption = "The alien landscape stretched endlessly before him.",
            platforms = {
                make_platform(0, 520, 350, 80),
                make_platform(400, 480, 200, 120),
                make_platform(650, 420, 150, 180),
                make_platform(100, 380, 140),
                make_platform(320, 320, 100),
            },
            aliens_def = {
                { x = 450, y = 446, patrol_l = 400, patrol_r = 580 },
                { x = 680, y = 386, patrol_l = 650, patrol_r = 790 },
            },
            exit_left = 1, exit_right = 3,
            spawn_x = 40, spawn_y = 400,
        },
        -- Scene 3: Underground passage
        {
            caption = "Deep underground... the hum of alien machinery.",
            platforms = {
                make_platform(0, 520, 800, 80),
                make_platform(0, 0, 800, 40),
                make_platform(150, 400, 120),
                make_platform(350, 340, 160),
                make_platform(580, 420, 120),
                make_platform(0, 300, 80),
            },
            aliens_def = {
                { x = 250, y = 486, patrol_l = 100, patrol_r = 350 },
                { x = 600, y = 486, patrol_l = 550, patrol_r = 750 },
                { x = 400, y = 306, patrol_l = 350, patrol_r = 500 },
            },
            exit_left = 2, exit_right = 4,
            spawn_x = 40, spawn_y = 400,
        },
        -- Scene 4: The prison
        {
            caption = "Captured... but not defeated.",
            platforms = {
                make_platform(0, 520, 800, 80),
                make_platform(50, 380, 100),
                make_platform(250, 340, 130),
                make_platform(500, 300, 140),
                make_platform(680, 400, 120),
            },
            aliens_def = {
                { x = 300, y = 306, patrol_l = 250, patrol_r = 370 },
                { x = 550, y = 266, patrol_l = 500, patrol_r = 630 },
            },
            exit_left = 3, exit_right = 5,
            spawn_x = 40, spawn_y = 400,
        },
        -- Scene 5: Escape
        {
            caption = "Freedom... at last... but at what cost?",
            platforms = {
                make_platform(0, 520, 800, 80),
                make_platform(100, 420, 140),
                make_platform(300, 360, 100),
                make_platform(500, 300, 120),
                make_platform(680, 240, 120),
            },
            aliens_def = {
                { x = 350, y = 486, patrol_l = 200, patrol_r = 500 },
                { x = 600, y = 486, patrol_l = 550, patrol_r = 750 },
                { x = 700, y = 206, patrol_l = 680, patrol_r = 790 },
            },
            exit_left = 4,
            spawn_x = 40, spawn_y = 400,
        },
    }
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function spawn_particles(px, py, r, g, b, count, speed_mult)
    speed_mult = speed_mult or 1
    for _ = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local spd = (30 + math.random() * 120) * speed_mult
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
        lurek.render.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

-- ---------------------------------------------------------------------------
-- Scene management
-- ---------------------------------------------------------------------------
local function load_scene(idx)
    current_scene = idx
    local s = scenes[idx]
    aliens = {}
    alien_projectiles = {}
    shots = {}
    shields = {}
    particles = {}
    charge_timer = 0
    charging = false

    for _, ad in ipairs(s.aliens_def) do
        table.insert(aliens, make_alien(ad.x, ad.y, ad.patrol_l, ad.patrol_r))
    end

    player.x = s.spawn_x
    player.y = s.spawn_y
    player.vx = 0
    player.vy = 0
    player.on_ground = false
end

local function start_scene_transition(target)
    fade_dir = 1
    fade_alpha = 0
    fade_target_scene = target
    lurek.tween.to({ duration = 0.4 })
end

-- ---------------------------------------------------------------------------
-- Intro text
-- ---------------------------------------------------------------------------
local intro_lines = {
    "The particle accelerator hummed with",
    "impossible energy...",
    "",
    "A flash of light —",
    "and the world you knew was gone.",
    "",
    "Now you stand on alien soil,",
    "surrounded by hostile creatures.",
    "",
    "Survive. Escape. Find your way home.",
}

-- ---------------------------------------------------------------------------
-- Player physics
-- ---------------------------------------------------------------------------
local function update_player(dt)
    local s = scenes[current_scene]

    -- Horizontal movement
    player.vx = 0
    if lurek.input.down("left") then
        player.vx = -WALK_SPEED
        player.facing = -1
    end
    if lurek.input.down("right") then
        player.vx = WALK_SPEED
        player.facing = 1
    end

    -- Jump
    if player.on_ground and lurek.input.pressed("jump") then
        player.vy = JUMP_VEL
        player.on_ground = false
    end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Platform collision
    player.on_ground = false
    for _, p in ipairs(s.platforms) do
        if rect_overlap(player.x - PLAYER_W / 2, player.y - PLAYER_H, PLAYER_W, PLAYER_H, p.x, p.y, p.w, p.h) then
            if player.vy > 0 and player.y - PLAYER_H + PLAYER_H * 0.6 < p.y then
                player.y = p.y
                player.vy = 0
                player.on_ground = true
            elseif player.vy < 0 and player.y - PLAYER_H < p.y + p.h then
                player.vy = 0
            end
        end
    end

    -- Clamp horizontally
    player.x = clamp(player.x, PLAYER_W / 2, SCREEN_W - PLAYER_W / 2)

    -- Scene transitions
    if player.x <= PLAYER_W / 2 + 2 and s.exit_left then
        start_scene_transition(s.exit_left)
    elseif player.x >= SCREEN_W - PLAYER_W / 2 - 2 and s.exit_right then
        start_scene_transition(s.exit_right)
    end

    -- Walking animation timer
    if math.abs(player.vx) > 10 then
        player.anim = player.anim + dt * 8
    else
        player.anim = 0
    end
end

-- ---------------------------------------------------------------------------
-- Energy gun system
-- ---------------------------------------------------------------------------
local function fire_normal()
    table.insert(shots, {
        x = player.x + player.facing * 12,
        y = player.y - PLAYER_H * 0.6,
        vx = player.facing * SHOT_SPEED,
        vy = 0,
        life = SHOT_LIFE,
        kind = "normal",
    })
    -- Muzzle flash particles
    spawn_particles(player.x + player.facing * 14, player.y - PLAYER_H * 0.6,
        1.0, 0.8, 0.2, 5, 0.6)
end

local function fire_shield()
    if #shields >= MAX_SHIELDS then return end
    local sx = player.x + player.facing * 40
    table.insert(shields, {
        x = sx,
        y = player.y - PLAYER_H - 10,
        life = SHIELD_DURATION,
        shimmer = 0,
    })
    -- Shield creation particles
    spawn_particles(sx, player.y - PLAYER_H / 2, 0.3, 0.6, 1.0, 10, 0.8)
end

local function fire_super()
    table.insert(shots, {
        x = player.x + player.facing * 12,
        y = player.y - PLAYER_H * 0.6,
        vx = player.facing * SUPER_SPEED,
        vy = 0,
        life = SUPER_LIFE,
        kind = "super",
    })
    -- Super-shot explosion particles
    spawn_particles(player.x + player.facing * 14, player.y - PLAYER_H * 0.6,
        1.0, 0.3, 0.1, 15, 1.2)
end

local function update_gun(dt)
    if lurek.input.pressed("fire") then
        charging = true
        charge_timer = 0
    end

    if charging then
        charge_timer = charge_timer + dt
    end

    if lurek.input.released("fire") and charging then
        charging = false
        if charge_timer >= CHARGE_SUPER then
            fire_super()
        elseif charge_timer >= CHARGE_SHIELD then
            fire_shield()
        else
            fire_normal()
        end
        charge_timer = 0
    end
end

-- ---------------------------------------------------------------------------
-- Projectile updates
-- ---------------------------------------------------------------------------
local function update_shots(dt)
    local s = scenes[current_scene]
    local i = 1
    while i <= #shots do
        local sh = shots[i]
        sh.x = sh.x + sh.vx * dt
        sh.y = sh.y + sh.vy * dt
        sh.life = sh.life - dt

        local removed = false

        -- Off-screen or expired
        if sh.life <= 0 or sh.x < -20 or sh.x > SCREEN_W + 20 then
            table.remove(shots, i)
            removed = true
        end

        -- Hit aliens
        if not removed then
            for ai = #aliens, 1, -1 do
                local al = aliens[ai]
                if al.alive and rect_overlap(sh.x - 4, sh.y - 4, 8, 8, al.x - ALIEN_W / 2, al.y - ALIEN_H, ALIEN_W, ALIEN_H) then
                    if sh.kind == "super" then
                        al.hp = al.hp - 3
                    else
                        al.hp = al.hp - 1
                    end
                    if al.hp <= 0 then
                        al.alive = false
                        -- Death burst
                        spawn_particles(al.x, al.y - ALIEN_H / 2, 0.8, 0.2, 0.3, 12, 1.0)
                    end
                    table.remove(shots, i)
                    removed = true
                    break
                end
            end
        end

        -- Super-shot destroys shields it passes through
        if not removed and sh.kind == "super" then
            for si = #shields, 1, -1 do
                local sd = shields[si]
                if math.abs(sh.x - sd.x) < 12 and sh.y > sd.y and sh.y < sd.y + PLAYER_H + 20 then
                    spawn_particles(sd.x, sd.y + 20, 0.3, 0.6, 1.0, 8, 0.5)
                    table.remove(shields, si)
                end
            end
        end

        if not removed then i = i + 1 end
    end
end

local function update_shields(dt)
    local i = 1
    while i <= #shields do
        local sd = shields[i]
        sd.life = sd.life - dt
        sd.shimmer = sd.shimmer + dt * 6
        if sd.life <= 0 then
            table.remove(shields, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Alien AI
-- ---------------------------------------------------------------------------
local function update_aliens(dt)
    for _, al in ipairs(aliens) do
        if al.alive then
            -- Patrol
            al.x = al.x + ALIEN_SPEED * al.facing * dt
            if al.x < al.patrol_l then al.facing = 1 end
            if al.x > al.patrol_r then al.facing = -1 end

            al.anim = al.anim + dt * 5

            -- Shoot at player
            al.fire_cd = al.fire_cd - dt
            if al.fire_cd <= 0 then
                al.fire_cd = ALIEN_FIRE_CD + math.random() * 0.8
                local dx = player.x - al.x
                local dy = (player.y - PLAYER_H / 2) - (al.y - ALIEN_H / 2)
                local len = math.sqrt(dx * dx + dy * dy)
                if len > 0 then
                    dx = dx / len
                    dy = dy / len
                end
                table.insert(alien_projectiles, {
                    x = al.x,
                    y = al.y - ALIEN_H / 2,
                    vx = dx * ALIEN_PROJ_SPEED,
                    vy = dy * ALIEN_PROJ_SPEED,
                })
            end
        end
    end
end

local function update_alien_projectiles(dt)
    local i = 1
    while i <= #alien_projectiles do
        local p = alien_projectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        local removed = false

        -- Off-screen
        if p.x < -20 or p.x > SCREEN_W + 20 or p.y < -20 or p.y > SCREEN_H + 20 then
            table.remove(alien_projectiles, i)
            removed = true
        end

        -- Blocked by shields
        if not removed then
            for _, sd in ipairs(shields) do
                if math.abs(p.x - sd.x) < 10 and p.y > sd.y and p.y < sd.y + PLAYER_H + 20 then
                    table.remove(alien_projectiles, i)
                    removed = true
                    spawn_particles(p.x, p.y, 0.4, 0.6, 1.0, 4, 0.4)
                    break
                end
            end
        end

        -- Hit player
        if not removed then
            if rect_overlap(p.x - 3, p.y - 3, 6, 6, player.x - PLAYER_W / 2, player.y - PLAYER_H, PLAYER_W, PLAYER_H) then
                table.remove(alien_projectiles, i)
                removed = true
                -- Player hit
                lives = lives - 1
                spawn_particles(player.x, player.y - PLAYER_H / 2, 1.0, 0.3, 0.3, 15, 1.0)
                if lives <= 0 then
                    current_state = STATE.GAME_OVER
                else
                    current_state = STATE.DEAD
                    dead_timer = 1.5
                end
            end
        end

        if not removed then i = i + 1 end
    end

    -- Contact damage with aliens
    for _, al in ipairs(aliens) do
        if al.alive and rect_overlap(player.x - PLAYER_W / 2, player.y - PLAYER_H, PLAYER_W, PLAYER_H,
                al.x - ALIEN_W / 2, al.y - ALIEN_H, ALIEN_W, ALIEN_H) then
            lives = lives - 1
            spawn_particles(player.x, player.y - PLAYER_H / 2, 1.0, 0.3, 0.3, 10, 1.0)
            if lives <= 0 then
                current_state = STATE.GAME_OVER
            else
                current_state = STATE.DEAD
                dead_timer = 1.5
            end
            break
        end
    end
end

-- ---------------------------------------------------------------------------
-- Fade transition
-- ---------------------------------------------------------------------------
local function update_fade(dt)
    if fade_dir == 1 then
        fade_alpha = fade_alpha + dt * 2.5
        if fade_alpha >= 1.0 then
            fade_alpha = 1.0
            fade_dir = -1
            if fade_target_scene then
                local target = fade_target_scene
                fade_target_scene = nil
                load_scene(target)
                -- Place player at correct edge
                if scenes[target].exit_right == current_scene or
                   (scenes[current_scene].exit_left == target) then
                    player.x = SCREEN_W - PLAYER_W - 10
                else
                    player.x = PLAYER_W + 10
                end
            end
        end
    elseif fade_dir == -1 then
        fade_alpha = fade_alpha - dt * 2.5
        if fade_alpha <= 0 then
            fade_alpha = 0
            fade_dir = 0
        end
    end
end

-- =========================================================================
-- Lurek callbacks
-- =========================================================================
function lurek.init()
    lurek.window.setTitle("Another World — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.28)

    lurek.input.bind("left",  { "a", "left" })
    lurek.input.bind("right", { "d", "right" })
    lurek.input.bind("jump",  { "space", "w", "up" })
    lurek.input.bind("fire",  { "f" })
    lurek.input.bind("quit",  { "escape" })
    lurek.input.bind("start", { "return" })

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)
    math.randomseed(os.time())
    build_scenes()
    current_state = STATE.TITLE
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    update_particles(dt)
    update_fade(dt)

    -- ── TITLE ──────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.pressed("start") then
            current_state = STATE.INTRO
            intro_timer = 0
            intro_line = 1
        end
        return
    end

    -- ── INTRO ──────────────────────────────────────────────────
    if current_state == STATE.INTRO then
        intro_timer = intro_timer + dt
        if lurek.input.pressed("start") or intro_timer > #intro_lines * 1.2 + 2 then
            current_state = STATE.PLAYING
            load_scene(1)
        end
        return
    end

    -- ── DEAD (respawn delay) ───────────────────────────────────
    if current_state == STATE.DEAD then
        dead_timer = dead_timer - dt
        if dead_timer <= 0 then
            current_state = STATE.PLAYING
            load_scene(current_scene)
        end
        return
    end

    -- ── GAME OVER ──────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        if lurek.input.pressed("start") then
            lives = 3
            current_state = STATE.PLAYING
            load_scene(1)
        end
        return
    end

    -- ── PLAYING ────────────────────────────────────────────────
    if fade_dir == 0 then
        update_player(dt)
        update_gun(dt)
    end
    update_shots(dt)
    update_shields(dt)
    update_aliens(dt)
    update_alien_projectiles(dt)
end

-- ---------------------------------------------------------------------------
-- Render — world scene
-- ---------------------------------------------------------------------------
lurek.render(function()
    cam:attach()

    local s = scenes[current_scene] or scenes[1]

    -- ── Sky / atmosphere ───────────────────────────────────────
    -- Gradient sky: dark blue → deep purple
    for row = 0, 5 do
        local t = row / 5
        local r = 0.03 + t * 0.06
        local g = 0.03 + t * 0.02
        local b = 0.18 - t * 0.08
        lurek.render.setColor(r, g, b, 1)
        lurek.render.rectangle("fill", 0, row * 100, SCREEN_W, 100)
    end

    -- Moon
    if s.moon_x then
        lurek.render.setColor(0.85, 0.82, 0.7, 0.9)
        lurek.render.circle("fill", s.moon_x, s.moon_y, 30)
        lurek.render.setColor(0.05, 0.05, 0.28, 1)
        lurek.render.circle("fill", s.moon_x + 8, s.moon_y - 6, 26)
    end

    -- Distant mountains (silhouettes)
    lurek.render.setColor(0.08, 0.06, 0.15, 0.7)
    for mx = 0, SCREEN_W, 160 do
        local mh = 80 + math.sin(mx * 0.01 + current_scene) * 40
        lurek.render.rectangle("fill", mx, SCREEN_H - 200 - mh, 180, mh + 200)
    end

    -- ── Platforms ──────────────────────────────────────────────
    for _, p in ipairs(s.platforms) do
        lurek.render.setColor(0.12, 0.10, 0.20, 1)
        lurek.render.rectangle("fill", p.x, p.y, p.w, p.h)
        -- Top edge highlight
        lurek.render.setColor(0.25, 0.20, 0.40, 1)
        lurek.render.rectangle("fill", p.x, p.y, p.w, 2)
    end

    -- ── Shields ────────────────────────────────────────────────
    for _, sd in ipairs(shields) do
        local flicker = 0.6 + 0.4 * math.sin(sd.shimmer)
        lurek.render.setColor(0.3, 0.6, 1.0, flicker)
        lurek.render.rectangle("fill", sd.x - 2, sd.y, 4, PLAYER_H + 20)
        lurek.render.setColor(0.5, 0.8, 1.0, flicker * 0.5)
        lurek.render.rectangle("fill", sd.x - 5, sd.y, 10, PLAYER_H + 20)
    end

    -- ── Aliens ─────────────────────────────────────────────────
    for _, al in ipairs(aliens) do
        if al.alive then
            -- Body silhouette
            lurek.render.setColor(0.15, 0.08, 0.08, 1)
            lurek.render.rectangle("fill", al.x - ALIEN_W / 2, al.y - ALIEN_H, ALIEN_W, ALIEN_H)
            -- Head
            lurek.render.circle("fill", al.x, al.y - ALIEN_H - 4, 7)
            -- Eyes (menacing red)
            lurek.render.setColor(1.0, 0.15, 0.1, 0.9)
            local eye_off = al.facing > 0 and 2 or -2
            lurek.render.circle("fill", al.x + eye_off - 2, al.y - ALIEN_H - 5, 2)
            lurek.render.circle("fill", al.x + eye_off + 2, al.y - ALIEN_H - 5, 2)
        end
    end

    -- ── Alien projectiles ──────────────────────────────────────
    for _, p in ipairs(alien_projectiles) do
        lurek.render.setColor(1.0, 0.25, 0.15, 0.9)
        lurek.render.circle("fill", p.x, p.y, 4)
        lurek.render.setColor(1.0, 0.6, 0.3, 0.4)
        lurek.render.circle("fill", p.x, p.y, 7)
    end

    -- ── Player ─────────────────────────────────────────────────
    if current_state == STATE.PLAYING or current_state == STATE.TITLE then
        -- Legs (animated)
        local leg_offset = math.sin(player.anim) * 3
        lurek.render.setColor(0.15, 0.25, 0.5, 1)
        lurek.render.rectangle("fill", player.x - 5, player.y - 10, 4, 10 + leg_offset)
        lurek.render.rectangle("fill", player.x + 1, player.y - 10, 4, 10 - leg_offset)

        -- Body
        lurek.render.setColor(0.2, 0.35, 0.6, 1)
        lurek.render.rectangle("fill", player.x - PLAYER_W / 2, player.y - PLAYER_H, PLAYER_W, PLAYER_H - 10)

        -- Head
        lurek.render.setColor(0.75, 0.6, 0.5, 1)
        lurek.render.circle("fill", player.x, player.y - PLAYER_H - 4, 6)

        -- Gun arm
        lurek.render.setColor(0.3, 0.3, 0.5, 1)
        local gun_x = player.x + player.facing * 8
        local gun_y = player.y - PLAYER_H * 0.6
        lurek.render.rectangle("fill", gun_x, gun_y - 2, player.facing * 10, 4)

        -- Charge indicator
        if charging and charge_timer > 0.1 then
            local charge_pct = clamp(charge_timer / CHARGE_SUPER, 0, 1)
            local cr, cg, cb = 1.0, 0.8 * (1 - charge_pct), 0.2 * (1 - charge_pct)
            lurek.render.setColor(cr, cg, cb, 0.6 + charge_pct * 0.4)
            lurek.render.circle("fill", gun_x + player.facing * 12, gun_y, 3 + charge_pct * 5)
        end
    end

    -- ── Player shots ───────────────────────────────────────────
    for _, sh in ipairs(shots) do
        if sh.kind == "super" then
            lurek.render.setColor(1.0, 0.4, 0.1, 0.9)
            lurek.render.rectangle("fill", sh.x - 6, sh.y - 4, 12, 8)
            lurek.render.setColor(1.0, 0.7, 0.2, 0.5)
            lurek.render.rectangle("fill", sh.x - 9, sh.y - 6, 18, 12)
        else
            lurek.render.setColor(1.0, 0.9, 0.3, 0.9)
            lurek.render.rectangle("fill", sh.x - 3, sh.y - 2, 6, 4)
        end
    end

    -- ── Particles ──────────────────────────────────────────────
    draw_particles()

    cam:detach()
end)

-- ---------------------------------------------------------------------------
-- Render UI — HUD overlay
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    -- ── TITLE screen ───────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(0.0, 0.0, 0.0, 0.5)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(0.85, 0.75, 0.95, 1)
        lurek.render.print("A N O T H E R   W O R L D", SCREEN_W / 2 - 140, 180)

        lurek.render.setColor(0.5, 0.45, 0.65, 0.8)
        lurek.render.print("A Cinematic Platformer", SCREEN_W / 2 - 90, 220)

        lurek.render.setColor(0.6, 0.55, 0.75, 0.6 + 0.3 * math.sin(lurek.timer.getTime() * 3))
        lurek.render.print("Press ENTER to begin", SCREEN_W / 2 - 82, 340)

        lurek.render.setColor(0.4, 0.35, 0.5, 0.5)
        lurek.render.print("F = shoot | hold F = shield | hold longer = super-shot", SCREEN_W / 2 - 210, 420)
        lurek.render.print("A/D = move  |  Space = jump  |  Escape = quit", SCREEN_W / 2 - 180, 445)
        return
    end

    -- ── INTRO sequence ─────────────────────────────────────────
    if current_state == STATE.INTRO then
        lurek.render.setColor(0.0, 0.0, 0.0, 1)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        for idx, line in ipairs(intro_lines) do
            local line_time = (idx - 1) * 1.2
            local alpha = clamp((intro_timer - line_time) / 0.8, 0, 1)
            if alpha > 0 then
                lurek.render.setColor(0.7, 0.65, 0.85, alpha)
                lurek.render.print(line, 180, 140 + idx * 30)
            end
        end

        lurek.render.setColor(0.4, 0.35, 0.5, 0.4 + 0.3 * math.sin(lurek.timer.getTime() * 2))
        lurek.render.print("Press ENTER to skip", SCREEN_W / 2 - 72, SCREEN_H - 60)
        return
    end

    -- ── DEAD screen ────────────────────────────────────────────
    if current_state == STATE.DEAD then
        lurek.render.setColor(0.6, 0.1, 0.1, 0.4)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1, 0.3, 0.3, 1)
        lurek.render.print("YOU DIED", SCREEN_W / 2 - 36, SCREEN_H / 2 - 20)

        lurek.render.setColor(0.8, 0.6, 0.6, 0.7)
        local remaining = string.format("Lives remaining: %d", lives)
        lurek.render.print(remaining, SCREEN_W / 2 - 60, SCREEN_H / 2 + 10)
        return
    end

    -- ── GAME OVER ──────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(0.0, 0.0, 0.0, 0.7)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        lurek.render.print("G A M E   O V E R", SCREEN_W / 2 - 80, SCREEN_H / 2 - 30)

        lurek.render.setColor(0.7, 0.5, 0.5, 0.6 + 0.3 * math.sin(lurek.timer.getTime() * 3))
        lurek.render.print("Press ENTER to restart", SCREEN_W / 2 - 85, SCREEN_H / 2 + 20)
        return
    end

    -- ── HUD (PLAYING) ──────────────────────────────────────────
    -- Scene caption
    local s = scenes[current_scene]
    if s and s.caption then
        lurek.render.setColor(0.7, 0.65, 0.85, 0.6)
        lurek.render.print(s.caption, 20, 12)
    end

    -- Lives
    lurek.render.setColor(0.9, 0.3, 0.3, 0.9)
    for i = 1, lives do
        lurek.render.circle("fill", SCREEN_W - 30 * i, 20, 8)
    end

    -- Scene indicator
    lurek.render.setColor(0.5, 0.5, 0.7, 0.6)
    lurek.render.print(string.format("Scene %d / %d", current_scene, #scenes), SCREEN_W - 100, SCREEN_H - 25)

    -- Shields remaining
    lurek.render.setColor(0.3, 0.6, 1.0, 0.7)
    lurek.render.print(string.format("Shields: %d / %d", MAX_SHIELDS - #shields, MAX_SHIELDS), 20, SCREEN_H - 25)

    -- Charge bar
    if charging and charge_timer > 0.1 then
        local bar_w = 60
        local pct = clamp(charge_timer / CHARGE_SUPER, 0, 1)
        lurek.render.setColor(0.2, 0.2, 0.3, 0.7)
        lurek.render.rectangle("fill", 20, SCREEN_H - 50, bar_w, 8)
        if pct < CHARGE_SHIELD / CHARGE_SUPER then
            lurek.render.setColor(1.0, 0.9, 0.3, 0.9)
        elseif pct < 1 then
            lurek.render.setColor(0.3, 0.6, 1.0, 0.9)
        else
            lurek.render.setColor(1.0, 0.3, 0.1, 0.9)
        end
        lurek.render.rectangle("fill", 20, SCREEN_H - 50, bar_w * pct, 8)
    end

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.5, 0.4)
    lurek.render.print(string.format("FPS: %d", lurek.timer.getFPS()), 10, 36)

    -- ── Fade overlay ───────────────────────────────────────────
    if fade_alpha > 0 then
        lurek.render.setColor(0, 0, 0, fade_alpha)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end
end)
