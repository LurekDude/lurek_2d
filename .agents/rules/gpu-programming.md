---
description: "Load when working on wgpu setup, RenderCommand flow, render passes, textures, shaders, or GPU validation errors. Skip for font internals, Lua API design, or physics."
alwaysApply: false
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
- wgpu 22 is the only renderer backend in core engine; there is no OpenGL fallback path.
- RenderCommand data is queued work and should stay separate from Lua callback execution.
- Validate WGSL at shader creation and keep shader assumptions aligned with src/lua_api/render_api.rs and docs/specs/render.md.
- src/render/ owns canvases, textures, bind groups, pipeline cache, and GPU resource lifetime.
- Raycaster and pseudo-3D features still resolve through the 2D render flow, not a separate 3D stack.
- Watch per-frame allocations, texture churn, buffer rebuilds, and layout mismatches before blaming pure shader cost.
- Pipeline changes should be checked against both Rust renderer code and Lua-facing draw paths.
- Common GPU validation failures come from lifetime, format, bind-layout, or usage-flag mismatches.
- Keep CPU-side state staging and GPU submission responsibilities distinct.
- The engine is 2D-only; render backend work should optimize the existing contract, not drift toward 3D.

## References
- src/render/
- src/lua_api/render_api.rs
- docs/specs/render.md
- tests/
