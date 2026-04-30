---
name: visual-effects
description: "Load this skill when building shader or post-process effects like bloom, blur, CRT, distortion, or palette swap. Skip it for basic drawing or out-of-scope 3D rendering."
---
# visual-effects

## Mission

Own the canvas render-to-texture post-processing pipeline, WGSL shader patterns, auto-uniform conventions, and per-frame performance budgets for visual effects.

## When To Load

- Adding a post-processing effect (blur, bloom, CRT, colour correction)
- Writing a custom WGSL fragment shader for screen-space effects
- Chaining multiple render passes via canvas objects
- Optimizing visual effect frame time

## When To Skip

- Basic sprite/image drawing -> use gpu-programming skill
- 3D rendering -> out of scope for Lurek2D

## Domain Knowledge
- Lurek2D postfx is still a 2D canvas -> shader -> draw pipeline, not a separate 3D renderer, so effect work should stay inside the existing screen-space model.
- Expensive blur, bloom, distortion, or CRT chains should usually start with half-resolution or otherwise reduced intermediate canvases on integrated GPUs.
- Multi-pass chains multiply GPU cost quickly, so budget each pass explicitly instead of treating postfx as free layering.
- Effect assumptions must stay aligned with docs/specs/render.md and src/render/ resource lifetime rules because post-processing is layered onto the same renderer contract.
- Existing showcase content such as postfx_demo is a better anchor than generic shader recipes because it reflects the engine's current canvas and command behavior.
- Pair this skill with gpu-programming when work touches pipelines, textures, render-command flow, or validation errors; this skill focuses on effect composition, not backend plumbing.
- Good effect design here balances look, clarity, and cost: a simpler pass that preserves frame budget is usually better than a visually richer chain that destabilizes performance.
- Keep effect chains readable and intentional so another maintainer can see which pass adds bloom, which pass handles color treatment, and where to tune the budget.
- Author-facing effect parameters should stay stable and understandable; if the shader math is complex, the exposed knobs should still be simple to reason about.
- Effect work must respect current canvas, shader, and render-command lifetime rules because post-processing remains part of the same 2D frame pipeline.
- This skill owns effect composition, shader-side visual tradeoffs, and postfx budgeting, not general render backend structure or unrelated gameplay art direction.
## Companion File Index

None - all guidance is inline.

## References
- src/render/
- docs/specs/render.md
- content/games/showcase/postfx_demo/
