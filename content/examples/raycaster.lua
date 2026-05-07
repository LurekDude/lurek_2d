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

-- â”€â”€ lurek.raycaster.* functions â”€â”€

--@api-stub: lurek.raycaster.new
-- Creates a new raycaster grid of the given dimensions.
-- Sizes are in cells, not pixels; walls are u32 cell values where 0 means empty.
-- if false then -- lurek.raycaster.new
--   local rc = lurek.raycaster.new(16, 12)
--   rc:setCell(3, 4, 1)
--   lurek.log.info("grid " .. rc:width() .. "x" .. rc:height(), "raycaster")
-- end

--@api-stub: lurek.raycaster.newMap
-- Alias for `new`.
-- Use `newMap` in code that already speaks tilemap vocabulary; semantics are identical to `new`.
-- if false then -- lurek.raycaster.newMap
--   local map = lurek.raycaster.newMap(32, 32)
--   for x = 0, 31 do map:setCell(x, 0, 1); map:setCell(x, 31, 1) end
--   for y = 0, 31 do map:setCell(0, y, 1); map:setCell(31, y, 1) end
-- end

--@api-stub: lurek.raycaster.projectColumn
-- Projects a wall distance to screen-space drawing parameters.
-- Returns (column_height, top_y, bottom_y); apply fish-eye correction to `distance` upstream when needed.
-- if false then -- lurek.raycaster.projectColumn
--   local fov = math.pi / 3
--   local h, top, bot = lurek.raycaster.projectColumn(4.5, fov, 720)
--   lurek.log.debug("col h=" .. h .. " top=" .. top .. " bot=" .. bot, "raycaster")
-- end

--@api-stub: lurek.raycaster.distanceShade
-- Returns distance-based brightness in [0, 1].
-- Multiply this into the wall colour each column to fade walls into ambient at `max_distance`.
-- if false then -- lurek.raycaster.distanceShade
--   local shade = lurek.raycaster.distanceShade(6.0, 12.0)
--   local r, g, b = 0.8 * shade, 0.6 * shade, 0.4 * shade
--   lurek.log.debug("wall rgb=" .. r .. "," .. g .. "," .. b, "raycaster")
-- end

--@api-stub: lurek.raycaster.newDoorManager
-- Creates a new empty door manager.
-- Hold one DoorManager per level; push every animated door through it so a single update(dt) advances them all.
-- if false then -- lurek.raycaster.newDoorManager
--   local doors = lurek.raycaster.newDoorManager()
--   doors:addDoor(5, 7, "horizontal", 2.5)
--   doors:addDoor(9, 3, "vertical", 1.8)
-- end

--@api-stub: lurek.raycaster.newHeightMap
-- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
-- Authoritative for variable floor/ceiling rendering; size should match the Raycaster2D grid it accompanies.
-- if false then -- lurek.raycaster.newHeightMap
--   local hm = lurek.raycaster.newHeightMap(16, 12)
--   hm:setFloor(4, 5, -0.25)
--   hm:setCeiling(4, 5, 1.5)
-- end

--@api-stub: lurek.raycaster.newPointLight
-- Creates a point light for use in raycaster scene lighting.
-- Pass the resulting userdata into `grid:buildScene{}` via the `lights` array; intensity scales with 1/distance^2.
-- if false then -- lurek.raycaster.newPointLight
--   local torch = lurek.raycaster.newPointLight(8.5, 6.0, 1.0, 0.7, 0.3, 4.0, 1.5)
--   lurek.log.info("torch radius=" .. torch:radius(), "raycaster")
-- end

--@api-stub: lurek.raycaster.newSpriteManager
-- Creates a new empty batch sprite manager for depth-sorted projection.
-- Use one per level; sortAndProject(cam_x, cam_y, angle) returns visible sprites back-to-front for billboarding.
-- if false then -- lurek.raycaster.newSpriteManager
--   local sprites = lurek.raycaster.newSpriteManager()
--   sprites:add(6.5, 4.5, "enemy_zombie", 1.0)
--   sprites:add(10.0, 8.0, "barrel", 0.75)
-- end

-- â”€â”€ DoorManager methods â”€â”€

--@api-stub: LDoorManager:openDoor
-- Begins opening the door at the given index.
-- Indices are 0-based and come from `addDoor`; calling on an already-open door is a no-op.
-- if false then -- DoorManager:openDoor
--   local doors = lurek.raycaster.newDoorManager()
--   local idx = doors:addDoor(5, 7, "horizontal", 2.0)
--   doors:openDoor(idx)
-- end

--@api-stub: LDoorManager:closeDoor
-- Begins closing the door at the given index.
-- Pair with proximity checks each frame so doors auto-close when the player walks away.
-- if false then -- DoorManager:closeDoor
--   local doors = lurek.raycaster.newDoorManager()
--   local idx = doors:addDoor(12, 4, "vertical", 1.5)
--   doors:openDoor(idx)
--   doors:closeDoor(idx)
-- end

--@api-stub: LDoorManager:update
-- Advances all door animations by dt seconds.
-- Call once per frame in lurek.process(dt); skipping it freezes every door mid-animation.
-- if false then -- DoorManager:update
--   local doors = lurek.raycaster.newDoorManager()
--   doors:addDoor(3, 3, "horizontal", 2.0)
--   function lurek.process(dt) doors:update(dt) end
-- end

--@api-stub: LDoorManager:getDoor
-- Returns the state table for door at index, or nil if out of range.
-- Read `openAmount` (0..1) to decide whether the player can pass; check `state` for "closed"/"opening"/"open"/"closing".
-- if false then -- DoorManager:getDoor
--   local doors = lurek.raycaster.newDoorManager()
--   local idx = doors:addDoor(5, 7, "horizontal", 2.0)
--   local d = doors:getDoor(idx)
--   if d and d.openAmount > 0.9 then lurek.log.info("door " .. d.x .. "," .. d.y .. " passable", "doors") end
-- end

--@api-stub: LDoorManager:count
-- Returns the number of registered doors.
-- Useful for level summaries, save snapshots, or pre-allocating a Lua array of door state.
-- if false then -- DoorManager:count
--   local doors = lurek.raycaster.newDoorManager()
--   doors:addDoor(2, 2, "horizontal", 2.0)
--   doors:addDoor(8, 5, "vertical", 2.0)
--   lurek.log.info("level has " .. doors:count() .. " doors", "doors")
-- end

--@api-stub: LDoorManager:type
-- Returns the type string "DoorManager".
-- Use in defensive helpers that accept multiple userdata shapes and need to dispatch by name.
-- if false then -- DoorManager:type
--   local doors = lurek.raycaster.newDoorManager()
--   if doors:type() == "DoorManager" then lurek.log.debug("door manager OK", "raycaster") end
-- end

--@api-stub: LDoorManager:typeOf
-- Returns true when the userdata matches a requested type name.
-- Mirrors love2d's Object:typeOf predicate shape so reusable utility libraries can branch the same way.
-- if false then -- DoorManager:typeOf
--   local doors = lurek.raycaster.newDoorManager()
--   if doors:typeOf("DoorManager") then lurek.log.debug("dispatched as DoorManager", "raycaster") end
-- end

-- â”€â”€ HeightMap methods â”€â”€

--@api-stub: LHeightMap:setFloor
-- Sets the floor height at (x, y).
-- Negative values dig pits; pair with setCeiling to carve cavities the player can drop into.
-- if false then -- HeightMap:setFloor
--   local hm = lurek.raycaster.newHeightMap(16, 12)
--   for x = 4, 7 do hm:setFloor(x, 6, -0.5) end
--   hm:setFloor(8, 6, -0.25)
-- end

--@api-stub: LHeightMap:setCeiling
-- Sets the ceiling height at (x, y).
-- Lower values create crawl-spaces; the renderer clips wall columns to floorAt..ceilingAt.
-- if false then -- HeightMap:setCeiling
--   local hm = lurek.raycaster.newHeightMap(16, 12)
--   for x = 0, 15 do hm:setCeiling(x, 0, 0.6) end
-- end

--@api-stub: LHeightMap:floorAt
-- Returns the floor height at (x, y).
-- Out-of-bounds reads return 0.0; use this for player gravity / jump landing checks.
-- if false then -- HeightMap:floorAt
--   local hm = lurek.raycaster.newHeightMap(16, 12)
--   hm:setFloor(5, 5, -0.4)
--   local h = hm:floorAt(5, 5)
--   if h < 0 then lurek.log.debug("pit depth " .. -h, "raycaster") end
-- end

--@api-stub: LHeightMap:ceilingAt
-- Returns the ceiling height at (x, y).
-- Default for unset cells is 1.0; subtract floorAt to get available headroom for entity placement.
-- if false then -- HeightMap:ceilingAt
--   local hm = lurek.raycaster.newHeightMap(16, 12)
--   local headroom = hm:ceilingAt(3, 4) - hm:floorAt(3, 4)
--   lurek.log.debug("cell headroom=" .. headroom, "raycaster")
-- end

--@api-stub: LHeightMap:type
-- Returns the type string "HeightMap".
-- Lets generic asset loaders confirm a userdata is a height map before passing it to buildScene.
-- if false then -- HeightMap:type
--   local hm = lurek.raycaster.newHeightMap(8, 8)
--   lurek.log.debug("heightmap type: " .. hm:type(), "raycaster")
-- end

--@api-stub: LHeightMap:typeOf
-- Returns true when the userdata matches a requested type name.
-- Uses the same love2d-style predicate shape as other userdata helpers.
-- if false then -- HeightMap:typeOf
--   local hm = lurek.raycaster.newHeightMap(8, 8)
--   if hm:typeOf("HeightMap") then lurek.log.debug("is HeightMap", "raycaster") end
-- end

-- â”€â”€ PointLight methods â”€â”€

--@api-stub: LPointLight:x
-- Returns the world-space X position.
-- Read alongside `:y()` to drive light-follows-actor patterns or fade lights based on player proximity.
-- if false then -- PointLight:x
--   local light = lurek.raycaster.newPointLight(10.0, 5.0, 1, 1, 1, 5, 1)
--   local px = light:x()
--   if px > 8 then lurek.log.debug("light is east of midpoint at x=" .. px, "raycaster") end
-- end

--@api-stub: LPointLight:y
-- Returns the world-space Y position.
-- Combine with `:x()` and `:radius()` for cull tests against the camera bounds before submitting to buildScene.
-- if false then -- PointLight:y
--   local light = lurek.raycaster.newPointLight(4.0, 7.5, 1, 0.8, 0.6, 4, 1.2)
--   local py = light:y()
--   lurek.log.debug("light row " .. math.floor(py), "raycaster")
-- end

--@api-stub: LPointLight:radius
-- Returns the illumination radius.
-- Use the radius to skip illumination math for cells outside the bounding square `(xÂ±r, yÂ±r)`.
-- if false then -- PointLight:radius
--   local light = lurek.raycaster.newPointLight(8, 6, 1, 1, 1, 6.0, 1.0)
--   local r = light:radius()
--   if r > 5 then lurek.log.info("large light radius=" .. r, "raycaster") end
-- end

--@api-stub: LPointLight:intensity
-- Returns the intensity multiplier.
-- Multiply this against `distanceShade` to attenuate per-pixel without rebuilding the light.
-- if false then -- PointLight:intensity
--   local light = lurek.raycaster.newPointLight(2, 3, 1, 0.5, 0.2, 3, 2.5)
--   local mul = light:intensity() * lurek.raycaster.distanceShade(1.5, 6.0)
--   lurek.log.debug("contrib=" .. mul, "raycaster")
-- end

--@api-stub: LPointLight:color
-- Returns the RGB color as three separate values.
-- Use the multi-return form to tint debug overlays of the light or to feed back into buildScene's lights array.
-- if false then -- PointLight:color
--   local light = lurek.raycaster.newPointLight(4, 4, 1.0, 0.4, 0.2, 5, 1)
--   local r, g, b = light:color()
--   lurek.log.debug("torch tint " .. r .. "," .. g .. "," .. b, "raycaster")
-- end

--@api-stub: LPointLight:type
-- Returns the type string "LPointLight".
-- Cheap runtime tag used by editors and serializers to recognise raycaster lights.
-- if false then -- PointLight:type
--   local light = lurek.raycaster.newPointLight(0, 0, 1, 1, 1, 1, 1)
--   lurek.log.info("PointLight:type = " .. light:type(), "raycaster")
-- end

--@api-stub: LPointLight:typeOf
-- Returns true if the given name matches "LPointLight", the legacy alias, or a parent type.
-- Same value as `:type()`; provided for parity with love2d-style userdata.
-- if false then -- PointLight:typeOf
--   local light = lurek.raycaster.newPointLight(1, 1, 0.5, 0.5, 1, 2, 1)
--   if light:typeOf("LPointLight") then lurek.log.debug("light kind ok", "raycaster") end
-- end

-- â”€â”€ Raycaster methods â”€â”€
-- do  -- Raycaster:setCell
--   local rc = lurek.raycaster.new(8, 8)
--   for x = 0, 7 do rc:setCell(x, 0, 1); rc:setCell(x, 7, 1) end
--   rc:setCell(3, 3, 2)
-- end

--@api-stub: LRaycaster:getCell
-- Returns the cell value at (x, y).
-- Returns 0 for both empty cells and out-of-bounds; combine with `:isBlocked` if you need the distinction.
-- if false then -- Raycaster:getCell
--   local rc = lurek.raycaster.new(8, 8)
--   rc:setCell(2, 2, 3)
--   if rc:getCell(2, 2) == 3 then lurek.log.debug("cell holds tile id 3", "raycaster") end
-- end

--@api-stub: LRaycaster:setCells
-- Replaces all grid cells from a flat array of values in row-major order.
-- Length must equal width*height; this is the fastest way to load a level from a TOML or JSON map.
-- if false then -- Raycaster:setCells
--   local rc = lurek.raycaster.new(4, 3)
--   rc:setCells({
--     1, 1, 1, 1,
--     1, 0, 0, 1,
--     1, 1, 1, 1,
--   })
-- end

-- The canonical move-collision test: gate any prospective player position through this before applying it.
-- do  -- Raycaster:isBlocked
--   local rc = lurek.raycaster.new(8, 8)
--   rc:setCell(4, 4, 1)
--   if not rc:isBlocked(3, 4) then lurek.log.debug("(3,4) is walkable", "raycaster") end

--@api-stub: LRaycaster:tryMove
-- Attempts world-space movement by (dx, dy) with collision checks.
-- if false then -- Raycaster:tryMove
--   local rc = lurek.raycaster.new(8, 8)
--   rc:setCell(4, 3, 1)
--   local x, y, moved = rc:tryMove(3.5, 3.5, 1.0, 0.0)
--   lurek.log.debug("tryMove -> " .. tostring(x) .. "," .. tostring(y) .. " moved=" .. tostring(moved), "raycaster")
-- end

--@api-stub: LRaycaster:gridMove
-- Attempts 4-direction camera-relative movement (`forward/back/left/right`) for dir=1..4.
-- if false then -- Raycaster:gridMove
--   local rc = lurek.raycaster.new(8, 8)
--   local x, y, moved = rc:gridMove(2.5, 2.5, 1, "forward", 1.0)
--   lurek.log.debug("gridMove -> " .. tostring(x) .. "," .. tostring(y) .. " moved=" .. tostring(moved), "raycaster")
-- end
-- end

--@api-stub: LRaycaster:width
-- if false then -- Raycaster:width
--   local rc = lurek.raycaster.new(20, 15)
--   for x = 0, rc:width() - 1 do rc:setCell(x, 0, 1) end
-- end

--@api-stub: LRaycaster:height
-- Returns the grid height in cells.
-- Pair with `:width()` to iterate every cell when serialising the level for save/load.
-- if false then -- Raycaster:height
--   local rc = lurek.raycaster.new(20, 15)
--   for y = 0, rc:height() - 1 do rc:setCell(0, y, 1) end
-- end

--@api-stub: LRaycaster:setWallAlpha
-- Sets the opacity for a wall tile type.
-- Values < 1.0 mark the tile as translucent so castRayMulti collects layered hits (glass, fences, force-fields).
-- if false then -- Raycaster:setWallAlpha
--   local rc = lurek.raycaster.new(8, 8)
--   rc:setCell(3, 3, 5)
--   rc:setWallAlpha(5, 0.4)
-- end

--@api-stub: LRaycaster:getWallAlpha
-- Returns the opacity for a wall tile type.
-- Defaults to 1.0 when never set; use it to debug-overlay translucent tiles in the level editor.
-- if false then -- Raycaster:getWallAlpha
--   local rc = lurek.raycaster.new(8, 8)
--   rc:setWallAlpha(2, 0.6)
--   local a = rc:getWallAlpha(2)
--   if a < 1.0 then lurek.log.debug("tile 2 alpha=" .. a, "raycaster") end
-- end

-- â”€â”€ SpriteManager methods â”€â”€

--@api-stub: LSpriteManager:remove
-- Removes the sprite with the given id.
-- Ids are returned from `:add(...)`; call this when an enemy dies or a pickup is collected.
-- if false then -- SpriteManager:remove
--   local sprites = lurek.raycaster.newSpriteManager()
--   local id = sprites:add(5.0, 4.0, "potion", 0.5)
--   sprites:remove(id)
-- end

--@api-stub: LSpriteManager:setPosition
-- Moves the sprite with the given id to world (x, y).
-- Cheap per-frame call; use it to drive moving NPCs without re-allocating sprite entries.
-- if false then -- SpriteManager:setPosition
--   local sprites = lurek.raycaster.newSpriteManager()
--   local id = sprites:add(2.0, 2.0, "enemy_imp", 1.0)
--   function lurek.process(dt) sprites:setPosition(id, 2.0 + dt, 2.0) end
-- end

--@api-stub: LSpriteManager:setVisible
-- Shows or hides the sprite with the given id.
-- Prefer this over remove/add for sprites that flicker (invulnerability frames, fog-of-war reveals).
-- if false then -- SpriteManager:setVisible
--   local sprites = lurek.raycaster.newSpriteManager()
--   local id = sprites:add(7.0, 3.0, "key_red", 0.6)
--   sprites:setVisible(id, false)
-- end

--@api-stub: LSpriteManager:clear
-- Removes all sprites from the manager.
-- Call between level transitions to drop every billboard before populating the next room.
-- if false then -- SpriteManager:clear
--   local sprites = lurek.raycaster.newSpriteManager()
--   sprites:add(1, 1, "barrel", 1.0)
--   sprites:add(3, 4, "barrel", 1.0)
--   sprites:clear()
-- end

--@api-stub: LSpriteManager:type
-- Returns the type string "LSpriteManager".
-- Useful in serializers that walk a heterogeneous level table and dispatch on each userdata's type.
-- if false then -- SpriteManager:type
--   local sprites = lurek.raycaster.newSpriteManager()
--   lurek.log.info("SpriteManager:type = " .. tostring(sprites and sprites:type() or "nil"), "raycaster")
-- end

--@api-stub: LSpriteManager:typeOf
-- Returns true if the given name matches "LSpriteManager", the legacy alias, or a parent type.
-- Mirrors love2d's Object:typeOf so library code can branch identically across engines.
-- if false then -- SpriteManager:typeOf
--   local sprites = lurek.raycaster.newSpriteManager()
--   if sprites and sprites:typeOf("LSpriteManager") then lurek.log.debug("sprite mgr ok", "raycaster") end
-- end
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

-- â”€â”€ lurek.raycaster.* functions â”€â”€

--@api-stub: LSpriteManager:add
-- Registers a sprite in the sprite manager at a world-space position.
-- Returns a sprite id; update position each frame with setPosition(id, x, y).
-- if false then -- SpriteManager:add
--   local sm = lurek.raycaster.newSpriteManager()
--   local id = sm:add(3.5, 2.5, "crate", 1.0)
--   lurek.log.info("sprite id: " .. id, "raycaster")
-- end

--@api-stub: LDoorManager:addDoor
-- Registers a door at a specific map cell with open/close state and animation speed.
-- DoorManager.update() advances door animations each frame automatically.
-- if false then -- DoorManager:addDoor
--   local dm = lurek.raycaster.newDoorManager()
--   local rc = lurek.raycaster.new(32, 32)
--   local did = dm:addDoor(5, 7, "horizontal", 1.0)
--   lurek.log.info("door id: " .. did, "raycaster")
-- end

--@api-stub: LRaycaster:buildScene
-- Precomputes a scene description from the current cell map for column-order rendering.
-- Call after setCell() changes; subsequent castRays use the compiled scene.
-- if false then -- Raycaster:buildScene
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   local params = { px = 8, py = 8, angle = 0, fov = math.pi/3, rays = 320,
--                    max_dist = 16, screen_w = 320, screen_h = 240 }
--   rc:buildScene(params, nil, nil, { [1] = tex })
--   lurek.log.info("scene built", "raycaster")
-- end

--@api-stub: LRaycaster:castFloorRow
-- Casts a single floor/ceiling row and returns depth and texture-coordinate tables.
-- Call for each screen row between the horizon and the floor to build the floor plane.
-- if false then -- Raycaster:castFloorRow
--   local rc = lurek.raycaster.new(16, 16)
--   local uvs = rc:castFloorRow(8, 8, 1, 0, 0, 0.66, 240)
--   lurek.log.info("floor row uv count: " .. (uvs and #uvs or 0), "raycaster")
-- end

--@api-stub: LRaycaster:castRay
-- Casts a single ray from origin in direction angle and returns the hit data.
-- Returns distance, wallType, side, and texture coordinates for the hit cell.
-- if false then -- Raycaster:castRay
--   local rc = lurek.raycaster.new(16, 16)
--   local hit = rc:castRay(8, 8, 0, 16)
--   lurek.log.info("ray dist: " .. (hit and hit.dist or -1), "raycaster")
-- end

--@api-stub: LRaycaster:castRayMulti
-- Casts multiple rays from different positions and returns a results table.
-- Useful for multi-camera setups or custom rendering passes.
-- if false then -- Raycaster:castRayMulti
--   local rc = lurek.raycaster.new(16, 16)
--   local results = rc:castRayMulti(8, 8, 0, 16)
--   lurek.log.info("multi-ray results: " .. #results, "raycaster")
-- end

--@api-stub: LRaycaster:castRays
-- Casts a full fan of rays for the current camera view and returns the column buffer.
-- Returns a table of per-column hit data; used by drawView() internally.
-- if false then -- Raycaster:castRays
--   local rc = lurek.raycaster.new(16, 16)
--   local cols = rc:castRays(8, 8, 0, math.pi/3, 320, 16)
--   lurek.log.info("columns: " .. (cols and #cols or 0), "raycaster")
-- end

--@api-stub: LRaycaster:castRaysFlat
-- Casts rays and returns results in a flat array format for GPU upload.
-- More cache-friendly than castRays for large column counts.
-- if false then -- Raycaster:castRaysFlat
--   local rc = lurek.raycaster.new(16, 16)
--   local flat = rc:castRaysFlat(8, 8, 0, math.pi/3, 320, 16)
--   lurek.log.info("flat ray count: " .. (flat and #flat or 0), "raycaster")
-- end

--@api-stub: LRaycaster:drawCameraSweep
-- Renders a top-down camera FOV arc onto an ImageData for a minimap overlay.
-- fov and range control the visible arc; useful for guard-vision debugging.
-- if false then -- Raycaster:drawCameraSweep
--   local rc = lurek.raycaster.new(16, 16)
--   local img = rc:drawCameraSweep(8, 8, math.pi/3, 16, 6, 64, 48)
--   lurek.log.info("camera sweep drawn", "raycaster")
-- end

--@api-stub: LRaycaster:drawDepthMap
-- Renders the per-column depth buffer as a greyscale gradient into an ImageData.
-- Useful for debugging occlusion and rendering artefacts.
-- if false then -- Raycaster:drawDepthMap
--   local rc = lurek.raycaster.new(16, 16)
--   local img = rc:drawDepthMap(8, 8, 0, math.pi/3, 320, 320, 240, 16)
--   lurek.log.info("depth map drawn", "raycaster")
-- end

--@api-stub: LRaycaster:drawLineOfSight
-- Draws a filled line-of-sight polygon onto a top-down ImageData.
-- Shows visible area from a guard's perspective for minimap or debugging.
-- if false then -- Raycaster:drawLineOfSight
--   local rc = lurek.raycaster.new(16, 16)
--   local img = rc:drawLineOfSight(4, 4, 12, 12, 8)
--   lurek.log.info("LOS drawn", "raycaster")
-- end

--@api-stub: LRaycaster:drawTopDown
-- Renders the map grid and optionally objects as a 2D top-down view.
-- Use for minimaps, editor overlays, or debugging spatial relationships.
-- if false then -- Raycaster:drawTopDown
--   local rc = lurek.raycaster.new(16, 16)
--   local img = rc:drawTopDown(8, 8, 0, 8)
--   lurek.log.info("top-down drawn", "raycaster")
-- end

--@api-stub: LRaycaster:drawView
-- Renders the full pseudo-3D first-person view from the camera position and angle.
-- Writes column-by-column into an ImageData; call once per frame in lurek.render().
-- if false then -- Raycaster:drawView
--   local rc = lurek.raycaster.new(16, 16)
--   local img = rc:drawView(8, 8, 0, math.pi/3, 320, 240, 16)
--   lurek.log.info("view rendered", "raycaster")
-- end

--@api-stub: LRaycaster:lineOfSight
-- Returns true if there is unobstructed sight between two map-space positions.
-- Uses DDA; blocked cells with non-zero wall values break the line.
-- if false then -- Raycaster:lineOfSight
--   local rc = lurek.raycaster.new(16, 16)
--   local los = rc:lineOfSight(4, 4, 12, 12)
--   lurek.log.info("LOS result: " .. tostring(los), "raycaster")
-- end

--@api-stub: LRaycaster:revealCellsFromRays
-- Traces rays and returns unique crossed cells for fog-of-war reveal.
-- Replaces Lua-side per-ray stepping loops with one engine-level call.
-- if false then -- Raycaster:revealCellsFromRays
--   local rc = lurek.raycaster.new(32, 32)
--   local cells = rc:revealCellsFromRays(10.5, 10.5, 0.0, math.pi/3, 32, 12.0, 0.2)
--   lurek.log.info("revealed cells: " .. #cells, "raycaster")
-- end

--@api-stub: LRaycaster:computeTileLight
-- Computes LOS-aware tile lighting from ambient plus point lights.
-- Returns r,g,b,luma in [0,1] for minimaps and tactical overlays.
-- if false then -- Raycaster:computeTileLight
--   local rc = lurek.raycaster.new(16, 16)
--   local r, g, b, luma = rc:computeTileLight(8, 8, 0.2, {
--     { x = 8.5, y = 8.5, radius = 5.0, r = 1.0, g = 0.8, b = 0.6, intensity = 8.0 }
--   })
--   lurek.log.info("tile luma: " .. luma, "raycaster")
-- end

--@api-stub: LRaycaster:buildMinimapWindow
-- Builds sampled minimap tiles around a world-space center.
-- Each row returns x,y,blocked,visible,r,g,b,luma for one map cell.
-- if false then -- Raycaster:buildMinimapWindow
--   local rc = lurek.raycaster.new(32, 32)
--   local rows = rc:buildMinimapWindow(12.5, 14.5, 10, 0.25, nil)
--   lurek.log.info("minimap rows: " .. #rows, "raycaster")
-- end

--@api-stub: LRaycaster:projectSprite
-- Projects a world-space sprite into screen-space column/height data.
-- Returns screen_x, screen_y, height, and a visibility mask for the sprite.
-- if false then -- Raycaster:projectSprite
--   local rc = lurek.raycaster.new(16, 16)
--   local sp = rc:projectSprite(8, 4, 4, 0, math.pi/3, 320, 240)
--   lurek.log.info("projected: " .. (sp and sp.screen_x or -1), "raycaster")
-- end

--@api-stub: LRaycaster:setCell
-- Sets the wall type of a single cell in the map grid.
-- type=0 means empty (walkable); non-zero values index the texture atlas.
-- if false then -- Raycaster:setCell
--   local rc = lurek.raycaster.new(16, 16)
--   rc:setCell(4, 4, 2)
--   lurek.log.info("cell 4,4 = 2", "raycaster")
-- end

--@api-stub: LRaycaster:setFloorTextureCell
-- Sets a per-cell floor texture override used by buildScene.
-- Pass nil as texture to clear override and use floor color fallback.
-- if false then -- Raycaster:setFloorTextureCell
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   rc:setFloorTextureCell(4, 4, tex)
--   rc:setFloorTextureCell(4, 4, nil)
-- end

--@api-stub: LRaycaster:getFloorTextureCell
-- Returns floor texture id for a cell, or nil when no override exists.
-- Useful to verify runtime map edits before buildScene.
-- if false then -- Raycaster:getFloorTextureCell
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   rc:setFloorTextureCell(2, 2, tex)
--   local id = rc:getFloorTextureCell(2, 2)
--   lurek.log.info("floor tex id: " .. tostring(id), "raycaster")
-- end

--@api-stub: LRaycaster:setCeilingTextureCell
-- Sets a per-cell ceiling texture override used by buildScene.
-- Pass nil as texture to clear override and use ceiling color fallback.
-- if false then -- Raycaster:setCeilingTextureCell
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   rc:setCeilingTextureCell(4, 4, tex)
--   rc:setCeilingTextureCell(4, 4, nil)
-- end

--@api-stub: LRaycaster:getCeilingTextureCell
-- Returns ceiling texture id for a cell, or nil when no override exists.
-- Useful to verify runtime map edits before buildScene.
-- if false then -- Raycaster:getCeilingTextureCell
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   rc:setCeilingTextureCell(2, 2, tex)
--   local id = rc:getCeilingTextureCell(2, 2)
--   lurek.log.info("ceiling tex id: " .. tostring(id), "raycaster")
-- end

--@api-stub: LRaycaster:setLoweredFloorCell
-- Sets or clears lowered floor cell metadata (water/lava/trench style).
-- Use depth=0.25 for a top surface rendered 25% below normal floor.
-- if false then -- Raycaster:setLoweredFloorCell
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   rc:setLoweredFloorCell(6, 6, {
--     texture = tex,
--     depth = 0.25,
--     r = 0.8,
--     g = 0.9,
--     b = 1.0,
--     blocked = true,
--   })
--   rc:setLoweredFloorCell(6, 6, nil)
-- end

--@api-stub: LRaycaster:getLoweredFloorCell
-- Returns lowered-floor metadata table, or nil when unset.
-- The table contains texture id, depth, tint, and blocked flag.
-- if false then -- Raycaster:getLoweredFloorCell
--   local rc = lurek.raycaster.new(16, 16)
--   local tex = lurek.render.newImage("assets/icon.png")
--   rc:setLoweredFloorCell(3, 3, { texture = tex, depth = 0.25, blocked = true })
--   local cell = rc:getLoweredFloorCell(3, 3)
--   lurek.log.info("lowered floor blocked: " .. tostring(cell and cell.blocked), "raycaster")
-- end

--@api-stub: LRaycaster:isWalkBlocked
-- Returns true for wall cells and blocked lowered-floor cells.
-- Use this for movement checks instead of getCell() when hazards exist.
-- if false then -- Raycaster:isWalkBlocked
--   local rc = lurek.raycaster.new(16, 16)
--   rc:setCell(1, 1, 2)
--   lurek.log.info("wall blocked: " .. tostring(rc:isWalkBlocked(1, 1)), "raycaster")
-- end

--@api-stub: LSpriteManager:sortAndProject
-- Sorts sprites by distance from the camera and projects them into screen-space.
-- Call after castRays() each frame; returns sorted projection data table.
-- if false then -- SpriteManager:sortAndProject
--   local sm = lurek.raycaster.newSpriteManager()
--   sm:add(3.5, 2.5, "crate", 1.0)
--   local projs = sm:sortAndProject(8, 8, 0)
--   lurek.log.info("projected sprites: " .. #projs, "raycaster")
-- end

--@api-stub: LPointLight:set
-- Configures a PointLight's position, colour, and radius in one call.
-- Use instead of separate property setters when updating all fields each frame.
-- if false then -- PointLight:set
--   local light = lurek.raycaster.newPointLight(4.5, 3.5, 1.0, 0.9, 0.7, 6.0, 1.0)
--   light:set(4.5, 3.5, 1.0, 0.9, 0.7, 6.0, 1.0)
--   lurek.log.info("point light configured", "raycaster")
-- end

-- =============================================================================
-- STUBS: 53 uncovered lurek.raycaster API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LRaycaster methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LRaycaster:type -----------------------------------------------
--@api-stub: LRaycaster:type
-- Returns the type name of this object.
-- lRaycaster_stub:type()  -- -> string
-- Useful for runtime type inspection and debug logging.
-- do  -- LRaycaster:type
--   local rc = lurek.raycaster.new(8, 8)
--   local t = rc:type()
--   lurek.log.info("LRaycaster:type = " .. t, "raycaster")
-- end
--@api-stub: LRaycaster:typeOf
-- Returns true if this object is of the given type.
-- lRaycaster_stub:typeOf("hero")  -- -> boolean
-- Use for runtime polymorphism and defensive checks.
-- do  -- LRaycaster:typeOf
--   local rc = lurek.raycaster.new(8, 8)
--   lurek.log.info("is LRaycaster: " .. tostring(rc:typeOf("LRaycaster")), "raycaster")
--   lurek.log.info("is unknown: " .. tostring(rc:typeOf("Unknown")), "raycaster")
-- end

-- =============================================================================
-- STUBS: 2 uncovered lurek.raycaster API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LRaycaster methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LRaycaster:isBlocked ------------------------------------------
--@api-stub: LRaycaster:isBlocked
-- Returns true when the cell at (x, y) is a wall (value > 0).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:isBlocked(0.0, 0.0)  -- -> boolean
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:buildSceneWithModels -------------------------------
--@api-stub: LRaycaster:buildSceneWithModels
-- Builds a raycaster scene and appends projected OBJ model meshes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:buildSceneWithModels()  -- -> integer
-- (replace lRaycaster_stub with your real LRaycaster instance above)
