# raycaster — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/raycaster.md`
**Files**: DDA 2D grid raycaster for Wolfenstein-style pseudo-3D

## Purpose

DDA-based 2D grid raycaster for retro FPS and dungeon crawlers. Produces RayHit results (distance, texture coord, hit position, side) that Lua scripts render as screen columns via `luna.graphics` fill/quad calls. Satisfies A-03 (2D graphics only) — pseudo-3D via 2D draw calls.

## Current Feature Summary

- `Raycaster2D`: mutable u32 grid, DDA traversal
- `RayHit`: per-column result (perpendicular distance, raw distance, cell value, side, tex_u, hit position)
- `castRay()` — single ray; `castRays()` — fan cast; `castRaysFlat()` — flat array
- `lineOfSight()` — boolean LOS check
- `projectSprite()` — project world-space sprite to screen
- `projectColumn()` — distance to wall height conversion
- `distanceShade()` — distance-based brightness falloff
- Fisheye correction (perpendicular distance)
- Cell values: 0=empty, >0=wall (multi-texture via value)

**Rust-only extension types (NOT exposed to Lua):**
- `ColumnBatch` — screen-width rendering state array
- `DoorManager` — animated doors with state machine
- `HeightMap` — per-cell floor/ceiling heights
- `DepthBuffer` — 1D depth per column
- `PointLight` — position, radius, intensity, color
- `SpriteProjection` — sprite screen projection data
- `Segment` — line segments for geometry raycasting

## Feature Gaps

1. **CRITICAL: Extension types not Lua-exposed**: DoorManager, HeightMap, DepthBuffer, PointLight, ColumnBatch all exist in Rust but users can't access them from Lua. This is the biggest gap — the module advertises features it doesn't deliver to scripters.
2. **No textured floor/ceiling**: Only wall columns are cast. Floor and ceiling rendering requires additional ray projection (common in Wolfenstein/DOOM-style engines).
3. **No transparent walls**: All walls are fully opaque. Transparent/translucent walls require additional ray continuation.
4. **No sprite billboarding system**: `projectSprite()` projects one sprite. No batch sprite management with depth sorting and clipping.
5. **No half-height walls / variable wall heights**: All walls are full height. HeightMap exists in Rust but isn't Lua-exposed.
6. **No column batch rendering**: ColumnBatch exists in Rust but Lua scripts must render columns one by one.
7. **No door system in Lua**: DoorManager exists in Rust but isn't accessible. Doors are a core FPS mechanic.

## Structural Issues

- **Rust implementation exceeds Lua API surface**: The module has far more capability in Rust than what's accessible from Lua. This is half-done. Either expose the extension types or document them as internal-only.
- **No GPU dependency**: Correct — outputs plain data, Lua handles rendering. Good architecture.
- **Geometry raycaster (Segment) hidden**: An alternative raycaster for arbitrary line segments exists but isn't exposed. Different use case from grid DDA.

## Suggestions

1. **Expose extension types to Lua** (critical): Every Rust type should have a Lua binding:
   - `luna.raycaster.newDoorManager()` → `doorMgr:addDoor(x, y, speed)`, `doorMgr:update(dt)`, `doorMgr:getDoorState(x, y)`
   - `luna.raycaster.newHeightMap(w, h)` → `hm:setFloor(x, y, h)`, `hm:setCeiling(x, y, h)`
   - `luna.raycaster.newDepthBuffer(screenWidth)` → `db:test(x, depth)`, `db:set(x, depth)`
   - `luna.raycaster.newLight(x, y, radius, intensity, r, g, b)` → lighting support
2. **Add column batch rendering helper**: `raycaster:castAndBatch(ox, oy, angle, fov, screenW, screenH)` → returns complete render-ready column data including wall heights, shade, and texture coordinates.
3. **Add textured floor/ceiling casting**: `raycaster:castFloor(px, py, angle, fov, screenW, screenH)` → per-pixel floor/ceiling texture coordinates.
4. **Add sprite manager**: `raycaster:addSprite(id, x, y, texture)` / `raycaster:projectSprites(px, py, angle, fov, screenW, depthBuffer)` → batch sprite projection with depth sorting.
5. **Document the Rust-only types**: If some types are intentionally internal, document them as "Rust internals, not planned for Lua."

## Competitor Comparison

No competitor 2D Lua engine has a built-in raycaster. This is unique to Luna2D.

| Feature | Luna2D | Love2D | Solar2D | Bevy | Custom raycasters |
|---|---|---|---|---|---|
| DDA grid | ✅ | ❌ | ❌ | ❌ | ✅ |
| Fan cast | ✅ | N/A | N/A | N/A | ✅ |
| Line-of-sight | ✅ | N/A | N/A | N/A | ✅ |
| Sprite projection | ✅ (single) | N/A | N/A | N/A | ✅ (batch) |
| Doors | ✅ (Rust only!) | N/A | N/A | N/A | ✅ |
| Floor/ceiling | ❌ | N/A | N/A | N/A | ✅ |
| Variable heights | ✅ (Rust only!) | N/A | N/A | N/A | ✅ |
| Lighting | ✅ (Rust only!) | N/A | N/A | N/A | ✅ |

The raycaster module is a unique feature. But the gap between Rust capabilities and Lua API surface undermines its value.

## Priority

**HIGH** — Exposing existing Rust types to Lua is the #1 priority. The code already exists — it just needs bindings. This is likely the highest-ROI task in the entire engine.
