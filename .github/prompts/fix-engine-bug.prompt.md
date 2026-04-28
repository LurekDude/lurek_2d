---
description: "Fix a Lurek2D engine bug."
---

# Fix Engine Bug

## Goal
- Systematic bug fix workflow: reproduce diagnose fix verify.

## Inputs
- **Symptom**: What's going wrong (error message, unexpected behavior, crash)
- **Reproduction**: How to trigger the bug
- **Affected module**: Which part of the engine

## Steps
- Load dev-debugging, error-handling before changing any files.
- Reproduce the bug with a minimal test case or Lua script
- Read the relevant code and trace the data flow
- Identify root cause with specific file and line
- Implement the fix
- Write a regression test that would have caught the bug
- Run cargo test and cargo clippy

## Success Criteria
- [ ] Root cause identified and documented
- [ ] Fix addresses root cause (not just symptoms)
- [ ] Regression test added
- [ ] All existing tests pass
- [ ] cargo clippy clean

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /fix-engine-bug

## CAG Metadata
- **Mode**: agent
- **Loads skills**: dev-debugging, error-handling
