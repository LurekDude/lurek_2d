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
-- Factory — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/factory/main.lua
-- Run with : cargo run -- content/games/simulation/factory
-- ============================================================================
-- Factory automation game (Factorio-lite): place conveyors, miners, smelters,
-- and assemblers to build production lines that turn ore into gold.
-- Controls: WASD direction, M/S/A machines, D delete, 1-3 speed, click place
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600
local TILE       = 32
local MAP_COLS   = 25
local MAP_ROWS   = 18
local MAP_W      = MAP_COLS * TILE
local MAP_H      = MAP_ROWS * TILE

local STATE = { TITLE = 1, PLAYING = 2, VICTORY = 3 }
local current_state = STATE.PLAYING

-- Directions: 1=right, 2=down, 3=left, 4=up
local DIR_RIGHT = 1
local DIR_DOWN  = 2
local DIR_LEFT  = 3
local DIR_UP    = 4
local DIR_DX    = { [1] = 1, [2] = 0, [3] = -1, [4] = 0 }
local DIR_DY    = { [1] = 0, [2] = 1, [3] = 0,  [4] = -1 }
local DIR_ARROW = { [1] = "→", [2] = "↓", [3] = "←", [4] = "↑" }

-- Tile types
local T_EMPTY    = 0
local T_CONVEYOR = 1
local T_MACHINE  = 2
local T_ORE      = 3
local T_STORAGE  = 4

-- Machine types
local M_MINER    = "miner"
local M_SMELTER  = "smelter"
local M_ASSEMBLER = "assembler"

-- Machine costs
local MACHINE_COST = {
    [M_MINER]     = 10,
    [M_SMELTER]   = 20,
    [M_ASSEMBLER] = 30,
}

-- Machine process times
local MACHINE_TIME = {
    [M_MINER]     = 3.0,
    [M_SMELTER]   = 5.0,
    [M_ASSEMBLER] = 8.0,
}

-- Machine input requirements
local MACHINE_INPUT = {
    [M_MINER]     = 0,
    [M_SMELTER]   = 1,
    [M_ASSEMBLER] = 2,
}

-- Item types
local I_RAW     = "raw"
local I_INGOT   = "ingot"
local I_PRODUCT = "product"

-- Item colors
local ITEM_COLORS = {
    [I_RAW]     = {0.6, 0.4, 0.2},
    [I_INGOT]   = {0.7, 0.7, 0.8},
    [I_PRODUCT] = {0.2, 0.8, 0.4},
}

-- Machine colors
local MACHINE_COLORS = {
    [M_MINER]     = {0.7, 0.5, 0.2},
    [M_SMELTER]   = {0.8, 0.3, 0.2},
    [M_ASSEMBLER] = {0.3, 0.3, 0.8},
}

local CONVEYOR_COST = 1
local ITEM_SPEED    = 32.0
local SELL_INTERVAL = 10.0
local SELL_PRICE    = 15
local WIN_GOLD      = 500
local START_GOLD    = 50
local ORE_COUNT     = 8

-- Colors
local COL_EMPTY   = {0.15, 0.15, 0.18}
local COL_ORE     = {0.5, 0.35, 0.15}
local COL_STORAGE = {0.2, 0.6, 0.3}
local COL_GRID    = {0.2, 0.2, 0.24}
local COL_BELT    = {0.35, 0.35, 0.4}

-- ---------------------------------------------------------------------------
-- Game State
-- ---------------------------------------------------------------------------
local grid       = {}   -- grid[row][col] = {type, dir, machine_type, ...}
local machines   = {}   -- {col, row, mtype, timer, input_count, output_item, active}
local items      = {}   -- {x, y, itype, col, row, moving, progress}
local particles  = {}   -- {x, y, vx, vy, life, r, g, b, a, size}
local tweens_active = {} -- {target, field, from, to, duration, elapsed}

local gold         = START_GOLD
local gold_display = START_GOLD
local sell_timer   = 0
local storage_count = 0
local speed_mult   = 1
local game_time    = 0

-- Placement state
local place_dir    = DIR_RIGHT
local place_mode   = "conveyor"  -- "conveyor", "miner", "smelter", "assembler", "delete"

-- Stats
local total_items_produced = 0
local items_last_minute    = 0
local items_minute_timer   = 0
local items_minute_count   = 0
local conveyor_count       = 0

-- Ore tile positions (col, row)
local ore_tiles = {}

-- ---------------------------------------------------------------------------
-- Render helpers — see universal helpers inserted before Engine Callbacks
-- ---------------------------------------------------------------------------
local fonts = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function in_bounds(col, row)
    return col >= 1 and col <= MAP_COLS and row >= 1 and row <= MAP_ROWS
end

local function grid_get(col, row)
    if in_bounds(col, row) then return grid[row][col] end
    return nil
end

local function screen_to_grid(mx, my)
    local col = math.floor(mx / TILE) + 1
    local row = math.floor(my / TILE) + 1
    return col, row
end

local function grid_center(col, row)
    return (col - 1) * TILE + TILE * 0.5, (row - 1) * TILE + TILE * 0.5
end

local function is_ore_tile(col, row)
    for _, o in ipairs(ore_tiles) do
        if o.col == col and o.row == row then return true end
    end
    return false
end

local function get_machine_at(col, row)
    for _, m in ipairs(machines) do
        if m.col == col and m.row == row then return m end
    end
    return nil
end

local function count_active_machines()
    local n = 0
    for _, m in ipairs(machines) do
        if m.active then n = n + 1 end
    end
    return n
end

-- ---------------------------------------------------------------------------
-- Particle System
-- ---------------------------------------------------------------------------
local function emit_particles(x, y, count, r, g, b, spread, sz)
    spread = spread or 60
    sz = sz or 3
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * spread,
            vy = (math.random() - 0.5) * spread - 20,
            life = 0.4 + math.random() * 0.5,
            r = r, g = g, b = b, a = 1.0,
            size = sz + math.random() * 2,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 40 * dt
        p.life = p.life - dt
        p.a = math.max(0, p.life / 0.9)
        p.size = p.size * (1 - dt * 0.5)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Tween System
-- ---------------------------------------------------------------------------
local function add_tween(target, field, from, to, duration)
    table.insert(tweens_active, {
        target = target, field = field,
        from = from, to = to,
        duration = duration, elapsed = 0,
    })
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens_active do
        local t = tweens_active[i]
        t.elapsed = t.elapsed + dt
        local progress = math.min(t.elapsed / t.duration, 1)
        -- Ease out quad
        local eased = 1 - (1 - progress) * (1 - progress)
        t.target[t.field] = t.from + (t.to - t.from) * eased
        if progress >= 1 then
            t.target[t.field] = t.to
            table.remove(tweens_active, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Map Generation
-- ---------------------------------------------------------------------------
local function generate_map()
    math.randomseed(os.time())
    grid = {}
    for r = 1, MAP_ROWS do
        grid[r] = {}
        for c = 1, MAP_COLS do
            grid[r][c] = { type = T_EMPTY, dir = 0, machine_type = nil }
        end
    end

    -- Place ore tiles
    ore_tiles = {}
    local placed = 0
    while placed < ORE_COUNT do
        local c = math.random(2, MAP_COLS - 1)
        local r = math.random(2, MAP_ROWS - 1)
        if grid[r][c].type == T_EMPTY and not is_ore_tile(c, r) then
            grid[r][c].type = T_ORE
            table.insert(ore_tiles, {col = c, row = r})
            placed = placed + 1
        end
    end

    -- Place 2 storage tiles on right edge
    for i = 0, 1 do
        local sr = math.floor(MAP_ROWS / 2) + i
        grid[sr][MAP_COLS].type = T_STORAGE
    end
end

-- ---------------------------------------------------------------------------
-- Game Init
-- ---------------------------------------------------------------------------
local function init_game()
    generate_map()
    machines = {}
    items = {}
    particles = {}
    tweens_active = {}
    gold = START_GOLD
    gold_display = START_GOLD
    sell_timer = 0
    storage_count = 0
    speed_mult = 1
    game_time = 0
    place_dir = DIR_RIGHT
    place_mode = "conveyor"
    total_items_produced = 0
    items_last_minute = 0
    items_minute_timer = 0
    items_minute_count = 0
    conveyor_count = 0
    current_state = STATE.PLAYING
end

-- ---------------------------------------------------------------------------
-- Placement Logic
-- ---------------------------------------------------------------------------
local function try_place(col, row)
    if not in_bounds(col, row) then return end
    local cell = grid[row][col]

    if place_mode == "delete" then
        if cell.type == T_CONVEYOR then
            cell.type = T_EMPTY
            cell.dir = 0
            conveyor_count = conveyor_count - 1
            emit_particles((col - 1) * TILE + 16, (row - 1) * TILE + 16, 4, 0.8, 0.2, 0.2)
        elseif cell.type == T_MACHINE then
            -- Remove machine
            for i = #machines, 1, -1 do
                if machines[i].col == col and machines[i].row == row then
                    table.remove(machines, i)
                    break
                end
            end
            cell.type = T_EMPTY
            cell.dir = 0
            cell.machine_type = nil
            emit_particles((col - 1) * TILE + 16, (row - 1) * TILE + 16, 6, 0.8, 0.2, 0.2)
        end
        return
    end

    if place_mode == "conveyor" then
        if cell.type ~= T_EMPTY then return end
        if gold < CONVEYOR_COST then return end
        gold = gold - CONVEYOR_COST
        add_tween({val = gold_display}, "val", gold_display, gold, 0.3)
        cell.type = T_CONVEYOR
        cell.dir = place_dir
        conveyor_count = conveyor_count + 1
        emit_particles((col - 1) * TILE + 16, (row - 1) * TILE + 16, 3, 0.5, 0.5, 0.6)
        return
    end

    -- Machine placement
    local mtype = place_mode
    local cost = MACHINE_COST[mtype]
    if not cost then return end
    if gold < cost then return end

    -- Miner must be on ore tile
    if mtype == M_MINER and cell.type ~= T_ORE then return end
    -- Smelter / assembler must be on empty
    if mtype ~= M_MINER and cell.type ~= T_EMPTY then return end

    gold = gold - cost
    add_tween({val = gold_display}, "val", gold_display, gold, 0.4)
    cell.type = T_MACHINE
    cell.dir = place_dir
    cell.machine_type = mtype

    table.insert(machines, {
        col = col, row = row,
        mtype = mtype,
        timer = 0,
        input_count = 0,
        output_item = nil,
        active = false,
    })
    emit_particles((col - 1) * TILE + 16, (row - 1) * TILE + 16, 8,
        MACHINE_COLORS[mtype][1], MACHINE_COLORS[mtype][2], MACHINE_COLORS[mtype][3], 40)
end

-- ---------------------------------------------------------------------------
-- Item Management
-- ---------------------------------------------------------------------------
local function spawn_item(col, row, itype)
    local cx, cy = grid_center(col, row)
    table.insert(items, {
        x = cx, y = cy,
        itype = itype,
        col = col, row = row,
        moving = false,
        target_x = cx, target_y = cy,
        progress = 0,
    })
    total_items_produced = total_items_produced + 1
    items_minute_count = items_minute_count + 1
    local ic = ITEM_COLORS[itype]
    emit_particles(cx, cy, 5, ic[1], ic[2], ic[3], 30, 2)
end

local function find_output_dir(col, row)
    -- Machine outputs in the direction it faces
    local cell = grid_get(col, row)
    if cell then return cell.dir end
    return DIR_RIGHT
end

local function update_items(dt)
    local to_remove = {}
    for idx, item in ipairs(items) do
        if item.moving then
            -- Move toward target
            local dx = item.target_x - item.x
            local dy = item.target_y - item.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 1 then
                item.x = item.target_x
                item.y = item.target_y
                item.moving = false
                item.col = math.floor(item.x / TILE) + 1
                item.row = math.floor(item.y / TILE) + 1
            else
                local spd = ITEM_SPEED * dt
                item.x = item.x + (dx / dist) * spd
                item.y = item.y + (dy / dist) * spd
            end
        else
            -- Check current tile
            local cell = grid_get(item.col, item.row)
            if not cell then
                table.insert(to_remove, idx)
            elseif cell.type == T_STORAGE then
                -- Item reached storage
                if item.itype == I_PRODUCT then
                    storage_count = storage_count + 1
                end
                emit_particles(item.x, item.y, 6, 0.2, 0.8, 0.4, 40, 3)
                table.insert(to_remove, idx)
            elseif cell.type == T_MACHINE then
                -- Feed into machine
                local mach = get_machine_at(item.col, item.row)
                if mach then
                    local needed = MACHINE_INPUT[mach.mtype]
                    if needed > 0 and mach.input_count < needed then
                        -- Accept correct item type
                        local accept = false
                        if mach.mtype == M_SMELTER and item.itype == I_RAW then accept = true end
                        if mach.mtype == M_ASSEMBLER and item.itype == I_INGOT then accept = true end
                        if accept then
                            mach.input_count = mach.input_count + 1
                            table.insert(to_remove, idx)
                            emit_particles(item.x, item.y, 3, 0.9, 0.9, 0.3, 20, 2)
                        else
                            -- Wrong item: push through
                            local odir = find_output_dir(item.col, item.row)
                            local nc = item.col + DIR_DX[odir]
                            local nr = item.row + DIR_DY[odir]
                            if in_bounds(nc, nr) then
                                item.target_x, item.target_y = grid_center(nc, nr)
                                item.moving = true
                            else
                                table.insert(to_remove, idx)
                            end
                        end
                    else
                        -- Machine full: push through
                        local odir = find_output_dir(item.col, item.row)
                        local nc = item.col + DIR_DX[odir]
                        local nr = item.row + DIR_DY[odir]
                        if in_bounds(nc, nr) then
                            item.target_x, item.target_y = grid_center(nc, nr)
                            item.moving = true
                        end
                    end
                end
            elseif cell.type == T_CONVEYOR then
                -- Move in conveyor direction
                local d = cell.dir
                if d > 0 then
                    local nc = item.col + DIR_DX[d]
                    local nr = item.row + DIR_DY[d]
                    if in_bounds(nc, nr) then
                        item.target_x, item.target_y = grid_center(nc, nr)
                        item.moving = true
                    else
                        table.insert(to_remove, idx)
                    end
                end
            else
                -- Item on empty/ore tile with nowhere to go
                -- Just sit (miner output might be here)
            end
        end
    end

    -- Remove collected/lost items in reverse order
    table.sort(to_remove, function(a, b) return a > b end)
    for _, idx in ipairs(to_remove) do
        table.remove(items, idx)
    end
end

-- ---------------------------------------------------------------------------
-- Machine Processing
-- ---------------------------------------------------------------------------
local function update_machines(dt)
    for _, m in ipairs(machines) do
        local needed = MACHINE_INPUT[m.mtype]

        if m.mtype == M_MINER then
            -- Miner always produces if on ore
            if is_ore_tile(m.col, m.row) then
                m.active = true
                m.timer = m.timer + dt
                if m.timer >= MACHINE_TIME[m.mtype] then
                    m.timer = m.timer - MACHINE_TIME[m.mtype]
                    -- Output raw material
                    local odir = find_output_dir(m.col, m.row)
                    local nc = m.col + DIR_DX[odir]
                    local nr = m.row + DIR_DY[odir]
                    if in_bounds(nc, nr) then
                        spawn_item(nc, nr, I_RAW)
                    end
                    emit_particles((m.col - 1) * TILE + 16, (m.row - 1) * TILE + 16,
                        4, 0.9, 0.6, 0.2, 30, 2)
                end
            else
                m.active = false
            end
        else
            -- Smelter or assembler
            if m.input_count >= needed and not m.active then
                m.active = true
                m.timer = 0
                m.input_count = m.input_count - needed
            end

            if m.active then
                m.timer = m.timer + dt
                -- Sparks while processing
                if math.random() < dt * 3 then
                    local mc = MACHINE_COLORS[m.mtype]
                    emit_particles((m.col - 1) * TILE + 16, (m.row - 1) * TILE + 16,
                        2, mc[1] + 0.2, mc[2] + 0.2, mc[3] + 0.2, 20, 2)
                end

                if m.timer >= MACHINE_TIME[m.mtype] then
                    m.timer = 0
                    m.active = false
                    -- Output product
                    local out_type = I_INGOT
                    if m.mtype == M_ASSEMBLER then out_type = I_PRODUCT end

                    local odir = find_output_dir(m.col, m.row)
                    local nc = m.col + DIR_DX[odir]
                    local nr = m.row + DIR_DY[odir]
                    if in_bounds(nc, nr) then
                        spawn_item(nc, nr, out_type)
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Sell Logic
-- ---------------------------------------------------------------------------
local function update_sell(dt)
    sell_timer = sell_timer + dt
    if sell_timer >= SELL_INTERVAL then
        sell_timer = sell_timer - SELL_INTERVAL
        if storage_count > 0 then
            local earnings = storage_count * SELL_PRICE
            local old_gold = gold
            gold = gold + earnings
            add_tween({val = gold_display}, "val", gold_display, gold, 0.6)
            -- Flash particles at storage locations
            for r = 1, MAP_ROWS do
                for c = 1, MAP_COLS do
                    if grid[r][c].type == T_STORAGE then
                        emit_particles((c - 1) * TILE + 16, (r - 1) * TILE + 16,
                            10, 1.0, 0.85, 0.1, 60, 4)
                    end
                end
            end
            storage_count = 0

            if gold >= WIN_GOLD then
                current_state = STATE.VICTORY
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Stats
-- ---------------------------------------------------------------------------
local function update_stats(dt)
    items_minute_timer = items_minute_timer + dt
    if items_minute_timer >= 60 then
        items_last_minute = items_minute_count
        items_minute_count = 0
        items_minute_timer = items_minute_timer - 60
    end
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
local function update_playing(dt)
    local sdt = dt * speed_mult
    game_time = game_time + sdt

    update_machines(sdt)
    update_items(sdt)
    update_sell(sdt)
    update_stats(sdt)
    update_particles(sdt)
    update_tweens(dt) -- tweens always real-time
end

-- ---------------------------------------------------------------------------
-- Rendering — World
-- ---------------------------------------------------------------------------
local function draw_grid()
    -- Background tiles
    for r = 1, MAP_ROWS do
        for c = 1, MAP_COLS do
            local cell = grid[r][c]
            local x = (c - 1) * TILE
            local y = (r - 1) * TILE
            local col = COL_EMPTY

            if cell.type == T_ORE then
                col = COL_ORE
            elseif cell.type == T_STORAGE then
                col = COL_STORAGE
            elseif cell.type == T_CONVEYOR then
                col = COL_BELT
            elseif cell.type == T_MACHINE then
                col = MACHINE_COLORS[cell.machine_type] or COL_EMPTY
            end

            rect(x, y, TILE, TILE, col[1], col[2], col[3], 1)

            -- Grid lines
            rect(x, y, TILE, 1, COL_GRID[1], COL_GRID[2], COL_GRID[3], 0.3)
            rect(x, y, 1, TILE, COL_GRID[1], COL_GRID[2], COL_GRID[3], 0.3)
        end
    end
end

local function draw_conveyors()
    for r = 1, MAP_ROWS do
        for c = 1, MAP_COLS do
            local cell = grid[r][c]
            if cell.type == T_CONVEYOR and cell.dir > 0 then
                local cx = (c - 1) * TILE + TILE * 0.5
                local cy = (r - 1) * TILE + TILE * 0.5
                text_(DIR_ARROW[cell.dir], cx - 5, cy - 7, 14, 0.9, 0.9, 0.9, 0.8)
            end
        end
    end
end

local function draw_ore_tiles()
    for _, o in ipairs(ore_tiles) do
        local cx = (o.col - 1) * TILE + TILE * 0.5
        local cy = (o.row - 1) * TILE + TILE * 0.5
        -- Only draw indicator if no machine placed here
        local cell = grid[o.row][o.col]
        if cell.type == T_ORE then
            circ(cx, cy, 10, 0.6, 0.4, 0.15, 0.7)
            circ(cx, cy, 6, 0.7, 0.5, 0.2, 0.5)
        end
    end
end

local function draw_machines()
    for _, m in ipairs(machines) do
        local x = (m.col - 1) * TILE + 4
        local y = (m.row - 1) * TILE + 4
        local mc = MACHINE_COLORS[m.mtype]

        -- Machine body
        rect(x, y, TILE - 8, TILE - 8, mc[1], mc[2], mc[3], 1)

        -- Label
        local label = "M"
        if m.mtype == M_SMELTER then label = "S" end
        if m.mtype == M_ASSEMBLER then label = "A" end
        text_(label, x + 7, y + 5, 14, 1, 1, 1, 0.9)

        -- Active indicator
        if m.active then
            local progress = m.timer / MACHINE_TIME[m.mtype]
            rect(x, y + TILE - 10, (TILE - 8) * progress, 3, 0.2, 1, 0.3, 0.8)
        end

        -- Direction arrow (small)
        local odir = find_output_dir(m.col, m.row)
        if odir > 0 then
            local ax = (m.col - 1) * TILE + TILE * 0.5 + DIR_DX[odir] * 10
            local ay = (m.row - 1) * TILE + TILE * 0.5 + DIR_DY[odir] * 10
            circ(ax, ay, 2, 1, 1, 0, 0.6)
        end
    end
end

local function draw_items()
    for _, item in ipairs(items) do
        local ic = ITEM_COLORS[item.itype]
        local sz = 4
        if item.itype == I_INGOT then sz = 5 end
        if item.itype == I_PRODUCT then sz = 6 end
        circ(item.x, item.y, sz, ic[1], ic[2], ic[3], 1)
    end
end

local function draw_particles()
    for _, p in ipairs(particles) do
        circ(p.x, p.y, p.size, p.r, p.g, p.b, p.a)
    end
end

local function draw_storage()
    for r = 1, MAP_ROWS do
        for c = 1, MAP_COLS do
            if grid[r][c].type == T_STORAGE then
                local x = (c - 1) * TILE + 2
                local y = (r - 1) * TILE + 2
                rect(x, y, TILE - 4, TILE - 4, 0.15, 0.5, 0.25, 0.8)
                text_("$", x + 9, y + 6, 16, 1, 0.9, 0.2, 0.9)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Rendering — UI
-- ---------------------------------------------------------------------------
local function draw_hud()
    -- Top bar background
    rect(0, 0, SCREEN_W, 28, 0, 0, 0, 0.7)

    -- Gold
    local gd = math.floor(gold_display + 0.5)
    text_("Gold: " .. gd, 10, 5, 16, 1, 0.85, 0.1, 1)

    -- Goal
    text_("/ " .. WIN_GOLD, 110, 5, 14, 0.7, 0.7, 0.7, 0.8)

    -- Storage
    text_("Storage: " .. storage_count, 200, 5, 14, 0.5, 0.9, 0.5, 1)

    -- Stats
    text_("Items/min: " .. items_last_minute, 340, 5, 12, 0.7, 0.7, 0.9, 0.8)
    text_("Machines: " .. #machines, 470, 5, 12, 0.7, 0.7, 0.9, 0.8)
    text_("Belts: " .. conveyor_count, 570, 5, 12, 0.7, 0.7, 0.9, 0.8)

    -- Speed
    local speed_text = speed_mult .. "x"
    text_("Speed: " .. speed_text, 660, 5, 12, 0.9, 0.9, 0.5, 1)

    -- FPS
    local fps = lurek.timer.getFPS()
    text_("FPS: " .. fps, SCREEN_W - 70, 5, 12, 0.5, 0.5, 0.5, 0.8)

    -- Bottom bar: placement mode
    rect(0, SCREEN_H - 24, SCREEN_W, 24, 0, 0, 0, 0.7)
    local mode_text = "Mode: " .. place_mode:upper()
    if place_mode == "conveyor" then
        mode_text = mode_text .. " " .. DIR_ARROW[place_dir]
    end
    text_(mode_text, 10, SCREEN_H - 19, 14, 0.9, 0.9, 0.9, 1)

    -- Hotkey hints
    text_(
        "WASD:dir  M:miner(10)  S:smelter(20)  A:assembler(30)  D:delete  1-3:speed",
        250, SCREEN_H - 19, 11, 0.6, 0.6, 0.6, 0.8)
end

-- ---------------------------------------------------------------------------
-- Title / Victory Screens
-- ---------------------------------------------------------------------------
local function draw_title()
    rect(0, 0, SCREEN_W, SCREEN_H, 0.08, 0.08, 0.1, 1)

    text_("FACTORY", SCREEN_W * 0.5 - 80, 160, 48, 0.9, 0.7, 0.1, 1)
    text_("BUILD YOUR PRODUCTION LINE", SCREEN_W * 0.5 - 140, 230, 18, 0.7, 0.7, 0.7, 1)

    text_("Place miners on ore, connect with conveyors,", 200, 300, 14, 0.6, 0.6, 0.6, 0.9)
    text_("smelt raw materials, assemble products, sell for gold!", 175, 320, 14, 0.6, 0.6, 0.6, 0.9)
    text_("Reach " .. WIN_GOLD .. " gold to win.", 320, 350, 14, 0.8, 0.8, 0.3, 1)

    local pulse = 0.6 + 0.4 * math.abs(math.sin(game_time * 2))
    text_("Click to Start", SCREEN_W * 0.5 - 55, 430, 18, 1, 1, 1, pulse)
end

local function draw_victory()
    rect(0, 0, SCREEN_W, SCREEN_H, 0.05, 0.1, 0.05, 0.85)

    text_("VICTORY!", SCREEN_W * 0.5 - 80, 200, 48, 0.2, 1, 0.3, 1)
    text_("You reached " .. gold .. " gold!", SCREEN_W * 0.5 - 90, 280, 20, 1, 0.9, 0.2, 1)
    text_("Machines: " .. #machines .. "  Belts: " .. conveyor_count,
        SCREEN_W * 0.5 - 100, 320, 16, 0.7, 0.7, 0.7, 0.9)

    local pulse = 0.6 + 0.4 * math.abs(math.sin(game_time * 2))
    text_("Click to Play Again", SCREEN_W * 0.5 - 75, 400, 18, 1, 1, 1, pulse)
end

-- ---------------------------------------------------------------------------
-- Input Bindings
-- ---------------------------------------------------------------------------
lurek.input.bind("place_right", "d")
lurek.input.bind("place_left",  "a")
lurek.input.bind("place_down",  "s")
lurek.input.bind("place_up",    "w")
lurek.input.bind("miner",       "m")
lurek.input.bind("smelter",     "s")
lurek.input.bind("assembler",   "a")
lurek.input.bind("delete",      "d")
lurek.input.bind("speed1",      "1")
lurek.input.bind("speed2",      "2")
lurek.input.bind("speed3",      "3")
lurek.input.bind("place",       "mouse1")
lurek.input.bind("quit",        "escape")

-- ---------------------------------------------------------------------------
-- Engine Callbacks
-- ---------------------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("Factory — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.12)
    for _, sz in ipairs({7, 10, 14, 18, 22}) do
        fonts[sz] = lurek.render.newFont(sz)
    end
end

local function _ready_setup()
    game_time = 0
end

function lurek.process(dt)
    game_time = game_time + dt

    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("place") then
            init_game()
        end
        return
    end

    if current_state == STATE.VICTORY then
        if lurek.input.wasActionPressed("place") then
            init_game()
        end
        update_particles(dt)
        return
    end

    -- PLAYING state input
    -- Direction keys (set conveyor direction and mode)
    if lurek.input.wasActionPressed("place_right") then
        place_dir = DIR_RIGHT
        place_mode = "conveyor"
    elseif lurek.input.wasActionPressed("place_left") then
        place_dir = DIR_LEFT
        place_mode = "conveyor"
    elseif lurek.input.wasActionPressed("place_down") then
        place_dir = DIR_DOWN
        place_mode = "conveyor"
    elseif lurek.input.wasActionPressed("place_up") then
        place_dir = DIR_UP
        place_mode = "conveyor"
    end

    -- Machine/mode selection
    if lurek.input.wasActionPressed("miner") then
        place_mode = M_MINER
    end
    if lurek.input.wasActionPressed("smelter") then
        place_mode = M_SMELTER
    end
    if lurek.input.wasActionPressed("assembler") then
        place_mode = M_ASSEMBLER
    end
    if lurek.input.wasActionPressed("delete") then
        place_mode = "delete"
    end

    -- Speed
    if lurek.input.wasActionPressed("speed1") then speed_mult = 1 end
    if lurek.input.wasActionPressed("speed2") then speed_mult = 2 end
    if lurek.input.wasActionPressed("speed3") then speed_mult = 4 end

    -- Placement
    if lurek.input.wasActionPressed("place") then
        local mx, my = lurek.input.mouse.getPosition()
        local col, row = screen_to_grid(mx, my)
        if row >= 1 then -- not on HUD
            try_place(col, row)
        end
    end

    update_playing(dt)
end

function lurek.draw()
    if current_state == STATE.PLAYING then
        draw_grid()
        draw_ore_tiles()
        draw_conveyors()
        draw_storage()
        draw_machines()
        draw_items()
        draw_particles()
    end
end

function lurek.draw_ui()
    if current_state == STATE.TITLE then
        draw_title()
    elseif current_state == STATE.PLAYING then
        draw_hud()
    elseif current_state == STATE.VICTORY then
        draw_victory()
    end
end
