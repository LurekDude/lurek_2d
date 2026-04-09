# Tilemap World

Load tilemaps, render layers, tile-based collision, auto-tiling, camera bounds, and trigger zones.

## Key Concepts

- **Tilemap data**: 2D array of tile IDs. Store in TOML or Lua table.
- **Tileset atlas**: Single image with uniform tile grid. Compute quad from tile ID.
- **Layers**: Render ground → objects → foreground. Collision uses a separate data layer.
- **Auto-tiling**: Choose tile variant based on neighbor occupancy (bitmask).
- **Trigger zones**: Special tile IDs that fire events (door, spike, checkpoint).

## Tilemap Structure (TOML)

```toml
[map]
width = 20
height = 15
tile_size = 16

[[layers]]
name = "ground"
data = [1,1,1,2,2,2,1,1,...]

[[layers]]
name = "collision"
data = [0,0,0,1,1,1,0,0,...]
```

## Loading a Tilemap

```lua
local map = {}

local function load_map(path)
    local content = luna.fs.read(path)
    local data = luna.data.decodeToml(content)
    map.width = data.map.width
    map.height = data.map.height
    map.tile_size = data.map.tile_size
    map.layers = {}
    for _, layer in ipairs(data.layers) do
        map.layers[layer.name] = layer.data
    end
    map.tileset = luna.gfx.newImage("tileset.png")
end
```

## Tile Quad Lookup

```lua
local function get_tile_quad(tile_id, tileset_w)
    local ts = map.tile_size
    local cols = math.floor(tileset_w / ts)
    local col = (tile_id - 1) % cols
    local row = math.floor((tile_id - 1) / cols)
    return luna.gfx.newQuad(col * ts, row * ts, ts, ts, tileset_w, tileset_w)
end
```

## Rendering with Camera Culling

```lua
local function draw_layer(layer_name, cam_x, cam_y, screen_w, screen_h)
    local ts = map.tile_size
    local data = map.layers[layer_name]
    if not data then return end

    local start_col = math.max(0, math.floor(cam_x / ts))
    local end_col   = math.min(map.width - 1, math.floor((cam_x + screen_w) / ts))
    local start_row = math.max(0, math.floor(cam_y / ts))
    local end_row   = math.min(map.height - 1, math.floor((cam_y + screen_h) / ts))

    for row = start_row, end_row do
        for col = start_col, end_col do
            local idx = row * map.width + col + 1
            local tile_id = data[idx]
            if tile_id and tile_id > 0 then
                local quad = get_tile_quad(tile_id, 256)
                luna.gfx.draw(map.tileset, quad, col * ts, row * ts)
            end
        end
    end
end
```

## Tile Collision Check

```lua
local function is_solid(px, py)
    local ts = map.tile_size
    local col = math.floor(px / ts)
    local row = math.floor(py / ts)
    if col < 0 or col >= map.width or row < 0 or row >= map.height then return true end
    local idx = row * map.width + col + 1
    local coll = map.layers["collision"]
    return coll and coll[idx] and coll[idx] > 0
end
```

## Camera Bounds from Map

```lua
local function clamp_camera_to_map(cam, screen_w, screen_h)
    local mw = map.width * map.tile_size
    local mh = map.height * map.tile_size
    cam.x = math.max(0, math.min(mw - screen_w, cam.x))
    cam.y = math.max(0, math.min(mh - screen_h, cam.y))
end
```

## Trigger Zones

```lua
local TRIGGER_TILES = { [5] = "door", [6] = "spike", [7] = "checkpoint" }

local function check_triggers(px, py)
    local ts = map.tile_size
    local col = math.floor(px / ts)
    local row = math.floor(py / ts)
    local idx = row * map.width + col + 1
    local tile = map.layers["triggers"] and map.layers["triggers"][idx]
    if tile and TRIGGER_TILES[tile] then
        return TRIGGER_TILES[tile]
    end
    return nil
end
```

## Common Pitfalls

- **Off-by-one in tile indexing** — Lua arrays are 1-based. Row/col to index: `row * width + col + 1`.
- **Drawing all tiles** — without culling, large maps tank FPS. Always cull to visible screen rect.
- **Quad cache** — creating quads every frame allocates. Cache quads per tile ID at load time.
- **Collision layer mismatch** — ensure collision layer dimensions match the map. Missing tiles default to passable, not solid.
- **Tileset size assumption** — compute columns from actual image width, don't hardcode.
