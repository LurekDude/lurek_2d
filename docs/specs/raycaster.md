# raycaster

## General Info

- Module group: `Feature Systems`
- Source path: `src/raycaster/`
- Lua API path(s): `src/lua_api/raycaster_api.rs`
- Primary Lua namespace: `lurek.raycaster`
- Rust test path(s): tests/rust/unit/raycaster_tests.rs
- Lua test path(s): tests/lua/unit/test_raycaster_core_unit.lua, tests/lua/evidence/test_raycaster_evidence.lua

## Summary

The `raycaster` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `math`, `render`, `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

## Files

- `build_scene.rs`: Builds a `RaycasterScene` from map, light, and sprite inputs so higher layers can render textured quads instead of raw hit columns.
- `column_batch.rs`: Defines column-oriented rendering payloads used by older or alternative wall-strip style outputs.
- `dda.rs`: Implements the main `Raycaster2D` DDA grid traversal, multi-ray casting, and line-of-sight queries.
- `depth_buffer.rs`: Stores per-column depth values for sprite occlusion and front-to-back visibility checks.
- `doors.rs`: Manages door state, orientation, and sliding animation timing for grid-based raycast worlds.
- `draw.rs`: Provides CPU-side image drawing for `RaycasterScene`, useful for software rendering or headless verification.
- `grid_motion.rs`: Provides shared 4-direction movement helpers (`forward/back/left/right`) and collision-aware movement stepping.
- `heightmap.rs`: Tracks per-cell floor and ceiling height variation for stepped or multi-height raycast spaces.
- `lighting.rs`: Defines point lights and computes light influence or lit shading values for projected geometry.
- `minimap_overlay.rs`: Extracts minimap-friendly data and player-arrow overlays from raycast world state.
- `mod.rs`: Declares the raycaster submodules and re-exports the core hit, scene, lighting, door, and helper types.
- `projection.rs`: Converts ray hits into projected wall geometry and shading metrics.
- `ray_hit.rs`: Defines the per-ray hit result returned by DDA and related casting helpers.
- `render.rs`: Converts a `RaycasterScene` into `RenderCommand` output for textured-quad rendering.
- `scene.rs`: Defines the high-level scene model of walls, floors, ceilings, and billboard sprites used after geometric casting.
- `segment.rs`: Implements raycasting against arbitrary 2D segments instead of a grid.
- `sprite_manager.rs`: Batch sprite manager with depth-sorted projection for raycaster scenes.
- `sprite_projection.rs`: Projects billboard sprites into screen space with depth and size data.
- `visibility.rs`: Builds visibility polygons and related field-of-view data from 2D geometry.
- `visualization.rs`: Diagnostic and visualization helpers for [`Raycaster2D`].

## Types

- `LoweredFloorCell` (`struct`, `build_scene.rs`): Auto-doc: public item.
- `SceneBuildParams` (`struct`, `build_scene.rs`): Parameters for building a raycaster scene.
- `WorldSprite` (`struct`, `build_scene.rs`): A world-space sprite for scene building.
- `TextureLookup` (`type`, `build_scene.rs`): Texture lookup function type.
- `CellTextureLookup` (`type`, `build_scene.rs`): Per-cell texture lookup function type.
- `ColumnData` (`struct`, `column_batch.rs`): One projected column entry inside a `ColumnBatch`.
- `ColumnBatch` (`struct`, `column_batch.rs`): Column-oriented wall rendering payload for strip-based outputs.
- `Raycaster2D` (`struct`, `dda.rs`): The main DDA grid raycaster over integer world cells. It answers ray hits, multi-ray sweeps, and line-of-sight checks.
- `DepthBuffer` (`struct`, `depth_buffer.rs`): Per-column depth storage used to hide sprites or geometry that should fall behind walls.
- `DoorDirection` (`enum`, `doors.rs`): Describes how a door opens relative to the map grid.
- `DoorState` (`enum`, `doors.rs`): Encodes whether a door is closed, opening, open, or closing.
- `Door` (`struct`, `doors.rs`): One animated door in a raycast map.
- `DoorManager` (`struct`, `doors.rs`): Owns door records and their animation state over time.
- `GridMoveAction` (`enum`, `grid_motion.rs`): Camera-relative movement action for 4-directional movement.
- `HeightMap` (`struct`, `heightmap.rs`): Per-cell floor and ceiling height data for non-flat raycast worlds.
- `PointLight` (`struct`, `lighting.rs`): A point light source used by the optional lighting helpers.
- `MinimapTileSample` (`struct`, `minimap_overlay.rs`): One sampled minimap tile with blocked/visible/light fields.
- `RayHit` (`struct`, `ray_hit.rs`): A single cast result describing hit distance, impacted cell, hit side, texture coordinate, and hit position.
- `WallQuad` (`struct`, `scene.rs`): One textured wall polygon in a built raycaster scene.
- `FloorQuad` (`struct`, `scene.rs`): One projected floor polygon in a built raycaster scene.
- `CeilingQuad` (`struct`, `scene.rs`): One projected ceiling polygon in a built raycaster scene.
- `BillboardSprite` (`struct`, `scene.rs`): A sprite projected into the raycast view that still faces the camera.
- `ModelMesh` (`struct`, `scene.rs`): A projected 3D model instance stored as a screen-space mesh.
- `RaycasterScene` (`struct`, `scene.rs`): A render-ready scene assembled from raycast results, carrying quads for walls, floors, ceilings, and sprites.
- `Segment` (`struct`, `segment.rs`): A line segment for raycasting.
- `WorldSprite` (`struct`, `sprite_manager.rs`): A world-space sprite for scene building.
- `SpriteManager` (`struct`, `sprite_manager.rs`): Manages a collection of [`WorldSprite`] objects with depth-sorted projection.
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
- `Raycaster2D::set_wall_alpha` (`dda.rs`): Sets the opacity for a wall tile type.
- `Raycaster2D::get_wall_alpha` (`dda.rs`): Returns the opacity for a wall tile type.
- `Raycaster2D::cast_ray` (`dda.rs`): Casts a single ray from (ox, oy) at the given angle using the DDA algorithm.
- `Raycaster2D::cast_ray_multi` (`dda.rs`): Casts a ray and collects up to `max_hits` wall hits, continuing through translucent walls (alpha < 1.0) registered via [`set_wall_alpha`].
- `Raycaster2D::cast_rays` (`dda.rs`): Casts multiple rays spread across a field of view.
- `Raycaster2D::cast_rays_flat` (`dda.rs`): Casts multiple rays and returns a flat `Vec<f32>` with 5 values per ray.
- `Raycaster2D::line_of_sight` (`dda.rs`): Checks line of sight between two points using DDA traversal.
- `Raycaster2D::project_sprite` (`dda.rs`): Projects a world-space sprite onto screen space.
- `Raycaster2D::cast_floor_row` (`dda.rs`): Computes floor (or ceiling) texture coordinates for one horizontal screen row.
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
- `GridMoveAction::parse` (`grid_motion.rs`): Parses Lua-facing action token.
- `dir4_delta` (`grid_motion.rs`): Returns movement delta for direction index `1..4` and action token (`forward/back/left/right`).
- `try_move` (`grid_motion.rs`): Applies a movement delta with bounds and collision checks.
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
- `compute_tile_light` (`minimap_overlay.rs`): Computes LOS-aware ambient + point-light color for a tile center.
- `build_minimap_tile_window` (`minimap_overlay.rs`): Returns sampled minimap tile records around a world-space center.
- `reveal_cells_from_rays` (`minimap_overlay.rs`): Traces multiple rays and returns unique crossed grid cells.
- `project_column` (`projection.rs`): Projects a wall column distance to screen-space drawing parameters.
- `distance_shade` (`projection.rs`): Distance-based shading.
- `RaycasterScene::generate_render_commands` (`render.rs`): Converts the entire scene into render commands.
- `RaycasterScene::new` (`scene.rs`): Creates an empty scene.
- `RaycasterScene::quad_count` (`scene.rs`): Returns the total number of quads in the scene.
- `RaycasterScene::is_empty` (`scene.rs`): Returns `true` when the scene has no visible geometry.
- `cast_ray_2d` (`segment.rs`): Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
- `SpriteManager::new` (`sprite_manager.rs`): Creates an empty sprite manager.
- `SpriteManager::add` (`sprite_manager.rs`): Adds a sprite at the given world position and returns its unique id.
- `SpriteManager::remove` (`sprite_manager.rs`): Removes the sprite with the given id.
- `SpriteManager::set_position` (`sprite_manager.rs`): Moves the sprite with the given id to a new world position.
- `SpriteManager::set_visible` (`sprite_manager.rs`): Sets visibility for the sprite with the given id.
- `SpriteManager::clear` (`sprite_manager.rs`): Removes all sprites from the manager.
- `SpriteManager::sort_by_distance` (`sprite_manager.rs`): Returns references to visible sprites sorted back-to-front (farthest first).
- `field_of_view` (`visibility.rs`): Computes a visibility polygon by casting rays at segment endpoints.
- `Raycaster2D::draw_top_down_to_image` (`visualization.rs`): Render a top-down map view to an image.
- `Raycaster2D::draw_view_to_image` (`visualization.rs`): Render a first-person column view to an image.
- `Raycaster2D::draw_depth_map_to_image` (`visualization.rs`): Render a depth-map column view with sky gradient and cell-value coloring.
- `Raycaster2D::draw_line_of_sight_to_image` (`visualization.rs`): Render a line-of-sight test between two points overlaid on the grid.
- `Raycaster2D::draw_camera_sweep_to_image` (`visualization.rs`): Render a mosaic of first-person views from evenly-spaced angles.
- `Raycaster2D::draw_textured_view_to_image` (`visualization.rs`): Draw a first-person textured raycaster view with procedural textures.

## Lua API Reference

- Binding path(s): `src/lua_api/raycaster_api.rs`
- Namespace: `lurek.raycaster`

### Module Functions
- `lurek.raycaster.new`: Creates a new raycaster grid of the given dimensions.
- `lurek.raycaster.newMap`: Alias for `new`. Creates a new raycaster grid of the given dimensions.
- `lurek.raycaster.projectColumn`: Projects a wall distance to screen-space drawing parameters.
- `lurek.raycaster.distanceShade`: Returns distance-based brightness in [0, 1].
- `lurek.raycaster.newDoorManager`: Creates a new empty door manager.
- `lurek.raycaster.newHeightMap`: Creates a new height map with default floor (0.0) and ceiling (1.0) values.
- `lurek.raycaster.newPointLight`: Creates a point light for use in raycaster scene lighting.
- `lurek.raycaster.newSpriteManager`: Creates a new empty batch sprite manager for depth-sorted projection.

### `LDoorManager` Methods
- `LDoorManager:addDoor`: Registers a door at grid position (x, y).
- `LDoorManager:openDoor`: Begins opening the door at the given index.
- `LDoorManager:closeDoor`: Begins closing the door at the given index.
- `LDoorManager:update`: Advances all door animations by dt seconds.
- `LDoorManager:getDoor`: Returns the state table for door at index, or nil if out of range.
- `LDoorManager:count`: Returns the number of registered doors.
- `LDoorManager:type`: Returns the Lua type name for this userdata.
- `LDoorManager:typeOf`: Returns true if this object is of the given type.

### `LHeightMap` Methods
- `LHeightMap:setFloor`: Sets the floor height at (x, y).
- `LHeightMap:setCeiling`: Sets the ceiling height at (x, y).
- `LHeightMap:floorAt`: Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
- `LHeightMap:ceilingAt`: Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
- `LHeightMap:type`: Returns the type string "HeightMap".
- `LHeightMap:typeOf`: Returns true if this object is of the given type.

### `LPointLight` Methods
- `LPointLight:x`: Returns the world-space X position.
- `LPointLight:y`: Returns the world-space Y position.
- `LPointLight:radius`: Returns the illumination radius.
- `LPointLight:intensity`: Returns the intensity multiplier.
- `LPointLight:color`: Returns the RGB color as three separate values.
- `LPointLight:set`: Updates all light properties at once.
- `LPointLight:type`: Returns the type string "PointLight".
- `LPointLight:typeOf`: Returns true if this object is of the given type.

### `LRaycaster` Methods
- `LRaycaster:setCell`: Sets the cell value at grid position (x, y).
- `LRaycaster:getCell`: Returns the cell value at (x, y).
- `LRaycaster:setCells`: Replaces all grid cells from a flat array of values in row-major order.
- `LRaycaster:isBlocked`: Returns true when the cell at (x, y) is a wall (value > 0).
- `LRaycaster:width`: Returns the grid width in cells.
- `LRaycaster:height`: Returns the grid height in cells.
- `LRaycaster:setFloorTextureCell`: Sets or clears a floor texture override for a map cell.
- `LRaycaster:getFloorTextureCell`: Returns floor texture override id for a map cell, or nil when unset.
- `LRaycaster:setCeilingTextureCell`: Sets or clears a ceiling texture override for a map cell.
- `LRaycaster:getCeilingTextureCell`: Returns ceiling texture override id for a map cell, or nil when unset.
- `LRaycaster:setLoweredFloorCell`: Sets or clears a lowered floor cell such as water or lava.
- `LRaycaster:getLoweredFloorCell`: Returns lowered floor cell config for a map cell, or nil when unset.
- `LRaycaster:isWalkBlocked`: Returns true if the cell cannot be entered because of a wall or a blocked lowered floor cell.
- `LRaycaster:tryMove`: Attempts to move by (dx, dy) in world space while respecting map and lowered-floor blocking.
- `LRaycaster:gridMove`: Attempts a 4-direction movement action (`forward`, `back`, `left`, `right`) from dir 1..4.
- `LRaycaster:castRay`: Casts a single ray and returns a hit table, or nil if nothing was hit.
- `LRaycaster:castRays`: Casts multiple rays across a field of view, returns an array of hit tables.
- `LRaycaster:castRaysFlat`: Casts multiple rays and returns a flat array of 5 floats per ray.
- `LRaycaster:lineOfSight`: Checks line of sight between two points using DDA traversal.
- `LRaycaster:revealCellsFromRays`: Traces multiple rays and returns unique crossed cells for fog-of-war reveal.
- `LRaycaster:computeTileLight`: Computes LOS-aware tile lighting from ambient and point lights.
- `LRaycaster:buildMinimapWindow`: Builds sampled minimap tile records around a world-space center.
- `LRaycaster:setWallAlpha`: Sets the opacity for a wall tile type. Alpha is clamped to [0, 1].
- `LRaycaster:getWallAlpha`: Returns the opacity for a wall tile type. Returns 1.0 if not set.
- `LRaycaster:castRayMulti`: Casts a ray collecting up to max_hits wall layers, continuing through
- `LRaycaster:castFloorRow`: Computes floor (or ceiling) texture UV coordinates for one horizontal screen row.
- `LRaycaster:projectSprite`: Projects a world-space sprite onto screen space.
- `LRaycaster:drawTopDown`: Renders a top-down grid view with player marker to an ImageData.
- `LRaycaster:drawView`: Renders a first-person column view to an ImageData.
- `LRaycaster:drawDepthMap`: Renders a depth-map column view to an ImageData.
- `LRaycaster:drawLineOfSight`: Renders a line-of-sight test between two points to an ImageData.
- `LRaycaster:drawCameraSweep`: Renders a mosaic of first-person views from evenly spaced angles to an ImageData.
- `LRaycaster:buildScene`: Builds a raycaster scene and stores it in SharedState for GPU rendering.
- `LRaycaster:buildSceneWithModels`: Builds a raycaster scene and appends projected OBJ model meshes.
- `LRaycaster:type`: Returns the type name of this object.
- `LRaycaster:typeOf`: Returns true if this object is of the given type.

### `LSpriteManager` Methods
- `LSpriteManager:add`: Adds a sprite at world position (x, y) and returns its unique id.
- `LSpriteManager:remove`: Removes the sprite with the given id. No-op if not found.
- `LSpriteManager:setPosition`: Moves the sprite with the given id to world (x, y).
- `LSpriteManager:setVisible`: Shows or hides the sprite with the given id.
- `LSpriteManager:clear`: Removes all sprites from the manager.
- `LSpriteManager:sortAndProject`: Returns an array of visible sprites sorted back-to-front from camera position.
- `LSpriteManager:type`: Returns the type string "SpriteManager".
- `LSpriteManager:typeOf`: Returns true if this object is of the given type.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/raycaster/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
