---
description: "Fix one engine bug in the smallest owner slice with focused validation."
agent: "Developer"
---
# Fix Engine Bug

## Goal
- Fix one concrete engine bug at the source.

## Inputs
- Bug symptom.
- Repro or failing test.
- Target subsystem.
- Acceptance gate.

## Steps
1. Load [skill: dev-debugging](../skills/dev-debugging/SKILL.md), [skill: error-handling](../skills/error-handling/SKILL.md), and [skill: rust-coding](../skills/rust-coding/SKILL.md) before acting.
2. Reproduce the failure from the smallest reproducer, nearby tests, the owning module, and the accepted contract source.
3. Change only the logic that controls the failing behavior, keep ownership boundaries intact, and add or update a test when the bug lacked coverage.
4. Rerun the same reproducer or failing test first, then run the broader required check if the bug is fixed.

## Success Criteria
- [ ] The failure was reproduced or tightly localized.
- [ ] The owner slice was fixed at the source.
- [ ] The failing check now passes.
- [ ] No unrelated drift was introduced.

## Anti-patterns
- Patch symptoms in a different layer from the one that owns the failure.
- Skip the smallest reproducer and guess at the fix.
- Keep editing after the first change instead of rerunning the failing check.

## Example Invocation
- /fix-engine-bug subsystem=timer symptom=repeat_callback_skips

## CAG Metadata
Mode: agent
Loads skills: dev-debugging, error-handling, rust-coding
Inputs required: Bug symptom., Repro or failing test., Target subsystem., Acceptance gate.
