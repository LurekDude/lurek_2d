# Luna2D Audio API Reference

## luna.audio.create_bus(name)
Creates a new audio bus for applying shared volume, pitch, and effects to a group of sources.
- **Parameters**:
ame (string)
- **Returns**: None

## luna.audio.add_effect(bus_name, effect_id, effect_type)
Adds a real-time DSP effect to the specified bus.
- **Parameters**:
  - us_name (string): The bus to apply the effect to.
  - effect_id (number): A unique identifier for this effect instance.
  - effect_type (string): The type of effect (e.g., "Lowpass", "Reverb").
- **Returns**: None

## luna.audio.remove_effect(bus_name, effect_id)
Removes an effect from the specified bus.
- **Parameters**:
  - us_name (string)
  - effect_id (number)
- **Returns**: None

## luna.audio.set_effect_param(bus_name, effect_id, param_index, value)
Updates a parameter of an active DSP effect.
- **Parameters**:
  - us_name (string)
  - effect_id (number)
  - param_index (number)
  - alue (number)
- **Returns**: None

## luna.audio.play(sound_name, [options])
Plays a sound.
- **Options**:
  - us: (string) The name of the bus to route this sound through.
  - olume, pitch, loop, ade_in.
---

## luna.postfx — ImageEffect API

`ImageEffect` chains one or more built-in shader passes and applies them to a
single drawable at draw time. Unlike `PostFxStack` (which captures a
full-screen render pass), `ImageEffect` is attached directly to individual
`luna.graphics.draw` calls via the `effect` key of the options-table overload.

### Factory Functions

#### luna.postfx.newImageEffect()

Creates an empty `ImageEffect` chain with no passes.

- **Returns**: `ImageEffect`

#### luna.postfx.newImageEffect(effect_name)

Creates an `ImageEffect` pre-loaded with a single built-in effect.

- **Parameters**:
  - `effect_name` (string): One of `"blur"`, `"vignette"`, `"bloom"`,
    `"crt"`, `"godrays"`, `"colourgrade"`, `"chromatic"`, `"pixelate"`,
    `"sepia"`, `"grayscale"`, `"invert"`, `"scanlines"`, `"edgedetect"`,
    `"hueshift"`, `"noise"`.
- **Returns**: `ImageEffect`

#### luna.postfx.newImageEffect(effect_name, params)

Creates an `ImageEffect` with a single built-in effect and initial float
parameters.

- **Parameters**:
  - `effect_name` (string): Built-in effect name.
  - `params` (table): Key-value pairs of `string → number` parameter overrides.
- **Returns**: `ImageEffect`

#### luna.postfx.newImageEffect(chain_table)

Creates an `ImageEffect` from a structured chain table. Each entry must be a
table with a `type` string key and an optional `params` sub-table.

```lua
local fx = luna.postfx.newImageEffect({
  { type = "blur",     params = { radius = 3 } },
  { type = "vignette", params = { strength = 0.6 } },
})
```

- **Parameters**:
  - `chain_table` (table): Array of `{ type = string, params = table? }` entries.
- **Returns**: `ImageEffect`

#### luna.postfx.loadImageEffect(path)

Loads an `ImageEffect` chain from a TOML preset file.

The TOML file must have a `name` string key and an `[[effects]]` array where
each entry has `type` (string), `enabled` (boolean), and optional float
parameter keys.

- **Parameters**:
  - `path` (string): Path to the `.toml` preset file.
- **Returns**: `ImageEffect`

---

### ImageEffect Methods

#### fx:addEffect(effect_name) → PostFxEffect

Appends a built-in effect to the end of the chain and returns it.

- **Parameters**:
  - `effect_name` (string): Built-in effect name.
- **Returns**: `PostFxEffect` — the new effect (configure with `setParameter`).

#### fx:getEffect(index_or_name) → PostFxEffect | nil

Returns the effect at a 1-based index or matching the given type name.

- **Parameters**:
  - `index_or_name` (integer | string): 1-based position or effect type name.
- **Returns**: `PostFxEffect | nil`

#### fx:effectCount() → integer

Returns the number of effects currently in the chain.

- **Returns**: `integer`

#### fx:removeEffect(index_or_name) → boolean

Removes the effect at a 1-based index or matching the given type name.

- **Parameters**:
  - `index_or_name` (integer | string): 1-based position or effect type name.

---

## luna.tilemap — Tile Map API

Full design reference: [`docs/API/tilemap-design.md`](API/tilemap-design.md)

### Factory Functions

#### luna.tilemap.newTileSet(firstGid, tileCount, columns, tileW, tileH [, spacing [, margin]]) → TileSet

Creates a TileSet for atlas-based tile lookup. No texture is required (pure metadata).

- `firstGid` — integer: first global tile ID in this set (1-based).
- `tileCount` — integer: total number of tiles.
- `columns` — integer: number of tile columns in the atlas.
- `tileW`, `tileH` — integer: pixel dimensions of each tile.
- `spacing` — optional integer (default 0): pixels between tiles.
- `margin` — optional integer (default 0): outer border pixels.

#### luna.tilemap.newTileMap(tileW, tileH [, chunkSize]) → TileMap

Creates a TileMap. Layers are added with `addLayer`.

- `tileW`, `tileH` — integer: pixel dimensions of one tile.
- `chunkSize` — optional integer (default 16): chunk dimension in tiles.

#### luna.tilemap.newAutoTileSheet(tileW, tileH, layout) → AutoTileSheet

Creates an autotile rule set. `layout` must be `"blob47"`, `"composite48"`, or `"minimal16"`.

#### luna.tilemap.newChunkMap([chunkSize]) → ChunkMap

Creates a sparse, infinite-extent tile map backed by chunks.

#### luna.tilemap.newIsoMap(width, height, tileW, tileH, levelHeight) → IsoMap

Creates an isometric map. Levels are added with `addLevel()`.

#### luna.tilemap.newMapBlock(width, height, layers, segmentSize) → MapBlock

Creates a fixed-size map block used in procedural generation.

#### luna.tilemap.newMapGroup(name) → MapGroup

Creates a named MapGroup that holds blocks and scripts for map generation.

#### luna.tilemap.newMapScript([name]) → MapScript

Creates a MapScript (list of generation steps executed by MapGen).

#### luna.tilemap.newMapGen(group, sizeOrW, hOrSeg [, segSize]) → MapGen

Creates a map generator. `sizeOrW` may be `"small"`, `"medium"`, or `"large"`, or a numeric width.

#### luna.tilemap.loadTMX(xmlString) → table

Parses a Tiled TMX XML string and returns a Lua table with fields:
`width`, `height`, `tileWidth`, `tileHeight`, `orientation`, `renderOrder`, `layers`, `tilesets`.
Throws a Lua error on parse failure.

---

### IsoMap Tile-Part Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `luna.tilemap.FLOOR` | 1 | Floor tile part |
| `luna.tilemap.NORTH_WALL` | 2 | North wall part |
| `luna.tilemap.WEST_WALL` | 3 | West wall part |
| `luna.tilemap.OBJECT` | 4 | Object part |

---

### Coordinate Helper Functions

#### Isometric

- `luna.tilemap.toScreenIso(tx, ty, tileW, tileH)` → `sx, sy`
- `luna.tilemap.fromScreenIso(sx, sy, tileW, tileH)` → `tx, ty`
- `luna.tilemap.isoRotate(direction, steps)` → `direction` (1–4, wraps)
- `luna.tilemap.isoDirectionName(direction)` → `"south"|"west"|"north"|"east"`
- `luna.tilemap.isoDirectionFromAngle(radians)` → `direction` (1–4)

#### Hexagonal

- `luna.tilemap.toScreenHex(q, r, size)` → `sx, sy`
- `luna.tilemap.fromScreenHex(sx, sy, size)` → `q, r`
- `luna.tilemap.hexDistance(q1, r1, q2, r2)` → `integer`
- `luna.tilemap.hexRound(q, r)` → `q, r`
- `luna.tilemap.hexNeighbors(q, r)` → `{ {q, r}, … }` (6 entries)
- `luna.tilemap.hexLine(q1, r1, q2, r2)` → `{ {q, r}, … }`
- `luna.tilemap.hexRing(q, r, radius)` → `{ {q, r}, … }`
- `luna.tilemap.hexSpiral(q, r, radius)` → `{ {q, r}, … }`
- `luna.tilemap.hexArea(q, r, radius)` → `{ {q, r}, … }`
- `luna.tilemap.hexRotate(q, r, cq, cr, steps)` → `q, r`
- `luna.tilemap.hexReflect(q, r, cq, cr, axis)` → `q, r` (`axis`: `"q"|"r"|"s"`)

---

### TileSet Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `ts:getFirstGid()` | integer | First GID of this set |
| `ts:getTileCount()` | integer | Total tile count |
| `ts:getColumns()` | integer | Column count |
| `ts:getTileWidth()` | integer | Tile pixel width |
| `ts:getTileHeight()` | integer | Tile pixel height |
| `ts:getTileDimensions()` | w, h | Width and height |
| `ts:getSpacing()` | integer | Inter-tile spacing |
| `ts:getMargin()` | integer | Atlas border margin |
| `ts:getQuad(tileId)` | `{x,y,width,height}` | Atlas rect for tile (1-based) |
| `ts:setSolid(tileId, bool)` | — | Mark tile as solid |
| `ts:isSolid(tileId)` | boolean | Solid collision flag |
| `ts:setAnimation(tileId, frames)` | — | Assign animation frames `{tileid, duration}` |
| `ts:getAnimation(tileId)` | frames or nil | Get animation frames |
| `ts:setAutoTileRule(type, bitmask4, tileId)` | — | 4-bit autotile rule |
| `ts:getAutoTileId(type, bitmask4)` | integer or nil | Lookup 4-bit autotile |
| `ts:setAutoTileRule8(type, bitmask8, tileId)` | — | 8-bit autotile rule |
| `ts:getAutoTileId8(type, bitmask8)` | integer or nil | Lookup 8-bit autotile |

---

### TileMap Methods

**Layers**

| Method | Returns | Description |
|--------|---------|-------------|
| `tm:addLayer(name, w, h)` | index | Add named layer (1-based index) |
| `tm:getLayerCount()` | integer | Number of layers |
| `tm:getLayerName(index)` | string | Layer name |
| `tm:setLayerVisible(index, bool)` | — | Layer visibility |
| `tm:getLayerVisible(index)` | boolean | Layer visibility |
| `tm:setLayerColor(index, r, g, b, a)` | — | Layer tint colour |
| `tm:getLayerColor(index)` | r, g, b, a | Layer tint colour |
| `tm:setLayerOffset(index, ox, oy)` | — | Layer pixel offset |
| `tm:getLayerOffset(index)` | ox, oy | Layer pixel offset |
| `tm:setLayerParallax(index, px, py)` | — | Layer parallax factor |
| `tm:getLayerParallax(index)` | px, py | Layer parallax factor |

**TileSets**

| Method | Returns | Description |
|--------|---------|-------------|
| `tm:addTileSet(ts)` | — | Register a TileSet |
| `tm:getTileSetCount()` | integer | Number of registered TileSets |
| `tm:getTileSet(index)` | TileSet or nil | Get TileSet by 1-based index |

**Tile Access**

| Method | Returns | Description |
|--------|---------|-------------|
| `tm:setTile(layer, x, y, gid)` | — | Set tile GID |
| `tm:getTile(layer, x, y)` | integer | Get tile GID (0 = empty) |
| `tm:clearTile(layer, x, y)` | — | Set tile to 0 |
| `tm:fill(layer, gid)` | — | Fill entire layer |
| `tm:setTileTint(layer, x, y, r, g, b, a)` | — | Per-tile tint override |

**Viewport and Coordinates**

| Method | Returns | Description |
|--------|---------|-------------|
| `tm:setViewport(x, y, w, h)` | — | Set visible world rect |
| `tm:getViewport()` | x, y, w, h | Current viewport |
| `tm:worldToTile(wx, wy)` | tx, ty | World → tile coordinates |
| `tm:tileToWorld(tx, ty)` | wx, wy | Tile → world coordinates |
| `tm:update(dt)` | — | Advance tile animations |

**Collision**

| Method | Returns | Description |
|--------|---------|-------------|
| `tm:isSolid(layer, x, y)` | boolean | True if tile at (x,y) is solid |
| `tm:rectOverlapsSolid(layer, wx, wy, w, h)` | boolean | AABB vs solid tiles |
| `tm:sweepRect(layer, wx, wy, w, h, dx, dy)` | ox, oy, nx, ny, hx, hy | Swept AABB collision |

**Autotile**

| Method | Description |
|--------|-------------|
| `tm:applyAutoTile(layer, type)` | Apply 4-bit autotile rules to whole layer |
| `tm:applyAutoTileAt(layer, x, y, type)` | Apply 4-bit autotile at one cell |
| `tm:applyAutoTile8(layer, type)` | Apply 8-bit autotile rules to whole layer |
| `tm:applyAutoTile8At(layer, x, y, type)` | Apply 8-bit autotile at one cell |

---

### ChunkMap Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `cm:getTile(x, y)` | integer | Get GID (infinite coords, 0-based) |
| `cm:setTile(x, y, gid)` | — | Set GID |
| `cm:clearTile(x, y)` | — | Reset to 0 |
| `cm:fillRect(x0, y0, x1, y1, gid)` | — | Fill a rectangular region |
| `cm:getChunkSize()` | integer | Chunk dimension |

---

### AutoTileSheet Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `sheet:getLayout()` | string | Layout name |
| `sheet:getTileCount()` | integer | Tile count for this layout |
| `sheet:getTileWidth()` | integer | Tile pixel width |
| `sheet:getTileHeight()` | integer | Tile pixel height |
| `sheet:getBitmaskForTile(index)` | integer | Bitmask for tile index |
| `sheet:getTileForBitmask(mask)` | integer | Tile index for bitmask |
| `sheet:applyToTileSet(ts, type)` | — | Register autotile rules on a TileSet |

---

### MapGen Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `gen:generate([scriptIndex [, seed]])` | TileMap | Run generation and return result |
- **Returns**: `boolean` — `true` if a matching effect was found and removed.

#### fx:clearEffects()

Removes all effects from the chain.

#### fx:clone() → ImageEffect

Returns a deep clone of this `ImageEffect`. The returned chain shares no state
with the original.

- **Returns**: `ImageEffect`

#### fx:save(path)

Serialises this effect chain to a TOML preset file (readable by
`luna.postfx.loadImageEffect`).

- **Parameters**:
  - `path` (string): Destination file path.

---

### Using ImageEffect with luna.graphics.draw

The `effect` key in the options-table overload of `luna.graphics.draw` accepts
an `ImageEffect`. Effects are applied at draw time to that image only.

```lua
local fx = luna.postfx.newImageEffect("blur", { radius = 4 })

function luna.draw()
  luna.graphics.draw(myImage, {
    x = 100, y = 200,
    sx = 2,  sy = 2,
    effect = fx,
  })
end
```

The `effect` field is supported only with the options-table overload, not the
positional-argument form (`luna.graphics.draw(img, x, y)`).

**Options-table fields for `luna.graphics.draw`:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `x` | number | `0` | Destination X position |
| `y` | number | `0` | Destination Y position |
| `r` | number | `0` | Rotation in radians |
| `sx` | number | `1` | X scale factor |
| `sy` | number | `sx` | Y scale factor (defaults to `sx`) |
| `ox` | number | `0` | X origin offset |
| `oy` | number | `0` | Y origin offset |
| `effect` | ImageEffect | `nil` | Per-image shader effect chain |