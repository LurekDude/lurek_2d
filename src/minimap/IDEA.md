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

### ❌ TODO — Custom Geometry Overlay
**Source**: features/minimap.md — Feature Gaps #5 / Suggestions #3

No `minimap:drawLine(x1, y1, x2, y2, color)` or `drawRect()` found. Needed for trade
routes, territorial borders, and areas of influence overlays.

---

### ❌ TODO — Icon Animation (Blink, Pulse, Rotate)
**Source**: features/minimap.md — Feature Gaps #2 / Suggestions #4

No `setIconAnimation(entity, "blink", speed)` found. Blinking icons are standard UI
feedback for alerts, quest markers, and danger indicators.

---

### ❌ TODO — Path Visualization Overlay
**Source**: features/minimap.md — Feature Gaps #4 / Suggestions #6

No `showPath(pathPoints, color)` found. Overlaying pathfinding routes on the minimap would
help both debugging and game UI (show enemy patrol routes).

---

### ❌ TODO — Multi-Layer Minimap (Underground / Surface Toggle)
**Source**: features/minimap.md — Feature Gaps #6

No layer toggle found. Games with underground areas need to switch which tilemap layer the
minimap renders.

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
