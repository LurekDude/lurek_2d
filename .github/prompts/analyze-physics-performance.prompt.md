---
description: "Analyze physics performance and hot spots."
---

# Analyze Physics Performance

## Goal
- ---.

## Inputs
- BODY_COUNT number of bodies in the scene when slowdown appears
- PROFILE_DATA optional output from cargo flamegraph or manual timing

## Steps
- Load performance-profiling before changing any files.
- Load skill performance-profiling/SKILL.md
- Load skill physics-engine/SKILL.md
- Read src/physics/world.rs step() function identify the collision detection loop
- Analyze collision detection complexity: is it O(N ) all-pairs or better?
- Check for per-frame allocations inside step() (Vec::new, collect, etc.)
- Measure force accumulation and velocity integration cost separately
- Identify scaling bottlenecks as body count increases (> 50, > 200, > 1000)
- If O(N ) is confirmed, recommend broad-phase (spatial hash, AABB sweep-and-prune)

## Success Criteria
- [ ] Complexity analysis of the collision detection loop
- [ ] Per-frame allocation sites found (if any)
- [ ] Scaling behaviour table (bodies estimated step time)
- [ ] Prioritized recommendations

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /analyze-physics-performance

## CAG Metadata
- **Mode**: agent
- **Loads skills**: performance-profiling
