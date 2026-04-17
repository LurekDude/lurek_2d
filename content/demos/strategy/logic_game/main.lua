-- Logic / Programming Puzzle — Program a robot to reach the flag
-- Run with: cargo run -- content/demos/strategy/logic_game

local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600
local TILE = 50
local GRID_X, GRID_Y = 40, 60
local COLS, COLS_MAX = 8, 8
local ROWS, ROWS_MAX = 8, 8

local CMD = { FWD = "FWD", LEFT = "LEFT", RIGHT = "RIGHT", LOOP = "LOOP" }
local CMD_LIST = { CMD.FWD, CMD.LEFT, CMD.RIGHT, CMD.LOOP }
local CMD_COLORS = {
    [CMD.FWD]  = { 0.2, 0.7, 0.3 },
    [CMD.LEFT] = { 0.3, 0.4, 0.9 },
    [CMD.RIGHT]= { 0.9, 0.5, 0.2 },
    [CMD.LOOP] = { 0.8, 0.2, 0.7 },
}

local DIR = { {0,-1}, {1,0}, {0,1}, {-1,0} } -- up, right, down, left

local levels = {}
local current_level = 1
local program = {}
local MAX_PROGRAM = 12
local executing = false
local exec_index = 1
local exec_timer = 0
local EXEC_SPEED = 0.35
local robot = { col = 1, row = 1, dir = 1, anim_x = 0, anim_y = 0 }
local goal = { col = 1, row = 1 }
local grid = {}
local level_complete = false
local loop_start = 0
local loop_count = 0
local all_done = false

local function make_grid(cols, rows, walls, start, flag)
    local g = {}
    for r = 1, rows do
        g[r] = {}
        for c = 1, cols do
            g[r][c] = 0 -- 0=floor
        end
    end
    for _, w in ipairs(walls) do
        g[w[2]][w[1]] = 1 -- 1=wall
    end
    return g, cols, rows, start, flag
end

local function build_levels()
    levels = {
        {
            name = "Level 1: Straight Path",
            build = function()
                return make_grid(5, 5, {}, {1,3}, {5,3})
            end,
        },
        {
            name = "Level 2: Turn the Corner",
            build = function()
                return make_grid(5, 5,
                    {{3,1},{3,2},{3,3}},
                    {1,2}, {5,4})
            end,
        },
        {
            name = "Level 3: Maze Sprint",
            build = function()
                return make_grid(7, 7,
                    {{2,2},{2,3},{4,3},{4,4},{4,5},{6,2},{6,3},{6,5},{3,6},{5,6}},
                    {1,1}, {7,7})
            end,
        },
    }
end

local function load_level(n)
    if n > #levels then
        all_done = true
        return
    end
    all_done = false
    current_level = n
    local g, cols, rows, start, flag = levels[n].build()
    grid = g
    COLS = cols
    ROWS = rows
    goal = { col = flag[1], row = flag[2] }
    robot = { col = start[1], row = start[2], dir = 2, anim_x = 0, anim_y = 0 }
    program = {}
    executing = false
    exec_index = 1
    exec_timer = 0
    level_complete = false
    loop_start = 0
    loop_count = 0
end

function lurek.init()
    lurek.window.setTitle("Logic Puzzle")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.15)
    build_levels()
    load_level(1)
end

local function can_move(col, row)
    if col < 1 or col > COLS or row < 1 or row > ROWS then return false end
    return grid[row][col] ~= 1
end

local function execute_step()
    if exec_index > #program then
        executing = false
        return
    end
    local cmd = program[exec_index]
    if cmd == CMD.FWD then
        local d = DIR[robot.dir]
        local nc = robot.col + d[1]
        local nr = robot.row + d[2]
        if can_move(nc, nr) then
            robot.col = nc
            robot.row = nr
        end
    elseif cmd == CMD.LEFT then
        robot.dir = robot.dir - 1
        if robot.dir < 1 then robot.dir = 4 end
    elseif cmd == CMD.RIGHT then
        robot.dir = robot.dir + 1
        if robot.dir > 4 then robot.dir = 1 end
    elseif cmd == CMD.LOOP then
        if loop_count < 2 then
            loop_count = loop_count + 1
            if loop_start > 0 then
                exec_index = loop_start
                return
            end
        else
            loop_count = 0
            loop_start = 0
        end
    end

    -- check win
    if robot.col == goal.col and robot.row == goal.row then
        level_complete = true
        executing = false
        return
    end

    exec_index = exec_index + 1
    if exec_index > #program then
        executing = false
    end
end

function lurek.process(dt)
    if not executing then return end
    exec_timer = exec_timer + dt
    if exec_timer >= EXEC_SPEED then
        exec_timer = exec_timer - EXEC_SPEED
        execute_step()
    end

    -- smooth animation
    local tx = GRID_X + (robot.col - 1) * TILE + TILE / 2
    local ty = GRID_Y + (robot.row - 1) * TILE + TILE / 2
    robot.anim_x = lerp(robot.anim_x, tx, 0.25)
    robot.anim_y = lerp(robot.anim_y, ty, 0.25)
end

local function draw_grid()
    for r = 1, ROWS do
        for c = 1, COLS do
            local x = GRID_X + (c - 1) * TILE
            local y = GRID_Y + (r - 1) * TILE
            if grid[r][c] == 1 then
                lurek.render.setColor(0.3, 0.3, 0.35, 1)
                lurek.render.rectangle("fill", x, y, TILE, TILE)
            else
                lurek.render.setColor(0.18, 0.18, 0.22, 1)
                lurek.render.rectangle("fill", x, y, TILE, TILE)
            end
            lurek.render.setColor(0.25, 0.25, 0.3, 1)
            lurek.render.rectangle("line", x, y, TILE, TILE)
        end
    end

    -- flag
    local fx = GRID_X + (goal.col - 1) * TILE + TILE / 2
    local fy = GRID_Y + (goal.row - 1) * TILE + TILE / 2
    lurek.render.setColor(1, 0.85, 0.1, 1)
    lurek.render.circle("fill", fx, fy, 10)
    lurek.render.setColor(0, 0, 0, 1)
    lurek.render.print("F", fx - 4, fy - 7, 0.9)
end

local function draw_robot()
    local rx, ry
    if executing then
        rx = robot.anim_x
        ry = robot.anim_y
    else
        rx = GRID_X + (robot.col - 1) * TILE + TILE / 2
        ry = GRID_Y + (robot.row - 1) * TILE + TILE / 2
        robot.anim_x = rx
        robot.anim_y = ry
    end

    -- body
    lurek.render.setColor(0.2, 0.8, 0.9, 1)
    lurek.render.circle("fill", rx, ry, 14)

    -- direction indicator
    local d = DIR[robot.dir]
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.circle("fill", rx + d[1] * 10, ry + d[2] * 10, 4)
end

local PANEL_X = 480
local PANEL_W = 300

local function draw_command_panel()
    lurek.render.setColor(0.12, 0.12, 0.18, 1)
    lurek.render.rectangle("fill", PANEL_X, 50, PANEL_W, H - 100)
    lurek.render.setColor(0.3, 0.3, 0.4, 1)
    lurek.render.rectangle("line", PANEL_X, 50, PANEL_W, H - 100)

    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("COMMANDS", PANEL_X + 10, 58, 1.1)

    -- command buttons
    for i, cmd in ipairs(CMD_LIST) do
        local bx = PANEL_X + 10 + (i - 1) * 70
        local by = 90
        local c = CMD_COLORS[cmd]
        lurek.render.setColor(c[1], c[2], c[3], 0.8)
        lurek.render.rectangle("fill", bx, by, 62, 28)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(cmd, bx + 5, by + 5, 0.85)
    end

    -- program list
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("PROGRAM (" .. #program .. "/" .. MAX_PROGRAM .. ")", PANEL_X + 10, 135, 1)

    for i, cmd in ipairs(program) do
        local py = 160 + (i - 1) * 28
        local c = CMD_COLORS[cmd]
        -- highlight current execution
        if executing and i == exec_index then
            lurek.render.setColor(1, 1, 0, 0.3)
            lurek.render.rectangle("fill", PANEL_X + 8, py - 2, PANEL_W - 16, 26)
        end
        lurek.render.setColor(c[1], c[2], c[3], 1)
        lurek.render.rectangle("fill", PANEL_X + 12, py, 18, 18)
        lurek.render.setColor(1, 1, 1, 1)
        local pointer = (executing and i == exec_index) and " >> " or ("  " .. i .. ". ")
        lurek.render.print(pointer .. cmd, PANEL_X + 35, py, 0.9)
    end

    -- controls
    lurek.render.setColor(0.6, 0.6, 0.6, 0.8)
    lurek.render.print("ENTER = Run", PANEL_X + 10, H - 90, 0.85)
    lurek.render.print("C = Clear   R = Reset", PANEL_X + 10, H - 70, 0.85)
end

function lurek.render()
    if all_done then
        lurek.render.setColor(1, 1, 0.5, 1)
        lurek.render.print("ALL LEVELS COMPLETE!", W / 2 - 100, H / 2 - 20, 1.5)
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("Press R to restart", W / 2 - 60, H / 2 + 20, 1)
        return
    end

    -- level name
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(levels[current_level].name, 10, 10, 1.2)

    draw_grid()
    draw_robot()
    draw_command_panel()

    if level_complete then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", W / 2 - 150, H / 2 - 30, 300, 60)
        lurek.render.setColor(0.2, 1, 0.3, 1)
        lurek.render.print("LEVEL COMPLETE!", W / 2 - 70, H / 2 - 20, 1.4)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Press N for next level", W / 2 - 65, H / 2 + 10, 0.9)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then
        if all_done then load_level(1) else load_level(current_level) end
        return
    end
    if all_done then return end

    if key == "n" and level_complete then
        load_level(current_level + 1)
        return
    end

    if executing or level_complete then return end

    if key == "c" then
        program = {}
        return
    end

    if key == "return" and #program > 0 then
        -- reset robot to start
        local _, _, _, start = levels[current_level].build()
        robot.col = start[1]
        robot.row = start[2]
        robot.dir = 2
        executing = true
        exec_index = 1
        exec_timer = 0
        loop_start = 0
        loop_count = 0
        return
    end

    -- backspace to remove last
    if key == "backspace" and #program > 0 then
        program[#program] = nil
    end
end

function lurek.mousepressed(mx, my, button)
    if all_done or executing or level_complete then return end

    -- check command buttons
    for i, cmd in ipairs(CMD_LIST) do
        local bx = PANEL_X + 10 + (i - 1) * 70
        local by = 90
        if mx > bx and mx < bx + 62 and my > by and my < by + 28 then
            if #program < MAX_PROGRAM then
                if cmd == CMD.LOOP and loop_start == 0 then
                    loop_start = #program + 1
                end
                program[#program + 1] = cmd
            end
            return
        end
    end
end
