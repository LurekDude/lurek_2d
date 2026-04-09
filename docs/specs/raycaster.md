# `raycaster` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                           |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.raycaster`                                     |
| **Source**      | `src/raycaster/`                                     |
| **Rust Tests** | `tests/rust/unit/raycaster_tests.rs`                 |
| **Lua Tests**  | `tests/lua/unit/test_raycaster.lua`                  |
| **Architecture** | —                                                  |

## Summary

The `raycaster` module implements a DDA-based 2D grid raycaster designed for Wolfenstein-style retro FPS and dungeon-crawler games. It operates entirely on a flat integer cell grid (`Raycaster2D`) and produces results as plain numeric data — distances, texture coordinates, hit positions — that Lua scripts consume to drive their own column rendering via `lurek.gfx` draw calls. The module is intentionally renderer-agnostic: it never writes GPU resources, pushes draw commands, or accesses SharedState resource pools. The engine owns column drawing; the raycaster provides the geometry.

The core DDA algorithm (`dda.rs`) traverses cells along a ray direction, returning `RayHit` results with perpendicular (fisheye-corrected) distance, wall side, texture U coordinate, and world-space hit position. Single-ray (`cast_ray`), multi-ray fan (`cast_rays` / `cast_rays_flat`), and line-of-sight (`line_of_sight`) queries are all provided. A separate geometry-only path (`segment.rs` / `visibility.rs`) casts rays against arbitrary 2D line segments rather than a grid, supporting visibility polygon computation for lighting and fog-of-war effects.

Extension subsystems are all optional and additive — a game can use only `castRays` and nothing else. `ColumnBatch` stores per-column projected wall data ready for batch rendering. `DoorManager` drives sliding-door animations with per-frame `update(dt)`. `HeightMap` adds per-cell variable floor and ceiling heights for stepped environments. `DepthBuffer` provides a 1D per-column depth tracker for correct sprite-vs-wall occlusion. `PointLight` and `compute_lighting` aggregate ambient + point-light illumination. `extract_minimap` rasterises a view-radius top-down crop of the grid to a flat RGBA pixel buffer suitable for `lurek.img`.

This module satisfies design constraint A-03 (2D graphics only) — the raycaster produces 2D column draw data, not a 3D scene graph, making it an explicitly allowed use of pseudo-3D rendering within Lurek2D's 2D-only architecture.

## Architecture

```
Raycaster2D (DDA grid — dda.rs)
  │
  ├── cast_ray / cast_rays / cast_rays_flat
  │     └── RayHit (ray_hit.rs)
  │
  ├── line_of_sight (DDA LOS check)
  │
  ├── project_sprite
  │     └── SpriteProjection (sprite_projection.rs)
  │
  ├── ColumnBatch (column_batch.rs)
  │     ├── ColumnData (per-column state)
  │     └── update_from_ray_data (flat → projected columns)
  │
  ├── DepthBuffer (depth_buffer.rs)
  │     └── is_visible (sprite occlusion gate)
  │
  ├── DoorManager (doors.rs)
  │     ├── Door (position + animation state)
  │     ├── DoorDirection (Horizontal | Vertical)
  │     └── DoorState (Closed | Opening | Open | Closing)
  │
  ├── HeightMap (heightmap.rs)
  │     └── per-cell floor/ceiling heights
  │
  ├── PointLight + compute_lighting (lighting.rs)
  │     └── apply_lit_shade (shade × light color)
  │
  └── extract_minimap + draw_player_arrow (minimap_overlay.rs)
        └── RGBA pixel buffer output

Segment (segment.rs) ── geometry-only raycaster (no grid)
  ├── cast_ray_2d (ray vs segment list)
  └── field_of_view (visibility.rs — polygon from endpoints)
```

## Source Files

| File                     | Purpose                                                        |
|--------------------------|----------------------------------------------------------------|
| `mod.rs`                 | Module root; re-exports all public types and functions          |
| `dda.rs`                 | `Raycaster2D` grid struct and DDA traversal algorithms         |
| `ray_hit.rs`             | `RayHit` result struct returned per cast column                |
| `segment.rs`             | `Segment` line type and `cast_ray_2d` geometry raycaster       |
| `visibility.rs`          | `field_of_view` — visibility polygon via endpoint raycasting   |
| `projection.rs`          | `project_column` column geometry and `distance_shade` falloff  |
| `sprite_projection.rs`   | `SpriteProjection` billboard transform for screen-space sprites|
| `column_batch.rs`        | `ColumnBatch` / `ColumnData` — per-column wall rendering state |
| `depth_buffer.rs`        | `DepthBuffer` — 1D per-column depth for sprite occlusion       |
| `doors.rs`               | `Door`, `DoorManager`, `DoorDirection`, `DoorState` — sliding door animation |
| `heightmap.rs`           | `HeightMap` — per-cell variable floor and ceiling heights      |
| `lighting.rs`            | `PointLight`, `compute_lighting`, `apply_lit_shade`            |
| `minimap_overlay.rs`     | `extract_minimap` (RGBA crop) and `draw_player_arrow`          |

## Submodules

### `raycaster::dda`

DDA grid raycaster — core casting engine.

- **`Raycaster2D`** (struct) — Mutable integer cell grid (`u32` per cell); DDA traversal for single-ray, multi-ray fan, flat output, line-of-sight, and sprite projection.

### `raycaster::ray_hit`

Cast result value type.

- **`RayHit`** (struct) — Per-column cast result: perpendicular distance, raw distance, cell value, side (0=horizontal, 1=vertical), texture U, world hit position, and hit flag.

### `raycaster::segment`

Geometry-only raycaster for segment lists (no grid).

- **`Segment`** (struct) — 2D float line segment `(x1, y1) → (x2, y2)`.
- **`cast_ray_2d`** (fn) — Cast a ray against a list of segments; returns nearest intersection point and segment index.

### `raycaster::visibility`

All-angle visibility from a single origin point.

- **`field_of_view`** (fn) — Casts rays at segment endpoints with angular offsets; returns a sorted flat polygon `[x0, y0, x1, y1, ...]`.

### `raycaster::projection`

Column projection and distance shading.

- **`project_column`** (fn) — Converts wall distance + FOV + screen height to `(wall_height, draw_start, draw_end)`.
- **`distance_shade`** (fn) — Linear distance falloff `(1 - dist/max)` clamped to `[0, 1]`.

### `raycaster::sprite_projection`

Billboard sprite screen-space transform.

- **`SpriteProjection`** (struct) — Screen X position, scale factor, distance, and visibility flag for a projected sprite.

### `raycaster::column_batch`

Batched per-column wall rendering state.

- **`ColumnData`** (struct) — Per-column state: texture U, screen Y start/end, shade, cell value, and depth.
- **`ColumnBatch`** (struct) — Array of `ColumnData` sized to screen width, plus floor/ceiling colors. Supports bulk update from raw ray data.

### `raycaster::depth_buffer`

1D per-column depth for sprite occlusion.

- **`DepthBuffer`** (struct) — One depth value per screen column; `is_visible()` gates sprite drawing against stored wall depth.

### `raycaster::doors`

Wolfenstein-style sliding door animation.

- **`DoorDirection`** (enum) — `Horizontal` or `Vertical` slide axis.
- **`DoorState`** (enum) — `Closed`, `Opening`, `Open`, `Closing` animation states.
- **`Door`** (struct) — Position, open amount `[0, 1]`, speed, direction, and state for a single door.
- **`DoorManager`** (struct) — Manages a list of doors; drives open/close animation via `update(dt)`.

### `raycaster::heightmap`

Per-cell variable floor and ceiling heights.

- **`HeightMap`** (struct) — Stores floor and ceiling height per grid cell. Defaults: floor=0.0, ceiling=1.0. Supports rectangular region fill.

### `raycaster::lighting`

Ambient + point-light illumination.

- **`PointLight`** (struct) — World position, radius, intensity, and RGB color.
- **`compute_lighting`** (fn) — Aggregates ambient + all point lights at a world position; inverse-distance falloff within radius; returns `[r, g, b]` clamped to `[0, 1]`.
- **`apply_lit_shade`** (fn) — Multiplies base shade by light color channels.

### `raycaster::minimap_overlay`

Top-down minimap rasterisation.

- **`extract_minimap`** (fn) — Rasterises a view-radius crop of the grid centered on the player to flat RGBA pixel data; draws a player arrow at the center.
- **`draw_player_arrow`** (fn) — Renders a directional arrow (filled circle + direction line) onto an RGBA pixel buffer.

## Key Types

### Structs

#### `raycaster::dda::Raycaster2D`

2D grid-based raycaster using DDA traversal. The grid stores wall types as `u32` values: 0 = empty, >0 = wall. Coordinates are 0-based with (0,0) at top-left. Public methods: `new`, `set_cell`, `get_cell`, `set_cells`, `is_blocked`, `width`, `height`, `cells`, `cast_ray`, `cast_rays`, `cast_rays_flat`, `line_of_sight`, `project_sprite`.

#### `raycaster::ray_hit::RayHit`

Per-column ray cast result. Fields: `distance` (fisheye-corrected perpendicular), `raw_distance` (Euclidean), `cell_value` (wall type), `side` (0=horizontal, 1=vertical), `tex_u` (texture coordinate in `[0, 1]`), `hit_x`/`hit_y` (world-space intersection), `hit` (bool flag).

#### `raycaster::segment::Segment`

A line segment from `(x1, y1)` to `(x2, y2)` in world space, used by the geometry raycaster `cast_ray_2d` and `field_of_view`.

#### `raycaster::sprite_projection::SpriteProjection`

Billboard sprite screen-space projection result. Fields: `screen_x` (center X), `scale` (render scale), `distance` (camera distance), `visible` (in front of camera).

#### `raycaster::column_batch::ColumnData`

Per-column rendering state: `tex_u`, `start`/`end` (screen Y range), `shade` (brightness 0–1), `cell_val` (wall type), `depth` (ray distance).

#### `raycaster::column_batch::ColumnBatch`

Screen-width array of `ColumnData` with floor/ceiling colors. Methods: `new`, `set_column`, `get_column`, `update_from_ray_data`, `get_depth_at`.

#### `raycaster::depth_buffer::DepthBuffer`

1D depth buffer storing one depth value per screen column. Methods: `new`, `clear`, `set`, `get`, `is_visible`, `width`. Initialized to `f32::MAX`.

#### `raycaster::doors::Door`

Single door instance with grid position `(x, y)`, `open_amount` in `[0, 1]`, animation `speed`, `direction`, and `state`.

#### `raycaster::doors::DoorManager`

Manages a list of `Door` objects. Methods: `new`, `add_door`, `open_door`, `close_door`, `update`, `get_door_at`, `doors`. Animation driven by `update(dt)`.

#### `raycaster::heightmap::HeightMap`

Per-cell floor and ceiling heights. Methods: `new`, `set_floor`, `set_ceiling`, `floor_at`, `ceiling_at`, `set_floor_rect`, `set_ceiling_rect`.

#### `raycaster::lighting::PointLight`

Point light source with world position `(x, y)`, `radius`, `intensity`, and `color` (`[f32; 3]`).

### Enums

#### `raycaster::doors::DoorDirection`

Slide axis for a door. Variants: `Horizontal`, `Vertical`.

#### `raycaster::doors::DoorState`

Animation state of a door. Variants: `Closed`, `Opening`, `Open`, `Closing`.

## Lua API

The Lua-facing surface is registered in `src/lua_api/raycaster_api.rs` under the `lurek.raycaster` namespace. The API exposes a `LuaRaycaster` UserData wrapping `Raycaster2D` and two free helper functions.

### Module functions (`lurek.raycaster.*`)

| Function | Signature | Description |
|----------|-----------|-------------|
| `new` | `(width, height) → Raycaster` | Creates a new raycaster grid |
| `projectColumn` | `(distance, fov, screen_height) → wall_height, draw_start, draw_end` | Projects wall distance to screen-space column parameters |
| `distanceShade` | `(distance, max_distance) → number` | Distance-based brightness in `[0, 1]` |

### Raycaster UserData methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `setCell` | `(x, y, val)` | Sets the cell value at grid position |
| `getCell` | `(x, y) → integer` | Returns the cell value at grid position |
| `setCells` | `(cells_table)` | Bulk-sets all cells from a flat row-major table |
| `isBlocked` | `(x, y) → boolean` | Returns true if cell value > 0 |
| `width` | `() → integer` | Returns grid width |
| `height` | `() → integer` | Returns grid height |
| `castRay` | `(ox, oy, angle, max_dist) → table\|nil` | Single DDA ray cast; returns hit table or nil |
| `castRays` | `(ox, oy, angle, fov, count, max_dist) → table` | Multi-ray fan cast; returns array of hit tables |
| `castRaysFlat` | `(ox, oy, angle, fov, count, max_dist) → table` | Multi-ray fan cast; flat array of 5 floats per ray |
| `lineOfSight` | `(x1, y1, x2, y2) → boolean` | DDA line-of-sight check between two points |
| `projectSprite` | `(sx, sy, px, py, pa, fov, screen_w) → table` | Projects world-space sprite to screen coordinates |

### Hit table fields

`distance`, `raw_distance`, `cell_value`, `side`, `tex_u`, `hit_x`, `hit_y`, `hit`

### Sprite projection table fields

`screen_x`, `scale`, `distance`, `visible`

## Lua Examples

```lua
-- Wolfenstein-style raycaster with distance fog
local rc
local px, py, pa = 3.5, 3.5, 0.0
local fov = math.pi / 3
local columns = 320

function lurek.init()
    rc = lurek.raycaster.new(16, 16)
    -- Build a walled enclosure
    for x = 0, 15 do
        rc:setCell(x, 0, 1)
        rc:setCell(x, 15, 1)
    end
    for y = 0, 15 do
        rc:setCell(0, y, 1)
        rc:setCell(15, y, 1)
    end
    -- Add some interior walls
    rc:setCell(5, 5, 2)
    rc:setCell(10, 8, 3)
end

function lurek.process(dt)
    -- Simple movement
    if lurek.keyboard.isDown("w") then
        px = px + math.cos(pa) * 3 * dt
        py = py + math.sin(pa) * 3 * dt
    end
    if lurek.keyboard.isDown("a") then pa = pa - 2 * dt end
    if lurek.keyboard.isDown("d") then pa = pa + 2 * dt end
end

function lurek.render()
    local w, h = lurek.gfx.getDimensions()
    local rays = rc:castRays(px, py, pa, fov, columns, 20.0)

    for i, hit in ipairs(rays) do
        if hit.hit then
            local wall_h, start, stop = lurek.raycaster.projectColumn(hit.distance, fov, h)
            local shade = lurek.raycaster.distanceShade(hit.distance, 20.0)
            -- Darker on vertical side hits
            if hit.side == 1 then shade = shade * 0.7 end
            lurek.gfx.setColor(shade, shade, shade)
            local col_w = w / columns
            lurek.gfx.rectangle("fill", (i - 1) * col_w, start, col_w, stop - start)
        end
    end
end
```

```lua
-- Line of sight check
local can_see = rc:lineOfSight(3.5, 3.5, 10.5, 8.5)
if can_see then
    print("Clear line of sight!")
end

-- Sprite projection
local sp = rc:projectSprite(10.5, 8.5, px, py, pa, fov, 640)
if sp.visible then
    local size = 64 * sp.scale
    lurek.gfx.draw(enemy_img, sp.screen_x - size / 2, 240 - size / 2, 0, sp.scale, sp.scale)
end
```

## Item Summary

| Kind       | Count  |
|------------|--------|
| `struct`   | 11     |
| `enum`     | 2      |
| `fn`       | 46     |
| **Total**  | **59** |

## References

| Module          | Relationship | Notes                                                    |
|-----------------|--------------|----------------------------------------------------------|
| `math`          | Imports from | `Color` type used by `ColumnBatch` floor/ceiling colors  |
| `engine`        | Imports from | `log_messages` constants for structured logging          |
| `lua_api`       | Imported by  | `raycaster_api.rs` binds `Raycaster2D` as UserData       |
| `graphics`      | Consumed by  | Lua scripts use `lurek.gfx` to draw column output    |
| `image`         | Related      | `extract_minimap` produces RGBA data usable with `lurek.img.newImageData` |
| `minimap`       | Similar      | `minimap` module handles full minimap rendering; `raycaster::minimap_overlay` is a lightweight pixel-buffer extraction specific to raycaster grids |
| `pathfinding`   | Similar      | Both operate on grids; raycaster does ray traversal, pathfinding does graph search |

## Notes

- **Constraint A-03 compliance**: The raycaster produces 2D column draw data (screen Y ranges, shading, texture coordinates) that Lua scripts render as filled rectangles or textured quads via `lurek.gfx`. No 3D scene graph or perspective projection pipeline is involved — it is pseudo-3D rendering via 2D draw calls, which is explicitly allowed under A-03.
- **Renderer-agnostic**: The module never touches `DrawCommand`, `SharedState` resource pools, or GPU types. All output is plain `f32`/`u32`/`Vec<u8>` data that the Lua layer consumes through the `lurek.raycaster` API and renders independently.
- **Cell type `u32`**: Wall cells store `u32` values. Zero means empty; any positive value is a wall type that scripts can use for multi-texture lookup.
- **Fisheye correction**: `cast_rays` applies `cos(angle_diff)` correction to perpendicular distances. `cast_ray` returns the raw perpendicular distance. The `raw_distance` field always holds the uncorrected Euclidean distance.
- **`cast_rays_flat` layout**: 5 floats per ray in order: `[distance, cell_value, side, tex_u, hit(0/1)]`. This flat format is optimised for `ColumnBatch::update_from_ray_data` and avoids per-ray Lua table creation overhead.
- **Extension subsystems are optional**: `ColumnBatch`, `DoorManager`, `HeightMap`, `DepthBuffer`, `PointLight`, and `extract_minimap` are independent features. A game can use only `Raycaster2D.castRays` and ignore everything else.
- **Lua API coverage gap**: Only `Raycaster2D`, `project_column`, and `distance_shade` are exposed to Lua. Extension types (`ColumnBatch`, `DoorManager`, `HeightMap`, `DepthBuffer`, `PointLight`, `Segment`, `field_of_view`, `extract_minimap`) are Rust-only and not yet bound. Scripts needing these features must implement equivalent logic in Lua or await future API additions.
- **Inline unit tests**: `depth_buffer.rs`, `doors.rs`, `heightmap.rs`, `lighting.rs`, `minimap_overlay.rs`, `projection.rs`, `segment.rs`, `visibility.rs`, and `dda.rs` all contain `#[cfg(test)] mod tests` blocks in addition to the external integration tests in `tests/rust/unit/raycaster_tests.rs`.
