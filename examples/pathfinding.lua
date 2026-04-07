-- examples/pathfinding.lua
-- luna.pathfinding — Grid-based A*, flow fields, hierarchical pathfinding,
-- NavGrid, UnitPathfinder, PathGrid, FlowField, and AiFlowField.
-- All luna.pathfinding API methods demonstrated with code and comments.

-- ── NavGrid ───────────────────────────────────────────────────────────────────

-- newNavGrid(width, height) → NavGrid
-- All cells start walkable (cost 1.0).
local grid = luna.pathfinding.newNavGrid(40, 30)  -- 40 columns, 30 rows

-- getDimensions() → w, h
local gw, gh = grid:getDimensions()

-- getWidth() / getHeight() → integer
local width  = grid:getWidth()
local height = grid:getHeight()

-- setBlocked(x, y, blocked)  /  isBlocked(x, y) → boolean  [0-based cell coords]
grid:setBlocked(5, 3, true)
local blocked = grid:isBlocked(5, 3)  -- true

-- isWalkable(x, y) → boolean  (shorthand for not isBlocked)
local walkable = grid:isWalkable(5, 3)  -- false

-- setCost(x, y, cost)  /  getCost(x, y) → number
-- Cost > 1 makes cells more expensive to traverse.
grid:setCost(10, 10, 3.0)   -- swamp tile — costs 3× as much as normal
local c = grid:getCost(10, 10)  -- 3.0

-- fill(blocked) — mark every cell walkable or blocked
grid:fill(false)   -- reset all to walkable

-- fillRect(x, y, w, h, blocked)
grid:fillRect(2, 2, 5, 3, true)   -- a wall rectangle

-- setDiagonalMode(mode) / getDiagonalMode() → string
-- Modes: "none" (4-way), "always" (8-way), "whenNotBlocked" (8-way safe)
grid:setDiagonalMode("whenNotBlocked")
local diag = grid:getDiagonalMode()  -- "whenNotBlocked"

-- Serialisation / deserialisation
local serialised = grid:saveToString()    -- compact string representation
grid:loadFromString(serialised)           -- restore from string

-- HPA* (Hierarchical Pathfinding A*) — abstract graph for large maps
-- setChunkSize(size) / getChunkSize() → integer
grid:setChunkSize(8)          -- 8×8 cell chunks for abstraction

-- rebuildAbstract() — must call after setChunkSize or bulk edits before HPA* search
grid:rebuildAbstract()

-- setDirty() / clearDirty() — mark grid as needing abstract rebuild
grid:setDirty()
grid:clearDirty()

-- ── UnitPathfinder (A* + smoothed paths) ─────────────────────────────────────

-- newPathfinder(navGrid) → UnitPathfinder
local pf = luna.pathfinding.newPathfinder(grid)

-- findPath(sx, sy, ex, ey) → {x1,y1, x2,y2, ...}? (nil if unreachable)
-- Returns cell coordinates along the path (0-based).
local path = pf:findPath(0, 0, 38, 28)
if path then
    for i = 1, #path, 2 do
        local cx, cy = path[i], path[i+1]
        -- draw or process each cell
    end
end

-- findPathSmooth(sx, sy, ex, ey) → {x1,y1, ...}? — path with waypoint smoothing
local smooth = pf:findPathSmooth(0, 0, 38, 28)

-- getPathLength(path) → number  — total path cell count
local len = pf:getPathLength(path or {})

-- getPathCost(path) → number  — total cost (sum of cell costs)
local cost = pf:getPathCost(path or {})

-- findPartialPath(sx, sy, ex, ey, maxCells) → {x1,y1, ...}?
-- Returns the closest partial path if the destination is unreachable.
local partial = pf:findPartialPath(0, 0, 38, 28, 100)

-- ── FlowField (BFS from one goal, all paths) ─────────────────────────────────

-- newFlowField(navGrid) → FlowField
-- Efficient for many-to-one pathfinding (all units converge on a target).
local flow = luna.pathfinding.newFlowField(grid)

-- setGoal(x, y) — BFS expands from this cell
flow:setGoal(20, 15)

-- compute() — run BFS, fills all reachable cells
flow:compute()

-- getDirection(x, y) → dx, dy  — unit direction toward goal from cell (x,y)
local dx, dy = flow:getDirection(5, 5)

-- getCost(x, y) → number  — BFS cost to reach goal from (x,y)
local flow_cost = flow:getCost(5, 5)

-- ── PathGrid (weighted A* with cell costs) ────────────────────────────────────

-- newPathGrid(width, height, cellSize) → PathGrid
-- Same as NavGrid but explicitly stores cell sizes for world-space conversions.
local pg = luna.pathfinding.newPathGrid(80, 60, 16)  -- 80×60 tiles, 16-pixel cells

-- setCost(x, y, cost)  /  getCost(x, y) → number
pg:setCost(20, 15, 5.0)  -- mud — expensive

-- setBlocked(x, y, bool)  /  isWalkable(x, y) → boolean
pg:setBlocked(10, 10, true)

-- worldToCell(wx, wy) → cx, cy  — convert world px coords to cell coords
local cx2, cy2 = pg:worldToCell(320, 240)

-- cellToWorld(cx, cy) → wx, wy  — convert cell to world-space center
local wx2, wy2 = pg:cellToWorld(20, 15)

-- findPath(sx, sy, ex, ey) → {wx1,wy1, wx2,wy2, ...}?  in WORLD space
local world_path = pg:findPath(32, 32, 640, 480)

-- ── AiFlowField (BFS from PathGrid for crowd pathfinding) ────────────────────

-- newPathFlowField(pathGrid) → AiFlowField
local ai_flow = luna.pathfinding.newPathFlowField(pg)

-- compute(goalX, goalY) — BFS from world-space goal
ai_flow:compute(640, 480)

-- getFlowDirection(wx, wy) → dx, dy — steering direction at world-space pos
local fd_x, fd_y = ai_flow:getFlowDirection(100, 100)

-- ── Typical Usage: Moving units along a path ──────────────────────────────────

--[[
local nav_grid, pathfinder
local path_nodes = {}
local path_idx = 1
local unit_x, unit_y = 64, 64
local TILE_SIZE = 32

function luna.init()
    nav_grid = luna.pathfinding.newNavGrid(20, 20)
    -- Place some walls
    nav_grid:fillRect(5, 0, 2, 15, true)
    nav_grid:fillRect(8, 5, 2, 15, true)
    nav_grid:setDiagonalMode("whenNotBlocked")
    nav_grid:rebuildAbstract()

    pathfinder = luna.pathfinding.newPathfinder(nav_grid)
    path_nodes = pathfinder:findPathSmooth(2, 2, 18, 18) or {}
    path_idx = 1
end

function luna.process(dt)
    if path_idx <= #path_nodes - 1 then
        local tx = path_nodes[path_idx]   * TILE_SIZE + TILE_SIZE / 2
        local ty = path_nodes[path_idx+1] * TILE_SIZE + TILE_SIZE / 2
        local speed = 120
        local mx = math.min(speed * dt, math.abs(tx - unit_x))
        local my = math.min(speed * dt, math.abs(ty - unit_y))
        unit_x = unit_x + mx * (tx > unit_x and 1 or -1)
        unit_y = unit_y + my * (ty > unit_y and 1 or -1)
        if math.abs(unit_x - tx) < 2 and math.abs(unit_y - ty) < 2 then
            path_idx = path_idx + 2
        end
    end
end

function luna.render()
    luna.gfx.setColor(0.3, 0.7, 1.0)
    luna.gfx.circle("fill", unit_x, unit_y, 8)
end
]]
