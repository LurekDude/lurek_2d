# IDEA.md — `raycaster` module

> Migrated from `ideas/features/raycaster.md`.
> Status checked against `src/raycaster/` and `src/lua_api/raycaster_api.rs`.
> Lua namespace: `lurek.raycaster`.

> **NOTE**: The feature analysis file (written before this audit) listed DoorManager,
> HeightMap, and PointLight as "Rust-only not exposed to Lua". That was incorrect — all
> three are fully Lua-exposed as of the current codebase. Marked ✅ below.

---

## Features

### ✅ DONE — DDA Grid Raycaster (`castRay`, `castRays`, `castRaysFlat`)
Core DDA raycasting implemented. Single-ray and fan-cast variants available.

---

### ✅ DONE — DoorManager Exposed to Lua
**Source**: features/raycaster.md — Feature Gaps #1 / Suggestions #1

`lurek.raycaster.newDoorManager()` fully bound at `raycaster_api.rs:709`.
`LuaDoorManager` struct with `impl LuaUserData` at line 39.

---

### ✅ DONE — HeightMap Exposed to Lua (Variable Floor/Ceiling Heights)
**Source**: features/raycaster.md — Feature Gaps #6 / Suggestions #1

`lurek.raycaster.newHeightMap(w, h)` fully bound at `raycaster_api.rs:723`.
Methods: `setFloor`, `setCeiling`, `floorAt`, `ceilingAt`.

---

### ✅ DONE — PointLight Exposed to Lua
**Source**: features/raycaster.md — Suggestions #1

`lurek.raycaster.newPointLight(x, y, radius, intensity, r, g, b)` at `raycaster_api.rs:742`.
`LuaPointLight` with full `LuaUserData` at line 204.

---

### ✅ DONE — Floor/Ceiling Color Support
**Source**: features/raycaster.md — Feature Gaps #2

`castAndBatch` params include `floor_color` and `ceiling_color` at `raycaster_api.rs:530`.

---

### ✅ DONE — Sprite Projection
**Source**: features/raycaster.md — Feature Gaps #4

`raycaster:projectSprite(...)` bound at `raycaster_api.rs:411`.

---

### ✅ DONE — Line-of-Sight Check
`lineOfSight()` — boolean LOS check implemented.

---

### ✅ DONE — Column Rendering Helpers
`projectColumn()` and `distanceShade()` available for manual column rendering.

---

### ❌ TODO — Transparent / Translucent Walls
**Source**: features/raycaster.md — Feature Gaps #3

All walls are fully opaque. Transparent walls require ray continuation after hit.
Useful for windows, force fields, and glass surfaces.

---

### ❌ TODO — Batch Sprite Manager with Depth Sorting
**Source**: features/raycaster.md — Feature Gaps #4

`projectSprite()` projects a single sprite. No batch sprite management with automatic
depth sorting and screen-space clipping. For dungeons with many actors, a dedicated
sprite manager with Z-buffered projection would improve ergonomics.

---

### ❌ TODO — Textured Floor/Ceiling Per-Pixel Casting
**Source**: features/raycaster.md — Feature Gaps #2

Floor/ceiling currently support flat color. No per-pixel texture coordinate generation
for textured floors (required for DOOM-style rendering). Suggested API:
```lua
local floorRows = raycaster:castFloor(px, py, angle, fov, screenW, screenH)
-- returns array of {texU, texV} per screen column per floor row
```

---

### ❌ TODO — Document Rust-Internal Types
**Source**: features/raycaster.md — Structural Issues

`ColumnBatch`, `Segment`, and `DepthBuffer` exist as Rust types but appear to have no
Lua binding. Either expose them or explicitly document them as "Rust internals."

---

## Performance

### 🔇 LOW — Performance optimizations not meaningfully relevant
DDA raycaster is already near-optimal for 2D grid traversal. The bottleneck for retro-FPS
is GPU draw call count for wall columns and sprite batching, not the DDA logic itself.
Optimize GPU slice submission before revisiting raycaster Rust code.
