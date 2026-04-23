-- ============================================================================
--  Pac-Man — Navigate a maze, eat dots, avoid ghosts
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Run with : cargo run -- content/games/arcade/pac_man
--
--  Controls (bound as input actions — see lurek.init):
--    up/down/left/right : W/S/A/D or ↑/↓/←/→
--    confirm            : Enter  (title screen)
--    restart             : R     (game over only)
--    quit               : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Screen & grid constants ───────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local TILE = 18
local COLS, ROWS = 28, 31
local MAZE_W = COLS * TILE
local MAZE_H = ROWS * TILE
local OFFSET_X = math.floor((SCREEN_W - MAZE_W) / 2)
local OFFSET_Y = math.floor((SCREEN_H - MAZE_H) / 2) + 14

-- ── Scene state enum ──────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local game_state = STATE.TITLE

-- ── Directions ────────────────────────────────────────────────────────────
local DIR = {
    NONE  = 0,
    UP    = 1,
    DOWN  = 2,
    LEFT  = 3,
    RIGHT = 4,
}
local DIR_DX = { [0]=0, [1]=0,  [2]=0,  [3]=-1, [4]=1 }
local DIR_DY = { [0]=0, [1]=-1, [2]=1,  [3]=0,  [4]=0 }

-- ── Maze layout (28×31) ──────────────────────────────────────────────────
-- W = wall, . = dot, O = power pellet, - = ghost gate, E = empty, T = tunnel
local MAZE_DEF = {
    "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
    "W............WW............W",
    "W.WWWW.WWWWW.WW.WWWWW.WWWWW",
    "WOWWWW.WWWWW.WW.WWWWW.WWWWW",
    "W.WWWW.WWWWW.WW.WWWWW.WWWWW",
    "W..........................W",
    "W.WWWW.WW.WWWWWWWW.WW.WWWWW",
    "W.WWWW.WW.WWWWWWWW.WW.WWWWW",
    "W......WW....WW....WW......W",
    "WWWWWW.WWWWWEWWEEWWWWW.WWWWWW",
    "WWWWWW.WWWWWEWWEEWWWWW.WWWWWW",
    "WWWWWW.WWEEEEEEEEEEWW.WWWWWW",
    "WWWWWW.WWEWWWW--WWWEWW.WWWWWW",
    "WWWWWW.WWEWWEEEEEEWWEWW.WWWWWW",
    "TEEEEEEEEEWWEEEEEEWWEEEEEEEEET",
    "WWWWWW.WWEWWEEEEEEWWEWW.WWWWWW",
    "WWWWWW.WWEWWWWWWWWWWEWW.WWWWWW",
    "WWWWWW.WWEEEEEEEEEEWW.WWWWWW",
    "WWWWWW.WWEWWWWWWWWEWW.WWWWWW",
    "WWWWWW.WWEWWWWWWWWEWW.WWWWWW",
    "W............WW............W",
    "W.WWWW.WWWWW.WW.WWWWW.WWWWW",
    "W.WWWW.WWWWW.WW.WWWWW.WWWWW",
    "WO..WW.......EE.......WW..OW",
    "WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
    "WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
    "W......WW....WW....WW......W",
    "W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
    "W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
    "W..........................W",
    "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
}

-- ── Parse maze into runtime grid ──────────────────────────────────────────
local maze = {}          -- maze[row][col] = char
local total_dots = 0

local function build_maze()
    maze = {}
    total_dots = 0
    for r = 1, ROWS do
        maze[r] = {}
        local line = MAZE_DEF[r]
        for c = 1, COLS do
            local ch = line:sub(c, c)
            maze[r][c] = ch
            if ch == "." or ch == "O" then
                total_dots = total_dots + 1
            end
        end
    end
end

local function is_wall(col, row)
    if row < 1 or row > ROWS then return true end
    -- Tunnel wrap
    if col < 1 or col > COLS then return false end
    local ch = maze[row][col]
    return ch == "W"
end

local function is_gate(col, row)
    if row < 1 or row > ROWS or col < 1 or col > COLS then return false end
    return maze[row][col] == "-"
end

-- ── Colors ────────────────────────────────────────────────────────────────
local WALL_COLOR       = { 0.15, 0.15, 0.85 }
local DOT_COLOR        = { 1.0,  0.85, 0.6  }
local PELLET_COLOR     = { 1.0,  0.85, 0.6  }
local PAC_COLOR        = { 1.0,  1.0,  0.0  }
local GHOST_COLORS     = {
    { 1.0, 0.0, 0.0 },   -- Blinky (red)
    { 1.0, 0.7, 0.8 },   -- Pinky  (pink)
    { 0.0, 1.0, 1.0 },   -- Inky   (cyan)
    { 1.0, 0.6, 0.0 },   -- Clyde  (orange)
}
local GHOST_NAMES      = { "Blinky", "Pinky", "Inky", "Clyde" }
local FRIGHTENED_COLOR = { 0.2, 0.2, 1.0 }

-- ── Pac-Man state ─────────────────────────────────────────────────────────
local pac = {
    col = 14, row = 24,      -- grid position (1-based)
    dir = DIR.LEFT,
    next_dir = DIR.LEFT,
    move_timer = 0,
    move_speed = 0.12,       -- seconds per tile
    mouth_open = true,
    mouth_timer = 0,
}

-- ── Ghost state ───────────────────────────────────────────────────────────
local ghosts = {}
local GHOST_START = {
    { col = 14, row = 12 },  -- Blinky
    { col = 13, row = 15 },  -- Pinky
    { col = 14, row = 15 },  -- Inky
    { col = 15, row = 15 },  -- Clyde
}
local SCATTER_TARGETS = {
    { col = 26, row = 1  },
    { col = 3,  row = 1  },
    { col = 26, row = 31 },
    { col = 3,  row = 31 },
}

-- ── Mode timers ───────────────────────────────────────────────────────────
local mode_timer = 0
local mode_index = 1
local MODE_DURATIONS = { 7, 20, 7, 20, 5, 20, 5 } -- scatter, chase, scatter, ...
local current_mode = "scatter"  -- "scatter" | "chase"

-- Frightened mode
local frightened_timer = 0
local FRIGHTENED_DURATION = 6

-- ── Score / lives / level ─────────────────────────────────────────────────
local score = 0
local lives = 3
local level = 1
local dots_eaten = 0
local ghost_eat_combo = 0  -- 200, 400, 800, 1600 progression

-- ── Visual effects ────────────────────────────────────────────────────────
local sparks         = nil   -- particle system for dot pickup
local ghost_burst    = nil   -- particle system for ghost eaten
local pellet_scale   = 1.0  -- tween-driven pulsing
local pellet_tween   = nil
local score_pop_val  = 0    -- floating score text
local score_pop_x    = 0
local score_pop_y    = 0
local score_pop_alpha = 0

-- Title animation
local title_blink = 0

-- Camera
local cam = nil

-- ── Distance helpers ──────────────────────────────────────────────────────
local function dist_sq(c1, r1, c2, r2)
    return (c1 - c2) * (c1 - c2) + (r1 - r2) * (r1 - r2)
end

local function opposite_dir(d)
    if d == DIR.UP    then return DIR.DOWN  end
    if d == DIR.DOWN  then return DIR.UP    end
    if d == DIR.LEFT  then return DIR.RIGHT end
    if d == DIR.RIGHT then return DIR.LEFT  end
    return DIR.NONE
end

-- ── Can a ghost move into a tile? ─────────────────────────────────────────
local function ghost_can_move(col, row, ghost_idx, allow_gate)
    if row < 1 or row > ROWS then return true end -- tunnel row
    if col < 1 or col > COLS then return true end -- tunnel col
    if is_wall(col, row) then return false end
    if is_gate(col, row) then return allow_gate or false end
    return true
end

-- ── Choose best direction toward target (greedy, no backtracking) ─────────
local function choose_ghost_dir(g, target_col, target_row, allow_gate)
    local dirs = { DIR.UP, DIR.LEFT, DIR.DOWN, DIR.RIGHT }
    local best_dir = g.dir
    local best_dist = math.huge
    local opp = opposite_dir(g.dir)

    for _, d in ipairs(dirs) do
        if d ~= opp then
            local nc = g.col + DIR_DX[d]
            local nr = g.row + DIR_DY[d]
            if ghost_can_move(nc, nr, g.idx, allow_gate) then
                local dd = dist_sq(nc, nr, target_col, target_row)
                if dd < best_dist then
                    best_dist = dd
                    best_dir = d
                end
            end
        end
    end
    return best_dir
end

-- ── Ghost AI: choose target based on personality ──────────────────────────
local function ghost_target(g)
    if g.frightened then
        -- Random movement during frightened
        return math.random(1, COLS), math.random(1, ROWS)
    end

    if current_mode == "scatter" then
        local st = SCATTER_TARGETS[g.idx]
        return st.col, st.row
    end

    -- Chase mode
    if g.idx == 1 then
        -- Blinky: targets pac-man directly
        return pac.col, pac.row

    elseif g.idx == 2 then
        -- Pinky: targets 4 tiles ahead of pac-man
        local tc = pac.col + DIR_DX[pac.dir] * 4
        local tr = pac.row + DIR_DY[pac.dir] * 4
        return tc, tr

    elseif g.idx == 3 then
        -- Inky: target = 2 tiles ahead of pac-man, then doubled vector from Blinky
        local ahead_c = pac.col + DIR_DX[pac.dir] * 2
        local ahead_r = pac.row + DIR_DY[pac.dir] * 2
        local blinky = ghosts[1]
        local tc = ahead_c + (ahead_c - blinky.col)
        local tr = ahead_r + (ahead_r - blinky.row)
        return tc, tr

    else
        -- Clyde: chases when far (>8 tiles), scatters when close
        local d = dist_sq(g.col, g.row, pac.col, pac.row)
        if d > 64 then
            return pac.col, pac.row
        else
            local st = SCATTER_TARGETS[4]
            return st.col, st.row
        end
    end
end

-- ── Initialize ghosts ─────────────────────────────────────────────────────
local function init_ghosts()
    ghosts = {}
    for i = 1, 4 do
        ghosts[i] = {
            idx = i,
            col = GHOST_START[i].col,
            row = GHOST_START[i].row,
            dir = DIR.UP,
            move_timer = 0,
            move_speed = 0.15 - (level - 1) * 0.005,
            frightened = false,
            eaten = false,
            in_house = (i > 1),    -- only Blinky starts outside
            house_timer = (i - 1) * 3, -- staggered release
        }
        if ghosts[i].move_speed < 0.06 then
            ghosts[i].move_speed = 0.06
        end
    end
end

-- ── Reset positions after death ───────────────────────────────────────────
local function reset_positions()
    pac.col = 14
    pac.row = 24
    pac.dir = DIR.LEFT
    pac.next_dir = DIR.LEFT
    pac.move_timer = 0
    pac.mouth_open = true
    pac.mouth_timer = 0

    for i = 1, 4 do
        ghosts[i].col = GHOST_START[i].col
        ghosts[i].row = GHOST_START[i].row
        ghosts[i].dir = DIR.UP
        ghosts[i].move_timer = 0
        ghosts[i].frightened = false
        ghosts[i].eaten = false
        ghosts[i].in_house = (i > 1)
        ghosts[i].house_timer = (i - 1) * 2
    end

    mode_timer = 0
    mode_index = 1
    current_mode = "scatter"
    frightened_timer = 0
    ghost_eat_combo = 0
end

-- ── Start new game ────────────────────────────────────────────────────────
local function start_game()
    build_maze()
    score = 0
    lives = 3
    level = 1
    dots_eaten = 0
    ghost_eat_combo = 0
    pellet_scale = 1.0
    score_pop_alpha = 0
    reset_positions()
    init_ghosts()
    game_state = STATE.PLAYING
end

-- ── Start next level ──────────────────────────────────────────────────────
local function next_level()
    level = level + 1
    build_maze()
    dots_eaten = 0
    ghost_eat_combo = 0
    reset_positions()
    init_ghosts()
end

-- ── Activate frightened mode ──────────────────────────────────────────────
local function activate_frightened()
    frightened_timer = FRIGHTENED_DURATION
    ghost_eat_combo = 0
    for i = 1, 4 do
        if not ghosts[i].eaten then
            ghosts[i].frightened = true
            ghosts[i].dir = opposite_dir(ghosts[i].dir)
        end
    end
end

-- ── Pixel position of a tile center ───────────────────────────────────────
local function tile_px(col, row)
    return OFFSET_X + (col - 0.5) * TILE,
           OFFSET_Y + (row - 0.5) * TILE
end

-- ===========================================================================
--  lurek.init — runs ONCE before the window opens
-- ===========================================================================
function lurek.init()
    lurek.window.setTitle("Pac-Man — Lurek2D")
    lurek.render.setBackgroundColor(0, 0, 0)

    -- Action-based input bindings
    lurek.input.bind("up",      { "w", "up"    })
    lurek.input.bind("down",    { "s", "down"  })
    lurek.input.bind("left",    { "a", "left"  })
    lurek.input.bind("right",   { "d", "right" })
    lurek.input.bind("confirm", { "return", "kp_enter" })
    lurek.input.bind("restart", { "r" })
    lurek.input.bind("quit",    { "escape" })

    -- Dot pickup sparkle particles
    sparks = lurek.particle.newSystem({
        maxParticles = 200,
        emissionRate = 0,
        lifetimeMin  = 0.15, lifetimeMax = 0.4,
        speedMin     = 30,   speedMax    = 80,
        direction    = 0,    spread      = math.pi * 2,
        sizes        = { 2, 1.5, 0.5 },
        colors = {
            { 1.0, 1.0, 0.7 },
            { 1.0, 0.9, 0.3, 0.0 },
        },
    })

    -- Ghost eaten burst particles
    ghost_burst = lurek.particle.newSystem({
        maxParticles = 150,
        emissionRate = 0,
        lifetimeMin  = 0.2, lifetimeMax = 0.6,
        speedMin     = 60,  speedMax    = 180,
        direction    = 0,   spread      = math.pi * 2,
        gravityY     = 80,
        sizes        = { 5, 3, 1 },
        colors = {
            { 0.3, 0.3, 1.0 },
            { 1.0, 1.0, 1.0 },
            { 0.2, 0.2, 1.0, 0.0 },
        },
    })

    -- Power pellet pulsing tween (loops)
    pellet_tween = lurek.tween.to(
        { val = 1.0 },
        { val = 1.6 },
        0.5,
        "inOutSine"
    )

    -- Camera (identity — no scrolling, but required per spec)
    cam = lurek.camera.new(SCREEN_W / 2, SCREEN_H / 2)

    -- Build initial maze
    build_maze()
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

    -- Update particles always
    if sparks     then sparks:update(dt) end
    if ghost_burst then ghost_burst:update(dt) end
    lurek.tween.update(dt)

    -- Score pop fade
    if score_pop_alpha > 0 then
        score_pop_alpha = score_pop_alpha - dt * 1.5
        score_pop_y = score_pop_y - dt * 40
    end

    -- Pellet pulse (manual sine since tween loop is limited)
    pellet_scale = 1.0 + 0.5 * math.abs(math.sin(lurek.timer.getTime() * 4))

    -- Title blink timer
    title_blink = title_blink + dt

    -- ── TITLE STATE ───────────────────────────────────────────────────
    if game_state == STATE.TITLE then
        if lurek.input.wasActionPressed("confirm") then
            start_game()
        end
        return
    end

    -- ── GAME OVER STATE ───────────────────────────────────────────────
    if game_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("restart") then
            start_game()
        end
        return
    end

    -- ── PLAYING STATE ─────────────────────────────────────────────────

    -- Read directional input
    if lurek.input.wasActionPressed("up")    then pac.next_dir = DIR.UP    end
    if lurek.input.wasActionPressed("down")  then pac.next_dir = DIR.DOWN  end
    if lurek.input.wasActionPressed("left")  then pac.next_dir = DIR.LEFT  end
    if lurek.input.wasActionPressed("right") then pac.next_dir = DIR.RIGHT end

    -- Mode switching (scatter ↔ chase)
    if frightened_timer <= 0 then
        mode_timer = mode_timer + dt
        if mode_index <= #MODE_DURATIONS and mode_timer >= MODE_DURATIONS[mode_index] then
            mode_timer = 0
            mode_index = mode_index + 1
            current_mode = (current_mode == "scatter") and "chase" or "scatter"
            -- Reverse all ghost directions on mode switch
            for i = 1, 4 do
                if not ghosts[i].eaten then
                    ghosts[i].dir = opposite_dir(ghosts[i].dir)
                end
            end
        end
    else
        -- Frightened countdown
        frightened_timer = frightened_timer - dt
        if frightened_timer <= 0 then
            frightened_timer = 0
            for i = 1, 4 do
                ghosts[i].frightened = false
            end
        end
    end

    -- ── Pac-Man movement ──────────────────────────────────────────────
    pac.move_timer = pac.move_timer + dt
    if pac.move_timer >= pac.move_speed then
        pac.move_timer = pac.move_timer - pac.move_speed

        -- Try turning to desired direction first
        local nc = pac.col + DIR_DX[pac.next_dir]
        local nr = pac.row + DIR_DY[pac.next_dir]
        if not is_wall(nc, nr) and not is_gate(nc, nr) then
            pac.dir = pac.next_dir
        end

        -- Move in current direction
        local fc = pac.col + DIR_DX[pac.dir]
        local fr = pac.row + DIR_DY[pac.dir]

        -- Tunnel wrap
        if fc < 1 then fc = COLS end
        if fc > COLS then fc = 1 end

        if not is_wall(fc, fr) and not is_gate(fc, fr) then
            pac.col = fc
            pac.row = fr
        end

        -- Mouth animation
        pac.mouth_open = not pac.mouth_open
    end

    -- ── Dot eating ────────────────────────────────────────────────────
    local tile = maze[pac.row] and maze[pac.row][pac.col]
    if tile == "." then
        maze[pac.row][pac.col] = "E"
        score = score + 10
        dots_eaten = dots_eaten + 1
        -- Sparkle
        local px, py = tile_px(pac.col, pac.row)
        if sparks then sparks:emit(3, px, py) end

    elseif tile == "O" then
        maze[pac.row][pac.col] = "E"
        score = score + 50
        dots_eaten = dots_eaten + 1
        activate_frightened()
        -- Sparkle (larger burst)
        local px, py = tile_px(pac.col, pac.row)
        if sparks then sparks:emit(8, px, py) end
    end

    -- Level complete?
    if dots_eaten >= total_dots then
        next_level()
        return
    end

    -- ── Ghost movement ────────────────────────────────────────────────
    for i = 1, 4 do
        local g = ghosts[i]

        -- Release from ghost house
        if g.in_house then
            g.house_timer = g.house_timer - dt
            if g.house_timer <= 0 then
                g.in_house = false
                g.col = 14
                g.row = 12
                g.dir = DIR.LEFT
            end
        end

        if not g.in_house then
            local spd = g.move_speed
            if g.frightened then spd = spd * 1.8 end  -- slower when frightened
            if g.eaten then spd = spd * 0.4 end       -- fast return to house

            g.move_timer = g.move_timer + dt
            if g.move_timer >= spd then
                g.move_timer = g.move_timer - spd

                if g.eaten then
                    -- Return to ghost house
                    local home = GHOST_START[i]
                    if g.col == home.col and g.row == home.row then
                        g.eaten = false
                        g.frightened = false
                        g.in_house = false
                    else
                        g.dir = choose_ghost_dir(g, home.col, home.row, true)
                    end
                else
                    local tc, tr = ghost_target(g)
                    g.dir = choose_ghost_dir(g, tc, tr, false)
                end

                -- Move
                local nc = g.col + DIR_DX[g.dir]
                local nr = g.row + DIR_DY[g.dir]
                -- Tunnel wrap
                if nc < 1 then nc = COLS end
                if nc > COLS then nc = 1 end
                if nr >= 1 and nr <= ROWS then
                    g.col = nc
                    g.row = nr
                end
            end
        end

        -- ── Ghost ↔ Pac-Man collision ─────────────────────────────────
        if not g.in_house and g.col == pac.col and g.row == pac.row then
            if g.frightened and not g.eaten then
                -- Eat the ghost!
                g.eaten = true
                ghost_eat_combo = ghost_eat_combo + 1
                local pts = 200 * math.pow(2, ghost_eat_combo - 1)
                if pts > 1600 then pts = 1600 end
                score = score + pts

                -- Ghost eaten burst
                local px, py = tile_px(g.col, g.row)
                if ghost_burst then ghost_burst:emit(20, px, py) end

                -- Score pop
                score_pop_val = pts
                score_pop_x = px
                score_pop_y = py
                score_pop_alpha = 1.0

            elseif not g.eaten then
                -- Pac-Man dies
                lives = lives - 1
                if lives <= 0 then
                    game_state = STATE.GAME_OVER
                else
                    reset_positions()
                end
                return
            end
        end
    end
end

-- ===========================================================================
--  Drawing helpers
-- ===========================================================================

--- Draw pac-man as a circle with a wedge mouth
local function draw_pacman(cx, cy)
    local r = TILE * 0.45
    local segments = 20
    local mouth_angle = pac.mouth_open and 0.6 or 0.05

    -- Determine facing angle
    local facing = 0
    if pac.dir == DIR.UP    then facing = -math.pi / 2
    elseif pac.dir == DIR.DOWN  then facing = math.pi / 2
    elseif pac.dir == DIR.LEFT  then facing = math.pi
    end

    lurek.render.setColor(PAC_COLOR[1], PAC_COLOR[2], PAC_COLOR[3])

    -- Draw as filled triangle fan (circle with wedge cut out)
    local start_a = facing + mouth_angle
    local end_a   = facing + math.pi * 2 - mouth_angle
    local step    = (end_a - start_a) / segments

    for s = 0, segments - 1 do
        local a1 = start_a + s * step
        local a2 = start_a + (s + 1) * step
        local x1 = cx + math.cos(a1) * r
        local y1 = cy + math.sin(a1) * r
        local x2 = cx + math.cos(a2) * r
        local y2 = cy + math.sin(a2) * r
        lurek.render.triangle("fill", cx, cy, x1, y1, x2, y2)
    end
end

--- Draw a ghost body with eyes
local function draw_ghost(g)
    local px, py = tile_px(g.col, g.row)
    local half = TILE * 0.45
    local color

    if g.eaten then
        -- Only draw eyes for eaten ghosts
        color = nil
    elseif g.frightened then
        -- Flash white near end of frightened
        if frightened_timer < 2 and math.floor(frightened_timer * 4) % 2 == 0 then
            color = { 1.0, 1.0, 1.0 }
        else
            color = FRIGHTENED_COLOR
        end
    else
        color = GHOST_COLORS[g.idx]
    end

    if color then
        -- Body rectangle
        lurek.render.setColor(color[1], color[2], color[3])
        lurek.render.rectangle("fill", px - half, py - half, half * 2, half * 1.7)
        -- Rounded top (approximate with a circle segment)
        lurek.render.circle("fill", px, py - half * 0.3, half)
        -- Wavy bottom (3 bumps)
        local bw = half * 2 / 3
        for b = 0, 2 do
            local bx = px - half + b * bw + bw / 2
            local by = py + half * 0.7
            lurek.render.circle("fill", bx, by, bw / 2.2)
        end
    end

    -- Eyes (always visible)
    local eye_off_x = half * 0.3
    local eye_r = half * 0.25
    local pupil_r = half * 0.12

    -- Eye direction offset for pupils
    local pdx = DIR_DX[g.dir] * pupil_r * 0.8
    local pdy = DIR_DY[g.dir] * pupil_r * 0.8

    -- Left eye
    lurek.render.setColor(1, 1, 1)
    lurek.render.circle("fill", px - eye_off_x, py - half * 0.2, eye_r)
    lurek.render.setColor(0.1, 0.1, 0.8)
    lurek.render.circle("fill", px - eye_off_x + pdx, py - half * 0.2 + pdy, pupil_r)

    -- Right eye
    lurek.render.setColor(1, 1, 1)
    lurek.render.circle("fill", px + eye_off_x, py - half * 0.2, eye_r)
    lurek.render.setColor(0.1, 0.1, 0.8)
    lurek.render.circle("fill", px + eye_off_x + pdx, py - half * 0.2 + pdy, pupil_r)
end

-- ===========================================================================
--  lurek.render — draw the WORLD (maze, characters, particles)
-- ===========================================================================
function lurek.draw()
    cam:apply()

    -- ── Draw maze walls and dots ──────────────────────────────────────
    for r = 1, ROWS do
        for c = 1, COLS do
            local ch = maze[r][c]
            local px = OFFSET_X + (c - 1) * TILE
            local py = OFFSET_Y + (r - 1) * TILE

            if ch == "W" then
                lurek.render.setColor(WALL_COLOR[1], WALL_COLOR[2], WALL_COLOR[3])
                lurek.render.rectangle("fill", px, py, TILE, TILE)
                -- Slightly brighter border for depth
                lurek.render.setColor(0.25, 0.25, 0.95)
                lurek.render.rectangle("line", px, py, TILE, TILE)

            elseif ch == "." then
                -- Small dot
                local cx = px + TILE / 2
                local cy = py + TILE / 2
                lurek.render.setColor(DOT_COLOR[1], DOT_COLOR[2], DOT_COLOR[3])
                lurek.render.circle("fill", cx, cy, 2)

            elseif ch == "O" then
                -- Power pellet (pulsing)
                local cx = px + TILE / 2
                local cy = py + TILE / 2
                lurek.render.setColor(PELLET_COLOR[1], PELLET_COLOR[2], PELLET_COLOR[3])
                lurek.render.circle("fill", cx, cy, 4 * pellet_scale)

            elseif ch == "-" then
                -- Ghost gate
                lurek.render.setColor(0.9, 0.7, 0.8)
                lurek.render.rectangle("fill", px, py + TILE / 2 - 1, TILE, 3)
            end
        end
    end

    -- ── Draw ghosts ───────────────────────────────────────────────────
    for i = 1, 4 do
        if not ghosts[i].in_house or game_state ~= STATE.PLAYING then
            draw_ghost(ghosts[i])
        end
    end

    -- ── Draw Pac-Man ──────────────────────────────────────────────────
    if game_state == STATE.PLAYING then
        local pcx, pcy = tile_px(pac.col, pac.row)
        draw_pacman(pcx, pcy)
    end

    -- ── Score pop text ────────────────────────────────────────────────
    if score_pop_alpha > 0 then
        lurek.render.setColor(1, 1, 1, score_pop_alpha)
        lurek.render.print(tostring(score_pop_val), score_pop_x - 12, score_pop_y, 1.5)
    end

    cam:reset()
end

-- ===========================================================================
--  lurek.render_ui — draw UI OVERLAY (score, lives, title, game over)
-- ===========================================================================
function lurek.draw_ui()
    -- ── TITLE SCREEN ──────────────────────────────────────────────────
    if game_state == STATE.TITLE then
        -- Game title
        lurek.render.setColor(1.0, 1.0, 0.0)
        lurek.render.print("P A C - M A N", SCREEN_W / 2 - 130, 100, 4)

        -- Ghost legend
        local legend_y = 210
        local legend_x = SCREEN_W / 2 - 120
        for i = 1, 4 do
            local gc = GHOST_COLORS[i]
            lurek.render.setColor(gc[1], gc[2], gc[3])
            lurek.render.rectangle("fill", legend_x, legend_y + (i-1) * 30, 16, 16)
            lurek.render.setColor(0.8, 0.8, 0.8)
            local desc = ""
            if i == 1 then desc = "Blinky — chases directly"
            elseif i == 2 then desc = "Pinky  — ambushes ahead"
            elseif i == 3 then desc = "Inky   — unpredictable"
            elseif i == 4 then desc = "Clyde  — shy when close"
            end
            lurek.render.print(desc, legend_x + 24, legend_y + (i-1) * 30, 1.3)
        end

        -- Blinking prompt
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1)
            lurek.render.print("PRESS ENTER TO START", SCREEN_W / 2 - 120, 380, 2)
        end

        -- Controls
        lurek.render.setColor(0.4, 0.4, 0.5)
        lurek.render.print("WASD / Arrows  Move",   SCREEN_W / 2 - 100, 440, 1.3)
        lurek.render.print("Escape         Quit",   SCREEN_W / 2 - 100, 460, 1.3)
        return
    end

    -- ── HUD: Score ────────────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1)
    lurek.render.print("SCORE", 10, 4, 1.4)
    lurek.render.print(tostring(score), 80, 4, 1.4)

    -- ── HUD: Level ────────────────────────────────────────────────────
    lurek.render.setColor(0.8, 0.8, 0.3)
    lurek.render.print("LVL " .. tostring(level), SCREEN_W / 2 - 20, 4, 1.4)

    -- ── HUD: Lives (pac-man icons) ────────────────────────────────────
    lurek.render.setColor(1, 1, 0)
    for i = 1, lives - 1 do
        local lx = SCREEN_W - 30 * i
        lurek.render.circle("fill", lx, 12, 8)
    end
    lurek.render.setColor(0.7, 0.7, 0.7)
    lurek.render.print("x" .. tostring(lives), SCREEN_W - 30 * lives - 20, 4, 1.2)

    -- ── FPS counter ───────────────────────────────────────────────────
    lurek.render.setColor(0.4, 0.4, 0.5)
    lurek.render.print("FPS: " .. math.floor(lurek.timer.getFPS()), 8, SCREEN_H - 18, 1)

    -- ── GAME OVER overlay ─────────────────────────────────────────────
    if game_state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1.0, 0.2, 0.2)
        lurek.render.print("G A M E   O V E R", SCREEN_W / 2 - 140, 200, 3)

        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Score: " .. tostring(score), SCREEN_W / 2 - 60, 280, 2)
        lurek.render.print("Level: " .. tostring(level), SCREEN_W / 2 - 60, 310, 2)

        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(0.8, 0.8, 0.8)
            lurek.render.print("PRESS R TO RESTART", SCREEN_W / 2 - 110, 380, 2)
        end
    end
end
