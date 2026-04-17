-- content/examples/pathfind.lua
-- Lurek2D lurek.pathfind API Reference
-- Run with: cargo run -- content/examples/pathfind
--
-- Scenario: A strategy game with grid-based movement, flow fields for unit
-- swarms, hex grid navigation for a hex-tile map, JPS for fast long-range
-- pathfinding, and threaded pathfinding for large maps.

print("=== lurek.pathfind — Pathfinding System ===\n")

-- =============================================================================
-- NavGrid — basic grid pathfinding
-- =============================================================================

--@api-stub: lurek.pathfind.newNavGrid
local grid = lurek.pathfind.newNavGrid(50, 50)

--@api-stub: NavGrid:getWidth
print("grid width: " .. grid:getWidth())

--@api-stub: NavGrid:getHeight
print("grid height: " .. grid:getHeight())

--@api-stub: NavGrid:getDimensions
local gw, gh = grid:getDimensions()
print("grid: " .. gw .. "x" .. gh)

--@api-stub: NavGrid:setCost
-- Set movement cost (1 = normal, higher = slower).
grid:setCost(10, 10, 1.0)
grid:setCost(11, 10, 2.0)  -- rough terrain

--@api-stub: NavGrid:getCost
print("cost at (10,10): " .. grid:getCost(10, 10))

--@api-stub: NavGrid:isBlocked
print("blocked at (10,10): " .. tostring(grid:isBlocked(10, 10)))

--@api-stub: NavGrid:fill
-- Block a rectangular wall.
grid:fill(20, 20, 5, 1, -1)

--@api-stub: NavGrid:loadFromString
grid:loadFromString("1111\n1001\n1111")
print("grid loaded from string")

--@api-stub: NavGrid:saveToString
local grid_str = grid:saveToString()
print("grid saved: " .. #grid_str .. " chars")

--@api-stub: NavGrid:setDiagonalMode
grid:setDiagonalMode(true)

--@api-stub: NavGrid:getDiagonalMode
print("diagonal: " .. tostring(grid:getDiagonalMode()))

--@api-stub: NavGrid:setChunkSize
grid:setChunkSize(8)

--@api-stub: NavGrid:getChunkSize
print("chunk size: " .. grid:getChunkSize())

--@api-stub: NavGrid:rebuildAbstract
grid:rebuildAbstract()

--@api-stub: NavGrid:setDirty
grid:setDirty()

--@api-stub: NavGrid:clearDirty
grid:clearDirty()

--@api-stub: NavGrid:type
print("NavGrid type: " .. grid:type())

--@api-stub: NavGrid:typeOf
print("is NavGrid: " .. tostring(grid:typeOf("NavGrid")))

-- =============================================================================
-- NavGrid from Tilemap
-- =============================================================================

--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Create a nav grid directly from a tilemap's collision data.
local tile_grid = lurek.pathfind.newNavGridFromTileMap("assets/maps/dungeon.json")
print("nav grid from tilemap")

-- =============================================================================
-- Pathfinder — A* pathfinding
-- =============================================================================

--@api-stub: lurek.pathfind.newPathfinder
local finder = lurek.pathfind.newPathfinder(grid)

--@api-stub: UnitPathfinder:getPathLength
print("path length: " .. finder:getPathLength())

--@api-stub: UnitPathfinder:getPathCost
print("path cost: " .. finder:getPathCost())

--@api-stub: UnitPathfinder:setCacheEnabled
finder:setCacheEnabled(true)

--@api-stub: UnitPathfinder:isCacheEnabled
print("cache: " .. tostring(finder:isCacheEnabled()))

--@api-stub: UnitPathfinder:clearCache
finder:clearCache()

--@api-stub: UnitPathfinder:getCacheSize
print("cache size: " .. finder:getCacheSize())

--@api-stub: UnitPathfinder:setCacheMaxSize
finder:setCacheMaxSize(1000)

--@api-stub: UnitPathfinder:type
print("UnitPathfinder type: " .. finder:type())

--@api-stub: UnitPathfinder:typeOf
print("is UnitPathfinder: " .. tostring(finder:typeOf("UnitPathfinder")))

-- =============================================================================
-- FlowField — unit swarm movement
-- =============================================================================

--@api-stub: lurek.pathfind.newFlowField
local flow = lurek.pathfind.newFlowField(grid)

--@api-stub: FlowField:getDirection
-- Get the movement direction at a cell for unit steering.
local dx, dy = flow:getDirection(5, 5)
print("flow at (5,5): " .. dx .. "," .. dy)

--@api-stub: FlowField:getDirectionAngle
local angle = flow:getDirectionAngle(5, 5)
print("flow angle: " .. angle)

--@api-stub: FlowField:getCostToTarget
print("cost to target from (5,5): " .. flow:getCostToTarget(5, 5))

--@api-stub: FlowField:isCalculated
print("calculated: " .. tostring(flow:isCalculated()))

--@api-stub: FlowField:getTargets
local targets = flow:getTargets()
print("flow targets: " .. #targets)

--@api-stub: FlowField:type
print("FlowField type: " .. flow:type())

--@api-stub: FlowField:typeOf
print("is FlowField: " .. tostring(flow:typeOf("FlowField")))

-- =============================================================================
-- PathGrid & PathFlowField — alternative grid types
-- =============================================================================

--@api-stub: lurek.pathfind.newPathGrid
local pgrid = lurek.pathfind.newPathGrid(40, 30, 16)

--@api-stub: PathGrid:getWidth
print("path grid: " .. pgrid:getWidth() .. "x" .. pgrid:getHeight())

--@api-stub: PathGrid:getHeight
-- (used above)

--@api-stub: PathGrid:getCellSize
print("cell size: " .. pgrid:getCellSize())

--@api-stub: PathGrid:setWalkable
pgrid:setWalkable(10, 10, true)

--@api-stub: PathGrid:isWalkable
print("walkable (10,10): " .. tostring(pgrid:isWalkable(10, 10)))

--@api-stub: PathGrid:setCost
pgrid:setCost(10, 10, 1.5)

--@api-stub: PathGrid:getCost
print("path grid cost: " .. pgrid:getCost(10, 10))

--@api-stub: PathGrid:type
print("PathGrid type: " .. pgrid:type())

--@api-stub: PathGrid:typeOf
print("is PathGrid: " .. tostring(pgrid:typeOf("PathGrid")))

--@api-stub: lurek.pathfind.newPathFlowField
local pflow = lurek.pathfind.newPathFlowField(pgrid)

--@api-stub: AiFlowField:getWidth
print("ai flow: " .. pflow:getWidth() .. "x" .. pflow:getHeight())

--@api-stub: AiFlowField:getHeight
-- (used above)

--@api-stub: AiFlowField:hasGoal
print("has goal: " .. tostring(pflow:hasGoal()))

--@api-stub: AiFlowField:setGoal
pflow:setGoal(20, 15)

--@api-stub: AiFlowField:getDirection
local adx, ady = pflow:getDirection(5, 5)
print("ai flow dir: " .. adx .. "," .. ady)

--@api-stub: AiFlowField:getDistance
print("distance to goal: " .. pflow:getDistance(5, 5))

--@api-stub: AiFlowField:type
print("AiFlowField type: " .. pflow:type())

--@api-stub: AiFlowField:typeOf
print("is AiFlowField: " .. tostring(pflow:typeOf("AiFlowField")))

-- =============================================================================
-- HexGrid — hex-tile pathfinding
-- =============================================================================

--@api-stub: lurek.pathfind.newHexGrid
local hex = lurek.pathfind.newHexGrid(20, 20)

--@api-stub: HexGrid:setBlocked
hex:setBlocked(5, 5, true)

--@api-stub: HexGrid:isBlocked
print("hex (5,5) blocked: " .. tostring(hex:isBlocked(5, 5)))

--@api-stub: HexGrid:setCost
hex:setCost(10, 10, 2.0)

--@api-stub: HexGrid:findPath
local hex_path = hex:findPath(0, 0, 15, 15)
print("hex path: " .. #hex_path .. " steps")

--@api-stub: HexGrid:lineOfSight
print("LOS (0,0)->(10,10): " .. tostring(hex:lineOfSight(0, 0, 10, 10)))

--@api-stub: HexGrid:fieldOfView
local fov = hex:fieldOfView(10, 10, 5)
print("FOV cells: " .. #fov)

--@api-stub: HexGrid:rangeOfMovement
local reachable = hex:rangeOfMovement(10, 10, 3)
print("reachable in 3 moves: " .. #reachable)

--@api-stub: HexGrid:distance
print("hex dist (0,0)->(5,5): " .. hex:distance(0, 0, 5, 5))

-- =============================================================================
-- JPS Grid — Jump Point Search (fast long-range)
-- =============================================================================

--@api-stub: lurek.pathfind.newJpsGrid
local jps = lurek.pathfind.newJpsGrid(100, 100)

--@api-stub: JpsGrid:setBlocked
jps:setBlocked(50, 50, true)

--@api-stub: JpsGrid:isBlocked
print("JPS (50,50) blocked: " .. tostring(jps:isBlocked(50, 50)))

--@api-stub: JpsGrid:findPath
local jps_path = jps:findPath(0, 0, 99, 99)
print("JPS path: " .. #jps_path .. " steps")

-- =============================================================================
-- Range Map & Threading
-- =============================================================================

--@api-stub: lurek.pathfind.rangeMap
-- Calculate reachable cells within a movement budget.
local range = lurek.pathfind.rangeMap(grid, 10, 10, 5)
print("range map cells: " .. #range)

--@api-stub: lurek.pathfind.setThreadCount
lurek.pathfind.setThreadCount(4)

--@api-stub: lurek.pathfind.getThreadCount
print("pathfind threads: " .. lurek.pathfind.getThreadCount())

print("\n-- pathfind.lua example complete --")
-- content/examples/pathfind.lua
-- Lurek2D lurek.pathfind API Reference
-- Run with: cargo run -- content/examples/pathfind

-- =============================================================================
-- lurek.pathfind — A*, JPS, flow fields, hex grids, nav grids, threading
--
-- Multiple grid types for different game needs: NavGrid (weighted A*),
-- JpsGrid (jump-point search for uniform grids), HexGrid (hex-based),
-- PathGrid (tile-based), and FlowField/AiFlowField for crowd steering.
-- =============================================================================

-- ---- Stub: lurek.pathfind.newNavGrid -------------------------------------
--@api-stub: lurek.pathfind.newNavGrid
-- Create a 20x20 navigation grid for a dungeon crawler.  Each cell has
-- a movement cost (1.0 = normal, higher = slower, 0 = impassable).
local nav = lurek.pathfind.newNavGrid(20, 20)
print("nav grid: " .. nav:getWidth() .. "x" .. nav:getHeight())

-- ---- Stub: lurek.pathfind.newPathfinder ----------------------------------
--@api-stub: lurek.pathfind.newPathfinder
-- Create a pathfinder that works on the nav grid.
local pf = lurek.pathfind.newPathfinder(nav)
print("pathfinder created for nav grid")

-- ---- Stub: lurek.pathfind.newFlowField -----------------------------------
--@api-stub: lurek.pathfind.newFlowField
-- Create a flow field for crowd pathfinding.  All units share one field
-- instead of computing individual A* paths.
local flow = lurek.pathfind.newFlowField(nav)
print("flow field created")

-- ---- Stub: lurek.pathfind.newPathGrid ------------------------------------
--@api-stub: lurek.pathfind.newPathGrid
-- Create a path grid with 32px cell size for tile-based pathfinding.
local pgrid = lurek.pathfind.newPathGrid(20, 20, 32)
print("path grid: " .. pgrid:getWidth() .. "x" .. pgrid:getHeight() .. " cells, " .. pgrid:getCellSize() .. "px")

-- ---- Stub: lurek.pathfind.newPathFlowField -------------------------------
--@api-stub: lurek.pathfind.newPathFlowField
-- Create a flow field for the path grid.
local pflow = lurek.pathfind.newPathFlowField(pgrid)
print("path flow field created")

-- ---- Stub: lurek.pathfind.setThreadCount ---------------------------------
--@api-stub: lurek.pathfind.setThreadCount
-- Use 4 threads for pathfinding to handle many simultaneous requests.
lurek.pathfind.setThreadCount(4)
print("pathfinding threads: 4")

-- ---- Stub: lurek.pathfind.getThreadCount ---------------------------------
--@api-stub: lurek.pathfind.getThreadCount
local threads = lurek.pathfind.getThreadCount()
print("pathfinding thread count: " .. threads)

-- ---- Stub: lurek.pathfind.newNavGridFromTileMap ---------------------------
--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Build a nav grid from a tilemap's collision data.  Solid tiles become
-- impassable cells automatically.
local tm_nav = lurek.pathfind.newNavGridFromTileMap("assets/dungeon.tmx")
print("nav grid from tilemap: " .. tostring(tm_nav))

-- ---- Stub: lurek.pathfind.newHexGrid -------------------------------------
--@api-stub: lurek.pathfind.newHexGrid
-- Create a hex grid for a strategy game with hex-based movement.
local hex = lurek.pathfind.newHexGrid(15, 15)
print("hex grid: 15x15")

-- ---- Stub: lurek.pathfind.newJpsGrid -------------------------------------
--@api-stub: lurek.pathfind.newJpsGrid
-- Create a JPS (Jump Point Search) grid for fast pathfinding on uniform-cost
-- grids.  Much faster than A* when all walkable tiles have the same cost.
local jps = lurek.pathfind.newJpsGrid(20, 20)
print("JPS grid: 20x20")

-- ---- Stub: lurek.pathfind.rangeMap ---------------------------------------
--@api-stub: lurek.pathfind.rangeMap
-- Compute a range map showing all cells reachable within 5 movement points.
-- Used for highlighting valid move destinations in a tactics game.
local rmap = lurek.pathfind.rangeMap(nav, 10, 10, 5)
print("range map from (10,10) with 5 movement: " .. tostring(rmap))


-- =============================================================================
-- NavGrid — weighted A* navigation
-- =============================================================================

-- ---- Stub: NavGrid:getWidth ----------------------------------------------
--@api-stub: NavGrid:getWidth
print("nav width: " .. nav:getWidth())

-- ---- Stub: NavGrid:getHeight ---------------------------------------------
--@api-stub: NavGrid:getHeight
print("nav height: " .. nav:getHeight())

-- ---- Stub: NavGrid:getDimensions -----------------------------------------
--@api-stub: NavGrid:getDimensions
local nw, nh = nav:getDimensions()
print("nav dimensions: " .. nw .. "x" .. nh)

-- ---- Stub: NavGrid:setCost -----------------------------------------------
--@api-stub: NavGrid:setCost
-- Set swamp tiles to cost 3.0 (3x slower to traverse).
nav:setCost(5, 5, 3.0)
print("cell (5,5) cost set to 3.0 (swamp)")

-- ---- Stub: NavGrid:getCost -----------------------------------------------
--@api-stub: NavGrid:getCost
local cost = nav:getCost(5, 5)
print("cell (5,5) cost: " .. cost)

-- ---- Stub: NavGrid:isBlocked ---------------------------------------------
--@api-stub: NavGrid:isBlocked
-- Block a cell to place a wall.
nav:setCost(3, 3, 0)
local blocked = nav:isBlocked(3, 3)
print("cell (3,3) blocked: " .. tostring(blocked))

-- ---- Stub: NavGrid:fill --------------------------------------------------
--@api-stub: NavGrid:fill
-- Fill the entire grid with cost 1.0 (reset to uniform terrain).
nav:fill(1.0)
print("nav grid filled with cost 1.0")

-- ---- Stub: NavGrid:loadFromString ----------------------------------------
--@api-stub: NavGrid:loadFromString
-- Load a grid from a string representation where '#' = wall, '.' = floor.
local map_str = "##########\n#........#\n#..####..#\n#........#\n##########"
nav:loadFromString(map_str, { ["#"] = 0, ["."] = 1.0 })
print("nav grid loaded from string")

-- ---- Stub: NavGrid:saveToString ------------------------------------------
--@api-stub: NavGrid:saveToString
-- Save the grid for debugging or level editing.
local saved = nav:saveToString()
print("saved grid:\n" .. tostring(saved))

-- ---- Stub: NavGrid:setChunkSize ------------------------------------------
--@api-stub: NavGrid:setChunkSize
-- Set the hierarchical chunk size for abstract graph pathfinding on large maps.
nav:setChunkSize(8)
print("chunk size set to 8 for hierarchical pathfinding")

-- ---- Stub: NavGrid:getChunkSize ------------------------------------------
--@api-stub: NavGrid:getChunkSize
print("chunk size: " .. nav:getChunkSize())

-- ---- Stub: NavGrid:rebuildAbstract ---------------------------------------
--@api-stub: NavGrid:rebuildAbstract
-- Rebuild the abstract graph after modifying the grid.  Required before
-- pathfinding on modified large maps.
nav:rebuildAbstract()
print("abstract graph rebuilt")

-- ---- Stub: NavGrid:setDirty ----------------------------------------------
--@api-stub: NavGrid:setDirty
-- Mark the grid as dirty after a batch of changes to trigger lazy rebuild.
nav:setDirty()
print("nav grid marked dirty")

-- ---- Stub: NavGrid:clearDirty --------------------------------------------
--@api-stub: NavGrid:clearDirty
nav:clearDirty()
print("dirty flag cleared")

-- ---- Stub: NavGrid:setDiagonalMode --------------------------------------
--@api-stub: NavGrid:setDiagonalMode
-- Allow diagonal movement for natural-looking paths.
nav:setDiagonalMode("always")
print("diagonal mode: always")

-- ---- Stub: NavGrid:getDiagonalMode ---------------------------------------
--@api-stub: NavGrid:getDiagonalMode
print("diagonal mode: " .. nav:getDiagonalMode())

-- ---- Stub: NavGrid:type --------------------------------------------------
--@api-stub: NavGrid:type
print("type: " .. nav:type())

-- ---- Stub: NavGrid:typeOf ------------------------------------------------
--@api-stub: NavGrid:typeOf
print("is NavGrid: " .. tostring(nav:typeOf("NavGrid")))


-- =============================================================================
-- UnitPathfinder — path queries with caching
-- =============================================================================

-- ---- Stub: UnitPathfinder:getPathLength ----------------------------------
--@api-stub: UnitPathfinder:getPathLength
-- Get the number of waypoints in the last computed path.
local path_len = pf:getPathLength()
print("path length: " .. tostring(path_len) .. " waypoints")

-- ---- Stub: UnitPathfinder:getPathCost ------------------------------------
--@api-stub: UnitPathfinder:getPathCost
-- Get the total movement cost for the last path to show the player
-- how many movement points the trip will consume.
local path_cost = pf:getPathCost()
print("path cost: " .. tostring(path_cost))

-- ---- Stub: UnitPathfinder:setCacheEnabled --------------------------------
--@api-stub: UnitPathfinder:setCacheEnabled
-- Enable path caching to avoid recomputing the same paths every frame.
pf:setCacheEnabled(true)
print("path cache enabled")

-- ---- Stub: UnitPathfinder:isCacheEnabled ---------------------------------
--@api-stub: UnitPathfinder:isCacheEnabled
print("cache enabled: " .. tostring(pf:isCacheEnabled()))

-- ---- Stub: UnitPathfinder:clearCache -------------------------------------
--@api-stub: UnitPathfinder:clearCache
-- Clear the cache when the grid changes (walls added/removed).
pf:clearCache()
print("path cache cleared")

-- ---- Stub: UnitPathfinder:getCacheSize -----------------------------------
--@api-stub: UnitPathfinder:getCacheSize
print("cache size: " .. pf:getCacheSize() .. " entries")

-- ---- Stub: UnitPathfinder:setCacheMaxSize --------------------------------
--@api-stub: UnitPathfinder:setCacheMaxSize
-- Limit cache to 1000 entries to control memory usage.
pf:setCacheMaxSize(1000)
print("cache max size: 1000")

-- ---- Stub: UnitPathfinder:type -------------------------------------------
--@api-stub: UnitPathfinder:type
print("type: " .. pf:type())

-- ---- Stub: UnitPathfinder:typeOf -----------------------------------------
--@api-stub: UnitPathfinder:typeOf
print("is UnitPathfinder: " .. tostring(pf:typeOf("UnitPathfinder")))


-- =============================================================================
-- FlowField — grid-wide direction field for crowd pathfinding
-- =============================================================================

-- ---- Stub: FlowField:getDirection ----------------------------------------
--@api-stub: FlowField:getDirection
-- Get the direction vector at a cell to steer a unit toward the target.
local dx, dy = flow:getDirection(10, 10)
print(string.format("flow direction at (10,10): (%.2f, %.2f)", dx or 0, dy or 0))

-- ---- Stub: FlowField:getDirectionAngle -----------------------------------
--@api-stub: FlowField:getDirectionAngle
-- Get the direction as an angle for rotating a sprite toward the target.
local angle = flow:getDirectionAngle(10, 10)
print(string.format("flow angle at (10,10): %.2f rad", angle or 0))

-- ---- Stub: FlowField:getCostToTarget -------------------------------------
--@api-stub: FlowField:getCostToTarget
-- Read the cost-to-target for AI priority decisions (closer enemies attack first).
local cost_to = flow:getCostToTarget(10, 10)
print("cost to target from (10,10): " .. tostring(cost_to))

-- ---- Stub: FlowField:isCalculated ----------------------------------------
--@api-stub: FlowField:isCalculated
-- Check if the flow field computation is done before using it.
local ready = flow:isCalculated()
print("flow field calculated: " .. tostring(ready))

-- ---- Stub: FlowField:getTargets ------------------------------------------
--@api-stub: FlowField:getTargets
-- List the target cells the flow field leads toward.
local targets = flow:getTargets()
print("flow targets: " .. tostring(#(targets or {})))

-- ---- Stub: FlowField:type ------------------------------------------------
--@api-stub: FlowField:type
print("type: " .. flow:type())

-- ---- Stub: FlowField:typeOf ----------------------------------------------
--@api-stub: FlowField:typeOf
print("is FlowField: " .. tostring(flow:typeOf("FlowField")))


-- =============================================================================
-- AiFlowField — simpler flow field for AI steering
-- =============================================================================

-- ---- Stub: AiFlowField:getWidth ------------------------------------------
--@api-stub: AiFlowField:getWidth
-- Create an AI flow field for enemy crowd movement.
local aiflow = lurek.pathfind.newFlowField(nav)
print("AI flow field width: " .. tostring(aiflow:getWidth()))

-- ---- Stub: AiFlowField:getHeight -----------------------------------------
--@api-stub: AiFlowField:getHeight
print("AI flow field height: " .. tostring(aiflow:getHeight()))

-- ---- Stub: AiFlowField:hasGoal -------------------------------------------
--@api-stub: AiFlowField:hasGoal
print("has goal: " .. tostring(aiflow:hasGoal()))

-- ---- Stub: AiFlowField:setGoal -------------------------------------------
--@api-stub: AiFlowField:setGoal
-- Set the player's position as the flow field goal.  All enemies will
-- steer toward this cell.
aiflow:setGoal(15, 15)
print("flow field goal set to (15, 15)")

-- ---- Stub: AiFlowField:getDirection --------------------------------------
--@api-stub: AiFlowField:getDirection
-- Get the direction an enemy at (5, 5) should move toward the goal.
local adx, ady = aiflow:getDirection(5, 5)
print(string.format("AI direction at (5,5): (%.2f, %.2f)", adx or 0, ady or 0))

-- ---- Stub: AiFlowField:getDistance ----------------------------------------
--@api-stub: AiFlowField:getDistance
-- Use distance to goal for AI aggression scaling (closer = more aggressive).
local dist = aiflow:getDistance(5, 5)
print("distance to goal from (5,5): " .. tostring(dist))

-- ---- Stub: AiFlowField:type ----------------------------------------------
--@api-stub: AiFlowField:type
print("type: " .. aiflow:type())

-- ---- Stub: AiFlowField:typeOf ---------------------------------------------
--@api-stub: AiFlowField:typeOf
print("is AiFlowField: " .. tostring(aiflow:typeOf("AiFlowField")))


-- =============================================================================
-- HexGrid — hexagonal grid pathfinding
-- =============================================================================

-- ---- Stub: HexGrid:setBlocked --------------------------------------------
--@api-stub: HexGrid:setBlocked
-- Block a hex cell to place a mountain tile.
hex:setBlocked(7, 7, true)
print("hex (7,7) blocked (mountain)")

-- ---- Stub: HexGrid:setCost -----------------------------------------------
--@api-stub: HexGrid:setCost
-- Set forest hex cost to 2.0 (slower to traverse).
hex:setCost(5, 5, 2.0)
print("hex (5,5) cost: 2.0 (forest)")

-- ---- Stub: HexGrid:isBlocked ---------------------------------------------
--@api-stub: HexGrid:isBlocked
print("hex (7,7) blocked: " .. tostring(hex:isBlocked(7, 7)))

-- ---- Stub: HexGrid:findPath ----------------------------------------------
--@api-stub: HexGrid:findPath
-- Find a path from (1,1) to (12,12) on the hex grid.
local hex_path = hex:findPath(1, 1, 12, 12)
print("hex path: " .. tostring(#(hex_path or {})) .. " steps")

-- ---- Stub: HexGrid:lineOfSight -------------------------------------------
--@api-stub: HexGrid:lineOfSight
-- Check if two hexes have line of sight (no walls between them).
local los = hex:lineOfSight(1, 1, 10, 10)
print("line of sight (1,1)->(10,10): " .. tostring(los))

-- ---- Stub: HexGrid:fieldOfView -------------------------------------------
--@api-stub: HexGrid:fieldOfView
-- Compute which hexes are visible from (5,5) within radius 4.
local fov = hex:fieldOfView(5, 5, 4)
print("field of view from (5,5) r=4: " .. tostring(#(fov or {})) .. " hexes")

-- ---- Stub: HexGrid:rangeOfMovement ---------------------------------------
--@api-stub: HexGrid:rangeOfMovement
-- Compute reachable hexes within 3 movement points for a unit selection.
local rom = hex:rangeOfMovement(5, 5, 3)
print("range of movement r=3: " .. tostring(#(rom or {})) .. " hexes")

-- ---- Stub: HexGrid:distance ----------------------------------------------
--@api-stub: HexGrid:distance
-- Calculate hex distance for range checks (e.g. attack range).
local hex_dist = hex:distance(1, 1, 5, 5)
print("hex distance (1,1)->(5,5): " .. tostring(hex_dist))


-- =============================================================================
-- JpsGrid — Jump Point Search for uniform grids
-- =============================================================================

-- ---- Stub: JpsGrid:setBlocked --------------------------------------------
--@api-stub: JpsGrid:setBlocked
-- Block cells to create walls in the JPS grid.
jps:setBlocked(10, 10, true)
print("JPS cell (10,10) blocked")

-- ---- Stub: JpsGrid:isBlocked ---------------------------------------------
--@api-stub: JpsGrid:isBlocked
print("JPS (10,10) blocked: " .. tostring(jps:isBlocked(10, 10)))

-- ---- Stub: JpsGrid:findPath ----------------------------------------------
--@api-stub: JpsGrid:findPath
-- JPS pathfinding is 10-50x faster than A* on open grids with uniform costs.
local jps_path = jps:findPath(0, 0, 19, 19)
print("JPS path: " .. tostring(#(jps_path or {})) .. " waypoints")


-- =============================================================================
-- PathGrid — tile-based pathfinding with cell sizes
-- =============================================================================

-- ---- Stub: PathGrid:getWidth ---------------------------------------------
--@api-stub: PathGrid:getWidth
print("path grid width: " .. pgrid:getWidth())

-- ---- Stub: PathGrid:getHeight --------------------------------------------
--@api-stub: PathGrid:getHeight
print("path grid height: " .. pgrid:getHeight())

-- ---- Stub: PathGrid:getCellSize ------------------------------------------
--@api-stub: PathGrid:getCellSize
print("cell size: " .. pgrid:getCellSize() .. " px")

-- ---- Stub: PathGrid:setWalkable ------------------------------------------
--@api-stub: PathGrid:setWalkable
-- Mark a cell as non-walkable to place a building.
pgrid:setWalkable(5, 5, false)
print("cell (5,5) set non-walkable")

-- ---- Stub: PathGrid:isWalkable -------------------------------------------
--@api-stub: PathGrid:isWalkable
print("cell (5,5) walkable: " .. tostring(pgrid:isWalkable(5, 5)))

-- ---- Stub: PathGrid:setCost ----------------------------------------------
--@api-stub: PathGrid:setCost
-- Set mud tile cost higher to make units prefer paved roads.
pgrid:setCost(8, 8, 2.5)
print("cell (8,8) cost: 2.5 (mud)")

-- ---- Stub: PathGrid:getCost ----------------------------------------------
--@api-stub: PathGrid:getCost
print("cell (8,8) cost: " .. pgrid:getCost(8, 8))

-- ---- Stub: PathGrid:type -------------------------------------------------
--@api-stub: PathGrid:type
print("type: " .. pgrid:type())

-- ---- Stub: PathGrid:typeOf -----------------------------------------------
--@api-stub: PathGrid:typeOf
print("is PathGrid: " .. tostring(pgrid:typeOf("PathGrid")))
-- content/examples/pathfind.lua
-- Lurek2D lurek.pathfind API Reference
-- Run with: cargo run -- content/examples/pathfind

-- =============================================================================
-- STUBS: 73 uncovered lurek.pathfind API item(s)
-- =============================================================================

-- ---- Stub: lurek.pathfind.newNavGrid -------------------------------------
--@api-stub: lurek.pathfind.newNavGrid
-- Create a 32x32 NavGrid for a dungeon level where each cell is one
-- 32-pixel tile; walls will be marked blocked after loading the map.
local nav = lurek.pathfind.newNavGrid(32, 32)
print("NavGrid:", nav:getWidth(), "x", nav:getHeight())

-- ---- Stub: lurek.pathfind.newPathfinder ----------------------------------
--@api-stub: lurek.pathfind.newPathfinder
-- Create a UnitPathfinder backed by the dungeon NavGrid so enemy
-- units can request A* paths to the player each combat turn.
local pf = lurek.pathfind.newPathfinder(nav)
print("UnitPathfinder created:", pf ~= nil)

-- ---- Stub: lurek.pathfind.newFlowField -----------------------------------
--@api-stub: lurek.pathfind.newFlowField
-- Create a FlowField over the dungeon grid so swarm enemies all move
-- toward the player without each running their own A* search.
local ff = lurek.pathfind.newFlowField(nav)
print("FlowField created:", ff ~= nil)

-- ---- Stub: lurek.pathfind.newPathGrid ------------------------------------
--@api-stub: lurek.pathfind.newPathGrid
-- Create a 16x16 PathGrid with 64-pixel cells so the AI can plan
-- routes for large vehicles on a coarser resolution grid.
local pg = lurek.pathfind.newPathGrid(16, 16, 64.0)
print("PathGrid cell size:", pg:getCellSize())

-- ---- Stub: lurek.pathfind.newPathFlowField -------------------------------
--@api-stub: lurek.pathfind.newPathFlowField
-- Create a BFS flow field from the PathGrid so the entire army can
-- share one precomputed direction table instead of N individual paths.
local aff = lurek.pathfind.newPathFlowField(pg)
print("AiFlowField created:", aff ~= nil)

-- ---- Stub: lurek.pathfind.setThreadCount ---------------------------------
--@api-stub: lurek.pathfind.setThreadCount
-- Reserve background threads for heavy A* jobs so real-time pathfinding
-- does not block the main game loop during crowded combat.
lurek.pathfind.setThreadCount(2)
print("thread count:", lurek.pathfind.getThreadCount())

-- ---- Stub: lurek.pathfind.getThreadCount ---------------------------------
--@api-stub: lurek.pathfind.getThreadCount
-- Read the thread count at startup to confirm the pathfinding pool
-- was initialised correctly before any combat begins.
print("pathfind threads:", lurek.pathfind.getThreadCount())

-- ---- Stub: lurek.pathfind.newNavGridFromTileMap --------------------------
--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Build the walkability grid directly from the collision TileMap layer
-- so wall tiles are automatically blocked without a manual setup loop.
-- Uses pcall because a real TileMap userdata is needed; falls back to
-- the manual nav grid in all standalone example runs.
local tm_ok, nav_from_tm = pcall(function()
    -- In a real game: local tm = lurek.tilemap.load("assets/dungeon.tmx")
    -- return lurek.pathfind.newNavGridFromTileMap(tm, 1, { 2, 3, 100 })
    return lurek.pathfind.newNavGridFromTileMap(nil, 1, { 2, 3 })
end)
print("newNavGridFromTileMap:", tm_ok and "ok" or "expected (no TileMap in example)")

-- ---- Stub: lurek.pathfind.newHexGrid -------------------------------------
--@api-stub: lurek.pathfind.newHexGrid
-- Create a pointy-top hex grid for a strategy game map so armies can
-- move in six directions with the correct hex distance metric.
local hex = lurek.pathfind.newHexGrid(16, 12, "pointy")
print("HexGrid created:", hex ~= nil)

-- ---- Stub: lurek.pathfind.newJpsGrid -------------------------------------
--@api-stub: lurek.pathfind.newJpsGrid
-- Create a JPS-optimised grid for the open world map so long-range
-- pathfinding over sparse terrain is significantly faster than A*.
local jps = lurek.pathfind.newJpsGrid(32, 32)
print("JpsGrid created:", jps ~= nil)

-- ---- Stub: lurek.pathfind.rangeMap ---------------------------------------
--@api-stub: lurek.pathfind.rangeMap
-- Compute the Dijkstra range-of-movement map from a unit's position
-- with a budget of 4 AP to highlight all reachable tiles this turn.
local range_cells = lurek.pathfind.rangeMap({
    grid   = nav,
    origin = { x = 5, y = 5 },
    budget = 4,
})
print("reachable cells:", range_cells and #range_cells or 0)

-- -----------------------------------------------------------------------------
-- AiFlowField methods
-- -----------------------------------------------------------------------------

aff:setGoal(8, 8)

-- ---- Stub: AiFlowField:getWidth ------------------------------------------
--@api-stub: AiFlowField:getWidth
-- Read the flow field width to confirm it matches the PathGrid
-- dimensions before beginning the flow computation.
print("AiFlowField width:", aff:getWidth())

-- ---- Stub: AiFlowField:getHeight -----------------------------------------
--@api-stub: AiFlowField:getHeight
-- Read the flow field height to set the loop bounds when iterating
-- every cell to visualise the field in the debug overlay.
print("AiFlowField height:", aff:getHeight())

-- ---- Stub: AiFlowField:hasGoal -------------------------------------------
--@api-stub: AiFlowField:hasGoal
-- Guard the getDirection call so a unit only queries the field
-- after a goal has been set and the BFS has run.
print("has goal:", aff:hasGoal())

-- ---- Stub: AiFlowField:setGoal -------------------------------------------
--@api-stub: AiFlowField:setGoal
-- Update the player's cell in the flow field each time they move so
-- every enemy automatically redirects toward the new position.
aff:setGoal(10, 10)
print("goal set, has goal:", aff:hasGoal())

-- ---- Stub: AiFlowField:getDirection --------------------------------------
--@api-stub: AiFlowField:getDirection
-- Read the normalised direction at the enemy's current cell so the
-- physics system can apply the correct movement impulse each frame.
local dx, dy = aff:getDirection(5, 5)
print(string.format("direction at (5,5): (%.2f, %.2f)", dx or 0, dy or 0))

-- ---- Stub: AiFlowField:getDistance ---------------------------------------
--@api-stub: AiFlowField:getDistance
-- Read the BFS distance to decide whether an enemy is close enough
-- to switch from flow-field navigation to direct melee attack.
local dist = aff:getDistance(5, 5)
print("distance to goal:", dist)

-- ---- Stub: AiFlowField:type ----------------------------------------------
--@api-stub: AiFlowField:type
-- Read the type name to confirm a variable holds an AiFlowField
-- before calling goal-specific methods on it.
print("aff type:", aff:type())

-- ---- Stub: AiFlowField:typeOf --------------------------------------------
--@api-stub: AiFlowField:typeOf
-- Check that the object is an AiFlowField before passing it to the
-- AI decision layer that calls getDirection.
print("is AiFlowField:", aff:typeOf("AiFlowField"))

-- -----------------------------------------------------------------------------
-- FlowField methods
-- -----------------------------------------------------------------------------

-- Build a simple wall in the dungeon for LOS and flow demos
for x = 5, 5 do
    for y = 2, 8 do
        nav:setCost(x, y, 255)  -- high cost = wall
    end
end

-- ---- Stub: FlowField:getDirection ----------------------------------------
--@api-stub: FlowField:getDirection
-- Read the normalised direction vector at an enemy cell so they
-- flow toward the player without individual A* searches.
local fdx, fdy = ff:getDirection(3, 3)
print(string.format("ff direction at (3,3): (%.2f, %.2f)", fdx or 0, fdy or 0))

-- ---- Stub: FlowField:getDirectionAngle -----------------------------------
--@api-stub: FlowField:getDirectionAngle
-- Read the direction angle to rotate the enemy sprite toward the
-- player using the engine's sprite rotation parameter.
local angle = ff:getDirectionAngle(3, 3)
print(string.format("flow angle: %.3f rad", angle or 0))

-- ---- Stub: FlowField:getCostToTarget -------------------------------------
--@api-stub: FlowField:getCostToTarget
-- Read the accumulated cost to the target to decide whether to use
-- the primary or a fallback path when cost exceeds a budget.
local cost = ff:getCostToTarget(3, 3)
print("cost to target:", cost)

-- ---- Stub: FlowField:isCalculated ----------------------------------------
--@api-stub: FlowField:isCalculated
-- Guard the getDirection call so enemies only read directions from a
-- field that has been computed for the current player position.
print("ff calculated:", ff:isCalculated())

-- ---- Stub: FlowField:getTargets ------------------------------------------
--@api-stub: FlowField:getTargets
-- Read the target cell list used in the last computation to log which
-- positions were considered goal cells during the BFS.
local targets = ff:getTargets()
print("ff targets:", #targets)

-- ---- Stub: FlowField:type ------------------------------------------------
--@api-stub: FlowField:type
-- Read the type name to confirm a variable holds a FlowField
-- before calling flow-specific methods on it.
print("ff type:", ff:type())

-- ---- Stub: FlowField:typeOf ----------------------------------------------
--@api-stub: FlowField:typeOf
-- Check that the object is a FlowField before registering it in the
-- swarm AI system that calls getDirection each frame.
print("is FlowField:", ff:typeOf("FlowField"))

-- -----------------------------------------------------------------------------
-- HexGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: HexGrid:setBlocked --------------------------------------------
--@api-stub: HexGrid:setBlocked
-- Mark impassable mountain terrain cells as blocked so armies cannot
-- route through them when planning invasion paths.
hex:setBlocked(3, 3, true)
hex:setBlocked(4, 3, true)
print("blocked mountain cells set")

-- ---- Stub: HexGrid:setCost -----------------------------------------------
--@api-stub: HexGrid:setCost
-- Set a higher movement cost on forest cells so cavalry units avoid
-- them when an open-field route exists.
hex:setCost(5, 4, 3)  -- forest costs 3 MP vs 1 for plains
print("forest cost set")

-- ---- Stub: HexGrid:isBlocked ---------------------------------------------
--@api-stub: HexGrid:isBlocked
-- Check whether a cell is blocked before placing a new building so
-- the placement tool rejects mountain tiles immediately.
print("(3,3) blocked:", hex:isBlocked(3, 3))

-- ---- Stub: HexGrid:findPath ----------------------------------------------
--@api-stub: HexGrid:findPath
-- Find the shortest hex path from the capital to the front-line hex
-- to draw the supply-line route on the strategic map.
local hex_path = hex:findPath(1, 1, 8, 6)
print("hex path length:", hex_path and #hex_path or 0)

-- ---- Stub: HexGrid:lineOfSight -------------------------------------------
--@api-stub: HexGrid:lineOfSight
-- Check line of sight from an artillery unit to the target hex to
-- determine whether it can fire without a spotter unit.
local los = hex:lineOfSight(1, 1, 8, 6)
print("hex LOS (1,1)->(8,6):", los)

-- ---- Stub: HexGrid:fieldOfView -------------------------------------------
--@api-stub: HexGrid:fieldOfView
-- Compute the FOV from a scout unit at range 3 to reveal all cells
-- the scout can see and update the fog-of-war mask.
local visible = hex:fieldOfView(5, 5, 3)
print("visible hex cells:", #visible)

-- ---- Stub: HexGrid:rangeOfMovement ---------------------------------------
--@api-stub: HexGrid:rangeOfMovement
-- Compute all hexes reachable within a 3 MP budget to highlight
-- valid move targets for the selected unit.
local reachable = hex:rangeOfMovement(5, 5, 3)
print("reachable hexes:", #reachable)

-- ---- Stub: HexGrid:distance ----------------------------------------------
--@api-stub: HexGrid:distance
-- Read the hex distance between two provinces to determine travel
-- time for supply convoys on the logistics map.
local hdist = hex:distance(1, 1, 8, 6)
print("hex distance (1,1)->(8,6):", hdist)

-- -----------------------------------------------------------------------------
-- JpsGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: JpsGrid:setBlocked --------------------------------------------
--@api-stub: JpsGrid:setBlocked
-- Paint a solid wall column in the JPS grid to model a cliff edge
-- that the pathfinder cannot cross.
for y = 2, 28 do
    jps:setBlocked(10, y, true)
end
print("JPS wall set")

-- ---- Stub: JpsGrid:isBlocked ---------------------------------------------
--@api-stub: JpsGrid:isBlocked
-- Check whether a cell is blocked before the player character moves
-- to provide immediate feedback without running a full path query.
print("jps (10,5) blocked:", jps:isBlocked(10, 5))
print("jps (5,5) blocked:",  jps:isBlocked(5, 5))

-- ---- Stub: JpsGrid:findPath ----------------------------------------------
--@api-stub: JpsGrid:findPath
-- Run a Jump Point Search from the player to a distant waypoint so
-- the route avoids the wall cliff with O(log N) node expansions.
local jps_path = jps:findPath(2, 15, 25, 15)
print("JPS path steps:", jps_path and #jps_path or 0)

-- -----------------------------------------------------------------------------
-- NavGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: NavGrid:getWidth ----------------------------------------------
--@api-stub: NavGrid:getWidth
-- Read width before iterating rows so the loop bound is always
-- consistent with the NavGrid that was loaded from the tilemap.
print("nav width:", nav:getWidth())

-- ---- Stub: NavGrid:getHeight ---------------------------------------------
--@api-stub: NavGrid:getHeight
-- Read height to compute the total cell count for pre-allocating
-- the visibility bitmask used by the fog-of-war system.
print("nav height:", nav:getHeight())

-- ---- Stub: NavGrid:getDimensions -----------------------------------------
--@api-stub: NavGrid:getDimensions
-- Get both dimensions in one call to configure the minimap renderer
-- that overlays the pathfinding grid at the same resolution.
local nw, nh = nav:getDimensions()
print(string.format("nav grid: %dx%d", nw, nh))

-- ---- Stub: NavGrid:setCost -----------------------------------------------
--@api-stub: NavGrid:setCost
-- Assign a cost of 5 to swamp cells so enemies prefer dry land
-- routes even when the swamp path is geometrically shorter.
nav:setCost(8, 8, 5)  -- swamp
print("swamp cost set at (8,8)")

-- ---- Stub: NavGrid:getCost -----------------------------------------------
--@api-stub: NavGrid:getCost
-- Read the cell cost before the AI decides to sprint through it to
-- check if the terrain penalty would exhaust the movement budget.
print("cost at (8,8):", nav:getCost(8, 8))

-- ---- Stub: NavGrid:isBlocked ---------------------------------------------
--@api-stub: NavGrid:isBlocked
-- Check whether a cell is blocked before spawning an enemy on it so
-- spawns never appear inside a wall tile.
nav:setCost(3, 3, 255)  -- block a wall cell
print("(3,3) blocked:", nav:isBlocked(3, 3))

-- ---- Stub: NavGrid:fill --------------------------------------------------
--@api-stub: NavGrid:fill
-- Reset every cell to cost 1 at the start of a new level so the
-- NavGrid from a previous level does not carry stale terrain data.
nav:fill(1)
print("grid filled to cost 1")

-- ---- Stub: NavGrid:loadFromString ----------------------------------------
--@api-stub: NavGrid:loadFromString
-- Restore the precomputed cost grid from a binary save blob so
-- the level loads without re-scanning the tilemap.
local saved_data = nav:saveToString()
nav:loadFromString(saved_data)
print("grid round-tripped via saveToString / loadFromString")

-- ---- Stub: NavGrid:saveToString ------------------------------------------
--@api-stub: NavGrid:saveToString
-- Export the cost grid as a byte string to store it in the save file
-- and avoid recomputing costs from the tilemap each load.
local blob = nav:saveToString()
print("saved grid blob size:", #blob, "bytes")

-- ---- Stub: NavGrid:setChunkSize ------------------------------------------
--@api-stub: NavGrid:setChunkSize
-- Set HPA* chunk size to 8 so each abstract node covers an 8x8 block
-- and reduces memory usage for the 256x256 world grid.
nav:setChunkSize(8)
print("chunk size:", nav:getChunkSize())

-- ---- Stub: NavGrid:getChunkSize ------------------------------------------
--@api-stub: NavGrid:getChunkSize
-- Read the chunk size before rebuilding the abstract graph to confirm
-- the configuration matches the expected tile block size.
print("configured chunk size:", nav:getChunkSize())  -- 8

-- ---- Stub: NavGrid:rebuildAbstract ----------------------------------------
--@api-stub: NavGrid:rebuildAbstract
-- Rebuild the HPA* abstract layer after placing a new set of walls so
-- the hierarchical planner uses an up-to-date graph.
nav:rebuildAbstract()
print("abstract graph rebuilt")

-- ---- Stub: NavGrid:setDirty ----------------------------------------------
--@api-stub: NavGrid:setDirty
-- Mark the cells affected by an explosion as dirty so the incremental
-- HPA* update rebuilds only the blast-radius region.
nav:setDirty(5, 5, 10, 10)
print("dirty region marked")

-- ---- Stub: NavGrid:clearDirty --------------------------------------------
--@api-stub: NavGrid:clearDirty
-- Clear the dirty region after the incremental HPA* rebuild finishes
-- so the next setDirty call starts from a clean state.
nav:clearDirty()
print("dirty cleared")

-- ---- Stub: NavGrid:setDiagonalMode ----------------------------------------
--@api-stub: NavGrid:setDiagonalMode
-- Disable diagonal movement so the dungeon pathfinder only uses
-- the four cardinal directions and units cannot cut through corners.
nav:setDiagonalMode("none")
print("diagonal mode:", nav:getDiagonalMode())

-- ---- Stub: NavGrid:getDiagonalMode ----------------------------------------
--@api-stub: NavGrid:getDiagonalMode
-- Read the diagonal mode to log it in the debug header so the
-- QA team can confirm orthogonal-only is active in playtests.
print("diagonal mode check:", nav:getDiagonalMode())  -- "none"

-- ---- Stub: NavGrid:type --------------------------------------------------
--@api-stub: NavGrid:type
-- Read the type name to validate a variable is a NavGrid before
-- passing it to newPathfinder which requires a NavGrid.
print("nav type:", nav:type())

-- ---- Stub: NavGrid:typeOf ------------------------------------------------
--@api-stub: NavGrid:typeOf
-- Check that the object is a NavGrid before calling getDimensions
-- which is not available on PathGrid or HexGrid objects.
print("is NavGrid:", nav:typeOf("NavGrid"))

-- -----------------------------------------------------------------------------
-- PathGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: PathGrid:getWidth ---------------------------------------------
--@api-stub: PathGrid:getWidth
-- Read the PathGrid width to iterate all columns when building
-- the AiFlowField visualisation texture each frame.
print("PathGrid width:", pg:getWidth())

-- ---- Stub: PathGrid:getHeight --------------------------------------------
--@api-stub: PathGrid:getHeight
-- Read the PathGrid height to compute the vertex count for the
-- debug grid mesh that overlays the navigation area.
print("PathGrid height:", pg:getHeight())

-- ---- Stub: PathGrid:getCellSize ------------------------------------------
--@api-stub: PathGrid:getCellSize
-- Read the cell size to convert between grid coordinates and world
-- pixel coordinates when spawning units from a waypoint table.
print("cell size:", pg:getCellSize())  -- 64.0

-- ---- Stub: PathGrid:setWalkable ------------------------------------------
--@api-stub: PathGrid:setWalkable
-- Mark river cells as unwalkable so large vehicles cannot cross
-- without using a bridge tile.
pg:setWalkable(5, 5, false)
print("(5,5) walkable:", pg:isWalkable(5, 5))

-- ---- Stub: PathGrid:isWalkable -------------------------------------------
--@api-stub: PathGrid:isWalkable
-- Check walkability before placing a building to ensure the chosen
-- cell is not already occupied by a river or cliff.
print("(8,8) walkable:", pg:isWalkable(8, 8))

-- ---- Stub: PathGrid:setCost ----------------------------------------------
--@api-stub: PathGrid:setCost
-- Assign a cost multiplier of 3.0 to rough terrain cells so
-- vehicles prefer smooth road tiles when planning routes.
pg:setCost(7, 7, 3.0)
print("rough terrain cost set at (7,7)")

-- ---- Stub: PathGrid:getCost ----------------------------------------------
--@api-stub: PathGrid:getCost
-- Read the cost multiplier before the route planner chooses between
-- two paths to confirm the terrain penalty is applied correctly.
print("cost at (7,7):", pg:getCost(7, 7))

-- ---- Stub: PathGrid:type -------------------------------------------------
--@api-stub: PathGrid:type
-- Read the type name to validate the object before passing it to
-- newPathFlowField which requires a PathGrid.
print("pg type:", pg:type())

-- ---- Stub: PathGrid:typeOf -----------------------------------------------
--@api-stub: PathGrid:typeOf
-- Check that the object is a PathGrid before calling getCellSize
-- which is a PathGrid-only method unavailable on NavGrid.
print("is PathGrid:", pg:typeOf("PathGrid"))

-- -----------------------------------------------------------------------------
-- UnitPathfinder methods
-- -----------------------------------------------------------------------------

-- Enable the cache so repeated requests from the same origin are served
-- instantly while enemies converge on the player from multiple spawn points.
pf:setCacheEnabled(true)

-- ---- Stub: UnitPathfinder:getPathLength ----------------------------------
--@api-stub: UnitPathfinder:getPathLength
-- Compute the euclidean length of the found path to convert it into
-- an estimated travel time displayed in the strategy UI.
local path = nav:findPath and nav:findPath(1, 1, 30, 30) or {}
local plen = pf:getPathLength(path)
print(string.format("path length: %.2f", plen))

-- ---- Stub: UnitPathfinder:getPathCost ------------------------------------
--@api-stub: UnitPathfinder:getPathCost
-- Sum the traversal costs along a path to display the AP cost of a
-- unit's move before the player commits to the action.
local pcost = pf:getPathCost(path)
print(string.format("path cost: %.2f", pcost))

-- ---- Stub: UnitPathfinder:setCacheEnabled --------------------------------
--@api-stub: UnitPathfinder:setCacheEnabled
-- Enable path caching for the enemy wave so all N enemies can share
-- cached paths from identical origins rather than each running A*.
pf:setCacheEnabled(true)
print("cache enabled:", pf:isCacheEnabled())

-- ---- Stub: UnitPathfinder:isCacheEnabled ---------------------------------
--@api-stub: UnitPathfinder:isCacheEnabled
-- Read the cache state to decide whether to flush it when the player
-- places a new wall that would invalidate all cached routes.
print("cache state:", pf:isCacheEnabled())

-- ---- Stub: UnitPathfinder:clearCache -------------------------------------
--@api-stub: UnitPathfinder:clearCache
-- Clear the path cache after the player places a wall so enemies
-- request fresh paths that route around the new obstacle.
pf:clearCache()
print("cache cleared, size:", pf:getCacheSize())

-- ---- Stub: UnitPathfinder:getCacheSize -----------------------------------
--@api-stub: UnitPathfinder:getCacheSize
-- Read the cache entry count to log a "cache hit rate" metric each
-- wave for the pathfinding performance dashboard.
print("cache size:", pf:getCacheSize())

-- ---- Stub: UnitPathfinder:setCacheMaxSize --------------------------------
--@api-stub: UnitPathfinder:setCacheMaxSize
-- Cap the cache at 256 entries to bound memory usage when many
-- unique origin cells are queried across a large game session.
pf:setCacheMaxSize(256)
print("cache max size set")

-- ---- Stub: UnitPathfinder:type -------------------------------------------
--@api-stub: UnitPathfinder:type
-- Read the type name to validate the variable before passing it to
-- the AI decision module that expects a UnitPathfinder.
print("pf type:", pf:type())

-- ---- Stub: UnitPathfinder:typeOf -----------------------------------------
--@api-stub: UnitPathfinder:typeOf
-- Check that the object is a UnitPathfinder before calling
-- getCacheSize which does not exist on FlowField or NavGrid.
print("is UnitPathfinder:", pf:typeOf("UnitPathfinder"))
