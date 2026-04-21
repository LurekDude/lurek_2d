---
name: gpu-programming
description: "Load this skill when working with the Lurek2D GPU rendering pipeline: wgpu device/surface setup, RenderCommand queue, render passes, texture management, custom WGSL shaders, blend modes, canvas render-to-texture, or transform stacks. Also covers profiling GPU frame time and diagnosing wgpu validation errors. Skip it for font rasterization details, Lua API design, or physics."
---
# gpu-programming

## Mission

# GPU Programming — Lurek2D

## When To Load

- Implementing or modifying a `RenderCommand` variant
- Adding a wgpu render pipeline (new blend mode, new shader type)
- Writing or debugging custom WGSL shaders
- Texture management — loading, uploading, caching by `TextureKey`
- Canvas (render-to-texture) implementation patterns
- Diagnosing wgpu validation layer errors or GPU memory issues
- Profiling GPU frame time and draw call count

## When To Skip

- Skip it for font rasterization details, Lua API design, or physics.

## Domain Knowledge

### Owns
- wgpu device/adapter/surface setup and swapchain lifecycle
- `RenderCommand` queue lifecycle and variant dispatch
- Built-in WGSL shaders and custom user shader pipeline
- Texture upload, format selection, and deferred destruction
- Blend mode pipeline cache
- Canvas render-to-texture pattern
- Transform stack (`PushTransform` / `PopTransform`)
- GPU performance rules for integrated-GPU baseline

### wgpu Stack
> See [snippets/wgpu-stack.txt](snippets/wgpu-stack.txt) for the example.

Lurek2D targets **wgpu 22**. No raw OpenGL path exists. All rendering goes through `GpuRenderer` in `src/render/gpu_renderer.rs`.

### RenderCommand Queue Lifecycle
> See [snippets/rendercommand-queue-lifecycle.txt](snippets/rendercommand-queue-lifecycle.txt) for the example.

**Invariants:**
- Never render inside a Lua closure — push RenderCommands only
- `render_commands` is cleared at the start of each frame's draw step (step 7)
- Only one `wgpu::CommandEncoder` is created per frame in `render_frame()`

### Adding a New RenderCommand Variant
1. Add variant to `RenderCommand` enum in `src/render/renderer.rs`
2. Add execution arm in `src/render/gpu_renderer.rs` (match arm)
3. Add Lua push function in `src/lua_api/render_api.rs`
4. Add Lua BDD test in `tests/lua/unit/test_render.lua`

### Shader Authoring (WGSL)
### Built-In Shaders

Two WGSL shaders are embedded in the binary:

| Shader | File | Vertex | Fragment |
|--------|------|--------|----------|
| `COLOR_SHADER` | `embedded in src/render/gpu_renderer.rs (COLOR_SHADER)` | position + color | pass-through |
| `TEXTURE_SHADER` | `embedded in src/render/gpu_renderer.rs (TEXTURE_SHADER)` | position + UV + color tint | texture sample |

### Custom User Shaders

Users provide WGSL fragment (or vertex+fragment) source via `lurek.render.newShader`:

> See [snippets/custom-user-shaders.txt](snippets/custom-user-shaders.txt) for the example.

**Shader authoring rules:**
- Entry point: `@fragment fn fs_main(...) -> @location(0) vec4<f32>`
- Access screen size via `luna_ScreenSize`, time via `luna_Time`
- Return `vec4<f32>` (RGBA) from fragment shader
- Do not declare bindings at group 0 (reserved for engine uniforms)
- User uniforms go at group 2+; set via `lurek.render.sendShaderUniform(shader, name, value)`

### Validation Errors

Enable the wgpu validation layer during development:

> See [snippets/validation-errors.ps1](snippets/validation-errors.ps1) for the example.

Common wgpu errors:
- `BUFFER_COPY_ALIGNMENT` — vertex/index buffer sizes must be multiples of 4 bytes
- `BIND_GROUP_LAYOUT_MISMATCH` — shader binding layout != render pipeline layout
- `INVALID_OPERATION` — using a released resource (check deferred destruction queue)

### Texture Management
> See [examples/texture-management.rs](examples/texture-management.rs) for the example.


> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/wgpu-stack.txt](snippets/wgpu-stack.txt) — wgpu Stack
- [snippets/rendercommand-queue-lifecycle.txt](snippets/rendercommand-queue-lifecycle.txt) — RenderCommand Queue Lifecycle
- [snippets/custom-user-shaders.txt](snippets/custom-user-shaders.txt) — Custom User Shaders
- [snippets/validation-errors.ps1](snippets/validation-errors.ps1) — Validation Errors
- [examples/texture-management.rs](examples/texture-management.rs) — Texture Management
- [examples/canvas-render-to-texture.lua](examples/canvas-render-to-texture.lua) — Canvas (Render-to-Texture)
- [snippets/canvas-render-to-texture-2.txt](snippets/canvas-render-to-texture-2.txt) — Canvas (Render-to-Texture)
- [snippets/transform-stack.txt](snippets/transform-stack.txt) — Transform Stack
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
