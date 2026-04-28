---
name: analytics
description: "Load this skill when collecting or reading logs, telemetry, perf counters, or session records for analysis. Skip it for live bug debugging or for adding log output."
---
# analytics

## Mission
- Own offline analysis of logs, telemetry, and session records.

## When To Load
- Read engine logs for trends.
- Analyze saved telemetry or session events.
- Summarize crash or warning patterns.
- Compare measurements across runs.

## When To Skip
- Live bug debugging.
- Adding or tuning log output.

## Domain Knowledge
- Prefer offline parsing over ad hoc guessing.
- Keep findings tied to saved evidence files.
- Separate engine telemetry from game telemetry.
- Report counts, trends, and outliers, not vague impressions.
- Use tools/audit/ when a repo tool already exists for the analysis.
- Keep output structured so another agent can act on it.

## Companion File Index
- None.

## References
- logs/
- tools/audit/
- docs/specs/