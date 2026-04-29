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
- wgpu 22 is the only renderer backend; there is no OpenGL fallback path in core engine.
- RenderCommand data is queued work and should stay separate from Lua callback execution.
- Validate WGSL at shader creation and keep shader assumptions aligned with src/lua_api/render_api.rs and docs/specs/render.md.
- src/render/ owns canvases, textures, pipeline cache, and GPU resource lifetime.
- Raycaster and pseudo-3D features still resolve through the 2D render flow, not a separate 3D stack.
- Watch per-frame allocations and texture churn before blaming pure shader cost.
- src/render/, render bindings, shader creation, and canvas usage are tightly connected here, so pipeline changes should be checked against both Rust renderer code and Lua-facing draw paths.
- Because the engine is 2D-only, pseudo-3D and raycaster features still resolve through this render contract instead of a separate 3D stack.
- This skill owns GPU-side correctness and lifetime, not API naming or gameplay visuals.
## Companion File Index
- None.

## References
- src/render/
- src/lua_api/render_api.rs
- docs/specs/render.md
- tests/
