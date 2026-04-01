---
description: "Analyze and reduce memory usage in the Luna2D engine. Use when frame memory allocations are excessive, the buffer grows unboundedly, or Lua GC pressure is suspected."
---

# Analyze Memory Usage

**Purpose**: Profile and reduce per-frame memory allocations in the Luna2D game loop.
**Use When**: Frame times are inconsistent (GC pauses), heap allocations appear in profiles, or `Vec` growth is suspected.
**Do Not Use When**: The issue is CPU-bound rendering time — use `analyze-render-performance.prompt.md` instead.
**Scope**: `src/engine/app.rs`, `src/graphics/renderer.rs`, `src/lua_api/`.

## Inputs

- `SYMPTOM` — describe the memory issue: frame spikes, growing RSS, Lua GC pauses, etc.
- `PROFILE_DATA` — optional: output from `cargo flamegraph` or `heaptrack`, if available

## Steps

1. Load skill `performance-profiling/SKILL.md`
2. Identify allocation hot-paths in the game loop:
   - `draw_commands: Vec<DrawCommand>` — is it cleared or recreated each frame?
   - `Renderer::execute_commands()` — is a new `Vec` allocated per call?
   - Lua string arguments — are `String::from()` calls avoidable?
3. Check `SharedState.draw_commands`:
   - Must use `.clear()` (retains capacity), never `= Vec::new()` (drops and reallocates)
4. Check `renderer.to_u32_buffer()` — must return `&[u32]` or reuse an owned buffer, not allocate a fresh `Vec<u32>` each frame
5. Check Lua API closures for unnecessary `String` allocations:
   - Prefer `lua.create_function` with `&str` args that convert only when needed
6. If Lua GC is suspected: call `lua.gc_collect()?` at a controlled point (not every frame)
7. Measure: use `cargo build --release` + system memory profiler

## Outputs

- List of allocation sites found with severity (per-frame vs. one-time)
- Recommended changes with before/after allocation counts
- Optionally: patch implementing the highest-impact fixes

## Acceptance

- [ ] Per-frame `Vec` reallocations in hot path reduced or eliminated
- [ ] `draw_commands` cleared with `.clear()` not re-created
- [ ] `to_u32_buffer()` does not allocate a new `Vec<u32>` each frame
- [ ] `cargo test` still passes after any changes

## References

**Required Skills**: `performance-profiling`, `software-rendering`, `game-loop`
**Suggested Agents**: `Optimizer`, `Renderer`
**Related Prompts**: `analyze-render-performance.prompt.md`
**Commands**:
```powershell
cargo build --release
cargo test
```
