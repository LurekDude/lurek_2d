# tilemap — AGENT.md

| Field | Value |
|---|---|
| **Module** | `tilemap` |
| **Path** | `src/tilemap/` |
| **Tier** | Tier 2 — Engine Extension |
| **Imports** | `math` (Vec2, Rect, Color), `engine` (log_messages) |
| **Peer deps** | None (no Tier 2 ↔ Tier 2 cross-imports) |
| **Lua namespace** | `luna.tilemap` |
| **API file** | `src/lua_api/tilemap_api.rs` |
| **Test files** | `tests/rust/unit/tilemap_tests.rs` (159 tests), `tests/lua/unit/test_tilemap.lua` (151 tests), `tests/lua/integration/test_tilemap_physics.lua`, `tests/lua/integration/test_tilemap_physics2.lua`, `tests/lua/stress/test_tilemap_stress.lua`, `tests/lua/stress/test_tilemap_stress2.lua` |

## Purpose

The `tilemap` module provides a comprehensive tilemap toolkit for 2D game development: orthogonal and isometric grids, sparse chunk-based infinite maps, hex and iso coordinate math, tile animation, per-tile collision detection with swept AABB support, autotiling (4-bit cardinal and 8-bit directional including blob-47 and composite-48 sheet helpers), TMX/TSX file parsing (Tiled editor import), procedural map generation via block prefabs and scripted placement steps, polygon region maps with point-in-polygon hit detection, a large-map renderer with LOD and camera-based chunk culling, and a first-person tile-walker controller for dungeon-crawler movement. The module is self-contained at Tier 2, importing only `math` (Vec2, Rect, Color) and `engine` (log_messages). It exposes seven UserData types to Lua (`TileSet`, `TileMap`, `AutoTileSheet`, `ChunkMap`, `IsoMap`, `MapBlock`, `MapGroup`) plus 16 standalone coordinate-helper functions. All Lua layer/tile indices use 1-based Lua convention, while Rust internals use 0-based indexing; the API boundary in `tilemap_api.rs` performs the translation. Additional Rust-only types (`LargeMapRenderer`, `PolygonMap`, `TileWalker`) are exported for direct Rust consumption but have no Lua bindings yet.

## Source Files

| File | Lines | Purpose |
|---|---|---|
| `mod.rs` | ~50 | Module root — declares 11 submodules, re-exports all public types |
| `tilemap.rs` | ~950 | Core `TileMap` with multi-layer support, viewport culling, tile animation, 4/8-bit autotile, collision (overlap + swept AABB) |
| `tileset.rs` | ~400 | `TileSet` — atlas layout, quad computation, animation frames, solid flags, 4-bit and 8-bit autotile rule storage |
| `chunk.rs` | ~270 | `ChunkMap` — sparse chunk-based storage for large/infinite maps using `HashMap<(i32,i32), Vec<u32>>` |
| `isomap.rs` | ~480 | `IsoMap` — multi-level isometric tilemap with painter's-algorithm draw ordering and coordinate conversion |
| `coords.rs` | ~400 | 17 standalone coordinate helpers for diamond-iso projection, iso direction/rotation, and hex grids (axial coordinates) |
| `autotile_sheet.rs` | ~500 | `AutoTileSheet` — bitmask-to-tile lookup tables for blob-47, composite-48 (quarter-tile), and minimal-16 autotile layouts |
| `mapgen.rs` | ~1200 | `MapGen`, `MapBlock`, `MapGroup`, `MapScript`, `ScriptStep` — block-prefab procedural map generation with scripted placement |
| `tmx.rs` | ~450 | `load_tmx()` — Tiled TMX/TSX format parser (CSV, XML, base64, zlib, gzip data encodings) |
| `large_map_renderer.rs` | ~430 | `LargeMapRenderer` — optimized large-map renderer with chunk-based dirty tracking, LOD thresholds, and camera viewport culling |
| `polygon_map.rs` | ~280 | `PolygonMap` — named polygon regions with point-in-polygon hit detection, highlighting, labels, and bounding box queries |
| `tile_walker.rs` | ~380 | `TileWalker` — tile-based first-person movement controller with cardinal Facing, smooth interpolation, and relative direction |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/tilemap.md`](../../specs/tilemap.md)

_Update both this file **and** `specs/tilemap.md` whenever source files, public types, or Lua bindings change._
