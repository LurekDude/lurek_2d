---
description: ﻿---.
agent: Physicist
---
# Analyze Physics Performance

## Goal

﻿---. The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `BODY_COUNT` — number of bodies in the scene when slowdown appears
- `PROFILE_DATA` — optional output from `cargo flamegraph` or manual timing

## Steps

1. Load [skill: performance-profiling](.github/skills/performance-profiling/SKILL.md) before changing any files.
2. Load skill `performance-profiling/SKILL.md`
3. Load skill `physics-engine/SKILL.md`
4. Read `src/physics/world.rs` `step()` function — identify the collision detection loop
5. Analyze collision detection complexity: is it O(N²) all-pairs or better?
6. Check for per-frame allocations inside `step()` (Vec::new, collect, etc.)
7. Measure force accumulation and velocity integration cost separately
8. Identify scaling bottlenecks as body count increases (> 50, > 200, > 1000)
9. If O(N²) is confirmed, recommend broad-phase (spatial hash, AABB sweep-and-prune)

## Success Criteria

- [ ] Complexity analysis of the collision detection loop
- [ ] Per-frame allocation sites found (if any)
- [ ] Scaling behaviour table (bodies → estimated step time)
- [ ] Prioritized recommendations

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/analyze-physics-performance`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: performance-profiling
