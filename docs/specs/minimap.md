# minimap

## General Info

- Module group: `Feature Systems`
- Source path: `src/minimap/`
- Lua API path(s): `src/lua_api/minimap_api.rs`
- Primary Lua namespace: `lurek.minimap`
- Rust test path(s): tests/rust/game/minimap_tests.rs
- Lua test path(s): tests/lua/unit/test_minimap.lua, tests/lua/evidence/test_evidence_minimap.lua

## Summary

The `minimap` module provides a grid-based minimap data model for overhead map displays with fog of war, tracked game objects, pings, persistent markers, and a viewport rectangle overlay. It is a Feature Systems tier module that is pure CPU — it has no direct GPU dependencies and produces `RenderCommand` entries for the renderer each frame.

`Minimap` is the main data container: a 2D grid of cells, each storing a terrain color, optional `FogLevel` (Hidden/Explored/Visible), and an impassable flag. Fog is used for classic fog-of-war: hidden cells render fully opaque, explored cells render semi-transparent, visible cells render clearly. `ColorMode` controls whether the minimap renders terrain colors directly or blends them with a configurable fog tint.

`MinimapObject` entries represent tracked game entities: each carries world position, `MinimapObjectType` (Player/Enemy/Ally/Item/Poi), a display color, and an optional icon texture key. `update_object(id, world_x, world_y)` keeps tracked entities current as they move. A `SlotMap<ObjectKey, MinimapObject>` manages the pool with safe stale-handle detection.

`MinimapPing` provides temporary pulsing markers at a world position for events like alerts or waypoints. `MinimapMarker` adds persistent named icons for points of interest. The viewport rectangle overlay uses the current `Camera` bounds from `SharedState` to draw a rectangle on the minimap showing which part of the world is currently visible on screen.

The `render` submodule converts the `Minimap` state into a series of `RenderCommand::DrawShape` and `RenderCommand::DrawImage` entries each frame.

**Scope boundary**: Feature Systems tier. Depends on `render` (command types), `math`, `runtime`. Lua bridge in `src/lua_api/minimap_api.rs`.

## Files

- `minimap.rs`: Implements the main `Minimap` state container, including terrain cells, fog, tracked objects, markers, pings, zoom, pan, and coordinate transforms.
- `mod.rs`: Declares the minimap submodules and re-exports the core minimap and support types.
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
- `Minimap::set_anti_alias` (`minimap.rs`): Set whether anti-aliasing is enabled.
- `Minimap::anti_alias` (`minimap.rs`): Returns whether anti-aliasing is enabled.
- `Minimap::set_clickable` (`minimap.rs`): Set whether this minimap responds to click hit-testing.
- `Minimap::is_clickable` (`minimap.rs`): Returns whether this minimap responds to click hit-testing.
- `Minimap::screen_to_grid` (`minimap.rs`): Convert screen coordinates to grid coordinates.
- `Minimap::grid_to_screen` (`minimap.rs`): Convert grid coordinates to screen coordinates.
- `Minimap::get_hover_info` (`minimap.rs`): Get hover tooltip text for the element under the given screen coordinates.
- `Minimap::update` (`minimap.rs`): Advance time-based effects: decrement ping timers and remove expired pings.
- `Minimap::draw_to_image` (`minimap.rs`): Renders the minimap to an `ImageData` for evidence/testing.
- `Minimap::build_render_commands` (`minimap.rs`): Generates GPU `RenderCommand`s for the minimap at the given screen position.
- `Minimap::generate_render_commands` (`render.rs`): Generate render commands to draw the minimap overlay at the given screen position.
- `ColorMode::parse_mode` (`types.rs`): Parse a color mode from its string name.
- `ColorMode::as_str` (`types.rs`): Return the string name of this color mode.
- `FogLevel::from_u8` (`types.rs`): Convert a raw `u8` value (0/1/2) into a `FogLevel`.

## Lua API Reference

- Binding path(s): `src/lua_api/minimap_api.rs`
- Namespace: `lurek.minimap`

### Module Functions
- `lurek.minimap.newMinimap`: Creates a new grid-based minimap.

### `Minimap` Methods
- `Minimap:getGridWidth`: Returns the grid width in cells.
- `Minimap:getGridHeight`: Returns the grid height in cells.
- `Minimap:getGridSize`: Returns the grid width and height as two values.
- `Minimap:getDisplayWidth`: Returns the display width in pixels.
- `Minimap:getDisplayHeight`: Returns the display height in pixels.
- `Minimap:getDisplaySize`: Returns the display width and height as two values.
- `Minimap:setDisplaySize`: Sets the display size in pixels.
- `Minimap:getTerrain`: Returns the terrain type at a 1-based grid position.
- `Minimap:setTerrainData`: Sets terrain types from a flat 1-based Lua table of integers (row-major).
- `Minimap:getTerrainColor`: Returns the display color for a terrain type as r, g, b, a.
- `Minimap:getTileDescription`: Returns the hover tooltip string for a terrain type ID, or nil.
- `Minimap:setFogEnabled`: Enables or disables fog of war.
- `Minimap:isFogEnabled`: Returns whether fog of war is enabled.
- `Minimap:setFogLevel`: Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
- `Minimap:getFogLevel`: Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
- `Minimap:getFogColor`: Returns the fog overlay color as r, g, b, a.
- `Minimap:setFogData`: Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
- `Minimap:isObjectTypeVisible`: Returns whether an object type (1-based index) is visible.
- `Minimap:getObjectTypeCount`: Returns the number of registered object types.
- `Minimap:removeObject`: Removes a tracked object by ID.
- `Minimap:clearObjects`: Removes all tracked objects.
- `Minimap:getObjectCount`: Returns the number of tracked objects.
- `Minimap:getOwnerColor`: Returns the display color for an owner/faction as r, g, b, a.
- `Minimap:setColorMode`: Sets the color mode ("terrain" or "political").
- `Minimap:getColorMode`: Returns the current color mode as a string.
- `Minimap:setZoom`: Sets the zoom level (minimum 0.1).
- `Minimap:getZoom`: Returns the current zoom level.
- `Minimap:setCenter`: Sets the center of the minimap view in grid coordinates.
- `Minimap:getCenter`: Returns the center coordinates as x, y.
- `Minimap:getCenterX`: Returns the center X coordinate.
- `Minimap:getCenterY`: Returns the center Y coordinate.
- `Minimap:clearViewportRect`: Clears the viewport rectangle overlay.
- `Minimap:getViewportRect`: Returns the viewport rectangle as x, y, w, h or nil if not set.
- `Minimap:setViewportVisible`: Sets whether the viewport rectangle is visible.
- `Minimap:isViewportVisible`: Returns whether the viewport rectangle is visible.
- `Minimap:getViewportColor`: Returns the viewport rectangle color as r, g, b, a.
- `Minimap:getPingCount`: Returns the number of active pings.
- `Minimap:removeMarker`: Removes a marker by ID.
- `Minimap:hasMarker`: Returns whether a marker with the given ID exists.
- `Minimap:getMarkerDescription`: Returns the description of a marker, or nil.
- `Minimap:getMarkerCount`: Returns the number of markers.
- `Minimap:setAntiAlias`: Sets whether anti-aliasing is enabled.
- `Minimap:isAntiAlias`: Returns whether anti-aliasing is enabled.
- `Minimap:setClickable`: Sets whether this minimap responds to click hit-testing.
- `Minimap:isClickable`: Returns whether this minimap responds to click hit-testing.
- `Minimap:update`: Advances time-based effects by dt seconds (expires pings).
- `Minimap:type`: Returns the type name of this object.
- `Minimap:typeOf`: Returns true if this object is of the given type.
- `Minimap:render`: Renders the minimap to the screen at the given position.
- `Minimap:drawToImage`: Renders the minimap grid to a CPU ImageData.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/minimap/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
