-- ============================================================================
--  Vertical Climber — Endless Doodle Jump-style vertical platformer
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/vertical_climber
--
--  Controls (bound as input actions — see lurek.init):
--    left   : A / ←
--    right  : D / →
--    shoot  : Space / W
--    quit   : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600

local PLAYER_W, PLAYER_H = 16, 16
local PLAYER_SPEED       = 350
local BOUNCE_VEL         = -500
local SPRING_VEL         = -1000
local GRAVITY            = 900
local BULLET_SPEED       = 600
local BULLET_SIZE        = 3

local PLAT_W, PLAT_H     = 50, 6
local PLAT_GAP_Y_MIN     = 50
local PLAT_GAP_Y_MAX     = 90
local PLAT_INITIAL_COUNT = 12

local MOVING_SPEED_MIN   = 40
local MOVING_SPEED_MAX   = 100
local ENEMY_SPEED        = 30
local ENEMY_RADIUS       = 6

-- Platform types
local P_NORMAL   = 1
local P_MOVING   = 2
local P_CRUMBLE  = 3
local P_SPRING   = 4

-- ── Scene states ──────────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local game_state = STATE.TITLE

-- ── Camera ────────────────────────────────────────────────────────────────
---@type LCamera
local cam = nil
local cam_y = 0  -- world Y of camera top (grows negative as we climb)

-- ── Player ────────────────────────────────────────────────────────────────
local player = {
    x = 0, y = 0, vx = 0, vy = 0,
    alive = true,
}

-- ── Game collections ──────────────────────────────────────────────────────
local platforms  = {}
local enemies    = {}
local bullets    = {}
local score      = 0
local high_score = 0
local max_height = 0   -- highest world-y reached (more negative = higher)
local highest_plat_y = 0  -- world-y of the highest generated platform

-- ── Particles ─────────────────────────────────────────────────────────────
---@type LParticleSystem
local dust_ps    = nil
---@type LParticleSystem
local crumble_ps = nil
---@type LParticleSystem
local spring_ps  = nil
---@type LParticleSystem
local enemy_ps   = nil
---@type LParticleSystem
local bullet_ps  = nil

-- ── Tween / UI ────────────────────────────────────────────────────────────
local score_pop   = { text = "", alpha = 0, y = 0 }
local title_blink = 0

-- ── Helpers ───────────────────────────────────────────────────────────────
local function rand_range(lo, hi)
    return lo + math.random() * (hi - lo)
end

local function difficulty_factor()
    -- 0.0 at ground, approaches 1.0 as height increases
    local h = math.abs(max_height)
    return math.min(h / 8000, 1.0)
end

local function pick_platform_type()
    local d = difficulty_factor()
    local roll = math.random()
    -- Spring chance: 5-10%
    if roll < 0.05 + d * 0.05 then return P_SPRING end
    -- Crumble chance: 5-30%
    if roll < 0.10 + d * 0.30 then return P_CRUMBLE end
    -- Moving chance: 10-25%
    if roll < 0.20 + d * 0.25 then return P_MOVING end
    return P_NORMAL
end

local function make_platform(world_y)
    local ptype = pick_platform_type()
    local p = {
        x = math.random(0, SCREEN_W - PLAT_W),
        y = world_y,
        w = PLAT_W,
        h = PLAT_H,
        ptype = ptype,
        alive = true,
        -- moving platform fields
        base_x = 0,
        move_speed = 0,
        move_dir = 1,
        -- crumble fields
        crumble_timer = 0,
        crumbling = false,
        crumble_vy = 0,
        -- spring fields
        spring_stretch = 0,
    }
    p.base_x = p.x
    if ptype == P_MOVING then
        p.move_speed = rand_range(MOVING_SPEED_MIN, MOVING_SPEED_MAX)
        p.move_dir = math.random() > 0.5 and 1 or -1
    end
    return p
end

local function maybe_spawn_enemy(plat)
    local d = difficulty_factor()
    -- 10-35% chance
    if math.random() < 0.10 + d * 0.25 then
        if plat.ptype == P_NORMAL or plat.ptype == P_MOVING then
            enemies[#enemies + 1] = {
                x = plat.x + plat.w / 2,
                y = plat.y - ENEMY_RADIUS * 2,
                vx = ENEMY_SPEED * (math.random() > 0.5 and 1 or -1),
                plat = plat,
                alive = true,
            }
        end
    end
end

local function generate_initial_platforms()
    platforms = {}
    enemies   = {}
    -- Ground platform (always normal, centered)
    platforms[1] = {
        x = SCREEN_W / 2 - PLAT_W / 2,
        y = SCREEN_H - 80,
        w = PLAT_W, h = PLAT_H,
        ptype = P_NORMAL, alive = true,
        base_x = SCREEN_W / 2 - PLAT_W / 2,
        move_speed = 0, move_dir = 1,
        crumble_timer = 0, crumbling = false, crumble_vy = 0,
        spring_stretch = 0,
    }
    highest_plat_y = platforms[1].y

    for i = 2, PLAT_INITIAL_COUNT do
        local py = highest_plat_y - rand_range(PLAT_GAP_Y_MIN, PLAT_GAP_Y_MAX)
        local p = make_platform(py)
        -- First few platforms are always normal
        if i <= 4 then p.ptype = P_NORMAL end
        platforms[#platforms + 1] = p
        highest_plat_y = py
    end
end

local function generate_platforms_above()
    -- Generate platforms until we have coverage above the camera
    local target_y = cam_y - SCREEN_H
    while highest_plat_y > target_y do
        local py = highest_plat_y - rand_range(PLAT_GAP_Y_MIN, PLAT_GAP_Y_MAX)
        local p = make_platform(py)
        platforms[#platforms + 1] = p
        maybe_spawn_enemy(p)
        highest_plat_y = py
    end
end

local function prune_below_camera()
    -- Remove platforms/enemies/bullets far below camera
    local cutoff = cam_y + SCREEN_H + 200
    local new_plats = {}
    for _, p in ipairs(platforms) do
        if p.y < cutoff then
            new_plats[#new_plats + 1] = p
        end
    end
    platforms = new_plats

    local new_enemies = {}
    for _, e in ipairs(enemies) do
        if e.y < cutoff and e.alive then
            new_enemies[#new_enemies + 1] = e
        end
    end
    enemies = new_enemies

    local new_bullets = {}
    for _, b in ipairs(bullets) do
        if b.y > cam_y - 50 then
            new_bullets[#new_bullets + 1] = b
        end
    end
    bullets = new_bullets
end

local function reset_game()
    game_state = STATE.PLAYING
    player.x = SCREEN_W / 2 - PLAYER_W / 2
    player.y = SCREEN_H - 80 - PLAYER_H
    player.vx = 0
    player.vy = 0
    player.alive = true
    score = 0
    max_height = 0
    cam_y = 0
    bullets = {}
    generate_initial_platforms()
end

-- ── Sky color based on altitude ───────────────────────────────────────────
local function sky_color()
    local h = math.abs(max_height)
    local t = math.min(h / 10000, 1.0)
    -- Light sky blue → dark navy
    local r = 0.6 * (1 - t * 0.7)
    local g = 0.75 * (1 - t * 0.6)
    local b = 0.9 * (1 - t * 0.3)
    return r, g, b
end

-- ── Engine callbacks ──────────────────────────────────────────────────────

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

function lurek.init()
    lurek.window.setTitle("Vertical Climber — Lurek2D")
    lurek.render.setBackgroundColor(0.6, 0.75, 0.9)

    -- Input actions
    lurek.input.bind("left",  {"a", "left"})
    lurek.input.bind("right", {"d", "right"})
    lurek.input.bind("shoot", {"space", "w"})
    lurek.input.bind("quit",  {"escape"})

    -- Camera
    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle systems
    dust_ps = lurek.particle.newSystem({
        maxParticles = 15, lifetime = 0.25,
        speed = 25, spread = 3.14,
        sizeStart = 3, sizeEnd = 1,
        colorStart = {0.7, 0.6, 0.4, 0.7},
        colorEnd   = {0.7, 0.6, 0.4, 0.0},
    })
    crumble_ps = lurek.particle.newSystem({
        maxParticles = 25, lifetime = 0.6,
        speed = 80, spread = 1.5,
        sizeStart = 4, sizeEnd = 2,
        colorStart = {0.55, 0.35, 0.15, 1.0},
        colorEnd   = {0.4,  0.25, 0.1,  0.0},
    })
    spring_ps = lurek.particle.newSystem({
        maxParticles = 20, lifetime = 0.4,
        speed = 60, spread = 6.28,
        sizeStart = 3, sizeEnd = 1,
        colorStart = {1.0, 0.95, 0.2, 0.9},
        colorEnd   = {1.0, 0.85, 0.0, 0.0},
    })
    enemy_ps = lurek.particle.newSystem({
        maxParticles = 20, lifetime = 0.4,
        speed = 70, spread = 6.28,
        sizeStart = 4, sizeEnd = 1,
        colorStart = {1.0, 0.2, 0.1, 1.0},
        colorEnd   = {0.5, 0.0, 0.0, 0.0},
    })
    bullet_ps = lurek.particle.newSystem({
        maxParticles = 10, lifetime = 0.2,
        speed = 40, spread = 6.28,
        sizeStart = 2, sizeEnd = 1,
        colorStart = {1.0, 1.0, 1.0, 0.8},
        colorEnd   = {0.8, 0.8, 0.8, 0.0},
    })
end

local function _ready_setup()
    generate_initial_platforms()
end

-- ── Process ───────────────────────────────────────────────────────────────
function lurek.process(dt)
    title_blink = title_blink + dt

    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── Title ─────────────────────────────────────────────────────────────
    if game_state == STATE.TITLE then
        if lurek.input.wasActionPressed("return") then
            reset_game()
        end
        return
    end

    -- ── Game Over ─────────────────────────────────────────────────────────
    if game_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("return") then
            game_state = STATE.TITLE
        end
        return
    end

    -- ── Playing ───────────────────────────────────────────────────────────

    -- Horizontal movement
    local move_x = 0
    if lurek.input.isActionDown("left")  then move_x = move_x - 1 end
    if lurek.input.isActionDown("right") then move_x = move_x + 1 end
    player.vx = move_x * PLAYER_SPEED

    -- Shooting
    if lurek.input.wasActionPressed("shoot") then
        bullets[#bullets + 1] = {
            x = player.x + PLAYER_W / 2 - BULLET_SIZE / 2,
            y = player.y - BULLET_SIZE,
        }
        bullet_ps:moveTo(player.x + PLAYER_W / 2, player.y)
        bullet_ps:emit(4)
    end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt
    if player.vy > 800 then player.vy = 800 end

    -- Move player horizontally
    player.x = player.x + player.vx * dt

    -- Screen wrapping
    if player.x + PLAYER_W < 0 then
        player.x = SCREEN_W
    elseif player.x > SCREEN_W then
        player.x = -PLAYER_W
    end

    -- Move player vertically
    player.y = player.y + player.vy * dt

    -- Platform collision (only when falling)
    if player.vy > 0 then
        for _, p in ipairs(platforms) do
            if p.alive and not p.crumbling then
                local foot_y = player.y + PLAYER_H
                local prev_foot = foot_y - player.vy * dt

                if player.x + PLAYER_W > p.x and player.x < p.x + p.w then
                    if prev_foot <= p.y and foot_y >= p.y and foot_y <= p.y + p.h + 8 then
                        -- Land on platform!
                        player.y = p.y - PLAYER_H
                        dust_ps:moveTo(player.x + PLAYER_W / 2, p.y)
                        dust_ps:emit(5)

                        if p.ptype == P_SPRING then
                            -- Spring bounce: 2x height
                            player.vy = SPRING_VEL
                            spring_ps:moveTo(p.x + p.w / 2, p.y)
                            spring_ps:emit(12)
                            -- Animate spring stretch
                            p.spring_stretch = 6
                            lurek.tween.to(p, 0.3, { spring_stretch = 0 })
                        elseif p.ptype == P_CRUMBLE then
                            -- Normal bounce, then platform crumbles
                            player.vy = BOUNCE_VEL
                            p.crumbling = true
                            p.crumble_timer = 0.2
                        else
                            -- Normal / moving bounce
                            player.vy = BOUNCE_VEL
                        end
                        break
                    end
                end
            end
        end
    end

    -- Update moving platforms
    for _, p in ipairs(platforms) do
        if p.alive and p.ptype == P_MOVING then
            p.x = p.x + p.move_speed * p.move_dir * dt
            if p.x <= 0 then
                p.x = 0
                p.move_dir = 1
            elseif p.x + p.w >= SCREEN_W then
                p.x = SCREEN_W - p.w
                p.move_dir = -1
            end
        end
    end

    -- Update crumbling platforms
    for _, p in ipairs(platforms) do
        if p.crumbling then
            p.crumble_timer = p.crumble_timer - dt
            if p.crumble_timer <= 0 then
                p.alive = false
                crumble_ps:moveTo(p.x + p.w / 2, p.y + p.h / 2)
                crumble_ps:emit(15)
            end
        end
    end

    -- Update enemies (patrol on their platform)
    for _, e in ipairs(enemies) do
        if e.alive and e.plat.alive then
            e.x = e.x + e.vx * dt
            e.y = e.plat.y - ENEMY_RADIUS * 2
            -- Bounce at platform edges
            if e.x - ENEMY_RADIUS < e.plat.x then
                e.x = e.plat.x + ENEMY_RADIUS
                e.vx = math.abs(e.vx)
            elseif e.x + ENEMY_RADIUS > e.plat.x + e.plat.w then
                e.x = e.plat.x + e.plat.w - ENEMY_RADIUS
                e.vx = -math.abs(e.vx)
            end

            -- Collision with player
            local dx = (player.x + PLAYER_W / 2) - e.x
            local dy = (player.y + PLAYER_H / 2) - (e.y + ENEMY_RADIUS)
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < ENEMY_RADIUS + PLAYER_W / 2 then
                -- Player dies — falls down
                player.alive = false
                player.vy = 200
                enemy_ps:moveTo(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2)
                enemy_ps:emit(15)
            end
        elseif not e.plat.alive then
            e.alive = false
        end
    end

    -- Update bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.y = b.y - BULLET_SPEED * dt

        -- Bullet vs enemy
        local hit = false
        for _, e in ipairs(enemies) do
            if e.alive then
                local dx = (b.x + BULLET_SIZE / 2) - e.x
                local dy = (b.y + BULLET_SIZE / 2) - (e.y + ENEMY_RADIUS)
                if math.sqrt(dx * dx + dy * dy) < ENEMY_RADIUS + BULLET_SIZE then
                    e.alive = false
                    enemy_ps:moveTo(e.x, e.y + ENEMY_RADIUS)
                    enemy_ps:emit(12)
                    bullet_ps:moveTo(b.x, b.y)
                    bullet_ps:emit(5)
                    score_pop.text = "+50"
                    score_pop.alpha = 1.0
                    score_pop.y = e.y
                    lurek.tween.to(score_pop, 0.6, { alpha = 0, y = score_pop.y - 25 })
                    score = score + 50
                    hit = true
                    break
                end
            end
        end
        if hit then
            table.remove(bullets, i)
        end
    end

    -- Track max height (score)
    if player.y < max_height then
        max_height = player.y
    end
    score = math.max(score, math.floor(math.abs(max_height) / 10))

    -- Camera: follow player upward, never descend
    local target_cam = player.y - SCREEN_H * 0.4
    if target_cam < cam_y then
        cam_y = cam_y + (target_cam - cam_y) * 5 * dt
    end

    -- Generate new platforms above camera
    generate_platforms_above()

    -- Remove objects far below
    prune_below_camera()

    -- Game over: fell below camera bottom
    if player.y > cam_y + SCREEN_H + 50 then
        game_state = STATE.GAME_OVER
        if score > high_score then
            high_score = score
        end
    end

    -- Update sky color based on altitude
    local sr, sg, sb = sky_color()
    lurek.render.setBackgroundColor(sr, sg, sb)

    -- Update particles
    dust_ps:update(dt)
    crumble_ps:update(dt)
    spring_ps:update(dt)
    enemy_ps:update(dt)
    bullet_ps:update(dt)
end

-- ── Render (world space) ──────────────────────────────────────────────────
function lurek.draw()
    if game_state == STATE.TITLE then return end

    local oy = -cam_y

    -- ── Platforms ─────────────────────────────────────────────────────────
    for _, p in ipairs(platforms) do
        if p.alive then
            local px = p.x
            local py = p.y + oy

            if p.ptype == P_NORMAL then
                -- Green platform
                lurek.render.setColor(0.2, 0.75, 0.3, 1)
                rect(px, py, p.w, p.h)
                -- Grass accent on top
                lurek.render.setColor(0.3, 0.85, 0.4, 1)
                rect(px, py, p.w, 2)

            elseif p.ptype == P_MOVING then
                -- Blue platform
                lurek.render.setColor(0.2, 0.5, 0.9, 1)
                rect(px, py, p.w, p.h)
                -- Arrow indicators
                lurek.render.setColor(0.4, 0.7, 1.0, 0.7)
                rect(px + 2, py + 1, 4, 4)
                rect(px + p.w - 6, py + 1, 4, 4)

            elseif p.ptype == P_CRUMBLE then
                -- Brown platform with cracks
                local shake = p.crumbling and (math.random() * 2 - 1) or 0
                lurek.render.setColor(0.55, 0.35, 0.15, 1)
                rect(px + shake, py, p.w, p.h)
                -- Crack lines
                lurek.render.setColor(0.35, 0.2, 0.08, 1)
                rect(px + 8 + shake, py + 1, 6, 1)
                rect(px + 20 + shake, py + 3, 8, 1)
                rect(px + 35 + shake, py + 2, 5, 1)

            elseif p.ptype == P_SPRING then
                -- Yellow platform base
                lurek.render.setColor(0.85, 0.75, 0.1, 1)
                rect(px, py, p.w, p.h)
                -- Coil spring on top
                local stretch = p.spring_stretch or 0
                lurek.render.setColor(0.95, 0.85, 0.15, 1)
                rect(px + p.w / 2 - 4, py - 8 - stretch, 8, 8 + stretch)
                -- Coil lines
                lurek.render.setColor(0.7, 0.6, 0.0, 1)
                for ci = 0, 2 do
                    local cy = py - 2 - ci * 3 - stretch * (ci / 3)
                    rect(px + p.w / 2 - 5, cy, 10, 1)
                end
            end
        end
    end

    -- ── Enemies ───────────────────────────────────────────────────────────
    for _, e in ipairs(enemies) do
        if e.alive then
            local ex = e.x
            local ey = e.y + oy
            -- Red circle body (drawn as small rects to approximate)
            lurek.render.setColor(0.9, 0.15, 0.1, 1)
            rect(ex - ENEMY_RADIUS, ey, ENEMY_RADIUS * 2, ENEMY_RADIUS * 2)
            rect(ex - ENEMY_RADIUS + 1, ey - 1, ENEMY_RADIUS * 2 - 2, ENEMY_RADIUS * 2 + 2)
            -- Angry eyes
            lurek.render.setColor(1, 1, 1, 1)
            rect(ex - 3, ey + 3, 2, 2)
            rect(ex + 2, ey + 3, 2, 2)
        end
    end

    -- ── Bullets ───────────────────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1, 1)
    for _, b in ipairs(bullets) do
        rect(b.x, b.y + oy, BULLET_SIZE, BULLET_SIZE)
    end

    -- ── Player ────────────────────────────────────────────────────────────
    local px = player.x
    local py = player.y + oy

    -- Body (blue square)
    lurek.render.setColor(0.2, 0.4, 0.9, 1)
    rect(px, py, PLAYER_W, PLAYER_H)
    -- Highlight
    lurek.render.setColor(0.35, 0.55, 1.0, 0.5)
    rect(px + 1, py + 1, PLAYER_W - 4, 3)
    -- Eyes
    lurek.render.setColor(1, 1, 1, 1)
    rect(px + 3, py + 4, 3, 3)
    rect(px + 10, py + 4, 3, 3)
    -- Pupils
    lurek.render.setColor(0, 0, 0, 1)
    rect(px + 4, py + 5, 2, 2)
    rect(px + 11, py + 5, 2, 2)

    -- ── Particles (world space) ───────────────────────────────────────────
    dust_ps:render()
    crumble_ps:render()
    spring_ps:render()
    enemy_ps:render()
    bullet_ps:render()
end

-- ── Render UI (screen space) ──────────────────────────────────────────────
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    -- ── Title screen ──────────────────────────────────────────────────────
    if game_state == STATE.TITLE then
        lurek.render.setColor(1, 1, 1, 1)
        text_("VERTICAL CLIMBER", SCREEN_W / 2 - 120, 160, 32)

        lurek.render.setColor(0.8, 0.85, 1.0, 1)
        text_("Auto-bounce to the top!", SCREEN_W / 2 - 100, 220, 16)

        if high_score > 0 then
            lurek.render.setColor(1, 0.9, 0.2, 1)
            text_("HIGH SCORE: " .. high_score, SCREEN_W / 2 - 70, 280, 18)
        end

        -- Blink prompt
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 0.9)
            text_("PRESS ENTER", SCREEN_W / 2 - 60, 360, 18)
        end

        -- Controls
        lurek.render.setColor(0.7, 0.7, 0.8, 0.7)
        text_("A/D  Move   Space/W  Shoot   Esc  Quit", SCREEN_W / 2 - 160, 440, 14)

        lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
        text_("FPS: " .. fps, 10, SCREEN_H - 20, 12)
        return
    end

    -- ── Game Over screen ──────────────────────────────────────────────────
    if game_state == STATE.GAME_OVER then
        lurek.render.setColor(0.9, 0.15, 0.15, 1)
        text_("GAME OVER", SCREEN_W / 2 - 80, 200, 32)

        lurek.render.setColor(1, 1, 1, 1)
        text_("Score: " .. score, SCREEN_W / 2 - 50, 270, 22)

        if score >= high_score and high_score > 0 then
            lurek.render.setColor(1, 0.9, 0.2, 1)
            text_("NEW HIGH SCORE!", SCREEN_W / 2 - 80, 310, 20)
        end

        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 0.9)
            text_("PRESS ENTER", SCREEN_W / 2 - 60, 380, 18)
        end

        lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
        text_("FPS: " .. fps, 10, SCREEN_H - 20, 12)
        return
    end

    -- ── HUD (playing) ─────────────────────────────────────────────────────
    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    text_("Score: " .. score, 10, 10, 18)

    -- High score
    if high_score > 0 then
        lurek.render.setColor(1, 0.9, 0.2, 0.8)
        text_("Best: " .. high_score, 10, 34, 14)
    end

    -- Height indicator
    local height_m = math.floor(math.abs(max_height) / 10)
    lurek.render.setColor(0.8, 0.9, 1.0, 0.7)
    text_(height_m .. "m", SCREEN_W - 60, 10, 16)

    -- Score popup
    if score_pop.alpha > 0.01 then
        lurek.render.setColor(1, 1, 0.3, score_pop.alpha)
        local pop_screen_y = score_pop.y - cam_y
        text_(score_pop.text, SCREEN_W / 2 - 15, pop_screen_y, 16)
    end

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
    text_("FPS: " .. fps, SCREEN_W - 70, SCREEN_H - 20, 12)
end
