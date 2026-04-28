---
description: "Create a new test suite for a module."
---

# Create Test Suite

## Goal
- Write tests for a Lurek2D module following proper test conventions.

## Inputs
- **Module**: Which module to test
- **Coverage goal**: What scenarios to cover (happy path, edge cases, errors)

## Steps
- Load testing-rust before changing any files.
- Read the module's public API
- Identify test scenarios: happy path, edge cases, error conditions
- Write integration tests in tests/<module>_tests.rs
- Use descriptive names: test_<subject>_<scenario>_<expected>
- Float comparisons with tolerance: (val - expected).abs() < 1e-5
- Run cargo test

## Success Criteria
- [ ] Tests cover happy path and edge cases
- [ ] Float comparisons use tolerance
- [ ] Test names describe scenarios
- [ ] All tests pass deterministically

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-test-suite <expected> <module> <scenario> <subject>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: testing-rust
- **Inputs required**: expected, module, scenario, subject
