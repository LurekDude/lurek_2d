# `raycaster` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.raycaster` |
| **Source** | `src/raycaster/` |
| **Rust Tests** | `tests/rust/unit/raycaster_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_raycaster.lua`, `tests/lua/evidence/test_evidence_raycaster.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `raycaster` module provides Lurek2D's retro first-person and dungeon-view geometry stack. It owns DDA grid traversal, segment ray tests, visibility computation, billboard projection, per-column depth information, optional lighting and door helpers, and scene construction for textured-quad output.

It exists so scripts can build Wolfenstein-style or dungeon-crawler views using deterministic CPU-side math instead of relying on a full 3D engine. The module focuses on spatial queries and projection results that can later be rendered by the Lua bridge or the render system.

It intentionally does not own GPU setup, camera input policy, texture management, or general scene orchestration. It produces hits, projected columns, and scene quads; rendering those results remains outside the module.

**Scope boundary**: This module currently depends on `image`, `math`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.raycaster.* (Lua API — src/lua_api/raycaster_api.rs)
    |
    v
src/raycaster/mod.rs
    |- build_scene.rs - build_scene
    |- column_batch.rs - column_batch
    |- dda.rs - dda
    |- depth_buffer.rs - depth_buffer
    |- doors.rs - doors
    |- draw.rs - draw
    |- heightmap.rs - heightmap
    |- lighting.rs - lighting
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `build_scene.rs` | Builds a `RaycasterScene` from map, light, and sprite inputs so higher layers can render textured quads instead of raw hit columns. |
| `column_batch.rs` | Defines column-oriented rendering payloads used by older or alternative wall-strip style outputs. |
| `dda.rs` | Implements the main `Raycaster2D` DDA grid traversal, multi-ray casting, and line-of-sight queries. |
| `depth_buffer.rs` | Stores per-column depth values for sprite occlusion and front-to-back visibility checks. |
| `doors.rs` | Manages door state, orientation, and sliding animation timing for grid-based raycast worlds. |
| `draw.rs` | Provides CPU-side image drawing for `RaycasterScene`, useful for software rendering or headless verification. |
| `heightmap.rs` | Tracks per-cell floor and ceiling height variation for stepped or multi-height raycast spaces. |
| `lighting.rs` | Defines point lights and computes light influence or lit shading values for projected geometry. |
| `minimap_overlay.rs` | Extracts minimap-friendly data and player-arrow overlays from raycast world state. |
| `mod.rs` | Declares the raycaster submodules and re-exports the core hit, scene, lighting, door, and helper types. |
| `projection.rs` | Converts ray hits into projected wall geometry and shading metrics. |
| `ray_hit.rs` | Defines the per-ray hit result returned by DDA and related casting helpers. |
| `render.rs` | Converts a `RaycasterScene` into `RenderCommand` output for textured-quad rendering. |
| `scene.rs` | Defines the high-level scene model of walls, floors, ceilings, and billboard sprites used after geometric casting. |
| `segment.rs` | Implements raycasting against arbitrary 2D segments instead of a grid. |
| `sprite_projection.rs` | Projects billboard sprites into screen space with depth and size data. |
| `visibility.rs` | Builds visibility polygons and related field-of-view data from 2D geometry. |

---

## Submodules

### `raycaster::build_scene`

Builds a `RaycasterScene` from map, light, and sprite inputs so higher layers can render textured quads instead of raw hit columns.

- **`SceneBuildParams`** (struct): Parameters for building a raycaster scene.
- **`WorldSprite`** (struct): A world-space sprite for scene building.
- **`TextureLookup`** (type): Texture lookup function type.

### `raycaster::column_batch`

Defines column-oriented rendering payloads used by older or alternative wall-strip style outputs.

- **`ColumnData`** (struct): Per-column rendering state produced by a raycaster.
- **`ColumnBatch`** (struct): Wolfenstein-style raycasting column batch renderer.

### `raycaster::dda`

Implements the main `Raycaster2D` DDA grid traversal, multi-ray casting, and line-of-sight queries.

- **`Raycaster2D`** (struct): 2D grid-based raycaster using DDA traversal.

### `raycaster::depth_buffer`

Stores per-column depth values for sprite occlusion and front-to-back visibility checks.

- **`DepthBuffer`** (struct): Column-based depth buffer for sprite occlusion.

### `raycaster::doors`

Manages door state, orientation, and sliding animation timing for grid-based raycast worlds.

- **`DoorDirection`** (enum): Sliding direction of a door.
- **`DoorState`** (enum): Current animation state of a door.
- **`Door`** (struct): Door state in a raycaster level.
- **`DoorManager`** (struct): Manages all doors in the level.

### `raycaster::draw`

Provides CPU-side image drawing for `RaycasterScene`, useful for software rendering or headless verification.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `raycaster::heightmap`

Tracks per-cell floor and ceiling height variation for stepped or multi-height raycast spaces.

- **`HeightMap`** (struct): Per-cell floor and ceiling heights for variable-height levels.

### `raycaster::lighting`

Defines point lights and computes light influence or lit shading values for projected geometry.

- **`PointLight`** (struct): Point light source in the raycaster world.

### `raycaster::minimap_overlay`

Extracts minimap-friendly data and player-arrow overlays from raycast world state.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `raycaster::projection`

Converts ray hits into projected wall geometry and shading metrics.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `raycaster::ray_hit`

Defines the per-ray hit result returned by DDA and related casting helpers.

- **`RayHit`** (struct): Result of a single ray cast.

### `raycaster::render`

Converts a `RaycasterScene` into `RenderCommand` output for textured-quad rendering.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `raycaster::scene`

Defines the high-level scene model of walls, floors, ceilings, and billboard sprites used after geometric casting.

- **`WallQuad`** (struct): A single wall segment projected onto the screen as a perspective-correct textured quad.
- **`FloorQuad`** (struct): A single floor tile projected onto the screen as a textured quad.
- **`CeilingQuad`** (struct): A single ceiling tile projected onto the screen as a textured quad.
- **`BillboardSprite`** (struct): A world-space sprite rendered as a camera-facing quad (billboard).
- **`RaycasterScene`** (struct): Complete raycaster scene ready for rendering as textured quads.

### `raycaster::segment`

Implements raycasting against arbitrary 2D segments instead of a grid.

- **`Segment`** (struct): A line segment for raycasting.

### `raycaster::sprite_projection`

Projects billboard sprites into screen space with depth and size data.

- **`SpriteProjection`** (struct): Sprite projection result.

### `raycaster::visibility`

Builds visibility polygons and related field-of-view data from 2D geometry.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `Raycaster2D`

The main DDA grid raycaster over integer world cells.

#### `RayHit`

A single cast result describing hit distance, impacted cell, hit side, texture coordinate, and hit position.

#### `RaycasterScene`

A render-ready scene assembled from raycast results, carrying quads for walls, floors, ceilings, and sprites.

#### `WallQuad`

One textured wall polygon in a built raycaster scene.

#### `FloorQuad`

One projected floor polygon in a built raycaster scene.

#### `CeilingQuad`

One projected ceiling polygon in a built raycaster scene.

#### `BillboardSprite`

A sprite projected into the raycast view that still faces the camera.

#### `PointLight`

A point light source used by the optional lighting helpers.

#### `DepthBuffer`

Per-column depth storage used to hide sprites or geometry that should fall behind walls.

#### `DoorManager`

Owns door records and their animation state over time.

#### `Door`

One animated door in a raycast map.

#### `DoorState`

Encodes whether a door is closed, opening, open, or closing.

#### `DoorDirection`

Describes how a door opens relative to the map grid.

#### `HeightMap`

Per-cell floor and ceiling height data for non-flat raycast worlds.

#### `ColumnBatch`

Column-oriented wall rendering payload for strip-based outputs.

#### `ColumnData`

One projected column entry inside a `ColumnBatch`.

---

## Lua API

Exposed under `lurek.raycaster.*` by `src/lua_api/raycaster_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.raycaster.new` | Creates a new raycaster grid of the given dimensions. |
| `lurek.raycaster.projectColumn` | Projects a wall distance to screen-space drawing parameters. |
| `lurek.raycaster.distanceShade` | Returns distance-based brightness in [0, 1]. |

### `Raycaster` Methods

| Method | Description |
|--------|-------------|
| `raycaster:setCell(...)` | Sets the cell value at grid position (x, y). |
| `raycaster:getCell(...)` | Returns the cell value at (x, y). |
| `raycaster:setCells(...)` | Replaces all grid cells from a flat array of values in row-major order. |
| `raycaster:isBlocked(...)` | Returns true when the cell at (x, y) is a wall (value > 0). |
| `raycaster:width(...)` | Returns the grid width in cells. |
| `raycaster:height(...)` | Returns the grid height in cells. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.raycaster.
if lurek.raycaster then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 18 |
| `enum` | 2 |
| `fn` (Lua API) | 9 |
| **Total** | **29** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Feature Systems to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/raycaster/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
