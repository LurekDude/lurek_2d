- Use `wgpu::TextureFormat::Rgba8Unorm` for data textures (no gamma correction)
- `GpuRenderer::flush_pending_removals()` processes the deferred destruction queue at frame start

### Canvas (Render-to-Texture)
> See [examples/canvas-render-to-texture.lua](examples/canvas-render-to-texture.lua) for the example.

> See [snippets/canvas-render-to-texture-2.txt](snippets/canvas-render-to-texture-2.txt) for the example.

### Blend Modes
Five pre-built wgpu pipelines, cached at startup:

| Mode | Pipeline constant | Use case |
|------|------------------|----------|
| `alpha` | `ALPHA_PIPELINE` | Default, standard alpha blending |
| `add` | `ADDITIVE_PIPELINE` | Particles, glow, light |
| `multiply` | `MULTIPLY_PIPELINE` | Shadows, product blending |
| `replace` | `REPLACE_PIPELINE` | No blending — overwrites |
| `screen` | `SCREEN_PIPELINE` | Screen blending, lightening |

### Transform Stack
> See [snippets/transform-stack.txt](snippets/transform-stack.txt) for the example.

Transforms apply to all subsequent draw calls until `PopTransform`.

### Performance Rules
- Per-frame code must not allocate on the heap — grow draw-call buffers at startup
- Target ≤ 2000 draw calls per frame on integrated GPU (Intel UHD 620 baseline)
- Batch sprites with `SpriteBatch` when drawing many instances of the same texture
- Use `SetScissor` to skip overdraw in large UI panels
- `DrawParticleSystem` is a single draw call regardless of particle count (GPU-side update where possible)
- Profile with `cargo flamegraph` or `pix` (DX12 PIX) / RenderDoc (Vulkan)

### Anti-Patterns
- **CPU pixel loop per frame**: Writing pixels to a CPU buffer every frame and uploading — use `Canvas` or compute shaders instead
- **Per-draw pipeline switches**: Changing shaders or blend modes per-entity — sort by state, batch draws
- **Missing deferred destroy**: Dropping `TextureKey` without removing from `SharedState` — GPU memory leak
- **Texture format mismatch**: Uploading sRGB images as `Rgba8Unorm` — causes washed-out colors
