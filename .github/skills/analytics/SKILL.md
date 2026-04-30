---
name: analytics
description: "Load this skill when collecting or reading logs, telemetry, SQL results, DataFrame tables, perf counters, or session records for analysis. Skip it for live bug debugging or for adding log output."
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
- Primary evidence lives in logs/data/, logs/reports/, save/, and structured outputs from tools/audit/, so analysis should start from saved artifacts instead of recollected anecdotes.
- src/dataframe/query.rs, sql.rs, and vectorized.rs define the in-engine table and SQL surface available for analysis; use that mental model when deciding which fields can be grouped, filtered, or derived reliably.
- Separate engine-quality telemetry from gameplay, economy, progression, and balance telemetry before drawing conclusions; a frame-time regression and a bad drop-rate curve are different questions even if they share one log source.
- Compare cohorts, versions, modules, or content slices instead of relying on global totals; raw counts often hide which scene, build, or ruleset is actually responsible for a trend.
- Check sample size, missing fields, outliers, mixed-version data, and partial captures before trusting a metric; this repo contains both manual saves and generated reports, and they do not always have identical schema quality.
- Prefer reproducible queries and small derived tables over ad hoc manual counting so later discussion can rerun the same logic with new input data.
- For balance questions, compare encounter outcomes, economy sinks, build variants, progression slices, or content branches rather than only total wins, losses, or currency totals.
- For quality questions, separate warnings, crashes, slow paths, and noisy but non-fatal events; one blended severity bucket usually hides the operational question the user actually asked.
- If telemetry cannot answer the question cleanly, report the missing field, inconsistent schema, or broken capture path instead of inventing a proxy metric with false precision.
## Companion File Index
- None.

## References
- logs/data/
- logs/reports/
- src/dataframe/
- docs/specs/dataframe.md
- tools/audit/test_analytics.py
