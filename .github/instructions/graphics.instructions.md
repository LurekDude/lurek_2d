---
applyTo: "src/graphics/**"
---

# Graphics Module Instructions

`src/graphics/` owns the GPU rendering pipeline: wgpu-backed `GpuRenderer`, the `DrawCommand` queue, texture management, color types, sprites, and camera transforms. All rendering goes through `DrawCommand` — never submit GPU work directly from Lua closures.

## Core Rules

- **Draw command queue pattern**: Lua pushes `DrawCommand` variants during `luna.draw()`; `GpuRenderer::render_frame()` processes them after the callback returns. Never render inside a Lua closure.
- **GPU rendering (primary)**: wgpu → `wgpu::Surface` → `GpuRenderer::render_frame()` → swapchain present. No CPU pixel buffer.
- **Draw types module**: `renderer.rs` contains shared draw types (`DrawCommand`, `DrawMode`, `BlendMode`, `TextureData`, etc.) used by `GpuRenderer` and the Lua API.
- **Color values**: `Color` stores RGBA as `f32` in `[0.0, 1.0]` range. Convert to/from `u8` via `Color::from_u8()` / `Color::to_u8()`
- **Premultiplied alpha**: textures loaded via `image` crate must have alpha premultiplied before upload to `wgpu::Texture`
- **Bitmap font**: text is rendered via the built-in 5×7 pixel font — no external font dependency

## Layer / Boundary Rules

- `graphics/` must NOT import from `physics/`, `audio/`, `input/`, or `timer/`
- `graphics/` may import from `math/` for `Vec2`, `Mat3`, `Rect`
- `DrawCommand` enum is defined in `mod.rs` — all draw call types are variants there
- `TextureData` is stored in `SharedState.textures: Vec<TextureData>` — `Texture` struct holds only an id + dimensions

## Compliance

- New `DrawCommand` variants must be handled in `GpuRenderer::render_frame()` — no `_ => {}` catch-all that silently ignores new variants
- GPU buffer writes use `bytemuck` for safe `Pod` casts — never use raw pointer arithmetic
- Camera transforms are applied via the transform stack (`PushTransform`/`PopTransform`/`Translate`/`Rotate`/`Scale` variants)

## Avoid

- Allocating new GPU buffers per frame — reuse renderer-owned vertex/index buffers
- Calling winit or wgpu surface methods from inside `graphics/` — that belongs in `engine/app.rs`
- Using `image::DynamicImage` beyond the load step — convert to `TextureData` and upload immediately
