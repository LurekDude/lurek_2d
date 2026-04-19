---
name: visual-effects
description: "Load this skill when implementing visual post-processing effects, image filters, or shader-based rendering techniques in Lurek2D: full-screen passes using canvas render-to-texture, custom WGSL fragment shaders for blur/bloom/distortion/colour grading, screen-space overlays, or multi-pass render pipelines. Use for: CRT scanlines, vignette, colour correction, bloom, distortion, pixelation, palette swap. Skip it for basic sprite/image drawing (use gpu-programming), or 3D-style rendering (out of scope for Lurek2D)."
---
# visual-effects

## Mission

# Visual Effects — Lurek2D

## When To Load

- Adding a full-screen post-processing effect (bloom, blur, vignette, CRT, etc.)
- Writing a WGSL fragment shader to transform rendered output
- Building a multi-pass render pipeline: render scene → apply effect → present
- Implementing palette swaps, colour grading, or per-pixel image filters
- Combining multiple effects in a layered pipeline
- Optimising effects for integrated GPU (frame budget constraints)

## When To Skip

- Skip it for basic sprite/image drawing (use gpu-programming), or 3D-style rendering (out of scope for Lurek2D).

## Domain Knowledge

### Owns
- Canvas render-to-texture as the post-processing substrate
- Custom WGSL fragment shader authoring patterns
- Multi-pass pipeline (scene → FX canvas → screen)
- Built-in shader auto-uniforms (`luna_Time`, `luna_ScreenSize`)
- Common effect recipes (blur, bloom, vignette, CRT, distortion)
- Performance budget for full-screen passes on integrated GPU
- CPU-side image filter via `lurek.img` (offline/load-time effects)

---

### How Post-Processing Works in Lurek2D
Lurek2D has no dedicated post-processing pipeline. Effects are implemented using the **canvas + custom shader** pattern:

> See [snippets/how-post-processing-works-in-lurek2d.txt](snippets/how-post-processing-works-in-lurek2d.txt) for the example.

This single pattern covers every post-processing effect. Multi-pass effects chain multiple canvases.

---

### Single-Pass Effect
> See [examples/single-pass-effect.lua](examples/single-pass-effect.lua) for the example.

---

### Built-In Shader Auto-Uniforms
These variables are automatically updated every frame — no manual upload needed:

| WGSL name | Type | Value |
|-----------|------|-------|
| `luna_Time` | `f32` | Elapsed time in seconds |
| `luna_ScreenSize` | `vec2<f32>` | Window width × height in pixels |

> See [examples/built-in-shader-auto-uniforms.wgsl](examples/built-in-shader-auto-uniforms.wgsl) for the example.

---

### Effect Recipes
### Greyscale / Desaturate

> See [examples/greyscale-desaturate.wgsl](examples/greyscale-desaturate.wgsl) for the example.

### CRT Scanlines

> See [examples/crt-scanlines.wgsl](examples/crt-scanlines.wgsl) for the example.

### Animated Wave Distortion

> See [examples/animated-wave-distortion.wgsl](examples/animated-wave-distortion.wgsl) for the example.

### Pixelation

> See [examples/pixelation.wgsl](examples/pixelation.wgsl) for the example.

### Colour Correction (Brightness / Contrast / Saturation)

> See [examples/colour-correction-brightness-contrast-saturation.wgsl](examples/colour-correction-brightness-contrast-saturation.wgsl) for the example.

---

### Multi-Pass Pipeline
Chain effects by using multiple canvases as intermediate render targets:

> See [examples/multi-pass-pipeline.lua](examples/multi-pass-pipeline.lua) for the example.

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/how-post-processing-works-in-lurek2d.txt](snippets/how-post-processing-works-in-lurek2d.txt) — How Post-Processing Works in Lurek2D
- [examples/single-pass-effect.lua](examples/single-pass-effect.lua) — Single-Pass Effect
- [examples/built-in-shader-auto-uniforms.wgsl](examples/built-in-shader-auto-uniforms.wgsl) — Built-In Shader Auto-Uniforms
- [examples/greyscale-desaturate.wgsl](examples/greyscale-desaturate.wgsl) — Greyscale / Desaturate
- [examples/crt-scanlines.wgsl](examples/crt-scanlines.wgsl) — CRT Scanlines
- [examples/animated-wave-distortion.wgsl](examples/animated-wave-distortion.wgsl) — Animated Wave Distortion
- [examples/pixelation.wgsl](examples/pixelation.wgsl) — Pixelation
- [examples/colour-correction-brightness-contrast-saturation.wgsl](examples/colour-correction-brightness-contrast-saturation.wgsl) — Colour Correction (Brightness / Contrast / Saturation)
- [examples/multi-pass-pipeline.lua](examples/multi-pass-pipeline.lua) — Multi-Pass Pipeline
- [examples/cpu-side-image-filters-offline-load.lua](examples/cpu-side-image-filters-offline-load.lua) — CPU-Side Image Filters (Offline / Load-Time)
- [examples/performance-budget.lua](examples/performance-budget.lua) — Performance Budget
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
