---
name: gpu-programming
description: "Load this skill when working with the Lurek2D GPU rendering pipeline: wgpu device/surface setup, RenderCommand queue, render passes, texture management, custom WGSL shaders, blend modes, canvas render-to-texture, or transform stacks. Also covers profiling GPU frame time and diagnosing wgpu validation errors. Skip it for font rasterization details, Lua API design, or physics."
---

# GPU Programming — Lurek2D

## Load When

- Implementing or modifying a `RenderCommand` variant
- Adding a wgpu render pipeline (new blend mode, new shader type)
- Writing or debugging custom WGSL shaders
- Texture management — loading, uploading, caching by `TextureKey`
- Canvas (render-to-texture) implementation patterns
- Diagnosing wgpu validation layer errors or GPU memory issues
- Profiling GPU frame time and draw call count

## Owns

- wgpu device/adapter/surface setup and swapchain lifecycle
- `RenderCommand` queue lifecycle and variant dispatch
- Built-in WGSL shaders and custom user shader pipeline
- Texture upload, format selection, and deferred destruction
- Blend mode pipeline cache
- Canvas render-to-texture pattern
- Transform stack (`PushTransform` / `PopTransform`)
- GPU performance rules for integrated-GPU baseline

## wgpu Stack

```
winit Window (Arc<Window>)
  └── wgpu::Instance
        └── wgpu::Adapter (auto-select: Vulkan → DX12 → Metal → fallback)
              └── wgpu::Device + Queue
                    └── wgpu::Surface (swapchain)
                          └── GpuRenderer::render_frame()
```

Lurek2D targets **wgpu 22**. No raw OpenGL path exists. All rendering goes through `GpuRenderer` in `src/graphics/gpu_renderer.rs`.

## RenderCommand Queue Lifecycle

```
lua.draw() callback:
  → Lua calls lurek.gfx.drawImage(img, x, y)
  → lua_api pushes RenderCommand::DrawImage { ... } into SharedState::render_commands

After lurek.draw() returns:
  → GpuRenderer::render_frame(render_commands) processes the queue
  → Each variant maps to wgpu render pass calls
  → swapchain present
```

**Invariants:**
- Never render inside a Lua closure — push RenderCommands only
- `render_commands` is cleared at the start of each frame's draw step (step 7)
- Only one `wgpu::CommandEncoder` is created per frame in `render_frame()`

## Adding a New RenderCommand Variant

1. Add variant to `RenderCommand` enum in `src/graphics/renderer.rs`
2. Add execution arm in `src/graphics/gpu_renderer.rs` (match arm)
3. Add Lua push function in `src/lua_api/graphics_api.rs`
4. Add Lua BDD test in `tests/lua/unit/test_graphics.lua`

## Shader Authoring (WGSL)

### Built-In Shaders

Two WGSL shaders are embedded in the binary:

| Shader | File | Vertex | Fragment |
|--------|------|--------|----------|
| `COLOR_SHADER` | `embedded in src/graphics/gpu_renderer.rs (COLOR_SHADER)` | position + color | pass-through |
| `TEXTURE_SHADER` | `embedded in src/graphics/gpu_renderer.rs (TEXTURE_SHADER)` | position + UV + color tint | texture sample |

### Custom User Shaders

Users provide WGSL fragment (or vertex+fragment) source via `lurek.gfx.newShader`:

```
User WGSL source
  └── Engine prepends standard header:
        @group(0) @binding(0) var<uniform> luna_ScreenSize: vec2<f32>;
        @group(0) @binding(1) var<uniform> luna_Time: f32;
        @group(1) @binding(0) var luna_texture: texture_2d<f32>;
        @group(1) @binding(1) var luna_sampler: sampler;
  └── Validate with naga (bundled in wgpu)
  └── Create dedicated wgpu::RenderPipeline
  └── Store as ShaderKey in SharedState
```

**Shader authoring rules:**
- Entry point: `@fragment fn fs_main(...) -> @location(0) vec4<f32>`
- Access screen size via `luna_ScreenSize`, time via `luna_Time`
- Return `vec4<f32>` (RGBA) from fragment shader
- Do not declare bindings at group 0 (reserved for engine uniforms)
- User uniforms go at group 2+; set via `lurek.gfx.sendShaderUniform(shader, name, value)`

### Validation Errors

Enable the wgpu validation layer during development:

```powershell
$env:WGPU_BACKEND = "vulkan"   # force backend (optional)
$env:RUST_LOG = "wgpu_core=warn,wgpu_hal=warn"
cargo run -- content/demos/hello_world
```

Common wgpu errors:
- `BUFFER_COPY_ALIGNMENT` — vertex/index buffer sizes must be multiples of 4 bytes
- `BIND_GROUP_LAYOUT_MISMATCH` — shader binding layout != render pipeline layout
- `INVALID_OPERATION` — using a released resource (check deferred destruction queue)

## Texture Management

```rust
// Upload texture to GPU:
let texture_key = state.borrow_mut().textures.insert(TextureData {
    width, height, format: wgpu::TextureFormat::Rgba8UnormSrgb, ...
});
gpu_renderer.upload_texture(texture_key, rgba_bytes);

// Reference by key in RenderCommand:
RenderCommand::DrawImage { texture_key, x, y, w, h, ... }

// Release (queued for deferred GPU destruction at next frame start):
state.borrow_mut().textures.remove(texture_key);
```

- Use `wgpu::TextureFormat::Rgba8UnormSrgb` for color images (sRGB compositing)
- Use `wgpu::TextureFormat::Rgba8Unorm` for data textures (no gamma correction)
- `GpuRenderer::flush_pending_removals()` processes the deferred destruction queue at frame start

## Canvas (Render-to-Texture)

```lua
-- Lua usage:
local c = lurek.gfx.newCanvas(512, 512)
lurek.gfx.setCanvas(c)
-- ... draw calls render to canvas texture ...
lurek.gfx.setCanvas()               -- back to screen
lurek.gfx.draw(c, 0, 0)
```

```
SetCanvas(Some(key))  → end screen pass, begin canvas render pass to CanvasKey texture
(draw calls render to canvas)
SetCanvas(None)       → end canvas pass, resume screen pass
DrawCanvas(key, ...)  → sample canvas texture as a quad
```

## Blend Modes

Five pre-built wgpu pipelines, cached at startup:

| Mode | Pipeline constant | Use case |
|------|------------------|----------|
| `alpha` | `ALPHA_PIPELINE` | Default, standard alpha blending |
| `add` | `ADDITIVE_PIPELINE` | Particles, glow, light |
| `multiply` | `MULTIPLY_PIPELINE` | Shadows, product blending |
| `replace` | `REPLACE_PIPELINE` | No blending — overwrites |
| `screen` | `SCREEN_PIPELINE` | Screen blending, lightening |

## Transform Stack

```
PushTransform      → push copy of current matrix onto stack
Translate(dx, dy)  → matrix = matrix * translate(dx, dy)
Rotate(angle)      → matrix = matrix * rotate(angle)
Scale(sx, sy)      → matrix = matrix * scale(sx, sy)
PopTransform       → restore previous matrix from stack
```

Transforms apply to all subsequent draw calls until `PopTransform`.

## Performance Rules

- Per-frame code must not allocate on the heap — grow draw-call buffers at startup
- Target ≤ 2000 draw calls per frame on integrated GPU (Intel UHD 620 baseline)
- Batch sprites with `SpriteBatch` when drawing many instances of the same texture
- Use `SetScissor` to skip overdraw in large UI panels
- `DrawParticleSystem` is a single draw call regardless of particle count (GPU-side update where possible)
- Profile with `cargo flamegraph` or `pix` (DX12 PIX) / RenderDoc (Vulkan)

## Anti-Patterns

- **CPU pixel loop per frame**: Writing pixels to a CPU buffer every frame and uploading — use `Canvas` or compute shaders instead
- **Per-draw pipeline switches**: Changing shaders or blend modes per-entity — sort by state, batch draws
- **Missing deferred destroy**: Dropping `TextureKey` without removing from `SharedState` — GPU memory leak
- **Texture format mismatch**: Uploading sRGB images as `Rgba8Unorm` — causes washed-out colors
