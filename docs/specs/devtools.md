# devtools

## General Info

- Module group: `Edge/Integration`
- Source path: `src/devtools/`
- Lua API path(s): `src/lua_api/devtools_api.rs`
- Primary Lua namespace: `lurek.devtools`
- Rust test path(s): tests/rust/unit/devtools_tests.rs
- Lua test path(s): tests/lua/unit/test_devtools.lua; tests/lua/integration/test_devtools.lua

## Summary

The `devtools` module is Lurek2D's in-process developer toolbox — a Feature Systems tier module exposing structured logging, frame profiling, rolling frame statistics, a file watcher for hot-reload, and an interactive Lua REPL, all accessible from Lua scripts via `lurek.devtools.*`. It is intended to aid game developers during development without requiring a separate profiler binary or GPU overlay renderer.

**Logger.** `Logger` is a level-filtered, categorised in-process message store with a rolling history ring buffer. Messages are tagged with a `LogLevel` (trace/debug/info/warn/error) and an optional category string. `push(level, category, message)` records an entry; `tail(n)` returns the most recent n entries; `filter_category(cat)` returns all entries matching a category prefix. The history bound is configurable (`set_capacity`). `Logger` is separate from the engine's Rust `log` crate output — it independently captures Lua-emitted diagnostic messages for in-game debug consoles and tooling.

**Profiler.** `Profiler` is a hierarchical zone-based frame profiler. `begin_zone(name)` / `end_zone()` bracket sections of game code; the profiler records wall-clock time per zone and builds a tree of `ProfileZone` entries for each completed frame. Each `ProfileZone` has `total_time()` (wall clock including children) and `self_time()` (exclusive cost), and `flatten()` collapses the tree to a pre-order list for tabular display. From Lua: `lurek.devtools.profiler:begin("name")`, `profiler:end()`, `profiler:frame()` returns the last completed frame's zone tree as a table.

**FrameStats.** `FrameStats` is a rolling sample buffer for frame delta-time values. `record(dt)` pushes a new sample, evicting the oldest when at capacity. The buffer is backed by `VecDeque` so eviction is O(1). `snapshot()` returns a `FrameSnapshot` with: current FPS, mean frame time, min, max, and percentile values p50/p95/p99 computed over the current window. Used by the debug overlay and the debug bridge performance endpoint.

**FileWatcher.** `FileWatcher` polls file modification times at a configurable interval. Watched paths are registered with `watch(path)`; `check()` returns the list of paths whose mtime has changed since the last check. From Lua: `lurek.devtools.watcher:watch(path)`, `watcher:check()` → changed paths table. Intended for hot-reload workflows: a Lua game can watch its own scripts and assets and call `lurek.require` or re-load textures on change without a full restart.

**REPL console.** `ReplConsole` provides an interactive Lua REPL with a bounded input history buffer that can be embedded in a running game session without spawning a separate process. `eval(code)` executes an arbitrary Lua expression in the current VM and returns its string representation. `history()` / `historySize()` / `clearHistory()` manage the input history ring. This enables in-game developer consoles (e.g., a text input field that submits code to `repl:eval()`) without external tooling.

**Lua surface.** `lurek.devtools.newLogger(capacity)` / `newProfiler()` / `newFrameStats(capacity)` / `newWatcher(interval_ms)` / `newRepl()` create instances. `Logger` userdata: `push(level, cat, msg)`, `tail(n)`, `filterCategory(cat)`, `clear()`, `setLevel(level)`. `Profiler` userdata: `begin(name)`, `stop()`, `frame()` (tree). `FrameStats` userdata: `record(dt)`, `snapshot()` (table with fps/mean/min/max/p50/p95/p99). `FileWatcher` userdata: `watch(path)`, `check()`. `ReplConsole` userdata: `eval(code)`, `history()`, `historySize()`, `clearHistory()`. Module-level utilities also expose lightweight GPU frame stats (`recordGpuFrameTime`, `getGpuFrameStats`) and an entity inspector toggle (`openEntityInspector`, `isEntityInspectorOpen`).

**Scope boundary.** Feature Systems tier. Depends on `runtime` for VM access in REPL eval. Lua bridge in `src/lua_api/devtools_api.rs`.

## Files

- `frame_stats.rs`: Defines FrameStats and FrameSnapshot for rolling frame-time analysis. This file is responsible for summary metrics such as min, max, average, FPS, and percentile calculations.
- `logger.rs`: Defines LogLevel, LogEntry, and Logger for runtime log capture and filtering. This is the place to inspect when diagnostic history, severity filtering, or category tagging changes.
- `lua_display.rs`: - Convert Lua values to human-readable text for REPL and debug display - Handle nil, boolean, number, string, table, function, and userdata variants - Return safe fallback labels for unrecognized value kinds
- `mod.rs`: Module root that re-exports the public devtools surface. It keeps the module easy to import without exposing internal file layout.
- `profiler.rs`: Defines ProfileZone and Profiler for nested CPU timing zones recorded across frames. It owns the push or pop profiler model and the retained per-frame profiling history.
- `repl.rs`: REPL console for interactive Lua evaluation inside a running game session.
- `time_anchor.rs`: - Capture a monotonic instant at construction time - Compute elapsed seconds from that anchor on demand - Provide a shared timing primitive for logger and profiler
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
- `TimeAnchor` (`struct`, `time_anchor.rs`): Hold a monotonic start instant used to measure elapsed seconds.
- `FileWatcher` (`struct`, `watcher.rs`): Polling watcher for individual file paths. It is intentionally simple and should be treated as a developer convenience tool, not a full file-system event subsystem.

## Functions

- `FrameStats::new` (`frame_stats.rs`): Create frame stats with bounded capacity and return the instance.
- `FrameStats::record` (`frame_stats.rs`): Append one frame delta sample and drop oldest samples past capacity.
- `FrameStats::set_capacity` (`frame_stats.rs`): Set the sample capacity and trim stored history to the new bound.
- `FrameStats::snapshot` (`frame_stats.rs`): Compute aggregate frame metrics and return zeros when history is empty.
- `LogLevel::from_str` (`logger.rs`): Parse a case-insensitive level name and return None when unknown.
- `LogLevel::as_str` (`logger.rs`): Return the canonical lowercase level label for this severity.
- `Logger::new` (`logger.rs`): Create logger state with default filtering and retention settings.
- `Logger::elapsed` (`logger.rs`): Return elapsed time in seconds since logger construction.
- `Logger::push` (`logger.rs`): Push a log entry and return unit after filtering and retention updates.
- `Logger::tail` (`logger.rs`): Return the most recent log entries, or all entries when count is None or zero.
- `Logger::filter_category` (`logger.rs`): Return entries whose category starts with the requested prefix.
- `Logger::clear` (`logger.rs`): Remove all in-memory history entries and return unit.
- `value_to_string` (`lua_display.rs`): Convert one Lua value to display text and return a fallback for unknown kinds.
- `ProfileZone::total_time` (`profiler.rs`): Return total duration of this zone in seconds.
- `ProfileZone::self_time` (`profiler.rs`): Return exclusive duration after subtracting child zone totals.
- `ProfileZone::flatten` (`profiler.rs`): Return a flattened pre-order list containing this zone and descendants.
- `Profiler::new` (`profiler.rs`): Create profiler state with recording disabled and default retention.
- `Profiler::elapsed` (`profiler.rs`): Return elapsed time in seconds from profiler epoch.
- `Profiler::push` (`profiler.rs`): Push a zone name onto the stack when profiling is enabled.
- `Profiler::pop` (`profiler.rs`): Pop current zone and attach it to parent or temporary frame root bucket.
- `Profiler::end_frame` (`profiler.rs`): Finalize current frame zones and append them to retained frame history.
- `Profiler::get_frame` (`profiler.rs`): Return one frame by index, supporting non-positive indices from the end.
- `Profiler::reset` (`profiler.rs`): Clear active zones and stored frame history.
- `ReplConsole::new` (`repl.rs`): Create a REPL console with bounded history and return the instance.
- `ReplConsole::eval` (`repl.rs`): Evaluate input and return expression result, ok marker, or error text.
- `ReplConsole::history` (`repl.rs`): Return an immutable slice of stored history entries.
- `ReplConsole::clear` (`repl.rs`): Clear command history and return unit.
- `ReplConsole::len` (`repl.rs`): Return the number of stored history entries.
- `ReplConsole::is_empty` (`repl.rs`): Return true when history contains no entries.
- `TimeAnchor::new` (`time_anchor.rs`): Create a new anchor from the current instant and return it.
- `TimeAnchor::elapsed_seconds` (`time_anchor.rs`): Return elapsed time in seconds since this anchor was created.
- `FileWatcher::new` (`watcher.rs`): Create watcher state and return native-backed watcher when feature is enabled.
- `FileWatcher::watch` (`watcher.rs`): Start watching a path and return unit.
- `FileWatcher::unwatch` (`watcher.rs`): Stop watching a path and return true when an entry was removed.
- `FileWatcher::watched_paths` (`watcher.rs`): Return watched paths as owned strings.
- `FileWatcher::poll` (`watcher.rs`): Poll all watched paths and return changed path strings.
- `FileWatcher::clear` (`watcher.rs`): Unregister all native watches, clear tracked paths, and return unit.
- `FileWatcher::force_changed` (`watcher.rs`): Mark all watched paths as stale so next poll reports them as changed.

## Lua API Reference

- Binding path(s): `src/lua_api/devtools_api.rs`
- Namespace: `lurek.devtools`

### Module Functions
- `lurek.devtools.log`: Adds a message to the devtools log using an explicit severity level.
- `lurek.devtools.trace`: Adds a trace-level diagnostic message to the devtools log.
- `lurek.devtools.debug`: Adds a debug-level diagnostic message to the devtools log.
- `lurek.devtools.info`: Adds an info-level diagnostic message to the devtools log.
- `lurek.devtools.warn`: Adds a warning-level diagnostic message to the devtools log.
- `lurek.devtools.error`: Adds an error-level diagnostic message to the devtools log.
- `lurek.devtools.fatal`: Adds a fatal-level diagnostic message to the devtools log.
- `lurek.devtools.setLogLevel`: Sets the minimum severity that remains visible in devtools log output.
- `lurek.devtools.getLogLevel`: Returns the minimum severity currently used by devtools log output.
- `lurek.devtools.setLogConsole`: Enables or disables mirroring devtools log entries to the console.
- `lurek.devtools.getLogConsole`: Returns whether devtools log entries are mirrored to the console.
- `lurek.devtools.setLogFile`: Sets the file path used by devtools file logging state.
- `lurek.devtools.getLogFile`: Returns the file path currently stored as the devtools log target.
- `lurek.devtools.getLogHistory`: Returns recent devtools log entries as structured tables.
- `lurek.devtools.clearLog`: Clears all in-memory devtools log entries.
- `lurek.devtools.setProfilingEnabled`: Enables or disables collection of CPU profiling zones.
- `lurek.devtools.isProfilingEnabled`: Returns whether CPU profiling zone collection is currently enabled.
- `lurek.devtools.profilePush`: Starts a named profiling zone on the current profiler stack.
- `lurek.devtools.profilePop`: Ends the current profiling zone on the profiler stack.
- `lurek.devtools.profileFrame`: Closes the current profiling frame and stores its zone tree for later inspection.
- `lurek.devtools.getProfileFrameCount`: Returns how many profiling frames are currently stored.
- `lurek.devtools.getProfileData`: Returns the profiler zone tree for a retained frame.
- `lurek.devtools.resetProfile`: Clears profiler state, active zones, and retained profiling frames.
- `lurek.devtools.recordFrameTime`: Records one CPU frame duration sample for devtools frame statistics.
- `lurek.devtools.getFrameStats`: Returns aggregate CPU frame timing statistics from recorded samples.
- `lurek.devtools.recordGpuFrameTime`: Records one GPU frame duration sample for devtools frame statistics.
- `lurek.devtools.getGpuFrameStats`: Returns aggregate GPU frame timing statistics from recorded samples.
- `lurek.devtools.getFrameHistory`: Returns retained CPU frame duration samples in insertion order.
- `lurek.devtools.setFrameHistorySize`: Sets the maximum number of CPU frame duration samples retained by devtools.
- `lurek.devtools.getFrameHistorySize`: Returns the current CPU frame history capacity.
- `lurek.devtools.watch`: Adds a path to the module-level devtools file watcher.
- `lurek.devtools.unwatch`: Removes a path from the module-level devtools file watcher.
- `lurek.devtools.getWatchedPaths`: Returns all paths currently watched by the module-level file watcher.
- `lurek.devtools.scan`: Polls module-level file watches and returns paths that changed since the previous scan.
- `lurek.devtools.clearWatches`: Removes every path from the module-level file watcher.
- `lurek.devtools.getWatchInterval`: Returns the polling interval hint used by devtools watch UIs.
- `lurek.devtools.setWatchInterval`: Sets the polling interval hint used by devtools watch UIs.
- `lurek.devtools.getCallStack`: Returns Lua call stack frames using the Lua debug library.
- `lurek.devtools.eval`: Evaluates Lua code in the current state and returns success plus values or failure plus an error message.
- `lurek.devtools.openConsole`: Marks the devtools console as open for UI state tracking.
- `lurek.devtools.isConsoleOpen`: Returns whether the devtools console is marked open.
- `lurek.devtools.openEntityInspector`: Marks the devtools entity inspector as open for UI state tracking.
- `lurek.devtools.isEntityInspectorOpen`: Returns whether the devtools entity inspector is marked open.
- `lurek.devtools.exposeWatch`: Registers a watch expression callback for snapshots and watch panels.
- `lurek.devtools.removeWatch`: Removes a previously exposed watch expression by id.
- `lurek.devtools.getWatches`: Evaluates exposed watch callbacks and returns their current values.
- `lurek.devtools.snapshot`: Captures a combined devtools snapshot containing frame stats, watch values, profile data, and recent logs.
- `lurek.devtools.profilerReport`: Aggregates retained profiler frames into per-zone timing rows.
- `lurek.devtools.newFileWatcher`: Creates a dedicated file watcher userdata for one path.
- `lurek.devtools.newRepl`: Creates a REPL console userdata with bounded command history.

### `LFileWatcher` Methods
- `LFileWatcher:onChanged`: Sets the callback invoked when this watcher observes a change.
- `LFileWatcher:check`: Polls the watcher and invokes the change callback when a change is found.
- `LFileWatcher:getPath`: Returns the watched path.
- `LFileWatcher:cancel`: Cancels this watcher and removes its callback.
- `LFileWatcher:type`: Returns the Lua-visible type name for this file watcher handle.
- `LFileWatcher:typeOf`: Returns whether this file watcher handle matches a supported type name.

### `LReplConsole` Methods
- `LReplConsole:eval`: Evaluates Lua code through this REPL console and records it in history.
- `LReplConsole:history`: Returns this REPL console's recorded command history.
- `LReplConsole:clear`: Clears this REPL console's command history.
- `LReplConsole:len`: Returns the number of entries stored in this REPL console history.
- `LReplConsole:type`: Returns the Lua-visible type name for this REPL console handle.
- `LReplConsole:typeOf`: Returns whether this REPL console handle matches a supported type name.

## References

- `filesystem`: Imports or references `src/filesystem/`. Cross-group dependency from `Edge/Integration` into `Core Runtime`.

## Notes

- Keep this module reference synchronized with `src/devtools/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
