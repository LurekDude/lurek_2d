# `render` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                              |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | `lurek.graphic` (66 functions, 7 UserData types)             |
| **Source**     | `src/render/`                                                |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                           |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline |

## Summary

`src/render/` is the authoritative GPU rendering pipeline for Lurek2D. It owns every
stage from the high-level draw calls Lua scripts issue through `lurek.graphic.*`, through
the deferred `RenderCommand` queue that batches all rendering work, to the wgpu GPU
backend that executes those commands against the swapchain. No other module writes pixels
to the screen; everything visual flows through this module.

The module is built around a **deferred command queue** architecture: during `lurek.draw()`
Lua pushes `RenderCommand` variants into a `Vec<RenderCommand>` stored in `SharedState`.
After the Lua callback returns, `GpuRenderer::render_frame()` processes the queue in one
GPU encoder pass. Lua never touches the GPU directly — it constructs a declarative list of
rendering intent, and the renderer has full visibility over the draw list to minimise
pipeline state switches before any GPU work begins.

All GPU resources (textures, fonts, canvases, shaders, meshes, sprite batches, and compound
shapes) are identified by typed `SlotMap` keys that are opaque to Lua. `LuaImage`,
`LuaFont`, `LuaCanvas`, `LuaShader`, `LuaMesh`, `LuaSpriteBatch`, and `LuaShape` UserData
types are thin wrappers around the corresponding `*Key` handles; the actual `wgpu::Texture`
objects and GPU pipelines live inside `GpuRenderer`.

> **Source boundary:** `src/render/` is the canonical home for the GPU pipeline. The legacy
> `src/graphics/` directory contains only `gpu_renderer.rs` as a transitional artefact; it
> will be merged into `src/render/` and removed in a future cleanup. All new GPU work goes
> in `src/render/`.

## Architecture

```
lurek.graphic.* (Lua API — src/lua_api/render_api.rs)
  │  66 functions, 7 UserData types
  │
  ▼
RenderCommand queue  (SharedState::render_commands)
  │  45+ variants: shapes, images, text, state, transforms, stencil, post-fx
  │
  ▼
GpuRenderer  (src/render/gpu_renderer.rs — wgpu backend)
  ├── wgpu Device + Queue + Surface (swapchain)
  ├── Pipeline cache (5 blend modes × wireframe, stencil, color-mask, custom shaders)
  ├── Depth/stencil texture  (Depth24PlusStencil8)
  ├── GPU resource pools
  │     ├── gpu_textures         SlotMap<TextureKey, GpuTexture>
  │     ├── canvas_gpu_textures  SlotMap<CanvasKey, GpuTexture>
  │     └── font_atlas_textures  SlotMap<FontKey, GpuTexture>
  ├── Vertex buffers (pre-allocated — 131K color verts, 16K texture verts)
  └── Per-frame transform stack (Mat3)
```

## Source Files

| File                | Purpose                                                               |
|---------------------|-----------------------------------------------------------------------|
| `canvas.rs`         | Off-screen render target metadata (`Canvas` struct with width/height) |
| `decal_surface.rs`  | Persistent surface descriptor for stamping decal textures             |
| `draw_layer.rs`     | Z-ordered draw callback queue for controlling render order            |
| `font.rs`           | TTF/OTF font loading via fontdue, glyph rasterization, shelf-packed RGBA atlas |
| `gpu_renderer.rs`   | wgpu-backed 2D renderer; processes `RenderCommand` queue, manages GPU resources and render passes |
| `image_effect.rs`   | Per-image shader-effect pass descriptor for the draw command pipeline |
| `mesh.rs`           | Custom geometry mesh with per-vertex position, UV, and color data     |
| `nine_slice.rs`     | Nine-slice (9-patch) image rendering for scalable UI elements         |
| `renderer.rs`       | `RenderCommand` enum (45+ variants), `BlendMode`, `DrawMode`, `TextAlign`, `StencilMode`, `TextureData`, and related types |
| `shader.rs`         | Custom WGSL shader support — source validation via naga, uniform variables, per-shader pipeline |
| `shape.rs`          | `CompoundShape` builder and `ShapeCommand` sub-enum for multi-primitive vector drawing |
| `sprite.rs`         | `Sprite` struct — texture handle + transform + tint color wrapper     |
| `sprite_batch.rs`   | Sprite batching for efficient rendering of many sprites sharing one texture |
| `sprite_sheet.rs`   | Grid-based sprite sheet with directional support and named frame groups |
| `texture.rs`        | Texture loading (PNG/JPEG/BMP), premultiplied-alpha conversion, and `TextureKey` handle |
| `texture_atlas.rs`  | CPU-side bin-packing texture atlas using the shelf algorithm           |
| `camera/`           | `Camera` struct — viewport offset, zoom, and world-to-screen projection |
| `effect/`           | Post-processing effect descriptors consumed by the `postfx` module    |
| `light/`            | `LightWorld` and occlusion geometry for 2D soft-shadow lighting       |
| `color.rs` | — |
| `mod.rs` | — |

## Key Types

| Type              | Description                                                                          |
|-------------------|--------------------------------------------------------------------------------------|
| `RenderCommand`   | 45+ variant enum encoding every drawable operation; enqueued by Lua, consumed by `GpuRenderer::render_frame()`. |
| `GpuRenderer`     | Owns the wgpu device, surface, pipeline cache, and GPU resource pools; executes the `RenderCommand` queue once per frame. |
| `Canvas`          | Logical metadata for an off-screen render target; GPU-side texture managed by `GpuRenderer`. |
| `Font`            | TTF/OTF font backed by fontdue; owns the CPU-side glyph shelf-atlas and uploads to a GPU atlas texture on demand. |
| `Shader`          | Custom WGSL shader with named uniform variables; validated at load time via naga and cached as a `wgpu::RenderPipeline`. |
| `Mesh`            | Indexed geometry with per-vertex position, UV, and color; drawn with `DrawMesh`. |
| `SpriteBatch`     | Pre-sorted list of `BatchEntry` quads sharing one texture; rendered in a single draw call. |
| `CompoundShape`   | Builder for multi-primitive vector shapes composed of `ShapeCommand` sub-operations. |
| `BlendMode`       | Five pre-built pipeline blend modes: `Alpha`, `Additive`, `Subtract`, `Multiply`, `Replace`. |
| `TextureData`     | CPU-side `RgbaImage` pixel buffer tagged with its origin path for deduplication. |

## Lua API Summary

Registered by `src/lua_api/render_api.rs` as `lurek.graphic`.

| Category          | Key functions                                                                        |
|-------------------|--------------------------------------------------------------------------------------|
| **Images**        | `newImage`, `draw`, `drawScaled`, `drawRotated`, `drawSub`, `getWidth`, `getHeight`  |
| **Text**          | `newFont`, `print`, `printf`, `setFont`, `setNewFont`, `getTextWidth`                |
| **Shapes**        | `rectangle`, `circle`, `polygon`, `line`, `point`, `newShape`, `drawShape`           |
| **Canvas**        | `newCanvas`, `setCanvas`, `getCanvas`, `drawCanvas`                                  |
| **Shaders**       | `newShader`, `setShader`, `sendShaderUniform`                                        |
| **Mesh**          | `newMesh`, `drawMesh`                                                                |
| **SpriteBatch**   | `newSpriteBatch`, `addSprite`, `flushBatch`, `drawBatch`                             |
| **Color**         | `setColor`, `setBackgroundColor`, `getColor`                                         |
| **Transforms**    | `push`, `pop`, `translate`, `rotate`, `scale`, `shear`, `origin`                    |
| **State**         | `setBlendMode`, `setDepthMode`, `setStencilMode`, `setWireframe`, `setScissor`       |
| **Screenshots**   | `saveScreenshot`                                                                     |

For full parameter signatures and usage examples see [`docs/specs/graphics.md`](graphics.md),
which documents the same `lurek.graphic.*` API surface in detail.

## Cross-Module References

| Module       | Relationship                                                                         |
|--------------|--------------------------------------------------------------------------------------|
| `runtime`    | `SharedState` holds `render_commands: Vec<RenderCommand>` and the typed `SlotMap` resource pools. |
| `math`       | `Color`, `Vec2`, `Mat3`, `Rect` are imported from `src/math/` and used throughout render types. |
| `image`      | `src/image/` provides `ImageData` (raw pixel buffer) used by `TextureData`. |
| `camera`     | `src/render/camera/` — `Camera` offsets the transform stack; integrated via `SetCamera` command. |
| `postfx`     | `src/postfx/` drives multi-pass effects using `BeginPostFx`/`EndPostFx`/`ApplyPostFx` commands. |
| `particle`   | `src/particle/` pushes `DrawParticleSystem` commands into the render queue.          |
| `light`      | `src/render/light/` manages `LightWorld` and occlusion geometry for the shadow pass. |
