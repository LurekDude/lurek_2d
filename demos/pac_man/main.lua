-- Pac-Man — Classic Arcade (Luna2D demo)
-- Navigate the maze, eat all dots, avoid the 4 ghosts.
-- Power pellets let you eat ghosts for 8 seconds.

-- ── Constants ────────────────────────────────────────────────────────────

local CELL = 20
local COLS, ROWS = 21, 21
local W, H = COLS * CELL, ROWS * CELL + 60

local DIR = { up = {0,-1}, down = {0,1}, left = {-1,0}, right = {1,0} }
local GHOST_COLORS = { {1,0.2,0.2}, {1,0.7,0.8}, {0.1,0.8,1}, {1,0.6,0.1} }
local POWER_TIME = 8.0

-- ── Maze layout (1=wall, 0=dot, 2=power pellet, 3=empty) ─────────────────

local MAP_TEMPLATE = {
    "111111111111111111111",
    "100000000010000000001",
    "101110111010110111101",
    "121110111010110111121",
    "101110111010110111101",
    "100000000000000000001",
    "101110101111101011101",
    "101110101111101011101",
    "100000100000001000001",
    "111110111333111011111",
    "111110100333001011111",
    "111110103333310011111",
    "111110103333310111111",
    "111110100333001011111",
    "111110111333111011111",
    "100000000000000000001",
    "101110111010110111101",
    "101110111010110111101",
    "120010000030000001021",
    "111010101111101010111",
    "111111111111111111111",
}

-- ── State ────────────────────────────────────────────────────────────────

local map = {}
local pac = {}
local ghosts = {}
local score, lives, level = 0, 3, 1
local dots_left = 0
local power_timer = 0
local game_state = "playing" -- "playing", "dead", "win"
local dead_timer = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function to_px(cx, cy) return cx * CELL + CELL/2, cy * CELL + CELL/2 + 30 end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function cell_walkable(cx, cy)
    if cx < 0 or cy < 0 or cx >= COLS or cy >= ROWS then return false end
    return map[cy+1] and map[cy+1][cx+1] ~= 1
end

local function build_map()
    map = {}
    dots_left = 0
    for y, row in ipairs(MAP_TEMPLATE) do
        map[y] = {}
        for x = 1, #row do
            local c = row:sub(x, x)
            local v = tonumber(c) or 1
            map[y][x] = v
            if v == 0 or v == 2 then dots_left = dots_left + 1 end
        end
    end
end

local function move_entity(e, dt)
    local nx = e.x + e.dx * e.speed * dt
    local ny = e.y + e.dy * e.speed * dt
    local hcx = math.floor((nx + (e.dx >= 0 and CELL - 2 or 1)) / CELL)
    local hcy = math.floor((ny + (e.dy >= 0 and CELL - 2 or 1)) / CELL)
    if cell_walkable(hcx, math.floor(e.y / CELL)) then e.x = nx end
    if cell_walkable(math.floor(e.x / CELL), hcy) then e.y = ny end
    -- Wrap tunnel (row 9)
    if e.x < 0 then e.x = COLS * CELL - CELL end
    if e.x >= COLS * CELL then e.x = 0 end
end

local function ghost_ai(g, dt)
    g.timer = g.timer - dt
    if g.timer > 0 then return end
    g.timer = 0.35 + math.random() * 0.25
    local cx = math.floor(g.x / CELL)
    local cy = math.floor(g.y / CELL)
    local dirs = { {1,0}, {-1,0}, {0,1}, {0,-1} }
    -- Shuffle directions
    for i = #dirs, 2, -1 do
        local j = math.random(i)
        dirs[i], dirs[j] = dirs[j], dirs[i]
    end
    if power_timer > 0 then
        -- Scatter randomly when frightened
        for _, d in ipairs(dirs) do
            if cell_walkable(cx + d[1], cy + d[2]) then
                g.dx = d[1]; g.dy = d[2]; break
            end
        end
    else
        -- Chase pac-man roughly
        local tx = math.floor(pac.x / CELL)
        local ty = math.floor(pac.y / CELL)
        local best = math.huge
        for _, d in ipairs(dirs) do
            local nx2, ny2 = cx + d[1], cy + d[2]
            if cell_walkable(nx2, ny2) then
                local dist = (nx2 - tx)^2 + (ny2 - ty)^2
                if dist < best then best = dist; g.dx = d[1]; g.dy = d[2] end
            end
        end
    end
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.load()
    luna.graphics.setBackgroundColor(0, 0, 0)
    build_map()
    pac = { x = 10*CELL, y = 15*CELL, dx = 0, dy = 0, next_dx = 1, next_dy = 0, speed = 130 }
    ghosts = {}
    for i = 1, 4 do
        ghosts[i] = { x = (9+i)*CELL, y = 10*CELL, dx = 1, dy = 0, speed = 110, timer = i * 0.5 }
    end
    score = 0; lives = 3; power_timer = 0; game_state = "playing"
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.update(dt)
    if game_state ~= "playing" then
        if game_state == "dead" then
            dead_timer = dead_timer - dt
            if dead_timer <= 0 then
                if lives > 0 then
                    pac.x = 10*CELL; pac.y = 15*CELL
                    pac.dx = 0; pac.dy = 0
                    game_state = "playing"
                else
                    game_state = "gameover"
                end
            end
        end
        return
    end

    power_timer = math.max(0, power_timer - dt)

    -- Pac-Man input buffering
    if luna.input.isKeyDown("left")  then pac.next_dx = -1; pac.next_dy = 0 end
    if luna.input.isKeyDown("right") then pac.next_dx =  1; pac.next_dy = 0 end
    if luna.input.isKeyDown("up")    then pac.next_dx =  0; pac.next_dy = -1 end
    if luna.input.isKeyDown("down")  then pac.next_dx =  0; pac.next_dy =  1 end

    -- Try queued direction
    local ncx = math.floor(pac.x / CELL) + pac.next_dx
    local ncy = math.floor(pac.y / CELL) + pac.next_dy
    if cell_walkable(ncx, ncy) then
        pac.dx = pac.next_dx; pac.dy = pac.next_dy
    end

    move_entity(pac, dt)

    -- Eat dots
    local cx = math.floor(pac.x / CELL + 0.5)
    local cy = math.floor(pac.y / CELL + 0.5)
    if cx >= 0 and cy >= 0 and cx < COLS and cy < ROWS then
        local cell = map[cy+1] and map[cy+1][cx+1]
        if cell == 0 then map[cy+1][cx+1] = 3; score = score + 10; dots_left = dots_left - 1 end
        if cell == 2 then map[cy+1][cx+1] = 3; score = score + 50; dots_left = dots_left - 1; power_timer = POWER_TIME end
    end

    if dots_left <= 0 then game_state = "win" return end

    -- Ghost logic
    for _, g in ipairs(ghosts) do
        ghost_ai(g, dt)
        move_entity(g, dt)
        -- Collision with pac
        local dx = math.abs(g.x - pac.x)
        local dy = math.abs(g.y - pac.y)
        if dx < CELL * 0.75 and dy < CELL * 0.75 then
            if power_timer > 0 then
                score = score + 200
                g.x = 10*CELL; g.y = 10*CELL
            else
                lives = lives - 1
                game_state = "dead"
                dead_timer = 1.5
                return
            end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.draw()
    -- Header bar
    luna.graphics.setColor(0, 0, 0.3)
    luna.graphics.rectangle("fill", 0, 0, W, 30)
    luna.graphics.setColor(1, 1, 0)
    luna.graphics.print("Score: " .. score, 4, 6, 1.5)
    luna.graphics.setColor(1, 0.3, 0.3)
    luna.graphics.print("Lives: " .. lives, W - 90, 6, 1.5)

    -- Map
    for y = 1, ROWS do
        for x = 1, COLS do
            local c = map[y][x]
            local px = (x-1)*CELL
            local py = (y-1)*CELL + 30
            if c == 1 then
                luna.graphics.setColor(0.1, 0.2, 0.8)
                luna.graphics.rectangle("fill", px+1, py+1, CELL-2, CELL-2)
            elseif c == 0 then
                luna.graphics.setColor(1, 0.9, 0.6)
                luna.graphics.circle("fill", px + CELL/2, py + CELL/2, 2)
            elseif c == 2 then
                luna.graphics.setColor(1, 1, 0)
                luna.graphics.circle("fill", px + CELL/2, py + CELL/2, 5)
            end
        end
    end

    -- Pac-Man
    local pac_color = (game_state == "dead") and {1,0,0} or {1,1,0}
    luna.graphics.setColor(pac_color[1], pac_color[2], pac_color[3])
    luna.graphics.circle("fill", pac.x + CELL/2, pac.y + CELL/2 + 30, CELL/2 - 1)

    -- Ghosts
    for i, g in ipairs(ghosts) do
        if power_timer > 0 then
            luna.graphics.setColor(0.1, 0.1, 0.8)
        else
            local c = GHOST_COLORS[i]
            luna.graphics.setColor(c[1], c[2], c[3])
        end
        local gx = g.x + CELL/2
        local gy = g.y + CELL/2 + 30
        luna.graphics.circle("fill", gx, gy - 2, CELL/2 - 1)
        luna.graphics.rectangle("fill", g.x + 1, gy - 2, CELL - 2, CELL/2)
    end

    -- Overlays
    if game_state == "win" then
        luna.graphics.setColor(0, 0, 0, 0.65)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 1, 0)
        luna.graphics.print("LEVEL CLEAR!", W/2 - 90, H/2 - 20, 3)
        luna.graphics.setColor(0.7, 0.7, 0.7)
        luna.graphics.print("Press R to restart", W/2 - 100, H/2 + 20, 2)
    elseif game_state == "gameover" then
        luna.graphics.setColor(0, 0, 0, 0.65)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 0.2, 0.2)
        luna.graphics.print("GAME OVER", W/2 - 80, H/2 - 20, 3)
        luna.graphics.setColor(0.7, 0.7, 0.7)
        luna.graphics.print("Press R to restart", W/2 - 100, H/2 + 20, 2)
    end

    if power_timer > 0 then
        luna.graphics.setColor(0.5, 0.5, 1)
        luna.graphics.print("POWER! " .. string.format("%.1f", power_timer), W/2 - 50, H - 20, 1.5)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" and (game_state == "win" or game_state == "gameover") then
        luna.load()
    end
end
