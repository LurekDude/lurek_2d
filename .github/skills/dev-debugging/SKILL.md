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
- Start from the symptom and form a few local hypotheses.
- Build the smallest deterministic repro.
- Trace from the lurek.* edge inward.
- Check SharedState, RefCell, and state transitions.
- Re-run the repro before final report.
- Report root cause, not only symptom.
- Route fixes to Developer and tests to Tester.

## Companion File Index
- None.

## References
- logs/
- tests/
- src/
