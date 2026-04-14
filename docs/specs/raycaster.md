# raycaster

## General Info

- Module group: `Feature Systems`
- Source path: `src/raycaster/`
- Lua API path(s): `src/lua_api/raycaster_api.rs`
- Primary Lua namespace: `lurek.raycaster`
- Rust test path(s): tests/rust/unit/raycaster_tests.rs
- Lua test path(s): tests/lua/unit/test_raycaster.lua, tests/lua/evidence/test_evidence_raycaster.lua

## Summary

The `raycaster` module implements a grid-based 2D raycaster engine for Wolfenstein-style first-person dungeon-crawler and retro FPS games. It provides all the building blocks for rendering a 3D-looking scene from a 2D grid using textured wall columns, billboard sprites, lighting, doors, floor/ceiling variation, and screen-space visibility.

`Raycaster2D` is the core DDA (Digital Differential Analyzer) traversal type. Given a player position, direction, and a 2D grid of tile IDs, it casts a horizontal array of rays — one per screen column — and returns a `Vec<RayHit>`, where each `RayHit` carries the grid cell coordinates, the struck face (North/South/East/West), the hit offset along the face (for texture UV mapping), and the perpendicular distance from the camera plane.

`DepthBuffer` records perpendicular depth per screen column for sprite occlusion testing. `project_column(dist, height)` converts a perpendicular distance into a projected wall column pixel height with a `distance_shade` falloff factor. `ColumnBatch` assembles the per-column draw data into instanced-quad render commands for a single GPU draw call.

`SpriteProjection` projects billboarded textured sprites into screen space with depth buffer clipping. `DoorManager` manages sliding door states (open, closed, opening, closing) for grid-blocking interactive geometry. `HeightMap` adds variable floor and ceiling heights for stepped or multi-level environments. `visibility.rs` computes a 2D visibility polygon via endpoint raycasting for field-of-view shadows. The `segment` submodule provides `Segment` and a general `cast_ray_2d` line-segment intersection test.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`, `runtime`. Lua bridge in `src/lua_api/raycaster_api.rs`.

## Files

- `build_scene.rs`: Builds a `RaycasterScene` from map, light, and sprite inputs so higher layers can render textured quads instead of raw hit columns.
- `column_batch.rs`: Defines column-oriented rendering payloads used by older or alternative wall-strip style outputs.
- `dda.rs`: Implements the main `Raycaster2D` DDA grid traversal, multi-ray casting, and line-of-sight queries.
- `depth_buffer.rs`: Stores per-column depth values for sprite occlusion and front-to-back visibility checks.
- `doors.rs`: Manages door state, orientation, and sliding animation timing for grid-based raycast worlds.
- `draw.rs`: Provides CPU-side image drawing for `RaycasterScene`, useful for software rendering or headless verification.
- `heightmap.rs`: Tracks per-cell floor and ceiling height variation for stepped or multi-height raycast spaces.
- `lighting.rs`: Defines point lights and computes light influence or lit shading values for projected geometry.
- `minimap_overlay.rs`: Extracts minimap-friendly data and player-arrow overlays from raycast world state.
- `mod.rs`: Declares the raycaster submodules and re-exports the core hit, scene, lighting, door, and helper types.
- `projection.rs`: Converts ray hits into projected wall geometry and shading metrics.
- `ray_hit.rs`: Defines the per-ray hit result returned by DDA and related casting helpers.
- `render.rs`: Converts a `RaycasterScene` into `RenderCommand` output for textured-quad rendering.
- `scene.rs`: Defines the high-level scene model of walls, floors, ceilings, and billboard sprites used after geometric casting.
- `segment.rs`: Implements raycasting against arbitrary 2D segments instead of a grid.
- `sprite_projection.rs`: Projects billboard sprites into screen space with depth and size data.
- `visibility.rs`: Builds visibility polygons and related field-of-view data from 2D geometry.

## Types

- `SceneBuildParams` (`struct`, `build_scene.rs`): Parameters for building a raycaster scene.
- `WorldSprite` (`struct`, `build_scene.rs`): A world-space sprite for scene building.
- `TextureLookup` (`type`, `build_scene.rs`): Texture lookup function type.
- `ColumnData` (`struct`, `column_batch.rs`): One projected column entry inside a `ColumnBatch`.
- `ColumnBatch` (`struct`, `column_batch.rs`): Column-oriented wall rendering payload for strip-based outputs.
- `Raycaster2D` (`struct`, `dda.rs`): The main DDA grid raycaster over integer world cells. It answers ray hits, multi-ray sweeps, and line-of-sight checks.
- `DepthBuffer` (`struct`, `depth_buffer.rs`): Per-column depth storage used to hide sprites or geometry that should fall behind walls.
- `DoorDirection` (`enum`, `doors.rs`): Describes how a door opens relative to the map grid.
- `DoorState` (`enum`, `doors.rs`): Encodes whether a door is closed, opening, open, or closing.
- `Door` (`struct`, `doors.rs`): One animated door in a raycast map.
- `DoorManager` (`struct`, `doors.rs`): Owns door records and their animation state over time.
- `HeightMap` (`struct`, `heightmap.rs`): Per-cell floor and ceiling height data for non-flat raycast worlds.
- `PointLight` (`struct`, `lighting.rs`): A point light source used by the optional lighting helpers.
- `RayHit` (`struct`, `ray_hit.rs`): A single cast result describing hit distance, impacted cell, hit side, texture coordinate, and hit position.
- `WallQuad` (`struct`, `scene.rs`): One textured wall polygon in a built raycaster scene.
- `FloorQuad` (`struct`, `scene.rs`): One projected floor polygon in a built raycaster scene.
- `CeilingQuad` (`struct`, `scene.rs`): One projected ceiling polygon in a built raycaster scene.
- `BillboardSprite` (`struct`, `scene.rs`): A sprite projected into the raycast view that still faces the camera.
- `RaycasterScene` (`struct`, `scene.rs`): A render-ready scene assembled from raycast results, carrying quads for walls, floors, ceilings, and sprites.
- `Segment` (`struct`, `segment.rs`): A line segment for raycasting.
- `SpriteProjection` (`struct`, `sprite_projection.rs`): Sprite projection result.

## Functions

- `RaycasterScene::build` (`build_scene.rs`): Builds a complete scene from a raycaster grid with per-polygon lighting.
- `ColumnBatch::new` (`column_batch.rs`): Create a new batch with `column_count` empty columns.
- `ColumnBatch::set_column` (`column_batch.rs`): Set the data for a single 0-based column index.
- `ColumnBatch::get_column` (`column_batch.rs`): Reference to a single column by 0-based index.
- `ColumnBatch::update_from_ray_data` (`column_batch.rs`): Bulk-update columns from raw ray data.
- `ColumnBatch::get_depth_at` (`column_batch.rs`): Depth value at a 0-based column index.
- `ColumnBatch::get_depth_buffer` (`column_batch.rs`): Depth buffer as a flat vector (one entry per column).
- `ColumnBatch::set_floor_color` (`column_batch.rs`): Set the floor color.
- `ColumnBatch::set_ceiling_color` (`column_batch.rs`): Set the ceiling color.
- `ColumnBatch::get_column_count` (`column_batch.rs`): Number of columns.
- `ColumnBatch::get_screen_width` (`column_batch.rs`): Screen width in pixels.
- `ColumnBatch::get_screen_height` (`column_batch.rs`): Screen height in pixels.
- `Raycaster2D::new` (`dda.rs`): Creates a new raycaster grid with all cells empty.
- `Raycaster2D::set_cell` (`dda.rs`): Sets the value of a cell at (x, y).
- `Raycaster2D::get_cell` (`dda.rs`): Gets the value of a cell at (x, y).
- `Raycaster2D::set_cells` (`dda.rs`): Bulk-sets all cells from a flat vector.
- `Raycaster2D::is_blocked` (`dda.rs`): Returns true if the cell at (x, y) is blocked (value > 0).
- `Raycaster2D::width` (`dda.rs`): Returns the grid width.
- `Raycaster2D::height` (`dda.rs`): Returns the grid height.
- `Raycaster2D::cells` (`dda.rs`): Returns a reference to the internal cell data.
- `Raycaster2D::cast_ray` (`dda.rs`): Casts a single ray from (ox, oy) at the given angle using the DDA algorithm.
- `Raycaster2D::cast_rays` (`dda.rs`): Casts multiple rays spread across a field of view.
- `Raycaster2D::cast_rays_flat` (`dda.rs`): Casts multiple rays and returns a flat `Vec<f32>` with 5 values per ray.
- `Raycaster2D::line_of_sight` (`dda.rs`): Checks line of sight between two points using DDA traversal.
- `Raycaster2D::project_sprite` (`dda.rs`): Projects a world-space sprite onto screen space.
- `Raycaster2D::draw_top_down_to_image` (`dda.rs`): Render a top-down map view to an image.
- `Raycaster2D::draw_view_to_image` (`dda.rs`): Render a first-person column view to an image.
- `Raycaster2D::draw_depth_map_to_image` (`dda.rs`): Render a depth-map column view with sky gradient and cell-value coloring.
- `Raycaster2D::draw_line_of_sight_to_image` (`dda.rs`): Render a line-of-sight test between two points overlaid on the grid.
- `Raycaster2D::draw_camera_sweep_to_image` (`dda.rs`): Render a mosaic of first-person views from evenly-spaced angles.
- `Raycaster2D::draw_textured_view_to_image` (`dda.rs`): Draw a first-person textured raycaster view with procedural textures.
- `DepthBuffer::new` (`depth_buffer.rs`): Creates a new depth buffer with the given width, initialized to `f32::MAX`.
- `DepthBuffer::clear` (`depth_buffer.rs`): Clears all depth values to `f32::MAX`.
- `DepthBuffer::set` (`depth_buffer.rs`): Sets the depth for a specific column.
- `DepthBuffer::get` (`depth_buffer.rs`): Gets the depth for a specific column.
- `DepthBuffer::is_visible` (`depth_buffer.rs`): Returns true if the given depth is closer than the stored depth at this column.
- `DepthBuffer::width` (`depth_buffer.rs`): Returns the buffer width.
- `DoorManager::new` (`doors.rs`): Creates an empty door manager.
- `DoorManager::add_door` (`doors.rs`): Adds a door at (x, y) with the given direction and speed.
- `DoorManager::open_door` (`doors.rs`): Begins opening a door by index.
- `DoorManager::close_door` (`doors.rs`): Begins closing a door by index.
- `DoorManager::update` (`doors.rs`): Advances all door animations by `dt` seconds.
- `DoorManager::get_door_at` (`doors.rs`): Finds a door at grid position (x, y), if any.
- `DoorManager::doors` (`doors.rs`): Returns a slice of all managed doors.
- `RaycasterScene::draw_to_image` (`draw.rs`): Renders the scene to a CPU image for headless testing and screenshots.
- `HeightMap::new` (`heightmap.rs`): Creates a new height map with default values (floor=0.0, ceiling=1.0).
- `HeightMap::set_floor` (`heightmap.rs`): Sets the floor height at (x, y).
- `HeightMap::set_ceiling` (`heightmap.rs`): Sets the ceiling height at (x, y).
- `HeightMap::floor_at` (`heightmap.rs`): Returns the floor height at (x, y).
- `HeightMap::ceiling_at` (`heightmap.rs`): Returns the ceiling height at (x, y).
- `HeightMap::set_floor_rect` (`heightmap.rs`): Sets the floor height for a rectangular region.
- `HeightMap::set_ceiling_rect` (`heightmap.rs`): Sets the ceiling height for a rectangular region.
- `compute_lighting` (`lighting.rs`): Computes ambient + point-light illumination at a world position.
- `apply_lit_shade` (`lighting.rs`): Applies lighting to a distance-shaded base brightness.
- `extract_minimap` (`minimap_overlay.rs`): Extracts a top-down minimap from a Raycaster2D grid.
- `draw_player_arrow` (`minimap_overlay.rs`): Renders a simple directional arrow for the player on the minimap.
- `project_column` (`projection.rs`): Projects a wall column distance to screen-space drawing parameters.
- `distance_shade` (`projection.rs`): Distance-based shading.
- `RaycasterScene::generate_render_commands` (`render.rs`): Converts the entire scene into render commands.
- `RaycasterScene::new` (`scene.rs`): Creates an empty scene.
- `RaycasterScene::quad_count` (`scene.rs`): Returns the total number of quads in the scene.
- `RaycasterScene::is_empty` (`scene.rs`): Returns `true` when the scene has no visible geometry.
- `cast_ray_2d` (`segment.rs`): Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
- `field_of_view` (`visibility.rs`): Computes a visibility polygon by casting rays at segment endpoints.

## Lua API Reference

- Binding path(s): `src/lua_api/raycaster_api.rs`
- Namespace: `lurek.raycaster`

### Module Functions
- `lurek.raycaster.new`: Creates a new raycaster grid of the given dimensions.
- `lurek.raycaster.projectColumn`: Projects a wall distance to screen-space drawing parameters.
- `lurek.raycaster.distanceShade`: Returns distance-based brightness in [0, 1].
- `lurek.raycaster.newDoorManager`: Creates a new empty door manager.
- `lurek.raycaster.newHeightMap`: Creates a new height map with default floor (0.0) and ceiling (1.0) values.
- `lurek.raycaster.newPointLight`: Creates a point light for use in raycaster scene lighting.

### `DoorManager` Methods
- `DoorManager:openDoor`: Begins opening the door at the given index.
- `DoorManager:closeDoor`: Begins closing the door at the given index.
- `DoorManager:update`: Advances all door animations by dt seconds.
- `DoorManager:getDoor`: Returns the state table for door at index, or nil if out of range.
- `DoorManager:count`: Returns the number of registered doors.
- `DoorManager:type`: Returns the type string "DoorManager".
- `DoorManager:typeOf`: Returns the type string "DoorManager".

### `HeightMap` Methods
- `HeightMap:setFloor`: Sets the floor height at (x, y).
- `HeightMap:setCeiling`: Sets the ceiling height at (x, y).
- `HeightMap:floorAt`: Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
- `HeightMap:ceilingAt`: Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
- `HeightMap:type`: Returns the type string "HeightMap".
- `HeightMap:typeOf`: Returns the type string "HeightMap".

### `PointLight` Methods
- `PointLight:x`: Returns the world-space X position.
- `PointLight:y`: Returns the world-space Y position.
- `PointLight:radius`: Returns the illumination radius.
- `PointLight:intensity`: Returns the intensity multiplier.
- `PointLight:color`: Returns the RGB color as three separate values.
- `PointLight:type`: Returns the type string "PointLight".
- `PointLight:typeOf`: Returns the type string "PointLight".

### `Raycaster` Methods
- `Raycaster:setCell`: Sets the cell value at grid position (x, y).
- `Raycaster:getCell`: Returns the cell value at (x, y).
- `Raycaster:setCells`: Replaces all grid cells from a flat array of values in row-major order.
- `Raycaster:isBlocked`: Returns true when the cell at (x, y) is a wall (value > 0).
- `Raycaster:width`: Returns the grid width in cells.
- `Raycaster:height`: Returns the grid height in cells.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/raycaster/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
