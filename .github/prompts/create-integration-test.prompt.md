---
description: "Create one integration test in the correct repo layer for a concrete behavior."
agent: "Tester"
---
# Create Integration Test

## Goal
- Add one integration test in the right place with a clear purpose.

## Inputs
- Behavior to cover.
- Target module or API.
- Correct test layer.
- Expected validation command.

## Steps
1. Load [skill: testing-rust](../skills/testing-rust/SKILL.md) and [skill: rust-coding](../skills/rust-coding/SKILL.md) before acting.
2. Read the owning module, existing tests in the same layer, the test placement rules, and the current failing or missing behavior before editing.
3. Choose the right home first, keep the test focused on externally visible behavior, and avoid hiding product bugs behind test-only scaffolding.
4. Run the narrowest test target that includes the new test and confirm the test proves the intended behavior.

## Success Criteria
- [ ] The prompt goal was completed: Add one integration test in the right place with a clear purpose.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-integration-test behavior=save_roundtrip layer=tests/rust

## CAG Metadata
Mode: agent
Loads skills: testing-rust, rust-coding
Inputs required: Behavior to cover., Target module or API., Correct test layer., Expected validation command.
