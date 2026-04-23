-- content/examples/raycaster.lua
-- Hand-written coverage of the lurek.raycaster API (42 items).
--
-- The raycaster module is a textured-quad 2.5D pipeline: build a
-- Raycaster2D grid, push doors / lights / height maps / sprites into
-- their managers, then call grid:buildScene{...} each frame to push
-- a quad list into the GPU pipeline. The factories below all return
-- userdata; the per-type methods are grouped further down.
--
-- Run: cargo run -- content/examples/raycaster.lua

-- ── lurek.raycaster.* functions ──

--@api-stub: lurek.raycaster.new
-- Creates a new raycaster grid of the given dimensions.
-- Sizes are in cells, not pixels; walls are u32 cell values where 0 means empty.
do  -- lurek.raycaster.new
  local rc = lurek.raycaster.new(16, 12)
  rc:setCell(3, 4, 1)
  lurek.log.info("grid " .. rc:width() .. "x" .. rc:height(), "raycaster")
end

--@api-stub: lurek.raycaster.newMap
-- Alias for `new`.
-- Use `newMap` in code that already speaks tilemap vocabulary; semantics are identical to `new`.
do  -- lurek.raycaster.newMap
  local map = lurek.raycaster.newMap(32, 32)
  for x = 0, 31 do map:setCell(x, 0, 1); map:setCell(x, 31, 1) end
  for y = 0, 31 do map:setCell(0, y, 1); map:setCell(31, y, 1) end
end

--@api-stub: lurek.raycaster.projectColumn
-- Projects a wall distance to screen-space drawing parameters.
-- Returns (column_height, top_y, bottom_y); apply fish-eye correction to `distance` upstream when needed.
do  -- lurek.raycaster.projectColumn
  local fov = math.pi / 3
  local h, top, bot = lurek.raycaster.projectColumn(4.5, fov, 720)
  lurek.log.debug("col h=" .. h .. " top=" .. top .. " bot=" .. bot, "raycaster")
end

--@api-stub: lurek.raycaster.distanceShade
-- Returns distance-based brightness in [0, 1].
-- Multiply this into the wall colour each column to fade walls into ambient at `max_distance`.
do  -- lurek.raycaster.distanceShade
  local shade = lurek.raycaster.distanceShade(6.0, 12.0)
  local r, g, b = 0.8 * shade, 0.6 * shade, 0.4 * shade
  lurek.log.debug("wall rgb=" .. r .. "," .. g .. "," .. b, "raycaster")
end

--@api-stub: lurek.raycaster.newDoorManager
-- Creates a new empty door manager.
-- Hold one DoorManager per level; push every animated door through it so a single update(dt) advances them all.
do  -- lurek.raycaster.newDoorManager
  local doors = lurek.raycaster.newDoorManager()
  doors:addDoor(5, 7, "horizontal", 2.5)
  doors:addDoor(9, 3, "vertical", 1.8)
end

--@api-stub: lurek.raycaster.newHeightMap
-- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
-- Authoritative for variable floor/ceiling rendering; size should match the Raycaster2D grid it accompanies.
do  -- lurek.raycaster.newHeightMap
  local hm = lurek.raycaster.newHeightMap(16, 12)
  hm:setFloor(4, 5, -0.25)
  hm:setCeiling(4, 5, 1.5)
end

--@api-stub: lurek.raycaster.newPointLight
-- Creates a point light for use in raycaster scene lighting.
-- Pass the resulting userdata into `grid:buildScene{}` via the `lights` array; intensity scales with 1/distance^2.
do  -- lurek.raycaster.newPointLight
  local torch = lurek.raycaster.newPointLight(8.5, 6.0, 1.0, 0.7, 0.3, 4.0, 1.5)
  lurek.log.info("torch radius=" .. torch:radius(), "raycaster")
end

--@api-stub: lurek.raycaster.newSpriteManager
-- Creates a new empty batch sprite manager for depth-sorted projection.
-- Use one per level; sortAndProject(cam_x, cam_y, angle) returns visible sprites back-to-front for billboarding.
do  -- lurek.raycaster.newSpriteManager
  local sprites = lurek.raycaster.newSpriteManager()
  sprites:add(6.5, 4.5, "enemy_zombie", 1.0)
  sprites:add(10.0, 8.0, "barrel", 0.75)
end

-- ── DoorManager methods ──

--@api-stub: DoorManager:openDoor
-- Begins opening the door at the given index.
-- Indices are 0-based and come from `addDoor`; calling on an already-open door is a no-op.
do  -- DoorManager:openDoor
  local doors = lurek.raycaster.newDoorManager()
  local idx = doors:addDoor(5, 7, "horizontal", 2.0)
  doors:openDoor(idx)
end

--@api-stub: DoorManager:closeDoor
-- Begins closing the door at the given index.
-- Pair with proximity checks each frame so doors auto-close when the player walks away.
do  -- DoorManager:closeDoor
  local doors = lurek.raycaster.newDoorManager()
  local idx = doors:addDoor(12, 4, "vertical", 1.5)
  doors:openDoor(idx)
  doors:closeDoor(idx)
end

--@api-stub: DoorManager:update
-- Advances all door animations by dt seconds.
-- Call once per frame in lurek.process(dt); skipping it freezes every door mid-animation.
do  -- DoorManager:update
  local doors = lurek.raycaster.newDoorManager()
  doors:addDoor(3, 3, "horizontal", 2.0)
  function lurek.process(dt) doors:update(dt) end
end

--@api-stub: DoorManager:getDoor
-- Returns the state table for door at index, or nil if out of range.
-- Read `openAmount` (0..1) to decide whether the player can pass; check `state` for "closed"/"opening"/"open"/"closing".
do  -- DoorManager:getDoor
  local doors = lurek.raycaster.newDoorManager()
  local idx = doors:addDoor(5, 7, "horizontal", 2.0)
  local d = doors:getDoor(idx)
  if d and d.openAmount > 0.9 then lurek.log.info("door " .. d.x .. "," .. d.y .. " passable", "doors") end
end

--@api-stub: DoorManager:count
-- Returns the number of registered doors.
-- Useful for level summaries, save snapshots, or pre-allocating a Lua array of door state.
do  -- DoorManager:count
  local doors = lurek.raycaster.newDoorManager()
  doors:addDoor(2, 2, "horizontal", 2.0)
  doors:addDoor(8, 5, "vertical", 2.0)
  lurek.log.info("level has " .. doors:count() .. " doors", "doors")
end

--@api-stub: DoorManager:type
-- Returns the type string "DoorManager".
-- Use in defensive helpers that accept multiple userdata shapes and need to dispatch by name.
do  -- DoorManager:type
  local doors = lurek.raycaster.newDoorManager()
  if doors:type() == "DoorManager" then lurek.log.debug("door manager OK", "raycaster") end
end

--@api-stub: DoorManager:typeOf
-- Returns the type string "DoorManager".
-- Mirrors love2d's Object:typeOf naming so reusable utility libraries can branch the same way.
do  -- DoorManager:typeOf
  local doors = lurek.raycaster.newDoorManager()
  local kind = doors:typeOf()
  if kind == "DoorManager" then lurek.log.debug("dispatched as " .. kind, "raycaster") end
end

-- ── HeightMap methods ──

--@api-stub: HeightMap:setFloor
-- Sets the floor height at (x, y).
-- Negative values dig pits; pair with setCeiling to carve cavities the player can drop into.
do  -- HeightMap:setFloor
  local hm = lurek.raycaster.newHeightMap(16, 12)
  for x = 4, 7 do hm:setFloor(x, 6, -0.5) end
  hm:setFloor(8, 6, -0.25)
end

--@api-stub: HeightMap:setCeiling
-- Sets the ceiling height at (x, y).
-- Lower values create crawl-spaces; the renderer clips wall columns to floorAt..ceilingAt.
do  -- HeightMap:setCeiling
  local hm = lurek.raycaster.newHeightMap(16, 12)
  for x = 0, 15 do hm:setCeiling(x, 0, 0.6) end
end

--@api-stub: HeightMap:floorAt
-- Returns the floor height at (x, y).
-- Out-of-bounds reads return 0.0; use this for player gravity / jump landing checks.
do  -- HeightMap:floorAt
  local hm = lurek.raycaster.newHeightMap(16, 12)
  hm:setFloor(5, 5, -0.4)
  local h = hm:floorAt(5, 5)
  if h < 0 then lurek.log.debug("pit depth " .. -h, "raycaster") end
end

--@api-stub: HeightMap:ceilingAt
-- Returns the ceiling height at (x, y).
-- Default for unset cells is 1.0; subtract floorAt to get available headroom for entity placement.
do  -- HeightMap:ceilingAt
  local hm = lurek.raycaster.newHeightMap(16, 12)
  local headroom = hm:ceilingAt(3, 4) - hm:floorAt(3, 4)
  lurek.log.debug("cell headroom=" .. headroom, "raycaster")
end

--@api-stub: HeightMap:type
-- Returns the type string "HeightMap".
-- Lets generic asset loaders confirm a userdata is a height map before passing it to buildScene.
do  -- HeightMap:type
  local hm = lurek.raycaster.newHeightMap(8, 8)
  assert(hm:type() == "HeightMap", "expected HeightMap userdata")
end

--@api-stub: HeightMap:typeOf
-- Returns the type string "HeightMap".
-- Identical to `:type()`; provided for love2d-style code that uses `:typeOf()` everywhere.
do  -- HeightMap:typeOf
  local hm = lurek.raycaster.newHeightMap(8, 8)
  if hm:typeOf() == "HeightMap" then lurek.log.debug("is HeightMap", "raycaster") end
end

-- ── PointLight methods ──

--@api-stub: PointLight:x
-- Returns the world-space X position.
-- Read alongside `:y()` to drive light-follows-actor patterns or fade lights based on player proximity.
do  -- PointLight:x
  local light = lurek.raycaster.newPointLight(10.0, 5.0, 1, 1, 1, 5, 1)
  local px = light:x()
  if px > 8 then lurek.log.debug("light is east of midpoint at x=" .. px, "raycaster") end
end

--@api-stub: PointLight:y
-- Returns the world-space Y position.
-- Combine with `:x()` and `:radius()` for cull tests against the camera bounds before submitting to buildScene.
do  -- PointLight:y
  local light = lurek.raycaster.newPointLight(4.0, 7.5, 1, 0.8, 0.6, 4, 1.2)
  local py = light:y()
  lurek.log.debug("light row " .. math.floor(py), "raycaster")
end

--@api-stub: PointLight:radius
-- Returns the illumination radius.
-- Use the radius to skip illumination math for cells outside the bounding square `(x±r, y±r)`.
do  -- PointLight:radius
  local light = lurek.raycaster.newPointLight(8, 6, 1, 1, 1, 6.0, 1.0)
  local r = light:radius()
  if r > 5 then lurek.log.info("large light radius=" .. r, "raycaster") end
end

--@api-stub: PointLight:intensity
-- Returns the intensity multiplier.
-- Multiply this against `distanceShade` to attenuate per-pixel without rebuilding the light.
do  -- PointLight:intensity
  local light = lurek.raycaster.newPointLight(2, 3, 1, 0.5, 0.2, 3, 2.5)
  local mul = light:intensity() * lurek.raycaster.distanceShade(1.5, 6.0)
  lurek.log.debug("contrib=" .. mul, "raycaster")
end

--@api-stub: PointLight:color
-- Returns the RGB color as three separate values.
-- Use the multi-return form to tint debug overlays of the light or to feed back into buildScene's lights array.
do  -- PointLight:color
  local light = lurek.raycaster.newPointLight(4, 4, 1.0, 0.4, 0.2, 5, 1)
  local r, g, b = light:color()
  lurek.log.debug("torch tint " .. r .. "," .. g .. "," .. b, "raycaster")
end

--@api-stub: PointLight:type
-- Returns the type string "PointLight".
-- Cheap runtime tag used by editors and serializers to recognise raycaster lights.
do  -- PointLight:type
  local light = lurek.raycaster.newPointLight(0, 0, 1, 1, 1, 1, 1)
  assert(light:type() == "PointLight")
end

--@api-stub: PointLight:typeOf
-- Returns the type string "PointLight".
-- Same value as `:type()`; provided for parity with love2d-style userdata.
do  -- PointLight:typeOf
  local light = lurek.raycaster.newPointLight(1, 1, 0.5, 0.5, 1, 2, 1)
  if light:typeOf() == "PointLight" then lurek.log.debug("light kind ok", "raycaster") end
end

-- ── Raycaster methods ──

--@api-stub: Raycaster:setCell
-- Sets the cell value at grid position (x, y).
-- Value 0 means empty; non-zero is a wall whose value picks the texture from buildScene's `wall_textures`.
do  -- Raycaster:setCell
  local rc = lurek.raycaster.new(8, 8)
  for x = 0, 7 do rc:setCell(x, 0, 1); rc:setCell(x, 7, 1) end
  rc:setCell(3, 3, 2)
end

--@api-stub: Raycaster:getCell
-- Returns the cell value at (x, y).
-- Returns 0 for both empty cells and out-of-bounds; combine with `:isBlocked` if you need the distinction.
do  -- Raycaster:getCell
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(2, 2, 3)
  if rc:getCell(2, 2) == 3 then lurek.log.debug("cell holds tile id 3", "raycaster") end
end

--@api-stub: Raycaster:setCells
-- Replaces all grid cells from a flat array of values in row-major order.
-- Length must equal width*height; this is the fastest way to load a level from a TOML or JSON map.
do  -- Raycaster:setCells
  local rc = lurek.raycaster.new(4, 3)
  rc:setCells({
    1, 1, 1, 1,
    1, 0, 0, 1,
    1, 1, 1, 1,
  })
end

--@api-stub: Raycaster:isBlocked
-- Returns true when the cell at (x, y) is a wall (value > 0).
-- The canonical move-collision test: gate any prospective player position through this before applying it.
do  -- Raycaster:isBlocked
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(4, 4, 1)
  if not rc:isBlocked(3, 4) then lurek.log.debug("(3,4) is walkable", "raycaster") end
end

--@api-stub: Raycaster:width
-- Returns the grid width in cells.
-- Use with `:height()` to clamp player coordinates and bound minimap drawing rectangles.
do  -- Raycaster:width
  local rc = lurek.raycaster.new(20, 15)
  for x = 0, rc:width() - 1 do rc:setCell(x, 0, 1) end
end

--@api-stub: Raycaster:height
-- Returns the grid height in cells.
-- Pair with `:width()` to iterate every cell when serialising the level for save/load.
do  -- Raycaster:height
  local rc = lurek.raycaster.new(20, 15)
  for y = 0, rc:height() - 1 do rc:setCell(0, y, 1) end
end

--@api-stub: Raycaster:setWallAlpha
-- Sets the opacity for a wall tile type.
-- Values < 1.0 mark the tile as translucent so castRayMulti collects layered hits (glass, fences, force-fields).
do  -- Raycaster:setWallAlpha
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(3, 3, 5)
  rc:setWallAlpha(5, 0.4)
end

--@api-stub: Raycaster:getWallAlpha
-- Returns the opacity for a wall tile type.
-- Defaults to 1.0 when never set; use it to debug-overlay translucent tiles in the level editor.
do  -- Raycaster:getWallAlpha
  local rc = lurek.raycaster.new(8, 8)
  rc:setWallAlpha(2, 0.6)
  local a = rc:getWallAlpha(2)
  if a < 1.0 then lurek.log.debug("tile 2 alpha=" .. a, "raycaster") end
end

-- ── SpriteManager methods ──

--@api-stub: SpriteManager:remove
-- Removes the sprite with the given id.
-- Ids are returned from `:add(...)`; call this when an enemy dies or a pickup is collected.
do  -- SpriteManager:remove
  local sprites = lurek.raycaster.newSpriteManager()
  local id = sprites:add(5.0, 4.0, "potion", 0.5)
  sprites:remove(id)
end

--@api-stub: SpriteManager:setPosition
-- Moves the sprite with the given id to world (x, y).
-- Cheap per-frame call; use it to drive moving NPCs without re-allocating sprite entries.
do  -- SpriteManager:setPosition
  local sprites = lurek.raycaster.newSpriteManager()
  local id = sprites:add(2.0, 2.0, "enemy_imp", 1.0)
  function lurek.process(dt) sprites:setPosition(id, 2.0 + dt, 2.0) end
end

--@api-stub: SpriteManager:setVisible
-- Shows or hides the sprite with the given id.
-- Prefer this over remove/add for sprites that flicker (invulnerability frames, fog-of-war reveals).
do  -- SpriteManager:setVisible
  local sprites = lurek.raycaster.newSpriteManager()
  local id = sprites:add(7.0, 3.0, "key_red", 0.6)
  sprites:setVisible(id, false)
end

--@api-stub: SpriteManager:clear
-- Removes all sprites from the manager.
-- Call between level transitions to drop every billboard before populating the next room.
do  -- SpriteManager:clear
  local sprites = lurek.raycaster.newSpriteManager()
  sprites:add(1, 1, "barrel", 1.0)
  sprites:add(3, 4, "barrel", 1.0)
  sprites:clear()
end

--@api-stub: SpriteManager:type
-- Returns the type string "SpriteManager".
-- Useful in serializers that walk a heterogeneous level table and dispatch on each userdata's type.
do  -- SpriteManager:type
  local sprites = lurek.raycaster.newSpriteManager()
  assert(sprites:type() == "SpriteManager")
end

--@api-stub: SpriteManager:typeOf
-- Returns the type string "SpriteManager".
-- Mirrors love2d's Object:typeOf so library code can branch identically across engines.
do  -- SpriteManager:typeOf
  local sprites = lurek.raycaster.newSpriteManager()
  if sprites:typeOf() == "SpriteManager" then lurek.log.debug("sprite mgr ok", "raycaster") end
end
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
--     `function lurek.draw() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/raycaster.lua

-- ── lurek.raycaster.* functions ──

--@api-stub: SpriteManager:add
-- Registers a sprite in the sprite manager at a world-space position.
-- Returns a sprite id; update position each frame with setPosition(id, x, y).
do  -- SpriteManager:add
  local sm = lurek.raycaster.newSpriteManager()
  local id = sm:add(3.5, 2.5, 1, 0)
  lurek.log.info("sprite id: " .. id, "raycaster")
end

--@api-stub: DoorManager:addDoor
-- Registers a door at a specific map cell with open/close state and animation speed.
-- DoorManager.update() advances door animations each frame automatically.
do  -- DoorManager:addDoor
  local dm = lurek.raycaster.newDoorManager()
  local rc = lurek.raycaster.new(32, 32, 1)
  local did = dm:addDoor(rc, 5, 7, 0)
  lurek.log.info("door id: " .. did, "raycaster")
end

--@api-stub: Raycaster:buildScene
-- Precomputes a scene description from the current cell map for column-order rendering.
-- Call after setCell() changes; subsequent castRays use the compiled scene.
do  -- Raycaster:buildScene
  local rc = lurek.raycaster.new(16, 16, 1)
  rc:setCells(1, 1, 1, 1, 1, 0)
  rc:buildScene()
  lurek.log.info("scene built", "raycaster")
end

--@api-stub: Raycaster:castFloorRow
-- Casts a single floor/ceiling row and returns depth and texture-coordinate tables.
-- Call for each screen row between the horizon and the floor to build the floor plane.
do  -- Raycaster:castFloorRow
  local rc = lurek.raycaster.new(16, 16, 1)
  local depths, us, vs = rc:castFloorRow(240, 400, 300, 0, 0.5)
  lurek.log.info("floor row depth count: " .. (depths and #depths or 0), "raycaster")
end

--@api-stub: Raycaster:castRay
-- Casts a single ray from origin in direction angle and returns the hit data.
-- Returns distance, wallType, side, and texture coordinates for the hit cell.
do  -- Raycaster:castRay
  local rc = lurek.raycaster.new(16, 16, 1)
  local dist, wtype, side, tx = rc:castRay(8, 8, 0)
  lurek.log.info("ray dist: " .. (dist or -1), "raycaster")
end

--@api-stub: Raycaster:castRayMulti
-- Casts multiple rays from different positions and returns a results table.
-- Useful for multi-camera setups or custom rendering passes.
do  -- Raycaster:castRayMulti
  local rc = lurek.raycaster.new(16, 16, 1)
  local results = rc:castRayMulti({{x=8,y=8,angle=0},{x=4,y=4,angle=math.pi/2}})
  lurek.log.info("multi-ray results: " .. #results, "raycaster")
end

--@api-stub: Raycaster:castRays
-- Casts a full fan of rays for the current camera view and returns the column buffer.
-- Returns a table of per-column hit data; used by drawView() internally.
do  -- Raycaster:castRays
  local rc = lurek.raycaster.new(16, 16, 1)
  local cols = rc:castRays(8, 8, 0, math.pi/3, 320)
  lurek.log.info("columns: " .. (cols and #cols or 0), "raycaster")
end

--@api-stub: Raycaster:castRaysFlat
-- Casts rays and returns results in a flat array format for GPU upload.
-- More cache-friendly than castRays for large column counts.
do  -- Raycaster:castRaysFlat
  local rc = lurek.raycaster.new(16, 16, 1)
  local flat = rc:castRaysFlat(8, 8, 0, math.pi/3, 320)
  lurek.log.info("flat ray count: " .. (flat and #flat or 0), "raycaster")
end

--@api-stub: Raycaster:drawCameraSweep
-- Renders a top-down camera FOV arc onto an ImageData for a minimap overlay.
-- fov and range control the visible arc; useful for guard-vision debugging.
do  -- Raycaster:drawCameraSweep
  local rc = lurek.raycaster.new(16, 16, 1)
  local img = lurek.image.newImageData(128, 128)
  rc:drawCameraSweep(img, 8, 8, 0, math.pi/3, 6, 8, 8)
  lurek.log.info("camera sweep drawn", "raycaster")
end

--@api-stub: Raycaster:drawDepthMap
-- Renders the per-column depth buffer as a greyscale gradient into an ImageData.
-- Useful for debugging occlusion and rendering artefacts.
do  -- Raycaster:drawDepthMap
  local rc = lurek.raycaster.new(16, 16, 1)
  local img = lurek.image.newImageData(320, 240)
  local cols = rc:castRays(8, 8, 0, math.pi/3, 320)
  rc:drawDepthMap(img, cols)
  lurek.log.info("depth map drawn", "raycaster")
end

--@api-stub: Raycaster:drawLineOfSight
-- Draws a filled line-of-sight polygon onto a top-down ImageData.
-- Shows visible area from a guard's perspective for minimap or debugging.
do  -- Raycaster:drawLineOfSight
  local rc = lurek.raycaster.new(16, 16, 1)
  local img = lurek.image.newImageData(128, 128)
  rc:drawLineOfSight(img, 8, 8, 0, math.pi/3, 8, 8, 8)
  lurek.log.info("LOS drawn", "raycaster")
end

--@api-stub: Raycaster:drawTopDown
-- Renders the map grid and optionally objects as a 2D top-down view.
-- Use for minimaps, editor overlays, or debugging spatial relationships.
do  -- Raycaster:drawTopDown
  local rc = lurek.raycaster.new(16, 16, 1)
  local img = lurek.image.newImageData(128, 128)
  rc:drawTopDown(img, 8, 8)
  lurek.log.info("top-down drawn", "raycaster")
end

--@api-stub: Raycaster:drawView
-- Renders the full pseudo-3D first-person view from the camera position and angle.
-- Writes column-by-column into an ImageData; call once per frame in lurek.render().
do  -- Raycaster:drawView
  local rc = lurek.raycaster.new(16, 16, 1)
  local img = lurek.image.newImageData(320, 240)
  rc:drawView(img, 8, 8, 0, math.pi/3, 240)
  lurek.log.info("view rendered", "raycaster")
end

--@api-stub: Raycaster:lineOfSight
-- Returns true if there is unobstructed sight between two map-space positions.
-- Uses DDA; blocked cells with non-zero wall values break the line.
do  -- Raycaster:lineOfSight
  local rc = lurek.raycaster.new(16, 16, 1)
  local los = rc:lineOfSight(4, 4, 12, 12)
  lurek.log.info("LOS result: " .. tostring(los), "raycaster")
end

--@api-stub: Raycaster:projectSprite
-- Projects a world-space sprite into screen-space column/height data.
-- Returns screen_x, screen_y, height, and a visibility mask for the sprite.
do  -- Raycaster:projectSprite
  local rc = lurek.raycaster.new(16, 16, 1)
  local sx, sy, h = rc:projectSprite(8, 4, 4, 0, math.pi/3, 320, 240)
  lurek.log.info("projected: " .. (sx or -1), "raycaster")
end

--@api-stub: Raycaster:setCell
-- Sets the wall type of a single cell in the map grid.
-- type=0 means empty (walkable); non-zero values index the texture atlas.
do  -- Raycaster:setCell
  local rc = lurek.raycaster.new(16, 16, 1)
  rc:setCell(4, 4, 2)
  lurek.log.info("cell 4,4 = 2", "raycaster")
end

--@api-stub: SpriteManager:sortAndProject
-- Sorts sprites by distance from the camera and projects them into screen-space.
-- Call after castRays() each frame; returns sorted projection data table.
do  -- SpriteManager:sortAndProject
  local sm = lurek.raycaster.newSpriteManager()
  sm:add(3.5, 2.5, 1, 0)
  local projs = sm:sortAndProject(8, 8, 0, math.pi/3, 320, 240)
  lurek.log.info("projected sprites: " .. #projs, "raycaster")
end

--@api-stub: PointLight:set
-- Configures a PointLight's position, colour, and radius in one call.
-- Use instead of separate property setters when updating all fields each frame.
do  -- PointLight:set
  local light = lurek.raycaster.newPointLight()
  light:set(4.5, 3.5, 1.0, 0.9, 0.7, 6.0)
  lurek.log.info("point light configured", "raycaster")
end
