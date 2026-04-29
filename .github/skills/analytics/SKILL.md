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
- Primary evidence lives in logs/data/, logs/reports/, save/, and structured outputs from tools/audit/.
- src/dataframe/query.rs, sql.rs, and vectorized.rs define the in-engine table and SQL surface available for analysis.
- Separate engine-quality telemetry from gameplay, economy, progression, and balance telemetry before drawing conclusions.
- Compare cohorts, versions, or content slices; raw totals alone rarely answer balance questions.
- Check sample size, missing fields, outliers, and mixed-version data before trusting a metric.
- Prefer reproducible queries and small derived tables over ad hoc manual counting.
- This repo already stores useful analysis inputs in logs/data/, logs/reports/, save/, and src/dataframe/ helpers like sql.rs and query.rs, so analysis should start from structured evidence instead of free-form reading.
- For balance questions, compare encounter outcomes, economy sinks, build variants, or progression slices rather than only total counts.
- If telemetry cannot answer the question cleanly, report the missing field or broken capture path instead of inventing a proxy metric.
## Companion File Index
- None.

## References
- logs/data/
- logs/reports/
- src/dataframe/
- docs/specs/dataframe.md
- tools/audit/test_analytics.py
