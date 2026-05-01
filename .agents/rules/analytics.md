---
description: "Load when collecting or reading logs, telemetry, SQL results, DataFrame tables, perf counters, or session records for analysis. Skip for live bug debugging or adding log output."
alwaysApply: false
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
- Primary evidence lives in logs/data/, logs/reports/, save/, and structured outputs from tools/audit/, so analysis should start from saved artifacts.
- src/dataframe/query.rs, sql.rs, and vectorized.rs define the in-engine table and SQL surface; use that mental model when deciding which fields can be grouped or filtered reliably.
- Separate engine-quality telemetry from gameplay, economy, progression, and balance telemetry before drawing conclusions.
- Compare cohorts, versions, modules, or content slices instead of relying on global totals.
- Check sample size, missing fields, outliers, mixed-version data, and partial captures before trusting a metric.
- Prefer reproducible queries and small derived tables over ad hoc manual counting.
- For quality questions, separate warnings, crashes, slow paths, and noisy but non-fatal events.
- If telemetry cannot answer the question cleanly, report the missing field or inconsistent schema.

## References
- logs/data/
- logs/reports/
- src/dataframe/
- docs/specs/dataframe.md
- tools/audit/test_analytics.py
