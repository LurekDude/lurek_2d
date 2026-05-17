-- Golf Classic — Lurek2D
-- Category: sports
-- A 9-hole top-down mini golf game with terrain, wind, and scoring.
-- Controls: Mouse aim, Space/Mouse1 charge+release to shoot, Escape quit
-- Run with: cargo run -- content/games/sports/golf_classic

-- ── Constants ─────────────────────────────────────────────────────
local W, H = 800, 600
local BALL_R = 6
local HOLE_R = 10
local MAX_POWER = 100
local MAX_VEL = 500
local SINK_DIST = 10
local SINK_SPEED = 10
local CHARGE_RATE = 120
local TRAIL_INTERVAL = 0.02

-- Terrain friction multipliers (applied per frame)
local FRICTION_FAIRWAY = 0.97
local FRICTION_ROUGH = 0.95
local FRICTION_SAND = 0.90

-- ── States ────────────────────────────────────────────────────────
local S_TITLE = "TITLE"
local S_AIMING = "AIMING"
local S_MOVING = "BALL_MOVING"
local S_HOLE_DONE = "HOLE_COMPLETE"
local S_SCORECARD = "SCORECARD"

-- ── Game state ────────────────────────────────────────────────────
local state = S_TITLE
local current_hole = 1
local strokes = 0
local hole_strokes = {}
local ball = { x = 0, y = 0, vx = 0, vy = 0 }
local last_ball = { x = 0, y = 0 }
local power = 0
local charging = false
local aim_x, aim_y = 0, 0
local particles = {}
local trail_timer = 0
local transition_timer = 0
local title_blink = 0
local power_tween = 0
local sink_anim = 0

-- ── Wind ──────────────────────────────────────────────────────────
local wind = { dx = 0, dy = 0, strength = 0 }

local function randomize_wind()
    local angle = math.random() * math.pi * 2
    wind.strength = math.random() * 30 + 5
    wind.dx = math.cos(angle) * wind.strength
    wind.dy = math.sin(angle) * wind.strength
end

-- ── Hole definitions ──────────────────────────────────────────────
-- Each hole: tee, target, par, walls, bunkers, water, rough_zones
local holes = {}

local function make_holes()
    holes = {
        -- Hole 1: straight shot
        {
            tee = { x = 400, y = 500 }, target = { x = 400, y = 120 }, par = 2,
            walls = {
                { x = 340, y = 80, w = 10, h = 460 },
                { x = 450, y = 80, w = 10, h = 460 },
            },
            bunkers = {}, water = {}, rough = {},
        },
        -- Hole 2: slight dogleg with bunker
        {
            tee = { x = 200, y = 500 }, target = { x = 600, y = 120 }, par = 3,
            walls = {
                { x = 130, y = 60, w = 10, h = 500 },
                { x = 660, y = 60, w = 10, h = 500 },
                { x = 350, y = 200, w = 10, h = 200 },
            },
            bunkers = { { x = 450, y = 300, w = 80, h = 50 } },
            water = {}, rough = {},
        },
        -- Hole 3: water hazard
        {
            tee = { x = 400, y = 520 }, target = { x = 400, y = 100 }, par = 3,
            walls = {
                { x = 300, y = 60, w = 10, h = 500 },
                { x = 500, y = 60, w = 10, h = 500 },
            },
            bunkers = {},
            water = { { x = 340, y = 260, w = 130, h = 60 } },
            rough = {},
        },
        -- Hole 4: narrow corridor with rough
        {
            tee = { x = 150, y = 500 }, target = { x = 650, y = 100 }, par = 4,
            walls = {
                { x = 100, y = 60, w = 10, h = 500 },
                { x = 700, y = 60, w = 10, h = 500 },
                { x = 300, y = 150, w = 10, h = 250 },
                { x = 500, y = 200, w = 10, h = 250 },
            },
            bunkers = { { x = 550, y = 120, w = 60, h = 40 } },
            water = {},
            rough = { { x = 200, y = 300, w = 100, h = 100 } },
        },
        -- Hole 5: island green surrounded by water
        {
            tee = { x = 400, y = 520 }, target = { x = 400, y = 150 }, par = 3,
            walls = {
                { x = 280, y = 60, w = 10, h = 500 },
                { x = 520, y = 60, w = 10, h = 500 },
            },
            bunkers = {},
            water = {
                { x = 320, y = 100, w = 170, h = 30 },
                { x = 320, y = 200, w = 170, h = 30 },
                { x = 320, y = 100, w = 30, h = 130 },
                { x = 460, y = 100, w = 30, h = 130 },
            },
            rough = {},
        },
        -- Hole 6: zigzag with walls and bunkers
        {
            tee = { x = 150, y = 520 }, target = { x = 650, y = 100 }, par = 4,
            walls = {
                { x = 100, y = 60, w = 10, h = 500 },
                { x = 700, y = 60, w = 10, h = 500 },
                { x = 300, y = 60, w = 10, h = 200 },
                { x = 500, y = 340, w = 10, h = 220 },
            },
            bunkers = {
                { x = 200, y = 300, w = 80, h = 50 },
                { x = 550, y = 200, w = 80, h = 50 },
            },
            water = {},
            rough = { { x = 350, y = 400, w = 100, h = 80 } },
        },
        -- Hole 7: long par 5 with multiple hazards
        {
            tee = { x = 100, y = 520 }, target = { x = 700, y = 80 }, par = 5,
            walls = {
                { x = 50, y = 40, w = 10, h = 530 },
                { x = 750, y = 40, w = 10, h = 530 },
                { x = 250, y = 150, w = 10, h = 250 },
                { x = 550, y = 200, w = 10, h = 250 },
            },
            bunkers = {
                { x = 150, y = 300, w = 70, h = 40 },
                { x = 600, y = 150, w = 70, h = 40 },
            },
            water = { { x = 350, y = 350, w = 100, h = 50 } },
            rough = { { x = 400, y = 100, w = 100, h = 80 } },
        },
        -- Hole 8: tight chicane
        {
            tee = { x = 400, y = 540 }, target = { x = 400, y = 80 }, par = 4,
            walls = {
                { x = 300, y = 40, w = 10, h = 530 },
                { x = 500, y = 40, w = 10, h = 530 },
                { x = 340, y = 200, w = 130, h = 10 },
                { x = 340, y = 350, w = 130, h = 10 },
            },
            bunkers = { { x = 350, y = 100, w = 50, h = 40 } },
            water = { { x = 350, y = 420, w = 110, h = 40 } },
            rough = {},
        },
        -- Hole 9: grand finale — everything
        {
            tee = { x = 100, y = 540 }, target = { x = 700, y = 80 }, par = 5,
            walls = {
                { x = 50, y = 40, w = 10, h = 530 },
                { x = 750, y = 40, w = 10, h = 530 },
                { x = 200, y = 40, w = 10, h = 200 },
                { x = 400, y = 300, w = 10, h = 270 },
                { x = 600, y = 40, w = 10, h = 250 },
            },
            bunkers = {
                { x = 250, y = 350, w = 80, h = 50 },
                { x = 500, y = 150, w = 80, h = 50 },
            },
            water = {
                { x = 120, y = 200, w = 80, h = 60 },
                { x = 620, y = 300, w = 80, h = 60 },
            },
            rough = {
                { x = 300, y = 100, w = 80, h = 80 },
                { x = 450, y = 400, w = 80, h = 80 },
            },
        },
    }
end

-- ── Helpers ───────────────────────────────────────────────────────

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function spawn_particles(x, y, count, r, g, b, speed, life)
    speed = speed or 80
    life = life or 0.4
    for i = 1, count do
        local a = math.random() * math.pi * 2
        local s = speed * (0.4 + math.random() * 0.6)
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(a) * s, vy = math.sin(a) * s,
            life = life + math.random() * 0.2,
            r = r, g = g, b = b, a = 1,
            size = 2 + math.random() * 2,
        }
    end
end

local function point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

local function get_terrain_friction(bx, by)
    local h = holes[current_hole]
    -- Water: instant stop + penalty
    for _, w in ipairs(h.water) do
        if point_in_rect(bx, by, w.x, w.y, w.w, w.h) then
            return 0, "water"
        end
    end
    -- Sand
    for _, s in ipairs(h.bunkers) do
        if point_in_rect(bx, by, s.x, s.y, s.w, s.h) then
            return FRICTION_SAND, "sand"
        end
    end
    -- Rough
    for _, r in ipairs(h.rough) do
        if point_in_rect(bx, by, r.x, r.y, r.w, r.h) then
            return FRICTION_ROUGH, "rough"
        end
    end
    return FRICTION_FAIRWAY, "fairway"
end

local function setup_hole(n)
    local h = holes[n]
    ball.x = h.tee.x
    ball.y = h.tee.y
    ball.vx = 0
    ball.vy = 0
    last_ball.x = h.tee.x
    last_ball.y = h.tee.y
    strokes = 0
    power = 0
    charging = false
    sink_anim = 0
    particles = {}
    randomize_wind()
    state = S_AIMING
end

local function total_strokes()
    local t = 0
    for _, s in ipairs(hole_strokes) do t = t + s end
    return t
end

local function total_par()
    local t = 0
    for _, h in ipairs(holes) do t = t + h.par end
    return t
end

-- ── Input ─────────────────────────────────────────────────────────

lurek.input.bind("shoot", {"space", "mouse1"})
lurek.input.bind("quit", "escape")

-- ── Callbacks ─────────────────────────────────────────────────────

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
    lurek.window.setTitle("Golf Classic — Lurek2D")
    lurek.render.setBackgroundColor(0.2, 0.5, 0.2)
    make_holes()
end

local function _ready_setup()
    -- camera positioning handled by render pipeline
end

function lurek.process(dt)
    title_blink = title_blink + dt

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.a = clamp(p.life / 0.3, 0, 1)
        p.size = p.size * (1 - dt * 2)
        if p.life <= 0 then table.remove(particles, i) end
    end

    if lurek.input.isActionDown("quit") then
        lurek.event.quit()
        return
    end

    -- ── TITLE ──
    if state == S_TITLE then
        if lurek.input.isActionDown("shoot") then
            hole_strokes = {}
            current_hole = 1
            setup_hole(1)
        end
        return
    end

    -- ── SCORECARD ──
    if state == S_SCORECARD then
        if lurek.input.isActionDown("shoot") then
            state = S_TITLE
        end
        return
    end

    -- ── HOLE COMPLETE ──
    if state == S_HOLE_DONE then
        transition_timer = transition_timer - dt
        sink_anim = clamp(sink_anim + dt * 4, 0, 1)
        if transition_timer <= 0 then
            if current_hole >= #holes then
                state = S_SCORECARD
            else
                current_hole = current_hole + 1
                setup_hole(current_hole)
            end
        end
        return
    end

    -- Mouse aim
    aim_x, aim_y = lurek.input.mouse.getPosition()

    -- ── AIMING ──
    if state == S_AIMING then
        if lurek.input.isActionDown("shoot") then
            charging = true
            power = clamp(power + CHARGE_RATE * dt, 0, MAX_POWER)
            power_tween = power / MAX_POWER
        elseif charging then
            -- Shoot
            charging = false
            local dx = ball.x - aim_x
            local dy = ball.y - aim_y
            local d = dist(ball.x, ball.y, aim_x, aim_y)
            if d > 1 then
                local vel = (power / MAX_POWER) * MAX_VEL
                ball.vx = (dx / d) * vel
                ball.vy = (dy / d) * vel
            end
            last_ball.x = ball.x
            last_ball.y = ball.y
            strokes = strokes + 1
            power = 0
            power_tween = 0
            state = S_MOVING
        end
        return
    end

    -- ── BALL MOVING ──
    if state == S_MOVING then
        -- Apply wind
        ball.vx = ball.vx + wind.dx * dt
        ball.vy = ball.vy + wind.dy * dt

        -- Move ball
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt

        -- Terrain friction
        local friction, terrain = get_terrain_friction(ball.x, ball.y)
        if terrain == "water" then
            -- Water hazard: penalty, return to last position
            spawn_particles(ball.x, ball.y, 15, 0.2, 0.4, 1.0, 100, 0.5)
            strokes = strokes + 1
            ball.x = last_ball.x
            ball.y = last_ball.y
            ball.vx = 0
            ball.vy = 0
            state = S_AIMING
            return
        end

        if terrain == "sand" then
            -- Sand spray particles
            trail_timer = trail_timer + dt
            if trail_timer >= 0.06 then
                trail_timer = 0
                spawn_particles(ball.x, ball.y, 2, 0.9, 0.8, 0.4, 30, 0.2)
            end
        end

        ball.vx = ball.vx * friction
        ball.vy = ball.vy * friction

        -- Wall collisions (bounce)
        local h = holes[current_hole]
        for _, w in ipairs(h.walls) do
            if point_in_rect(ball.x, ball.y, w.x - BALL_R, w.y - BALL_R, w.w + BALL_R * 2, w.h + BALL_R * 2) then
                -- Determine bounce axis
                local cx = clamp(ball.x, w.x, w.x + w.w)
                local cy = clamp(ball.y, w.y, w.y + w.h)
                local dx = ball.x - cx
                local dy = ball.y - cy
                local d = math.sqrt(dx * dx + dy * dy)
                if d < BALL_R and d > 0.001 then
                    local nx, ny = dx / d, dy / d
                    ball.x = cx + nx * (BALL_R + 1)
                    ball.y = cy + ny * (BALL_R + 1)
                    local dot = ball.vx * nx + ball.vy * ny
                    ball.vx = ball.vx - 2 * dot * nx
                    ball.vy = ball.vy - 2 * dot * ny
                    -- Dampen on bounce
                    ball.vx = ball.vx * 0.8
                    ball.vy = ball.vy * 0.8
                end
            end
        end

        -- Screen boundary bounce
        if ball.x < BALL_R then ball.x = BALL_R; ball.vx = math.abs(ball.vx) * 0.7 end
        if ball.x > W - BALL_R then ball.x = W - BALL_R; ball.vx = -math.abs(ball.vx) * 0.7 end
        if ball.y < BALL_R then ball.y = BALL_R; ball.vy = math.abs(ball.vy) * 0.7 end
        if ball.y > H - BALL_R then ball.y = H - BALL_R; ball.vy = -math.abs(ball.vy) * 0.7 end

        -- Ball trail particles
        trail_timer = trail_timer + dt
        if trail_timer >= TRAIL_INTERVAL then
            trail_timer = 0
            local spd = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
            if spd > 20 then
                particles[#particles + 1] = {
                    x = ball.x, y = ball.y, vx = 0, vy = 0,
                    life = 0.3, r = 1, g = 1, b = 1, a = 0.4,
                    size = BALL_R * 0.6,
                }
            end
        end

        -- Check if ball stopped
        local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
        local target = h.target

        -- Hole sink detection
        if speed < SINK_SPEED * 10 and dist(ball.x, ball.y, target.x, target.y) < SINK_DIST then
            -- Ball sinks!
            ball.vx = 0
            ball.vy = 0
            spawn_particles(target.x, target.y, 20, 1, 0.9, 0.3, 120, 0.6)
            hole_strokes[#hole_strokes + 1] = strokes
            transition_timer = 2.0
            sink_anim = 0
            state = S_HOLE_DONE
            return
        end

        if speed < 2 then
            ball.vx = 0
            ball.vy = 0
            state = S_AIMING
        end
    end
end

-- ── Render — course, ball, hole ───────────────────────────────────

function lurek.draw()
    if state == S_TITLE or state == S_SCORECARD then return end

    local h = holes[current_hole]

    -- Draw fairway background
    lurek.render.setColor(0.18, 0.55, 0.18, 1)
    rect("fill", 0, 0, W, H)

    -- Draw rough zones
    for _, r in ipairs(h.rough) do
        lurek.render.setColor(0.1, 0.35, 0.1, 1)
        rect("fill", r.x, r.y, r.w, r.h)
    end

    -- Draw sand bunkers
    for _, s in ipairs(h.bunkers) do
        lurek.render.setColor(0.85, 0.78, 0.45, 1)
        rect("fill", s.x, s.y, s.w, s.h)
    end

    -- Draw water hazards
    for _, w in ipairs(h.water) do
        lurek.render.setColor(0.15, 0.3, 0.8, 0.8)
        rect("fill", w.x, w.y, w.w, w.h)
    end

    -- Draw walls
    for _, w in ipairs(h.walls) do
        lurek.render.setColor(0.45, 0.3, 0.15, 1)
        rect("fill", w.x, w.y, w.w, w.h)
    end

    -- Draw hole target
    lurek.render.setColor(0.08, 0.08, 0.08, 1)
    circ("fill", h.target.x, h.target.y, HOLE_R)
    lurek.render.setColor(0.15, 0.15, 0.15, 1)
    circ("line", h.target.x, h.target.y, HOLE_R)

    -- Flag pole
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    ln(h.target.x, h.target.y, h.target.x, h.target.y - 30)
    lurek.render.setColor(1, 0.2, 0.2, 1)
    rect("fill", h.target.x, h.target.y - 30, 15, 10)

    -- Aim line
    if state == S_AIMING then
        local dx = ball.x - aim_x
        local dy = ball.y - aim_y
        local d = dist(ball.x, ball.y, aim_x, aim_y)
        if d > 1 then
            local nx, ny = dx / d, dy / d
            local line_len = 40 + (power / MAX_POWER) * 80
            lurek.render.setColor(1, 1, 1, 0.5)
            ln(ball.x, ball.y, ball.x + nx * line_len, ball.y + ny * line_len)
        end
    end

    -- Particles
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.a)
        circ("fill", p.x, p.y, p.size)
    end

    -- Ball
    if state ~= S_HOLE_DONE then
        lurek.render.setColor(1, 1, 1, 1)
        circ("fill", ball.x, ball.y, BALL_R)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        circ("line", ball.x, ball.y, BALL_R)
    else
        -- Sinking animation: shrink into hole
        local r = BALL_R * (1 - sink_anim)
        if r > 0.5 then
            lurek.render.setColor(1, 1, 1, 1 - sink_anim)
            circ("fill", holes[current_hole].target.x, holes[current_hole].target.y, r)
        end
    end
end

-- ── Render UI — HUD, power bar, scores ────────────────────────────

function lurek.draw_ui()
    -- ── TITLE SCREEN ──
    if state == S_TITLE then
        lurek.render.setColor(0.05, 0.2, 0.05, 1)
        rect("fill", 0, 0, W, H)

        lurek.render.setColor(1, 1, 1, 1)
        text_("GOLF CLASSIC", W / 2 - 80, 180)

        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(0.8, 0.9, 0.4, 1)
            text_("TEE OFF", W / 2 - 40, 260)
        end

        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        text_("Mouse to aim — Space/Click to charge — Release to shoot", W / 2 - 200, 340)
        text_("9 holes of mini golf", W / 2 - 70, 380)
        return
    end

    -- ── SCORECARD ──
    if state == S_SCORECARD then
        lurek.render.setColor(0.05, 0.15, 0.05, 1)
        rect("fill", 0, 0, W, H)

        lurek.render.setColor(1, 0.9, 0.3, 1)
        text_("SCORECARD", W / 2 - 50, 40)

        local y = 90
        local ts = total_strokes()
        local tp = total_par()
        for i = 1, #holes do
            local par = holes[i].par
            local s = hole_strokes[i] or 0
            local diff = s - par
            local diff_str = ""
            if diff > 0 then diff_str = " (+" .. diff .. ")"
            elseif diff < 0 then diff_str = " (" .. diff .. ")"
            else diff_str = " (E)" end

            if diff < 0 then lurek.render.setColor(0.3, 1, 0.3, 1)
            elseif diff > 0 then lurek.render.setColor(1, 0.4, 0.4, 1)
            else lurek.render.setColor(1, 1, 1, 1) end

            text_("Hole " .. i .. ": " .. s .. " strokes  (Par " .. par .. ")" .. diff_str, 200, y)
            y = y + 28
        end

        y = y + 20
        local total_diff = ts - tp
        if total_diff < 0 then lurek.render.setColor(0.3, 1, 0.5, 1)
        elseif total_diff > 0 then lurek.render.setColor(1, 0.5, 0.3, 1)
        else lurek.render.setColor(1, 1, 1, 1) end

        local label = "TOTAL: " .. ts .. " / Par " .. tp
        if total_diff < 0 then label = label .. "  (" .. total_diff .. " UNDER PAR!)"
        elseif total_diff > 0 then label = label .. "  (+" .. total_diff .. " over par)"
        else label = label .. "  (EVEN PAR)" end
        text_(label, 200, y)

        y = y + 50
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        text_("Press Space to return to title", W / 2 - 110, y)
        return
    end

    -- ── In-game HUD ──
    local h = holes[current_hole]

    -- Hole info
    lurek.render.setColor(1, 1, 1, 1)
    text_("Hole " .. current_hole .. " / " .. #holes, 10, 10)
    text_("Par " .. h.par, 10, 30)
    text_("Strokes: " .. strokes, 10, 50)

    -- Stroke vs par indicator
    local diff = strokes - h.par
    if diff > 0 then
        lurek.render.setColor(1, 0.4, 0.4, 1)
        text_("+" .. diff, 130, 50)
    elseif diff < 0 then
        lurek.render.setColor(0.4, 1, 0.4, 1)
        text_(tostring(diff), 130, 50)
    end

    -- Wind indicator
    lurek.render.setColor(0.7, 0.85, 1, 1)
    text_("Wind:", 10, 80)
    local wind_cx, wind_cy = 80, 88
    lurek.render.setColor(1, 1, 1, 0.6)
    circ("line", wind_cx, wind_cy, 12)
    if wind.strength > 0.1 then
        local wnx = wind.dx / wind.strength
        local wny = wind.dy / wind.strength
        local arrow_len = 8 + (wind.strength / 35) * 8
        lurek.render.setColor(0.5, 0.8, 1, 1)
        ln(wind_cx, wind_cy, wind_cx + wnx * arrow_len, wind_cy + wny * arrow_len)
    end

    -- Power bar (right side)
    local bar_x = W - 40
    local bar_y = 100
    local bar_w = 20
    local bar_h = 300

    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    rect("fill", bar_x, bar_y, bar_w, bar_h)
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    rect("line", bar_x, bar_y, bar_w, bar_h)

    -- Fill
    local fill_h = (power / MAX_POWER) * bar_h
    if fill_h > 0 then
        local fill_t = power / MAX_POWER
        local pr = fill_t
        local pg = 1 - fill_t * 0.7
        local pb = 0.2
        lurek.render.setColor(pr, pg, pb, 1)
        rect("fill", bar_x + 2, bar_y + bar_h - fill_h, bar_w - 4, fill_h)
    end
    lurek.render.setColor(1, 1, 1, 0.7)
    text_(math.floor(power) .. "%", bar_x - 5, bar_y + bar_h + 8)

    -- Hole complete message
    if state == S_HOLE_DONE then
        lurek.render.setColor(0, 0, 0, 0.5)
        rect("fill", W / 2 - 120, H / 2 - 40, 240, 80)

        local msg = "HOLE IN!"
        local s_diff = strokes - h.par
        if s_diff <= -2 then msg = "EAGLE!"
        elseif s_diff == -1 then msg = "BIRDIE!"
        elseif s_diff == 0 then msg = "PAR"
        elseif s_diff == 1 then msg = "BOGEY"
        elseif s_diff >= 2 then msg = "DOUBLE BOGEY+"
        end
        if strokes == 1 then msg = "HOLE IN ONE!!!" end

        lurek.render.setColor(1, 0.9, 0.3, 1)
        text_(msg, W / 2 - 50, H / 2 - 20)
        lurek.render.setColor(1, 1, 1, 0.8)
        text_(strokes .. " strokes", W / 2 - 35, H / 2 + 10)
    end

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
    text_("FPS: " .. lurek.timer.getFPS(), W - 90, H - 20)
end
