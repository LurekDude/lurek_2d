-- content/examples/pathfind.lua
-- Practical usage examples for the lurek.pathfind API (65 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.pathfind.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/pathfind.lua

print("[example] lurek.pathfind — 65 API entries")

-- ── lurek.pathfind.* free functions ──

--@api-stub: lurek.pathfind.newNavGrid
-- Creates a new NavGrid with all cells walkable.
-- Call when you need to create a new nav grid.
local ok, obj = pcall(function() return lurek.pathfind.newNavGrid(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newNavGrid ok=", ok)

--@api-stub: lurek.pathfind.newPathfinder
-- Creates a new UnitPathfinder backed by a NavGrid.
-- Call when you need to create a new pathfinder.
local ok, obj = pcall(function() return lurek.pathfind.newPathfinder(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newPathfinder ok=", ok)

--@api-stub: lurek.pathfind.newFlowField
-- Creates a new FlowField backed by a NavGrid.
-- Call when you need to create a new flow field.
local ok, obj = pcall(function() return lurek.pathfind.newFlowField(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newFlowField ok=", ok)

--@api-stub: lurek.pathfind.newPathGrid
-- Creates a new PathGrid with per-cell cost and walkability.
-- Call when you need to create a new path grid.
local ok, obj = pcall(function() return lurek.pathfind.newPathGrid(100, 100, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newPathGrid ok=", ok)

--@api-stub: lurek.pathfind.newPathFlowField
-- Creates a new BFS flow field from a PathGrid.
-- Call when you need to create a new path flow field.
local ok, obj = pcall(function() return lurek.pathfind.newPathFlowField(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newPathFlowField ok=", ok)

--@api-stub: lurek.pathfind.setThreadCount
-- Sets the background pathfinding thread count (currently a no-op).
-- Call when you need to assign thread count.
local ok, err = pcall(function() lurek.pathfind.setThreadCount(10) end)
if not ok then print("set skipped:", err) end
print("lurek.pathfind.setThreadCount applied=", ok)

--@api-stub: lurek.pathfind.getThreadCount
-- Returns the background pathfinding thread count (currently always 0).
-- Call when you need to read thread count.
local ok, value = pcall(function() return lurek.pathfind.getThreadCount() end)
local v = ok and value or "(unavailable)"
print("lurek.pathfind.getThreadCount ->", v)

--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
-- Call when you need to create a new nav grid from tile map.
local ok, obj = pcall(function() return lurek.pathfind.newNavGridFromTileMap(nil, 1, {}) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newNavGridFromTileMap ok=", ok)

--@api-stub: lurek.pathfind.newHexGrid
-- Creates a hex grid for pathfinding, LOS, FOV, and range queries.
-- Call when you need to create a new hex grid.
local ok, obj = pcall(function() return lurek.pathfind.newHexGrid(100, 100, "layout_str value") end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newHexGrid ok=", ok)

--@api-stub: lurek.pathfind.newJpsGrid
-- Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
-- Call when you need to create a new jps grid.
local ok, obj = pcall(function() return lurek.pathfind.newJpsGrid(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.pathfind.newJpsGrid ok=", ok)

--@api-stub: lurek.pathfind.rangeMap
-- Computes a Dijkstra range-of-movement map from an origin within a movement budget.
-- Call when you need to invoke range map.
local ok, result = pcall(function() return lurek.pathfind.rangeMap({}) end)
if ok then print("lurek.pathfind.rangeMap ->", result)
else print("unavailable:", result) end

-- ── NavGrid methods ──

--@api-stub: NavGrid:getWidth
-- Returns the grid width in cells.
-- Call when you need to read width.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("NavGrid:getWidth ->", ok, result)
end

--@api-stub: NavGrid:getHeight
-- Returns the grid height in cells.
-- Call when you need to read height.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("NavGrid:getHeight ->", ok, result)
end

--@api-stub: NavGrid:getDimensions
-- Returns the grid dimensions as width, height.
-- Call when you need to read dimensions.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("NavGrid:getDimensions ->", ok, result)
end

--@api-stub: NavGrid:setCost
-- Sets the traversal cost of a cell (1-based coordinates).
-- Call when you need to assign cost.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setCost(0, 0, nil) end)
  print("NavGrid:setCost ->", ok, result)
end

--@api-stub: NavGrid:getCost
-- Returns the traversal cost of a cell (1-based coordinates).
-- Call when you need to read cost.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getCost(0, 0) end)
  print("NavGrid:getCost ->", ok, result)
end

--@api-stub: NavGrid:isBlocked
-- Returns true if the cell is blocked (1-based coordinates).
-- Call when you need to check is blocked.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:isBlocked(0, 0) end)
  print("NavGrid:isBlocked ->", ok, result)
end

--@api-stub: NavGrid:fill
-- Sets every cell to the given cost.
-- Call when you need to invoke fill.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:fill(nil) end)
  print("NavGrid:fill ->", ok, result)
end

--@api-stub: NavGrid:loadFromString
-- Overwrites the grid from a raw byte string (row-major, one byte per cell).
-- Call when you need to load from string.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:loadFromString({}) end)
  print("NavGrid:loadFromString ->", ok, result)
end

--@api-stub: NavGrid:saveToString
-- Exports the cost grid as a byte string (row-major, one byte per cell).
-- Call when you need to invoke save to string.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:saveToString() end)
  print("NavGrid:saveToString ->", ok, result)
end

--@api-stub: NavGrid:setChunkSize
-- Sets the HPA★ chunk size.
-- Call when you need to assign chunk size.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setChunkSize(10) end)
  print("NavGrid:setChunkSize ->", ok, result)
end

--@api-stub: NavGrid:getChunkSize
-- Returns the current HPA★ chunk size.
-- Call when you need to read chunk size.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getChunkSize() end)
  print("NavGrid:getChunkSize ->", ok, result)
end

--@api-stub: NavGrid:rebuildAbstract
-- Rebuilds the HPA★ abstract graph from the current grid state.
-- Call when you need to invoke rebuild abstract.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:rebuildAbstract() end)
  print("NavGrid:rebuildAbstract ->", ok, result)
end

--@api-stub: NavGrid:setDirty
-- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
-- Call when you need to assign dirty.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setDirty(0, 0, 100, 100) end)
  print("NavGrid:setDirty ->", ok, result)
end

--@api-stub: NavGrid:clearDirty
-- Clears all pending dirty rectangles.
-- Call when you need to invoke clear dirty.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:clearDirty() end)
  print("NavGrid:clearDirty ->", ok, result)
end

--@api-stub: NavGrid:setDiagonalMode
-- Sets the diagonal movement mode.
-- Call when you need to assign diagonal mode.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setDiagonalMode(nil) end)
  print("NavGrid:setDiagonalMode ->", ok, result)
end

--@api-stub: NavGrid:getDiagonalMode
-- Returns the current diagonal movement mode as a string.
-- Call when you need to read diagonal mode.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getDiagonalMode() end)
  print("NavGrid:getDiagonalMode ->", ok, result)
end

--@api-stub: NavGrid:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("NavGrid:type ->", ok, result)
end

--@api-stub: NavGrid:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a NavGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newNavGrid(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("NavGrid:typeOf ->", ok, result)
end

-- ── UnitPathfinder methods ──

--@api-stub: UnitPathfinder:getPathLength
-- Returns the euclidean length of a path table.
-- Call when you need to read path length.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:getPathLength("path") end)
  print("UnitPathfinder:getPathLength ->", ok, result)
end

--@api-stub: UnitPathfinder:getPathCost
-- Returns the sum of grid traversal costs along a path.
-- Call when you need to read path cost.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:getPathCost("path") end)
  print("UnitPathfinder:getPathCost ->", ok, result)
end

--@api-stub: UnitPathfinder:setCacheEnabled
-- Enables or disables path result caching.
-- Call when you need to assign cache enabled.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:setCacheEnabled(nil) end)
  print("UnitPathfinder:setCacheEnabled ->", ok, result)
end

--@api-stub: UnitPathfinder:isCacheEnabled
-- Returns true if path result caching is enabled.
-- Call when you need to check is cache enabled.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:isCacheEnabled() end)
  print("UnitPathfinder:isCacheEnabled ->", ok, result)
end

--@api-stub: UnitPathfinder:clearCache
-- Removes all cached path results.
-- Call when you need to invoke clear cache.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:clearCache() end)
  print("UnitPathfinder:clearCache ->", ok, result)
end

--@api-stub: UnitPathfinder:getCacheSize
-- Returns the number of entries in the path cache.
-- Call when you need to read cache size.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:getCacheSize() end)
  print("UnitPathfinder:getCacheSize ->", ok, result)
end

--@api-stub: UnitPathfinder:setCacheMaxSize
-- Sets the maximum number of cached path entries.
-- Call when you need to assign cache max size.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:setCacheMaxSize(10) end)
  print("UnitPathfinder:setCacheMaxSize ->", ok, result)
end

--@api-stub: UnitPathfinder:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("UnitPathfinder:type ->", ok, result)
end

--@api-stub: UnitPathfinder:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a UnitPathfinder via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newUnitPathfinder(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("UnitPathfinder:typeOf ->", ok, result)
end

-- ── FlowField methods ──

--@api-stub: FlowField:getDirection
-- Returns the normalised direction vector at a cell (1-based coordinates).
-- Call when you need to read direction.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getDirection(0, 0) end)
  print("FlowField:getDirection ->", ok, result)
end

--@api-stub: FlowField:getDirectionAngle
-- Returns the flow direction as an angle in radians (1-based coordinates).
-- Call when you need to read direction angle.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getDirectionAngle(0, 0) end)
  print("FlowField:getDirectionAngle ->", ok, result)
end

--@api-stub: FlowField:getCostToTarget
-- Returns the integrated cost to the nearest target (1-based coordinates).
-- Call when you need to read cost to target.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getCostToTarget(0, 0) end)
  print("FlowField:getCostToTarget ->", ok, result)
end

--@api-stub: FlowField:isCalculated
-- Returns true if the flow field has been computed at least once.
-- Call when you need to check is calculated.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:isCalculated() end)
  print("FlowField:isCalculated ->", ok, result)
end

--@api-stub: FlowField:getTargets
-- Returns the target cells from the most recent computation (1-based coordinates).
-- Call when you need to read targets.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getTargets() end)
  print("FlowField:getTargets ->", ok, result)
end

--@api-stub: FlowField:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("FlowField:type ->", ok, result)
end

--@api-stub: FlowField:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a FlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("FlowField:typeOf ->", ok, result)
end

-- ── PathGrid methods ──

--@api-stub: PathGrid:getWidth
-- Returns the grid width in cells.
-- Call when you need to read width.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("PathGrid:getWidth ->", ok, result)
end

--@api-stub: PathGrid:getHeight
-- Returns the grid height in cells.
-- Call when you need to read height.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("PathGrid:getHeight ->", ok, result)
end

--@api-stub: PathGrid:getCellSize
-- Returns the world-space size of each cell.
-- Call when you need to read cell size.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getCellSize() end)
  print("PathGrid:getCellSize ->", ok, result)
end

--@api-stub: PathGrid:setWalkable
-- Sets the walkability of a cell (1-based coordinates).
-- Call when you need to assign walkable.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setWalkable(0, 0, 100) end)
  print("PathGrid:setWalkable ->", ok, result)
end

--@api-stub: PathGrid:isWalkable
-- Returns true if a cell is walkable (1-based coordinates).
-- Call when you need to check is walkable.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:isWalkable(0, 0) end)
  print("PathGrid:isWalkable ->", ok, result)
end

--@api-stub: PathGrid:setCost
-- Sets the cost multiplier for a cell (1-based coordinates).
-- Call when you need to assign cost.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setCost(0, 0, nil) end)
  print("PathGrid:setCost ->", ok, result)
end

--@api-stub: PathGrid:getCost
-- Returns the cost multiplier for a cell (1-based coordinates).
-- Call when you need to read cost.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getCost(0, 0) end)
  print("PathGrid:getCost ->", ok, result)
end

--@api-stub: PathGrid:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("PathGrid:type ->", ok, result)
end

--@api-stub: PathGrid:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a PathGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newPathGrid(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("PathGrid:typeOf ->", ok, result)
end

-- ── AiFlowField methods ──

--@api-stub: AiFlowField:getWidth
-- Returns the flow field grid width in cells.
-- Call when you need to read width.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("AiFlowField:getWidth ->", ok, result)
end

--@api-stub: AiFlowField:getHeight
-- Returns the flow field grid height in cells.
-- Call when you need to read height.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("AiFlowField:getHeight ->", ok, result)
end

--@api-stub: AiFlowField:hasGoal
-- Returns true if a goal has been set.
-- Call when you need to check has goal.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:hasGoal() end)
  print("AiFlowField:hasGoal ->", ok, result)
end

--@api-stub: AiFlowField:setGoal
-- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
-- Call when you need to assign goal.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:setGoal(0, 0) end)
  print("AiFlowField:setGoal ->", ok, result)
end

--@api-stub: AiFlowField:getDirection
-- Returns the normalised direction toward the goal (1-based coordinates).
-- Call when you need to read direction.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getDirection(0, 0) end)
  print("AiFlowField:getDirection ->", ok, result)
end

--@api-stub: AiFlowField:getDistance
-- Returns the BFS distance to the goal (1-based coordinates).
-- Call when you need to read distance.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:getDistance(0, 0) end)
  print("AiFlowField:getDistance ->", ok, result)
end

--@api-stub: AiFlowField:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("AiFlowField:type ->", ok, result)
end

--@api-stub: AiFlowField:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a AiFlowField via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newAiFlowField(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("AiFlowField:typeOf ->", ok, result)
end

-- ── HexGrid methods ──

--@api-stub: HexGrid:setCost
-- Set movement cost for a cell (1-based coordinates).
-- Call when you need to assign cost.
-- Build a HexGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newHexGrid(...)
if instance then
  local ok, result = pcall(function() return instance:setCost(nil, nil, nil) end)
  print("HexGrid:setCost ->", ok, result)
end

--@api-stub: HexGrid:isBlocked
-- Returns true if a cell is blocked (1-based coordinates).
-- Call when you need to check is blocked.
-- Build a HexGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newHexGrid(...)
if instance then
  local ok, result = pcall(function() return instance:isBlocked(nil, nil) end)
  print("HexGrid:isBlocked ->", ok, result)
end

-- ── JpsGrid methods ──

--@api-stub: JpsGrid:isBlocked
-- Returns true if the cell is blocked (1-based coordinates).
-- Call when you need to check is blocked.
-- Build a JpsGrid via the appropriate lurek.pathfind.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pathfind.newJpsGrid(...)
if instance then
  local ok, result = pcall(function() return instance:isBlocked(0, 0) end)
  print("JpsGrid:isBlocked ->", ok, result)
end

