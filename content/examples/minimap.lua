-- examples/minimap.lua
-- lurek.minimap — Mini-map renderer: terrain colors, fog of war, tracked
-- objects, owner/faction tinting, zoom, and viewport indicator.

-- ── Minimap Creation ──────────────────────────────────────────────────────────

-- newMinimap(gridW, gridH, displayW?, displayH?) → Minimap
-- gridW/gridH: number of tiles in the logical grid (must match your tile map).
-- displayW/displayH: pixel dimensions of the minimap image (defaults: 128×128).
local minimap = lurek.minimap.newMinimap(64, 64, 128, 128)

-- ── Grid and Display Size ─────────────────────────────────────────────────────

local gw = minimap:getGridWidth()
local gh = minimap:getGridHeight()
local gw2, gh2 = minimap:getGridSize()    -- same, two return values

local dw = minimap:getDisplayWidth()
local dh = minimap:getDisplayHeight()
local dw2, dh2 = minimap:getDisplaySize()

-- setDisplaySize(w, h) — resize the output pixel image
minimap:setDisplaySize(256, 256)

-- ── Terrain Colors ────────────────────────────────────────────────────────────

-- Terrain types are integers stored per cell.  Assign a color to each type.

-- setTerrainColor(typeId, r, g, b)
minimap:setTerrainColor(0, 0.1, 0.5, 0.1)   -- type 0 = grass (dark green)
minimap:setTerrainColor(1, 0.7, 0.6, 0.3)   -- type 1 = sand  (tan)
minimap:setTerrainColor(2, 0.1, 0.2, 0.8)   -- type 2 = water (blue)
minimap:setTerrainColor(3, 0.5, 0.5, 0.5)   -- type 3 = stone (grey)

-- getTerrainColor(typeId) → r, g, b
local r, g, b = minimap:getTerrainColor(0)  -- 0.1, 0.5, 0.1

-- getTileDescription(typeId) → string  — debug name
local desc = minimap:getTileDescription(0)   -- "terrain_0"

-- getTerrain(x, y) → integer  — read the stored type for a single cell
local ttype = minimap:getTerrain(10, 15)

-- setTerrainData(table)  — bulk-load ALL cells from a flat 1-based table
-- (length must equal gridW × gridH; values are terrain type integers)
local terrain_flat = {}
for i = 1, 64*64 do terrain_flat[i] = 0 end   -- all grass
minimap:setTerrainData(terrain_flat)

-- ── Fog of War ────────────────────────────────────────────────────────────────

-- setFogEnabled(bool) / isFogEnabled() → bool
minimap:setFogEnabled(true)

-- setFogLevel(x, y, level)   — level 0=hidden, 1=explored, 2=visible
for x = 0, 10 do
    for y = 0, 10 do
        minimap:setFogLevel(x, y, 2)   -- reveal a 11×11 patch
    end
end

-- getFogLevel(x, y) → integer
local fog = minimap:getFogLevel(5, 5)  -- 2

-- setFogData(table)  — bulk-load fog grid from flat 1-based table
local fog_table = {}
for i = 1, 64*64 do fog_table[i] = 0 end   -- all hidden
minimap:setFogData(fog_table)

-- setFogColor(r, g, b, a?) / getFogColor() → r, g, b, a
minimap:setFogColor(0.0, 0.0, 0.0, 0.7)    -- black translucent fog
local fr, fg, fb, fa = minimap:getFogColor()

-- ── Object Types (icons/dots on the map) ─────────────────────────────────────

-- addObjectType(name, r, g, b, a?) → index (1-based)
local TYPE_PLAYER  = minimap:addObjectType("player",  1.0, 1.0, 0.0)   -- yellow dot
local TYPE_ENEMY   = minimap:addObjectType("enemy",   1.0, 0.2, 0.2)   -- red dot
local TYPE_CHEST   = minimap:addObjectType("chest",   0.9, 0.7, 0.0)   -- gold dot

-- setObjectTypeVisible(type_idx, bool)
minimap:setObjectTypeVisible(TYPE_ENEMY, true)

-- isObjectTypeVisible(type_idx) → bool
local vis = minimap:isObjectTypeVisible(TYPE_ENEMY)

-- getObjectTypeCount() → integer
local ntypes = minimap:getObjectTypeCount()  -- 3

-- ── Placing Objects ───────────────────────────────────────────────────────────

-- setObject(id, x, y, type_idx, owner?)
-- id:       unique integer ID for this tracked entity
-- x, y:     grid coordinates (float; matches tile coords)
-- type_idx: 1-based object type index returned by addObjectType
-- owner:    optional faction integer (0 = neutral)
minimap:setObject(1, 32.0, 32.0, TYPE_PLAYER, 0)
minimap:setObject(2, 45.0, 20.0, TYPE_ENEMY,  1)
minimap:setObject(3, 10.0, 10.0, TYPE_CHEST,  0)

-- removeObject(id) → bool  — true if the object existed
minimap:removeObject(3)

-- getObjectCount() → integer
local nobj = minimap:getObjectCount()

-- clearObjects() — remove all objects
minimap:clearObjects()

-- ── Owner / Faction Colors ────────────────────────────────────────────────────

-- setOwnerColor(owner, r, g, b, a?)
minimap:setOwnerColor(0, 0.2, 0.6, 1.0)   -- player faction = blue
minimap:setOwnerColor(1, 1.0, 0.2, 0.2)   -- enemy faction  = red

-- getOwnerColor(owner) → r, g, b, a
local or_, og, ob, oa = minimap:getOwnerColor(0)

-- ── Color Mode ────────────────────────────────────────────────────────────────

-- setColorMode("terrain" | "political") / getColorMode() → string
minimap:setColorMode("terrain")   -- show terrain type colors
minimap:setColorMode("political")  -- show owner faction colors

-- ── Zoom and Pan ─────────────────────────────────────────────────────────────

-- setZoom(n) / getZoom() → n  (1.0 = fit entire grid; >1 = zoom in)
minimap:setZoom(2.0)
local z = minimap:getZoom()

-- setCenter(x, y) / getCenter() → x, y  — grid position at centre of display
minimap:setCenter(32, 32)
local cx, cy = minimap:getCenter()
local cx2    = minimap:getCenterX()
local cy2    = minimap:getCenterY()

-- ── Viewport Indicator ────────────────────────────────────────────────────────

-- setViewportRect(x, y, w, h)  — draw a rect overlay showing the current camera view
minimap:setViewportRect(28, 28, 8, 6)   -- camera shows 8×6 tiles around position 28,28

-- getViewportRect() → x?, y?, w?, h?  (nil if not set)
local vx, vy, vw, vh = minimap:getViewportRect()

-- clearViewportRect()
minimap:clearViewportRect()

-- ── Typical Update / Draw ─────────────────────────────────────────────────────

--[[
local mm, player_id

function lurek.init()
    mm = lurek.minimap.newMinimap(MAP_W, MAP_H, 200, 200)
    mm:setFogEnabled(true)
    mm:setTerrainColor(0, 0.1, 0.5, 0.1)
    mm:setTerrainData(tilemap:getTerainFlat())
    player_id = 1
    mm:addObjectType("player", 1,1,0)
    mm:setObject(player_id, player.x/TILE, player.y/TILE, 1)
end

function lurek.process(dt)
    -- track player on minimap
    mm:setObject(player_id, player.x/TILE, player.y/TILE, 1)
    -- update viewport indicator
    mm:setViewportRect(cam.x/TILE, cam.y/TILE, VIEW_W/TILE, VIEW_H/TILE)
    -- reveal fog near player
    local px, py = math.floor(player.x/TILE), math.floor(player.y/TILE)
    for dx = -4, 4 do for dy = -4, 4 do
        mm:setFogLevel(px+dx, py+dy, 2)
    end end
end

function lurek.render()
    -- draw minimap in top-right corner
    lurek.gfx.draw(mm:getImageData(), SCREEN_W - 210, 10)
end
]]

-- ─── Minimap ───────────────────────────────────────────────────────────────────

local color_mode = minimap:getColorMode()  -- Returns the current color mode as a string
local marker_count = minimap:getMarkerCount()  -- Returns the number of markers
local marker_description = minimap:getMarkerDescription(1)  -- Returns the description of a marker, or nil
local ping_count = minimap:getPingCount()  -- Returns the number of active pings
local viewport_color = minimap:getViewportColor()  -- Returns the viewport rectangle color as r, g, b, a
local has_marker = minimap:hasMarker(1)  -- Returns whether a marker with the given ID exists
local is_anti_alias = minimap:isAntiAlias()  -- Returns whether anti-aliasing is enabled
local is_clickable = minimap:isClickable()  -- Returns whether this minimap responds to click hit-testing
local is_fog_enabled = minimap:isFogEnabled()  -- Returns whether fog of war is enabled
local is_viewport_visible = minimap:isViewportVisible()  -- Returns whether the viewport rectangle is visible
local remove_marker = minimap:removeMarker(1)  -- Removes a marker by ID
minimap:setAntiAlias(false)  -- Sets whether anti-aliasing is enabled
minimap:setClickable(false)  -- Sets whether this minimap responds to click hit-testing
minimap:setViewportVisible(false)  -- Sets whether the viewport rectangle is visible
local minimap_type = minimap:type()  -- "Minimap"
local minimap_is_type = minimap:typeOf("Minimap")  -- Returns true if this object is of the given type
minimap:update(1.0)  -- Advances time-based effects by dt seconds (expires pings and animation phases)

-- ── Geometry Overlay ──────────────────────────────────────────────────────────

-- drawLine(x1, y1, x2, y2, color)
-- Draw a custom line segment on the minimap in grid coordinates.
-- color is {r, g, b, a} with each channel 0-255.
minimap:drawLine(0, 0, 32, 32, {255, 128, 0, 255})   -- orange diagonal (e.g. trade route)
minimap:drawLine(10, 5, 54, 5,  {255,   0, 0, 200})   -- red horizontal border

-- drawRect(x, y, w, h, color)
-- Draw a filled-border rectangle overlay in grid coordinates.
minimap:drawRect(20, 20, 10, 8, {0, 200, 255, 180})  -- teal territory highlight

-- clearOverlay()  — remove all custom geometry
minimap:clearOverlay()

-- ── Path Visualization ────────────────────────────────────────────────────────

-- showPath(points, color) → path_id
-- Display a pathfinding route as a connected polyline.
-- points is a table of {x, y} pairs in grid coordinates.
-- Returns a unique integer ID so you can remove this specific path later.
local patrol_path = minimap:showPath(
    {{5, 5}, {15, 5}, {15, 20}, {5, 20}, {5, 5}},
    {255, 255, 0, 200}   -- yellow patrol loop
)

local attack_path = minimap:showPath(
    {{32, 32}, {40, 25}, {55, 10}},
    {255, 50, 50, 220}   -- red attack vector
)

-- clearPath()         — remove all paths
-- clearPath(path_id)  — remove a specific path by its ID
minimap:clearPath(attack_path)  -- remove only the attack vector
minimap:clearPath()             -- remove all remaining paths

-- ── Multi-Layer Minimap ───────────────────────────────────────────────────────

-- setLayer(index) / getLayer() → index
-- Switch which layer the minimap renders (0 = surface, 1 = underground, 2 = sky…)
minimap:setLayer(0)              -- surface
local current_layer = minimap:getLayer()  -- 0

minimap:setLayer(1)              -- switch to underground layer
-- getLayer() → 1

-- setLayerData(layer_index, data)
-- Store a flat 1-based table of terrain type IDs for a given layer.
-- The data length should equal gridW × gridH (same as the main terrain grid).
local underground_terrain = {}
for i = 1, 64*64 do
    underground_terrain[i] = (i % 3 == 0) and 3 or 0   -- stone and grass mix
end
minimap:setLayerData(1, underground_terrain)  -- store underground tile data

-- Switch back to surface for normal rendering
minimap:setLayer(0)

-- ── Marker Animation ─────────────────────────────────────────────────────────

-- setMarkerAnimation(id, anim_type, speed)
-- Attach an animation to an existing marker.
--   anim_type: "blink" | "pulse" | "rotate"
--   speed:     cycles/s for blink/pulse; radians/s for rotate
local quest_marker = minimap:addMarker(45, 22, "Quest: Lost Artefact")
local alert_marker = minimap:addMarker(10, 55, "Danger!")
local boss_marker  = minimap:addMarker(32, 32, "Boss room")

minimap:setMarkerAnimation(quest_marker, "pulse",  1.5)   -- slow peaceful pulse
minimap:setMarkerAnimation(alert_marker, "blink",  4.0)   -- fast urgent blink
minimap:setMarkerAnimation(boss_marker,  "rotate", 2.0)   -- spinning skull icon

-- clearMarkerAnimation(id)  — revert marker to static
minimap:clearMarkerAnimation(alert_marker)

-- Animations are advanced automatically by update(dt):
minimap:update(0.016)  -- call once per frame with the frame delta time

