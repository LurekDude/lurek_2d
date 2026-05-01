---
description: "Analyze memory usage and allocations for a specific Lurek2D scenario or module."
---

# Analyze Memory Usage

## Goal
- Identify memory allocation hotspots and per-frame allocation churn for a named scenario.

## Inputs
- Scenario or module to profile.
- Known memory concern (leaks, churn, peak usage).

## Steps
1. Load performance-profiling before acting.
2. Build in release mode with debug symbols if needed.
3. Run the scenario and capture allocation count, peak memory, and per-frame allocation delta.
4. Identify the top three allocation sites: Vec growth, texture churn, or Lua boundary allocation.
5. Return measured values with source locations and recommended fixes.

## Success Criteria
- [ ] Measurements are from release mode.
- [ ] Top allocation sites are identified with source locations.
- [ ] Scenario is explicit and reproducible.

## Example Invocation
- /analyze-memory-usage scenario=content/games/demo_platformer.lua concern=per-frame-churn
