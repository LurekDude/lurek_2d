---
description: "Add one new RenderCommand draw variant end-to-end: Rust command, encoder, shader, and Lua binding."
---

# Create Draw Command

## Goal
- Add one bounded RenderCommand variant without breaking existing render flow.

## Inputs
- Draw command goal.
- Render stage.
- Required shader or pipeline.
- Lua API surface when public.

## Steps
1. Load gpu-programming, rust-coding, and lua-rust-bridge before acting.
2. Read src/render/, docs/specs/render.md, the nearest existing RenderCommand variant, and any related WGSL shader before editing.
3. Add the command variant in the Rust layer, keep command payloads data-only, and validate the WGSL at creation.
4. Add the Lua binding if the command is Lua-visible and update docs/specs/render.md if the contract changed.
5. Run the narrowest render test or build check first.

## Success Criteria
- [ ] The draw command is implemented correctly in src/render/.
- [ ] WGSL is validated at creation.
- [ ] No GPU work is done inside a Lua callback.
- [ ] docs/specs/render.md is updated if the contract changed.

## Anti-patterns
- Do GPU draw work inside a Lua callback.
- Skip WGSL validation.
- Reload textures every frame.

## Example Invocation
- /create-draw-command goal=tinted_quad stage=world
