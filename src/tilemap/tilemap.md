# tilemap — Tile Maps, Procedural Generation & Autotile

> **Lua namespace:** `luna.tilemap`
> **C++ module:** `src/modules/tilemap/`
> **Purpose:** A comprehensive tile map engine with multi-layer rendering, tile animations, autotile rules, collision detection (solid tiles, rect overlap, swept AABB), isometric/hexagonal coordinate systems, and an X-COM-inspired procedural map generation system using MapBlocks, MapGroups, MapScripts, and MapGen.

## Reimplementation Notes

- **Coordinate convention**: All Lua-facing APIs use **1-based** tile/layer/segment indices. C++ internally subtracts 1.
- **Chunk-based rendering**: TileMap uses a chunk size (default 16) for spatial partitioning. SpriteBatch is used per-chunk for efficient rendering.
- **GID (Global Tile ID)**: Tiles are identified by a global integer ID. Each TileSet has a `firstGid`; the TileMap resolves which TileSet a GID belongs to. GID 0 = empty.
- **Autotile system**: TileSet stores rules mapping 4-bit cardinal neighbor bitmasks (N=1, E=2, S=4, W=8) to local tile IDs. TileMap can apply these rules to entire layers or single cells (with 3x3 neighborhood update).
- **Tile animations**: Each tile in a TileSet can have an animation — a sequence of `{tileid, duration}` frames. `update(dt)` advances all animations.
- **Collision**: `isSolid()` checks per-tile solidity (set on TileSet), `rectOverlapsSolid()` tests axis-aligned rect overlap, and `sweepRect()` performs continuous swept AABB collision returning contact point, normal, and hit tile coordinate.
- **Procedural generation** (MapGen): Inspired by X-COM: UFO Defense. A MapGroup holds prefab MapBlocks and MapScripts. MapGen creates a segment grid, runs a MapScript's steps to place blocks, then expands to a final TileMap. Supports zone constraints, layer modes, orientations.
- **MapScript step types**: `"fillRandom"`, `"placeBlock"`, `"placeRandom"`, `"placeLine"`, `"floodFill"`, `"fillArea"`, `"drawPath"`, `"fillRect"` — each with rich configuration (chance, conditions, transforms, size filters, zone constraints).
- **Viewport culling**: Set a viewport rectangle on TileMap; only visible chunks are drawn via `drawLayer()`.
- **Layer properties**: Each layer has name, visibility, tint color (RGBA), offset (px), and parallax factor.
- **Hex coordinate system**: Uses axial (q,r) coordinates with pointy-top orientation. Module provides conversion, neighbor lookup, distance, rounding, line drawing, rings, spirals, area selection, rotation, and reflection functions.
- **Iso coordinate system**: Diamond (staggered) isometric with standard `toScreenIso`/`fromScreenIso` projection formulas. Includes directional rotation for iso character sprites (4 directions at 90° intervals).
- **8-directional autotile**: In addition to the 4-bit cardinal bitmask (N=1,E=2,S=4,W=8), an 8-bit bitmask system adds diagonals (NE=16,SE=32,SW=64,NW=128) for 47-tile autotile sets compatible with a similar game engine/a similar game engine blob-style tiling. AutoTileSheet handles image-based autotile atlas loading and rule assignment.
- **AutoTileSheet**: Loads a pre-arranged autotile image (e.g., 47-tile blob set) and automatically generates TileSet tiles and 8-bit bitmask rules. Supports standard layouts: standard autotile A2-layout (6×8), a similar game engine 47-tile, a similar game engine 3×3 minimal (16-tile).

## Dependencies

- `luna.graphics` — for `Quad`, `SpriteBatch`, `Graphics` (rendering via `drawLayer`)
- `luna.image` — for texture data (TileSet references a texture)

## Module Functions

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `newTileSet` | `newTileSet(texture, firstGid, tileCount, columns, tileW, tileH [, spacing [, margin]])` | `TileSet` | Create a TileSet from a texture atlas. `firstGid` is the starting global tile ID. `spacing` and `margin` default to 0. |
| `newTileMap` | `newTileMap(tileW, tileH [, chunkSize])` | `TileMap` | Create an empty TileMap with the given tile pixel dimensions. `chunkSize` defaults to 16. |
| `toScreenIso` | `toScreenIso(tx, ty, tileW, tileH)` | `sx, sy` | Convert tile coordinates to screen position in diamond isometric projection. |
| `fromScreenIso` | `fromScreenIso(sx, sy, tileW, tileH)` | `tx, ty` | Convert screen position to tile coordinates in diamond isometric projection. |
| `toScreenHex` | `toScreenHex(q, r, size)` | `sx, sy` | Convert axial hex coordinates (pointy-top) to screen pixel position. |
| `fromScreenHex` | `fromScreenHex(sx, sy, size)` | `q, r` | Convert screen pixel position to axial hex coordinates (pointy-top). |
| `hexNeighbors` | `hexNeighbors(q, r)` | `table` | Return a table of 6 neighboring hex cells as `{q, r}` pairs. |
| `hexDistance` | `hexDistance(q1, r1, q2, r2)` | `int` | Calculate the hex distance between two axial coordinates. |
| `hexRound` | `hexRound(q, r)` | `int, int` | Round fractional axial coordinates to the nearest hex cell. |
| `newMapBlock` | `newMapBlock(width, height, layers, segmentSize)` | `MapBlock` | Create a prefab map block with given tile dimensions, number of layers, and segment size. |
| `newMapGroup` | `newMapGroup(name)` | `MapGroup` | Create a named map group (biome container for blocks and scripts). |
| `newMapScript` | `newMapScript()` | `MapScript` | Create an empty procedural generation script. |
| `newMapGen` | `newMapGen(group, sizeOrGridW [, gridH], segSize)` | `MapGen` | Create a map generator. First form: `(group, "small"|"medium"|"large", segSize)`. Second form: `(group, gridW, gridH, segSize)`. |
| `hexLine` | `hexLine(q1, r1, q2, r2)` | `table` | Return a list of hex cells `{q, r}` forming a line between two hex coordinates (Bresenham on hex grid). |
| `hexRing` | `hexRing(q, r, radius)` | `table` | Return all hex cells `{q, r}` at exactly `radius` distance from center. |
| `hexSpiral` | `hexSpiral(q, r, radius)` | `table` | Return all hex cells `{q, r}` in a spiral from center outward to `radius` (inclusive). |
| `hexArea` | `hexArea(q, r, radius)` | `table` | Return all hex cells `{q, r}` within `radius` distance from center (filled circle). |
| `hexRotate` | `hexRotate(q, r, centerQ, centerR, steps)` | `q, r` | Rotate a hex cell around a center by `steps` × 60° clockwise. |
| `hexReflect` | `hexReflect(q, r, centerQ, centerR, axis)` | `q, r` | Reflect a hex cell across an axis through center. `axis`: `"q"`, `"r"`, or `"s"`. |
| `isoRotate` | `isoRotate(direction, steps)` | `int` | Rotate an iso direction index (1–4) by `steps` × 90° clockwise. Returns new direction (1–4). |
| `isoDirectionName` | `isoDirectionName(direction)` | `string` | Get the name of an iso direction: 1=`"south"`, 2=`"west"`, 3=`"north"`, 4=`"east"`. |
| `isoDirectionFromAngle` | `isoDirectionFromAngle(angle)` | `int` | Snap an angle (radians) to the nearest iso direction (1–4). |
| `newAutoTileSheet` | `newAutoTileSheet(texture, tileW, tileH, layout)` | `AutoTileSheet` | Create an autotile sheet from an image. `layout`: `"blob47"`, `"composite48"`, `"minimal16"`. |

### MapSize Presets

| Size | Grid Dimensions |
|------|----------------|
| `"small"` | 3×3 segments |
| `"medium"` | 5×5 segments |
| `"large"` | 6×6 segments |

## Type: TileSet

Defines tiles from a texture atlas with animation and collision data.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `getFirstGid` | `getFirstGid()` | `int` | Get the starting global tile ID. |
| `getTileCount` | `getTileCount()` | `int` | Get the total number of tiles. |
| `getColumns` | `getColumns()` | `int` | Get the number of tile columns in the atlas. |
| `getTileWidth` | `getTileWidth()` | `int` | Get tile width in pixels. |
| `getTileHeight` | `getTileHeight()` | `int` | Get tile height in pixels. |
| `getTileDimensions` | `getTileDimensions()` | `int, int` | Get tile width and height in pixels. |
| `getSpacing` | `getSpacing()` | `int` | Get spacing between tiles in pixels. |
| `getMargin` | `getMargin()` | `int` | Get margin around the atlas in pixels. |
| `getQuad` | `getQuad(tileId)` | `Quad` | Get the `luna.graphics.Quad` for the 1-based local tile ID. |
| `setAnimation` | `setAnimation(tileId, frames)` | — | Set animation frames for a tile. `frames` is `{{tileid=id, duration=ms}, ...}` (1-based tile IDs). |
| `getAnimation` | `getAnimation(tileId)` | `table\|nil` | Get animation frames for a tile, or nil if none. Returns `{{tileid=id, duration=ms}, ...}`. |
| `setSolid` | `setSolid(tileId, solid)` | — | Mark a tile as solid (collidable) or not. |
| `isSolid` | `isSolid(tileId)` | `boolean` | Check if a tile is marked as solid. |
| `setAutoTileRule` | `setAutoTileRule(type, bitmask, tileId)` | — | Set an autotile rule: for type name and 4-bit cardinal bitmask (N=1,E=2,S=4,W=8), map to local tile ID (1-based). |
| `getAutoTileId` | `getAutoTileId(type, bitmask)` | `int\|nil` | Get the local tile ID for an autotile type + 4-bit bitmask, or nil if no rule. |
| `setAutoTileRule8` | `setAutoTileRule8(type, bitmask, tileId)` | — | Set an 8-directional autotile rule: for type name and 8-bit bitmask (N=1,E=2,S=4,W=8,NE=16,SE=32,SW=64,NW=128), map to local tile ID (1-based). |
| `getAutoTileId8` | `getAutoTileId8(type, bitmask)` | `int\|nil` | Get the local tile ID for an autotile type + 8-bit bitmask, or nil if no rule. |

## Type: TileMap

The main map container with layers, tiles, viewport, rendering, and collision.

### TileSet Management

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addTileSet` | `addTileSet(tileset)` | — | Register a TileSet with this map. |
| `getTileSet` | `getTileSet(index)` | `TileSet` | Get the TileSet at 1-based index. |
| `getTileSetCount` | `getTileSetCount()` | `int` | Get the number of registered TileSets. |

### Layer Management

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addLayer` | `addLayer(name, width, height)` | `int` | Add a layer with given name and tile dimensions. Returns 1-based layer index. |
| `getLayerCount` | `getLayerCount()` | `int` | Get the number of layers. |
| `getLayerName` | `getLayerName(layerIdx)` | `string` | Get the name of a layer (1-based index). |
| `setLayerVisible` | `setLayerVisible(layerIdx, visible)` | — | Set layer visibility. |
| `getLayerVisible` | `getLayerVisible(layerIdx)` | `boolean` | Get layer visibility. |
| `setLayerColor` | `setLayerColor(layerIdx, r, g, b [, a])` | — | Set layer tint color (0..1), alpha defaults to 1. |
| `getLayerColor` | `getLayerColor(layerIdx)` | `r, g, b, a` | Get layer tint color. |
| `setLayerOffset` | `setLayerOffset(layerIdx, ox, oy)` | — | Set per-layer pixel offset (for parallax or decoration layers). |
| `getLayerOffset` | `getLayerOffset(layerIdx)` | `ox, oy` | Get per-layer pixel offset. |
| `setLayerParallax` | `setLayerParallax(layerIdx, px, py)` | — | Set parallax scrolling factor (1.0 = normal, <1 = slower background). |
| `getLayerParallax` | `getLayerParallax(layerIdx)` | `px, py` | Get parallax scrolling factor. |

### Tile Access

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setTile` | `setTile(layerIdx, x, y, gid)` | — | Set the tile GID at position (all 1-based). |
| `getTile` | `getTile(layerIdx, x, y)` | `int` | Get the tile GID at position. |
| `setTileTint` | `setTileTint(layerIdx, x, y, r, g, b [, a])` | — | Set per-tile tint color. |
| `clearTile` | `clearTile(layerIdx, x, y)` | — | Remove the tile at position (sets GID to 0). |
| `fill` | `fill(layerIdx, gid)` | — | Fill an entire layer with a single GID. |

### Viewport & Rendering

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setViewport` | `setViewport(x, y, w, h)` | — | Set the visible viewport rectangle in world pixels. Only chunks overlapping this area are rendered. |
| `getViewport` | `getViewport()` | `x, y, w, h` | Get the current viewport rectangle. |
| `update` | `update(dt)` | — | Advance tile animations by `dt` seconds. |
| `drawLayer` | `drawLayer(layerIdx [, transform])` | — | Draw a single layer, respecting the viewport. Optional transform argument (same as `luna.graphics.draw`). |

### Coordinate Conversion

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `worldToTile` | `worldToTile(wx, wy)` | `tx, ty` | Convert world pixel position to 1-based tile coordinates. |
| `tileToWorld` | `tileToWorld(tx, ty)` | `wx, wy` | Convert 1-based tile coordinates to world pixel position. |

### Dimension Getters

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `getTileWidth` | `getTileWidth()` | `int` | Get tile pixel width of this map. |
| `getTileHeight` | `getTileHeight()` | `int` | Get tile pixel height of this map. |
| `getTileDimensions` | `getTileDimensions()` | `int, int` | Get tile pixel width and height. |
| `getChunkSize` | `getChunkSize()` | `int` | Get the chunk size in tiles (used for spatial partitioning). |

### Collision

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `isSolid` | `isSolid(layerIdx, tx, ty)` | `boolean` | Check if the tile at 1-based position is solid (via its TileSet solid flag). |
| `rectOverlapsSolid` | `rectOverlapsSolid(layerIdx, x, y, w, h)` | `boolean` | Check if a world-space rectangle overlaps any solid tiles on the given layer. |
| `sweepRect` | `sweepRect(layerIdx, x, y, w, h, dx, dy)` | `outX, outY, normalX, normalY, hitTileX, hitTileY` | Perform continuous AABB sweep along (dx,dy). Returns resolved position, surface normal, and hit tile coords (1-based). If no hit, returns `(x+dx, y+dy, 0, 0, nil, nil)`. |

### Autotile

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `applyAutoTile` | `applyAutoTile(layerIdx, type)` | — | Apply autotile rules across the entire layer for the given type, updating all non-empty tiles. |
| `applyAutoTileAt` | `applyAutoTileAt(layerIdx, x, y, type)` | — | Apply 4-bit autotile rules at a single 1-based tile position and its 3×3 neighborhood. |
| `applyAutoTile8` | `applyAutoTile8(layerIdx, type)` | — | Apply 8-directional autotile rules across the entire layer for the given type, using the 8-bit bitmask (including diagonals). |
| `applyAutoTile8At` | `applyAutoTile8At(layerIdx, x, y, type)` | — | Apply 8-directional autotile rules at a single 1-based tile position and its 3×3 neighborhood. |

## Type: AutoTileSheet

Pre-arranged autotile image with automatic tile extraction and bitmask rule generation. Supports standard autotile layouts from standard level design tools, a similar game engine, and a similar game engine.

**Created by:** `luna.tilemap.newAutoTileSheet(texture, tileW, tileH, layout)`

### Layout Formats

| Layout | Tiles | Grid | Description |
|--------|-------|------|-------------|
| `"blob47"` | 47 | varies | Full 47-tile blob set. Each tile maps to a unique 8-bit bitmask combination (after reduction). a similar game engine-compatible. |
| `"composite48"` | 48 | 6×8 | 48-tile quarter-tile composite format (6 columns × 8 rows). Auto-splits into sub-tiles. |
| `"minimal16"` | 16 | 4×4 | Minimal 16-tile set using 4-bit cardinal bitmask only (a similar game engine 3×3 minimal). |

### Methods

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `getLayout` | `getLayout()` | `string` | Get layout format name. |
| `getTileCount` | `getTileCount()` | `int` | Get total number of tiles extracted. |
| `getTileWidth` | `getTileWidth()` | `int` | Get tile width in pixels. |
| `getTileHeight` | `getTileHeight()` | `int` | Get tile height in pixels. |
| `applyToTileSet` | `applyToTileSet(tileset, type [, startGid])` | — | Apply this sheet's rules to a TileSet. Creates tiles starting at `startGid` (defaults to tileset's next available GID). Sets both 4-bit and 8-bit autotile rules for the given type. |
| `getBitmaskForTile` | `getBitmaskForTile(index)` | `int` | Get the 8-bit bitmask value for the tile at 1-based index. |
| `getTileForBitmask` | `getTileForBitmask(bitmask)` | `int` | Get the 1-based tile index for a given 8-bit bitmask. |
| `getQuad` | `getQuad(index)` | `Quad` | Get the texture Quad for tile at 1-based index. |

### 8-Bit Bitmask

The 8-directional bitmask extends the cardinal 4-bit mask with diagonals:

| Bit | Direction | Value |
|-----|-----------|-------|
| 0 | North | 1 |
| 1 | East | 2 |
| 2 | South | 4 |
| 3 | West | 8 |
| 4 | North-East | 16 |
| 5 | South-East | 32 |
| 6 | South-West | 64 |
| 7 | North-West | 128 |

**Note**: Diagonal bits are only meaningful when both adjacent cardinal neighbors are present. For example, the NE bit only affects the tile appearance when both N and E are also set. The 47-tile reduction handles this automatically.

---

## Type: MapBlock

A prefab rectangular grid of tiles used as building blocks for procedural generation. Each edge is divided into segments for side-matching constraints.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setTile` | `setTile(layer, x, y, gid)` | — | Set a tile GID in this block (all 1-based). |
| `getTile` | `getTile(layer, x, y)` | `int` | Get a tile GID from this block. |
| `setSide` | `setSide(edge, segment, sideId)` | — | Set the side connection ID for an edge segment. `edge` is `"north"`, `"east"`, `"south"`, or `"west"`. `segment` is 1-based. |
| `getSide` | `getSide(edge, segment)` | `int` | Get the side connection ID for an edge segment. |
| `getWidth` | `getWidth()` | `int` | Get width in tiles. |
| `getHeight` | `getHeight()` | `int` | Get height in tiles. |
| `getDimensions` | `getDimensions()` | `int, int` | Get width and height in tiles. |
| `getLayerCount` | `getLayerCount()` | `int` | Get number of tile layers. |
| `getSegmentSize` | `getSegmentSize()` | `int` | Get tiles per segment. |
| `getWidthInSegments` | `getWidthInSegments()` | `int` | Get width measured in segments. |
| `getHeightInSegments` | `getHeightInSegments()` | `int` | Get height measured in segments. |
| `getSegmentCount` | `getSegmentCount(edge)` | `int` | Get the number of segments on the given edge (`"north"`/`"east"`/`"south"`/`"west"`). |
| `setName` | `setName(name)` | — | Set the block's name. |
| `getName` | `getName()` | `string` | Get the block's name. |
| `setWeight` | `setWeight(weight)` | — | Set the placement weight for procedural selection. |
| `getWeight` | `getWeight()` | `number` | Get the placement weight. |

### Edge Enum

| Value | Description |
|-------|-------------|
| `"north"` | Top edge |
| `"east"` | Right edge |
| `"south"` | Bottom edge |
| `"west"` | Left edge |

## Type: MapGroup

A named container holding MapBlocks and MapScripts for a biome/terrain type.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addBlock` | `addBlock(block)` | — | Add a MapBlock to this group. |
| `getBlock` | `getBlock(index)` | `MapBlock\|nil` | Get the MapBlock at 1-based index, or nil. |
| `getBlockCount` | `getBlockCount()` | `int` | Get the number of blocks. |
| `removeBlock` | `removeBlock(index)` | — | Remove the MapBlock at 1-based index. |
| `addScript` | `addScript(script)` | — | Add a MapScript to this group. |
| `getScript` | `getScript(index)` | `MapScript\|nil` | Get the MapScript at 1-based index, or nil. |
| `getScriptCount` | `getScriptCount()` | `int` | Get the number of scripts. |
| `getName` | `getName()` | `string` | Get the group's name. |
| `setName` | `setName(name)` | — | Set the group's name. |

## Type: MapScript

An ordered list of generation steps that control how MapBlocks are placed on the segment grid.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addStep` | `addStep(stepTable)` | — | Append a step described by a table (see ScriptStep fields below). |
| `getStep` | `getStep(index)` | `table\|nil` | Get a step at 1-based index as a table, or nil. |
| `getStepCount` | `getStepCount()` | `int` | Get the number of steps. |
| `removeStep` | `removeStep(index)` | — | Remove the step at 1-based index. |
| `clearSteps` | `clearSteps()` | — | Remove all steps. |
| `setName` | `setName(name)` | — | Set the script's name. |
| `getName` | `getName()` | `string` | Get the script's name. |

### ScriptStep Table Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | `string` | `"fillRandom"` | Step type (see StepType enum below). |
| `groupIndex` | `int` | -1 | Sub-group index to pick blocks from (-1 = all). |
| `blockIndex` | `int` | -1 | Specific block index to place (-1 = random). 1-based. |
| `x` | `int` | 1 | Grid X position in segments (1-based). |
| `y` | `int` | 1 | Grid Y position in segments (1-based). |
| `width` | `int` | 0 | Area width in segments (for `fillArea`). |
| `height` | `int` | 0 | Area height in segments (for `fillArea`). |
| `count` | `int` | 1 | Number of blocks to place (for `placeRandom`). |
| `rotation` | `int` | 0 | Fixed rotation 0-3 (0°/90°/180°/270° CW). |
| `mirror` | `boolean` | false | Horizontal mirror. |
| `randomRotation` | `boolean` | false | Randomize rotation per placement. |
| `randomMirror` | `boolean` | false | Randomize mirror per placement. |
| `direction` | `int` | 0 | Line direction: 0 = horizontal, 1 = vertical. |
| `matchSides` | `boolean` | true | Enforce side-connection matching. |
| `conditionStep` | `int` | -1 | 1-based index of a prior step; -1 = unconditional. |
| `conditionSuccess` | `boolean` | true | Run only if conditionStep succeeded (true) or failed (false). |
| `chance` | `number` | 1.0 | Random execution probability (0.0–1.0). |
| `repeatCount` | `int` | 1 | Repeat this step N times. |
| `minCount` | `int` | -1 | Only run if at least this many blocks from groupIndex are placed (-1 = ignore). |
| `maxCount` | `int` | -1 | Only run if at most this many blocks from groupIndex are placed (-1 = ignore). |
| `sizeFilterW` | `int` | -1 | Only pick blocks with this width in segments (-1 = any). |
| `sizeFilterH` | `int` | -1 | Only pick blocks with this height in segments (-1 = any). |
| `tileId` | `int` | 1 | Tile GID for `drawPath`/`fillRect` steps. |
| `pathWidth` | `int` | 1 | Path width in tiles for `drawPath`. |
| `tileLayer` | `int` | 1 | Target layer for tile writes (1-based). |
| `zoneStartY` | `int` | -1 | Restrict placement to rows >= this (1-based, -1 = ignore). |
| `zoneEndY` | `int` | -1 | Restrict placement to rows < this (1-based, -1 = ignore). |

### StepType Enum

| Value | Description |
|-------|-------------|
| `"fillRandom"` | Fill all empty grid cells with random blocks from the group. |
| `"placeBlock"` | Place a specific block at a specific grid position. |
| `"placeRandom"` | Place N random blocks at random empty positions. |
| `"placeLine"` | Place blocks in a line across the grid (roads, corridors). |
| `"floodFill"` | Fill remaining empty cells respecting side constraints. |
| `"fillArea"` | Fill a rectangular area with blocks. |
| `"drawPath"` | Draw a tile-by-tile path (corridors, roads) — writes tiles, not blocks. |
| `"fillRect"` | Fill a rectangle with a specific tile value — writes tiles, not blocks. |

## Type: MapGen

The procedural generation engine. Takes a MapGroup and grid dimensions, runs MapScript steps to populate a segment grid, and expands to a final TileMap.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `generate` | `generate([scriptIndex [, seed]])` | `TileMap` | Generate a TileMap. `scriptIndex` is 1-based (-1 or 0 = random script). `seed` 0 = random device. |
| `generateWorld` | `generateWorld(columns, rows [, scriptIndex [, seed]])` | `TileMap` | Generate a large world by tiling regions in a columns×rows grid. |
| `getGridWidth` | `getGridWidth()` | `int` | Get segment grid width. |
| `getGridHeight` | `getGridHeight()` | `int` | Get segment grid height. |
| `getGridDimensions` | `getGridDimensions()` | `int, int` | Get segment grid width and height. |
| `getSegmentSize` | `getSegmentSize()` | `int` | Get tiles per segment. |
| `setTileSize` | `setTileSize(w, h)` | — | Set tile pixel dimensions for the output TileMap. |
| `getTilePixelWidth` | `getTilePixelWidth()` | `int` | Get tile pixel width. |
| `getTilePixelHeight` | `getTilePixelHeight()` | `int` | Get tile pixel height. |
| `getPlacementCount` | `getPlacementCount()` | `int` | Get the number of block placements from the last generation. |
| `setOrientation` | `setOrientation(orientation)` | — | Set map orientation (`"topDown"` or `"sideView"`). |
| `getOrientation` | `getOrientation()` | `string` | Get current map orientation. |
| `addZone` | `addZone(name, startRow, height)` | — | Add a named horizontal zone. `startRow` is 1-based. |
| `getZoneCount` | `getZoneCount()` | `int` | Get the number of defined zones. |
| `getZone` | `getZone(index)` | `table` | Get zone at 1-based index as `{name, startRow, height}` (startRow is 1-based). |
| `clearZones` | `clearZones()` | — | Remove all zones. |
| `setLayerMode` | `setLayerMode(mode)` | — | Set layer handling mode (`"unified"` or `"independent"`). |
| `getLayerMode` | `getLayerMode()` | `string` | Get current layer mode. |

### MapOrientation Enum

| Value | Description |
|-------|-------------|
| `"topDown"` | Default overhead view. |
| `"sideView"` | Side-scrolling with gravity (sky at top, underground at bottom). |

### LayerMode Enum

| Value | Description |
|-------|-------------|
| `"unified"` | All layers from a placed block go into the output (default). |
| `"independent"` | Each layer picks blocks independently via shuffled assignments. |

## Usage Examples

### Basic TileMap

```lua
local tileset = luna.tilemap.newTileSet(texture, 1, 256, 16, 16, 16)
local map = luna.tilemap.newTileMap(16, 16)
map:addTileSet(tileset)

local layerIdx = map:addLayer("ground", 50, 50)
map:fill(layerIdx, 1)  -- fill with tile GID 1
map:setTile(layerIdx, 5, 5, 10)

map:setViewport(0, 0, 800, 600)

function luna.update(dt)
    map:update(dt)  -- advance tile animations
end

function luna.draw()
    map:drawLayer(1)
end
```

### Autotile

```lua
-- Define autotile rules on the tileset
for bitmask = 0, 15 do
    tileset:setAutoTileRule("wall", bitmask, wallTileIds[bitmask])
end

-- Place some wall tiles, then apply autotiling
map:setTile(1, 3, 3, wallGid)
map:setTile(1, 3, 4, wallGid)
map:setTile(1, 4, 3, wallGid)
map:applyAutoTile(1, "wall")  -- updates all wall tiles on layer 1
```

### Swept Collision

```lua
local outX, outY, nx, ny, hitTX, hitTY = map:sweepRect(1, px, py, pw, ph, dx, dy)
if hitTX then
    -- collision occurred; outX/outY is the resolved position, nx/ny is the contact normal
    player.x, player.y = outX, outY
else
    player.x, player.y = outX, outY  -- no collision, full movement applied
end
```

### Procedural Generation (X-COM Style)

```lua
-- Create blocks
local block = luna.tilemap.newMapBlock(10, 10, 2, 10) -- 10x10 tiles, 2 layers, 10 tiles/seg
block:setName("room_a")
block:setWeight(1.5)
block:setSide("north", 1, 1)  -- connect type 1 on north segment 1
block:setSide("south", 1, 1)  -- matching south

-- Group them
local group = luna.tilemap.newMapGroup("dungeon")
group:addBlock(block)

-- Create generation script
local script = luna.tilemap.newMapScript()
script:addStep({ type = "placeRandom", count = 5, randomRotation = true })
script:addStep({ type = "floodFill", matchSides = true })
group:addScript(script)

-- Generate
local gen = luna.tilemap.newMapGen(group, "medium", 10) -- medium=5x5 grid, 10 tiles/seg
gen:setTileSize(16, 16)
gen:setOrientation("topDown")
local map = gen:generate(1, 42) -- script 1, seed 42
```

### Hexagonal Coordinates

```lua
local sx, sy = luna.tilemap.toScreenHex(q, r, 32)  -- hex size 32px
local q, r = luna.tilemap.fromScreenHex(mouseX, mouseY, 32)
local neighbors = luna.tilemap.hexNeighbors(q, r)  -- 6 adjacent cells
local dist = luna.tilemap.hexDistance(q1, r1, q2, r2)
```

### Isometric Coordinates

```lua
local sx, sy = luna.tilemap.toScreenIso(tileX, tileY, 64, 32)
local tx, ty = luna.tilemap.fromScreenIso(screenX, screenY, 64, 32)
```

### Isometric Character Direction

```lua
-- Track character facing direction (1-4)
local facing = 1  -- 1=south, 2=west, 3=north, 4=east

-- Rotate based on input
if luna.keyboard.isDown("q") then
    facing = luna.tilemap.isoRotate(facing, -1)  -- rotate left 90°
end
if luna.keyboard.isDown("e") then
    facing = luna.tilemap.isoRotate(facing, 1)   -- rotate right 90°
end

-- Get sprite row/column from direction
local dirName = luna.tilemap.isoDirectionName(facing)  -- "south", "west", etc.
print("Facing: " .. dirName)

-- Snap movement angle to iso direction
local moveAngle = math.atan2(dy, dx)
local moveDir = luna.tilemap.isoDirectionFromAngle(moveAngle)
```

### 8-Directional AutoTile (47-Tile Blob Set)

```lua
-- Load a 47-tile autotile image
local autoSheet = luna.tilemap.newAutoTileSheet(autotileTexture, 16, 16, "blob47")

-- Apply to a tileset (creates tiles + rules automatically)
autoSheet:applyToTileSet(tileset, "terrain")

-- Place terrain tiles on the map
for x = 3, 8 do
    for y = 3, 8 do
        map:setTile(1, x, y, terrainGid)
    end
end

-- Apply 8-directional autotiling — edges AND corners handled
map:applyAutoTile8(1, "terrain")
```

### Hex Line, Ring, and Spiral

```lua
-- Draw a line of hex cells between two points
local line = luna.tilemap.hexLine(0, 0, 5, -3)
for _, cell in ipairs(line) do
    highlightHex(cell[1], cell[2])
end

-- Get a ring of cells at distance 3
local ring = luna.tilemap.hexRing(centerQ, centerR, 3)

-- Get all cells in a spiral outward (for area effects)
local area = luna.tilemap.hexSpiral(centerQ, centerR, 5)

-- Get filled circle area
local blast = luna.tilemap.hexArea(targetQ, targetR, 2)

-- Rotate a hex position around a center
local newQ, newR = luna.tilemap.hexRotate(q, r, centerQ, centerR, 1)  -- 60° CW

-- Reflect across an axis
local mirQ, mirR = luna.tilemap.hexReflect(q, r, centerQ, centerR, "q")
```

---

## Extension Integration

The **Map Editor** panel (`luna2d.editor.mapEditor`) provides a tile-based map painting tool with multi-layer support.

### Editor Features

- **16 tile types**: Empty, Grass, Water, Sand, Stone, Wall, Road, Forest, Mountain, Lava, Ice, Bridge, Spawn (🟠), Goal (🟡), Trap (🔴), Chest (🟡)
- **5 drawing tools**: Paint 🖌️, Erase 🧹, Fill 🩣, Pick 💉, Rectangle ⬜
- Multi-layer support with dynamic layer creation and per-layer visibility
- Configurable map size (4–200 × 4–200 tiles) and tile size (8–64px)
- Grid toggle and all-layers preview mode
- Status bar: mouse position, current tile, active layer
- Export to **Lua** and **TOML** formats

### Export Format (Lua)

```lua
-- Generated by Luna2D Extension Map Editor
return {
    width = 20,
    height = 15,
    tiles = {
        [1] = "Grass",
        [2] = "Water",
        [3] = "Stone",
        [4] = "Wall",
    },
    layers = {
        ground = {
            { 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            { 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            -- ... rows
        },
        buildings = {
            { 0, 0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            -- ... rows
        },
    },
}
```

### Export Format (TOML)

```toml
[map]
width = 20
height = 15

[map.tiles]
1 = "Grass"
2 = "Water"
3 = "Stone"
4 = "Wall"

[map.layers.ground]
data = [
    [1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

[map.layers.buildings]
data = [
    [0, 0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]
```

---

## Game Design Role

- **Level layout**: Define worlds, dungeons, and platformer terrain as tile grids.
- **Efficient rendering**: SpriteBatch-based rendering for large maps with minimal draw calls.
- **Animated tiles**: Frame sequences for water, lava, conveyor belts.
- **Collision metadata**: Tag tiles as solid, one-way, hazard, etc. → build collision geometry from metadata.
- **Multiple layers**: Background, terrain, foreground layers for parallax depth.

---

## Module Boundaries

**vs luna.physics** — Tilemap stores the grid and tile data. Physics resolves collisions. Build chain shapes from solid tiles. Tilemap says *which tiles are solid*; physics says *how objects bounce off them*.

**vs luna.graphics (SpriteBatch)** — Graphics provides SpriteBatch as a low-level primitive. Tilemap uses SpriteBatch internally for efficient rendering. Tilemap adds grid logic on top.

**vs luna.math (PathGrid)** — Math’s PathGrid is for A* pathfinding on a grid. Tilemap stores visual tile data. They can share the same grid dimensions — PathGrid reads Tilemap solid metadata.

**vs luna.entity** — Entity manages game objects. Tilemap manages static terrain. A tilemap can be owned by a scene; entities move on top of it.

**vs luna.scene** — Scene manages screen states. A TileMap belongs to a gameplay scene as its level geometry.

**vs luna.decal** — Decal places temporary visual marks (stains, impacts) over the tilemap surface. Tilemap owns permanent static tile data; decal manages transient overlays.

**vs luna.platformer** — Platformer’s CollisionWorld can be built from tilemap solid metadata. Tilemap says which cells are solid; platformer sweeps its AABB against those cells each frame.

---

## Edge Cases & Pitfalls

- **Tile ID 0 is empty**: By default, tile GID 0 means “no tile”. If your tileset uses 0-based tile indices, offset by 1 when storing in TileMap to avoid the empty-tile sentinel.
- **SpriteBatch rebuild cost**: Modifying tiles triggers chunk dirty flags. For large maps (256×256+), batch modifications before the next `drawLayer` call — don’t rebuild per tile write.
- **Layer rendering order**: Layers render in `addLayer()` order. If you add a new layer after construction, it renders on top of all existing layers regardless of its semantic meaning (foreground vs background).
- **PathGrid synchronization**: `luna.math.PathGrid` and the TileMap `isSolid()` metadata are not automatically linked. When you change a tile’s solid flag, you must also call `pathGrid:setWalkable(x, y, passable)` to keep pathfinding consistent.
- **Animated tile clock drift**: Animated tiles advance by `dt` each frame. If the game pauses (dt = 0), tiles freeze as expected. But `luna.timer.sleep()` in non-update code does not advance tile animations — animations are driven by explicit `update(dt)` calls only.

---

## Collision Bridge

> **How tilemap integrates with physics sub-systems** — the tilemap stores which tiles are solid; other modules consume that data to build collision geometry.

### With KinematicBody (Platformer Controller)

`luna.physics.newCollisionWorld` can be populated directly from tilemap solid tiles:

```lua
local cw = luna.physics.newCollisionWorld()
for row = 1, map:getLayerCount() > 0 and 1 or 0 do
    for ty = 1, 50 do
        for tx = 1, 50 do
            if map:isSolid(1, tx, ty) then
                local wx, wy = map:tileToWorld(tx, ty)
                cw:addRect(wx, wy, map:getTileWidth(), map:getTileHeight())
            end
        end
    end
end
```

### With physics simulation libraries Physics (Chain Shapes)

For physics simulation libraries, convert tilemap solids into `RectangleShape` fixtures on a static body:

```lua
local world = luna.physics.newWorld(0, 400)
local groundBody = luna.physics.newBody(world, 0, 0, "static")

for ty = 1, 50 do
    for tx = 1, 50 do
        if map:isSolid(1, tx, ty) then
            local wx, wy = map:tileToWorld(tx, ty)
            local tw, th = map:getTileDimensions()
            local shape = luna.physics.newRectangleShape(wx + tw/2, wy + th/2, tw, th)
            luna.physics.newFixture(groundBody, shape)
        end
    end
end
```

> For large levels, batch adjacent solid tiles into merged edge chains using a contour-tracing algorithm to reduce fixture count.

### Tile Metadata for Game Logic

Custom per-tile properties can be stored via the TileSet and queried during gameplay:

```lua
-- Read tile properties to trigger game logic
local gid = map:getTile(1, tx, ty)
if gid > 0 then
    -- Use GID to determine tile behaviour from a game-defined lookup table
    local tileInfo = myTileProperties[gid]
    if tileInfo and tileInfo.type == "coin" then collectCoin(tx, ty) end
    if tileInfo and tileInfo.type == "hazard" then damagePlayer(tileInfo.damage) end
end
```
