# `devtools` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.devtools`                                        |
| **Source**       | `src/devtools/`                                        |
| **Rust Tests**   | `tests/rust/unit/devtools_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_devtools.lua`                     |
| **Architecture** | —                                                      |

## Purpose

The `devtools` module provides the developer diagnostics toolkit for Luna2D, exposed to Lua games via `luna.devtools.*`. It contains four core components plus a live watch/snapshot system:

1. **Logger** — structured logger with level filtering and category tagging
2. **Profiler** — hierarchical CPU-time zones across frames
3. **FrameStats** — rolling frame-time buffer with p50/p95/p99 percentiles
4. **FileWatcher** — hot-reload trigger via mtime polling
5. **Live watches** — named getter functions exposed via `exposeWatch()`; sampled via `getWatches()` or `snapshot()`

This module is **pure Rust** with no mlua dependency; all Lua plumbing lives in `src/lua_api/devtools_api.rs`. It is gated by `modules.debug = true` in `conf.lua`.

**Ownership Rule — frame timing**: Use `luna.time.getDelta()` / `luna.time.getFps()` for basic timing. Use `luna.devtools.frameStats:record(dt)` + `frameStats:snapshot()` only when **percentile analysis** is needed.

## Source Files

| File              | Purpose                                                                         |
|-------------------|---------------------------------------------------------------------------------|
| `logger.rs`       | `Logger`, `LogEntry`, `LogLevel` — structured log buffer with level and category |
| `profiler.rs`     | `Profiler`, `ProfileZone` — hierarchical CPU-time zone profiler across frames   |
| `frame_stats.rs`  | `FrameStats`, `FrameSnapshot` — circular frame-time buffer with percentile stats |
| `watcher.rs`      | `FileWatcher` — path modification time polling for hot-reload detection         |
| `mod.rs`          | Re-exports all public types                                                     |

## Full Specification

See [`specs/devtools.md`](../../../specs/devtools.md) for full architecture, type details, Lua API, examples, and notes.
