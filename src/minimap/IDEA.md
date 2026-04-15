# IDEA.md — `minimap` module

> Migrated from `ideas/features/minimap.md` and `ideas/performance/14-minimap-fov-gpu.md`.
> Status checked against `src/minimap/` and `src/lua_api/minimap_api.rs`.
> Lua namespace: `lurek.minimap`.

---

## Features

### ✅ DONE — Minimap Zoom
**Source**: features/minimap.md — Suggestions #2

`setZoom(level)` implemented in `minimap_api.rs` (line ~420).

---

### ✅ DONE — Generic Markers (Non-tilemap entities)
**Source**: features/minimap.md — Suggestions #1

`addMarker(x, y, icon, color)` implemented in `minimap_api.rs` (line ~579). Minimap is no
longer tilemap-only — arbitrary world-space markers are supported.

---

### ✅ DONE — Custom Geometry Overlay
**Source**: features/minimap.md — Feature Gaps #5 / Suggestions #3

`minimap:drawLine(x1, y1, x2, y2, color)`, `minimap:drawRect(x, y, w, h, color)`, and
`minimap:clearOverlay()` implemented in `minimap_api.rs`. Shapes stored in
`Vec<OverlayShape>` on the `Minimap` struct.

---

### ✅ DONE — Icon Animation (Blink, Pulse, Rotate)
**Source**: features/minimap.md — Feature Gaps #2 / Suggestions #4

`minimap:setMarkerAnimation(id, anim_type, speed)` and `minimap:clearMarkerAnimation(id)`
implemented. Animation state stored in `MinimapMarker.animation: Option<MarkerAnimation>`.
Phases advanced on each `minimap:update(dt)` call.

---

### ✅ DONE — Path Visualization Overlay
**Source**: features/minimap.md — Feature Gaps #4 / Suggestions #6

`minimap:showPath(points, color)` → returns path ID; `minimap:clearPath()` / `minimap:clearPath(id)`
implemented. Paths stored in `Vec<OverlayPath>` on the `Minimap` struct.

---

### ✅ DONE — Multi-Layer Minimap (Underground / Surface Toggle)
**Source**: features/minimap.md — Feature Gaps #6

`minimap:setLayer(index)`, `minimap:getLayer()`, and `minimap:setLayerData(layer, data)`
implemented. Layer data stored in `Vec<LayerData>`; `active_layer: usize` tracks the
current render layer.

---

### 🤔 CONSIDER — Extract Fog of War as Standalone System
**Source**: features/minimap.md — Structural Issues #2

Fog of war is bundled inside the minimap module. In RTS, RPG, and stealth games, fog of
war is a gameplay system independent of the minimap. Consider extracting into `src/fow/`
or a sub-namespace `lurek.minimap.fow` with a standalone Lua API.

---

## Performance

### 🔇 LOW — GPU Fog of War Rendering
**Source**: performance/14-minimap-fov-gpu.md

Fog of war reveal is computed CPU-side per entity per frame. For large maps (500×500+
tiles) and many entities, a GPU compute shader fill would be faster. Evidence from profiling
is needed first. Priority: **LOW**.
