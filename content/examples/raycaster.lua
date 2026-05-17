-- content/examples/raycaster.lua
-- lurek.raycaster API examples.
-- Run: cargo run -- content/examples/raycaster.lua

-- =============================================================================
-- Module-level constructors
-- =============================================================================

--@api-stub: lurek.raycaster.new
-- Creates a new raycaster map with the given grid dimensions
do
  -- Create a 16x12 grid map. Each cell holds an integer:
  -- 0 = empty (walkable), 1+ = wall type (blocks rays and movement).
  local rc = lurek.raycaster.new(16, 12)

  -- Place a single wall tile at column 3, row 4 with wall type 1
  rc:setCell(3, 4, 1)

  -- The map dimensions are fixed at creation time
  lurek.log.info("grid " .. rc:width() .. "x" .. rc:height(), "raycaster")
end

--@api-stub: lurek.raycaster.newMap
-- Creates a new raycaster map (alias for `new`)
do
  -- newMap is identical to new() — use whichever reads better in your code.
  -- Here we build a 32x32 dungeon with solid border walls.
  local map = lurek.raycaster.newMap(32, 32)

  -- Build perimeter walls: top and bottom rows
  for x = 0, 31 do map:setCell(x, 0, 1); map:setCell(x, 31, 1) end
  -- Left and right columns
  for y = 0, 31 do map:setCell(0, y, 1); map:setCell(31, y, 1) end
end

--@api-stub: lurek.raycaster.projectColumn
-- Computes the projected wall-column height for a given distance, FOV, and screen height
do
  -- Use projectColumn to manually render wall strips in a custom renderer.
  -- Given: distance from camera to wall, field of view, and screen height,
  -- it returns: projected height, top pixel, bottom pixel.
  local fov = math.pi / 3  -- 60 degree FOV
  local wall_dist = 4.5    -- wall is 4.5 units away

  local h, top, bot = lurek.raycaster.projectColumn(wall_dist, fov, 720)

  -- h = how tall the wall column appears on screen
  -- top = y pixel where the column starts (from top)
  -- bot = y pixel where the column ends
  -- Closer walls produce larger h values
  lurek.log.debug("col h=" .. h .. " top=" .. top .. " bot=" .. bot, "raycaster")
end

--@api-stub: lurek.raycaster.distanceShade
-- Returns a brightness multiplier (0.0..1.0) based on distance for fog/darkness falloff
do
  -- Use distanceShade to simulate distance fog in a dungeon.
  -- Objects further away become darker, reaching 0.0 at maxDistance.
  local max_visible = 12.0  -- beyond 12 units everything is black
  local wall_dist = 6.0     -- this wall is 6 units away

  local shade = lurek.raycaster.distanceShade(wall_dist, max_visible)

  -- Multiply your wall color by shade to darken distant surfaces
  local base_r, base_g, base_b = 0.8, 0.6, 0.4
  local r = base_r * shade
  local g = base_g * shade
  local b = base_b * shade
  lurek.log.debug("wall rgb=" .. r .. "," .. g .. "," .. b, "raycaster")
end

--@api-stub: lurek.raycaster.newDoorManager
-- Creates a new door manager for tracking and animating sliding doors
do
  -- DoorManager tracks sliding doors that open and close over time.
  -- Each door lives at a grid cell and slides in one direction.
  local doors = lurek.raycaster.newDoorManager()

  -- Add a horizontal-sliding door at cell (5,7) that opens at 2.5 units/sec
  doors:addDoor(5, 7, "horizontal", 2.5)
  -- Add a vertical-sliding door at cell (9,3) — slower at 1.8 units/sec
  doors:addDoor(9, 3, "vertical", 1.8)
end

--@api-stub: lurek.raycaster.newHeightMap
-- Creates a new height map for variable floor/ceiling heights across the grid
do
  -- HeightMap adds variable floor/ceiling elevations to a flat raycaster map.
  -- Use it for pits, raised platforms, and low ceilings.
  local hm = lurek.raycaster.newHeightMap(16, 12)

  -- Lower the floor at (4,5) to create a shallow pit
  -- Negative values = floor sinks below default level
  hm:setFloor(4, 5, -0.25)

  -- Raise the ceiling at (4,5) to give extra headroom above the pit
  hm:setCeiling(4, 5, 1.5)
end

--@api-stub: lurek.raycaster.newPointLight
-- Creates a new point light with position, color, radius, and intensity
do
  -- Point lights illuminate nearby tiles with colored falloff.
  -- Args: x, y, red, green, blue, radius, intensity
  -- This creates a warm torch light at world position (8.5, 6.0)
  local torch = lurek.raycaster.newPointLight(
    8.5, 6.0,     -- world position
    1.0, 0.7, 0.3, -- warm orange color
    4.0,           -- illuminates tiles within 4 units
    1.5            -- 150% brightness multiplier
  )

  -- Query properties for debug display
  lurek.log.info("torch radius=" .. torch:radius(), "raycaster")
end

--@api-stub: lurek.raycaster.newSpriteManager
-- Creates a new sprite manager for tracking and projecting billboard sprites
do
  -- SpriteManager tracks world-space billboard sprites (enemies, items, props).
  -- Sprites always face the camera and can be sorted by distance for correct draw order.
  local sprites = lurek.raycaster.newSpriteManager()

  -- Add sprites with: x, y, texture_name, scale
  -- These exist in world space and are projected to screen during rendering
  sprites:add(6.5, 4.5, "enemy_zombie", 1.0)   -- full-size enemy
  sprites:add(10.0, 8.0, "barrel", 0.75)        -- smaller prop barrel
end

-- =============================================================================
-- DoorManager methods
-- =============================================================================

--@api-stub: DoorManager:addDoor
-- Adds a door to this door manager
do
  local dm = lurek.raycaster.newDoorManager()

  -- addDoor returns the zero-based index of the new door.
  -- Use this index for openDoor/closeDoor/getDoor calls.
  local did = dm:addDoor(5, 7, "horizontal", 1.0)
  lurek.log.info("door id: " .. did, "raycaster")
end

--@api-stub: DoorManager:openDoor
-- Begins opening the door at the given index
do
  local doors = lurek.raycaster.newDoorManager()
  local idx = doors:addDoor(5, 7, "horizontal", 2.0)

  -- openDoor starts the animation — call update(dt) each frame to advance it.
  -- The door slides from closed (0.0) to fully open (1.0) at the configured speed.
  doors:openDoor(idx)
end

--@api-stub: DoorManager:closeDoor
-- Begins closing the door at the given index
do
  local doors = lurek.raycaster.newDoorManager()
  local idx = doors:addDoor(12, 4, "vertical", 1.5)

  -- Doors can be triggered to close after a timer or when the player moves away
  doors:openDoor(idx)
  doors:closeDoor(idx)  -- immediately reverses direction
end

--@api-stub: DoorManager:update
-- Advances all door animations by the given delta time
do
  local doors = lurek.raycaster.newDoorManager()
  doors:addDoor(3, 3, "horizontal", 2.0)

  -- Call update once per frame in lurek.process to animate all doors.
  -- dt is seconds since last frame — doors slide at their configured speed.
  function lurek.process(dt)
    doors:update(dt)
  end
end

--@api-stub: DoorManager:getDoor
-- Returns a table describing the door at the given index
do
  local doors = lurek.raycaster.newDoorManager()
  local idx = doors:addDoor(5, 7, "horizontal", 2.0)

  -- getDoor returns: { x, y, openAmount (0.0..1.0), state ("closed"|"opening"|"open"|"closing") }
  -- Use openAmount to check if the player can pass through
  local d = doors:getDoor(idx)
  if d and d.openAmount > 0.9 then
    lurek.log.info("door " .. d.x .. "," .. d.y .. " passable (state=" .. d.state .. ")", "doors")
  end
end

--@api-stub: DoorManager:count
-- Returns the total number of registered doors
do
  local doors = lurek.raycaster.newDoorManager()
  doors:addDoor(2, 2, "horizontal", 2.0)
  doors:addDoor(8, 5, "vertical", 2.0)

  -- Useful for iterating all doors (indices 0 to count-1)
  lurek.log.info("level has " .. doors:count() .. " doors", "doors")
end

--@api-stub: DoorManager:type
-- Returns the Lua-visible type name string for this door manager handle
do
  local doors = lurek.raycaster.newDoorManager()
  -- Returns "LDoorManager" — useful for runtime type checks in generic code
  if doors:type() == "LDoorManager" then
    lurek.log.debug("door manager OK", "raycaster")
  end
end

--@api-stub: DoorManager:typeOf
-- Returns true if this door manager handle matches the given type name string
do
  local doors = lurek.raycaster.newDoorManager()
  -- typeOf accepts "LDoorManager", "DoorManager", or "Object"
  if doors:typeOf("DoorManager") then
    lurek.log.debug("dispatched as DoorManager", "raycaster")
  end
end

-- =============================================================================
-- HeightMap methods
-- =============================================================================

--@api-stub: HeightMap:setFloor
-- Sets the floor height offset at a specific grid cell
do
  local hm = lurek.raycaster.newHeightMap(16, 12)

  -- Create a trench: lower the floor across several cells.
  -- Negative offset = floor drops below default level (a pit).
  for x = 4, 7 do hm:setFloor(x, 6, -0.5) end
  -- Gradual ramp: half-depth at the edge
  hm:setFloor(8, 6, -0.25)
end

--@api-stub: HeightMap:setCeiling
-- Sets the ceiling height offset at a specific grid cell
do
  local hm = lurek.raycaster.newHeightMap(16, 12)

  -- Create a low-ceiling corridor along row 0.
  -- Lower values = ceiling comes down, making the space feel cramped.
  for x = 0, 15 do hm:setCeiling(x, 0, 0.6) end
end

--@api-stub: HeightMap:floorAt
-- Returns the floor height offset at a given grid cell
do
  local hm = lurek.raycaster.newHeightMap(16, 12)
  hm:setFloor(5, 5, -0.4)

  -- Query the floor to detect pits for gameplay (damage zones, water, etc.)
  local h = hm:floorAt(5, 5)
  if h < 0 then
    lurek.log.debug("pit depth " .. -h, "raycaster")
  end
end

--@api-stub: HeightMap:ceilingAt
-- Returns the ceiling height offset at a given grid cell
do
  local hm = lurek.raycaster.newHeightMap(16, 12)

  -- Compute available headroom at a cell to check if tall entities can pass
  local headroom = hm:ceilingAt(3, 4) - hm:floorAt(3, 4)
  lurek.log.debug("cell headroom=" .. headroom, "raycaster")
end

--@api-stub: HeightMap:type
-- Returns the Lua-visible type name string for this height map handle
do
  local hm = lurek.raycaster.newHeightMap(8, 8)
  -- Always returns "LHeightMap"
  lurek.log.debug("heightmap type: " .. hm:type(), "raycaster")
end

--@api-stub: HeightMap:typeOf
-- Returns true if this height map handle matches the given type name string
do
  local hm = lurek.raycaster.newHeightMap(8, 8)
  -- Accepts "LHeightMap", "HeightMap", or "Object"
  if hm:typeOf("HeightMap") then lurek.log.debug("is HeightMap", "raycaster") end
end

-- =============================================================================
-- PointLight methods
-- =============================================================================

--@api-stub: PointLight:x
-- Returns the X world position of this point light
do
  local light = lurek.raycaster.newPointLight(10.0, 5.0, 1, 1, 1, 5, 1)

  -- Use x() and y() to track a light's position for distance checks
  local px = light:x()
  if px > 8 then
    lurek.log.debug("light is east of midpoint at x=" .. px, "raycaster")
  end
end

--@api-stub: PointLight:y
-- Returns the Y world position of this point light
do
  local light = lurek.raycaster.newPointLight(4.0, 7.5, 1, 0.8, 0.6, 4, 1.2)

  -- Determine which grid row the light falls in
  local py = light:y()
  lurek.log.debug("light row " .. math.floor(py), "raycaster")
end

--@api-stub: PointLight:radius
-- Returns the light's falloff radius in world units
do
  local light = lurek.raycaster.newPointLight(8, 6, 1, 1, 1, 6.0, 1.0)

  -- Radius determines how far the light reaches before fading to zero.
  -- Larger radius = softer, wider illumination area.
  local r = light:radius()
  if r > 5 then lurek.log.info("large light radius=" .. r, "raycaster") end
end

--@api-stub: PointLight:intensity
-- Returns the brightness multiplier of this point light
do
  local light = lurek.raycaster.newPointLight(2, 3, 1, 0.5, 0.2, 3, 2.5)

  -- Combine intensity with distanceShade for manual per-pixel lighting
  local dist_to_wall = 1.5
  local shade = lurek.raycaster.distanceShade(dist_to_wall, 6.0)
  local contribution = light:intensity() * shade
  lurek.log.debug("light contribution at wall=" .. contribution, "raycaster")
end

--@api-stub: PointLight:color
-- Returns the RGB color components of this point light
do
  local light = lurek.raycaster.newPointLight(4, 4, 1.0, 0.4, 0.2, 5, 1)

  -- color() returns r, g, b channels (0.0..1.0)
  -- Use this to tint nearby surfaces for colored lighting
  local r, g, b = light:color()
  lurek.log.debug("torch tint " .. r .. "," .. g .. "," .. b, "raycaster")
end

--@api-stub: PointLight:set
-- Overwrites all properties of this point light in a single call
do
  local light = lurek.raycaster.newPointLight(4.5, 3.5, 1.0, 0.9, 0.7, 6.0, 1.0)

  -- set() updates position, color, radius, and intensity all at once.
  -- Useful for animating a light (flickering torch, moving lantern).
  light:set(
    4.5, 3.5,       -- position stays the same
    1.0, 0.9, 0.7,  -- warm color
    6.0,             -- radius
    1.0              -- intensity
  )
  lurek.log.info("point light configured", "raycaster")
end

--@api-stub: PointLight:type
-- Returns the Lua-visible type name string for this point light handle
do
  local light = lurek.raycaster.newPointLight(0, 0, 1, 1, 1, 1, 1)
  -- Always returns "LPointLight"
  lurek.log.info("PointLight:type = " .. light:type(), "raycaster")
end

--@api-stub: PointLight:typeOf
-- Returns true if this point light handle matches the given type name string
do
  local light = lurek.raycaster.newPointLight(1, 1, 0.5, 0.5, 1, 2, 1)
  -- Accepts "LPointLight", "PointLight", or "Object"
  if light:typeOf("LPointLight") then lurek.log.debug("light kind ok", "raycaster") end
end

-- =============================================================================
-- Raycaster map methods
-- =============================================================================

--@api-stub: Raycaster:setCell
-- Sets the wall type value at a grid cell
do
  local rc = lurek.raycaster.new(16, 16)

  -- Cell values: 0 = empty/walkable, 1+ = solid wall with that texture index.
  -- Different non-zero values can map to different wall textures in buildScene.
  rc:setCell(4, 4, 2)  -- wall type 2 at column 4, row 4
  lurek.log.info("cell 4,4 = 2", "raycaster")
end

--@api-stub: Raycaster:getCell
-- Returns the wall type value at a grid cell
do
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(2, 2, 3)

  -- Returns the integer wall type at that position
  if rc:getCell(2, 2) == 3 then
    lurek.log.debug("cell holds tile id 3", "raycaster")
  end
end

--@api-stub: Raycaster:setCells
-- Replaces the entire map grid with a flat array of cell values
do
  local rc = lurek.raycaster.new(4, 3)

  -- setCells takes a row-major flat array: width*height elements.
  -- This is the fastest way to load a level from data.
  -- Row 0 (top): all walls. Row 1: corridor. Row 2: all walls.
  rc:setCells({
    1, 1, 1, 1,
    1, 0, 0, 1,
    1, 1, 1, 1,
  })
end

--@api-stub: Raycaster:width
-- Returns the map width in grid cells
do
  local rc = lurek.raycaster.new(20, 15)

  -- Use width() for boundary loops when building perimeter walls
  for x = 0, rc:width() - 1 do rc:setCell(x, 0, 1) end
end

--@api-stub: Raycaster:height
-- Returns the map height in grid cells
do
  local rc = lurek.raycaster.new(20, 15)

  -- Use height() for boundary loops
  for y = 0, rc:height() - 1 do rc:setCell(0, y, 1) end
end

--@api-stub: Raycaster:isBlocked
-- Returns true if the grid cell is a solid wall (non-zero value)
do
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(4, 4, 1)

  -- isBlocked checks only the wall grid (ignores lowered floor blocking).
  -- Use isWalkBlocked for full collision checks including pits.
  local blocked = rc:isBlocked(4, 4)
  lurek.log.debug("(4,4) blocked=" .. tostring(blocked), "raycaster")
end

--@api-stub: Raycaster:isWalkBlocked
-- Returns true if this cell blocks walking (solid wall OR blocked lowered-floor cell)
do
  local rc = lurek.raycaster.new(16, 16)
  rc:setCell(1, 1, 2)

  -- isWalkBlocked returns true for walls AND for lowered-floor cells marked blocked=true.
  -- This is what tryMove and gridMove use internally for collision.
  lurek.log.info("walk blocked: " .. tostring(rc:isWalkBlocked(1, 1)), "raycaster")
end

--@api-stub: Raycaster:setWallAlpha
-- Sets the transparency for a specific wall tile type
do
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(3, 3, 5)

  -- Make tile type 5 semi-transparent (glass walls, force fields).
  -- Alpha 0.0 = fully transparent, 1.0 = fully opaque (default).
  -- castRayMulti will pass through transparent walls and report multiple hits.
  rc:setWallAlpha(5, 0.4)
end

--@api-stub: Raycaster:getWallAlpha
-- Returns the current transparency value for a wall tile type
do
  local rc = lurek.raycaster.new(8, 8)
  rc:setWallAlpha(2, 0.6)

  -- Query the current alpha to check if a wall type is see-through
  local a = rc:getWallAlpha(2)
  if a < 1.0 then lurek.log.debug("tile 2 alpha=" .. a, "raycaster") end
end

--@api-stub: Raycaster:tryMove
-- Attempts to move with wall-slide collision
do
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(4, 3, 1)

  -- tryMove handles collision with wall-sliding.
  -- Pass current position + desired movement delta.
  -- Returns: final_x, final_y, did_move_at_all
  -- If the direct path is blocked, it tries sliding along each axis separately.
  local x, y, moved = rc:tryMove(3.5, 3.5, 1.0, 0.0)
  lurek.log.debug("tryMove -> " .. x .. "," .. y .. " moved=" .. tostring(moved), "raycaster")
end

--@api-stub: Raycaster:gridMove
-- Performs a discrete grid-step movement in one of 4 cardinal directions
do
  local rc = lurek.raycaster.new(8, 8)

  -- gridMove is for tile-by-tile dungeon crawlers (like Dungeon Master, Eye of the Beholder).
  -- dir: 1=North, 2=East, 3=South, 4=West
  -- action: "forward", "back", "left", "right" (relative to facing direction)
  -- step: typically 1.0 for one full tile
  local x, y, moved = rc:gridMove(2.5, 2.5, 1, "forward", 1.0)
  lurek.log.debug("gridMove -> " .. x .. "," .. y .. " moved=" .. tostring(moved), "raycaster")
end

--@api-stub: Raycaster:castRay
-- Casts a single ray from a point at a given angle
do
  local rc = lurek.raycaster.new(16, 16)
  -- Build some walls to hit
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end

  -- Cast a ray from the center looking north (angle 0 = along -Y axis)
  -- Returns a hit table or nil if nothing within maxDist
  local hit = rc:castRay(8, 8, 0, 16)
  if hit then
    -- hit.distance = perpendicular (fisheye-corrected) distance
    -- hit.raw_distance = true euclidean distance
    -- hit.cell_value = which wall type was hit
    -- hit.side = 0 (vertical grid line) or 1 (horizontal grid line)
    -- hit.tex_u = texture U coordinate (0.0..1.0) for the hit column
    -- hit.hit_x, hit.hit_y = exact world position of the hit
    lurek.log.info("ray dist: " .. hit.distance .. " cell=" .. hit.cell_value, "raycaster")
  end
end

--@api-stub: Raycaster:castRayMulti
-- Casts a single ray that passes through transparent walls, returning multiple hits
do
  local rc = lurek.raycaster.new(16, 16)
  -- Set up a glass wall (semi-transparent) and a solid wall behind it
  rc:setCell(8, 4, 2)   -- glass wall
  rc:setWallAlpha(2, 0.3)
  rc:setCell(8, 2, 1)   -- solid wall behind

  -- castRayMulti returns ALL hits in distance order, up to maxHits (default 4, max 8).
  -- Essential for rendering layered transparent walls.
  local results = rc:castRayMulti(8.5, 8.5, math.pi * 1.5, 16)
  lurek.log.info("multi-ray hits: " .. #results, "raycaster")
end

--@api-stub: Raycaster:castRays
-- Casts multiple rays across a field of view
do
  local rc = lurek.raycaster.new(16, 16)
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end
  for y = 0, 15 do rc:setCell(0, y, 1); rc:setCell(15, y, 1) end

  -- castRays sweeps rays across your FOV, returning full hit info per column.
  -- Use this for custom rendering where you need tex_u, side, etc.
  local cols = rc:castRays(8, 8, 0, math.pi/3, 320, 16)
  lurek.log.info("columns: " .. (cols and #cols or 0), "raycaster")
end

--@api-stub: Raycaster:castRaysFlat
-- Casts multiple rays and returns only corrected distances as a flat array
do
  local rc = lurek.raycaster.new(16, 16)
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end

  -- castRaysFlat is faster than castRays when you only need distances
  -- (e.g. for depth-based effects, occlusion, or simple column height calculation).
  local dists = rc:castRaysFlat(8, 8, 0, math.pi/3, 320, 16)
  lurek.log.info("flat ray count: " .. (dists and #dists or 0), "raycaster")
end

--@api-stub: Raycaster:lineOfSight
-- Tests line of sight between two world points
do
  local rc = lurek.raycaster.new(16, 16)

  -- lineOfSight returns true if no wall blocks the straight path between two points.
  -- Use for AI visibility checks: can an enemy see the player?
  local can_see = rc:lineOfSight(4, 4, 12, 12)
  lurek.log.info("LOS clear: " .. tostring(can_see), "raycaster")
end

--@api-stub: Raycaster:revealCellsFromRays
-- Reveals grid cells visible from a point for fog-of-war
do
  local rc = lurek.raycaster.new(32, 32)
  -- Build some walls to block visibility
  rc:setCell(12, 10, 1)
  rc:setCell(13, 10, 1)

  -- Casts rays across the FOV and walks along each ray, collecting visible cells.
  -- Returns array of {x, y} tables — mark these on your fog-of-war map.
  -- step (last param) controls sampling density: smaller = more accurate, slower.
  local cells = rc:revealCellsFromRays(
    10.5, 10.5,   -- origin
    0.0,           -- center angle (north)
    math.pi / 3,  -- 60 degree FOV
    32,            -- number of rays
    12.0,          -- max reveal distance
    0.2            -- walk step along each ray
  )
  lurek.log.info("revealed cells: " .. #cells, "raycaster")
end

--@api-stub: Raycaster:computeTileLight
-- Computes combined lighting color at a tile from ambient and point lights
do
  local rc = lurek.raycaster.new(16, 16)

  -- computeTileLight accounts for walls blocking light paths.
  -- Returns r, g, b, luma — use luma for quick brightness checks.
  local r, g, b, luma = rc:computeTileLight(8, 8, 0.2, {
    { x = 8.5, y = 8.5, radius = 5.0, r = 1.0, g = 0.8, b = 0.6, intensity = 8.0 }
  })
  lurek.log.info("tile luma: " .. luma, "raycaster")
end

--@api-stub: Raycaster:buildMinimapWindow
-- Generates minimap tile samples around a center point with lighting
do
  local rc = lurek.raycaster.new(32, 32)
  -- Build some walls
  rc:setCell(12, 14, 1)
  rc:setCell(13, 15, 1)

  -- buildMinimapWindow samples a square region around the center.
  -- Each result has: x, y, blocked, visible, r, g, b, luma.
  -- Use this to render a lit minimap overlay in-game.
  local rows = rc:buildMinimapWindow(
    12.5, 14.5,  -- center position (player location)
    10,          -- sample radius (10 tiles in each direction)
    0.25,        -- ambient light level
    nil          -- no point lights (or pass an array)
  )
  lurek.log.info("minimap rows: " .. #rows, "raycaster")
end

--@api-stub: Raycaster:projectSprite
-- Projects a world-space sprite to screen coordinates for billboard rendering
do
  local rc = lurek.raycaster.new(16, 16)

  -- projectSprite converts a world position to screen-space coordinates.
  -- Use it to draw enemy/item billboards at the correct screen position and scale.
  local sp = rc:projectSprite(
    8, 4,         -- sprite world position
    4, 4,         -- player world position
    0,            -- player facing angle
    math.pi/3,   -- FOV
    320           -- screen width
  )
  if sp and sp.visible then
    -- sp.screen_x = horizontal pixel position on screen
    -- sp.scale = size multiplier (closer = larger)
    -- sp.distance = distance from camera to sprite
    lurek.log.info("sprite at screen_x=" .. sp.screen_x .. " scale=" .. sp.scale, "raycaster")
  end
end

--@api-stub: Raycaster:castFloorRow
-- Computes floor/ceiling texture UV coordinates for a single scanline row
do
  local rc = lurek.raycaster.new(16, 16)

  -- castFloorRow is for software-rendered textured floors.
  -- It computes UV coordinates for one horizontal scanline below/above the walls.
  -- Camera direction and plane define the perspective projection.
  local cam_x, cam_y = 8.0, 8.0
  local dir_x, dir_y = 1.0, 0.0     -- looking east
  local plane_x, plane_y = 0.0, 0.66 -- FOV plane perpendicular to direction

  local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 240)
  -- Each entry is {u, v} — the world-space texture coordinate for that pixel
  lurek.log.info("floor row uv count: " .. (uvs and #uvs or 0), "raycaster")
end

--@api-stub: Raycaster:setFloorTextureCell
-- Assigns a per-cell floor texture override
do
  local rc = lurek.raycaster.new(16, 16)
  local tex = lurek.render.newImage("assets/icon.png")

  -- Assign a custom floor texture to a specific cell.
  -- This overrides the default floor color for that tile in buildScene.
  rc:setFloorTextureCell(4, 4, tex)

  -- Pass nil to remove the override and revert to the default floor
  rc:setFloorTextureCell(4, 4, nil)
end

--@api-stub: Raycaster:getFloorTextureCell
-- Returns the raw texture id assigned to a floor cell
do
  local rc = lurek.raycaster.new(16, 16)
  local tex = lurek.render.newImage("assets/icon.png")
  rc:setFloorTextureCell(2, 2, tex)

  -- Returns the numeric texture id, or nil if no override is set
  local id = rc:getFloorTextureCell(2, 2)
  lurek.log.info("floor tex id: " .. tostring(id), "raycaster")
end

--@api-stub: Raycaster:setCeilingTextureCell
-- Assigns a per-cell ceiling texture override
do
  local rc = lurek.raycaster.new(16, 16)
  local tex = lurek.render.newImage("assets/icon.png")

  -- Same as setFloorTextureCell but for the ceiling surface
  rc:setCeilingTextureCell(4, 4, tex)

  -- Pass nil to clear
  rc:setCeilingTextureCell(4, 4, nil)
end

--@api-stub: Raycaster:getCeilingTextureCell
-- Returns the raw texture id assigned to a ceiling cell
do
  local rc = lurek.raycaster.new(16, 16)
  local tex = lurek.render.newImage("assets/icon.png")
  rc:setCeilingTextureCell(2, 2, tex)

  -- Returns nil if no ceiling texture is assigned to this cell
  local id = rc:getCeilingTextureCell(2, 2)
  lurek.log.info("ceiling tex id: " .. tostring(id), "raycaster")
end

--@api-stub: Raycaster:setLoweredFloorCell
-- Marks a cell as a lowered floor (pit) with texture, depth, tint, and blocking
do
  local rc = lurek.raycaster.new(16, 16)
  local tex = lurek.render.newImage("assets/icon.png")

  -- Lowered floors create visible pits with their own texture and depth.
  -- Options: texture (required), depth (0.0..0.75), r/g/b tint, blocked flag.
  rc:setLoweredFloorCell(6, 6, {
    texture = tex,    -- pit floor texture
    depth = 0.25,     -- how deep the pit is (clamped to 0..0.75)
    r = 0.8,          -- blue-ish tint for water pit
    g = 0.9,
    b = 1.0,
    blocked = true,   -- player cannot walk through (isWalkBlocked returns true)
  })

  -- Pass nil to remove the lowered floor and revert to a normal cell
  rc:setLoweredFloorCell(6, 6, nil)
end

--@api-stub: Raycaster:getLoweredFloorCell
-- Returns the lowered floor configuration at a cell
do
  local rc = lurek.raycaster.new(16, 16)
  local tex = lurek.render.newImage("assets/icon.png")
  rc:setLoweredFloorCell(3, 3, { texture = tex, depth = 0.25, blocked = true })

  -- Returns a table with: texture, depth, r, g, b, blocked — or nil if normal cell
  local cell = rc:getLoweredFloorCell(3, 3)
  if cell then
    lurek.log.info("pit depth=" .. cell.depth .. " blocked=" .. tostring(cell.blocked), "raycaster")
  end
end

--@api-stub: Raycaster:buildScene
-- Builds a complete textured raycaster scene for GPU rendering
do
  local rc = lurek.raycaster.new(16, 16)
  -- Build a simple room
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end
  for y = 0, 15 do rc:setCell(0, y, 1); rc:setCell(15, y, 1) end

  local wall_tex = lurek.render.newImage("assets/icon.png")

  -- buildScene generates all render quads for a full raycaster frame.
  -- The scene is stored internally and rendered automatically by the engine.
  local params = {
    px = 8, py = 8,         -- player position
    angle = 0,              -- facing angle in radians
    fov = math.pi/3,        -- 60 degree field of view
    rays = 320,             -- number of ray columns (higher = more detail)
    max_dist = 16,          -- max render distance
    screen_w = 320,         -- output width
    screen_h = 240,         -- output height
    -- Optional parameters with defaults:
    -- ambient = 0.3,       -- base ambient light
    -- shade_dist = 8.0,    -- distance fog cutoff
    -- floor_r/g/b = 0.2,   -- default floor color
    -- ceiling_r/g/b = 0.1, -- default ceiling color
    -- camera_height = 0.5, -- eye height (0.0..1.0)
    -- horizon_offset = 0.0 -- vertical look offset
  }

  -- Wall textures map cell values to texture images
  local quad_count = rc:buildScene(params, nil, nil, { [1] = wall_tex })
  lurek.log.info("scene quads: " .. quad_count, "raycaster")
end

--@api-stub: Raycaster:buildSceneWithModels
-- Builds a textured scene with additional 3D .obj model instances projected into the view
do
  local rc = lurek.raycaster.new(8, 8)
  rc:setCell(3, 3, 1)

  -- buildSceneWithModels extends buildScene with 3D model projection.
  -- Models are .obj files rendered as billboards at their world position.
  local params = {
    px = 1.5, py = 1.5, angle = 0, fov = 1.0,
    rays = 160, max_dist = 8,
    screen_w = 320, screen_h = 200
  }
  local ok, n = pcall(function() return rc:buildSceneWithModels(params) end)
  lurek.log.info("buildSceneWithModels ok=" .. tostring(ok), "raycaster")
end

--@api-stub: Raycaster:drawView
-- Renders a first-person raycaster view to a raw image buffer (flat-shaded, no textures)
do
  local rc = lurek.raycaster.new(16, 16)
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end
  for y = 0, 15 do rc:setCell(0, y, 1); rc:setCell(15, y, 1) end

  -- drawView creates a CPU-rendered flat-shaded image.
  -- Useful for minimaps, thumbnails, or software rendering fallback.
  local img = rc:drawView(8, 8, 0, math.pi/3, 320, 240, 16)
  lurek.log.info("view rendered", "raycaster")
end

--@api-stub: Raycaster:drawTopDown
-- Renders a top-down debug view of the map
do
  local rc = lurek.raycaster.new(16, 16)
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end

  -- drawTopDown creates a bird's-eye debug image showing walls, player position, and direction.
  -- scale = pixels per grid cell (8 = 8px per tile)
  local img = rc:drawTopDown(8, 8, 0, 8)
  lurek.log.info("top-down drawn", "raycaster")
end

--@api-stub: Raycaster:drawDepthMap
-- Renders a grayscale depth map showing distance-to-wall for each column
do
  local rc = lurek.raycaster.new(16, 16)
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end
  for y = 0, 15 do rc:setCell(0, y, 1); rc:setCell(15, y, 1) end

  -- drawDepthMap produces a grayscale image: white = close, black = far.
  -- Useful for post-processing effects (depth-of-field, fog) or AI visibility.
  local img = rc:drawDepthMap(8, 8, 0, math.pi/3, 320, 320, 240, 16)
  lurek.log.info("depth map drawn", "raycaster")
end

--@api-stub: Raycaster:drawLineOfSight
-- Renders a debug image showing the line-of-sight ray between two points
do
  local rc = lurek.raycaster.new(16, 16)
  rc:setCell(8, 8, 1)  -- wall in the middle

  -- drawLineOfSight creates a debug image with the grid, the ray, and hit marker.
  -- Useful for visualizing AI sight lines during development.
  local img = rc:drawLineOfSight(4, 4, 12, 12, 8)
  lurek.log.info("LOS drawn", "raycaster")
end

--@api-stub: Raycaster:drawCameraSweep
-- Renders multiple rotation frames as a combined image
do
  local rc = lurek.raycaster.new(16, 16)
  for x = 0, 15 do rc:setCell(x, 0, 1); rc:setCell(x, 15, 1) end
  for y = 0, 15 do rc:setCell(0, y, 1); rc:setCell(15, y, 1) end

  -- drawCameraSweep renders numFrames views at evenly-spaced rotation angles,
  -- stitched into a single wide image. Use for sprite-sheet generation or panoramas.
  local img = rc:drawCameraSweep(
    8, 8,       -- camera position
    math.pi/3,  -- FOV per frame
    16,         -- max render distance
    6,          -- 6 rotation frames (60 degrees each = full 360)
    64, 48      -- each frame is 64x48 pixels
  )
  lurek.log.info("camera sweep drawn", "raycaster")
end

--@api-stub: LRaycaster:type
-- Returns the type name of this object ("LRaycaster")
do
  local rc = lurek.raycaster.new(8, 8)
  -- Always returns "LRaycaster"
  local t = rc:type()
  lurek.log.info("LRaycaster:type = " .. t, "raycaster")
end

--@api-stub: LRaycaster:typeOf
-- Checks whether this object matches the given type name
do
  local rc = lurek.raycaster.new(8, 8)
  -- Accepts "LRaycaster", "Raycaster", or "Object"
  lurek.log.info("is LRaycaster: " .. tostring(rc:typeOf("LRaycaster")), "raycaster")
  lurek.log.info("is unknown: " .. tostring(rc:typeOf("Unknown")), "raycaster")
end

-- =============================================================================
-- SpriteManager methods
-- =============================================================================

--@api-stub: SpriteManager:add
-- Adds a sprite to this sprite manager
do
  local sm = lurek.raycaster.newSpriteManager()

  -- add() places a billboard sprite in the world.
  -- Returns a unique id for later manipulation (move, hide, remove).
  local id = sm:add(3.5, 2.5, "crate", 1.0)
  lurek.log.info("sprite id: " .. id, "raycaster")
end

--@api-stub: SpriteManager:remove
-- Removes a sprite by its id
do
  local sprites = lurek.raycaster.newSpriteManager()
  local id = sprites:add(5.0, 4.0, "potion", 0.5)

  -- Remove a sprite when it is picked up or destroyed
  sprites:remove(id)
end

--@api-stub: SpriteManager:setPosition
-- Updates the world position of an existing sprite
do
  local sprites = lurek.raycaster.newSpriteManager()
  local id = sprites:add(2.0, 2.0, "enemy_imp", 1.0)

  -- Move sprites each frame for enemy AI or animated props
  function lurek.process(dt)
    sprites:setPosition(id, 2.0 + dt, 2.0)
  end
end

--@api-stub: SpriteManager:setVisible
-- Shows or hides a sprite without removing it
do
  local sprites = lurek.raycaster.newSpriteManager()
  local id = sprites:add(7.0, 3.0, "key_red", 0.6)

  -- Hide sprites temporarily (e.g. item already collected but may respawn)
  -- Hidden sprites are skipped during sortAndProject
  sprites:setVisible(id, false)
end

--@api-stub: SpriteManager:clear
-- Removes all sprites from the manager
do
  local sprites = lurek.raycaster.newSpriteManager()
  sprites:add(1, 1, "barrel", 1.0)
  sprites:add(3, 4, "barrel", 1.0)

  -- Use clear() when transitioning between levels
  sprites:clear()
end

--@api-stub: SpriteManager:sortAndProject
-- Sorts all visible sprites by distance from camera and returns projection data
do
  local sm = lurek.raycaster.newSpriteManager()
  sm:add(3.5, 2.5, "crate", 1.0)
  sm:add(6.0, 5.0, "enemy", 1.0)

  -- sortAndProject returns sprites sorted back-to-front for correct draw order.
  -- Each entry: { id, x, y, texture, scale, distance }
  -- Draw them in order to get correct painter's-algorithm layering.
  local projs = sm:sortAndProject(8, 8, 0)
  lurek.log.info("projected sprites: " .. #projs, "raycaster")
end

--@api-stub: SpriteManager:type
-- Returns the Lua-visible type name string for this sprite manager handle
do
  local sprites = lurek.raycaster.newSpriteManager()
  -- Always returns "LSpriteManager"
  lurek.log.info("SpriteManager:type = " .. tostring(sprites and sprites:type() or "nil"), "raycaster")
end

--@api-stub: SpriteManager:typeOf
-- Returns true if this sprite manager handle matches the given type name string
do
  local sprites = lurek.raycaster.newSpriteManager()
  -- Accepts "LSpriteManager", "SpriteManager", or "Object"
  if sprites and sprites:typeOf("LSpriteManager") then
    lurek.log.debug("sprite mgr ok", "raycaster")
  end
end

print("content/examples/raycaster.lua")

-- =============================================================================
-- STUBS: 64 uncovered lurek.raycaster API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LDoorManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDoorManager:addDoor ------------------------------------------
--@api-stub: LDoorManager:addDoor
-- Registers a new sliding door at the given grid cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:addDoor(0.0, 0.0, dir_str, 120.0)  -- -> number
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:openDoor -----------------------------------------
--@api-stub: LDoorManager:openDoor
-- Begins opening the door at the given index. The door animates over time via `update()`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:openDoor(1)
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:closeDoor ----------------------------------------
--@api-stub: LDoorManager:closeDoor
-- Begins closing the door at the given index. The door animates over time via `update()`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:closeDoor(1)
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:update -------------------------------------------
--@api-stub: LDoorManager:update
-- Advances all door animations by the given delta time. Call once per frame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:update(0.016)
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:getDoor ------------------------------------------
--@api-stub: LDoorManager:getDoor
-- Returns a table describing the door at the given index, or nil if index is out of range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:getDoor(1)  -- -> table
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:count --------------------------------------------
--@api-stub: LDoorManager:count
-- Returns the total number of registered doors.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:count()  -- -> number
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:type ---------------------------------------------
--@api-stub: LDoorManager:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:type()  -- -> string
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- ---- Stub: LDoorManager:typeOf -------------------------------------------
--@api-stub: LDoorManager:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDoorManager_stub:typeOf("hero")  -- -> boolean
-- (replace lDoorManager_stub with your real LDoorManager instance above)

-- -----------------------------------------------------------------------------
-- LHeightMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHeightMap:setFloor -------------------------------------------
--@api-stub: LHeightMap:setFloor
-- Sets the floor height offset at a specific grid cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHeightMap_stub:setFloor(0.0, 0.0, 64.0)
-- (replace lHeightMap_stub with your real LHeightMap instance above)

-- ---- Stub: LHeightMap:setCeiling -----------------------------------------
--@api-stub: LHeightMap:setCeiling
-- Sets the ceiling height offset at a specific grid cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHeightMap_stub:setCeiling(0.0, 0.0, 64.0)
-- (replace lHeightMap_stub with your real LHeightMap instance above)

-- ---- Stub: LHeightMap:floorAt --------------------------------------------
--@api-stub: LHeightMap:floorAt
-- Returns the floor height offset at a given grid cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHeightMap_stub:floorAt(0.0, 0.0)  -- -> number
-- (replace lHeightMap_stub with your real LHeightMap instance above)

-- ---- Stub: LHeightMap:ceilingAt ------------------------------------------
--@api-stub: LHeightMap:ceilingAt
-- Returns the ceiling height offset at a given grid cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHeightMap_stub:ceilingAt(0.0, 0.0)  -- -> number
-- (replace lHeightMap_stub with your real LHeightMap instance above)

-- ---- Stub: LHeightMap:type -----------------------------------------------
--@api-stub: LHeightMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHeightMap_stub:type()  -- -> string
-- (replace lHeightMap_stub with your real LHeightMap instance above)

-- ---- Stub: LHeightMap:typeOf ---------------------------------------------
--@api-stub: LHeightMap:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHeightMap_stub:typeOf("hero")  -- -> boolean
-- (replace lHeightMap_stub with your real LHeightMap instance above)

-- -----------------------------------------------------------------------------
-- LPointLight methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPointLight:x -------------------------------------------------
--@api-stub: LPointLight:x
-- Returns the X world position of this light.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:x()  -- -> number
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:y -------------------------------------------------
--@api-stub: LPointLight:y
-- Returns the Y world position of this light.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:y()  -- -> number
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:radius --------------------------------------------
--@api-stub: LPointLight:radius
-- Returns the light's falloff radius in world units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:radius()  -- -> number
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:intensity -----------------------------------------
--@api-stub: LPointLight:intensity
-- Returns the brightness multiplier of this light.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:intensity()  -- -> number
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:color ---------------------------------------------
--@api-stub: LPointLight:color
-- Returns the RGB color components of this light.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:color()  -- -> number, number, number
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:set -----------------------------------------------
--@api-stub: LPointLight:set
-- Overwrites all properties of this point light in a single call.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:set(0.0, 0.0, 1.0, 0.8, 0.2, 24.0, intensity)
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:type ----------------------------------------------
--@api-stub: LPointLight:type
-- Returns the type name of this object ("LPointLight").
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:type()  -- -> string
-- (replace lPointLight_stub with your real LPointLight instance above)

-- ---- Stub: LPointLight:typeOf --------------------------------------------
--@api-stub: LPointLight:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPointLight_stub:typeOf("hero")  -- -> boolean
-- (replace lPointLight_stub with your real LPointLight instance above)

-- -----------------------------------------------------------------------------
-- LRaycaster methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LRaycaster:setCell --------------------------------------------
--@api-stub: LRaycaster:setCell
-- Sets the wall type value at a grid cell. Non-zero values are solid walls.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:setCell(0.0, 0.0, val)
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:getCell --------------------------------------------
--@api-stub: LRaycaster:getCell
-- Returns the wall type value at a grid cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:getCell(0.0, 0.0)  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:setCells -------------------------------------------
--@api-stub: LRaycaster:setCells
-- Replaces the entire map grid with a flat array of cell values (row-major order).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:setCells(cells_tbl)
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:isBlocked ------------------------------------------
--@api-stub: LRaycaster:isBlocked
-- Returns true if the grid cell is a solid wall (non-zero value).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:isBlocked(0.0, 0.0)  -- -> boolean
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:width ----------------------------------------------
--@api-stub: LRaycaster:width
-- Returns the map width in grid cells.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:width()  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:height ---------------------------------------------
--@api-stub: LRaycaster:height
-- Returns the map height in grid cells.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:height()  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:setFloorTextureCell --------------------------------
--@api-stub: LRaycaster:setFloorTextureCell
-- Assigns a per-cell floor texture override. Pass nil to remove the override.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:setFloorTextureCell(0.0, 0.0, texture)
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:getFloorTextureCell --------------------------------
--@api-stub: LRaycaster:getFloorTextureCell
-- Returns the raw texture id assigned to this floor cell, or nil if none.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:getFloorTextureCell(0.0, 0.0)  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:setCeilingTextureCell ------------------------------
--@api-stub: LRaycaster:setCeilingTextureCell
-- Assigns a per-cell ceiling texture override. Pass nil to remove the override.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:setCeilingTextureCell(0.0, 0.0, texture)
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:getCeilingTextureCell ------------------------------
--@api-stub: LRaycaster:getCeilingTextureCell
-- Returns the raw texture id assigned to this ceiling cell, or nil if none.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:getCeilingTextureCell(0.0, 0.0)  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:setLoweredFloorCell --------------------------------
--@api-stub: LRaycaster:setLoweredFloorCell
-- Marks a cell as a lowered floor (pit) with its own texture, depth, tint, and blocking flag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:setLoweredFloorCell(0.0, 0.0, opts)
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:getLoweredFloorCell --------------------------------
--@api-stub: LRaycaster:getLoweredFloorCell
-- Returns the lowered floor configuration at a cell, or nil if the cell is normal.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:getLoweredFloorCell(0.0, 0.0)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:isWalkBlocked --------------------------------------
--@api-stub: LRaycaster:isWalkBlocked
-- Returns true if the cell blocks walking (solid wall OR blocked lowered-floor cell).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:isWalkBlocked(0.0, 0.0)  -- -> boolean
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:tryMove --------------------------------------------
--@api-stub: LRaycaster:tryMove
-- Attempts to move from (px,py) by (dx,dy) with wall-slide collision. Returns the final position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:tryMove(px, py, dx, dy)  -- -> number, number, boolean
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:gridMove -------------------------------------------
--@api-stub: LRaycaster:gridMove
-- Performs a discrete grid-step movement in one of 4 cardinal directions with collision.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:gridMove(px, py, dir, action, step)  -- -> number, number, boolean
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:castRay --------------------------------------------
--@api-stub: LRaycaster:castRay
-- Casts a single ray from (ox,oy) at the given angle and returns hit info or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:castRay(ox, oy, 0.0, max_dist)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:castRays -------------------------------------------
--@api-stub: LRaycaster:castRays
-- Casts multiple rays across a field of view and returns an array of hit tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:castRays(ox, oy, 0.0, fov, 10, max_dist)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:castRaysFlat ---------------------------------------
--@api-stub: LRaycaster:castRaysFlat
-- Casts multiple rays and returns only the corrected distances as a flat array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:castRaysFlat(ox, oy, 0.0, fov, 10, max_dist)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:lineOfSight ----------------------------------------
--@api-stub: LRaycaster:lineOfSight
-- Tests whether there is a clear line of sight between two world points (no walls in between).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:lineOfSight(x1, y1, x2, y2)  -- -> boolean
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:revealCellsFromRays --------------------------------
--@api-stub: LRaycaster:revealCellsFromRays
-- Casts rays across the FOV and returns a list of grid cells that are visible (for fog-of-war).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:revealCellsFromRays()  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:computeTileLight -----------------------------------
--@api-stub: LRaycaster:computeTileLight
-- Computes the combined lighting color at a tile from ambient and point lights, accounting for walls.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:computeTileLight(0.0, 0.0, ambient, lights_tbl)  -- -> number, number, number, number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:buildMinimapWindow ---------------------------------
--@api-stub: LRaycaster:buildMinimapWindow
-- Generates a grid of minimap tile samples around a center point with lighting info.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:buildMinimapWindow(center_x, center_y, 24.0, ambient, lights_tbl)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:setWallAlpha ---------------------------------------
--@api-stub: LRaycaster:setWallAlpha
-- Sets the transparency for a specific wall tile type, enabling see-through walls.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:setWallAlpha(tile_type, alpha)
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:getWallAlpha ---------------------------------------
--@api-stub: LRaycaster:getWallAlpha
-- Returns the current transparency value for a wall tile type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:getWallAlpha(tile_type)  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:castRayMulti ---------------------------------------
--@api-stub: LRaycaster:castRayMulti
-- Casts a single ray that passes through transparent walls, returning multiple hits.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:castRayMulti(ox, oy, 0.0, max_dist, [max_hits])  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:castFloorRow ---------------------------------------
--@api-stub: LRaycaster:castFloorRow
-- Computes floor/ceiling texture UV coordinates for a single scanline row.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:castFloorRow()  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:projectSprite --------------------------------------
--@api-stub: LRaycaster:projectSprite
-- Projects a world-space sprite to screen coordinates for billboard rendering.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:projectSprite(1.0, 1.0, px, py, pa, fov, screen_w)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:drawTopDown ----------------------------------------
--@api-stub: LRaycaster:drawTopDown
-- Renders a top-down debug view of the map with the player's position and direction.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:drawTopDown(px, py, 0.0, 1.0)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:drawView -------------------------------------------
--@api-stub: LRaycaster:drawView
-- Renders a first-person raycaster view to a raw image buffer (no textures, flat-shaded).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:drawView(px, py, 0.0, fov, 64.0, 64.0, max_dist)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:drawDepthMap ---------------------------------------
--@api-stub: LRaycaster:drawDepthMap
-- Renders a grayscale depth map showing distance-to-wall for each column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:drawDepthMap()  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:drawLineOfSight ------------------------------------
--@api-stub: LRaycaster:drawLineOfSight
-- Renders a debug image showing the line-of-sight ray between two world points.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:drawLineOfSight(ax, ay, bx, by, 1.0)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:drawCameraSweep ------------------------------------
--@api-stub: LRaycaster:drawCameraSweep
-- Renders multiple frames of a rotating camera sweep as a single combined image.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:drawCameraSweep(0.0, 0.0, fov, max_dist, num_frames, fw, fh)  -- -> table
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:buildScene -----------------------------------------
--@api-stub: LRaycaster:buildScene
-- Builds a complete textured raycaster scene for GPU rendering. Stores the output internally.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:buildScene()  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- ---- Stub: LRaycaster:buildSceneWithModels -------------------------------
--@api-stub: LRaycaster:buildSceneWithModels
-- Builds a textured raycaster scene with additional 3D .obj model instances projected into the view.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRaycaster_stub:buildSceneWithModels()  -- -> number
-- (replace lRaycaster_stub with your real LRaycaster instance above)

-- -----------------------------------------------------------------------------
-- LSpriteManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSpriteManager:add --------------------------------------------
--@api-stub: LSpriteManager:add
-- Adds a new sprite to the manager at a world position with a texture name and optional scale.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:add(0.0, 0.0, texture, [scale])  -- -> number
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:remove -----------------------------------------
--@api-stub: LSpriteManager:remove
-- Removes a sprite by its id. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:remove(1)
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:setPosition ------------------------------------
--@api-stub: LSpriteManager:setPosition
-- Updates the world position of an existing sprite.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:setPosition(1, 0.0, 0.0)
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:setVisible -------------------------------------
--@api-stub: LSpriteManager:setVisible
-- Shows or hides a sprite without removing it.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:setVisible(1, true)
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:clear ------------------------------------------
--@api-stub: LSpriteManager:clear
-- Removes all sprites from the manager.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:clear()
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:sortAndProject ---------------------------------
--@api-stub: LSpriteManager:sortAndProject
-- Sorts all visible sprites by distance from the camera and returns projection data.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:sortAndProject(cam_x, cam_y, cam_angle)  -- -> table
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:type -------------------------------------------
--@api-stub: LSpriteManager:type
-- Returns the type name of this object ("LSpriteManager").
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:type()  -- -> string
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)

-- ---- Stub: LSpriteManager:typeOf -----------------------------------------
--@api-stub: LSpriteManager:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteManager_stub:typeOf("hero")  -- -> boolean
-- (replace lSpriteManager_stub with your real LSpriteManager instance above)
