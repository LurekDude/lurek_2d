---
description: "Load when analyzing or optimizing frame time, allocations, hot paths, rendering throughput, or Lua-Rust overhead. Skip for correctness bugs or feature work."
alwaysApply: false
---

# performance-profiling

## Mission
- Own measurement-first performance analysis for frame time and hot paths.

## When To Load
- Measure a slowdown.
- Analyze allocations.
- Find a hot path.
- Compare performance across scenarios.

## When To Skip
- Correctness bugs.
- Feature implementation.

## Domain Knowledge
- Release mode and an explicit scenario are required; dev-mode impressions are noise and should not drive engine-level optimization decisions.
- tools/audit/stress_report.py and quality_report.py already provide repo-level signals worth checking before ad hoc guesses or micro-optimizations.
- Split render, physics, Lua boundary, allocation, and content-side costs instead of reporting one blended slow number; the next owner needs to know where the budget is actually going.
- The project budget anchor remains 60 FPS at 1080p on integrated GPUs, so measurements should speak to that target rather than an abstract benchmark.
- Watch per-frame Vec growth, texture churn, callback allocation, buffer rebuilds, and unnecessary cross-layer work, not only the hottest CPU function.
- Return measured current values, target values, scenario details, and estimated savings so recommendations are comparable and actionable.
- Measured scenarios should name the actual subsystem and content path being exercised, such as a render-heavy demo, physics scene, or Lua callback loop.
- Compare before and after using the same build mode, same content, and same capture method; otherwise the numbers are not trustworthy enough to guide work.
- Performance analysis should identify whether the limiting factor is CPU, GPU, boundary overhead, memory churn, or content shape before prescribing a fix.
- Intel-class integrated GPU and 1080p are still the practical frame-budget anchor for this repo, so optimization claims should stay grounded in that target hardware class.

## References
- src/render/
- src/physics/
- tools/audit/stress_report.py
- tools/audit/quality_report.py
