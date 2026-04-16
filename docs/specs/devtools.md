# devtools

## General Info

- Module group: `Edge/Integration`
- Source path: `src/devtools/`
- Lua API path(s): `src/lua_api/devtools_api.rs`
- Primary Lua namespace: `lurek.devtools`
- Rust test path(s): tests/rust/unit/devtools_tests.rs
- Lua test path(s): tests/lua/unit/test_devtools.lua; tests/lua/integration/test_devtools.lua

## Summary

The `devtools` module provides Lurek2D's in-process developer tools: a structured logger, a frame profiler, rolling frame statistics, and a file watcher for hot-reload detection. These tools are exposed to Lua games via `lurek.devtools.*` and are designed to aid game developers during development without shipping GPU overlays or requiring a separate profiler binary.

`Logger` is a level-filtered, categorised in-process log with a rolling history ring buffer. Messages are tagged with a `LogLevel` (trace/debug/info/warn/error) and an optional category string. The history is accessible from Lua for in-game debug consoles. `Logger` is separate from the engine's Rust `log` crate output — it captures Lua-emitted messages independently.

`Profiler` is a hierarchical zone-based frame profiler. `begin_zone(name)` / `end_zone()` calls bracket sections of game code; the profiler records wall-clock time per zone and builds a tree of `ProfileZone` entries for each completed frame. Results are accessible from Lua for custom in-game overlays.

`FrameStats` computes rolling FPS and frame-time statistics including mean, min, max, and percentile values (p50/p95/p99) over the last N frames. `FrameSnapshot` captures one frame's complete stat set for display or logging.

`FileWatcher` polls file modification times at a configurable interval. When a watched path's mtime changes, it queues a change notification that Lua code can poll to trigger hot-reload of assets or scripts.

The `repl.rs` source file adds `ReplConsole`, an interactive Lua REPL with a bounded input history buffer that can be embedded in a running game session without spawning a separate process. Lua scripts drive it through `lurek.devtools.repl:eval(code)` for expression execution, `repl:history()` and `repl:historySize()` for browsing past inputs, and `repl:clearHistory()` to reset the buffer — enabling in-game developer consoles that evaluate live Lua without external tooling.

**Scope boundary**: Feature Systems tier. Depends on `runtime`. Lua bridge in `src/lua_api/devtools_api.rs`.

## Files

- `frame_stats.rs`: Defines FrameStats and FrameSnapshot for rolling frame-time analysis. This file is responsible for summary metrics such as min, max, average, FPS, and percentile calculations.
- `logger.rs`: Defines LogLevel, LogEntry, and Logger for runtime log capture and filtering. This is the place to inspect when diagnostic history, severity filtering, or category tagging changes.
- `mod.rs`: Module root that re-exports the public devtools surface. It keeps the module easy to import without exposing internal file layout.
- `profiler.rs`: Defines ProfileZone and Profiler for nested CPU timing zones recorded across frames. It owns the push or pop profiler model and the retained per-frame profiling history.
- `repl.rs`: REPL console for interactive Lua evaluation inside a running game session.
- `watcher.rs`: Defines FileWatcher for lightweight path polling based on modification time. It is the module's file-change detection primitive for developer workflows.

## Types

- `FrameStats` (`struct`, `frame_stats.rs`): Rolling frame-duration buffer that turns raw dt samples into actionable summary metrics. It is the module boundary between raw timing collection and interpreted frame-health reporting.
- `FrameSnapshot` (`struct`, `frame_stats.rs`): Immutable summary of the current FrameStats state. This is the structure most consumers should read instead of recalculating metrics themselves.
- `LogLevel` (`enum`, `logger.rs`): Ordered logging enum used to filter messages and present consistent severity labels to Lua and Rust callers. It is the shared language for the module's diagnostic output.
- `LogEntry` (`struct`, `logger.rs`): One captured runtime log record, including message, severity, source location, and optional category. It is the data unit exchanged between logger internals and diagnostics UIs.
- `Logger` (`struct`, `logger.rs`): In-memory logging surface with severity filtering and bounded history. It is the right place to look when runtime diagnostics need to be retained, filtered, or surfaced in tools.
- `ProfileZone` (`struct`, `profiler.rs`): One timed scope inside the profiler tree. It is useful when debugging incorrect nesting, missing pops, or self-time calculations.
- `Profiler` (`struct`, `profiler.rs`): Frame-by-frame nested timing recorder built around push or pop zones. It exists for CPU-cost inspection, not for GPU profiling or OS-level tracing.
- `ReplConsole` (`struct`, `repl.rs`): Interactive Lua REPL with a bounded input history buffer.
- `FileWatcher` (`struct`, `watcher.rs`): Polling watcher for individual file paths. It is intentionally simple and should be treated as a developer convenience tool, not a full file-system event subsystem.

## Functions

- `FrameStats::new` (`frame_stats.rs`): Creates a new `FrameStats` with the given sample capacity.
- `FrameStats::record` (`frame_stats.rs`): Pushes a new frame-time sample, evicting the oldest when full.
- `FrameStats::set_capacity` (`frame_stats.rs`): Sets the capacity, trimming old samples if necessary.
- `FrameStats::snapshot` (`frame_stats.rs`): Returns a snapshot of computed frame statistics.
- `LogLevel::from_str` (`logger.rs`): Parse a case-insensitive level name string.
- `LogLevel::as_str` (`logger.rs`): Returns the canonical lowercase name string.
- `Logger::new` (`logger.rs`): Creates a new logger with sensible defaults (level = `Info`, console on, 1 000 entry history).
- `Logger::elapsed` (`logger.rs`): Seconds elapsed since the logger was created.
- `Logger::push` (`logger.rs`): Records a message at the given level, respecting the minimum filter.
- `Logger::tail` (`logger.rs`): Returns the last `count` entries (or all when `count` is `None` or zero).
- `Logger::filter_category` (`logger.rs`): Filters history by category tag (case-insensitive prefix match).
- `Logger::clear` (`logger.rs`): Clears all log history without changing settings.
- `ProfileZone::total_time` (`profiler.rs`): Total wall-clock duration of this zone (includes children).
- `ProfileZone::self_time` (`profiler.rs`): Exclusive (self-only) duration, excluding children.
- `ProfileZone::flatten` (`profiler.rs`): Flattens all zones and children into a single pre-order list.
- `Profiler::new` (`profiler.rs`): Creates a new profiler (disabled by default, 300 frame buffer).
- `Profiler::elapsed` (`profiler.rs`): Current seconds from the profiler epoch.
- `Profiler::push` (`profiler.rs`): Opens a named timing zone.
- `Profiler::pop` (`profiler.rs`): Closes the most recent open zone.
- `Profiler::end_frame` (`profiler.rs`): Seals the current frame and stores the collected zones.
- `Profiler::get_frame` (`profiler.rs`): Returns zone data for the frame at offset `idx` (0 = most recent, negative = relative).
- `Profiler::reset` (`profiler.rs`): Clears all captured profiling data and resets the zone stack.
- `ReplConsole::new` (`repl.rs`): Creates a new REPL console with the given history limit.
- `ReplConsole::eval` (`repl.rs`): Evaluates a Lua snippet and records the input in history.
- `ReplConsole::history` (`repl.rs`): Returns a read-only slice of the history buffer (oldest first).
- `ReplConsole::clear` (`repl.rs`): Clears the history buffer.
- `ReplConsole::len` (`repl.rs`): Returns the current number of history entries.
- `ReplConsole::is_empty` (`repl.rs`): Returns `true` if the history is empty.
- `FileWatcher::new` (`watcher.rs`): Creates a new empty watcher.
- `FileWatcher::watch` (`watcher.rs`): Adds a path to the watch list.
- `FileWatcher::unwatch` (`watcher.rs`): Removes a path from the watch list.
- `FileWatcher::watched_paths` (`watcher.rs`): Returns all currently watched paths.
- `FileWatcher::poll` (`watcher.rs`): Polls all watched paths and returns paths that have changed since the last call to `poll`.
- `FileWatcher::clear` (`watcher.rs`): Clears all watched paths.

## Lua API Reference

- Binding path(s): `src/lua_api/devtools_api.rs`
- Namespace: `lurek.devtools`

### Module Functions
- `lurek.devtools.log`: Logs a message at the given level.
- `lurek.devtools.setLogLevel`: Sets the minimum log level.
- `lurek.devtools.getLogLevel`: Returns the current minimum log level.
- `lurek.devtools.setLogConsole`: Enables or disables console log output.
- `lurek.devtools.getLogConsole`: Returns whether console log output is enabled.
- `lurek.devtools.setLogFile`: Sets the log file path (empty string disables file output).
- `lurek.devtools.getLogFile`: Returns the current log file path.
- `lurek.devtools.getLogHistory`: Returns recent log entries as an array of tables.
- `lurek.devtools.clearLog`: Discards all accumulated log entries from the in-memory devtools log buffer.
- `lurek.devtools.setProfilingEnabled`: Enables or disables the profiler.
- `lurek.devtools.isProfilingEnabled`: Returns whether the profiler is enabled.
- `lurek.devtools.profilePush`: Opens a named profiling zone on the stack.
- `lurek.devtools.profilePop`: Closes the most recent profiling zone.
- `lurek.devtools.profileFrame`: Seals the current frame of profiling data.
- `lurek.devtools.getProfileFrameCount`: Returns the number of retained profile frames.
- `lurek.devtools.getProfileData`: Returns zone data table for a specific frame (0 or nil = most recent).
- `lurek.devtools.resetProfile`: Clears all profiling data and resets the zone stack.
- `lurek.devtools.recordFrameTime`: Records a frame-time sample (call each frame with delta time in seconds).
- `lurek.devtools.getFrameStats`: Returns a table of computed frame statistics.
- `lurek.devtools.getFrameHistory`: Returns the raw frame-time sample array.
- `lurek.devtools.setFrameHistorySize`: Sets the frame-history buffer capacity (clamped 10-10000).
- `lurek.devtools.getFrameHistorySize`: Returns the current frame-history buffer capacity.
- `lurek.devtools.watch`: Adds a file path to the watch list. Returns false if already watched.
- `lurek.devtools.unwatch`: Removes a file path from the watch list.
- `lurek.devtools.getWatchedPaths`: Returns an array of all watched paths.
- `lurek.devtools.scan`: Polls all watched paths and returns paths whose mtime changed.
- `lurek.devtools.clearWatches`: Clears all watched paths.
- `lurek.devtools.getWatchInterval`: Returns the file watch poll interval in seconds.
- `lurek.devtools.setWatchInterval`: Sets the file watch poll interval in seconds.
- `lurek.devtools.getCallStack`: Returns the Lua call stack as a table of frames.
- `lurek.devtools.eval`: Evaluates a Lua string and returns (success, results...).
- `lurek.devtools.openConsole`: Opens the console window (updates the console flag; returns true).
- `lurek.devtools.isConsoleOpen`: Returns whether the console is considered open.
- `lurek.devtools.exposeWatch`: Registers a named live watch. The getter function is called on demand to sample a value.
- `lurek.devtools.removeWatch`: Removes a watch by the id returned from exposeWatch. Returns true if removed.
- `lurek.devtools.getWatches`: Calls all registered watch getters and returns a table of {name, category, value} records.
- `lurek.devtools.snapshot`: Takes a structured snapshot of all watches + frame stats + last profile frame.
- `lurek.devtools.profilerReport`: Returns a flat summary table of all recorded profiler zones across all stored
- `lurek.devtools.newFileWatcher`: Creates a standalone per-path file watcher. Call `:check()` once per frame
- `lurek.devtools.newRepl`: Creates an interactive Lua REPL console with a bounded history buffer.

### `FileWatcher` Methods
- `FileWatcher:onChanged`: Registers a callback invoked (with no arguments) when the watched path changes.
- `FileWatcher:check`: Polls the watcher. If the file has changed since the last call, fires the
- `FileWatcher:getPath`: Returns the watched path string.
- `FileWatcher:cancel`: Removes the stored `onChanged` callback and stops future notifications.

### `ReplConsole` Methods
- `ReplConsole:eval`: Evaluates a Lua snippet and records the input in history.
- `ReplConsole:history`: Returns an ordered array of past inputs (oldest first).
- `ReplConsole:clear`: Clears the REPL history buffer.
- `ReplConsole:len`: Returns the number of history entries.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/devtools/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
