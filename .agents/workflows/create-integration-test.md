---
description: "Create an integration test that validates one cross-module behavior end to end."
---

# Create Integration Test

## Goal
- Author one integration test that validates a cross-module behavior from the Lua surface down.

## Inputs
- Behavior under test.
- Modules involved.
- Expected observable outcome.

## Steps
1. Load testing-rust and lua-scripting before acting.
2. Read tests/lua/ for the nearest existing integration test pattern.
3. Write a Lua test in tests/lua/unit/ that exercises the cross-module path from lurek.* calls to the expected outcome.
4. Register the test in tests/lua/harness.rs.
5. Run cargo test -- <test_name> to confirm it passes.

## Success Criteria
- [ ] The test covers the full cross-module path from Lua API to outcome.
- [ ] Test is registered in harness.rs.
- [ ] Test passes on first run.
- [ ] No windowed or environment-dependent setup.

## Example Invocation
- /create-integration-test behavior=save_load_roundtrip modules=save,filesystem
