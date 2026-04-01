---
name: shader-patterns
description: "Load this skill when implementing software shader effects in Luna2D: color manipulation, blending modes, pixel-level operations, or post-processing. Skip it for geometry rendering or physics."
---

# Shader Patterns — Luna2D Engine

## Load When

- Implementing software shader effects in `src/graphics/shader.rs`
- Adding blending modes or color manipulation
- Working on post-processing effects (screen-wide pixel operations)
- Implementing alpha blending or color tinting

## Owns

- Software shader architecture patterns
- Color blending algorithms
- Custom WGSL fragment shaders via the Shader API
- Post-processing effect pipeline

## Does Not Cover

- GPU shaders → Luna2D is software-rendered
- Geometry rendering → use `software-rendering` skill
- Color type definition → defined in `color.rs` via `software-rendering` skill

## Live Repository Contracts

- `src/graphics/shader.rs` — software shader effect implementations
- `src/graphics/color.rs` — Color struct for shader inputs
- `src/graphics/renderer.rs` — shader integration point in render pipeline

## Decision Rules

- **WGSL shaders**: Custom fragment shaders in WGSL via the Shader API
- **GPU pipeline**: Shaders execute on GPU — no CPU pixel manipulation in the primary path
- **Premultiplied alpha**: wgpu pipeline uses premultiplied alpha — respect this in blending math
- **No GPU abstractions**: Don't design shader interfaces that imply GPU concepts (vertex/fragment)
- **Performance awareness**: Pixel-level operations are expensive — minimize per-frame shader work
- **Blending formula**: `result = src * src_alpha + dst * (1 - src_alpha)` for standard alpha blend
- **Color clamping**: Clamp all color channel results to 0..255 (or 0.0..1.0) after operations
