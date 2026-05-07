-- content/examples/minimap.lua
-- Hand-written coverage of the lurek.minimap API (56 items).
--
-- The lurek.minimap namespace provides grid-based minimap widgets with
-- terrain colouring, fog of war, tracked objects/factions, animated pings,
-- persistent markers, custom overlay geometry, multi-layer floor stacks,
-- and screen<->grid coordinate conversion.
--
-- Run: cargo run -- content/examples/minimap.lua

-- â”€â”€ lurek.minimap.* functions â”€â”€

--@api-stub: lurek.minimap.newMinimap
-- Creates a new grid-based minimap.
-- Pass display_w/display_h to size the on-screen panel; defaults are 200x200 if omitted.
-- if false then -- lurek.minimap.newMinimap
--   local mm = lurek.minimap.newMinimap(64, 48, 256, 192)
--   mm:setTerrain(1, 1, 1)
--   lurek.log.info("minimap grid " .. mm:getGridWidth() .. "x" .. mm:getGridHeight(), "minimap")
-- end

-- â”€â”€ Minimap methods â”€â”€

--@api-stub: LMinimap:getGridWidth
-- Returns the grid width in cells.
-- Use to size loops over terrain or to translate world tiles into minimap cells.
-- if false then -- Minimap:getGridWidth
--   local mm = lurek.minimap.newMinimap(80, 60)
--   local w = mm:getGridWidth()
--   for x = 1, w do mm:setTerrain(x, 1, 2) end
-- end

--@api-stub: LMinimap:getGridHeight
-- Returns the grid height in cells.
-- Use alongside getGridWidth to drive nested terrain or fog initialisation loops.
-- if false then -- Minimap:getGridHeight
--   local mm = lurek.minimap.newMinimap(80, 60)
--   local h = mm:getGridHeight()
--   for y = 1, h do mm:setTerrain(1, y, 3) end
-- end

--@api-stub: LMinimap:getGridSize
-- Returns the grid width and height as two values.
-- Returns both dimensions as a multi-return; assign to two locals, never collect into a table.
-- if false then -- Minimap:getGridSize
--   local mm = lurek.minimap.newMinimap(48, 32)
--   local gw, gh = mm:getGridSize()
--   lurek.log.info("grid cells: " .. (gw * gh), "minimap")
-- end

--@api-stub: LMinimap:getDisplayWidth
-- Returns the display width in pixels.
-- Use to align HUD widgets immediately to the right of the minimap panel.
-- if false then -- Minimap:getDisplayWidth
--   local mm = lurek.minimap.newMinimap(32, 32, 240, 180)
--   local px = mm:getDisplayWidth()
--   local hud_x = 16 + px + 8
--   lurek.log.info("hud x=" .. hud_x, "ui")
-- end

--@api-stub: LMinimap:getDisplayHeight
-- Returns the display height in pixels.
-- Pair with getDisplayWidth when stacking HUD elements vertically below the minimap.
-- if false then -- Minimap:getDisplayHeight
--   local mm = lurek.minimap.newMinimap(32, 32, 240, 180)
--   local py = mm:getDisplayHeight()
--   lurek.log.info("minimap occupies " .. py .. " px tall", "ui")
-- end

--@api-stub: LMinimap:getDisplaySize
-- Returns the display width and height as two values.
-- Use this 2-return when computing screen-space bounds in one shot.
-- if false then -- Minimap:getDisplaySize
--   local mm = lurek.minimap.newMinimap(40, 30, 200, 150)
--   local dw, dh = mm:getDisplaySize()
--   local cx, cy = dw * 0.5, dh * 0.5
--   lurek.log.info("center px " .. cx .. "," .. cy, "minimap")
-- end

--@api-stub: LMinimap:setDisplaySize
-- Sets the display size in pixels.
-- Call when the player resizes the HUD; values are interpreted as integer pixels.
-- if false then -- Minimap:setDisplaySize
--   local mm = lurek.minimap.newMinimap(64, 64)
--   mm:setDisplaySize(320, 240)
--   local w, h = mm:getDisplaySize()
--   lurek.log.info("resized minimap to " .. w .. "x" .. h, "ui")
-- end

--@api-stub: LMinimap:getTerrain
-- Returns the terrain type at a 1-based grid position.
-- Coordinates are 1-based; passing 0 raises a runtime error, so guard before calling.
-- if false then -- Minimap:getTerrain
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setTerrain(4, 4, 7)
--   local t = mm:getTerrain(4, 4)
--   if t == 7 then lurek.log.info("forest tile at 4,4", "minimap") end
-- end

--@api-stub: LMinimap:setTerrainData
-- Sets terrain types from a flat 1-based Lua table of integers (row-major).
-- Provide width*height integers in row-major order; faster than per-cell setTerrain.
-- if false then -- Minimap:setTerrainData
--   local mm = lurek.minimap.newMinimap(4, 3)
--   local data = { 1,1,2,2, 1,3,3,2, 0,3,3,0 }
--   mm:setTerrainData(data)
--   lurek.log.info("seeded " .. #data .. " cells", "minimap")
-- end

--@api-stub: LMinimap:getTerrainColor
-- Returns the display color for a terrain type as r, g, b, a.
-- Returns RGBA as 0-1 floats; use to drive matching legend swatches in the UI.
-- if false then -- Minimap:getTerrainColor
--   local mm = lurek.minimap.newMinimap(8, 8)
--   mm:setTerrainColor(2, 0.2, 0.6, 0.1, 1.0)
--   local r, g, b, a = mm:getTerrainColor(2)
--   lurek.log.info("forest swatch " .. r .. "," .. g .. "," .. b .. "," .. a, "ui")
-- end

--@api-stub: LMinimap:getTileDescription
-- Returns the hover tooltip string for a terrain type ID, or nil.
-- Returns nil for unregistered terrain types; branch on the result before showing tooltips.
-- if false then -- Minimap:getTileDescription
--   local mm = lurek.minimap.newMinimap(8, 8)
--   mm:setTileDescription(3, "Dense forest, slows movement")
--   local desc = mm:getTileDescription(3)
--   if desc then lurek.log.info("tooltip: " .. desc, "ui") end
-- end

--@api-stub: LMinimap:setFogEnabled
-- Enables or disables fog of war.
-- Toggle off in editor or debug overlays to see the entire map at once.
-- if false then -- Minimap:setFogEnabled
--   local mm = lurek.minimap.newMinimap(32, 32)
--   mm:setFogEnabled(true)
--   if mm:isFogEnabled() then lurek.log.info("fog on", "minimap") end
-- end

--@api-stub: LMinimap:isFogEnabled
-- Returns whether fog of war is enabled.
-- Use to gate reveal/explore writes; they're cheap to skip when fog is off.
-- if false then -- Minimap:isFogEnabled
--   local mm = lurek.minimap.newMinimap(32, 32)
--   mm:setFogEnabled(false)
--   if not mm:isFogEnabled() then mm:setTerrain(1, 1, 9) end
-- end

--@api-stub: LMinimap:setFogLevel
-- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- Levels are 0=hidden, 1=explored, 2=visible; cell coords are 1-based.
-- if false then -- Minimap:setFogLevel
--   local mm = lurek.minimap.newMinimap(20, 20)
--   mm:setFogEnabled(true)
--   for x = 4, 8 do mm:setFogLevel(x, 5, 2) end
--   mm:setFogLevel(6, 5, 1)
-- end

--@api-stub: LMinimap:getFogLevel
-- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- Use when revealing rooms; only fade in pickups when their cell is at level 2.
-- if false then -- Minimap:getFogLevel
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setFogEnabled(true)
--   mm:setFogLevel(8, 8, 2)
--   if mm:getFogLevel(8, 8) == 2 then lurek.log.info("cell visible", "fog") end
-- end

--@api-stub: LMinimap:getFogColor
-- Returns the fog overlay color as r, g, b, a.
-- Default is dim grey at 0.8 alpha; read it to keep custom fog UI in sync.
-- if false then -- Minimap:getFogColor
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setFogColor(0.05, 0.05, 0.1, 0.85)
--   local r, g, b, a = mm:getFogColor()
--   lurek.log.info("fog rgba " .. r .. "," .. g .. "," .. b .. "," .. a, "fog")
-- end

--@api-stub: LMinimap:setFogData
-- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
-- Bulk-load a saved fog grid from save data; size must match grid_w*grid_h.
-- if false then -- Minimap:setFogData
--   local mm = lurek.minimap.newMinimap(4, 3)
--   mm:setFogEnabled(true)
--   local fog = { 2,2,1,0, 2,2,1,0, 1,1,1,0 }
--   mm:setFogData(fog)
-- end

--@api-stub: LMinimap:isObjectTypeVisible
-- Returns whether an object type (1-based index) is visible.
-- Use to drive a 'show enemies' toggle in the minimap legend.
-- if false then -- Minimap:isObjectTypeVisible
--   local mm = lurek.minimap.newMinimap(20, 20)
--   local enemy = mm:addObjectType("enemy", 1, 0.1, 0.1, 1)
--   if mm:isObjectTypeVisible(enemy) then lurek.log.info("enemies shown", "minimap") end
-- end

--@api-stub: LMinimap:getObjectTypeCount
-- Returns the number of registered object types.
-- Use after registering all factions to size legend rows or icon arrays.
-- if false then -- Minimap:getObjectTypeCount
--   local mm = lurek.minimap.newMinimap(20, 20)
--   mm:addObjectType("ally", 0.2, 0.6, 1, 1)
--   mm:addObjectType("enemy", 1, 0.2, 0.2, 1)
--   lurek.log.info("registered types: " .. mm:getObjectTypeCount(), "minimap")
-- end

--@api-stub: LMinimap:removeObject
-- Removes a tracked object by ID.
-- Returns true if the ID was tracked; safe to call on already-removed objects.
-- if false then -- Minimap:removeObject
--   local mm = lurek.minimap.newMinimap(20, 20)
--   local t = mm:addObjectType("loot", 1, 1, 0, 1)
--   mm:setObject(101, 5, 5, t)
--   if mm:removeObject(101) then lurek.log.info("loot 101 picked up", "minimap") end
-- end

--@api-stub: LMinimap:clearObjects
-- Removes all tracked objects.
-- Call on level transitions to drop stale icons before repopulating from the new scene.
-- if false then -- Minimap:clearObjects
--   local mm = lurek.minimap.newMinimap(20, 20)
--   local t = mm:addObjectType("npc", 0, 1, 0, 1)
--   mm:setObject(1, 4, 4, t); mm:setObject(2, 9, 9, t)
--   mm:clearObjects()
--   lurek.log.info("objects after clear: " .. mm:getObjectCount(), "minimap")
-- end

--@api-stub: LMinimap:getObjectCount
-- Returns the number of tracked objects.
-- Use to display 'X enemies remaining' or to short-circuit AI sweeps.
-- if false then -- Minimap:getObjectCount
--   local mm = lurek.minimap.newMinimap(16, 16)
--   local t = mm:addObjectType("rat", 0.6, 0.4, 0.2, 1)
--   for i = 1, 5 do mm:setObject(i, i, i, t) end
--   lurek.log.info("tracked: " .. mm:getObjectCount(), "minimap")
-- end

--@api-stub: LMinimap:getOwnerColor
-- Returns the display color for an owner/faction as r, g, b, a.
-- Reflects setOwnerColor; useful when rendering team flags consistently elsewhere.
-- if false then -- Minimap:getOwnerColor
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setOwnerColor(2, 0.1, 0.4, 0.9, 1)
--   local r, g, b, a = mm:getOwnerColor(2)
--   lurek.log.info("team 2 colour " .. r .. "," .. g .. "," .. b .. "," .. a, "team")
-- end

--@api-stub: LMinimap:setColorMode
-- Sets the color mode ("terrain" or "political").
-- 'terrain' shows biome colours; 'political' tints by owner; switch on a player toggle key.
-- if false then -- Minimap:setColorMode
--   local mm = lurek.minimap.newMinimap(20, 20)
--   mm:setColorMode("political")
--   lurek.log.info("mode now " .. mm:getColorMode(), "minimap")
-- end

--@api-stub: LMinimap:getColorMode
-- Returns the current color mode as a string.
-- Returns 'terrain' or 'political'; compare with == when branching display logic.
-- if false then -- Minimap:getColorMode
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setColorMode("terrain")
--   if mm:getColorMode() == "terrain" then mm:setTerrainColor(1, 0.3, 0.5, 0.2, 1) end
-- end

--@api-stub: LMinimap:setZoom
-- Sets the zoom level (minimum 0.1).
-- Values below 0.1 are clamped; bind to mouse-wheel for player-controlled zoom.
-- if false then -- Minimap:setZoom
--   local mm = lurek.minimap.newMinimap(64, 64)
--   mm:setZoom(2.5)
--   lurek.log.info("zoom " .. mm:getZoom(), "minimap")
-- end

--@api-stub: LMinimap:getZoom
-- Returns the current zoom level.
-- Use to recompute screen-space cell sizes when laying out custom overlays.
-- if false then -- Minimap:getZoom
--   local mm = lurek.minimap.newMinimap(48, 48, 240, 240)
--   mm:setZoom(1.5)
--   local cell_px = (mm:getDisplayWidth() / mm:getGridWidth()) * mm:getZoom()
--   lurek.log.info("cell size " .. cell_px .. " px", "minimap")
-- end

--@api-stub: LMinimap:setCenter
-- Sets the center of the minimap view in grid coordinates.
-- Pass world tile coords; call each frame with player position for follow-cam behaviour.
-- if false then -- Minimap:setCenter
--   local mm = lurek.minimap.newMinimap(128, 128, 200, 200)
--   local player = { x = 64, y = 32 }
--   mm:setCenter(player.x, player.y)
-- end

--@api-stub: LMinimap:getCenter
-- Returns the center coordinates as x, y.
-- Returns 2 values; use to save view state across map screens.
-- if false then -- Minimap:getCenter
--   local mm = lurek.minimap.newMinimap(64, 64)
--   mm:setCenter(20.5, 35.0)
--   local cx, cy = mm:getCenter()
--   lurek.log.info("centered at " .. cx .. "," .. cy, "minimap")
-- end

--@api-stub: LMinimap:getCenterX
-- Returns the center X coordinate.
-- Cheaper single-axis read when you only need the horizontal pan.
-- if false then -- Minimap:getCenterX
--   local mm = lurek.minimap.newMinimap(64, 64)
--   mm:setCenter(40, 20)
--   if mm:getCenterX() > 32 then mm:setCenter(32, mm:getCenterY()) end
-- end

--@api-stub: LMinimap:getCenterY
-- Returns the center Y coordinate.
-- Use to clamp vertical pan inside the world bounds before drawing.
-- if false then -- Minimap:getCenterY
--   local mm = lurek.minimap.newMinimap(64, 48)
--   mm:setCenter(10, 50)
--   local cy = math.min(mm:getCenterY(), 40)
--   mm:setCenter(mm:getCenterX(), cy)
-- end

--@api-stub: LMinimap:clearViewportRect
-- Clears the viewport rectangle overlay.
-- Call when the camera detaches (e.g. cinematic) so the rectangle stops drawing.
-- if false then -- Minimap:clearViewportRect
--   local mm = lurek.minimap.newMinimap(80, 60)
--   mm:setViewportRect(10, 10, 20, 15)
--   mm:clearViewportRect()
--   local x = mm:getViewportRect()
--   if x == nil then lurek.log.info("viewport hidden", "minimap") end
-- end

--@api-stub: LMinimap:getViewportRect
-- Returns the viewport rectangle as x, y, w, h or nil if not set.
-- Returns 4 values or nils; check the first against nil before using the rest.
-- if false then -- Minimap:getViewportRect
--   local mm = lurek.minimap.newMinimap(80, 60)
--   mm:setViewportRect(5, 8, 16, 12)
--   local x, y, w, h = mm:getViewportRect()
--   if x then lurek.log.info("viewport " .. x .. "," .. y .. " " .. w .. "x" .. h, "minimap") end
-- end

--@api-stub: LMinimap:setViewportVisible
-- Sets whether the viewport rectangle is visible.
-- Toggle off during pause menus or cutscenes to declutter the minimap.
-- if false then -- Minimap:setViewportVisible
--   local mm = lurek.minimap.newMinimap(80, 60)
--   mm:setViewportRect(0, 0, 24, 18)
--   mm:setViewportVisible(false)
-- end

--@api-stub: LMinimap:isViewportVisible
-- Returns whether the viewport rectangle is visible.
-- Use as a guard before computing custom viewport overlay decorations.
-- if false then -- Minimap:isViewportVisible
--   local mm = lurek.minimap.newMinimap(80, 60)
--   mm:setViewportRect(0, 0, 16, 12)
--   if mm:isViewportVisible() then lurek.log.info("viewport overlay on", "minimap") end
-- end

--@api-stub: LMinimap:getViewportColor
-- Returns the viewport rectangle color as r, g, b, a.
-- Read after setViewportColor to keep a HUD frame matching the minimap rectangle.
-- if false then -- Minimap:getViewportColor
--   local mm = lurek.minimap.newMinimap(40, 30)
--   mm:setViewportColor(1, 1, 1, 0.6)
--   local r, g, b, a = mm:getViewportColor()
--   lurek.log.info("viewport rgba " .. r .. "," .. g .. "," .. b .. "," .. a, "ui")
-- end

--@api-stub: LMinimap:getPingCount
-- Returns the number of active pings.
-- Use to throttle additional pings; many hundreds active will affect frame time.
-- if false then -- Minimap:getPingCount
--   local mm = lurek.minimap.newMinimap(40, 30)
--   mm:addPing(10, 10, 1.5)
--   mm:addPing(20, 15, 1.5, 0.2, 1, 0.4, 1)
--   lurek.log.info("pings active: " .. mm:getPingCount(), "minimap")
-- end

--@api-stub: LMinimap:removeMarker
-- Removes the minimap marker with the given integer ID, if present.
-- Returns false if the ID was already removed; idempotent and safe to spam.
-- if false then -- Minimap:removeMarker
--   local mm = lurek.minimap.newMinimap(40, 30)
--   local id = mm:addMarker(5, 5, "Quest goal")
--   if mm:removeMarker(id) then lurek.log.info("marker " .. id .. " cleared", "minimap") end
-- end

--@api-stub: LMinimap:hasMarker
-- Returns whether a marker with the given ID exists.
-- Cheap existence check before calling getMarkerDescription or setMarkerAnimation.
-- if false then -- Minimap:hasMarker
--   local mm = lurek.minimap.newMinimap(40, 30)
--   local id = mm:addMarker(8, 6, "Ally HQ")
--   if mm:hasMarker(id) then mm:setMarkerAnimation(id, "pulse", 1.5) end
-- end

--@api-stub: LMinimap:getMarkerDescription
-- Returns the description of a marker, or nil.
-- Returns nil for unknown IDs; use the result to populate hover tooltips.
-- if false then -- Minimap:getMarkerDescription
--   local mm = lurek.minimap.newMinimap(40, 30)
--   local id = mm:addMarker(12, 9, "Hidden cache")
--   local desc = mm:getMarkerDescription(id)
--   if desc then lurek.log.info("marker " .. id .. ": " .. desc, "minimap") end
-- end

--@api-stub: LMinimap:getMarkerCount
-- Returns the number of markers.
-- Use to gate UI like 'click to clear all markers' when the count is non-zero.
-- if false then -- Minimap:getMarkerCount
--   local mm = lurek.minimap.newMinimap(32, 32)
--   mm:addMarker(2, 2, "A"); mm:addMarker(8, 4, "B"); mm:addMarker(14, 7, "C")
--   lurek.log.info("markers placed: " .. mm:getMarkerCount(), "minimap")
-- end

--@api-stub: LMinimap:clearMarkerAnimation
-- Removes the animation from a marker, reverting it to static.
-- Revert a marker to a static dot without removing it (useful when an objective completes).
-- if false then -- Minimap:clearMarkerAnimation
--   local mm = lurek.minimap.newMinimap(32, 32)
--   local id = mm:addMarker(4, 4, "Boss")
--   mm:setMarkerAnimation(id, "blink", 4.0)
--   mm:clearMarkerAnimation(id)
-- end

--@api-stub: LMinimap:clearOverlay
-- Removes all custom geometry from the minimap overlay.
-- Strips drawLine/drawRect geometry; markers and pings are unaffected.
-- if false then -- Minimap:clearOverlay
--   local mm = lurek.minimap.newMinimap(40, 30)
--   mm:drawLine(0, 0, 40, 30, { 255, 255, 0, 255 })
--   mm:drawRect(5, 5, 10, 8, { 0, 200, 255, 180 })
--   mm:clearOverlay()
-- end

--@api-stub: LMinimap:clearPath
-- Removes a displayed path.
-- Pass the ID returned by showPath, or nil to wipe every active path at once.
-- if false then -- Minimap:clearPath
--   local mm = lurek.minimap.newMinimap(40, 30)
--   local id = mm:showPath({ {2,2}, {6,4}, {10,8} }, { 0, 255, 0, 200 })
--   mm:clearPath(id)
-- end

--@api-stub: LMinimap:setLayer
-- Switches the minimap's active render layer (0-based index).
-- Switch between stored layers (surface, cave, sky); call setLayerData first to populate them.
-- if false then -- Minimap:setLayer
--   local mm = lurek.minimap.newMinimap(8, 4)
--   mm:setLayerData(1, { 1,1,2,2,1,1,2,2, 0,1,1,2,0,1,1,2, 0,0,1,1,0,0,1,1, 0,0,0,1,0,0,0,1 })
--   mm:setLayer(1)
-- end

--@api-stub: LMinimap:getLayer
-- Returns the index of the currently active render layer.
-- Use after a layer-toggle hotkey to label the HUD with the active floor index.
-- if false then -- Minimap:getLayer
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setLayer(2)
--   lurek.log.info("active layer: " .. mm:getLayer(), "minimap")
-- end

--@api-stub: LMinimap:setAntiAlias
-- Sets whether anti-aliasing is enabled.
-- Disable for crisp pixel-art minimaps; the default is enabled for smooth lines.
-- if false then -- Minimap:setAntiAlias
--   local mm = lurek.minimap.newMinimap(32, 32)
--   mm:setAntiAlias(false)
--   if not mm:isAntiAlias() then lurek.log.info("pixel-perfect minimap", "render") end
-- end

--@api-stub: LMinimap:isAntiAlias
-- Returns whether anti-aliasing is enabled.
-- Read when persisting graphics options to disk so the user's choice survives restart.
-- if false then -- Minimap:isAntiAlias
--   local mm = lurek.minimap.newMinimap(32, 32)
--   mm:setAntiAlias(true)
--   local opts = { aa = mm:isAntiAlias() }
--   lurek.log.info("graphics.aa=" .. tostring(opts.aa), "settings")
-- end

--@api-stub: LMinimap:setClickable
-- Sets whether this minimap responds to click hit-testing.
-- Disable in cinematics or when the minimap is inside an inactive tab.
-- if false then -- Minimap:setClickable
--   local mm = lurek.minimap.newMinimap(40, 30)
--   mm:setClickable(false)
--   if not mm:isClickable() then lurek.log.info("minimap input disabled", "ui") end
-- end

--@api-stub: LMinimap:isClickable
-- Returns whether this minimap responds to click hit-testing.
-- Use as a guard around mouse hit-tests, e.g. in a custom mousepressed handler.
-- if false then -- Minimap:isClickable
--   local mm = lurek.minimap.newMinimap(40, 30)
--   mm:setClickable(true)
--   if mm:isClickable() then mm:addMarker(20, 15, "click target") end
-- end

--@api-stub: LMinimap:update
-- Advances time-based effects by dt seconds (expires pings).
-- Drive from lurek.process(dt) so pings expire and marker animations advance every frame.
-- if false then -- Minimap:update
--   local mm = lurek.minimap.newMinimap(32, 32)
--   mm:addPing(8, 8, 0.5)
--   function lurek.process(dt) mm:update(dt) end
-- end

--@api-stub: LMinimap:type
-- Returns the type name of this object.
-- Use in generic UI helpers that need to dispatch on element kind.
-- if false then -- Minimap:type
--   local mm = lurek.minimap.newMinimap(16, 16)
--   if mm:type() == "Minimap" then lurek.log.info("widget is a minimap", "ui") end
-- end

--@api-stub: LMinimap:typeOf
-- Returns true if this object is of the given type.
-- 'Object' is also true; useful for shared base behaviours across widget kinds.
-- if false then -- Minimap:typeOf
--   local mm = lurek.minimap.newMinimap(16, 16)
--   if mm:typeOf("Object") then lurek.log.info("widget responds to Object api", "ui") end
-- end

--@api-stub: LMinimap:render
-- Renders the minimap to the screen at the given position.
-- Call inside lurek.render(); x,y default to 0,0 so pass HUD coords to position the panel.
-- if false then -- Minimap:render
--   local mm
--   function lurek.init() mm = lurek.minimap.newMinimap(48, 32, 200, 140) end
--   function lurek.draw() mm:render(20, 20) end
-- end

--@api-stub: LMinimap:drawToImage
-- Renders the minimap grid to a CPU ImageData.
-- Returns ImageData at pixel_size px per cell; great for screenshots or pause overlays.
-- if false then -- Minimap:drawToImage
--   local mm = lurek.minimap.newMinimap(16, 16)
--   mm:setTerrain(1, 1, 1)
--   local img = mm:drawToImage(8)
--   lurek.log.info("snapshot: " .. img:getWidth() .. "x" .. img:getHeight(), "minimap")
-- end

--@api-stub: LMinimap:addMarker
-- Adds a named waypoint marker at a grid cell with optional colour override.
-- Markers persist across frames; remove by id with removeMarker().
-- if false then -- Minimap:addMarker
--   local mm = lurek.minimap.newMinimap(64, 64, 4)
--   local id = mm:addMarker(20, 30, "quest_marker", 1, 1, 0, 1)
--   lurek.log.info("marker id: " .. id, "minimap")
-- end

--@api-stub: LMinimap:addObjectType
-- Registers a named object type with a default colour for rendering.
-- Object types control how setObject() icons appear on the minimap.
-- if false then -- Minimap:addObjectType
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local enemy_idx = mm:addObjectType("enemy", 1, 0, 0, 1)
--   local ally_idx = mm:addObjectType("ally",  0, 0.5, 1, 1)
--   lurek.log.info("object types: " .. mm:getObjectTypeCount(), "minimap")
-- end

--@api-stub: LMinimap:addPing
-- Adds a temporary animated ping at a grid cell that fades out over duration seconds.
-- Use for unit selection highlights or tactical markers in multiplayer.
-- if false then -- Minimap:addPing
--   local mm = lurek.minimap.newMinimap(64, 64, 4)
--   mm:addPing(32, 32, 2.0, 0, 1, 1, 1)
--   lurek.log.info("ping added; count: " .. mm:getPingCount(), "minimap")
-- end

--@api-stub: LMinimap:drawLine
-- Draws a persistent overlay line between two grid cells with a colour.
-- Lines are rendered on top of terrain; call clearOverlay() to remove all lines.
-- if false then -- Minimap:drawLine
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   mm:drawLine(0, 0, 31, 31, {1, 1, 0, 1})
--   lurek.log.info("overlay line drawn", "minimap")
-- end

--@api-stub: LMinimap:drawRect
-- Draws a persistent overlay rectangle between two grid cells with a colour.
-- Use to highlight selection boxes or zone boundaries on the minimap.
-- if false then -- Minimap:drawRect
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   mm:drawRect(5, 5, 20, 20, {0, 1, 0, 0.5})
--   lurek.log.info("overlay rect drawn", "minimap")
-- end

--@api-stub: LMinimap:getHoverInfo
-- Returns the grid cell and any object/terrain description under the screen cursor.
-- Call from mousemoved to implement minimap hover tooltips.
-- if false then -- Minimap:getHoverInfo
--   local mm = lurek.minimap.newMinimap(64, 64, 4)
--   mm:setTerrain(10, 10, 1)
--   local info = mm:getHoverInfo(40, 40, 0, 0)
--   lurek.log.info("hover info: " .. tostring(info), "minimap")
-- end

--@api-stub: LMinimap:gridToScreen
-- Converts a minimap grid cell to screen pixel coordinates.
-- Inverse of screenToGrid; use for placing HUD elements above minimap cells.
-- if false then -- Minimap:gridToScreen
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local sx, sy = mm:gridToScreen(16, 16, 0, 0)
--   lurek.log.info("grid 16,16 -> screen " .. sx .. "," .. sy, "minimap")
-- end

--@api-stub: LMinimap:screenToGrid
-- Converts screen pixel coordinates to the nearest minimap grid cell.
-- Use in mouse-click handlers to translate HUD clicks to world actions.
-- if false then -- Minimap:screenToGrid
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local gx, gy = mm:screenToGrid(64, 64, 0, 0)
--   lurek.log.info("screen -> grid: " .. gx .. "," .. gy, "minimap")
-- end

--@api-stub: LMinimap:setFogColor
-- Sets the RGBA colour used to render fog-of-war cells on the minimap.
-- Default is black; use a semi-transparent dark colour for explored-but-hidden regions.
-- if false then -- Minimap:setFogColor
--   local mm = lurek.minimap.newMinimap(64, 64, 4)
--   mm:setFogEnabled(true)
--   mm:setFogColor(0.0, 0.0, 0.1, 0.7)
--   lurek.log.info("fog colour set", "minimap")
-- end

--@api-stub: LMinimap:setLayerData
-- Sets a flat table of terrain or overlay values for a named layer.
-- Table must have width*height entries in row-major order.
-- if false then -- Minimap:setLayerData
--   local mm = lurek.minimap.newMinimap(8, 8, 8)
--   local data = {}
--   for i = 1, 64 do data[i] = (i % 2 == 0) and 1 or 0 end
--   mm:setLayerData(0, data)
--   lurek.log.info("layer data set", "minimap")
-- end

--@api-stub: LMinimap:setMarkerAnimation
-- Sets a looping icon animation for a marker type by name.
-- Pass a table of icon frame indices and a frames-per-second rate.
-- if false then -- Minimap:setMarkerAnimation
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local marker_id = mm:addMarker(16, 16, "quest_marker", 1, 1, 0, 1)
--   mm:setMarkerAnimation(marker_id, "pulse", 4)
--   lurek.log.info("marker animation set", "minimap")
-- end

--@api-stub: LMinimap:setObject
-- Places a named object at a grid cell with its registered type for rendering.
-- Objects appear as coloured icons; update their position by calling setObject again.
-- if false then -- Minimap:setObject
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local unit_idx = mm:addObjectType("unit", 0, 0.7, 1, 1)
--   mm:setObject(1, 16, 16, unit_idx)
--   lurek.log.info("object count: " .. mm:getObjectCount(), "minimap")
-- end

--@api-stub: LMinimap:setObjectTypeVisible
-- Shows or hides all objects of a registered type on the minimap.
-- Use to toggle unit icons by army or faction without removing them.
-- if false then -- Minimap:setObjectTypeVisible
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local enemy_idx = mm:addObjectType("enemy", 1, 0, 0, 1)
--   mm:setObjectTypeVisible(enemy_idx, false)
--   lurek.log.info("enemy visible: " .. tostring(mm:isObjectTypeVisible(enemy_idx)), "minimap")
-- end

--@api-stub: LMinimap:setOwnerColor
-- Sets the colour for a named owner (faction/player) used by coloured province rendering.
-- Call once per faction at init; provinces tagged with that owner use this colour.
-- if false then -- Minimap:setOwnerColor
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   mm:setOwnerColor(1, 0.9, 0.1, 0.1, 1)
--   mm:setOwnerColor(2, 0.1, 0.2, 0.9, 1)
--   lurek.log.info("owner colours set", "minimap")
-- end

--@api-stub: LMinimap:setTerrain
-- Sets the terrain type for a single grid cell.
-- Terrain types are registered with setTerrainColor; unknown types fall back to white.
-- if false then -- Minimap:setTerrain
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   mm:setTerrainColor(1, 0.2, 0.4, 0.9, 1)
--   mm:setTerrain(5, 10, 1)
--   lurek.log.info("terrain set", "minimap")
-- end

--@api-stub: LMinimap:setTerrainColor
-- Registers a colour for a named terrain type.
-- Cells set to this terrain type render in the registered colour on the minimap.
-- if false then -- Minimap:setTerrainColor
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   mm:setTerrainColor(1, 0.1, 0.6, 0.1, 1)
--   mm:setTerrainColor(2, 0.9, 0.8, 0.4, 1)
--   lurek.log.info("terrain colours registered", "minimap")
-- end

--@api-stub: LMinimap:setTileDescription
-- Attaches a short text description to a terrain type for tooltip display.
-- Returned by getHoverInfo when the player hovers over cells of this terrain.
-- if false then -- Minimap:setTileDescription
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   mm:setTerrainColor(1, 0.5, 0.5, 0.5, 1)
--   mm:setTileDescription(1, "Impassable rock face")
--   lurek.log.info("tile description set", "minimap")
-- end

--@api-stub: LMinimap:setViewportColor
-- Sets the RGBA colour of the viewport rectangle drawn on the minimap.
-- The viewport shows which portion of the world the main camera sees.
-- if false then -- Minimap:setViewportColor
--   local mm = lurek.minimap.newMinimap(64, 64, 4)
--   mm:setViewportColor(1, 1, 0, 0.8)
--   lurek.log.info("viewport colour set", "minimap")
-- end

--@api-stub: LMinimap:setViewportRect
-- Sets the viewport rectangle shown on the minimap in world-space coordinates.
-- Update each frame based on the main camera's visible area.
-- if false then -- Minimap:setViewportRect
--   local mm = lurek.minimap.newMinimap(64, 64, 4)
--   mm:setViewportRect(100, 100, 800, 600)
--   lurek.log.info("viewport rect set", "minimap")
-- end

--@api-stub: LMinimap:showPath
-- Draws a path as a sequence of connected line segments on the minimap overlay.
-- Pass a table of {x,y} grid cell positions; cleared by clearPath().
-- if false then -- Minimap:showPath
--   local mm = lurek.minimap.newMinimap(32, 32, 4)
--   local path = {{5,5},{10,10},{20,15}}
--   mm:showPath(path, {1, 0.5, 0, 1})
--   lurek.log.info("path shown", "minimap")
-- end

