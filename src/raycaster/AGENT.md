# `raycaster` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Lua API** | `luna.math` (base types) · `luna.raycaster` (extensions) |
| **Source** | `src/raycaster/` |
| **Tests** | `tests/lua/unit/test_math.lua` |

## Summary

The `raycaster` module implements a DDA-based 2D grid raycaster designed for
Wolfenstein-style and dungeon-crawler games.  All algorithms operate on a flat
integer cell grid (`Raycaster2D`) and produce results as plain numeric data
that the Lua script can use to drive its own column renderer.

The module is intentionally renderer-agnostic: it never writes GPU resources or
draw commands.  The engine owns column drawing; the raycaster provides the
geometry.  Extension sub-systems (doors, heightmaps, depth buffering, lighting)
are all optional and additive — a game can use only `castRays` and nothing else.

**Core capability:**
- `Raycaster2D` — mutable grid with per-cell `u8` values; DDA cast for one or all columns.
- `RayHit` — per-column cast result with distance, wall side, texture U coordinate, and world hit position.
- `Segment` — 2D float line segment for `cast_ray_2d` / `field_of_view` (geometry-only, no grid).
- `SpriteProjection` — screen-space transform for billboard sprites, including depth-correct visibility.

**Extension systems:**
- `DoorManager` / `Door` — sliding door animation; cells block or open based on `open_amount`.
- `HeightMap` — per-cell variable floor and ceiling heights for sloped environments.
- `DepthBuffer` — 1D buffer tracking the depth of the nearest wall per column; gates sprite drawing.
- `PointLight` — position/radius/intensity/color tuple; `compute_lighting` aggregates a list of lights at a world point.
- `extract_minimap` — rasterises a view-radius minimap crop to a flat RGBA pixel buffer.
- `draw_player_arrow` — overlays a direction arrow on any RGBA pixel buffer.

## Architecture

```
Raycaster2D (DDA grid)
  │
  ├── dda.rs          — cast_ray, cast_rays, cast_rays_flat, project_sprite, line_of_sight
  ├── ray_hit.rs      — RayHit result struct
  ├── segment.rs      — Segment + cast_ray_2d (geometry raycaster, no grid)
  ├── visibility.rs   — field_of_view (all-angle visible segment endpoints)
  ├── projection.rs   — project_column, distance_shade (column geometry + shade)
  └── sprite_projection.rs — SpriteProjection, Raycaster2D::project_sprite
  │
  ├── doors.rs        — Door, DoorManager, DoorDirection, DoorState
  ├── heightmap.rs    — HeightMap (per-cell floor/ceiling heights)
  ├── depth_buffer.rs — DepthBuffer (1D per-column depth for sprite occlusion)
  ├── lighting.rs     — PointLight, compute_lighting, apply_lit_shade
  └── minimap_overlay.rs — extract_minimap, draw_player_arrow
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root; re-exports all public API items |
| `dda.rs` | `Raycaster2D` grid struct and DDA cast algorithms |
| `ray_hit.rs` | `RayHit` result type per cast column |
| `segment.rs` | `Segment` type and `cast_ray_2d` geometry raycaster |
| `visibility.rs` | `field_of_view` — visible angle set from a point against a segment list |
| `projection.rs` | `project_column` column geometry and `distance_shade` falloff |
| `sprite_projection.rs` | `SpriteProjection` billboard transform; `Raycaster2D::project_sprite` |
| `doors.rs` | `Door`, `DoorManager`, `DoorDirection`, `DoorState` — sliding door animation |
| `heightmap.rs` | `HeightMap` — per-cell variable floor and ceiling heights |
| `depth_buffer.rs` | `DepthBuffer` — 1D per-column depth tracker for sprite occlusion |
| `lighting.rs` | `PointLight`, `compute_lighting`, `apply_lit_shade` |
| `minimap_overlay.rs` | `extract_minimap` (RGBA crop), `draw_player_arrow` |

## Submodules

### `raycaster::dda`

DDA grid raycaster.

- **`Raycaster2D`** (struct): Mutable integer cell grid; DDA cast for one or all view columns.

### `raycaster::ray_hit`

Cast result type.

- **`RayHit`** (struct): Per-column cast result; distance, cell value, side, texture U, and world hit position.

### `raycaster::segment`

Geometry-only raycaster for segment lists.

- **`Segment`** (struct): 2D float line segment `(x1, y1) → (x2, y2)`.
- **`cast_ray_2d`** (fn): Cast a ray against a list of segments; return nearest intersection distance and point.

### `raycaster::visibility`

All-angle visibility from a single origin point.

- **`field_of_view`** (fn): Collect all visible end-point angles from `(ox, oy)` against a segment list within a radius.

### `raycaster::projection`

Column geometry helpers.

- **`project_column`** (fn): Convert a perpendicular wall distance to `(wall_height, draw_start, draw_end)` on screen.
- **`distance_shade`** (fn): Map distance to a `[0, 1]` brightness value using `max_dist` as the dark horizon.

### `raycaster::sprite_projection`

Billboard sprite transform.

- **`SpriteProjection`** (struct): Screen-space sprite position, scale, distance, and visibility flag.

### `raycaster::doors`

Sliding door animation.

- **`DoorDirection`** (enum): `Horizontal` or `Vertical` — axis along which the door slides.
- **`DoorState`** (enum): `Closed | Opening | Open | Closing` — current animation phase.
- **`Door`** (struct): Single door with position, open amount `[0, 1]`, speed, direction, and state.
- **`DoorManager`** (struct): Manages all doors in the level; drives animations each frame via `update(dt)`.

### `raycaster::heightmap`

Per-cell variable floor and ceiling heights.

- **`HeightMap`** (struct): Grid of `f32` floor and ceiling height values; supports bulk rectangle fills.

### `raycaster::depth_buffer`

1D depth tracking for sprite occlusion.

- **`DepthBuffer`** (struct): Stores the perpendicular wall distance for each screen column so sprites behind walls are culled.

### `raycaster::lighting`

Point-light illumination.

- **`PointLight`** (struct): World-space light with position, radius, intensity, and RGB colour.
- **`compute_lighting`** (fn): Aggegate a slice of lights at `(x, y)` with an ambient floor and return an `[f32; 3]` colour.
- **`apply_lit_shade`** (fn): Multiply a base shade scalar by an `[f32; 3]` light colour to produce a final RGB triple.

### `raycaster::minimap_overlay`

RGBA minimap rendering.

- **`extract_minimap`** (fn): Rasterise a `view_radius`-cell crop of the raycaster grid at `cell_size` pixel scale into a flat RGBA buffer.
- **`draw_player_arrow`** (fn): Overlay a direction arrow on any RGBA pixel buffer.

## Key Types

### Structs

#### `raycaster::Raycaster2D`

Mutable integer cell grid with DDA ray casting.

Key methods: `new(w, h)`, `set_cell(x, y, v)`, `get_cell(x, y) -> u8`, `is_blocked(x, y) -> bool`,
`cast_ray(ox, oy, angle, max_dist)`, `cast_rays(ox, oy, angle, fov, num_cols, max_dist)`,
`cast_rays_flat(...)`, `line_of_sight(x1, y1, x2, y2)`, `project_sprite(...)`.

#### `raycaster::RayHit`

Per-column cast result.

| Field | Type | Description |
|-------|------|-------------|
| `distance` | `f32` | Perpendicular distance (corrected for fisheye) |
| `raw_distance` | `f32` | Euclidean hit distance |
| `cell_value` | `u8` | Value of the hit cell |
| `side` | `bool` | `true` = NS wall, `false` = EW wall |
| `tex_u` | `f32` | Texture U coordinate `[0, 1]` along the hit wall |
| `hit_x` | `f32` | World X of the exact hit point |
| `hit_y` | `f32` | World Y of the exact hit point |
| `hit` | `bool` | `false` if the ray reached `max_dist` without hitting a wall |

#### `raycaster::Segment`

2D float line segment for geometry-only raycasting.

| Field | Type |
|-------|------|
| `x1, y1` | `f32` |
| `x2, y2` | `f32` |

#### `raycaster::SpriteProjection`

Screen-space billboard sprite transform.

| Field | Type | Description |
|-------|------|-------------|
| `screen_x` | `f32` | Horizontal screen position of the sprite centre |
| `scale` | `f32` | Uniform scale factor (height in pixels = `scale * screen_h`) |
| `distance` | `f32` | Depth for occlusion comparison with `DepthBuffer` |
| `visible` | `bool` | `false` if the sprite is behind the camera |

#### `raycaster::Door`

A single sliding door.

| Field | Type | Description |
|-------|------|-------------|
| `x, y` | `u32` | Grid cell position (0-based) |
| `open_amount` | `f32` | Current open fraction `[0, 1]` |
| `speed` | `f32` | Open/close rate in units per second |
| `direction` | `DoorDirection` | Slide axis |
| `state` | `DoorState` | Current animation phase |

#### `raycaster::PointLight`

A world-space point light.

| Field | Type |
|-------|------|
| `x, y` | `f32` |
| `radius` | `f32` |
| `intensity` | `f32` |
| `color` | `[f32; 3]` |

## Public Functions

| Function | Parameters | Returns |
|----------|-----------|---------|
| `cast_ray_2d` | `(ox, oy, dx, dy, max_dist, segs)` | `Option<(f32, f32, f32)>` — (dist, hx, hy) |
| `field_of_view` | `(ox, oy, segments, radius)` | `Vec<f32>` — visible angles |
| `project_column` | `(dist, fov, screen_height)` | `(wall_height, draw_start, draw_end): (f32,f32,f32)` |
| `distance_shade` | `(dist, max_dist)` | `f32` in `[0, 1]` |
| `compute_lighting` | `(x, y, ambient, lights)` | `[f32; 3]` RGB |
| `apply_lit_shade` | `(base_shade, r, g, b)` | `(r, g, b): (f32, f32, f32)` |
| `extract_minimap` | `(rc, px, py, angle, view_radius, cell_size, wall_color, floor_color, player_color)` | `(Vec<u8>, u32, u32)` — RGBA, width, height |
| `draw_player_arrow` | `(pixels, img_w, cx, cy, angle, size, color)` | `()` |

## Lua API

### `luna.math.*` — base raycaster types

| Lua function | Parameters | Returns |
|---|---|---|
| `luna.math.newRaycaster2D(w, h)` | `integer, integer` | `Raycaster2D` userdata |
| `luna.math.castRay2D(ox, oy, dx, dy, maxDist, segs)` | numbers + segment table | `dist, hx, hy` or `nil` |
| `luna.math.fieldOfView(ox, oy, segs, radius)` | numbers + segment table | `{angle,...}` |

**`Raycaster2D` methods:**

| Method | Parameters | Returns |
|--------|-----------|---------|
| `:getWidth()` | — | `integer` |
| `:getHeight()` | — | `integer` |
| `:getDimensions()` | — | `w, h` |
| `:setCell(x, y, v)` | 1-based coords, `integer` | — |
| `:getCell(x, y)` | 1-based coords | `integer` |
| `:setCells(flat_table)` | flat `{integer,...}` | — |
| `:isBlocked(x, y)` | 1-based coords | `boolean` |
| `:castRay(ox, oy, angle, maxDist)` | `number` each | `RayHit` table |
| `:castRays(ox, oy, angle, fov, numCols, maxDist)` | `number` each | `{RayHit,...}` |
| `:castRaysFlat(ox, oy, angle, fov, numCols, maxDist)` | `number` each | flat number array |
| `:lineOfSight(x1, y1, x2, y2)` | `number` each | `boolean` |
| `:projectSprite(sx, sy, px, py, pa, fov, screenW)` | `number` each | `screenX, scale, dist, visible` |
| `:extractMinimap(px, py, pa, viewRadius, cellSize, wr,wg,wb,wa, fr,fg,fb,fa, pr,pg,pb,pa)` | numbers (last 12 are `0–255` RGBA for wall/floor/player) | `{byte,...}, w, h` |

### `luna.raycaster.*` — extension API

| Lua function | Parameters | Returns |
|---|---|---|
| `luna.raycaster.newDoorManager()` | — | `DoorManager` userdata |
| `luna.raycaster.newHeightMap(w, h)` | `integer, integer` | `HeightMap` userdata |
| `luna.raycaster.newDepthBuffer(width)` | `integer` | `DepthBuffer` userdata |
| `luna.raycaster.newLight(x, y, radius, intensity?, r?, g?, b?)` | numbers | `PointLight` userdata |
| `luna.raycaster.computeLighting(x, y, ambient, lights)` | `number, number, number, {PointLight,...}` | `r, g, b` |
| `luna.raycaster.applyLitShade(shade, r, g, b)` | `number` each | `r, g, b` |
| `luna.raycaster.projectColumn(dist, fov, screenH)` | `number` each | `wallHeight, drawStart, drawEnd` |
| `luna.raycaster.distanceShade(dist, maxDist)` | `number` each | `number` |

**`DoorManager` methods:**

| Method | Parameters | Returns |
|--------|-----------|---------|
| `:addDoor(x, y, dir, speed)` | 1-based coords; `dir: "h"/"v"`, `speed: number` | `index: integer` |
| `:openDoor(index)` | `integer` | — |
| `:closeDoor(index)` | `integer` | — |
| `:update(dt)` | `number` | — |
| `:getDoorCount()` | — | `integer` |
| `:getDoorAt(x, y)` | 1-based coords | `{x,y,open_amount,speed,state,direction}` or `nil` |
| `:getDoor(index)` | `integer` | `{x,y,open_amount,speed,state,direction}` or `nil` |

**`HeightMap` methods:**

| Method | Parameters | Returns |
|--------|-----------|---------|
| `:setFloor(x, y, h)` | 1-based coords, `number` | — |
| `:setCeiling(x, y, h)` | 1-based coords, `number` | — |
| `:floorAt(x, y)` | 1-based coords | `number` |
| `:ceilingAt(x, y)` | 1-based coords | `number` |
| `:setFloorRect(x, y, w, h, height)` | 1-based top-left, dims, float height | — |
| `:setCeilingRect(x, y, w, h, height)` | 1-based top-left, dims, float height | — |

**`DepthBuffer` methods:**

| Method | Parameters | Returns |
|--------|-----------|---------|
| `:clear()` | — | — |
| `:set(col, depth)` | 0-based column, `number` | — |
| `:get(col)` | 0-based column | `number` |
| `:isVisible(col, depth)` | 0-based column, `number` | `boolean` |
| `:getWidth()` | — | `integer` |

**`PointLight` methods:**

| Method | Parameters | Returns |
|--------|-----------|---------|
| `:getX() / :getY()` | — | `number` |
| `:setPosition(x, y)` | `number, number` | — |
| `:getRadius() / :setRadius(r)` | `number` | `number` |
| `:getIntensity() / :setIntensity(i)` | `number` | `number` |
| `:getColor()` | — | `r, g, b` |
| `:setColor(r, g, b)` | `number` each | — |

## Item Summary

| Category | Count |
|----------|-------|
| Structs | 7 |
| Enums | 2 |
| Free functions | 8 |
| Lua bindings (luna.math) | 3 + 14 methods |
| Lua bindings (luna.raycaster) | 8 + 27 methods |
| Source files | 12 |
