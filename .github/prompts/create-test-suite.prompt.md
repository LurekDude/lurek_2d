---
description: "Create integration or unit tests for a Lurek2D module with proper patterns and coverage."
---

# Create Test Suite

## Purpose

Write tests for a Lurek2D module following proper test conventions.

## Inputs

- **Module**: Which module to test
- **Coverage goal**: What scenarios to cover (happy path, edge cases, errors)

## Steps

1. Read the module's public API
2. Identify test scenarios: happy path, edge cases, error conditions
3. Write integration tests in `tests/<module>_tests.rs`
4. Use descriptive names: `test_<subject>_<scenario>_<expected>`
5. Float comparisons with tolerance: `(val - expected).abs() < 1e-5`
6. Run `cargo test`

## Acceptance

- [ ] Tests cover happy path and edge cases
- [ ] Float comparisons use tolerance
- [ ] Test names describe scenarios
- [ ] All tests pass deterministically

## References

- `testing-rust` skill
- `tests/` directory
