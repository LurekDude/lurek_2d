---
description: "Fix current compilation errors in the narrowest owner slice."
---

# Fix Compilation Errors

## Goal
- Take one failing compile path back to green.

## Inputs
- Failing command or target.
- Relevant files.
- Error output.
- Acceptance gate.

## Steps
1. Load rust-coding, error-handling, and quality-pipeline before acting.
2. Reproduce the failure from the failing cargo output, the named files, and the smallest owning module or bridge slice.
3. Address the compile error in the owner layer, prefer a real type or contract fix over temporary workarounds, and avoid unrelated cleanup.
4. Rerun the same failing compile target first, then run the broader named gate if the narrow fix passed.

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
- /fix-compilation-errors target=graphics error=E0308
