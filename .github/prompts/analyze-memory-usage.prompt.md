---
description: "Analyze engine memory use and allocation hot spots."
---

# Analyze Memory Usage

## Goal
- Analyze and reduce memory usage in the Lurek2D engine. Use when frame memory allocations are excessive, the buffer grows unboundedly, or...

## Inputs
- SYMPTOM describe the memory issue: frame spikes, growing RSS, Lua GC pauses, etc.
- PROFILE_DATA optional: output from cargo flamegraph or heaptrack, if available

## Steps
- Load gpu-programming, performance-profiling before changing any files.
- Load skill performance-profiling/SKILL.md
- Identify allocation hot-paths in the game loop:
- render_commands: Vec<RenderCommand> is it cleared or recreated each frame?
- Renderer::execute_commands() is a new Vec allocated per call?
- Lua string arguments are String::from() calls avoidable?
- Check SharedState.draw_commands:
- Must use .clear() (retains capacity), never = Vec::new() (drops and reallocates)
- Check renderer.to_u32_buffer() must return &[u32] or reuse an owned buffer, not allocate a fresh Vec<u32> each frame
- Check Lua API closures for unnecessary String allocations:
- Prefer lua.create_function with &str args that convert only when needed
- If Lua GC is suspected: call lua.gc_collect()? at a controlled point (not every frame)

## Success Criteria
- [ ] List of allocation sites found with severity (per-frame vs. one-time)
- [ ] Recommended changes with before/after allocation counts
- [ ] Optionally: patch implementing the highest-impact fixes

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /analyze-memory-usage <RenderCommand> <u32>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: gpu-programming, performance-profiling
- **Inputs required**: RenderCommand, u32
