# devtools

## Module Info
- Module name: devtools
- Module group: Edge/Integration
- Spec path: docs/specs/devtools.md
- Lua API path(s): src/lua_api/devtools_api.rs
- Rust test path(s): tests/rust/unit/devtools_tests.rs
- Lua test path(s): tests/lua/unit/test_devtools.lua; tests/lua/integration/test_devtools.lua

## Module Purpose

The devtools module provides runtime diagnostics that are useful while building and debugging games or the engine itself. It exists so developers can inspect logs, frame timing, profiler zones, and watched files from inside the running engine instead of depending entirely on external profilers or raw console output.

Its components are intentionally orthogonal. Logger stores in-process diagnostic history, Profiler records nested timing zones, FrameStats computes aggregate and percentile frame metrics, and FileWatcher polls files for change detection. The Lua bridge combines those pieces into the lurek.devtools namespace, but the Rust module itself stays focused on diagnostics primitives.

This module does not own the main engine log facade, the app event loop, or hot-reload policy. It supplements those systems with developer-facing runtime instrumentation and inspection helpers rather than replacing them.

## Files
- mod.rs: Module root that re-exports the public devtools surface. It keeps the module easy to import without exposing internal file layout.
- logger.rs: Defines LogLevel, LogEntry, and Logger for runtime log capture and filtering. This is the place to inspect when diagnostic history, severity filtering, or category tagging changes.
- profiler.rs: Defines ProfileZone and Profiler for nested CPU timing zones recorded across frames. It owns the push or pop profiler model and the retained per-frame profiling history.
- frame_stats.rs: Defines FrameStats and FrameSnapshot for rolling frame-time analysis. This file is responsible for summary metrics such as min, max, average, FPS, and percentile calculations.
- watcher.rs: Defines FileWatcher for lightweight path polling based on modification time. It is the module's file-change detection primitive for developer workflows.

## Key Types
- Logger: In-memory logging surface with severity filtering and bounded history. It is the right place to look when runtime diagnostics need to be retained, filtered, or surfaced in tools.
- LogLevel: Ordered logging enum used to filter messages and present consistent severity labels to Lua and Rust callers. It is the shared language for the module's diagnostic output.
- LogEntry: One captured runtime log record, including message, severity, source location, and optional category. It is the data unit exchanged between logger internals and diagnostics UIs.
- Profiler: Frame-by-frame nested timing recorder built around push or pop zones. It exists for CPU-cost inspection, not for GPU profiling or OS-level tracing.
- ProfileZone: One timed scope inside the profiler tree. It is useful when debugging incorrect nesting, missing pops, or self-time calculations.
- FrameStats: Rolling frame-duration buffer that turns raw dt samples into actionable summary metrics. It is the module boundary between raw timing collection and interpreted frame-health reporting.
- FrameSnapshot: Immutable summary of the current FrameStats state. This is the structure most consumers should read instead of recalculating metrics themselves.
- FileWatcher: Polling watcher for individual file paths. It is intentionally simple and should be treated as a developer convenience tool, not a full file-system event subsystem.