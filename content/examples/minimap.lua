-- content/examples/minimap.lua
-- Practical usage examples for the lurek.minimap API (56 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.minimap.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/minimap.lua

print("[example] lurek.minimap — 56 API entries")

-- ── lurek.minimap.* free functions ──

--@api-stub: lurek.minimap.newMinimap
-- Creates a new grid-based minimap.
-- Call when you need to create a new minimap.
local ok, obj = pcall(function() return lurek.minimap.newMinimap(nil, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.minimap.newMinimap ok=", ok)

-- ── Minimap methods ──

--@api-stub: Minimap:getGridWidth
-- Returns the grid width in cells.
-- Call when you need to read grid width.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getGridWidth() end)
  print("Minimap:getGridWidth ->", ok, result)
end

--@api-stub: Minimap:getGridHeight
-- Returns the grid height in cells.
-- Call when you need to read grid height.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getGridHeight() end)
  print("Minimap:getGridHeight ->", ok, result)
end

--@api-stub: Minimap:getGridSize
-- Returns the grid width and height as two values.
-- Call when you need to read grid size.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getGridSize() end)
  print("Minimap:getGridSize ->", ok, result)
end

--@api-stub: Minimap:getDisplayWidth
-- Returns the display width in pixels.
-- Call when you need to read display width.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getDisplayWidth() end)
  print("Minimap:getDisplayWidth ->", ok, result)
end

--@api-stub: Minimap:getDisplayHeight
-- Returns the display height in pixels.
-- Call when you need to read display height.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getDisplayHeight() end)
  print("Minimap:getDisplayHeight ->", ok, result)
end

--@api-stub: Minimap:getDisplaySize
-- Returns the display width and height as two values.
-- Call when you need to read display size.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getDisplaySize() end)
  print("Minimap:getDisplaySize ->", ok, result)
end

--@api-stub: Minimap:setDisplaySize
-- Sets the display size in pixels.
-- Call when you need to assign display size.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setDisplaySize(100, 100) end)
  print("Minimap:setDisplaySize ->", ok, result)
end

--@api-stub: Minimap:getTerrain
-- Returns the terrain type at a 1-based grid position.
-- Call when you need to read terrain.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getTerrain(0, 0) end)
  print("Minimap:getTerrain ->", ok, result)
end

--@api-stub: Minimap:setTerrainData
-- Sets terrain types from a flat 1-based Lua table of integers (row-major).
-- Call when you need to assign terrain data.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setTerrainData({}) end)
  print("Minimap:setTerrainData ->", ok, result)
end

--@api-stub: Minimap:getTerrainColor
-- Returns the display color for a terrain type as r, g, b, a.
-- Call when you need to read terrain color.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getTerrainColor(nil) end)
  print("Minimap:getTerrainColor ->", ok, result)
end

--@api-stub: Minimap:getTileDescription
-- Returns the hover tooltip string for a terrain type ID, or nil.
-- Call when you need to read tile description.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileDescription(1) end)
  print("Minimap:getTileDescription ->", ok, result)
end

--@api-stub: Minimap:setFogEnabled
-- Enables or disables fog of war.
-- Call when you need to assign fog enabled.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setFogEnabled(nil) end)
  print("Minimap:setFogEnabled ->", ok, result)
end

--@api-stub: Minimap:isFogEnabled
-- Returns whether fog of war is enabled.
-- Call when you need to check is fog enabled.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:isFogEnabled() end)
  print("Minimap:isFogEnabled ->", ok, result)
end

--@api-stub: Minimap:setFogLevel
-- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- Call when you need to assign fog level.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setFogLevel(0, 0, nil) end)
  print("Minimap:setFogLevel ->", ok, result)
end

--@api-stub: Minimap:getFogLevel
-- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- Call when you need to read fog level.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getFogLevel(0, 0) end)
  print("Minimap:getFogLevel ->", ok, result)
end

--@api-stub: Minimap:getFogColor
-- Returns the fog overlay color as r, g, b, a.
-- Call when you need to read fog color.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getFogColor() end)
  print("Minimap:getFogColor ->", ok, result)
end

--@api-stub: Minimap:setFogData
-- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
-- Call when you need to assign fog data.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setFogData({}) end)
  print("Minimap:setFogData ->", ok, result)
end

--@api-stub: Minimap:isObjectTypeVisible
-- Returns whether an object type (1-based index) is visible.
-- Call when you need to check is object type visible.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:isObjectTypeVisible(1) end)
  print("Minimap:isObjectTypeVisible ->", ok, result)
end

--@api-stub: Minimap:getObjectTypeCount
-- Returns the number of registered object types.
-- Call when you need to read object type count.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getObjectTypeCount() end)
  print("Minimap:getObjectTypeCount ->", ok, result)
end

--@api-stub: Minimap:removeObject
-- Removes a tracked object by ID.
-- Call when you need to remove object.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:removeObject(1) end)
  print("Minimap:removeObject ->", ok, result)
end

--@api-stub: Minimap:clearObjects
-- Removes all tracked objects.
-- Call when you need to invoke clear objects.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:clearObjects() end)
  print("Minimap:clearObjects ->", ok, result)
end

--@api-stub: Minimap:getObjectCount
-- Returns the number of tracked objects.
-- Call when you need to read object count.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getObjectCount() end)
  print("Minimap:getObjectCount ->", ok, result)
end

--@api-stub: Minimap:getOwnerColor
-- Returns the display color for an owner/faction as r, g, b, a.
-- Call when you need to read owner color.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getOwnerColor(nil) end)
  print("Minimap:getOwnerColor ->", ok, result)
end

--@api-stub: Minimap:setColorMode
-- Sets the color mode ("terrain" or "political").
-- Call when you need to assign color mode.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setColorMode(nil) end)
  print("Minimap:setColorMode ->", ok, result)
end

--@api-stub: Minimap:getColorMode
-- Returns the current color mode as a string.
-- Call when you need to read color mode.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getColorMode() end)
  print("Minimap:getColorMode ->", ok, result)
end

--@api-stub: Minimap:setZoom
-- Sets the zoom level (minimum 0.1).
-- Call when you need to assign zoom.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setZoom(nil) end)
  print("Minimap:setZoom ->", ok, result)
end

--@api-stub: Minimap:getZoom
-- Returns the current zoom level.
-- Call when you need to read zoom.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getZoom() end)
  print("Minimap:getZoom ->", ok, result)
end

--@api-stub: Minimap:setCenter
-- Sets the center of the minimap view in grid coordinates.
-- Call when you need to assign center.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setCenter(0, 0) end)
  print("Minimap:setCenter ->", ok, result)
end

--@api-stub: Minimap:getCenter
-- Returns the center coordinates as x, y.
-- Call when you need to read center.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getCenter() end)
  print("Minimap:getCenter ->", ok, result)
end

--@api-stub: Minimap:getCenterX
-- Returns the center X coordinate.
-- Call when you need to read center x.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getCenterX() end)
  print("Minimap:getCenterX ->", ok, result)
end

--@api-stub: Minimap:getCenterY
-- Returns the center Y coordinate.
-- Call when you need to read center y.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getCenterY() end)
  print("Minimap:getCenterY ->", ok, result)
end

--@api-stub: Minimap:clearViewportRect
-- Clears the viewport rectangle overlay.
-- Call when you need to invoke clear viewport rect.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:clearViewportRect() end)
  print("Minimap:clearViewportRect ->", ok, result)
end

--@api-stub: Minimap:getViewportRect
-- Returns the viewport rectangle as x, y, w, h or nil if not set.
-- Call when you need to read viewport rect.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getViewportRect() end)
  print("Minimap:getViewportRect ->", ok, result)
end

--@api-stub: Minimap:setViewportVisible
-- Sets whether the viewport rectangle is visible.
-- Call when you need to assign viewport visible.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setViewportVisible(nil) end)
  print("Minimap:setViewportVisible ->", ok, result)
end

--@api-stub: Minimap:isViewportVisible
-- Returns whether the viewport rectangle is visible.
-- Call when you need to check is viewport visible.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:isViewportVisible() end)
  print("Minimap:isViewportVisible ->", ok, result)
end

--@api-stub: Minimap:getViewportColor
-- Returns the viewport rectangle color as r, g, b, a.
-- Call when you need to read viewport color.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getViewportColor() end)
  print("Minimap:getViewportColor ->", ok, result)
end

--@api-stub: Minimap:getPingCount
-- Returns the number of active pings.
-- Call when you need to read ping count.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getPingCount() end)
  print("Minimap:getPingCount ->", ok, result)
end

--@api-stub: Minimap:removeMarker
-- Removes the minimap marker with the given integer ID, if present.
-- Call when you need to remove marker.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:removeMarker(1) end)
  print("Minimap:removeMarker ->", ok, result)
end

--@api-stub: Minimap:hasMarker
-- Returns whether a marker with the given ID exists.
-- Call when you need to check has marker.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:hasMarker(1) end)
  print("Minimap:hasMarker ->", ok, result)
end

--@api-stub: Minimap:getMarkerDescription
-- Returns the description of a marker, or nil.
-- Call when you need to read marker description.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getMarkerDescription(1) end)
  print("Minimap:getMarkerDescription ->", ok, result)
end

--@api-stub: Minimap:getMarkerCount
-- Returns the number of markers.
-- Call when you need to read marker count.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getMarkerCount() end)
  print("Minimap:getMarkerCount ->", ok, result)
end

--@api-stub: Minimap:clearMarkerAnimation
-- Removes the animation from a marker, reverting it to static.
-- Call when you need to invoke clear marker animation.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:clearMarkerAnimation(1) end)
  print("Minimap:clearMarkerAnimation ->", ok, result)
end

--@api-stub: Minimap:clearOverlay
-- Removes all custom geometry from the minimap overlay.
-- Call when you need to invoke clear overlay.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:clearOverlay() end)
  print("Minimap:clearOverlay ->", ok, result)
end

--@api-stub: Minimap:clearPath
-- Removes a displayed path.
-- If id is nil, all paths are removed.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:clearPath(1) end)
  print("Minimap:clearPath ->", ok, result)
end

--@api-stub: Minimap:setLayer
-- Switches the minimap's active render layer (0-based index).
-- Call when you need to assign layer.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setLayer(nil) end)
  print("Minimap:setLayer ->", ok, result)
end

--@api-stub: Minimap:getLayer
-- Returns the index of the currently active render layer.
-- Call when you need to read layer.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayer() end)
  print("Minimap:getLayer ->", ok, result)
end

--@api-stub: Minimap:setAntiAlias
-- Sets whether anti-aliasing is enabled.
-- Call when you need to assign anti alias.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setAntiAlias(nil) end)
  print("Minimap:setAntiAlias ->", ok, result)
end

--@api-stub: Minimap:isAntiAlias
-- Returns whether anti-aliasing is enabled.
-- Call when you need to check is anti alias.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:isAntiAlias() end)
  print("Minimap:isAntiAlias ->", ok, result)
end

--@api-stub: Minimap:setClickable
-- Sets whether this minimap responds to click hit-testing.
-- Call when you need to assign clickable.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:setClickable(nil) end)
  print("Minimap:setClickable ->", ok, result)
end

--@api-stub: Minimap:isClickable
-- Returns whether this minimap responds to click hit-testing.
-- Call when you need to check is clickable.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:isClickable() end)
  print("Minimap:isClickable ->", ok, result)
end

--@api-stub: Minimap:update
-- Advances time-based effects by dt seconds (expires pings).
-- Call when you need to invoke update.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Minimap:update ->", ok, result)
end

--@api-stub: Minimap:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Minimap:type ->", ok, result)
end

--@api-stub: Minimap:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Minimap:typeOf ->", ok, result)
end

--@api-stub: Minimap:render
-- Renders the minimap to the screen at the given position.
-- Call when you need to invoke render.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:render(0, 0) end)
  print("Minimap:render ->", ok, result)
end

--@api-stub: Minimap:drawToImage
-- Renders the minimap grid to a CPU ImageData.
-- Call when you need to render to image.
-- Build a Minimap via the appropriate lurek.minimap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.minimap.newMinimap(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(nil) end)
  print("Minimap:drawToImage ->", ok, result)
end

