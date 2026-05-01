---
description: "Add one visual effect to the 2D renderer or post-process stack."
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
1. Load visual-effects, gpu-programming, and testing-rust before acting.
2. Read the owning render or effect files, nearby tests, docs/specs/render.md, and any existing effect path before editing.
3. Keep the change inside the current 2D pipeline, wire only the required parameters, and update the nearest test or demo proof.
4. Run the narrowest render test, build check, or demo path that exercises the effect before broadening validation.

## Success Criteria
- [ ] The effect is added inside the existing 2D pipeline.
- [ ] Required sync files were updated.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Skip the first narrow validation.
- Introduce 3D rendering assumptions.

## Example Invocation
- /add-visual-effect effect=crt stage=post_process
