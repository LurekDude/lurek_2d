---
description: "Fix a bug in the Lurek2D engine: diagnose root cause, implement fix, verify with tests."
---

# Fix Engine Bug

## Purpose

Systematic bug fix workflow: reproduce → diagnose → fix → verify.

## Inputs

- **Symptom**: What's going wrong (error message, unexpected behavior, crash)
- **Reproduction**: How to trigger the bug
- **Affected module**: Which part of the engine

## Steps

1. Reproduce the bug with a minimal test case or Lua script
2. Read the relevant code and trace the data flow
3. Identify root cause with specific file and line
4. Implement the fix
5. Write a regression test that would have caught the bug
6. Run `cargo test` and `cargo clippy`

## Acceptance

- [ ] Root cause identified and documented
- [ ] Fix addresses root cause (not just symptoms)
- [ ] Regression test added
- [ ] All existing tests pass
- [ ] `cargo clippy` clean

## References

- `dev-debugging` skill
- `error-handling` skill
