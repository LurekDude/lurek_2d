---
description: "Load when diagnosing runtime bugs, crashes, or wrong behavior in Lurek2D. Skip for feature work or test writing."
alwaysApply: false
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
- logs/, tests/, content/, and save/ already contain many repro anchors, so start from an existing failing script, fixture, or save-state before reading large areas of src/.
- Trace from the lurek.* symptom or user-visible failure to the controlling src/<module>/ or src/lua_api/ boundary, and stop as soon as one concrete control path explains the observed behavior.
- The common failure surfaces in this repo are SharedState borrowing, RefCell lifetime leaks across callbacks, wrong callback order, stale registries, and state transitions that skip one edge case.
- Build the smallest deterministic repro first; one narrowed Lua test, smoke case, or content script is worth more than broad speculative reading across unrelated modules.
- Use tools/audit/parse_test_log.py for harness output instead of scrolling raw logs, especially when the same suite already prints structured pass or fail context.
- Separate failure classes early: crash, wrong result, missing side effect, stale state, race or ordering issue, and backend-specific behavior each imply a different next hop.
- When a bug crosses the Lua boundary, compare the public contract in docs/specs or generated docs with the binding behavior in src/lua_api/ before blaming engine internals.
- Prefer one cheap discriminating check after each theory: a narrowed test, a single content repro, or a direct state readback that can falsify the current hypothesis quickly.
- Existing harnesses and smoke tests can often be narrowed into a bug repro faster than writing fresh scripts, and they give you a stable path to validate the eventual fix.
- If a save file or content asset triggers the problem, record the exact path and visible symptom so the repro stays portable.

## References
- logs/
- tests/
- src/
- tools/audit/parse_test_log.py
