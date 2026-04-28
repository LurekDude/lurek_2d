---
description: "Create a new RenderCommand variant."
---

# Create Draw Command

## Goal
- Add a new RenderCommand variant to the rendering pipeline.

## Inputs
- **Command name**: PascalCase variant name (e.g., DrawCircle, DrawLine)
- **Parameters**: Data fields the command needs
- **Rendering behavior**: How the wgpu pipeline should render it

## Steps
- Load gpu-programming before changing any files.
- Add variant to RenderCommand enum in src/render/mod.rs
- Implement rendering in src/render/renderer.rs match arm
- Add Lua binding in src/lua_api/render_api.rs
- Update docs/api/lurek.md
- Write test for the new command
- Run cargo test and cargo clippy
- Consult the actual lurek.* API surface via docs/api/lurek.md, content/examples/, and docs/specs/. Do NOT invent APIs.

## Success Criteria
- [ ] RenderCommand variant is data-only (no logic)
- [ ] Renderer processes command correctly
- [ ] Lua binding follows lurek.render.* pattern
- [ ] Tests pass, clippy clean

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-draw-command

## CAG Metadata
- **Mode**: agent
- **Loads skills**: gpu-programming
