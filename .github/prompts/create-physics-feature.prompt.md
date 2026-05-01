---
description: "Create one bounded physics feature and keep the Lua-facing contract honest."
agent: "Developer"
---
# Create Physics Feature

## Goal
- Add one physics feature without breaking invariants or ownership.

## Inputs
- Feature goal.
- Target physics path.
- Lua-facing impact.
- Expected validation path.

## Steps
1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md), [skill: error-handling](../skills/error-handling/SKILL.md), [skill: testing-rust](../skills/testing-rust/SKILL.md), and [skill: lua-rust-bridge](../skills/lua-rust-bridge/SKILL.md) before acting.
2. Read src/physics/, any matching Lua bridge code, docs/specs/physics.md, and nearby tests before editing.
3. Keep the physics state authoritative in the domain module, make boundary errors explicit, and avoid leaking implementation details into the Lua API.
4. Run the narrowest physics test or build check first, then sync docs or bindings only where the feature changed the contract.

## Success Criteria
- [ ] The prompt goal was completed: Add one physics feature without breaking invariants or ownership.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-physics-feature feature=one_way_platforms

## CAG Metadata
Mode: agent
Loads skills: rust-coding, error-handling, testing-rust, lua-rust-bridge
Inputs required: Feature goal., Target physics path., Lua-facing impact., Expected validation path.
