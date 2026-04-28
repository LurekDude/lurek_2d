---
description: "Fix failing tests."
---

# Fix Failing Tests

## Goal
- Diagnose and fix test failures.

## Inputs
- **Failing test(s)**: Which tests are failing
- **Error output**: Test failure messages

## Steps
- Load dev-debugging, testing-rust before changing any files.
- Run cargo test and capture the failure output
- Read the failing test code
- Determine if the bug is in the test or the production code
- Fix the appropriate code
- Run cargo test to verify all pass

## Success Criteria
- [ ] Root cause of failure identified
- [ ] Fix applied (test or production code)
- [ ] All tests pass
- [ ] No tests deleted to make suite pass

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /fix-failing-tests

## CAG Metadata
- **Mode**: agent
- **Loads skills**: dev-debugging, testing-rust
