-- ============================================================================
-- Vehicle Builder — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/vehicle_builder/main.lua
-- Run with : cargo run -- content/games/simulation/vehicle_builder
-- ============================================================================
-- Grid-based vehicle construction and side-scrolling test track.
-- Build mode: place Frame/Wheel/Engine/Armor/Booster on a 20x12 grid.
-- Test mode: watch your vehicle tackle increasingly difficult tracks.
-- Controls: F/W/E/A/B parts, D delete, T test, B build, Space boost, Esc quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local GRID_COLS, GRID_ROWS = 20, 12
local CELL = 32
local GRID_X = 20
local GRID_Y = 80

local STATE = { TITLE = 1, BUILDING = 2, TESTING = 3, RESULTS = 4 }
local current_state = STATE.TITLE

-- Part types
local PART = { FRAME = 1, WHEEL = 2, ENGINE = 3, ARMOR = 4, BOOSTER = 5 }
local PART_NAMES = { "Frame", "Wheel", "Engine", "Armor", "Booster" }
local PART_COST  = { 0, 20, 50, 30, 40 }
local PART_COLOR = {
    { 0.5, 0.5, 0.55 },  -- frame: gray
    { 0.3, 0.3, 0.3  },  -- wheel: dark
    { 0.9, 0.5, 0.1  },  -- engine: orange
    { 0.2, 0.5, 0.8  },  -- armor: blue
    { 0.9, 0.2, 0.2  },  -- booster: red
}

local BUDGET       = 300
local BASE_SPEED   = 100  -- per engine, before weight
local BOOST_MULT   = 2.0
local BOOST_DUR    = 3.0
local TRACK_GROUND = SCREEN_H - 60

-- Track obstacles: {type, x_offset}
local TRACKS = {
    { -- track 1: easy
        length = 3000,
        obstacles = {
            { kind = "ramp",  x = 600,  w = 80,  h = 20 },
            { kind = "gap",   x = 1200, w = 100 },
            { kind = "wall",  x = 2000, w = 30,  h = 50 },
            { kind = "ramp",  x = 2500, w = 80,  h = 25 },
        },
    },
    { -- track 2: medium
        length = 4000,
        obstacles = {
            { kind = "wall",  x = 500,  w = 30,  h = 40 },
            { kind = "gap",   x = 1000, w = 120 },
            { kind = "ramp",  x = 1500, w = 100, h = 30 },
            { kind = "wall",  x = 2200, w = 30,  h = 60 },
            { kind = "gap",   x = 2800, w = 140 },
            { kind = "wall",  x = 3500, w = 40,  h = 55 },
        },
    },
    { -- track 3: hard
        length = 5000,
        obstacles = {
            { kind = "gap",   x = 400,  w = 130 },
            { kind = "wall",  x = 800,  w = 30,  h = 60 },
            { kind = "wall",  x = 1100, w = 30,  h = 45 },
            { kind = "gap",   x = 1600, w = 160 },
            { kind = "ramp",  x = 2100, w = 90,  h = 35 },
            { kind = "wall",  x = 2600, w = 40,  h = 70 },
            { kind = "gap",   x = 3200, w = 180 },
            { kind = "wall",  x = 4000, w = 50,  h = 80 },
        },
    },
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local grid = {}           -- grid[row][col] = part_type or nil
local selected_part = PART.FRAME
local delete_mode   = false
local total_cost    = 0
local title_timer   = 0
local track_index   = 1

-- Vehicle stats (computed from grid)
local stats = { speed = 0, weight = 0, armor = 0, engines = 0, wheels = 0, boosters = 0 }

-- Test state
local test = {
    vx = 0, x = 0, y = 0,
    cam_x = 0,
    speed = 0,
    alive = true,
    armor_hp = 0,
    distance = 0,
    boosting = false,
    boost_timer = 0,
    finished = false,
    score = 0,
    airborne = false,
    vy = 0,
}

-- Particles
local particles = {}

-- Tweens
local tweens = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clear_grid()
    grid = {}
    for r = 1, GRID_ROWS do
        grid[r] = {}
        for c = 1, GRID_COLS do
            grid[r][c] = nil
        end
    end
    total_cost = 0
end

local function has_neighbor(r, c)
    if grid[r - 1] and grid[r - 1][c] then return true end
    if grid[r + 1] and grid[r + 1][c] then return true end
    if grid[r] and grid[r][c - 1]     then return true end
    if grid[r] and grid[r][c + 1]     then return true end
    return false
end

local function count_parts()
    local n = 0
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            if grid[r][c] then n = n + 1 end
        end
    end
    return n
end

local function compute_stats()
    stats.speed   = 0
    stats.weight  = 0
    stats.armor   = 0
    stats.engines = 0
    stats.wheels  = 0
    stats.boosters = 0
    total_cost = 0
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local p = grid[r][c]
            if p then
                total_cost = total_cost + PART_COST[p]
                stats.weight = stats.weight + 1
                if p == PART.WHEEL   then stats.wheels   = stats.wheels + 1 end
                if p == PART.ENGINE  then stats.engines  = stats.engines + 1 end
                if p == PART.ARMOR   then stats.armor    = stats.armor + 1 end
                if p == PART.BOOSTER then stats.boosters = stats.boosters + 1 end
            end
        end
    end
    if stats.engines > 0 and stats.weight > 0 then
        stats.speed = (stats.engines * BASE_SPEED) / (stats.weight * 0.3)
    else
        stats.speed = 0
    end
end

local function spawn_particle(x, y, vx, vy, r, g, b, life)
    particles[#particles + 1] = {
        x = x, y = y, vx = vx, vy = vy,
        r = r, g = g, b = b, a = 1.0,
        life = life, max_life = life,
    }
end

local function add_tween(target, field, to, dur)
    tweens[#tweens + 1] = {
        target = target, field = field,
        from = target[field], to = to,
        elapsed = 0, duration = dur,
    }
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 200 * dt  -- gravity on particles
        p.life = p.life - dt
        p.a = math.max(0, p.life / p.max_life)
        if p.life <= 0 then
            particles[i] = particles[#particles]
            particles[#particles] = nil
        else
            i = i + 1
        end
    end
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        -- ease out quad
        t = 1 - (1 - t) * (1 - t)
        tw.target[tw.field] = tw.from + (tw.to - tw.from) * t
        if tw.elapsed >= tw.duration then
            tw.target[tw.field] = tw.to
            tweens[i] = tweens[#tweens]
            tweens[#tweens] = nil
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Input binding
-- ---------------------------------------------------------------------------
lurek.input.bind("place",   "mouse1")
lurek.input.bind("part_f",  "f")
lurek.input.bind("part_w",  "w")
lurek.input.bind("part_e",  "e")
lurek.input.bind("part_a",  "a")
lurek.input.bind("part_b",  "b")
lurek.input.bind("delete",  "d")
lurek.input.bind("test",    "t")
lurek.input.bind("build",   "b")
lurek.input.bind("boost",   "space")
lurek.input.bind("quit",    "escape")

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
lurek.init(function()
    lurek.window.setTitle("Vehicle Builder — Lurek2D")
    lurek.window.setBackgroundColor(0.1, 0.1, 0.12)
    clear_grid()
end)

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
lurek.ready(function()
    -- place a starter frame in center
    local cr = math.floor(GRID_ROWS / 2)
    local cc = math.floor(GRID_COLS / 2)
    grid[cr][cc] = PART.FRAME
    compute_stats()
end)

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
lurek.process(function(dt)
    title_timer = title_timer + dt

    update_particles(dt)
    update_tweens(dt)

    -- Quit
    if lurek.input.isActionJustPressed("quit") then
        if current_state == STATE.BUILDING then
            lurek.event.quit()
        elseif current_state == STATE.TESTING then
            current_state = STATE.RESULTS
        elseif current_state == STATE.RESULTS then
            current_state = STATE.BUILDING
        elseif current_state == STATE.TITLE then
            lurek.event.quit()
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- TITLE
    -- -----------------------------------------------------------------------
    if current_state == STATE.TITLE then
        if lurek.input.isActionJustPressed("place") then
            current_state = STATE.BUILDING
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- BUILDING
    -- -----------------------------------------------------------------------
    if current_state == STATE.BUILDING then
        -- Part selection
        if lurek.input.isActionJustPressed("part_f") then selected_part = PART.FRAME;   delete_mode = false end
        if lurek.input.isActionJustPressed("part_w") then selected_part = PART.WHEEL;   delete_mode = false end
        if lurek.input.isActionJustPressed("part_e") then selected_part = PART.ENGINE;  delete_mode = false end
        if lurek.input.isActionJustPressed("part_a") then selected_part = PART.ARMOR;   delete_mode = false end
        if lurek.input.isActionJustPressed("part_b") then selected_part = PART.BOOSTER; delete_mode = false end
        if lurek.input.isActionJustPressed("delete") then delete_mode = not delete_mode end

        -- Place / delete
        if lurek.input.isActionJustPressed("place") then
            local mx, my = lurek.input.getMousePosition()
            local gc = math.floor((mx - GRID_X) / CELL) + 1
            local gr = math.floor((my - GRID_Y) / CELL) + 1
            if gc >= 1 and gc <= GRID_COLS and gr >= 1 and gr <= GRID_ROWS then
                if delete_mode then
                    if grid[gr][gc] then
                        grid[gr][gc] = nil
                        compute_stats()
                    end
                else
                    if not grid[gr][gc] then
                        local can_place = (count_parts() == 0) or has_neighbor(gr, gc)
                        local cost_ok = (total_cost + PART_COST[selected_part]) <= BUDGET
                        if can_place and cost_ok then
                            grid[gr][gc] = selected_part
                            compute_stats()
                        end
                    end
                end
            end
        end

        -- Switch to test
        if lurek.input.isActionJustPressed("test") then
            if stats.wheels > 0 and stats.engines > 0 then
                -- Init test
                test.x = 100
                test.y = TRACK_GROUND
                test.vx = stats.speed
                test.cam_x = 0
                test.speed = stats.speed
                test.alive = true
                test.armor_hp = stats.armor
                test.distance = 0
                test.boosting = false
                test.boost_timer = 0
                test.finished = false
                test.score = 0
                test.airborne = false
                test.vy = 0
                particles = {}
                current_state = STATE.TESTING
            end
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- TESTING
    -- -----------------------------------------------------------------------
    if current_state == STATE.TESTING then
        if not test.alive or test.finished then
            if lurek.input.isActionJustPressed("place") or lurek.input.isActionJustPressed("build") then
                test.score = math.floor(test.distance)
                current_state = STATE.RESULTS
            end
            return
        end

        -- Boost
        if lurek.input.isActionJustPressed("boost") and stats.boosters > 0 and not test.boosting then
            test.boosting = true
            test.boost_timer = BOOST_DUR
        end
        if test.boosting then
            test.boost_timer = test.boost_timer - dt
            if test.boost_timer <= 0 then
                test.boosting = false
            end
        end

        -- Speed
        local spd = test.speed
        if test.boosting then spd = spd * BOOST_MULT end

        -- Tween acceleration at start
        local target_vx = spd
        test.vx = test.vx + (target_vx - test.vx) * math.min(dt * 3, 1)

        test.x = test.x + test.vx * dt
        test.distance = test.x - 100

        -- Gravity / airborne
        if test.airborne then
            test.vy = test.vy + 600 * dt
            test.y = test.y + test.vy * dt
            if test.y >= TRACK_GROUND then
                test.y = TRACK_GROUND
                test.airborne = false
                test.vy = 0
            end
        end

        -- Camera follow
        test.cam_x = test.x - 200

        -- Check obstacles
        local track = TRACKS[track_index]
        for _, obs in ipairs(track.obstacles) do
            local ox = obs.x
            local ow = obs.w
            if test.x + 20 > ox and test.x - 20 < ox + ow then
                if obs.kind == "wall" and not obs.hit then
                    if test.armor_hp > 0 then
                        test.armor_hp = test.armor_hp - 1
                        obs.hit = true
                        -- crash debris particles
                        for _ = 1, 12 do
                            spawn_particle(
                                test.x, test.y - 10,
                                math.random(-150, 50), math.random(-200, -50),
                                0.8, 0.4, 0.1, 0.6 + math.random() * 0.4
                            )
                        end
                        -- shake tween
                        local shake_tbl = { val = 0 }
                        add_tween(shake_tbl, "val", 8, 0.1)
                        test.vx = test.vx * 0.4  -- slowdown on hit
                    else
                        test.alive = false
                        -- big crash
                        for _ = 1, 25 do
                            spawn_particle(
                                test.x, test.y - 15,
                                math.random(-200, 200), math.random(-300, -50),
                                1.0, 0.3, 0.0, 0.8 + math.random() * 0.5
                            )
                        end
                    end
                elseif obs.kind == "gap" then
                    -- check if over gap — fall if no wheels / no ground
                    if not test.airborne then
                        test.airborne = true
                        test.vy = 0
                        -- if y goes below screen, fail
                    end
                elseif obs.kind == "ramp" and not obs.launched then
                    obs.launched = true
                    test.airborne = true
                    test.vy = -(obs.h or 20) * 8
                end
            end
        end

        -- Fell off screen
        if test.y > SCREEN_H + 50 then
            test.alive = false
        end

        -- Track complete
        if test.distance >= track.length then
            test.finished = true
            test.score = math.floor(test.distance) + track_index * 500
        end

        -- Engine exhaust particles
        if math.random() < 0.6 then
            spawn_particle(
                test.x - 20 - test.cam_x + 200, test.y - 8,
                math.random(-80, -20), math.random(-30, 30),
                0.9, 0.5, 0.1, 0.3 + math.random() * 0.2
            )
        end

        -- Booster flame particles
        if test.boosting and math.random() < 0.8 then
            spawn_particle(
                test.x - 25 - test.cam_x + 200, test.y - 12,
                math.random(-160, -60), math.random(-20, 20),
                1.0, 0.2, 0.0, 0.2 + math.random() * 0.3
            )
        end

        -- Wheel dust
        if not test.airborne and math.random() < 0.4 * (stats.wheels / 4) then
            spawn_particle(
                test.x - 10 - test.cam_x + 200, test.y,
                math.random(-40, 10), math.random(-20, -5),
                0.6, 0.55, 0.45, 0.3 + math.random() * 0.2
            )
        end

        return
    end

    -- -----------------------------------------------------------------------
    -- RESULTS
    -- -----------------------------------------------------------------------
    if current_state == STATE.RESULTS then
        if lurek.input.isActionJustPressed("build") then
            -- advance track or loop
            if test.finished and track_index < #TRACKS then
                track_index = track_index + 1
            end
            -- reset obstacle hit flags
            for _, track in ipairs(TRACKS) do
                for _, obs in ipairs(track.obstacles) do
                    obs.hit = nil
                    obs.launched = nil
                end
            end
            current_state = STATE.BUILDING
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Render — world-space drawing (vehicle, track)
-- ---------------------------------------------------------------------------
lurek.render(function()
    -- -----------------------------------------------------------------------
    -- TITLE
    -- -----------------------------------------------------------------------
    if current_state == STATE.TITLE then
        local pulse = 0.6 + 0.4 * math.sin(title_timer * 3)
        lurek.draw.text("VEHICLE BUILDER", SCREEN_W / 2 - 130, 180, 32)
        lurek.draw.setColor(0.7, 0.8, 1.0, pulse)
        lurek.draw.text("DESIGN AND TEST", SCREEN_W / 2 - 110, 240, 20)
        lurek.draw.setColor(0.5, 0.5, 0.5, 1)
        lurek.draw.text("Click to start", SCREEN_W / 2 - 70, 340, 16)
        lurek.draw.setColor(1, 1, 1, 1)
        return
    end

    -- -----------------------------------------------------------------------
    -- BUILDING — draw grid and placed parts
    -- -----------------------------------------------------------------------
    if current_state == STATE.BUILDING then
        -- Grid lines
        lurek.draw.setColor(0.2, 0.2, 0.25, 1)
        for r = 0, GRID_ROWS do
            local y = GRID_Y + r * CELL
            lurek.draw.line(GRID_X, y, GRID_X + GRID_COLS * CELL, y)
        end
        for c = 0, GRID_COLS do
            local x = GRID_X + c * CELL
            lurek.draw.line(x, GRID_Y, x, GRID_Y + GRID_ROWS * CELL)
        end

        -- Parts on grid
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                local p = grid[r][c]
                if p then
                    local px = GRID_X + (c - 1) * CELL + 2
                    local py = GRID_Y + (r - 1) * CELL + 2
                    local clr = PART_COLOR[p]
                    lurek.draw.setColor(clr[1], clr[2], clr[3], 1)
                    if p == PART.WHEEL then
                        lurek.draw.circle(px + CELL / 2 - 2, py + CELL / 2 - 2, CELL / 2 - 4)
                    else
                        lurek.draw.rect(px, py, CELL - 4, CELL - 4)
                    end
                end
            end
        end

        -- Hover preview
        local mx, my = lurek.input.getMousePosition()
        local hc = math.floor((mx - GRID_X) / CELL) + 1
        local hr = math.floor((my - GRID_Y) / CELL) + 1
        if hc >= 1 and hc <= GRID_COLS and hr >= 1 and hr <= GRID_ROWS and not grid[hr][hc] then
            local clr = PART_COLOR[selected_part]
            lurek.draw.setColor(clr[1], clr[2], clr[3], 0.35)
            local px = GRID_X + (hc - 1) * CELL + 2
            local py = GRID_Y + (hr - 1) * CELL + 2
            lurek.draw.rect(px, py, CELL - 4, CELL - 4)
        end

        lurek.draw.setColor(1, 1, 1, 1)
        return
    end

    -- -----------------------------------------------------------------------
    -- TESTING — side-scrolling track
    -- -----------------------------------------------------------------------
    if current_state == STATE.TESTING then
        -- Ground
        lurek.draw.setColor(0.25, 0.6, 0.25, 1)
        local track = TRACKS[track_index]

        -- Draw ground segments (skip gaps)
        local gx = -test.cam_x
        local segment_start = 0
        -- Sort obstacles by x for drawing
        for _, obs in ipairs(track.obstacles) do
            if obs.kind == "gap" then
                -- draw ground before gap
                lurek.draw.rect(segment_start - test.cam_x, TRACK_GROUND, obs.x - segment_start, 40)
                segment_start = obs.x + obs.w
            end
        end
        -- draw remaining ground
        lurek.draw.rect(segment_start - test.cam_x, TRACK_GROUND, track.length + 500 - segment_start, 40)

        -- Obstacles
        for _, obs in ipairs(track.obstacles) do
            local ox = obs.x - test.cam_x
            if obs.kind == "wall" then
                if obs.hit then
                    lurek.draw.setColor(0.4, 0.2, 0.1, 0.5)
                else
                    lurek.draw.setColor(0.6, 0.3, 0.15, 1)
                end
                lurek.draw.rect(ox, TRACK_GROUND - (obs.h or 40), obs.w, obs.h or 40)
            elseif obs.kind == "ramp" then
                lurek.draw.setColor(0.5, 0.5, 0.2, 1)
                lurek.draw.rect(ox, TRACK_GROUND - (obs.h or 20), obs.w, obs.h or 20)
            end
        end

        -- Vehicle (simplified)
        local vx_screen = test.x - test.cam_x
        local vy_screen = test.y
        if test.alive then
            -- body
            lurek.draw.setColor(0.5, 0.5, 0.55, 1)
            lurek.draw.rect(vx_screen - 20, vy_screen - 24, 40, 16)
            -- wheels
            lurek.draw.setColor(0.3, 0.3, 0.3, 1)
            lurek.draw.circle(vx_screen - 12, vy_screen - 4, 6)
            lurek.draw.circle(vx_screen + 12, vy_screen - 4, 6)
            -- engine glow
            if stats.engines > 0 then
                lurek.draw.setColor(0.9, 0.5, 0.1, 0.7)
                lurek.draw.rect(vx_screen - 6, vy_screen - 22, 12, 8)
            end
            -- booster indicator
            if test.boosting then
                lurek.draw.setColor(1.0, 0.2, 0.0, 0.9)
                lurek.draw.rect(vx_screen - 24, vy_screen - 18, 6, 10)
            end
        end

        -- Particles
        for _, p in ipairs(particles) do
            lurek.draw.setColor(p.r, p.g, p.b, p.a)
            lurek.draw.rect(p.x, p.y, 3, 3)
        end

        -- Finish line
        local finish_x = track.length - test.cam_x
        if finish_x > -20 and finish_x < SCREEN_W + 20 then
            lurek.draw.setColor(1, 1, 0, 0.8)
            lurek.draw.rect(finish_x, TRACK_GROUND - 80, 4, 80)
            lurek.draw.text("FINISH", finish_x - 20, TRACK_GROUND - 95, 14)
        end

        lurek.draw.setColor(1, 1, 1, 1)

        -- Death / finish overlay
        if not test.alive then
            lurek.draw.setColor(1, 0.2, 0.2, 0.8)
            lurek.draw.text("CRASHED!", SCREEN_W / 2 - 60, SCREEN_H / 2, 28)
            lurek.draw.setColor(0.7, 0.7, 0.7, 1)
            lurek.draw.text("Click or press B to continue", SCREEN_W / 2 - 120, SCREEN_H / 2 + 40, 14)
        elseif test.finished then
            lurek.draw.setColor(0.2, 1, 0.2, 0.8)
            lurek.draw.text("TRACK COMPLETE!", SCREEN_W / 2 - 100, SCREEN_H / 2, 28)
            lurek.draw.setColor(0.7, 0.7, 0.7, 1)
            lurek.draw.text("Click or press B to continue", SCREEN_W / 2 - 120, SCREEN_H / 2 + 40, 14)
        end

        lurek.draw.setColor(1, 1, 1, 1)
        return
    end

    -- -----------------------------------------------------------------------
    -- RESULTS
    -- -----------------------------------------------------------------------
    if current_state == STATE.RESULTS then
        lurek.draw.setColor(1, 0.9, 0.4, 1)
        lurek.draw.text("TEST RESULTS", SCREEN_W / 2 - 90, 120, 28)

        lurek.draw.setColor(0.9, 0.9, 0.9, 1)
        lurek.draw.text(string.format("Track: %d / %d", track_index, #TRACKS), 280, 200, 18)
        lurek.draw.text(string.format("Distance: %d px", math.floor(test.distance)), 280, 230, 18)
        lurek.draw.text(string.format("Score: %d", test.score), 280, 260, 18)
        lurek.draw.text(string.format("Armor remaining: %d / %d", test.armor_hp, stats.armor), 280, 290, 18)

        if test.finished then
            lurek.draw.setColor(0.3, 1, 0.3, 1)
            lurek.draw.text("PASSED!", 280, 330, 22)
        else
            lurek.draw.setColor(1, 0.3, 0.3, 1)
            lurek.draw.text("FAILED", 280, 330, 22)
        end

        lurek.draw.setColor(0.5, 0.5, 0.5, 1)
        lurek.draw.text("Press B to return to build mode", 250, 420, 14)
        lurek.draw.setColor(1, 1, 1, 1)
    end
end)

-- ---------------------------------------------------------------------------
-- Render UI — HUD panels, stats, budget (screen-space)
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    if current_state == STATE.BUILDING then
        -- Top bar
        lurek.draw.setColor(0.12, 0.12, 0.15, 0.9)
        lurek.draw.rect(0, 0, SCREEN_W, 28)

        lurek.draw.setColor(0.9, 0.9, 0.9, 1)
        lurek.draw.text(string.format("FPS: %d", lurek.timer.getFps()), 10, 6, 14)

        -- Budget
        local budget_color = total_cost <= BUDGET and { 0.3, 1, 0.3 } or { 1, 0.3, 0.3 }
        lurek.draw.setColor(budget_color[1], budget_color[2], budget_color[3], 1)
        lurek.draw.text(string.format("Budget: %dg / %dg", total_cost, BUDGET), 120, 6, 14)

        -- Mode
        lurek.draw.setColor(1, 1, 0.5, 1)
        if delete_mode then
            lurek.draw.text("[DELETE MODE]", 340, 6, 14)
        else
            lurek.draw.text("[" .. PART_NAMES[selected_part] .. "]", 340, 6, 14)
        end

        -- Stats panel (right side)
        local sx = GRID_X + GRID_COLS * CELL + 20
        local sy = GRID_Y
        lurek.draw.setColor(0.15, 0.15, 0.18, 0.9)
        lurek.draw.rect(sx - 5, sy - 5, 130, 180)

        lurek.draw.setColor(1, 0.9, 0.5, 1)
        lurek.draw.text("STATS", sx, sy, 16)
        lurek.draw.setColor(0.8, 0.8, 0.8, 1)
        lurek.draw.text(string.format("Speed:   %.0f", stats.speed), sx, sy + 25, 13)
        lurek.draw.text(string.format("Weight:  %d", stats.weight), sx, sy + 45, 13)
        lurek.draw.text(string.format("Engines: %d", stats.engines), sx, sy + 65, 13)
        lurek.draw.text(string.format("Wheels:  %d", stats.wheels), sx, sy + 85, 13)
        lurek.draw.text(string.format("Armor:   %d", stats.armor), sx, sy + 105, 13)
        lurek.draw.text(string.format("Boost:   %d", stats.boosters), sx, sy + 125, 13)

        -- Parts legend
        lurek.draw.setColor(1, 0.9, 0.5, 1)
        lurek.draw.text("PARTS", sx, sy + 155, 16)
        local parts_info = {
            "F: Frame  (0g)",
            "W: Wheel  (20g)",
            "E: Engine (50g)",
            "A: Armor  (30g)",
            "B: Boost  (40g)",
        }
        for i, txt in ipairs(parts_info) do
            local clr = PART_COLOR[i]
            lurek.draw.setColor(clr[1], clr[2], clr[3], 1)
            lurek.draw.text(txt, sx, sy + 155 + i * 18, 12)
        end

        -- Controls hint
        lurek.draw.setColor(0.4, 0.4, 0.4, 1)
        lurek.draw.text("D: toggle delete | T: test", GRID_X, GRID_Y + GRID_ROWS * CELL + 12, 12)
        lurek.draw.text("Need wheels + engine to test", GRID_X, GRID_Y + GRID_ROWS * CELL + 28, 12)

    elseif current_state == STATE.TESTING then
        -- Test HUD
        lurek.draw.setColor(0.12, 0.12, 0.15, 0.85)
        lurek.draw.rect(0, 0, SCREEN_W, 28)

        lurek.draw.setColor(0.9, 0.9, 0.9, 1)
        lurek.draw.text(string.format("FPS: %d", lurek.timer.getFps()), 10, 6, 14)
        lurek.draw.text(string.format("Distance: %d", math.floor(test.distance)), 120, 6, 14)
        lurek.draw.text(string.format("Track %d/%d", track_index, #TRACKS), 320, 6, 14)

        -- Armor bar
        if stats.armor > 0 then
            lurek.draw.setColor(0.2, 0.5, 0.8, 1)
            lurek.draw.text(string.format("Armor: %d/%d", test.armor_hp, stats.armor), 480, 6, 14)
        end

        -- Boost indicator
        if test.boosting then
            lurek.draw.setColor(1, 0.3, 0.0, 1)
            lurek.draw.text(string.format("BOOST %.1fs", test.boost_timer), 640, 6, 14)
        elseif stats.boosters > 0 then
            lurek.draw.setColor(0.5, 0.5, 0.5, 1)
            lurek.draw.text("[Space] Boost", 640, 6, 14)
        end
    end

    lurek.draw.setColor(1, 1, 1, 1)
end)
