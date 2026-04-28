---
description: "Analyze pathfinding performance and hot spots."
---

# Analyze Pathfinding Performance

## Goal
- Analyze and optimize pathfinding performance: A cost, grid size impact, HPA preprocessing, flow field computation, and multi-unit coord...

## Inputs
- None.

## Steps
- Load performance-profiling before changing any files.
- **Identify the bottleneck**
- Which algorithm is slow? (A , HPA , FlowField)
- What grid size and how many simultaneous pathfinding requests?
- Is pathfinding running synchronously or via PathThreadPool?
- **Measure current performance**
- Time A calls for representative grid sizes (50x50, 100x100, 200x200)
- Count pathfinding requests per frame
- Measure NavGrid cell count and diagonal mode impact
- **Evaluate algorithm selection**
- **Apply optimizations**
- Switch to HPA for large static maps precompute abstract graph at load

## Success Criteria
- [ ] Pathfinding stays within frame budget (< 2ms per frame)
- [ ] No frame drops during heavy pathfinding
- [ ] Path quality acceptable (no excessive detours)
- [ ] Algorithm selection matches grid size and agent count

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /analyze-pathfinding-performance

## CAG Metadata
- **Mode**: agent
- **Loads skills**: performance-profiling
