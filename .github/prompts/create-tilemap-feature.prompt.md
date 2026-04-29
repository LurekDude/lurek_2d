---
description: "Create one bounded tilemap feature with synced docs and tests."
agent: "Developer"
---
# Create Tilemap Feature

## Goal
- Add one tilemap feature in the owner layer.

## Inputs
- Feature goal.
- Target tilemap path.
- Lua-facing impact.
- Expected validation path.

## Steps
1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md) and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read src/tilemap/, the matching spec, any Lua bridge touchpoints, and nearby tests or examples before editing.
3. Keep the feature inside the tilemap domain, update only the necessary contracts, and avoid spreading scene or render logic into the wrong layer.
4. Run the narrowest tilemap-focused test or build check first, then sync docs or examples when the contract actually changed.

## Success Criteria
- [ ] The prompt goal was completed: Add one tilemap feature in the owner layer.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-tilemap-feature feature=autotile_rules

## CAG Metadata
Mode: agent
Loads skills: rust-coding, testing-rust
Inputs required: Feature goal., Target tilemap path., Lua-facing impact., Expected validation path.
