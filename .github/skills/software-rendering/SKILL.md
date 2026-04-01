---
name: software-rendering
description: "Load this skill when working on the Luna2D graphics pipeline: wgpu GPU rendering, DrawCommand queue, texture management, or camera transforms. Skip it for physics, audio, or Lua API design."
---

# GPU Rendering — Luna2D Engine

## Load When

- Modifying the rendering pipeline in `src/graphics/`
- Adding new `DrawCommand` variants
- Working with `GpuRenderer` or wgpu pipeline objects
- Implementing texture loading or sprite rendering
- Modifying camera transforms
- Working on the winit `ApplicationHandler` event loop in `src/engine/app.rs`

## Owns

- wgpu GPU rendering pipeline patterns
- DrawCommand enum design and processing
- `GpuRenderer::render_frame()` → wgpu swapchain present flow
- Texture loading via `image` crate, upload to `wgpu::Texture`
- Camera matrix transforms
- Color type conversions
- Transform stack (`PushTransform` / `PopTransform`) processing

## Does Not Cover

- Physics visualization → `Physicist` agent handles collision debug rendering
- UI layout systems → not implemented in Luna2D
- Shared draw types in `renderer.rs` (DrawCommand, BlendMode, etc.)

## Live Repository Contracts

- `src/graphics/gpu_renderer.rs` — active render loop, `GpuRenderer`, DrawCommand processing
- `src/graphics/renderer.rs` — shared draw types (DrawCommand, BlendMode, etc.)
- `src/graphics/mod.rs` — `DrawCommand` enum definition
- `src/graphics/texture.rs` — image loading, GPU texture management
- `src/graphics/camera.rs` — Camera struct, view matrix
- `src/graphics/color.rs` — Color struct and conversions
- `src/engine/app.rs` — winit 0.30 `ApplicationHandler`, `Arc<Window>`, `Surface<'static>`

## Decision Rules

- **GPU primary**: All rendering through `GpuRenderer` (wgpu) — `GpuRenderer::render_frame()` submits draw calls, presents swapchain. No CPU pixel buffer in the primary path.
- **DrawCommand queue**: Lua `luna.draw()` pushes commands; engine processes after callback returns — this contract is UNCHANGED from the old software renderer
- **Never render in closure**: DrawCommands are data — rendering happens in the engine loop
- **Texture caching**: Load images once via `image` crate, upload to GPU texture, reuse by ID
- **Color boundary**: Convert Luna `Color` to wgpu/WGSL-compatible `[f32; 4]` at the rendering boundary only
- **Camera applies globally**: Camera transform multiplied into all world-space draw commands
- **Transform stack**: `PushTransform`/`PopTransform` variants manage a matrix stack; `Translate`, `Rotate`, `Scale` push incremental transforms
- **Coordinate system**: Origin at top-left, Y increases downward (screen coordinates)
- **winit pattern**: `app.rs` implements `winit::application::ApplicationHandler`; window is `Arc<Window>` to satisfy `Surface<'static>` lifetime
- **New DrawCommand variants**: `PushTransform`, `PopTransform`, `Translate { x, y }`, `Rotate { angle }`, `Scale { sx, sy }`, `Arc { mode, x, y, radius, angle1, angle2, segments }`, `DrawImageEx { ... }`, `DrawQuad { ... }`, `Polyline { points }`
