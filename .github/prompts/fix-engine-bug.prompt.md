---
description: "Fix a bug in the Lurek2D engine: diagnose root cause, implement fix, verify with tests."
agent: Developer
---
# Fix Engine Bug

## Goal

Systematic bug fix workflow: reproduce → diagnose → fix → verify.

## Inputs

- **Symptom**: What's going wrong (error message, unexpected behavior, crash)
- **Reproduction**: How to trigger the bug
- **Affected module**: Which part of the engine

## Steps

1. Load [skill: dev-debugging](.github/skills/dev-debugging/SKILL.md), [skill: error-handling](.github/skills/error-handling/SKILL.md) before changing any files.
2. Reproduce the bug with a minimal test case or Lua script
3. Read the relevant code and trace the data flow
4. Identify root cause with specific file and line
5. Implement the fix
6. Write a regression test that would have caught the bug
7. Run `cargo test` and `cargo clippy`

## Success Criteria

- [ ] Root cause identified and documented
- [ ] Fix addresses root cause (not just symptoms)
- [ ] Regression test added
- [ ] All existing tests pass
- [ ] `cargo clippy` clean

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-engine-bug`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: dev-debugging, error-handling
