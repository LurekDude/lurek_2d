# `camera` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Lua API** | `luna.graphics.setCamera()` / `luna.graphics.newCamera2D()` (via `src/lua_api/sprite_api.rs`) |
| **Source** | `src/camera/mod.rs`, `camera.rs`, `viewport.rs`, `viewport_scale.rs` |
| **Rust Tests** | `tests/unit/camera_tests.rs` — 15 tests |
| **Lua Tests** | None dedicated (camera math exercised in `tests/lua/integration/test_math_graphics.lua`) |
| **Status** | Implemented — Full |

## Summary

The `camera` module provides camera and virtual-resolution types for 2D rendering.

[`Camera`] is the original flat-API camera stored in `SharedState` and used by
`luna.graphics.setCamera()`.  It holds a world-space position, uniform zoom, and rotation,
and exposes `view_matrix()` that combines these into a `Mat3` ready for the GPU renderer.

[`Camera2D`] is the Phase 24 addition: a full-featured camera with smooth-follow lerp,
dead-zone rectangle, clamped world bounds, screen-shake, and a target position queue.
It is created from Lua via `luna.graphics.newCamera2D(w, h)`.

[`Viewport`] maps a fixed game resolution onto an arbitrary window size using
[`ScaleMode`]: `Letterbox` (black bars), `Stretch` (non-uniform fill), or `PixelPerfect`
(integer-only scale for crisp pixel art).  `resize(window_w, window_h)` updates the
scale and offset; `get_scale()` / `get_offset()` query the result.

[`ViewportScale`] extends `Viewport` by also computing `scaled_width` / `scaled_height`,
i.e. the game area in window pixels, for integration with the automatic graphics transform
stack.

## Architecture Note

`camera` was extracted from `src/graphics/` during the graphics-module-split session
(CPD-1 Option C decision; see `work/graphics-module-split/reports/camera-decision.md`).

`SharedState` in `src/engine/shared_state.rs` holds a `Camera` field, creating an
acknowledged Baseline→Tier 1 soft coupling.  This coupling is intentional and documented
as an exception: `Camera` is a pure value type with no Tier 1 behaviour, and moving it
to Baseline would require shipping camera logic in the engine substrate.  Future work may
introduce a camera trait in `engine` to formalise the boundary.

The module imports only from `crate::math` (`Vec2`, `Mat3`, `Rect`).

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Public re-exports: `Camera`, `Camera2D`, `ScaleMode`, `Viewport`, `ViewportScale` |
| `camera.rs` | `Camera` (flat API) and `Camera2D` (smooth-follow, shake, bounds) |
| `viewport.rs` | `ScaleMode` enum and `Viewport` struct |
| `viewport_scale.rs` | `ViewportScale` struct with scaled-dimension tracking |

## Key Types

| Type | Kind | Module | Description |
|------|------|--------|-------------|
| `Camera` | struct | `camera.rs` | Flat camera: position, zoom, rotation, `view_matrix()` |
| `Camera2D` | struct | `camera.rs` | Advanced camera: smooth follow, dead zone, bounds clamping, screen-shake |
| `Viewport` | struct | `viewport.rs` | Virtual-resolution mapping with `ScaleMode` |
| `ScaleMode` | enum | `viewport.rs` | `Letterbox` / `Stretch` / `PixelPerfect` |
| `ViewportScale` | struct | `viewport_scale.rs` | Extended viewport that tracks scaled content dimensions |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `luna.graphics.setCamera(cam)` | Sets the active flat `Camera` for the next draw pass |
| `luna.graphics.getCamera()` | Returns the current `Camera` |
| `luna.graphics.newCamera2D(w?, h?)` | Creates a new `Camera2D` object |
| `cam2d:setTarget(x, y)` | Sets the smooth-follow target position |
| `cam2d:setDeadZone(w, h)` | Sets the dead-zone rectangle (camera only moves outside this) |
| `cam2d:setBounds(x, y, w, h)` | Clamps the camera within world bounds |
| `cam2d:shake(intensity, duration)` | Applies a screen-shake effect |
| `cam2d:update(dt)` | Advances smooth follow and shake |
| `cam2d:getViewMatrix()` | Returns the `Mat3` view transform |
