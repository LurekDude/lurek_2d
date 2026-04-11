# `minimap` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.minimap` |
| **Source** | `src/minimap/` |
| **Rust Tests** | `tests/rust/game/minimap_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_minimap.lua`, `tests/lua/evidence/test_evidence_minimap.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `minimap` module provides a compact overhead representation of a larger game world. It stores terrain cells, fog-of-war state, tracked objects, temporary pings, persistent markers, and the current viewport rectangle so scripts can present navigational context without rebuilding that logic every frame.

It exists to centralize minimap state and coordinate conversion in one CPU-side system. That keeps world-to-minimap math, visibility bookkeeping, and ping or marker lifecycle out of UI code and out of unrelated gameplay modules.

It intentionally does not own input handling, camera control, or texture-backed rendering. The module produces draw-ready data and render commands, but the actual UI composition and event routing stay elsewhere.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.minimap.* (Lua API — src/lua_api/minimap_api.rs)
    |
    v
src/minimap/mod.rs
    |- minimap.rs - minimap
    |- render.rs - render
    |- types.rs - types
```

---

## Source Files

| File | Purpose |
|------|---------|
| `minimap.rs` | Implements the main `Minimap` state container, including terrain cells, fog, tracked objects, markers, pings, zoom, pan, and coordinate transforms. |
| `mod.rs` | Declares the minimap submodules and re-exports the core minimap and support types. |
| `render.rs` | Generates render commands for the minimap background, cells, viewport rectangle, and animated pings. |
| `types.rs` | Defines shared enums and data records such as fog levels, color modes, objects, pings, and markers. |

---

## Submodules

### `minimap::minimap`

Implements the main `Minimap` state container, including terrain cells, fog, tracked objects, markers, pings, zoom, pan, and coordinate transforms.

- **`Minimap`** (struct): A grid-based minimap with terrain, fog-of-war, objects, pings, markers, and navigation state.

### `minimap::render`

Generates render commands for the minimap background, cells, viewport rectangle, and animated pings.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `minimap::types`

Defines shared enums and data records such as fog levels, color modes, objects, pings, and markers.

- **`ColorMode`** (enum): How cells are colored on the minimap.
- **`FogLevel`** (enum): Fog-of-war visibility level for a cell.
- **`MinimapObjectType`** (struct): A registered object type with a display color and visibility toggle.
- **`MinimapObject`** (struct): A tracked object on the minimap.
- **`MinimapPing`** (struct): A temporary animated ping on the minimap.
- **`MinimapMarker`** (struct): A persistent labeled marker on the minimap.

---

## Key Types

### Public Types

#### `Minimap`

The main grid-based minimap model.

#### `ColorMode`

Chooses how minimap cells are colored, such as terrain-driven versus owner-driven display.

#### `FogLevel`

Encodes whether a minimap cell is hidden, explored, or currently visible.

#### `MinimapObject`

A tracked world object projected onto the minimap with position, type, and owner metadata.

#### `MinimapPing`

A temporary animated alert marker used for events or attention cues.

#### `MinimapMarker`

A persistent named marker with descriptive text for locations of interest.

---

## Lua API

Exposed under `lurek.minimap.*` by `src/lua_api/minimap_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.minimap.newMinimap` | Creates a new grid-based minimap. |

### `Minimap` Methods

| Method | Description |
|--------|-------------|
| `minimap:getGridWidth(...)` | Returns the grid width in cells. |
| `minimap:getGridHeight(...)` | Returns the grid height in cells. |
| `minimap:getGridSize(...)` | Returns the grid width and height as two values. |
| `minimap:getDisplayWidth(...)` | Returns the display width in pixels. |
| `minimap:getDisplayHeight(...)` | Returns the display height in pixels. |
| `minimap:getDisplaySize(...)` | Returns the display width and height as two values. |
| `minimap:setDisplaySize(...)` | Sets the display size in pixels. |
| `minimap:getTerrain(...)` | Returns the terrain type at a 1-based grid position. |
| `minimap:setTerrainData(...)` | Sets terrain types from a flat 1-based Lua table of integers (row-major). |
| `minimap:getTerrainColor(...)` | Returns the display color for a terrain type as r, g, b, a. |
| `minimap:getTileDescription(...)` | Returns the hover tooltip string for a terrain type ID, or nil. |
| `minimap:setFogEnabled(...)` | Enables or disables fog of war. |
| `minimap:isFogEnabled(...)` | Returns whether fog of war is enabled. |
| `minimap:setFogLevel(...)` | Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible). |
| `minimap:getFogLevel(...)` | Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible). |
| `minimap:getFogColor(...)` | Returns the fog overlay color as r, g, b, a. |
| `minimap:setFogData(...)` | Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible). |
| `minimap:isObjectTypeVisible(...)` | Returns whether an object type (1-based index) is visible. |
| `minimap:getObjectTypeCount(...)` | Returns the number of registered object types. |
| `minimap:removeObject(...)` | Removes a tracked object by ID. |
| `minimap:clearObjects(...)` | Removes all tracked objects. |
| `minimap:getObjectCount(...)` | Returns the number of tracked objects. |
| `minimap:getOwnerColor(...)` | Returns the display color for an owner/faction as r, g, b, a. |
| `minimap:setColorMode(...)` | Sets the color mode ("terrain" or "political"). |
| `minimap:getColorMode(...)` | Returns the current color mode as a string. |
| `minimap:setZoom(...)` | Sets the zoom level (minimum 0.1). |
| `minimap:getZoom(...)` | Returns the current zoom level. |
| `minimap:setCenter(...)` | Sets the center of the minimap view in grid coordinates. |
| `minimap:getCenter(...)` | Returns the center coordinates as x, y. |
| `minimap:getCenterX(...)` | Returns the center X coordinate. |
| `minimap:getCenterY(...)` | Returns the center Y coordinate. |
| `minimap:clearViewportRect(...)` | Clears the viewport rectangle overlay. |
| `minimap:getViewportRect(...)` | Returns the viewport rectangle as x, y, w, h or nil if not set. |
| `minimap:setViewportVisible(...)` | Sets whether the viewport rectangle is visible. |
| `minimap:isViewportVisible(...)` | Returns whether the viewport rectangle is visible. |
| `minimap:getViewportColor(...)` | Returns the viewport rectangle color as r, g, b, a. |
| `minimap:getPingCount(...)` | Returns the number of active pings. |
| `minimap:removeMarker(...)` | Removes a marker by ID. |
| `minimap:hasMarker(...)` | Returns whether a marker with the given ID exists. |
| `minimap:getMarkerDescription(...)` | Returns the description of a marker, or nil. |
| `minimap:getMarkerCount(...)` | Returns the number of markers. |
| `minimap:setAntiAlias(...)` | Sets whether anti-aliasing is enabled. |
| `minimap:isAntiAlias(...)` | Returns whether anti-aliasing is enabled. |
| `minimap:setClickable(...)` | Sets whether this minimap responds to click hit-testing. |
| `minimap:isClickable(...)` | Returns whether this minimap responds to click hit-testing. |
| `minimap:update(...)` | Advances time-based effects by dt seconds (expires pings). |
| `minimap:type(...)` | Returns the type name of this object. |
| `minimap:typeOf(...)` | Returns true if this object is of the given type. |
| `minimap:render(...)` | Renders the minimap to the screen at the given position. |
| `minimap:drawToImage(...)` | Renders the minimap grid to a CPU ImageData. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.minimap.
if lurek.minimap then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 5 |
| `enum` | 2 |
| `fn` (Lua API) | 51 |
| **Total** | **58** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/minimap/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
