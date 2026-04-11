---
description: "Create a new RenderCommand variant for the rendering pipeline with full integration."
---

# Create Draw Command

## Purpose

Add a new RenderCommand variant to the rendering pipeline.

## Inputs

- **Command name**: PascalCase variant name (e.g., `DrawCircle`, `DrawLine`)
- **Parameters**: Data fields the command needs
- **Rendering behavior**: How the wgpu pipeline should render it

## Steps

1. Add variant to `RenderCommand` enum in `src/render/mod.rs`
2. Implement rendering in `src/render/renderer.rs` match arm
3. Add Lua binding in `src/lua_api/render_api.rs`
4. Update `docs/API/lua_api_reference_generated.md`
5. Write test for the new command
6. Run `cargo test` and `cargo clippy`

## Acceptance

- [ ] RenderCommand variant is data-only (no logic)
- [ ] Renderer processes command correctly
- [ ] Lua binding follows `lurek.gfx.*` pattern
- [ ] Tests pass, clippy clean

## References

- `gpu-programming` skill
- `src/render/AGENT.md`
- `src/render/mod.rs`
