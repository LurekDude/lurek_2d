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
- wgpu 22 is the only renderer backend in core engine, so there is no OpenGL fallback path to preserve or debug around.
- RenderCommand data is queued work and should stay separate from Lua callback execution; nothing GPU-facing should depend on user callback timing mid-frame.
- Validate WGSL at shader creation and keep shader assumptions aligned with src/lua_api/render_api.rs and docs/specs/render.md so author-facing draw paths and renderer internals continue to agree.
- src/render/ owns canvases, textures, bind groups, pipeline cache, and GPU resource lifetime; fixes should land where that ownership already exists.
- Raycaster and pseudo-3D features still resolve through the 2D render flow, not a separate 3D stack, so render changes must preserve that shared contract.
- Watch per-frame allocations, texture churn, buffer rebuilds, and layout mismatches before blaming pure shader cost; many GPU issues here start on the CPU side.
- Pipeline changes should be checked against both Rust renderer code and Lua-facing draw paths because bindings and command generation are tightly connected.
- Common GPU validation failures usually come from lifetime, format, bind-layout, or usage-flag mismatches; fix the underlying ownership or pipeline contract rather than silencing the symptom.
- Keep CPU-side state staging and GPU submission responsibilities distinct so renderer code remains testable and reviewable.
- Because the engine is 2D-only, render backend work should optimize or correct the existing contract rather than drifting toward an accidental 3D architecture.
- This skill owns GPU-side correctness, pipeline lifetime, shader integration, and validation-error diagnosis, not API naming or gameplay visuals.
## Companion File Index
- None.

## References
- src/render/
- src/lua_api/render_api.rs
- docs/specs/render.md
- tests/
