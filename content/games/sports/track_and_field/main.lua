-- ============================================================================
-- Track & Field — Lurek2D
-- ============================================================================
-- Category : sports
-- Source   : content/games/sports/track_and_field/main.lua
-- Run with : cargo run -- content/games/sports/track_and_field
-- ============================================================================
-- Olympic-style athletics with 5 events: 100m Sprint, Long Jump, Javelin,
-- High Jump, 110m Hurdles. Mash A/D to run, Space for context actions.
-- Medal tally at the end.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = {
    TITLE        = 1,
    EVENT_INTRO  = 2,
    RUNNING      = 3,
    JUMPING      = 4,
    THROWING     = 5,
    EVENT_RESULT = 6,
    FINAL        = 7,
}

local EVENT = {
    SPRINT_100   = 1,
    LONG_JUMP    = 2,
    JAVELIN      = 3,
    HIGH_JUMP    = 4,
    HURDLES_110  = 5,
}

local EVENT_NAMES = {
    "100m Sprint",
    "Long Jump",
    "Javelin Throw",
    "High Jump",
    "110m Hurdles",
}

local NUM_EVENTS     = 5
local GRAVITY        = 980
local TRACK_Y        = 420
local TRACK_LEFT     = 50
local TRACK_RIGHT    = 750
local RUNNER_W       = 20
local RUNNER_H       = 40
local MASH_DECAY     = 3.0
local MAX_SPEED      = 300
local AI_COUNT       = 3

-- Qualifying standards (lower is better for time, higher for distance)
local QUALIFY = { 10.5, 7.0, 70.0, 2.10, 14.0 }

-- Colors
local COL_TRACK      = { 0.72, 0.35, 0.28 }
local COL_GRASS      = { 0.25, 0.55, 0.20 }
local COL_LINE       = { 1, 1, 1 }
local COL_PLAYER     = { 0.20, 0.45, 0.85 }
local COL_AI         = {
    { 0.85, 0.25, 0.20 },
    { 0.20, 0.75, 0.30 },
    { 0.80, 0.65, 0.15 },
}
local COL_HURDLE     = { 0.90, 0.90, 0.90 }
local COL_GOLD       = { 1.00, 0.84, 0.00 }
local COL_SILVER     = { 0.75, 0.75, 0.75 }
local COL_BRONZE     = { 0.80, 0.50, 0.20 }
local COL_HUD_BG     = { 0.08, 0.08, 0.10, 0.85 }
local COL_WHITE      = { 1, 1, 1 }
local COL_DARK       = { 0.12, 0.12, 0.15 }
local COL_BAR        = { 0.85, 0.85, 0.20 }

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local current_state  = STATE.TITLE
local current_event  = EVENT.SPRINT_100
local intro_timer    = 0
local result_timer   = 0

-- Player
local px, py         = 0, 0
local p_speed        = 0
local p_vy           = 0
local p_airborne     = false
local p_last_key     = ""   -- "a" or "d"
local p_mash_power   = 0
local p_stamina      = 100
local p_max_stamina  = 100

-- Event-specific
local attempt        = 0
local max_attempts   = 3
local event_timer    = 0
local distance       = 0
local best_distance  = 0
local angle          = 0
local angle_set      = false
local throw_released = false
local wind_speed     = 0

-- High jump
local hj_bar_height  = 1.50
local hj_failures    = 0
local hj_cleared     = false
local hj_jumping     = false
local hj_approach_x  = 0

-- Hurdles
local hurdles        = {}
local hurdle_penalty = 0
local hurdles_cleared = 0

-- AI runners
local ai_runners     = {}

-- Results
local event_results  = {}   -- per-event: { player_rank, player_score, medal }
local medals         = { gold = 0, silver = 0, bronze = 0 }
local total_points   = 0

-- Particles
local ps_dust        = nil
local ps_impact      = nil
local ps_trail       = nil
local ps_confetti    = nil

-- Tween targets
local tw_speed_meter = { value = 0 }
local tw_distance    = { value = 0 }
local tw_medal_alpha = { value = 0 }

-- Camera
local camera         = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
local function lerp(a, b, t) return a + (b - a) * t end
local function rand_range(lo, hi) return lo + math.random() * (hi - lo) end

local function medal_for_rank(rank)
    if rank == 1 then return "gold"
    elseif rank == 2 then return "silver"
    elseif rank == 3 then return "bronze"
    else return nil end
end

local function medal_color(m)
    if m == "gold" then return COL_GOLD
    elseif m == "silver" then return COL_SILVER
    elseif m == "bronze" then return COL_BRONZE
    else return COL_WHITE end
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
lurek.input.bind("run_left",  "a")
lurek.input.bind("run_right", "d")
lurek.input.bind("action",    "space")
lurek.input.bind("quit",      "escape")

-- ---------------------------------------------------------------------------
-- Init AI runners
-- ---------------------------------------------------------------------------
local function init_ai()
    ai_runners = {}
    for i = 1, AI_COUNT do
        ai_runners[i] = {
            x        = 0,
            speed    = 0,
            target_speed = rand_range(180, 260),
            reaction = rand_range(0.1, 0.4),
            finished = false,
            time     = 0,
            lane_y   = TRACK_Y - 60 - i * 30,
            color    = COL_AI[i],
            hurdle_jump = false,
            hurdle_vy   = 0,
            hurdle_y    = 0,
        }
    end
end

-- ---------------------------------------------------------------------------
-- Init particles
-- ---------------------------------------------------------------------------
local function init_particles()
    ps_dust = lurek.particle.new()
    ps_dust:setEmissionRate(0)
    ps_dust:setLifetime(0.4, 0.8)
    ps_dust:setSpeed(20, 60)
    ps_dust:setDirection(math.pi * 0.5)
    ps_dust:setSpread(math.pi * 0.6)
    ps_dust:setColor(0.6, 0.5, 0.4, 0.7, 0.6, 0.5, 0.4, 0)
    ps_dust:setSize(2, 5)

    ps_impact = lurek.particle.new()
    ps_impact:setEmissionRate(0)
    ps_impact:setLifetime(0.3, 0.6)
    ps_impact:setSpeed(40, 100)
    ps_impact:setDirection(math.pi * 1.5)
    ps_impact:setSpread(math.pi)
    ps_impact:setColor(0.7, 0.6, 0.4, 1, 0.7, 0.6, 0.4, 0)
    ps_impact:setSize(3, 7)

    ps_trail = lurek.particle.new()
    ps_trail:setEmissionRate(0)
    ps_trail:setLifetime(0.2, 0.5)
    ps_trail:setSpeed(10, 30)
    ps_trail:setDirection(math.pi)
    ps_trail:setSpread(0.3)
    ps_trail:setColor(0.9, 0.85, 0.7, 0.6, 0.9, 0.85, 0.7, 0)
    ps_trail:setSize(2, 4)

    ps_confetti = lurek.particle.new()
    ps_confetti:setEmissionRate(0)
    ps_confetti:setLifetime(1.0, 2.5)
    ps_confetti:setSpeed(50, 150)
    ps_confetti:setDirection(math.pi * 1.5)
    ps_confetti:setSpread(math.pi * 0.8)
    ps_confetti:setColor(1, 0.8, 0.2, 1, 0.2, 0.6, 1, 0)
    ps_confetti:setSize(3, 6)
end

-- ---------------------------------------------------------------------------
-- Event setup
-- ---------------------------------------------------------------------------
local function setup_event(ev)
    current_event = ev
    p_speed       = 0
    p_mash_power  = 0
    p_vy          = 0
    p_airborne    = false
    p_last_key    = ""
    distance      = 0
    best_distance = 0
    angle         = 0
    angle_set     = false
    throw_released = false
    event_timer   = 0
    attempt       = 1
    hurdle_penalty = 0
    hurdles_cleared = 0
    wind_speed    = rand_range(-3, 3)

    if ev == EVENT.SPRINT_100 or ev == EVENT.HURDLES_110 then
        px = TRACK_LEFT
        py = TRACK_Y - RUNNER_H
        init_ai()
    elseif ev == EVENT.LONG_JUMP then
        px = TRACK_LEFT
        py = TRACK_Y - RUNNER_H
    elseif ev == EVENT.JAVELIN then
        px = TRACK_LEFT
        py = TRACK_Y - RUNNER_H
    elseif ev == EVENT.HIGH_JUMP then
        hj_bar_height = 1.50
        hj_failures   = 0
        hj_cleared    = false
        hj_jumping    = false
        hj_approach_x = TRACK_LEFT
        px = TRACK_LEFT
        py = TRACK_Y - RUNNER_H
    end

    -- Hurdle positions
    if ev == EVENT.HURDLES_110 then
        hurdles = {}
        local spacing = (TRACK_RIGHT - TRACK_LEFT - 80) / 10
        for i = 1, 10 do
            hurdles[i] = {
                x = TRACK_LEFT + 40 + (i - 1) * spacing,
                cleared = false,
                hit = false,
            }
        end
    end

    intro_timer   = 2.5
    current_state = STATE.EVENT_INTRO
end

-- ---------------------------------------------------------------------------
-- Attempt reset (for multi-attempt events)
-- ---------------------------------------------------------------------------
local function reset_attempt()
    px         = TRACK_LEFT
    py         = TRACK_Y - RUNNER_H
    p_speed    = 0
    p_mash_power = 0
    p_vy       = 0
    p_airborne = false
    p_last_key = ""
    distance   = 0
    angle      = 0
    angle_set  = false
    throw_released = false
    event_timer = 0
    wind_speed  = rand_range(-3, 3)

    if current_event == EVENT.HIGH_JUMP then
        hj_jumping  = false
        hj_cleared  = false
        hj_approach_x = TRACK_LEFT
        px = TRACK_LEFT
        py = TRACK_Y - RUNNER_H
    end
end

-- ---------------------------------------------------------------------------
-- Finish event — calculate rank and medals
-- ---------------------------------------------------------------------------
local function finish_event()
    local result = { player_score = 0, player_rank = 4, medal = nil, bonus = false }

    if current_event == EVENT.SPRINT_100 or current_event == EVENT.HURDLES_110 then
        -- Time-based (lower is better)
        local p_time = event_timer + hurdle_penalty
        local times = { { time = p_time, who = "player" } }
        for i, ai in ipairs(ai_runners) do
            times[#times + 1] = { time = ai.time > 0 and ai.time or 999, who = "ai" .. i }
        end
        table.sort(times, function(a, b) return a.time < b.time end)
        for rank, entry in ipairs(times) do
            if entry.who == "player" then
                result.player_rank  = rank
                result.player_score = math.max(0, 100 - math.floor(p_time * 5))
                break
            end
        end
        local qi = current_event == EVENT.SPRINT_100 and 1 or 5
        if p_time <= QUALIFY[qi] then result.bonus = true end

    elseif current_event == EVENT.LONG_JUMP then
        local ai_dists = { rand_range(5.5, 7.5), rand_range(5.0, 7.0), rand_range(4.5, 6.5) }
        local all = { { dist = best_distance, who = "player" } }
        for i, d in ipairs(ai_dists) do
            all[#all + 1] = { dist = d, who = "ai" .. i }
        end
        table.sort(all, function(a, b) return a.dist > b.dist end)
        for rank, entry in ipairs(all) do
            if entry.who == "player" then
                result.player_rank  = rank
                result.player_score = math.floor(best_distance * 10)
                break
            end
        end
        if best_distance >= QUALIFY[2] then result.bonus = true end

    elseif current_event == EVENT.JAVELIN then
        local ai_dists = { rand_range(55, 75), rand_range(50, 70), rand_range(45, 65) }
        local all = { { dist = best_distance, who = "player" } }
        for i, d in ipairs(ai_dists) do
            all[#all + 1] = { dist = d, who = "ai" .. i }
        end
        table.sort(all, function(a, b) return a.dist > b.dist end)
        for rank, entry in ipairs(all) do
            if entry.who == "player" then
                result.player_rank  = rank
                result.player_score = math.floor(best_distance)
                break
            end
        end
        if best_distance >= QUALIFY[3] then result.bonus = true end

    elseif current_event == EVENT.HIGH_JUMP then
        local ai_heights = { rand_range(1.8, 2.2), rand_range(1.7, 2.1), rand_range(1.6, 2.0) }
        local p_height = hj_bar_height - 0.05  -- last cleared height
        local all = { { h = p_height, who = "player" } }
        for i, h in ipairs(ai_heights) do
            all[#all + 1] = { h = h, who = "ai" .. i }
        end
        table.sort(all, function(a, b) return a.h > b.h end)
        for rank, entry in ipairs(all) do
            if entry.who == "player" then
                result.player_rank  = rank
                result.player_score = math.floor(p_height * 50)
                break
            end
        end
        if p_height >= QUALIFY[4] then result.bonus = true end
    end

    local m = medal_for_rank(result.player_rank)
    result.medal = m
    if m then medals[m] = medals[m] + 1 end

    local pts = result.player_score
    if result.bonus then pts = pts + 25 end
    total_points = total_points + pts
    result.player_score = pts

    event_results[current_event] = result

    -- Confetti for gold
    if m == "gold" then
        ps_confetti:setPosition(SCREEN_W * 0.5, 100)
        ps_confetti:emit(80)
    end

    -- Tween medal reveal
    tw_medal_alpha.value = 0
    lurek.tween.to(tw_medal_alpha, 0.6, { value = 1 })

    -- Stamina cost
    p_stamina = clamp(p_stamina - 15, 10, p_max_stamina)

    result_timer  = 3.5
    current_state = STATE.EVENT_RESULT
end

-- ---------------------------------------------------------------------------
-- Mash processing
-- ---------------------------------------------------------------------------
local function process_mash(dt)
    local pressed_a = lurek.input.isPressed("run_left")
    local pressed_d = lurek.input.isPressed("run_right")

    if pressed_a and p_last_key ~= "a" then
        p_mash_power = clamp(p_mash_power + 12 * (p_stamina / p_max_stamina), 0, 100)
        p_last_key = "a"
        ps_dust:setPosition(px, TRACK_Y)
        ps_dust:emit(3)
    elseif pressed_d and p_last_key ~= "d" then
        p_mash_power = clamp(p_mash_power + 12 * (p_stamina / p_max_stamina), 0, 100)
        p_last_key = "d"
        ps_dust:setPosition(px, TRACK_Y)
        ps_dust:emit(3)
    end

    p_mash_power = clamp(p_mash_power - MASH_DECAY * dt * 20, 0, 100)
    p_speed = (p_mash_power / 100) * MAX_SPEED

    -- Tween speed meter
    tw_speed_meter.value = lerp(tw_speed_meter.value, p_speed, dt * 8)
end

-- ---------------------------------------------------------------------------
-- Update: 100m Sprint
-- ---------------------------------------------------------------------------
local function update_sprint(dt)
    process_mash(dt)
    px = px + p_speed * dt
    event_timer = event_timer + dt

    -- AI
    for _, ai in ipairs(ai_runners) do
        if not ai.finished then
            ai.reaction = ai.reaction - dt
            if ai.reaction <= 0 then
                ai.speed = lerp(ai.speed, ai.target_speed + rand_range(-20, 20), dt * 2)
                ai.x = ai.x + ai.speed * dt
            end
            if ai.x >= TRACK_RIGHT - TRACK_LEFT then
                ai.finished = true
                ai.time = event_timer
            end
        end
    end

    -- Player finish
    if px >= TRACK_RIGHT - RUNNER_W then
        px = TRACK_RIGHT - RUNNER_W
        finish_event()
    end

    -- Time limit
    if event_timer >= 15 then
        finish_event()
    end
end

-- ---------------------------------------------------------------------------
-- Update: Long Jump
-- ---------------------------------------------------------------------------
local BOARD_X = TRACK_LEFT + 400

local function update_long_jump(dt)
    if not p_airborne then
        process_mash(dt)
        px = px + p_speed * dt

        if lurek.input.isPressed("action") and px >= BOARD_X - 20 and px <= BOARD_X + 20 then
            -- Jump
            p_airborne = true
            local angle_factor = 0.7 + 0.3 * (clamp(px - BOARD_X + 20, 0, 40) / 40)
            p_vy = -(p_speed * angle_factor * 0.8)
            ps_dust:setPosition(px, TRACK_Y)
            ps_dust:emit(15)
        end

        -- Foul if past board
        if px > BOARD_X + 20 and not p_airborne then
            distance = -1  -- foul
            p_airborne = false
            if attempt < max_attempts then
                attempt = attempt + 1
                reset_attempt()
            else
                finish_event()
            end
        end
    else
        -- Airborne
        px = px + p_speed * 0.5 * dt
        p_vy = p_vy + GRAVITY * dt
        py = py + p_vy * dt

        if py >= TRACK_Y - RUNNER_H then
            py = TRACK_Y - RUNNER_H
            p_airborne = false
            distance = (px - BOARD_X) / 60  -- convert pixels to meters
            if distance > best_distance then best_distance = distance end

            ps_impact:setPosition(px, TRACK_Y)
            ps_impact:emit(20)

            -- Tween distance counter
            lurek.tween.to(tw_distance, 0.5, { value = best_distance })

            if attempt < max_attempts then
                attempt = attempt + 1
                reset_attempt()
            else
                finish_event()
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Update: Javelin
-- ---------------------------------------------------------------------------
local function update_javelin(dt)
    if throw_released then
        -- Javelin in flight
        event_timer = event_timer + dt
        local rad = math.rad(angle)
        local vx = p_speed * math.cos(rad) + wind_speed * 5
        local vy = -p_speed * math.sin(rad) + GRAVITY * event_timer
        px = px + vx * dt
        py = py + vy * dt

        -- Trail particles
        ps_trail:setPosition(px, py)
        ps_trail:emit(2)

        -- Landing
        if py >= TRACK_Y - RUNNER_H then
            py = TRACK_Y - RUNNER_H
            throw_released = false
            distance = (p_speed * math.sin(2 * rad) / GRAVITY) * 100 + wind_speed * 2
            distance = math.max(0, distance)
            if distance > best_distance then best_distance = distance end

            ps_impact:setPosition(px, TRACK_Y)
            ps_impact:emit(15)

            lurek.tween.to(tw_distance, 0.5, { value = best_distance })

            if attempt < max_attempts then
                attempt = attempt + 1
                reset_attempt()
            else
                finish_event()
            end
        end
    elseif angle_set then
        -- Waiting for throw release
        if lurek.input.isPressed("action") then
            throw_released = true
            event_timer = 0
            p_vy = -p_speed * math.sin(math.rad(angle))
        end
    else
        -- Running approach
        process_mash(dt)
        px = px + p_speed * dt

        if lurek.input.isPressed("action") and p_speed > 30 then
            angle_set = true
            angle = 0
        end

        -- Angle sweep while holding
        if angle_set then
            angle = angle + 90 * dt
            if angle > 45 then angle = 45 end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Update: High Jump
-- ---------------------------------------------------------------------------
local BAR_X = 400
local BAR_PIXEL_SCALE = 150  -- pixels per meter for bar height

local function update_high_jump(dt)
    if hj_jumping then
        p_vy = p_vy + GRAVITY * dt
        py = py + p_vy * dt

        -- Check bar clearance at peak
        local bar_pixel_y = TRACK_Y - hj_bar_height * BAR_PIXEL_SCALE
        local player_top = py

        if py >= TRACK_Y - RUNNER_H then
            -- Landed
            py = TRACK_Y - RUNNER_H
            hj_jumping = false

            -- Did we clear? Check if we were above bar at BAR_X
            if player_top < bar_pixel_y then
                hj_cleared = true
                hj_bar_height = hj_bar_height + 0.05
                hj_failures = 0
                ps_confetti:setPosition(BAR_X, bar_pixel_y)
                ps_confetti:emit(30)
                reset_attempt()
            else
                hj_failures = hj_failures + 1
                ps_impact:setPosition(BAR_X, bar_pixel_y)
                ps_impact:emit(10)
                if hj_failures >= 3 then
                    finish_event()
                else
                    reset_attempt()
                end
            end
        end
    else
        -- Approach
        process_mash(dt)
        px = px + p_speed * dt

        if lurek.input.isPressed("action") and math.abs(px - BAR_X) < 60 then
            hj_jumping = true
            local jump_power = clamp(p_speed / MAX_SPEED, 0.3, 1.0)
            p_vy = -(450 * jump_power)
            ps_dust:setPosition(px, TRACK_Y)
            ps_dust:emit(12)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Update: 110m Hurdles
-- ---------------------------------------------------------------------------
local HURDLE_H = 30

local function update_hurdles(dt)
    process_mash(dt)
    px = px + p_speed * dt
    event_timer = event_timer + dt

    -- Jump
    if lurek.input.isPressed("action") and not p_airborne then
        p_airborne = true
        p_vy = -350
        ps_dust:setPosition(px, TRACK_Y)
        ps_dust:emit(8)
    end

    if p_airborne then
        p_vy = p_vy + GRAVITY * dt
        py = py + p_vy * dt
        if py >= TRACK_Y - RUNNER_H then
            py = TRACK_Y - RUNNER_H
            p_airborne = false
            p_vy = 0
        end
    end

    -- Check hurdle collisions
    for _, h in ipairs(hurdles) do
        if not h.cleared and not h.hit then
            if math.abs(px + RUNNER_W * 0.5 - h.x) < 15 then
                if py + RUNNER_H > TRACK_Y - HURDLE_H then
                    -- Hit hurdle
                    h.hit = true
                    hurdle_penalty = hurdle_penalty + 0.5
                    p_speed = p_speed * 0.7
                else
                    -- Cleared
                    h.cleared = true
                    hurdles_cleared = hurdles_cleared + 1
                end
            end
        end
    end

    -- AI runners
    for _, ai in ipairs(ai_runners) do
        if not ai.finished then
            ai.reaction = ai.reaction - dt
            if ai.reaction <= 0 then
                ai.speed = lerp(ai.speed, ai.target_speed + rand_range(-15, 15), dt * 2)
                ai.x = ai.x + ai.speed * dt
            end
            if ai.x >= TRACK_RIGHT - TRACK_LEFT then
                ai.finished = true
                ai.time = event_timer
            end
        end
    end

    -- Player finish
    if px >= TRACK_RIGHT - RUNNER_W then
        px = TRACK_RIGHT - RUNNER_W
        finish_event()
    end

    if event_timer >= 20 then
        finish_event()
    end
end

-- ---------------------------------------------------------------------------
-- lurek.init
-- ---------------------------------------------------------------------------
lurek.init(function()
    lurek.render.setBackgroundColor(0.6, 0.3, 0.2)
    lurek.window.setTitle("Track & Field — Lurek2D")
    camera = lurek.camera.new()
    init_particles()
end)

-- ---------------------------------------------------------------------------
-- lurek.ready
-- ---------------------------------------------------------------------------
lurek.ready(function()
    current_state = STATE.TITLE
end)

-- ---------------------------------------------------------------------------
-- lurek.process
-- ---------------------------------------------------------------------------
lurek.process(function(dt)
    -- Quit
    if lurek.input.isPressed("quit") then
        lurek.event.signal("quit")
        return
    end

    -- Update particles
    ps_dust:update(dt)
    ps_impact:update(dt)
    ps_trail:update(dt)
    ps_confetti:update(dt)

    -- Title
    if current_state == STATE.TITLE then
        if lurek.input.isPressed("action") then
            p_stamina = p_max_stamina
            medals = { gold = 0, silver = 0, bronze = 0 }
            total_points = 0
            event_results = {}
            setup_event(EVENT.SPRINT_100)
        end
        return
    end

    -- Event intro countdown
    if current_state == STATE.EVENT_INTRO then
        intro_timer = intro_timer - dt
        if intro_timer <= 0 then
            if current_event == EVENT.SPRINT_100 then
                current_state = STATE.RUNNING
            elseif current_event == EVENT.LONG_JUMP then
                current_state = STATE.JUMPING
            elseif current_event == EVENT.JAVELIN then
                current_state = STATE.THROWING
            elseif current_event == EVENT.HIGH_JUMP then
                current_state = STATE.JUMPING
            elseif current_event == EVENT.HURDLES_110 then
                current_state = STATE.RUNNING
            end
        end
        return
    end

    -- Event result display
    if current_state == STATE.EVENT_RESULT then
        result_timer = result_timer - dt
        if result_timer <= 0 then
            -- Stamina recovery between events
            p_stamina = clamp(p_stamina + 10, 10, p_max_stamina)

            if current_event < NUM_EVENTS then
                setup_event(current_event + 1)
            else
                current_state = STATE.FINAL
            end
        end
        return
    end

    -- Final screen
    if current_state == STATE.FINAL then
        if lurek.input.isPressed("action") then
            current_state = STATE.TITLE
        end
        return
    end

    -- Active gameplay
    if current_event == EVENT.SPRINT_100 then
        update_sprint(dt)
    elseif current_event == EVENT.LONG_JUMP then
        update_long_jump(dt)
    elseif current_event == EVENT.JAVELIN then
        update_javelin(dt)
    elseif current_event == EVENT.HIGH_JUMP then
        update_high_jump(dt)
    elseif current_event == EVENT.HURDLES_110 then
        update_hurdles(dt)
    end

    -- Camera follow
    if camera then
        local target_x = clamp(px - SCREEN_W * 0.35, 0, math.max(0, TRACK_RIGHT - SCREEN_W + 100))
        local cx = lerp(camera:getX(), target_x, dt * 4)
        camera:setPosition(cx, 0)
    end

    -- FPS in title
    lurek.window.setTitle(string.format("Track & Field — %d FPS", lurek.timer.getFPS()))
end)

-- ---------------------------------------------------------------------------
-- Render helpers
-- ---------------------------------------------------------------------------
local function draw_track()
    -- Grass
    lurek.render.setColor(COL_GRASS[1], COL_GRASS[2], COL_GRASS[3])
    lurek.render.rectangle("fill", 0, TRACK_Y + 30, SCREEN_W + 200, SCREEN_H - TRACK_Y)

    -- Track surface
    lurek.render.setColor(COL_TRACK[1], COL_TRACK[2], COL_TRACK[3])
    lurek.render.rectangle("fill", TRACK_LEFT - 20, TRACK_Y - 10, TRACK_RIGHT - TRACK_LEFT + 40, 40)

    -- Lane lines
    lurek.render.setColor(COL_LINE[1], COL_LINE[2], COL_LINE[3], 0.4)
    for i = 0, 4 do
        local ly = TRACK_Y - 10 + i * 8
        lurek.render.line(TRACK_LEFT - 20, ly, TRACK_RIGHT + 20, ly)
    end

    -- Start / finish lines
    lurek.render.setColor(COL_LINE[1], COL_LINE[2], COL_LINE[3])
    lurek.render.rectangle("fill", TRACK_LEFT - 5, TRACK_Y - 15, 4, 50)
    lurek.render.rectangle("fill", TRACK_RIGHT - 5, TRACK_Y - 15, 4, 50)
end

local function draw_runner(x, y, color, w, h)
    w = w or RUNNER_W
    h = h or RUNNER_H
    -- Body
    lurek.render.setColor(color[1], color[2], color[3])
    lurek.render.rectangle("fill", x, y, w, h)
    -- Head
    lurek.render.circle("fill", x + w * 0.5, y - 6, 6)
end

local function draw_hurdles()
    for _, h in ipairs(hurdles) do
        if h.hit then
            lurek.render.setColor(0.5, 0.3, 0.2, 0.5)
        else
            lurek.render.setColor(COL_HURDLE[1], COL_HURDLE[2], COL_HURDLE[3])
        end
        lurek.render.rectangle("fill", h.x - 3, TRACK_Y - HURDLE_H, 6, HURDLE_H)
        lurek.render.rectangle("fill", h.x - 10, TRACK_Y - HURDLE_H, 20, 3)
    end
end

-- ---------------------------------------------------------------------------
-- lurek.render
-- ---------------------------------------------------------------------------
lurek.render(function()
    if current_state == STATE.TITLE or current_state == STATE.FINAL then
        return
    end

    if camera then camera:attach() end

    draw_track()

    -- Event-specific field elements
    if current_event == EVENT.LONG_JUMP then
        -- Board
        lurek.render.setColor(1, 1, 1)
        lurek.render.rectangle("fill", BOARD_X - 5, TRACK_Y - 5, 10, 15)
        -- Sand pit
        lurek.render.setColor(0.9, 0.85, 0.6)
        lurek.render.rectangle("fill", BOARD_X + 30, TRACK_Y - 3, 200, 15)
    end

    if current_event == EVENT.HIGH_JUMP then
        -- Bar
        local bar_py = TRACK_Y - hj_bar_height * BAR_PIXEL_SCALE
        lurek.render.setColor(COL_BAR[1], COL_BAR[2], COL_BAR[3])
        lurek.render.line(BAR_X - 40, bar_py, BAR_X + 40, bar_py)
        -- Uprights
        lurek.render.setColor(0.5, 0.5, 0.5)
        lurek.render.rectangle("fill", BAR_X - 42, bar_py, 4, TRACK_Y - bar_py)
        lurek.render.rectangle("fill", BAR_X + 38, bar_py, 4, TRACK_Y - bar_py)
        -- Mat
        lurek.render.setColor(0.3, 0.3, 0.8, 0.5)
        lurek.render.rectangle("fill", BAR_X - 50, TRACK_Y - 10, 100, 20)
    end

    if current_event == EVENT.HURDLES_110 then
        draw_hurdles()
    end

    -- AI runners
    for _, ai in ipairs(ai_runners) do
        local ay = ai.lane_y or (TRACK_Y - RUNNER_H)
        if current_event == EVENT.HURDLES_110 then
            ay = TRACK_Y - RUNNER_H + (ai.hurdle_y or 0)
        end
        draw_runner(TRACK_LEFT + ai.x, ay, ai.color, 18, 36)
    end

    -- Player
    draw_runner(px, py, COL_PLAYER)

    -- Particles
    lurek.render.setColor(1, 1, 1)
    lurek.particle.draw(ps_dust)
    lurek.particle.draw(ps_impact)
    lurek.particle.draw(ps_trail)
    lurek.particle.draw(ps_confetti)

    if camera then camera:detach() end
end)

-- ---------------------------------------------------------------------------
-- lurek.render_ui
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    -- Title screen
    if current_state == STATE.TITLE then
        lurek.render.setColor(COL_DARK[1], COL_DARK[2], COL_DARK[3])
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        lurek.render.print("TRACK & FIELD", SCREEN_W * 0.5 - 100, 160, 0, 2.5, 2.5)

        lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        lurek.render.print("GO FOR GOLD", SCREEN_W * 0.5 - 60, 230, 0, 1.5, 1.5)

        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Mash A/D to run — Space for actions", SCREEN_W * 0.5 - 140, 310)
        lurek.render.print("Press SPACE to start", SCREEN_W * 0.5 - 80, 400)
        return
    end

    -- Final results
    if current_state == STATE.FINAL then
        lurek.render.setColor(COL_DARK[1], COL_DARK[2], COL_DARK[3])
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        lurek.render.print("FINAL RESULTS", SCREEN_W * 0.5 - 90, 40, 0, 2, 2)

        local y = 110
        for i = 1, NUM_EVENTS do
            local r = event_results[i]
            local mc = COL_WHITE
            local medal_str = "---"
            if r and r.medal then
                mc = medal_color(r.medal)
                medal_str = string.upper(r.medal)
            end
            lurek.render.setColor(mc[1], mc[2], mc[3])
            lurek.render.print(string.format("%-18s  %s  %4d pts", EVENT_NAMES[i], medal_str, r and r.player_score or 0), 120, y)
            y = y + 30
        end

        y = y + 20
        lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        lurek.render.print(string.format("Gold: %d", medals.gold), 180, y)
        lurek.render.setColor(COL_SILVER[1], COL_SILVER[2], COL_SILVER[3])
        lurek.render.print(string.format("Silver: %d", medals.silver), 320, y)
        lurek.render.setColor(COL_BRONZE[1], COL_BRONZE[2], COL_BRONZE[3])
        lurek.render.print(string.format("Bronze: %d", medals.bronze), 470, y)

        y = y + 40
        lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        lurek.render.print(string.format("Total Points: %d", total_points), 260, y, 0, 1.5, 1.5)

        lurek.render.setColor(0.5, 0.5, 0.5)
        lurek.render.print("Press SPACE to return to title", SCREEN_W * 0.5 - 120, SCREEN_H - 60)
        return
    end

    -- Event intro overlay
    if current_state == STATE.EVENT_INTRO then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        lurek.render.print(string.format("Event %d / %d", current_event, NUM_EVENTS), SCREEN_W * 0.5 - 60, 200, 0, 1.5, 1.5)
        lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        lurek.render.print(EVENT_NAMES[current_event], SCREEN_W * 0.5 - 80, 250, 0, 2, 2)

        local countdown = math.ceil(intro_timer)
        lurek.render.setColor(1, 1, 1)
        lurek.render.print(tostring(countdown), SCREEN_W * 0.5 - 10, 320, 0, 3, 3)
        return
    end

    -- Event result overlay
    if current_state == STATE.EVENT_RESULT then
        lurek.render.setColor(0, 0, 0, 0.5)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        local r = event_results[current_event]
        lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        lurek.render.print(EVENT_NAMES[current_event] .. " — Results", SCREEN_W * 0.5 - 100, 150, 0, 1.5, 1.5)

        if r and r.medal then
            local mc = medal_color(r.medal)
            local a = tw_medal_alpha.value
            lurek.render.setColor(mc[1], mc[2], mc[3], a)
            lurek.render.print(string.upper(r.medal) .. " MEDAL!", SCREEN_W * 0.5 - 70, 210, 0, 2, 2)
        else
            lurek.render.setColor(0.5, 0.5, 0.5)
            lurek.render.print("No medal", SCREEN_W * 0.5 - 40, 210, 0, 1.5, 1.5)
        end

        lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        lurek.render.print(string.format("Points: %d", r and r.player_score or 0), SCREEN_W * 0.5 - 50, 270)
        if r and r.bonus then
            lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
            lurek.render.print("Qualifying standard met! +25 bonus", SCREEN_W * 0.5 - 120, 300)
        end
        return
    end

    -- HUD panel
    lurek.render.setColor(COL_HUD_BG[1], COL_HUD_BG[2], COL_HUD_BG[3], COL_HUD_BG[4])
    lurek.render.rectangle("fill", 0, 0, SCREEN_W, 50)

    -- Event name
    lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
    lurek.render.print(EVENT_NAMES[current_event], 10, 8, 0, 1.2, 1.2)

    -- Speed meter
    lurek.render.setColor(0.3, 0.3, 0.3)
    lurek.render.rectangle("fill", 200, 10, 120, 14)
    local speed_pct = tw_speed_meter.value / MAX_SPEED
    local sr = lerp(0.2, 1.0, speed_pct)
    local sg = lerp(0.8, 0.2, speed_pct)
    lurek.render.setColor(sr, sg, 0.2)
    lurek.render.rectangle("fill", 200, 10, 120 * speed_pct, 14)
    lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
    lurek.render.print("Speed", 200, 26)

    -- Stamina
    lurek.render.setColor(0.3, 0.3, 0.3)
    lurek.render.rectangle("fill", 200, 32, 120, 8)
    lurek.render.setColor(0.2, 0.7, 0.9)
    lurek.render.rectangle("fill", 200, 32, 120 * (p_stamina / p_max_stamina), 8)

    -- Event-specific info
    local info_x = 350
    lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])

    if current_event == EVENT.SPRINT_100 or current_event == EVENT.HURDLES_110 then
        lurek.render.print(string.format("Time: %.2fs", event_timer + hurdle_penalty), info_x, 10)
        if current_event == EVENT.HURDLES_110 then
            lurek.render.print(string.format("Penalty: %.1fs  Cleared: %d/10", hurdle_penalty, hurdles_cleared), info_x, 28)
        end
    elseif current_event == EVENT.LONG_JUMP then
        lurek.render.print(string.format("Attempt: %d/%d  Best: %.2fm", attempt, max_attempts, tw_distance.value), info_x, 10)
        if distance == -1 then
            lurek.render.setColor(0.9, 0.2, 0.2)
            lurek.render.print("FOUL!", info_x + 250, 10)
        end
    elseif current_event == EVENT.JAVELIN then
        lurek.render.print(string.format("Attempt: %d/%d  Best: %.1fm", attempt, max_attempts, tw_distance.value), info_x, 10)
        if angle_set then
            lurek.render.print(string.format("Angle: %.0f°", angle), info_x, 28)
        end
        lurek.render.setColor(0.7, 0.7, 0.9)
        lurek.render.print(string.format("Wind: %+.1f m/s", wind_speed), info_x + 200, 10)
    elseif current_event == EVENT.HIGH_JUMP then
        lurek.render.print(string.format("Bar: %.2fm  Fails: %d/3", hj_bar_height, hj_failures), info_x, 10)
    end

    -- Medal tally (top right)
    local mx = SCREEN_W - 180
    lurek.render.setColor(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
    lurek.render.print(string.format("G:%d", medals.gold), mx, 10)
    lurek.render.setColor(COL_SILVER[1], COL_SILVER[2], COL_SILVER[3])
    lurek.render.print(string.format("S:%d", medals.silver), mx + 45, 10)
    lurek.render.setColor(COL_BRONZE[1], COL_BRONZE[2], COL_BRONZE[3])
    lurek.render.print(string.format("B:%d", medals.bronze), mx + 90, 10)
    lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
    lurek.render.print(string.format("Pts:%d", total_points), mx + 130, 10)
end)
