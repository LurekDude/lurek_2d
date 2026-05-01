---
description: "Write and run tests for one Rust module or Lua API surface with correct layer placement."
---

# Create Test Suite

## Goal
- Author a complete, correctly-placed test suite for one module or surface.

## Inputs
- Module or API surface under test.
- Expected behavior and invariants.
- Preferred test layer (Lua or Rust unit).

## Steps
1. Load testing-rust and add one narrower skill if the module demands it.
2. Read the spec, nearby tests, and docs/specs/<module>.md before choosing the layer.
3. Put lurek.*-reachable behavior in tests/lua/, Rust-only internals in tests/rust/unit/<module>_tests.rs.
4. End each Lua file with test_summary(), add @covers markers, and register new Lua tests in tests/lua/harness.rs.
5. Run the narrowest test command first, then widen only after the target slice is green.

## Success Criteria
- [ ] The test layer matches Lua-first rules.
- [ ] New assertions guard a real regression or invariant.
- [ ] Harness or target wiring is updated.
- [ ] Scoped and final test runs both pass.

## Anti-patterns
- Create windowed or non-headless tests.
- Use float equality without epsilon.
- Depend on test order or ambient filesystem state.
- Put tests inside src/.

## Example Invocation
- /create-test-suite module=timer layer=lua
