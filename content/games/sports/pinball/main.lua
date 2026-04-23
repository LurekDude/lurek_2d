-- Pinball — Lurek2D
-- Category: sports
-- A classic vertical pinball table with flippers, bumpers, targets, ramps, and plunger.

-- Constants
local W, H = 800, 600
local TABLE_W, TABLE_H = 600, 540
local TABLE_X = (W - TABLE_W) / 2
local TABLE_Y = (H - TABLE_H) / 2
local GRAVITY = 500
local BALL_R = 8
local FLIPPER_LEN = 60
local FLIPPER_REST_ANGLE = 30
local FLIPPER_UP_ANGLE = -30
local BUMPER_R = 20
local TARGET_W, TARGET_H = 30, 10
local PLUNGER_X = TABLE_X + TABLE_W - 30
local PLUNGER_Y = TABLE_Y + TABLE_H - 40
local MAX_LAUNCH_VEL = 800

-- States
local STATE_TITLE = "TITLE"
local STATE_PLUNGING = "PLUNGING"
local STATE_PLAYING = "PLAYING"
local STATE_BALL_LOST = "BALL_LOST"
local STATE_GAME_OVER = "GAME_OVER"

-- Game state
local state = STATE_TITLE
local score = 0
local display_score = 0
local high_score = 0
local balls_left = 3
local extra_ball_given = false
local multiplier = 1
local bumper_combo = 0
local charge = 0
local charging = false

-- Ball
local ball = { x = 0, y = 0, vx = 0, vy = 0, active = false }

-- Flippers
local flippers = {
local _cam = lurek.camera.new()  -- injected by fix_games.py
    left = {
        px = TABLE_X + 160, py = TABLE_Y + TABLE_H - 50,
        angle = FLIPPER_REST_ANGLE, target_angle = FLIPPER_REST_ANGLE,
        dir = 1
    },
    right = {
        px = TABLE_X + TABLE_W - 160, py = TABLE_Y + TABLE_H - 50,
        angle = -FLIPPER_REST_ANGLE, target_angle = -FLIPPER_REST_ANGLE,
        dir = -1
    },
}

-- Bumpers
local bumpers = {
    { x = TABLE_X + TABLE_W * 0.3,  y = TABLE_Y + 140, flash = 0 },
    { x = TABLE_X + TABLE_W * 0.5,  y = TABLE_Y + 100, flash = 0 },
    { x = TABLE_X + TABLE_W * 0.7,  y = TABLE_Y + 140, flash = 0 },
}

-- Targets
local targets = {}
local all_targets_hit = false

-- Ramps (line segments)
local ramps = {
    { x1 = TABLE_X + 80,  y1 = TABLE_Y + 300, x2 = TABLE_X + 40,  y2 = TABLE_Y + 180 },
    { x1 = TABLE_X + TABLE_W - 80, y1 = TABLE_Y + 300, x2 = TABLE_X + TABLE_W - 40, y2 = TABLE_Y + 180 },
}

-- Particles
local particles = {}

-- Timers
local ball_lost_timer = 0
local title_blink = 0

-- ─── Helpers ────────────────────────────────────────────────────────

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function spawn_particles(x, y, count, r, g, b, speed)
    speed = speed or 120
    for i = 1, count do
        local a = math.random() * math.pi * 2
        local s = speed * (0.5 + math.random() * 0.5)
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(a) * s,
            vy = math.sin(a) * s,
            life = 0.4 + math.random() * 0.3,
            r = r, g = g, b = b, a = 1,
            size = 2 + math.random() * 3,
        }
    end
end

local function reset_targets()
    targets = {}
    local start_x = TABLE_X + TABLE_W * 0.25
    local spacing = TABLE_W * 0.5 / 4
    for i = 0, 4 do
        targets[#targets + 1] = {
            x = start_x + i * spacing - TARGET_W / 2,
            y = TABLE_Y + 240,
            hit = false,
        }
    end
    all_targets_hit = false
end

local function reset_ball()
    ball.x = PLUNGER_X
    ball.y = PLUNGER_Y
    ball.vx = 0
    ball.vy = 0
    ball.active = false
    charge = 0
    charging = false
    multiplier = 1
    bumper_combo = 0
end

local function start_game()
    score = 0
    display_score = 0
    balls_left = 3
    extra_ball_given = false
    multiplier = 1
    bumper_combo = 0
    reset_targets()
    reset_ball()
    state = STATE_PLUNGING
end

local function add_score(pts)
    score = score + pts * multiplier
    if not extra_ball_given and score >= 5000 then
        balls_left = balls_left + 1
        extra_ball_given = true
        spawn_particles(W / 2, H / 2, 30, 1, 1, 0, 200)
    end
end

-- ─── Flipper geometry ───────────────────────────────────────────────

local function flipper_tip(f)
    local rad = math.rad(f.angle)
    return f.px + math.cos(rad) * FLIPPER_LEN * f.dir,
           f.py + math.sin(rad) * FLIPPER_LEN
end

local function point_to_segment_dist(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 < 0.001 then return dist(px, py, ax, ay), ax, ay end
    local t = clamp(((px - ax) * dx + (py - ay) * dy) / len2, 0, 1)
    local cx, cy = ax + t * dx, ay + t * dy
    return dist(px, py, cx, cy), cx, cy
end

-- ─── Input ──────────────────────────────────────────────────────────

lurek.input.bind("left_flip", "a", "left")
lurek.input.bind("right_flip", "d", "right")
lurek.input.bind("plunge", "space")
lurek.input.bind("tilt", "t")
lurek.input.bind("quit", "escape")

-- ─── Callbacks ──────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Pinball — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.05)
    reset_targets()
end

local function _ready_setup()
    _cam:setPosition(W, H)
end

function lurek.process(dt)
    title_blink = title_blink + dt

    -- Animate score display
    if display_score < score then
        display_score = display_score + math.ceil((score - display_score) * dt * 10)
        if display_score > score then display_score = score end
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.a = clamp(p.life / 0.3, 0, 1)
        p.size = p.size * (1 - dt * 2)
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

    -- Update bumper flashes
    for _, b in ipairs(bumpers) do
        if b.flash > 0 then b.flash = b.flash - dt * 3 end
    end

    -- Quit
    if lurek.input.isActionDown("quit") then
        lurek.event.quit()
        return
    end

    -- ── TITLE ──
    if state == STATE_TITLE then
        if lurek.input.isActionDown("plunge") then
            start_game()
        end
        return
    end

    -- ── GAME OVER ──
    if state == STATE_GAME_OVER then
        if lurek.input.isActionDown("plunge") then
            state = STATE_TITLE
        end
        return
    end

    -- ── BALL LOST ──
    if state == STATE_BALL_LOST then
        ball_lost_timer = ball_lost_timer - dt
        if ball_lost_timer <= 0 then
            if balls_left <= 0 then
                if score > high_score then high_score = score end
                state = STATE_GAME_OVER
            else
                reset_ball()
                state = STATE_PLUNGING
            end
        end
        return
    end

    -- ── Flipper control ──
    local left_pressed = lurek.input.isActionDown("left_flip")
    local right_pressed = lurek.input.isActionDown("right_flip")

    flippers.left.target_angle = left_pressed and FLIPPER_UP_ANGLE or FLIPPER_REST_ANGLE
    flippers.right.target_angle = right_pressed and (-FLIPPER_UP_ANGLE) or (-FLIPPER_REST_ANGLE)

    if left_pressed or right_pressed then
        bumper_combo = 0
        multiplier = 1
    end

    -- Tween flipper angles
    for _, f in pairs(flippers) do
        f.angle = lerp(f.angle, f.target_angle, clamp(dt * 20, 0, 1))
    end

    -- ── PLUNGING ──
    if state == STATE_PLUNGING then
        if lurek.input.isActionDown("plunge") then
            charging = true
            charge = clamp(charge + dt * 150, 0, 100)
        elseif charging then
            -- Launch
            local vel = (charge / 100) * MAX_LAUNCH_VEL
            ball.vy = -vel
            ball.vx = 0
            ball.active = true
            charging = false
            spawn_particles(ball.x, ball.y, 8, 0.6, 0.6, 0.6, 80)
            state = STATE_PLAYING
        end
        ball.x = PLUNGER_X
        ball.y = PLUNGER_Y + (charge / 100) * 20
        return
    end

    -- ── Tilt ──
    if lurek.input.isActionDown("tilt") then
        ball.x = ball.x + (math.random() * 40 - 20)
        ball.y = ball.y + (math.random() * 40 - 20)
        ball.vx = ball.vx + (math.random() * 100 - 50)
        ball.vy = ball.vy + (math.random() * 100 - 50)
    end

    -- ── PLAYING — physics ──
    ball.vy = ball.vy + GRAVITY * dt
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Wall collisions
    local left_wall = TABLE_X + BALL_R
    local right_wall = TABLE_X + TABLE_W - BALL_R
    local top_wall = TABLE_Y + BALL_R

    if ball.x < left_wall then
        ball.x = left_wall
        ball.vx = math.abs(ball.vx) * 0.8
    elseif ball.x > right_wall then
        ball.x = right_wall
        ball.vx = -math.abs(ball.vx) * 0.8
    end
    if ball.y < top_wall then
        ball.y = top_wall
        ball.vy = math.abs(ball.vy) * 0.8
    end

    -- Drain check (gap between flippers at bottom)
    if ball.y > TABLE_Y + TABLE_H + BALL_R then
        balls_left = balls_left - 1
        ball.active = false
        spawn_particles(ball.x, TABLE_Y + TABLE_H, 20, 1, 0.3, 0.1, 150)
        ball_lost_timer = 1.5
        state = STATE_BALL_LOST
        return
    end

    -- Bumper collisions
    for _, b in ipairs(bumpers) do
        local d = dist(ball.x, ball.y, b.x, b.y)
        if d < BUMPER_R + BALL_R then
            local nx = (ball.x - b.x) / d
            local ny = (ball.y - b.y) / d
            ball.x = b.x + nx * (BUMPER_R + BALL_R + 1)
            ball.y = b.y + ny * (BUMPER_R + BALL_R + 1)
            local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
            ball.vx = nx * speed * 1.5
            ball.vy = ny * speed * 1.5
            b.flash = 1
            bumper_combo = bumper_combo + 1
            if bumper_combo >= 6 then
                multiplier = 4
            elseif bumper_combo >= 4 then
                multiplier = 3
            elseif bumper_combo >= 2 then
                multiplier = 2
            end
            add_score(100)
            spawn_particles(b.x, b.y, 10, 1, 0.8, 0.2, 100)
        end
    end

    -- Target collisions
    local all_hit = true
    for _, t in ipairs(targets) do
        if not t.hit then
            if ball.x + BALL_R > t.x and ball.x - BALL_R < t.x + TARGET_W and
               ball.y + BALL_R > t.y and ball.y - BALL_R < t.y + TARGET_H then
                t.hit = true
                ball.vy = -math.abs(ball.vy) * 0.9
                add_score(50)
                spawn_particles(t.x + TARGET_W / 2, t.y + TARGET_H / 2, 8, 0, 1, 0.5, 90)
            end
        end
        if not t.hit then all_hit = false end
    end
    if all_hit and not all_targets_hit then
        all_targets_hit = true
        add_score(500)
        spawn_particles(TABLE_X + TABLE_W / 2, TABLE_Y + 240, 25, 0, 1, 1, 180)
        -- Reset targets after brief delay (instant for simplicity)
        reset_targets()
    end

    -- Ramp collisions
    for _, r in ipairs(ramps) do
        local d, cx, cy = point_to_segment_dist(ball.x, ball.y, r.x1, r.y1, r.x2, r.y2)
        if d < BALL_R + 3 then
            local nx = (ball.x - cx)
            local ny = (ball.y - cy)
            local nd = math.sqrt(nx * nx + ny * ny)
            if nd > 0.001 then
                nx, ny = nx / nd, ny / nd
                ball.x = cx + nx * (BALL_R + 4)
                ball.y = cy + ny * (BALL_R + 4)
                -- Reflect velocity
                local dot = ball.vx * nx + ball.vy * ny
                ball.vx = ball.vx - 2 * dot * nx
                ball.vy = ball.vy - 2 * dot * ny
                -- Roll along ramp upward
                if ball.vy < -50 then
                    add_score(200)
                    spawn_particles(cx, cy, 6, 0.5, 0.5, 1, 60)
                end
            end
        end
    end

    -- Flipper collisions
    for _, f in pairs(flippers) do
        local tx, ty = flipper_tip(f)
        local d, cx, cy = point_to_segment_dist(ball.x, ball.y, f.px, f.py, tx, ty)
        if d < BALL_R + 4 then
            local nx = (ball.x - cx)
            local ny = (ball.y - cy)
            local nd = math.sqrt(nx * nx + ny * ny)
            if nd > 0.001 then
                nx, ny = nx / nd, ny / nd
                ball.x = cx + nx * (BALL_R + 5)
                ball.y = cy + ny * (BALL_R + 5)
                -- Reflect
                local dot = ball.vx * nx + ball.vy * ny
                ball.vx = ball.vx - 2 * dot * nx
                ball.vy = ball.vy - 2 * dot * ny
                -- Flipper boost when moving up
                local flipper_moving = math.abs(f.angle - f.target_angle) > 2
                if flipper_moving then
                    ball.vy = ball.vy - 200
                    ball.vx = ball.vx + f.dir * 80
                end
                -- Minimum upward velocity off flipper
                if ball.vy > -100 then ball.vy = -180 end
            end
        end
    end

    -- Speed cap
    local spd = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
    if spd > 1200 then
        ball.vx = ball.vx / spd * 1200
        ball.vy = ball.vy / spd * 1200
    end
end

-- ─── Render — table, ball, obstacles ─────────────────────────────────

function lurek.draw()
    -- Table background
    lurek.render.setColor(0.08, 0.08, 0.12, 1)
    lurek.render.rectangle("fill", TABLE_X, TABLE_Y, TABLE_W, TABLE_H)

    -- Table border
    lurek.render.setColor(0.4, 0.35, 0.5, 1)
    lurek.render.rectangle("line", TABLE_X, TABLE_Y, TABLE_W, TABLE_H)

    -- Ramps
    lurek.render.setColor(0.3, 0.3, 0.6, 1)
    for _, r in ipairs(ramps) do
        lurek.render.line(r.x1, r.y1, r.x2, r.y2)
    end

    -- Targets
    for _, t in ipairs(targets) do
        if t.hit then
            lurek.render.setColor(0.15, 0.15, 0.15, 1)
        else
            lurek.render.setColor(0, 0.9, 0.5, 1)
        end
        lurek.render.rectangle("fill", t.x, t.y, TARGET_W, TARGET_H)
    end

    -- Bumpers
    for _, b in ipairs(bumpers) do
        local flash = clamp(b.flash, 0, 1)
        local br = 0.9 + flash * 0.1
        local bg = 0.4 + flash * 0.6
        local bb = 0.1 + flash * 0.4
        lurek.render.setColor(br, bg, bb, 1)
        lurek.render.circle("fill", b.x, b.y, BUMPER_R)
        lurek.render.setColor(1, 1, 1, 0.3 + flash * 0.7)
        lurek.render.circle("line", b.x, b.y, BUMPER_R)
    end

    -- Flippers
    lurek.render.setColor(0.8, 0.8, 0.9, 1)
    for _, f in pairs(flippers) do
        local tx, ty = flipper_tip(f)
        lurek.render.line(f.px, f.py, tx, ty)
        lurek.render.circle("fill", f.px, f.py, 5)
        lurek.render.circle("fill", tx, ty, 4)
    end

    -- Plunger lane
    lurek.render.setColor(0.2, 0.15, 0.25, 1)
    lurek.render.rectangle("fill", PLUNGER_X - 12, TABLE_Y + TABLE_H - 80, 24, 80)

    -- Plunger
    if state == STATE_PLUNGING then
        local py = PLUNGER_Y + (charge / 100) * 20
        lurek.render.setColor(0.7, 0.2, 0.2, 1)
        lurek.render.rectangle("fill", PLUNGER_X - 8, py + 5, 16, 12)
        -- Charge meter
        lurek.render.setColor(0.3, 0.3, 0.3, 1)
        lurek.render.rectangle("fill", PLUNGER_X - 10, TABLE_Y + TABLE_H - 78, 20, 60)
        local ch = (charge / 100) * 56
        lurek.render.setColor(1, 0.3 + 0.7 * (1 - charge / 100), 0, 1)
        lurek.render.rectangle("fill", PLUNGER_X - 8, TABLE_Y + TABLE_H - 20 - ch, 16, ch)
    end

    -- Ball
    if ball.active or state == STATE_PLUNGING then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.circle("fill", ball.x, ball.y, BALL_R)
        lurek.render.setColor(0.7, 0.7, 0.8, 0.5)
        lurek.render.circle("line", ball.x, ball.y, BALL_R + 1)
    end

    -- Particles
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.a)
        lurek.render.circle("fill", p.x, p.y, math.max(p.size, 0.5))
    end

    -- Drain zone indicator
    lurek.render.setColor(0.5, 0.1, 0.1, 0.4)
    local drain_left = flippers.left.px + 20
    local drain_right = flippers.right.px - 20
    lurek.render.rectangle("fill", drain_left, TABLE_Y + TABLE_H - 6, drain_right - drain_left, 6)
end

-- ─── Render UI — score, balls, state overlays ───────────────────────

function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    -- Score bar
    lurek.render.setColor(0.05, 0.05, 0.08, 0.9)
    lurek.render.rectangle("fill", 0, 0, W, 28)

    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(string.format("SCORE: %d", display_score), 10, 6)
    lurek.render.print(string.format("HI: %d", high_score), W / 2 - 40, 6)
    lurek.render.print(string.format("BALLS: %d", balls_left), W - 120, 6)
    lurek.render.print(string.format("FPS: %d", fps), W - 200, 6)

    -- Multiplier
    if multiplier > 1 then
        lurek.render.setColor(1, 1, 0, 1)
        lurek.render.print(string.format("%dX COMBO!", multiplier), TABLE_X + TABLE_W / 2 - 30, TABLE_Y - 16)
    end

    -- ── State overlays ──
    if state == STATE_TITLE then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 0.8, 0.2, 1)
        lurek.render.print("PINBALL", W / 2 - 50, H / 2 - 40)
        local alpha = 0.4 + 0.6 * math.abs(math.sin(title_blink * 2))
        lurek.render.setColor(1, 1, 1, alpha)
        lurek.render.print("FLIP IT", W / 2 - 40, H / 2)
        lurek.render.setColor(0.6, 0.6, 0.7, 1)
        lurek.render.print("Press SPACE to start", W / 2 - 70, H / 2 + 40)
    end

    if state == STATE_BALL_LOST then
        lurek.render.setColor(1, 0.3, 0.3, 0.8)
        lurek.render.print("BALL LOST", W / 2 - 40, H / 2 - 10)
    end

    if state == STATE_GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.print("GAME OVER", W / 2 - 50, H / 2 - 30)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(string.format("FINAL SCORE: %d", score), W / 2 - 60, H / 2 + 10)
        if score >= high_score and score > 0 then
            lurek.render.setColor(1, 1, 0, 1)
            lurek.render.print("NEW HIGH SCORE!", W / 2 - 55, H / 2 + 40)
        end
        lurek.render.setColor(0.6, 0.6, 0.7, 1)
        lurek.render.print("Press SPACE", W / 2 - 40, H / 2 + 70)
    end
end
