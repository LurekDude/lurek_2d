-- ============================================================================
-- Settlers Rise — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/settlers_rise/main.lua
-- Run with : cargo run -- content/games/simulation/settlers_rise
-- ============================================================================
-- Settlement-building simulation inspired by The Settlers 2 (Amiga 1998).
-- Place buildings, settlers walk supply chains, resources accumulate.
-- Controls: LMB place building, Tab cycle build type, Escape quit
-- ============================================================================

local W, H = 1024, 768

-- ── Constants ─────────────────────────────────────────────────────────────
local TILE        = 48
local MAP_COLS    = 21
local MAP_ROWS    = 16
local UI_H        = 60        -- bottom panel

-- Building types
local BTYPE = {
    HQ        = "HQ",
    WOODCUTTER = "Woodcutter",
    SAWMILL   = "Sawmill",
    QUARRY    = "Quarry",
    FARM      = "Farm",
    MINE      = "Mine",
}
local BUILD_ORDER = { BTYPE.WOODCUTTER, BTYPE.SAWMILL, BTYPE.QUARRY, BTYPE.FARM, BTYPE.MINE }
local build_index = 1

-- Resource costs
local COSTS = {
    [BTYPE.WOODCUTTER]  = { wood=2, stone=0 },
    [BTYPE.SAWMILL]     = { wood=4, stone=2 },
    [BTYPE.QUARRY]      = { wood=3, stone=0 },
    [BTYPE.FARM]        = { wood=5, stone=3 },
    [BTYPE.MINE]        = { wood=4, stone=4 },
}
local BUILD_COLORS = {
    [BTYPE.HQ]          = {0.9, 0.8, 0.1},
    [BTYPE.WOODCUTTER]  = {0.5, 0.75, 0.25},
    [BTYPE.SAWMILL]     = {0.7, 0.5, 0.25},
    [BTYPE.QUARRY]      = {0.65, 0.65, 0.65},
    [BTYPE.FARM]        = {0.3, 0.8, 0.3},
    [BTYPE.MINE]        = {0.5, 0.4, 0.3},
}

-- Settler carry
local CARRY_TIME = 3.0      -- seconds per road segment (simplified)
local PRODUCE_TIMES = {
    [BTYPE.WOODCUTTER]  = 5.0,
    [BTYPE.SAWMILL]     = 7.0,
    [BTYPE.QUARRY]      = 8.0,
    [BTYPE.FARM]        = 10.0,
    [BTYPE.MINE]        = 12.0,
}
local PRODUCE_RESOURCE = {
    [BTYPE.WOODCUTTER]  = "logs",
    [BTYPE.SAWMILL]     = "wood",
    [BTYPE.QUARRY]      = "stone",
    [BTYPE.FARM]        = "food",
    [BTYPE.MINE]        = "iron",
}

-- ── State ─────────────────────────────────────────────────────────────────
local resources = { wood = 12, stone = 8, food = 5, logs = 0, iron = 0 }
local buildings  = {}     -- { type, col, row, timer, producing }
local settlers   = {}     -- { x, y, tx, ty, carry, t }
local roads      = {}     -- { {col,row} ... } — flagged tiles for road rendering
local next_settler_id = 1

-- Tilemap: 0=grass, 1=forest, 2=stone, 3=road, 4=water
local tilemap = {}
local function tile_at(c, r)
    if r < 1 or r > MAP_ROWS or c < 1 or c > MAP_COLS then return 4 end
    return tilemap[r][c]
end

local TILE_COLORS = {
    [0] = {0.35, 0.62, 0.22},
    [1] = {0.18, 0.45, 0.12},
    [2] = {0.60, 0.60, 0.58},
    [3] = {0.72, 0.65, 0.48},
    [4] = {0.25, 0.45, 0.72},
}

local hq_col, hq_row = 3, 8  -- starting HQ position

-- Pathfinding grid for settlers
local pf_grid = nil

-- ── Helpers ───────────────────────────────────────────────────────────────
local function world_x(col) return (col - 1) * TILE + TILE/2 end
local function world_y(row) return (row - 1) * TILE + TILE/2 end
local function col_of(px)   return math.floor(px / TILE) + 1 end
local function row_of(py)   return math.floor(py / TILE) + 1 end

local function building_at(c, r)
    for _, b in ipairs(buildings) do
        if b.col == c and b.row == r then return b end
    end
    return nil
end

local function can_build(c, r)
    local t = tile_at(c, r)
    return t == 0 or t == 3   -- grass or road
end

local function spawn_settler(from_col, from_row, to_col, to_row, carry)
    local s = {
        id   = next_settler_id,
        x    = world_x(from_col), y = world_y(from_row),
        tx   = world_x(to_col),   ty = world_y(to_row),
        carry = carry,
        t    = 0,
        dur  = CARRY_TIME,
    }
    next_settler_id = next_settler_id + 1
    settlers[#settlers+1] = s
end

-- ── Generate map ──────────────────────────────────────────────────────────
local function gen_map(seed)
    local rng = lurek.math.newRandomGenerator(seed)
    local ng  = lurek.math.newNoiseGenerator(seed)
    for r = 1, MAP_ROWS do
        tilemap[r] = {}
        for c = 1, MAP_COLS do
            local n  = (ng:noise(c * 0.18, r * 0.18) + 1) * 0.5
            local t
            if r == 1 or r == MAP_ROWS or c == 1 or c == MAP_COLS then
                t = 4   -- water border
            elseif n < 0.25 then
                t = 4   -- water lake
            elseif n < 0.45 then
                t = 1   -- forest
            elseif n < 0.55 then
                t = 2   -- rock
            else
                t = 0   -- grass
            end
            tilemap[r][c] = t
        end
    end
    -- Ensure HQ area is clear
    for dr = -1, 1 do
        for dc = -1, 1 do
            local rr = hq_row + dr; local cc = hq_col + dc
            if rr >= 1 and rr <= MAP_ROWS and cc >= 1 and cc <= MAP_COLS then
                tilemap[rr][cc] = 0
            end
        end
    end
end

-- ── Load ──────────────────────────────────────────────────────────────────
function lurek.load()
    lurek.window.setTitle("Settlers Rise — Lurek2D")
    lurek.gfx.setBackgroundColor(0.25, 0.45, 0.2)

    gen_map(17)

    -- Place HQ
    buildings[#buildings+1] = { type=BTYPE.HQ, col=hq_col, row=hq_row, timer=0, producing=false }
    tilemap[hq_row][hq_col] = 3

    -- Build pathfinding grid (walkable = not water)
    pf_grid = lurek.pathfind.newGrid(MAP_COLS, MAP_ROWS, function(c, r)
        local t = tile_at(c, r)
        return t ~= 4
    end)
end

-- ── Update ────────────────────────────────────────────────────────────────
function lurek.update(dt)
    -- Tick buildings
    for _, b in ipairs(buildings) do
        if b.type ~= BTYPE.HQ then
            b.timer = b.timer + dt
            local pt = PRODUCE_TIMES[b.type]
            if pt and b.timer >= pt then
                b.timer = 0
                local res = PRODUCE_RESOURCE[b.type]
                resources[res] = (resources[res] or 0) + 1
                -- Spawn settler carrying goods back to HQ
                spawn_settler(b.col, b.row, hq_col, hq_row, res)
            end
        end
    end

    -- Move settlers
    for i = #settlers, 1, -1 do
        local s = settlers[i]
        s.t = s.t + dt
        local prog = math.min(1, s.t / s.dur)
        s.x = lurek.math.lerp(world_x(col_of(s.x)), s.tx, prog)
        s.y = lurek.math.lerp(world_y(row_of(s.y)), s.ty, prog)
        -- Smooth linear movement toward target
        local dx = s.tx - s.x; local dy = s.ty - s.y
        local spd = 55 * dt
        local d   = math.sqrt(dx*dx + dy*dy)
        if d <= spd + 1 then
            table.remove(settlers, i)
        else
            s.x = s.x + (dx/d) * spd
            s.y = s.y + (dy/d) * spd
        end
    end

    -- Convert logs → wood at sawmill
    for _, b in ipairs(buildings) do
        if b.type == BTYPE.SAWMILL and resources.logs >= 2 then
            -- handled by produce timer above; just drain logs
        end
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────
function lurek.draw()
    -- Tiles
    for r = 1, MAP_ROWS do
        for c = 1, MAP_COLS do
            local t  = tilemap[r][c]
            local tc = TILE_COLORS[t] or TILE_COLORS[0]
            lurek.gfx.setColor(tc[1], tc[2], tc[3])
            lurek.gfx.rectangle("fill", (c-1)*TILE, (r-1)*TILE, TILE, TILE)
            -- subtle grid
            lurek.gfx.setColor(0, 0, 0, 0.08)
            lurek.gfx.rectangle("line", (c-1)*TILE, (r-1)*TILE, TILE, TILE)
        end
    end

    -- Buildings
    for _, b in ipairs(buildings) do
        local bx = (b.col-1)*TILE
        local by = (b.row-1)*TILE
        local bc = BUILD_COLORS[b.type] or {0.8,0.8,0.8}
        lurek.gfx.setColor(bc[1], bc[2], bc[3])
        lurek.gfx.rectangle("fill", bx + 6, by + 6, TILE - 12, TILE - 12)
        lurek.gfx.setColor(0, 0, 0, 0.6)
        lurek.gfx.rectangle("line", bx + 6, by + 6, TILE - 12, TILE - 12)
        -- Label
        lurek.gfx.setColor(0, 0, 0, 0.8)
        local short = b.type:sub(1, 2)
        lurek.gfx.print(short, bx + 14, by + 16)
        -- Produce progress bar
        if b.type ~= BTYPE.HQ then
            local pt  = PRODUCE_TIMES[b.type] or 1
            local prog = b.timer / pt
            lurek.gfx.setColor(0.1, 0.8, 0.3, 0.9)
            lurek.gfx.rectangle("fill", bx + 4, by + TILE - 8, (TILE - 8) * prog, 5)
        end
    end

    -- Settlers
    for _, s in ipairs(settlers) do
        lurek.gfx.setColor(0.95, 0.85, 0.55)
        lurek.gfx.circle("fill", s.x, s.y, 5)
        lurek.gfx.setColor(0, 0, 0, 0.6)
        if s.carry then
            lurek.gfx.print(s.carry:sub(1,2), s.x + 4, s.y - 10)
        end
    end

    -- Hover tile highlight
    local mx, my = lurek.input.getPosition()
    local hc = math.floor(mx / TILE) + 1
    local hr = math.floor(my / TILE) + 1
    if hr <= MAP_ROWS and my < MAP_ROWS * TILE then
        local can = can_build(hc, hr) and not building_at(hc, hr)
        lurek.gfx.setColor(1, 1, 0, can and 0.35 or 0.15)
        lurek.gfx.rectangle("fill", (hc-1)*TILE, (hr-1)*TILE, TILE, TILE)
    end

    -- UI panel
    lurek.gfx.setColor(0.12, 0.12, 0.12, 0.88)
    lurek.gfx.rectangle("fill", 0, H - UI_H, W, UI_H)
    lurek.gfx.setColor(0.9, 0.85, 0.55)
    lurek.gfx.print(string.format("Wood:%d  Stone:%d  Food:%d  Logs:%d  Iron:%d",
        resources.wood, resources.stone, resources.food, resources.logs, resources.iron), 10, H - UI_H + 8)
    -- Selected build type
    local sel = BUILD_ORDER[build_index]
    local sc  = COSTS[sel]
    lurek.gfx.setColor(0.7, 0.9, 1)
    lurek.gfx.print(string.format("[Tab] Build: %s  (cost: wood%d stone%d)  [LMB place]",
        sel, sc.wood, sc.stone), 10, H - UI_H + 30)

    -- Settler count badge
    lurek.gfx.setColor(0.2, 0.7, 0.4)
    lurek.gfx.print("Settlers: " .. #settlers, W - 160, H - UI_H + 20)
end

-- ── Mousepressed ──────────────────────────────────────────────────────────
function lurek.mousepressed(x, y, button)
    if button == 1 and y < H - UI_H then
        local c = math.floor(x / TILE) + 1
        local r = math.floor(y / TILE) + 1
        if building_at(c, r) then return end
        if not can_build(c, r) then return end

        local sel = BUILD_ORDER[build_index]
        local cost = COSTS[sel]
        if resources.wood >= cost.wood and resources.stone >= cost.stone then
            resources.wood  = resources.wood  - cost.wood
            resources.stone = resources.stone - cost.stone
            buildings[#buildings+1] = { type=sel, col=c, row=r, timer=0, producing=false }
            tilemap[r][c] = 3    -- mark as road/occupied
        end
    end
end

-- ── Keypressed ────────────────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "tab" then
        build_index = (build_index % #BUILD_ORDER) + 1
    end
end
