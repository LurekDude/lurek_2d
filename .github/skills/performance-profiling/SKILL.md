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
- Measure first and keep the scenario explicit.
- Tie each bottleneck to a specific function or path.
- Report current numbers, target numbers, and estimated savings.
- Prioritize by measured impact, not by ease.
- Watch per-frame allocation patterns, not only CPU time.
- Separate render, physics, and Lua boundary costs in the report when possible.

## Companion File Index
- None.

## References
- src/render/gpu_renderer.rs
- src/physics/
- tools/audit/quality_report.py