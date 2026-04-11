# `devtools` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | `lurek.devtools` |
| **Source** | `src/devtools/` |
| **Rust Tests** | tests/rust/unit/devtools_tests.rs |
| **Lua Tests** | tests/lua/unit/test_devtools.lua; tests/lua/integration/test_devtools.lua |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The devtools module provides runtime diagnostics that are useful while building and debugging games or the engine itself. It exists so developers can inspect logs, frame timing, profiler zones, and watched files from inside the running engine instead of depending entirely on external profilers or raw console output.

Its components are intentionally orthogonal. Logger stores in-process diagnostic history, Profiler records nested timing zones, FrameStats computes aggregate and percentile frame metrics, and FileWatcher polls files for change detection. The Lua bridge combines those pieces into the lurek.devtools namespace, but the Rust module itself stays focused on diagnostics primitives.

This module does not own the main engine log facade, the app event loop, or hot-reload policy. It supplements those systems with developer-facing runtime instrumentation and inspection helpers rather than replacing them.

**Scope boundary**: This module currently acts as a mostly self-contained part of the Edge/Integration layer. Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below.

---

## Architecture

```
lurek.devtools.* (Lua API — src/lua_api/devtools_api.rs)
    |
    v
src/devtools/mod.rs
    |- frame_stats.rs - frame_stats
    |- logger.rs - logger
    |- profiler.rs - profiler
    |- watcher.rs - watcher
```

---

## Source Files

| File | Purpose |
|------|---------|
| `frame_stats.rs` | Defines FrameStats and FrameSnapshot for rolling frame-time analysis. This file is responsible for summary metrics such as min, max, average, FPS, and percentile calculations. |
| `logger.rs` | Defines LogLevel, LogEntry, and Logger for runtime log capture and filtering. This is the place to inspect when diagnostic history, severity filtering, or category tagging changes. |
| `mod.rs` | Module root that re-exports the public devtools surface. It keeps the module easy to import without exposing internal file layout. |
| `profiler.rs` | Defines ProfileZone and Profiler for nested CPU timing zones recorded across frames. It owns the push or pop profiler model and the retained per-frame profiling history. |
| `watcher.rs` | Defines FileWatcher for lightweight path polling based on modification time. It is the module's file-change detection primitive for developer workflows. |

---

## Submodules

### `devtools::frame_stats`

Defines FrameStats and FrameSnapshot for rolling frame-time analysis. This file is responsible for summary metrics such as min, max, average, FPS, and percentile calculations.

- **`FrameStats`** (struct): Rolling-window frame-time accumulator.
- **`FrameSnapshot`** (struct): Computed statistics snapshot from [`FrameStats::snapshot`].

### `devtools::logger`

Defines LogLevel, LogEntry, and Logger for runtime log capture and filtering. This is the place to inspect when diagnostic history, severity filtering, or category tagging changes.

- **`LogLevel`** (enum): Log severity level.
- **`LogEntry`** (struct): A single log entry captured in the rolling history.
- **`Logger`** (struct): Structured in-process logger with level filtering and rolling history.

### `devtools::profiler`

Defines ProfileZone and Profiler for nested CPU timing zones recorded across frames. It owns the push or pop profiler model and the retained per-frame profiling history.

- **`ProfileZone`** (struct): A completed timing zone with optional nested children.
- **`Profiler`** (struct): Hierarchical frame profiler.

### `devtools::watcher`

Defines FileWatcher for lightweight path polling based on modification time. It is the module's file-change detection primitive for developer workflows.

- **`FileWatcher`** (struct): Polling-based file-modification watcher.

---

## Key Types

### Public Types

#### `Logger`

In-memory logging surface with severity filtering and bounded history.

#### `LogLevel`

Ordered logging enum used to filter messages and present consistent severity labels to Lua and Rust callers.

#### `LogEntry`

One captured runtime log record, including message, severity, source location, and optional category.

#### `Profiler`

Frame-by-frame nested timing recorder built around push or pop zones.

#### `ProfileZone`

One timed scope inside the profiler tree.

#### `FrameStats`

Rolling frame-duration buffer that turns raw dt samples into actionable summary metrics.

#### `FrameSnapshot`

Immutable summary of the current FrameStats state.

#### `FileWatcher`

Polling watcher for individual file paths.

---

## Lua API

Exposed under `lurek.devtools.*` by `src/lua_api/devtools_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.devtools.log` | Logs a message at the given level. |
| `lurek.devtools.setLogLevel` | Sets the minimum log level. |
| `lurek.devtools.getLogLevel` | Returns the current minimum log level. |
| `lurek.devtools.setLogConsole` | Enables or disables console log output. |
| `lurek.devtools.getLogConsole` | Returns whether console log output is enabled. |
| `lurek.devtools.setLogFile` | Sets the log file path (empty string disables file output). |
| `lurek.devtools.getLogFile` | Returns the current log file path. |
| `lurek.devtools.getLogHistory` | Returns recent log entries as an array of tables. |
| `lurek.devtools.clearLog` | Clears all log history. |
| `lurek.devtools.setProfilingEnabled` | Enables or disables the profiler. |
| `lurek.devtools.isProfilingEnabled` | Returns whether the profiler is enabled. |
| `lurek.devtools.profilePush` | Opens a named profiling zone on the stack. |
| `lurek.devtools.profilePop` | Closes the most recent profiling zone. |
| `lurek.devtools.profileFrame` | Seals the current frame of profiling data. |
| `lurek.devtools.getProfileFrameCount` | Returns the number of retained profile frames. |
| `lurek.devtools.getProfileData` | Returns zone data table for a specific frame (0 or nil = most recent). |
| `lurek.devtools.resetProfile` | Clears all profiling data and resets the zone stack. |
| `lurek.devtools.recordFrameTime` | Records a frame-time sample (call each frame with delta time in seconds). |
| `lurek.devtools.getFrameStats` | Returns a table of computed frame statistics. |
| `lurek.devtools.getFrameHistory` | Returns the raw frame-time sample array. |
| `lurek.devtools.setFrameHistorySize` | Sets the frame-history buffer capacity (clamped 10-10000). |
| `lurek.devtools.getFrameHistorySize` | Returns the current frame-history buffer capacity. |
| `lurek.devtools.watch` | Adds a file path to the watch list. Returns false if already watched. |
| `lurek.devtools.unwatch` | Removes a file path from the watch list. |
| `lurek.devtools.getWatchedPaths` | Returns an array of all watched paths. |
| `lurek.devtools.scan` | Polls all watched paths and returns paths whose mtime changed. |
| `lurek.devtools.clearWatches` | Clears all watched paths. |
| `lurek.devtools.getWatchInterval` | Returns the file watch poll interval in seconds. |
| `lurek.devtools.setWatchInterval` | Sets the file watch poll interval in seconds. |
| `lurek.devtools.getCallStack` | Returns the Lua call stack as a table of frames. |
| `lurek.devtools.eval` | Evaluates a Lua string and returns (success, results...). |
| `lurek.devtools.openConsole` | Opens the console window (updates the console flag; returns true). |
| `lurek.devtools.isConsoleOpen` | Returns whether the console is considered open. |
| `lurek.devtools.exposeWatch` | Registers a named live watch. The getter function is called on demand to sample a value. |
| `lurek.devtools.removeWatch` | Removes a watch by the id returned from exposeWatch. Returns true if removed. |
| `lurek.devtools.getWatches` | Calls all registered watch getters and returns a table of {name, category, value} records. |
| `lurek.devtools.snapshot` | Takes a structured snapshot of all watches + frame stats + last profile frame. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.devtools.
if lurek.devtools then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 7 |
| `enum` | 1 |
| `fn` (Lua API) | 37 |
| **Total** | **45** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/devtools/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
