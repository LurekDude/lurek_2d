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

-- ============================================================================
--  Tetris — Rotate and stack falling tetrominoes
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Source   : ../../../../content/demos/arcade/tetris   (original demo)
--  Run with : cargo run -- content/games/arcade/tetris
--
--  Controls (bound as input actions — see lurek.init):
--    left/right : A/D or ←/→
--    rotate     : W / ↑
--    soft_drop  : S / ↓  (hold)
--    hard_drop  : Space
--    hold       : C  (swap current piece with hold slot)
--    restart    : R  (game over only)
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween
-- ============================================================================

-- ── Game-wide constants ───────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local COLS, ROWS          = 10, 20
local CELL                = 28
local BOARD_X             = math.floor((SCREEN_W - COLS * CELL) / 2)
local BOARD_Y             = 40

-- ── Scene state enum ──────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local state = STATE.TITLE

-- ── Tetromino definitions ─────────────────────────────────────────────────
local PIECES = {
    { cells = {{0,0},{1,0},{2,0},{3,0}}, color = {0.0, 0.9, 0.9} }, -- I
    { cells = {{0,0},{1,0},{2,0},{2,1}}, color = {0.0, 0.4, 0.9} }, -- J
    { cells = {{0,0},{1,0},{2,0},{0,1}}, color = {1.0, 0.6, 0.0} }, -- L
    { cells = {{0,0},{1,0},{0,1},{1,1}}, color = {0.9, 0.9, 0.0} }, -- O
    { cells = {{1,0},{2,0},{0,1},{1,1}}, color = {0.0, 0.9, 0.3} }, -- S
    { cells = {{0,0},{1,0},{2,0},{1,1}}, color = {0.6, 0.0, 0.9} }, -- T
    { cells = {{0,0},{1,0},{1,1},{2,1}}, color = {0.9, 0.1, 0.1} }, -- Z
}

local PIECE_NAMES = { "I", "J", "L", "O", "S", "T", "Z" }
local LINE_SCORES = { 100, 300, 500, 800 }

-- ── Mutable game state ───────────────────────────────────────────────────
local board = {}
local piece, next_piece
local piece_x, piece_y
local score, lines_cleared, level
local drop_timer, drop_interval
local lock_timer
local hold_piece       = nil   -- held piece (swap with C)
local hold_used        = false -- can only hold once per spawn

-- Visual effects
local sparks                   -- particle system for line clears
local flash_alpha      = 0     -- screen flash on line clear
local flash_tween      = nil   -- tween driving flash_alpha
local flash_state      = { val = 0 }
local shake_offset_x   = 0     -- screen shake offset
local shake_offset_y   = 0
local shake_tween      = nil
local shake_state      = { x = 0, y = 0 }

-- Title screen animation
local title_blink      = 0

-- ── Deep-copy a cells table ───────────────────────────────────────────────
local function copy_cells(cells)
    local r = {}
    for i, c in ipairs(cells) do r[i] = { c[1], c[2] } end
    return r
end

-- ── Deep-copy a piece definition ──────────────────────────────────────────
local function copy_piece(p)
    return { cells = copy_cells(p.cells), color = { p.color[1], p.color[2], p.color[3] } }
end

-- ── Board helpers ─────────────────────────────────────────────────────────
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
    for _, c in ipairs(cells) do r[#r + 1] = { max_y - c[2], c[1] } end
    return r
end

local function collides(cells, ox, oy)
    for _, c in ipairs(cells) do
        local x, y = c[1] + ox, c[2] + oy
        if x < 0 or x >= COLS or y >= ROWS then return true end
        if y >= 0 and board[y + 1][x + 1] then return true end
    end
    return false
end

local function ghost_y()
    local gy = piece_y
    while not collides(piece.cells, piece_x, gy + 1) do gy = gy + 1 end
    return gy
end

-- ── Line clearing with effects ────────────────────────────────────────────
local function clear_lines()
    local cleared = 0
    local y = ROWS
    while y >= 1 do
        local full = true
        for x = 1, COLS do
            if not board[y][x] then full = false; break end
        end
        if full then
            -- Emit particles along the cleared row
            if sparks then
                local row_y = BOARD_Y + (y - 1) * CELL + CELL / 2
                for x = 0, COLS - 1 do
                    local px = BOARD_X + x * CELL + CELL / 2
                    sparks:moveTo(px, row_y)
                    sparks:emit(3)
                end
            end
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

        -- Flash effect
        flash_state.val = 0.6
        flash_alpha = 0.6
        flash_tween = lurek.tween.to(
            flash_state,
            { val = 0 },
            0.3,
            "outQuad"
        )

        -- Shake effect
        shake_state.x = 4
        shake_state.y = 2
        shake_offset_x = 4
        shake_offset_y = 2
        shake_tween = lurek.tween.to(
            shake_state,
            { x = 0, y = 0 },
            0.25,
            "outElastic"
        )
    end
    return cleared
end

-- ── Lock the active piece into the board ──────────────────────────────────
local function lock_piece_fn()
    for _, c in ipairs(piece.cells) do
        local x, y = c[1] + piece_x, c[2] + piece_y
        if y < 0 then
            state = STATE.GAME_OVER
            return
        end
        board[y + 1][x + 1] = piece.color
    end
    clear_lines()
    hold_used = false  -- allow hold again after locking
end

-- ── Spawn next piece ──────────────────────────────────────────────────────
local function spawn_piece()
    piece = copy_piece(next_piece or PIECES[math.random(#PIECES)])
    next_piece = copy_piece(PIECES[math.random(#PIECES)])
    piece_x = math.floor(COLS / 2) - 1
    piece_y = -1
    drop_timer = 0
    lock_timer = 0
    if collides(piece.cells, piece_x, piece_y) then
        state = STATE.GAME_OVER
    end
end

-- ── Reset game ────────────────────────────────────────────────────────────
local function reset_game()
    new_board()
    score         = 0
    lines_cleared = 0
    level         = 1
    drop_interval = 0.5
    hold_piece    = nil
    hold_used     = false
    flash_alpha   = 0
    flash_state.val = 0
    shake_offset_x = 0
    shake_offset_y = 0
    shake_state.x = 0
    shake_state.y = 0
    next_piece = copy_piece(PIECES[math.random(#PIECES)])
    spawn_piece()
    state = STATE.PLAYING
end

-- ── Draw a single cell (used for board, active piece, ghost, sidebar) ─────
local function draw_cell(x, y, color, alpha)
    local px = BOARD_X + x * CELL
    local py = BOARD_Y + y * CELL
    lurek.render.setColor(color[1], color[2], color[3], alpha or 1)
    rect("fill", px + 1, py + 1, CELL - 2, CELL - 2)
    -- Highlight border
    lurek.render.setColor(
        math.min(1, color[1] * 1.4),
        math.min(1, color[2] * 1.4),
        math.min(1, color[3] * 1.4),
        alpha or 1
    )
    rect("line", px + 1, py + 1, CELL - 2, CELL - 2)
end

-- ── Draw a piece preview at arbitrary pixel position ──────────────────────
local function draw_piece_preview(p, px, py)
    if not p then return end
    for _, c in ipairs(p.cells) do
        local cx = px + c[1] * CELL
        local cy = py + c[2] * CELL
        lurek.render.setColor(p.color[1], p.color[2], p.color[3])
        rect("fill", cx + 1, cy + 1, CELL - 2, CELL - 2)
        lurek.render.setColor(
            math.min(1, p.color[1] * 1.4),
            math.min(1, p.color[2] * 1.4),
            math.min(1, p.color[3] * 1.4)
        )
        rect("line", cx + 1, cy + 1, CELL - 2, CELL - 2)
    end
end

-- ===========================================================================
--  lurek.init — runs ONCE before the window opens
-- ===========================================================================

function lurek.init()
    lurek.window.setTitle("Tetris — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.1)

    -- Action-based input bindings
    lurek.input.bind("left",      { "a", "left"  })
    lurek.input.bind("right",     { "d", "right" })
    lurek.input.bind("rotate",    { "w", "up"    })
    lurek.input.bind("soft_drop", { "s", "down"  })
    lurek.input.bind("hard_drop", { "space"      })
    lurek.input.bind("hold",      { "c"          })
    lurek.input.bind("confirm",   { "return", "kp_enter" })
    lurek.input.bind("restart",   { "r"          })
    lurek.input.bind("quit",      { "escape"     })

    -- Particle system for line-clear sparkles
    sparks = lurek.particle.newSystem({
        maxParticles  = 300,
        emissionRate  = 0,
        lifetimeMin   = 0.3,  lifetimeMax = 0.9,
        speedMin      = 80,   speedMax    = 220,
        direction     = 0,    spread      = math.pi,
        gravityY      = 200,
        sizes         = { 4, 3, 1.5, 0.5 },
        colors = {
            { 1.0, 1.0, 0.7 },
            { 1.0, 0.8, 0.2 },
            { 0.8, 0.3, 0.0, 0.0 },
        },
    })

    -- Initialize game state
    new_board()
    score         = 0
    lines_cleared = 0
    level         = 1
    drop_interval = 0.5
end

-- ===========================================================================
--  lurek.process(dt) — gameplay logic, called every frame
-- ===========================================================================
function lurek.process(dt)
    -- Global quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Update tweens every frame (all states — flash may linger into game-over)
    lurek.tween.update(dt)

    -- Update flash/shake values from tweens
    flash_alpha = flash_state.val
    shake_offset_x = shake_state.x
    shake_offset_y = shake_state.y

    -- Update particles
    if sparks then sparks:update(dt) end

    -- Title screen blink
    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("confirm") then
            reset_game()
        end
        return
    end

    -- Game over — wait for restart
    if state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("restart") then
            reset_game()
        end
        return
    end

    -- ── PLAYING state ─────────────────────────────────────────────────
    -- Rotation with wall kicks
    if lurek.input.wasActionPressed("rotate") then
        local r = rotate(piece.cells)
        if not collides(r, piece_x, piece_y) then
            piece.cells = r
        elseif not collides(r, piece_x + 1, piece_y) then
            piece.cells = r; piece_x = piece_x + 1
        elseif not collides(r, piece_x - 1, piece_y) then
            piece.cells = r; piece_x = piece_x - 1
        end
    end

    -- Horizontal movement
    if lurek.input.wasActionPressed("left") then
        if not collides(piece.cells, piece_x - 1, piece_y) then
            piece_x = piece_x - 1
        end
    end
    if lurek.input.wasActionPressed("right") then
        if not collides(piece.cells, piece_x + 1, piece_y) then
            piece_x = piece_x + 1
        end
    end

    -- Hold piece (swap with hold slot)
    if lurek.input.wasActionPressed("hold") and not hold_used then
        hold_used = true
        if hold_piece then
            local tmp = hold_piece
            hold_piece = copy_piece(piece)
            piece = tmp
            piece_x = math.floor(COLS / 2) - 1
            piece_y = -1
            drop_timer = 0
            lock_timer = 0
        else
            hold_piece = copy_piece(piece)
            spawn_piece()
        end
    end

    -- Hard drop
    if lurek.input.wasActionPressed("hard_drop") then
        piece_y = ghost_y()
        lock_piece_fn()
        if state == STATE.PLAYING then spawn_piece() end
        return
    end

    -- Gravity / soft drop
    local fast = lurek.input.isActionDown("soft_drop")
    local effective_dt = fast and dt * 10 or dt

    drop_timer = drop_timer + effective_dt
    if drop_timer >= drop_interval then
        drop_timer = 0
        if not collides(piece.cells, piece_x, piece_y + 1) then
            piece_y = piece_y + 1
            lock_timer = 0
        else
            lock_timer = lock_timer + drop_interval
            if lock_timer >= 0.5 then
                lock_piece_fn()
                if state == STATE.PLAYING then spawn_piece() end
            end
        end
    end
end

-- ===========================================================================
--  lurek.render — draw the WORLD (board, pieces, particles)
-- ===========================================================================
function lurek.draw()
    -- Apply screen shake offset
    local sx_off = math.floor(shake_offset_x * math.sin(lurek.timer.getTime() * 60))
    local sy_off = math.floor(shake_offset_y * math.cos(lurek.timer.getTime() * 47))

    -- Board border
    lurek.render.setColor(0.3, 0.3, 0.5)
    rect("line",
        BOARD_X - 1 + sx_off, BOARD_Y - 1 + sy_off,
        COLS * CELL + 2, ROWS * CELL + 2)

    -- Grid background
    lurek.render.setColor(0.12, 0.12, 0.18)
    for y = 0, ROWS - 1 do
        for x = 0, COLS - 1 do
            rect("line",
                BOARD_X + x * CELL + 1 + sx_off,
                BOARD_Y + y * CELL + 1 + sy_off,
                CELL - 2, CELL - 2)
        end
    end

    -- Placed cells
    for y = 1, ROWS do
        for x = 1, COLS do
            if board[y][x] then
                local px = BOARD_X + (x - 1) * CELL + sx_off
                local py = BOARD_Y + (y - 1) * CELL + sy_off
                local c = board[y][x]
                lurek.render.setColor(c[1], c[2], c[3])
                rect("fill", px + 1, py + 1, CELL - 2, CELL - 2)
                lurek.render.setColor(
                    math.min(1, c[1] * 1.4),
                    math.min(1, c[2] * 1.4),
                    math.min(1, c[3] * 1.4))
                rect("line", px + 1, py + 1, CELL - 2, CELL - 2)
            end
        end
    end

    if state == STATE.PLAYING then
        -- Ghost piece (drop preview at 25% alpha)
        local gy = ghost_y()
        for _, c in ipairs(piece.cells) do
            local cx, cy = c[1] + piece_x, c[2] + gy
            if cy >= 0 then
                local px = BOARD_X + cx * CELL + sx_off
                local py = BOARD_Y + cy * CELL + sy_off
                lurek.render.setColor(piece.color[1], piece.color[2], piece.color[3], 0.25)
                rect("fill", px + 1, py + 1, CELL - 2, CELL - 2)
            end
        end

        -- Active piece
        for _, c in ipairs(piece.cells) do
            local cx, cy = c[1] + piece_x, c[2] + piece_y
            if cy >= 0 then
                local px = BOARD_X + cx * CELL + sx_off
                local py = BOARD_Y + cy * CELL + sy_off
                lurek.render.setColor(piece.color[1], piece.color[2], piece.color[3])
                rect("fill", px + 1, py + 1, CELL - 2, CELL - 2)
                lurek.render.setColor(
                    math.min(1, piece.color[1] * 1.4),
                    math.min(1, piece.color[2] * 1.4),
                    math.min(1, piece.color[3] * 1.4))
                rect("line", px + 1, py + 1, CELL - 2, CELL - 2)
            end
        end
    end

    -- Particles (line-clear sparkles)
    -- sparks:render() handled automatically by the particle system

    -- Line-clear flash overlay
    if flash_alpha > 0.01 then
        lurek.render.setColor(1, 1, 1, flash_alpha)
        rect("fill", BOARD_X, BOARD_Y, COLS * CELL, ROWS * CELL)
    end
end

-- ===========================================================================
--  lurek.render_ui — draw UI OVERLAY (score, next, hold, controls, menus)
-- ===========================================================================
function lurek.draw_ui()
    local sx = BOARD_X + COLS * CELL + 24

    if state == STATE.TITLE then
        -- Title screen
        lurek.render.setColor(0.0, 0.9, 0.9)
        text_("T E T R I S", SCREEN_W / 2 - 100, 180, 4)

        lurek.render.setColor(0.7, 0.7, 0.9)
        text_("Rotate and stack falling tetrominoes", SCREEN_W / 2 - 160, 240, 1.5)

        -- Blinking "press enter"
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1)
            text_("PRESS ENTER TO START", SCREEN_W / 2 - 120, 340, 2)
        end

        -- Controls preview
        lurek.render.setColor(0.4, 0.4, 0.5)
        text_("←→ / AD   Move",     200, 430, 1.3)
        text_("↑  / W    Rotate",    200, 450, 1.3)
        text_("↓  / S    Soft drop", 200, 470, 1.3)
        text_("Space     Hard drop", 200, 490, 1.3)
        text_("C         Hold",      200, 510, 1.3)
        text_("Escape    Quit",      200, 530, 1.3)
        return
    end

    -- ── Sidebar: Score / Level / Lines ────────────────────────────────
    lurek.render.setColor(0.7, 0.7, 0.9)
    text_("SCORE", sx, BOARD_Y + 10, 1.5)
    lurek.render.setColor(1, 1, 1)
    text_(tostring(score), sx, BOARD_Y + 30, 1.8)

    lurek.render.setColor(0.7, 0.7, 0.9)
    text_("LEVEL", sx, BOARD_Y + 70, 1.5)
    lurek.render.setColor(1, 1, 1)
    text_(tostring(level), sx, BOARD_Y + 90, 2)

    lurek.render.setColor(0.7, 0.7, 0.9)
    text_("LINES", sx, BOARD_Y + 130, 1.5)
    lurek.render.setColor(1, 1, 1)
    text_(tostring(lines_cleared), sx, BOARD_Y + 150, 2)

    -- ── Sidebar: Next piece preview ──────────────────────────────────
    lurek.render.setColor(0.7, 0.7, 0.9)
    text_("NEXT", sx, BOARD_Y + 195, 1.5)
    draw_piece_preview(next_piece, sx, BOARD_Y + 215)

    -- ── Sidebar: Hold piece preview ──────────────────────────────────
    lurek.render.setColor(0.7, 0.7, 0.9)
    text_("HOLD", sx, BOARD_Y + 300, 1.5)
    if hold_piece then
        draw_piece_preview(hold_piece, sx, BOARD_Y + 320)
    else
        lurek.render.setColor(0.3, 0.3, 0.4)
        text_("(empty)", sx, BOARD_Y + 325, 1.2)
    end

    -- ── Sidebar: Controls ────────────────────────────────────────────
    lurek.render.setColor(0.4, 0.4, 0.5)
    text_("←→  Move",      sx, SCREEN_H - 140, 1.2)
    text_("↑   Rotate",    sx, SCREEN_H - 125, 1.2)
    text_("↓   Soft drop", sx, SCREEN_H - 110, 1.2)
    text_("SPC Hard drop", sx, SCREEN_H - 95,  1.2)
    text_("C   Hold",      sx, SCREEN_H - 80,  1.2)
    text_("ESC Quit",      sx, SCREEN_H - 65,  1.2)

    -- ── Left sidebar: FPS ────────────────────────────────────────────
    lurek.render.setColor(0.4, 0.4, 0.5)
    text_("FPS: " .. math.floor(lurek.timer.getFPS()), 8, SCREEN_H - 20, 1)

    -- ── Game over overlay ────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.7)
        rect("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1, 0.2, 0.2)
        text_("GAME OVER", SCREEN_W / 2 - 90, SCREEN_H / 2 - 40, 3.5)

        lurek.render.setColor(1, 1, 1)
        text_("Score: " .. score, SCREEN_W / 2 - 60, SCREEN_H / 2 + 10, 2)
        text_("Level: " .. level, SCREEN_W / 2 - 60, SCREEN_H / 2 + 35, 2)
        text_("Lines: " .. lines_cleared, SCREEN_W / 2 - 60, SCREEN_H / 2 + 60, 2)

        lurek.render.setColor(0.7, 0.7, 0.7)
        text_("Press R to restart", SCREEN_W / 2 - 100, SCREEN_H / 2 + 100, 2)
    end
end
