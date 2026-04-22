-- content/examples/raycaster.lua
-- Practical usage examples for the lurek.raycaster API (42 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.raycaster.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/raycaster.lua

print("[example] lurek.raycaster — 42 API entries")

-- ── lurek.raycaster.* free functions ──

--@api-stub: lurek.raycaster.new
-- Creates a new raycaster grid of the given dimensions.
-- Call when you need to invoke new.
local ok, obj = pcall(function() return lurek.raycaster.new(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.raycaster.new ok=", ok)

--@api-stub: lurek.raycaster.newMap
-- Alias for `new`.
-- Creates a new raycaster grid of the given dimensions.
local ok, obj = pcall(function() return lurek.raycaster.newMap(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.raycaster.newMap ok=", ok)

--@api-stub: lurek.raycaster.projectColumn
-- Projects a wall distance to screen-space drawing parameters.
-- Call when you need to invoke project column.
local ok, result = pcall(function() return lurek.raycaster.projectColumn(nil, nil, nil) end)
if ok then print("lurek.raycaster.projectColumn ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.raycaster.distanceShade
-- Returns distance-based brightness in [0, 1].
-- Call when you need to invoke distance shade.
local ok, result = pcall(function() return lurek.raycaster.distanceShade(nil, nil) end)
if ok then print("lurek.raycaster.distanceShade ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.raycaster.newDoorManager
-- Creates a new empty door manager.
-- Call when you need to create a new door manager.
local ok, obj = pcall(function() return lurek.raycaster.newDoorManager() end)
if ok and obj then print("created:", obj) end
print("lurek.raycaster.newDoorManager ok=", ok)

--@api-stub: lurek.raycaster.newHeightMap
-- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
-- Call when you need to create a new height map.
local ok, obj = pcall(function() return lurek.raycaster.newHeightMap(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.raycaster.newHeightMap ok=", ok)

--@api-stub: lurek.raycaster.newPointLight
-- Creates a point light for use in raycaster scene lighting.
-- Call when you need to create a new point light.
local ok, obj = pcall(function() return lurek.raycaster.newPointLight(0, 0, 1, 1, 1, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.raycaster.newPointLight ok=", ok)

--@api-stub: lurek.raycaster.newSpriteManager
-- Creates a new empty batch sprite manager for depth-sorted projection.
-- Call when you need to create a new sprite manager.
local ok, obj = pcall(function() return lurek.raycaster.newSpriteManager() end)
if ok and obj then print("created:", obj) end
print("lurek.raycaster.newSpriteManager ok=", ok)

-- ── DoorManager methods ──

--@api-stub: DoorManager:openDoor
-- Begins opening the door at the given index.
-- Call when you need to invoke open door.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:openDoor(1) end)
  print("DoorManager:openDoor ->", ok, result)
end

--@api-stub: DoorManager:closeDoor
-- Begins closing the door at the given index.
-- Call when you need to invoke close door.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:closeDoor(1) end)
  print("DoorManager:closeDoor ->", ok, result)
end

--@api-stub: DoorManager:update
-- Advances all door animations by dt seconds.
-- Call when you need to invoke update.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("DoorManager:update ->", ok, result)
end

--@api-stub: DoorManager:getDoor
-- Returns the state table for door at index, or nil if out of range.
-- Call when you need to read door.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:getDoor(1) end)
  print("DoorManager:getDoor ->", ok, result)
end

--@api-stub: DoorManager:count
-- Returns the number of registered doors.
-- Call when you need to invoke count.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:count() end)
  print("DoorManager:count ->", ok, result)
end

--@api-stub: DoorManager:type
-- Returns the type string "DoorManager".
-- Call when you need to invoke type.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("DoorManager:type ->", ok, result)
end

--@api-stub: DoorManager:typeOf
-- Returns the type string "DoorManager".
-- Call when you need to invoke type of.
-- Build a DoorManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newDoorManager(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("DoorManager:typeOf ->", ok, result)
end

-- ── HeightMap methods ──

--@api-stub: HeightMap:setFloor
-- Sets the floor height at (x, y).
-- Call when you need to assign floor.
-- Build a HeightMap via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newHeightMap(...)
if instance then
  local ok, result = pcall(function() return instance:setFloor(0, 0, 100) end)
  print("HeightMap:setFloor ->", ok, result)
end

--@api-stub: HeightMap:setCeiling
-- Sets the ceiling height at (x, y).
-- Call when you need to assign ceiling.
-- Build a HeightMap via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newHeightMap(...)
if instance then
  local ok, result = pcall(function() return instance:setCeiling(0, 0, 100) end)
  print("HeightMap:setCeiling ->", ok, result)
end

--@api-stub: HeightMap:floorAt
-- Returns the floor height at (x, y).
-- Returns 0.0 for out-of-bounds.
-- Build a HeightMap via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newHeightMap(...)
if instance then
  local ok, result = pcall(function() return instance:floorAt(0, 0) end)
  print("HeightMap:floorAt ->", ok, result)
end

--@api-stub: HeightMap:ceilingAt
-- Returns the ceiling height at (x, y).
-- Returns 1.0 for out-of-bounds.
-- Build a HeightMap via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newHeightMap(...)
if instance then
  local ok, result = pcall(function() return instance:ceilingAt(0, 0) end)
  print("HeightMap:ceilingAt ->", ok, result)
end

--@api-stub: HeightMap:type
-- Returns the type string "HeightMap".
-- Call when you need to invoke type.
-- Build a HeightMap via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newHeightMap(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("HeightMap:type ->", ok, result)
end

--@api-stub: HeightMap:typeOf
-- Returns the type string "HeightMap".
-- Call when you need to invoke type of.
-- Build a HeightMap via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newHeightMap(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("HeightMap:typeOf ->", ok, result)
end

-- ── PointLight methods ──

--@api-stub: PointLight:x
-- Returns the world-space X position.
-- Call when you need to invoke x.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:x() end)
  print("PointLight:x ->", ok, result)
end

--@api-stub: PointLight:y
-- Returns the world-space Y position.
-- Call when you need to invoke y.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:y() end)
  print("PointLight:y ->", ok, result)
end

--@api-stub: PointLight:radius
-- Returns the illumination radius.
-- Call when you need to invoke radius.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:radius() end)
  print("PointLight:radius ->", ok, result)
end

--@api-stub: PointLight:intensity
-- Returns the intensity multiplier.
-- Call when you need to invoke intensity.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:intensity() end)
  print("PointLight:intensity ->", ok, result)
end

--@api-stub: PointLight:color
-- Returns the RGB color as three separate values.
-- Call when you need to invoke color.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:color() end)
  print("PointLight:color ->", ok, result)
end

--@api-stub: PointLight:type
-- Returns the type string "PointLight".
-- Call when you need to invoke type.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("PointLight:type ->", ok, result)
end

--@api-stub: PointLight:typeOf
-- Returns the type string "PointLight".
-- Call when you need to invoke type of.
-- Build a PointLight via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newPointLight(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("PointLight:typeOf ->", ok, result)
end

-- ── Raycaster methods ──

--@api-stub: Raycaster:setCell
-- Sets the cell value at grid position (x, y).
-- Call when you need to assign cell.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:setCell(0, 0, nil) end)
  print("Raycaster:setCell ->", ok, result)
end

--@api-stub: Raycaster:getCell
-- Returns the cell value at (x, y).
-- Call when you need to read cell.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:getCell(0, 0) end)
  print("Raycaster:getCell ->", ok, result)
end

--@api-stub: Raycaster:setCells
-- Replaces all grid cells from a flat array of values in row-major order.
-- Call when you need to assign cells.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:setCells(nil) end)
  print("Raycaster:setCells ->", ok, result)
end

--@api-stub: Raycaster:isBlocked
-- Returns true when the cell at (x, y) is a wall (value > 0).
-- Call when you need to check is blocked.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:isBlocked(0, 0) end)
  print("Raycaster:isBlocked ->", ok, result)
end

--@api-stub: Raycaster:width
-- Returns the grid width in cells.
-- Call when you need to invoke width.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:width() end)
  print("Raycaster:width ->", ok, result)
end

--@api-stub: Raycaster:height
-- Returns the grid height in cells.
-- Call when you need to invoke height.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:height() end)
  print("Raycaster:height ->", ok, result)
end

--@api-stub: Raycaster:setWallAlpha
-- Sets the opacity for a wall tile type.
-- Alpha is clamped to [0, 1].
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:setWallAlpha(nil, 1) end)
  print("Raycaster:setWallAlpha ->", ok, result)
end

--@api-stub: Raycaster:getWallAlpha
-- Returns the opacity for a wall tile type.
-- Returns 1.0 if not set.
-- Build a Raycaster via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newRaycaster(...)
if instance then
  local ok, result = pcall(function() return instance:getWallAlpha(nil) end)
  print("Raycaster:getWallAlpha ->", ok, result)
end

-- ── SpriteManager methods ──

--@api-stub: SpriteManager:remove
-- Removes the sprite with the given id.
-- No-op if not found.
-- Build a SpriteManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newSpriteManager(...)
if instance then
  local ok, result = pcall(function() return instance:remove(1) end)
  print("SpriteManager:remove ->", ok, result)
end

--@api-stub: SpriteManager:setPosition
-- Moves the sprite with the given id to world (x, y).
-- Call when you need to assign position.
-- Build a SpriteManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newSpriteManager(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(1, 0, 0) end)
  print("SpriteManager:setPosition ->", ok, result)
end

--@api-stub: SpriteManager:setVisible
-- Shows or hides the sprite with the given id.
-- Call when you need to assign visible.
-- Build a SpriteManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newSpriteManager(...)
if instance then
  local ok, result = pcall(function() return instance:setVisible(1, nil) end)
  print("SpriteManager:setVisible ->", ok, result)
end

--@api-stub: SpriteManager:clear
-- Removes all sprites from the manager.
-- Call when you need to invoke clear.
-- Build a SpriteManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newSpriteManager(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("SpriteManager:clear ->", ok, result)
end

--@api-stub: SpriteManager:type
-- Returns the type string "SpriteManager".
-- Call when you need to invoke type.
-- Build a SpriteManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newSpriteManager(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("SpriteManager:type ->", ok, result)
end

--@api-stub: SpriteManager:typeOf
-- Returns the type string "SpriteManager".
-- Call when you need to invoke type of.
-- Build a SpriteManager via the appropriate lurek.raycaster.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.raycaster.newSpriteManager(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("SpriteManager:typeOf ->", ok, result)
end

