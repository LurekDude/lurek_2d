-- content/examples/raycaster.lua
-- Scaffolded coverage of the lurek.raycaster API (42 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/raycaster_api.rs   (Lua binding, arg types, return shape)
--   * src/raycaster/                 (semantics, side effects)
--   * docs/specs/raycaster.md        (canonical reference)
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
-- Run: cargo run -- content/examples/raycaster.lua

-- ── lurek.raycaster.* functions ──

--@api-stub: lurek.raycaster.new
-- Creates a new raycaster grid of the given dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.new
  local _todo = "TODO: write a real lurek.raycaster.new usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.newMap
-- Alias for `new`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.newMap
  local _todo = "TODO: write a real lurek.raycaster.newMap usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.projectColumn
-- Projects a wall distance to screen-space drawing parameters.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.projectColumn
  local _todo = "TODO: write a real lurek.raycaster.projectColumn usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.distanceShade
-- Returns distance-based brightness in [0, 1].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.distanceShade
  local _todo = "TODO: write a real lurek.raycaster.distanceShade usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.newDoorManager
-- Creates a new empty door manager.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.newDoorManager
  local _todo = "TODO: write a real lurek.raycaster.newDoorManager usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.newHeightMap
-- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.newHeightMap
  local _todo = "TODO: write a real lurek.raycaster.newHeightMap usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.newPointLight
-- Creates a point light for use in raycaster scene lighting.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.newPointLight
  local _todo = "TODO: write a real lurek.raycaster.newPointLight usage example"
  print(_todo)
end

--@api-stub: lurek.raycaster.newSpriteManager
-- Creates a new empty batch sprite manager for depth-sorted projection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: lurek.raycaster.newSpriteManager
  local _todo = "TODO: write a real lurek.raycaster.newSpriteManager usage example"
  print(_todo)
end

-- ── DoorManager methods ──

--@api-stub: DoorManager:openDoor
-- Begins opening the door at the given index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:openDoor
  local _todo = "TODO: write a real DoorManager:openDoor usage example"
  print(_todo)
end

--@api-stub: DoorManager:closeDoor
-- Begins closing the door at the given index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:closeDoor
  local _todo = "TODO: write a real DoorManager:closeDoor usage example"
  print(_todo)
end

--@api-stub: DoorManager:update
-- Advances all door animations by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:update
  local _todo = "TODO: write a real DoorManager:update usage example"
  print(_todo)
end

--@api-stub: DoorManager:getDoor
-- Returns the state table for door at index, or nil if out of range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:getDoor
  local _todo = "TODO: write a real DoorManager:getDoor usage example"
  print(_todo)
end

--@api-stub: DoorManager:count
-- Returns the number of registered doors.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:count
  local _todo = "TODO: write a real DoorManager:count usage example"
  print(_todo)
end

--@api-stub: DoorManager:type
-- Returns the type string "DoorManager".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:type
  local _todo = "TODO: write a real DoorManager:type usage example"
  print(_todo)
end

--@api-stub: DoorManager:typeOf
-- Returns the type string "DoorManager".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: DoorManager:typeOf
  local _todo = "TODO: write a real DoorManager:typeOf usage example"
  print(_todo)
end

-- ── HeightMap methods ──

--@api-stub: HeightMap:setFloor
-- Sets the floor height at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: HeightMap:setFloor
  local _todo = "TODO: write a real HeightMap:setFloor usage example"
  print(_todo)
end

--@api-stub: HeightMap:setCeiling
-- Sets the ceiling height at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: HeightMap:setCeiling
  local _todo = "TODO: write a real HeightMap:setCeiling usage example"
  print(_todo)
end

--@api-stub: HeightMap:floorAt
-- Returns the floor height at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: HeightMap:floorAt
  local _todo = "TODO: write a real HeightMap:floorAt usage example"
  print(_todo)
end

--@api-stub: HeightMap:ceilingAt
-- Returns the ceiling height at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: HeightMap:ceilingAt
  local _todo = "TODO: write a real HeightMap:ceilingAt usage example"
  print(_todo)
end

--@api-stub: HeightMap:type
-- Returns the type string "HeightMap".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: HeightMap:type
  local _todo = "TODO: write a real HeightMap:type usage example"
  print(_todo)
end

--@api-stub: HeightMap:typeOf
-- Returns the type string "HeightMap".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: HeightMap:typeOf
  local _todo = "TODO: write a real HeightMap:typeOf usage example"
  print(_todo)
end

-- ── PointLight methods ──

--@api-stub: PointLight:x
-- Returns the world-space X position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:x
  local _todo = "TODO: write a real PointLight:x usage example"
  print(_todo)
end

--@api-stub: PointLight:y
-- Returns the world-space Y position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:y
  local _todo = "TODO: write a real PointLight:y usage example"
  print(_todo)
end

--@api-stub: PointLight:radius
-- Returns the illumination radius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:radius
  local _todo = "TODO: write a real PointLight:radius usage example"
  print(_todo)
end

--@api-stub: PointLight:intensity
-- Returns the intensity multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:intensity
  local _todo = "TODO: write a real PointLight:intensity usage example"
  print(_todo)
end

--@api-stub: PointLight:color
-- Returns the RGB color as three separate values.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:color
  local _todo = "TODO: write a real PointLight:color usage example"
  print(_todo)
end

--@api-stub: PointLight:type
-- Returns the type string "PointLight".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:type
  local _todo = "TODO: write a real PointLight:type usage example"
  print(_todo)
end

--@api-stub: PointLight:typeOf
-- Returns the type string "PointLight".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: PointLight:typeOf
  local _todo = "TODO: write a real PointLight:typeOf usage example"
  print(_todo)
end

-- ── Raycaster methods ──

--@api-stub: Raycaster:setCell
-- Sets the cell value at grid position (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:setCell
  local _todo = "TODO: write a real Raycaster:setCell usage example"
  print(_todo)
end

--@api-stub: Raycaster:getCell
-- Returns the cell value at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:getCell
  local _todo = "TODO: write a real Raycaster:getCell usage example"
  print(_todo)
end

--@api-stub: Raycaster:setCells
-- Replaces all grid cells from a flat array of values in row-major order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:setCells
  local _todo = "TODO: write a real Raycaster:setCells usage example"
  print(_todo)
end

--@api-stub: Raycaster:isBlocked
-- Returns true when the cell at (x, y) is a wall (value > 0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:isBlocked
  local _todo = "TODO: write a real Raycaster:isBlocked usage example"
  print(_todo)
end

--@api-stub: Raycaster:width
-- Returns the grid width in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:width
  local _todo = "TODO: write a real Raycaster:width usage example"
  print(_todo)
end

--@api-stub: Raycaster:height
-- Returns the grid height in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:height
  local _todo = "TODO: write a real Raycaster:height usage example"
  print(_todo)
end

--@api-stub: Raycaster:setWallAlpha
-- Sets the opacity for a wall tile type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:setWallAlpha
  local _todo = "TODO: write a real Raycaster:setWallAlpha usage example"
  print(_todo)
end

--@api-stub: Raycaster:getWallAlpha
-- Returns the opacity for a wall tile type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: Raycaster:getWallAlpha
  local _todo = "TODO: write a real Raycaster:getWallAlpha usage example"
  print(_todo)
end

-- ── SpriteManager methods ──

--@api-stub: SpriteManager:remove
-- Removes the sprite with the given id.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: SpriteManager:remove
  local _todo = "TODO: write a real SpriteManager:remove usage example"
  print(_todo)
end

--@api-stub: SpriteManager:setPosition
-- Moves the sprite with the given id to world (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: SpriteManager:setPosition
  local _todo = "TODO: write a real SpriteManager:setPosition usage example"
  print(_todo)
end

--@api-stub: SpriteManager:setVisible
-- Shows or hides the sprite with the given id.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: SpriteManager:setVisible
  local _todo = "TODO: write a real SpriteManager:setVisible usage example"
  print(_todo)
end

--@api-stub: SpriteManager:clear
-- Removes all sprites from the manager.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: SpriteManager:clear
  local _todo = "TODO: write a real SpriteManager:clear usage example"
  print(_todo)
end

--@api-stub: SpriteManager:type
-- Returns the type string "SpriteManager".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: SpriteManager:type
  local _todo = "TODO: write a real SpriteManager:type usage example"
  print(_todo)
end

--@api-stub: SpriteManager:typeOf
-- Returns the type string "SpriteManager".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/raycaster_api.rs and docs/specs/raycaster.md).
do  -- TODO: SpriteManager:typeOf
  local _todo = "TODO: write a real SpriteManager:typeOf usage example"
  print(_todo)
end

