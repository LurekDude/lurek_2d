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
- Lurek2D postfx is still a 2D canvas -> shader -> draw pipeline, not a separate 3D renderer.
- Expensive blur or bloom should usually start with half-resolution canvases on integrated GPUs.
- Multi-pass chains multiply GPU cost fast, so budget passes explicitly.
- Effect assumptions must stay aligned with docs/specs/render.md and src/render/ resource lifetime rules.
- Existing showcase content such as postfx_demo is a better anchor than generic shader recipes.
- Pair this skill with gpu-programming when the work touches pipelines, textures, or command flow.
- postfx_demo and related showcase content are practical anchors for what screen-space effects should look like in this repo.
- Effect work must respect current canvas, shader, and render-command lifetime rules because post-processing is layered on the same 2D pipeline.
- This skill owns effect composition and shader-side visual tradeoffs, not general render backend structure.
## Companion File Index

None - all guidance is inline.

## References
- src/render/
- docs/specs/render.md
- content/games/showcase/postfx_demo/
