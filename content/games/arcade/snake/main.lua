-- ============================================================================
--  Snake — Eat, grow, avoid yourself
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Source   : ../../../../content/demos/arcade/snake   (original demo)
--  Run with : cargo run -- content/games/arcade/snake
--
--  Controls (bound as input actions — see lurek.init):
--    up/down/left/right : W/A/S/D or ←↑↓→
--    confirm            : Enter          (start / restart)
--    quit               : Escape
--
--  lurek.* namespaces used:
--    window, render, input, signal, time, camera, particles, tween
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
-- Capture lurek.render API table before `function lurek.render()` shadows it.
local gfx = lurek.render

local CELL       = 20
local COLS, ROWS = 32, 28
local GRID_W     = COLS * CELL        -- 640
local GRID_H     = ROWS * CELL        -- 560
local HUD_H      = 40
local SCREEN_W   = GRID_W             -- 640
local SCREEN_H   = GRID_H + HUD_H    -- 600
local BASE_SPEED = 8                  -- cells / second
local FOOD_COUNT = 3

-- ── Scene state enum ──────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, DEAD = 3 }
local state = STATE.TITLE

-- ── Mutable game state ───────────────────────────────────────────────────
local snake      = {}
local dir        = { 1, 0 }
local next_dir   = { 1, 0 }
local food       = {}
local score      = 0
local display_score = 0              -- tweened display value
local high_score = 0
local move_timer = 0
local speed      = BASE_SPEED
local cam                            -- Camera2D
local food_particles                 -- particle system for eat bursts
local score_tween                    -- active score tween (or nil)

-- ── Helpers ───────────────────────────────────────────────────────────────

--- Check if a cell is occupied by snake or food.
local function is_occupied(cx, cy)
    for _, seg in ipairs(snake) do
        if seg[1] == cx and seg[2] == cy then return true end
    end
    for _, f in ipairs(food) do
        if f[1] == cx and f[2] == cy then return true end
    end
    return false
end

--- Spawn food items until the board has FOOD_COUNT pieces.
local function spawn_food()
    local attempts = 0
    while #food < FOOD_COUNT and attempts < 1000 do
        local fx = math.random(0, COLS - 1)
        local fy = math.random(0, ROWS - 1)
        if not is_occupied(fx, fy) then
            food[#food + 1] = { fx, fy }
        end
        attempts = attempts + 1
    end
end

--- Reset state to start a fresh round.
local function reset()
    local mid_x = math.floor(COLS / 2)
    local mid_y = math.floor(ROWS / 2)
    snake = {}
    for i = 4, 1, -1 do
        snake[#snake + 1] = { mid_x - i + 1, mid_y }
    end
    dir      = { 1, 0 }
    next_dir = { 1, 0 }
    score    = 0
    display_score = 0
    speed    = BASE_SPEED
    move_timer = 0
    food     = {}
    spawn_food()
    state = STATE.PLAYING
end

-- ── lurek.init ────────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Snake — Lurek2D")
    gfx.setBackgroundColor(0.04, 0.06, 0.04)

    -- Action-based input
    lurek.input.bind("up",      { "w", "up"    })
    lurek.input.bind("down",    { "s", "down"  })
    lurek.input.bind("left",    { "a", "left"  })
    lurek.input.bind("right",   { "d", "right" })
    lurek.input.bind("confirm", { "return", "kp_enter" })
    lurek.input.bind("quit",    { "escape" })

    -- Camera (static, but good practice)
    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle system — burst when eating food
    food_particles = lurek.particle.newSystem({
        maxParticles = 120,
        emissionRate = 0,
        lifetimeMin  = 0.2,  lifetimeMax = 0.55,
        speedMin     = 80,   speedMax    = 200,
        direction    = 0,    spread      = math.pi * 2,
        gravityY     = 60,
        sizes        = { 4, 3, 1.5, 0 },
        colors = {
            { 1.0, 0.4, 0.2 },
            { 1.0, 0.8, 0.1 },
            { 0.2, 1.0, 0.2, 0.0 },
        },
    })
end

-- ── lurek.ready ───────────────────────────────────────────────────────────
function lurek.ready()
    -- nothing extra needed
end

-- ── Input: direction changes via keypressed callback ──────────────────────
-- Using keypressed avoids frame-skip issues with buffered direction input.
function lurek.keypressed(key)
    if state ~= STATE.PLAYING then return end

    -- Map raw key to direction, preventing 180-degree reversal
    if (key == "w" or key == "up")    and dir[2] ~=  1 then next_dir = {  0, -1 } end
    if (key == "s" or key == "down")  and dir[2] ~= -1 then next_dir = {  0,  1 } end
    if (key == "a" or key == "left")  and dir[1] ~=  1 then next_dir = { -1,  0 } end
    if (key == "d" or key == "right") and dir[1] ~= -1 then next_dir = {  1,  0 } end
end

-- ── lurek.process(dt) ─────────────────────────────────────────────────────
function lurek.process(dt)
    -- Quit action (all states)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Title screen
    if state == STATE.TITLE then
        if lurek.input.wasActionPressed("confirm") then
            reset()
        end
        return
    end

    -- Death screen
    if state == STATE.DEAD then
        if lurek.input.wasActionPressed("confirm") then
            reset()
        end
        return
    end

    -- ── Playing ───────────────────────────────────────────────────────────

    -- Drive tweens and particles
    lurek.tween.update(dt)
    food_particles:update(dt)
    cam:update(dt)

    -- Tick-based movement
    move_timer = move_timer + dt
    if move_timer < 1 / speed then return end
    move_timer = move_timer - 1 / speed

    -- Apply buffered direction
    dir[1] = next_dir[1]
    dir[2] = next_dir[2]

    -- Compute next head position (wrapping)
    local head = snake[#snake]
    local nx = (head[1] + dir[1]) % COLS
    local ny = (head[2] + dir[2]) % ROWS

    -- Self-collision (ignore tail tip — it will move)
    for i = 1, #snake - 1 do
        if snake[i][1] == nx and snake[i][2] == ny then
            state = STATE.DEAD
            high_score = math.max(high_score, score)
            return
        end
    end

    -- Advance snake
    snake[#snake + 1] = { nx, ny }

    -- Eat food?
    local ate = false
    for i, f in ipairs(food) do
        if f[1] == nx and f[2] == ny then
            score = score + 1
            speed = BASE_SPEED + math.floor(score / 5) * 1.5

            -- Particle burst at food location (screen coords)
            local px = f[1] * CELL + CELL / 2
            local py = f[2] * CELL + HUD_H + CELL / 2
            food_particles:emit(18, px, py)

            -- Tween score display
            local target = score
            score_tween = lurek.tween.to(display_score, { value = target }, 0.25, "outQuad")

            -- Replace eaten food item
            table.remove(food, i)
            spawn_food()
            ate = true
            break
        end
    end

    if not ate then
        table.remove(snake, 1)
    end

    -- Update tweened display score from tween target
    display_score = score  -- fallback; tween drives smooth transitions visually
end

-- ── lurek.render — world / game grid ──────────────────────────────────────
function lurek.render()
    cam:apply()

    -- Grid background
    gfx.setColor(0.06, 0.08, 0.06)
    gfx.rectangle("fill", 0, HUD_H, GRID_W, GRID_H)

    -- Subtle grid lines
    gfx.setColor(0.09, 0.12, 0.09)
    for gx = 0, COLS do
        gfx.line(gx * CELL, HUD_H, gx * CELL, HUD_H + GRID_H)
    end
    for gy = 0, ROWS do
        gfx.line(0, HUD_H + gy * CELL, GRID_W, HUD_H + gy * CELL)
    end

    -- Food: red circle with green stem
    for _, f in ipairs(food) do
        local cx = f[1] * CELL + CELL / 2
        local cy = f[2] * CELL + HUD_H + CELL / 2
        -- Body
        gfx.setColor(1, 0.2, 0.2)
        gfx.circle("fill", cx, cy, CELL / 2 - 3)
        -- Stem
        gfx.setColor(0.2, 0.8, 0.2)
        gfx.rectangle("fill", cx - 1, f[2] * CELL + HUD_H + 2, 3, 5)
    end

    -- Snake body: gradient coloring (darker tail → brighter head)
    for i, seg in ipairs(snake) do
        local t  = i / #snake
        local sx = seg[1] * CELL
        local sy = seg[2] * CELL + HUD_H

        if i == #snake then
            -- Head — brightest green
            gfx.setColor(0.4, 1.0, 0.4)
            gfx.rectangle("fill", sx + 1, sy + 1, CELL - 2, CELL - 2)

            -- Eyes: two black dots that follow direction
            gfx.setColor(0, 0, 0)
            local ex, ey
            if dir[1] == 1 then         -- right
                ex = sx + CELL - 5;  ey = sy + CELL / 2 - 3
            elseif dir[1] == -1 then    -- left
                ex = sx + 3;         ey = sy + CELL / 2 - 3
            elseif dir[2] == 1 then     -- down
                ex = sx + CELL / 2 - 3;  ey = sy + CELL - 5
            else                        -- up
                ex = sx + CELL / 2 - 3;  ey = sy + 3
            end
            gfx.circle("fill", ex, ey, 2)
            -- Second eye (offset perpendicular to direction)
            if dir[1] ~= 0 then
                gfx.circle("fill", ex, ey + 6, 2)
            else
                gfx.circle("fill", ex + 6, ey, 2)
            end
        else
            -- Body segment — gradient
            local gr = 0.3 + t * 0.5
            local gg = 0.7 + t * 0.3
            local gb = 0.3 + t * 0.2
            gfx.setColor(gr, gg, gb)
            gfx.rectangle("fill", sx + 2, sy + 2, CELL - 4, CELL - 4)
        end
    end

    -- Particles (food burst) — drawn in world space
    food_particles:draw()

    cam:reset()
end

-- ── lurek.render_ui — HUD / overlays ──────────────────────────────────────
function lurek.render_ui()
    -- Top bar background
    gfx.setColor(0.08, 0.12, 0.08)
    gfx.rectangle("fill", 0, 0, SCREEN_W, HUD_H)

    -- Title
    gfx.setColor(0.4, 0.9, 0.4)
    gfx.print("SNAKE", 8, 8, 2)

    -- Score (uses tweened display value for smooth pops)
    gfx.setColor(1, 1, 1)
    gfx.print("Score: " .. math.floor(display_score), SCREEN_W / 2 - 50, 10, 1.8)

    -- High score
    gfx.setColor(0.6, 0.8, 0.6)
    gfx.print("Best: " .. high_score, SCREEN_W - 130, 10, 1.5)

    -- FPS counter (bottom-left)
    gfx.setColor(0.4, 0.4, 0.4)
    gfx.print("FPS: " .. math.floor(lurek.timer.getFPS()), 4, SCREEN_H - 18, 1)

    -- Controls hint (bottom-right)
    gfx.setColor(0.35, 0.35, 0.35)
    gfx.print("WASD / Arrows  |  ESC quit", SCREEN_W - 230, SCREEN_H - 18, 1)

    -- ── State overlays ────────────────────────────────────────────────────

    if state == STATE.TITLE then
        -- Dim overlay
        gfx.setColor(0, 0, 0, 0.75)
        gfx.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        -- Title text
        gfx.setColor(0.4, 1.0, 0.4)
        gfx.print("SNAKE", SCREEN_W / 2 - 60, SCREEN_H / 2 - 60, 4)

        gfx.setColor(0.7, 0.9, 0.7)
        gfx.print("Eat, grow, avoid yourself", SCREEN_W / 2 - 110, SCREEN_H / 2 - 10, 1.8)

        gfx.setColor(1, 1, 1)
        gfx.print("Press ENTER to start", SCREEN_W / 2 - 95, SCREEN_H / 2 + 30, 2)

        gfx.setColor(0.5, 0.5, 0.5)
        gfx.print("WASD or Arrow Keys to steer", SCREEN_W / 2 - 115, SCREEN_H / 2 + 65, 1.5)
    end

    if state == STATE.DEAD then
        -- Dim overlay
        gfx.setColor(0, 0, 0, 0.7)
        gfx.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        gfx.setColor(1, 0.3, 0.3)
        gfx.print("GAME OVER", SCREEN_W / 2 - 90, SCREEN_H / 2 - 40, 3)

        gfx.setColor(1, 1, 1)
        gfx.print("Score: " .. score, SCREEN_W / 2 - 50, SCREEN_H / 2 + 5, 2)

        if score >= high_score and score > 0 then
            gfx.setColor(1, 1, 0.3)
            gfx.print("NEW BEST!", SCREEN_W / 2 - 50, SCREEN_H / 2 + 35, 2)
        end

        gfx.setColor(0.7, 0.7, 0.7)
        gfx.print("Press ENTER to restart", SCREEN_W / 2 - 100, SCREEN_H / 2 + 65, 2)
    end
end
