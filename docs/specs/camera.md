# `camera` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.camera` |
| **Source** | `src/camera/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The camera module owns 2D camera math and virtual viewport mapping. It provides the simple Camera type used for view transforms, the richer Camera2D type used for follow behavior and coordinate conversion, and the viewport helpers that map a logical game resolution onto an actual window.

This module stays on the CPU side of the engine. It can produce transform-stack render commands and screen-to-world conversions, but it does not own live window state, renderer internals, or scene logic. Other systems decide what the camera follows and when it moves; camera is responsible for the math and state needed to express that behavior cleanly.

**Scope boundary**: This module currently depends on `math`, `render`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.camera.* (Lua API — src/lua_api/camera_api.rs)
    |
    v
src/camera/mod.rs
    |- render.rs - render
    |- types.rs - types
    |- viewport.rs - viewport
    |- viewport_scale.rs - viewport_scale
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Declares the camera submodules and re-exports the public camera and viewport surface. |
| `render.rs` | Converts Camera and Camera2D state into push, translate, rotate, scale, and pop render commands. |
| `types.rs` | Defines Camera and Camera2D, including transforms, follow logic, bounds, shake, and coordinate conversion. |
| `viewport.rs` | Defines ScaleMode and Viewport for logical-resolution scaling and coordinate mapping. |
| `viewport_scale.rs` | Defines ViewportScale, a viewport helper that also tracks scaled output dimensions. |

---

## Submodules

### `camera::render`

Converts Camera and Camera2D state into push, translate, rotate, scale, and pop render commands.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `camera::types`

Defines Camera and Camera2D, including transforms, follow logic, bounds, shake, and coordinate conversion.

- **`Camera`** (struct): Basic camera with position, zoom, and rotation.
- **`Camera2D`** (struct): Full-featured 2D camera with smooth follow, dead zone, bounds clamping,

### `camera::viewport`

Defines ScaleMode and Viewport for logical-resolution scaling and coordinate mapping.

- **`ScaleMode`** (enum): Scale mode for virtual resolution mapping.
- **`Viewport`** (struct): Virtual resolution with manual transform application.

### `camera::viewport_scale`

Defines ViewportScale, a viewport helper that also tracks scaled output dimensions.

- **`ViewportScale`** (struct): Virtual resolution with automatic graphics stack management.

---

## Key Types

### Public Types

#### `Camera`

Lightweight camera state with position, zoom, rotation, and view-matrix generation.

#### `Camera2D`

Gameplay-facing 2D camera with follow targets, dead zones, look-ahead, bounds clamping, shake, and coordinate helpers.

#### `Viewport`

Logical-resolution mapper that computes scale and offset for letterbox, stretch, and pixel-perfect modes.

#### `ViewportScale`

Viewport variant that also tracks scaled pixel dimensions for transform-stack integration.

#### `ScaleMode`

Enum selecting letterbox, stretch, or pixel-perfect viewport behavior.

---

## Lua API

Exposed under `lurek.camera.*` by `src/lua_api/camera_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.camera.new` | Creates a new Camera2D with the given viewport dimensions. |

### `Camera2D` Methods

| Method | Description |
|--------|-------------|
| `camera2d:setPosition(...)` | Sets the camera's world-space position. |
| `camera2d:getPosition(...)` | Returns the camera's world-space position as x, y. |
| `camera2d:setZoom(...)` | Sets the uniform zoom factor (1.0 = natural size). |
| `camera2d:getZoom(...)` | Returns the current zoom factor. |
| `camera2d:setRotation(...)` | Sets the rotation in radians. |
| `camera2d:getRotation(...)` | Returns the rotation in radians. |
| `camera2d:setViewport(...)` | Sets the viewport rectangle in screen pixels. |
| `camera2d:getViewport(...)` | Returns the current viewport as x, y, w, h. |
| `camera2d:setBounds(...)` | Sets world-space bounds for camera clamping. |
| `camera2d:removeBounds(...)` | Removes previously set world-space bounds. |
| `camera2d:setTarget(...)` | Sets the follow target position. |
| `camera2d:clearTarget(...)` | Clears the follow target so the camera stops tracking. |
| `camera2d:setFollowSmooth(...)` | Sets the follow smooth interpolation speed (0.0 = instant snap). |
| `camera2d:setDeadZone(...)` | Sets the dead zone half-extents for camera follow. |
| `camera2d:setLookAhead(...)` | Sets the look-ahead multiplier for follow prediction. |
| `camera2d:shake(...)` | Starts a screen-shake effect. |
| `camera2d:update(...)` | Advances the camera simulation by dt seconds. |
| `camera2d:toWorld(...)` | Converts screen coordinates to world coordinates. |
| `camera2d:toScreen(...)` | Converts world coordinates to screen coordinates. |
| `camera2d:getVisibleArea(...)` | Returns the visible world area as x, y, w, h. |
| `camera2d:lookAt(...)` | Instantly moves the camera to look at the given position. |
| `camera2d:move(...)` | Translates the camera by dx, dy in world space. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.camera.
if lurek.camera then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 1 |
| `fn` (Lua API) | 23 |
| **Total** | **28** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Platform Services to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/camera/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
