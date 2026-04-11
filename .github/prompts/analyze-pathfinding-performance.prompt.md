---
description: "Analyze and optimize pathfinding performance: A★ cost, grid size impact, HPA★ preprocessing, flow field computation, and multi-unit coordination. Use when pathfinding causes frame drops."
---

# Analyze Pathfinding Performance

## Prerequisites

- Read `src/pathfind/mod.rs` for algorithm inventory
- Read `tests/rust/unit/pathfinding_tests.rs` for test setup patterns
- Load the `pathfinding-systems` skill and `performance-profiling` skill

## Steps

1. **Identify the bottleneck**
   - Which algorithm is slow? (A★, HPA★, FlowField)
   - What grid size and how many simultaneous pathfinding requests?
   - Is pathfinding running synchronously or via PathThreadPool?

2. **Measure current performance**
   - Time A★ calls for representative grid sizes (50x50, 100x100, 200x200)
   - Count pathfinding requests per frame
   - Measure NavGrid cell count and diagonal mode impact

3. **Evaluate algorithm selection**
   | Grid Size | Agents | Recommended |
   |---|---|---|
   | <100x100 | <10 | A★ (synchronous) |
   | <100x100 | 10-50 | A★ via PathThreadPool |
   | >200x200 | <10 | HPA★ (precomputed) |
   | Any | >50 same target | FlowField |

4. **Apply optimizations**
   - Switch to HPA★ for large static maps — precompute abstract graph at load
   - Use FlowField for crowd movement toward shared targets
   - Enable PathThreadPool for non-blocking pathfinding
   - Use `smooth_path()` sparingly — it adds post-processing cost
   - Reduce NavGrid resolution if precision allows
   - Cache paths and reuse when start/end haven't changed

5. **Verify improvement**
   - Re-measure after optimization
   - Confirm path quality hasn't degraded (visual inspection)
   - Run pathfinding stress tests

## Acceptance Criteria

- [ ] Pathfinding stays within frame budget (< 2ms per frame)
- [ ] No frame drops during heavy pathfinding
- [ ] Path quality acceptable (no excessive detours)
- [ ] Algorithm selection matches grid size and agent count
