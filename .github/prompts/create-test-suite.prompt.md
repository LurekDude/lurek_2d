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
4. For every `it()`, add the suite marker directly above it (same indentation, no blank lines): `unit -> @covers`, `security -> @security`, `integration -> @integration`, `stress -> @stress`, `evidence -> @evidence`. For unit tests, list one symbol per `@covers` line and only symbols called in that `it()`. Never use `-- @tests`. Never group markers above a `describe()`.
5. For legacy cleanup work, process files in batches of max 3: read each file fully, apply manual corrections, and validate those exact files before moving to the next batch.
6. Run `python tools/audit/lua_test_structure_audit.py --path <file>` for each touched file and confirm PASS before widening validation.
7. Run the narrowest suite or target that covers the new tests and confirm the suite proves real behavior rather than scaffolding.

## Success Criteria
- [ ] The prompt goal was completed: Add a coherent test suite for one behavior slice.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.
- Use `-- @tests` (forbidden).
- Put suite markers at column 0 when `it()` is indented.
- Add marker symbols not called inside the `it()` body.
- Group markers above `describe()` instead of above each `it()`.
- Rewrite markers repo-wide in one pass without per-file review.

## Example Invocation
- /create-test-suite area=pathfind layer=tests/rust/unit

## CAG Metadata
Mode: agent
Loads skills: testing-rust
Inputs required: Behavior area., Target layer., Required fixtures or harness., Expected validation command.
