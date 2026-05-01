---
description: "Load when building shader or post-process effects like bloom, blur, CRT, distortion, or palette swap. Skip for basic drawing or out-of-scope 3D rendering."
alwaysApply: false
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
- Basic sprite/image drawing → use gpu-programming skill.
- 3D rendering → out of scope for Lurek2D.

## Domain Knowledge
- Lurek2D postfx is still a 2D canvas → shader → draw pipeline, not a separate 3D renderer.
- Expensive blur, bloom, distortion, or CRT chains should usually start with half-resolution or otherwise reduced intermediate canvases on integrated GPUs.
- Multi-pass chains multiply GPU cost quickly, so budget each pass explicitly.
- Effect assumptions must stay aligned with docs/specs/render.md and src/render/ resource lifetime rules.
- Existing showcase content such as postfx_demo is a better anchor than generic shader recipes.
- Pair this skill with gpu-programming when work touches pipelines, textures, render-command flow, or validation errors.
- Good effect design here balances look, clarity, and cost.
- Keep effect chains readable and intentional.
- Author-facing effect parameters should stay stable and understandable.

## References
- src/render/
- docs/specs/render.md
- content/games/showcase/postfx_demo/
