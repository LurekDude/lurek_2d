---
description: "Add one visual effect to the 2D renderer or post-process stack."
agent: "Developer"
---
# Add Visual Effect

## Goal
- Add one bounded visual effect without breaking the existing render model.

## Inputs
- Effect goal.
- Target render stage.
- Input data or parameters.
- Expected validation or demo path.

## Steps
1. Load [skill: visual-effects](../skills/visual-effects/SKILL.md), [skill: gpu-programming](../skills/gpu-programming/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read the owning render or effect files, nearby tests, docs/architecture/render-command-architecture.md, and any existing effect path before editing.
3. Keep the change inside the current 2D or pseudo-3D pipeline, wire only the required parameters, and update the nearest test or demo proof.
4. Run the narrowest render test, build check, or demo path that exercises the effect before broadening validation.

## Success Criteria
- [ ] The prompt goal was completed: Add one bounded visual effect without breaking the existing render model.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /add-visual-effect effect=crt stage=post_process

## CAG Metadata
Mode: agent
Loads skills: visual-effects, gpu-programming, testing-rust
Inputs required: Effect goal., Target render stage., Input data or parameters., Expected validation or demo path.
