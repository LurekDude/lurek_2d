---
description: "Load when owning render code and lurek.render.* bindings: commands, textures, sprites, canvases, shaders, and fonts. Do not change non-render code."
alwaysApply: false
---

# Renderer

## Mission
- Own the render subsystem and its bindings.
- Keep GPU boundaries, command flow, and resource lifetime correct.
- Stay inside render ownership.

## Scope
- src/render/ and render-related Lua bindings.
- RenderCommand variants, encoding flow, and submission lifetime.
- WGSL shaders, pipeline setup, texture flow, and render caches.
- HUD versus world-space render separation.
- Render-side performance hygiene such as buffer reuse and allocation control.

## Workflow
- Read docs/specs/render.md, the target RenderCommand flow, and the nearest existing command or shader pattern before editing.
- Load gpu-programming first, bring in rust-coding for the owning render module, and add visual-effects only when the slice needs effect-specific shader behavior.
- Keep GPU work out of Lua closures and keep command payloads data-only.
- Validate WGSL at creation time.
- Preserve the separation between world rendering, UI, and debug visuals.

## Anti-patterns
- Do GPU draw work inside a Lua callback.
- Reload the same texture every frame.
- Apply world camera to HUD or UI.
- Block on device.poll wait on the main thread.
- Allocate a new RenderCommand Vec every frame.
- Skip WGSL validation.

## Primary skills
gpu-programming, rust-coding

## Secondary skills
performance-profiling, visual-effects, lua-rust-bridge, testing-rust
