---
description: "Create integration or unit tests for a Luna2D module with proper patterns and coverage."
---

# Create Test Suite

## Purpose

Write tests for a Luna2D module following proper test conventions.

## Inputs

- **Module**: Which module to test
- **Coverage goal**: What scenarios to cover (happy path, edge cases, errors)

## Steps

1. Read the module's public API
2. Identify test scenarios: happy path, edge cases, error conditions
3. Write or extend tests in the appropriate registered Rust test binary and/or `tests/lua/<category>/test_<name>.lua`
4. Use descriptive names: `<subject>_<scenario>_<expected>`
5. Float comparisons with tolerance: `(val - expected).abs() < 1e-5`
6. Run the relevant scoped command: `cargo test --test <binary-name>` and/or `cargo test --test lua_tests <dispatcher-name>`

## Acceptance

- [ ] Tests cover happy path and edge cases
- [ ] Float comparisons use tolerance
- [ ] Test names describe scenarios
- [ ] All tests pass deterministically

## References

- `testing-rust` skill
- `tests/` directory
