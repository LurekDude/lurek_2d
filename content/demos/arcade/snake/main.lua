-- Snake — Classic Arcade (Lurek2D demo)
-- Guide the snake to eat food and grow. Avoid walls and your own tail.
-- Arrow keys to change direction, game speeds up as score increases.
-- Run with: cargo run -- content/demos/arcade/snake

-- ── Constants ────────────────────────────────────────────────────────────

local CELL = 20
local COLS, ROWS = 32, 28
local W, H = COLS * CELL, ROWS * CELL + 40
local BASE_SPEED = 8   -- cells per second
local FOOD_COUNT = 3

-- ── State ────────────────────────────────────────────────────────────────

local snake = {}
local dir = {}
local next_dir = {}
local food = {}
local score = 0
local game_state = "playing" -- "playing", "dead", "start"
local move_timer = 0
local speed = BASE_SPEED
local high_score = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function occ_check(ex, ey)
    for _, seg in ipairs(snake) do
        if seg[1] == ex and seg[2] == ey then return true end
    end
    for _, f in ipairs(food) do
        if f[1] == ex and f[2] == ey then return true end
    end
    return false
end

local function spawn_food()
    food = {}
    local attempts = 0
    while #food < FOOD_COUNT and attempts < 1000 do
        local fx = math.random(0, COLS - 1)
        local fy = math.random(0, ROWS - 1)
        if not occ_check(fx, fy) then
            table.insert(food, { fx, fy })
        end
        attempts = attempts + 1
    end
end

local function reset()
    local mid_x = math.floor(COLS / 2)
    local mid_y = math.floor(ROWS / 2)
    snake = {}
    for i = 4, 1, -1 do
        table.insert(snake, { mid_x - i + 1, mid_y })
    end
    dir = { 1, 0 }
    next_dir = { 1, 0 }
    score = 0
    speed = BASE_SPEED
    move_timer = 0
    game_state = "playing"
    spawn_food()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.04, 0.06, 0.04)
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end

    move_timer = move_timer + dt
    if move_timer < 1 / speed then return end
    move_timer = move_timer - 1 / speed

    -- Apply buffered direction
    dir[1] = next_dir[1]
    dir[2] = next_dir[2]

    local head = snake[#snake]
    local nx = (head[1] + dir[1]) % COLS
    local ny = (head[2] + dir[2]) % ROWS

    -- Self collision (skip tail since tail moves)
    for i = 1, #snake - 1 do
        if snake[i][1] == nx and snake[i][2] == ny then
            game_state = "dead"
            high_score = math.max(high_score, score)
            return
        end
    end

    -- Move
    table.insert(snake, { nx, ny })

    -- Eat food
    local ate = false
    for i, f in ipairs(food) do
        if f[1] == nx and f[2] == ny then
            score = score + 1
            speed = BASE_SPEED + math.floor(score / 5) * 1.5
            table.remove(food, i)
            -- Respawn one food
            local attempts = 0
            while attempts < 200 do
                local fx = math.random(0, COLS - 1)
                local fy = math.random(0, ROWS - 1)
                if not occ_check(fx, fy) then
                    table.insert(food, { fx, fy })
                    break
                end
                attempts = attempts + 1
            end
            ate = true
            break
        end
    end

    if not ate then
        table.remove(snake, 1)
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Header
    lurek.render.setColor(0.08, 0.12, 0.08)
    lurek.render.rectangle("fill", 0, 0, W, 40)
    lurek.render.setColor(0.4, 0.9, 0.4)
    lurek.render.print("SNAKE", 8, 8, 2)
    lurek.render.setColor(1, 1, 1)
    lurek.render.print("Score: " .. score, W/2 - 50, 10, 1.8)
    lurek.render.setColor(0.6, 0.8, 0.6)
    lurek.render.print("Best: " .. high_score, W - 100, 10, 1.5)

    -- Grid background
    lurek.render.setColor(0.06, 0.08, 0.06)
    lurek.render.rectangle("fill", 0, 40, W, ROWS * CELL)

    -- Subtle grid lines
    lurek.render.setColor(0.09, 0.12, 0.09)
    for gx = 0, COLS do
        lurek.render.line(gx * CELL, 40, gx * CELL, 40 + ROWS * CELL)
    end
    for gy = 0, ROWS do
        lurek.render.line(0, 40 + gy * CELL, W, 40 + gy * CELL)
    end

    -- Food
    for _, f in ipairs(food) do
        local fx = f[1] * CELL + 3
        local fy = f[2] * CELL + 40 + 3
        lurek.render.setColor(1, 0.2, 0.2)
        lurek.render.circle("fill", f[1] * CELL + CELL/2, f[2] * CELL + 40 + CELL/2, CELL/2 - 3)
        lurek.render.setColor(0.2, 0.8, 0.2)
        lurek.render.rectangle("fill", f[1] * CELL + CELL/2 - 1, f[2] * CELL + 40 + 2, 3, 5)
    end

    -- Snake body
    for i, seg in ipairs(snake) do
        local t = i / #snake
        local gr = 0.3 + t * 0.5
        local gg = 0.7 + t * 0.3
        local gb = 0.3 + t * 0.2
        if i == #snake then
            -- Head: brighter
            lurek.render.setColor(0.4, 1.0, 0.4)
            lurek.render.rectangle("fill", seg[1]*CELL + 1, seg[2]*CELL + 40 + 1, CELL - 2, CELL - 2)
            -- Eyes
            lurek.render.setColor(0, 0, 0)
            local ex = seg[1]*CELL + (dir[1] == 1 and CELL - 5 or (dir[1] == -1 and 3 or CELL/2 - 3))
            local ey = seg[2]*CELL + 40 + (dir[2] == 1 and CELL - 5 or (dir[2] == -1 and 3 or CELL/2 - 3))
            lurek.render.circle("fill", ex, ey, 2)
        else
            lurek.render.setColor(gr, gg, gb)
            lurek.render.rectangle("fill", seg[1]*CELL + 2, seg[2]*CELL + 40 + 2, CELL - 4, CELL - 4)
        end
    end

    -- Game over overlay
    if game_state == "dead" then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 0.3, 0.3)
        lurek.render.print("GAME OVER", W/2 - 80, H/2 - 30, 3)
        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Score: " .. score, W/2 - 45, H/2 + 10, 2)
        lurek.render.setColor(0.7, 0.7, 0.7)
        lurek.render.print("Press R to restart", W/2 - 100, H/2 + 40, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then reset() end
    if game_state ~= "playing" then return end

    if key == "up"    and dir[2] ~=  1 then next_dir = { 0, -1 } end
    if key == "down"  and dir[2] ~= -1 then next_dir = { 0,  1 } end
    if key == "left"  and dir[1] ~=  1 then next_dir = {-1,  0 } end
    if key == "right" and dir[1] ~= -1 then next_dir = { 1,  0 } end
    if key == "w"     and dir[2] ~=  1 then next_dir = { 0, -1 } end
    if key == "s"     and dir[2] ~= -1 then next_dir = { 0,  1 } end
    if key == "a"     and dir[1] ~=  1 then next_dir = {-1,  0 } end
    if key == "d"     and dir[1] ~= -1 then next_dir = { 1,  0 } end
end
