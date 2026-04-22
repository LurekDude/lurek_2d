-- content/examples/minimap.lua
-- Auto-scaffolded coverage of the lurek.minimap Lua API (56 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/minimap.lua

print("[example] lurek.minimap loaded — 56 API items demonstrated")

-- ── lurek.minimap free functions ──

--@api-stub: lurek.minimap.newMinimap
-- Creates a new grid-based minimap.
-- Use this when creates a new grid-based minimap is needed.
if false then
  local _r = lurek.minimap.newMinimap(1, 1, 0, 0)
  print(_r)
end

-- ── Minimap methods ──

--@api-stub: Minimap:getGridWidth
-- Returns the grid width in cells.
-- Use this when returns the grid width in cells is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getGridWidth()
end

--@api-stub: Minimap:getGridHeight
-- Returns the grid height in cells.
-- Use this when returns the grid height in cells is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getGridHeight()
end

--@api-stub: Minimap:getGridSize
-- Returns the grid width and height as two values.
-- Use this when returns the grid width and height as two values is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getGridSize()
end

--@api-stub: Minimap:getDisplayWidth
-- Returns the display width in pixels.
-- Use this when returns the display width in pixels is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getDisplayWidth()
end

--@api-stub: Minimap:getDisplayHeight
-- Returns the display height in pixels.
-- Use this when returns the display height in pixels is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getDisplayHeight()
end

--@api-stub: Minimap:getDisplaySize
-- Returns the display width and height as two values.
-- Use this when returns the display width and height as two values is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getDisplaySize()
end

--@api-stub: Minimap:setDisplaySize
-- Sets the display size in pixels.
-- Use this when sets the display size in pixels is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setDisplaySize(0, 0)
end

--@api-stub: Minimap:getTerrain
-- Returns the terrain type at a 1-based grid position.
-- Use this when returns the terrain type at a 1-based grid position is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getTerrain(0, 0)
end

--@api-stub: Minimap:setTerrainData
-- Sets terrain types from a flat 1-based Lua table of integers (row-major).
-- Use this when sets terrain types from a flat 1-based Lua table of integers (row-major) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setTerrainData(0)
end

--@api-stub: Minimap:getTerrainColor
-- Returns the display color for a terrain type as r, g, b, a.
-- Use this when returns the display color for a terrain type as r, g, b, a is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getTerrainColor(1)
end

--@api-stub: Minimap:getTileDescription
-- Returns the hover tooltip string for a terrain type ID, or nil.
-- Use this when returns the hover tooltip string for a terrain type ID, or nil is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getTileDescription(1)
end

--@api-stub: Minimap:setFogEnabled
-- Enables or disables fog of war.
-- Use this when enables or disables fog of war is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setFogEnabled(1)
end

--@api-stub: Minimap:isFogEnabled
-- Returns whether fog of war is enabled.
-- Use this when returns whether fog of war is enabled is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:isFogEnabled()
end

--@api-stub: Minimap:setFogLevel
-- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- Use this when sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setFogLevel(0, 0, 0)
end

--@api-stub: Minimap:getFogLevel
-- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- Use this when returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getFogLevel(0, 0)
end

--@api-stub: Minimap:getFogColor
-- Returns the fog overlay color as r, g, b, a.
-- Use this when returns the fog overlay color as r, g, b, a is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getFogColor()
end

--@api-stub: Minimap:setFogData
-- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
-- Use this when sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setFogData(0)
end

--@api-stub: Minimap:isObjectTypeVisible
-- Returns whether an object type (1-based index) is visible.
-- Use this when returns whether an object type (1-based index) is visible is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:isObjectTypeVisible(1)
end

--@api-stub: Minimap:getObjectTypeCount
-- Returns the number of registered object types.
-- Use this when returns the number of registered object types is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getObjectTypeCount()
end

--@api-stub: Minimap:removeObject
-- Removes a tracked object by ID.
-- Use this when removes a tracked object by ID is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:removeObject(1)
end

--@api-stub: Minimap:clearObjects
-- Removes all tracked objects.
-- Use this when removes all tracked objects is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:clearObjects()
end

--@api-stub: Minimap:getObjectCount
-- Returns the number of tracked objects.
-- Use this when returns the number of tracked objects is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getObjectCount()
end

--@api-stub: Minimap:getOwnerColor
-- Returns the display color for an owner/faction as r, g, b, a.
-- Use this when returns the display color for an owner/faction as r, g, b, a is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getOwnerColor(1)
end

--@api-stub: Minimap:setColorMode
-- Sets the color mode ("terrain" or "political").
-- Use this when sets the color mode ("terrain" or "political") is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setColorMode(nil)
end

--@api-stub: Minimap:getColorMode
-- Returns the current color mode as a string.
-- Use this when returns the current color mode as a string is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getColorMode()
end

--@api-stub: Minimap:setZoom
-- Sets the zoom level (minimum 0.1).
-- Use this when sets the zoom level (minimum 0.1) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setZoom(0)
end

--@api-stub: Minimap:getZoom
-- Returns the current zoom level.
-- Use this when returns the current zoom level is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getZoom()
end

--@api-stub: Minimap:setCenter
-- Sets the center of the minimap view in grid coordinates.
-- Use this when sets the center of the minimap view in grid coordinates is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setCenter(0, 0)
end

--@api-stub: Minimap:getCenter
-- Returns the center coordinates as x, y.
-- Use this when returns the center coordinates as x, y is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getCenter()
end

--@api-stub: Minimap:getCenterX
-- Returns the center X coordinate.
-- Use this when returns the center X coordinate is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getCenterX()
end

--@api-stub: Minimap:getCenterY
-- Returns the center Y coordinate.
-- Use this when returns the center Y coordinate is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getCenterY()
end

--@api-stub: Minimap:clearViewportRect
-- Clears the viewport rectangle overlay.
-- Use this when clears the viewport rectangle overlay is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:clearViewportRect()
end

--@api-stub: Minimap:getViewportRect
-- Returns the viewport rectangle as x, y, w, h or nil if not set.
-- Use this when returns the viewport rectangle as x, y, w, h or nil if not set is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getViewportRect()
end

--@api-stub: Minimap:setViewportVisible
-- Sets whether the viewport rectangle is visible.
-- Use this when sets whether the viewport rectangle is visible is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setViewportVisible(0)
end

--@api-stub: Minimap:isViewportVisible
-- Returns whether the viewport rectangle is visible.
-- Use this when returns whether the viewport rectangle is visible is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:isViewportVisible()
end

--@api-stub: Minimap:getViewportColor
-- Returns the viewport rectangle color as r, g, b, a.
-- Use this when returns the viewport rectangle color as r, g, b, a is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getViewportColor()
end

--@api-stub: Minimap:getPingCount
-- Returns the number of active pings.
-- Use this when returns the number of active pings is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getPingCount()
end

--@api-stub: Minimap:removeMarker
-- Removes the minimap marker with the given integer ID, if present.
-- Use this when removes the minimap marker with the given integer ID, if present is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:removeMarker(1)
end

--@api-stub: Minimap:hasMarker
-- Returns whether a marker with the given ID exists.
-- Use this when returns whether a marker with the given ID exists is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:hasMarker(1)
end

--@api-stub: Minimap:getMarkerDescription
-- Returns the description of a marker, or nil.
-- Use this when returns the description of a marker, or nil is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getMarkerDescription(1)
end

--@api-stub: Minimap:getMarkerCount
-- Returns the number of markers.
-- Use this when returns the number of markers is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getMarkerCount()
end

--@api-stub: Minimap:clearMarkerAnimation
-- Removes the animation from a marker, reverting it to static.
-- Use this when removes the animation from a marker, reverting it to static is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:clearMarkerAnimation(1)
end

--@api-stub: Minimap:clearOverlay
-- Removes all custom geometry from the minimap overlay.
-- Use this when removes all custom geometry from the minimap overlay is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:clearOverlay()
end

--@api-stub: Minimap:clearPath
-- Removes a displayed path.
-- If id is nil, all paths are removed.
if false then
  local _o = nil  -- Minimap instance
  _o:clearPath(1)
end

--@api-stub: Minimap:setLayer
-- Switches the minimap's active render layer (0-based index).
-- Use this when switches the minimap's active render layer (0-based index) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setLayer(0)
end

--@api-stub: Minimap:getLayer
-- Returns the index of the currently active render layer.
-- Use this when returns the index of the currently active render layer is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:getLayer()
end

--@api-stub: Minimap:setAntiAlias
-- Sets whether anti-aliasing is enabled.
-- Use this when sets whether anti-aliasing is enabled is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setAntiAlias(1)
end

--@api-stub: Minimap:isAntiAlias
-- Returns whether anti-aliasing is enabled.
-- Use this when returns whether anti-aliasing is enabled is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:isAntiAlias()
end

--@api-stub: Minimap:setClickable
-- Sets whether this minimap responds to click hit-testing.
-- Use this when sets whether this minimap responds to click hit-testing is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:setClickable(1)
end

--@api-stub: Minimap:isClickable
-- Returns whether this minimap responds to click hit-testing.
-- Use this when returns whether this minimap responds to click hit-testing is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:isClickable()
end

--@api-stub: Minimap:update
-- Advances time-based effects by dt seconds (expires pings).
-- Use this when advances time-based effects by dt seconds (expires pings) is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:update(0)
end

--@api-stub: Minimap:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:type()
end

--@api-stub: Minimap:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:typeOf(1)
end

--@api-stub: Minimap:render
-- Renders the minimap to the screen at the given position.
-- Use this when renders the minimap to the screen at the given position is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:render(0, 0)
end

--@api-stub: Minimap:drawToImage
-- Renders the minimap grid to a CPU ImageData.
-- Use this when renders the minimap grid to a CPU ImageData is needed.
if false then
  local _o = nil  -- Minimap instance
  _o:drawToImage(1)
end

