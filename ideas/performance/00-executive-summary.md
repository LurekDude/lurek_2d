# Lurek2D Performance & Threading — Executive Summary

> Research date: 2026-04-03 | Branch: `root`
> Session: `perf-threading-research`

## Purpose

This report analyzes every Lurek2D module for multithreading and GPU performance
improvement opportunities. It compares current implementation against Engine A,
Corona/Engine B, Engine F, and Engine E reference architectures found in
`docs/competition/` and `docs/future/`.

## Current State

Lurek2D follows a **synchronous-by-default, opt-in background threading** model:

| Layer | Threading Today |
|-------|----------------|
| Lua execution | Main thread only (by design — LuaJIT VMs cannot share state) |
| Event loop | Main thread (winit `ApplicationHandler`) |
| GPU rendering | Main thread (wgpu `queue.write_buffer` + `queue.submit`) |
| Audio playback | Rodio internal thread (out of our control) |
| Audio decoding | **Main thread — blocks on file decode** |
| Physics | Main thread (rapier2d `parallel` feature **not enabled**) |
| Pathfinding | **Background thread pool** (AsyncPool) ✅ |
| File I/O | **Background thread** (AsyncLoader, 1 worker) ✅ |
| Compute/NdArray | Main thread — no parallelism |
| AI (GOAP, influence) | Main thread — no parallelism |
| Particle updates | Main thread — no parallelism |
| Tilemap processing | Main thread — no parallelism |
| DataFrame queries | Main thread — no parallelism |

## Concurrency Primitives in Use

- `std::thread::spawn` — OS threads for async loader, pathfinding pool, debug bridge, Lua workers
- `Arc<Mutex<T>>` — shared state across threads
- `mpsc::SyncSender` — bounded work queues
- `Condvar` — blocking channel waits
- `Rc<RefCell<SharedState>>` — main-thread-only game state (NOT thread-safe)
- **NOT used**: tokio, async/await, crossbeam (direct), rayon (direct), parking_lot

## Key Findings

### Highest-Impact Opportunities (ranked by ROI)

| # | Opportunity | Effort | Expected Speedup | Report File |
|---|-------------|--------|------------------|-------------|
| 1 | Enable rapier2d `parallel` feature | 1 line | 2–4× physics | `01-physics-threading.md` |
| 2 | Frustum culling for all draw commands | Medium | Eliminate 30–80% of tessellation | `02-gpu-rendering.md` |
| 3 | Texture atlas auto-batching | Medium | Reduce draw calls 5–20× | `02-gpu-rendering.md` |
| 4 | Rayon for NdArray ops | Low | 4–8× on large arrays | `04-compute-threading.md` |
| 5 | Rayon for particle updates | Low | 4–8× for 10k+ particles | `03-particle-audio.md` |
| 6 | Async audio decoding | Low | Non-blocking load times | `03-particle-audio.md` |
| 7 | GPU compute shaders for NdArray | High | 10–100× on 100k+ elements | `04-compute-threading.md` |
| 8 | Parallel AI planning (GOAP) | Medium | 2–8× multi-agent | `05-ai-pathfinding.md` |
| 9 | Geometry caching (static scenes) | Medium | Eliminate re-tessellation | `02-gpu-rendering.md` |
| 10 | DataFrame parallel sort/filter | Low | 2–4× on 100k+ rows | `04-compute-threading.md` |

### Architecture Constraint

`Rc<RefCell<SharedState>>` is the central shared state. It is **not** `Send + Sync`.
Any threading work that touches game state must either:
- Use message-passing (channels) to communicate with the main thread
- Clone needed data out before sending to a worker thread
- Use `Arc<Mutex<T>>` wrappers for shared resources (already done in AsyncLoader, AsyncPool)

## Report Structure

| File | Covers |
|------|--------|
| `00-executive-summary.md` | This file — overview and priority ranking |
| `01-physics-threading.md` | Physics engine parallelism (rapier2d) |
| `02-gpu-rendering.md` | GPU rendering pipeline, batching, culling, compute shaders |
| `03-particle-audio.md` | Particle system parallelism + audio threading |
| `04-compute-threading.md` | NdArray, DataFrame, GPU compute |
| `05-ai-pathfinding.md` | AI planning, influence maps, pathfinding |
| `06-io-filesystem.md` | File I/O, async loading, texture streaming |
| `07-tilemap-large-world.md` | Tilemap culling, chunk streaming, large map optimization |
| `08-reference-engine-comparison.md` | How Engine A, Corona, Engine F, Engine E handle these problems |
| `09-implementation-plan.md` | Phased implementation plan with priorities |
