---
description: "Analyze rendering performance: frame time, draw command throughput, texture memory, wgpu pipeline operations."
agent: Renderer
---
# Analyze Render Performance

## Goal

Profile and analyze the rendering pipeline performance.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. Load [skill: gpu-programming](.github/skills/gpu-programming/SKILL.md), [skill: performance-profiling](.github/skills/performance-profiling/SKILL.md) before changing any files.
2. Identify the rendering hot path in `src/render/renderer.rs`
3. Count draw commands processed per frame
4. Check for per-frame allocations in render loop
5. Analyze texture memory usage (loaded textures, format conversions)
6. Check camera transform overhead
7. Report bottlenecks with recommended optimizations

## Success Criteria

- [ ] Frame time measured per rendering phase
- [ ] Per-frame allocations identified
- [ ] Recommendations ordered by impact

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/analyze-render-performance`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: gpu-programming, performance-profiling
