# `src/tilemap/` — Tilemap System

## Purpose

The tilemap module is one of the deepest systems in Luna2D — providing a
complete tile-based game foundation from simple orthographic grids to complex
multi-level isometric worlds.  A `TileMap` supports multiple named layers
(background tiles, gameplay tiles, collision layer, decorative overlay) each
with independent visibility and per-tile collision flags; the collision layer
drives both AABB overlap tests and a continuous sweep test using the
Minkowski-sum difference that handles moving platforms and fast projectiles
correctly at any speed without tunnelling.

Advanced storage: the `ChunkMap` provides sparse chunk-based storage for
infinite or very large worlds where only currently-loaded chunks occupy
memory.  Chunks are addressed via Euclidean division so the world extends in
all four directions from the origin with negative coordinates supported.  The
autotile system (`AutoTileSheet`) eliminates manual tile selection: given a
bitmask of same-type neighbours, it returns the correct tile ID automatically
using one of three algorithms — Blob47 for full 8-directional corner autotiling,
Composite48 quarter-tile composition for its characteristic 48-tile sheet
format, and Minimal16 for simple 4-directional edge-only autotiling.

TMX import reads Tiled editor files covering all four orientations (orthogonal,
isometric, staggered, hexagonal) with CSV and Base64+zlib/gzip tile encoding,
plus object layers exposing spawn points, trigger regions, and level-design
annotations.  The 28 coordinate transform functions cover orthographic,
isometric, and hexagonal grids.  Procedural map generation from a
script-of-steps (noise pass, cellular automata, flood fill, room placement,
corridor connection) with a seeded LCG RNG produces deterministic maps from
compact scripts.

## Architecture

```
tilemap/
  │
  ├── TileMap ── multi-layer tilemap with collision
  │     ├── Layers: Vec<TileLayer>
  │     ├── Tile access: set/get_tile (Lua 1-based coords)
  │     ├── Animation: update_animations(dt)
  │     ├── Viewport culling: visible tile range
  │     └── Collision: is_solid, rect_overlaps_solid, sweep_rect (AABB+Minkowski)
  │
  ├── TileSet ── atlas configuration + animation + autotile
  │     ├── Tile dimensions, atlas columns
  │     ├── Per-tile animation frames
  │     └── Autotile rules (4-bit or 8-bit)
  │
  ├── ChunkMap ── sparse chunk-based tile storage
  │     ├── Infinite map support (negative coordinates)
  │     ├── chunk_size × chunk_size chunks
  │     └── Load/unload chunks dynamically
  │
    ├── AutoTileSheet ── bitmask-to-tile mappings
    │     ├── Blob47 (47-tile full corner)
    │     ├── Composite48 (48-tile quarter-tile composition)
    │     └── Minimal16 (16-tile simplified)
  │
  ├── TMX loader ── Tiled editor format
  │     ├── Orthogonal, Isometric, Staggered, Hexagonal
  │     ├── CSV and Base64+zlib/gzip tile data
  │     └── Tilesets, tile layers, object layers
  │
  ├── Coordinate transforms
  │     ├── 28 pub functions for iso + hex coords
  │     ├── Isometric ↔ screen conversion
  │     └── Hex (pointy/flat) ↔ screen + hex distance/neighbors
  │
  ├── MapGen ── procedural map generation
  │     ├── MapScript with 22-field steps
  │     ├── 8 StepTypes (noise, cellular, fill, scatter, ...)
  │     └── Lcg32 RNG for deterministic generation
  │
  └── IsoMap ── multi-level isometric rendering
        ├── IsoTile: Floor/NorthWall/WestWall/Object parts
        ├── Multiple vertical levels
        └── Diagonal-order painter's algorithm
```

### How It Works

The Lua-facing tile coordinate convention is 1-based — tile (1, 1) is the
top-left corner — matching Tiled's own 1-based convention and preventing
off-by-one mistakes in typical game iteration loops like
`for y = 1, map_height do ... end`.  Internally Rust uses 0-based indices;
the `lua_to_internal(coord)` conversion is applied at the API boundary and
nowhere else.

The sweep test in `TileMap::sweep_rect(rect, dx, dy)` uses the Minkowski AABB
difference trick: the blocker is expanded by half the mover's dimensions and
the movement delta is treated as a ray.  The earliest ray/AABB intersection
gives the blocked fraction of motion and the blocking wall normal.  The result
is a `SweepResult { fraction, normal }` struct.  This provides sub-tile
precision even when moving many tiles per frame, which is especially important
for fast projectiles.

Blob47 autotile bitmasks use the 8 cardinal and diagonal neighbours mapped to
bits 7..0.  The reduction step removes corner bits when neither adjacent edge
bit is set (a corner cannot be concave if neither wall face is present),
reducing the 256 possible 8-bit masks to the 47 visually distinct tile shapes.
The full 256→47 reduction is a pre-computed lookup table (`BLOB47_REDUCTION`)
for O(1) mapping per tile.

`ChunkMap` uses `div_euclid` for chunk coordinate calculation, which correctly
handles negative world coordinates: tile at world X = −1 maps to chunk −1
(not chunk 0 with a negative offset), so chunk boundaries align with the world
origin regardless of sign.

### Dependency Direction

```
tilemap/ ──────► math (Vec2)
```

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports all public types.

**~31 lines** — re-exports.

---

### `tilemap.rs` — `TileMap` (Core Tilemap)

**~664 lines** | Multi-layer tilemap with viewport culling and collision.

#### Struct: `TileMap`

40+ methods for layer management, tile access, animation, and collision.

#### Key Features

| Feature | Methods |
|---------|---------|
| Layers | `add_layer`, `remove_layer`, `get/set_layer_visible` |
| Tiles | `set_tile`, `get_tile` (Lua 1-based), `fill`, `fill_rect` |
| Viewport | `set_viewport`, `get_visible_range` |
| Animation | `update_animations(dt)` |
| Collision | `is_solid(x, y)`, `rect_overlaps_solid(rect)` |
| Sweep test | `sweep_rect(rect, dx, dy)` → `SweepResult` (Minkowski AABB) |

**Design**: Lua 1-based coordinate convention — tile (1,1) is the top-left.
Sweep test uses `sweep_aabb_vs_aabb` Minkowski difference for continuous
collision detection.

---

### `tileset.rs` — `TileSet`

**~217 lines** | Tile atlas configuration with animation and autotile rules.

16 methods for atlas dimensions, tile properties, animation frame access,
and autotile rule management (4-bit and 8-bit bitmask support).

---

### `chunk.rs` — `ChunkMap` (Sparse Storage)

**~387 lines** | Chunk-based infinite map storage.

#### Struct: `ChunkMap`

```rust
pub struct ChunkMap {
    chunk_size: u32,
    chunks: HashMap<(i32, i32), Vec<u32>>,   // (chunk_x, chunk_y) → tile data
}
```

15 methods including `get/set_tile`, `fill_rect`, `load/unload_chunk`,
`get_chunks_in_view`, `get_loaded_chunks`.

**Design**: Sparse HashMap storage supports negative coordinates via
`div_euclid` for chunk addressing. Default GID = 0 (empty tile).

---

### `autotile_sheet.rs` — `AutoTileSheet`

**~537 lines** | Three autotile layout algorithms.

#### Enum: `AutoTileLayout`

| Layout | Tiles | Method |
|--------|-------|--------|
| `Blob47` | 47 tiles | Full 8-bit bitmask (corners + edges) |
| `Composite48` | Variable | 48-tile quarter-tile composition (QUARTER_POSITIONS) |
| `Minimal16` | 16 tiles | 4-bit bitmask (edges only) |

9+ methods for bitmask-to-tile conversion. Bitmask reduction simplifies
the 256-case 8-bit mask to the 47 visually distinct cases.

---

### `tmx.rs` — TMX Loader (Tiled Editor)

**~614 lines** | XML-based Tiled map file loader.

#### Enum: `TmxOrientation`

`Orthogonal | Isometric | Staggered | Hexagonal`

#### Structs

| Struct | Purpose |
|--------|---------|
| `TmxMap` | Root map: orientation, dimensions, tilesets, layers |
| `TmxTileset` | Tileset: first GID, tile size, image source |
| `TmxTileLayer` | Tile layer: name, dimensions, tile data |
| `TmxObjectLayer` | Object layer: name, objects list |
| `TmxObject` | Object: id, name, type, position, dimensions |

Function `load_tmx(xml: &str) → Result<TmxMap>` — parses XML with
CSV or Base64+zlib/gzip tile data encoding.

---

### `coords.rs` — Coordinate Transforms

**~376 lines** | 28 public functions for isometric and hexagonal coordinates.

| Category | Functions |
|----------|-----------|
| Isometric | `iso_to_screen`, `screen_to_iso`, `iso_diamond_to_screen`, etc. |
| Hex (pointy) | `hex_to_pixel_pointy`, `pixel_to_hex_pointy`, `hex_round` |
| Hex (flat) | `hex_to_pixel_flat`, `pixel_to_hex_flat` |
| Hex utility | `hex_distance`, `hex_neighbors`, `hex_ring`, `hex_spiral` |

---

### `mapgen.rs` — Procedural Map Generation

**~652 lines** | Script-driven map generation.

| Struct | Purpose |
|--------|---------|
| `MapGen` | Generator with grid output |
| `MapScript` | Sequence of generation steps |
| `ScriptStep` | Individual step (22 configuration fields) |
| `MapBlock` | Room/region definition |
| `MapGroup` | Group of related blocks |

#### 8 Step Types

`Noise | Cellular | Fill | Scatter | River | Room | Connect | Custom`

Uses `Lcg32` RNG for deterministic generation from a seed.

---

### `isomap.rs` — `IsoMap` (Multi-Level Isometric)

**~413 lines** | Multi-level isometric tilemap with painter's algorithm rendering.

#### Struct: `IsoTile`

```rust
pub struct IsoTile {
    pub parts: [u32; 4],   // Floor, NorthWall, WestWall, Object
}
```

#### Enum: `IsoTilePart`

`Floor | NorthWall | WestWall | Object`

14 methods for multi-level tile access, viewport culling, and
diagonal-order painter's algorithm draw order.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/tilemap_api.rs` (~1900 lines), one of
the largest API files. Exposes tilemaps, autotile, TMX loading, coordinate
transforms, and chunk maps under `luna.tilemap.*`.

### Usage from Lua

```lua
-- Create tilemap
local map = luna.tilemap.newTileMap(100, 100, 32, 32)
local layer = map:addLayer("ground")
map:setTile(layer, 1, 1, 5)  -- 1-based coords

-- Load Tiled map
local tmx = luna.tilemap.loadTMX("maps/level1.tmx")

-- Coordinate transforms
local sx, sy = luna.tilemap.isoToScreen(tx, ty, 64, 32)

-- Collision
if not map:isSolid(tx, ty) then
    player:moveTo(tx, ty)
end

-- Autotile
local sheet = luna.tilemap.newAutoTileSheet("blob47")
local tile_id = sheet:getTile(bitmask)
```
