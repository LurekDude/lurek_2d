-- content/examples/minimap.lua
-- lurek.minimap API examples.
-- Run: cargo run -- content/examples/minimap.lua

--@api-stub: lurek.minimap.newMinimap
-- Creates a minimap with grid dimensions and optional display size
do
  -- newMinimap(grid_w, grid_h [, display_w, display_h]) -> LMinimap
  -- grid_w/grid_h: number of logical cells in the minimap grid (the world you represent)
  -- display_w/display_h: pixel size on screen (defaults to 200x200 if omitted)

  -- RPG world map: 64x48 cells shown in a 256x192 pixel HUD corner widget
  local world_map = lurek.minimap.newMinimap(64, 48, 256, 192)
  world_map:setTerrain(1, 1, 1)

  -- Small radar: omit display size to use the 200x200 default
  local radar = lurek.minimap.newMinimap(32, 32)

  lurek.log.info("world grid " .. world_map:getGridWidth() .. "x" .. world_map:getGridHeight(), "minimap")
  lurek.log.info("radar grid " .. radar:getGridWidth() .. "x" .. radar:getGridHeight(), "minimap")
end

-- Minimap methods

--@api-stub: LMinimap:getGridWidth
-- Returns the grid width of this minimap.
do
  -- Use getGridWidth() to iterate over the x axis of the grid.
  -- Scenario: paint a border row of "wall" terrain along the top edge.
  local mm = lurek.minimap.newMinimap(80, 60)
  local w = mm:getGridWidth()
  for x = 1, w do
    -- Terrain type 2 = wall (you define what each type means via setTerrainColor)
    mm:setTerrain(x, 1, 2)
  end
end

--@api-stub: LMinimap:getGridHeight
-- Returns the grid height of this minimap.
do
  -- Use getGridHeight() to iterate over the y axis.
  -- Scenario: paint a river along the left column of the map.
  local mm = lurek.minimap.newMinimap(80, 60)
  local h = mm:getGridHeight()
  for y = 1, h do
    mm:setTerrain(1, y, 3) -- type 3 = water
  end
end

--@api-stub: LMinimap:getGridSize
-- Returns the grid size of this minimap.
do
  -- getGridSize() returns both dimensions at once — handy for area calculations.
  -- Scenario: log total tile count for a procedural dungeon.
  local mm = lurek.minimap.newMinimap(48, 32)
  local gw, gh = mm:getGridSize()
  lurek.log.info("dungeon has " .. (gw * gh) .. " tiles to fill", "minimap")
end

--@api-stub: LMinimap:getDisplayWidth
-- Returns the display width of this minimap.
do
  -- getDisplayWidth() returns the pixel width on screen.
  -- Scenario: position a HUD label to the right of the minimap.
  local mm = lurek.minimap.newMinimap(32, 32, 240, 180)
  local px = mm:getDisplayWidth()
  -- Place a text label 8 pixels to the right of the minimap at x=16
  local label_x = 16 + px + 8
  lurek.log.info("label goes at x=" .. label_x, "ui")
end

--@api-stub: LMinimap:getDisplayHeight
-- Returns the display height of this minimap.
do
  -- getDisplayHeight() returns the pixel height on screen.
  -- Scenario: calculate whether the minimap fits above a chat window.
  local mm = lurek.minimap.newMinimap(32, 32, 240, 180)
  local py = mm:getDisplayHeight()
  local screen_h = 720
  local chat_h = 200
  local fits = (py + chat_h) <= screen_h
  lurek.log.info("minimap fits above chat: " .. tostring(fits), "ui")
end

--@api-stub: LMinimap:getDisplaySize
-- Returns the display size of this minimap.
do
  -- getDisplaySize() returns both width and height in pixels.
  -- Scenario: find the center pixel of the minimap for drawing a crosshair overlay.
  local mm = lurek.minimap.newMinimap(40, 30, 200, 150)
  local dw, dh = mm:getDisplaySize()
  local center_px_x, center_px_y = dw * 0.5, dh * 0.5
  lurek.log.info("minimap center pixel: " .. center_px_x .. "," .. center_px_y, "minimap")
end

--@api-stub: LMinimap:setDisplaySize
-- Sets the display size of this minimap.
do
  -- setDisplaySize(w, h) changes the on-screen pixel size at runtime.
  -- Scenario: player opens "expanded map" view — scale the minimap up.
  local mm = lurek.minimap.newMinimap(64, 64)
  -- Start small in the HUD corner
  mm:setDisplaySize(160, 160)
  -- Player presses Tab — expand to fill more of the screen
  mm:setDisplaySize(480, 480)
  local w, h = mm:getDisplaySize()
  lurek.log.info("expanded minimap to " .. w .. "x" .. h, "ui")
end

--@api-stub: LMinimap:getTerrain
-- Returns the terrain of this minimap.
do
  -- getTerrain(x, y) returns the terrain type id at a grid cell.
  -- Scenario: RPG tooltip — show terrain name when player hovers a cell.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setTerrain(4, 4, 7) -- type 7 = forest
  local t = mm:getTerrain(4, 4)
  -- Map terrain type to a name for UI display
  local names = { [0] = "void", [1] = "grass", [7] = "forest" }
  lurek.log.info("tile at 4,4: " .. (names[t] or "unknown"), "minimap")
end

--@api-stub: LMinimap:setTerrainData
-- Sets the terrain data of this minimap.
do
  -- setTerrainData(data) replaces ALL cells from a flat array (row-major order).
  -- Length must equal grid_w * grid_h. First grid_w entries are row 1, etc.
  -- Scenario: load a pre-built dungeon map from level data.
  local mm = lurek.minimap.newMinimap(4, 3)
  -- 4 columns x 3 rows = 12 cells
  -- Layout:  row1: wall wall floor floor
  --          row2: wall door  door  floor
  --          row3: void door  door  void
  local level = { 1,1,2,2, 1,3,3,2, 0,3,3,0 }
  mm:setTerrainData(level)
  lurek.log.info("loaded " .. #level .. " cells of dungeon data", "minimap")
end

--@api-stub: LMinimap:getTerrainColor
-- Returns the terrain color of this minimap.
do
  -- getTerrainColor(type) returns r, g, b, a for a registered terrain type.
  -- Scenario: verify colour assignments in a debug panel.
  local mm = lurek.minimap.newMinimap(8, 8)
  mm:setTerrainColor(2, 0.2, 0.6, 0.1, 1.0) -- type 2 = forest green
  local r, g, b, a = mm:getTerrainColor(2)
  lurek.log.info("forest swatch: rgba(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "ui")
end

--@api-stub: LMinimap:getTileDescription
-- Returns the tile description of this minimap.
do
  -- getTileDescription(type_id) returns the string description, or nil if unset.
  -- Scenario: show a tooltip when mouse hovers a tile type.
  local mm = lurek.minimap.newMinimap(8, 8)
  mm:setTileDescription(3, "Dense forest, slows movement by 50%")
  local desc = mm:getTileDescription(3)
  if desc then
    lurek.log.info("tooltip: " .. desc, "ui")
  end
end

--@api-stub: LMinimap:setFogEnabled
-- Sets whether fog of war is enabled on this minimap.
do
  -- setFogEnabled(bool) turns fog of war on or off.
  -- When enabled, cells default to fully fogged (level 0) until revealed.
  -- Scenario: dungeon crawler — enable fog at game start.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setFogEnabled(true)
  -- All cells are now hidden until the player explores them
  if mm:isFogEnabled() then
    lurek.log.info("fog of war active — dungeon unexplored", "minimap")
  end
end

--@api-stub: LMinimap:isFogEnabled
-- Returns true if fog of war is currently enabled.
do
  -- isFogEnabled() checks if fog is active. Use to gate fog-related logic.
  -- Scenario: creative mode toggle — disable fog in sandbox.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setFogEnabled(false)
  if not mm:isFogEnabled() then
    -- In creative mode, all tiles are always visible
    mm:setTerrain(1, 1, 9)
    lurek.log.info("creative mode: full map visibility", "minimap")
  end
end

--@api-stub: LMinimap:setFogLevel
-- Sets the fog level for a specific grid cell.
do
  -- setFogLevel(x, y, level) sets visibility per cell.
  -- Level 0 = fully fogged (hidden), 1 = explored but not visible, 2 = fully visible.
  -- Scenario: RTS scout reveals a corridor.
  local mm = lurek.minimap.newMinimap(20, 20)
  mm:setFogEnabled(true)
  -- Scout moves through cells (4,5) to (8,5) — mark them visible
  for x = 4, 8 do
    mm:setFogLevel(x, 5, 2) -- fully revealed
  end
  -- Cells the scout left behind fade to "explored" (greyed out but mapped)
  mm:setFogLevel(4, 5, 1)
  mm:setFogLevel(5, 5, 1)
end

--@api-stub: LMinimap:getFogLevel
-- Returns the fog level for a specific grid cell.
do
  -- getFogLevel(x, y) returns 0 (fogged), 1 (explored), or 2 (visible).
  -- Scenario: AI checks if a cell is visible before spawning a surprise enemy.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setFogEnabled(true)
  mm:setFogLevel(8, 8, 2) -- player can see this cell
  local level = mm:getFogLevel(8, 8)
  if level == 2 then
    lurek.log.info("player can see cell 8,8 — no ambush here", "fog")
  elseif level == 0 then
    lurek.log.info("cell 8,8 is hidden — safe to spawn enemy", "fog")
  end
end

--@api-stub: LMinimap:getFogColor
-- Returns the fog color used when rendering fogged cells.
do
  -- getFogColor() returns r, g, b, a of the fog overlay.
  -- Scenario: read current fog colour to display in a settings menu.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setFogColor(0.05, 0.05, 0.1, 0.85) -- dark blueish fog
  local r, g, b, a = mm:getFogColor()
  lurek.log.info("fog rgba: " .. r .. "," .. g .. "," .. b .. "," .. a, "fog")
end

--@api-stub: LMinimap:setFogData
-- Sets all fog levels from a flat array (row-major, like setTerrainData).
do
  -- setFogData(data) bulk-sets fog for every cell at once.
  -- Useful for loading saved exploration state from a save file.
  -- Scenario: restore fog state when player loads a saved game.
  local mm = lurek.minimap.newMinimap(4, 3)
  mm:setFogEnabled(true)
  -- Saved state: top row visible, middle partially explored, bottom fogged
  local saved_fog = { 2,2,1,0, 2,2,1,0, 1,1,1,0 }
  mm:setFogData(saved_fog)
  lurek.log.info("fog state restored from save", "minimap")
end

--@api-stub: LMinimap:isObjectTypeVisible
-- Returns true if the given object type is currently visible on the minimap.
do
  -- isObjectTypeVisible(type_idx) checks draw visibility per type.
  -- Scenario: HUD toggle button — check if enemies are shown.
  local mm = lurek.minimap.newMinimap(20, 20)
  local enemy = mm:addObjectType("enemy", 1, 0.1, 0.1, 1)
  if mm:isObjectTypeVisible(enemy) then
    lurek.log.info("enemy markers visible on radar", "minimap")
  end
end

--@api-stub: LMinimap:getObjectTypeCount
-- Returns the number of registered object types.
do
  -- getObjectTypeCount() returns how many types have been registered with addObjectType.
  -- Scenario: validate that all expected unit categories are registered.
  local mm = lurek.minimap.newMinimap(20, 20)
  mm:addObjectType("ally", 0.2, 0.6, 1, 1)   -- blue dots
  mm:addObjectType("enemy", 1, 0.2, 0.2, 1)  -- red dots
  mm:addObjectType("neutral", 0.8, 0.8, 0.8, 1) -- grey dots
  lurek.log.info("registered " .. mm:getObjectTypeCount() .. " object types", "minimap")
end

--@api-stub: LMinimap:removeObject
-- Removes a tracked object from this minimap by its id.
do
  -- removeObject(id) removes a specific tracked object. Returns true if found.
  -- Scenario: player picks up loot — remove its minimap blip.
  local mm = lurek.minimap.newMinimap(20, 20)
  local loot_type = mm:addObjectType("loot", 1, 1, 0, 1) -- yellow dots
  mm:setObject(101, 5, 5, loot_type) -- loot item at grid position (5,5)
  -- Player walks over it and picks it up:
  local removed = mm:removeObject(101)
  if removed then
    lurek.log.info("loot #101 collected — removed from minimap", "minimap")
  end
end

--@api-stub: LMinimap:clearObjects
-- Clears all tracked objects from this minimap.
do
  -- clearObjects() removes every object at once.
  -- Scenario: wave-based game — clear all enemy blips between waves.
  local mm = lurek.minimap.newMinimap(20, 20)
  local npc = mm:addObjectType("npc", 0, 1, 0, 1)
  mm:setObject(1, 4, 4, npc)
  mm:setObject(2, 9, 9, npc)
  -- Wave complete — remove all tracked units before spawning new wave
  mm:clearObjects()
  lurek.log.info("objects after wave clear: " .. mm:getObjectCount(), "minimap")
end

--@api-stub: LMinimap:getObjectCount
-- Returns the number of tracked objects on this minimap.
do
  -- getObjectCount() returns the total number of objects currently placed.
  -- Scenario: display "5 enemies remaining" from minimap state.
  local mm = lurek.minimap.newMinimap(16, 16)
  local rat = mm:addObjectType("rat", 0.6, 0.4, 0.2, 1)
  for i = 1, 5 do
    mm:setObject(i, i * 2, i * 2, rat)
  end
  lurek.log.info("tracked objects: " .. mm:getObjectCount(), "minimap")
end

--@api-stub: LMinimap:getOwnerColor
-- Returns the RGBA color assigned to an owner id.
do
  -- getOwnerColor(owner) returns r, g, b, a for a team/faction colour.
  -- Scenario: RTS — display faction colour in a diplomacy screen.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setOwnerColor(2, 0.1, 0.4, 0.9, 1) -- team 2 = blue
  local r, g, b, a = mm:getOwnerColor(2)
  lurek.log.info("team 2 colour: rgba(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "team")
end

--@api-stub: LMinimap:setColorMode
-- Sets the color mode used for rendering terrain cells.
do
  -- setColorMode(mode) switches between "terrain" (natural colours) and "political" (owner-based).
  -- Scenario: strategy game map mode selector.
  local mm = lurek.minimap.newMinimap(20, 20)
  -- "terrain" mode: cells coloured by terrain type (grass, water, mountain)
  -- "political" mode: cells coloured by owning faction
  mm:setColorMode("political")
  lurek.log.info("map mode: " .. mm:getColorMode(), "minimap")
end

--@api-stub: LMinimap:getColorMode
-- Returns the current color mode of this minimap.
do
  -- getColorMode() returns "terrain" or "political".
  -- Scenario: toggle logic — switch mode based on current state.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setColorMode("terrain")
  if mm:getColorMode() == "terrain" then
    -- In terrain mode, make sure terrain colours are configured
    mm:setTerrainColor(1, 0.3, 0.5, 0.2, 1) -- grass green
  end
end

--@api-stub: LMinimap:setZoom
-- Sets the zoom level of this minimap.
do
  -- setZoom(factor) magnifies the minimap view.
  -- 1.0 = show entire grid, >1.0 = zoomed in (shows fewer cells, larger).
  -- Scenario: player scrolls mousewheel over minimap to zoom in/out.
  local mm = lurek.minimap.newMinimap(64, 64)
  mm:setZoom(2.5) -- zoom in — show only a portion of the 64x64 grid
  lurek.log.info("zoom level: " .. mm:getZoom(), "minimap")
end

--@api-stub: LMinimap:getZoom
-- Returns the current zoom level.
do
  -- getZoom() returns the current magnification factor.
  -- Scenario: calculate effective cell pixel size for hit-testing.
  local mm = lurek.minimap.newMinimap(48, 48, 240, 240)
  mm:setZoom(1.5)
  -- Each cell is (display_w / grid_w) * zoom pixels wide
  local cell_px = (mm:getDisplayWidth() / mm:getGridWidth()) * mm:getZoom()
  lurek.log.info("effective cell size: " .. cell_px .. " px", "minimap")
end

--@api-stub: LMinimap:setCenter
-- Sets the world center point of this minimap's view.
do
  -- setCenter(x, y) pans the minimap view to center on grid coordinates.
  -- When zoomed in, this controls which part of the world is visible.
  -- Scenario: follow the player character on the map.
  local mm = lurek.minimap.newMinimap(128, 128, 200, 200)
  mm:setZoom(3.0) -- zoomed in, only showing a small area
  local player = { x = 64, y = 32 }
  -- Center the minimap on the player each frame
  mm:setCenter(player.x, player.y)
end

--@api-stub: LMinimap:getCenter
-- Returns the current center point of this minimap's view.
do
  -- getCenter() returns x, y of the current view center.
  -- Scenario: calculate distance between minimap center and a point of interest.
  local mm = lurek.minimap.newMinimap(64, 64)
  mm:setCenter(20.5, 35.0)
  local cx, cy = mm:getCenter()
  lurek.log.info("view centered at " .. cx .. "," .. cy, "minimap")
end

--@api-stub: LMinimap:getCenterX
-- Returns the x coordinate of the minimap's view center.
do
  -- getCenterX() returns just the x component. Useful for single-axis clamping.
  -- Scenario: prevent the minimap from scrolling past the right edge.
  local mm = lurek.minimap.newMinimap(64, 64)
  mm:setCenter(40, 20)
  local max_x = mm:getGridWidth() - 10
  if mm:getCenterX() > max_x then
    mm:setCenter(max_x, mm:getCenterY())
  end
end

--@api-stub: LMinimap:getCenterY
-- Returns the y coordinate of the minimap's view center.
do
  -- getCenterY() returns just the y component.
  -- Scenario: clamp vertical scroll to prevent showing empty space below the map.
  local mm = lurek.minimap.newMinimap(64, 48)
  mm:setCenter(10, 50) -- 50 > grid height of 48, would show void
  local max_y = mm:getGridHeight() - 5
  local cy = math.min(mm:getCenterY(), max_y)
  mm:setCenter(mm:getCenterX(), cy)
end

--@api-stub: LMinimap:clearViewportRect
-- Clears the viewport rectangle overlay from this minimap.
do
  -- clearViewportRect() removes the camera rectangle indicator.
  -- Scenario: hide the viewport rect when player is in fullscreen map mode.
  local mm = lurek.minimap.newMinimap(80, 60)
  mm:setViewportRect(10, 10, 20, 15)
  -- Player opens fullscreen map — no need to show "where camera is"
  mm:clearViewportRect()
  local x = mm:getViewportRect()
  if x == nil then
    lurek.log.info("viewport rect hidden in fullscreen mode", "minimap")
  end
end

--@api-stub: LMinimap:getViewportRect
-- Returns the viewport rectangle (x, y, w, h) or nil if not set.
do
  -- getViewportRect() returns x, y, w, h of the camera's visible area on the minimap.
  -- Returns nil values when no viewport rect is set.
  -- Scenario: draw a custom border around the viewport rect for style.
  local mm = lurek.minimap.newMinimap(80, 60)
  mm:setViewportRect(5, 8, 16, 12)
  local x, y, w, h = mm:getViewportRect()
  if x then
    lurek.log.info("camera sees grid region: " .. x .. "," .. y .. " size " .. w .. "x" .. h, "minimap")
  end
end

--@api-stub: LMinimap:setViewportVisible
-- Sets whether the viewport rectangle overlay is drawn.
do
  -- setViewportVisible(bool) toggles the camera rect overlay without removing it.
  -- Scenario: hide viewport rect during cutscenes, show it again after.
  local mm = lurek.minimap.newMinimap(80, 60)
  mm:setViewportRect(0, 0, 24, 18)
  -- Cutscene starts — hide the viewport indicator
  mm:setViewportVisible(false)
  -- Cutscene ends — show it again (rect data is preserved)
  mm:setViewportVisible(true)
end

--@api-stub: LMinimap:isViewportVisible
-- Returns true if the viewport rectangle overlay is visible.
do
  -- isViewportVisible() returns the visibility state of the viewport rect.
  -- Scenario: toggle button state in settings UI.
  local mm = lurek.minimap.newMinimap(80, 60)
  mm:setViewportRect(0, 0, 16, 12)
  if mm:isViewportVisible() then
    lurek.log.info("viewport overlay is drawn on minimap", "minimap")
  end
end

--@api-stub: LMinimap:getViewportColor
-- Returns the RGBA color of the viewport rectangle overlay.
do
  -- getViewportColor() returns r, g, b, a for the camera rect border.
  -- Scenario: match viewport colour to current UI theme.
  local mm = lurek.minimap.newMinimap(40, 30)
  mm:setViewportColor(1, 1, 1, 0.6) -- white, semi-transparent
  local r, g, b, a = mm:getViewportColor()
  lurek.log.info("viewport colour: rgba(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "ui")
end

--@api-stub: LMinimap:getPingCount
-- Returns the number of active ping effects on this minimap.
do
  -- getPingCount() returns how many pings are currently animating.
  -- Pings fade out over their duration and are auto-removed when finished.
  -- Scenario: limit ping spam — only allow 3 simultaneous pings.
  local mm = lurek.minimap.newMinimap(40, 30)
  mm:addPing(10, 10, 1.5) -- default yellow ping, 1.5 second duration
  mm:addPing(20, 15, 1.5, 0.2, 1, 0.4, 1) -- custom green ping
  local count = mm:getPingCount()
  if count < 3 then
    lurek.log.info("can add more pings (current: " .. count .. ")", "minimap")
  end
end

--@api-stub: LMinimap:removeMarker
-- Removes a marker from this minimap by its id.
do
  -- removeMarker(id) deletes a marker. Returns true if it existed.
  -- Scenario: quest complete — remove the quest marker from the map.
  local mm = lurek.minimap.newMinimap(40, 30)
  local quest_id = mm:addMarker(5, 5, "Deliver the package")
  -- Player completes the quest:
  if mm:removeMarker(quest_id) then
    lurek.log.info("quest marker " .. quest_id .. " cleared", "minimap")
  end
end

--@api-stub: LMinimap:hasMarker
-- Returns true if a marker with the given id exists.
do
  -- hasMarker(id) checks existence before performing operations on a marker.
  -- Scenario: only animate a marker if it still exists (quest not yet complete).
  local mm = lurek.minimap.newMinimap(40, 30)
  local id = mm:addMarker(8, 6, "Ally HQ")
  if mm:hasMarker(id) then
    -- Marker still active — add a pulse animation to draw attention
    mm:setMarkerAnimation(id, "pulse", 1.5)
  end
end

--@api-stub: LMinimap:getMarkerDescription
-- Returns the description text of a marker, or nil.
do
  -- getMarkerDescription(id) returns the string passed to addMarker.
  -- Scenario: show marker label in a tooltip when hovered.
  local mm = lurek.minimap.newMinimap(40, 30)
  local id = mm:addMarker(12, 9, "Hidden treasure cache")
  local desc = mm:getMarkerDescription(id)
  if desc then
    lurek.log.info("hovering marker: " .. desc, "minimap")
  end
end

--@api-stub: LMinimap:getMarkerCount
-- Returns the total number of markers placed on this minimap.
do
  -- getMarkerCount() returns how many markers exist.
  -- Scenario: show "3 points of interest" in a quest tracker.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:addMarker(2, 2, "Cave entrance")
  mm:addMarker(8, 4, "Merchant")
  mm:addMarker(14, 7, "Boss arena")
  lurek.log.info("points of interest: " .. mm:getMarkerCount(), "minimap")
end

--@api-stub: LMinimap:clearMarkerAnimation
-- Clears the animation on a marker by its id.
do
  -- clearMarkerAnimation(id) stops any active animation on the marker.
  -- Scenario: stop blinking a "danger" marker once the threat is neutralized.
  local mm = lurek.minimap.newMinimap(32, 32)
  local id = mm:addMarker(4, 4, "Boss location")
  mm:setMarkerAnimation(id, "blink", 4.0)
  -- Boss defeated — stop the blinking
  mm:clearMarkerAnimation(id)
end

--@api-stub: LMinimap:clearOverlay
-- Clears all drawn overlay shapes (lines, rectangles).
do
  -- clearOverlay() removes every overlay shape at once.
  -- Scenario: redraw overlay fresh each frame instead of accumulating shapes.
  local mm = lurek.minimap.newMinimap(40, 30)
  mm:drawLine(0, 0, 40, 30, { 255, 255, 0, 255 })  -- diagonal line
  mm:drawRect(5, 5, 10, 8, { 0, 200, 255, 180 })   -- highlight zone
  -- Next frame: clear and redraw with updated positions
  mm:clearOverlay()
end

--@api-stub: LMinimap:clearPath
-- Clears a specific path by id, or all paths if no id is given.
do
  -- clearPath(id) removes one path; clearPath() with no arg removes all paths.
  -- Scenario: player reaches the next waypoint — remove the old navigation path.
  local mm = lurek.minimap.newMinimap(40, 30)
  local path_id = mm:showPath({ {2,2}, {6,4}, {10,8} }, { 0, 255, 0, 200 })
  -- Player reached waypoint — clear this specific path
  mm:clearPath(path_id)
end

--@api-stub: LMinimap:setLayer
-- Sets the active display layer of this minimap.
do
  -- setLayer(index) switches which layer's terrain data is rendered.
  -- Layers are useful for multi-floor dungeons or underground/overworld views.
  -- Scenario: player enters a dungeon — switch from overworld (layer 0) to dungeon (layer 1).
  local mm = lurek.minimap.newMinimap(8, 4)
  -- Pre-populate layer 1 with dungeon data
  mm:setLayerData(1, { 1,1,2,2,1,1,2,2, 0,1,1,2,0,1,1,2, 0,0,1,1,0,0,1,1, 0,0,0,1,0,0,0,1 })
  -- Player steps on a staircase — switch to dungeon layer
  mm:setLayer(1)
end

--@api-stub: LMinimap:getLayer
-- Returns the currently active layer index.
do
  -- getLayer() returns which layer is being displayed.
  -- Scenario: display "Floor B2" text based on current layer.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setLayer(2)
  local floor_names = { [0] = "Overworld", [1] = "Floor B1", [2] = "Floor B2" }
  lurek.log.info("current: " .. (floor_names[mm:getLayer()] or "unknown"), "minimap")
end

--@api-stub: LMinimap:setAntiAlias
-- Enables or disables anti-aliasing on this minimap.
do
  -- setAntiAlias(bool) controls edge smoothing.
  -- false = crisp pixel-perfect edges (good for pixel art games).
  -- true = smooth edges (good for larger, high-res minimaps).
  -- Scenario: pixel-art retro game disables AA for authentic look.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setAntiAlias(false)
  if not mm:isAntiAlias() then
    lurek.log.info("pixel-perfect minimap rendering", "render")
  end
end

--@api-stub: LMinimap:isAntiAlias
-- Returns true if anti-aliasing is enabled.
do
  -- isAntiAlias() returns current AA state.
  -- Scenario: display AA state in graphics settings menu.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setAntiAlias(true)
  local settings = { antiAlias = mm:isAntiAlias() }
  lurek.log.info("minimap AA=" .. tostring(settings.antiAlias), "settings")
end

--@api-stub: LMinimap:setClickable
-- Enables or disables click interaction on this minimap.
do
  -- setClickable(bool) controls whether the minimap responds to mouse clicks.
  -- When false, clicks pass through to whatever is behind the minimap.
  -- Scenario: disable clicking during a tutorial overlay.
  local mm = lurek.minimap.newMinimap(40, 30)
  mm:setClickable(false) -- lock minimap during tutorial
  if not mm:isClickable() then
    lurek.log.info("minimap input locked (tutorial active)", "ui")
  end
end

--@api-stub: LMinimap:isClickable
-- Returns true if click interaction is enabled.
do
  -- isClickable() returns whether the minimap accepts mouse input.
  -- Scenario: show a "click to ping" hint only when minimap is interactive.
  local mm = lurek.minimap.newMinimap(40, 30)
  mm:setClickable(true)
  if mm:isClickable() then
    mm:addMarker(20, 15, "Click here!")
  end
end

--@api-stub: LMinimap:update
-- Advances minimap animations and timers by delta time.
do
  -- update(dt) must be called each frame to animate pings, marker animations, etc.
  -- Without calling update, pings won't fade out and animations won't play.
  -- Scenario: integrate minimap into the game loop.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:addPing(8, 8, 0.5) -- ping that fades over 0.5 seconds
  function lurek.process(dt)
    -- Advance minimap time — this drives ping fadeout and marker animations
    mm:update(dt)
  end
end

--@api-stub: LMinimap:type
-- Returns the Lua-visible type name string for this minimap handle.
do
  -- type() returns "LMinimap" — the internal type name of the handle.
  -- Scenario: generic widget system that checks type before casting.
  local mm = lurek.minimap.newMinimap(16, 16)
  lurek.log.info("handle type: " .. mm:type(), "ui")
end

--@api-stub: LMinimap:typeOf
-- Returns true if this handle matches the given type name string.
do
  -- typeOf(name) checks against "LMinimap", "Minimap", and "Object".
  -- Scenario: polymorphic UI — check if a widget supports the Object interface.
  local mm = lurek.minimap.newMinimap(16, 16)
  if mm:typeOf("Object") then
    lurek.log.info("minimap supports the Object interface", "ui")
  end
  if mm:typeOf("Minimap") then
    lurek.log.info("confirmed: this is a Minimap", "ui")
  end
end

--@api-stub: LMinimap:render
-- Enqueues render commands to draw the minimap at a screen position.
do
  -- render(x, y) draws the minimap on screen at pixel coordinates.
  -- Call this in lurek.draw() each frame. x, y default to 0, 0 if omitted.
  -- Scenario: draw minimap in the top-right corner of the screen.
  local mm
  function lurek.init()
    mm = lurek.minimap.newMinimap(48, 32, 200, 140)
    mm:setTerrainColor(1, 0.2, 0.5, 0.1, 1)
    mm:setTerrain(1, 1, 1)
  end
  function lurek.draw()
    -- Position at top-right: screen_w - minimap_w - margin
    local screen_w = 1280
    local margin = 16
    mm:render(screen_w - mm:getDisplayWidth() - margin, margin)
  end
end

--@api-stub: LMinimap:drawToImage
-- Renders the minimap into an image data object at a given pixel scale.
do
  -- drawToImage(pixel_size) returns an LImage snapshot of the minimap.
  -- pixel_size controls how many pixels per grid cell (e.g., 8 = 8px per cell).
  -- Scenario: export minimap as a texture for a loading screen background.
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setTerrainColor(1, 0.3, 0.6, 0.2, 1)
  mm:setTerrain(1, 1, 1)
  local img = mm:drawToImage(8) -- 16*8 = 128px wide image
  lurek.log.info("snapshot: " .. img:getWidth() .. "x" .. img:getHeight() .. " px", "minimap")
end

--@api-stub: LMinimap:addMarker
-- Adds a marker at grid coordinates with optional description and color.
do
  -- addMarker(x, y [, desc, r, g, b, a]) -> marker_id
  -- Markers are persistent icons on the minimap (quest goals, POIs, waypoints).
  -- Returns a unique id for later removal or animation.
  -- Scenario: RPG quest system places markers for active objectives.
  local mm = lurek.minimap.newMinimap(64, 64)
  -- Yellow quest marker with description
  local quest_marker = mm:addMarker(20, 30, "Rescue the villager", 1, 1, 0, 1)
  -- Red danger marker (no description)
  local danger_marker = mm:addMarker(45, 12, nil, 1, 0, 0, 1)
  -- Default colour marker (red) with description
  local poi = mm:addMarker(10, 50, "Hidden shop")
  lurek.log.info("placed markers: " .. quest_marker .. ", " .. danger_marker .. ", " .. poi, "minimap")
end

--@api-stub: LMinimap:addObjectType
-- Registers a named object type with a display color.
do
  -- addObjectType(name, r, g, b [, a]) -> type_index (one-based)
  -- Object types define categories (enemy, ally, resource) with a colour dot.
  -- Tracked objects reference a type_index so they share appearance.
  -- Scenario: RTS — register unit categories for the radar.
  local mm = lurek.minimap.newMinimap(32, 32)
  local enemy_idx = mm:addObjectType("enemy", 1, 0, 0, 1)      -- red
  local ally_idx  = mm:addObjectType("ally", 0, 0.5, 1, 1)     -- blue
  local resource_idx = mm:addObjectType("resource", 1, 0.8, 0, 1) -- gold
  lurek.log.info("types registered: " .. mm:getObjectTypeCount(), "minimap")
end

--@api-stub: LMinimap:addPing
-- Adds a timed ping effect that fades out over its duration.
do
  -- addPing(x, y, duration [, r, g, b, a])
  -- Pings are temporary animated effects (expanding circle that fades).
  -- Great for alerting players to events on the map.
  -- Scenario: co-op game — ping where an ally requests help.
  local mm = lurek.minimap.newMinimap(64, 64)
  -- Cyan "help me!" ping lasting 2 seconds
  mm:addPing(32, 32, 2.0, 0, 1, 1, 1)
  -- Default colour ping (yellow) at another location
  mm:addPing(10, 45, 1.5)
  lurek.log.info("active pings: " .. mm:getPingCount(), "minimap")
end

--@api-stub: LMinimap:drawLine
-- Draws an overlay line between two grid points.
do
  -- drawLine(x1, y1, x2, y2, color_tbl)
  -- Overlay shapes are drawn on top of the terrain layer.
  -- color_tbl is {r, g, b, a} with 0..1 float values.
  -- Scenario: draw a border outline around a territory claim.
  local mm = lurek.minimap.newMinimap(32, 32)
  local yellow = {1, 1, 0, 1}
  -- Draw a square border around cells 5,5 to 20,20
  mm:drawLine(5, 5, 20, 5, yellow)   -- top
  mm:drawLine(20, 5, 20, 20, yellow) -- right
  mm:drawLine(20, 20, 5, 20, yellow) -- bottom
  mm:drawLine(5, 20, 5, 5, yellow)   -- left
  lurek.log.info("territory border drawn", "minimap")
end

--@api-stub: LMinimap:drawRect
-- Draws an overlay rectangle at a grid position.
do
  -- drawRect(x, y, w, h, color_tbl)
  -- Draws a filled or semi-transparent rectangle overlay.
  -- Scenario: highlight a danger zone on the minimap.
  local mm = lurek.minimap.newMinimap(32, 32)
  -- Semi-transparent red zone marking an artillery strike area
  local danger_red = {1, 0.2, 0.1, 0.4}
  mm:drawRect(10, 10, 8, 6, danger_red)
  lurek.log.info("danger zone highlighted", "minimap")
end

--@api-stub: LMinimap:getHoverInfo
-- Returns tooltip text for a screen position, if available.
do
  -- getHoverInfo(sx, sy, mx, my) returns hover text based on screen coords.
  -- sx, sy = screen position of the minimap; mx, my = mouse screen position.
  -- Returns nil when mouse is outside or no info is available.
  -- Scenario: show terrain name on mouse hover.
  local mm = lurek.minimap.newMinimap(64, 64)
  mm:setTerrain(10, 10, 1)
  mm:setTileDescription(1, "Grassland")
  -- Simulate mouse at screen position (40, 40) with minimap at (0, 0)
  local info = mm:getHoverInfo(40, 40, 0, 0)
  lurek.log.info("hover: " .. tostring(info), "minimap")
end

--@api-stub: LMinimap:gridToScreen
-- Converts grid coordinates to screen pixel coordinates.
do
  -- gridToScreen(gx, gy, mx, my) -> sx, sy
  -- gx, gy = grid cell; mx, my = minimap screen origin.
  -- Returns screen pixel position of that grid cell.
  -- Scenario: position a tooltip bubble at the screen location of a grid cell.
  local mm = lurek.minimap.newMinimap(32, 32)
  -- Minimap drawn at screen position (0, 0)
  local sx, sy = mm:gridToScreen(16, 16, 0, 0)
  lurek.log.info("grid 16,16 -> screen " .. tostring(sx) .. "," .. tostring(sy), "minimap")
end

--@api-stub: LMinimap:screenToGrid
-- Converts screen pixel coordinates to grid coordinates.
do
  -- screenToGrid(sx, sy, mx, my) -> gx, gy
  -- sx, sy = screen click; mx, my = minimap screen origin.
  -- Scenario: player clicks minimap to issue a move command at that grid location.
  local mm = lurek.minimap.newMinimap(32, 32)
  -- Player clicks at screen pixel (64, 64), minimap is at (0, 0)
  local gx, gy = mm:screenToGrid(64, 64, 0, 0)
  lurek.log.info("click -> grid cell " .. tostring(gx) .. "," .. tostring(gy), "minimap")
end

--@api-stub: LMinimap:setFogColor
-- Sets the RGBA color of the fog overlay.
do
  -- setFogColor(r, g, b [, a]) changes the appearance of fogged cells.
  -- Scenario: icy level uses pale blue fog; volcanic level uses dark red fog.
  local mm = lurek.minimap.newMinimap(64, 64)
  mm:setFogEnabled(true)
  -- Dark blue-black fog for a night-time dungeon crawler
  mm:setFogColor(0.0, 0.0, 0.1, 0.7)
  lurek.log.info("dark fog colour set for night dungeon", "minimap")
end

--@api-stub: LMinimap:setLayerData
-- Sets raw terrain cell data for a specific layer.
do
  -- setLayerData(layer, data_tbl) populates a layer's grid from a flat array.
  -- Layers let you store multiple floors/levels in one minimap.
  -- Scenario: two-floor dungeon — set ground floor and basement data.
  local mm = lurek.minimap.newMinimap(8, 8)
  -- Layer 0 = ground floor (checkerboard pattern for testing)
  local ground = {}
  for i = 1, 64 do ground[i] = (i % 2 == 0) and 1 or 0 end
  mm:setLayerData(0, ground)
  -- Layer 1 = basement (all walls except a corridor)
  local basement = {}
  for i = 1, 64 do basement[i] = 2 end -- fill with walls
  for i = 25, 32 do basement[i] = 0 end -- corridor in row 4
  mm:setLayerData(1, basement)
  lurek.log.info("2 dungeon floors loaded", "minimap")
end

--@api-stub: LMinimap:setMarkerAnimation
-- Sets an animation on a marker by type name and speed.
do
  -- setMarkerAnimation(id, anim_type, speed)
  -- anim_type: "blink" (flashes on/off), "pulse" (grows/shrinks), "rotate" (spins).
  -- speed: animation cycles per second.
  -- Scenario: active quest marker pulses to draw the player's eye.
  local mm = lurek.minimap.newMinimap(32, 32)
  local marker_id = mm:addMarker(16, 16, "Main quest objective", 1, 1, 0, 1)
  -- Slow pulse (1.5 cycles/sec) for a gentle attention effect
  mm:setMarkerAnimation(marker_id, "pulse", 1.5)
  lurek.log.info("quest marker now pulsing", "minimap")
end

--@api-stub: LMinimap:setObject
-- Places or updates a tracked object on the minimap.
do
  -- setObject(id, x, y, type_idx [, owner])
  -- id: unique identifier for this object (e.g., entity id from your ECS).
  -- x, y: grid position. type_idx: from addObjectType. owner: optional team id.
  -- Call again with same id to update position (e.g., moving units).
  -- Scenario: RTS — track unit movement on the minimap.
  local mm = lurek.minimap.newMinimap(32, 32)
  local unit_type = mm:addObjectType("infantry", 0, 0.7, 1, 1)
  -- Place a unit at (16, 16), owned by team 1
  mm:setObject(1, 16, 16, unit_type, 1)
  -- Unit moves — update its position
  mm:setObject(1, 17, 15, unit_type, 1)
  lurek.log.info("tracking " .. mm:getObjectCount() .. " unit(s)", "minimap")
end

--@api-stub: LMinimap:setObjectTypeVisible
-- Sets whether objects of a given type are drawn on the minimap.
do
  -- setObjectTypeVisible(type_idx, visible) toggles rendering for a whole category.
  -- Scenario: player opens filter panel and hides resource nodes.
  local mm = lurek.minimap.newMinimap(32, 32)
  local enemy_idx = mm:addObjectType("enemy", 1, 0, 0, 1)
  -- Player toggles "show enemies" off in the minimap filter
  mm:setObjectTypeVisible(enemy_idx, false)
  lurek.log.info("enemies hidden: " .. tostring(not mm:isObjectTypeVisible(enemy_idx)), "minimap")
end

--@api-stub: LMinimap:setOwnerColor
-- Assigns an RGBA color to an owner/team id.
do
  -- setOwnerColor(owner, r, g, b [, a]) defines faction colours.
  -- Used in "political" color mode to tint cells by which team owns them.
  -- Scenario: 4-player RTS — assign team colours.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setOwnerColor(1, 0.9, 0.1, 0.1, 1)  -- team 1 = red
  mm:setOwnerColor(2, 0.1, 0.2, 0.9, 1)  -- team 2 = blue
  mm:setOwnerColor(3, 0.1, 0.8, 0.2, 1)  -- team 3 = green
  mm:setOwnerColor(4, 0.9, 0.9, 0.1, 1)  -- team 4 = yellow
  lurek.log.info("4 team colours assigned", "minimap")
end

--@api-stub: LMinimap:setTerrain
-- Sets the terrain type for a specific grid cell.
do
  -- setTerrain(x, y, terrain_type) assigns a terrain type id to a cell.
  -- Coordinates are one-based. The colour shown depends on setTerrainColor.
  -- Scenario: map editor — player paints water tiles.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setTerrainColor(1, 0.2, 0.4, 0.9, 1) -- type 1 = water (blue)
  -- Paint a small lake
  for x = 5, 10 do
    for y = 8, 12 do
      mm:setTerrain(x, y, 1)
    end
  end
  lurek.log.info("lake painted on minimap", "minimap")
end

--@api-stub: LMinimap:setTerrainColor
-- Assigns an RGBA display color to a terrain type id.
do
  -- setTerrainColor(terrain_type, r, g, b [, a])
  -- Define how each terrain type appears on the minimap.
  -- Scenario: define a colour palette for a fantasy world map.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setTerrainColor(0, 0.05, 0.05, 0.1, 1) -- type 0 = void/unexplored (dark)
  mm:setTerrainColor(1, 0.1, 0.6, 0.1, 1)   -- type 1 = grassland (green)
  mm:setTerrainColor(2, 0.9, 0.8, 0.4, 1)   -- type 2 = desert (sand)
  mm:setTerrainColor(3, 0.2, 0.3, 0.8, 1)   -- type 3 = ocean (blue)
  mm:setTerrainColor(4, 0.5, 0.5, 0.5, 1)   -- type 4 = mountain (grey)
  lurek.log.info("5 terrain colours registered", "minimap")
end

--@api-stub: LMinimap:setTileDescription
-- Assigns a text description to a terrain type id for tooltips.
do
  -- setTileDescription(type_id, desc)
  -- Description appears in getHoverInfo when the mouse is over that tile type.
  -- Scenario: add tooltip text for terrain types.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:setTileDescription(1, "Grassland — normal movement speed")
  mm:setTileDescription(2, "Desert — drains stamina, +50% water consumption")
  mm:setTileDescription(3, "Ocean — impassable without a ship")
  mm:setTileDescription(4, "Mountain — impassable, blocks line of sight")
  lurek.log.info("tile tooltips configured", "minimap")
end

--@api-stub: LMinimap:setViewportColor
-- Sets the RGBA color of the viewport rectangle overlay.
do
  -- setViewportColor(r, g, b [, a]) customizes the camera rect appearance.
  -- Scenario: bright yellow viewport border for high visibility.
  local mm = lurek.minimap.newMinimap(64, 64)
  mm:setViewportColor(1, 1, 0, 0.8) -- bright yellow, slightly transparent
  lurek.log.info("viewport colour: bright yellow", "minimap")
end

--@api-stub: LMinimap:setViewportRect
-- Sets the viewport rectangle showing the camera's visible area on the minimap.
do
  -- setViewportRect(x, y, w, h) defines the camera frustum on the map.
  -- x, y = top-left grid position; w, h = width and height in grid cells.
  -- Scenario: show what the main camera sees on a strategy game minimap.
  local mm = lurek.minimap.newMinimap(64, 64)
  -- Camera shows grid cells (10, 8) to (26, 20) — that's 16 wide, 12 tall
  mm:setViewportRect(10, 8, 16, 12)
  lurek.log.info("viewport rect shows camera frustum", "minimap")
end

--@api-stub: LMinimap:showPath
-- Draws a coloured path overlay and returns its id.
do
  -- showPath(points_tbl, color_tbl) -> path_id
  -- points_tbl: array of {x, y} waypoints. color_tbl: RGBA byte table.
  -- Scenario: display A* navigation path from unit to destination.
  local mm = lurek.minimap.newMinimap(32, 32)
  -- Path from spawn (5,5) through waypoints to destination (25,20)
  local waypoints = { {5,5}, {8,7}, {12,10}, {18,14}, {25,20} }
  local orange = {1, 0.5, 0, 1}
  local path_id = mm:showPath(waypoints, orange)
  lurek.log.info("navigation path id: " .. path_id, "minimap")
end

--@api-stub: LMinimap:getCellCount
-- Returns the total number of grid cells (grid_w * grid_h).
do
  -- getCellCount() is a shorthand for getGridWidth() * getGridHeight().
  -- Scenario: allocate a flat array matching the grid for external processing.
  local mm = lurek.minimap.newMinimap(40, 30)
  local total = mm:getCellCount() -- 40 * 30 = 1200
  lurek.log.info("total cells: " .. total, "minimap")
end

--@api-stub: LMinimap:trackCamera
-- Centers the minimap and viewport rectangle from a camera handle.
do
  -- trackCamera(camera_ud) reads position and zoom from an LCamera
  -- and automatically calls setCenter + setViewportRect to match.
  -- Scenario: keep minimap synced with the game camera every frame.
  local mm = lurek.minimap.newMinimap(64, 64, 200, 200)
  local cam = lurek.camera.new(20, 10)
  cam:setPosition(12, 18)
  cam:setZoom(2)
  -- One call syncs center + viewport from camera state
  mm:trackCamera(cam)
  local x, y, w, h = mm:getViewportRect()
  lurek.log.info("camera rect: " .. tostring(x) .. "," .. tostring(y) .. " " .. tostring(w) .. "x" .. tostring(h), "minimap")
end

--@api-stub: LMinimap:revealRadius
-- Reveals fog of war in a circle around a world position.
do
  -- revealRadius(cx, cy, radius) sets cells within radius to fog level 2 (visible).
  -- Scenario: player character reveals fog as they move (vision radius).
  local mm = lurek.minimap.newMinimap(16, 16)
  mm:setFogEnabled(true)
  -- Player at grid (8, 8) with vision radius of 3 cells
  mm:revealRadius(8, 8, 3)
  -- Center cell should now be fully visible (level 2)
  lurek.log.info("center fog level: " .. mm:getFogLevel(8, 8), "minimap")
end

--@api-stub: LMinimap:setObjectTypeTexture
-- Assigns an image texture to an object type for custom icons.
do
  -- setObjectTypeTexture(type_idx, image_ud, width, height)
  -- Instead of a plain colour dot, objects of this type render as an icon.
  -- Scenario: use a skull icon for enemy units on the minimap.
  local mm = lurek.minimap.newMinimap(32, 32)
  local icon = lurek.render.newImage("assets/icon.png")
  local idx = mm:addObjectType("enemy", 1, 0, 0, 1)
  -- Display enemy dots as a 12x12 pixel icon instead of a colour dot
  mm:setObjectTypeTexture(idx, icon, 12, 12)
end

--@api-stub: LMinimap:clearObjectTypeTexture
-- Removes the image texture from an object type, reverting to colour dot.
do
  -- clearObjectTypeTexture(type_idx) reverts to the default colour rendering.
  -- Scenario: player disables "fancy icons" in settings.
  local mm = lurek.minimap.newMinimap(32, 32)
  local icon = lurek.render.newImage("assets/icon.png")
  local idx = mm:addObjectType("unit", 1, 1, 1, 1)
  mm:setObjectTypeTexture(idx, icon, 12, 12)
  -- Revert to simple colour dot
  mm:clearObjectTypeTexture(idx)
end

--@api-stub: LMinimap:setMarkerTexture
-- Assigns an image texture to a specific marker for a custom icon.
do
  -- setMarkerTexture(id, image_ud [, width, height])
  -- Scenario: quest marker uses a golden exclamation mark icon.
  local mm = lurek.minimap.newMinimap(32, 32)
  local quest_icon = lurek.render.newImage("assets/icon.png")
  local id = mm:addMarker(10, 12, "Main quest")
  -- Render this marker as a 10x10 pixel custom icon
  mm:setMarkerTexture(id, quest_icon, 10, 10)
end

--@api-stub: LMinimap:clearMarkerTexture
-- Removes the image texture from a marker, reverting to default dot.
do
  -- clearMarkerTexture(id) removes the custom icon from a marker.
  -- Scenario: quest changes state — revert marker to plain colour indicator.
  local mm = lurek.minimap.newMinimap(32, 32)
  local icon = lurek.render.newImage("assets/icon.png")
  local id = mm:addMarker(10, 12, "Side quest")
  mm:setMarkerTexture(id, icon, 10, 10)
  -- Quest completed — clear the fancy icon, marker stays as plain dot
  mm:clearMarkerTexture(id)
end

--@api-stub: LMinimap:getOverlayShapeCount
-- Returns the number of overlay shapes (lines and rectangles) drawn.
do
  -- getOverlayShapeCount() returns total overlays for budget tracking.
  -- Scenario: limit overlay complexity to avoid visual clutter.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:drawLine(0, 0, 8, 8, {1, 0, 0, 1})
  mm:drawRect(4, 4, 6, 6, {0, 1, 0, 0.7})
  local count = mm:getOverlayShapeCount()
  lurek.log.info("overlay shapes: " .. count .. " (max recommended: 50)", "minimap")
end

--@api-stub: LMinimap:getPathCount
-- Returns the number of active path overlays.
do
  -- getPathCount() returns how many paths are currently displayed.
  -- Scenario: limit active paths to prevent visual noise.
  local mm = lurek.minimap.newMinimap(32, 32)
  mm:showPath({ {2,2}, {3,4}, {5,6} }, {1, 0.8, 0, 1})
  mm:showPath({ {10,10}, {15,12} }, {0, 1, 0.5, 1})
  lurek.log.info("active paths: " .. mm:getPathCount(), "minimap")
end

--@api-stub: LMinimap:getLayerCount
-- Returns the number of layers that have data.
do
  -- getLayerCount() returns how many layers have been populated with setLayerData.
  -- Scenario: show "Floor X of Y" indicator in dungeon UI.
  local mm = lurek.minimap.newMinimap(4, 4)
  -- Populate two layers
  mm:setLayerData(0, {0,1,0,1, 1,0,1,0, 0,1,0,1, 1,0,1,0})
  mm:setLayerData(1, {1,1,1,1, 0,0,0,0, 1,1,1,1, 0,0,0,0})
  lurek.log.info("dungeon has " .. mm:getLayerCount() .. " floors", "minimap")
end

--@api-stub: LMinimap:getLayerData
-- Returns the raw cell data array for a specific layer.
do
  -- getLayerData(layer) returns a flat array table, or nil if layer is empty.
  -- Scenario: serialize layer data to save file for persistence.
  local mm = lurek.minimap.newMinimap(4, 4)
  mm:setLayerData(0, {1,2,3,4, 4,3,2,1, 1,2,3,4, 4,3,2,1})
  local data = mm:getLayerData(0)
  if data then
    lurek.log.info("layer 0 has " .. #data .. " cells to save", "minimap")
  end
end

print("content/examples/minimap.lua")

-- =============================================================================
-- STUBS: 86 uncovered lurek.minimap API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LMinimap methods
-- -----------------------------------------------------------------------------
