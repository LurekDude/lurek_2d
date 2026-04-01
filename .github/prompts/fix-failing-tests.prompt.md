---
description: "Fix failing tests: diagnose why tests fail and correct either the test or the code."
---

# Fix Failing Tests

## Purpose

Diagnose and fix test failures.

## Inputs

- **Failing test(s)**: Which tests are failing
- **Error output**: Test failure messages

## Steps

1. Run `cargo test` and capture the failure output
2. Read the failing test code
3. Determine if the bug is in the test or the production code
4. Fix the appropriate code
5. Run `cargo test` to verify all pass

## Acceptance

- [ ] Root cause of failure identified
- [ ] Fix applied (test or production code)
- [ ] All tests pass
- [ ] No tests deleted to make suite pass

## References

- `testing-rust` skill
- `dev-debugging` skill
