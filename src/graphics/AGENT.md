# `graphics` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                              |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | `luna.graphics`                                              |
| **Source**     | `src/graphics/`                                              |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                           |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline |

## Purpose

The graphics module owns the entire GPU rendering pipeline for Luna2D — from the high-level draw calls that Lua scripts issue through `luna.graphics.*`, through a deferred `DrawCommand` queue that batches all rendering work, to the wgpu GPU backend that executes those commands against the swapchain. No other module writes pixels to the screen; everything visual flows through this module.

## Source Files

| File               | Purpose                                                              |
|--------------------|----------------------------------------------------------------------|
| `canvas.rs`        | Off-screen render target metadata (`Canvas` struct with width/height) |
| `color.rs`         | Orphaned `Color` struct — not declared in `mod.rs`; active `Color` lives in `src/math/color.rs` |
| `decal_surface.rs` | Persistent surface descriptor for stamping decal textures            |
| `draw_layer.rs`    | Z-ordered draw callback queue for controlling render order           |
| `font.rs`          | TTF/OTF font loading via fontdue, glyph rasterization, shelf-packed RGBA atlas |
| `gpu_renderer.rs`  | GPU-accelerated 2D renderer backed by wgpu; processes DrawCommand queue, manages GPU resources and render passes |
| `image_effect.rs`  | Per-image shader-effect pass descriptor for the draw command pipeline |
| `mesh.rs`          | Custom geometry mesh with per-vertex position, UV, and color data    |
| `nine_slice.rs`    | Nine-slice (9-patch) image rendering for scalable UI elements        |
| `renderer.rs`      | `DrawCommand` enum (45+ variants), `BlendMode`, `DrawMode`, `TextAlign`, `StencilMode`, `TextureData`, and related types |
| `shader.rs`        | Custom WGSL shader support — source validation via naga, uniform variables, per-shader pipeline |
| `shape.rs`         | `CompoundShape` builder and `ShapeCommand` sub-enum for multi-primitive vector drawing |
| `sprite.rs`        | `Sprite` struct — texture handle + transform + tint color wrapper    |
| `sprite_batch.rs`  | Sprite batching for efficient rendering of many sprites sharing one texture |
| `sprite_sheet.rs`  | Grid-based sprite sheet with directional support and named frame groups |
| `texture.rs`       | Texture loading (PNG/JPEG/BMP), premultiplied-alpha conversion, and `TextureKey` handle |
| `texture_atlas.rs` | CPU-side bin-packing texture atlas using shelf algorithm              |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/graphics.md`](../../specs/graphics.md)

_Update both this file **and** `specs/graphics.md` whenever source files, public types, or Lua bindings change._
