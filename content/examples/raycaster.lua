-- content/examples/raycaster.lua
-- Lurek2D lurek.raycaster API Reference
-- Run with: cargo run -- content/examples/raycaster
--
-- Scenario: A Wolfenstein-style first-person dungeon crawler with textured
-- walls, height-mapped floors/ceilings, doors that open/close, point lights
-- for torches, and billboard sprites for enemies and items.

print("=== lurek.raycaster — 2.5D Raycasting ===\n")

-- =============================================================================
-- Map & Raycaster Creation
-- =============================================================================

--@api-stub: lurek.raycaster.newMap
local map = lurek.raycaster.newMap(16, 16)

--@api-stub: lurek.raycaster.new
local rc = lurek.raycaster.new(map)

-- =============================================================================
-- Map Cell Operations
-- =============================================================================

--@api-stub: Raycaster:setCell
-- Build dungeon walls (1 = stone wall, 2 = brick wall).
rc:setCell(0, 0, 1)
rc:setCell(1, 0, 1)
rc:setCell(2, 0, 2)

--@api-stub: Raycaster:getCell
print("cell (0,0): " .. rc:getCell(0, 0))

--@api-stub: Raycaster:setCells
-- Fill a rectangular area with wall type.
rc:setCells(0, 0, 16, 1, 1)  -- top wall row

--@api-stub: Raycaster:isBlocked
print("blocked (0,0): " .. tostring(rc:isBlocked(0, 0)))

--@api-stub: Raycaster:width
print("map width: " .. rc:width())

--@api-stub: Raycaster:height
print("map height: " .. rc:height())

--@api-stub: Raycaster:getWallAlpha
print("wall alpha (0,0): " .. rc:getWallAlpha(0, 0))

-- =============================================================================
-- Rendering Helpers
-- =============================================================================

--@api-stub: lurek.raycaster.projectColumn
-- Project a single wall column for custom rendering.
local col = lurek.raycaster.projectColumn(rc, 5.0, 3.5, 0.0, 160)

--@api-stub: lurek.raycaster.distanceShade
-- Fog/distance shading factor.
local shade = lurek.raycaster.distanceShade(8.0, 16.0)
print("shade at dist 8: " .. shade)

-- =============================================================================
-- HeightMap — Variable floor/ceiling
-- =============================================================================

--@api-stub: lurek.raycaster.newHeightMap
local hmap = lurek.raycaster.newHeightMap(16, 16)

--@api-stub: HeightMap:setFloor
hmap:setFloor(5, 5, 0.2)

--@api-stub: HeightMap:setCeiling
hmap:setCeiling(5, 5, 0.8)

--@api-stub: HeightMap:floorAt
print("floor at (5,5): " .. hmap:floorAt(5, 5))

--@api-stub: HeightMap:ceilingAt
print("ceiling at (5,5): " .. hmap:ceilingAt(5, 5))

--@api-stub: HeightMap:type
print("heightmap type: " .. hmap:type())

--@api-stub: HeightMap:typeOf
print("is HeightMap: " .. tostring(hmap:typeOf("HeightMap")))

-- =============================================================================
-- DoorManager — Interactive doors
-- =============================================================================

--@api-stub: lurek.raycaster.newDoorManager
local doors = lurek.raycaster.newDoorManager()

--@api-stub: DoorManager:openDoor
doors:openDoor(5, 3, 1.0)

--@api-stub: DoorManager:closeDoor
doors:closeDoor(5, 3, 1.0)

--@api-stub: DoorManager:update
doors:update(1/60)

--@api-stub: DoorManager:getDoor
local door = doors:getDoor(5, 3)
print("door state: " .. tostring(door))

--@api-stub: DoorManager:count
print("doors: " .. doors:count())

--@api-stub: DoorManager:type
print("door mgr type: " .. doors:type())

--@api-stub: DoorManager:typeOf
print("is DoorManager: " .. tostring(doors:typeOf("DoorManager")))

-- =============================================================================
-- PointLight — Torch lights in the dungeon
-- =============================================================================

--@api-stub: lurek.raycaster.newPointLight
local torch = lurek.raycaster.newPointLight(5.5, 3.5, 4.0, 1.0, {1.0, 0.8, 0.5})

--@api-stub: PointLight:x
print("torch x: " .. torch:x())

--@api-stub: PointLight:y
print("torch y: " .. torch:y())

--@api-stub: PointLight:radius
print("radius: " .. torch:radius())

--@api-stub: PointLight:intensity
print("intensity: " .. torch:intensity())

--@api-stub: PointLight:color
local c = torch:color()
print("color: " .. tostring(c))

--@api-stub: PointLight:type
print("light type: " .. torch:type())

--@api-stub: PointLight:typeOf
print("is PointLight: " .. tostring(torch:typeOf("PointLight")))

-- =============================================================================
-- SpriteManager — Billboard sprites (enemies, items)
-- =============================================================================

--@api-stub: lurek.raycaster.newSpriteManager
local sprites = lurek.raycaster.newSpriteManager()

--@api-stub: SpriteManager:setPosition
sprites:setPosition(1, 7.5, 4.5)

--@api-stub: SpriteManager:setVisible
sprites:setVisible(1, true)

--@api-stub: SpriteManager:remove
-- sprites:remove(1)

--@api-stub: SpriteManager:clear
-- sprites:clear()

--@api-stub: SpriteManager:type
print("sprite mgr type: " .. sprites:type())

--@api-stub: SpriteManager:typeOf
print("is SpriteManager: " .. tostring(sprites:typeOf("SpriteManager")))

print("\n-- raycaster.lua example complete --")
-- content/examples/raycaster.lua
-- Lurek2D lurek.raycaster API Reference
-- Run with: cargo run -- content/examples/raycaster

-- =============================================================================
-- lurek.raycaster — Wolfenstein-style 2.5D raycasting with doors, height maps,
--                   point lights, and billboarded sprites
--
-- The raycaster projects a 2D grid map into a pseudo-3D first-person view
-- using column-based rendering.  It supports textured walls, floor/ceiling
-- height maps, interactive doors, dynamic point lights, distance-based fog,
-- and billboarded sprite objects.
-- =============================================================================

-- ---- Stub: lurek.raycaster.new -------------------------------------------
--@api-stub: lurek.raycaster.new
-- Create a raycaster with a 16x16 grid.  Each cell value is a wall type
-- (0 = empty, 1+ = wall texture index).
local rc = lurek.raycaster.new(16, 16)
print("raycaster created: 16x16 grid")
print("  width: " .. rc:width() .. ", height: " .. rc:height())

-- ---- Stub: lurek.raycaster.newMap ----------------------------------------
--@api-stub: lurek.raycaster.newMap
-- Create a raycaster from a pre-built 2D table.  Each row is a table of
-- cell values.  Useful for loading maps from files.
local map_data = {
    {1,1,1,1,1},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {1,1,1,1,1},
}
local rc_map = lurek.raycaster.newMap(map_data)
print("raycaster from map: " .. rc_map:width() .. "x" .. rc_map:height())

-- ---- Stub: lurek.raycaster.projectColumn ---------------------------------
--@api-stub: lurek.raycaster.projectColumn
-- Project a single column at angle offset 0.3 rad from the camera facing
-- direction.  Returns wall distance, wall type, and hit side.
local dist, wall_type, side = lurek.raycaster.projectColumn(rc, 4.5, 4.5, 0.0, 0.3)
print(string.format("column: dist=%.2f wall=%d side=%s",
    dist or 0, wall_type or 0, tostring(side)))

-- ---- Stub: lurek.raycaster.distanceShade ---------------------------------
--@api-stub: lurek.raycaster.distanceShade
-- Compute a fog factor from 0.0 (close, bright) to 1.0 (far, dark) for
-- distance-based atmosphere.  Max range 10 units.
local shade = lurek.raycaster.distanceShade(5.0, 10.0)
print(string.format("shade at dist 5.0 (max 10): %.2f", shade))
local shade_close = lurek.raycaster.distanceShade(1.0, 10.0)
print(string.format("shade at dist 1.0: %.2f (brighter)", shade_close))


-- =============================================================================
-- Raycaster grid manipulation
-- =============================================================================

-- ---- Stub: Raycaster:setCell ---------------------------------------------
--@api-stub: Raycaster:setCell
-- Place a wall (type 2) at grid position (3, 3) to block a corridor.
rc:setCell(3, 3, 2)
print("wall type 2 placed at (3,3)")

-- ---- Stub: Raycaster:getCell ---------------------------------------------
--@api-stub: Raycaster:getCell
-- Read the cell value to determine which wall texture to render.
local cell = rc:getCell(3, 3)
print("cell (3,3) = " .. cell .. "  (0=empty, 1+=wall)")

-- ---- Stub: Raycaster:setCells --------------------------------------------
--@api-stub: Raycaster:setCells
-- Fill a rectangular region with walls to create a room boundary.
-- Sets cells (1,1) through (4,4) to wall type 1.
for y = 1, 4 do
    for x = 1, 4 do
        rc:setCell(x, y, (x == 1 or x == 4 or y == 1 or y == 4) and 1 or 0)
    end
end
print("room boundary built from (1,1) to (4,4)")

-- ---- Stub: Raycaster:isBlocked ------------------------------------------
--@api-stub: Raycaster:isBlocked
-- Check if a cell is blocked before moving the player or placing an object.
local blocked = rc:isBlocked(3, 3)
print("cell (3,3) blocked: " .. tostring(blocked))
local open = rc:isBlocked(2, 2)
print("cell (2,2) blocked: " .. tostring(open))

-- ---- Stub: Raycaster:width ----------------------------------------------
--@api-stub: Raycaster:width
-- Use the map width to iterate over all columns for rendering.
local w = rc:width()
print("map width: " .. w .. " cells")

-- ---- Stub: Raycaster:height ---------------------------------------------
--@api-stub: Raycaster:height
-- Use the map height for boundary checks during pathfinding.
local h = rc:height()
print("map height: " .. h .. " cells")

-- ---- Stub: Raycaster:getWallAlpha ----------------------------------------
--@api-stub: Raycaster:getWallAlpha
-- Get the wall transparency at a grid cell for glass/window walls.
local alpha = rc:getWallAlpha(3, 3)
print("wall alpha at (3,3): " .. tostring(alpha) .. "  (1.0 = opaque)")


-- =============================================================================
-- DoorManager — interactive doors that open and close over time
-- =============================================================================

-- ---- Stub: lurek.raycaster.newDoorManager --------------------------------
--@api-stub: lurek.raycaster.newDoorManager
-- Create a door manager linked to the raycaster grid.
local doors = lurek.raycaster.newDoorManager(rc)
print("door manager created")

-- ---- Stub: DoorManager:openDoor -----------------------------------------
--@api-stub: DoorManager:openDoor
-- Open the door at cell (5, 2) when the player presses the interact key.
doors:openDoor(5, 2)
print("door at (5,2) opening...")

-- ---- Stub: DoorManager:closeDoor ----------------------------------------
--@api-stub: DoorManager:closeDoor
-- Close the door after a timeout to reset the corridor.
doors:closeDoor(5, 2)
print("door at (5,2) closing...")

-- ---- Stub: DoorManager:update -------------------------------------------
--@api-stub: DoorManager:update
-- Advance door animations each frame.  Doors slide open/closed over time.
doors:update(0.016)
print("doors updated for frame")

-- ---- Stub: DoorManager:getDoor -------------------------------------------
--@api-stub: DoorManager:getDoor
-- Read the door state (open fraction 0..1) to render partial openings.
local state = doors:getDoor(5, 2)
print("door (5,2) state: " .. tostring(state))

-- ---- Stub: DoorManager:count ---------------------------------------------
--@api-stub: DoorManager:count
-- Display the total number of doors in the level for debug info.
local door_count = doors:count()
print("total doors: " .. door_count)

-- ---- Stub: DoorManager:type ----------------------------------------------
--@api-stub: DoorManager:type
-- Inspect the type name for debugging and serialization.
print("door manager type: " .. doors:type())

-- ---- Stub: DoorManager:typeOf --------------------------------------------
--@api-stub: DoorManager:typeOf
-- Type check before casting.
print("is DoorManager: " .. tostring(doors:typeOf("DoorManager")))


-- =============================================================================
-- HeightMap — variable floor and ceiling heights for 2.5D depth
-- =============================================================================

-- ---- Stub: lurek.raycaster.newHeightMap ----------------------------------
--@api-stub: lurek.raycaster.newHeightMap
-- Create a height map matching the raycaster grid for floor/ceiling offsets.
local hmap = lurek.raycaster.newHeightMap(16, 16)
print("height map created: 16x16")

-- ---- Stub: HeightMap:setFloor --------------------------------------------
--@api-stub: HeightMap:setFloor
-- Raise the floor at (3, 3) to create a step / platform.
hmap:setFloor(3, 3, 0.5)
print("floor at (3,3) raised to 0.5")

-- ---- Stub: HeightMap:setCeiling ------------------------------------------
--@api-stub: HeightMap:setCeiling
-- Lower the ceiling to create a low passage the player must duck under.
hmap:setCeiling(4, 4, 0.7)
print("ceiling at (4,4) lowered to 0.7")

-- ---- Stub: HeightMap:floorAt ---------------------------------------------
--@api-stub: HeightMap:floorAt
-- Read floor height to adjust the player's vertical position.
local floor_h = hmap:floorAt(3, 3)
print("floor height at (3,3): " .. floor_h)

-- ---- Stub: HeightMap:ceilingAt -------------------------------------------
--@api-stub: HeightMap:ceilingAt
-- Read ceiling height to check if the player fits under a low arch.
local ceil_h = hmap:ceilingAt(4, 4)
print("ceiling height at (4,4): " .. ceil_h)

-- ---- Stub: HeightMap:type ------------------------------------------------
--@api-stub: HeightMap:type
print("height map type: " .. hmap:type())

-- ---- Stub: HeightMap:typeOf ----------------------------------------------
--@api-stub: HeightMap:typeOf
print("is HeightMap: " .. tostring(hmap:typeOf("HeightMap")))


-- =============================================================================
-- PointLight — dynamic lights for torches, muzzle flashes, lava glow
-- =============================================================================

-- ---- Stub: lurek.raycaster.newPointLight ---------------------------------
--@api-stub: lurek.raycaster.newPointLight
-- Create a flickering torch light at world position (3.5, 7.5) with
-- radius 4.0 and warm orange colour.
local torch = lurek.raycaster.newPointLight(3.5, 7.5, 4.0)
print("point light created at (3.5, 7.5) radius 4.0")

-- ---- Stub: PointLight:x -------------------------------------------------
--@api-stub: PointLight:x
-- Read the light's X position for distance calculations.
print("light x: " .. torch:x())

-- ---- Stub: PointLight:y -------------------------------------------------
--@api-stub: PointLight:y
-- Read the light's Y position.
print("light y: " .. torch:y())

-- ---- Stub: PointLight:radius ---------------------------------------------
--@api-stub: PointLight:radius
-- Read the radius to determine the area of effect for shadow casting.
print("light radius: " .. torch:radius())

-- ---- Stub: PointLight:intensity ------------------------------------------
--@api-stub: PointLight:intensity
-- Read the intensity for brightness calculations.
local intensity = torch:intensity()
print("light intensity: " .. tostring(intensity))

-- ---- Stub: PointLight:color ----------------------------------------------
--@api-stub: PointLight:color
-- Read the light colour for tinting nearby walls.
local r, g, b = torch:color()
print(string.format("light color: (%.2f, %.2f, %.2f)", r or 0, g or 0, b or 0))

-- ---- Stub: PointLight:type -----------------------------------------------
--@api-stub: PointLight:type
print("light type: " .. torch:type())

-- ---- Stub: PointLight:typeOf ---------------------------------------------
--@api-stub: PointLight:typeOf
print("is PointLight: " .. tostring(torch:typeOf("PointLight")))


-- =============================================================================
-- SpriteManager — billboarded objects (enemies, pickups, decorations)
-- =============================================================================

-- ---- Stub: lurek.raycaster.newSpriteManager ------------------------------
--@api-stub: lurek.raycaster.newSpriteManager
-- Create a sprite manager for billboarded objects in the 3D view.
local sprites = lurek.raycaster.newSpriteManager()
print("sprite manager created")

-- ---- Stub: SpriteManager:remove -----------------------------------------
--@api-stub: SpriteManager:remove
-- Remove a sprite when the enemy is killed.
sprites:remove(0)
print("sprite 0 removed (enemy killed)")

-- ---- Stub: SpriteManager:setPosition ------------------------------------
--@api-stub: SpriteManager:setPosition
-- Move a sprite to a new position for enemy AI wandering.
sprites:setPosition(0, 5.5, 8.2)
print("sprite 0 moved to (5.5, 8.2)")

-- ---- Stub: SpriteManager:setVisible -------------------------------------
--@api-stub: SpriteManager:setVisible
-- Hide a sprite when the player picks it up (before removal animation).
sprites:setVisible(0, false)
print("sprite 0 hidden")

-- ---- Stub: SpriteManager:clear ------------------------------------------
--@api-stub: SpriteManager:clear
-- Clear all sprites when loading a new level.
sprites:clear()
print("all sprites cleared for level transition")

-- ---- Stub: SpriteManager:type -------------------------------------------
--@api-stub: SpriteManager:type
print("sprite manager type: " .. sprites:type())

-- ---- Stub: SpriteManager:typeOf -----------------------------------------
--@api-stub: SpriteManager:typeOf
print("is SpriteManager: " .. tostring(sprites:typeOf("SpriteManager")))
-- content/examples/raycaster.lua
-- Lurek2D lurek.raycaster API Reference
-- Run with: cargo run -- content/examples/raycaster

-- =============================================================================
-- STUBS: 41 uncovered lurek.raycaster API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.raycaster.new -------------------------------------------
--@api-stub: lurek.raycaster.new
-- Create the tile grid that defines the dungeon layout -- cell value 0 is
-- open space; any value > 0 is a wall with that texture index.
local rc = lurek.raycaster.new(32, 32)
print("raycaster grid:", rc:width(), "x", rc:height())

-- ---- Stub: lurek.raycaster.newMap ----------------------------------------
--@api-stub: lurek.raycaster.newMap
-- Alias for new() -- prefer newMap() when your code emphasises the grid
-- as a map object rather than a renderer configuration.
local dungeon = lurek.raycaster.newMap(64, 64)
print("dungeon map:", dungeon:width(), "x", dungeon:height())

-- ---- Stub: lurek.raycaster.projectColumn ---------------------------------
--@api-stub: lurek.raycaster.projectColumn
-- Convert a ray-hit distance to the height in pixels of the wall slice
-- that should be drawn for that screen column.
local distance     = 4.5
local fov          = math.pi / 3
local screen_h     = 480
local slice_height = lurek.raycaster.projectColumn(distance, fov, screen_h)
print(string.format("wall slice height at dist %.1f: %.0f px", distance, slice_height))

-- ---- Stub: lurek.raycaster.distanceShade ---------------------------------
--@api-stub: lurek.raycaster.distanceShade
-- Compute a brightness factor to darken walls and sprites with distance --
-- multiply the texture colour by this value before drawing each column.
local brightness = lurek.raycaster.distanceShade(6.0, 16.0)
print(string.format("shade at dist 6 of max 16: %.2f", brightness))

-- ---- Stub: lurek.raycaster.newDoorManager --------------------------------
--@api-stub: lurek.raycaster.newDoorManager
-- Track animated sliding doors in the map -- the manager handles open/close
-- state and partial offsets so the raycaster can skip blocked columns.
local dm = lurek.raycaster.newDoorManager()
print("door manager type:", dm:type())

-- ---- Stub: lurek.raycaster.newHeightMap ----------------------------------
--@api-stub: lurek.raycaster.newHeightMap
-- Vary floor and ceiling heights per cell for stairways, platforms, and
-- multi-level areas in a 2.5D dungeon renderer.
local hm = lurek.raycaster.newHeightMap(32, 32)
hm:setFloor(10, 10, 0.25)    -- sunken floor pit
hm:setCeiling(10, 10, 0.75)  -- lower ceiling above it
print("height map floor at (10,10):", hm:floorAt(10, 10))

-- ---- Stub: lurek.raycaster.newPointLight ---------------------------------
--@api-stub: lurek.raycaster.newPointLight
-- Add a dynamic point light source for torches, portals, or glowing pickups
-- that illuminate nearby walls with a coloured halo.
local pl = lurek.raycaster.newPointLight(16.5, 12.0, 1.0, 0.8, 0.2, 8.0, 1.5)
-- args: x, y, r, g, b, radius, intensity
print("point light at", pl:x(), pl:y(), "radius:", pl:radius())

-- ---- Stub: lurek.raycaster.newSpriteManager ------------------------------
--@api-stub: lurek.raycaster.newSpriteManager
-- Manage depth-sorted world sprites (enemies, pickups, decorations) so they
-- are drawn in correct painter's order relative to wall columns.
local sm = lurek.raycaster.newSpriteManager()
print("sprite manager type:", sm:type())

-- -----------------------------------------------------------------------------
-- DoorManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: DoorManager:openDoor ------------------------------------------
--@api-stub: DoorManager:openDoor
-- Trigger the opening animation when the player activates the USE key
-- in front of a door cell -- the manager slides it open over time.
dm:openDoor(1)
print("door 1 opening")

-- ---- Stub: DoorManager:closeDoor -----------------------------------------
--@api-stub: DoorManager:closeDoor
-- Auto-close a door after a timer or when the player walks through --
-- prevents doors from staying open and letting enemies follow freely.
dm:closeDoor(1)
print("door 1 closing")

-- ---- Stub: DoorManager:update --------------------------------------------
--@api-stub: DoorManager:update
-- Advance door animations each frame so the slide position stays smooth
-- and matches the frame rate rather than snapping to open/closed.
dm:update(0.016)
local door = dm:getDoor(1)
if door then
    print("door 1 offset:", door.offset)
end

-- ---- Stub: DoorManager:getDoor -------------------------------------------
--@api-stub: DoorManager:getDoor
-- Read the door state during raycasting to offset the wall column based
-- on how far open the door is, giving the sliding-door visual effect.
local door_state = dm:getDoor(1)
if door_state then
    print("door 1 state:", door_state.state, "offset:", door_state.offset)
end

-- ---- Stub: DoorManager:count ---------------------------------------------
--@api-stub: DoorManager:count
-- Read the door count to pre-allocate state tables or to validate
-- that the map script registered the correct number of doors.
print("registered doors:", dm:count())

-- ---- Stub: DoorManager:type ----------------------------------------------
--@api-stub: DoorManager:type
-- Confirm type identity in a generic raycaster-object dispatcher before
-- calling door-specific methods.
print(dm:type())  -- "DoorManager"

-- ---- Stub: DoorManager:typeOf --------------------------------------------
--@api-stub: DoorManager:typeOf
-- Verify the object is a DoorManager in a guard before calling door-specific
-- methods in a generic raycaster entity dispatch function.
print(dm:typeOf("DoorManager"))  -- true

-- -----------------------------------------------------------------------------
-- HeightMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: HeightMap:setFloor --------------------------------------------
--@api-stub: HeightMap:setFloor
-- Raise or lower the floor at a specific cell for steps, pits, or terrain
-- variation -- 0.0 = ground level, positive values raise it.
hm:setFloor(5, 5, 0.3)  -- slightly raised platform
print("floor at (5,5):", hm:floorAt(5, 5))

-- ---- Stub: HeightMap:setCeiling ------------------------------------------
--@api-stub: HeightMap:setCeiling
-- Lower the ceiling for oppressive corridors or raise it for grand halls --
-- 1.0 = full wall height, 0.5 = only half the column is rendered.
hm:setCeiling(8, 8, 0.6)  -- low-clearance tunnel
print("ceiling at (8,8):", hm:ceilingAt(8, 8))

-- ---- Stub: HeightMap:floorAt ---------------------------------------------
--@api-stub: HeightMap:floorAt
-- Query floor height during rendering to determine the bottom of the wall
-- slice or the visible floor stripe for a given cell.
print("floor at (5,5):", hm:floorAt(5, 5))   -- 0.3
print("floor at (0,0):", hm:floorAt(0, 0))   -- 0.0 (default)

-- ---- Stub: HeightMap:ceilingAt -------------------------------------------
--@api-stub: HeightMap:ceilingAt
-- Query ceiling height during rendering to determine the top of the wall
-- slice or the visible ceiling stripe for a given cell.
print("ceiling at (8,8):", hm:ceilingAt(8, 8))  -- 0.6
print("ceiling at (0,0):", hm:ceilingAt(0, 0))  -- 1.0 (default)

-- ---- Stub: HeightMap:type ------------------------------------------------
--@api-stub: HeightMap:type
-- Confirm type identity in a generic raycaster-object dispatcher before
-- calling height-specific methods.
print(hm:type())  -- "HeightMap"

-- ---- Stub: HeightMap:typeOf ----------------------------------------------
--@api-stub: HeightMap:typeOf
-- Verify the object is a HeightMap before calling height-specific methods
-- in a generic raycaster scene-object function.
print(hm:typeOf("HeightMap"))  -- true

-- -----------------------------------------------------------------------------
-- PointLight methods
-- -----------------------------------------------------------------------------

-- ---- Stub: PointLight:x --------------------------------------------------
--@api-stub: PointLight:x
-- Read the world X position to pass to the renderer or to compute the
-- distance from the player for culling far lights.
print("light x:", pl:x())  -- 16.5

-- ---- Stub: PointLight:y --------------------------------------------------
--@api-stub: PointLight:y
-- Read the world Y position to update a torch's position when attached
-- to a moving platform or pushed by a puzzle mechanic.
print("light y:", pl:y())  -- 12.0

-- ---- Stub: PointLight:radius ---------------------------------------------
--@api-stub: PointLight:radius
-- Read the illumination radius to cull lights that are farther than this
-- from the player before passing them to the renderer.
print("light radius:", pl:radius())  -- 8.0

-- ---- Stub: PointLight:intensity ------------------------------------------
--@api-stub: PointLight:intensity
-- Animate the intensity each frame to create a flickering torch effect by
-- oscillating between 0.8 and 1.5 using a sine wave or TweenState.
print("light intensity:", pl:intensity())  -- 1.5

-- ---- Stub: PointLight:color ----------------------------------------------
--@api-stub: PointLight:color
-- Read RGB to tint wall columns within the light radius -- multiply
-- each channel by distanceShade() and the wall texture colour.
local r, g, b = pl:color()
print(string.format("light colour: (%.2f, %.2f, %.2f)", r, g, b))

-- ---- Stub: PointLight:type -----------------------------------------------
--@api-stub: PointLight:type
-- Confirm type identity in a generic raycaster-object dispatcher before
-- treating the variable as a light source.
print(pl:type())  -- "PointLight"

-- ---- Stub: PointLight:typeOf ---------------------------------------------
--@api-stub: PointLight:typeOf
-- Verify the variable is a PointLight in a mixed-type scene-object array
-- before reading its colour or radius.
print(pl:typeOf("PointLight"))  -- true

-- -----------------------------------------------------------------------------
-- Raycaster methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Raycaster:setCell ---------------------------------------------
--@api-stub: Raycaster:setCell
-- Paint wall types into the grid -- 0 = passable space, 1..N = wall
-- texture indices rendered on each side of the column.
rc:setCell(0, 0, 1)   -- solid wall
rc:setCell(15, 15, 0) -- open corridor
print("cell (0,0):", rc:getCell(0, 0))

-- ---- Stub: Raycaster:getCell ---------------------------------------------
--@api-stub: Raycaster:getCell
-- Read a cell value during pathfinding or collision checking to decide
-- whether a move is valid before updating the player position.
print("cell (5,3) texture:", rc:getCell(5, 3))  -- 0 = open, 1+ = wall

-- ---- Stub: Raycaster:setCells --------------------------------------------
--@api-stub: Raycaster:setCells
-- Load an entire map level from a flat row-major array in one call --
-- faster than calling setCell() for every tile when the map is large.
local map_data = {}
for i = 1, 32 * 32 do map_data[i] = 0 end
map_data[1] = 1  -- north-west corner wall
rc:setCells(map_data)
print("all cells loaded from array")

-- ---- Stub: Raycaster:isBlocked -------------------------------------------
--@api-stub: Raycaster:isBlocked
-- Call before moving the player to allow wall-sliding rather than stopping
-- dead -- check x and y axes independently for smooth sliding.
local new_x, new_y = 4.5, 6.0
if rc:isBlocked(new_x, new_y) then
    print("move blocked at", new_x, new_y)
else
    print("move OK")
end

-- ---- Stub: Raycaster:width -----------------------------------------------
--@api-stub: Raycaster:width
-- Read width and height to clamp coordinate lookups and to validate
-- that a loaded map matches the expected dimensions.
print("grid size:", rc:width(), "x", rc:height())

-- ---- Stub: Raycaster:height ----------------------------------------------
--@api-stub: Raycaster:height
-- Read height alongside width to ensure both dimensions are within budget
-- before allocating the HeightMap or DoorManager for this grid.
print("grid height:", rc:height())

-- ---- Stub: Raycaster:getWallAlpha ----------------------------------------
--@api-stub: Raycaster:getWallAlpha
-- Read opacity for transparent wall types (e.g. glass, forcefields) to
-- blend the wall column with the background during rendering.
local alpha = rc:getWallAlpha(3)  -- tile type 3 = glass panel
print(string.format("wall type 3 alpha: %.2f", alpha))

-- -----------------------------------------------------------------------------
-- SpriteManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: SpriteManager:remove ------------------------------------------
--@api-stub: SpriteManager:remove
-- Remove a sprite when the entity it represents is destroyed -- stale
-- entries would keep drawing invisible sprites each frame.
sm:remove(5)  -- sprite ID 5
print("sprite 5 removed")

-- ---- Stub: SpriteManager:setPosition -------------------------------------
--@api-stub: SpriteManager:setPosition
-- Update the world position each frame so the sprite stays aligned with
-- its entity as it moves through the dungeon.
sm:setPosition(1, 10.5, 8.0)
print("sprite 1 moved to (10.5, 8.0)")

-- ---- Stub: SpriteManager:setVisible --------------------------------------
--@api-stub: SpriteManager:setVisible
-- Hide a sprite temporarily (e.g. a pickup after collection) without
-- removing it from the manager so it can reappear later.
sm:setVisible(1, false)  -- hide
sm:setVisible(1, true)   -- show again
print("sprite 1 visibility toggled")

-- ---- Stub: SpriteManager:clear -------------------------------------------
--@api-stub: SpriteManager:clear
-- Flush all sprites when loading a new level so entities from the
-- previous room do not bleed into the new scene.
sm:clear()
print("all sprites cleared")

-- ---- Stub: SpriteManager:type --------------------------------------------
--@api-stub: SpriteManager:type
-- Confirm type in a generic raycaster-object dispatcher before calling
-- sprite-specific methods.
print(sm:type())  -- "SpriteManager"

-- ---- Stub: SpriteManager:typeOf ------------------------------------------
--@api-stub: SpriteManager:typeOf
-- Verify the object is a SpriteManager in a mixed-type scene-object function
-- that handles multiple manager types.
print(sm:typeOf("SpriteManager"))  -- true

-- =============================================================================
-- STUBS: 1 uncovered lurek.raycaster API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Raycaster methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Raycaster:setWallAlpha ----------------------------------------
--@api-stub: Raycaster:setWallAlpha
-- Sets the opacity for a wall tile type. Alpha is clamped to [0, 1].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- raycaster_stub:setWallAlpha(tile_type, alpha)
-- (replace raycaster_stub with your real Raycaster instance above)
