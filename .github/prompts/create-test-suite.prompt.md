---
description: "Create integration or unit tests for a Lurek2D module with proper patterns and coverage."
mode: agent
loads_skills: [testing-rust]
loads_tools: []
expected_agent: Tester
inputs_required: [expected, module, scenario, subject]
---

# Create Test Suite

## Goal

Write tests for a Lurek2D module following proper test conventions.

## Inputs

- **Module**: Which module to test
- **Coverage goal**: What scenarios to cover (happy path, edge cases, errors)

## Steps

1. Load [skill: testing-rust](.github/skills/testing-rust/SKILL.md) before changing any files.
2. Read the module's public API
3. Identify test scenarios: happy path, edge cases, error conditions
4. Write integration tests in `tests/<module>_tests.rs`
5. Use descriptive names: `test_<subject>_<scenario>_<expected>`
6. Float comparisons with tolerance: `(val - expected).abs() < 1e-5`
7. Run `cargo test`

## Success Criteria

- [ ] Tests cover happy path and edge cases
- [ ] Float comparisons use tolerance
- [ ] Test names describe scenarios
- [ ] All tests pass deterministically

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-test-suite <expected> <module> <scenario> <subject>`
