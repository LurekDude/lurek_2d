---
description: "Analyze and reduce memory usage in the Lurek2D engine. Use when frame memory allocations are excessive, the buffer grows unboundedly, or..."
agent: Developer
---
# Analyze Memory Usage

## Goal

Analyze and reduce memory usage in the Lurek2D engine. Use when frame memory allocations are excessive, the buffer grows unboundedly, or... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `SYMPTOM` — describe the memory issue: frame spikes, growing RSS, Lua GC pauses, etc.
- `PROFILE_DATA` — optional: output from `cargo flamegraph` or `heaptrack`, if available

## Steps

1. Load [skill: gpu-programming](.github/skills/gpu-programming/SKILL.md), [skill: performance-profiling](.github/skills/performance-profiling/SKILL.md) before changing any files.
2. Load skill `performance-profiling/SKILL.md`
3. Identify allocation hot-paths in the game loop:
4. `render_commands: Vec<RenderCommand>` — is it cleared or recreated each frame?
5. `Renderer::execute_commands()` — is a new `Vec` allocated per call?
6. Lua string arguments — are `String::from()` calls avoidable?
7. Check `SharedState.draw_commands`:
8. Must use `.clear()` (retains capacity), never `= Vec::new()` (drops and reallocates)
9. Check `renderer.to_u32_buffer()` — must return `&[u32]` or reuse an owned buffer, not allocate a fresh `Vec<u32>` each frame
10. Check Lua API closures for unnecessary `String` allocations:
11. Prefer `lua.create_function` with `&str` args that convert only when needed
12. If Lua GC is suspected: call `lua.gc_collect()?` at a controlled point (not every frame)

## Success Criteria

- [ ] List of allocation sites found with severity (per-frame vs. one-time)
- [ ] Recommended changes with before/after allocation counts
- [ ] Optionally: patch implementing the highest-impact fixes

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/analyze-memory-usage <RenderCommand> <u32>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: gpu-programming, performance-profiling
- **Inputs required**: RenderCommand, u32
