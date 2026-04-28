---
description: "Analyze rendering performance and hot spots."
---

# Analyze Render Performance

## Goal
- Profile and analyze the rendering pipeline performance.

## Inputs
- None.

## Steps
- Load gpu-programming, performance-profiling before changing any files.
- Identify the rendering hot path in src/render/renderer.rs
- Count draw commands processed per frame
- Check for per-frame allocations in render loop
- Analyze texture memory usage (loaded textures, format conversions)
- Check camera transform overhead
- Report bottlenecks with recommended optimizations

## Success Criteria
- [ ] Frame time measured per rendering phase
- [ ] Per-frame allocations identified
- [ ] Recommendations ordered by impact

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /analyze-render-performance

## CAG Metadata
- **Mode**: agent
- **Loads skills**: gpu-programming, performance-profiling
