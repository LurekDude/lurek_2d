# `tilemap` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.tilemap` |
| **Source** | `src/tilemap/` |
| **Rust Tests** | `tests/rust/unit/tilemap_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_tilemap.lua`, `tests/lua/stress/test_tilemap_stress.lua`, `tests/lua/integration/test_tilemap_physics.lua`, `tests/lua/integration/test_tilemap_pathfinding.lua`, `tests/lua/integration/test_tilemap_camera.lua`, `tests/lua/integration/test_savegame_tilemap.lua`, `tests/lua/integration/test_procgen_tilemap.lua`, `tests/lua/golden/test_tilemap_golden.lua`, `tests/lua/evidence/test_evidence_tilemap.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `tilemap` module is Lurek2D's general-purpose grid world toolkit. It owns orthogonal tile layers, tilesets, autotiling, isometric map data, sparse chunk storage, Tiled TMX import, procedural block-based generation, coordinate helpers, and a few specialized map-side utilities such as polygon regions and first-person tile walking.

It exists so scripts can build and query tile-driven worlds without pushing map rules into the renderer or the physics layer. The module focuses on map representation, map math, tile semantics, and CPU-side generation or query work. The Lua bridge exposes the script-facing API, but the actual state and algorithms live here.

It intentionally does not own GPU resources, texture loading, camera policy, scene management, or physics simulation. It can generate render commands and collision-friendly map queries, but rendering stays in `render` and collision resolution stays outside the module.

**Scope boundary**: This module currently depends on `image`, `math`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.tilemap.* (Lua API — src/lua_api/tilemap_api.rs)
    |
    v
src/tilemap/mod.rs
    |- autotile_sheet.rs - autotile_sheet
    |- chunk.rs - chunk
    |- coords.rs - coords
    |- isomap.rs - isomap
    |- large_map_renderer.rs - large_map_renderer
    |- mapgen.rs - mapgen
    |- polygon_map.rs - polygon_map
    |- render.rs - render
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `autotile_sheet.rs` | Defines autotile lookup tables for blob-47, composite-48, and minimal-16 layouts and applies those rules onto a `TileSet`. |
| `chunk.rs` | Implements `ChunkMap`, a sparse chunked tile store for very large or effectively infinite worlds with negative coordinate support. |
| `coords.rs` | Provides standalone isometric and hex-grid conversion helpers so scripts and engine code can reason about non-orthogonal tile coordinates without embedding projection math elsewhere. |
| `isomap.rs` | Stores multi-level isometric maps and yields painter-ordered draw items for floor, wall, and object parts per cell. |
| `large_map_renderer.rs` | Tracks chunk visibility, dirty state, viewport, and LOD metadata for large tile worlds that need efficient culling-friendly batching. |
| `mapgen.rs` | Implements prefab blocks, grouped block libraries, scripted generation steps, and map assembly logic for procedural tilemap authoring. |
| `mod.rs` | Declares the tilemap submodules and re-exports the main map, tileset, generation, TMX, isometric, and utility types as the public module surface. |
| `polygon_map.rs` | Manages named polygon regions with hit testing, labels, highlight state, and bounding-box queries for map overlays or province-style regions. |
| `render.rs` | Adds `TileMap` render-command generation so tile layers can be turned into CPU-side draw commands without putting map traversal logic in the renderer. |
| `tile_walker.rs` | Implements a cardinal, cell-by-cell movement controller for dungeon-crawler or raycast-style navigation on a tile grid. |
| `tilemap.rs` | Holds the core layered `TileMap`, including tile CRUD, per-layer display state, viewport culling, animation state, and tile collision queries. |
| `tileset.rs` | Defines `TileSet` atlas layout, per-tile animation frames, solid flags, and 4-bit or 8-bit autotile rule tables. |
| `tmx.rs` | Parses Tiled TMX data, including tilesets, tile layers, object layers, and supported encoded tile payloads. |

---

## Submodules

### `tilemap::autotile_sheet`

Defines autotile lookup tables for blob-47, composite-48, and minimal-16 layouts and applies those rules onto a `TileSet`.

- **`AutoTileLayout`** (enum): Predefined autotile sheet layout variants.
- **`AutoTileSheet`** (struct): An autotile sheet that maps layout conventions to bitmask-based tile selection.

### `tilemap::chunk`

Implements `ChunkMap`, a sparse chunked tile store for very large or effectively infinite worlds with negative coordinate support.

- **`ChunkMap`** (struct): A chunk-based tilemap that supports large and infinite maps through sparse storage.

### `tilemap::coords`

Provides standalone isometric and hex-grid conversion helpers so scripts and engine code can reason about non-orthogonal tile coordinates without embedding projection math elsewhere.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `tilemap::isomap`

Stores multi-level isometric maps and yields painter-ordered draw items for floor, wall, and object parts per cell.

- **`IsoTilePart`** (enum): The four sub-slots within each isometric map cell, rendered in this order.
- **`IsoTile`** (struct): One map cell containing four GIDs, one per [`IsoTilePart`].
- **`IsoLevel`** (struct): One Z-level of the isometric map — a 2-D grid of [`IsoTile`]s.
- **`IsoDrawItem`** (struct): One renderable item produced by [`IsoMap::draw_iter`] in painter's order.
- **`IsoMap`** (struct): Multi-level isometric tilemap with painter's-algorithm draw iteration.

### `tilemap::large_map_renderer`

Tracks chunk visibility, dirty state, viewport, and LOD metadata for large tile worlds that need efficient culling-friendly batching.

- **`MapChunk`** (struct): A chunk of tiles pre-batched for fast culling and rendering.
- **`LargeMapRenderer`** (struct): Optimized large tile-map renderer with chunked culling.

### `tilemap::mapgen`

Implements prefab blocks, grouped block libraries, scripted generation steps, and map assembly logic for procedural tilemap authoring.

- **`Edge`** (enum): Cardinal edge direction for block-segment connectivity.
- **`MapBlock`** (struct): A prefab grid of tiles that can be stamped into a generated map.
- **`MapGroup`** (struct): A biome-like container holding [`MapBlock`] prefabs and [`MapScript`] generators.
- **`StepType`** (enum): The type of operation a [`ScriptStep`] performs.
- **`ScriptStep`** (struct): A single step in a [`MapScript`] with rich configuration.
- **`MapScript`** (struct): A named sequence of [`ScriptStep`]s that drives procedural generation.
- **`MapOrientation`** (enum): Map orientation for visual layout hints.
- **`LayerMode`** (enum): How layers are managed during generation.
- **`MapSize`** (enum): Predefined map size presets expressed in segment-grid units.
- **`MapZone`** (struct): A named horizontal zone within a generated map.

### `tilemap::polygon_map`

Manages named polygon regions with hit testing, labels, highlight state, and bounding-box queries for map overlays or province-style regions.

- **`PolygonRegion`** (struct): A named polygon region.
- **`PolygonMap`** (struct): Polygon map renderer with region management and hit detection.

### `tilemap::render`

Adds `TileMap` render-command generation so tile layers can be turned into CPU-side draw commands without putting map traversal logic in the renderer.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `tilemap::tile_walker`

Implements a cardinal, cell-by-cell movement controller for dungeon-crawler or raycast-style navigation on a tile grid.

- **`Facing`** (enum): Cardinal facing direction.
- **`TileWalker`** (struct): Tile-based movement controller for first-person grid navigation.

### `tilemap::tilemap`

Holds the core layered `TileMap`, including tile CRUD, per-layer display state, viewport culling, animation state, and tile collision queries.

- **`TileLayer`** (struct): A single layer of tiles in a [`TileMap`].
- **`SweepResult`** (struct): Result of a swept-AABB collision test against solid tiles.
- **`TileMap`** (struct): A 2D tile map composed of layers, tilesets, and viewport-clipped rendering state.

### `tilemap::tileset`

Defines `TileSet` atlas layout, per-tile animation frames, solid flags, and 4-bit or 8-bit autotile rule tables.

- **`TileAnimFrame`** (struct): A single frame in a tile animation sequence.
- **`TileSet`** (struct): A tile set that maps local tile IDs to atlas regions, animations, and collision flags.

### `tilemap::tmx`

Parses Tiled TMX data, including tilesets, tile layers, object layers, and supported encoded tile payloads.

- **`TmxOrientation`** (enum): Rendering orientation of the map, as specified in the TMX `orientation` attribute.
- **`TmxStaggerAxis`** (enum): The axis along which isometric / hexagonal tiles are staggered.
- **`TmxTileset`** (struct): A tileset reference embedded in a TMX map.
- **`TmxTileLayer`** (struct): A standard tile layer from a TMX map.
- **`TmxObjectLayer`** (struct): An object layer (object group) from a TMX map.
- **`TmxObject`** (struct): A single Tiled object within an object layer.
- **`TmxLayer`** (enum): Variant tag for TMX map layers.
- **`TmxMap`** (struct): A fully-parsed TMX map.

---

## Key Types

### Public Types

#### `TileMap`

The main layered orthogonal map container.

#### `TileLayer`

A single named tile layer with visibility, tint, parallax, offset, and per-tile GID storage.

#### `SweepResult`

The return value for swept AABB tile collision tests, carrying hit point, normal, tile coordinates, and time-of-impact.

#### `TileSet`

Atlas metadata plus per-tile behavior such as solidity, animation, and autotile rule mappings.

#### `TileAnimFrame`

One frame in a tile animation sequence, pairing a local tile id with a duration.

#### `AutoTileSheet`

Precomputed autotile layout helper that maps neighbor bitmasks to tile indices for common autotile atlas formats.

#### `AutoTileLayout`

Enumerates the supported autotile sheet conventions and therefore which lookup rules apply.

#### `ChunkMap`

Sparse tile storage for streamed or massive maps where allocating one dense grid would be wasteful.

#### `IsoMap`

Multi-level isometric map model that stores four tile parts per cell and yields stable painter-order iteration.

#### `IsoLevel`

One Z-level within an `IsoMap`, holding the grid of `IsoTile` cells for that floor.

#### `IsoTilePart` - Names the four per-cell isometric slots`

floor, north wall, west wall, and object.

#### `IsoDrawItem`

A render-ready isometric cell part with tile coordinates, level, part, gid, and projected screen position.

#### `MapBlock`

A reusable prefab tile block with multi-layer tile data and edge metadata for procedural placement.

#### `MapGroup`

A named collection of blocks and generation scripts that acts like a biome or prefab library.

#### `MapGen`

The procedural assembly engine that consumes blocks and scripted steps to build a `TileMap`.

#### `MapScript`

A reusable scripted generation recipe composed of ordered `ScriptStep` values.

#### `ScriptStep`

One procedural generation operation with parameters such as placement mode, size filters, repetition, and chance.

#### `StepType`

Identifies which generation action a `ScriptStep` performs.

#### `MapOrientation`

Describes the intended map orientation mode used by generation and map construction code.

#### `LargeMapRenderer`

CPU-side helper for chunk visibility and LOD bookkeeping over large dense tilemaps.

#### `MapChunk`

The chunk record stored by `LargeMapRenderer`, including dirty state and the chunk's local tile payload.

#### `PolygonMap`

A named region overlay useful for province, zone, or area queries over a world map.

#### `PolygonRegion`

One polygon region entry with geometry, display color, and optional label.

#### `TileWalker`

Simple first-person or grid-walk movement state with facing and interpolation support.

#### `Facing`

Cardinal facing direction used by `TileWalker`.

#### `TmxMap`

Parsed TMX document containing map dimensions, tilesets, and loaded layers.

#### `TmxTileset`

TMX-side tileset metadata, including atlas info and solid tile markers.

#### `TmxLayer`

Tagged enum for the layer kinds parsed from a TMX file.

#### `TmxTileLayer`

Parsed tile layer payload from TMX.

#### `TmxObjectLayer`

Parsed object-layer payload from TMX.

#### `TmxObject`

One object entry from a TMX object layer.

#### `TmxOrientation`

TMX map orientation enum.

#### `IsoTilePart`

Principal type for the `tilemap` module.

#### `IsoTile`

Principal type for the `tilemap` module.

#### `Edge`

Principal type for the `tilemap` module.

---

## Lua API

Exposed under `lurek.tilemap.*` by `src/lua_api/tilemap_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.tilemap.newTileSet` | Creates a new TileSet with the given atlas layout parameters. |
| `lurek.tilemap.newTileMap` | Creates a new TileMap with the given tile size and chunk size. |
| `lurek.tilemap.newAutoTileSheet` | Creates a new AutoTileSheet with the given tile dimensions and layout. |
| `lurek.tilemap.newChunkMap` | Creates a new ChunkMap with the given chunk size. |
| `lurek.tilemap.newIsoMap` | Creates a new IsoMap with no levels. |
| `lurek.tilemap.newMapBlock` | Creates a new MapBlock with the given dimensions. |
| `lurek.tilemap.newMapGroup` | Creates a new empty MapGroup with the given name. |
| `lurek.tilemap.toScreenIso` | Converts tile coordinates to screen position using diamond isometric projection. |
| `lurek.tilemap.fromScreenIso` | Converts screen position back to tile coordinates for diamond isometric projection. |
| `lurek.tilemap.toScreenHex` | Converts axial hex coordinates to screen position (pointy-top layout). |
| `lurek.tilemap.fromScreenHex` | Converts screen position back to axial hex coordinates (pointy-top layout). |
| `lurek.tilemap.hexNeighbors` | Returns the six axial neighbor coordinates as a table of {q, r} pairs. |
| `lurek.tilemap.hexDistance` | Returns the hex distance between two axial coordinates. |
| `lurek.tilemap.hexRound` | Rounds fractional axial coordinates to the nearest hex cell. |
| `lurek.tilemap.hexLine` | Returns all hex cells along a line between two axial coordinates as a table. |
| `lurek.tilemap.hexRing` | Returns all cells at exactly radius distance from (q, r) as a table. |
| `lurek.tilemap.hexSpiral` | Returns all hex cells from center outward to radius, ring by ring, as a table. |
| `lurek.tilemap.hexArea` | Returns all hex cells within radius distance (filled hex circle) as a table. |
| `lurek.tilemap.hexRotate` | Rotates hex coordinates around a center by steps x 60 degrees clockwise. |
| `lurek.tilemap.hexReflect` | Reflects hex coordinates across an axis through the center. |
| `lurek.tilemap.isoRotate` | Rotates an isometric direction (1-4) clockwise by steps. |
| `lurek.tilemap.isoDirectionName` | Returns the name of an isometric direction (1-4). |
| `lurek.tilemap.isoDirectionFromAngle` | Snaps an angle (in radians) to the nearest isometric direction (1-4). |
| `lurek.tilemap.newMapScript` | Creates a new empty MapScript procedural generation script. |
| `lurek.tilemap.newMapGen` | Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size. |
| `lurek.tilemap.loadTMX` | Parses a TMX XML string and returns a table with map metadata and layers. |

### `AutoTileSheet` Methods

| Method | Description |
|--------|-------------|
| `autotilesheet:getLayout(...)` | Returns the layout variant as a string. |
| `autotilesheet:getTileCount(...)` | Returns the number of tiles in this sheet. |
| `autotilesheet:getTileWidth(...)` | Returns the tile width in pixels. |
| `autotilesheet:getTileHeight(...)` | Returns the tile height in pixels. |
| `autotilesheet:getBitmaskForTile(...)` | Returns the bitmask value associated with a 1-based local tile ID. |
| `autotilesheet:getTileForBitmask(...)` | Returns the 1-based tile ID for a given bitmask, or nil. |
| `autotilesheet:getQuad(...)` | Returns the atlas region rectangle for the 1-based tile ID. |

### `ChunkMap` Methods

| Method | Description |
|--------|-------------|
| `chunkmap:getTile(...)` | Returns the GID at tile coordinate (x, y). |
| `chunkmap:setTile(...)` | Sets the GID at tile coordinate (x, y). |
| `chunkmap:clearTile(...)` | Clears the tile at (x, y) by setting its GID to 0. |
| `chunkmap:loadChunk(...)` | Pre-allocates the chunk at chunk coordinates (cx, cy). |
| `chunkmap:unloadChunk(...)` | Removes the chunk at chunk coordinates (cx, cy) from memory. |
| `chunkmap:getChunkSize(...)` | Returns the chunk size (tiles per side). |
| `chunkmap:getLoadedChunks(...)` | Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}. |
| `chunkmap:chunkTileRange(...)` | Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1). |

### `IsoMap` Methods

| Method | Description |
|--------|-------------|
| `isomap:addLevel(...)` | Appends a new empty Z-level and returns its 1-based index. |
| `isomap:getLevelCount(...)` | Returns the number of Z-levels currently in the map. |
| `isomap:setLevelVisible(...)` | Sets the visibility of a level (1-based z). |
| `isomap:isLevelVisible(...)` | Returns the visibility of a level (1-based z). |
| `isomap:fillLevel(...)` | Fills every cell in level z with gid for the given part (1-based z; 0-based part). |
| `isomap:setOrigin(...)` | Sets the screen pixel origin. |
| `isomap:getWidth(...)` | Returns the map width in tiles. |
| `isomap:getHeight(...)` | Returns the map height in tiles. |
| `isomap:getTileWidth(...)` | Returns the tile footprint width in pixels. |
| `isomap:getTileHeight(...)` | Returns the tile footprint height in pixels. |
| `isomap:getLevelHeight(...)` | Returns the vertical pixel offset between consecutive Z-levels. |
| `isomap:tileToScreen(...)` | Projects isometric tile coordinates (tx, ty, tz) to screen pixels. |
| `isomap:screenToTile(...)` | Converts screen pixel coordinates to isometric tile coordinates at Z-level 0. |

### `MapBlock` Methods

| Method | Description |
|--------|-------------|
| `mapblock:getTile(...)` | Returns the GID of the tile at (x, y) on the given layer (1-based). |
| `mapblock:getSide(...)` | Returns the side connection ID for a segment on a given edge. |
| `mapblock:getWidth(...)` | Returns the block width in tiles. |
| `mapblock:getHeight(...)` | Returns the block height in tiles. |
| `mapblock:getDimensions(...)` | Returns the block dimensions as (width, height) in tiles. |
| `mapblock:getLayerCount(...)` | Returns the number of layers in this block. |
| `mapblock:getSegmentSize(...)` | Returns the segment size in tiles. |
| `mapblock:getWidthInSegments(...)` | Returns the number of segments along the width. |
| `mapblock:getHeightInSegments(...)` | Returns the number of segments along the height. |
| `mapblock:setName(...)` | Sets the human-readable name of this block. |
| `mapblock:getName(...)` | Returns the name of this block. |
| `mapblock:setWeight(...)` | Sets the placement weight. |
| `mapblock:getWeight(...)` | Returns the placement weight. |

### `MapGroup` Methods

| Method | Description |
|--------|-------------|
| `mapgroup:addBlock(...)` | Adds a block to this group. |
| `mapgroup:getBlockCount(...)` | Returns the number of blocks in this group. |
| `mapgroup:removeBlock(...)` | Removes a block by 1-based index. |
| `mapgroup:getName(...)` | Returns the name of this group. |
| `mapgroup:addScript(...)` | Adds a MapScript to this group. |
| `mapgroup:getScriptCount(...)` | Returns the number of scripts in this group. |

### `MapScript` Methods

| Method | Description |
|--------|-------------|
| `mapscript:getStepCount(...)` | Returns the number of steps in this script. |
| `mapscript:addStep(...)` | Appends a generation step from a step-definition table. |

### `TileMap` Methods

| Method | Description |
|--------|-------------|
| `tilemap:addTileSet(...)` | Adds a tileset to this map. |
| `tilemap:getTileSetCount(...)` | Returns the number of tilesets attached to this map. |
| `tilemap:getTileSet(...)` | Returns a tileset by 1-based index, or nil if out of range. |
| `tilemap:addLayer(...)` | Adds a new empty layer and returns its 1-based index. |
| `tilemap:getLayerCount(...)` | Returns the number of layers. |
| `tilemap:getLayerName(...)` | Returns the name of a layer by 1-based index. |
| `tilemap:getLayerVisible(...)` | Returns layer visibility. |
| `tilemap:getLayerColor(...)` | Returns the RGBA tint color of a layer. |
| `tilemap:getLayerOffset(...)` | Returns the pixel offset of a layer. |
| `tilemap:getLayerParallax(...)` | Returns the parallax factor of a layer. |
| `tilemap:getTile(...)` | Returns the GID at (x, y) on the given layer (1-based). |
| `tilemap:clearTile(...)` | Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based). |
| `tilemap:fill(...)` | Fills an entire layer with the given GID (1-based layer). |
| `tilemap:getViewport(...)` | Returns the viewport as (x, y, w, h) or nil if not set. |
| `tilemap:update(...)` | Advances tile animation timers by dt seconds. |
| `tilemap:worldToTile(...)` | Converts world pixel coordinates to tile coordinates. |
| `tilemap:tileToWorld(...)` | Converts tile coordinates to world pixel coordinates (1-based input). |
| `tilemap:getTileWidth(...)` | Returns the tile width in pixels. |
| `tilemap:getTileHeight(...)` | Returns the tile height in pixels. |
| `tilemap:getTileDimensions(...)` | Returns tile dimensions as (width, height). |
| `tilemap:getChunkSize(...)` | Returns the chunk size used for spatial partitioning. |
| `tilemap:isSolid(...)` | Returns true if the tile at (x, y) on layer is solid (1-based). |
| `tilemap:getOrientation(...)` | Returns the map orientation as a string ("topdown" or "sideview"). |
| `tilemap:setOrientation(...)` | Sets the map orientation from a string ("topdown" or "sideview"). |
| `tilemap:render(...)` | Renders the tile map to the screen at the given offset. |
| `tilemap:drawToImage(...)` | Renders the tile map to a CPU ImageData using the given tile pixel size. |

### `TileSet` Methods

| Method | Description |
|--------|-------------|
| `tileset:getFirstGid(...)` | Returns the first global ID assigned to this tileset. |
| `tileset:getTileCount(...)` | Returns the total number of tiles in this tileset. |
| `tileset:getColumns(...)` | Returns the number of tile columns in the atlas texture. |
| `tileset:getTileWidth(...)` | Returns the width of a single tile in pixels. |
| `tileset:getTileHeight(...)` | Returns the height of a single tile in pixels. |
| `tileset:getTileDimensions(...)` | Returns the tile dimensions as (width, height). |
| `tileset:getSpacing(...)` | Returns the spacing in pixels between tiles in the atlas. |
| `tileset:getMargin(...)` | Returns the margin in pixels around the edges of the atlas. |
| `tileset:getQuad(...)` | Computes the atlas source rectangle for a 1-based local tile ID. |
| `tileset:getAnimation(...)` | Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil. |
| `tileset:setSolid(...)` | Sets whether a 1-based local tile ID is solid for collision purposes. |
| `tileset:isSolid(...)` | Returns whether a 1-based local tile ID is solid. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.tilemap.
if lurek.tilemap then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 27 |
| `enum` | 11 |
| `fn` (Lua API) | 113 |
| **Total** | **151** |

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

- **Source of truth**: Keep this spec synchronized with `src/tilemap/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
