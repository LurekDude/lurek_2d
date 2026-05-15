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

- `RaycasterScene::build` (`build_scene.rs`): Build a complete `RaycasterScene` from camera params, lights, sprites, and texture lookups.
- `ColumnBatch::new` (`column_batch.rs`): Create a new `ColumnBatch` with `column_count` default columns for the given screen size.
- `ColumnBatch::set_column` (`column_batch.rs`): Write projected wall-slice data to column `col`; silently ignores out-of-range indices.
- `ColumnBatch::get_column` (`column_batch.rs`): Return the `ColumnData` for column `col`, or `None` if `col` is out of range.
- `ColumnBatch::update_from_ray_data` (`column_batch.rs`): Populate columns from a packed float slice produced by the DDA stepper; each ray is 5 floats.
- `ColumnBatch::get_depth_at` (`column_batch.rs`): Return the depth value stored in column `col`, or `None` if out of range.
- `ColumnBatch::get_depth_buffer` (`column_batch.rs`): Collect depth values from all columns into a new `Vec<f32>`.
- `ColumnBatch::set_floor_color` (`column_batch.rs`): Set the flat floor color.
- `ColumnBatch::set_ceiling_color` (`column_batch.rs`): Set the flat ceiling color.
- `ColumnBatch::get_column_count` (`column_batch.rs`): Return the number of columns in this batch.
- `ColumnBatch::get_screen_width` (`column_batch.rs`): Return the render target width this batch was created for.
- `ColumnBatch::get_screen_height` (`column_batch.rs`): Return the render target height this batch was created for.
- `Raycaster2D::new` (`dda.rs`): Create a new empty grid of `width × height` open cells.
- `Raycaster2D::set_cell` (`dda.rs`): Set the value of cell `(x, y)`; silently ignores out-of-bounds coordinates.
- `Raycaster2D::get_cell` (`dda.rs`): Return the value of cell `(x, y)`, or 0 for out-of-bounds coordinates.
- `Raycaster2D::set_cells` (`dda.rs`): Replace the entire cell grid with `data`; no-op if length mismatches.
- `Raycaster2D::is_blocked` (`dda.rs`): Return true when cell `(x, y)` has a non-zero value (solid wall).
- `Raycaster2D::width` (`dda.rs`): Return the map width in tiles.
- `Raycaster2D::height` (`dda.rs`): Return the map height in tiles.
- `Raycaster2D::cells` (`dda.rs`): Return a read-only slice of the raw cell grid.
- `Raycaster2D::set_wall_alpha` (`dda.rs`): Set the alpha for walls of `tile_type`; clamped to 0.0..1.0.
- `Raycaster2D::get_wall_alpha` (`dda.rs`): Return the wall alpha for `tile_type`; defaults to 1.0 if not set.
- `Raycaster2D::cast_ray` (`dda.rs`): Cast a single DDA ray from `(ox, oy)` in direction `angle`; return the first solid hit or `None`.
- `Raycaster2D::cast_ray_multi` (`dda.rs`): Cast a ray and collect up to `max_hits` (≤ 8) consecutive hits, stopping at the first opaque wall.
- `Raycaster2D::cast_rays` (`dda.rs`): Cast `count` rays spread across `fov` from `(ox, oy)`; return one `RayHit` per ray with fish-eye correction.
- `Raycaster2D::cast_rays_flat` (`dda.rs`): Cast `count` rays and pack each hit as 5 floats `[dist, cell, side, tex_u, hit]`.
- `Raycaster2D::line_of_sight` (`dda.rs`): Return true if the straight-line path from `(x1,y1)` to `(x2,y2)` contains no solid cell.
- `Raycaster2D::project_sprite` (`dda.rs`): Project world sprite at `(sx, sy)` onto the screen given player position and orientation; return a `SpriteProjection`.
- `Raycaster2D::cast_floor_row` (`dda.rs`): Return per-pixel `(tex_u, tex_v)` world UV coordinates for every pixel in floor row `row`.
- `DepthBuffer::new` (`depth_buffer.rs`): Create a new depth buffer for `width` screen columns, all initialised to `f32::MAX`.
- `DepthBuffer::clear` (`depth_buffer.rs`): Reset all columns to `f32::MAX` (no wall) ready for the next frame.
- `DepthBuffer::set` (`depth_buffer.rs`): Store wall depth for `column`; silently ignores out-of-range indices.
- `DepthBuffer::get` (`depth_buffer.rs`): Return the stored depth for `column`, or `f32::MAX` if out of range.
- `DepthBuffer::is_visible` (`depth_buffer.rs`): Return true when `depth` is less than the stored depth for `column` (sprite pixel is visible).
- `DepthBuffer::width` (`depth_buffer.rs`): Return the width this buffer was created for.
- `DoorManager::new` (`doors.rs`): Create an empty `DoorManager`.
- `DoorManager::add_door` (`doors.rs`): Register a new closed door at `(x, y)` with the given `direction` and `speed`; return its index handle.
- `DoorManager::open_door` (`doors.rs`): Start opening door `index` if it is Closed or Closing; no-op otherwise.
- `DoorManager::close_door` (`doors.rs`): Start closing door `index` if it is Open or Opening; no-op otherwise.
- `DoorManager::update` (`doors.rs`): Advance all door animations by `dt` seconds.
- `DoorManager::get_door_at` (`doors.rs`): Return the first door at grid tile `(x, y)`, or `None` if none is registered there.
- `DoorManager::doors` (`doors.rs`): Return a slice of all registered doors.
- `RaycasterScene::draw_to_image` (`draw.rs`): Rasterize this scene into a new `ImageData` of `width × height`; draws ceilings, floors, walls, then sprites back-to-front.
- `GridMoveAction::parse` (`grid_motion.rs`): Parse a string token into a `GridMoveAction`; return `None` for unrecognised tokens.
- `dir4_delta` (`grid_motion.rs`): Returns movement delta for direction index `1..4` and action token (`forward/back/left/right`).
- `try_move` (`grid_motion.rs`): Applies a movement delta with bounds and collision checks.
- `HeightMap::new` (`heightmap.rs`): Create a new `HeightMap` with default floor heights 0.0 and ceiling heights 1.0.
- `HeightMap::set_floor` (`heightmap.rs`): Set the floor height for tile `(x, y)`; silently ignores out-of-bounds coordinates.
- `HeightMap::set_ceiling` (`heightmap.rs`): Set the ceiling height for tile `(x, y)`; silently ignores out-of-bounds coordinates.
- `HeightMap::floor_at` (`heightmap.rs`): Return the floor height at tile `(x, y)`, or 0.0 for out-of-bounds coordinates.
- `HeightMap::ceiling_at` (`heightmap.rs`): Return the ceiling height at tile `(x, y)`, or 1.0 for out-of-bounds coordinates.
- `HeightMap::set_floor_rect` (`heightmap.rs`): Set the floor height for all tiles in the rectangle `(x, y, w, h)` to `height`.
- `HeightMap::set_ceiling_rect` (`heightmap.rs`): Set the ceiling height for all tiles in the rectangle `(x, y, w, h)` to `height`.
- `compute_lighting` (`lighting.rs`): Computes ambient + point-light illumination at a world position.
- `apply_lit_shade` (`lighting.rs`): Applies lighting to a distance-shaded base brightness.
- `compute_tile_light` (`minimap_overlay.rs`): Computes LOS-aware ambient + point-light color for a tile center.
- `build_minimap_tile_window` (`minimap_overlay.rs`): Returns sampled minimap tile records around a world-space center.
- `reveal_cells_from_rays` (`minimap_overlay.rs`): Traces multiple rays and returns unique crossed grid cells.
- `extract_minimap` (`minimap_overlay.rs`): Extracts a top-down minimap from a Raycaster2D grid.
- `draw_player_arrow` (`minimap_overlay.rs`): Renders a simple directional arrow for the player on the minimap.
- `project_column` (`projection.rs`): Projects a wall column distance to screen-space drawing parameters.
- `distance_shade` (`projection.rs`): Distance-based shading.
- `RaycasterScene::generate_render_commands` (`render.rs`): Build a `Vec<RenderCommand>` for the full scene: ceilings, floors, walls, then sprites back-to-front.
- `RaycasterScene::new` (`scene.rs`): Create an empty scene sized to `screen_width` × `screen_height` pixels.
- `RaycasterScene::quad_count` (`scene.rs`): Return the total number of quads, sprites, and models in this scene.
- `RaycasterScene::is_empty` (`scene.rs`): Return true when no geometry has been added to this scene.
- `cast_ray_2d` (`segment.rs`): Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
- `SpriteManager::new` (`sprite_manager.rs`): Create an empty `SpriteManager` with ID counter starting at 1.
- `SpriteManager::add` (`sprite_manager.rs`): Register a sprite at `(x, y)` with the given `texture` path and `scale`; return its new ID.
- `SpriteManager::remove` (`sprite_manager.rs`): Remove the sprite with the given `id`; silently does nothing if not found.
- `SpriteManager::set_position` (`sprite_manager.rs`): Move the sprite with `id` to world position `(x, y)`; silently does nothing if not found.
- `SpriteManager::set_visible` (`sprite_manager.rs`): Set the visibility flag for sprite `id`; silently does nothing if not found.
- `SpriteManager::clear` (`sprite_manager.rs`): Remove all sprites from the registry.
- `SpriteManager::sort_by_distance` (`sprite_manager.rs`): Return visible sprites sorted farthest-to-nearest from `(cam_x, cam_y)`.
- `field_of_view` (`visibility.rs`): Computes a visibility polygon by casting rays at segment endpoints.
- `Raycaster2D::draw_top_down_to_image` (`visualization.rs`): Render a top-down grid map with player dot and radial ray lines into an `ImageData`.
- `Raycaster2D::draw_view_to_image` (`visualization.rs`): Render a software first-person view with cell-colour shading into an `ImageData`.
- `Raycaster2D::draw_depth_map_to_image` (`visualization.rs`): Render a depth-map greyscale view where brighter = closer, into an `ImageData`.
- `Raycaster2D::draw_line_of_sight_to_image` (`visualization.rs`): Render a top-down grid with a line-of-sight check between two points into an `ImageData`.
- `Raycaster2D::draw_camera_sweep_to_image` (`visualization.rs`): Render a multi-frame camera rotation sweep as a tiled atlas into an `ImageData`.
- `Raycaster2D::draw_textured_view_to_image` (`visualization.rs`): Render a first-person view with procedural wall textures into an `ImageData`.

## Lua API Reference

- Binding path(s): `src/lua_api/raycaster_api.rs`
- Namespace: `lurek.raycaster`

### Module Functions
- `lurek.raycaster.new`: Creates a new raycaster map with the given grid dimensions.
- `lurek.raycaster.newMap`: Creates a new raycaster map (alias for `new`).
- `lurek.raycaster.projectColumn`: Computes the projected wall-column height for a given distance, FOV, and screen height.
- `lurek.raycaster.distanceShade`: Returns a brightness multiplier (0.0..1.0) based on distance for fog/darkness falloff.
- `lurek.raycaster.newDoorManager`: Creates a new door manager for tracking and animating sliding doors.
- `lurek.raycaster.newHeightMap`: Creates a new height map for variable floor/ceiling heights across the grid.
- `lurek.raycaster.newPointLight`: Creates a new point light with position, color, radius, and intensity.
- `lurek.raycaster.newSpriteManager`: Creates a new sprite manager for tracking and projecting billboard sprites.

### `LDoorManager` Methods
- `LDoorManager:addDoor`: Registers a new sliding door at the given grid cell.
- `LDoorManager:openDoor`: Begins opening the door at the given index. The door animates over time via `update()`.
- `LDoorManager:closeDoor`: Begins closing the door at the given index. The door animates over time via `update()`.
- `LDoorManager:update`: Advances all door animations by the given delta time. Call once per frame.
- `LDoorManager:getDoor`: Returns a table describing the door at the given index, or nil if index is out of range.
- `LDoorManager:count`: Returns the total number of registered doors.
- `LDoorManager:type`: Returns the type name of this object.
- `LDoorManager:typeOf`: Checks whether this object matches the given type name.

### `LHeightMap` Methods
- `LHeightMap:setFloor`: Sets the floor height offset at a specific grid cell.
- `LHeightMap:setCeiling`: Sets the ceiling height offset at a specific grid cell.
- `LHeightMap:floorAt`: Returns the floor height offset at a given grid cell.
- `LHeightMap:ceilingAt`: Returns the ceiling height offset at a given grid cell.
- `LHeightMap:type`: Returns the type name of this object.
- `LHeightMap:typeOf`: Checks whether this object matches the given type name.

### `LPointLight` Methods
- `LPointLight:x`: Returns the X world position of this light.
- `LPointLight:y`: Returns the Y world position of this light.
- `LPointLight:radius`: Returns the light's falloff radius in world units.
- `LPointLight:intensity`: Returns the brightness multiplier of this light.
- `LPointLight:color`: Returns the RGB color components of this light.
- `LPointLight:set`: Overwrites all properties of this point light in a single call.
- `LPointLight:type`: Returns the type name of this object ("LPointLight").
- `LPointLight:typeOf`: Checks whether this object matches the given type name.

### `LRaycaster` Methods
- `LRaycaster:setCell`: Sets the wall type value at a grid cell. Non-zero values are solid walls.
- `LRaycaster:getCell`: Returns the wall type value at a grid cell.
- `LRaycaster:setCells`: Replaces the entire map grid with a flat array of cell values (row-major order).
- `LRaycaster:isBlocked`: Returns true if the grid cell is a solid wall (non-zero value).
- `LRaycaster:width`: Returns the map width in grid cells.
- `LRaycaster:height`: Returns the map height in grid cells.
- `LRaycaster:setFloorTextureCell`: Assigns a per-cell floor texture override. Pass nil to remove the override.
- `LRaycaster:getFloorTextureCell`: Returns the raw texture id assigned to this floor cell, or nil if none.
- `LRaycaster:setCeilingTextureCell`: Assigns a per-cell ceiling texture override. Pass nil to remove the override.
- `LRaycaster:getCeilingTextureCell`: Returns the raw texture id assigned to this ceiling cell, or nil if none.
- `LRaycaster:setLoweredFloorCell`: Marks a cell as a lowered floor (pit) with its own texture, depth, tint, and blocking flag.
- `LRaycaster:getLoweredFloorCell`: Returns the lowered floor configuration at a cell, or nil if the cell is normal.
- `LRaycaster:isWalkBlocked`: Returns true if the cell blocks walking (solid wall OR blocked lowered-floor cell).
- `LRaycaster:tryMove`: Attempts to move from (px,py) by (dx,dy) with wall-slide collision. Returns the final position.
- `LRaycaster:gridMove`: Performs a discrete grid-step movement in one of 4 cardinal directions with collision.
- `LRaycaster:castRay`: Casts a single ray from (ox,oy) at the given angle and returns hit info or nil.
- `LRaycaster:castRays`: Casts multiple rays across a field of view and returns an array of hit tables.
- `LRaycaster:castRaysFlat`: Casts multiple rays and returns only the corrected distances as a flat array.
- `LRaycaster:lineOfSight`: Tests whether there is a clear line of sight between two world points (no walls in between).
- `LRaycaster:revealCellsFromRays`: Casts rays across the FOV and returns a list of grid cells that are visible (for fog-of-war).
- `LRaycaster:computeTileLight`: Computes the combined lighting color at a tile from ambient and point lights, accounting for walls.
- `LRaycaster:buildMinimapWindow`: Generates a grid of minimap tile samples around a center point with lighting info.
- `LRaycaster:setWallAlpha`: Sets the transparency for a specific wall tile type, enabling see-through walls.
- `LRaycaster:getWallAlpha`: Returns the current transparency value for a wall tile type.
- `LRaycaster:castRayMulti`: Casts a single ray that passes through transparent walls, returning multiple hits.
- `LRaycaster:castFloorRow`: Computes floor/ceiling texture UV coordinates for a single scanline row.
- `LRaycaster:projectSprite`: Projects a world-space sprite to screen coordinates for billboard rendering.
- `LRaycaster:drawTopDown`: Renders a top-down debug view of the map with the player's position and direction.
- `LRaycaster:drawView`: Renders a first-person raycaster view to a raw image buffer (no textures, flat-shaded).
- `LRaycaster:drawDepthMap`: Renders a grayscale depth map showing distance-to-wall for each column.
- `LRaycaster:drawLineOfSight`: Renders a debug image showing the line-of-sight ray between two world points.
- `LRaycaster:drawCameraSweep`: Renders multiple frames of a rotating camera sweep as a single combined image.
- `LRaycaster:buildScene`: Builds a complete textured raycaster scene for GPU rendering. Stores the output internally
- `LRaycaster:buildSceneWithModels`: Builds a textured raycaster scene with additional 3D .obj model instances projected into the view.
- `LRaycaster:type`: Returns the type name of this object ("LRaycaster").
- `LRaycaster:typeOf`: Checks whether this object matches the given type name.

### `LSpriteManager` Methods
- `LSpriteManager:add`: Adds a new sprite to the manager at a world position with a texture name and optional scale.
- `LSpriteManager:remove`: Removes a sprite by its id.
- `LSpriteManager:setPosition`: Updates the world position of an existing sprite.
- `LSpriteManager:setVisible`: Shows or hides a sprite without removing it.
- `LSpriteManager:clear`: Removes all sprites from the manager.
- `LSpriteManager:sortAndProject`: Sorts all visible sprites by distance from the camera and returns projection data.
- `LSpriteManager:type`: Returns the type name of this object ("LSpriteManager").
- `LSpriteManager:typeOf`: Checks whether this object matches the given type name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/raycaster/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
