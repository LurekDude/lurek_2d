---
name: gpu-programming
description: "Load this skill when working on wgpu setup, RenderCommand flow, render passes, textures, shaders, or GPU validation errors. Skip it for font internals, Lua API design, or physics."
---
# gpu-programming

## Mission
- Own wgpu rendering flow, RenderCommand behavior, and shader integration.

## When To Load
- Change device or surface setup.
- Add or modify RenderCommand behavior.
- Work on textures, canvases, or shaders.
- Diagnose GPU validation errors.

## When To Skip
- Font internals.
- Lua API design.
- Physics logic.

## Domain Knowledge
- wgpu 22 is the only renderer backend (binding constraint B-02). No OpenGL path, no Vulkan-direct path, no Metal-direct path. When a wgpu 22 API limitation forces a workaround, document it in a comment near the workaround rather than hiding it.
- The `RenderCommand` enum in `src/render/renderer.rs` is the contract between game logic and the GPU. `on_render` callbacks push commands into `SharedState::pending_commands` during `lurek.draw()` / `lurek.draw_ui()`; after all callbacks return, `GpuRenderer::render_frame()` in `src/render/gpu_renderer.rs` processes the queue, batches compatible draw calls, and presents the swapchain surface. Never call wgpu submission APIs outside `src/render/`.
- RenderPass count rule: one RenderPass per phase (opaque → transparent → ui → post-process). Adding a mid-frame RenderPass for a single effect is almost always wrong — batch the draw into the existing transparent pass instead. Each extra RenderPass forces a GPU pipeline flush costing 0.5–2 ms on integrated hardware.
- Bind-group management is the most common GPU performance issue. Group textures by frequency-of-change: per-frame uniforms in group 0, per-batch textures in group 1, per-draw data in group 2. A unique bind-group switch costs ~0.05 ms on integrated GPU — that budget matters at 60 FPS.
- Buffer upload rule: upload via `wgpu::Queue::write_buffer` only when data changed since the last frame. Maintain a dirty flag or hash on the CPU side to skip redundant uploads. A frame with 100 unchanged sprites should have zero buffer writes for those sprites.
- Shader compilation failures are fatal at startup. Keep the wgpu validation layer enabled in debug builds (`WGPU_VALIDATION=1`). Check `src/render/gpu_renderer.rs` startup code for how validation is configured. Never disable validation to silence a startup error without fixing the root cause.
- Pipeline state objects (PSOs) are expensive to create. Create all pipelines at startup inside `GpuRenderer::new()` and cache them in the renderer struct. Never call `device.create_render_pipeline()` inside a per-frame render path.
- Texture format convention: all game textures must use `wgpu::TextureFormat::Rgba8UnormSrgb` unless explicitly documented otherwise. A format mismatch between texture and bind-group layout produces black output on some GPUs and a validation error on others — both symptoms are confusing to diagnose.
- Canvas (`src/render/canvas.rs`) is the mechanism for render-to-texture and post-processing. A `Canvas` stores logical dimensions; `GpuRenderer` manages the actual GPU texture. To add a post-processing pass: create a `Canvas` at the desired resolution, render scene into it via a `RenderCommand::DrawToCanvas`, apply a shader effect via `src/render/postfx_pipeline.rs`, then composite the canvas back to the screen. See `content/games/showcase/postfx_demo/` for the full pattern.
- Sprite batching happens automatically in `render_frame()` when consecutive `RenderCommand::DrawSprite` commands share the same texture, blend mode, and shader. Break the batch only when necessary; sorting draw commands by texture before pushing them to `pending_commands` is the simplest way to maximize batch sizes and reduce bind-group switches.
- `src/render/shader.rs` exposes user WGSL shaders with a uniform variable table. Auto-uniform convention: declare a uniform name in Lua, the engine binds the value each frame before the draw call. When adding a new auto-uniform, add it to both the WGSL binding slot and the Rust `UniformTable` in `shader.rs`, then update the binding index in the pipeline layout.
- Draw layer ordering is controlled by `src/render/draw_layer.rs`. Layers determine which RenderPass phase a command lands in. If a new draw type needs to render in a specific phase (e.g., always on top of everything), assign it the correct layer enum variant — do not rely on push order.
- After render changes, run `cargo test --test graphics_tests` and check `tests/evidence_out/` for screenshot regressions. Cargo test pass alone does not confirm visual correctness.
- Engine is 2D-only (binding constraint A-03). Any proposal involving perspective projection, depth buffer, or 3D scene graph is out of scope. Raycasting and isometric effects still use 2D draw calls.
## Companion File Index
- None.

## References
- src/render/
- src/lua_api/render_api.rs
- docs/specs/render.md
- tests/
