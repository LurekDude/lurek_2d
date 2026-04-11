# tilemap

## Module Info
- Module name: `tilemap`
- Module group: `Feature Systems`
- Spec path: `docs/specs/tilemap.md`
- Lua API path(s): `src/lua_api/tilemap_api.rs`
- Rust test path(s): `tests/rust/unit/tilemap_tests.rs`
- Lua test path(s): `tests/lua/unit/test_tilemap.lua`, `tests/lua/stress/test_tilemap_stress.lua`, `tests/lua/integration/test_tilemap_physics.lua`, `tests/lua/integration/test_tilemap_pathfinding.lua`, `tests/lua/integration/test_tilemap_camera.lua`, `tests/lua/integration/test_savegame_tilemap.lua`, `tests/lua/integration/test_procgen_tilemap.lua`, `tests/lua/golden/test_tilemap_golden.lua`, `tests/lua/evidence/test_evidence_tilemap.lua`

## Module Purpose
The `tilemap` module is Lurek2D's general-purpose grid world toolkit. It owns orthogonal tile layers, tilesets, autotiling, isometric map data, sparse chunk storage, Tiled TMX import, procedural block-based generation, coordinate helpers, and a few specialized map-side utilities such as polygon regions and first-person tile walking.

It exists so scripts can build and query tile-driven worlds without pushing map rules into the renderer or the physics layer. The module focuses on map representation, map math, tile semantics, and CPU-side generation or query work. The Lua bridge exposes the script-facing API, but the actual state and algorithms live here.

It intentionally does not own GPU resources, texture loading, camera policy, scene management, or physics simulation. It can generate render commands and collision-friendly map queries, but rendering stays in `render` and collision resolution stays outside the module.

## Files
- `mod.rs` - Declares the tilemap submodules and re-exports the main map, tileset, generation, TMX, isometric, and utility types as the public module surface.
- `autotile_sheet.rs` - Defines autotile lookup tables for blob-47, composite-48, and minimal-16 layouts and applies those rules onto a `TileSet`.
- `chunk.rs` - Implements `ChunkMap`, a sparse chunked tile store for very large or effectively infinite worlds with negative coordinate support.
- `coords.rs` - Provides standalone isometric and hex-grid conversion helpers so scripts and engine code can reason about non-orthogonal tile coordinates without embedding projection math elsewhere.
- `isomap.rs` - Stores multi-level isometric maps and yields painter-ordered draw items for floor, wall, and object parts per cell.
- `large_map_renderer.rs` - Tracks chunk visibility, dirty state, viewport, and LOD metadata for large tile worlds that need efficient culling-friendly batching.
- `mapgen.rs` - Implements prefab blocks, grouped block libraries, scripted generation steps, and map assembly logic for procedural tilemap authoring.
- `polygon_map.rs` - Manages named polygon regions with hit testing, labels, highlight state, and bounding-box queries for map overlays or province-style regions.
- `render.rs` - Adds `TileMap` render-command generation so tile layers can be turned into CPU-side draw commands without putting map traversal logic in the renderer.
- `tile_walker.rs` - Implements a cardinal, cell-by-cell movement controller for dungeon-crawler or raycast-style navigation on a tile grid.
- `tilemap.rs` - Holds the core layered `TileMap`, including tile CRUD, per-layer display state, viewport culling, animation state, and tile collision queries.
- `tileset.rs` - Defines `TileSet` atlas layout, per-tile animation frames, solid flags, and 4-bit or 8-bit autotile rule tables.
- `tmx.rs` - Parses Tiled TMX data, including tilesets, tile layers, object layers, and supported encoded tile payloads.

## Key Types
- `TileMap` - The main layered orthogonal map container. It owns tilesets, layers, animation timers, viewport state, and the map-side queries that other systems consume.
- `TileLayer` - A single named tile layer with visibility, tint, parallax, offset, and per-tile GID storage.
- `SweepResult` - The return value for swept AABB tile collision tests, carrying hit point, normal, tile coordinates, and time-of-impact.
- `TileSet` - Atlas metadata plus per-tile behavior such as solidity, animation, and autotile rule mappings.
- `TileAnimFrame` - One frame in a tile animation sequence, pairing a local tile id with a duration.
- `AutoTileSheet` - Precomputed autotile layout helper that maps neighbor bitmasks to tile indices for common autotile atlas formats.
- `AutoTileLayout` - Enumerates the supported autotile sheet conventions and therefore which lookup rules apply.
- `ChunkMap` - Sparse tile storage for streamed or massive maps where allocating one dense grid would be wasteful.
- `IsoMap` - Multi-level isometric map model that stores four tile parts per cell and yields stable painter-order iteration.
- `IsoLevel` - One Z-level within an `IsoMap`, holding the grid of `IsoTile` cells for that floor.
- `IsoTilePart` - Names the four per-cell isometric slots: floor, north wall, west wall, and object.
- `IsoDrawItem` - A render-ready isometric cell part with tile coordinates, level, part, gid, and projected screen position.
- `MapBlock` - A reusable prefab tile block with multi-layer tile data and edge metadata for procedural placement.
- `MapGroup` - A named collection of blocks and generation scripts that acts like a biome or prefab library.
- `MapGen` - The procedural assembly engine that consumes blocks and scripted steps to build a `TileMap`.
- `MapScript` - A reusable scripted generation recipe composed of ordered `ScriptStep` values.
- `ScriptStep` - One procedural generation operation with parameters such as placement mode, size filters, repetition, and chance.
- `StepType` - Identifies which generation action a `ScriptStep` performs.
- `MapOrientation` - Describes the intended map orientation mode used by generation and map construction code.
- `LargeMapRenderer` - CPU-side helper for chunk visibility and LOD bookkeeping over large dense tilemaps.
- `MapChunk` - The chunk record stored by `LargeMapRenderer`, including dirty state and the chunk's local tile payload.
- `PolygonMap` - A named region overlay useful for province, zone, or area queries over a world map.
- `PolygonRegion` - One polygon region entry with geometry, display color, and optional label.
- `TileWalker` - Simple first-person or grid-walk movement state with facing and interpolation support.
- `Facing` - Cardinal facing direction used by `TileWalker`.
- `TmxMap` - Parsed TMX document containing map dimensions, tilesets, and loaded layers.
- `TmxTileset` - TMX-side tileset metadata, including atlas info and solid tile markers.
- `TmxLayer` - Tagged enum for the layer kinds parsed from a TMX file.
- `TmxTileLayer` - Parsed tile layer payload from TMX.
- `TmxObjectLayer` - Parsed object-layer payload from TMX.
- `TmxObject` - One object entry from a TMX object layer.
- `TmxOrientation` - TMX map orientation enum.