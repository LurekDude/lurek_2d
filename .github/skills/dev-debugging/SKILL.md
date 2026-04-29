---
name: dev-debugging
description: "Load this skill when diagnosing runtime bugs, crashes, or wrong behavior in Lurek2D. Skip it for feature work or test writing."
---
# dev-debugging

## Mission
- Own runtime diagnosis, repro building, and root-cause reporting.

## When To Load
- Investigate a crash.
- Investigate wrong runtime behavior.
- Read logs and traces.
- Build a small repro.

## When To Skip
- Feature implementation.
- Test authoring.

## Domain Knowledge
- logs/, tests/, content/, and save/ already contain many repro anchors; start there before instrumenting code.
- Trace from the lurek.* symptom or user-visible failure to the controlling src/<module>/ or src/lua_api/ boundary.
- SharedState, RefCell lifetime, callback order, and state transitions are common failure surfaces in this repo.
- Use tools/audit/parse_test_log.py for harness output instead of scanning long raw logs by hand.
- Build the smallest deterministic repro first; only add logging when one discriminating check still is missing.
- Report root cause, confidence, and smallest fix slice separately.
- Repro quality matters more than raw code reading: one small failing scenario in tests/, content/, or save/ is worth more than broad speculative scanning.
- Existing harnesses and smoke tests can often be narrowed into a bug repro faster than writing fresh scripts from scratch.
- This skill owns diagnosis flow and evidence quality; it does not own final fixes or coverage additions.
## Companion File Index
- None.

## References
- logs/
- tests/
- src/
- tools/audit/parse_test_log.py
