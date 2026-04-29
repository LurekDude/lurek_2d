---
name: performance-profiling
description: "Load this skill when analyzing or optimizing frame time, allocations, hot paths, rendering throughput, or Lua-Rust overhead. Skip it for correctness bugs or feature work."
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
- Release mode and an explicit scenario are required; dev-mode impressions are noise.
- tools/audit/stress_report.py and quality_report.py already provide repo-level signals worth using before ad hoc guesses.
- Split render, physics, Lua boundary, and allocation costs instead of reporting one blended slow number.
- The project budget anchor is 60 FPS at 1080p on integrated GPUs.
- Watch per-frame Vec growth, texture churn, and callback allocation, not only CPU hotspots.
- Return measured current values, target values, and estimated savings.
- Measured scenarios should reference the actual subsystem and content path being exercised, such as render-heavy demos, physics scenes, or Lua callback loops.
- Intel-class integrated GPU and 1080p are still the practical frame-budget anchor for this repo.
- The skill owns measurement design and prioritization, not implementation of the optimizations it recommends.
## Companion File Index
- None.

## References
- src/render/
- src/physics/
- tools/audit/stress_report.py
- tools/audit/quality_report.py
