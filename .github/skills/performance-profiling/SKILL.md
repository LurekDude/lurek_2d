---
name: performance-profiling
description: "Load this skill when analyzing or optimizing Lurek2D performance: frame time, allocations, hot paths, rendering throughput, or Lua/Rust boundary overhead. Skip it for correctness bugs or feature implementation."
---
# performance-profiling

## Mission

# Performance Profiling — Lurek2D Engine

## When To Load

- Investigating frame rate drops or slow performance
- Analyzing per-frame memory allocations
- Optimizing hot paths in the game loop
- Measuring Lua/Rust boundary crossing overhead
- Reducing rendering or physics step time

## When To Skip

- Correctness bugs → use `dev-debugging` skill
- Algorithm design → use the relevant domain skill
- Architecture redesign → use `module-architecture` skill

## Domain Knowledge

### Owns
- Frame budget analysis (16.6ms at 60fps)
- Per-frame allocation identification and reduction
- Hot path identification in game loop
- Lua/Rust interop overhead measurement
- Rendering throughput optimization strategies

### Live Repository Contracts
- `src/app/app.rs` — main game loop (hot path)
- `src/render/renderer.rs` — draw command processing (hot path)
- `src/physics/world.rs` — world step, collision detection (hot path)
- `src/timer/clock.rs` — frame timing measurement

### Decision Rules
- **Measure first**: Never optimize without profiling evidence
- **Frame budget**: 16.6ms total for input + update + draw + present at 60fps
- **Zero-alloc hot path**: Avoid `Vec::new()`, `String::from()`, `clone()` in per-frame code
- **Pre-allocate buffers**: Reuse Vec/String buffers across frames with `clear()` + reuse
- **Batch lua calls**: Minimize Lua/Rust boundary crossings per frame
- **RenderCommand as data**: RenderCommands should be cheap to create (no allocations in variants)
- **Spatial partitioning**: Use grid or quadtree for collision if body count exceeds ~50
- **Profile tools**: Use `std::time::Instant` for timing; consider `cargo flamegraph` for deep profiling
- **Texture atlas**: Batch draw calls by texture to reduce state changes in renderer

---

### Frame Budget
At 60 FPS the total frame budget is **16.6ms**. Approximate targets for integrated GPU (Intel UHD 620):

| Phase | Budget |
|-------|--------|
| Input event processing | < 0.5ms |
| `lurek.update(dt)` | < 4ms |
| `lurek.draw()` (Lua push commands) | < 1ms |
| `GpuRenderer::render_frame()` | < 8ms |
| Physics `world:step()` | < 3ms |
| Audio decode (background thread) | 0ms (async) |
| Headroom + present | ~0.1ms |

---

### Profiling Tools
### 1. `std::time::Instant` (built-in, no install)

Inline timing in Rust hot paths:

> See [examples/1-std-time-instant-built-in.rs](examples/1-std-time-instant-built-in.rs) for the example.

Control visibility with `RUST_LOG=lurek2d=debug`.

### 2. Lua-side timing

> See [examples/2-lua-side-timing.lua](examples/2-lua-side-timing.lua) for the example.

### 3. `cargo flamegraph` (install once)

> See [snippets/3-cargo-flamegraph-install-once.ps1](snippets/3-cargo-flamegraph-install-once.ps1) for the example.

Requires `perf` on Linux or `dtrace` on macOS. On Windows use:

> See [snippets/3-cargo-flamegraph-install-once-2.ps1](snippets/3-cargo-flamegraph-install-once-2.ps1) for the example.

### 4. Debug overlay

Enable the built-in FPS + draw call counter:


> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [examples/1-std-time-instant-built-in.rs](examples/1-std-time-instant-built-in.rs) — 1. `std::time::Instant` (built-in, no install)
- [examples/2-lua-side-timing.lua](examples/2-lua-side-timing.lua) — 2. Lua-side timing
- [snippets/3-cargo-flamegraph-install-once.ps1](snippets/3-cargo-flamegraph-install-once.ps1) — 3. `cargo flamegraph` (install once)
- [snippets/3-cargo-flamegraph-install-once-2.ps1](snippets/3-cargo-flamegraph-install-once-2.ps1) — 3. `cargo flamegraph` (install once)
- [examples/4-debug-overlay.lua](examples/4-debug-overlay.lua) — 4. Debug overlay
- [examples/spritebatch-most-important.lua](examples/spritebatch-most-important.lua) — SpriteBatch (most important)
- [examples/lua-gc-pressure-reduction.lua](examples/lua-gc-pressure-reduction.lua) — Lua GC Pressure Reduction
- [examples/lua-gc-pressure-reduction-2.lua](examples/lua-gc-pressure-reduction-2.lua) — Lua GC Pressure Reduction
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
