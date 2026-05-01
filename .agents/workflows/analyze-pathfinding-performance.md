---
description: "Analyze pathfinding cost, search hotspots, or route-quality regressions."
---

# Analyze Pathfinding Performance

## Goal
- Explain the main pathfinding performance bottleneck or architectural pressure point.

## Inputs
- Pathfinding scenario.
- Target map or content set.
- Observed slowdown or quality issue.
- Any trace or timing data.

## Steps
1. Load performance-profiling and module-architecture before acting.
2. Gather relevant source material from pathfinding code, timing output, sample maps, and nearby specs or tests.
3. Measure the dominant cost driver, note whether the issue is algorithmic, data-shape, or call-frequency driven.
4. Return the likely owner path, the highest-value next experiment, and any content patterns that amplify the problem.

## Success Criteria
- [ ] The data or source scope is explicit.
- [ ] Findings are evidence-backed and quantified where possible.
- [ ] Assumptions and open questions are separated from facts.
- [ ] A next owner or next validation step is clear.

## Anti-patterns
- Give generic advice with no repo evidence or measured signal.
- Mix facts, guesses, and recommendations into one vague paragraph.

## Example Invocation
- /analyze-pathfinding-performance map=content/games/maze slowdown=spikes
