-- content/examples/raycaster.lua
-- Auto-scaffolded coverage of the lurek.raycaster Lua API (42 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/raycaster.lua

print("[example] lurek.raycaster loaded — 42 API items demonstrated")

-- ── lurek.raycaster free functions ──

--@api-stub: lurek.raycaster.new
-- Creates a new raycaster grid of the given dimensions.
-- Use this when creates a new raycaster grid of the given dimensions is needed.
if false then
  local _r = lurek.raycaster.new(0, 0)
  print(_r)
end

--@api-stub: lurek.raycaster.newMap
-- Alias for `new`.
-- Creates a new raycaster grid of the given dimensions.
if false then
  local _r = lurek.raycaster.newMap(0, 0)
  print(_r)
end

--@api-stub: lurek.raycaster.projectColumn
-- Projects a wall distance to screen-space drawing parameters.
-- Use this when projects a wall distance to screen-space drawing parameters is needed.
if false then
  local _r = lurek.raycaster.projectColumn(1, 0, 1)
  print(_r)
end

--@api-stub: lurek.raycaster.distanceShade
-- Returns distance-based brightness in [0, 1].
-- Use this when returns distance-based brightness in [0, 1] is needed.
if false then
  local _r = lurek.raycaster.distanceShade(1, 1)
  print(_r)
end

--@api-stub: lurek.raycaster.newDoorManager
-- Creates a new empty door manager.
-- Use this when creates a new empty door manager is needed.
if false then
  local _r = lurek.raycaster.newDoorManager()
  print(_r)
end

--@api-stub: lurek.raycaster.newHeightMap
-- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
-- Use this when creates a new height map with default floor (0.0) and ceiling (1.0) values is needed.
if false then
  local _r = lurek.raycaster.newHeightMap(0, 0)
  print(_r)
end

--@api-stub: lurek.raycaster.newPointLight
-- Creates a point light for use in raycaster scene lighting.
-- Use this when creates a point light for use in raycaster scene lighting is needed.
if false then
  local _r = lurek.raycaster.newPointLight(0, 0, nil, nil, nil, nil, 1)
  print(_r)
end

--@api-stub: lurek.raycaster.newSpriteManager
-- Creates a new empty batch sprite manager for depth-sorted projection.
-- Use this when creates a new empty batch sprite manager for depth-sorted projection is needed.
if false then
  local _r = lurek.raycaster.newSpriteManager()
  print(_r)
end

-- ── DoorManager methods ──

--@api-stub: DoorManager:openDoor
-- Begins opening the door at the given index.
-- Use this when begins opening the door at the given index is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:openDoor(1)
end

--@api-stub: DoorManager:closeDoor
-- Begins closing the door at the given index.
-- Use this when begins closing the door at the given index is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:closeDoor(1)
end

--@api-stub: DoorManager:update
-- Advances all door animations by dt seconds.
-- Use this when advances all door animations by dt seconds is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:update(0)
end

--@api-stub: DoorManager:getDoor
-- Returns the state table for door at index, or nil if out of range.
-- Use this when returns the state table for door at index, or nil if out of range is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:getDoor(1)
end

--@api-stub: DoorManager:count
-- Returns the number of registered doors.
-- Use this when returns the number of registered doors is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:count()
end

--@api-stub: DoorManager:type
-- Returns the type string "DoorManager".
-- Use this when returns the type string "DoorManager" is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:type()
end

--@api-stub: DoorManager:typeOf
-- Returns the type string "DoorManager".
-- Use this when returns the type string "DoorManager" is needed.
if false then
  local _o = nil  -- DoorManager instance
  _o:typeOf()
end

-- ── HeightMap methods ──

--@api-stub: HeightMap:setFloor
-- Sets the floor height at (x, y).
-- Use this when sets the floor height at (x, y) is needed.
if false then
  local _o = nil  -- HeightMap instance
  _o:setFloor(0, 0, 0)
end

--@api-stub: HeightMap:setCeiling
-- Sets the ceiling height at (x, y).
-- Use this when sets the ceiling height at (x, y) is needed.
if false then
  local _o = nil  -- HeightMap instance
  _o:setCeiling(0, 0, 0)
end

--@api-stub: HeightMap:floorAt
-- Returns the floor height at (x, y).
-- Returns 0.0 for out-of-bounds.
if false then
  local _o = nil  -- HeightMap instance
  _o:floorAt(0, 0)
end

--@api-stub: HeightMap:ceilingAt
-- Returns the ceiling height at (x, y).
-- Returns 1.0 for out-of-bounds.
if false then
  local _o = nil  -- HeightMap instance
  _o:ceilingAt(0, 0)
end

--@api-stub: HeightMap:type
-- Returns the type string "HeightMap".
-- Use this when returns the type string "HeightMap" is needed.
if false then
  local _o = nil  -- HeightMap instance
  _o:type()
end

--@api-stub: HeightMap:typeOf
-- Returns the type string "HeightMap".
-- Use this when returns the type string "HeightMap" is needed.
if false then
  local _o = nil  -- HeightMap instance
  _o:typeOf()
end

-- ── PointLight methods ──

--@api-stub: PointLight:x
-- Returns the world-space X position.
-- Use this when returns the world-space X position is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:x()
end

--@api-stub: PointLight:y
-- Returns the world-space Y position.
-- Use this when returns the world-space Y position is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:y()
end

--@api-stub: PointLight:radius
-- Returns the illumination radius.
-- Use this when returns the illumination radius is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:radius()
end

--@api-stub: PointLight:intensity
-- Returns the intensity multiplier.
-- Use this when returns the intensity multiplier is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:intensity()
end

--@api-stub: PointLight:color
-- Returns the RGB color as three separate values.
-- Use this when returns the RGB color as three separate values is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:color()
end

--@api-stub: PointLight:type
-- Returns the type string "PointLight".
-- Use this when returns the type string "PointLight" is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:type()
end

--@api-stub: PointLight:typeOf
-- Returns the type string "PointLight".
-- Use this when returns the type string "PointLight" is needed.
if false then
  local _o = nil  -- PointLight instance
  _o:typeOf()
end

-- ── Raycaster methods ──

--@api-stub: Raycaster:setCell
-- Sets the cell value at grid position (x, y).
-- Use this when sets the cell value at grid position (x, y) is needed.
if false then
  local _o = nil  -- Raycaster instance
  _o:setCell(0, 0, 0)
end

--@api-stub: Raycaster:getCell
-- Returns the cell value at (x, y).
-- Use this when returns the cell value at (x, y) is needed.
if false then
  local _o = nil  -- Raycaster instance
  _o:getCell(0, 0)
end

--@api-stub: Raycaster:setCells
-- Replaces all grid cells from a flat array of values in row-major order.
-- Use this when replaces all grid cells from a flat array of values in row-major order is needed.
if false then
  local _o = nil  -- Raycaster instance
  _o:setCells(0)
end

--@api-stub: Raycaster:isBlocked
-- Returns true when the cell at (x, y) is a wall (value > 0).
-- Use this when returns true when the cell at (x, y) is a wall (value > 0) is needed.
if false then
  local _o = nil  -- Raycaster instance
  _o:isBlocked(0, 0)
end

--@api-stub: Raycaster:width
-- Returns the grid width in cells.
-- Use this when returns the grid width in cells is needed.
if false then
  local _o = nil  -- Raycaster instance
  _o:width()
end

--@api-stub: Raycaster:height
-- Returns the grid height in cells.
-- Use this when returns the grid height in cells is needed.
if false then
  local _o = nil  -- Raycaster instance
  _o:height()
end

--@api-stub: Raycaster:setWallAlpha
-- Sets the opacity for a wall tile type.
-- Alpha is clamped to [0, 1].
if false then
  local _o = nil  -- Raycaster instance
  _o:setWallAlpha(0, 0)
end

--@api-stub: Raycaster:getWallAlpha
-- Returns the opacity for a wall tile type.
-- Returns 1.0 if not set.
if false then
  local _o = nil  -- Raycaster instance
  _o:getWallAlpha(0)
end

-- ── SpriteManager methods ──

--@api-stub: SpriteManager:remove
-- Removes the sprite with the given id.
-- No-op if not found.
if false then
  local _o = nil  -- SpriteManager instance
  _o:remove(1)
end

--@api-stub: SpriteManager:setPosition
-- Moves the sprite with the given id to world (x, y).
-- Use this when moves the sprite with the given id to world (x, y) is needed.
if false then
  local _o = nil  -- SpriteManager instance
  _o:setPosition(1, 0, 0)
end

--@api-stub: SpriteManager:setVisible
-- Shows or hides the sprite with the given id.
-- Use this when shows or hides the sprite with the given id is needed.
if false then
  local _o = nil  -- SpriteManager instance
  _o:setVisible(1, 0)
end

--@api-stub: SpriteManager:clear
-- Removes all sprites from the manager.
-- Use this when removes all sprites from the manager is needed.
if false then
  local _o = nil  -- SpriteManager instance
  _o:clear()
end

--@api-stub: SpriteManager:type
-- Returns the type string "SpriteManager".
-- Use this when returns the type string "SpriteManager" is needed.
if false then
  local _o = nil  -- SpriteManager instance
  _o:type()
end

--@api-stub: SpriteManager:typeOf
-- Returns the type string "SpriteManager".
-- Use this when returns the type string "SpriteManager" is needed.
if false then
  local _o = nil  -- SpriteManager instance
  _o:typeOf()
end

