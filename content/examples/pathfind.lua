-- content/examples/pathfind.lua
-- Scaffolded coverage of the lurek.pathfind API (65 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/pathfind_api.rs   (Lua binding, arg types, return shape)
--   * src/pathfind/                 (semantics, side effects)
--   * docs/specs/pathfind.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/pathfind.lua

-- ── lurek.pathfind.* functions ──

--@api-stub: lurek.pathfind.newNavGrid
-- Creates a new NavGrid with all cells walkable.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newNavGrid
  local _todo = "TODO: write a real lurek.pathfind.newNavGrid usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newPathfinder
-- Creates a new UnitPathfinder backed by a NavGrid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newPathfinder
  local _todo = "TODO: write a real lurek.pathfind.newPathfinder usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newFlowField
-- Creates a new FlowField backed by a NavGrid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newFlowField
  local _todo = "TODO: write a real lurek.pathfind.newFlowField usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newPathGrid
-- Creates a new PathGrid with per-cell cost and walkability.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newPathGrid
  local _todo = "TODO: write a real lurek.pathfind.newPathGrid usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newPathFlowField
-- Creates a new BFS flow field from a PathGrid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newPathFlowField
  local _todo = "TODO: write a real lurek.pathfind.newPathFlowField usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.setThreadCount
-- Sets the background pathfinding thread count (currently a no-op).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.setThreadCount
  local _todo = "TODO: write a real lurek.pathfind.setThreadCount usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.getThreadCount
-- Returns the background pathfinding thread count (currently always 0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.getThreadCount
  local _todo = "TODO: write a real lurek.pathfind.getThreadCount usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newNavGridFromTileMap
  local _todo = "TODO: write a real lurek.pathfind.newNavGridFromTileMap usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newHexGrid
-- Creates a hex grid for pathfinding, LOS, FOV, and range queries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newHexGrid
  local _todo = "TODO: write a real lurek.pathfind.newHexGrid usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.newJpsGrid
-- Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.newJpsGrid
  local _todo = "TODO: write a real lurek.pathfind.newJpsGrid usage example"
  print(_todo)
end

--@api-stub: lurek.pathfind.rangeMap
-- Computes a Dijkstra range-of-movement map from an origin within a movement budget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: lurek.pathfind.rangeMap
  local _todo = "TODO: write a real lurek.pathfind.rangeMap usage example"
  print(_todo)
end

-- ── NavGrid methods ──

--@api-stub: NavGrid:getWidth
-- Returns the grid width in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:getWidth
  local _todo = "TODO: write a real NavGrid:getWidth usage example"
  print(_todo)
end

--@api-stub: NavGrid:getHeight
-- Returns the grid height in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:getHeight
  local _todo = "TODO: write a real NavGrid:getHeight usage example"
  print(_todo)
end

--@api-stub: NavGrid:getDimensions
-- Returns the grid dimensions as width, height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:getDimensions
  local _todo = "TODO: write a real NavGrid:getDimensions usage example"
  print(_todo)
end

--@api-stub: NavGrid:setCost
-- Sets the traversal cost of a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:setCost
  local _todo = "TODO: write a real NavGrid:setCost usage example"
  print(_todo)
end

--@api-stub: NavGrid:getCost
-- Returns the traversal cost of a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:getCost
  local _todo = "TODO: write a real NavGrid:getCost usage example"
  print(_todo)
end

--@api-stub: NavGrid:isBlocked
-- Returns true if the cell is blocked (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:isBlocked
  local _todo = "TODO: write a real NavGrid:isBlocked usage example"
  print(_todo)
end

--@api-stub: NavGrid:fill
-- Sets every cell to the given cost.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:fill
  local _todo = "TODO: write a real NavGrid:fill usage example"
  print(_todo)
end

--@api-stub: NavGrid:loadFromString
-- Overwrites the grid from a raw byte string (row-major, one byte per cell).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:loadFromString
  local _todo = "TODO: write a real NavGrid:loadFromString usage example"
  print(_todo)
end

--@api-stub: NavGrid:saveToString
-- Exports the cost grid as a byte string (row-major, one byte per cell).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:saveToString
  local _todo = "TODO: write a real NavGrid:saveToString usage example"
  print(_todo)
end

--@api-stub: NavGrid:setChunkSize
-- Sets the HPA★ chunk size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:setChunkSize
  local _todo = "TODO: write a real NavGrid:setChunkSize usage example"
  print(_todo)
end

--@api-stub: NavGrid:getChunkSize
-- Returns the current HPA★ chunk size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:getChunkSize
  local _todo = "TODO: write a real NavGrid:getChunkSize usage example"
  print(_todo)
end

--@api-stub: NavGrid:rebuildAbstract
-- Rebuilds the HPA★ abstract graph from the current grid state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:rebuildAbstract
  local _todo = "TODO: write a real NavGrid:rebuildAbstract usage example"
  print(_todo)
end

--@api-stub: NavGrid:setDirty
-- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:setDirty
  local _todo = "TODO: write a real NavGrid:setDirty usage example"
  print(_todo)
end

--@api-stub: NavGrid:clearDirty
-- Clears all pending dirty rectangles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:clearDirty
  local _todo = "TODO: write a real NavGrid:clearDirty usage example"
  print(_todo)
end

--@api-stub: NavGrid:setDiagonalMode
-- Sets the diagonal movement mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:setDiagonalMode
  local _todo = "TODO: write a real NavGrid:setDiagonalMode usage example"
  print(_todo)
end

--@api-stub: NavGrid:getDiagonalMode
-- Returns the current diagonal movement mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:getDiagonalMode
  local _todo = "TODO: write a real NavGrid:getDiagonalMode usage example"
  print(_todo)
end

--@api-stub: NavGrid:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:type
  local _todo = "TODO: write a real NavGrid:type usage example"
  print(_todo)
end

--@api-stub: NavGrid:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: NavGrid:typeOf
  local _todo = "TODO: write a real NavGrid:typeOf usage example"
  print(_todo)
end

-- ── UnitPathfinder methods ──

--@api-stub: UnitPathfinder:getPathLength
-- Returns the euclidean length of a path table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:getPathLength
  local _todo = "TODO: write a real UnitPathfinder:getPathLength usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:getPathCost
-- Returns the sum of grid traversal costs along a path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:getPathCost
  local _todo = "TODO: write a real UnitPathfinder:getPathCost usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:setCacheEnabled
-- Enables or disables path result caching.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:setCacheEnabled
  local _todo = "TODO: write a real UnitPathfinder:setCacheEnabled usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:isCacheEnabled
-- Returns true if path result caching is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:isCacheEnabled
  local _todo = "TODO: write a real UnitPathfinder:isCacheEnabled usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:clearCache
-- Removes all cached path results.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:clearCache
  local _todo = "TODO: write a real UnitPathfinder:clearCache usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:getCacheSize
-- Returns the number of entries in the path cache.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:getCacheSize
  local _todo = "TODO: write a real UnitPathfinder:getCacheSize usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:setCacheMaxSize
-- Sets the maximum number of cached path entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:setCacheMaxSize
  local _todo = "TODO: write a real UnitPathfinder:setCacheMaxSize usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:type
  local _todo = "TODO: write a real UnitPathfinder:type usage example"
  print(_todo)
end

--@api-stub: UnitPathfinder:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: UnitPathfinder:typeOf
  local _todo = "TODO: write a real UnitPathfinder:typeOf usage example"
  print(_todo)
end

-- ── FlowField methods ──

--@api-stub: FlowField:getDirection
-- Returns the normalised direction vector at a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:getDirection
  local _todo = "TODO: write a real FlowField:getDirection usage example"
  print(_todo)
end

--@api-stub: FlowField:getDirectionAngle
-- Returns the flow direction as an angle in radians (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:getDirectionAngle
  local _todo = "TODO: write a real FlowField:getDirectionAngle usage example"
  print(_todo)
end

--@api-stub: FlowField:getCostToTarget
-- Returns the integrated cost to the nearest target (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:getCostToTarget
  local _todo = "TODO: write a real FlowField:getCostToTarget usage example"
  print(_todo)
end

--@api-stub: FlowField:isCalculated
-- Returns true if the flow field has been computed at least once.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:isCalculated
  local _todo = "TODO: write a real FlowField:isCalculated usage example"
  print(_todo)
end

--@api-stub: FlowField:getTargets
-- Returns the target cells from the most recent computation (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:getTargets
  local _todo = "TODO: write a real FlowField:getTargets usage example"
  print(_todo)
end

--@api-stub: FlowField:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:type
  local _todo = "TODO: write a real FlowField:type usage example"
  print(_todo)
end

--@api-stub: FlowField:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: FlowField:typeOf
  local _todo = "TODO: write a real FlowField:typeOf usage example"
  print(_todo)
end

-- ── PathGrid methods ──

--@api-stub: PathGrid:getWidth
-- Returns the grid width in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:getWidth
  local _todo = "TODO: write a real PathGrid:getWidth usage example"
  print(_todo)
end

--@api-stub: PathGrid:getHeight
-- Returns the grid height in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:getHeight
  local _todo = "TODO: write a real PathGrid:getHeight usage example"
  print(_todo)
end

--@api-stub: PathGrid:getCellSize
-- Returns the world-space size of each cell.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:getCellSize
  local _todo = "TODO: write a real PathGrid:getCellSize usage example"
  print(_todo)
end

--@api-stub: PathGrid:setWalkable
-- Sets the walkability of a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:setWalkable
  local _todo = "TODO: write a real PathGrid:setWalkable usage example"
  print(_todo)
end

--@api-stub: PathGrid:isWalkable
-- Returns true if a cell is walkable (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:isWalkable
  local _todo = "TODO: write a real PathGrid:isWalkable usage example"
  print(_todo)
end

--@api-stub: PathGrid:setCost
-- Sets the cost multiplier for a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:setCost
  local _todo = "TODO: write a real PathGrid:setCost usage example"
  print(_todo)
end

--@api-stub: PathGrid:getCost
-- Returns the cost multiplier for a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:getCost
  local _todo = "TODO: write a real PathGrid:getCost usage example"
  print(_todo)
end

--@api-stub: PathGrid:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:type
  local _todo = "TODO: write a real PathGrid:type usage example"
  print(_todo)
end

--@api-stub: PathGrid:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: PathGrid:typeOf
  local _todo = "TODO: write a real PathGrid:typeOf usage example"
  print(_todo)
end

-- ── AiFlowField methods ──

--@api-stub: AiFlowField:getWidth
-- Returns the flow field grid width in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:getWidth
  local _todo = "TODO: write a real AiFlowField:getWidth usage example"
  print(_todo)
end

--@api-stub: AiFlowField:getHeight
-- Returns the flow field grid height in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:getHeight
  local _todo = "TODO: write a real AiFlowField:getHeight usage example"
  print(_todo)
end

--@api-stub: AiFlowField:hasGoal
-- Returns true if a goal has been set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:hasGoal
  local _todo = "TODO: write a real AiFlowField:hasGoal usage example"
  print(_todo)
end

--@api-stub: AiFlowField:setGoal
-- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:setGoal
  local _todo = "TODO: write a real AiFlowField:setGoal usage example"
  print(_todo)
end

--@api-stub: AiFlowField:getDirection
-- Returns the normalised direction toward the goal (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:getDirection
  local _todo = "TODO: write a real AiFlowField:getDirection usage example"
  print(_todo)
end

--@api-stub: AiFlowField:getDistance
-- Returns the BFS distance to the goal (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:getDistance
  local _todo = "TODO: write a real AiFlowField:getDistance usage example"
  print(_todo)
end

--@api-stub: AiFlowField:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:type
  local _todo = "TODO: write a real AiFlowField:type usage example"
  print(_todo)
end

--@api-stub: AiFlowField:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: AiFlowField:typeOf
  local _todo = "TODO: write a real AiFlowField:typeOf usage example"
  print(_todo)
end

-- ── HexGrid methods ──

--@api-stub: HexGrid:setCost
-- Set movement cost for a cell (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: HexGrid:setCost
  local _todo = "TODO: write a real HexGrid:setCost usage example"
  print(_todo)
end

--@api-stub: HexGrid:isBlocked
-- Returns true if a cell is blocked (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: HexGrid:isBlocked
  local _todo = "TODO: write a real HexGrid:isBlocked usage example"
  print(_todo)
end

-- ── JpsGrid methods ──

--@api-stub: JpsGrid:isBlocked
-- Returns true if the cell is blocked (1-based coordinates).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pathfind_api.rs and docs/specs/pathfind.md).
do  -- TODO: JpsGrid:isBlocked
  local _todo = "TODO: write a real JpsGrid:isBlocked usage example"
  print(_todo)
end

