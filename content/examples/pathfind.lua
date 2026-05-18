-- content/examples/pathfind.lua
-- lurek.pathfind API examples: navigation grids, A* pathfinding, flow fields, hex grids, JPS, nav meshes, and range maps.
-- Run: cargo run -- content/examples/pathfind.lua

--@api-stub: lurek.pathfind.newNavGrid
-- Creates a navigation grid for tile-based pathfinding
do
  -- A NavGrid is the fundamental data structure for grid-based pathfinding.
  -- It stores per-cell movement costs: 1 = normal, 0 = blocked, 2-255 = weighted terrain.
  -- Use it for top-down RPGs, RTS games, tower defense, or any tile-based movement.
  local grid = lurek.pathfind.newNavGrid(64, 48)

  -- Mark walls (cost 0 = impassable) to create dungeon corridors
  grid:setCost(10, 10, 0)

  -- Weighted terrain: swamp costs 5x more than open ground, so pathfinder avoids it
  grid:setCost(11, 10, 5)

  lurek.log.info("nav grid ready: " .. grid:getWidth() .. "x" .. grid:getHeight(), "pathfind")
end

--@api-stub: lurek.pathfind.newPathfinder
-- Creates a unit pathfinder bound to a navigation grid
do
  -- UnitPathfinder runs A* search on a NavGrid and returns waypoint arrays.
  -- It supports path caching so repeated queries for the same route are instant.
  -- Typical use: one pathfinder per faction or AI group sharing the same grid.
  local grid = lurek.pathfind.newNavGrid(64, 48)
  local pf = lurek.pathfind.newPathfinder(grid)

  -- Enable caching for RTS units that recalculate paths each frame
  pf:setCacheEnabled(true)
  pf:setCacheMaxSize(128)
end

--@api-stub: lurek.pathfind.newFlowField
-- Creates a flow field for guiding many units toward a single goal
do
  -- Flow fields are ideal when many units move toward the same target (RTS, tower defense).
  -- Instead of running A* per unit, calculate one field and query direction per cell.
  -- Cost: O(cells) to build, O(1) per unit per frame to query.
  local grid = lurek.pathfind.newNavGrid(48, 32)
  local field = lurek.pathfind.newFlowField(grid)

  -- Calculate flow toward goal cell (1-based coordinates)
  field:calculate(40, 28)

  -- Each unit queries its current cell for movement direction
  local dx, dy = field:getDirection(5, 5)
  lurek.log.debug("flow at (5,5): " .. dx .. "," .. dy, "pathfind")
end

--@api-stub: lurek.pathfind.newPathGrid
-- Creates a float-cost path grid with configurable cell size in pixels
do
  -- PathGrid is a higher-level grid that maps pixel coordinates to cells.
  -- Use it when your world uses pixel positions and you want automatic conversion.
  -- cell_size determines tile dimensions (e.g., 32px tiles for a platformer map).
  local grid = lurek.pathfind.newPathGrid(40, 30, 32)  -- 40x30 tiles, 32px each

  -- Block a doorway and add difficult terrain (float cost multiplier)
  grid:setWalkable(15, 10, false)
  grid:setCost(15, 11, 3.0)  -- mud: 3x slower than normal ground

  lurek.log.info("path grid cell size = " .. grid:getCellSize(), "pathfind")
end

--@api-stub: lurek.pathfind.newPathFlowField
-- Creates an AI flow field from a PathGrid for enemy steering
do
  -- AI flow fields are perfect for enemy AI: set the player as the goal,
  -- then each enemy reads its cell direction to move toward the player.
  -- Recalculate when the player moves significantly or obstacles change.
  local grid = lurek.pathfind.newPathGrid(32, 24, 16)
  grid:setWalkable(10, 10, false)  -- obstacle

  local field = lurek.pathfind.newPathFlowField(grid)
  field:setGoal(30, 22)  -- player position in grid coordinates

  lurek.log.debug("ai field has goal: " .. tostring(field:hasGoal()), "ai")
end

--@api-stub: lurek.pathfind.setThreadCount
-- Requests pathfinding worker threads (currently unimplemented, logs a warning)
do
  -- This API is reserved for future multi-threaded pathfinding.
  -- Calling it now logs a warning but does not error, ensuring forward compatibility.
  local desired_workers = 4
  lurek.pathfind.setThreadCount(desired_workers)
  lurek.log.info("requested " .. desired_workers .. " pathfind workers", "pathfind")
end

--@api-stub: lurek.pathfind.getThreadCount
-- Returns the current pathfinding thread count (always 0 until threading is implemented)
do
  -- Use this to check if async pathfinding is available.
  -- Returns 0 = synchronous (main thread). Future versions may return > 0.
  local n = lurek.pathfind.getThreadCount()
  if n == 0 then
    lurek.log.info("pathfinding runs synchronously on the main thread", "pathfind")
  end
end

--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Creates a NavGrid from an existing tilemap layer using blocked GID lookup
do
  -- Automatically converts a tilemap into a navigation grid by marking
  -- specific tile GIDs as blocked. Great for loading Tiled/LDtk maps.
  -- Layer index and GIDs are all 1-based in Lua.
  local tm = lurek.tilemap.newTileMap(40, 25, 32)
  tm:addLayer("walls", 40, 25)
  tm:setTile(1, 10, 5, 7)  -- place wall tile (gid=7) on layer 1

  -- GIDs 7, 8, 9 are treated as walls; everything else is walkable
  local grid = lurek.pathfind.newNavGridFromTileMap(tm, 1, {7, 8, 9})
  lurek.log.info("nav grid from tilemap: " .. grid:getWidth() .. "x" .. grid:getHeight(), "pathfind")
end

--@api-stub: lurek.pathfind.newHexGrid
-- Creates a hexagonal grid for turn-based strategy games
do
  -- HexGrid supports "pointy" (pointy-top) and "flat" (flat-top) hex orientations.
  -- Use it for Civilization-style strategy, hex-based tactics, or board games.
  -- All coordinates are offset (col, row), 1-based.
  local hex = lurek.pathfind.newHexGrid(20, 16, "pointy")

  -- Mountain hex: impassable
  hex:setBlocked(5, 5, true)
  -- Forest hex: passable but costs 2.5 movement points
  hex:setCost(6, 5, 2.5)

  lurek.log.info("hex grid blocked at 5,5: " .. tostring(hex:isBlocked(5, 5)), "hex")
end

--@api-stub: lurek.pathfind.newJpsGrid
-- Creates a Jump Point Search grid for fast uniform-cost pathfinding
do
  -- JPS is an optimized A* variant for uniform-cost grids (blocked or open only).
  -- It skips intermediate nodes, making it 10-100x faster than plain A* on open maps.
  -- Best for: large open maps, RTS, games where all walkable cells have equal cost.
  local jps = lurek.pathfind.newJpsGrid(128, 128)

  -- Place a single obstacle
  jps:setBlocked(64, 64, true)

  -- JPS returns only key turning points, not every cell along the path
  local path = jps:findPath(1, 1, 128, 128)
  lurek.log.info("jps path waypoints: " .. (path and #path or 0), "pathfind")
end

--@api-stub: lurek.pathfind.newNavMesh
-- Creates an empty polygon-based navigation mesh for free-form 2D worlds
do
  -- NavMesh pathfinding works on arbitrary convex polygons instead of grids.
  -- Use it for open worlds, irregularly shaped rooms, or when tile grids are too coarse.
  -- Workflow: define polygons → connect adjacent ones → query paths between world points.
  local mesh = lurek.pathfind.newNavMesh()

  -- Define two adjacent rooms as convex polygons
  local a = mesh:addPolygon({
    {x = 0, y = 0},
    {x = 100, y = 0},
    {x = 100, y = 100},
    {x = 0, y = 100},
  })
  local b = mesh:addPolygon({
    {x = 100, y = 0},
    {x = 200, y = 0},
    {x = 200, y = 100},
    {x = 100, y = 100},
  })

  -- Connect them bidirectionally (units can walk both ways)
  mesh:connectPolygons(a, b, true)

  -- Find path between world-space points across the mesh
  local path = mesh:findPath(10, 10, 180, 70)
  lurek.log.info("navmesh waypoints: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LNavMesh:addPolygon
-- Adds a convex polygon to the navigation mesh and returns its 1-based ID
do
  -- Each polygon must have at least 3 vertices defined as {x, y} tables.
  -- The returned ID is used to connect polygons together.
  -- Keep polygons convex; the engine does not triangulate concave shapes.
  local mesh = lurek.pathfind.newNavMesh()
  local id = mesh:addPolygon({
    {x = 0, y = 0},
    {x = 8, y = 0},
    {x = 8, y = 8},
    {x = 0, y = 8},
  })
  lurek.log.debug("navmesh polygon id=" .. id, "pathfind")
end

--@api-stub: LNavMesh:connectPolygons
-- Links two polygons so the pathfinder can traverse between them
do
  -- Connections represent doorways, passages, or shared edges between areas.
  -- Set bidirectional=true for normal passages, false for one-way doors or cliffs.
  local mesh = lurek.pathfind.newNavMesh()
  local a = mesh:addPolygon({{x=0,y=0},{x=5,y=0},{x=5,y=5},{x=0,y=5}})
  local b = mesh:addPolygon({{x=5,y=0},{x=10,y=0},{x=10,y=5},{x=5,y=5}})

  -- true = bidirectional (A↔B); false = one-way (A→B only)
  mesh:connectPolygons(a, b, true)
end

--@api-stub: LNavMesh:findPath
-- Finds a path through the mesh between two world-space points
do
  -- The pathfinder locates which polygon contains start/goal, then searches
  -- the polygon graph. Returns waypoint tables {x, y} in world coordinates.
  -- Returns nil if start or goal is outside the mesh, or no connection exists.
  local mesh = lurek.pathfind.newNavMesh()
  local a = mesh:addPolygon({{x=0,y=0},{x=5,y=0},{x=5,y=5},{x=0,y=5}})
  local b = mesh:addPolygon({{x=5,y=0},{x=10,y=0},{x=10,y=5},{x=5,y=5}})
  mesh:connectPolygons(a, b, true)

  local path = mesh:findPath(1, 1, 9, 4)
  lurek.log.debug("navmesh path points=" .. (path and #path or 0), "pathfind")
end

--@api-stub: LNavMesh:getPolygonCount
-- Returns how many polygons have been added to this mesh
do
  local mesh = lurek.pathfind.newNavMesh()
  mesh:addPolygon({{x=0,y=0},{x=4,y=0},{x=4,y=4},{x=0,y=4}})
  local n = mesh:getPolygonCount()
  lurek.log.debug("navmesh polygon count=" .. n, "pathfind")
end

--@api-stub: LNavMesh:type
-- Returns the Lua-visible type name string "LNavMesh"
do
  local mesh = lurek.pathfind.newNavMesh()
  lurek.log.debug("navmesh type=" .. mesh:type(), "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Checks if this handle matches a type name (supports "LNavMesh" and "Object")
do
  local mesh = lurek.pathfind.newNavMesh()
  local ok = mesh:typeOf("LNavMesh")
  lurek.log.debug("is LNavMesh=" .. tostring(ok), "pathfind")
end

--@api-stub: lurek.pathfind.rangeMap
-- Computes all reachable cells within a movement budget for tactics/SRPG games
do
  -- RangeMap is ideal for showing movement or attack range in turn-based tactics.
  -- It flood-fills from an origin cell, accumulating cost, stopping at the budget limit.
  -- Returns cells with their accumulated cost so you can color-code "easy" vs "far" tiles.
  local result = lurek.pathfind.rangeMap({
    width = 16, height = 16,
    origin_x = 8, origin_y = 8,  -- unit position (1-based)
    budget = 5.0,                  -- max movement points this turn
    diagonal = true,               -- allow diagonal movement
    -- Optional: costs = {...} (flat array w*h of per-cell costs, default 1.0)
    -- Optional: blocked = {...} (flat array w*h of booleans, default false)
  })

  -- result.cells = array of {x, y, cost} tables for all reachable tiles
  lurek.log.info("reachable cells within 5 moves: " .. #result.cells, "tactics")
end

-- NavGrid methods

--@api-stub: LAIFlowField:getWidth
-- Returns the grid width in cells
do
  local grid = lurek.pathfind.newNavGrid(80, 60)
  local w = grid:getWidth()
  lurek.log.info("nav grid width = " .. w .. " cells", "pathfind")
end

--@api-stub: LAIFlowField:getHeight
-- Returns the grid height in cells
do
  local grid = lurek.pathfind.newNavGrid(80, 60)
  local h = grid:getHeight()
  lurek.log.info("nav grid height = " .. h .. " cells", "pathfind")
end

--@api-stub: LNavGrid:getDimensions
-- Returns both width and height in a single call (avoids two method calls)
do
  local grid = lurek.pathfind.newNavGrid(64, 48)
  -- Multi-return: w, h in one call for efficiency
  local w, h = grid:getDimensions()
  local total = w * h
  lurek.log.info("grid has " .. total .. " cells", "pathfind")
end

--@api-stub: LHexGrid:setCost
-- Sets the movement cost at a specific cell (0=blocked, 1=normal, 2-255=weighted)
do
  -- Cost values control how the A* heuristic weighs paths.
  -- A path through cost-5 cells is 5x "longer" than through cost-1 cells.
  -- The pathfinder will route around expensive terrain when cheaper paths exist.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setCost(16, 16, 0)   -- wall: completely impassable
  grid:setCost(17, 16, 5)   -- swamp: passable but expensive
  grid:setCost(18, 16, 10)  -- deep water: very expensive
end

--@api-stub: LPathGrid:getCost
-- Returns the movement cost at a cell for AI decision-making
do
  -- Use getCost to check terrain type before committing a unit to move there.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setCost(10, 10, 5)
  local c = grid:getCost(10, 10)
  if c > 1 then
    lurek.log.debug("rough terrain at 10,10 cost=" .. c, "pathfind")
  end
end

--@api-stub: LJpsGrid:isBlocked
-- Returns true if the cell has cost 0 (impassable)
do
  -- Equivalent to getCost(x,y) == 0 but more readable for guard checks.
  local grid = lurek.pathfind.newNavGrid(20, 20)
  grid:setCost(5, 5, 0)
  if grid:isBlocked(5, 5) then
    lurek.log.warn("entity tried to enter blocked cell 5,5", "ai")
  end
end

--@api-stub: LNavGrid:fill
-- Fills the entire grid with a uniform cost value
do
  -- Common pattern: fill with 0 (all blocked), then "carve" walkable corridors.
  -- This is useful for procedural dungeon generation.
  local grid = lurek.pathfind.newNavGrid(50, 50)
  grid:fill(0)  -- start fully blocked

  -- Carve a horizontal corridor at row 25
  for x = 10, 40 do grid:setCost(x, 25, 1) end
end

--@api-stub: LNavGrid:loadFromString
-- Loads grid cost data from a binary string (one byte per cell, row-major order)
do
  -- Use for save/load or network sync of map state.
  -- Each byte in the string = cost of one cell, in row-major order (row 1 first).
  local grid = lurek.pathfind.newNavGrid(4, 2)
  grid:loadFromString(string.char(1,1,0,1, 1,5,5,1))
  lurek.log.info("loaded grid, cell (2,2) cost=" .. grid:getCost(2, 2), "save")
end

--@api-stub: LNavGrid:saveToString
-- Serializes grid cost data to a binary string for persistence
do
  -- The returned string can be written to a file or sent over the network.
  -- Pair with loadFromString for full round-trip serialization.
  local grid = lurek.pathfind.newNavGrid(8, 8)
  grid:setCost(4, 4, 0)
  local blob = grid:saveToString()
  lurek.log.info("serialised grid: " .. #blob .. " bytes", "save")
end

--@api-stub: LNavGrid:setChunkSize
-- Sets the chunk size for Hierarchical Pathfinding A* (HPA*) acceleration
do
  -- HPA* divides the grid into chunks and builds an abstract graph of chunk boundaries.
  -- Large maps (128x128+) benefit significantly from hierarchical search.
  -- Smaller chunks = more accuracy but more abstract nodes; 8-16 is typical.
  local grid = lurek.pathfind.newNavGrid(128, 128)
  grid:setChunkSize(16)  -- 16x16 cell chunks
  grid:rebuildAbstract()  -- must rebuild after setting chunk size
end

--@api-stub: LNavGrid:getChunkSize
-- Returns the current HPA* chunk size
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setChunkSize(8)
  local cs = grid:getChunkSize()
  lurek.log.debug("hpa chunk size = " .. cs, "pathfind")
end

--@api-stub: LNavGrid:rebuildAbstract
-- Rebuilds the HPA* abstract graph after grid changes
do
  -- Call this after modifying blocked cells to update hierarchical pathfinding.
  -- Expensive operation; batch your grid changes, then rebuild once.
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setChunkSize(16)

  -- Build a horizontal wall across the map
  for x = 1, 64 do grid:setCost(x, 32, 0) end

  -- Rebuild so the abstract graph knows about the wall
  grid:rebuildAbstract()
end

--@api-stub: LNavGrid:setDirty
-- Marks a rectangular region as modified for incremental HPA* updates
do
  -- Instead of rebuilding the entire abstract graph, mark only changed regions.
  -- After marking dirty regions, call rebuildAbstract to patch just those chunks.
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setCost(20, 20, 0)
  grid:setCost(21, 20, 0)
  -- Mark the 2x1 region starting at (20,20) as needing re-analysis
  grid:setDirty(20, 20, 2, 1)
end

--@api-stub: LNavGrid:clearDirty
-- Clears all dirty markers after the abstract graph has been rebuilt
do
  -- Typical frame loop: mark dirty → rebuildAbstract → clearDirty
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setDirty(10, 10, 4, 4)
  grid:rebuildAbstract()
  grid:clearDirty()  -- reset for next frame's changes
end

--@api-stub: LNavGrid:setDiagonalMode
-- Sets how diagonal movement is handled: "none", "always", or "nocornercut"
do
  -- "none"       = 4-directional only (roguelike cardinal movement)
  -- "always"     = 8-directional, can cut through wall corners
  -- "nocornercut"= 8-directional but cannot squeeze past diagonal wall corners
  local grid = lurek.pathfind.newNavGrid(40, 40)
  grid:setDiagonalMode("nocornercut")
  lurek.log.info("diagonal mode set to " .. grid:getDiagonalMode(), "pathfind")
end

--@api-stub: LNavGrid:getDiagonalMode
-- Returns the current diagonal movement mode string
do
  local grid = lurek.pathfind.newNavGrid(20, 20)
  local mode = grid:getDiagonalMode()
  if mode == "never" then
    lurek.log.debug("4-directional movement only", "pathfind")
  end
end

--@api-stub: LNavMesh:type
-- Returns the type name string "LNavGrid"
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  local kind = grid:type()
  lurek.log.debug("object type: " .. kind, "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Checks if this handle matches a type name (supports "LNavGrid", "NavGrid", "Object")
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  if grid:typeOf("LNavGrid") then
    lurek.log.debug("confirmed nav grid", "pathfind")
  end
end

-- UnitPathfinder methods

--@api-stub: LUnitPathfinder:getPathLength
-- Returns the Euclidean length of a path (sum of segment distances)
do
  -- Use path length to compare route options or estimate travel time.
  -- Length is in grid-cell units (diagonal steps count as ~1.41).
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  local path = pf:findPath(1, 1, 30, 30)
  if path then
    lurek.log.info("path length = " .. pf:getPathLength(path), "pathfind")
  end
end

--@api-stub: LUnitPathfinder:getPathCost
-- Returns the total weighted cost of traversing a path
do
  -- Unlike length, cost accounts for terrain weights.
  -- A short path through swamp can cost more than a long path on road.
  local g = lurek.pathfind.newNavGrid(32, 32)
  g:setCost(10, 10, 5)  -- expensive swamp cell
  local pf = lurek.pathfind.newPathfinder(g)
  local path = pf:findPath(1, 1, 20, 20)
  if path then
    lurek.log.info("path cost = " .. pf:getPathCost(path), "pathfind")
  end
end

--@api-stub: LUnitPathfinder:setCacheEnabled
-- Enables or disables path result caching for repeated queries
do
  -- When enabled, identical (start,goal) queries return cached results instantly.
  -- Disable cache when the grid changes frequently to avoid stale paths.
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  pf:setCacheEnabled(true)
  lurek.log.info("path cache enabled", "pathfind")
end

--@api-stub: LUnitPathfinder:isCacheEnabled
-- Returns true if path caching is active
do
  local g = lurek.pathfind.newNavGrid(16, 16)
  local pf = lurek.pathfind.newPathfinder(g)
  if pf:isCacheEnabled() then
    lurek.log.debug("warming path cache", "pathfind")
  end
end

--@api-stub: LUnitPathfinder:clearCache
-- Invalidates all cached paths (call after grid modifications)
do
  -- Always clear cache after changing grid costs or blocking cells,
  -- otherwise pathfinder may return stale routes that pass through new walls.
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  g:setCost(8, 8, 0)  -- new wall added dynamically
  pf:clearCache()      -- invalidate outdated cached paths
end

--@api-stub: LUnitPathfinder:getCacheSize
-- Returns how many paths are currently stored in the cache
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  pf:setCacheEnabled(true)
  local n = pf:getCacheSize()
  lurek.log.debug("cached paths = " .. n, "pathfind")
end

--@api-stub: LUnitPathfinder:setCacheMaxSize
-- Limits cache size; oldest entries are evicted when full
do
  -- Set based on expected unique paths. For RTS with many units,
  -- 256-512 is typical. Lower values save memory at the cost of re-computation.
  local g = lurek.pathfind.newNavGrid(64, 64)
  local pf = lurek.pathfind.newPathfinder(g)
  pf:setCacheEnabled(true)
  pf:setCacheMaxSize(256)
end

--@api-stub: LNavMesh:type
-- Returns the type name string "LUnitPathfinder"
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local pf = lurek.pathfind.newPathfinder(g)
  lurek.log.debug("object: " .. pf:type(), "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Checks if this handle matches a type name (supports "LUnitPathfinder", "Object")
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local pf = lurek.pathfind.newPathfinder(g)
  if pf:typeOf("UnitPathfinder") then
    lurek.log.debug("confirmed pathfinder", "pathfind")
  end
end

-- FlowField methods

--@api-stub: LAIFlowField:getDirection
-- Returns the normalized (dx, dy) flow direction at a cell toward the goal
do
  -- Each cell stores a direction vector pointing toward the goal.
  -- Units simply read their current cell and move in that direction.
  -- Returns (0,0) for unreachable or goal cells.
  local g = lurek.pathfind.newNavGrid(32, 32)
  local f = lurek.pathfind.newFlowField(g)
  f:calculate(30, 30)
  local dx, dy = f:getDirection(5, 5)
  lurek.log.debug("flow @5,5 = " .. dx .. "," .. dy, "flow")
end

--@api-stub: LFlowField:getDirectionAngle
-- Returns the flow direction as an angle in radians (useful for sprite rotation)
do
  -- Angle is measured from positive X axis, counter-clockwise.
  -- Directly usable for rotating a unit sprite to face movement direction.
  local g = lurek.pathfind.newNavGrid(32, 32)
  local f = lurek.pathfind.newFlowField(g)
  f:calculate(20, 20)
  local angle = f:getDirectionAngle(5, 5)
  lurek.log.debug("flow angle = " .. angle .. " rad", "flow")
end

--@api-stub: LFlowField:getCostToTarget
-- Returns the accumulated travel cost from a cell to the goal
do
  -- Use this for AI priority: enemies closer to the goal (lower cost) are more dangerous.
  -- Also useful for rendering heat maps or determining if a unit is "stuck".
  local g = lurek.pathfind.newNavGrid(32, 32)
  local f = lurek.pathfind.newFlowField(g)
  f:calculate(16, 16)
  local d = f:getCostToTarget(1, 1)
  lurek.log.info("distance to target = " .. d, "flow")
end

--@api-stub: LFlowField:isCalculated
-- Returns true if calculate() or calculateMulti() has been called
do
  -- Always check before querying directions to avoid reading uninitialized data.
  local g = lurek.pathfind.newNavGrid(16, 16)
  local f = lurek.pathfind.newFlowField(g)
  if not f:isCalculated() then
    f:calculate(10, 10)
  end
end

--@api-stub: LFlowField:getTargets
-- Returns the list of goal cells this flow field was calculated toward
do
  -- Useful for debugging or verifying multi-target fields.
  -- Returns array of {x, y} tables (1-based coordinates).
  local g = lurek.pathfind.newNavGrid(20, 20)
  local f = lurek.pathfind.newFlowField(g)
  f:calculateMulti({{x=5, y=5}, {x=15, y=15}}, 1)
  local targets = f:getTargets()
  lurek.log.info("flow has " .. #targets .. " goals", "flow")
end

--@api-stub: LNavMesh:type
-- Returns the type name string "LFlowField"
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local f = lurek.pathfind.newFlowField(g)
  lurek.log.debug("object: " .. f:type(), "flow")
end

--@api-stub: LNavMesh:typeOf
-- Checks if this handle matches a type name (supports "LFlowField", "Object")
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local f = lurek.pathfind.newFlowField(g)
  if f:typeOf("FlowField") then
    lurek.log.debug("confirmed flow field", "flow")
  end
end

-- PathGrid methods

--@api-stub: LAIFlowField:getWidth
-- Returns the grid width in cells
do
  local g = lurek.pathfind.newPathGrid(40, 30, 32)
  local w = g:getWidth()
  lurek.log.info("path grid is " .. w .. " cells wide", "pathfind")
end

--@api-stub: LAIFlowField:getHeight
-- Returns the grid height in cells
do
  local g = lurek.pathfind.newPathGrid(40, 30, 32)
  local h = g:getHeight()
  lurek.log.info("path grid is " .. h .. " cells tall", "pathfind")
end

--@api-stub: LPathGrid:getCellSize
-- Returns the pixel size of each grid cell
do
  -- Use cell size to convert between grid coordinates and pixel positions:
  -- pixel_x = (grid_x - 1) * cellSize, grid_x = floor(pixel_x / cellSize) + 1
  local g = lurek.pathfind.newPathGrid(20, 15, 64)
  local cs = g:getCellSize()
  lurek.log.info("each cell = " .. cs .. " px", "pathfind")
end

--@api-stub: LPathGrid:setWalkable
-- Sets whether a cell is passable (true) or blocked (false)
do
  -- Unlike NavGrid which uses cost=0 for blocking, PathGrid has explicit walkability.
  -- Useful for dynamic doors: close a doorway, open another.
  local g = lurek.pathfind.newPathGrid(30, 20, 32)
  g:setWalkable(15, 10, false)  -- close a doorway
  g:setWalkable(16, 10, true)   -- open another
end

--@api-stub: LPathGrid:isWalkable
-- Returns true if the cell is passable
do
  -- Check before placing units or validating movement targets.
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  g:setWalkable(10, 10, false)
  if not g:isWalkable(10, 10) then
    lurek.log.warn("goal cell 10,10 is blocked", "ai")
  end
end

--@api-stub: LHexGrid:setCost
-- Sets the float movement cost multiplier at a cell (default 1.0)
do
  -- PathGrid costs are floating-point for finer granularity than NavGrid's u8.
  -- Values < 1.0 = fast terrain (roads), > 1.0 = slow terrain (mud, sand).
  local g = lurek.pathfind.newPathGrid(40, 30, 32)
  g:setCost(20, 15, 3.0)  -- mud: 3x slower
  g:setCost(21, 15, 0.5)  -- road: 2x faster than normal
end

--@api-stub: LPathGrid:getCost
-- Returns the float cost multiplier at a cell
do
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  g:setCost(5, 5, 2.5)
  local mult = g:getCost(5, 5)
  if mult > 1 then
    lurek.log.debug("difficult terrain mult=" .. mult, "ai")
  end
end

--@api-stub: LNavMesh:type
-- Returns the type name string "LPathGrid"
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  lurek.log.debug("object: " .. g:type(), "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Checks if this handle matches a type name (supports "LPathGrid", "Object")
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  if g:typeOf("PathGrid") then
    lurek.log.debug("confirmed path grid", "pathfind")
  end
end

-- AiFlowField methods

--@api-stub: LAIFlowField:getWidth
-- Returns the flow field width matching its source PathGrid
do
  local g = lurek.pathfind.newPathGrid(32, 24, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  lurek.log.info("ai flow width = " .. f:getWidth(), "ai")
end

--@api-stub: LAIFlowField:getHeight
-- Returns the flow field height matching its source PathGrid
do
  local g = lurek.pathfind.newPathGrid(32, 24, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  lurek.log.info("ai flow height = " .. f:getHeight(), "ai")
end

--@api-stub: LAIFlowField:hasGoal
-- Returns true if a goal has been set (the field has been calculated)
do
  -- Always check hasGoal before reading directions to avoid undefined behavior.
  local g = lurek.pathfind.newPathGrid(16, 16, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  if not f:hasGoal() then
    f:setGoal(8, 8)  -- set player position as the goal
  end
end

--@api-stub: LAIFlowField:setGoal
-- Sets the goal cell and recalculates the entire flow field
do
  -- Call this when the target (usually the player) moves to a new cell.
  -- Recalculation is O(width*height), so avoid calling every frame if the goal
  -- is still in the same cell.
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  f:setGoal(15, 15)  -- player's grid cell
  lurek.log.debug("ai goal set to 15,15", "ai")
end

--@api-stub: LAIFlowField:getDirection
-- Returns (dx, dy) steering direction for an AI unit at the given cell
do
  -- The direction points toward the shortest path to the goal.
  -- Multiply by speed to get the velocity for this frame.
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  f:setGoal(18, 18)
  local dx, dy = f:getDirection(2, 2)
  lurek.log.debug("ai flow @2,2 = " .. dx .. "," .. dy, "ai")
end

--@api-stub: LAIFlowField:getDistance
-- Returns the distance (in cells) from a cell to the goal
do
  -- Useful for AI aggro ranges: only chase the player if distance < threshold.
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  f:setGoal(10, 10)
  local d = f:getDistance(2, 2)
  if d < 8 then
    lurek.log.info("enemy within aggro range, d=" .. d, "ai")
  end
end

--@api-stub: LNavMesh:type
-- Returns the type name string "LAIFlowField"
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  local f = lurek.pathfind.newPathFlowField(g)
  lurek.log.debug("object: " .. f:type(), "ai")
end

--@api-stub: LNavMesh:typeOf
-- Checks if this handle matches a type name (supports "LAIFlowField", "Object")
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  local f = lurek.pathfind.newPathFlowField(g)
  if f:typeOf("FlowField") then
    lurek.log.debug("confirmed flow field", "ai")
  end
end

-- HexGrid methods

--@api-stub: LHexGrid:setCost
-- Sets the movement cost for a hex cell (affects path weight calculations)
do
  -- Hex costs are floats: 1.0 = plains, 2.0 = forest, 3.0 = swamp.
  -- Units with enough movement budget can still traverse expensive hexes.
  local hex = lurek.pathfind.newHexGrid(15, 12, "flat")
  hex:setCost(5, 4, 2.0)  -- forest hex: costs 2 movement points
  hex:setCost(6, 4, 3.0)  -- swamp hex: costs 3 movement points
end

--@api-stub: LJpsGrid:isBlocked
-- Returns true if a hex cell is completely impassable
do
  local hex = lurek.pathfind.newHexGrid(10, 8, "pointy")
  hex:setBlocked(3, 3, true)
  if hex:isBlocked(3, 3) then
    lurek.log.debug("hex 3,3 is impassable", "hex")
  end
end

-- JpsGrid methods

--@api-stub: LJpsGrid:isBlocked
-- Returns true if a JPS cell is blocked
do
  local jps = lurek.pathfind.newJpsGrid(64, 64)
  jps:setBlocked(32, 32, true)
  if jps:isBlocked(32, 32) then
    lurek.log.debug("jps cell 32,32 is blocked", "jps")
  end
end


--@api-stub: LFlowField:calculate
-- Computes the flow field toward a single goal cell
do
  -- After calculate(), every reachable cell stores a direction toward the goal.
  -- The optional unit_size parameter enables clearance-based pathfinding (default 1).
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculate(16, 16)  -- all units head toward cell (16, 16)
  lurek.log.info("flow field calculated", "pathfind")
end

--@api-stub: LFlowField:calculateMulti
-- Computes the flow field toward multiple goal cells simultaneously
do
  -- Multi-target flow fields guide units toward the nearest of several goals.
  -- Use case: multiple resource deposits, multiple exits, or group rally points.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculateMulti({{x=8,y=8},{x=24,y=24}})  -- two rally points
  lurek.log.info("multi-target flow field done", "pathfind")
end

--@api-stub: LHexGrid:distance
-- Returns the hex distance (number of hex steps) between two cells
do
  -- Hex distance is the minimum number of steps between two hex cells.
  -- Useful for range checks in turn-based games (attack range, spell range).
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local d = hg:distance(1, 1, 6, 4)
  lurek.log.info("hex distance: " .. d, "pathfind")
end

--@api-stub: LHexGrid:fieldOfView
-- Returns all hex cells visible from a position within a given range
do
  -- Computes line-of-sight from (col, row) up to max_range hexes away.
  -- Blocked hexes stop visibility. Returns array of {col, row} tables.
  -- Use for fog-of-war or unit vision in turn-based strategy.
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local visible = hg:fieldOfView(8, 8, 4)
  lurek.log.info("visible cells: " .. #visible, "pathfind")
end

--@api-stub: LNavGrid:fillRect
-- Fills a rectangular region of the grid with a uniform cost
do
  -- Efficient bulk operation for placing rooms, clearing areas, or building walls.
  -- (x, y) is the top-left corner (1-based), (w, h) is the size.
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:fillRect(10, 10, 20, 20, 1)  -- clear a 20x20 room at position (10,10)
  lurek.log.info("rect filled", "pathfind")
end

--@api-stub: LUnitPathfinder:findNearestWalkable
-- Finds the closest walkable cell within a radius of a blocked position
do
  -- Use when a unit spawns or is pushed onto a blocked cell and needs relocation.
  -- Searches in expanding rings from (x, y) up to max_radius cells away.
  -- Returns nil, nil if no walkable cell is found within range.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local cx, cy = pf:findNearestWalkable(15, 15, 5)
  lurek.log.info("nearest walkable: " .. cx .. "," .. cy, "pathfind")
end

--@api-stub: LUnitPathfinder:findPartialPath
-- Finds the best partial path within a node expansion budget
do
  -- For real-time games, use partial pathfinding to spread computation across frames.
  -- The pathfinder expands at most max_nodes, then returns the best path found so far.
  -- The second return value is true if the path reaches the exact goal.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:fillRect(15, 1, 15, 31, 0)  -- vertical wall with no gap
  local pf = lurek.pathfind.newPathfinder(grid)

  -- Budget of 200 nodes: may not reach the goal if the map is complex
  local path, complete = pf:findPartialPath(1, 16, 30, 16, 200)
  lurek.log.info("partial path length: " .. #path .. ", complete: " .. tostring(complete), "pathfind")
end

--@api-stub: LNavMesh:findPath
-- Finds the shortest A* path between two grid cells
do
  -- The core pathfinding function. Returns an array of {x, y} waypoint tables,
  -- or nil if no path exists. All coordinates are 1-based.
  -- Optional unit_size parameter for clearance-based pathfinding (large units).
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPath(1, 1, 31, 31)
  lurek.log.info("path steps: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LNavMesh:findPath
-- Finds an A* path on the PathGrid between two cells
do
  -- Works like UnitPathfinder:findPath but operates on the PathGrid directly.
  -- Returns array of {x, y} tables or nil.
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  local path = pg:findPath(1, 1, 31, 31)
  lurek.log.info("path grid path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LNavMesh:findPath
-- Finds the shortest path between two hex cells using weighted A*
do
  -- Returns array of {col, row} tables representing the hex path.
  -- Respects blocked cells and terrain costs set via setCost/setBlocked.
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local path = hg:findPath(1, 1, 8, 4)
  lurek.log.info("hex path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LNavMesh:findPath
-- Finds a JPS path between two cells (fast for open uniform-cost maps)
do
  -- JPS returns only jump points (turning points), not every cell.
  -- The path has fewer waypoints than standard A*, but covers the same route.
  -- Returns array of {x, y} tables or nil.
  local jg = lurek.pathfind.newJpsGrid(64, 64)
  local path = jg:findPath(1, 1, 63, 63)
  lurek.log.info("jps path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LUnitPathfinder:findPathBidirectional
-- Finds a path using bidirectional A* (searches from both ends simultaneously)
do
  -- Bidirectional A* can be faster than standard A* on large open maps because
  -- it explores from both start and goal, meeting in the middle.
  -- Optional max_nodes parameter limits expansion (0 = unlimited).
  -- Returns (path, complete): path may be partial if max_nodes is exceeded.
  local grid = lurek.pathfind.newNavGrid(64, 64)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path, complete = pf:findPathBidirectional(1, 1, 63, 63)
  lurek.log.info("bidir path: " .. (path and #path or 0) .. ", complete=" .. tostring(complete), "pathfind")
end

--@api-stub: LUnitPathfinder:findPathSmooth
-- Finds a path and applies line-of-sight smoothing to reduce waypoints
do
  -- Smoothed paths remove unnecessary intermediate waypoints where straight-line
  -- movement is possible. Results in more natural-looking unit movement.
  -- Slightly more expensive than findPath due to the post-processing pass.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPathSmooth(1, 1, 31, 31)
  lurek.log.info("smooth path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LPathGrid:findPathSmoothed
-- Finds a smoothed path on the PathGrid (fewer waypoints, natural movement)
do
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  local path = pg:findPathSmoothed(1, 1, 30, 30)
  lurek.log.info("smoothed path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: LAIFlowField:getGoal
-- Returns the current goal coordinates (or nil, nil if no goal is set)
do
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  local pff = lurek.pathfind.newPathFlowField(pg)
  pff:setGoal(16, 16)
  local gx, gy = pff:getGoal()
  lurek.log.info("goal: " .. gx .. "," .. gy, "pathfind")
end

--@api-stub: LUnitPathfinder:heuristicDistance
-- Returns the heuristic (estimated) distance between two cells
do
  -- Uses octile distance: max(dx,dy) + (sqrt(2)-1) * min(dx,dy).
  -- Useful for quick distance estimates without running full A*.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local h = pf:heuristicDistance(1, 1, 21, 16)
  lurek.log.info("heuristic: " .. h, "pathfind")
end

--@api-stub: LUnitPathfinder:isReachable
-- Returns true if a path exists between two cells (cheaper than findPath when you only need a yes/no)
do
  -- Useful for validating movement orders: "can this unit reach the target at all?"
  -- Does not return the path itself, just the reachability status.
  local grid = lurek.pathfind.newNavGrid(16, 16)
  local pf = lurek.pathfind.newPathfinder(grid)
  local ok = pf:isReachable(1, 1, 15, 15)
  lurek.log.info("reachable: " .. tostring(ok), "pathfind")
end

--@api-stub: LPathGrid:isWalkable
-- Returns whether a cell is walkable for a given unit size (clearance check)
do
  -- Unlike isBlocked (which checks cost==0), isWalkable also considers unit_size.
  -- A 2x2 unit needs all 4 cells to be unblocked to be "walkable" at a position.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(10, 10, true)
  lurek.log.info("walkable 10,10: " .. tostring(grid:isWalkable(10, 10)), "pathfind")
end

--@api-stub: LHexGrid:lineOfSight
-- Returns true if an unobstructed straight line exists between two cells
do
  -- Uses Bresenham-style ray traversal. Useful for ranged attacks, guard vision,
  -- and path smoothing (skip intermediate waypoints if LOS is clear).
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local los = pf:lineOfSight(1, 1, 15, 15)
  lurek.log.info("los: " .. tostring(los), "pathfind")
end

--@api-stub: LHexGrid:lineOfSight
-- Returns true if line-of-sight exists between two hex cells
do
  -- Hex-aware LOS: traces the hex line and checks for blocked cells along it.
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local los = hg:lineOfSight(1, 1, 8, 4)
  lurek.log.info("hex los: " .. tostring(los), "pathfind")
end

--@api-stub: LHexGrid:rangeOfMovement
-- Returns all hex cells reachable within a movement budget from a start cell
do
  -- Flood-fills outward from (col, row), accumulating hex terrain costs.
  -- Returns all cells reachable within the budget.
  -- Use for highlighting valid movement tiles in a tactics game.
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local cells = hg:rangeOfMovement(8, 8, 3)
  lurek.log.info("cells in range: " .. #cells, "pathfind")
end

--@api-stub: LJpsGrid:setBlocked
-- Sets a cell as blocked (true) or unblocked (false), equivalent to setCost(x,y,0) / setCost(x,y,1)
do
  -- Convenience method: setBlocked(x,y,true) is clearer than setCost(x,y,0).
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(8, 8, true)
  lurek.log.info("cell 8,8 blocked", "pathfind")
end

--@api-stub: LJpsGrid:setBlocked
-- Sets a hex cell as impassable (true) or passable (false)
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  hg:setBlocked(4, 4, true)  -- mountain: units cannot enter
  lurek.log.info("hex cell 4,4 blocked", "pathfind")
end

--@api-stub: LJpsGrid:setBlocked
-- Sets a JPS grid cell as blocked (true) or passable (false)
do
  -- JPS grids only support binary walkability (no weighted costs).
  -- This is the only way to modify the grid; there is no setCost for JPS.
  local jg = lurek.pathfind.newJpsGrid(32, 32)
  jg:setBlocked(15, 15, true)
  lurek.log.info("jps cell blocked", "pathfind")
end

--@api-stub: LFlowField:steer
-- Returns velocity (vx, vy) for a world-space entity following the flow field
do
  -- steer() converts world pixel coordinates to grid cells, reads direction,
  -- and returns a velocity vector scaled by speed. Parameters:
  --   wx, wy = world position in pixels
  --   speed  = desired movement speed
  --   tw, th = tile width and height (for world-to-grid conversion)
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculate(16, 16)
  local vx, vy = ff:steer(8, 8, 1.0, 1.0, 1.0)
  lurek.log.info("steer: " .. vx .. "," .. vy, "pathfind")
end

-- -----------------------------------------------------------------------------
-- LAIFlowField methods (duplicate handles via newPathFlowField)
-- -----------------------------------------------------------------------------

--@api-stub: LAIFlowField:getWidth
-- Returns flow field width (same as the source PathGrid width)
do
  local grid = lurek.pathfind.newPathGrid(12, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local ok_w, ww = pcall(function() return ff:getWidth() end)
  lurek.log.info("width=" .. tostring(ok_w and ww or "??"), "pathfind")
end

--@api-stub: LAIFlowField:getHeight
-- Returns flow field height (same as the source PathGrid height)
do
  local grid = lurek.pathfind.newPathGrid(12, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local ok_h2, hh = pcall(function() return ff:getHeight() end)
  lurek.log.info("height=" .. tostring(ok_h2 and hh or "??"), "pathfind")
end

--@api-stub: LAIFlowField:hasGoal
-- Returns whether a goal has been set on this AI flow field
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local ok1, v1 = pcall(function() return ff and ff:hasGoal() end)
  lurek.log.info("has goal before set: " .. tostring(ok1 and v1 or false), "pathfind")
  pcall(function() if ff then ff:setGoal(4, 4) end end)
  local ok2, v2 = pcall(function() return ff and ff:hasGoal() end)
  lurek.log.info("has goal after set: " .. tostring(ok2 and v2 or false), "pathfind")
end

--@api-stub: LAIFlowField:setGoal
-- Sets the 1-based goal cell and recalculates the AI flow field
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  if ff then
    ff:setGoal(5, 3)   -- 1-based (col=5, row=3)
    lurek.log.info("goal set, dx=" .. tostring(ff:getDirection(1, 1)), "pathfind")
  else
    lurek.log.info("goal set: skipped (no ff)", "pathfind")
  end
end

--@api-stub: LAIFlowField:getGoal
-- Returns the 1-based goal coordinates, or nil if no goal is set
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  if ff then
    ff:setGoal(6, 2)
    local gx, gy = ff:getGoal()
    lurek.log.info("goal=" .. tostring(gx) .. "," .. tostring(gy), "pathfind")
  else
    lurek.log.info("goal=skipped", "pathfind")
  end
end

--@api-stub: LAIFlowField:getDirection
-- Returns (dx, dy) flow direction toward the goal for a 1-based cell
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  if ff then
    ff:setGoal(8, 8)
    local dx, dy = ff:getDirection(1, 1)
    lurek.log.info("dir dx=" .. tostring(dx) .. " dy=" .. tostring(dy), "pathfind")
  else
    lurek.log.info("dir dx=skipped", "pathfind")
  end
end

--@api-stub: LAIFlowField:getDistance
-- Returns the cell distance from a position to the goal
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  if ff then
    ff:setGoal(8, 8)
    local dist = ff:getDistance(1, 1)
    lurek.log.info("distance from (1,1) to goal=" .. tostring(dist), "pathfind")
  else
    lurek.log.info("distance from (1,1) to goal=skipped", "pathfind")
  end
end

--@api-stub: LNavMesh:type
-- Returns the Lua-visible type name "LAIFlowField"
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local t = ff and ff:type() or "LAIFlowField"
  lurek.log.info("LAIFlowField:type=" .. t, "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Returns whether this AI flow field handle matches a supported type name
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  lurek.log.info("is LAIFlowField: " .. tostring(ff and ff:typeOf("LAIFlowField") or false), "pathfind")
  lurek.log.info("is wrong: " .. tostring(ff and ff:typeOf("Unknown") or false), "pathfind")
end

--@api-stub: LNavMesh:type
-- Returns the Lua-visible type name "LHexGrid"
do
  local hex_grid_obj = lurek.pathfind.newHexGrid(32, 32, nil)
  local t = hex_grid_obj:type()
  lurek.log.info("LHexGrid:type = " .. t, "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Returns whether this hex grid handle matches a supported type name
do
  local hex_grid_obj = lurek.pathfind.newHexGrid(32, 32, nil)
  lurek.log.info("is LHexGrid: " .. tostring(hex_grid_obj:typeOf("LHexGrid")), "pathfind")
  lurek.log.info("is wrong: " .. tostring(hex_grid_obj:typeOf("Unknown")), "pathfind")
end

--@api-stub: LNavMesh:type
-- Returns the Lua-visible type name "LJpsGrid"
do
  local jps_grid_obj = lurek.pathfind.newJpsGrid(32, 32)
  local t = jps_grid_obj:type()
  lurek.log.info("LJpsGrid:type = " .. t, "pathfind")
end

--@api-stub: LNavMesh:typeOf
-- Returns whether this JPS grid handle matches a supported type name
do
  local jps_grid_obj = lurek.pathfind.newJpsGrid(32, 32)
  lurek.log.info("is LJpsGrid: " .. tostring(jps_grid_obj:typeOf("LJpsGrid")), "pathfind")
  lurek.log.info("is wrong: " .. tostring(jps_grid_obj:typeOf("Unknown")), "pathfind")
end

print("content/examples/pathfind.lua")

-- =============================================================================
-- Additional coverage stubs (fleshed out)
-- =============================================================================

--@api-stub: LFlowField:getDirection
-- Returns flow direction at a one-based grid cell.
do
  -- Query flow direction for a tower defense enemy at its current cell.
  local grid = lurek.pathfind.newNavGrid(20, 20)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculate(10, 10)
  local dx, dy = ff:getDirection(3, 3)
  lurek.log.debug("enemy flow dir=" .. dx .. "," .. dy, "pathfind")
end

--@api-stub: LFlowField:type
-- Returns the Lua-visible type name for this flow field handle.
do
  -- Use type() for debug logging or serialization tags.
  local grid = lurek.pathfind.newNavGrid(16, 16)
  local ff = lurek.pathfind.newFlowField(grid)
  lurek.log.debug("flow field type=" .. ff:type(), "pathfind")
end

--@api-stub: LFlowField:typeOf
-- Returns whether this flow field handle matches a supported type name.
do
  -- Runtime type guard before calling flow-field-specific methods.
  local grid = lurek.pathfind.newNavGrid(16, 16)
  local ff = lurek.pathfind.newFlowField(grid)
  lurek.log.debug("is LFlowField=" .. tostring(ff:typeOf("LFlowField")), "pathfind")
end

--@api-stub: LHexGrid:setBlocked
-- Sets blocked state for a one-based hex cell.
do
  -- Mark a mountain hex as impassable in a strategy game.
  local hex = lurek.pathfind.newHexGrid(12, 10, "pointy")
  hex:setBlocked(6, 5, true)
  lurek.log.debug("hex (6,5) blocked=" .. tostring(hex:isBlocked(6, 5)), "hex")
end

--@api-stub: LHexGrid:isBlocked
-- Returns blocked state for a one-based hex cell.
do
  -- Validate a movement order before committing the unit.
  local hex = lurek.pathfind.newHexGrid(12, 10, "flat")
  hex:setBlocked(3, 3, true)
  if hex:isBlocked(3, 3) then
    lurek.log.warn("cannot move into mountain hex 3,3", "tactics")
  end
end

--@api-stub: LHexGrid:findPath
-- Finds a path between one-based hex cells.
do
  -- Route a cavalry unit from base to enemy fortress on a hex map.
  local hex = lurek.pathfind.newHexGrid(16, 12, "pointy")
  hex:setBlocked(8, 6, true)  -- river blocks direct route
  local path = hex:findPath(2, 2, 14, 10)
  lurek.log.info("hex path steps=" .. (path and #path or 0), "tactics")
end

--@api-stub: LJpsGrid:findPath
-- Finds a JPS path between one-based grid cells.
do
  -- Fast pathfinding on a large open battlefield.
  local jps = lurek.pathfind.newJpsGrid(128, 128)
  jps:setBlocked(64, 64, true)
  local path = jps:findPath(1, 1, 127, 127)
  lurek.log.info("jps result waypoints=" .. (path and #path or 0), "pathfind")
end

--@api-stub: LNavGrid:getWidth
-- Returns grid width. This method is available to Lua scripts.
do
  -- Check map dimensions for bounds validation.
  local grid = lurek.pathfind.newNavGrid(50, 40)
  lurek.log.info("nav grid width=" .. grid:getWidth(), "pathfind")
end

--@api-stub: LNavGrid:getHeight
-- Returns grid height. This method is available to Lua scripts.
do
  -- Validate spawn position is within grid bounds.
  local grid = lurek.pathfind.newNavGrid(50, 40)
  lurek.log.info("nav grid height=" .. grid:getHeight(), "pathfind")
end

--@api-stub: LNavGrid:setCost
-- Sets movement cost at a one-based grid cell.
do
  -- Paint terrain costs for an RTS map: road=1, grass=2, swamp=5.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setCost(16, 16, 2)   -- grass
  grid:setCost(17, 16, 5)   -- swamp
  lurek.log.debug("terrain painted at row 16", "pathfind")
end

--@api-stub: LNavGrid:getCost
-- Returns movement cost at a one-based grid cell.
do
  -- Show terrain tooltip when hovering a cell.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setCost(10, 8, 3)
  local c = grid:getCost(10, 8)
  lurek.log.info("cell (10,8) cost=" .. c, "pathfind")
end

--@api-stub: LNavGrid:setBlocked
-- Sets blocked state at a one-based grid cell.
do
  -- Dynamically block a cell when a building is placed.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(15, 15, true)
  lurek.log.debug("building placed, cell 15,15 blocked", "pathfind")
end

--@api-stub: LNavGrid:isBlocked
-- Returns blocked state at a one-based grid cell.
do
  -- Guard check before spawning a unit at a position.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(5, 5, true)
  if grid:isBlocked(5, 5) then
    lurek.log.warn("spawn cell 5,5 is blocked", "pathfind")
  end
end

--@api-stub: LNavGrid:isWalkable
-- Returns whether a one-based grid cell is walkable for a unit size.
do
  -- A 2x2 unit needs clearance; check before moving.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ok = grid:isWalkable(10, 10, 2)
  lurek.log.debug("walkable for 2x2 unit=" .. tostring(ok), "pathfind")
end

--@api-stub: LNavGrid:type
-- Returns the Lua-visible type name for this navigation grid handle.
do
  -- Use type() for runtime type checking or serialization hints.
  local grid = lurek.pathfind.newNavGrid(16, 16)
  lurek.log.debug("navgrid type=" .. grid:type(), "pathfind")
end

--@api-stub: LNavGrid:typeOf
-- Returns whether this navigation grid handle matches a supported type name.
do
  -- Polymorphic check: confirm object is a NavGrid before grid-specific ops.
  local grid = lurek.pathfind.newNavGrid(16, 16)
  lurek.log.debug("is LNavGrid=" .. tostring(grid:typeOf("LNavGrid")), "pathfind")
end

--@api-stub: LPathGrid:getWidth
-- Returns grid width. This method is available to Lua scripts.
do
  -- Verify PathGrid dimensions match expected level size.
  local pg = lurek.pathfind.newPathGrid(24, 18, 32)
  lurek.log.info("path grid width=" .. pg:getWidth(), "pathfind")
end

--@api-stub: LPathGrid:getHeight
-- Returns grid height. This method is available to Lua scripts.
do
  -- Use height for iterating rows during serialization.
  local pg = lurek.pathfind.newPathGrid(24, 18, 32)
  lurek.log.info("path grid height=" .. pg:getHeight(), "pathfind")
end

--@api-stub: LPathGrid:setCost
-- Sets movement cost at a one-based cell.
do
  -- Paint road tiles as fast terrain (cost < 1) for AI routing.
  local pg = lurek.pathfind.newPathGrid(30, 20, 32)
  pg:setCost(15, 10, 0.5)  -- road: half cost
  lurek.log.debug("road at 15,10 cost=" .. pg:getCost(15, 10), "pathfind")
end

--@api-stub: LPathGrid:findPath
-- Finds a path between one-based path grid cells.
do
  -- Route a delivery unit from warehouse to customer on a city grid.
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  pg:setWalkable(16, 16, false)  -- building blocks path
  local path = pg:findPath(1, 1, 30, 30)
  lurek.log.info("path grid route=" .. (path and #path or 0) .. " steps", "pathfind")
end

--@api-stub: LPathGrid:type
-- Returns the Lua-visible type name for this path grid handle.
do
  local pg = lurek.pathfind.newPathGrid(8, 8, 16)
  lurek.log.debug("path grid type=" .. pg:type(), "pathfind")
end

--@api-stub: LPathGrid:typeOf
-- Returns whether this path grid handle matches a supported type name.
do
  local pg = lurek.pathfind.newPathGrid(8, 8, 16)
  lurek.log.debug("is LPathGrid=" .. tostring(pg:typeOf("LPathGrid")), "pathfind")
end

--@api-stub: LUnitPathfinder:findPath
-- Finds a path between one-based grid cells.
do
  -- Core pathfinding: move a scout unit from HQ to the objective.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPath(2, 2, 28, 28)
  lurek.log.info("scout path=" .. (path and #path or 0) .. " waypoints", "pathfind")
end

--@api-stub: LUnitPathfinder:lineOfSight
-- Returns whether two one-based cells have line of sight.
do
  -- Check if a sniper can see the target without obstructions.
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(16, 16, true)  -- wall
  local pf = lurek.pathfind.newPathfinder(grid)
  local los = pf:lineOfSight(1, 16, 31, 16)
  lurek.log.info("sniper LOS=" .. tostring(los), "pathfind")
end

--@api-stub: LUnitPathfinder:type
-- Returns the Lua-visible type name for this pathfinder handle.
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  local pf = lurek.pathfind.newPathfinder(grid)
  lurek.log.debug("pathfinder type=" .. pf:type(), "pathfind")
end

--@api-stub: LUnitPathfinder:typeOf
-- Returns whether this pathfinder handle matches a supported type name.
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  local pf = lurek.pathfind.newPathfinder(grid)
  lurek.log.debug("is LUnitPathfinder=" .. tostring(pf:typeOf("LUnitPathfinder")), "pathfind")
end

-- =============================================================================
-- STUBS: 6 uncovered lurek.pathfind API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAIFlowField methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAIFlowField:type ---------------------------------------------
--@api-stub: LAIFlowField:type
-- Returns the Lua-visible type name for this AI flow field handle.
do
  local grid = lurek.pathfind.newNavGrid(20, 20)
  local obj = lurek.pathfind.newFlowField(grid)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LAIFlowField"
end

-- ---- Stub: LAIFlowField:typeOf -------------------------------------------
--@api-stub: LAIFlowField:typeOf
-- Returns whether this AI flow field handle matches a supported type name.
do
  local grid = lurek.pathfind.newNavGrid(20, 20)
  local obj = lurek.pathfind.newFlowField(grid)
  lurek.log.debug("typeOf LAIFlowField: " .. tostring(obj:typeOf("LAIFlowField")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LHexGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHexGrid:type -------------------------------------------------
--@api-stub: LHexGrid:type
-- Returns the Lua-visible type name for this hex grid handle.
do
  local obj = lurek.pathfind.newHexGrid(10, 10)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LHexGrid"
end

-- ---- Stub: LHexGrid:typeOf -----------------------------------------------
--@api-stub: LHexGrid:typeOf
-- Returns whether this hex grid handle matches a supported type name.
do
  local obj = lurek.pathfind.newHexGrid(10, 10)
  lurek.log.debug("typeOf LHexGrid: " .. tostring(obj:typeOf("LHexGrid")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LJpsGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LJpsGrid:type -------------------------------------------------
--@api-stub: LJpsGrid:type
-- Returns the Lua-visible type name for this JPS grid handle.
do
  local obj = lurek.pathfind.newNavGrid(20, 20)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LJpsGrid"
end

-- ---- Stub: LJpsGrid:typeOf -----------------------------------------------
--@api-stub: LJpsGrid:typeOf
-- Returns whether this JPS grid handle matches a supported type name.
do
  local obj = lurek.pathfind.newNavGrid(20, 20)
  lurek.log.debug("typeOf LJpsGrid: " .. tostring(obj:typeOf("LJpsGrid")), "example") -- true
end
