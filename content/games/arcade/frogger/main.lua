-- ============================================================================
-- Frogger — Lurek2D
-- ============================================================================
-- Category : arcade
-- Source   : content/games/arcade/frogger/main.lua
-- Run with : cargo run -- content/games/arcade/frogger
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- Grid / row layout
local TILE  = 40                        -- pixels per grid cell
local COLS  = SCREEN_W / TILE           -- 20 columns
local ROWS  = 13                        -- total rows top→bottom

-- Row indices (0 = top row, 12 = bottom row)
local HOME_ROW     = 0
local RIVER_TOP    = 1
local RIVER_BOT    = 5
local MID_SAFE     = 6
local ROAD_TOP     = 7
local ROAD_BOT     = 11
local START_ROW    = 12

-- Y position for a given row
local function row_y(r) return 40 + r * TILE end

-- Home slot positions (5 evenly spaced)
local HOME_SLOTS = {}
for i = 0, 4 do
    HOME_SLOTS[i + 1] = { x = 60 + i * 160, filled = false }
end

-- Frog
local FROG_SIZE = 30
local FROG_SPEED_INTERVAL = 0.12       -- min time between hops (input cooldown)

-- Timer
local LEVEL_TIME      = 30             -- seconds per level
local TIMER_BAR_W     = 200
local TIMER_BAR_H     = 12

-- Scoring
local PTS_STEP        = 10
local PTS_HOME        = 50
local PTS_LEVEL       = 1000
local PTS_FLY         = 200
local PTS_TIME_BONUS  = 5              -- per remaining second

-- ---------------------------------------------------------------------------
-- Lane definitions (road + river) — built per level
-- ---------------------------------------------------------------------------
-- Each lane: { row, speed, dir(1=right, -1=left), type, obj_w, gap, submerge? }
local lane_defs = {}

local function build_lanes(level)
    local spd = 1.0 + (level - 1) * 0.12       -- speed multiplier

    lane_defs = {
        -- Road lanes (rows 7-11, bottom to top)
        { row = 11, speed = 60  * spd, dir = -1, kind = "car",   w = 40,  gap = 200 },
        { row = 10, speed = 80  * spd, dir =  1, kind = "truck", w = 80,  gap = 260 },
        { row =  9, speed = 100 * spd, dir = -1, kind = "car",   w = 40,  gap = 180 },
        { row =  8, speed = 70  * spd, dir =  1, kind = "car",   w = 50,  gap = 220 },
        { row =  7, speed = 110 * spd, dir = -1, kind = "truck", w = 70,  gap = 240 },
        -- River lanes (rows 1-5, bottom to top)
        { row =  5, speed = 50  * spd, dir =  1, kind = "log",    w = 120, gap = 220 },
        { row =  4, speed = 40  * spd, dir = -1, kind = "turtle", w = 100, gap = 200, submerge = true },
        { row =  3, speed = 65  * spd, dir =  1, kind = "log",    w = 160, gap = 260 },
        { row =  2, speed = 45  * spd, dir = -1, kind = "turtle", w = 90,  gap = 210, submerge = true },
        { row =  1, speed = 55  * spd, dir =  1, kind = "log",    w = 140, gap = 240 },
    }
end

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local frog = { gx = 10, gy = START_ROW, x = 0, y = 0, alive = true }
local frog_visual = { x = 0, y = 0 }   -- smoothly tweened draw position
local hopping = false                    -- true while hop tween is active
local hop_cooldown = 0

local lanes = {}        -- { [lane_idx] = { objects = { {x, y, w} ... } } }
local lives = 3
local score = 0
local high_score = 0
local level = 1
local timer_left = LEVEL_TIME
local furthest_row = START_ROW          -- highest row reached (for step scoring)

-- Bonus fly
local fly = { active = false, slot = 0, timer = 0 }

-- Turtle submerge state per lane
local turtle_timers = {}                -- { [lane_idx] = { phase, timer } }

-- Camera / FX
local cam = nil
local particles = {}
local score_pops = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function frog_screen_pos()
    return frog.gx * TILE + (TILE - FROG_SIZE) / 2,
           row_y(frog.gy) + (TILE - FROG_SIZE) / 2
end

local function rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ---------------------------------------------------------------------------
-- Particle helpers
-- ---------------------------------------------------------------------------
local function spawn_particles(px, py, r, g, b, count)
    for _ = 1, (count or 10) do
        table.insert(particles, {
            x = px, y = py,
            vx = (math.random() - 0.5) * 200,
            vy = (math.random() - 0.5) * 200,
            life = 0.35 + math.random() * 0.35,
            max_life = 0.7,
            r = r, g = g, b = b,
            size = 2 + math.random() * 4,
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
        lurek.render.drawRect("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

-- ---------------------------------------------------------------------------
-- Score pop (tween-like rising text)
-- ---------------------------------------------------------------------------
local function add_score_pop(x, y, pts)
    table.insert(score_pops, {
        x = x, y = y, text = "+" .. tostring(pts),
        alpha = 1.0, dy = 0, life = 0.8,
    })
end

local function update_score_pops(dt)
    local i = 1
    while i <= #score_pops do
        local sp = score_pops[i]
        sp.dy = sp.dy - 60 * dt
        sp.y  = sp.y + sp.dy * dt
        sp.life  = sp.life - dt
        sp.alpha = clamp(sp.life / 0.8, 0, 1)
        if sp.life <= 0 then
            table.remove(score_pops, i)
        else
            i = i + 1
        end
    end
end

local function draw_score_pops()
    for _, sp in ipairs(score_pops) do
        lurek.render.setColor(1, 1, 0, sp.alpha)
        lurek.render.print(sp.text, sp.x, sp.y, 1)
    end
end

-- ---------------------------------------------------------------------------
-- Lane object spawning
-- ---------------------------------------------------------------------------
local function build_lane_objects()
    lanes = {}
    for li, def in ipairs(lane_defs) do
        local objs = {}
        local count = math.ceil(SCREEN_W / def.gap) + 2
        for j = 0, count - 1 do
            local ox = j * def.gap
            if def.dir == -1 then ox = SCREEN_W - ox end
            table.insert(objs, { x = ox, y = row_y(def.row) + 4, w = def.w })
        end
        lanes[li] = { def = def, objects = objs }
        -- Turtle submerge timers
        if def.submerge then
            turtle_timers[li] = { phase = "visible", timer = 3 + math.random() * 3 }
        end
    end
end

-- ---------------------------------------------------------------------------
-- Frog hop (tween)
-- ---------------------------------------------------------------------------
local hop_tween = nil

local function start_hop(dx, dy)
    if hopping then return end
    local nx = clamp(frog.gx + dx, 0, COLS - 1)
    local ny = clamp(frog.gy + dy, HOME_ROW, START_ROW)
    if nx == frog.gx and ny == frog.gy then return end

    frog.gx = nx
    frog.gy = ny
    local tx, ty = frog_screen_pos()

    hopping = true
    hop_tween = {
        sx = frog_visual.x, sy = frog_visual.y,
        tx = tx, ty = ty,
        elapsed = 0, duration = 0.08,
    }

    -- Score for moving forward
    if ny < furthest_row then
        local steps = furthest_row - ny
        score = score + PTS_STEP * steps
        furthest_row = ny
    end
end

local function update_hop_tween(dt)
    if not hop_tween then return end
    hop_tween.elapsed = hop_tween.elapsed + dt
    local t = clamp(hop_tween.elapsed / hop_tween.duration, 0, 1)
    -- Smooth-step interpolation
    t = t * t * (3 - 2 * t)
    frog_visual.x = hop_tween.sx + (hop_tween.tx - hop_tween.sx) * t
    frog_visual.y = hop_tween.sy + (hop_tween.ty - hop_tween.sy) * t
    if hop_tween.elapsed >= hop_tween.duration then
        frog_visual.x = hop_tween.tx
        frog_visual.y = hop_tween.ty
        hop_tween = nil
        hopping = false
    end
end

-- ---------------------------------------------------------------------------
-- Frog death / respawn
-- ---------------------------------------------------------------------------
local function kill_frog(cause)
    if not frog.alive then return end
    frog.alive = false
    local fx, fy = frog_visual.x + FROG_SIZE / 2, frog_visual.y + FROG_SIZE / 2

    if cause == "water" then
        spawn_particles(fx, fy, 0.2, 0.5, 1.0, 14)    -- blue splash
    else
        spawn_particles(fx, fy, 1.0, 0.4, 0.1, 12)     -- orange poof
    end

    lives = lives - 1
    if lives <= 0 then
        current_state = STATE.GAME_OVER
        if score > high_score then high_score = score end
    else
        -- Respawn after short delay using a simple timer
        frog.respawn_timer = 0.8
    end
end

local function respawn_frog()
    frog.gx = 10
    frog.gy = START_ROW
    frog.alive = true
    frog.respawn_timer = nil
    hopping = false
    hop_tween = nil
    furthest_row = START_ROW
    local sx, sy = frog_screen_pos()
    frog_visual.x = sx
    frog_visual.y = sy
end

-- ---------------------------------------------------------------------------
-- Level / reset
-- ---------------------------------------------------------------------------
local function reset_homes()
    for _, h in ipairs(HOME_SLOTS) do h.filled = false end
end

local function start_level()
    build_lanes(level)
    build_lane_objects()
    timer_left = LEVEL_TIME
    furthest_row = START_ROW
    fly.active = false
    fly.timer = 5 + math.random() * 10
    respawn_frog()
end

local function start_game()
    score = 0
    lives = 3
    level = 1
    reset_homes()
    particles = {}
    score_pops = {}
    current_state = STATE.PLAYING
    start_level()
end

-- ---------------------------------------------------------------------------
-- lurek.init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Frogger — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.06)

    -- Action-based input
    lurek.input.bind("up",    {"up",    "w"})
    lurek.input.bind("down",  {"down",  "s"})
    lurek.input.bind("left",  {"left",  "a"})
    lurek.input.bind("right", {"right", "d"})
    lurek.input.bind("start", {"return", "space"})
    lurek.input.bind("quit",  {"escape"})

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    math.randomseed(os.time())
    build_lanes(1)
end

-- ---------------------------------------------------------------------------
-- lurek.process — update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    update_particles(dt)
    update_score_pops(dt)

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("start") then
            start_game()
        end
        if lurek.input.wasActionPressed("quit") then lurek.event.quit() end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("start") then
            reset_homes()
            start_game()
        end
        if lurek.input.wasActionPressed("quit") then lurek.event.quit() end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Respawn timer
    if frog.respawn_timer then
        frog.respawn_timer = frog.respawn_timer - dt
        if frog.respawn_timer <= 0 then respawn_frog() end
        update_hop_tween(dt)
        return
    end

    -- Hop input
    hop_cooldown = hop_cooldown - dt
    if frog.alive and hop_cooldown <= 0 then
        if     lurek.input.wasActionPressed("up")    then start_hop( 0, -1); hop_cooldown = FROG_SPEED_INTERVAL
        elseif lurek.input.wasActionPressed("down")  then start_hop( 0,  1); hop_cooldown = FROG_SPEED_INTERVAL
        elseif lurek.input.wasActionPressed("left")  then start_hop(-1,  0); hop_cooldown = FROG_SPEED_INTERVAL
        elseif lurek.input.wasActionPressed("right") then start_hop( 1,  0); hop_cooldown = FROG_SPEED_INTERVAL
        end
    end

    update_hop_tween(dt)

    -- Move lane objects
    for li, lane in ipairs(lanes) do
        local def = lane.def
        for _, obj in ipairs(lane.objects) do
            obj.x = obj.x + def.speed * def.dir * dt
            -- Wrap around screen
            if def.dir == 1 and obj.x > SCREEN_W + obj.w then
                obj.x = -obj.w
            elseif def.dir == -1 and obj.x < -obj.w then
                obj.x = SCREEN_W + obj.w
            end
        end
    end

    -- Turtle submerge cycle
    for li, tt in pairs(turtle_timers) do
        tt.timer = tt.timer - dt
        if tt.timer <= 0 then
            if tt.phase == "visible" then
                tt.phase = "warning"
                tt.timer = 0.8
            elseif tt.phase == "warning" then
                tt.phase = "submerged"
                tt.timer = 1.5 + math.random() * 1.0
            else
                tt.phase = "visible"
                tt.timer = 3 + math.random() * 3
            end
        end
    end

    -- Timer countdown
    timer_left = timer_left - dt
    if timer_left <= 0 then
        timer_left = 0
        kill_frog("time")
    end

    -- Bonus fly timer
    if not fly.active then
        fly.timer = fly.timer - dt
        if fly.timer <= 0 then
            -- Pick a random unfilled home slot
            local open = {}
            for idx, h in ipairs(HOME_SLOTS) do
                if not h.filled then table.insert(open, idx) end
            end
            if #open > 0 then
                fly.slot = open[math.random(#open)]
                fly.active = true
                fly.timer = 4 + math.random() * 4     -- fly stays this long
            else
                fly.timer = 2
            end
        end
    else
        fly.timer = fly.timer - dt
        if fly.timer <= 0 then fly.active = false; fly.timer = 6 + math.random() * 8 end
    end

    -- ── Collision detection (only when not hopping) ───────────
    if frog.alive and not hopping then
        local fx = frog.gx * TILE + (TILE - FROG_SIZE) / 2
        local fy = row_y(frog.gy) + (TILE - FROG_SIZE) / 2
        local fw, fh = FROG_SIZE, FROG_SIZE

        -- Road collision (rows 7-11)
        if frog.gy >= ROAD_TOP and frog.gy <= ROAD_BOT then
            for li = 1, 5 do   -- first 5 lane_defs are road
                for _, obj in ipairs(lanes[li].objects) do
                    if rects_overlap(fx, fy, fw, fh, obj.x, obj.y, obj.w, TILE - 8) then
                        kill_frog("car")
                        return
                    end
                end
            end
        end

        -- River collision (rows 1-5)
        if frog.gy >= RIVER_TOP and frog.gy <= RIVER_BOT then
            local on_platform = false
            local ride_vx = 0

            for li = 6, 10 do  -- lane_defs 6-10 are river
                local lane = lanes[li]
                local def  = lane.def
                if def.row == frog.gy then
                    -- Check if turtle lane is submerged
                    local tt = turtle_timers[li]
                    local visible = true
                    if tt and tt.phase == "submerged" then visible = false end

                    if visible then
                        for _, obj in ipairs(lane.objects) do
                            if rects_overlap(fx, fy, fw, fh, obj.x, obj.y, obj.w, TILE - 8) then
                                on_platform = true
                                ride_vx = def.speed * def.dir
                                break
                            end
                        end
                    end
                end
                if on_platform then break end
            end

            if on_platform then
                -- Ride the log/turtle
                frog_visual.x = frog_visual.x + ride_vx * dt
                frog.gx = math.floor((frog_visual.x + FROG_SIZE / 2) / TILE)
                frog.gx = clamp(frog.gx, 0, COLS - 1)
                -- Check if frog drifted off screen
                if frog_visual.x < -FROG_SIZE or frog_visual.x > SCREEN_W then
                    kill_frog("water")
                end
            else
                kill_frog("water")
            end
        end

        -- Home slot landing (row 0)
        if frog.gy == HOME_ROW then
            local landed = false
            for idx, h in ipairs(HOME_SLOTS) do
                if not h.filled and math.abs(fx + FROG_SIZE / 2 - (h.x + TILE / 2)) < TILE * 0.6 then
                    h.filled = true
                    landed = true
                    local pts = PTS_HOME
                    if fly.active and fly.slot == idx then
                        pts = pts + PTS_FLY
                        fly.active = false
                        fly.timer = 6 + math.random() * 8
                    end
                    score = score + pts
                    add_score_pop(h.x, row_y(HOME_ROW), pts)
                    spawn_particles(h.x + TILE / 2, row_y(HOME_ROW) + TILE / 2, 0, 1, 0, 10)
                    break
                end
            end

            if not landed then
                -- Missed the slot — death
                kill_frog("water")
            else
                -- Check if all homes filled
                local all_filled = true
                for _, h in ipairs(HOME_SLOTS) do
                    if not h.filled then all_filled = false; break end
                end
                if all_filled then
                    -- Level complete
                    local time_bonus = math.floor(timer_left) * PTS_TIME_BONUS
                    score = score + PTS_LEVEL + time_bonus
                    add_score_pop(SCREEN_W / 2 - 40, SCREEN_H / 2, PTS_LEVEL + time_bonus)
                    level = level + 1
                    reset_homes()
                    start_level()
                else
                    respawn_frog()
                end
            end
        end
    end

    cam:update(dt)
end

-- ---------------------------------------------------------------------------
-- lurek.render — world drawing
-- ---------------------------------------------------------------------------
function lurek.render()
    cam:apply()

    -- ── Water band (rows 0-5) ─────────────────────────────────
    lurek.render.setColor(0.05, 0.15, 0.45, 1)
    lurek.render.drawRect("fill", 0, row_y(HOME_ROW), SCREEN_W, TILE * 6)

    -- ── Road band (rows 7-11) ─────────────────────────────────
    lurek.render.setColor(0.18, 0.18, 0.2, 1)
    lurek.render.drawRect("fill", 0, row_y(ROAD_TOP), SCREEN_W, TILE * 5)

    -- Road lane dividers
    lurek.render.setColor(0.5, 0.5, 0.2, 0.5)
    for r = ROAD_TOP, ROAD_BOT - 1 do
        local ly = row_y(r) + TILE
        for dx = 0, SCREEN_W, 40 do
            lurek.render.drawRect("fill", dx, ly - 1, 20, 2)
        end
    end

    -- ── Safe zones ────────────────────────────────────────────
    -- Start zone (row 12)
    lurek.render.setColor(0.1, 0.35, 0.1, 1)
    lurek.render.drawRect("fill", 0, row_y(START_ROW), SCREEN_W, TILE)
    -- Middle safe zone (row 6)
    lurek.render.setColor(0.1, 0.35, 0.1, 1)
    lurek.render.drawRect("fill", 0, row_y(MID_SAFE), SCREEN_W, TILE)

    -- ── Home slots ────────────────────────────────────────────
    for idx, h in ipairs(HOME_SLOTS) do
        if h.filled then
            lurek.render.setColor(0.1, 0.8, 0.1, 1)
        else
            lurek.render.setColor(0.03, 0.06, 0.15, 1)
        end
        lurek.render.drawRect("fill", h.x, row_y(HOME_ROW) + 4, TILE, TILE - 8)
        -- Slot outline
        lurek.render.setColor(0.3, 0.3, 0.4, 1)
        lurek.render.drawRect("line", h.x, row_y(HOME_ROW) + 4, TILE, TILE - 8)
    end

    -- Bonus fly
    if fly.active then
        local h = HOME_SLOTS[fly.slot]
        if h and not h.filled then
            lurek.render.setColor(1, 0.9, 0.1, 0.9)
            lurek.render.circle("fill", h.x + TILE / 2, row_y(HOME_ROW) + TILE / 2, 6)
            lurek.render.setColor(0.6, 0.4, 0, 1)
            lurek.render.circle("fill", h.x + TILE / 2 - 5, row_y(HOME_ROW) + TILE / 2 - 2, 2)
            lurek.render.circle("fill", h.x + TILE / 2 + 5, row_y(HOME_ROW) + TILE / 2 - 2, 2)
        end
    end

    -- ── Lane objects ──────────────────────────────────────────
    for li, lane in ipairs(lanes) do
        local def = lane.def
        for _, obj in ipairs(lane.objects) do
            if def.kind == "car" then
                lurek.render.setColor(0.9, 0.2, 0.2, 1)
                lurek.render.drawRect("fill", obj.x, obj.y, obj.w, TILE - 8)
                -- Windshield
                lurek.render.setColor(0.5, 0.8, 1, 0.7)
                local wx = (def.dir == 1) and (obj.x + obj.w - 10) or (obj.x + 2)
                lurek.render.drawRect("fill", wx, obj.y + 4, 8, TILE - 16)
            elseif def.kind == "truck" then
                lurek.render.setColor(0.85, 0.65, 0.1, 1)
                lurek.render.drawRect("fill", obj.x, obj.y, obj.w, TILE - 8)
                -- Cab
                lurek.render.setColor(0.7, 0.5, 0.05, 1)
                local cx = (def.dir == 1) and (obj.x + obj.w - 16) or obj.x
                lurek.render.drawRect("fill", cx, obj.y + 2, 16, TILE - 12)
            elseif def.kind == "log" then
                lurek.render.setColor(0.45, 0.28, 0.1, 1)
                lurek.render.drawRect("fill", obj.x, obj.y, obj.w, TILE - 8)
                -- Wood grain lines
                lurek.render.setColor(0.35, 0.2, 0.05, 0.5)
                lurek.render.drawRect("fill", obj.x + 6, obj.y + 8, obj.w - 12, 2)
                lurek.render.drawRect("fill", obj.x + 10, obj.y + TILE - 16, obj.w - 20, 2)
            elseif def.kind == "turtle" then
                local tt = turtle_timers[li]
                if tt then
                    if tt.phase == "submerged" then
                        -- Don't draw submerged turtles
                    elseif tt.phase == "warning" then
                        -- Blinking — draw semi-transparent
                        local blink = math.sin(tt.timer * 20) > 0
                        if blink then
                            lurek.render.setColor(0.1, 0.4, 0.2, 0.5)
                            local tw = (TILE - 8) / 2
                            local shells = math.floor(obj.w / (tw + 6))
                            for s = 0, shells - 1 do
                                lurek.render.circle("fill", obj.x + tw / 2 + s * (tw + 6) + 3, obj.y + (TILE - 8) / 2, tw / 2)
                            end
                        end
                    else
                        lurek.render.setColor(0.1, 0.45, 0.2, 1)
                        local tw = (TILE - 8) / 2
                        local shells = math.floor(obj.w / (tw + 6))
                        for s = 0, shells - 1 do
                            lurek.render.circle("fill", obj.x + tw / 2 + s * (tw + 6) + 3, obj.y + (TILE - 8) / 2, tw / 2)
                        end
                        -- Shell detail
                        lurek.render.setColor(0.05, 0.3, 0.1, 0.6)
                        for s = 0, shells - 1 do
                            lurek.render.circle("fill", obj.x + tw / 2 + s * (tw + 6) + 3, obj.y + (TILE - 8) / 2, tw / 4)
                        end
                    end
                end
            end
        end
    end

    -- ── Frog ──────────────────────────────────────────────────
    if frog.alive then
        local fx, fy = frog_visual.x, frog_visual.y

        -- Body
        lurek.render.setColor(0.15, 0.75, 0.15, 1)
        lurek.render.drawRect("fill", fx, fy, FROG_SIZE, FROG_SIZE)

        -- Lighter belly
        lurek.render.setColor(0.3, 0.9, 0.3, 1)
        lurek.render.drawRect("fill", fx + 6, fy + 8, FROG_SIZE - 12, FROG_SIZE - 12)

        -- Eyes (white + black pupil)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.circle("fill", fx + 6, fy + 4, 4)
        lurek.render.circle("fill", fx + FROG_SIZE - 6, fy + 4, 4)
        lurek.render.setColor(0, 0, 0, 1)
        lurek.render.circle("fill", fx + 6, fy + 4, 2)
        lurek.render.circle("fill", fx + FROG_SIZE - 6, fy + 4, 2)
    end

    -- ── Particles ─────────────────────────────────────────────
    draw_particles()
    draw_score_pops()

    cam:reset()
end

-- ---------------------------------------------------------------------------
-- lurek.render_ui — HUD overlay (screen space)
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(0.05, 0.15, 0.45, 1)
        lurek.render.drawRect("fill", 0, 0, SCREEN_W, SCREEN_H)

        -- Title
        lurek.render.setColor(0.1, 0.9, 0.1, 1)
        lurek.render.print("F R O G G E R", SCREEN_W / 2 - 100, 100, 2)

        -- ASCII frog art
        lurek.render.setColor(0.2, 0.8, 0.2, 1)
        local frog_art = {
            "    @..@    ",
            "   (----)   ",
            "  ( >  < )  ",
            "  ^^ /\\ ^^  ",
            "    ~~~~    ",
        }
        for i, line in ipairs(frog_art) do
            lurek.render.print(line, SCREEN_W / 2 - 72, 180 + i * 22, 1.4)
        end

        -- Instructions
        lurek.render.setColor(1, 1, 1, 0.9)
        lurek.render.print("Guide the frog across roads and rivers!", SCREEN_W / 2 - 160, 350, 1)
        lurek.render.print("Ride logs and turtles — don't fall in!", SCREEN_W / 2 - 155, 375, 1)
        lurek.render.print("Fill all 5 home slots to win!", SCREEN_W / 2 - 120, 400, 1)

        -- Blink "PRESS ENTER"
        local blink = math.sin(lurek.timer.getTime() * 4) > 0
        if blink then
            lurek.render.setColor(1, 1, 0, 1)
            lurek.render.print("PRESS ENTER", SCREEN_W / 2 - 70, 470, 1.5)
        end

        -- High score
        if high_score > 0 then
            lurek.render.setColor(0.8, 0.8, 0.2, 1)
            lurek.render.print("HIGH SCORE: " .. high_score, SCREEN_W / 2 - 70, 530, 1)
        end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.drawRect("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 90, 200, 2.5)

        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("SCORE: " .. score, SCREEN_W / 2 - 60, 280, 1.5)
        lurek.render.print("LEVEL: " .. level, SCREEN_W / 2 - 50, 320, 1.2)

        if score >= high_score and score > 0 then
            lurek.render.setColor(1, 1, 0, 1)
            lurek.render.print("NEW HIGH SCORE!", SCREEN_W / 2 - 80, 360, 1.2)
        end

        local blink = math.sin(lurek.timer.getTime() * 4) > 0
        if blink then
            lurek.render.setColor(1, 1, 1, 0.9)
            lurek.render.print("PRESS ENTER TO RETRY", SCREEN_W / 2 - 110, 430, 1.2)
        end
        return
    end

    -- ── PLAYING HUD ───────────────────────────────────────────
    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("SCORE: " .. score, 10, 6, 1)

    -- Level
    lurek.render.print("LVL " .. level, SCREEN_W / 2 - 25, 6, 1)

    -- Lives (draw small frogs)
    for i = 1, lives do
        lurek.render.setColor(0.15, 0.75, 0.15, 1)
        lurek.render.drawRect("fill", SCREEN_W - 30 * i, 6, 16, 16)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.circle("fill", SCREEN_W - 30 * i + 4, 9, 2)
        lurek.render.circle("fill", SCREEN_W - 30 * i + 12, 9, 2)
    end

    -- Timer bar (bottom)
    local timer_pct = clamp(timer_left / LEVEL_TIME, 0, 1)
    local bar_x = SCREEN_W / 2 - TIMER_BAR_W / 2
    local bar_y = SCREEN_H - 22
    -- Background
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.drawRect("fill", bar_x, bar_y, TIMER_BAR_W, TIMER_BAR_H)
    -- Fill (green → yellow → red)
    local tr = (timer_pct < 0.5) and 1.0 or (1.0 - (timer_pct - 0.5) * 2)
    local tg = (timer_pct > 0.5) and 1.0 or (timer_pct * 2)
    lurek.render.setColor(tr, tg, 0.1, 1)
    lurek.render.drawRect("fill", bar_x + 1, bar_y + 1, (TIMER_BAR_W - 2) * timer_pct, TIMER_BAR_H - 2)
    -- Label
    lurek.render.setColor(1, 1, 1, 0.8)
    lurek.render.print("TIME", bar_x - 40, bar_y, 1)

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 0.8)
end

-- ---------------------------------------------------------------------------
-- lurek.keypressed — discrete key events
-- ---------------------------------------------------------------------------
function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
end
