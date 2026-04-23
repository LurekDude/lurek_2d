-- Ski Jump — Lurek2D
-- Category: sports
-- Side-view ski jumping with approach, flight, and landing phases

-- ─── Constants ───────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local GRAVITY = 980
local MAX_ROUNDS = 3
local JUDGES = 5
local PX_TO_METERS = 0.5

local HILLS = {
    { name = "Small",  k_point = 90,  ramp_len = 320, ramp_angle = 35, launch_y = 400 },
    { name = "Normal", k_point = 120, ramp_len = 420, ramp_angle = 37, launch_y = 380 },
    { name = "Large",  k_point = 150, ramp_len = 520, ramp_angle = 40, launch_y = 360 },
}

-- ─── State ───────────────────────────────────────────────────────────
local state = "TITLE"
local hill = 2
local round = 1
local round_scores = {}
local dt = 0

-- approach
local ramp_start_x, ramp_start_y = 80, 80
local ramp_end_x, ramp_end_y = 0, 0
local skier_t = 0
local skier_x, skier_y = 0, 0
local skier_speed = 0
local crouching = false
local wind = 0

-- airborne
local air_vx, air_vy = 0, 0
local lean = 0
local flight_time = 0
local jump_quality = 0

-- landing
local landing_slope_y = 0
local landing_slope_angle = 0
local distance_px = 0
local distance_m = 0
local style_points = 0
local judge_scores = {}
local landing_quality = ""
local wobble_timer = 0
local tumble_timer = 0

-- score display
local score_reveal_timer = 0
local shown_judges = 0

-- tween
local display_speed = 0
local display_distance = 0

-- particles
local particles = {}

-- camera
local cam_x, cam_y = 0, 0

-- ─── Helpers ─────────────────────────────────────────────────────────
local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function rand_range(lo, hi) return lo + math.random() * (hi - lo) end

local function compute_ramp()
    local h = HILLS[hill]
    ramp_start_x = 80
    ramp_start_y = 80
    ramp_end_x = ramp_start_x + h.ramp_len
    ramp_end_y = h.launch_y
    landing_slope_y = h.launch_y + 60
    landing_slope_angle = 12
end

local function spawn_particles(x, y, count, color, vx_range, vy_range, life)
    for i = 1, count do
        table.insert(particles, {
            x = x + rand_range(-8, 8),
            y = y + rand_range(-4, 4),
            vx = rand_range(vx_range[1], vx_range[2]),
            vy = rand_range(vy_range[1], vy_range[2]),
            life = life or rand_range(0.4, 1.0),
            max_life = life or 1.0,
            r = color[1], g = color[2], b = color[3],
            size = rand_range(2, 5),
        })
    end
end

local function update_particles()
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 120 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function reset_approach()
    compute_ramp()
    skier_t = 0
    skier_speed = 20
    crouching = false
    wind = rand_range(-3, 3)
    lean = 0
    flight_time = 0
    air_vx, air_vy = 0, 0
    distance_px = 0
    distance_m = 0
    style_points = 0
    judge_scores = {}
    landing_quality = ""
    wobble_timer = 0
    tumble_timer = 0
    display_speed = 0
    display_distance = 0
    shown_judges = 0
    score_reveal_timer = 0
    particles = {}
    jump_quality = 0
end

local function start_round()
    reset_approach()
    state = "APPROACH"
end

local function compute_judge_scores(base)
    judge_scores = {}
    for i = 1, JUDGES do
        local score = clamp(math.floor(base + rand_range(-2, 2) + 0.5), 1, 20)
        table.insert(judge_scores, score)
    end
end

local function total_score()
    local sum = 0
    for _, s in ipairs(judge_scores) do sum = sum + s end
    return distance_m + (sum / JUDGES)
end

-- ─── Input Bindings ──────────────────────────────────────────────────
lurek.input.bind("crouch", "d")
lurek.input.bind("jump", "space")
lurek.input.bind("lean_fwd", "w")
lurek.input.bind("lean_back", "s")
lurek.input.bind("hill_small", "1")
lurek.input.bind("hill_normal", "2")
lurek.input.bind("hill_large", "3")
lurek.input.bind("quit", "escape")

-- ─── Init ────────────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Ski Jump — Lurek2D")
    lurek.render.setBackgroundColor(0.7, 0.8, 0.95)
    compute_ramp()
    math.randomseed(os.time())
end

-- ─── Process ─────────────────────────────────────────────────────────
function lurek.process(delta)
    dt = delta

    if lurek.input.isActionDown("quit") then
        lurek.event.quit()
        return
    end

    -- hill selection from title
    if state == "TITLE" or state == "FINAL" then
        if lurek.input.isActionDown("hill_small") then hill = 1; compute_ramp() end
        if lurek.input.isActionDown("hill_normal") then hill = 2; compute_ramp() end
        if lurek.input.isActionDown("hill_large") then hill = 3; compute_ramp() end

        if lurek.input.isActionDown("jump") then
            round = 1
            round_scores = {}
            start_round()
        end
    end

    -- ─── APPROACH ────────────────────────────────────────────────
    if state == "APPROACH" then
        crouching = lurek.input.isActionDown("crouch")

        local slope_rad = math.rad(HILLS[hill].ramp_angle)
        local accel = GRAVITY * math.sin(slope_rad)
        local drag = crouching and 0.02 or 0.05
        accel = accel - drag * skier_speed * skier_speed / 200

        skier_speed = skier_speed + accel * dt
        if crouching then skier_speed = skier_speed * (1 + 0.10 * dt) end
        skier_speed = clamp(skier_speed, 0, 600)

        skier_t = skier_t + (skier_speed * dt) / HILLS[hill].ramp_len
        skier_t = clamp(skier_t, 0, 1)

        skier_x = lerp(ramp_start_x, ramp_end_x, skier_t)
        skier_y = lerp(ramp_start_y, ramp_end_y, skier_t)

        -- snow spray while sliding
        if math.random() < 0.3 then
            spawn_particles(skier_x, skier_y + 10, 2, {0.9, 0.95, 1.0}, {-30, 10}, {-40, -10}, 0.5)
        end

        -- jump trigger
        if lurek.input.isActionDown("jump") and skier_t > 0.8 then
            local dist_from_end = math.abs(skier_t - 1.0) * HILLS[hill].ramp_len
            local launch_angle
            if dist_from_end < 5 then
                launch_angle = 35
                jump_quality = 1.0
            elseif skier_t < 1.0 then
                launch_angle = 30 - (1.0 - skier_t) * 40
                jump_quality = 0.8
            else
                launch_angle = 25
                jump_quality = 0.6
                skier_speed = skier_speed * 0.8
            end

            local rad = math.rad(launch_angle)
            air_vx = skier_speed * math.cos(rad) * jump_quality
            air_vy = -skier_speed * math.sin(rad) * jump_quality
            state = "AIRBORNE"
            flight_time = 0
            lean = 0

            spawn_particles(skier_x, skier_y, 15, {0.85, 0.9, 1.0}, {-60, 60}, {-80, -20}, 0.8)
        end

        -- auto-jump at ramp end
        if skier_t >= 1.0 and state == "APPROACH" then
            air_vx = skier_speed * 0.85
            air_vy = -skier_speed * 0.35
            jump_quality = 0.5
            state = "AIRBORNE"
            flight_time = 0
            lean = 0
        end

        display_speed = lerp(display_speed, skier_speed, clamp(dt * 8, 0, 1))
    end

    -- ─── AIRBORNE ────────────────────────────────────────────────
    if state == "AIRBORNE" then
        flight_time = flight_time + dt

        if lurek.input.isActionDown("lean_fwd") then lean = lean + 2.0 * dt end
        if lurek.input.isActionDown("lean_back") then lean = lean - 2.0 * dt end
        lean = clamp(lean, -1.0, 1.0)

        -- optimal lean: body parallel to velocity = lean near trajectory angle
        local traj_angle = math.atan2(air_vy, air_vx)
        local optimal_lean = clamp(traj_angle / math.rad(45), -1, 1)
        local lean_diff = math.abs(lean - optimal_lean)
        local lift_factor = 1.0 - lean_diff * 0.8

        air_vy = air_vy + GRAVITY * 0.55 * dt
        air_vy = air_vy - lift_factor * 120 * dt
        air_vx = air_vx + wind * 15 * dt

        -- drag
        local speed_sq = air_vx * air_vx + air_vy * air_vy
        local drag_coeff = 0.0001 + lean_diff * 0.0003
        air_vx = air_vx - air_vx * drag_coeff * math.sqrt(speed_sq) * dt
        air_vy = air_vy - air_vy * drag_coeff * math.sqrt(speed_sq) * dt * 0.5

        skier_x = skier_x + air_vx * dt
        skier_y = skier_y + air_vy * dt

        -- wind particles
        if math.random() < 0.2 then
            spawn_particles(skier_x + rand_range(-40, 40), skier_y + rand_range(-20, 20),
                1, {0.8, 0.85, 0.95}, {wind * 40, wind * 80}, {-10, 10}, 0.6)
        end

        -- check landing
        if skier_y >= landing_slope_y then
            skier_y = landing_slope_y
            distance_px = skier_x - ramp_end_x
            distance_m = math.floor(distance_px * PX_TO_METERS + 0.5)
            if distance_m < 0 then distance_m = 0 end
            state = "LANDING"
            wobble_timer = 0
            tumble_timer = 0
            display_distance = 0

            spawn_particles(skier_x, skier_y, 20, {0.9, 0.92, 1.0}, {-80, 80}, {-100, -20}, 1.0)
        end
    end

    -- ─── LANDING ─────────────────────────────────────────────────
    if state == "LANDING" then
        local slope_rad = math.rad(landing_slope_angle)
        local lean_angle = lean * 45
        local diff = math.abs(lean_angle - landing_slope_angle)

        if diff <= 15 then
            landing_quality = "smooth"
            style_points = 16
        elseif diff <= 35 then
            landing_quality = "rough"
            style_points = 8
            wobble_timer = 0.8
        else
            landing_quality = "crash"
            style_points = 0
            tumble_timer = 1.2
        end

        -- space for telemark landing bonus
        if lurek.input.isActionDown("jump") and landing_quality == "smooth" then
            style_points = style_points + 4
        end

        compute_judge_scores(style_points)

        if landing_quality ~= "crash" and distance_m > HILLS[hill].k_point * 0.7 then
            spawn_particles(skier_x, skier_y - 60, 30, {1.0, 0.85, 0.2}, {-100, 100}, {-150, -40}, 1.5)
        end

        state = "SCORE"
        score_reveal_timer = 0
        shown_judges = 0
    end

    -- ─── SCORE ───────────────────────────────────────────────────
    if state == "SCORE" then
        score_reveal_timer = score_reveal_timer + dt
        shown_judges = clamp(math.floor(score_reveal_timer / 0.4), 0, JUDGES)

        display_distance = lerp(display_distance, distance_m, clamp(dt * 3, 0, 1))

        wobble_timer = math.max(0, wobble_timer - dt)
        tumble_timer = math.max(0, tumble_timer - dt)

        if lurek.input.isActionDown("jump") and shown_judges >= JUDGES then
            table.insert(round_scores, total_score())
            round = round + 1
            if round > MAX_ROUNDS then
                state = "FINAL"
            else
                start_round()
            end
        end
    end

    -- ─── Camera ──────────────────────────────────────────────────
    local target_cx = skier_x - SCREEN_W * 0.35
    local target_cy = skier_y - SCREEN_H * 0.5
    cam_x = lerp(cam_x, target_cx, clamp(dt * 4, 0, 1))
    cam_y = lerp(cam_y, target_cy, clamp(dt * 4, 0, 1))
    cam_x = math.max(0, cam_x)

    update_particles()
end

-- ─── Render (world) ──────────────────────────────────────────────────
function lurek.draw()
    if state == "TITLE" or state == "FINAL" then return end

    local ox, oy = -cam_x, -cam_y

    -- sky gradient (simple bands)
    for i = 0, 5 do
        local t = i / 5
        local r = lerp(0.5, 0.7, t)
        local g = lerp(0.6, 0.8, t)
        local b = lerp(0.9, 0.95, t)
        lurek.render.setColor(r, g, b, 1)
        lurek.render.rectangle(0, i * 100, SCREEN_W + 1000, 100)
    end

    -- mountains (background)
    lurek.render.setColor(0.75, 0.8, 0.88, 1)
    for i = 0, 8 do
        local mx = i * 180 + ox * 0.3
        lurek.render.triangle(mx, 350 + oy * 0.3, mx + 90, 180 + oy * 0.3, mx + 180, 350 + oy * 0.3)
    end

    -- snow ground
    lurek.render.setColor(0.95, 0.97, 1.0, 1)
    lurek.render.rectangle(ox, landing_slope_y + oy, 3000, 300)

    -- ramp structure
    lurek.render.setColor(0.3, 0.5, 0.7, 1)
    lurek.render.line(ramp_start_x + ox, ramp_start_y + oy, ramp_end_x + ox, ramp_end_y + oy, 4)

    -- ramp support beams
    lurek.render.setColor(0.4, 0.4, 0.5, 0.6)
    for i = 0, 4 do
        local t = i / 4
        local bx = lerp(ramp_start_x, ramp_end_x, t) + ox
        local by = lerp(ramp_start_y, ramp_end_y, t) + oy
        lurek.render.line(bx, by, bx, landing_slope_y + oy + 10, 2)
    end

    -- landing slope line
    lurek.render.setColor(0.6, 0.75, 0.6, 0.5)
    lurek.render.line(ramp_end_x + ox, landing_slope_y + oy, ramp_end_x + 800 + ox, landing_slope_y + oy, 2)

    -- K-point marker
    local kx = ramp_end_x + HILLS[hill].k_point / PX_TO_METERS + ox
    lurek.render.setColor(1, 0.2, 0.2, 0.8)
    lurek.render.line(kx, landing_slope_y - 20 + oy, kx, landing_slope_y + 10 + oy, 2)

    -- distance markers every 20m
    lurek.render.setColor(0.3, 0.3, 0.5, 0.4)
    for m = 20, 300, 20 do
        local mx = ramp_end_x + m / PX_TO_METERS + ox
        lurek.render.line(mx, landing_slope_y - 8 + oy, mx, landing_slope_y + 5 + oy, 1)
    end

    -- skier
    local sx, sy = skier_x + ox, skier_y + oy
    if tumble_timer > 0 then
        -- tumble: rotating rectangle
        local angle = tumble_timer * 600
        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        -- [fix] rectangleRotated -> push/rotate/pop equivalent
        local _rx, _ry, _rw, _rh = sx - 8, sy - 18, 16, 36
        lurek.render.push()
        lurek.render.translate(_rx + _rw * 0.5, _ry + _rh * 0.5)
        lurek.render.rotate(math.rad(angle))
        lurek.render.rectangle("fill", -_rw * 0.5, -_rh * 0.5, _rw, _rh)
        lurek.render.pop()
    elseif wobble_timer > 0 then
        local wobble = math.sin(wobble_timer * 30) * 4
        lurek.render.setColor(0.15, 0.2, 0.6, 1)
        lurek.render.rectangle(sx - 6 + wobble, sy - 30, 12, 30)
        lurek.render.setColor(0.9, 0.75, 0.6, 1)
        lurek.render.circle(sx + wobble, sy - 34, 6)
    else
        local h = crouching and 18 or 30
        local body_lean = 0
        if state == "AIRBORNE" then body_lean = lean * 20 end

        -- body
        lurek.render.setColor(0.15, 0.2, 0.6, 1)
        lurek.render.rectangle(sx - 6, sy - h + body_lean, 12, h)
        -- head
        lurek.render.setColor(0.9, 0.75, 0.6, 1)
        lurek.render.circle(sx, sy - h - 4 + body_lean, 6)
        -- skis
        lurek.render.setColor(0.8, 0.2, 0.1, 1)
        local ski_len = 22
        lurek.render.rectangle(sx - ski_len / 2, sy, ski_len, 3)
    end

    -- particles (world space)
    for _, p in ipairs(particles) do
        local alpha = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, alpha)
        lurek.render.circle(p.x + ox, p.y + oy, p.size * alpha)
    end

    -- trees on landing slope
    lurek.render.setColor(0.2, 0.55, 0.25, 0.7)
    for i = 0, 6 do
        local tx = ramp_end_x + 100 + i * 120 + ox
        local ty = landing_slope_y + oy
        lurek.render.triangle(tx, ty - 40, tx - 15, ty, tx + 15, ty)
        lurek.render.triangle(tx, ty - 60, tx - 10, ty - 25, tx + 10, ty - 25)
    end
end

-- ─── Render UI (HUD) ────────────────────────────────────────────────
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    if state == "TITLE" then
        lurek.render.setColor(0.1, 0.15, 0.4, 1)
        lurek.render.print("SKI JUMP", SCREEN_W / 2 - 100, 140, 48)
        lurek.render.setColor(0.3, 0.5, 0.8, 1)
        lurek.render.print("FLY HIGH", SCREEN_W / 2 - 70, 200, 24)

        lurek.render.setColor(0.2, 0.2, 0.3, 1)
        lurek.render.print("Hill: " .. HILLS[hill].name .. " (" .. HILLS[hill].k_point .. "m)", SCREEN_W / 2 - 90, 280, 18)
        lurek.render.print("Press 1/2/3 to change hill", SCREEN_W / 2 - 100, 310, 16)
        lurek.render.print("Space to start", SCREEN_W / 2 - 55, 350, 16)

        lurek.render.setColor(0.5, 0.5, 0.6, 0.6)
        lurek.render.print("D=crouch  Space=jump  W/S=lean", SCREEN_W / 2 - 130, 420, 14)
        lurek.render.print(string.format("FPS: %d", fps), 10, 10, 12)
        return
    end

    if state == "FINAL" then
        lurek.render.setColor(0.1, 0.15, 0.4, 1)
        lurek.render.print("FINAL RESULTS", SCREEN_W / 2 - 100, 100, 36)

        local grand_total = 0
        for i, s in ipairs(round_scores) do
            grand_total = grand_total + s
            lurek.render.setColor(0.2, 0.2, 0.35, 1)
            lurek.render.print(string.format("Round %d: %.1f", i, s), SCREEN_W / 2 - 70, 170 + i * 35, 20)
        end

        lurek.render.setColor(0.8, 0.6, 0.1, 1)
        lurek.render.print(string.format("Total: %.1f", grand_total), SCREEN_W / 2 - 60, 170 + (#round_scores + 1) * 35 + 10, 24)

        lurek.render.setColor(0.3, 0.3, 0.4, 1)
        lurek.render.print("Space for new competition  |  1/2/3 change hill", SCREEN_W / 2 - 180, 480, 14)
        lurek.render.print(string.format("FPS: %d", fps), 10, 10, 12)
        return
    end

    -- ─── HUD during gameplay ─────────────────────────────────────
    -- top bar background
    lurek.render.setColor(0, 0, 0, 0.4)
    lurek.render.rectangle(0, 0, SCREEN_W, 36)

    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(string.format("Round %d/%d", round, MAX_ROUNDS), 10, 8, 16)
    lurek.render.print(HILLS[hill].name .. " Hill", 150, 8, 16)
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, 8, 12)

    -- wind indicator
    local wind_color_r = wind > 0 and 0.2 or 0.9
    local wind_color_g = 0.7
    local wind_color_b = wind > 0 and 0.9 or 0.2
    lurek.render.setColor(wind_color_r, wind_color_g, wind_color_b, 1)
    local wind_label = string.format("Wind: %.1f m/s %s", math.abs(wind), wind > 0 and "→" or "←")
    lurek.render.print(wind_label, SCREEN_W / 2 - 50, 8, 14)

    -- speed display
    if state == "APPROACH" then
        lurek.render.setColor(1, 0.9, 0.3, 1)
        lurek.render.print(string.format("Speed: %.0f km/h", display_speed * 3.6 / 10), 10, 50, 20)

        if crouching then
            lurek.render.setColor(0.3, 1, 0.3, 0.8)
            lurek.render.print("CROUCHING", 10, 76, 14)
        end

        lurek.render.setColor(0.8, 0.8, 0.9, 0.6)
        lurek.render.print("D=crouch  Space=jump near end", 10, SCREEN_H - 30, 13)
    end

    -- airborne display
    if state == "AIRBORNE" then
        lurek.render.setColor(0.3, 1, 0.5, 1)
        lurek.render.print(string.format("Flight: %.1fs", flight_time), 10, 50, 18)

        -- lean meter
        local meter_x, meter_y = SCREEN_W - 40, SCREEN_H / 2 - 60
        lurek.render.setColor(0.3, 0.3, 0.4, 0.6)
        lurek.render.rectangle(meter_x, meter_y, 20, 120)
        local lean_pos = meter_y + 60 - lean * 55
        lurek.render.setColor(1, 1, 0.3, 1)
        lurek.render.rectangle(meter_x + 2, lean_pos - 3, 16, 6)
        lurek.render.setColor(0.8, 0.8, 0.9, 0.5)
        lurek.render.print("W", meter_x + 4, meter_y - 18, 12)
        lurek.render.print("S", meter_x + 4, meter_y + 124, 12)

        lurek.render.setColor(0.8, 0.8, 0.9, 0.6)
        lurek.render.print("W/S=lean  Space=land", 10, SCREEN_H - 30, 13)
    end

    -- score display
    if state == "SCORE" then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(string.format("Distance: %.1f m", display_distance), SCREEN_W / 2 - 80, 60, 22)

        -- landing quality
        if landing_quality == "smooth" then
            lurek.render.setColor(0.2, 1, 0.3, 1)
            lurek.render.print("SMOOTH LANDING!", SCREEN_W / 2 - 80, 95, 18)
        elseif landing_quality == "rough" then
            lurek.render.setColor(1, 0.7, 0.2, 1)
            lurek.render.print("ROUGH LANDING", SCREEN_W / 2 - 70, 95, 18)
        else
            lurek.render.setColor(1, 0.2, 0.2, 1)
            lurek.render.print("CRASH!", SCREEN_W / 2 - 30, 95, 18)
        end

        -- judge scores (revealed one by one)
        lurek.render.setColor(0.15, 0.15, 0.25, 0.7)
        lurek.render.rectangle(SCREEN_W / 2 - 140, 130, 280, 50)

        for i = 1, JUDGES do
            local jx = SCREEN_W / 2 - 120 + (i - 1) * 56
            if i <= shown_judges then
                local s = judge_scores[i]
                if s >= 16 then
                    lurek.render.setColor(0.2, 1, 0.3, 1)
                elseif s >= 10 then
                    lurek.render.setColor(1, 0.9, 0.3, 1)
                else
                    lurek.render.setColor(1, 0.4, 0.3, 1)
                end
                lurek.render.print(tostring(s), jx + 10, 145, 22)
            else
                lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
                lurek.render.print("?", jx + 14, 145, 22)
            end
        end

        if shown_judges >= JUDGES then
            local ts = total_score()
            lurek.render.setColor(0.9, 0.8, 0.2, 1)
            lurek.render.print(string.format("Round Score: %.1f", ts), SCREEN_W / 2 - 80, 200, 20)

            lurek.render.setColor(0.7, 0.7, 0.8, 0.7)
            lurek.render.print("Space to continue", SCREEN_W / 2 - 60, 240, 14)
        end
    end
end
