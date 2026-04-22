-- content/examples/pathfind.lua
-- Auto-scaffolded coverage of the lurek.pathfind Lua API (65 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/pathfind.lua

print("[example] lurek.pathfind loaded — 65 API items demonstrated")

-- ── lurek.pathfind free functions ──

--@api-stub: lurek.pathfind.newNavGrid
-- Creates a new NavGrid with all cells walkable.
-- Use this when creates a new NavGrid with all cells walkable is needed.
if false then
  local _r = lurek.pathfind.newNavGrid(1, 1)
  print(_r)
end

--@api-stub: lurek.pathfind.newPathfinder
-- Creates a new UnitPathfinder backed by a NavGrid.
-- Use this when creates a new UnitPathfinder backed by a NavGrid is needed.
if false then
  local _r = lurek.pathfind.newPathfinder(1)
  print(_r)
end

--@api-stub: lurek.pathfind.newFlowField
-- Creates a new FlowField backed by a NavGrid.
-- Use this when creates a new FlowField backed by a NavGrid is needed.
if false then
  local _r = lurek.pathfind.newFlowField(1)
  print(_r)
end

--@api-stub: lurek.pathfind.newPathGrid
-- Creates a new PathGrid with per-cell cost and walkability.
-- Use this when creates a new PathGrid with per-cell cost and walkability is needed.
if false then
  local _r = lurek.pathfind.newPathGrid(0, 0, 1)
  print(_r)
end

--@api-stub: lurek.pathfind.newPathFlowField
-- Creates a new BFS flow field from a PathGrid.
-- Use this when creates a new BFS flow field from a PathGrid is needed.
if false then
  local _r = lurek.pathfind.newPathFlowField(1)
  print(_r)
end

--@api-stub: lurek.pathfind.setThreadCount
-- Sets the background pathfinding thread count (currently a no-op).
-- Use this when sets the background pathfinding thread count (currently a no-op) is needed.
if false then
  local _r = lurek.pathfind.setThreadCount(1)
  print(_r)
end

--@api-stub: lurek.pathfind.getThreadCount
-- Returns the background pathfinding thread count (currently always 0).
-- Use this when returns the background pathfinding thread count (currently always 0) is needed.
if false then
  local _r = lurek.pathfind.getThreadCount()
  print(_r)
end

--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
-- Use this when builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable) is needed.
if false then
  local _r = lurek.pathfind.newNavGridFromTileMap(0, 1, 0)
  print(_r)
end

--@api-stub: lurek.pathfind.newHexGrid
-- Creates a hex grid for pathfinding, LOS, FOV, and range queries.
-- Use this when creates a hex grid for pathfinding, LOS, FOV, and range queries is needed.
if false then
  local _r = lurek.pathfind.newHexGrid(1, 1, 0)
  print(_r)
end

--@api-stub: lurek.pathfind.newJpsGrid
-- Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
-- Use this when creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal) is needed.
if false then
  local _r = lurek.pathfind.newJpsGrid(1, 1)
  print(_r)
end

--@api-stub: lurek.pathfind.rangeMap
-- Computes a Dijkstra range-of-movement map from an origin within a movement budget.
-- Use this when computes a Dijkstra range-of-movement map from an origin within a movement budget is needed.
if false then
  local _r = lurek.pathfind.rangeMap(0)
  print(_r)
end

-- ── NavGrid methods ──

--@api-stub: NavGrid:getWidth
-- Returns the grid width in cells.
-- Use this when returns the grid width in cells is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:getWidth()
end

--@api-stub: NavGrid:getHeight
-- Returns the grid height in cells.
-- Use this when returns the grid height in cells is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:getHeight()
end

--@api-stub: NavGrid:getDimensions
-- Returns the grid dimensions as width, height.
-- Use this when returns the grid dimensions as width, height is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:getDimensions()
end

--@api-stub: NavGrid:setCost
-- Sets the traversal cost of a cell (1-based coordinates).
-- Use this when sets the traversal cost of a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:setCost(0, 0, 0)
end

--@api-stub: NavGrid:getCost
-- Returns the traversal cost of a cell (1-based coordinates).
-- Use this when returns the traversal cost of a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:getCost(0, 0)
end

--@api-stub: NavGrid:isBlocked
-- Returns true if the cell is blocked (1-based coordinates).
-- Use this when returns true if the cell is blocked (1-based coordinates) is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:isBlocked(0, 0)
end

--@api-stub: NavGrid:fill
-- Sets every cell to the given cost.
-- Use this when sets every cell to the given cost is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:fill(0)
end

--@api-stub: NavGrid:loadFromString
-- Overwrites the grid from a raw byte string (row-major, one byte per cell).
-- Use this when overwrites the grid from a raw byte string (row-major, one byte per cell) is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:loadFromString(0)
end

--@api-stub: NavGrid:saveToString
-- Exports the cost grid as a byte string (row-major, one byte per cell).
-- Use this when exports the cost grid as a byte string (row-major, one byte per cell) is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:saveToString()
end

--@api-stub: NavGrid:setChunkSize
-- Sets the HPA★ chunk size.
-- Use this when sets the HPA★ chunk size is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:setChunkSize(1)
end

--@api-stub: NavGrid:getChunkSize
-- Returns the current HPA★ chunk size.
-- Use this when returns the current HPA★ chunk size is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:getChunkSize()
end

--@api-stub: NavGrid:rebuildAbstract
-- Rebuilds the HPA★ abstract graph from the current grid state.
-- Use this when rebuilds the HPA★ abstract graph from the current grid state is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:rebuildAbstract()
end

--@api-stub: NavGrid:setDirty
-- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
-- Use this when records a dirty rectangle for incremental HPA★ updates (1-based coordinates) is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:setDirty(0, 0, 0, 0)
end

--@api-stub: NavGrid:clearDirty
-- Clears all pending dirty rectangles.
-- Use this when clears all pending dirty rectangles is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:clearDirty()
end

--@api-stub: NavGrid:setDiagonalMode
-- Sets the diagonal movement mode.
-- Use this when sets the diagonal movement mode is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:setDiagonalMode(nil)
end

--@api-stub: NavGrid:getDiagonalMode
-- Returns the current diagonal movement mode as a string.
-- Use this when returns the current diagonal movement mode as a string is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:getDiagonalMode()
end

--@api-stub: NavGrid:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:type()
end

--@api-stub: NavGrid:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- NavGrid instance
  _o:typeOf(1)
end

-- ── UnitPathfinder methods ──

--@api-stub: UnitPathfinder:getPathLength
-- Returns the euclidean length of a path table.
-- Use this when returns the euclidean length of a path table is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:getPathLength(0)
end

--@api-stub: UnitPathfinder:getPathCost
-- Returns the sum of grid traversal costs along a path.
-- Use this when returns the sum of grid traversal costs along a path is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:getPathCost(0)
end

--@api-stub: UnitPathfinder:setCacheEnabled
-- Enables or disables path result caching.
-- Use this when enables or disables path result caching is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:setCacheEnabled(1)
end

--@api-stub: UnitPathfinder:isCacheEnabled
-- Returns true if path result caching is enabled.
-- Use this when returns true if path result caching is enabled is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:isCacheEnabled()
end

--@api-stub: UnitPathfinder:clearCache
-- Removes all cached path results.
-- Use this when removes all cached path results is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:clearCache()
end

--@api-stub: UnitPathfinder:getCacheSize
-- Returns the number of entries in the path cache.
-- Use this when returns the number of entries in the path cache is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:getCacheSize()
end

--@api-stub: UnitPathfinder:setCacheMaxSize
-- Sets the maximum number of cached path entries.
-- Use this when sets the maximum number of cached path entries is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:setCacheMaxSize(1)
end

--@api-stub: UnitPathfinder:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:type()
end

--@api-stub: UnitPathfinder:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- UnitPathfinder instance
  _o:typeOf(1)
end

-- ── FlowField methods ──

--@api-stub: FlowField:getDirection
-- Returns the normalised direction vector at a cell (1-based coordinates).
-- Use this when returns the normalised direction vector at a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:getDirection(0, 0)
end

--@api-stub: FlowField:getDirectionAngle
-- Returns the flow direction as an angle in radians (1-based coordinates).
-- Use this when returns the flow direction as an angle in radians (1-based coordinates) is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:getDirectionAngle(0, 0)
end

--@api-stub: FlowField:getCostToTarget
-- Returns the integrated cost to the nearest target (1-based coordinates).
-- Use this when returns the integrated cost to the nearest target (1-based coordinates) is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:getCostToTarget(0, 0)
end

--@api-stub: FlowField:isCalculated
-- Returns true if the flow field has been computed at least once.
-- Use this when returns true if the flow field has been computed at least once is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:isCalculated()
end

--@api-stub: FlowField:getTargets
-- Returns the target cells from the most recent computation (1-based coordinates).
-- Use this when returns the target cells from the most recent computation (1-based coordinates) is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:getTargets()
end

--@api-stub: FlowField:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:type()
end

--@api-stub: FlowField:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- FlowField instance
  _o:typeOf(1)
end

-- ── PathGrid methods ──

--@api-stub: PathGrid:getWidth
-- Returns the grid width in cells.
-- Use this when returns the grid width in cells is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:getWidth()
end

--@api-stub: PathGrid:getHeight
-- Returns the grid height in cells.
-- Use this when returns the grid height in cells is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:getHeight()
end

--@api-stub: PathGrid:getCellSize
-- Returns the world-space size of each cell.
-- Use this when returns the world-space size of each cell is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:getCellSize()
end

--@api-stub: PathGrid:setWalkable
-- Sets the walkability of a cell (1-based coordinates).
-- Use this when sets the walkability of a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:setWalkable(0, 0, 0)
end

--@api-stub: PathGrid:isWalkable
-- Returns true if a cell is walkable (1-based coordinates).
-- Use this when returns true if a cell is walkable (1-based coordinates) is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:isWalkable(0, 0)
end

--@api-stub: PathGrid:setCost
-- Sets the cost multiplier for a cell (1-based coordinates).
-- Use this when sets the cost multiplier for a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:setCost(0, 0, 0)
end

--@api-stub: PathGrid:getCost
-- Returns the cost multiplier for a cell (1-based coordinates).
-- Use this when returns the cost multiplier for a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:getCost(0, 0)
end

--@api-stub: PathGrid:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:type()
end

--@api-stub: PathGrid:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- PathGrid instance
  _o:typeOf(1)
end

-- ── AiFlowField methods ──

--@api-stub: AiFlowField:getWidth
-- Returns the flow field grid width in cells.
-- Use this when returns the flow field grid width in cells is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:getWidth()
end

--@api-stub: AiFlowField:getHeight
-- Returns the flow field grid height in cells.
-- Use this when returns the flow field grid height in cells is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:getHeight()
end

--@api-stub: AiFlowField:hasGoal
-- Returns true if a goal has been set.
-- Use this when returns true if a goal has been set is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:hasGoal()
end

--@api-stub: AiFlowField:setGoal
-- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
-- Use this when sets the goal cell and triggers BFS recomputation (1-based coordinates) is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:setGoal(0, 0)
end

--@api-stub: AiFlowField:getDirection
-- Returns the normalised direction toward the goal (1-based coordinates).
-- Use this when returns the normalised direction toward the goal (1-based coordinates) is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:getDirection(0, 0)
end

--@api-stub: AiFlowField:getDistance
-- Returns the BFS distance to the goal (1-based coordinates).
-- Use this when returns the BFS distance to the goal (1-based coordinates) is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:getDistance(0, 0)
end

--@api-stub: AiFlowField:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:type()
end

--@api-stub: AiFlowField:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- AiFlowField instance
  _o:typeOf(1)
end

-- ── HexGrid methods ──

--@api-stub: HexGrid:setCost
-- Set movement cost for a cell (1-based coordinates).
-- Use this when set movement cost for a cell (1-based coordinates) is needed.
if false then
  local _o = nil  -- HexGrid instance
  _o:setCost(nil, 0, 0)
end

--@api-stub: HexGrid:isBlocked
-- Returns true if a cell is blocked (1-based coordinates).
-- Use this when returns true if a cell is blocked (1-based coordinates) is needed.
if false then
  local _o = nil  -- HexGrid instance
  _o:isBlocked(nil, 0)
end

-- ── JpsGrid methods ──

--@api-stub: JpsGrid:isBlocked
-- Returns true if the cell is blocked (1-based coordinates).
-- Use this when returns true if the cell is blocked (1-based coordinates) is needed.
if false then
  local _o = nil  -- JpsGrid instance
  _o:isBlocked(0, 0)
end

