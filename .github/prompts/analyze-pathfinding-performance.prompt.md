---
description: "Analyze and optimize pathfinding performance: A★ cost, grid size impact, HPA★ preprocessing, flow field computation, and multi-unit coord..."
mode: agent
loads_skills: [performance-profiling]
loads_tools: []
expected_agent: Optimizer
inputs_required: []
---

# Analyze Pathfinding Performance

## Goal

Analyze and optimize pathfinding performance: A★ cost, grid size impact, HPA★ preprocessing, flow field computation, and multi-unit coord... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. Load [skill: performance-profiling](.github/skills/performance-profiling/SKILL.md) before changing any files.
2. **Identify the bottleneck**
3. Which algorithm is slow? (A★, HPA★, FlowField)
4. What grid size and how many simultaneous pathfinding requests?
5. Is pathfinding running synchronously or via PathThreadPool?
6. **Measure current performance**
7. Time A★ calls for representative grid sizes (50x50, 100x100, 200x200)
8. Count pathfinding requests per frame
9. Measure NavGrid cell count and diagonal mode impact
10. **Evaluate algorithm selection**
11. **Apply optimizations**
12. Switch to HPA★ for large static maps — precompute abstract graph at load

## Success Criteria

- [ ] Pathfinding stays within frame budget (< 2ms per frame)
- [ ] No frame drops during heavy pathfinding
- [ ] Path quality acceptable (no excessive detours)
- [ ] Algorithm selection matches grid size and agent count

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/analyze-pathfinding-performance`
