---
name: gpu-programming
description: "Load this skill when working on wgpu setup, RenderCommand flow, render passes, textures, shaders, or GPU validation errors. Skip it for font internals, Lua API design, or physics."
---
# gpu-programming

## Mission
- Own wgpu rendering flow, RenderCommand behavior, and shader integration.

## When To Load
- Change device or surface setup.
- Add or modify RenderCommand behavior.
- Work on textures, canvases, or shaders.
- Diagnose GPU validation errors.

## When To Skip
- Font internals.
- Lua API design.
- Physics logic.

## Domain Knowledge
- Keep GPU work out of Lua-facing closures.
- Treat RenderCommand as queued data, not immediate draw logic.
- Validate WGSL at creation time.
- Reuse buffers and avoid per-frame allocation when possible.
- Keep texture and canvas lifetime rules explicit.
- Use the render module spec as the canonical contract for renderer behavior.

## Companion File Index
- None.

## References
- src/render/gpu_renderer.rs
- src/render/renderer.rs
- src/lua_api/render_api.rs
- docs/specs/render.md