-- content/examples/minimap.lua
-- Scaffolded coverage of the lurek.minimap API (56 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/minimap_api.rs   (Lua binding, arg types, return shape)
--   * src/minimap/                 (semantics, side effects)
--   * docs/specs/minimap.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/minimap.lua

-- ── lurek.minimap.* functions ──

--@api-stub: lurek.minimap.newMinimap
-- Creates a new grid-based minimap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: lurek.minimap.newMinimap
  local _todo = "TODO: write a real lurek.minimap.newMinimap usage example"
  print(_todo)
end

-- ── Minimap methods ──

--@api-stub: Minimap:getGridWidth
-- Returns the grid width in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getGridWidth
  local _todo = "TODO: write a real Minimap:getGridWidth usage example"
  print(_todo)
end

--@api-stub: Minimap:getGridHeight
-- Returns the grid height in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getGridHeight
  local _todo = "TODO: write a real Minimap:getGridHeight usage example"
  print(_todo)
end

--@api-stub: Minimap:getGridSize
-- Returns the grid width and height as two values.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getGridSize
  local _todo = "TODO: write a real Minimap:getGridSize usage example"
  print(_todo)
end

--@api-stub: Minimap:getDisplayWidth
-- Returns the display width in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getDisplayWidth
  local _todo = "TODO: write a real Minimap:getDisplayWidth usage example"
  print(_todo)
end

--@api-stub: Minimap:getDisplayHeight
-- Returns the display height in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getDisplayHeight
  local _todo = "TODO: write a real Minimap:getDisplayHeight usage example"
  print(_todo)
end

--@api-stub: Minimap:getDisplaySize
-- Returns the display width and height as two values.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getDisplaySize
  local _todo = "TODO: write a real Minimap:getDisplaySize usage example"
  print(_todo)
end

--@api-stub: Minimap:setDisplaySize
-- Sets the display size in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setDisplaySize
  local _todo = "TODO: write a real Minimap:setDisplaySize usage example"
  print(_todo)
end

--@api-stub: Minimap:getTerrain
-- Returns the terrain type at a 1-based grid position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getTerrain
  local _todo = "TODO: write a real Minimap:getTerrain usage example"
  print(_todo)
end

--@api-stub: Minimap:setTerrainData
-- Sets terrain types from a flat 1-based Lua table of integers (row-major).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setTerrainData
  local _todo = "TODO: write a real Minimap:setTerrainData usage example"
  print(_todo)
end

--@api-stub: Minimap:getTerrainColor
-- Returns the display color for a terrain type as r, g, b, a.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getTerrainColor
  local _todo = "TODO: write a real Minimap:getTerrainColor usage example"
  print(_todo)
end

--@api-stub: Minimap:getTileDescription
-- Returns the hover tooltip string for a terrain type ID, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getTileDescription
  local _todo = "TODO: write a real Minimap:getTileDescription usage example"
  print(_todo)
end

--@api-stub: Minimap:setFogEnabled
-- Enables or disables fog of war.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setFogEnabled
  local _todo = "TODO: write a real Minimap:setFogEnabled usage example"
  print(_todo)
end

--@api-stub: Minimap:isFogEnabled
-- Returns whether fog of war is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:isFogEnabled
  local _todo = "TODO: write a real Minimap:isFogEnabled usage example"
  print(_todo)
end

--@api-stub: Minimap:setFogLevel
-- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setFogLevel
  local _todo = "TODO: write a real Minimap:setFogLevel usage example"
  print(_todo)
end

--@api-stub: Minimap:getFogLevel
-- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getFogLevel
  local _todo = "TODO: write a real Minimap:getFogLevel usage example"
  print(_todo)
end

--@api-stub: Minimap:getFogColor
-- Returns the fog overlay color as r, g, b, a.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getFogColor
  local _todo = "TODO: write a real Minimap:getFogColor usage example"
  print(_todo)
end

--@api-stub: Minimap:setFogData
-- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setFogData
  local _todo = "TODO: write a real Minimap:setFogData usage example"
  print(_todo)
end

--@api-stub: Minimap:isObjectTypeVisible
-- Returns whether an object type (1-based index) is visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:isObjectTypeVisible
  local _todo = "TODO: write a real Minimap:isObjectTypeVisible usage example"
  print(_todo)
end

--@api-stub: Minimap:getObjectTypeCount
-- Returns the number of registered object types.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getObjectTypeCount
  local _todo = "TODO: write a real Minimap:getObjectTypeCount usage example"
  print(_todo)
end

--@api-stub: Minimap:removeObject
-- Removes a tracked object by ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:removeObject
  local _todo = "TODO: write a real Minimap:removeObject usage example"
  print(_todo)
end

--@api-stub: Minimap:clearObjects
-- Removes all tracked objects.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:clearObjects
  local _todo = "TODO: write a real Minimap:clearObjects usage example"
  print(_todo)
end

--@api-stub: Minimap:getObjectCount
-- Returns the number of tracked objects.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getObjectCount
  local _todo = "TODO: write a real Minimap:getObjectCount usage example"
  print(_todo)
end

--@api-stub: Minimap:getOwnerColor
-- Returns the display color for an owner/faction as r, g, b, a.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getOwnerColor
  local _todo = "TODO: write a real Minimap:getOwnerColor usage example"
  print(_todo)
end

--@api-stub: Minimap:setColorMode
-- Sets the color mode ("terrain" or "political").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setColorMode
  local _todo = "TODO: write a real Minimap:setColorMode usage example"
  print(_todo)
end

--@api-stub: Minimap:getColorMode
-- Returns the current color mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getColorMode
  local _todo = "TODO: write a real Minimap:getColorMode usage example"
  print(_todo)
end

--@api-stub: Minimap:setZoom
-- Sets the zoom level (minimum 0.1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setZoom
  local _todo = "TODO: write a real Minimap:setZoom usage example"
  print(_todo)
end

--@api-stub: Minimap:getZoom
-- Returns the current zoom level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getZoom
  local _todo = "TODO: write a real Minimap:getZoom usage example"
  print(_todo)
end

--@api-stub: Minimap:setCenter
-- Sets the center of the minimap view in grid coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setCenter
  local _todo = "TODO: write a real Minimap:setCenter usage example"
  print(_todo)
end

--@api-stub: Minimap:getCenter
-- Returns the center coordinates as x, y.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getCenter
  local _todo = "TODO: write a real Minimap:getCenter usage example"
  print(_todo)
end

--@api-stub: Minimap:getCenterX
-- Returns the center X coordinate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getCenterX
  local _todo = "TODO: write a real Minimap:getCenterX usage example"
  print(_todo)
end

--@api-stub: Minimap:getCenterY
-- Returns the center Y coordinate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getCenterY
  local _todo = "TODO: write a real Minimap:getCenterY usage example"
  print(_todo)
end

--@api-stub: Minimap:clearViewportRect
-- Clears the viewport rectangle overlay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:clearViewportRect
  local _todo = "TODO: write a real Minimap:clearViewportRect usage example"
  print(_todo)
end

--@api-stub: Minimap:getViewportRect
-- Returns the viewport rectangle as x, y, w, h or nil if not set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getViewportRect
  local _todo = "TODO: write a real Minimap:getViewportRect usage example"
  print(_todo)
end

--@api-stub: Minimap:setViewportVisible
-- Sets whether the viewport rectangle is visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setViewportVisible
  local _todo = "TODO: write a real Minimap:setViewportVisible usage example"
  print(_todo)
end

--@api-stub: Minimap:isViewportVisible
-- Returns whether the viewport rectangle is visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:isViewportVisible
  local _todo = "TODO: write a real Minimap:isViewportVisible usage example"
  print(_todo)
end

--@api-stub: Minimap:getViewportColor
-- Returns the viewport rectangle color as r, g, b, a.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getViewportColor
  local _todo = "TODO: write a real Minimap:getViewportColor usage example"
  print(_todo)
end

--@api-stub: Minimap:getPingCount
-- Returns the number of active pings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getPingCount
  local _todo = "TODO: write a real Minimap:getPingCount usage example"
  print(_todo)
end

--@api-stub: Minimap:removeMarker
-- Removes the minimap marker with the given integer ID, if present.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:removeMarker
  local _todo = "TODO: write a real Minimap:removeMarker usage example"
  print(_todo)
end

--@api-stub: Minimap:hasMarker
-- Returns whether a marker with the given ID exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:hasMarker
  local _todo = "TODO: write a real Minimap:hasMarker usage example"
  print(_todo)
end

--@api-stub: Minimap:getMarkerDescription
-- Returns the description of a marker, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getMarkerDescription
  local _todo = "TODO: write a real Minimap:getMarkerDescription usage example"
  print(_todo)
end

--@api-stub: Minimap:getMarkerCount
-- Returns the number of markers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getMarkerCount
  local _todo = "TODO: write a real Minimap:getMarkerCount usage example"
  print(_todo)
end

--@api-stub: Minimap:clearMarkerAnimation
-- Removes the animation from a marker, reverting it to static.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:clearMarkerAnimation
  local _todo = "TODO: write a real Minimap:clearMarkerAnimation usage example"
  print(_todo)
end

--@api-stub: Minimap:clearOverlay
-- Removes all custom geometry from the minimap overlay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:clearOverlay
  local _todo = "TODO: write a real Minimap:clearOverlay usage example"
  print(_todo)
end

--@api-stub: Minimap:clearPath
-- Removes a displayed path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:clearPath
  local _todo = "TODO: write a real Minimap:clearPath usage example"
  print(_todo)
end

--@api-stub: Minimap:setLayer
-- Switches the minimap's active render layer (0-based index).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setLayer
  local _todo = "TODO: write a real Minimap:setLayer usage example"
  print(_todo)
end

--@api-stub: Minimap:getLayer
-- Returns the index of the currently active render layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:getLayer
  local _todo = "TODO: write a real Minimap:getLayer usage example"
  print(_todo)
end

--@api-stub: Minimap:setAntiAlias
-- Sets whether anti-aliasing is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setAntiAlias
  local _todo = "TODO: write a real Minimap:setAntiAlias usage example"
  print(_todo)
end

--@api-stub: Minimap:isAntiAlias
-- Returns whether anti-aliasing is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:isAntiAlias
  local _todo = "TODO: write a real Minimap:isAntiAlias usage example"
  print(_todo)
end

--@api-stub: Minimap:setClickable
-- Sets whether this minimap responds to click hit-testing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:setClickable
  local _todo = "TODO: write a real Minimap:setClickable usage example"
  print(_todo)
end

--@api-stub: Minimap:isClickable
-- Returns whether this minimap responds to click hit-testing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:isClickable
  local _todo = "TODO: write a real Minimap:isClickable usage example"
  print(_todo)
end

--@api-stub: Minimap:update
-- Advances time-based effects by dt seconds (expires pings).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:update
  local _todo = "TODO: write a real Minimap:update usage example"
  print(_todo)
end

--@api-stub: Minimap:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:type
  local _todo = "TODO: write a real Minimap:type usage example"
  print(_todo)
end

--@api-stub: Minimap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:typeOf
  local _todo = "TODO: write a real Minimap:typeOf usage example"
  print(_todo)
end

--@api-stub: Minimap:render
-- Renders the minimap to the screen at the given position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:render
  local _todo = "TODO: write a real Minimap:render usage example"
  print(_todo)
end

--@api-stub: Minimap:drawToImage
-- Renders the minimap grid to a CPU ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/minimap_api.rs and docs/specs/minimap.md).
do  -- TODO: Minimap:drawToImage
  local _todo = "TODO: write a real Minimap:drawToImage usage example"
  print(_todo)
end

