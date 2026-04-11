# raycaster

## Module Info
- Module name: `raycaster`
- Module group: `Feature Systems`
- Spec path: `docs/specs/raycaster.md`
- Lua API path(s): `src/lua_api/raycaster_api.rs`
- Rust test path(s): `tests/rust/unit/raycaster_tests.rs`
- Lua test path(s): `tests/lua/unit/test_raycaster.lua`, `tests/lua/evidence/test_evidence_raycaster.lua`

## Module Purpose
The `raycaster` module provides Lurek2D's retro first-person and dungeon-view geometry stack. It owns DDA grid traversal, segment ray tests, visibility computation, billboard projection, per-column depth information, optional lighting and door helpers, and scene construction for textured-quad output.

It exists so scripts can build Wolfenstein-style or dungeon-crawler views using deterministic CPU-side math instead of relying on a full 3D engine. The module focuses on spatial queries and projection results that can later be rendered by the Lua bridge or the render system.

It intentionally does not own GPU setup, camera input policy, texture management, or general scene orchestration. It produces hits, projected columns, and scene quads; rendering those results remains outside the module.

## Files
- `mod.rs` - Declares the raycaster submodules and re-exports the core hit, scene, lighting, door, and helper types.
- `build_scene.rs` - Builds a `RaycasterScene` from map, light, and sprite inputs so higher layers can render textured quads instead of raw hit columns.
- `column_batch.rs` - Defines column-oriented rendering payloads used by older or alternative wall-strip style outputs.
- `dda.rs` - Implements the main `Raycaster2D` DDA grid traversal, multi-ray casting, and line-of-sight queries.
- `depth_buffer.rs` - Stores per-column depth values for sprite occlusion and front-to-back visibility checks.
- `doors.rs` - Manages door state, orientation, and sliding animation timing for grid-based raycast worlds.
- `draw.rs` - Provides CPU-side image drawing for `RaycasterScene`, useful for software rendering or headless verification.
- `heightmap.rs` - Tracks per-cell floor and ceiling height variation for stepped or multi-height raycast spaces.
- `lighting.rs` - Defines point lights and computes light influence or lit shading values for projected geometry.
- `minimap_overlay.rs` - Extracts minimap-friendly data and player-arrow overlays from raycast world state.
- `projection.rs` - Converts ray hits into projected wall geometry and shading metrics.
- `ray_hit.rs` - Defines the per-ray hit result returned by DDA and related casting helpers.
- `render.rs` - Converts a `RaycasterScene` into `RenderCommand` output for textured-quad rendering.
- `scene.rs` - Defines the high-level scene model of walls, floors, ceilings, and billboard sprites used after geometric casting.
- `segment.rs` - Implements raycasting against arbitrary 2D segments instead of a grid.
- `sprite_projection.rs` - Projects billboard sprites into screen space with depth and size data.
- `visibility.rs` - Builds visibility polygons and related field-of-view data from 2D geometry.

## Key Types
- `Raycaster2D` - The main DDA grid raycaster over integer world cells. It answers ray hits, multi-ray sweeps, and line-of-sight checks.
- `RayHit` - A single cast result describing hit distance, impacted cell, hit side, texture coordinate, and hit position.
- `RaycasterScene` - A render-ready scene assembled from raycast results, carrying quads for walls, floors, ceilings, and sprites.
- `WallQuad` - One textured wall polygon in a built raycaster scene.
- `FloorQuad` - One projected floor polygon in a built raycaster scene.
- `CeilingQuad` - One projected ceiling polygon in a built raycaster scene.
- `BillboardSprite` - A sprite projected into the raycast view that still faces the camera.
- `PointLight` - A point light source used by the optional lighting helpers.
- `DepthBuffer` - Per-column depth storage used to hide sprites or geometry that should fall behind walls.
- `DoorManager` - Owns door records and their animation state over time.
- `Door` - One animated door in a raycast map.
- `DoorState` - Encodes whether a door is closed, opening, open, or closing.
- `DoorDirection` - Describes how a door opens relative to the map grid.
- `HeightMap` - Per-cell floor and ceiling height data for non-flat raycast worlds.
- `ColumnBatch` - Column-oriented wall rendering payload for strip-based outputs.
- `ColumnData` - One projected column entry inside a `ColumnBatch`.