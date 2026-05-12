# minimap

## General Info

- Module group: `Feature Systems`
- Source path: `src/minimap/`
- Lua API path(s): `src/lua_api/minimap_api.rs`
- Primary Lua namespace: `lurek.minimap`
- Rust test path(s): tests/rust/game/minimap_tests.rs
- Lua test path(s): tests/lua/unit/test_minimap.lua, tests/lua/evidence/test_evidence_minimap.lua

## Summary

The `minimap` module owns a grid-backed minimap state model plus the CPU/GPU command builders used to visualize that state for gameplay HUDs, screenshots, and evidence tests.

This module primarily collaborates with `camera`, `image`, `province`, `render`, and `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

Recent additions in this slice include shared fog visibility handling, camera-tracking helpers, radius-based fog reveal, texture-backed marker/object icons, and a single render-command path used by both `render()` and evidence-oriented validation.

## Files

- `minimap.rs`: Implements the main `Minimap` state container, including terrain cells, fog, tracked objects, markers, pings, zoom, pan, and coordinate transforms.
- `mod.rs`: Declares the minimap submodules and re-exports the core minimap and support types.
- `province_adapter.rs`: Minimap ↔ province adapter (optional coupling layer).
- `render.rs`: Generates render commands for the minimap background, cells, viewport rectangle, and animated pings.
- `types.rs`: Defines shared enums and data records such as fog levels, color modes, objects, pings, and markers.

## Types

- `Minimap` (`struct`, `minimap.rs`): The main grid-based minimap model. It owns terrain, visibility, tracked entities, overlays, and minimap-space conversions.
- `ColorMode` (`enum`, `types.rs`): Chooses how minimap cells are colored, such as terrain-driven versus owner-driven display.
- `FogLevel` (`enum`, `types.rs`): Encodes whether a minimap cell is hidden, explored, or currently visible.
- `MinimapObjectType` (`struct`, `types.rs`): A registered object type with a display color and visibility toggle.
- `MinimapObject` (`struct`, `types.rs`): A tracked world object projected onto the minimap with position, type, and owner metadata.
- `MinimapPing` (`struct`, `types.rs`): A temporary animated alert marker used for events or attention cues.
- `MinimapMarker` (`struct`, `types.rs`): A persistent named marker with descriptive text for locations of interest.
- `MarkerAnimation` (`enum`, `types.rs`): Animation applied to a minimap marker icon.
- `OverlayShape` (`enum`, `types.rs`): A custom geometric shape drawn on top of the minimap in grid space.
- `OverlayPath` (`struct`, `types.rs`): A pathfinding route overlay displayed on the minimap.
- `LayerData` (`struct`, `types.rs`): Per-layer terrain data for multi-layer minimap rendering.

## Functions

- `Minimap::new` (`minimap.rs`): Create a new minimap with the given grid and display dimensions.
- `Minimap::grid_width` (`minimap.rs`): Returns the grid width in cells.
- `Minimap::grid_height` (`minimap.rs`): Returns the grid height in cells.
- `Minimap::grid_size` (`minimap.rs`): Returns the total number of grid cells.
- `Minimap::display_width` (`minimap.rs`): Returns the display width in pixels.
- `Minimap::display_height` (`minimap.rs`): Returns the display height in pixels.
- `Minimap::set_display_size` (`minimap.rs`): Set the display size in pixels.
- `Minimap::set_terrain` (`minimap.rs`): Set the terrain type at a grid position (0-based internally).
- `Minimap::get_terrain` (`minimap.rs`): Get the terrain type at a grid position.
- `Minimap::set_terrain_data` (`minimap.rs`): Bulk-set terrain types from a flat slice (row-major, length = gridW × gridH).
- `Minimap::set_terrain_color` (`minimap.rs`): Set the display color for a terrain type.
- `Minimap::get_terrain_color` (`minimap.rs`): Get the display color for a terrain type (grey `[0.5, 0.5, 0.5, 1.0]` if unset).
- `Minimap::set_tile_description` (`minimap.rs`): Set a hover tooltip string for a terrain type ID.
- `Minimap::get_tile_description` (`minimap.rs`): Get the hover tooltip string for a terrain type ID.
- `Minimap::set_fog_enabled` (`minimap.rs`): Enable or disable fog of war.
- `Minimap::fog_enabled` (`minimap.rs`): Returns whether fog of war is enabled.
- `Minimap::set_fog_level` (`minimap.rs`): Set the fog level at a grid position.
- `Minimap::get_fog_level` (`minimap.rs`): Get the fog level at a grid position.
- `Minimap::set_fog_color` (`minimap.rs`): Set the fog overlay color (RGBA).
- `Minimap::fog_color` (`minimap.rs`): Get the fog overlay color.
- `Minimap::set_fog_data` (`minimap.rs`): Set the entire fog grid from a flat byte array (0=hidden, 1=explored, 2=visible).
- `Minimap::add_object_type` (`minimap.rs`): Register a new object type and return its 0-based index.
- `Minimap::set_object_type_visible` (`minimap.rs`): Set whether an object type is visible on the minimap.
- `Minimap::is_object_type_visible` (`minimap.rs`): Returns whether an object type is visible.
- `Minimap::object_type_count` (`minimap.rs`): Get the number of registered object types.
- `Minimap::set_object` (`minimap.rs`): Set or update a tracked object on the minimap.
- `Minimap::remove_object` (`minimap.rs`): Remove a tracked object by ID.
- `Minimap::clear_objects` (`minimap.rs`): Remove all tracked objects.
- `Minimap::object_count` (`minimap.rs`): Get the number of tracked objects.
- `Minimap::set_owner_color` (`minimap.rs`): Set the display color for an owner/faction.
- `Minimap::get_owner_color` (`minimap.rs`): Get the display color for an owner/faction (grey `[0.8, 0.8, 0.8, 1.0]` if unset).
- `Minimap::set_color_mode` (`minimap.rs`): Set the color mode (`Terrain` or `Political`).
- `Minimap::color_mode` (`minimap.rs`): Get the current color mode.
- `Minimap::set_zoom` (`minimap.rs`): Set the zoom level (minimum 0.1).
- `Minimap::zoom` (`minimap.rs`): Get the current zoom level.
- `Minimap::set_center` (`minimap.rs`): Set the center of the minimap view in grid coordinates.
- `Minimap::center_x` (`minimap.rs`): Get the center X coordinate.
- `Minimap::center_y` (`minimap.rs`): Get the center Y coordinate.
- `Minimap::set_viewport_rect` (`minimap.rs`): Set the viewport rectangle overlay (in grid coordinates).
- `Minimap::clear_viewport_rect` (`minimap.rs`): Clear the viewport rectangle overlay.
- `Minimap::viewport_rect` (`minimap.rs`): Get the viewport rectangle, if set.
- `Minimap::set_viewport_visible` (`minimap.rs`): Set whether the viewport rectangle is visible.
- `Minimap::viewport_visible` (`minimap.rs`): Returns whether the viewport rectangle is visible.
- `Minimap::set_viewport_color` (`minimap.rs`): Set the viewport rectangle color.
- `Minimap::viewport_color` (`minimap.rs`): Get the viewport rectangle color.
- `Minimap::add_ping` (`minimap.rs`): Add an animated ping at grid coordinates.
- `Minimap::ping_count` (`minimap.rs`): Get the number of active pings.
- `Minimap::pings` (`minimap.rs`): Return a slice of all active pings.
- `Minimap::markers_iter` (`minimap.rs`): Return an iterator over all markers.
- `Minimap::add_marker` (`minimap.rs`): Add a persistent marker and return its auto-assigned ID.
- `Minimap::remove_marker` (`minimap.rs`): Remove a marker by ID.
- `Minimap::has_marker` (`minimap.rs`): Check if a marker with the given ID exists.
- `Minimap::get_marker_description` (`minimap.rs`): Get the description of a marker, if it exists.
- `Minimap::marker_count` (`minimap.rs`): Get the number of markers.
- `Minimap::set_marker_animation` (`minimap.rs`): Attach an animation to a marker.
- `Minimap::clear_marker_animation` (`minimap.rs`): Remove the animation from a marker, reverting it to static.
- `Minimap::draw_line` (`minimap.rs`): Push a line segment onto the effect layer.
- `Minimap::draw_rect` (`minimap.rs`): Push a rectangle onto the effect layer.
- `Minimap::clear_overlay` (`minimap.rs`): Remove all custom geometry from the effect layer.
- `Minimap::overlay_shapes` (`minimap.rs`): Return a slice of all overlay shapes for the current frame.
- `Minimap::show_path` (`minimap.rs`): Display a pathfinding route on the minimap and return its auto-assigned ID.
- `Minimap::clear_path` (`minimap.rs`): Remove a displayed path.
- `Minimap::paths` (`minimap.rs`): Return a slice of all active path overlays.
- `Minimap::set_layer` (`minimap.rs`): Switch the minimap's active render layer.
- `Minimap::get_layer` (`minimap.rs`): Return the index of the currently active render layer.
- `Minimap::set_layer_data` (`minimap.rs`): Store tile/cell data for a specific layer index.
- `Minimap::layer_data` (`minimap.rs`): Return the layer data for the given index, if it exists.
- `Minimap::layer_count` (`minimap.rs`): Return the number of stored layers.
- `Minimap::set_anti_alias` (`minimap.rs`): Set whether anti-aliasing is enabled.
- `Minimap::anti_alias` (`minimap.rs`): Returns whether anti-aliasing is enabled.
- `Minimap::set_clickable` (`minimap.rs`): Set whether this minimap responds to click hit-testing.
- `Minimap::is_clickable` (`minimap.rs`): Returns whether this minimap responds to click hit-testing.
- `Minimap::screen_to_grid` (`minimap.rs`): Convert screen coordinates to grid coordinates.
- `Minimap::grid_to_screen` (`minimap.rs`): Convert grid coordinates to screen coordinates.
- `Minimap::get_hover_info` (`minimap.rs`): Get hover tooltip text for the element under the given screen coordinates.
- `Minimap::update` (`minimap.rs`): Advance time-based effects: decrement ping timers and remove expired pings, and advance animation phases on all animated markers.
- `Minimap::draw_to_image` (`minimap.rs`): Renders the minimap to an `ImageData` for evidence/testing.
- `Minimap::build_render_commands` (`minimap.rs`): Generates GPU `RenderCommand`s for the minimap at the given screen position.
- `apply_terrain` (`province_adapter.rs`): Projects province terrain IDs into minimap terrain grid.
- `apply_visibility` (`province_adapter.rs`): Projects province visibility state into minimap fog cells.
- `apply_terrain_palette` (`province_adapter.rs`): Pushes terrain-type color palette inferred from province styles.
- `Minimap::generate_render_commands` (`render.rs`): Generate render commands to draw the minimap overlay at the given screen position.
- `ColorMode::parse_mode` (`types.rs`): Parse a color mode from its string name.
- `ColorMode::as_str` (`types.rs`): Return the string name of this color mode.
- `FogLevel::from_u8` (`types.rs`): Convert a raw `u8` value (0/1/2) into a `FogLevel`.

## Lua API Reference

- Binding path(s): `src/lua_api/minimap_api.rs`
- Namespace: `lurek.minimap`

### Module Functions
- `lurek.minimap.newMinimap`: Creates a new grid-based minimap.

### `LMinimap` Methods
- `LMinimap:getGridWidth`: Returns the grid width in cells.
- `LMinimap:getGridHeight`: Returns the grid height in cells.
- `LMinimap:getGridSize`: Returns the grid width and height as two values.
- `LMinimap:getDisplayWidth`: Returns the display width in pixels.
- `LMinimap:getDisplayHeight`: Returns the display height in pixels.
- `LMinimap:getDisplaySize`: Returns the display width and height as two values.
- `LMinimap:setDisplaySize`: Sets the display size in pixels.
- `LMinimap:setTerrain`: Sets the terrain type at a 1-based grid position.
- `LMinimap:getTerrain`: Returns the terrain type at a 1-based grid position.
- `LMinimap:setTerrainData`: Sets terrain types from a flat 1-based Lua table of integers (row-major).
- `LMinimap:setTerrainColor`: Sets the display color for a terrain type.
- `LMinimap:getTerrainColor`: Returns the display color for a terrain type as r, g, b, a.
- `LMinimap:setTileDescription`: Sets a hover tooltip string for a terrain type ID.
- `LMinimap:getTileDescription`: Returns the hover tooltip string for a terrain type ID, or nil.
- `LMinimap:setFogEnabled`: Enables or disables fog of war.
- `LMinimap:isFogEnabled`: Returns whether fog of war is enabled.
- `LMinimap:setFogLevel`: Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
- `LMinimap:getFogLevel`: Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
- `LMinimap:setFogColor`: Sets the fog overlay color.
- `LMinimap:getFogColor`: Returns the fog overlay color as r, g, b, a.
- `LMinimap:setFogData`: Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
- `LMinimap:addObjectType`: Registers a new object type and returns its 1-based index.
- `LMinimap:setObjectTypeVisible`: Sets whether an object type (1-based index) is visible.
- `LMinimap:isObjectTypeVisible`: Returns whether an object type (1-based index) is visible.
- `LMinimap:getObjectTypeCount`: Returns the number of registered object types.
- `LMinimap:setObject`: Sets or updates a tracked object on the minimap.
- `LMinimap:removeObject`: Removes a tracked object by ID.
- `LMinimap:clearObjects`: Removes all tracked objects.
- `LMinimap:getObjectCount`: Returns the number of tracked objects.
- `LMinimap:setOwnerColor`: Sets the display color for an owner/faction.
- `LMinimap:getOwnerColor`: Returns the display color for an owner/faction as r, g, b, a.
- `LMinimap:setColorMode`: Sets the color mode ("terrain" or "political").
- `LMinimap:getColorMode`: Returns the current color mode as a string.
- `LMinimap:setZoom`: Sets the zoom level (minimum 0.1).
- `LMinimap:getZoom`: Returns the current zoom level.
- `LMinimap:setCenter`: Sets the center of the minimap view in grid coordinates.
- `LMinimap:getCenter`: Returns the center coordinates as x, y.
- `LMinimap:getCenterX`: Returns the center X coordinate.
- `LMinimap:getCenterY`: Returns the center Y coordinate.
- `LMinimap:setViewportRect`: Sets the viewport rectangle overlay in grid coordinates.
- `LMinimap:clearViewportRect`: Clears the viewport rectangle overlay.
- `LMinimap:getViewportRect`: Returns the viewport rectangle as x, y, w, h or nil if not set.
- `LMinimap:setViewportVisible`: Sets whether the viewport rectangle is visible.
- `LMinimap:isViewportVisible`: Returns whether the viewport rectangle is visible.
- `LMinimap:setViewportColor`: Sets the viewport rectangle color.
- `LMinimap:getViewportColor`: Returns the viewport rectangle color as r, g, b, a.
- `LMinimap:addPing`: Adds an animated ping at grid coordinates with a duration and optional color.
- `LMinimap:getPingCount`: Returns the number of active pings.
- `LMinimap:addMarker`: Adds a persistent marker and returns its auto-assigned ID.
- `LMinimap:removeMarker`: Removes the minimap marker with the given integer ID, if present.
- `LMinimap:hasMarker`: Returns whether a marker with the given ID exists.
- `LMinimap:getMarkerDescription`: Returns the description of a marker, or nil.
- `LMinimap:getMarkerCount`: Returns the number of markers.
- `LMinimap:setMarkerAnimation`: Attaches an animation to a marker. Does nothing if the ID does not exist.
- `LMinimap:clearMarkerAnimation`: Removes the animation from a marker, reverting it to static.
- `LMinimap:drawLine`: Draws a custom line segment on the minimap overlay.
- `LMinimap:drawRect`: Draws a custom rectangle on the minimap overlay.
- `LMinimap:clearOverlay`: Removes all custom geometry from the minimap overlay.
- `LMinimap:showPath`: Displays a pathfinding route on the minimap and returns its path ID.
- `LMinimap:clearPath`: Removes a displayed path. If id is nil, all paths are removed.
- `LMinimap:setLayer`: Switches the minimap's active render layer (0-based index).
- `LMinimap:getLayer`: Returns the index of the currently active render layer.
- `LMinimap:setLayerData`: Stores tile data for a specific layer index.
- `LMinimap:setAntiAlias`: Sets whether anti-aliasing is enabled.
- `LMinimap:isAntiAlias`: Returns whether anti-aliasing is enabled.
- `LMinimap:setClickable`: Sets whether this minimap responds to click hit-testing.
- `LMinimap:isClickable`: Returns whether this minimap responds to click hit-testing.
- `LMinimap:getHoverInfo`: Returns hover tooltip text for the element under screen coordinates, or nil.
- `LMinimap:screenToGrid`: Converts screen coordinates to grid coordinates.
- `LMinimap:gridToScreen`: Converts grid coordinates to screen coordinates.
- `LMinimap:update`: Advances time-based effects by dt seconds (expires pings).
- `LMinimap:type`: Returns the type name of this object.
- `LMinimap:typeOf`: Returns true if this object is of the given type.
- `LMinimap:render`: Renders the minimap to the screen at the given position.
- `LMinimap:drawToImage`: Renders the minimap grid to a CPU ImageData.

## References

- `image`: Imports or references `image` from `src/image/`.
- `province`: Imports or references `src/province/`. Cross-group dependency from `Feature Systems` into `Edge/Integration`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/minimap/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
