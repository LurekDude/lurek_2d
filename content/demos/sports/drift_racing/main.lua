-- Top-Down Drift Racing
-- W=accelerate, S=brake, A/D=steer. Drift around an oval track.
-- 3 laps to win. AI cars follow the track. Boost zones on track.
-- Run with: cargo run -- demos/sports/drift_racing

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600
local TWO_PI = math.pi * 2

-- Track definition (oval waypoints)
local track_pts = {}
local track_inner = {}
local track_outer = {}
local checkpoints = {}
local boost_zones = {}

local car = {}
local ai_cars = {}
local skid_marks = {}

local state = {}

local function build_track()
    local cx, cy = W / 2, H / 2
    local rx, ry = 300, 200
    local n = 60
    track_pts = {}
    track_inner = {}
    track_outer = {}
    local road_w = 50
    for i = 0, n do
        local a = (i / n) * TWO_PI
        local px = cx + math.cos(a) * rx
        local py = cy + math.sin(a) * ry
        track_pts[i + 1] = { x = px, y = py }
        track_inner[i + 1] = {
            x = cx + math.cos(a) * (rx - road_w),
            y = cy + math.sin(a) * (ry - road_w)
        }
        track_outer[i + 1] = {
            x = cx + math.cos(a) * (rx + road_w),
            y = cy + math.sin(a) * (ry + road_w)
        }
    end

    -- checkpoints at 4 positions
    checkpoints = {}
    for i = 1, 4 do
        local idx = math.floor((i - 1) * n / 4) + 1
        checkpoints[i] = { x = track_pts[idx].x, y = track_pts[idx].y, idx = idx }
    end

    -- boost zones at 2 positions
    boost_zones = {}
    for i = 1, 2 do
        local idx = math.floor((i - 0.5) * n / 2) + 1
        if idx > #track_pts then idx = #track_pts end
        boost_zones[i] = { x = track_pts[idx].x, y = track_pts[idx].y, radius = 25, active = true }
    end
end

local function make_car(track_idx, color_r, color_g, color_b)
    local pt = track_pts[track_idx] or track_pts[1]
    return {
        x = pt.x, y = pt.y,
        angle = 0, speed = 0,
        vx = 0, vy = 0,
        drift = 0,
        r = color_r, g = color_g, b = color_b,
        lap = 0, checkpoint = 0,
        lap_time = 0, best_lap = 999,
        boost = 0, track_idx = track_idx
    }
end

local function closest_track_idx(px, py)
    local best_d = 999999
    local best_i = 1
    for i, p in ipairs(track_pts) do
        local dx = px - p.x
        local dy = py - p.y
        local d = dx * dx + dy * dy
        if d < best_d then best_d = d; best_i = i end
    end
    return best_i
end

function luna.init()
    build_track()
    car = make_car(1, 0, 0.8, 1)
    car.angle = -math.pi / 2
    ai_cars = {}
    local ai_colors = { { 1, 0.3, 0.3 }, { 0.3, 1, 0.3 }, { 1, 1, 0.3 } }
    for i = 1, 3 do
        local offset = math.floor(#track_pts * i / 4) + 1
        if offset > #track_pts then offset = offset - #track_pts end
        local ai = make_car(offset, ai_colors[i][1], ai_colors[i][2], ai_colors[i][3])
        ai.ai = true
        ai.ai_speed = 120 + i * 15
        ai_cars[i] = ai
    end
    skid_marks = {}
    state.finished = false
    state.laps_to_win = 3
    state.race_time = 0
    state.message = ""
end

local function update_car_physics(c, dt, accel, brake, steer)
    -- steering
    if c.speed > 5 then
        c.angle = c.angle + steer * 3.0 * dt
    end

    -- acceleration
    local max_speed = 250
    if c.boost > 0 then max_speed = 400; c.boost = c.boost - dt end
    c.speed = c.speed + accel * 300 * dt
    c.speed = c.speed - brake * 200 * dt
    c.speed = c.speed * (1 - 0.5 * dt) -- drag
    c.speed = clamp(c.speed, -60, max_speed)

    -- forward direction
    local fx = math.cos(c.angle)
    local fy = math.sin(c.angle)

    -- target velocity (forward direction * speed)
    local tvx = fx * c.speed
    local tvy = fy * c.speed

    -- blend current velocity toward target (drift factor)
    -- Lower grip when steering hard at speed = drift / slide sensation
    local grip = 0.08
    if math.abs(steer) > 0.1 and c.speed > 80 then grip = 0.03 end
    c.vx = lerp(c.vx, tvx, grip)
    c.vy = lerp(c.vy, tvy, grip)

    c.x = c.x + c.vx * dt
    c.y = c.vy and c.y + c.vy * dt or c.y

    -- drift amount (lateral velocity component)
    local lat = -fx * c.vy + fy * c.vx
    c.drift = math.abs(lat)

    -- skid marks when drifting
    -- Cap the history at 500 points to avoid unbounded memory growth
    if c.drift > 40 and c.speed > 50 then
        skid_marks[#skid_marks + 1] = { x = c.x, y = c.y, t = 3 }
        if #skid_marks > 500 then table.remove(skid_marks, 1) end
    end

    -- wrap around screen
    if c.x < -20 then c.x = W + 20 end
    if c.x > W + 20 then c.x = -20 end
    if c.y < -20 then c.y = H + 20 end
    if c.y > H + 20 then c.y = -20 end

    -- boost zone check
    for _, bz in ipairs(boost_zones) do
        if bz.active then
            local dx = c.x - bz.x
            local dy = c.y - bz.y
            if math.sqrt(dx * dx + dy * dy) < bz.radius then
                c.boost = 1.5
                bz.active = false
            end
        end
    end
end

local function update_checkpoints(c)
    local next_cp = (c.checkpoint % #checkpoints) + 1
    local cp = checkpoints[next_cp]
    local dx = c.x - cp.x
    local dy = c.y - cp.y
    if math.sqrt(dx * dx + dy * dy) < 50 then
        c.checkpoint = next_cp
        if next_cp == 1 and c.checkpoint == 1 then
            c.lap = c.lap + 1
            if c.lap_time > 0 and c.lap_time < c.best_lap then
                c.best_lap = c.lap_time
            end
            c.lap_time = 0
        end
    end
end

function luna.process(dt)
    if state.finished then return end
    state.race_time = state.race_time + dt

    -- player input
    local accel, brake, steer = 0, 0, 0
    if luna.keyboard.isDown("w") or luna.keyboard.isDown("up") then accel = 1 end
    if luna.keyboard.isDown("s") or luna.keyboard.isDown("down") then brake = 1 end
    if luna.keyboard.isDown("a") or luna.keyboard.isDown("left") then steer = -1 end
    if luna.keyboard.isDown("d") or luna.keyboard.isDown("right") then steer = 1 end

    update_car_physics(car, dt, accel, brake, steer)
    car.lap_time = car.lap_time + dt
    update_checkpoints(car)

    if car.lap >= state.laps_to_win then
        state.finished = true
        state.message = "You finished in " .. math.floor(state.race_time) .. "s!"
    end

    -- AI cars
    for _, ai in ipairs(ai_cars) do
        local target_idx = ai.track_idx + 2
        if target_idx > #track_pts then target_idx = target_idx - #track_pts end
        local tp = track_pts[target_idx]
        local dx = tp.x - ai.x
        local dy = tp.y - ai.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 30 then
            ai.track_idx = target_idx
        end
        local target_angle = math.atan2(dy, dx)
        local diff = target_angle - ai.angle
        while diff > math.pi do diff = diff - TWO_PI end
        while diff < -math.pi do diff = diff + TWO_PI end
        local ai_steer = clamp(diff * 3, -1, 1)
        update_car_physics(ai, dt, 1, 0, ai_steer)
        ai.speed = clamp(ai.speed, 0, ai.ai_speed)
        ai.lap_time = ai.lap_time + dt
        update_checkpoints(ai)
    end

    -- recharge boost zones
    for _, bz in ipairs(boost_zones) do
        if not bz.active then
            bz.timer = (bz.timer or 0) + dt
            if bz.timer > 5 then bz.active = true; bz.timer = 0 end
        end
    end

    -- fade skid marks
    local i = 1
    while i <= #skid_marks do
        skid_marks[i].t = skid_marks[i].t - dt
        if skid_marks[i].t <= 0 then
            table.remove(skid_marks, i)
        else
            i = i + 1
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.signal.restart() end
end

local function draw_car(c)
    local hw, hh = 12, 7
    local cos_a = math.cos(c.angle)
    local sin_a = math.sin(c.angle)
    local corners = {
        c.x + cos_a * hw - sin_a * hh, c.y + sin_a * hw + cos_a * hh,
        c.x + cos_a * hw + sin_a * hh, c.y + sin_a * hw - cos_a * hh,
        c.x - cos_a * hw + sin_a * hh, c.y - sin_a * hw - cos_a * hh,
        c.x - cos_a * hw - sin_a * hh, c.y - sin_a * hw + cos_a * hh
    }
    luna.gfx.setColor(c.r, c.g, c.b, 1)
    luna.gfx.polygon("fill", corners)
    luna.gfx.setColor(1, 1, 1, 0.5)
    luna.gfx.polygon("line", corners)
end

function luna.render()
    luna.gfx.setBackgroundColor(0.15, 0.18, 0.12)

    -- draw track road
    luna.gfx.setColor(0.3, 0.3, 0.3, 1)
    for i = 1, #track_outer - 1 do
        local a = track_outer[i]; local b = track_outer[i + 1]
        local c = track_inner[i + 1]; local d = track_inner[i]
        luna.gfx.polygon("fill", { a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y })
    end

    -- track edges
    luna.gfx.setColor(1, 1, 1, 0.3)
    luna.gfx.setLineWidth(2)
    for i = 1, #track_outer - 1 do
        luna.gfx.line(track_outer[i].x, track_outer[i].y, track_outer[i + 1].x, track_outer[i + 1].y)
        luna.gfx.line(track_inner[i].x, track_inner[i].y, track_inner[i + 1].x, track_inner[i + 1].y)
    end

    -- boost zones
    for _, bz in ipairs(boost_zones) do
        if bz.active then
            luna.gfx.setColor(0, 1, 1, 0.4)
            luna.gfx.circle("fill", bz.x, bz.y, bz.radius)
            luna.gfx.setColor(0, 1, 1, 0.8)
            luna.gfx.circle("line", bz.x, bz.y, bz.radius)
        end
    end

    -- checkpoints
    for i, cp in ipairs(checkpoints) do
        luna.gfx.setColor(1, 1, 0, 0.3)
        luna.gfx.circle("fill", cp.x, cp.y, 10)
        luna.gfx.setColor(1, 1, 0, 0.7)
        luna.gfx.print(tostring(i), cp.x - 3, cp.y - 6)
    end

    -- skid marks
    luna.gfx.setColor(0.15, 0.15, 0.15, 0.5)
    for _, s in ipairs(skid_marks) do
        luna.gfx.circle("fill", s.x, s.y, 2)
    end

    -- AI cars
    for _, ai in ipairs(ai_cars) do draw_car(ai) end

    -- player car
    draw_car(car)
    if car.boost > 0 then
        luna.gfx.setColor(0, 1, 1, 0.6)
        luna.gfx.circle("fill", car.x, car.y, 15)
    end

    -- HUD
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Speed: " .. math.floor(car.speed), 10, 10)
    luna.gfx.print("Lap: " .. car.lap .. "/" .. state.laps_to_win, 10, 30)
    local lt = math.floor(car.lap_time * 10) / 10
    luna.gfx.print("Lap Time: " .. lt .. "s", 10, 50)
    luna.gfx.print("Drift: " .. math.floor(car.drift), 10, 70)

    if car.boost > 0 then
        luna.gfx.setColor(0, 1, 1, 1)
        luna.gfx.print("BOOST!", 10, 90)
    end

    -- mini map
    local mx, my, ms = W - 110, 10, 0.12
    luna.gfx.setColor(0, 0, 0, 0.5)
    luna.gfx.rectangle("fill", mx - 5, my - 5, 110, 85)
    luna.gfx.setColor(0.4, 0.4, 0.4, 0.8)
    for i = 1, #track_pts - 1 do
        local a, b = track_pts[i], track_pts[i + 1]
        luna.gfx.line(mx + a.x * ms, my + a.y * ms, mx + b.x * ms, my + b.y * ms)
    end
    luna.gfx.setColor(0, 0.8, 1, 1)
    luna.gfx.circle("fill", mx + car.x * ms, my + car.y * ms, 3)
    for _, ai in ipairs(ai_cars) do
        luna.gfx.setColor(ai.r, ai.g, ai.b, 1)
        luna.gfx.circle("fill", mx + ai.x * ms, my + ai.y * ms, 2)
    end

    -- finished message
    if state.finished then
        luna.gfx.setColor(1, 1, 0.3, 1)
        luna.gfx.print(state.message, W / 2 - 120, H / 2 - 15, 1.5)
    end

    luna.gfx.setColor(0.6, 0.6, 0.6, 0.5)
    luna.gfx.print("WASD: Drive | R: Restart", W / 2 - 80, H - 20)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), W - 80, H - 20)
end
