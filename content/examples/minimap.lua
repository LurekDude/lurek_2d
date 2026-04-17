-- content/examples/minimap.lua
-- Lurek2D lurek.minimap API Reference
-- Run with: cargo run -- content/examples/minimap
--
-- Scenario: A top-down dungeon crawler with a corner minimap showing the player's
-- explored rooms, fog of war, quest markers, enemy dots, and a viewport rectangle
-- indicating the camera frustum on the world map.

print("=== lurek.minimap — Dungeon Crawler Minimap ===\n")

-- =============================================================================
-- Minimap Creation
-- =============================================================================

-- ---- Stub: lurek.minimap.newMinimap ---------------------------------------
--@api-stub: lurek.minimap.newMinimap
-- Create a minimap for a 20x15 tile dungeon. Each cell is either wall or floor.
local mm = lurek.minimap.newMinimap({ width = 20, height = 15, cell_size = 8 })
print("minimap created: 20x15 grid, 8px cells")

-- =============================================================================
-- Grid & Display Dimensions (Minimap class methods — use colon syntax)
-- =============================================================================

-- ---- Stub: Minimap:getGridWidth -------------------------------------------
--@api-stub: Minimap:getGridWidth
print("grid width: " .. tostring(mm:getGridWidth()) .. " cells")

-- ---- Stub: Minimap:getGridHeight ------------------------------------------
--@api-stub: Minimap:getGridHeight
print("grid height: " .. tostring(mm:getGridHeight()) .. " cells")

-- ---- Stub: Minimap:getGridSize --------------------------------------------
--@api-stub: Minimap:getGridSize
local gw, gh = mm:getGridSize()
print("grid size: " .. gw .. "x" .. gh)

-- ---- Stub: Minimap:getDisplayWidth ----------------------------------------
--@api-stub: Minimap:getDisplayWidth
print("display width: " .. tostring(mm:getDisplayWidth()) .. "px")

-- ---- Stub: Minimap:getDisplayHeight ---------------------------------------
--@api-stub: Minimap:getDisplayHeight
print("display height: " .. tostring(mm:getDisplayHeight()) .. "px")

-- ---- Stub: Minimap:getDisplaySize -----------------------------------------
--@api-stub: Minimap:getDisplaySize
local dw, dh = mm:getDisplaySize()
print("display size: " .. dw .. "x" .. dh)

-- ---- Stub: Minimap:setDisplaySize -----------------------------------------
--@api-stub: Minimap:setDisplaySize
-- Set the on-screen pixel dimensions. Place it 160x120 in the top-right corner.
mm:setDisplaySize(160, 120)
print("minimap display: 160x120 pixels")

-- =============================================================================
-- Terrain Data
-- =============================================================================

-- ---- Stub: Minimap:setTerrainData -----------------------------------------
--@api-stub: Minimap:setTerrainData
-- Load terrain types from a flat array for the entire grid.
local terrain_data = {}
for i = 1, 20 * 15 do terrain_data[i] = "stone" end
terrain_data[11 * 20 + 3] = "water"
terrain_data[6 * 20 + 15] = "lava"
mm:setTerrainData(terrain_data)
print("terrain data loaded: mostly stone, one water, one lava cell")

-- ---- Stub: Minimap:getTerrain ---------------------------------------------
--@api-stub: Minimap:getTerrain
local terrain = mm:getTerrain(10, 7)
print("terrain at (10,7): " .. tostring(terrain))

-- ---- Stub: Minimap:getTerrainColor ----------------------------------------
--@api-stub: Minimap:getTerrainColor
local tcr, tcg, tcb = mm:getTerrainColor("stone")
print("stone color: (" .. tostring(tcr) .. ", " .. tostring(tcg) .. ", " .. tostring(tcb) .. ")")

-- ---- Stub: Minimap:getTileDescription -------------------------------------
--@api-stub: Minimap:getTileDescription
local tile_desc = mm:getTileDescription(10, 7)
print("tile (10,7): " .. tostring(tile_desc))

-- =============================================================================
-- Fog of War — reveal rooms as the player explores
-- =============================================================================

-- ---- Stub: Minimap:setFogEnabled ------------------------------------------
--@api-stub: Minimap:setFogEnabled
mm:setFogEnabled(true)
print("fog of war enabled — unexplored areas hidden")

-- ---- Stub: Minimap:isFogEnabled -------------------------------------------
--@api-stub: Minimap:isFogEnabled
print("fog enabled: " .. tostring(mm:isFogEnabled()))

-- ---- Stub: Minimap:setFogLevel --------------------------------------------
--@api-stub: Minimap:setFogLevel
-- Fog level 0.0=clear, 1.0=fully obscured. 0.5 = "visited but not visible" dim.
mm:setFogLevel(0.5)
print("fog level: 0.5 (visited areas shown dimly)")

-- ---- Stub: Minimap:getFogLevel --------------------------------------------
--@api-stub: Minimap:getFogLevel
print("fog level: " .. tostring(mm:getFogLevel()))

-- ---- Stub: Minimap:getFogColor --------------------------------------------
--@api-stub: Minimap:getFogColor
local fcr, fcg, fcb, fca = mm:getFogColor()
print("fog color: (" .. fcr .. ", " .. fcg .. ", " .. fcb .. ", " .. fca .. ")")

-- ---- Stub: Minimap:setFogData ---------------------------------------------
--@api-stub: Minimap:setFogData
-- Bulk-load fog state from a saved game. Array of booleans: true=revealed.
local fog_data = {}
for i = 1, 20 * 15 do fog_data[i] = false end
-- Reveal the central room
for x = 8, 12 do for y = 5, 9 do fog_data[(y * 20) + x + 1] = true end end
mm:setFogData(fog_data)
print("fog data loaded from save (central room revealed)")

-- =============================================================================
-- Objects — dynamic entities (enemies, NPCs) on the minimap
-- =============================================================================

-- ---- Stub: Minimap:isObjectTypeVisible ------------------------------------
--@api-stub: Minimap:isObjectTypeVisible
print("enemy type visible: " .. tostring(mm:isObjectTypeVisible("enemy")))

-- ---- Stub: Minimap:getObjectTypeCount -------------------------------------
--@api-stub: Minimap:getObjectTypeCount
print("enemy objects: " .. tostring(mm:getObjectTypeCount("enemy")))

-- ---- Stub: Minimap:getObjectCount -----------------------------------------
--@api-stub: Minimap:getObjectCount
print("total minimap objects: " .. tostring(mm:getObjectCount()))

-- ---- Stub: Minimap:removeObject -------------------------------------------
--@api-stub: Minimap:removeObject
-- Remove a specific dynamic object by ID (e.g. enemy killed).
mm:removeObject("enemy_01")
print("enemy_01 removed from minimap (defeated)")

-- ---- Stub: Minimap:clearObjects -------------------------------------------
--@api-stub: Minimap:clearObjects
-- Clear all dynamic objects when transitioning to a new floor.
mm:clearObjects()
print("all dynamic objects cleared (room transition)")

-- ---- Stub: Minimap:getOwnerColor ------------------------------------------
--@api-stub: Minimap:getOwnerColor
-- Faction ownership color for territory-control minimaps.
local or_, og, ob, oa = mm:getOwnerColor("player")
print("player territory: (" .. tostring(or_) .. ", " .. tostring(og) .. ", " .. tostring(ob) .. ")")

-- =============================================================================
-- Color Mode & Visual Options
-- =============================================================================

-- ---- Stub: Minimap:setColorMode -------------------------------------------
--@api-stub: Minimap:setColorMode
-- "solid" for flat fills, "gradient" for height-based coloring.
mm:setColorMode("solid")
print("color mode: solid fills")

-- ---- Stub: Minimap:getColorMode -------------------------------------------
--@api-stub: Minimap:getColorMode
print("color mode: " .. tostring(mm:getColorMode()))

-- ---- Stub: Minimap:setAntiAlias -------------------------------------------
--@api-stub: Minimap:setAntiAlias
mm:setAntiAlias(true)
print("anti-alias enabled (smoother edges)")

-- ---- Stub: Minimap:isAntiAlias --------------------------------------------
--@api-stub: Minimap:isAntiAlias
print("anti-alias: " .. tostring(mm:isAntiAlias()))

-- =============================================================================
-- Zoom & Pan — camera-like controls on the minimap
-- =============================================================================

-- ---- Stub: Minimap:setZoom ------------------------------------------------
--@api-stub: Minimap:setZoom
mm:setZoom(1.5)
print("minimap zoom: 1.5x (focused on nearby area)")

-- ---- Stub: Minimap:getZoom ------------------------------------------------
--@api-stub: Minimap:getZoom
print("zoom: " .. tostring(mm:getZoom()))

-- ---- Stub: Minimap:setCenter ----------------------------------------------
--@api-stub: Minimap:setCenter
-- Center the view on the player's position.
mm:setCenter(10, 7)
print("minimap centered on player (10, 7)")

-- ---- Stub: Minimap:getCenter ----------------------------------------------
--@api-stub: Minimap:getCenter
local cx, cy = mm:getCenter()
print("center: (" .. tostring(cx) .. ", " .. tostring(cy) .. ")")

-- ---- Stub: Minimap:getCenterX ---------------------------------------------
--@api-stub: Minimap:getCenterX
print("center X: " .. tostring(mm:getCenterX()))

-- ---- Stub: Minimap:getCenterY ---------------------------------------------
--@api-stub: Minimap:getCenterY
print("center Y: " .. tostring(mm:getCenterY()))

-- =============================================================================
-- Viewport Rectangle — shows the camera frustum on the world map
-- =============================================================================

-- ---- Stub: Minimap:setViewportVisible -------------------------------------
--@api-stub: Minimap:setViewportVisible
mm:setViewportVisible(true)
print("viewport rectangle shown on minimap")

-- ---- Stub: Minimap:isViewportVisible --------------------------------------
--@api-stub: Minimap:isViewportVisible
print("viewport visible: " .. tostring(mm:isViewportVisible()))

-- ---- Stub: Minimap:getViewportRect ----------------------------------------
--@api-stub: Minimap:getViewportRect
local vx, vy, vw, vh = mm:getViewportRect()
print("viewport: (" .. tostring(vx) .. "," .. tostring(vy) .. "," .. tostring(vw) .. "," .. tostring(vh) .. ")")

-- ---- Stub: Minimap:getViewportColor ---------------------------------------
--@api-stub: Minimap:getViewportColor
local vr, vg, vb, va = mm:getViewportColor()
print("viewport color: (" .. tostring(vr) .. ", " .. tostring(vg) .. ", " .. tostring(vb) .. ")")

-- ---- Stub: Minimap:clearViewportRect --------------------------------------
--@api-stub: Minimap:clearViewportRect
mm:clearViewportRect()
print("viewport rectangle cleared")

-- =============================================================================
-- Pings — player communication signals
-- =============================================================================

-- ---- Stub: Minimap:getPingCount -------------------------------------------
--@api-stub: Minimap:getPingCount
print("active pings: " .. tostring(mm:getPingCount()))

-- =============================================================================
-- Markers — quest icons, enemies, items on the minimap
-- =============================================================================

-- ---- Stub: Minimap:removeMarker -------------------------------------------
--@api-stub: Minimap:removeMarker
-- Place a marker then remove it to demonstrate the lifecycle.
mm:removeMarker("treasure")
print("treasure marker removed (chest already looted)")

-- ---- Stub: Minimap:hasMarker ----------------------------------------------
--@api-stub: Minimap:hasMarker
print("has 'boss_room' marker: " .. tostring(mm:hasMarker("boss_room")))

-- ---- Stub: Minimap:getMarkerDescription -----------------------------------
--@api-stub: Minimap:getMarkerDescription
local desc = mm:getMarkerDescription("boss_room")
print("boss marker description: " .. tostring(desc))

-- ---- Stub: Minimap:getMarkerCount ----------------------------------------
--@api-stub: Minimap:getMarkerCount
print("active markers: " .. tostring(mm:getMarkerCount()))

-- ---- Stub: Minimap:clearMarkerAnimation -----------------------------------
--@api-stub: Minimap:clearMarkerAnimation
mm:clearMarkerAnimation()
print("marker animations cleared (no more pulsing)")

-- =============================================================================
-- Layers & Overlays
-- =============================================================================

-- ---- Stub: Minimap:setLayer -----------------------------------------------
--@api-stub: Minimap:setLayer
-- Switch between minimap layers (base terrain, objects, fog, overlays).
mm:setLayer(0)
print("active layer: 0 (base terrain)")

-- ---- Stub: Minimap:getLayer -----------------------------------------------
--@api-stub: Minimap:getLayer
print("layer: " .. tostring(mm:getLayer()))

-- ---- Stub: Minimap:clearOverlay -------------------------------------------
--@api-stub: Minimap:clearOverlay
mm:clearOverlay()
print("overlay layer cleared")

-- ---- Stub: Minimap:clearPath ----------------------------------------------
--@api-stub: Minimap:clearPath
-- Clear any drawn path lines (e.g. quest navigation breadcrumb trail).
mm:clearPath()
print("navigation path cleared")

-- =============================================================================
-- Clickable & Interactive Minimap
-- =============================================================================

-- ---- Stub: Minimap:setClickable -------------------------------------------
--@api-stub: Minimap:setClickable
-- Allow clicking on the minimap to set waypoints or ping locations.
mm:setClickable(true)
print("minimap clickable (click to set waypoint)")

-- ---- Stub: Minimap:isClickable --------------------------------------------
--@api-stub: Minimap:isClickable
print("clickable: " .. tostring(mm:isClickable()))

-- =============================================================================
-- Update & Render
-- =============================================================================

-- ---- Stub: Minimap:update -------------------------------------------------
--@api-stub: Minimap:update
-- Call every frame to update animations, pings, fog transitions.
mm:update(0.016)
print("minimap updated (16ms frame)")

-- ---- Stub: Minimap:type ---------------------------------------------------
--@api-stub: Minimap:type
-- ---- Stub: Minimap:typeOf -------------------------------------------------
--@api-stub: Minimap:typeOf
print("minimap type: " .. tostring(mm:type()))
print("minimap typeOf: " .. tostring(mm:typeOf("Minimap")))

-- ---- Stub: Minimap:render -------------------------------------------------
--@api-stub: Minimap:render
-- Draw the minimap directly. Call inside lurek.render_ui() callback.
mm:render()
print("minimap rendered to screen")

-- ---- Stub: Minimap:drawToImage --------------------------------------------
--@api-stub: Minimap:drawToImage
-- Export the minimap as a full image for save-game thumbnails.
mm:drawToImage("output/dungeon_map.png")
print("minimap exported to output/dungeon_map.png")

print("\n-- minimap.lua example complete --")
