---
name: camera-transforms
description: "Load this skill when implementing or modifying Camera transform logic, world↔screen space conversion, camera integration into the renderer, or Lua camera bindings. Skip it for non-camera graphics work, physics, audio, or input handling."
---

# Camera Transforms — Luna2D Engine

## Load When
- Wiring `Camera` into `SharedState` or `execute_commands()`
- Implementing `luna.graphics.setCamera` / `getCamera` Lua bindings
- Converting world space ↔ screen space coordinates
- Adding camera shake, zoom, or rotation

## Owns
- `Camera` struct and `view_matrix()` construction
- Mat3 affine math for camera: translation, rotation, scale order
- World↔screen unprojection via matrix inversion
- HUD / world-space draw separation

## Does Not Cover
- General wgpu draw commands (see `software-rendering` skill)
- Lua API registration boilerplate (see `lua-api-design` skill)

## Live Repository Contracts

| File | Key fact |
|---|---|
| `src/graphics/camera.rs` | `Camera { position: Vec2, zoom: f32, rotation: f32 }` |
| `src/graphics/camera.rs` | `view_matrix()` = `scale * rotation * translation`; position is negated in translation |
| `src/math/mat3.rs` | `from_translation`, `from_rotation`, `from_scale`, `*` multiply |
| `src/math/vec2.rs` | `Vec2::ZERO`, `Vec2::splat`, standard ops |
| `src/graphics/renderer.rs` | `execute_commands()` — camera transform applied here per vertex before rasterizing |
| `src/lua_api/mod.rs` | `SharedState` — add `pub camera: Camera` to share across API and engine loop |

> **Current status**: `Camera` is defined but NOT yet in `SharedState` and NOT yet applied in `execute_commands()`. All draw calls currently use `Transform::identity()`.

## Decision Rules

**View matrix order** — right-to-left application:
1. Translate: negate `position` so camera position maps to origin
2. Rotate: `camera.rotation` radians (Y-down: positive = clockwise)
3. Scale: `camera.zoom` (uniform)

**Zoom semantics**: `zoom > 1.0` → objects appear larger (zoom in); `zoom < 1.0` → zoom out.
Zoom is centered on the **viewport center**, not the world origin — bias position by `viewport_size * 0.5 / zoom` when integrating.

**World → screen**: `screen_pt = view_matrix() * world_pt`
**Screen → world (unproject)**: `world_pt = view_matrix().inverse() * screen_pt` — never compute the inverse manually.

**Applying to DrawCommands**: multiply each world-space vertex by `view_matrix()` inside `execute_commands()`, not inside individual `DrawCommand` variants.

**HUD elements**: reset camera to `Camera::default()` (identity) before drawing HUD. Alternatively add a `DrawCommand::SetCamera(Camera)` variant to toggle mid-frame.

**Camera shake** (Lua pattern — exponential decay):
> See [example.lua](example.lua) for the decision rules code example.
Apply the offset each frame during `luna.update(dt)`; draw HUD after calling `luna.graphics.resetCamera()`.
