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

- `MinimapIcon` (`struct`, `minimap.rs`): Cached icon dimensions for one object type or marker texture slot.
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

- `Minimap::new` (`minimap.rs`): Create a minimap with the given grid and display dimensions; logs MM01.
- `Minimap::grid_width` (`minimap.rs`): Return the number of grid columns.
- `Minimap::grid_height` (`minimap.rs`): Return the number of grid rows.
- `Minimap::grid_size` (`minimap.rs`): Return the total cell count (`grid_width * grid_height`).
- `Minimap::display_width` (`minimap.rs`): Return the pixel display width.
- `Minimap::display_height` (`minimap.rs`): Return the pixel display height.
- `Minimap::set_display_size` (`minimap.rs`): Update the pixel display dimensions.
- `Minimap::set_terrain` (`minimap.rs`): Set the terrain type for cell `(x, y)`; out-of-bounds writes are silently ignored.
- `Minimap::get_terrain` (`minimap.rs`): Return the terrain type for cell `(x, y)`; returns 0 for out-of-bounds.
- `Minimap::set_terrain_data` (`minimap.rs`): Bulk-write terrain types from a flat slice, clamped to the cell count.
- `Minimap::set_terrain_color` (`minimap.rs`): Register an RGBA colour for a terrain type id.
- `Minimap::get_terrain_color` (`minimap.rs`): Return the colour for a terrain type id; returns mid-grey when unregistered.
- `Minimap::set_tile_description` (`minimap.rs`): Register a human-readable description for a terrain type id.
- `Minimap::get_tile_description` (`minimap.rs`): Return the description string for a terrain type id, or `None` when unregistered.
- `Minimap::set_fog_enabled` (`minimap.rs`): Enable or disable fog-of-war rendering.
- `Minimap::fog_enabled` (`minimap.rs`): Return true when fog-of-war is active.
- `Minimap::set_fog_level` (`minimap.rs`): Set the fog level for cell `(x, y)`; out-of-bounds writes are silently ignored.
- `Minimap::get_fog_level` (`minimap.rs`): Return the fog level for cell `(x, y)`; returns `Hidden` for out-of-bounds.
- `Minimap::set_fog_color` (`minimap.rs`): Set the RGBA tint colour used for hidden fog cells.
- `Minimap::fog_color` (`minimap.rs`): Return the current fog tint colour.
- `Minimap::set_fog_data` (`minimap.rs`): Bulk-write raw fog bytes from a flat slice; values are clamped to `[0, 2]`.
- `Minimap::fog_multiplier` (`minimap.rs`): Return the colour-multiplier for cell `(x, y)` based on fog state: 1.0/0.5/0.15.
- `Minimap::add_object_type` (`minimap.rs`): Register a new object type with a name and base colour; returns its type index.
- `Minimap::set_object_type_texture` (`minimap.rs`): Assign a texture icon to an object type; silently ignored when `type_index` is out of range.
- `Minimap::clear_object_type_texture` (`minimap.rs`): Remove the custom icon from an object type, reverting it to colour-dot rendering.
- `Minimap::set_object_type_visible` (`minimap.rs`): Show or hide all objects of the given type.
- `Minimap::is_object_type_visible` (`minimap.rs`): Return true when objects of the given type are visible.
- `Minimap::object_type_count` (`minimap.rs`): Return the number of registered object types.
- `Minimap::set_object` (`minimap.rs`): Insert or update a minimap object with a type index and owner.
- `Minimap::remove_object` (`minimap.rs`): Remove object `id`; returns true when an object was actually removed.
- `Minimap::clear_objects` (`minimap.rs`): Remove all objects from the map.
- `Minimap::object_count` (`minimap.rs`): Return the number of live objects.
- `Minimap::objects_iter` (`minimap.rs`): Iterate over all live objects; used by the renderer.
- `Minimap::object_type` (`minimap.rs`): Return the object type descriptor for `type_index`, or `None` when out of range.
- `Minimap::set_owner_color` (`minimap.rs`): Register an RGBA colour for an owner id used in political colour mode.
- `Minimap::get_owner_color` (`minimap.rs`): Return the colour for an owner id; returns light-grey when unregistered.
- `Minimap::set_color_mode` (`minimap.rs`): Set whether cells are coloured by terrain type or by object owner.
- `Minimap::color_mode` (`minimap.rs`): Return the active colour mode.
- `Minimap::set_zoom` (`minimap.rs`): Set the zoom factor; clamped to a minimum of 0.1.
- `Minimap::zoom` (`minimap.rs`): Return the current zoom factor.
- `Minimap::set_center` (`minimap.rs`): Set the world-space centre the minimap is panned to.
- `Minimap::track_camera` (`minimap.rs`): Sync the minimap centre and viewport rect from a `Camera2D`.
- `Minimap::reveal_radius` (`minimap.rs`): Mark all cells within `radius` grid units of `(cx, cy)` as `Visible`.
- `Minimap::center_x` (`minimap.rs`): Return the world-space X coordinate the minimap is centred on.
- `Minimap::center_y` (`minimap.rs`): Return the world-space Y coordinate the minimap is centred on.
- `Minimap::set_viewport_rect` (`minimap.rs`): Set the viewport outline rectangle as `(x, y, w, h)` in world coordinates.
- `Minimap::clear_viewport_rect` (`minimap.rs`): Remove the viewport outline rectangle.
- `Minimap::viewport_rect` (`minimap.rs`): Return the current viewport outline rectangle, or `None` when cleared.
- `Minimap::set_viewport_visible` (`minimap.rs`): Show or hide the viewport outline rectangle.
- `Minimap::viewport_visible` (`minimap.rs`): Return true when the viewport outline is visible.
- `Minimap::set_viewport_color` (`minimap.rs`): Set the RGBA colour of the viewport outline rectangle.
- `Minimap::viewport_color` (`minimap.rs`): Return the viewport outline colour.
- `Minimap::add_ping` (`minimap.rs`): Spawn a timed ping at `(x, y)` that fades over `duration` seconds.
- `Minimap::ping_count` (`minimap.rs`): Return the number of active pings.
- `Minimap::pings` (`minimap.rs`): Return the slice of active pings; used by the renderer.
- `Minimap::markers_iter` (`minimap.rs`): Iterate over all markers; used by the Lua API.
- `Minimap::markers_with_ids` (`minimap.rs`): Iterate over markers with their ids; used by the renderer.
- `Minimap::add_marker` (`minimap.rs`): Add a named marker at `(x, y)` and return its auto-assigned id.
- `Minimap::remove_marker` (`minimap.rs`): Remove marker `id` and its optional icon; returns true when a marker was removed.
- `Minimap::set_marker_texture` (`minimap.rs`): Assign a texture icon to an existing marker; silently ignored when `id` is unknown.
- `Minimap::clear_marker_texture` (`minimap.rs`): Remove the custom icon from marker `id`, reverting it to cross rendering.
- `Minimap::has_marker` (`minimap.rs`): Return true when marker `id` exists.
- `Minimap::get_marker_description` (`minimap.rs`): Return the description string for marker `id`, or `None` when not found.
- `Minimap::marker_count` (`minimap.rs`): Return the total number of markers.
- `Minimap::set_marker_animation` (`minimap.rs`): Attach a blink, pulse, or rotation animation to marker `id`.
- `Minimap::clear_marker_animation` (`minimap.rs`): Remove any animation from marker `id`.
- `Minimap::draw_line` (`minimap.rs`): Append a line segment to the overlay shape list.
- `Minimap::draw_rect` (`minimap.rs`): Append a rectangle outline to the overlay shape list.
- `Minimap::clear_overlay` (`minimap.rs`): Clear all overlay shapes.
- `Minimap::overlay_shapes` (`minimap.rs`): Return the current overlay shape list; used by the renderer.
- `Minimap::show_path` (`minimap.rs`): Add a named polyline path and return its auto-assigned id.
- `Minimap::clear_path` (`minimap.rs`): Remove a specific path by id, or all paths when `id` is `None`.
- `Minimap::paths` (`minimap.rs`): Return all active overlay paths; used by the renderer.
- `Minimap::set_layer` (`minimap.rs`): Switch the active render layer by index.
- `Minimap::get_layer` (`minimap.rs`): Return the active render layer index.
- `Minimap::set_layer_data` (`minimap.rs`): Write cell data for a layer, auto-extending the layer list as needed.
- `Minimap::layer_data` (`minimap.rs`): Return the cell data for a layer, or `None` when that layer index is unused.
- `Minimap::layer_count` (`minimap.rs`): Return the number of allocated layers.
- `Minimap::set_anti_alias` (`minimap.rs`): Enable or disable anti-aliased rendering for the minimap texture.
- `Minimap::anti_alias` (`minimap.rs`): Return true when anti-aliasing is enabled.
- `Minimap::set_clickable` (`minimap.rs`): Enable or disable click-event handling on the minimap.
- `Minimap::is_clickable` (`minimap.rs`): Return true when the minimap responds to click events.
- `Minimap::screen_to_grid` (`minimap.rs`): Convert a screen pixel `(sx, sy)` relative to `(minimap_x, minimap_y)` to grid coordinates.
- `Minimap::grid_to_screen` (`minimap.rs`): Convert grid coordinates to screen pixels relative to `(minimap_x, minimap_y)`.
- `Minimap::get_hover_info` (`minimap.rs`): Return the terrain description for the cell under screen point `(sx, sy)`, or `None` when out of bounds.
- `Minimap::update` (`minimap.rs`): Advance ping timers and marker animation phases by `dt` seconds; remove expired pings.
- `Minimap::draw_to_image` (`minimap.rs`): Rasterise the minimap to an `ImageData` buffer for export or screenshot.
- `Minimap::build_render_commands` (`minimap.rs`): Build the full set of `RenderCommand`s for the minimap at screen position `(screen_x, screen_y)`.
- `Minimap::object_type_icon` (`minimap.rs`): Return the icon for object type `type_index`, or `None` when no icon is registered.
- `Minimap::marker_icon` (`minimap.rs`): Return the icon for marker `id`, or `None` when no icon is registered.
- `Minimap::owner_colors_by_cell` (`minimap.rs`): Build a map of `(grid_x, grid_y)` → owner colour from the current object set.
- `Minimap::resolve_cell_color` (`minimap.rs`): Resolve the display colour for cell `(gx, gy)` based on the active colour mode.
- `apply_terrain` (`province_adapter.rs`): Projects province terrain IDs into minimap terrain grid.
- `apply_visibility` (`province_adapter.rs`): Projects province visibility state into minimap fog cells.
- `apply_terrain_palette` (`province_adapter.rs`): Pushes terrain-type color palette inferred from province styles.
- `Minimap::generate_render_commands` (`render.rs`): Build the full ordered `RenderCommand` list for this minimap at screen origin `(screen_x, screen_y)`.
- `ColorMode::parse_mode` (`types.rs`): Parse `"terrain"` or `"political"` to a `ColorMode`; returns `None` on unknown strings.
- `ColorMode::as_str` (`types.rs`): Return the canonical string name for this colour mode.
- `FogLevel::from_u8` (`types.rs`): Convert a raw `u8` byte to a `FogLevel`; values >= 2 map to `Visible`.

## Lua API Reference

- Binding path(s): `src/lua_api/minimap_api.rs`
- Namespace: `lurek.minimap`

### Module Functions
- `lurek.minimap.newMinimap`: Creates a minimap with grid dimensions and optional display size.

### `LMinimap` Methods
- `LMinimap:getGridWidth`: Returns the minimap grid width.
- `LMinimap:getGridHeight`: Returns the minimap grid height.
- `LMinimap:getCellCount`: Returns the total number of grid cells.
- `LMinimap:getGridSize`: Returns the minimap grid size.
- `LMinimap:getDisplayWidth`: Returns the minimap display width.
- `LMinimap:getDisplayHeight`: Returns the minimap display height.
- `LMinimap:getDisplaySize`: Returns the minimap display size.
- `LMinimap:setDisplaySize`: Sets the minimap display size.
- `LMinimap:setTerrain`: Sets terrain type for a one-based grid cell.
- `LMinimap:getTerrain`: Returns terrain type for a one-based grid cell.
- `LMinimap:setTerrainData`: Replaces terrain data from a flat array table.
- `LMinimap:setTerrainColor`: Sets RGBA color for a terrain type.
- `LMinimap:getTerrainColor`: Returns RGBA color for a terrain type.
- `LMinimap:setTileDescription`: Sets text description for a tile type.
- `LMinimap:getTileDescription`: Returns text description for a tile type.
- `LMinimap:setFogEnabled`: Enables or disables fog display.
- `LMinimap:isFogEnabled`: Returns whether fog display is enabled.
- `LMinimap:setFogLevel`: Sets fog level for a one-based grid cell.
- `LMinimap:getFogLevel`: Returns fog level for a one-based grid cell.
- `LMinimap:setFogColor`: Sets the fog overlay color.
- `LMinimap:getFogColor`: Returns the fog overlay color.
- `LMinimap:setFogData`: Replaces fog data from a flat array table.
- `LMinimap:addObjectType`: Adds an object type and returns its one-based index.
- `LMinimap:setObjectTypeVisible`: Sets visibility for an object type by one-based index.
- `LMinimap:isObjectTypeVisible`: Returns visibility for an object type by one-based index.
- `LMinimap:getObjectTypeCount`: Returns the number of object types.
- `LMinimap:setObjectTypeTexture`: Assigns an image texture to an object type.
- `LMinimap:clearObjectTypeTexture`: Clears image texture for an object type.
- `LMinimap:setObject`: Adds or updates an object on the minimap.
- `LMinimap:removeObject`: Removes an object by id.
- `LMinimap:clearObjects`: Clears all objects from the minimap.
- `LMinimap:getObjectCount`: Returns the number of objects on the minimap.
- `LMinimap:setOwnerColor`: Sets RGBA color for an owner id.
- `LMinimap:getOwnerColor`: Returns RGBA color for an owner id.
- `LMinimap:setColorMode`: Sets the minimap color mode.
- `LMinimap:getColorMode`: Returns the current minimap color mode.
- `LMinimap:setZoom`: Sets minimap zoom.
- `LMinimap:getZoom`: Returns minimap zoom.
- `LMinimap:setCenter`: Sets minimap world center.
- `LMinimap:trackCamera`: Centers the minimap and viewport rectangle from a camera handle.
- `LMinimap:revealRadius`: Reveals fog inside a world-space radius.
- `LMinimap:getCenter`: Returns minimap world center.
- `LMinimap:getCenterX`: Returns minimap world center x coordinate.
- `LMinimap:getCenterY`: Returns minimap world center y coordinate.
- `LMinimap:setViewportRect`: Sets the visible viewport rectangle shown on the minimap.
- `LMinimap:clearViewportRect`: Clears the viewport rectangle.
- `LMinimap:getViewportRect`: Returns the viewport rectangle when one is set.
- `LMinimap:setViewportVisible`: Sets whether the viewport rectangle is visible.
- `LMinimap:isViewportVisible`: Returns whether the viewport rectangle is visible.
- `LMinimap:setViewportColor`: Sets the viewport rectangle color.
- `LMinimap:getViewportColor`: Returns the viewport rectangle color.
- `LMinimap:addPing`: Adds a timed ping effect at a minimap position.
- `LMinimap:getPingCount`: Returns the number of active pings.
- `LMinimap:addMarker`: Adds a marker and returns its id.
- `LMinimap:removeMarker`: Removes a marker by id.
- `LMinimap:hasMarker`: Returns whether a marker id exists.
- `LMinimap:getMarkerDescription`: Returns a marker description by id.
- `LMinimap:getMarkerCount`: Returns the number of markers.
- `LMinimap:setMarkerTexture`: Assigns an image texture to a marker.
- `LMinimap:clearMarkerTexture`: Clears image texture from a marker.
- `LMinimap:setMarkerAnimation`: Sets marker animation by type name.
- `LMinimap:clearMarkerAnimation`: Clears marker animation by id.
- `LMinimap:drawLine`: Adds an overlay line.
- `LMinimap:drawRect`: Adds an overlay rectangle.
- `LMinimap:clearOverlay`: Clears overlay shapes.
- `LMinimap:getOverlayShapeCount`: Returns the number of overlay shapes.
- `LMinimap:showPath`: Adds a colored path overlay and returns its id.
- `LMinimap:clearPath`: Clears one path by id or all paths when no id is provided.
- `LMinimap:getPathCount`: Returns the number of paths.
- `LMinimap:setLayer`: Sets active minimap layer.
- `LMinimap:getLayer`: Returns active minimap layer.
- `LMinimap:getLayerCount`: Returns the number of minimap layers.
- `LMinimap:setLayerData`: Sets raw cell data for a layer.
- `LMinimap:getLayerData`: Returns raw cell data for a layer.
- `LMinimap:setAntiAlias`: Enables or disables minimap anti-aliasing.
- `LMinimap:isAntiAlias`: Returns whether anti-aliasing is enabled.
- `LMinimap:setClickable`: Enables or disables minimap click handling.
- `LMinimap:isClickable`: Returns whether minimap click handling is enabled.
- `LMinimap:getHoverInfo`: Returns hover text for a screen position when available.
- `LMinimap:screenToGrid`: Converts a screen position to grid coordinates.
- `LMinimap:gridToScreen`: Converts grid coordinates to screen coordinates.
- `LMinimap:update`: Advances minimap animations and timers.
- `LMinimap:type`: Returns the Lua-visible type name for this minimap handle.
- `LMinimap:typeOf`: Returns whether this minimap handle matches a supported type name.
- `LMinimap:render`: Enqueues minimap render commands at an optional screen position.
- `LMinimap:drawToImage`: Draws the minimap into image data at a pixel size.

## References

- `camera`: Imports or references `src/camera/`. Cross-group dependency from `Feature Systems` into `Platform Services`.
- `image`: Imports or references `image` from `src/image/`.
- `province`: Imports or references `src/province/`. Cross-group dependency from `Feature Systems` into `Edge/Integration`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/minimap/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
