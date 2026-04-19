# IDEA.md — `devtools` module

| Field      | Value            |
| ---------- | ---------------- |
| **Module** | `devtools`       |
| **Path**   | `src/devtools/`  |
| **Date**   | 2026-04-18       |
| **Tier**   | Edge/Integration |

---

## Mission

Provide in-process developer tools for Lurek2D: structured logging, hierarchical frame profiling, rolling FPS statistics, file-change watching, and an interactive Lua REPL — all exposed to Lua via `lurek.devtools.*`.

## Strengths

- Five independent, well-scoped facilities (Logger, Profiler, FrameStats, FileWatcher, ReplConsole).
- No GPU or windowing dependency — pure Rust data structures suitable for headless use.
- Logger supports category-based filtering with case-insensitive prefix match.
- Profiler builds a true hierarchical zone tree with self-time calculation.
- REPL evaluates expressions and statements with graceful error handling.

## Gaps

- No entity/ECS inspector (`lurek.devtools.openEntityInspector()`).
- No GPU/render profiling — only CPU-side zone timing.
- FileWatcher is polling-only — no OS-native file-system event support (inotify/ReadDirectoryChanges).

## Features — Competitor Reference

| Feature                          | Status    | Competitor                                            |
| -------------------------------- | --------- | ----------------------------------------------------- |
| Entity inspector / scene browser | ❌ Missing | Godot — Remote Scene Tree, Unity — Inspector panel    |
| GPU profiling timeline           | ❌ Missing | Unreal — GPU Visualizer, bgfx — built-in GPU profiler |
| OS-native file watching          | ❌ Missing | notify crate (Rust), Unity — FileSystemWatcher        |

## Performance / Quality

- `FrameStats::record` uses `Vec::remove(0)` for ring eviction — O(n) shift. Switching to `VecDeque` would be O(1).
- `Logger::push` also uses `Vec::remove(0)` — same O(n) concern for large histories.
- `Profiler::end_frame` drains the zone stack with `pop()` in a loop — correct but allocates intermediate vecs.

## Test Gaps

- `frame_stats.rs` — newly added inline tests (5 tests); edge cases (single sample, all-equal samples) could use coverage.
- `logger.rs` — newly added inline tests (6 tests); log-to-file path untested (requires temp file).
- `profiler.rs` — newly added inline tests (8 tests); `get_frame` with negative indices untested.
- `repl.rs` — newly added inline tests (5 tests); `eval()` requires live `mlua::Lua` — tested via Lua integration tests.
- `watcher.rs` — newly added inline tests (5 tests); mtime change detection with real files untested.

## TODO(dedup)

- `Vec::remove(0)` eviction pattern appears in `FrameStats::record`, `Logger::push`, and `Profiler::end_frame` — extract a `RingBuffer<T>` helper or use `VecDeque`.
- `Logger::push` and `Profiler::push` both call `self.elapsed()` — shared epoch pattern.

## TODO(helper)

- `lua_value_to_string` in `repl.rs` is a generic mlua display helper — could be shared with other lua_api modules.
- `FileWatcher::mtime` is a one-liner that could live in a filesystem utility module.

## TODO(plugin)

- `devtools` is a strong plugin candidate — production games typically strip developer tools.
- Logger could be split from Profiler/FrameStats for lightweight builds.
- REPL depends on `mlua` — should be behind a feature flag for sandbox-restricted builds.

## References

- `docs/specs/devtools.md`
- `src/lua_api/devtools_api.rs`
- `tests/rust/unit/devtools_tests.rs`
- `tests/lua/unit/test_devtools.lua`
