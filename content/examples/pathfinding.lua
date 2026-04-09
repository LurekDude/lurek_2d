-- examples/pathfinding.lua
-- lurek.pathfinding — Grid-based A*, flow fields, hierarchical pathfinding,
-- NavGrid, UnitPathfinder, PathGrid, FlowField, and AiFlowField.

-- ── NavGrid ───────────────────────────────────────────────────────────────────

-- newNavGrid(width, height) → NavGrid
-- All cells start walkable (cost 1.0).
local grid = lurek.pathfinding.newNavGrid(40, 30)  -- 40 columns, 30 rows

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
local pf = lurek.pathfinding.newPathfinder(grid)

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
local flow = lurek.pathfinding.newFlowField(grid)

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
local pg = lurek.pathfinding.newPathGrid(80, 60, 16)  -- 80×60 tiles, 16-pixel cells

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
local ai_flow = lurek.pathfinding.newPathFlowField(pg)

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

function lurek.init()
    nav_grid = lurek.pathfinding.newNavGrid(20, 20)
    -- Place some walls
    nav_grid:fillRect(5, 0, 2, 15, true)
    nav_grid:fillRect(8, 5, 2, 15, true)
    nav_grid:setDiagonalMode("whenNotBlocked")
    nav_grid:rebuildAbstract()

    pathfinder = lurek.pathfinding.newPathfinder(nav_grid)
    path_nodes = pathfinder:findPathSmooth(2, 2, 18, 18) or {}
    path_idx = 1
end

function lurek.process(dt)
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

function lurek.render()
    lurek.gfx.setColor(0.3, 0.7, 1.0)
    lurek.gfx.circle("fill", unit_x, unit_y, 8)
end
]]


-- ─── AiFlowField ─────────────────────────────────────────────────────────────
-- AiFlowField layers BFS on top of a PathGrid for crowd pathfinding.
-- Always check hasGoal() before querying distances; an unset field returns 0.

-- hasGoal() → bool — true once compute() has been called with a valid goal position
local goal_ready = ai_flow:hasGoal()          -- false before first compute()
ai_flow:compute(640, 480)                     -- set goal at world position (640, 480)
goal_ready = ai_flow:hasGoal()               -- true

-- getDistance(col, row) → number — BFS cell-distance from (col, row) to the goal
-- Useful for heat-map debug overlays or selecting spawns closest to the player.
if ai_flow:hasGoal() then
    local dist = ai_flow:getDistance(5, 3)    -- e.g. 14 cells from goal in a 20-cell map
end

local aiflowfield_type    = ai_flow:type()                -- "AiFlowField"
local aiflowfield_is_type = ai_flow:typeOf("AiFlowField") -- true

-- ─── FlowField ───────────────────────────────────────────────────────────────
-- FlowField extends basic BFS with integrated costs, directional angles, and the
-- registered target list.  Guard all value queries behind isCalculated().

-- isCalculated() → bool — true after at least one compute() call
local ff_ready = flow:isCalculated()          -- false before compute()
flow:setGoal(20, 15)
flow:compute()
ff_ready = flow:isCalculated()               -- true

-- getTargets() → table — {x,y} goal positions used in the last compute()
-- Inspect to verify multi-goal setups or to draw goal markers on the minimap.
local ff_targets = flow:getTargets()          -- e.g. { {x=20, y=15} }

-- getCostToTarget(x, y) → number — integrated weighted cost from (x,y) to the goal
-- Exceeds raw BFS hop count when tiles have non-default weights (mud, swamp, water).
if flow:isCalculated() then
    local travel_cost = flow:getCostToTarget(5, 3)  -- weighted cost sum to goal
end

-- getDirectionAngle(x, y) → number — flow direction in radians (0 = +x axis)
-- Convert to a unit vector to orient unit sprites or steer crowd particles.
local angle   = flow:getDirectionAngle(5, 3)  -- e.g. 0.46 rad (≈27° toward goal)
local steer_x = math.cos(angle)
local steer_y = math.sin(angle)

local flowfield_type    = flow:type()             -- "FlowField"
local flowfield_is_type = flow:typeOf("FlowField") -- true

-- ─── NavGrid ─────────────────────────────────────────────────────────────────
-- NavGrid state accessors used after initial setup.  Read getChunkSize() to
-- confirm the HPA★ abstraction granularity before calling rebuildAbstract().

-- getChunkSize() → number — HPA★ chunk size in cells (set by setChunkSize)
local chunk_sz = grid:getChunkSize()     -- 8 (from setChunkSize(8) above)

local navgrid_type    = grid:type()             -- "NavGrid"
local navgrid_is_type = grid:typeOf("NavGrid")  -- true

-- ─── PathGrid ────────────────────────────────────────────────────────────────
-- PathGrid stores world-space cell dimensions.  Use getCellSize() to derive the
-- tile pixel size at runtime instead of hard-coding TILE_SIZE in game scripts.

-- getCellSize() → number — world-space pixels per cell (fixed at construction time)
local tile_px = pg:getCellSize()         -- 16 px (from newPathGrid(80, 60, 16))

-- setWalkable(col, row, bool) — mark a cell walkable or blocked at runtime
-- Call when a door opens (true) or a destructible obstacle is placed (false).
pg:setWalkable(10, 10, true)             -- re-open a previously blocked doorway
pg:setWalkable(15, 8, false)             -- block a newly spawned barrel obstacle

local pathgrid_type    = pg:type()             -- "PathGrid"
local pathgrid_is_type = pg:typeOf("PathGrid") -- true

-- ─── UnitPathfinder ──────────────────────────────────────────────────────────
-- UnitPathfinder caches A★ results so repeated same-origin / same-goal queries
-- cost nothing after the first call.  Enable for patrol units on fixed routes;
-- disable for one-off scripted movement where cache overhead outweighs savings.

-- isCacheEnabled() → bool — whether results are stored between findPath calls
local caching_on = pf:isCacheEnabled()   -- true by default

-- setCacheMaxSize(n) — cap cache entries to bound memory over long play sessions
pf:setCacheMaxSize(256)                  -- hold at most 256 cached route entries

-- getCacheSize() → number — current entry count; compare against max to tune it
local n_cached = pf:getCacheSize()       -- grows as findPath is called

-- setCacheEnabled(bool) — disable caching for one-shot scripted sequences
pf:setCacheEnabled(false)
-- ... cut-scene or story-driven path queries that will never be repeated ...
pf:setCacheEnabled(true)                 -- restore caching for normal AI gameplay

-- clearCache() — flush all entries after bulk grid edits (opened doors, new walls)
pf:clearCache()                          -- stale cached paths through modified cells are gone

local unitpathfinder_type    = pf:type()                   -- "UnitPathfinder"
local unitpathfinder_is_type = pf:typeOf("UnitPathfinder") -- true

-- ─── lurek.pathfinding module functions ───────────────────────────────────────
-- Module-level helpers for background thread control and TileMap-driven grid creation.

-- getThreadCount() / setThreadCount(n) — background worker threads for pathfinding
-- 0 = synchronous (blocking); raise for large maps with many simultaneously active units.
local worker_threads = lurek.pathfinding.getThreadCount()   -- 0 by default (synchronous)
lurek.pathfinding.setThreadCount(2)    -- offload BFS / A★ computation to 2 workers
lurek.pathfinding.setThreadCount(0)    -- revert to synchronous single-threaded mode

-- newNavGridFromTileMap(tilemap, layer, blocked_gids) → NavGrid
-- Builds a NavGrid directly from a TileMap layer — no manual setBlocked() loop needed.
-- Pass GID integers for tile types that should be treated as solid obstacles.
local world_map  = lurek.tilemap.load("assets/levels/world.lua")
local solid_gids = { 12, 13, 14, 47 }    -- GIDs of wall / water / lava tiles in the atlas
local nav_map    = lurek.pathfinding.newNavGridFromTileMap(world_map, 1, solid_gids)
local map_pf     = lurek.pathfinding.newPathfinder(nav_map)  -- ready to use immediately
