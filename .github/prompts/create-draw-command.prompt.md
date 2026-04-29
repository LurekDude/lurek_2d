---
description: "Create one new render draw command and wire it through the owning render path."
agent: "Renderer"
---
# Create Draw Command

## Goal
- Add one bounded draw command to the render pipeline.

## Inputs
- Command goal.
- Target renderer path.
- Required parameters.
- Expected test or demo path.

## Steps
1. Load [skill: gpu-programming](../skills/gpu-programming/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read the render command types, the owning encoder or pass, nearby tests, and the contract docs before editing.
3. Keep the command shape minimal, follow the current render-command flow, and avoid slipping unrelated scene or gameplay logic into the renderer.
4. Run the narrowest render test or build check that covers the new command before broadening validation.

## Success Criteria
- [ ] The prompt goal was completed: Add one bounded draw command to the render pipeline.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-draw-command command=drawNineSlice

## CAG Metadata
Mode: agent
Loads skills: gpu-programming, rust-coding, testing-rust
Inputs required: Command goal., Target renderer path., Required parameters., Expected test or demo path.
