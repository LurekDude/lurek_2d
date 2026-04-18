---
description: "Create a new RenderCommand variant for the rendering pipeline with full integration."
mode: agent
loads_skills: [gpu-programming]
loads_tools: []
expected_agent: Developer
inputs_required: []
---

# Create Draw Command

## Goal

Add a new RenderCommand variant to the rendering pipeline.

## Inputs

- **Command name**: PascalCase variant name (e.g., `DrawCircle`, `DrawLine`)
- **Parameters**: Data fields the command needs
- **Rendering behavior**: How the wgpu pipeline should render it

## Steps

1. Load [skill: gpu-programming](.github/skills/gpu-programming/SKILL.md) before changing any files.
2. Add variant to `RenderCommand` enum in `src/render/mod.rs`
3. Implement rendering in `src/render/renderer.rs` match arm
4. Add Lua binding in `src/lua_api/render_api.rs`
5. Update `docs/API/lua-api.md`
6. Write test for the new command
7. Run `cargo test` and `cargo clippy`
8. Consult the actual `lurek.*` API surface via [docs/API/lua-api.md](docs/API/lua-api.md), [content/examples/](content/examples/), and [docs/specs/](docs/specs/). Do NOT invent APIs.

## Success Criteria

- [ ] RenderCommand variant is data-only (no logic)
- [ ] Renderer processes command correctly
- [ ] Lua binding follows `lurek.gfx.*` pattern
- [ ] Tests pass, clippy clean

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-draw-command`
