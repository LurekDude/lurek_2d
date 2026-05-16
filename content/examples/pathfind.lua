-- content/examples/pathfind.lua
-- lurek.pathfind API examples.
-- Run: cargo run -- content/examples/pathfind.lua

--@api-stub: lurek.pathfind.newNavGrid
-- Creates a navigation grid
do
  local grid = lurek.pathfind.newNavGrid(64, 48)
  grid:setCost(10, 10, 0)  -- mark a wall: cost 0 == blocked
  grid:setCost(11, 10, 5)  -- swamp: 5x slower than open ground
  lurek.log.info("nav grid ready: " .. grid:getWidth() .. "x" .. grid:getHeight(), "pathfind")
end

--@api-stub: lurek.pathfind.newPathfinder
-- Creates a unit pathfinder for a navigation grid
do
  local grid = lurek.pathfind.newNavGrid(64, 48)
  local pf = lurek.pathfind.newPathfinder(grid)
  pf:setCacheEnabled(true)
  pf:setCacheMaxSize(128)
end

--@api-stub: lurek.pathfind.newFlowField
-- Creates a flow field for a navigation grid
do
  local grid = lurek.pathfind.newNavGrid(48, 32)
  local field = lurek.pathfind.newFlowField(grid)
  field:calculate(40, 28)  -- goal cell (1-based)
  local dx, dy = field:getDirection(5, 5)
  lurek.log.debug("flow at (5,5): " .. dx .. "," .. dy, "pathfind")
end

--@api-stub: lurek.pathfind.newPathGrid
-- Creates a cell-size path grid
do
  local grid = lurek.pathfind.newPathGrid(40, 30, 32)  -- 40x30 tiles, 32px each
  grid:setWalkable(15, 10, false)
  grid:setCost(15, 11, 3.0)  -- difficult terrain
  lurek.log.info("path grid cell size = " .. grid:getCellSize(), "pathfind")
end

--@api-stub: lurek.pathfind.newPathFlowField
-- Creates an AI flow field from a path grid
do
  local grid = lurek.pathfind.newPathGrid(32, 24, 16)
  grid:setWalkable(10, 10, false)
  local field = lurek.pathfind.newPathFlowField(grid)
  field:setGoal(30, 22)
  lurek.log.debug("ai field has goal: " .. tostring(field:hasGoal()), "ai")
end

--@api-stub: lurek.pathfind.setThreadCount
-- Records a warning because pathfinding thread count is not implemented
do
  local desired_workers = 4
  lurek.pathfind.setThreadCount(desired_workers)
  lurek.log.info("requested " .. desired_workers .. " pathfind workers", "pathfind")
end

--@api-stub: lurek.pathfind.getThreadCount
-- Returns the pathfinding thread count
do
  local n = lurek.pathfind.getThreadCount()
  if n == 0 then
    lurek.log.info("pathfinding runs synchronously on the main thread", "pathfind")
  end
end

--@api-stub: lurek.pathfind.newNavGridFromTileMap
-- Creates a navigation grid from a tilemap layer and blocked gid table
do
  local tm = lurek.tilemap.newTileMap(40, 25, 32)
  tm:addLayer("walls", 40, 25)
  tm:setTile(1, 10, 5, 7)  -- place wall tile (gid=7) on layer 1
  local grid = lurek.pathfind.newNavGridFromTileMap(tm, 1, {7, 8, 9})
  lurek.log.info("nav grid from tilemap: " .. grid:getWidth() .. "x" .. grid:getHeight(), "pathfind")
end

--@api-stub: lurek.pathfind.newHexGrid
-- Creates a hex grid
do
  local hex = lurek.pathfind.newHexGrid(20, 16, "pointy")
  hex:setBlocked(5, 5, true)
  hex:setCost(6, 5, 2.5)  -- forest hex
  lurek.log.info("hex grid blocked at 5,5: " .. tostring(hex:isBlocked(5, 5)), "hex")
end

--@api-stub: lurek.pathfind.newJpsGrid
-- Creates a Jump Point Search grid
do
  local jps = lurek.pathfind.newJpsGrid(128, 128)
  jps:setBlocked(64, 64, true)
  local path = jps:findPath(1, 1, 128, 128)
  lurek.log.info("jps path waypoints: " .. (path and #path or 0), "pathfind")
end

--@api-stub: lurek.pathfind.newNavMesh
-- Creates an empty navigation mesh
do
  local mesh = lurek.pathfind.newNavMesh()
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
  mesh:connectPolygons(a, b, true)
  local path = mesh:findPath(10, 10, 180, 70)
  lurek.log.info("navmesh waypoints: " .. (path and #path or 0), "pathfind")
end

--@api-stub: NavMesh:addPolygon
-- Adds a polygon to this nav mesh.
do
  local mesh = lurek.pathfind.newNavMesh()
  local id = mesh:addPolygon({
    {x = 0, y = 0},
    {x = 8, y = 0},
    {x = 8, y = 8},
    {x = 0, y = 8},
  })
  lurek.log.debug("navmesh polygon id=" .. id, "pathfind")
end

--@api-stub: NavMesh:connectPolygons
-- Initiates a connection from this nav mesh to the target address.
do
  local mesh = lurek.pathfind.newNavMesh()
  local a = mesh:addPolygon({{x=0,y=0},{x=5,y=0},{x=5,y=5},{x=0,y=5}})
  local b = mesh:addPolygon({{x=5,y=0},{x=10,y=0},{x=10,y=5},{x=5,y=5}})
  mesh:connectPolygons(a, b, true)
end

--@api-stub: NavMesh:findPath
-- Finds and returns the path in this nav mesh by name or id.
do
  local mesh = lurek.pathfind.newNavMesh()
  local a = mesh:addPolygon({{x=0,y=0},{x=5,y=0},{x=5,y=5},{x=0,y=5}})
  local b = mesh:addPolygon({{x=5,y=0},{x=10,y=0},{x=10,y=5},{x=5,y=5}})
  mesh:connectPolygons(a, b, true)
  local path = mesh:findPath(1, 1, 9, 4)
  lurek.log.debug("navmesh path points=" .. (path and #path or 0), "pathfind")
end

--@api-stub: NavMesh:getPolygonCount
-- Returns the number of polygon items in this nav mesh.
do
  local mesh = lurek.pathfind.newNavMesh()
  mesh:addPolygon({{x=0,y=0},{x=4,y=0},{x=4,y=4},{x=0,y=4}})
  local n = mesh:getPolygonCount()
  lurek.log.debug("navmesh polygon count=" .. n, "pathfind")
end

--@api-stub: NavMesh:type
-- Returns the Lua-visible type name string for this nav mesh handle.
do
  local mesh = lurek.pathfind.newNavMesh()
  lurek.log.debug("navmesh type=" .. mesh:type(), "pathfind")
end

--@api-stub: NavMesh:typeOf
-- Returns true if this nav mesh handle matches the given type name string.
do
  local mesh = lurek.pathfind.newNavMesh()
  local ok = mesh:typeOf("LNavMesh")
  lurek.log.debug("is LNavMesh=" .. tostring(ok), "pathfind")
end

--@api-stub: lurek.pathfind.rangeMap
-- Computes reachable cells from range map options
do
  local result = lurek.pathfind.rangeMap({
    width = 16, height = 16, origin_x = 8, origin_y = 8,
    budget = 5.0, diagonal = true,
  })
  lurek.log.info("reachable cells within 5 moves: " .. #result.cells, "tactics")
end

-- NavGrid methods

--@api-stub: NavGrid:getWidth
-- Returns the width of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(80, 60)
  local w = grid:getWidth()
  lurek.log.info("nav grid width = " .. w .. " cells", "pathfind")
end

--@api-stub: NavGrid:getHeight
-- Returns the height of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(80, 60)
  local h = grid:getHeight()
  lurek.log.info("nav grid height = " .. h .. " cells", "pathfind")
end

--@api-stub: NavGrid:getDimensions
-- Returns the dimensions of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(64, 48)
  local w, h = grid:getDimensions()
  local total = w * h
  lurek.log.info("grid has " .. total .. " cells", "pathfind")
end

--@api-stub: NavGrid:setCost
-- Sets the cost of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setCost(16, 16, 0)   -- wall
  grid:setCost(17, 16, 5)   -- swamp
  grid:setCost(18, 16, 10)  -- deep water
end

--@api-stub: NavGrid:getCost
-- Returns the cost of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setCost(10, 10, 5)
  local c = grid:getCost(10, 10)
  if c > 1 then
    lurek.log.debug("rough terrain at 10,10 cost=" .. c, "pathfind")
  end
end

--@api-stub: NavGrid:isBlocked
-- Returns true if this nav grid blocked.
do
  local grid = lurek.pathfind.newNavGrid(20, 20)
  grid:setCost(5, 5, 0)
  if grid:isBlocked(5, 5) then
    lurek.log.warn("entity tried to enter blocked cell 5,5", "ai")
  end
end

--@api-stub: NavGrid:fill
-- Performs the fill operation on this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(50, 50)
  grid:fill(0)  -- start fully blocked
  for x = 10, 40 do grid:setCost(x, 25, 1) end  -- carve a corridor
end

--@api-stub: NavGrid:loadFromString
-- Loads from string into this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(4, 2)
  grid:loadFromString(string.char(1,1,0,1, 1,5,5,1))
  lurek.log.info("loaded grid, cell (2,2) cost=" .. grid:getCost(2, 2), "save")
end

--@api-stub: NavGrid:saveToString
-- Saves the current state of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  grid:setCost(4, 4, 0)
  local blob = grid:saveToString()
  lurek.log.info("serialised grid: " .. #blob .. " bytes", "save")
end

--@api-stub: NavGrid:setChunkSize
-- Sets the chunk size of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(128, 128)
  grid:setChunkSize(16)
  grid:rebuildAbstract()
end

--@api-stub: NavGrid:getChunkSize
-- Returns the chunk size of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setChunkSize(8)
  local cs = grid:getChunkSize()
  lurek.log.debug("hpa chunk size = " .. cs, "pathfind")
end

--@api-stub: NavGrid:rebuildAbstract
-- Performs the rebuild abstract operation on this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setChunkSize(16)
  for x = 1, 64 do grid:setCost(x, 32, 0) end  -- horizontal wall
  grid:rebuildAbstract()
end

--@api-stub: NavGrid:setDirty
-- Sets the dirty of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setCost(20, 20, 0)
  grid:setCost(21, 20, 0)
  grid:setDirty(20, 20, 2, 1)  -- 2x1 rectangle from (20,20)
end

--@api-stub: NavGrid:clearDirty
-- Clears all dirty items from this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:setDirty(10, 10, 4, 4)
  grid:rebuildAbstract()
  grid:clearDirty()
end

--@api-stub: NavGrid:setDiagonalMode
-- Sets the diagonal mode of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(40, 40)
  grid:setDiagonalMode("nocornercut")
  lurek.log.info("diagonal mode set to " .. grid:getDiagonalMode(), "pathfind")
end

--@api-stub: NavGrid:getDiagonalMode
-- Returns the diagonal mode of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(20, 20)
  local mode = grid:getDiagonalMode()
  if mode == "never" then
    lurek.log.debug("4-directional movement only", "pathfind")
  end
end

--@api-stub: NavGrid:type
-- Returns the Lua-visible type name string for this nav grid handle.
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  local kind = grid:type()
  lurek.log.debug("object type: " .. kind, "pathfind")
end

--@api-stub: NavGrid:typeOf
-- Returns true if this nav grid handle matches the given type name string.
do
  local grid = lurek.pathfind.newNavGrid(8, 8)
  if grid:typeOf("LNavGrid") then
    lurek.log.debug("confirmed nav grid", "pathfind")
  end
end

-- UnitPathfinder methods

--@api-stub: UnitPathfinder:getPathLength
-- Returns the path length of this unit pathfinder.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  local path = pf:findPath(1, 1, 30, 30)
  if path then
    lurek.log.info("path length = " .. pf:getPathLength(path), "pathfind")
  end
end

--@api-stub: UnitPathfinder:getPathCost
-- Returns the path cost of this unit pathfinder.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  g:setCost(10, 10, 5)
  local pf = lurek.pathfind.newPathfinder(g)
  local path = pf:findPath(1, 1, 20, 20)
  if path then
    lurek.log.info("path cost = " .. pf:getPathCost(path), "pathfind")
  end
end

--@api-stub: UnitPathfinder:setCacheEnabled
-- Sets whether this unit pathfinder is enabled and accepts input.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  pf:setCacheEnabled(true)
  lurek.log.info("path cache enabled", "pathfind")
end

--@api-stub: UnitPathfinder:isCacheEnabled
-- Returns true if this unit pathfinder is currently enabled.
do
  local g = lurek.pathfind.newNavGrid(16, 16)
  local pf = lurek.pathfind.newPathfinder(g)
  if pf:isCacheEnabled() then
    lurek.log.debug("warming path cache", "pathfind")
  end
end

--@api-stub: UnitPathfinder:clearCache
-- Clears all cache items from this unit pathfinder.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  g:setCost(8, 8, 0)  -- new wall
  pf:clearCache()
end

--@api-stub: UnitPathfinder:getCacheSize
-- Returns the cache size of this unit pathfinder.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(g)
  pf:setCacheEnabled(true)
  local n = pf:getCacheSize()
  lurek.log.debug("cached paths = " .. n, "pathfind")
end

--@api-stub: UnitPathfinder:setCacheMaxSize
-- Sets the cache max size of this unit pathfinder.
do
  local g = lurek.pathfind.newNavGrid(64, 64)
  local pf = lurek.pathfind.newPathfinder(g)
  pf:setCacheEnabled(true)
  pf:setCacheMaxSize(256)
end

--@api-stub: UnitPathfinder:type
-- Returns the Lua-visible type name string for this unit pathfinder handle.
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local pf = lurek.pathfind.newPathfinder(g)
  lurek.log.debug("object: " .. pf:type(), "pathfind")
end

--@api-stub: UnitPathfinder:typeOf
-- Returns true if this unit pathfinder handle matches the given type name string.
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local pf = lurek.pathfind.newPathfinder(g)
  if pf:typeOf("UnitPathfinder") then
    lurek.log.debug("confirmed pathfinder", "pathfind")
  end
end

-- FlowField methods

--@api-stub: FlowField:getDirection
-- Returns the direction of this flow field.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local f = lurek.pathfind.newFlowField(g)
  f:calculate(30, 30)
  local dx, dy = f:getDirection(5, 5)
  lurek.log.debug("flow @5,5 = " .. dx .. "," .. dy, "flow")
end

--@api-stub: FlowField:getDirectionAngle
-- Returns the direction angle of this flow field.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local f = lurek.pathfind.newFlowField(g)
  f:calculate(20, 20)
  local angle = f:getDirectionAngle(5, 5)
  lurek.log.debug("flow angle = " .. angle .. " rad", "flow")
end

--@api-stub: FlowField:getCostToTarget
-- Returns the cost to target of this flow field.
do
  local g = lurek.pathfind.newNavGrid(32, 32)
  local f = lurek.pathfind.newFlowField(g)
  f:calculate(16, 16)
  local d = f:getCostToTarget(1, 1)
  lurek.log.info("distance to target = " .. d, "flow")
end

--@api-stub: FlowField:isCalculated
-- Returns true if this flow field calculated.
do
  local g = lurek.pathfind.newNavGrid(16, 16)
  local f = lurek.pathfind.newFlowField(g)
  if not f:isCalculated() then
    f:calculate(10, 10)
  end
end

--@api-stub: FlowField:getTargets
-- Returns the targets of this flow field.
do
  local g = lurek.pathfind.newNavGrid(20, 20)
  local f = lurek.pathfind.newFlowField(g)
  f:calculateMulti({{x=5, y=5}, {x=15, y=15}}, 1)
  local targets = f:getTargets()
  lurek.log.info("flow has " .. #targets .. " goals", "flow")
end

--@api-stub: FlowField:type
-- Returns the Lua-visible type name string for this flow field handle.
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local f = lurek.pathfind.newFlowField(g)
  lurek.log.debug("object: " .. f:type(), "flow")
end

--@api-stub: FlowField:typeOf
-- Returns true if this flow field handle matches the given type name string.
do
  local g = lurek.pathfind.newNavGrid(8, 8)
  local f = lurek.pathfind.newFlowField(g)
  if f:typeOf("FlowField") then
    lurek.log.debug("confirmed flow field", "flow")
  end
end

-- PathGrid methods

--@api-stub: PathGrid:getWidth
-- Returns the width of this path grid.
do
  local g = lurek.pathfind.newPathGrid(40, 30, 32)
  local w = g:getWidth()
  lurek.log.info("path grid is " .. w .. " cells wide", "pathfind")
end

--@api-stub: PathGrid:getHeight
-- Returns the height of this path grid.
do
  local g = lurek.pathfind.newPathGrid(40, 30, 32)
  local h = g:getHeight()
  lurek.log.info("path grid is " .. h .. " cells tall", "pathfind")
end

--@api-stub: PathGrid:getCellSize
-- Returns the cell size of this path grid.
do
  local g = lurek.pathfind.newPathGrid(20, 15, 64)
  local cs = g:getCellSize()
  lurek.log.info("each cell = " .. cs .. " px", "pathfind")
end

--@api-stub: PathGrid:setWalkable
-- Sets the walkable of this path grid.
do
  local g = lurek.pathfind.newPathGrid(30, 20, 32)
  g:setWalkable(15, 10, false)  -- close a doorway
  g:setWalkable(16, 10, true)   -- open another
end

--@api-stub: PathGrid:isWalkable
-- Returns true if this path grid walkable.
do
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  g:setWalkable(10, 10, false)
  if not g:isWalkable(10, 10) then
    lurek.log.warn("goal cell 10,10 is blocked", "ai")
  end
end

--@api-stub: PathGrid:setCost
-- Sets the cost of this path grid.
do
  local g = lurek.pathfind.newPathGrid(40, 30, 32)
  g:setCost(20, 15, 3.0)  -- mud
  g:setCost(21, 15, 0.5)  -- road
end

--@api-stub: PathGrid:getCost
-- Returns the cost of this path grid.
do
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  g:setCost(5, 5, 2.5)
  local mult = g:getCost(5, 5)
  if mult > 1 then
    lurek.log.debug("difficult terrain mult=" .. mult, "ai")
  end
end

--@api-stub: PathGrid:type
-- Returns the Lua-visible type name string for this path grid handle.
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  lurek.log.debug("object: " .. g:type(), "pathfind")
end

--@api-stub: PathGrid:typeOf
-- Returns true if this path grid handle matches the given type name string.
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  if g:typeOf("PathGrid") then
    lurek.log.debug("confirmed path grid", "pathfind")
  end
end

-- AiFlowField methods

--@api-stub: AiFlowField:getWidth
-- Returns the width of this ai flow field.
do
  local g = lurek.pathfind.newPathGrid(32, 24, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  lurek.log.info("ai flow width = " .. f:getWidth(), "ai")
end

--@api-stub: AiFlowField:getHeight
-- Returns the height of this ai flow field.
do
  local g = lurek.pathfind.newPathGrid(32, 24, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  lurek.log.info("ai flow height = " .. f:getHeight(), "ai")
end

--@api-stub: AiFlowField:hasGoal
-- Returns true if this ai flow field has a goal.
do
  local g = lurek.pathfind.newPathGrid(16, 16, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  if not f:hasGoal() then
    f:setGoal(8, 8)
  end
end

--@api-stub: AiFlowField:setGoal
-- Sets the goal of this ai flow field.
do
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  f:setGoal(15, 15)  -- player position
  lurek.log.debug("ai goal set to 15,15", "ai")
end

--@api-stub: AiFlowField:getDirection
-- Returns the direction of this ai flow field.
do
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  f:setGoal(18, 18)
  local dx, dy = f:getDirection(2, 2)
  lurek.log.debug("ai flow @2,2 = " .. dx .. "," .. dy, "ai")
end

--@api-stub: AiFlowField:getDistance
-- Returns the distance of this ai flow field.
do
  local g = lurek.pathfind.newPathGrid(20, 20, 32)
  local f = lurek.pathfind.newPathFlowField(g)
  f:setGoal(10, 10)
  local d = f:getDistance(2, 2)
  if d < 8 then
    lurek.log.info("enemy within aggro range, d=" .. d, "ai")
  end
end

--@api-stub: AiFlowField:type
-- Returns the Lua-visible type name string for this ai flow field handle.
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  local f = lurek.pathfind.newPathFlowField(g)
  lurek.log.debug("object: " .. f:type(), "ai")
end

--@api-stub: AiFlowField:typeOf
-- Returns true if this ai flow field handle matches the given type name string.
do
  local g = lurek.pathfind.newPathGrid(8, 8, 16)
  local f = lurek.pathfind.newPathFlowField(g)
  if f:typeOf("FlowField") then
    lurek.log.debug("confirmed flow field", "ai")
  end
end

-- HexGrid methods

--@api-stub: HexGrid:setCost
-- Sets the cost of this hex grid.
do
  local hex = lurek.pathfind.newHexGrid(15, 12, "flat")
  hex:setCost(5, 4, 2.0)  -- forest hex
  hex:setCost(6, 4, 3.0)  -- swamp hex
end

--@api-stub: HexGrid:isBlocked
-- Returns true if this hex grid blocked.
do
  local hex = lurek.pathfind.newHexGrid(10, 8, "pointy")
  hex:setBlocked(3, 3, true)
  if hex:isBlocked(3, 3) then
    lurek.log.debug("hex 3,3 is impassable", "hex")
  end
end

-- JpsGrid methods

--@api-stub: JpsGrid:isBlocked
-- Returns true if this jps grid blocked.
do
  local jps = lurek.pathfind.newJpsGrid(64, 64)
  jps:setBlocked(32, 32, true)
  if jps:isBlocked(32, 32) then
    lurek.log.debug("jps cell 32,32 is blocked", "jps")
  end
end


--@api-stub: FlowField:calculate
-- Performs the calculate operation on this flow field.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculate(16, 16)
  lurek.log.info("flow field calculated", "pathfind")
end

--@api-stub: FlowField:calculateMulti
-- Performs the calculate multi operation on this flow field.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculateMulti({{x=8,y=8},{x=24,y=24}})
  lurek.log.info("multi-target flow field done", "pathfind")
end

--@api-stub: HexGrid:distance
-- Performs the distance operation on this hex grid.
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local d = hg:distance(1, 1, 6, 4)
  lurek.log.info("hex distance: " .. d, "pathfind")
end

--@api-stub: HexGrid:fieldOfView
-- Performs the field of view operation on this hex grid.
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local visible = hg:fieldOfView(8, 8, 4)
  lurek.log.info("visible cells: " .. #visible, "pathfind")
end

--@api-stub: NavGrid:fillRect
-- Performs the fill rect operation on this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  grid:fillRect(10, 10, 20, 20, 1)
  lurek.log.info("rect filled", "pathfind")
end

--@api-stub: UnitPathfinder:findNearestWalkable
-- Finds and returns the nearest walkable in this unit pathfinder by name or id.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local cx, cy = pf:findNearestWalkable(15, 15, 5)
  lurek.log.info("nearest walkable: " .. cx .. "," .. cy, "pathfind")
end

--@api-stub: UnitPathfinder:findPartialPath
-- Finds and returns the partial path in this unit pathfinder by name or id.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:fillRect(15, 1, 15, 31, 0)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPartialPath(1, 16, 30, 16, 200)
  lurek.log.info("partial path length: " .. #path, "pathfind")
end

--@api-stub: UnitPathfinder:findPath
-- Finds and returns the path in this unit pathfinder by name or id.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPath(1, 1, 31, 31)
  lurek.log.info("path steps: " .. (path and #path or 0), "pathfind")
end

--@api-stub: PathGrid:findPath
-- Finds and returns the path in this path grid by name or id.
do
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  local path = pg:findPath(1, 1, 31, 31)
  lurek.log.info("path grid path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: HexGrid:findPath
-- Finds and returns the path in this hex grid by name or id.
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local path = hg:findPath(1, 1, 8, 4)
  lurek.log.info("hex path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: JpsGrid:findPath
-- Finds and returns the path in this jps grid by name or id.
do
  local jg = lurek.pathfind.newJpsGrid(64, 64)
  local path = jg:findPath(1, 1, 63, 63)
  lurek.log.info("jps path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: UnitPathfinder:findPathBidirectional
-- Finds and returns the path bidirectional in this unit pathfinder by name or id.
do
  local grid = lurek.pathfind.newNavGrid(64, 64)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPathBidirectional(1, 1, 63, 63)
  lurek.log.info("bidir path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: UnitPathfinder:findPathSmooth
-- Finds and returns the path smooth in this unit pathfinder by name or id.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local path = pf:findPathSmooth(1, 1, 31, 31)
  lurek.log.info("smooth path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: PathGrid:findPathSmoothed
-- Finds and returns the path smoothed in this path grid by name or id.
do
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  local path = pg:findPathSmoothed(1, 1, 30, 30)
  lurek.log.info("smoothed path: " .. (path and #path or 0), "pathfind")
end

--@api-stub: AiFlowField:getGoal
-- Returns the goal of this ai flow field.
do
  local pg = lurek.pathfind.newPathGrid(32, 32, 16)
  local pff = lurek.pathfind.newPathFlowField(pg)
  pff:setGoal(16, 16)
  local gx, gy = pff:getGoal()
  lurek.log.info("goal: " .. gx .. "," .. gy, "pathfind")
end

--@api-stub: UnitPathfinder:heuristicDistance
-- Performs the heuristic distance operation on this unit pathfinder.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local h = pf:heuristicDistance(1, 1, 21, 16)
  lurek.log.info("heuristic: " .. h, "pathfind")
end

--@api-stub: UnitPathfinder:isReachable
-- Returns true if this unit pathfinder reachable.
do
  local grid = lurek.pathfind.newNavGrid(16, 16)
  local pf = lurek.pathfind.newPathfinder(grid)
  local ok = pf:isReachable(1, 1, 15, 15)
  lurek.log.info("reachable: " .. tostring(ok), "pathfind")
end

--@api-stub: NavGrid:isWalkable
-- Returns true if this nav grid walkable.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(10, 10, true)
  lurek.log.info("walkable 10,10: " .. tostring(grid:isWalkable(10, 10)), "pathfind")
end

--@api-stub: UnitPathfinder:lineOfSight
-- Performs the line of sight operation on this unit pathfinder.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local pf = lurek.pathfind.newPathfinder(grid)
  local los = pf:lineOfSight(1, 1, 15, 15)
  lurek.log.info("los: " .. tostring(los), "pathfind")
end

--@api-stub: HexGrid:lineOfSight
-- Performs the line of sight operation on this hex grid.
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local los = hg:lineOfSight(1, 1, 8, 4)
  lurek.log.info("hex los: " .. tostring(los), "pathfind")
end

--@api-stub: HexGrid:rangeOfMovement
-- Performs the range of movement operation on this hex grid.
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  local cells = hg:rangeOfMovement(8, 8, 3)
  lurek.log.info("cells in range: " .. #cells, "pathfind")
end

--@api-stub: NavGrid:setBlocked
-- Sets the blocked of this nav grid.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  grid:setBlocked(8, 8, true)
  lurek.log.info("cell 8,8 blocked", "pathfind")
end

--@api-stub: HexGrid:setBlocked
-- Sets the blocked of this hex grid.
do
  local hg = lurek.pathfind.newHexGrid(16, 16)
  hg:setBlocked(4, 4, true)
  lurek.log.info("hex cell 4,4 blocked", "pathfind")
end

--@api-stub: JpsGrid:setBlocked
-- Sets the blocked of this jps grid.
do
  local jg = lurek.pathfind.newJpsGrid(32, 32)
  jg:setBlocked(15, 15, true)
  lurek.log.info("jps cell blocked", "pathfind")
end

--@api-stub: FlowField:steer
-- Performs the steer operation on this flow field.
do
  local grid = lurek.pathfind.newNavGrid(32, 32)
  local ff = lurek.pathfind.newFlowField(grid)
  ff:calculate(16, 16)
  local vx, vy = ff:steer(8, 8, 1.0, 1.0, 1.0)
  lurek.log.info("steer: " .. vx .. "," .. vy, "pathfind")
end

-- -----------------------------------------------------------------------------
-- LAIFlowField methods
-- -----------------------------------------------------------------------------

--@api-stub: LAIFlowField:getWidth
-- Returns flow field width
do
  local grid = lurek.pathfind.newPathGrid(12, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local ok_w, ww = pcall(function() return ff:getWidth() end)
  lurek.log.info("width=" .. tostring(ok_w and ww or "??"), "pathfind")
end
--@api-stub: LAIFlowField:getHeight
-- Returns flow field height
do
  local grid = lurek.pathfind.newPathGrid(12, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local ok_h2, hh = pcall(function() return ff:getHeight() end)
  lurek.log.info("height=" .. tostring(ok_h2 and hh or "??"), "pathfind")
end
--@api-stub: LAIFlowField:hasGoal
-- Returns whether a goal is set
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
-- Sets the one-based flow field goal
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
-- Returns the one-based flow field goal when set
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
-- Returns flow direction for a one-based cell
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
-- Returns distance to goal for a one-based cell
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
--@api-stub: LAIFlowField:type
-- Returns the Lua-visible type name for this AI flow field handle
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  local t = ff and ff:type() or "LAIFlowField"
  lurek.log.info("LAIFlowField:type=" .. t, "pathfind")
end
--@api-stub: LAIFlowField:typeOf
-- Returns whether this AI flow field handle matches a supported type name
do
  local grid = lurek.pathfind.newPathGrid(8, 8, 1.0)
  local ff = lurek.pathfind.newPathFlowField(grid)
  lurek.log.info("is LAIFlowField: " .. tostring(ff and ff:typeOf("LAIFlowField") or false), "pathfind")
  lurek.log.info("is wrong: " .. tostring(ff and ff:typeOf("Unknown") or false), "pathfind")
end
--@api-stub: LHexGrid:type
-- Returns the Lua-visible type name for this hex grid handle
do
  local hex_grid_obj = lurek.pathfind.newHexGrid(32, 32, nil)
  local t = hex_grid_obj:type()
  lurek.log.info("LHexGrid:type = " .. t, "pathfind")
end
--@api-stub: LHexGrid:typeOf
-- Returns whether this hex grid handle matches a supported type name
do
  local hex_grid_obj = lurek.pathfind.newHexGrid(32, 32, nil)
  lurek.log.info("is LHexGrid: " .. tostring(hex_grid_obj:typeOf("LHexGrid")), "pathfind")
  lurek.log.info("is wrong: " .. tostring(hex_grid_obj:typeOf("Unknown")), "pathfind")
end
--@api-stub: LJpsGrid:type
-- Returns the Lua-visible type name for this JPS grid handle
do
  local jps_grid_obj = lurek.pathfind.newJpsGrid(32, 32)
  local t = jps_grid_obj:type()
  lurek.log.info("LJpsGrid:type = " .. t, "pathfind")
end
--@api-stub: LJpsGrid:typeOf
-- Returns whether this JPS grid handle matches a supported type name
do
  local jps_grid_obj = lurek.pathfind.newJpsGrid(32, 32)
  lurek.log.info("is LJpsGrid: " .. tostring(jps_grid_obj:typeOf("LJpsGrid")), "pathfind")
  lurek.log.info("is wrong: " .. tostring(jps_grid_obj:typeOf("Unknown")), "pathfind")
end
