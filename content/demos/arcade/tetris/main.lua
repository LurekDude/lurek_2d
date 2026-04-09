-- Tetris — Classic Arcade (Luna2D demo)
-- Rotate and place falling tetrominoes, clear lines to score points.
-- Arrow keys to move/rotate, Down to soft-drop, Space to hard-drop.
-- Run with: cargo run -- demos/arcade/tetris

-- ── Constants ────────────────────────────────────────────────────────────

local COLS, ROWS = 10, 20
local CELL = 28
local BOARD_X = (800 - COLS * CELL) / 2
local BOARD_Y = 40
local W, H = 800, 600

local PIECES = {
    { cells = {{0,0},{1,0},{2,0},{3,0}}, color = {0.0, 0.9, 0.9} }, -- I
    { cells = {{0,0},{1,0},{2,0},{2,1}}, color = {0.0, 0.4, 0.9} }, -- J
    { cells = {{0,0},{1,0},{2,0},{0,1}}, color = {1.0, 0.6, 0.0} }, -- L
    { cells = {{0,0},{1,0},{0,1},{1,1}}, color = {0.9, 0.9, 0.0} }, -- O
    { cells = {{1,0},{2,0},{0,1},{1,1}}, color = {0.0, 0.9, 0.3} }, -- S
    { cells = {{0,0},{1,0},{2,0},{1,1}}, color = {0.6, 0.0, 0.9} }, -- T
    { cells = {{0,0},{1,0},{1,1},{2,1}}, color = {0.9, 0.1, 0.1} }, -- Z
}

-- ── State ────────────────────────────────────────────────────────────────

local board = {}
local piece, next_piece
local piece_x, piece_y
local score, lines_cleared, level = 0, 0, 1
local drop_timer, drop_interval
local game_over = false
local lock_timer = 0
local LINE_SCORES = { 100, 300, 500, 800 }

-- ── Helpers ──────────────────────────────────────────────────────────────

local function new_board()
    board = {}
    for y = 1, ROWS do
        board[y] = {}
        for x = 1, COLS do board[y][x] = nil end
    end
end

local function rotate(cells)
    -- 90° clockwise: (x,y) → (max_y - y, x)
    local max_y = 0
    for _, c in ipairs(cells) do max_y = math.max(max_y, c[2]) end
    local r = {}
    for _, c in ipairs(cells) do r[#r+1] = { max_y - c[2], c[1] } end
    return r
end

local function collides(cells, ox, oy)
    for _, c in ipairs(cells) do
        local x, y = c[1] + ox, c[2] + oy
        if x < 0 or x >= COLS or y >= ROWS then return true end
        if y >= 0 and board[y+1][x+1] then return true end
    end
    return false
end

local function lock_piece()
    for _, c in ipairs(piece.cells) do
        local x, y = c[1] + piece_x, c[2] + piece_y
        if y < 0 then game_over = true; return end
        board[y+1][x+1] = piece.color
    end
    -- Clear full lines
    local cleared = 0
    local y = ROWS
    while y >= 1 do
        local full = true
        for x = 1, COLS do if not board[y][x] then full = false; break end end
        if full then
            table.remove(board, y)
            table.insert(board, 1, {})
            for x = 1, COLS do board[1][x] = nil end
            cleared = cleared + 1
        else
            y = y - 1
        end
    end
    if cleared > 0 then
        score = score + (LINE_SCORES[cleared] or 800) * level
        lines_cleared = lines_cleared + cleared
        level = math.floor(lines_cleared / 10) + 1
        drop_interval = math.max(0.08, 0.5 - (level - 1) * 0.04)
    end
end

local function spawn_piece()
    piece = next_piece or PIECES[math.random(#PIECES)]
    next_piece = PIECES[math.random(#PIECES)]
    piece_x = math.floor(COLS / 2) - 1
    piece_y = -1
    drop_timer = 0
    lock_timer = 0
    if collides(piece.cells, piece_x, piece_y) then game_over = true end
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0.05, 0.05, 0.1)
    new_board()
    score = 0; lines_cleared = 0; level = 1
    drop_interval = 0.5
    game_over = false
    next_piece = PIECES[math.random(#PIECES)]
    spawn_piece()
end

-- ── Update ───────────────────────────────────────────────────────────────

local move_repeat_timer = 0
local move_dir = 0

function luna.process(dt)
    if game_over then return end

    -- Soft drop
    local fast = luna.input.isKeyDown("down")
    local effective_dt = fast and dt * 10 or dt

    drop_timer = drop_timer + effective_dt
    if drop_timer >= drop_interval then
        drop_timer = 0
        if not collides(piece.cells, piece_x, piece_y + 1) then
            piece_y = piece_y + 1
        else
            lock_timer = lock_timer + drop_interval
            if lock_timer >= 0.5 then
                lock_piece()
                if not game_over then spawn_piece() end
            end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

local function draw_cell(x, y, color, alpha)
    local px = BOARD_X + x * CELL
    local py = BOARD_Y + y * CELL
    luna.gfx.setColor(color[1], color[2], color[3], alpha or 1)
    luna.gfx.rectangle("fill", px+1, py+1, CELL-2, CELL-2)
    luna.gfx.setColor(color[1]*1.4, color[2]*1.4, color[3]*1.4, alpha or 1)
    luna.gfx.rectangle("line", px+1, py+1, CELL-2, CELL-2)
end

function luna.render()
    -- Board border
    luna.gfx.setColor(0.3, 0.3, 0.5)
    luna.gfx.rectangle("line", BOARD_X - 1, BOARD_Y - 1, COLS * CELL + 2, ROWS * CELL + 2)

    -- Grid ghost
    luna.gfx.setColor(0.12, 0.12, 0.18)
    for y = 0, ROWS - 1 do
        for x = 0, COLS - 1 do
            luna.gfx.rectangle("line", BOARD_X + x*CELL + 1, BOARD_Y + y*CELL + 1, CELL - 2, CELL - 2)
        end
    end

    -- Placed cells
    for y = 1, ROWS do
        for x = 1, COLS do
            if board[y][x] then
                draw_cell(x - 1, y - 1, board[y][x])
            end
        end
    end

    -- Ghost (drop preview)
    local ghost_y = piece_y
    while not collides(piece.cells, piece_x, ghost_y + 1) do ghost_y = ghost_y + 1 end
    for _, c in ipairs(piece.cells) do
        local cx, cy = c[1] + piece_x, c[2] + ghost_y
        if cy >= 0 then
            draw_cell(cx, cy, piece.color, 0.25)
        end
    end

    -- Active piece
    for _, c in ipairs(piece.cells) do
        local cx, cy = c[1] + piece_x, c[2] + piece_y
        if cy >= 0 then draw_cell(cx, cy, piece.color) end
    end

    -- Sidebar info
    local sx = BOARD_X + COLS * CELL + 20
    luna.gfx.setColor(0.7, 0.7, 0.9)
    luna.gfx.print("SCORE",  sx, BOARD_Y + 10, 1.5)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print(tostring(score), sx, BOARD_Y + 28, 1.8)
    luna.gfx.setColor(0.7, 0.7, 0.9)
    luna.gfx.print("LEVEL", sx, BOARD_Y + 65, 1.5)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print(tostring(level), sx, BOARD_Y + 82, 2)
    luna.gfx.setColor(0.7, 0.7, 0.9)
    luna.gfx.print("LINES", sx, BOARD_Y + 115, 1.5)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print(tostring(lines_cleared), sx, BOARD_Y + 132, 2)
    luna.gfx.setColor(0.7, 0.7, 0.9)
    luna.gfx.print("NEXT",  sx, BOARD_Y + 165, 1.5)
    if next_piece then
        for _, c in ipairs(next_piece.cells) do
            draw_cell(-1 + c[1] + math.floor((COLS + 12.5) / CELL), c[2] + 11, next_piece.color)
        end
        for _, c in ipairs(next_piece.cells) do
            local px2 = sx + c[1] * CELL
            local py2 = BOARD_Y + 180 + c[2] * CELL
            luna.gfx.setColor(next_piece.color[1], next_piece.color[2], next_piece.color[3])
            luna.gfx.rectangle("fill", px2+1, py2+1, CELL-2, CELL-2)
        end
    end

    -- Controls
    luna.gfx.setColor(0.4, 0.4, 0.5)
    luna.gfx.print("←→  Move",   sx, H - 110, 1.2)
    luna.gfx.print("↑   Rotate", sx, H - 95,  1.2)
    luna.gfx.print("↓   Soft",   sx, H - 80,  1.2)
    luna.gfx.print("SPC Hard",   sx, H - 65,  1.2)
    luna.gfx.print("ESC Quit",   sx, H - 50,  1.2)

    -- Game over overlay
    if game_over then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.2, 0.2)
        luna.gfx.print("GAME OVER", W/2 - 80, H/2 - 20, 3)
        luna.gfx.setColor(0.7, 0.7, 0.7)
        luna.gfx.print("Score: " .. score, W/2 - 50, H/2 + 20, 2)
        luna.gfx.print("Press R to restart", W/2 - 100, H/2 + 50, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" and game_over then luna.signal.restart() end
    if game_over then return end

    if key == "left" then
        if not collides(piece.cells, piece_x - 1, piece_y) then piece_x = piece_x - 1 end
    elseif key == "right" then
        if not collides(piece.cells, piece_x + 1, piece_y) then piece_x = piece_x + 1 end
    elseif key == "up" then
        local r = rotate(piece.cells)
        if not collides(r, piece_x, piece_y) then
            piece.cells = r
        elseif not collides(r, piece_x + 1, piece_y) then
            piece.cells = r; piece_x = piece_x + 1
        elseif not collides(r, piece_x - 1, piece_y) then
            piece.cells = r; piece_x = piece_x - 1
        end
    elseif key == "space" then
        while not collides(piece.cells, piece_x, piece_y + 1) do
            piece_y = piece_y + 1
        end
        lock_piece()
        if not game_over then spawn_piece() end
    end
end
