--[[

  Drift Racing — Lurek2D
  Category: sports

  Top-down drift racing with drift scoring, AI opponents, boost pads,
  tire marks, and 3 tracks of increasing difficulty.
]]

-- Constants
local SCREEN_W = 800
local SCREEN_H = 600
local MAX_SPEED = 300
local ACCEL = 150
local BRAKE_DECEL = 200
local FRICTION = 40
local GRASS_SLOW = 0.5
local DRIFT_THRESHOLD = 150
local DRIFT_PTS_PER_SEC = 10
local BOOST_DURATION = 2.0
local BOOST_MULT = 1.5
local TOTAL_LAPS = 3
local AI_COUNT = 2
local ROAD_WIDTH = 60
local CHECKPOINT_RADIUS = 40
local BOOST_PAD_SIZE = 20

-- State
local state = "TITLE"
local dt = 0
local track_index = 1
local tracks = {}
local player = {}
local ai_cars = {}
local tire_marks = {}
local boost_pads = {}
local race_timer = 0
local best_lap = math.huge
local lap_start_time = 0
local results = {}
local camera_x, camera_y = 0, 0

-- Tween state
local tween_speed_display = 0
local tween_lap_scale = 1
local tween_pos_alpha = 0

-- Particle lists
local particles = {}

-- Track definitions (waypoints forming a loop)
local function define_tracks()
    tracks = {
        -- Track 1: Easy oval
        {
            name = "Coastal Loop",
            difficulty = "Easy",
            waypoints = {
                {x = 400, y = 100}, {x = 650, y = 150}, {x = 720, y = 300},
                {x = 680, y = 480}, {x = 500, y = 550}, {x = 300, y = 550},
                {x = 120, y = 480}, {x = 80, y = 300}, {x = 150, y = 150},
            },
            boost_spots = {{idx = 3}, {idx = 7}},
        },
        -- Track 2: Medium S-curves
        {
            name = "Mountain Pass",
            difficulty = "Medium",
            waypoints = {
                {x = 150, y = 80}, {x = 400, y = 80}, {x = 650, y = 150},
                {x = 700, y = 280}, {x = 550, y = 350}, {x = 350, y = 300},
                {x = 200, y = 350}, {x = 100, y = 450}, {x = 250, y = 550},
                {x = 500, y = 530}, {x = 650, y = 450}, {x = 600, y = 550},
                {x = 350, y = 580}, {x = 100, y = 500}, {x = 80, y = 250},
            },
            boost_spots = {{idx = 4}, {idx = 8}, {idx = 12}},
        },
        -- Track 3: Hard hairpins
        {
            name = "Drift City",
            difficulty = "Hard",
            waypoints = {
                {x = 100, y = 100}, {x = 300, y = 60}, {x = 500, y = 100},
                {x = 700, y = 80}, {x = 720, y = 200}, {x = 550, y = 220},
                {x = 400, y = 180}, {x = 350, y = 300}, {x = 500, y = 350},
                {x = 700, y = 330}, {x = 720, y = 460}, {x = 600, y = 540},
                {x = 400, y = 500}, {x = 250, y = 540}, {x = 100, y = 500},
                {x = 80, y = 350}, {x = 200, y = 280}, {x = 100, y = 200},
            },
            boost_spots = {{idx = 3}, {idx = 7}, {idx = 11}, {idx = 15}},
        },
    }
end

local function dist(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function angle_diff(a, b)
    local d = b - a
    while d > math.pi do d = d - 2 * math.pi end
    while d < -math.pi do d = d + 2 * math.pi end
    return d
end

local function point_to_segment_dist(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 == 0 then return dist(px, py, ax, ay) end
    local t = math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / len2))
    return dist(px, py, ax + t * dx, ay + t * dy)
end

local function is_on_road(x, y, waypoints)
    local n = #waypoints
    for i = 1, n do
        local j = (i % n) + 1
        if point_to_segment_dist(x, y, waypoints[i].x, waypoints[i].y, waypoints[j].x, waypoints[j].y) < ROAD_WIDTH then
            return true
        end
    end
    return false
end

local function spawn_particle(x, y, kind, vx, vy, life, r, g, b, a)
    table.insert(particles, {
        x = x, y = y, vx = vx or 0, vy = vy or 0,
        life = life or 0.5, max_life = life or 0.5,
        kind = kind, r = r or 1, g = g or 1, b = b or 1, a = a or 0.8,
    })
end

local function init_player(wp)
    local start = wp[1]
    local next_wp = wp[2]
    local angle = math.atan2(next_wp.y - start.y, next_wp.x - start.x)
    player = {
        x = start.x, y = start.y, angle = angle,
        speed = 0, drift_angle = 0, is_drifting = false,
        drift_score = 0, lap = 0, checkpoint = 1,
        boost_fuel = 0, boost_active = false, boost_timer = 0,
        finished = false, finish_time = 0,
    }
end

local function init_ai(wp)
    ai_cars = {}
    local colors = {{0.9, 0.2, 0.2}, {0.2, 0.2, 0.9}}
    for i = 1, AI_COUNT do
        local start = wp[1]
        local next_wp = wp[2]
        local angle = math.atan2(next_wp.y - start.y, next_wp.x - start.x)
        local offset = i * 25
        table.insert(ai_cars, {
            x = start.x - math.sin(angle) * offset,
            y = start.y + math.cos(angle) * offset,
            angle = angle, speed = 180 + i * 30,
            target_wp = 2, lap = 0, checkpoint = 1,
            finished = false, finish_time = 0,
            color = colors[i],
            wobble_phase = i * 1.7,
        })
    end
end

local function init_boost_pads(track)
    boost_pads = {}
    local wp = track.waypoints
    for _, spot in ipairs(track.boost_spots) do
        local w = wp[spot.idx]
        table.insert(boost_pads, {x = w.x, y = w.y, active = true, respawn_timer = 0})
    end
end

local function start_race()
    local track = tracks[track_index]
    init_player(track.waypoints)
    init_ai(track.waypoints)
    init_boost_pads(track)
    tire_marks = {}
    particles = {}
    race_timer = 0
    best_lap = math.huge
    lap_start_time = 0
    tween_speed_display = 0
    tween_lap_scale = 1
    tween_pos_alpha = 0
    state = "RACING"
end

local function get_position()
    local pos = 1
    for _, ai in ipairs(ai_cars) do
        if ai.finished and not player.finished then
            pos = pos + 1
        elseif not ai.finished and not player.finished then
            if ai.lap > player.lap or (ai.lap == player.lap and ai.checkpoint > player.checkpoint) then
                pos = pos + 1
            end
        end
    end
    return pos
end

local function update_car_physics(car_dt)
    local accel_input = lurek.input.wasActionPressed("accelerate")
    local brake_input = lurek.input.wasActionPressed("brake")
    local steer_l = lurek.input.wasActionPressed("steer_left")
    local steer_r = lurek.input.wasActionPressed("steer_right")
    local boost_input = lurek.input.wasActionPressed("boost")

    -- Boost activation
    if boost_input and player.boost_fuel > 0 and not player.boost_active then
        player.boost_active = true
        player.boost_timer = BOOST_DURATION
    end

    if player.boost_active then
        player.boost_timer = player.boost_timer - car_dt
        if player.boost_timer <= 0 then
            player.boost_active = false
            player.boost_fuel = math.max(0, player.boost_fuel - 1)
        end
        -- Boost flame particles
        local bx = player.x - math.cos(player.angle) * 18
        local by = player.y - math.sin(player.angle) * 18
        spawn_particle(bx, by, "boost", -math.cos(player.angle) * 60, -math.sin(player.angle) * 60, 0.3, 1, 0.6, 0.1, 0.9)
    end

    local speed_mult = 1
    if player.boost_active then speed_mult = BOOST_MULT end

    local track = tracks[track_index]
    local on_road = is_on_road(player.x, player.y, track.waypoints)
    if not on_road then speed_mult = speed_mult * GRASS_SLOW end

    -- Acceleration / braking
    if accel_input then
        player.speed = math.min(player.speed + ACCEL * car_dt, MAX_SPEED * speed_mult)
    elseif brake_input then
        player.speed = math.max(player.speed - BRAKE_DECEL * car_dt, -50)
    else
        if player.speed > 0 then
            player.speed = math.max(0, player.speed - FRICTION * car_dt)
        elseif player.speed < 0 then
            player.speed = math.min(0, player.speed + FRICTION * car_dt)
        end
    end

    -- Steering
    local steer_rate = 3.0
    if math.abs(player.speed) < 30 then steer_rate = 1.0 end

    if steer_l then
        player.angle = player.angle - steer_rate * car_dt
    elseif steer_r then
        player.angle = player.angle + steer_rate * car_dt
    end

    -- Drift mechanics
    local abs_speed = math.abs(player.speed)
    if abs_speed > DRIFT_THRESHOLD and (steer_l or steer_r) then
        local drift_strength = (abs_speed - DRIFT_THRESHOLD) / (MAX_SPEED - DRIFT_THRESHOLD)
        local target_drift = (steer_l and -1 or 1) * drift_strength * 0.6
        player.drift_angle = lerp(player.drift_angle, target_drift, 4 * car_dt)
        player.is_drifting = math.abs(player.drift_angle) > 0.1

        if player.is_drifting then
            player.drift_score = player.drift_score + DRIFT_PTS_PER_SEC * car_dt
            -- Tire smoke particles
            local rx = player.x - math.cos(player.angle) * 14
            local ry = player.y - math.sin(player.angle) * 14
            spawn_particle(rx, ry, "smoke", (math.random() - 0.5) * 30, (math.random() - 0.5) * 30, 0.6, 0.7, 0.7, 0.7, 0.5)

            -- Tire marks
            table.insert(tire_marks, {x = rx, y = ry, alpha = 0.6, age = 0})
            if #tire_marks > 500 then table.remove(tire_marks, 1) end
        end
    else
        player.drift_angle = lerp(player.drift_angle, 0, 6 * car_dt)
        player.is_drifting = false
    end

    -- Movement with drift
    local move_angle = player.angle + player.drift_angle
    player.x = player.x + math.cos(move_angle) * player.speed * car_dt
    player.y = player.y + math.sin(move_angle) * player.speed * car_dt

    -- Clamp to world
    player.x = math.max(0, math.min(player.x, SCREEN_W * 2))
    player.y = math.max(0, math.min(player.y, SCREEN_H * 2))
end

local function update_checkpoints()
    local track = tracks[track_index]
    local wp = track.waypoints
    local n = #wp
    local next_cp = (player.checkpoint % n) + 1
    local cp = wp[next_cp]

    if dist(player.x, player.y, cp.x, cp.y) < CHECKPOINT_RADIUS then
        player.checkpoint = next_cp
        -- Checkpoint flash particles
        for _ = 1, 8 do
            spawn_particle(cp.x, cp.y, "flash",
                (math.random() - 0.5) * 120, (math.random() - 0.5) * 120,
                0.4, 1, 1, 0.3, 1)
        end

        -- Lap completion (crossed start after visiting all checkpoints)
        if next_cp == 1 then
            player.lap = player.lap + 1
            local lap_time = race_timer - lap_start_time
            if lap_time < best_lap and player.lap > 0 then
                best_lap = lap_time
            end
            lap_start_time = race_timer
            tween_lap_scale = 1.5

            if player.lap >= TOTAL_LAPS then
                player.finished = true
                player.finish_time = race_timer
            end
        end
    end
end

local function update_ai(car_dt)
    local track = tracks[track_index]
    local wp = track.waypoints
    local n = #wp

    for _, ai in ipairs(ai_cars) do
        if ai.finished then goto continue end

        local target = wp[ai.target_wp]
        local dx = target.x - ai.x
        local dy = target.y - ai.y
        local d = math.sqrt(dx * dx + dy * dy)
        local target_angle = math.atan2(dy, dx)

        -- Wobble
        ai.wobble_phase = ai.wobble_phase + car_dt * 2
        local wobble = math.sin(ai.wobble_phase) * 0.15

        local diff = angle_diff(ai.angle, target_angle + wobble)
        ai.angle = ai.angle + diff * math.min(1, 4 * car_dt)

        ai.x = ai.x + math.cos(ai.angle) * ai.speed * car_dt
        ai.y = ai.y + math.sin(ai.angle) * ai.speed * car_dt

        if d < CHECKPOINT_RADIUS then
            ai.checkpoint = ai.target_wp
            ai.target_wp = (ai.target_wp % n) + 1
            if ai.target_wp == 1 then
                -- Actually we increment when crossing start
            end
            if ai.checkpoint == 1 and ai.target_wp == 2 then
                ai.lap = ai.lap + 1
                if ai.lap >= TOTAL_LAPS then
                    ai.finished = true
                    ai.finish_time = race_timer
                end
            end
        end
        ::continue::
    end
end

local function update_boost_pads(pad_dt)
    for _, pad in ipairs(boost_pads) do
        if not pad.active then
            pad.respawn_timer = pad.respawn_timer - pad_dt
            if pad.respawn_timer <= 0 then
                pad.active = true
            end
        elseif dist(player.x, player.y, pad.x, pad.y) < BOOST_PAD_SIZE + 10 then
            pad.active = false
            pad.respawn_timer = 5.0
            player.boost_fuel = player.boost_fuel + 1
        end
    end
end

local function update_particles(p_dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * p_dt
        p.y = p.y + p.vy * p_dt
        p.life = p.life - p_dt
        p.a = (p.life / p.max_life) * 0.8
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

local function update_tire_marks(m_dt)
    for i = #tire_marks, 1, -1 do
        tire_marks[i].age = tire_marks[i].age + m_dt
        tire_marks[i].alpha = math.max(0, 0.6 - tire_marks[i].age * 0.15)
        if tire_marks[i].alpha <= 0 then
            table.remove(tire_marks, i)
        end
    end
end

local function update_tweens(tw_dt)
    tween_speed_display = lerp(tween_speed_display, math.abs(player.speed), 8 * tw_dt)
    tween_lap_scale = lerp(tween_lap_scale, 1.0, 5 * tw_dt)
    tween_pos_alpha = lerp(tween_pos_alpha, 1.0, 3 * tw_dt)
end

local function check_race_end()
    if player.finished then
        local all_done = true
        for _, ai in ipairs(ai_cars) do
            if not ai.finished then
                -- Give AI a few more seconds
                if race_timer - player.finish_time > 5 then
                    ai.finished = true
                    ai.finish_time = race_timer
                else
                    all_done = false
                end
            end
        end
        if all_done then
            results = {
                position = get_position(),
                total_time = player.finish_time,
                best_lap = best_lap,
                drift_score = math.floor(player.drift_score),
            }
            state = "RESULTS"
        end
    end
end

-- Draw helpers
local function draw_road_segment(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end
    local nx, ny = -dy / len * ROAD_WIDTH, dx / len * ROAD_WIDTH
    lurek.render.drawq(
        ax + nx, ay + ny, bx + nx, by + ny,
        bx - nx, by - ny, ax - nx, ay - ny,
        0.35, 0.35, 0.35, 1
    )
end

local function draw_car(x, y, angle, w, h, r, g, b)
    lurek.render.push()
    lurek.render.translate(x, y)
    lurek.render.rotate(angle)
    lurek.render.setColor(r, g, b, 1)
    lurek.render.rectangle("fill", -w / 2, -h / 2, w, h)
    -- Windshield
    lurek.render.setColor(0.6, 0.8, 1, 0.8)
    lurek.render.rectangle("fill", w * 0.1, -h * 0.3, w * 0.25, h * 0.6)
    lurek.render.pop()
end

-- Callbacks
lurek.input.bind("accelerate", "w")
lurek.input.bind("accelerate", "up")
lurek.input.bind("brake", "s")
lurek.input.bind("brake", "down")
lurek.input.bind("steer_left", "a")
lurek.input.bind("steer_left", "left")
lurek.input.bind("steer_right", "d")
lurek.input.bind("steer_right", "right")
lurek.input.bind("boost", "space")
lurek.input.bind("quit", "escape")

define_tracks()

function lurek.init()
    lurek.window.setTitle("Drift Racing — Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.2, 0.1)
end

local function _ready_setup()
    state = "TITLE"
end

function lurek.process(delta)
    dt = delta

    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    if state == "TITLE" then
        if lurek.input.wasActionPressed("accelerate") then
            state = "TRACK_SELECT"
        end

    elseif state == "TRACK_SELECT" then
        if lurek.input.wasActionPressed("1") then
            track_index = 1; start_race()
        elseif lurek.input.wasActionPressed("2") then
            track_index = 2; start_race()
        elseif lurek.input.wasActionPressed("3") then
            track_index = 3; start_race()
        end

    elseif state == "RACING" then
        if not player.finished then
            race_timer = race_timer + dt
            update_car_physics(dt)
            update_checkpoints()
        end
        update_ai(dt)
        update_boost_pads(dt)
        update_particles(dt)
        update_tire_marks(dt)
        update_tweens(dt)
        check_race_end()

        -- Camera follow player
        camera_x = lerp(camera_x, player.x - SCREEN_W / 2, 5 * dt)
        camera_y = lerp(camera_y, player.y - SCREEN_H / 2, 5 * dt)

    elseif state == "RESULTS" then
        if lurek.input.wasActionPressed("accelerate") then
            state = "TRACK_SELECT"
        end
    end

    lurek.window.setTitle(string.format("Drift Racing — FPS: %d", lurek.timer.getFPS()))
end

function lurek.draw()
    if state == "RACING" then
        lurek.render.push()
        lurek.render.translate(-camera_x, -camera_y)

        local track = tracks[track_index]
        local wp = track.waypoints
        local n = #wp

        -- Draw grass background
        lurek.render.setColor(0.2, 0.45, 0.15, 1)
        lurek.render.rectangle("fill", -200, -200, SCREEN_W * 2 + 400, SCREEN_H * 2 + 400)

        -- Draw road segments
        for i = 1, n do
            local j = (i % n) + 1
            draw_road_segment(wp[i].x, wp[i].y, wp[j].x, wp[j].y)
        end

        -- Draw start/finish line
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.rectangle("fill", wp[1].x - 4, wp[1].y - ROAD_WIDTH, 8, ROAD_WIDTH * 2)

        -- Draw tire marks
        for _, mark in ipairs(tire_marks) do
            lurek.render.setColor(0.15, 0.15, 0.15, mark.alpha)
            lurek.render.circle("fill", mark.x, mark.y, 2)
        end

        -- Draw boost pads
        for _, pad in ipairs(boost_pads) do
            if pad.active then
                lurek.render.setColor(1, 0.9, 0.1, 0.9)
                lurek.render.rectangle("fill", pad.x - BOOST_PAD_SIZE / 2, pad.y - BOOST_PAD_SIZE / 2, BOOST_PAD_SIZE, BOOST_PAD_SIZE)
            end
        end

        -- Draw checkpoint indicators (subtle)
        local next_cp = (player.checkpoint % n) + 1
        local cp = wp[next_cp]
        lurek.render.setColor(0.3, 1, 0.3, 0.3 + 0.2 * math.sin(race_timer * 4))
        lurek.render.circle("line", cp.x, cp.y, CHECKPOINT_RADIUS)

        -- Draw AI cars
        for _, ai in ipairs(ai_cars) do
            draw_car(ai.x, ai.y, ai.angle, 28, 14, ai.color[1], ai.color[2], ai.color[3])
        end

        -- Draw player car
        draw_car(player.x, player.y, player.angle, 30, 15, 0.1, 0.8, 0.2)

        -- Draw particles
        for _, p in ipairs(particles) do
            lurek.render.setColor(p.r, p.g, p.b, p.a)
            if p.kind == "smoke" then
                lurek.render.circle("fill", p.x, p.y, 3 + (1 - p.life / p.max_life) * 4)
            elseif p.kind == "boost" then
                lurek.render.circle("fill", p.x, p.y, 4)
            elseif p.kind == "flash" then
                lurek.render.circle("fill", p.x, p.y, 2 + p.life * 6)
            end
        end

        lurek.render.pop()
    end
end

function lurek.draw_ui()
    if state == "TITLE" then
        lurek.render.setColor(1, 0.85, 0.1, 1)
        lurek.render.print("DRIFT RACING", SCREEN_W / 2 - 120, SCREEN_H / 2 - 60, 0, 3, 3)
        lurek.render.setColor(0.8, 0.8, 0.8, 0.7 + 0.3 * math.sin(lurek.timer.getTime() * 3))
        lurek.render.print("SLIDE TO WIN", SCREEN_W / 2 - 80, SCREEN_H / 2 + 10, 0, 1.5, 1.5)
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        lurek.render.print("Press W to start", SCREEN_W / 2 - 60, SCREEN_H / 2 + 60)

    elseif state == "TRACK_SELECT" then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("SELECT TRACK", SCREEN_W / 2 - 100, 80, 0, 2.5, 2.5)
        for i, track in ipairs(tracks) do
            local y = 180 + (i - 1) * 80
            lurek.render.setColor(0.9, 0.9, 0.3, 1)
            lurek.render.print(string.format("[%d] %s", i, track.name), SCREEN_W / 2 - 100, y, 0, 1.5, 1.5)
            lurek.render.setColor(0.6, 0.6, 0.6, 1)
            lurek.render.print("Difficulty: " .. track.difficulty, SCREEN_W / 2 - 80, y + 30)
        end

    elseif state == "RACING" then
        -- Speed display (tweened)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(string.format("Speed: %d", math.floor(tween_speed_display)), 20, 20)

        -- Lap counter (with scale tween)
        local lap_text = string.format("Lap %d / %d", math.min(player.lap + 1, TOTAL_LAPS), TOTAL_LAPS)
        lurek.render.setColor(1, 1, 0.3, 1)
        lurek.render.print(lap_text, 20, 50, 0, tween_lap_scale, tween_lap_scale)

        -- Race timer
        lurek.render.setColor(1, 1, 1, 0.9)
        lurek.render.print(string.format("Time: %.1fs", race_timer), SCREEN_W - 160, 20)

        -- Best lap
        if best_lap < math.huge then
            lurek.render.setColor(0.3, 1, 0.3, 1)
            lurek.render.print(string.format("Best Lap: %.1fs", best_lap), SCREEN_W - 180, 45)
        end

        -- Position (tweened alpha)
        local pos = get_position()
        local pos_labels = {"1st", "2nd", "3rd"}
        local pos_colors = {{1, 0.85, 0}, {0.75, 0.75, 0.75}, {0.8, 0.5, 0.2}}
        local pc = pos_colors[pos] or {1, 1, 1}
        lurek.render.setColor(pc[1], pc[2], pc[3], tween_pos_alpha)
        lurek.render.print(pos_labels[pos] or tostring(pos), SCREEN_W / 2 - 20, 15, 0, 2, 2)

        -- Drift score
        if player.is_drifting then
            lurek.render.setColor(1, 0.5, 0, 0.9)
            lurek.render.print(string.format("DRIFT! +%d", math.floor(player.drift_score)), SCREEN_W / 2 - 50, 55, 0, 1.3, 1.3)
        else
            lurek.render.setColor(0.7, 0.7, 0.7, 0.6)
            lurek.render.print(string.format("Drift: %d pts", math.floor(player.drift_score)), 20, 80)
        end

        -- Boost indicator
        if player.boost_fuel > 0 then
            lurek.render.setColor(1, 0.9, 0.1, 1)
            lurek.render.print(string.format("Boost: %d", player.boost_fuel), 20, 105)
        end
        if player.boost_active then
            lurek.render.setColor(1, 0.4, 0, 0.8 + 0.2 * math.sin(race_timer * 10))
            lurek.render.print("BOOST!", SCREEN_W / 2 - 30, 80, 0, 1.5, 1.5)
        end

    elseif state == "RESULTS" then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("RACE COMPLETE!", SCREEN_W / 2 - 120, 80, 0, 2.5, 2.5)

        local pos_labels = {"1st", "2nd", "3rd"}
        local pos_colors = {{1, 0.85, 0}, {0.75, 0.75, 0.75}, {0.8, 0.5, 0.2}}
        local pc = pos_colors[results.position] or {1, 1, 1}

        lurek.render.setColor(pc[1], pc[2], pc[3], 1)
        lurek.render.print(string.format("Position: %s", pos_labels[results.position] or "???"), SCREEN_W / 2 - 100, 180, 0, 2, 2)

        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(string.format("Total Time: %.1fs", results.total_time), SCREEN_W / 2 - 80, 250)

        if results.best_lap < math.huge then
            lurek.render.setColor(0.3, 1, 0.3, 1)
            lurek.render.print(string.format("Best Lap: %.1fs", results.best_lap), SCREEN_W / 2 - 80, 290)
        end

        lurek.render.setColor(1, 0.5, 0, 1)
        lurek.render.print(string.format("Drift Score: %d pts", results.drift_score), SCREEN_W / 2 - 80, 330)

        lurek.render.setColor(0.6, 0.6, 0.6, 0.7 + 0.3 * math.sin(lurek.timer.getTime() * 3))
        lurek.render.print("Press W for track select", SCREEN_W / 2 - 90, 420)
    end
end
