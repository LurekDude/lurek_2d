# `minimap` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.minimap`                                       |
| **Source**     | `src/minimap/`                                       |
| **Rust Tests** | `tests/rust/game/minimap_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_minimap.lua`                    |
| **Architecture** | —                                                  |

## Summary

The `minimap` module provides a self-contained, grid-based minimap data model for overhead map displays commonly used in strategy, RPG, and open-world games. It is a **Tier 2 Engine Extension** that operates as a **pure CPU data-model module** — it has zero GPU or wgpu dependencies. All rendering responsibility is delegated to the `lua_api` bridge layer, which reads the minimap state and produces draw commands or texture uploads.

The core `Minimap` struct holds a fixed-size terrain colour grid (integer terrain type IDs mapped to RGBA colours), a per-cell fog-of-war visibility mask (hidden/explored/visible), a collection of tracked `MinimapObject` entities (position, type, owner), and overlay features including a viewport rectangle, temporary animated `MinimapPing` flashes, and persistent labelled `MinimapMarker` stamps. A zoom/pan system controls which portion of the grid is visible, and coordinate conversion functions translate between screen space and grid space.

The module supports two colour modes: `Terrain` (cells coloured by terrain type) and `Political` (cells coloured by owner/faction). Object types are registered with names and colours, then individual objects reference a type index and optional owner ID. Tile descriptions provide hover tooltip text keyed by terrain type. Anti-aliasing and clickability are toggleable rendering hints.

**Scope boundary**: The `minimap` module owns only the data model and coordinate math. It never imports `wgpu`, `graphics`, or any rendering code. The `lua_api/minimap_api.rs` bridge wraps `Minimap` in a `LuaMinimap` UserData and exposes the full API under `luna.minimap.*`. All GPU upload, texture creation, and draw-call submission is the responsibility of code outside this module. The module also does not handle input events — click detection and hover queries require the caller to pass screen coordinates into the conversion functions.

## Architecture

```
luna.minimap.newMinimap(gw, gh, dw, dh)
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LuaMinimap (UserData)                        │
│                   src/lua_api/minimap_api.rs                    │
│                                                                 │
│  Wraps Minimap, converts 1-based Lua indices to 0-based Rust   │
│  All 61 methods delegate to Minimap methods                    │
└────────────────────────┬────────────────────────────────────────┘
                         │ owns
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Minimap (struct)                            │
│                   src/minimap/minimap.rs                        │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Terrain Grid │  │ Fog-of-War   │  │ Objects & Types      │  │
│  │ Vec<u32>     │  │ Vec<u8>      │  │ HashMap<u32,Object>  │  │
│  │ + color map  │  │ + enabled    │  │ Vec<ObjectType>      │  │
│  │ + tile descs │  │ + fog color  │  │ + owner colors       │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Viewport     │  │ Pings        │  │ Markers              │  │
│  │ rect, color  │  │ Vec<Ping>    │  │ HashMap<u32,Marker>  │  │
│  │ visible flag │  │ time-decayed │  │ auto-incrementing ID  │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│                                                                 │
│  zoom / center_x / center_y / color_mode / anti_alias / click  │
│  screen_to_grid() ←→ grid_to_screen()  coordinate conversion  │
└─────────────────────────────────────────────────────────────────┘
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Supporting Types                              │
│                   src/minimap/types.rs                          │
│                                                                 │
│  ColorMode (Terrain | Political)                               │
│  FogLevel  (Hidden | Explored | Visible)                       │
│  MinimapObjectType { name, color, visible }                    │
│  MinimapObject     { x, y, type_index, owner }                 │
│  MinimapPing       { x, y, remaining, duration, color }        │
│  MinimapMarker     { x, y, description, color }                │
└─────────────────────────────────────────────────────────────────┘
```

## Source Files

| File         | Purpose                                                                                  |
|--------------|------------------------------------------------------------------------------------------|
| `minimap.rs` | Core `Minimap` data model: terrain grid, fog of war, objects, pings, markers, zoom/pan, coordinate conversion, and time-based update. |
| `types.rs`   | Supporting type definitions: `ColorMode` and `FogLevel` enums, `MinimapObjectType`, `MinimapObject`, `MinimapPing`, and `MinimapMarker` plain data structs. |

## Submodules

### `minimap::minimap`

Core `Minimap` data model: terrain grid, fog of war, objects, pings, markers, and navigation.

- **`Minimap`** (struct) — Grid-based minimap with terrain, fog-of-war, tracked objects, pings, markers, viewport overlay, zoom/pan, and coordinate conversion.

### `minimap::types`

Supporting types for the minimap module: enums and plain data structs.

- **`MinimapObjectType`** (struct) — A registered object type with a display name, colour, and visibility toggle.
- **`MinimapObject`** (struct) — A tracked object on the minimap with position, type index, and owner ID.
- **`MinimapPing`** (struct) — A temporary animated ping at grid coordinates with a countdown timer.
- **`MinimapMarker`** (struct) — A persistent labeled marker at grid coordinates with a description and colour.
- **`ColorMode`** (enum) — How cells are coloured: by terrain type or by owner/faction (political).
- **`FogLevel`** (enum) — Fog-of-war visibility level for a cell: Hidden (0), Explored (1), or Visible (2).

## Key Types

### Structs

#### `minimap::minimap::Minimap`

A grid-based minimap with terrain, fog-of-war, objects, pings, markers, and navigation state. Holds a flat `Vec<u32>` terrain grid and `Vec<u8>` fog grid of `grid_width × grid_height` cells, a `HashMap<u32, MinimapObject>` of tracked objects, a `Vec<MinimapObjectType>` registry, `Vec<MinimapPing>` animated pings, and `HashMap<u32, MinimapMarker>` persistent markers. Supports zoom, pan (centre coordinates), viewport rectangle overlay, coordinate conversion between screen and grid space, and per-frame update to expire pings. Created via `Minimap::new(grid_width, grid_height, display_width, display_height)`.

Key methods: `set_terrain`, `get_terrain`, `set_terrain_data`, `set_terrain_color`, `get_terrain_color`, `set_tile_description`, `get_tile_description`, `set_fog_enabled`, `set_fog_level`, `get_fog_level`, `set_fog_data`, `add_object_type`, `set_object`, `remove_object`, `clear_objects`, `set_owner_color`, `set_color_mode`, `set_zoom`, `set_center`, `set_viewport_rect`, `add_ping`, `add_marker`, `remove_marker`, `screen_to_grid`, `grid_to_screen`, `get_hover_info`, `update`.

#### `minimap::types::MinimapObjectType`

A registered object type with a human-readable `name: String`, display `color: [f32; 4]` (RGBA), and `visible: bool` toggle. Object types are stored in a `Vec` and referenced by index from `MinimapObject`.

#### `minimap::types::MinimapObject`

A tracked object on the minimap with fractional grid position (`x: f32`, `y: f32`), a `type_index: usize` into the object types array, and an `owner: u32` faction identifier (0 = neutral).

#### `minimap::types::MinimapPing`

A temporary animated ping at grid position (`x: f32`, `y: f32`) with a `remaining: f32` countdown timer, `duration: f32` total lifetime, and `color: [f32; 4]`. Expired via `Minimap::update(dt)` when `remaining` reaches zero.

#### `minimap::types::MinimapMarker`

A persistent labeled marker at grid position (`x: f32`, `y: f32`) with a `description: String` tooltip and `color: [f32; 4]`. Assigned an auto-incrementing `u32` ID by `Minimap::add_marker()`.

### Enums

#### `minimap::types::ColorMode`

How cells are coloured on the minimap. Two variants: `Terrain` (colour by terrain type) and `Political` (colour by owner/faction). Parsed from strings via `ColorMode::parse_mode("terrain" | "political")` and serialised via `as_str()`.

#### `minimap::types::FogLevel`

Fog-of-war visibility level for a cell. Three variants represented as `#[repr(u8)]`: `Hidden` (0) — cell never seen, `Explored` (1) — previously seen but not currently visible, `Visible` (2) — currently fully visible. Converted from raw bytes via `FogLevel::from_u8(val)`.

## Lua API

Exposed under `luna.minimap.*` by `src/lua_api/minimap_api.rs`. The module registers one factory function on the `luna.minimap` table and wraps `Minimap` as a `LuaMinimap` UserData with 61 methods plus `type()` and `typeOf()` from the `LunaType` trait.

**Index convention**: All grid coordinates in the Lua API are **1-based** (Lua convention). The bridge layer subtracts 1 before passing to the 0-based Rust model. Object type indices returned by `addObjectType` are also 1-based.

### Factory Function

| Function | Signature | Description |
|----------|-----------|-------------|
| `luna.minimap.newMinimap` | `(grid_w, grid_h [, display_w, display_h]) → Minimap` | Creates a new grid-based minimap. Display size defaults to 200×200 if omitted. |

### Minimap Methods — Grid Queries

| Method | Signature | Description |
|--------|-----------|-------------|
| `getGridWidth` | `() → integer` | Returns the grid width in cells. |
| `getGridHeight` | `() → integer` | Returns the grid height in cells. |
| `getGridSize` | `() → integer, integer` | Returns grid width and height as two values. |

### Minimap Methods — Display Dimensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `getDisplayWidth` | `() → integer` | Returns the display width in pixels. |
| `getDisplayHeight` | `() → integer` | Returns the display height in pixels. |
| `getDisplaySize` | `() → integer, integer` | Returns display width and height as two values. |
| `setDisplaySize` | `(w, h)` | Sets the display size in pixels. |

### Minimap Methods — Terrain

| Method | Signature | Description |
|--------|-----------|-------------|
| `setTerrain` | `(x, y, terrain_type)` | Sets the terrain type at a 1-based grid position. |
| `getTerrain` | `(x, y) → integer` | Returns the terrain type at a 1-based grid position. |
| `setTerrainData` | `(table)` | Bulk-sets terrain types from a flat 1-based Lua table (row-major). |
| `setTerrainColor` | `(terrain_type, r, g, b [, a])` | Sets the display colour for a terrain type. Alpha defaults to 1.0. |
| `getTerrainColor` | `(terrain_type) → r, g, b, a` | Returns the display colour for a terrain type. |
| `setTileDescription` | `(type_id, desc)` | Sets a hover tooltip string for a terrain type ID. |
| `getTileDescription` | `(type_id) → string?` | Returns the tooltip string for a terrain type, or nil. |

### Minimap Methods — Fog of War

| Method | Signature | Description |
|--------|-----------|-------------|
| `setFogEnabled` | `(enabled)` | Enables or disables fog of war. |
| `isFogEnabled` | `() → boolean` | Returns whether fog of war is enabled. |
| `setFogLevel` | `(x, y, level)` | Sets the fog level at a 1-based position (0=hidden, 1=explored, 2=visible). |
| `getFogLevel` | `(x, y) → integer` | Returns the fog level at a 1-based position. |
| `setFogColor` | `(r, g, b [, a])` | Sets the fog overlay colour. Alpha defaults to 0.8. |
| `getFogColor` | `() → r, g, b, a` | Returns the fog overlay colour. |
| `setFogData` | `(table)` | Bulk-sets the fog grid from a flat 1-based table of 0/1/2 values. |

### Minimap Methods — Object Types

| Method | Signature | Description |
|--------|-----------|-------------|
| `addObjectType` | `(name, r, g, b [, a]) → integer` | Registers a new object type; returns its 1-based index. |
| `setObjectTypeVisible` | `(type_idx, visible)` | Sets whether an object type (1-based) is visible. |
| `isObjectTypeVisible` | `(type_idx) → boolean` | Returns whether an object type (1-based) is visible. |
| `getObjectTypeCount` | `() → integer` | Returns the number of registered object types. |

### Minimap Methods — Objects

| Method | Signature | Description |
|--------|-----------|-------------|
| `setObject` | `(id, x, y, type_idx [, owner])` | Sets or updates a tracked object. type_idx is 1-based; owner defaults to 0. |
| `removeObject` | `(id) → boolean` | Removes a tracked object by ID. Returns true if it existed. |
| `clearObjects` | `()` | Removes all tracked objects. |
| `getObjectCount` | `() → integer` | Returns the number of tracked objects. |

### Minimap Methods — Owner Colours

| Method | Signature | Description |
|--------|-----------|-------------|
| `setOwnerColor` | `(owner, r, g, b [, a])` | Sets the display colour for an owner/faction. Alpha defaults to 1.0. |
| `getOwnerColor` | `(owner) → r, g, b, a` | Returns the display colour for an owner/faction. |

### Minimap Methods — Colour Mode

| Method | Signature | Description |
|--------|-----------|-------------|
| `setColorMode` | `(mode)` | Sets the colour mode: `"terrain"` or `"political"`. Errors on invalid string. |
| `getColorMode` | `() → string` | Returns the current colour mode as a string. |

### Minimap Methods — Zoom and Pan

| Method | Signature | Description |
|--------|-----------|-------------|
| `setZoom` | `(zoom)` | Sets the zoom level (minimum 0.1). |
| `getZoom` | `() → number` | Returns the current zoom level. |
| `setCenter` | `(x, y)` | Sets the centre of the minimap view in grid coordinates. |
| `getCenter` | `() → x, y` | Returns the centre coordinates. |
| `getCenterX` | `() → number` | Returns the centre X coordinate. |
| `getCenterY` | `() → number` | Returns the centre Y coordinate. |

### Minimap Methods — Viewport Rectangle

| Method | Signature | Description |
|--------|-----------|-------------|
| `setViewportRect` | `(x, y, w, h)` | Sets the viewport rectangle overlay in grid coordinates. |
| `clearViewportRect` | `()` | Clears the viewport rectangle overlay. |
| `getViewportRect` | `() → x, y, w, h or nil` | Returns the viewport rectangle, or nil if not set. |
| `setViewportVisible` | `(visible)` | Sets whether the viewport rectangle is visible. |
| `isViewportVisible` | `() → boolean` | Returns whether the viewport rectangle is visible. |
| `setViewportColor` | `(r, g, b [, a])` | Sets the viewport rectangle colour. Alpha defaults to 0.8. |
| `getViewportColor` | `() → r, g, b, a` | Returns the viewport rectangle colour. |

### Minimap Methods — Pings

| Method | Signature | Description |
|--------|-----------|-------------|
| `addPing` | `(x, y, duration [, r, g, b, a])` | Adds an animated ping. Colour defaults to yellow (1,1,0,1). |
| `getPingCount` | `() → integer` | Returns the number of active pings. |

### Minimap Methods — Markers

| Method | Signature | Description |
|--------|-----------|-------------|
| `addMarker` | `(x, y [, desc, r, g, b, a]) → integer` | Adds a persistent marker; returns its auto-assigned ID. Colour defaults to red (1,0,0,1). |
| `removeMarker` | `(id) → boolean` | Removes a marker by ID. |
| `hasMarker` | `(id) → boolean` | Returns whether a marker exists. |
| `getMarkerDescription` | `(id) → string?` | Returns the marker description, or nil. |
| `getMarkerCount` | `() → integer` | Returns the number of markers. |

### Minimap Methods — Rendering Options

| Method | Signature | Description |
|--------|-----------|-------------|
| `setAntiAlias` | `(enabled)` | Sets whether anti-aliasing is enabled. |
| `isAntiAlias` | `() → boolean` | Returns whether anti-aliasing is enabled. |
| `setClickable` | `(enabled)` | Sets whether this minimap responds to click hit-testing. |
| `isClickable` | `() → boolean` | Returns whether this minimap responds to click hit-testing. |

### Minimap Methods — Hover and Coordinates

| Method | Signature | Description |
|--------|-----------|-------------|
| `getHoverInfo` | `(sx, sy, minimap_x, minimap_y) → string?` | Returns tooltip text for the terrain under screen coordinates, or nil. |
| `screenToGrid` | `(sx, sy, minimap_x, minimap_y) → gx, gy` | Converts screen coordinates to grid coordinates. |
| `gridToScreen` | `(gx, gy, minimap_x, minimap_y) → sx, sy` | Converts grid coordinates to screen coordinates. |

### Minimap Methods — Update

| Method | Signature | Description |
|--------|-----------|-------------|
| `update` | `(dt)` | Advances time-based effects by dt seconds; expires pings whose remaining time reaches zero. |

## Lua Examples

```lua
function luna.init()
    -- Create a 64x48 minimap displayed at 200x160 pixels
    minimap = luna.minimap.newMinimap(64, 48, 200, 160)

    -- Define terrain colours
    minimap:setTerrainColor(0, 0.0, 0.5, 0.0)  -- grass (green)
    minimap:setTerrainColor(1, 0.3, 0.3, 0.3)  -- rock (grey)
    minimap:setTerrainColor(2, 0.0, 0.0, 0.8)  -- water (blue)

    -- Fill terrain
    for x = 1, 64 do
        for y = 1, 48 do
            minimap:setTerrain(x, y, (x + y) % 3)
        end
    end

    -- Tile tooltips
    minimap:setTileDescription(0, "Grass")
    minimap:setTileDescription(1, "Rock")
    minimap:setTileDescription(2, "Water")

    -- Enable fog of war and reveal a starting area
    minimap:setFogEnabled(true)
    minimap:setFogColor(0, 0, 0, 0.7)
    for x = 1, 10 do
        for y = 1, 10 do
            minimap:setFogLevel(x, y, 2) -- visible
        end
    end

    -- Register object types
    unitType = minimap:addObjectType("unit", 0, 1, 0)       -- green
    buildingType = minimap:addObjectType("building", 0, 0, 1) -- blue

    -- Place objects
    minimap:setObject(1, 5, 5, unitType, 0)      -- neutral unit
    minimap:setObject(2, 30, 20, buildingType, 1) -- player 1 building

    -- Owner colours for political mode
    minimap:setOwnerColor(0, 0.5, 0.5, 0.5) -- neutral grey
    minimap:setOwnerColor(1, 1, 0, 0)        -- player 1 red

    -- Viewport rectangle showing the camera frustum
    minimap:setViewportRect(0, 0, 16, 12)
    minimap:setViewportColor(1, 1, 1, 0.8)

    -- Persistent marker
    minimap:addMarker(40, 30, "Objective", 1, 1, 0)

    -- Zoom in
    minimap:setZoom(1.5)
    minimap:setCenter(32, 24)
end

function luna.process(dt)
    minimap:update(dt) -- expire pings

    -- Example: add a ping on key press
    if luna.keyboard.isDown("p") then
        minimap:addPing(32, 24, 2.0, 1, 0, 0, 1) -- red ping, 2 seconds
    end

    -- Move the viewport to follow camera
    local cx, cy = getCameraPosition()
    minimap:setViewportRect(cx - 8, cy - 6, 16, 12)
end

function luna.render()
    -- Draw the minimap at screen position (580, 10)
    -- (actual rendering is done by luna.gfx using the minimap data)
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 5     |
| `enum`     | 2     |
| `fn`       | 63    |
| **Total**  | **70** |

## References

| Module       | Relationship | Notes                                                                 |
|--------------|--------------|-----------------------------------------------------------------------|
| `engine`     | Imports from | Uses `log_messages` constants for structured logging via `log_msg!`.  |
| `math`       | —            | No direct import; colours are raw `[f32; 4]` arrays, not `Color`.    |
| `lua_api`    | Imported by  | `minimap_api.rs` wraps `Minimap` as `LuaMinimap` UserData.           |
| `tilemap`    | Similar      | `tilemap` handles tile-based world maps with layers and tilesets; `minimap` is a simplified overhead display model without rendering. |
| `province_map` | Similar    | `province_map` (library/) is a Lua gameplay layer for province ownership; `minimap` is a Rust data model for the visual minimap overlay. |
| `graphics`   | No dependency | `minimap` has zero GPU imports; rendering is the caller's responsibility. |

## Notes

- **Pure data model**: The minimap module has zero external crate dependencies beyond `std`. It does not import `wgpu`, `image`, `rapier2d`, or any other Luna2D tier module except `engine` (for log message constants). This makes it safe to use in headless/test environments without GPU or window.
- **0-based vs 1-based indexing**: The Rust `Minimap` struct uses 0-based grid coordinates and 0-based object type indices internally. The `LuaMinimap` bridge in `minimap_api.rs` converts to/from 1-based Lua conventions by subtracting/adding 1. Passing 0 for coordinates or type indices from Lua triggers a descriptive `LuaError`.
- **Flat array storage**: Terrain (`Vec<u32>`) and fog (`Vec<u8>`) grids are stored as flat row-major arrays of `grid_width × grid_height` elements. Bulk-set operations (`setTerrainData`, `setFogData`) accept flat Lua tables and clamp to the grid size, silently ignoring excess values.
- **Ping expiration**: Pings are time-decayed — `Minimap::update(dt)` decrements each ping's `remaining` field and removes expired pings via `Vec::retain_mut`. The caller must call `update(dt)` every frame for pings to expire, or they persist indefinitely.
- **Marker auto-ID**: Markers receive monotonically increasing `u32` IDs starting from 1. IDs are never reused within a single `Minimap` instance.
- **Coordinate conversion**: `screen_to_grid` and `grid_to_screen` account for zoom and centre offset. They require the screen position of the minimap widget (`minimap_x`, `minimap_y`) as parameters because the module has no knowledge of where it is drawn on screen.
- **Colour defaults**: Unset terrain colours default to grey `[0.5, 0.5, 0.5, 1.0]`. Unset owner colours default to light grey `[0.8, 0.8, 0.8, 1.0]`. Fog colour defaults to semi-transparent black `[0.0, 0.0, 0.0, 0.8]`. Viewport colour defaults to semi-transparent white `[1.0, 1.0, 1.0, 0.8]`. Ping colour defaults to yellow `[1.0, 1.0, 0.0, 1.0]` when omitted in Lua. Marker colour defaults to red `[1.0, 0.0, 0.0, 1.0]` when omitted in Lua.
- **No SharedState interaction**: Unlike most Lua API modules, `minimap_api.rs` does not borrow `SharedState` at all — it receives the `_state` parameter but ignores it. The `LuaMinimap` UserData owns its `Minimap` instance directly, avoiding borrow contention.
- **Breaking change surface**: Renaming or removing any `LuaMinimap` method breaks Lua game scripts that call `luna.minimap.newMinimap()` and use the returned object. The 1-based coordinate convention is load-bearing — changing it would silently corrupt terrain and fog data in existing games.
