---
description: "Analyze physics engine performance: collision detection scaling, world step cost, body count impact. Use during optimization or when physics slows below 60 fps."
---

# Analyze Physics Performance

**Purpose**: Profile the Luna2D physics engine to find bottlenecks in collision detection, force accumulation, and world step cost.
**Use When**: Frame rate degrades as body count increases, or `luna.physics` step time exceeds 4 ms.
**Do Not Use When**: The issue is rendering performance — use `analyze-render-performance.prompt.md`.
**Scope**: `src/physics/world.rs`, `src/physics/collision.rs`.

## Inputs

- `BODY_COUNT` — number of bodies in the scene when slowdown appears
- `PROFILE_DATA` — optional output from `cargo flamegraph` or manual timing

## Steps

1. Load skill `performance-profiling/SKILL.md`
2. Load skill `physics-engine/SKILL.md`
3. Read `src/physics/world.rs` `step()` function — identify the collision detection loop
4. Analyze collision detection complexity: is it O(N²) all-pairs or better?
5. Check for per-frame allocations inside `step()` (Vec::new, collect, etc.)
6. Measure force accumulation and velocity integration cost separately
7. Identify scaling bottlenecks as body count increases (> 50, > 200, > 1000)
8. If O(N²) is confirmed, recommend broad-phase (spatial hash, AABB sweep-and-prune)

## Outputs

- Complexity analysis of the collision detection loop
- Per-frame allocation sites found (if any)
- Scaling behaviour table (bodies → estimated step time)
- Prioritized recommendations

## Acceptance

- [ ] Collision detection complexity documented (O(N) or O(N²) with justification)
- [ ] Per-frame allocations in physics step identified or ruled out
- [ ] Scaling behaviour analyzed
- [ ] Recommendations are actionable (specific to `src/physics/`)

## References

**Required Skills**: `performance-profiling`, `physics-engine`
**Suggested Agents**: `Optimizer`, `Physicist`
**Related Prompts**: `analyze-render-performance.prompt.md`, `create-physics-feature.prompt.md`
**Docs**: `src/physics/world.rs`, `src/physics/collision.rs`
