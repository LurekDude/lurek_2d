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

**Single-pass pipeline:** setCanvas(c) -> render scene -> setCanvas(nil) -> setShader(s) -> draw(c, 0, 0) -> setShader(nil). This renders the scene to a canvas texture, then draws that canvas through a shader as a full-screen quad.

**Auto-uniforms available in WGSL shaders:** luna_Time (f32, seconds since start), luna_ScreenSize (vec2 of f32, viewport width and height in pixels). These are set automatically by the engine before each shader draw call.

**Common effect recipes:**

Greyscale: luminance = 0.299 * R + 0.587 * G + 0.114 * B. Apply to each texel in the fragment shader.

CRT scanlines: darken every Nth row (e.g., row % 3 == 0) by multiplying RGB by 0.7-0.8. Add slight barrel distortion by offsetting UV coordinates based on distance from center.

Wave distortion: offset UV.x by sin(UV.y * frequency + luna_Time * speed) * amplitude. Keep amplitude small (0.005-0.02) to avoid nausea.

Pixelation: floor UV coordinates to nearest grid cell: floor(uv * resolution) / resolution. Lower resolution = more pixelated.

Colour correction: multiply final RGB by a correction vector, or apply gamma curve (pow(color, vec3(gamma))).

**Multi-pass chaining:** render scene to canvas1, apply shader1 drawing canvas1 to canvas2, apply shader2 drawing canvas2 to screen. Each pass adds GPU overhead.

**Performance budget:** max 2ms total for all FX per frame on Intel UHD at 1080p. For expensive effects like blur or bloom, use a half-resolution canvas (540p) to halve pixel shader cost.

## Companion File Index

None - all guidance is inline.

## References

- src/render/ - render pipeline and shader integration
- docs/specs/render.md - render module specification

