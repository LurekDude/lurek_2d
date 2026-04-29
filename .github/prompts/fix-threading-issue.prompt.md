---
description: "Fix one threading or worker-communication issue in the owning layer."
agent: "Developer"
---
# Fix Threading Issue

## Goal
- Fix one threading issue without widening into unrelated runtime work.

## Inputs
- Symptom.
- Repro path.
- Target thread or worker path.
- Acceptance gate.

## Steps
1. Load [skill: dev-debugging](../skills/dev-debugging/SKILL.md) and [skill: error-handling](../skills/error-handling/SKILL.md) before acting.
2. Reproduce the failure from the smallest reproducer, thread or channel code, related tests, and any worker-VM contract notes.
3. Correct the synchronization, ownership, or error path in the controlling code, and keep cross-VM or channel boundaries explicit.
4. Rerun the same reproducer first, then the narrowest threading-focused test or build check before broadening scope.

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
- /fix-threading-issue path=src/thread symptom=deadlock_on_shutdown

## CAG Metadata
Mode: agent
Loads skills: dev-debugging, error-handling
Inputs required: Symptom., Repro path., Target thread or worker path., Acceptance gate.
