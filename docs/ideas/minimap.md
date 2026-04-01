# minimap — Strategy Game Minimap Module

> **Lua namespace:** `luna.minimap`
> **C++ module:** `src/modules/minimap/`
> **Purpose:** Provides a data-driven minimap system for strategy/RPG games with terrain rendering, fog of war, trackable objects with ownership, markers, animated pings, viewport overlay, zoom/pan navigation, and mouse interaction. The Minimap type extends `Drawable` — it can be drawn directly with `luna.graphics.draw()`.

## Reimplementation Notes

- Minimap inherits from `engine::graphics::Drawable` — the C++ implementation renders to an internal texture
- Data model is a 2D integer grid where each cell stores a terrain type ID
- Fog of war is a separate per-cell byte array with three levels: hidden, explored, visible
- Objects are tracked by numeric ID with position, type, and owner
- Terrain colors, fog colors, and owner colors are set independently
- Color mode switches between terrain-based and owner/political-based rendering
- The viewport rectangle overlay shows the player's current view area on the minimap
- Mouse interaction supports screen-to-grid coordinate conversion and hover tooltips
- Pings are animated effects with a duration that auto-expire via `update(dt)`
- No external dependencies beyond the standard graphics module

## Dependencies

- `luna.graphics` (Drawable base, internal texture rendering)
- No external library dependencies

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newMinimap` | `gridW: int, gridH: int, displayW?: int, displayH?: int` | `Minimap` | Create a new minimap. Grid size is the data resolution; display size is the pixel rendering size (default 200×200) |

---

## Type: Minimap

A drawable minimap backed by a grid of terrain cells, fog-of-war layer, trackable objects, markers, and pings.

**Created by:** `luna.minimap.newMinimap(gridW, gridH, displayW?, displayH?)`

### Display Size

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setDisplaySize` | `width, height` | — | Set the pixel display dimensions |
| `getDisplaySize` | — | `width, height` | Get both display dimensions |
| `getDisplayWidth` | — | `int` | Get display width in pixels |
| `getDisplayHeight` | — | `int` | Get display height in pixels |

### Grid Info

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getGridWidth` | — | `int` | Get grid column count |
| `getGridHeight` | — | `int` | Get grid row count |
| `getGridSize` | — | `int, int` | Get grid width and height |

### Terrain

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTerrainColor` | `typeId, r, g, b, a?` | — | Set the RGBA color for a terrain type ID. Alpha defaults to 1.0 |
| `setTerrainType` | `x, y, typeId` | — | Set the terrain type at a grid cell |
| `getTerrainType` | `x, y` | `int` | Get the terrain type at a grid cell |
| `setTerrainData` | `data: table` | — | Bulk-set terrain types from a flat integer table (length = gridW × gridH) |

### Fog of War

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setFogEnabled` | `enabled: boolean` | — | Enable/disable fog-of-war rendering |
| `isFogEnabled` | — | `boolean` | Check if fog-of-war is enabled |
| `setFogLevel` | `x, y, level: string` | — | Set fog level at a cell. Level: `"hidden"`, `"explored"`, or `"visible"` |
| `getFogLevel` | `x, y` | `string` | Get fog level at a cell |
| `setFogData` | `data: table` | — | Bulk-set fog levels from a flat byte table (0=hidden, 1=explored, 2=visible) |
| `setFogColor` | `level: string, r, g, b, a?` | — | Set the RGBA color used to render a fog level |

### Color Mode

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setColorMode` | `mode: string` | — | Set rendering mode: `"terrain"` or `"political"` |
| `getColorMode` | — | `string` | Get current rendering mode |

### Objects

Objects are tracked entities rendered on the minimap (units, buildings, etc.).

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addObjectType` | `name, r, g, b, a?` | `int` | Register an object type with default color. Returns the type index |
| `setObjectTypeVisible` | `typeIndex, visible` | — | Show/hide all objects of a type |
| `isObjectTypeVisible` | `typeIndex` | `boolean` | Check visibility of an object type |
| `setObject` | `id, x, y, typeIndex, owner?` | — | Place/update a tracked object. `owner` defaults to 0 |
| `removeObject` | `id: int` | — | Remove a tracked object by ID |
| `clearObjects` | — | — | Remove all tracked objects |

### Owner Colors

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setOwnerColor` | `owner, r, g, b, a?` | — | Set the tint color for objects belonging to an owner index. Used in `"political"` color mode |

### Zoom & Navigation

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setZoom` | `factor: number` | — | Set the zoom level (1.0 = fit entire grid) |
| `getZoom` | — | `number` | Get current zoom factor |
| `setCenter` | `x, y` | — | Set the visible center in grid coordinates |
| `getCenter` | — | `x, y` | Get the visible center |
| `getCenterX` | — | `number` | Get center X coordinate |
| `getCenterY` | — | `number` | Get center Y coordinate |

### Viewport Rectangle

An overlay rectangle showing the player's current game viewport on the minimap.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setViewportRect` | `x, y, w, h` | — | Set the viewport rect in normalized grid coordinates |
| `setViewportRectVisible` | `visible: boolean` | — | Show/hide the viewport rect overlay |
| `isViewportRectVisible` | — | `boolean` | Check if viewport rect is visible |
| `setViewportRectColor` | `r, g, b, a?` | — | Set the viewport rect border color |

### Pings

Animated alert effects that expire after a duration.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addPing` | `x, y, duration, r?, g?, b?, a?` | — | Add a ping at a grid cell. Default color: yellow (1,1,0,1) |

### Markers

Persistent labeled points on the minimap.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addMarker` | `id, x, y, desc?, r?, g?, b?, a?` | — | Add a marker. `desc` defaults to "". Default color: red (1,0,0,1) |
| `removeMarker` | `id: int` | — | Remove a marker by ID |
| `hasMarker` | `id: int` | `boolean` | Check if a marker exists |
| `getMarkerDescription` | `id: int` | `string` | Get the description text of a marker |

### Anti-Aliasing

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setAntiAlias` | `enabled: boolean` | — | Enable/disable anti-aliased rendering |
| `isAntiAlias` | — | `boolean` | Check if AA is enabled |

### Tile Descriptions

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTileDescription` | `typeId, desc: string` | — | Set a hover tooltip string for a terrain type |
| `getTileDescription` | `typeId` | `string` | Get the tooltip string for a terrain type |

### Mouse Interaction

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `screenToGrid` | `screenX, screenY, drawX, drawY` | `gx, gy \| nil` | Convert screen pixel coords to grid cell coords. `drawX, drawY` is where the minimap is drawn on screen. Returns nil if outside |
| `getHoverInfo` | `screenX, screenY, drawX, drawY` | `string \| nil` | Get tooltip text for the element under the cursor |
| `setClickable` | `enabled: boolean` | — | Enable/disable click hit-testing |
| `isClickable` | — | `boolean` | Check if click hit-testing is enabled |

### Update

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `update` | `dt: number` | — | Advance time-based effects (ping animations). Call every frame |

---

## Enums

### FogLevel

| Value | String | Description |
|---|---|---|
| 0 | `"hidden"` | Cell not yet discovered — fully obscured |
| 1 | `"explored"` | Cell previously seen — partially dimmed |
| 2 | `"visible"` | Cell currently visible — fully lit |

### ColorMode

| Value | String | Description |
|---|---|---|
| 0 | `"terrain"` | Color cells by terrain type colors |
| 1 | `"political"` | Color cells by owner colors (for strategy games with territories) |
