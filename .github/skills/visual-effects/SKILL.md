---
name: visual-effects
description: "Load this skill when building shader or post-process effects like bloom, blur, CRT, distortion, or palette swap. Skip it for basic drawing or out-of-scope 3D rendering."
---
# visual-effects

## Mission
- Own the canvas render-to-texture post-processing pipeline, WGSL shader patterns, auto-uniform conventions, and per-frame performance budgets for visual effects.

## When To Load
- Adding a post-processing effect (blur, bloom, CRT, colour correction).
- Writing a custom WGSL fragment shader for screen-space effects.
- Chaining multiple render passes via canvas objects.
- Optimizing visual effect frame time.

## When To Skip
- Basic sprite/image drawing — use `gpu-programming` skill.
- 3D rendering — out of scope for Lurek2D.

## Domain Knowledge
- How to add a new post-processing effect: (1) create a `Canvas` via `lurek.render.newCanvas(w, h)` at the desired resolution — typically half the screen resolution for blur or bloom; (2) draw the scene into it using a `RenderCommand::DrawToCanvas`; (3) create a `Shader` via `lurek.render.newShader(wgsl_source)` with the desired WGSL fragment code; (4) draw the canvas back to screen via `lurek.render.drawCanvas(canvas, 0, 0)` with the shader active. See `content/games/showcase/postfx_demo/main.lua` for a working example of 10 chained effects including bloom, blur, CRT, and palette swap.
- WGSL shader conventions in this engine: the engine provides `@group(0) @binding(0)` as the source texture and `@group(0) @binding(1)` as a sampler. Auto-uniforms (declared in Lua via `shader:setUniform("name", value)`) are bound at `@group(1)` starting at `@binding(0)`. Do not invent new binding slots without updating `src/render/shader.rs` and the bind group layout in `src/render/postfx_pipeline.rs`.
- Half-resolution rule: bloom, blur, and glow passes should operate on a canvas at half the render target resolution (e.g., 640×360 for a 1280×720 game). This halves the fragment shader invocations and is usually imperceptible quality-wise. Full-resolution multi-pass blur chains are the fastest way to break the 60 FPS budget on integrated GPUs.
- Pass budget: each `Canvas` draw is an additional GPU pass. Budget 2–3 passes maximum for combined effects on integrated hardware. Chain effects by compositing canvas-to-canvas at half resolution before the final full-resolution composite, not by running each effect at full resolution separately.
- CRT and scanline effects are achieved via a fragment shader that reads `frag_uv.y` and applies a periodic darkening or distortion formula. The `postfx_demo` includes a working CRT shader — copy its binding layout rather than writing from scratch, because the binding slot convention must match what the Rust pipeline expects.
- Palette swap / colour grading: load a 256×1 or 16×16 LUT texture, bind it as a second texture at `@group(0) @binding(2)` (if supported), and sample it using the greyscale value of the source pixel as the UV coordinate. Check `src/render/shader.rs` for whether multi-texture bindings are already supported before adding a new slot.
- `src/render/image_effect.rs` and `src/render/postfx_pipeline.rs` own the Rust side of the post-processing pipeline. Changes to effect parameters, canvas lifetime, or shader reuse must respect the resource lifetime rules in those files. Canvases are created once and reused across frames — never create a new canvas per frame.
## Companion File Index
- None.

## References
- src/render/
- docs/specs/render.md
- content/games/showcase/postfx_demo/
