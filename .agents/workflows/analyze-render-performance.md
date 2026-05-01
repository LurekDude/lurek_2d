---
description: "Analyze render performance: frame time, draw call budget, and GPU throughput for a named scenario."
---

# Analyze Render Performance

## Goal
- Measure and report render performance for a named scenario.

## Inputs
- Demo or scenario to profile.
- Target metric (frame time, draw calls, GPU time).
- Build mode (release required).

## Steps
1. Load performance-profiling before acting.
2. Build in release mode. Do not use dev-mode timings.
3. Run the named scenario and capture frame time, draw call count, and GPU time.
4. Compare against the 60 FPS / 1080p integrated GPU budget.
5. Identify the largest bottleneck (render, physics, Lua, allocation) and return measured values, target, and delta.

## Success Criteria
- [ ] Measurements are from release mode.
- [ ] Frame time, draw calls, and GPU time are reported.
- [ ] Bottleneck is identified, not just the total budget.
- [ ] Scenario details are explicit.

## Example Invocation
- /analyze-render-performance scenario=content/games/demo_platformer.lua
