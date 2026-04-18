-- ============================================================
-- Logic Game — Robot programming puzzle
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/logic_game
-- ============================================================

local COLS, ROWS = 10, 8
local CELL = 56
local OX   = 40  -- grid X offset
local OY   = 60  -- grid Y offset

-- Cell types
local EMPTY = 0
local WALL  = 1
local GOAL  = 2
local CRATE = 3

-- Directions
local DIR = {
    up    = { dx = 0,  dy = -1, name = "UP" },
    down  = { dx = 0,  dy = 1,  name = "DOWN" },
    left  = { dx = -1, dy = 0,  name = "LEFT" },
    right = { dx = 1,  dy = 0,  name = "RIGHT" },
}
local CMD_ORDER = { "up","down","left","right","wait" }

-- Levels
local LEVELS = {
    {
        title = "Get to the goal",
        map = {
            {1,1,1,1,1,1,1,1,1,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,1,1,1,1,1,1,1,1,1},
        },
        robot = { x = 2, y = 2 },
        goal  = { x = 8, y = 6 },
        maxCmds = 8,
    },
    {
        title = "Avoid the walls",
        map = {
            {1,1,1,1,1,1,1,1,1,1},
            {1,0,0,0,1,0,0,0,0,1},
            {1,0,1,0,1,0,1,0,0,1},
            {1,0,1,0,0,0,1,0,0,1},
            {1,0,0,0,1,0,0,0,0,1},
            {1,0,1,1,1,0,1,1,0,1},
            {1,0,0,0,0,0,0,0,0,1},
            {1,1,1,1,1,1,1,1,1,1},
        },
        robot = { x = 1, y = 1 },
        goal  = { x = 8, y = 6 },
        maxCmds = 12,
    },
}

local level_idx  = 1
local program    = {}        -- list of command strings
local robot      = {}
local goal       = {}
local grid       = {}
local running    = false
local run_timer  = 0
local run_step   = 0
local run_done   = false
local run_win    = false
local selected   = 1         -- selected program slot
local msg        = ""
local msg_timer  = 0.0

local step_particles = nil
local win_particles  = nil

local function load_level(idx)
    local lv = LEVELS[idx]
    robot = { x = lv.robot.x, y = lv.robot.y }
    goal  = { x = lv.goal.x,  y = lv.goal.y  }
    grid  = {}
    for r, row in ipairs(lv.map) do
        grid[r] = {}
        for c, val in ipairs(row) do grid[r][c] = val end
    end
    grid[goal.y][goal.x] = GOAL
    program  = {}
    for _ = 1, lv.maxCmds do program[#program + 1] = "wait" end
    running  = false
    run_done = false
    run_win  = false
    selected = 1
    msg      = ""
end

local function cell_color(v)
    if v == WALL  then return {0.3,0.3,0.3,1} end
    if v == GOAL  then return {0.2,0.8,0.4,1} end
    return {0.12,0.12,0.18,1}
end

local function set_msg(s, t) msg = s ; msg_timer = t or 2.0 end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("cmd_up",    "w")
lurek.input.bind("cmd_down",  "s")
lurek.input.bind("cmd_left",  "a")
lurek.input.bind("cmd_right", "d")
lurek.input.bind("cmd_wait",  "space")
lurek.input.bind("slot_prev", "left")
lurek.input.bind("slot_next", "right")
lurek.input.bind("run",       "return")
lurek.input.bind("reset",     "r")
lurek.input.bind("next_lvl",  "n")
lurek.input.bind("quit",      "escape")

-- ── Init ──────────────────────────────────────────────────
lurek.init(function()
    lurek.window.setTitle("Logic Game — Lurek2D")
    lurek.render.setBackgroundColor(0.06, 0.06, 0.12, 1.0)

    step_particles = lurek.particles.newSystem({
        maxParticles = 16,
        emitRate     = 0,
        lifetime     = { 0.2, 0.5 },
        speed        = { 20, 60 },
        startColor   = { 0.4, 0.8, 1.0, 1.0 },
        endColor     = { 0.2, 0.4, 0.8, 0.0 },
        startSize    = 4, endSize = 1,
        spread       = math.pi * 2,
    })

    win_particles = lurek.particles.newSystem({
        maxParticles = 80,
        emitRate     = 0,
        lifetime     = { 0.4, 1.0 },
        speed        = { 60, 200 },
        startColor   = { 1.0, 0.9, 0.2, 1.0 },
        endColor     = { 0.8, 0.3, 0.0, 0.0 },
        startSize    = 6, endSize = 1,
        spread       = math.pi * 2,
    })

    load_level(level_idx)
end)

-- ── Process ───────────────────────────────────────────────
lurek.process(function(dt)
    if step_particles then step_particles:update(dt) end
    if win_particles  then win_particles:update(dt)  end

    if msg_timer > 0 then msg_timer = msg_timer - dt end

    if lurek.input.isActionJustPressed("quit") then lurek.signal.quit() return end

    if run_done then
        if lurek.input.isActionJustPressed("reset") then
            load_level(level_idx)
        elseif run_win and lurek.input.isActionJustPressed("next_lvl") then
            level_idx = level_idx < #LEVELS and level_idx + 1 or 1
            load_level(level_idx)
        end
        return
    end

    if running then
        run_timer = run_timer - dt
        if run_timer <= 0 then
            run_timer = 0.4
            run_step  = run_step + 1
            if run_step > #program then
                running  = true
                run_done = true
                if robot.x == goal.x and robot.y == goal.y then
                    run_win = true
                    set_msg("Level complete! N=next level, R=restart", 60)
                    if win_particles then
                        win_particles:emit(OX + goal.x * CELL, OY + goal.y * CELL, 40)
                    end
                else
                    set_msg("Program ended — goal not reached. R to reset.", 60)
                end
                return
            end
            local cmd = program[run_step]
            if cmd ~= "wait" then
                local d = DIR[cmd]
                local nx, ny = robot.x + d.dx, robot.y + d.dy
                if grid[ny] and grid[ny][nx] and grid[ny][nx] ~= WALL then
                    robot.x, robot.y = nx, ny
                    if step_particles then
                        step_particles:emit(OX + robot.x * CELL + CELL/2, OY + robot.y * CELL + CELL/2, 4)
                    end
                else
                    set_msg("Blocked by wall!", 1.5)
                end
            end
        end
        return
    end

    -- Edit mode
    if lurek.input.isActionJustPressed("slot_prev") then
        selected = math.max(1, selected - 1)
    elseif lurek.input.isActionJustPressed("slot_next") then
        selected = math.min(#program, selected + 1)
    end

    local cmd_map = {
        cmd_up    = "up",
        cmd_down  = "down",
        cmd_left  = "left",
        cmd_right = "right",
        cmd_wait  = "wait",
    }
    for key, val in pairs(cmd_map) do
        if lurek.input.isActionJustPressed(key) then
            program[selected] = val
            if selected < #program then selected = selected + 1 end
        end
    end

    if lurek.input.isActionJustPressed("run") then
        running   = true
        run_timer = 0.0
        run_step  = 0
        robot     = { x = LEVELS[level_idx].robot.x, y = LEVELS[level_idx].robot.y }
    end

    if lurek.input.isActionJustPressed("reset") then
        load_level(level_idx)
    end
end)

-- ── Render world ──────────────────────────────────────────
lurek.render(function()
    -- Grid
    for r = 1, ROWS do
        for c = 1, COLS do
            local v = grid[r][c]
            local col = cell_color(v)
            lurek.render.drawRect(OX + (c-1)*CELL, OY + (r-1)*CELL, CELL-2, CELL-2, { color = col })
        end
    end
    -- Robot
    lurek.render.drawRect(OX + (robot.x-1)*CELL + 8, OY + (robot.y-1)*CELL + 8, CELL-18, CELL-18, { color = {0.3,0.7,1.0,1} })

    if step_particles then step_particles:draw() end
    if win_particles  then win_particles:draw()  end
end)

-- ── Render UI ─────────────────────────────────────────────
lurek.render_ui(function()
    local lv = LEVELS[level_idx]
    lurek.render.drawText("Level " .. level_idx .. ": " .. lv.title, 40, 14, { color = {1,0.9,0.3,1}, size = 16 })
    lurek.render.drawText("Program (" .. #program .. " slots):", 40, 520, { color = {0.7,0.7,0.9,1}, size = 14 })

    local px = 40
    for i, cmd in ipairs(program) do
        local sel  = i == selected
        local bg   = sel and {0.4,0.3,0.6,1} or {0.2,0.2,0.3,1}
        local step = running and (i == run_step)
        if step then bg = {0.7,0.5,0.1,1} end
        lurek.render.drawRect(px, 540, 48, 28, { color = bg })
        lurek.render.drawText(string.upper(cmd):sub(1,2), px+14, 548, { color = {1,1,1,1}, size = 12 })
        px = px + 52
    end

    lurek.render.drawText("W/A/S/D=set cmd  ←/→=slot  Enter=run  R=reset", 40, 578, { color = {0.4,0.4,0.4,1}, size = 11 })

    if msg_timer > 0 and msg ~= "" then
        lurek.render.drawText(msg, 40, 494, { color = {1,0.9,0.4,1}, size = 13 })
    end
end)
