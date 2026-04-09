# `camera` — Agent Reference

| Property       | Value                                    |
|----------------|------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems          |
| **Status**     | Implemented — Full                       |
| **Lua API**    | `lurek.camera`                            |
| **Source**      | `src/camera/`                            |
| **Rust Tests** | `tests/rust/unit/camera_tests.rs`        |
| **Lua Tests**  | `tests/lua/unit/test_camera.lua`         |
| **Architecture** | —                                      |

## Purpose

The `camera` module provides camera and viewport types for 2D rendering. It is a Tier 1 engine module extracted from `src/graphics/` during the graphics-module-split session; it depends only on `crate::math` (Vec2, Mat3, Rect) and never imports wgpu, winit, or any other engine module. `SharedState` holds a `Camera` field accessed by the GPU renderer each frame to apply the view transform to all draw commands.

## Source Files

| File                | Purpose                                                                                 |
|---------------------|-----------------------------------------------------------------------------------------|
| `mod.rs`            | Module root — declares types, viewport, viewport_scale submodules and re-exports Camera, Camera2D, ScaleMode, Viewport, ViewportScale |
| `types.rs`          | `Camera` (flat API) and `Camera2D` (smooth follow, dead zone, bounds, shake) structs    |
| `viewport.rs`       | `ScaleMode` enum and `Viewport` struct for virtual-resolution mapping                   |
| `viewport_scale.rs` | `ViewportScale` struct — `Viewport` variant with automatic scaled-dimension tracking     |

## Key Types
| Type | Location | Purpose |
|------|----------|---------|
| \Camera2D\ | \src/camera/mod.rs\ | 2D camera tracking position, zoom, and rotation |
| \Camera\ | \src/camera/mod.rs\ | Active camera state driving the view transform |
| \Viewport\ | \src/camera/mod.rs\ | Screen region mapped to a camera view |
| \ScaleMode\ | \src/camera/mod.rs\ | Enum: Fixed, Fit, Fill, Stretch scaling modes |

## Lua API Summary
| Function | Signature | Purpose |
|----------|-----------|---------|
| \lurek.camera.new\ | \(x: number, y: number) → Camera2D\ | Create a 2D camera at position |
| \lurek.camera.setPosition\ | \(cam: Camera2D, x: number, y: number) → nil\ | Move camera |
| \lurek.camera.setZoom\ | \(cam: Camera2D, zoom: number) → nil\ | Set zoom level |
| \lurek.camera.activate\ | \(cam: Camera2D) → nil\ | Set as the active render camera |
| \lurek.camera.screenToWorld\ | \(cam: Camera2D, sx: number, sy: number) → number, number\ | Convert screen coords |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/camera.md`](../../docs/specs/camera.md)

_Update both this file **and** `docs/specs/camera.md` whenever source files, public types, or Lua bindings change._
