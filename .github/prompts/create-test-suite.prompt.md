---
description: "Create a bounded test suite for one module or behavior area in the correct layer."
agent: "Tester"
---
# Create Test Suite

## Goal
- Add a coherent test suite for one behavior slice.

## Inputs
- Behavior area.
- Target layer.
- Required fixtures or harness.
- Expected validation command.

## Steps
1. Load [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read existing tests in the same layer, the owning module, harness files, and the repo test placement rules before editing.
3. Keep the suite organized around one capability, reuse the existing harness patterns, and avoid mixing Rust-only internals with Lua-visible behavior in the same layer.
4. Run the narrowest suite or target that covers the new tests and confirm the suite proves real behavior rather than scaffolding.

## Success Criteria
- [ ] The prompt goal was completed: Add a coherent test suite for one behavior slice.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-test-suite area=pathfind layer=tests/rust/unit

## CAG Metadata
Mode: agent
Loads skills: testing-rust
Inputs required: Behavior area., Target layer., Required fixtures or harness., Expected validation command.
