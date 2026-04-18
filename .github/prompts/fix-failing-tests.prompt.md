---
description: "Fix failing tests: diagnose why tests fail and correct either the test or the code."
mode: agent
loads_skills: [dev-debugging, testing-rust]
loads_tools: []
expected_agent: Tester
inputs_required: []
---

# Fix Failing Tests

## Goal

Diagnose and fix test failures.

## Inputs

- **Failing test(s)**: Which tests are failing
- **Error output**: Test failure messages

## Steps

1. Load [skill: dev-debugging](.github/skills/dev-debugging/SKILL.md), [skill: testing-rust](.github/skills/testing-rust/SKILL.md) before changing any files.
2. Run `cargo test` and capture the failure output
3. Read the failing test code
4. Determine if the bug is in the test or the production code
5. Fix the appropriate code
6. Run `cargo test` to verify all pass

## Success Criteria

- [ ] Root cause of failure identified
- [ ] Fix applied (test or production code)
- [ ] All tests pass
- [ ] No tests deleted to make suite pass

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-failing-tests`
