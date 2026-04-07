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

---

## Summary

The `tilemap` module provides a comprehensive tilemap toolkit for 2D game development: orthogonal and isometric grids, sparse chunk-based infinite maps, hex and iso coordinate math, tile animation, per-tile collision detection with swept AABB support, autotiling (4-bit cardinal and 8-bit directional including blob-47 and composite-48 sheet helpers), TMX/TSX file parsing (Tiled editor import), procedural map generation via block prefabs and scripted placement steps, polygon region maps with point-in-polygon hit detection, a large-map renderer with LOD and camera-based chunk culling, and a first-person tile-walker controller for dungeon-crawler movement. The module is self-contained at Tier 2, importing only `math` (Vec2, Rect, Color) and `engine` (log_messages). It exposes seven UserData types to Lua (`TileSet`, `TileMap`, `AutoTileSheet`, `ChunkMap`, `IsoMap`, `MapBlock`, `MapGroup`) plus 16 standalone coordinate-helper functions. All Lua layer/tile indices use 1-based Lua convention, while Rust internals use 0-based indexing; the API boundary in `tilemap_api.rs` performs the translation. Additional Rust-only types (`LargeMapRenderer`, `PolygonMap`, `TileWalker`) are exported for direct Rust consumption but have no Lua bindings yet.

---

## Architecture

```
                  luna.tilemap (Lua namespace)
                         |
                         v
            +--- tilemap_api.rs -----------------------------------+
            |  LuaTileSet   LuaTileMap   LuaAutoTileSheet          |
            |  LuaChunkMap  LuaIsoMap    LuaMapBlock   LuaMapGroup |
            |  + 16 coord helpers (iso, hex)                       |
            +------------------+-----------------------------------+
                               | Rc<RefCell<T>>
  +----------------------------+------------------------------------+
  |                    src/tilemap/                                  |
  |                                                                 |
  |  tilemap.rs --- TileMap, TileLayer, SweepResult                |
  |       |             multi-layer, animation, autotile, collision |
  |       +-- tileset.rs --- TileSet, TileAnimFrame                |
  |                             atlas layout, solid flags, autotile |
  |                                                                 |
  |  chunk.rs ---- ChunkMap                                        |
  |                    sparse HashMap-based infinite storage        |
  |                                                                 |
  |  isomap.rs --- IsoMap, IsoLevel, IsoTile, IsoTilePart,        |
  |                IsoDrawItem                                      |
  |                    multi-level iso with painter's-algorithm     |
  |                                                                 |
  |  coords.rs -- 17 standalone functions (iso + hex)              |
  |                                                                 |
  |  autotile_sheet.rs -- AutoTileSheet, AutoTileLayout            |
  |                          bitmask-to-tile lookup tables          |
  |                                                                 |
  |  mapgen.rs --- MapGen, MapBlock, MapGroup, MapScript,          |
  |                MapZone, ScriptStep, StepType, Edge,            |
  |                MapOrientation, LayerMode, MapSize              |
  |                    procedural generation via scripts            |
  |                                                                 |
  |  tmx.rs ------ load_tmx(), TmxMap, TmxTileset, TmxTileLayer,  |
  |                TmxObjectLayer, TmxObject, TmxOrientation,      |
  |                TmxStaggerAxis, TmxLayer                        |
  |                    Tiled editor XML parser                      |
  |                                                                 |
  |  large_map_renderer.rs -- LargeMapRenderer, MapChunk           |
  |                              LOD + camera-based culling        |
  |                                                                 |
  |  polygon_map.rs -- PolygonMap, PolygonRegion                   |
  |                       hit detection, labels, highlighting      |
  |                                                                 |
  |  tile_walker.rs -- TileWalker, Facing                          |
  |                       first-person grid movement + interp      |
  +-------------------------------------------------------------+
         |                              |
         v                              v
  crate::math (Vec2, Rect, Color)   crate::engine (log_messages)
```

---

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

---

## Submodules

### `tilemap` (tilemap.rs)
Core orthogonal tilemap engine. Manages a stack of named `TileLayer`s, each a flat `Vec<u32>` of global tile IDs. Supports per-tile tinting via `tile_tints`, viewport-based culling, tile animation (driven by `TileSet` frame data), and orientation (`TopDown` / `SideView`). Autotile: computes 4-bit cardinal and 8-bit directional bitmasks then replaces tiles via `TileSet` rule lookups — both whole-layer and localized 3×3-neighborhood variants. Collision: `is_solid()` delegates to tileset solid flags; `rect_overlaps_solid()` checks world-space AABB overlap; `sweep_rect()` performs swept AABB continuous collision detection and returns `SweepResult` with contact point, surface normal, tile coordinates, and time-of-impact.

### `tileset` (tileset.rs)
Defines the atlas layout for a tile image. Each `TileSet` has a first GID, tile count, columns, tile dimensions, spacing, and margin. Computes source quads from atlas layout. Stores per-tile solid flags (`HashSet<u32>`), animation frame sequences (`HashMap<u32, Vec<TileAnimFrame>>`), and autotile rules in two maps: `auto_rules_4` (4-bit cardinal, key = `(String, u8)` → `u32`) and `auto_rules_8` (8-bit directional, key = `(String, u16)` → `u32`).

### `chunk` (chunk.rs)
Sparse chunk-based tile storage for arbitrarily large or infinite maps. Tiles are organized into square chunks of configurable size in a `HashMap<(i32,i32), Vec<u32>>`. Uses Euclidean division for correct negative coordinate support. Key operations: get/set/clear tiles, fill rectangles, load/unload chunks, query visible chunks by world-pixel viewport, iterate chunk tiles, and compute chunk-to-tile ranges and world rects.

### `isomap` (isomap.rs)
Multi-level isometric tilemap. Each `IsoLevel` is a grid of `IsoTile`s, each containing 4 GID slots corresponding to `IsoTilePart` variants: `Floor`, `NorthWall`, `WestWall`, `Object`. The `IsoMap` manages a stack of toggleable levels with a configurable pixel height between levels. `tile_to_screen()` / `screen_to_tile()` perform diamond isometric projection. `draw_iter()` yields all tile parts in painter's-algorithm order (diagonal sweep: ascending `d = tx + ty`, then ascending `tx`, then ascending `z`, then part order) for correct back-to-front rendering.

### `coords` (coords.rs)
17 standalone coordinate conversion functions for isometric and hexagonal grid systems. Isometric: `to_screen_iso()`, `from_screen_iso()` (diamond projection), `iso_rotate()` (direction rotation 1–4), `iso_direction_name()`, `iso_direction_from_angle()`. Hexagonal (axial coordinates, pointy-top): `to_screen_hex()`, `from_screen_hex()`, `hex_neighbors()`, `hex_distance()`, `hex_round()`, `hex_line()` (Bresenham-style), `hex_ring()`, `hex_spiral()`, `hex_area()`, `hex_rotate()` (cube-coordinate rotation by 60° steps), `hex_reflect()` (cube-coordinate reflection across q/r/s axis).

### `autotile_sheet` (autotile_sheet.rs)
Manages bitmask-to-tile index mappings for three autotile layout variants. `Blob47` supports 47 distinct tiles using 8-bit bitmasks reduced to 4-bit + corner masking. `Composite48` uses 48 pre-composed tiles in a 6-column grid and also provides quarter-tile source/destination rects for rendering individual quarter-pieces (TL, TR, BL, BR). `Minimal16` uses a 16-tile 4-bit edge set. `apply_to_tileset()` bulk-registers all bitmask→tile rules into a `TileSet`. `get_quarter_rects()` returns four source `Rect`s for composite rendering of any 8-bit bitmask configuration.

### `mapgen` (mapgen.rs)
Procedural map generation framework. `MapBlock` is a multi-layer tile prefab with named segments and edge-connection side IDs for constraint-based placement. `MapGroup` collects blocks and `MapScript`s. `ScriptStep` configures a single generation operation (8 step types: FillRandom, PlaceBlock, PlaceRandom, PlaceLine, FloodFill, FillArea, DrawPath, FillRect) with 27 parameters including chance, repeat count, rotation, mirroring, conditional execution, zone filtering, and size filters. `MapGen` processes scripts via an LCG PRNG to produce `TileMap` output; `generate_world()` tiles multiple generation regions into a larger world map. Currently FillRandom, PlaceBlock, and FillRect are implemented; other step types are stubs.

### `tmx` (tmx.rs)
Parses Tiled editor TMX/TSX map files from XML using `roxmltree`. Supports tile layer data in CSV, XML element, base64, base64+zlib, and base64+gzip encodings; does not support zstd or infinite maps. Produces a `TmxMap` containing `TmxTileset`s (with solid tile markers), `TmxTileLayer`s (tile GID arrays), and `TmxObjectLayer`s (positioned objects with type, dimensions, and optional GID). Parses map-level properties: orientation (orthogonal, isometric, staggered, hexagonal), stagger axis, hex side length, and background color.

### `large_map_renderer` (large_map_renderer.rs)
Optimized renderer for large tilemaps using chunk-based dirty tracking and camera-viewport culling. The map is divided into `MapChunk`s of configurable size; each chunk has a dirty flag for incremental updates. The renderer maintains camera state (position, zoom) and viewport dimensions to compute visible chunk ranges. LOD support: three distance thresholds (`lod_thresholds`) with `lod_enabled` flag. Key operations: `set_map_data()` for bulk loading, per-tile get/set with automatic chunk invalidation, `get_visible_chunks()` for rendering only what is on screen.

### `polygon_map` (polygon_map.rs)
Named polygon region map for province/territory-style overlays. `PolygonRegion` stores a flat vertex array, fill color, optional label text with font size. `PolygonMap` manages regions in a `HashMap<String, PolygonRegion>` with configurable outline color/width and highlight color/name. `get_region_at()` performs ray-casting point-in-polygon queries. Supports centroid calculation, bounding box computation, per-region color/label management, and single-region highlighting.

### `tile_walker` (tile_walker.rs)
First-person tile-based movement controller for dungeon crawlers and grid-based games. `Facing` enum (North=0, East=1, South=2, West=3) with parsing, angle conversion, delta computation, and rotation methods. `TileWalker` tracks current position, facing, and previous state for smooth interpolation. Movement: `move_forward()`, `move_backward()`, `strafe_left()`, `strafe_right()`, `turn_left()`, `turn_right()`, `turn_around()`. `begin_move()` snapshots state; `get_interpolated_position()` and `get_interpolated_angle()` (shortest-path) provide smooth animation between steps. `get_relative_facing()` returns "front"/"back"/"left"/"right" for a target tile.

---

## Key Types

### Structs

| Type | File | Purpose |
|---|---|---|
| `TileMap` | `tilemap.rs` | Core tilemap: multi-layer, animation, autotile, collision |
| `TileLayer` | `tilemap.rs` | Single named layer: GID grid, visibility, tint, offset, parallax, per-tile tints |
| `SweepResult` | `tilemap.rs` | Swept AABB collision result: contact point (Vec2), normal (Vec2), tile coords, time-of-impact |
| `TileSet` | `tileset.rs` | Atlas layout, quad computation, animation frames, solid flags, autotile rules |
| `TileAnimFrame` | `tileset.rs` | Animation frame: tile_id + duration_ms |
| `ChunkMap` | `chunk.rs` | Sparse chunk storage: `HashMap<(i32,i32), Vec<u32>>` with configurable chunk_size |
| `IsoMap` | `isomap.rs` | Multi-level isometric map with diamond projection, draw ordering |
| `IsoLevel` | `isomap.rs` | Single isometric Z-level: grid of `IsoTile`s, toggleable visibility |
| `IsoTile` | `isomap.rs` | 4-slot tile: `parts: [u32; 4]` (Floor, NorthWall, WestWall, Object) |
| `IsoDrawItem` | `isomap.rs` | Draw iteration item: level, tile coords, part index, GID, screen position |
| `AutoTileSheet` | `autotile_sheet.rs` | Bitmask→tile lookup tables for blob-47, composite-48, minimal-16 layouts |
| `MapGen` | `mapgen.rs` | Procedural map generator: grid size, tile size, orientation, zones, seed |
| `MapBlock` | `mapgen.rs` | Multi-layer tile prefab with segment edges for constraint-based placement |
| `MapGroup` | `mapgen.rs` | Collection of `MapBlock`s and `MapScript`s |
| `MapScript` | `mapgen.rs` | Ordered sequence of `ScriptStep`s for procedural generation |
| `ScriptStep` | `mapgen.rs` | Single generation operation with 27 config fields |
| `MapZone` | `mapgen.rs` | Horizontal zone definition: name, start_row, height |
| `TmxMap` | `tmx.rs` | Parsed Tiled map: dimensions, tilesets, layers, background color |
| `TmxTileset` | `tmx.rs` | Parsed tileset: GID range, atlas dimensions, image source, solid tiles |
| `TmxTileLayer` | `tmx.rs` | Parsed tile layer: name, dimensions, visibility, opacity, offset, GID array |
| `TmxObjectLayer` | `tmx.rs` | Parsed object layer: name, visibility, objects |
| `TmxObject` | `tmx.rs` | Parsed object: id, name, type, position, size, optional GID |
| `LargeMapRenderer` | `large_map_renderer.rs` | Chunked renderer with LOD, dirty tracking, camera-based culling |
| `MapChunk` | `large_map_renderer.rs` | Single chunk: coords, dirty flag, tile_ids array |
| `PolygonMap` | `polygon_map.rs` | Named polygon region collection with hit detection and highlighting |
| `PolygonRegion` | `polygon_map.rs` | Single polygon: vertices, color, label, font_size |
| `TileWalker` | `tile_walker.rs` | Grid movement controller: position, facing, previous state for interpolation |

### Enums

| Type | File | Purpose |
|---|---|---|
| `IsoTilePart` | `isomap.rs` | Tile slot index: Floor, NorthWall, WestWall, Object |
| `AutoTileLayout` | `autotile_sheet.rs` | Sheet layout variant: Blob47, Composite48, Minimal16 |
| `Edge` | `mapgen.rs` | Block edge direction: North, East, South, West |
| `StepType` | `mapgen.rs` | Generation operation: FillRandom, PlaceBlock, PlaceRandom, PlaceLine, FloodFill, FillArea, DrawPath, FillRect |
| `MapOrientation` | `mapgen.rs` | Map view: TopDown, SideView |
| `LayerMode` | `mapgen.rs` | Layer handling: Unified, Separate |
| `MapSize` | `mapgen.rs` | Grid preset: Tiny, Small, Medium, Large, Huge, Custom(u32, u32) |
| `TmxOrientation` | `tmx.rs` | Tiled map orientation: Orthogonal, Isometric, Staggered, Hexagonal |
| `TmxStaggerAxis` | `tmx.rs` | Hex stagger axis: X, Y |
| `TmxLayer` | `tmx.rs` | Layer variant: Tile(TmxTileLayer), Object(TmxObjectLayer) |
| `Facing` | `tile_walker.rs` | Cardinal direction: North, East, South, West (with angle/delta methods) |

### Standalone Functions

| Function | File | Purpose |
|---|---|---|
| `load_tmx(xml: &str) -> Result<TmxMap, String>` | `tmx.rs` | Parse a TMX XML string into a `TmxMap` |
| `to_screen_iso(tx, ty, tw, th) -> Vec2` | `coords.rs` | Diamond iso tile→screen projection |
| `from_screen_iso(sx, sy, tw, th) -> Vec2` | `coords.rs` | Diamond iso screen→tile conversion |
| `iso_rotate(direction, steps) -> i32` | `coords.rs` | Rotate iso direction (1–4) by steps |
| `iso_direction_name(direction) -> &str` | `coords.rs` | Direction integer to name string |
| `iso_direction_from_angle(angle) -> i32` | `coords.rs` | Snap radians to iso direction |
| `to_screen_hex(q, r, size) -> Vec2` | `coords.rs` | Axial hex → screen (pointy-top) |
| `from_screen_hex(sx, sy, size) -> (i32, i32)` | `coords.rs` | Screen → axial hex |
| `hex_neighbors(q, r) -> [(i32,i32); 6]` | `coords.rs` | Six hex neighbors |
| `hex_distance(q1, r1, q2, r2) -> i32` | `coords.rs` | Manhattan hex distance |
| `hex_round(q, r) -> (i32, i32)` | `coords.rs` | Fractional to nearest hex cell |
| `hex_line(q1, r1, q2, r2) -> Vec<(i32,i32)>` | `coords.rs` | Bresenham hex line |
| `hex_ring(q, r, radius) -> Vec<(i32,i32)>` | `coords.rs` | Cells at exact distance |
| `hex_spiral(q, r, radius) -> Vec<(i32,i32)>` | `coords.rs` | Concentric ring spiral |
| `hex_area(q, r, radius) -> Vec<(i32,i32)>` | `coords.rs` | Filled hex disk |
| `hex_rotate(q, r, cq, cr, steps) -> (i32,i32)` | `coords.rs` | Cube rotation by 60° steps |
| `hex_reflect(q, r, cq, cr, axis) -> (i32,i32)` | `coords.rs` | Cube reflection across q/r/s axis |

---

## Lua API

Registered by `src/lua_api/tilemap_api.rs` under `luna.tilemap`.

### Factory Functions

| Lua Function | Returns | Description |
|---|---|---|
| `luna.tilemap.newTileSet(firstGid, tileCount, columns, tileW, tileH, spacing?, margin?)` | `TileSet` | Create a tileset with atlas layout |
| `luna.tilemap.newTileMap(tileW, tileH, chunkSize?)` | `TileMap` | Create a tilemap (default chunk 16) |
| `luna.tilemap.newAutoTileSheet(tileW, tileH, layout?)` | `AutoTileSheet` | Create autotile sheet ("blob47", "composite48", "minimal16") |
| `luna.tilemap.newChunkMap(chunkSize?)` | `ChunkMap` | Create sparse chunk storage |
| `luna.tilemap.newIsoMap(w, h, tileW, tileH, levelH)` | `IsoMap` | Create empty isometric map |
| `luna.tilemap.newMapBlock(w, h, layers?, segmentSize?)` | `MapBlock` | Create tile prefab |
| `luna.tilemap.newMapGroup(name)` | `MapGroup` | Create block group |

### Coordinate Helpers (standalone)

| Lua Function | Returns | Description |
|---|---|---|
| `luna.tilemap.toScreenIso(tx, ty, tileW, tileH)` | `sx, sy` | Diamond iso projection |
| `luna.tilemap.fromScreenIso(sx, sy, tileW, tileH)` | `tx, ty` | Reverse iso projection |
| `luna.tilemap.toScreenHex(q, r, size)` | `sx, sy` | Axial hex → screen |
| `luna.tilemap.fromScreenHex(sx, sy, size)` | `q, r` | Screen → axial hex |
| `luna.tilemap.hexNeighbors(q, r)` | `table` | Six neighbor coords |
| `luna.tilemap.hexDistance(q1, r1, q2, r2)` | `integer` | Hex Manhattan distance |
| `luna.tilemap.hexRound(q, r)` | `q, r` | Snap to nearest hex |
| `luna.tilemap.hexLine(q1, r1, q2, r2)` | `table` | Hex line cells |
| `luna.tilemap.hexRing(q, r, radius)` | `table` | Ring at distance |
| `luna.tilemap.hexSpiral(q, r, radius)` | `table` | Concentric spiral |
| `luna.tilemap.hexArea(q, r, radius)` | `table` | Filled hex disk |
| `luna.tilemap.hexRotate(q, r, cq, cr, steps)` | `q, r` | Cube rotation |
| `luna.tilemap.hexReflect(q, r, cq, cr, axis)` | `q, r` | Cube reflection |
| `luna.tilemap.isoRotate(direction, steps)` | `integer` | Rotate iso direction |
| `luna.tilemap.isoDirectionName(direction)` | `string` | Direction to name |
| `luna.tilemap.isoDirectionFromAngle(angle)` | `integer` | Angle to direction |

### TileSet Methods

| Method | Returns | Description |
|---|---|---|
| `:getFirstGid()` | `integer` | First global tile ID |
| `:getTileCount()` | `integer` | Total tiles |
| `:getColumns()` | `integer` | Atlas columns |
| `:getTileWidth()` | `integer` | Tile width px |
| `:getTileHeight()` | `integer` | Tile height px |
| `:getTileDimensions()` | `w, h` | Both dimensions |
| `:getSpacing()` | `integer` | Atlas spacing |
| `:getMargin()` | `integer` | Atlas margin |
| `:getQuad(tileId)` | `x, y, w, h` | Atlas source rect |
| `:setAnimation(tileId, frames)` | `nil` | Set frame sequence |
| `:getAnimation(tileId)` | `table?` | Get frame sequence |
| `:setSolid(tileId, solid)` | `nil` | Mark tile solid |
| `:isSolid(tileId)` | `boolean` | Check solid flag |
| `:setAutoTileRule(type, mask, id)` | `nil` | Register 4-bit rule |
| `:getAutoTileId(type, mask)` | `integer?` | Lookup 4-bit rule |
| `:setAutoTileRule8(type, mask, id)` | `nil` | Register 8-bit rule |
| `:getAutoTileId8(type, mask)` | `integer?` | Lookup 8-bit rule |

### TileMap Methods

| Method | Returns | Description |
|---|---|---|
| `:addTileSet(tileset)` | `nil` | Attach tileset |
| `:getTileSetCount()` | `integer` | Tileset count |
| `:addLayer(name, w, h)` | `integer` | Add layer (1-based index) |
| `:getLayerCount()` | `integer` | Layer count |
| `:getLayerName(idx)` | `string?` | Layer name |
| `:setLayerVisible(idx, visible)` | `nil` | Toggle visibility |
| `:getLayerVisible(idx)` | `boolean` | Check visibility |
| `:setLayerColor(idx, r, g, b, a)` | `nil` | Set layer tint |
| `:getLayerColor(idx)` | `r, g, b, a` | Get layer tint |
| `:setLayerOffset(idx, ox, oy)` | `nil` | Set pixel offset |
| `:getLayerOffset(idx)` | `ox, oy` | Get pixel offset |
| `:setLayerParallax(idx, px, py)` | `nil` | Set parallax factor |
| `:getLayerParallax(idx)` | `px, py` | Get parallax factor |
| `:setTile(layer, x, y, gid)` | `nil` | Set tile GID (1-based) |
| `:getTile(layer, x, y)` | `integer` | Get tile GID (1-based) |
| `:clearTile(layer, x, y)` | `nil` | Clear tile (1-based) |
| `:fill(layer, gid)` | `nil` | Fill entire layer |
| `:setViewport(x, y, w, h)` | `nil` | Set render viewport |
| `:getViewport()` | `x, y, w, h` | Get viewport |
| `:update(dt)` | `nil` | Advance animations |
| `:worldToTile(wx, wy)` | `tx, ty` | Pixel → tile (1-based) |
| `:tileToWorld(tx, ty)` | `wx, wy` | Tile → pixel (1-based) |
| `:getTileWidth()` | `integer` | Tile width px |
| `:getTileHeight()` | `integer` | Tile height px |
| `:getTileDimensions()` | `w, h` | Both dimensions |
| `:getChunkSize()` | `integer` | Spatial chunk size |
| `:isSolid(layer, x, y)` | `boolean` | Check solid (1-based) |
| `:applyAutoTile(layer, type)` | `nil` | 4-bit autotile full layer |
| `:applyAutoTileAt(layer, x, y, type)` | `nil` | 4-bit autotile local |
| `:applyAutoTile8(layer, type)` | `nil` | 8-bit autotile full layer |
| `:applyAutoTile8At(layer, x, y, type)` | `nil` | 8-bit autotile local |
| `:rectOverlapsSolid(layer, x, y, w, h)` | `boolean` | AABB solid check |
| `:sweepRect(layer, x, y, w, h, dx, dy)` | `table?` | Swept AABB collision |
| `:getOrientation()` | `string` | "topdown" or "sideview" |
| `:setOrientation(str)` | `nil` | Set orientation |
| `:setTileTint(layer, x, y, r, g, b, a)` | `nil` | Per-tile tint (1-based) |

### AutoTileSheet Methods

| Method | Returns | Description |
|---|---|---|
| `:getLayout()` | `string` | Layout name |
| `:getTileCount()` | `integer` | Tile count |
| `:getTileWidth()` | `integer` | Tile width px |
| `:getTileHeight()` | `integer` | Tile height px |
| `:applyToTileSet(tileset, type, startGid?)` | `nil` | Bulk-register rules |
| `:getBitmaskForTile(idx)` | `integer` | Reverse lookup |
| `:getTileForBitmask(mask)` | `integer?` | Forward lookup |
| `:getQuad(idx)` | `x, y, w, h` | Atlas source rect |

### ChunkMap Methods

| Method | Returns | Description |
|---|---|---|
| `:getTile(x, y)` | `integer` | GID at tile coords |
| `:setTile(x, y, gid)` | `nil` | Set tile |
| `:clearTile(x, y)` | `nil` | Clear tile |
| `:fillRect(x0, y0, x1, y1, gid)` | `nil` | Fill rect |
| `:loadChunk(cx, cy)` | `nil` | Pre-allocate chunk |
| `:unloadChunk(cx, cy)` | `nil` | Free chunk |
| `:getChunkSize()` | `integer` | Tiles per side |
| `:getLoadedChunks()` | `table` | All loaded chunk coords |
| `:getChunksInView(vx, vy, vw, vh, tw, th)` | `table` | Visible chunk coords |
| `:chunkTileRange(cx, cy)` | `x0, y0, x1, y1` | Tile range for chunk |

### IsoMap Methods

| Method | Returns | Description |
|---|---|---|
| `:addLevel()` | `integer` | Add Z-level (1-based) |
| `:getLevelCount()` | `integer` | Level count |
| `:setLevelVisible(z, visible)` | `nil` | Toggle level |
| `:isLevelVisible(z)` | `boolean` | Check level visibility |
| `:setTilePart(z, x, y, part, gid)` | `nil` | Write tile part (1-based z,x,y; 0-based part) |
| `:getTilePart(z, x, y, part)` | `integer` | Read tile part |
| `:fillLevel(z, part, gid)` | `nil` | Fill level |
| `:setOrigin(x, y)` | `nil` | Set screen origin |
| `:getWidth()` | `integer` | Map width tiles |
| `:getHeight()` | `integer` | Map height tiles |
| `:getTileWidth()` | `integer` | Tile footprint width px |
| `:getTileHeight()` | `integer` | Tile footprint height px |
| `:getLevelHeight()` | `integer` | Vertical offset per level |
| `:tileToScreen(tx, ty, tz)` | `sx, sy` | Iso projection |
| `:screenToTile(sx, sy)` | `tx, ty` | Reverse projection (Z=0) |

### MapBlock Methods

| Method | Returns | Description |
|---|---|---|
| `:setTile(layer, x, y, gid)` | `nil` | Set tile (1-based) |
| `:getTile(layer, x, y)` | `integer` | Get tile (1-based) |
| `:setSide(edge, segment, sideId)` | `nil` | Set edge connection |
| `:getSide(edge, segment)` | `integer` | Get edge connection |
| `:getWidth()` | `integer` | Block width tiles |
| `:getHeight()` | `integer` | Block height tiles |
| `:getDimensions()` | `w, h` | Both dimensions |
| `:getLayerCount()` | `integer` | Layer count |
| `:getSegmentSize()` | `integer` | Segment size |
| `:getWidthInSegments()` | `integer` | Segment columns |
| `:getHeightInSegments()` | `integer` | Segment rows |
| `:setName(name)` | `nil` | Set name |
| `:getName()` | `string` | Get name |
| `:setWeight(weight)` | `nil` | Placement weight |
| `:getWeight()` | `number` | Get weight |

### MapGroup Methods

| Method | Returns | Description |
|---|---|---|
| `:addBlock(block)` | `nil` | Add block |
| `:getBlockCount()` | `integer` | Block count |
| `:removeBlock(idx)` | `nil` | Remove block (1-based) |
| `:getName()` | `string` | Group name |

---

## Lua Examples

### Basic orthogonal tilemap
```lua
-- Create tileset and map
local ts = luna.tilemap.newTileSet(1, 64, 8, 32, 32)
ts:setSolid(5, true)  -- mark tile 5 as solid

local map = luna.tilemap.newTileMap(32, 32)
map:addTileSet(ts)
map:addLayer("ground", 20, 15)
map:fill(1, 1)          -- fill layer 1 with GID 1
map:setTile(1, 5, 5, 3) -- set tile at (5,5) to GID 3
map:setViewport(0, 0, 640, 480)

-- Animation
ts:setAnimation(1, {{2, 200}, {3, 200}, {4, 200}})
map:update(dt)
```

### 4-bit autotile
```lua
local ts = luna.tilemap.newTileSet(1, 64, 8, 32, 32)
for mask = 0, 15 do
    ts:setAutoTileRule("grass", mask, mask + 1)
end
local map = luna.tilemap.newTileMap(32, 32)
map:addTileSet(ts)
map:addLayer("terrain", 20, 15)
map:fill(1, 1)
map:applyAutoTile(1, "grass")        -- whole layer
map:setTile(1, 3, 3, 5)
map:applyAutoTileAt(1, 3, 3, "grass") -- localized update
```

### Hex grid coordinate helpers
```lua
local sx, sy = luna.tilemap.toScreenHex(3, 2, 32)
local q, r = luna.tilemap.fromScreenHex(sx, sy, 32)
local neighbors = luna.tilemap.hexNeighbors(q, r)
local dist = luna.tilemap.hexDistance(0, 0, 3, 2)
local ring = luna.tilemap.hexRing(0, 0, 2)
local line = luna.tilemap.hexLine(0, 0, 5, 3)
```

### Sparse chunk map
```lua
local chunks = luna.tilemap.newChunkMap(16)
chunks:setTile(100, 200, 5)
chunks:loadChunk(0, 0)
local visible = chunks:getChunksInView(0, 0, 800, 600, 32, 32)
local x0, y0, x1, y1 = chunks:chunkTileRange(0, 0)
```

### Isometric map
```lua
local iso = luna.tilemap.newIsoMap(10, 10, 64, 32, 24)
iso:addLevel()
iso:setTilePart(1, 1, 1, 0, 5)  -- Floor of tile (1,1) on level 1
iso:setOrigin(400, 100)
local sx, sy = iso:tileToScreen(3.0, 2.0, 0.0)
```

### Swept AABB collision
```lua
local result = map:sweepRect(1, px, py, pw, ph, dx, dy)
if result then
    -- result.contactX, result.contactY = contact point
    -- result.normalX, result.normalY   = surface normal
    -- result.tileX, result.tileY       = colliding tile (1-based)
    -- result.t                         = time of impact [0,1]
end
```

---

## Item Summary

| Category | Count |
|---|---|
| Source files | 12 |
| Structs | 27 |
| Enums | 11 |
| Standalone functions | 18 (17 coords + 1 tmx) |
| Lua UserData types | 7 (TileSet, TileMap, AutoTileSheet, ChunkMap, IsoMap, MapBlock, MapGroup) |
| Lua factory functions | 7 |
| Lua coord helpers | 16 |
| Lua methods (total) | ~120 across all UserData types |
| Rust tests | 159 (tests/rust/unit/tilemap_tests.rs) + inline tests in tileset.rs, large_map_renderer.rs, coords.rs |
| Lua tests | 151 (tests/lua/unit/test_tilemap.lua) + integration + stress |

---

## References

- `src/math/vec2.rs` — `Vec2` used by coordinate functions and `SweepResult`
- `src/math/rect.rs` — `Rect` used by atlas quads, viewports, swept collision, autotile sheet rects
- `src/math/color.rs` — `Color` used by `PolygonMap`, `PolygonRegion`, layer tints
- `src/lua_api/tilemap_api.rs` — Lua binding layer (7 UserData types + 16 standalone functions)
- `tests/rust/unit/tilemap_tests.rs` — 159 Rust integration tests
- `tests/lua/unit/test_tilemap.lua` — 151 Lua BDD tests
- `tests/lua/integration/test_tilemap_physics.lua` — Tilemap + collision cross-module tests
- `tests/lua/integration/test_tilemap_physics2.lua` — Additional tilemap + collision tests
- `tests/lua/stress/test_tilemap_stress.lua` — Performance stress tests
- `tests/lua/stress/test_tilemap_stress2.lua` — Additional stress tests
- `examples/tilemap.lua` — Lua tilemap usage example
- External crate `roxmltree` — XML parsing for TMX files
- External crate `base64` — Base64 decoding for TMX tile data
- External crate `flate2` — zlib/gzip decompression for TMX tile data

---

## Notes

- **Index convention**: All Lua-facing layer/tile indices are 1-based; Rust internals are 0-based. The `tilemap_api.rs` boundary performs `idx - 1` on inputs and `idx + 1` on outputs.
- **Rust-only types**: `LargeMapRenderer`, `MapChunk`, `PolygonMap`, `PolygonRegion`, `TileWalker`, and `Facing` are exported from the Rust module but have no Lua UserData wrappers in `tilemap_api.rs`.
- **MapGen not exposed to Lua**: The `MapGen` struct (procedural generation) has no Lua binding; only `MapBlock` and `MapGroup` are exposed. Generation must happen Rust-side or via a future Lua API extension.
- **TMX parser limitations**: `load_tmx()` does not support zstd compression, infinite maps, or embedded TSX references. Only external `.tsx` references are parsed inline. The parser is also not exposed to Lua.
- **Autotile step stubs**: `StepType::PlaceRandom`, `PlaceLine`, `FloodFill`, `FillArea`, and `DrawPath` are declared in `mapgen.rs` but not yet implemented in `MapGen::generate()`.
- **TileWalker collision**: `can_move_to()` always returns `true`; actual collision checking is deferred to the Lua layer.
- **Composite autotile rendering**: `AutoTileSheet::get_quarter_rects()` returns source sub-rects for quarter-tile rendering; the engine has no built-in composite draw call — game scripts must issue four blit calls per tile.
- **IsoMap draw_iter()**: Yields all tile parts including those with `gid == 0`; Lua should skip drawing those to keep the Rust side allocation-free.
- **LCG PRNG**: `MapGen` uses a simple linear congruential generator (`Lcg`) for deterministic procedural generation, not the engine's `RandomGenerator`.
