-- ============================================================
-- Physics Puzzle — Drop shapes to guide ball to goal
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/physics_puzzle
-- ============================================================

local W, H = 800, 600

-- Physics world
local GRAVITY = 400

-- Shapes placed by player
local placed   = {}
local ball     = nil ---@type any
local goal     = { x = 680, y = 520, r = 20 }
local state    = "place"   -- place | simulating | win | fail
local level    = 1
local score    = 0
local preview  = { type = "plank", x = 0, y = 0, angle = 0 }

-- Particle systems
---@type LParticleSystem
local ball_trail    = nil
---@type LParticleSystem
local win_burst     = nil
---@type LParticleSystem
local bounce_sparks = nil

-- Shape types
local SHAPES = {
    plank  = { w = 100, h = 10, label = "Plank" },
    wedge  = { w = 60,  h = 60, label = "Wedge" },
    block  = { w = 40,  h = 40, label = "Block"  },
    ramp   = { w = 120, h = 14, label = "Ramp"  },
}
local SHAPE_ORDER = { "plank", "ramp", "block", "wedge" }
local shape_idx   = 1

-- Ball spawn
local BALL_START = { x = 100, y = 80, r = 14 }

local WALLS = {
    { x = 0,   y = 580, w = 800, h = 20 },  -- floor
    { x = 0,   y = 0,   w = 10,  h = 600 }, -- left
    { x = 790, y = 0,   w = 10,  h = 600 }, -- right
}

local LEVELS = {
    {
        title   = "Reach the bucket",
        spawns  = { { x = 100, y = 80 } },
        goal    = { x = 680, y = 510 },
        budgets = 4,
    },
    {
        title   = "Long drop",
        spawns  = { { x = 60, y = 60 } },
        goal    = { x = 700, y = 500 },
        budgets = 5,
    },
    {
        title   = "Tight landing",
        spawns  = { { x = 400, y = 60 } },
        goal    = { x = 100, y = 520 },
        budgets = 6,
    },
}

-- Very simple AABB + circle physics (no rapier — using Lua physics)
local sim = {}

local function reset_sim()
    local lv = LEVELS[level]
    local sp = lv.spawns[1]
    ball = { x = sp.x, y = sp.y, r = 14, vx = 0, vy = 0, on_ground = false }
    goal = { x = lv.goal.x, y = lv.goal.y, r = 22 }
    sim  = {}
    -- Add placed shapes to sim
    for _, sh in ipairs(placed) do sim[#sim + 1] = sh end
    -- Add walls to sim as static rects
    for _, w in ipairs(WALLS) do
        sim[#sim + 1] = { type = "wall", x = w.x, y = w.y, w = w.w, h = w.h, angle = 0, static = true }
    end
    state = "simulating"
end

local function collide_circle_rect(bx, by, br, rx, ry, rw, rh)
    local cx = math.max(rx, math.min(bx, rx + rw))
    local cy = math.max(ry, math.min(by, ry + rh))
    local dx, dy = bx - cx, by - cy
    local d = math.sqrt(dx*dx + dy*dy)
    if d < br then
        local nx = dx / (d + 0.001)
        local ny = dy / (d + 0.001)
        local pen = br - d
        return true, nx, ny, pen
    end
    return false
end

local function circle_goal(bx, by, br, gx, gy, gr)
    local dx, dy = bx - gx, by - gy
    return math.sqrt(dx*dx + dy*dy) < (br + gr)
end

local sim_time = 0

local function update_physics(dt)
    -- Gravity
    ball.vy = ball.vy + GRAVITY * dt
    ball.x  = ball.x  + ball.vx * dt
    ball.y  = ball.y  + ball.vy * dt

    -- Collisions
    for _, sh in ipairs(sim) do
        if sh.type ~= "wedge" then  -- simple AABB for planks/walls/blocks
            local hit, nx, ny, pen = collide_circle_rect(ball.x, ball.y, ball.r, sh.x, sh.y, sh.w or 100, sh.h or 10)
            if hit then
                ball.x = ball.x + nx * pen
                ball.y = ball.y + ny * pen
                -- Reflect velocity
                local dot = ball.vx * nx + ball.vy * ny
                ball.vx   = (ball.vx - 2 * dot * nx) * 0.7
                ball.vy   = (ball.vy - 2 * dot * ny) * 0.7
                if bounce_sparks then bounce_sparks:moveTo(ball.x, ball.y) bounce_sparks:emit(3) end
            end
        end
    end

    -- Goal check
    if circle_goal(ball.x, ball.y, ball.r, goal.x, goal.y, goal.r) then
        state = "win"
        score = score + (10 - math.floor(sim_time))
        if win_burst then win_burst:moveTo(goal.x, goal.y) win_burst:emit(30) end
        return
    end

    -- Out of bounds / fell off
    if ball.y > H + 50 then
        state = "fail"
    end

    sim_time = sim_time + dt
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("place",        "mouse1")
lurek.input.bind("rotate_cw",    "e")
lurek.input.bind("rotate_ccw",   "q")
lurek.input.bind("next_shape",   "tab")
lurek.input.bind("run",          "space")
lurek.input.bind("reset",        "r")
lurek.input.bind("next_level",   "n")
lurek.input.bind("quit",         "escape")

-- ── Init ──────────────────────────────────────────────────

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
    lurek.window.setTitle("Physics Puzzle — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.08, 0.12)
    math.randomseed(os.time())

    ball_trail = lurek.particle.newSystem({
        maxParticles = 40,
        emitRate     = 0,
        lifetime     = { 0.1, 0.3 },
        speed        = { 5, 20 },
        startColor   = { 0.4, 0.7, 1.0, 0.7 },
        endColor     = { 0.1, 0.2, 0.5, 0.0 },
        startSize    = 6, endSize = 1,
        spread       = math.pi * 2,
    })

    win_burst = lurek.particle.newSystem({
        maxParticles = 80,
        emitRate     = 0,
        lifetime     = { 0.4, 1.2 },
        speed        = { 80, 250 },
        startColor   = { 1.0, 0.9, 0.2, 1.0 },
        endColor     = { 0.8, 0.3, 0.0, 0.0 },
        startSize    = 7, endSize = 1,
        spread       = math.pi * 2,
    })

    bounce_sparks = lurek.particle.newSystem({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.1, 0.3 },
        speed        = { 30, 80 },
        startColor   = { 1.0, 0.8, 0.3, 1.0 },
        endColor     = { 0.5, 0.2, 0.0, 0.0 },
        startSize    = 3, endSize = 1,
        spread       = math.pi * 2,
    })

    local sp = LEVELS[level].spawns[1]
    ball  = { x = sp.x, y = sp.y, r = 14, vx = 0, vy = 0 }
    goal  = { x = LEVELS[level].goal.x, y = LEVELS[level].goal.y, r = 22 }
    placed = {}
    state  = "place"
end

-- ── Process ───────────────────────────────────────────────
function lurek.process(dt)
    if ball_trail    then ball_trail:update(dt)    end
    if win_burst     then win_burst:update(dt)     end
    if bounce_sparks then bounce_sparks:update(dt) end

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() return end

    local mx, my = lurek.input.mouse.getPosition()
    preview.x = mx
    preview.y = my

    if state == "win" or state == "fail" then
        if lurek.input.wasActionPressed("reset") then
            placed = {}
            state  = "place"
            sim_time = 0
        elseif state == "win" and lurek.input.wasActionPressed("next_level") then
            level   = level < #LEVELS and level + 1 or 1
            placed  = {}
            state   = "place"
            sim_time = 0
            goal    = { x = LEVELS[level].goal.x, y = LEVELS[level].goal.y, r = 22 }
        end
        return
    end

    if state == "place" then
        if lurek.input.wasActionPressed("rotate_cw")  then preview.angle = preview.angle + 15 end
        if lurek.input.wasActionPressed("rotate_ccw") then preview.angle = preview.angle - 15 end

        if lurek.input.wasActionPressed("next_shape") then
            shape_idx = (shape_idx % #SHAPE_ORDER) + 1
            preview.type = SHAPE_ORDER[shape_idx]
        end

        if lurek.input.wasActionPressed("place") then
            local lv  = LEVELS[level]
            if #placed < lv.budgets then
                local sh = SHAPES[preview.type]
                placed[#placed + 1] = {
                    type  = preview.type,
                    x     = mx - (sh.w or 60) / 2,
                    y     = my - (sh.h or 10) / 2,
                    w     = sh.w,
                    h     = sh.h,
                    angle = preview.angle,
                }
            end
        end

        if lurek.input.wasActionPressed("run") then
            sim_time = 0
            reset_sim()
        end
        return
    end

    if state == "simulating" then
        update_physics(dt)
        if ball_trail then ball_trail:moveTo(ball.x, ball.y) ball_trail:emit(1) end
    end
end

-- ── Render world ──────────────────────────────────────────
function lurek.draw()
    local lv = LEVELS[level]

    -- Walls
    for _, w in ipairs(WALLS) do
        rect(w.x, w.y, w.w, w.h, { color = {0.4,0.4,0.4,1} })
    end

    -- Goal
    circ(goal.x, goal.y, goal.r, { color = {0.2,0.8,0.3,0.8}, segments = 16 })
    text_("GOAL", goal.x - 16, goal.y - 8, { color = {1,1,1,1}, size = 11 })

    -- Ball spawn indicator
    local sp = lv.spawns[1]
    circ(sp.x, sp.y, 16, { color = {0.4,0.4,0.9,0.4}, segments = 12 })

    -- Placed shapes
    for _, sh in ipairs(placed) do
        rect(sh.x, sh.y, sh.w, sh.h, { color = {0.6,0.5,0.3,1} })
    end

    -- Preview (build mode)
    if state == "place" then
        local sh = SHAPES[preview.type]
        local px, py = preview.x - (sh.w or 60)/2, preview.y - (sh.h or 10)/2
        rect(px, py, sh.w, sh.h, { color = {0.8,0.8,0.4,0.5} })
    end

    -- Ball
    if ball then
        circ(ball.x, ball.y, ball.r, { color = {0.3,0.6,1.0,1}, segments = 12 })
    end

    if ball_trail    then ball_trail:render()    end
    if win_burst     then win_burst:render()     end
    if bounce_sparks then bounce_sparks:render() end
end

-- ── Render UI ─────────────────────────────────────────────
function lurek.draw_ui()
    local lv = LEVELS[level]
    text_("Level " .. level .. ": " .. lv.title, 14, 10, { color = {1,0.9,0.3,1}, size = 15 })
    text_("Budget: " .. #placed .. "/" .. lv.budgets, 400, 10, { color = {0.7,0.9,1.0,1}, size = 15 })
    text_("Score: " .. score, 580, 10, { color = {1,1,1,1}, size = 15 })

    if state == "place" then
        local sh = SHAPES[SHAPE_ORDER[shape_idx]]
        text_("Shape: " .. sh.label .. "  Angle: " .. preview.angle .. "°", 14, H - 38, { color = {0.7,0.7,1.0,1}, size = 13 })
        text_("LMB=place  E/Q=rotate  Tab=shape  Space=launch  R=reset", 14, H - 20, { color = {0.4,0.4,0.4,1}, size = 11 })
    elseif state == "win" then
        text_("GOAL REACHED! +pts", 270, 250, { color = {0.2,1.0,0.3,1}, size = 32 })
        text_("N=next level  R=retry", 290, 310, { color = {0.6,0.6,0.6,1}, size = 16 })
    elseif state == "fail" then
        text_("BALL LOST — R to retry", 240, 260, { color = {0.9,0.3,0.3,1}, size = 26 })
    end
end
