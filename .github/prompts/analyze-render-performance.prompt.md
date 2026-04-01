---
description: "Analyze rendering performance: frame time, draw command throughput, texture memory, wgpu pipeline operations."
---

# Analyze Render Performance

## Purpose

Profile and analyze the rendering pipeline performance.

## Steps

1. Identify the rendering hot path in `src/graphics/renderer.rs`
2. Count draw commands processed per frame
3. Check for per-frame allocations in render loop
4. Analyze texture memory usage (loaded textures, format conversions)
5. Check camera transform overhead
6. Report bottlenecks with recommended optimizations

## Acceptance

- [ ] Frame time measured per rendering phase
- [ ] Per-frame allocations identified
- [ ] Recommendations ordered by impact

## References

- `performance-profiling` skill
- `software-rendering` skill
