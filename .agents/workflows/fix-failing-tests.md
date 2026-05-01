---
description: "Analyze and fix failing tests across Lua and Rust test layers."
---

# Fix Failing Tests

## Goal
- Restore all failing tests to green without touching production code unless a genuine bug is found.

## Inputs
- Failing test command and output.
- Module or test layer in scope.
- Acceptance gate.

## Steps
1. Load testing-rust, rust-coding, and error-handling before acting.
2. Run the failing test command and collect the full error output.
3. Determine if the failure is a test bug (wrong assertion, stale fixture) or a product bug exposed by the test.
4. Fix test-only issues in the test file. If a product bug is found, fix it at the source per fix-engine-bug rules.
5. Rerun the narrowest failing target, then the broader suite gate.

## Success Criteria
- [ ] All previously failing tests now pass.
- [ ] No test assertions were silently weakened.
- [ ] cargo test passes for the touched scope.

## Example Invocation
- /fix-failing-tests target=tests/lua/unit/test_timer_unit.lua
