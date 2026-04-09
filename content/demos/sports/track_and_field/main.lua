-- Track & Field — Sport Game (Luna2D demo)
-- Alternate A and D (or Left/Right) keys rapidly to run.  
-- Four events: 100m Sprint, Long Jump, Hurdles, and Hammer Throw.
-- Run with: cargo run -- demos/sports/track_and_field

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local EVENTS = { "100m Sprint", "Long Jump", "Hurdles", "Hammer Throw" }
local HURDLE_SPACING = 90
local HURDLE_COUNT   = 10

-- ── State ─────────────────────────────────────────────────────────────────

local player    = {}
local event_idx = 1
local game_state = "ready"   -- ready / running / airborne / throwing / result
local event_time = 0
local run_timer = 0
local speed = 0
local power = 0
local power_dir = 1    -- for hammer throw oscillation
local angle = 0        -- throwing angle
local dist = 0         -- long jump / hammer
local result = 0
local best = {}
local anim = 0
local step_timer = 0
local last_key = ""
local hurdles = {}
local hurdle_cleared = 0
local athlete_x = 0
local athlete_y = 0
local jump_vy = 0
local jump_x  = 0
local hammer_spin = 0

local function reset_event()
    speed = 0; power = 0; dist = 0; result = 0
    angle = 0; step_timer = 0; last_key = ""; anim = 0
    athlete_x = 80; athlete_y = H - 100
    jump_vy = 0; jump_x = athlete_x; hurdle_cleared = 0
    hammer_spin = 0; power_dir = 1; run_timer = 0; event_time = 0

    if event_idx == 3 then  -- Hurdles
        hurdles = {}
        for i = 1, HURDLE_COUNT do
            hurdles[i] = { x = 200 + i * HURDLE_SPACING, cleared = false }
        end
    end
    game_state = "ready"
end

local function init()
    best = {}
    for i, _ in ipairs(EVENTS) do best[i] = 0 end
    event_idx = 1
    reset_event()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0.4, 0.7, 1)
    init()
end

-- ── Running sub-system ────────────────────────────────────────────────────

-- Alternating A/D increases speed, same key twice slows
local function press_run(key)
    if key == "a" or key == "left" then
        if last_key == "a" or last_key == "left" then
            speed = math.max(0, speed - 0.8)
        else
            speed = math.min(10, speed + 1.5)
        end
        last_key = "a"
    elseif key == "d" or key == "right" then
        if last_key == "d" or last_key == "right" then
            speed = math.max(0, speed - 0.8)
        else
            speed = math.min(10, speed + 1.5)
        end
        last_key = "d"
    end
end

-- ── Update ────────────────────────────────────────────────────────────────

function luna.process(dt)
    anim = anim + dt

    if game_state == "ready" then return end

    if game_state == "result" then
        event_time = event_time + dt
        if event_time > 4 then
            event_idx = event_idx + 1
            if event_idx > #EVENTS then
                game_state = "gameover"
            else
                reset_event()
            end
        end
        return
    end

    local ev = event_idx

    -- ── 100m Sprint (event 1) ─────────────────────────────────────────────
    if ev == 1 then
        run_timer = run_timer + dt
        speed = math.max(0, speed - dt * 0.5)  -- natural deceleration
        athlete_x = athlete_x + speed * 40 * dt
        if athlete_x >= 720 then
            result = math.floor(run_timer * 100) / 100
            if best[1] == 0 or result < best[1] then best[1] = result end
            game_state = "result"; event_time = 0
        end

    -- ── Long Jump (event 2) ──────────────────────────────────────────────
    elseif ev == 2 then
        if game_state == "running" then
            run_timer = run_timer + dt
            speed = math.max(0, speed - dt * 0.3)
            athlete_x = athlete_x + speed * 40 * dt

            -- Reach take-off board (x=420)
            if athlete_x >= 420 then
                game_state = "airborne"
                jump_x = 420
                jump_vy = -speed * 22 - 80  -- launch vy
                athlete_y = H - 100
            end
        elseif game_state == "airborne" then
            jump_vy = jump_vy + 380 * dt  -- gravity
            athlete_y = athlete_y + jump_vy * dt
            athlete_x = athlete_x + speed * 30 * dt
            if athlete_y >= H - 85 then  -- land
                athlete_y = H - 85
                result = math.floor((athlete_x - 420) / 5 * 10) / 10  -- metres
                if result > best[2] then best[2] = result end
                game_state = "result"; event_time = 0
            end
        end

    -- ── Hurdles (event 3) ────────────────────────────────────────────────
    elseif ev == 3 then
        run_timer = run_timer + dt
        speed = math.max(0, speed - dt * 0.4)
        athlete_x = athlete_x + speed * 40 * dt

        -- Jump state
        if game_state == "airborne" then
            jump_vy = jump_vy + 480 * dt
            athlete_y = athlete_y + jump_vy * dt
            if athlete_y >= H - 100 then
                athlete_y = H - 100; game_state = "running"
            end
        end

        -- Check hurdles
        for _, hrd in ipairs(hurdles) do
            if not hrd.cleared and math.abs(athlete_x - hrd.x) < 15 then
                if athlete_y < H - 130 then  -- cleared
                    hrd.cleared = true; hurdle_cleared = hurdle_cleared + 1
                elseif game_state ~= "airborne" then
                    -- Hit hurdle — big speed penalty
                    speed = math.max(0, speed - 3)
                end
            end
        end

        if athlete_x >= 100 + HURDLE_COUNT * HURDLE_SPACING + 120 then
            result = math.floor(run_timer * 100) / 100
            if best[3] == 0 or result < best[3] then best[3] = result end
            game_state = "result"; event_time = 0
        end

    -- ── Hammer Throw (event 4) ────────────────────────────────────────────
    elseif ev == 4 then
        power = power + power_dir * dt * 85
        if power >= 100 then power = 100; power_dir = -1 end
        if power <= 0   then power = 0;   power_dir = 1 end
        hammer_spin = hammer_spin + dt * 4

        if game_state == "throwing" then
            -- Projectile released
            local vx = angle * 320
            local vy = -(1 - angle) * 320 - 100
            -- Simple distance calc from launch angle
            result = math.floor((power / 100) * 65 + angle * 15)
            if result > best[4] then best[4] = result end
            game_state = "result"; event_time = 0
        end
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────

local function draw_athlete(x, y, running)
    local leg_off = running and math.sin(anim * 12) * 8 or 0
    -- Body
    luna.gfx.setColor(0.9, 0.6, 0.3)
    luna.gfx.rectangle("fill", x - 6, y - 30, 12, 18)
    -- Head
    luna.gfx.circle("fill", x, y - 36, 7)
    -- Legs
    luna.gfx.setColor(0.2, 0.3, 0.8)
    luna.gfx.rectangle("fill", x - 5, y - 12, 5, 18 + leg_off)
    luna.gfx.rectangle("fill", x,     y - 12, 5, 18 - leg_off)
    -- Arms
    luna.gfx.setColor(0.9, 0.6, 0.3)
    luna.gfx.line(x - 6, y - 26, x - 14, y - 20 + leg_off/2)
    luna.gfx.line(x + 6, y - 26, x + 14, y - 20 - leg_off/2)
end

function luna.render()
    -- Sky
    luna.gfx.setColor(0.4, 0.7, 1)
    luna.gfx.rectangle("fill", 0, 0, W, H)
    -- Crowd stands
    luna.gfx.setColor(0.6, 0.3, 0.1)
    luna.gfx.rectangle("fill", 0, 0, W, 60)
    for i = 0, 15 do
        local cx = 24 + i * 50
        luna.gfx.setColor(0.2 + (i % 3)*0.2, 0.1, 0.4 + (i % 2)*0.2)
        luna.gfx.circle("fill", cx, 35 + (i % 3) * 7, 10)
    end
    -- Ground / track
    luna.gfx.setColor(0.85, 0.65, 0.3)
    luna.gfx.rectangle("fill", 0, H - 130, W, 130)
    luna.gfx.setColor(0.8, 0.6, 0.25)
    for i = 0, 3 do
        luna.gfx.rectangle("fill", 0, H - 130 + i * 32, W, 2)
    end

    local ev = event_idx

    -- ── Sprint lane markings ──────────────────────────────────────────────
    if ev == 1 then
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.rectangle("line", 80, H - 120, 640, 20)
        luna.gfx.line(720, H - 130, 720, H)  -- finish line
        draw_athlete(athlete_x, H - 90, game_state == "running" or game_state == "ready")
        luna.gfx.setColor(1, 1, 0.5)
        luna.gfx.print("SPEED: " .. string.format("%.1f", speed), 20, 70, 2.2)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Time: " .. string.format("%.2f", run_timer) .. "s", 20, 96, 1.8)

    -- ── Long Jump ────────────────────────────────────────────────────────
    elseif ev == 2 then
        luna.gfx.setColor(0.85, 0.75, 0.5)
        luna.gfx.rectangle("fill", 420, H - 98, 260, 30)   -- sand pit
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.rectangle("fill", 420, H - 115, 8, 30)    -- take-off board
        draw_athlete(athlete_x, athlete_y, game_state == "running")
        luna.gfx.setColor(1, 1, 0.5)
        luna.gfx.print("SPEED: " .. string.format("%.1f", speed), 20, 70, 2.2)
        if game_state == "result" then
            luna.gfx.setColor(0.2, 1, 0.5)
            luna.gfx.print(string.format("%.1f m", result), 20, 96, 2.5)
        end

    -- ── Hurdles ──────────────────────────────────────────────────────────
    elseif ev == 3 then
        for _, hrd in ipairs(hurdles) do
            if not hrd.cleared then
                luna.gfx.setColor(1, 0.8, 0.1)
                luna.gfx.rectangle("fill", hrd.x - 3, H - 130, 6, 30)
                luna.gfx.rectangle("fill", hrd.x - 15, H - 100, 30, 5)
            end
        end
        lua_ath_y = (game_state == "airborne") and athlete_y or H - 100
        draw_athlete(athlete_x, lua_ath_y, game_state == "running")
        luna.gfx.setColor(1, 1, 0.5)
        luna.gfx.print("SPEED: " .. string.format("%.1f", speed), 20, 70, 2.2)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Time: " .. string.format("%.2f", run_timer) .. "s", 20, 96, 1.8)

    -- ── Hammer Throw ─────────────────────────────────────────────────────
    elseif ev == 4 then
        -- Spinning athlete
        local hr = 90 + math.sin(hammer_spin) * 40
        luna.gfx.setColor(0.9, 0.6, 0.3)
        luna.gfx.circle("fill", W/2, H - 90, 12)
        luna.gfx.setColor(0.3, 0.4, 0.8)
        luna.gfx.circle("fill", W/2, H - 70, 9)
        -- Hammer chain
        local hx = W/2 + math.cos(hammer_spin) * 45
        local hy = H - 80 + math.sin(hammer_spin) * 20
        luna.gfx.setColor(0.7, 0.7, 0.7)
        luna.gfx.line(W/2, H - 80, hx, hy)
        luna.gfx.setColor(0.3, 0.3, 0.3)
        luna.gfx.circle("fill", hx, hy, 10)

        -- Power bar
        luna.gfx.setColor(0.3, 0.3, 0.3)
        luna.gfx.rectangle("fill", W - 60, H - 200, 30, 160)
        local bar_r = power >= 70 and 1 or 0.3
        local bar_g = power <= 30 and 0.6 or (power <= 70 and 1 or 0.2)
        luna.gfx.setColor(bar_r, bar_g, 0.1)
        luna.gfx.rectangle("fill", W - 60, H - 200 + 160 * (1 - power/100), 30, 160 * power/100)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("POWER", W - 70, H - 210, 1.3)
        luna.gfx.print("Release:", W - 110, H/2, 1.5)
        luna.gfx.print("[Space]", W - 100, H/2 + 22, 1.5)

        if game_state == "result" then
            luna.gfx.setColor(0.2, 1, 0.6)
            luna.gfx.print(tostring(result) .. " m", W/2 - 30, 70, 3)
        end
    end

    -- Event header
    luna.gfx.setColor(0, 0, 0, 0.65)
    luna.gfx.rectangle("fill", 0, 0, W, 60)
    luna.gfx.setColor(1, 1, 0.3)
    luna.gfx.print(EVENTS[event_idx], W/2 - 100, 12, 2.5)
    local instr = { "[A] [D] Alternate fast!", "[A/D] Run then [Space] Jump", "[A/D] Run [Space] Leap hurdle", "[A/D] Spin then [Space] Release" }
    luna.gfx.setColor(0.8, 0.9, 1, 0.8)
    luna.gfx.print(instr[event_idx], W/2 - 150, 36, 1.4)

    -- Best scores
    luna.gfx.setColor(0.2, 0.2, 0.2, 0.65)
    luna.gfx.rectangle("fill", 0, H - 26, W, 26)
    for i, nm in ipairs(EVENTS) do
        luna.gfx.setColor(i == event_idx and 0.9 or 0.5, 0.9, 0.5)
        local bstr = best[i] > 0 and (i >= 2 and best[i] .. "m" or best[i] .. "s") or "—"
        luna.gfx.print(nm .. ": " .. bstr, (i-1)*200 + 8, H - 22, 1.3)
    end

    -- Result overlay
    if game_state == "result" then
        luna.gfx.setColor(0, 0, 0, 0.6)
        luna.gfx.rectangle("fill", W/2 - 180, H/2 - 45, 360, 90)
        luna.gfx.setColor(1, 1, 0)
        luna.gfx.print("RESULT", W/2 - 50, H/2 - 40, 2)
        local rstr = (ev == 1 or ev == 3) and (string.format("%.2f", result) .. " s") or (tostring(result) .. " m")
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print(rstr, W/2 - 40, H/2 - 5, 2.5)
    end

    -- Game over
    if game_state == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.8)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.9, 0.2)
        luna.gfx.print("ALL EVENTS COMPLETE!", W/2 - 140, H/2 - 60, 2.5)
        for i, nm in ipairs(EVENTS) do
            luna.gfx.setColor(0.8, 1, 0.8)
            local bstr = best[i] > 0 and (i >= 2 and best[i] .. " m" or best[i] .. " s") or "—"
            luna.gfx.print(nm .. ": " .. bstr, W/2 - 100, H/2 - 10 + i * 28, 1.7)
        end
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to try again", W/2 - 110, H/2 + 130, 2)
    end
end

-- ── Input ─────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.signal.restart() end
    if game_state ~= "ready" and game_state ~= "running" and game_state ~= "airborne" then return end

    if key == "a" or key == "left" or key == "d" or key == "right" then
        if game_state == "ready" then
            game_state = "running"
        end
        press_run(key)
    end

    if key == "space" then
        local ev = event_idx
        if ev == 2 and game_state == "running" and athlete_x >= 380 then
            -- Force take-off
            game_state = "airborne"
            jump_vy = -speed * 22 - 80
        elseif ev == 3 and game_state == "running" then
            game_state = "airborne"
            jump_vy = -300
        elseif ev == 4 then
            -- Throw with current power
            angle = power / 200 + 0.25
            game_state = "throwing"
        end
    end
end
