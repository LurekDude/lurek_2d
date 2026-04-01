---
name: performance-profiling
description: "Load this skill when analyzing or optimizing Luna2D performance: frame time, allocations, hot paths, rendering throughput, or Lua/Rust boundary overhead. Skip it for correctness bugs or feature implementation."
---

# Performance Profiling — Luna2D Engine

## Load When

- Investigating frame rate drops or slow performance
- Analyzing per-frame memory allocations
- Optimizing hot paths in the game loop
- Measuring Lua/Rust boundary crossing overhead
- Reducing rendering or physics step time

## Owns

- Frame budget analysis (16.6ms at 60fps)
- Per-frame allocation identification and reduction
- Hot path identification in game loop
- Lua/Rust interop overhead measurement
- Rendering throughput optimization strategies

## Does Not Cover

- Correctness bugs → use `dev-debugging` skill
- Algorithm design → use the relevant domain skill
- Architecture redesign → use `module-architecture` skill

## Live Repository Contracts

- `src/engine/app.rs` — main game loop (hot path)
- `src/graphics/renderer.rs` — draw command processing (hot path)
- `src/physics/world.rs` — world step, collision detection (hot path)
- `src/timer/clock.rs` — frame timing measurement

## Decision Rules

- **Measure first**: Never optimize without profiling evidence
- **Frame budget**: 16.6ms total for input + update + draw + present at 60fps
- **Zero-alloc hot path**: Avoid `Vec::new()`, `String::from()`, `clone()` in per-frame code
- **Pre-allocate buffers**: Reuse Vec/String buffers across frames with `clear()` + reuse
- **Batch lua calls**: Minimize Lua/Rust boundary crossings per frame
- **DrawCommand as data**: DrawCommands should be cheap to create (no allocations in variants)
- **Spatial partitioning**: Use grid or quadtree for collision if body count exceeds ~50
- **Profile tools**: Use `std::time::Instant` for timing; consider `cargo flamegraph` for deep profiling
- **Texture atlas**: Batch draw calls by texture to reduce state changes in renderer
