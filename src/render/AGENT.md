# `render` — Agent Reference

| Property         | Value                                                                         |
|------------------|-------------------------------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                                               |
| **Status**       | Implemented — Full                                                            |
| **Lua API**      | `lurek.graphic` (66 functions, 7 UserData types)                              |
| **Source**       | `src/render/`                                                                 |
| **Rust Tests**   | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**    | `tests/lua/unit/test_graphics.lua`                                            |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline               |

## Purpose

`src/render/` is the authoritative GPU rendering pipeline for Lurek2D. It owns every
stage from the high-level draw calls Lua scripts issue through `lurek.graphic.*`, through
a deferred `RenderCommand` queue, to the wgpu GPU backend that executes those commands
against the swapchain. No other module writes pixels to the screen; everything visual flows
through this module. The Lua bridge lives in `src/lua_api/render_api.rs`.

## Source Files

| File               | Purpose                                                              |
|--------------------|----------------------------------------------------------------------|
| `mod.rs`           | Module root — declares all submodules and re-exports public types.   |
| `canvas.rs`        | `Canvas` — off-screen render target metadata (width, height).        |
| `color.rs`         | Legacy `Color` file; canonical `Color` lives in `src/math/color.rs`. |
| `decal_surface.rs` | `DecalSurface` — persistent descriptor for stamping decal textures.  |
| `draw_layer.rs`    | `DrawLayer` — Z-ordered draw callback queue.                         |
| `font.rs`          | `Font` — TTF/OTF font via fontdue, glyph rasterization, shelf atlas. |
| `gpu_renderer.rs`  | `GpuRenderer` — wgpu device, surface, pipeline cache, resource pools.|
| `image_effect.rs`  | `ShaderPassDescriptor` — per-image shader-effect pass descriptor.    |
| `mesh.rs`          | `Mesh`, `MeshVertex`, `MeshDrawMode` — indexed geometry types.       |
| `nine_slice.rs`    | `NineSlice`, `Patch` — 9-patch image rendering for scalable UI.      |
| `renderer.rs`      | `RenderCommand` (45+ variants), `BlendMode`, draw enums, `TextureData`. |
| `shader.rs`        | `Shader`, `UniformValue` — custom WGSL shader with naga validation.  |
| `shape.rs`         | `CompoundShape`, `ShapeCommand` — batched vector shape builder.      |
| `sprite.rs`        | `Sprite` — texture + transform + tint wrapper.                       |
| `sprite_batch.rs`  | `SpriteBatch` — shared-texture quad batch for one GPU draw call.     |
| `sprite_sheet.rs`  | `SpriteSheet` — grid animation with named frame groups.              |
| `texture.rs`       | `Texture` — PNG/JPEG/BMP loader with `TextureKey` handle.            |
| `texture_atlas.rs` | `TextureAtlas` — shelf-algorithm CPU-side atlas packing.             |

## Full Specification

Full spec: [`docs/specs/render.md`](../../../docs/specs/render.md)
