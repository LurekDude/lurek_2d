//! `lurek.devtools` -- Developer tooling bindings for logs, profiling, frame stats, file watching, console state, watch expressions, snapshots, REPL, and debugger-style eval helpers.

use crate::devtools::{FileWatcher, FrameStats, Logger, ProfileZone, Profiler, ReplConsole};
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Stored devtools watch expression with display metadata.
struct WatchEntry {
    /// Watch display name.
    name: String,
    /// Lua callback that returns the current watch value.
    getter: LuaRegistryKey,
    /// Optional category label used by inspector UIs.
    category: String,
}
/// Shared devtools state captured by module closures.
struct DevtoolsShared {
    /// In-memory logger and log settings.
    logger: Logger,
    /// CPU profiler state and recorded frames.
    profiler: Profiler,
    /// CPU frame timing history.
    frame_stats: FrameStats,
    /// GPU frame timing history.
    gpu_frame_stats: FrameStats,
    /// File watcher state for module-level watch calls.
    watcher: FileWatcher,
    /// Console visibility flag.
    console_open: bool,
    /// Entity inspector visibility flag.
    entity_inspector_open: bool,
    /// Poll interval used by watch UIs.
    watch_interval: f32,
    /// Registered watch callbacks.
    watches: Vec<WatchEntry>,
    /// Next watch id assigned by `exposeWatch`.
    next_watch_id: u64,
}
impl DevtoolsShared {
    /// Creates default devtools shared state.
    fn new() -> Self {
        Self {
            logger: Logger::new(),
            profiler: Profiler::new(),
            frame_stats: FrameStats::default(),
            gpu_frame_stats: FrameStats::default(),
            watcher: FileWatcher::new(),
            console_open: false,
            entity_inspector_open: false,
            watch_interval: 0.5,
            watches: Vec::new(),
            next_watch_id: 1,
        }
    }
}
/// Converts a profiler zone tree into a Lua table.
fn zone_to_table<'a>(lua: &'a Lua, zone: &ProfileZone) -> LuaResult<LuaTable<'a>> {
    let tbl = lua.create_table()?;
    /// Performs the 'name' operation.
    tbl.set("name", zone.name.clone())?;
    /// Performs the 'time' operation.
    tbl.set("time", zone.total_time())?;
    /// Performs the 'selfTime' operation.
    tbl.set("selfTime", zone.self_time())?;
    /// Performs the 'startTime' operation.
    tbl.set("startTime", zone.start_time)?;
    let children = lua.create_table()?;
    for (i, child) in zone.children.iter().enumerate() {
        children.set(i + 1, zone_to_table(lua, child)?)?;
    }
    /// Performs the 'children' operation.
    tbl.set("children", children)?;
    Ok(tbl)
}
/// Lua-side file watcher with an optional change callback.
struct LuaFileWatcher {
    /// File watcher tracking the configured path.
    watcher: FileWatcher,
    /// Watched path string returned to Lua.
    path: String,
    /// Optional registry key for the change callback.
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}
/// Provides Lua methods for polling, cancelling, and identifying file watcher handles.
impl LuaUserData for LuaFileWatcher {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- onChanged --
        /// Sets the callback invoked when this watcher observes a change.
        /// @param | func | function | Callback called with no arguments after a change is detected.
        methods.add_method_mut("onChanged", |lua, this, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            if let Some(old) = this.callback.borrow_mut().replace(key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        // -- check --
        /// Polls the watcher and invokes the change callback when a change is found.
        /// @return | boolean | True when at least one change was detected.
        methods.add_method_mut("check", |lua, this, ()| {
            let changed = this.watcher.poll();
            if !changed.is_empty() {
                if let Some(key) = this.callback.borrow().as_ref() {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        func.call::<_, ()>(())?;
                    }
                }
                return Ok(true);
            }
            Ok(false)
        });
        // -- getPath --
        /// Returns the watched path. This method is available to Lua scripts.
        /// @return | string | Watched path string.
        methods.add_method("getPath", |_, this, ()| Ok(this.path.clone()));
        // -- cancel --
        /// Cancels this watcher and removes its callback.
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.watcher.clear();
            if let Some(key) = this.callback.borrow_mut().take() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this file watcher handle.
        /// @return | string | The string `LFileWatcher`.
        methods.add_method("type", |_, _, ()| Ok("LFileWatcher"));
        // -- typeOf --
        /// Returns whether this file watcher handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LFileWatcher` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileWatcher" || name == "Object")
        });
    }
}
/// Registers the `lurek.devtools` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let dt = lua.create_table()?;
    let shared = Rc::new(RefCell::new(DevtoolsShared::new()));

    // -- log --
    /// Adds a message to the devtools log using an explicit severity level.
    /// @param | level | string | Log level name such as `trace`, `debug`, `info`, `warn`, `error`, or `fatal`.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "log",
        lua.create_function(move |_, (level, message): (String, String)| {
            s.borrow_mut().logger.push(&level, &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- trace --
    /// Adds a trace-level diagnostic message to the devtools log.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "trace",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("trace", &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- debug --
    /// Adds a debug-level diagnostic message to the devtools log.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "debug",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("debug", &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- info --
    /// Adds an info-level diagnostic message to the devtools log.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "info",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("info", &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- warn --
    /// Adds a warning-level diagnostic message to the devtools log.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "warn",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("warn", &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- error --
    /// Adds an error-level diagnostic message to the devtools log.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "error",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("error", &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- fatal --
    /// Adds a fatal-level diagnostic message to the devtools log.
    /// @param | message | string | Message text stored in the in-memory log history.
    let s = shared.clone();
    dt.set(
        "fatal",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("fatal", &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    // -- setLogLevel --
    /// Sets the minimum severity that remains visible in devtools log output.
    /// @param | level | string | Log level name parsed by the devtools logger; unknown names are ignored.
    let s = shared.clone();
    dt.set(
        "setLogLevel",
        lua.create_function(move |_, level: String| {
            use crate::devtools::LogLevel;
            if let Some(lv) = LogLevel::from_str(&level) {
                s.borrow_mut().logger.min_level = lv;
            }
            Ok(())
        })?,
    )?;

    // -- getLogLevel --
    /// Returns the minimum severity currently used by devtools log output.
    /// @return | string | Current minimum log level name.
    let s = shared.clone();
    dt.set(
        "getLogLevel",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.min_level.as_str().to_string()))?,
    )?;

    // -- setLogConsole --
    /// Enables or disables mirroring devtools log entries to the console.
    /// @param | enabled | boolean | True to emit future log entries to console output.
    let s = shared.clone();
    dt.set(
        "setLogConsole",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().logger.console_enabled = enabled;
            Ok(())
        })?,
    )?;

    // -- getLogConsole --
    /// Returns whether devtools log entries are mirrored to the console.
    /// @return | boolean | True when console logging is enabled.
    let s = shared.clone();
    dt.set(
        "getLogConsole",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.console_enabled))?,
    )?;

    // -- setLogFile --
    /// Sets the file path used by devtools file logging state.
    /// @param | path | string | File path recorded as the active devtools log target.
    let s = shared.clone();
    dt.set(
        "setLogFile",
        lua.create_function(move |_, path: String| {
            s.borrow_mut().logger.log_file = path;
            Ok(())
        })?,
    )?;

    // -- getLogFile --
    /// Returns the file path currently stored as the devtools log target.
    /// @return | string | Current log file path.
    let s = shared.clone();
    dt.set(
        "getLogFile",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.log_file.clone()))?,
    )?;

    // -- getLogHistory --
    /// Returns recent devtools log entries as structured tables.
    /// @param | count | integer? | Optional number of newest entries to return; omitted returns the logger default.
    /// @return | table | Array table containing level, timestamp, message, source, line, and optional category fields.
    /// @field | level | string | Log level.
    /// @field | timestamp | number | Unix timestamp.
    /// @field | message | string | Log message.
    /// @field | source | string | Source file.
    /// @field | line | integer | Line number.
    /// @field | category | string? | Optional log category.
    let s = shared.clone();
    dt.set(
        "getLogHistory",
        lua.create_function(move |lua, count: Option<usize>| {
            let st = s.borrow();
            let entries = st.logger.tail(count);
            let tbl = lua.create_table()?;
            for (i, entry) in entries.iter().enumerate() {
                let e = lua.create_table()?;
                /// Performs the 'level' operation.
                e.set("level", entry.level.clone())?;
                /// Performs the 'timestamp' operation.
                e.set("timestamp", entry.timestamp)?;
                /// Performs the 'message' operation.
                e.set("message", entry.message.clone())?;
                /// Performs the 'source' operation.
                e.set("source", entry.source.clone())?;
                /// Performs the 'line' operation.
                e.set("line", entry.line)?;
                if let Some(ref cat) = entry.category {
                    /// Performs the 'category' operation.
                    e.set("category", cat.clone())?;
                }
                tbl.set(i + 1, e)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- clearLog --
    /// Clears all in-memory devtools log entries.
    let s = shared.clone();
    dt.set(
        "clearLog",
        lua.create_function(move |_, ()| {
            s.borrow_mut().logger.clear();
            Ok(())
        })?,
    )?;

    // -- setProfilingEnabled --
    /// Enables or disables collection of CPU profiling zones.
    /// @param | enabled | boolean | True to record profiling zones into future profiler frames.
    let s = shared.clone();
    dt.set(
        "setProfilingEnabled",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().profiler.enabled = enabled;
            Ok(())
        })?,
    )?;

    // -- isProfilingEnabled --
    /// Returns whether CPU profiling zone collection is currently enabled.
    /// @return | boolean | True when profiler recording is enabled.
    let s = shared.clone();
    dt.set(
        "isProfilingEnabled",
        lua.create_function(move |_, ()| Ok(s.borrow().profiler.enabled))?,
    )?;

    // -- profilePush --
    /// Starts a named profiling zone on the current profiler stack.
    /// @param | name | string | Profiling zone name shown in reports and snapshots.
    let s = shared.clone();
    dt.set(
        "profilePush",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().profiler.push(&name);
            Ok(())
        })?,
    )?;

    // -- profilePop --
    /// Ends the current profiling zone on the profiler stack.
    /// @param | name | string? | Optional zone name accepted for API compatibility and ignored by the profiler.
    let s = shared.clone();
    dt.set(
        "profilePop",
        lua.create_function(move |_, _: Option<String>| {
            s.borrow_mut().profiler.pop();
            Ok(())
        })?,
    )?;

    // -- profileFrame --
    /// Closes the current profiling frame and stores its zone tree for later inspection.
    let s = shared.clone();
    dt.set(
        "profileFrame",
        lua.create_function(move |_, ()| {
            s.borrow_mut().profiler.end_frame();
            Ok(())
        })?,
    )?;

    // -- getProfileFrameCount --
    /// Returns how many profiling frames are currently stored.
    /// @return | integer | Number of retained profiler frames.
    let s = shared.clone();
    dt.set(
        "getProfileFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().profiler.frames.len()))?,
    )?;

    // -- getProfileData --
    /// Returns the profiler zone tree for a retained frame.
    /// @param | frame | integer? | Optional frame index understood by the profiler; omitted reads the newest frame alias used by the backend.
    /// @return | table | Array of profiler zones with name, time, selfTime, startTime, and children fields.
    /// @field | name | string | Zone name.
    /// @field | time | number | Total time in ms.
    /// @field | selfTime | number | Self time in ms.
    /// @field | startTime | number | Start time in ms.
    /// @field | children | table | Nested child zones.
    let s = shared.clone();
    dt.set(
        "getProfileData",
        lua.create_function(move |lua, frame: Option<i64>| {
            let st = s.borrow();
            let idx = frame.unwrap_or(0);
            let tbl = lua.create_table()?;
            if let Some(zones) = st.profiler.get_frame(idx) {
                for (i, zone) in zones.iter().enumerate() {
                    tbl.set(i + 1, zone_to_table(lua, zone)?)?;
                }
            }
            Ok(tbl)
        })?,
    )?;

    // -- resetProfile --
    /// Clears profiler state, active zones, and retained profiling frames.
    let s = shared.clone();
    dt.set(
        "resetProfile",
        lua.create_function(move |_, ()| {
            s.borrow_mut().profiler.reset();
            Ok(())
        })?,
    )?;

    // -- recordFrameTime --
    /// Records one CPU frame duration sample for devtools frame statistics.
    /// @param | dt_val | number | Frame duration in seconds.
    let s = shared.clone();
    dt.set(
        "recordFrameTime",
        lua.create_function(move |_, dt_val: f64| {
            s.borrow_mut().frame_stats.record(dt_val);
            Ok(())
        })?,
    )?;

    // -- getFrameStats --
    /// Returns aggregate CPU frame timing statistics from recorded samples.
    /// @return | table | Table containing fps, dt, avg, min, max, p50, p95, p99, and samples fields.
    /// @field | fps | number | Fps.
    /// @field | dt | number | Dt.
    /// @field | avg | number | Avg.
    /// @field | min | number | Min.
    /// @field | max | number | Max.
    /// @field | p50 | number | P50.
    /// @field | p95 | number | P95.
    /// @field | p99 | number | P99.
    /// @field | samples | integer | Samples.
    let s = shared.clone();
    dt.set(
        "getFrameStats",
        lua.create_function(move |lua, ()| {
            let snap = s.borrow().frame_stats.snapshot();
            let tbl = lua.create_table()?;
            /// Performs the 'fps' operation.
            tbl.set("fps", snap.fps)?;
            /// Performs the 'dt' operation.
            tbl.set("dt", snap.dt)?;
            /// Performs the 'avg' operation.
            tbl.set("avg", snap.avg)?;
            /// Performs the 'min' operation.
            tbl.set("min", snap.min)?;
            /// Performs the 'max' operation.
            tbl.set("max", snap.max)?;
            /// Performs the 'p50' operation.
            tbl.set("p50", snap.p50)?;
            /// Performs the 'p95' operation.
            tbl.set("p95", snap.p95)?;
            /// Performs the 'p99' operation.
            tbl.set("p99", snap.p99)?;
            /// Performs the 'samples' operation.
            tbl.set("samples", snap.samples)?;
            Ok(tbl)
        })?,
    )?;

    // -- recordGpuFrameTime --
    /// Records one GPU frame duration sample for devtools frame statistics.
    /// @param | dt_val | number | GPU frame duration in seconds.
    let s = shared.clone();
    dt.set(
        "recordGpuFrameTime",
        lua.create_function(move |_, dt_val: f64| {
            s.borrow_mut().gpu_frame_stats.record(dt_val);
            Ok(())
        })?,
    )?;

    // -- getGpuFrameStats --
    /// Returns aggregate GPU frame timing statistics from recorded samples.
    /// @return | table | Table containing fps, dt, avg, min, max, p50, p95, p99, and samples fields.
    /// @field | fps | number | Fps.
    /// @field | dt | number | Dt.
    /// @field | avg | number | Avg.
    /// @field | min | number | Min.
    /// @field | max | number | Max.
    /// @field | p50 | number | P50.
    /// @field | p95 | number | P95.
    /// @field | p99 | number | P99.
    /// @field | samples | integer | Samples.
    let s = shared.clone();
    dt.set(
        "getGpuFrameStats",
        lua.create_function(move |lua, ()| {
            let snap = s.borrow().gpu_frame_stats.snapshot();
            let tbl = lua.create_table()?;
            /// Performs the 'fps' operation.
            tbl.set("fps", snap.fps)?;
            /// Performs the 'dt' operation.
            tbl.set("dt", snap.dt)?;
            /// Performs the 'avg' operation.
            tbl.set("avg", snap.avg)?;
            /// Performs the 'min' operation.
            tbl.set("min", snap.min)?;
            /// Performs the 'max' operation.
            tbl.set("max", snap.max)?;
            /// Performs the 'p50' operation.
            tbl.set("p50", snap.p50)?;
            /// Performs the 'p95' operation.
            tbl.set("p95", snap.p95)?;
            /// Performs the 'p99' operation.
            tbl.set("p99", snap.p99)?;
            /// Performs the 'samples' operation.
            tbl.set("samples", snap.samples)?;
            Ok(tbl)
        })?,
    )?;

    // -- getFrameHistory --
    /// Returns retained CPU frame duration samples in insertion order.
    /// @return | number[] | Array table of CPU frame durations in seconds.
    let s = shared.clone();
    dt.set(
        "getFrameHistory",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, &val) in st.frame_stats.history.iter().enumerate() {
                tbl.set(i + 1, val)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- setFrameHistorySize --
    /// Sets the maximum number of CPU frame duration samples retained by devtools.
    /// @param | size | integer | Maximum number of frame samples to keep.
    let s = shared.clone();
    dt.set(
        "setFrameHistorySize",
        lua.create_function(move |_, size: usize| {
            s.borrow_mut().frame_stats.set_capacity(size);
            Ok(())
        })?,
    )?;

    // -- getFrameHistorySize --
    /// Returns the current CPU frame history capacity.
    /// @return | integer | Maximum number of retained CPU frame duration samples.
    let s = shared.clone();
    dt.set(
        "getFrameHistorySize",
        lua.create_function(move |_, ()| Ok(s.borrow().frame_stats.capacity))?,
    )?;

    // -- watch --
    /// Adds a path to the module-level devtools file watcher.
    /// @param | path | string | File or directory path to poll for changes.
    /// @return | boolean | True when the path was newly added; false when it was already watched.
    let s = shared.clone();
    dt.set(
        "watch",
        lua.create_function(move |_, path: String| {
            let mut st = s.borrow_mut();
            if st.watcher.paths.contains_key(std::path::Path::new(&path)) {
                return Ok(false);
            }
            st.watcher.watch(&path);
            Ok(true)
        })?,
    )?;

    // -- unwatch --
    /// Removes a path from the module-level devtools file watcher.
    /// @param | path | string | Previously watched file or directory path.
    /// @return | boolean | True when the path was removed.
    let s = shared.clone();
    dt.set(
        "unwatch",
        lua.create_function(move |_, path: String| Ok(s.borrow_mut().watcher.unwatch(&path)))?,
    )?;

    // -- getWatchedPaths --
    /// Returns all paths currently watched by the module-level file watcher.
    /// @return | string[] | Sorted array table of watched path strings.
    let s = shared.clone();
    dt.set(
        "getWatchedPaths",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let mut paths = st.watcher.watched_paths();
            paths.sort();
            let tbl = lua.create_table()?;
            for (i, p) in paths.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- scan --
    /// Polls module-level file watches and returns paths that changed since the previous scan.
    /// @return | string[] | Changed path strings.
    let s = shared.clone();
    dt.set(
        "scan",
        lua.create_function(move |lua, ()| {
            let mut st = s.borrow_mut();
            let changed = st.watcher.poll();
            let tbl = lua.create_table()?;
            for (i, p) in changed.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- clearWatches --
    /// Removes every path from the module-level file watcher.
    let s = shared.clone();
    dt.set(
        "clearWatches",
        lua.create_function(move |_, ()| {
            s.borrow_mut().watcher.clear();
            Ok(())
        })?,
    )?;

    // -- getWatchInterval --
    /// Returns the polling interval hint used by devtools watch UIs.
    /// @return | number | Watch interval in seconds.
    let s = shared.clone();
    dt.set(
        "getWatchInterval",
        lua.create_function(move |_, ()| Ok(s.borrow().watch_interval))?,
    )?;

    // -- setWatchInterval --
    /// Sets the polling interval hint used by devtools watch UIs.
    /// @param | interval | number | Watch interval in seconds, clamped to at least 0.01.
    let s = shared.clone();
    dt.set(
        "setWatchInterval",
        lua.create_function(move |_, interval: f32| {
            s.borrow_mut().watch_interval = interval.max(0.01);
            Ok(())
        })?,
    )?;

    // -- getCallStack --
    /// Returns Lua call stack frames using the Lua debug library.
    /// @param | max_depth | integer? | Optional maximum number of frames to return; defaults to 20 and is capped at 100.
    /// @return | any[] | Array of frame tables; each has source (string), line (integer), name (string), and what (string) fields.
    dt.set(
        "getCallStack",
        lua.create_function(|lua, max_depth: Option<usize>| {
            let max = max_depth.unwrap_or(20).min(100);
            let code = "local max = ...\n\
            local frames = {}\n\
            if not debug or not debug.getinfo then return frames end\n\
            for i = 2, max + 1 do\n\
              local info = debug.getinfo(i, 'Snl')\n\
              if not info then break end\n\
              frames[#frames+1] = {\n\
                source = info.short_src or '?',\n\
                line = info.currentline or 0,\n\
                name = info.name or '?',\n\
                what = info.namewhat or ''\n\
              }\n\
            end\n\
            return frames";
            // LUA-EVAL-JUSTIFIED: devtools.getCallStack runs a fixed debug introspection script.
            let frames: LuaTable = lua.load(code).call(max)?;
            Ok(frames)
        })?,
    )?;

    // -- eval --
    /// Evaluates Lua code in the current state and returns success plus values or failure plus an error message.
    /// @param | code | string | Lua source code evaluated through the current Lua VM.
    /// @return | LuaValue | Multi-return where the first value is a boolean success flag followed by result values or an error string.
    dt.set(
        "eval",
        lua.create_function(|lua, code: String| {
            // LUA-EVAL-JUSTIFIED: devtools.eval is an explicit REPL/debug eval API.
            match lua.load(&code).eval::<LuaMultiValue>() {
                Ok(vals) => {
                    let mut result = vec![LuaValue::Boolean(true)];
                    result.extend(vals.into_iter());
                    Ok(LuaMultiValue::from_vec(result))
                }
                Err(e) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Boolean(false),
                    LuaValue::String(lua.create_string(e.to_string().as_bytes())?),
                ])),
            }
        })?,
    )?;

    // -- openConsole --
    /// Marks the devtools console as open for UI state tracking.
    /// @return | boolean | Always returns true after setting the console-open flag.
    let s = shared.clone();
    dt.set(
        "openConsole",
        lua.create_function(move |_, ()| {
            s.borrow_mut().console_open = true;
            Ok(true)
        })?,
    )?;

    // -- isConsoleOpen --
    /// Returns whether the devtools console is marked open.
    /// @return | boolean | True when the console-open flag is set.
    let s = shared.clone();
    dt.set(
        "isConsoleOpen",
        lua.create_function(move |_, ()| Ok(s.borrow().console_open))?,
    )?;

    // -- openEntityInspector --
    /// Marks the devtools entity inspector as open for UI state tracking.
    /// @return | boolean | Always returns true after setting the entity-inspector flag.
    let s = shared.clone();
    dt.set(
        "openEntityInspector",
        lua.create_function(move |_, ()| {
            s.borrow_mut().entity_inspector_open = true;
            Ok(true)
        })?,
    )?;

    // -- isEntityInspectorOpen --
    /// Returns whether the devtools entity inspector is marked open.
    /// @return | boolean | True when the entity-inspector-open flag is set.
    let s = shared.clone();
    dt.set(
        "isEntityInspectorOpen",
        lua.create_function(move |_, ()| Ok(s.borrow().entity_inspector_open))?,
    )?;

    // -- exposeWatch --
    /// Registers a watch expression callback for snapshots and watch panels.
    /// @param | name | string | Display name for the watch entry.
    /// @param | getter | function | Callback invoked with no arguments when watch values are collected.
    /// @param | category | string | Optional category label used by devtools UIs.
    /// @return | integer | Numeric watch id that can be passed to `removeWatch`.
    let s = shared.clone();
    dt.set(
        "exposeWatch",
        lua.create_function(
            move |lua, (name, getter, category): (String, LuaFunction, Option<String>)| {
                let key = lua.create_registry_value(getter)?;
                let mut st = s.borrow_mut();
                let id = st.next_watch_id;
                st.next_watch_id += 1;
                st.watches.push(WatchEntry {
                    name,
                    getter: key,
                    category: category.unwrap_or_default(),
                });
                Ok(id)
            },
        )?,
    )?;

    // -- removeWatch --
    /// Removes a previously exposed watch expression by id.
    /// @param | id | integer | Watch id returned by `exposeWatch`.
    /// @return | boolean | True when a watch entry was removed.
    let s = shared.clone();
    dt.set(
        "removeWatch",
        lua.create_function(move |_, id: u64| {
            let mut st = s.borrow_mut();
            let start_id = st.next_watch_id - st.watches.len() as u64;
            let idx = id.checked_sub(start_id) as Option<u64>;
            if let Some(i) = idx {
                if (i as usize) < st.watches.len() {
                    st.watches.remove(i as usize);
                    return Ok(true);
                }
            }
            Ok(false)
        })?,
    )?;

    // -- getWatches --
    /// Evaluates exposed watch callbacks and returns their current values.
    /// @return | table | Array of watch rows with name, category, and value fields.
    /// @field | name | string | Watch name.
    /// @field | category | string | Category.
    /// @field | value | string | Formatted value.
    let s = shared.clone();
    dt.set(
        "getWatches",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, entry) in st.watches.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'name' operation.
                row.set("name", entry.name.clone())?;
                /// Performs the 'category' operation.
                row.set("category", entry.category.clone())?;
                let getter: LuaFunction = lua.registry_value(&entry.getter)?;
                match getter.call::<_, LuaValue>(()) {
                    Ok(v) => {
                        /// Performs the 'value' operation.
                        row.set("value", v)?;
                    }
                    Err(e) => {
                        /// Performs the 'value' operation.
                        row.set("value", format!("(error: {})", e))?;
                    }
                }
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- snapshot --
    /// Captures a combined devtools snapshot containing frame stats, watch values, profile data, and recent logs.
    /// @return | table | Snapshot table with frameStats, watches, profile, log, and watchCount fields.
    /// @field | frameStats | table | Frame statistics table.
    /// @field | watches | table | Watch values table.
    /// @field | profile | table | Profile data table.
    /// @field | log | table | Recent log entries table.
    /// @field | watchCount | integer | WatchCount.
    let s = shared.clone();
    dt.set(
        "snapshot",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let snap = lua.create_table()?;
            let fs = st.frame_stats.snapshot();
            let fst = lua.create_table()?;
            /// Performs the 'fps' operation.
            fst.set("fps", fs.fps)?;
            /// Performs the 'dt' operation.
            fst.set("dt", fs.dt)?;
            /// Performs the 'avg' operation.
            fst.set("avg", fs.avg)?;
            /// Performs the 'p95' operation.
            fst.set("p95", fs.p95)?;
            /// Performs the 'p99' operation.
            fst.set("p99", fs.p99)?;
            /// Performs the 'frameStats' operation.
            snap.set("frameStats", fst)?;
            let watches_tbl = lua.create_table()?;
            for (i, entry) in st.watches.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'name' operation.
                row.set("name", entry.name.clone())?;
                /// Performs the 'category' operation.
                row.set("category", entry.category.clone())?;
                let getter: LuaFunction = lua.registry_value(&entry.getter)?;
                match getter.call::<_, LuaValue>(()) {
                    Ok(v) => {
                        /// Performs the 'value' operation.
                        row.set("value", v)?;
                    }
                    Err(e) => {
                        /// Performs the 'value' operation.
                        row.set("value", format!("(error: {})", e))?;
                    }
                }
                watches_tbl.set(i + 1, row)?;
            }
            /// Performs the 'watches' operation.
            snap.set("watches", watches_tbl)?;
            let profile_tbl = lua.create_table()?;
            if let Some(zones) = st.profiler.get_frame(0) {
                for (i, zone) in zones.iter().enumerate() {
                    profile_tbl.set(i + 1, zone_to_table(lua, zone)?)?;
                }
            }
            /// Performs the 'profile' operation.
            snap.set("profile", profile_tbl)?;
            let log_tbl = lua.create_table()?;
            for (i, entry) in st.logger.tail(Some(10)).iter().enumerate() {
                let et = lua.create_table()?;
                /// Performs the 'level' operation.
                et.set("level", entry.level.clone())?;
                /// Performs the 'message' operation.
                et.set("message", entry.message.clone())?;
                /// Performs the 'source' operation.
                et.set("source", entry.source.clone())?;
                log_tbl.set(i + 1, et)?;
            }
            /// Performs the 'log' operation.
            snap.set("log", log_tbl)?;
            /// Performs the 'watchCount' operation.
            snap.set("watchCount", st.watches.len())?;
            Ok(snap)
        })?,
    )?;

    // -- profilerReport --
    /// Aggregates retained profiler frames into per-zone timing rows.
    /// @return | table | Array table with zone name, call count, total_ms, avg_ms, min_ms, max_ms, and self_ms fields.
    /// @field | name | string | Zone name.
    /// @field | call_count | integer | Call count.
    /// @field | total_ms | number | Total time in ms.
    /// @field | avg_ms | number | Average time per call in ms.
    /// @field | min_ms | number | Minimum time in ms.
    /// @field | max_ms | number | Maximum time in ms.
    /// @field | self_ms | number | Self time in ms.
    let s = shared.clone();
    dt.set(
        "profilerReport",
        lua.create_function(move |lua, ()| {
            let mut aggregated: std::collections::HashMap<String, (f64, u32, f64, f64, f64)> =
                Default::default();
            let st = s.borrow();
            for frame in &st.profiler.frames {
                for zone in frame.iter() {
                    for z in zone.flatten() {
                        let dur = z.total_time() * 1000.0;
                        let self_dur = z.self_time() * 1000.0;
                        let e = aggregated.entry(z.name.clone()).or_insert((
                            0.0,
                            0,
                            f64::MAX,
                            0.0_f64,
                            0.0,
                        ));
                        e.0 += dur;
                        e.1 += 1;
                        e.2 = e.2.min(dur);
                        e.3 = e.3.max(dur);
                        e.4 += self_dur;
                    }
                }
            }
            let out = lua.create_table()?;
            for (i, (name, (total, calls, min, max, self_ms))) in aggregated.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'name' operation.
                row.set("name", name.clone())?;
                /// Performs the 'calls' operation.
                row.set("calls", *calls)?;
                /// Performs the 'total_ms' operation.
                row.set("total_ms", *total)?;
                row.set(
                    "avg_ms",
                    if *calls > 0 {
                        total / (*calls as f64)
                    } else {
                        0.0
                    },
                )?;
                /// Performs the 'min_ms' operation.
                row.set("min_ms", if *min == f64::MAX { 0.0 } else { *min })?;
                /// Performs the 'max_ms' operation.
                row.set("max_ms", *max)?;
                /// Performs the 'self_ms' operation.
                row.set("self_ms", *self_ms)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        })?,
    )?;

    // -- newFileWatcher --
    /// Creates a dedicated file watcher userdata for one path.
    /// @param | path | string | File or directory path watched by the returned handle.
    /// @return | LFileWatcher | File watcher handle with polling and callback methods.
    dt.set(
        "newFileWatcher",
        lua.create_function(|lua, path: String| {
            let mut fw = LuaFileWatcher {
                watcher: FileWatcher::new(),
                path: path.clone(),
                callback: Rc::new(RefCell::new(None)),
            };
            fw.watcher.watch(&path);
            lua.create_userdata(fw)
        })?,
    )?;

    // -- newRepl --
    /// Creates a REPL console userdata with bounded command history.
    /// @param | max_history | integer? | Optional maximum number of history entries; defaults to 200.
    /// @return | LReplConsole | REPL console handle for eval and history management.
    dt.set(
        "newRepl",
        lua.create_function(|lua, max_history: Option<usize>| {
            lua.create_userdata(LuaReplConsole {
                inner: ReplConsole::new(max_history.unwrap_or(200)),
            })
        })?,
    )?;
    /// Performs the 'devtools' operation.
    lurek.set("devtools", dt)?;
    Ok(())
}
/// Lua-side REPL console handle with bounded history.
pub struct LuaReplConsole {
    /// Console implementation that evaluates code and stores command history.
    inner: ReplConsole,
}
/// Provides Lua methods for evaluating code, reading history, and identifying REPL handles.
impl LuaUserData for LuaReplConsole {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- eval --
        /// Evaluates Lua code through this REPL console and records it in history.
        /// @param | code | string | Lua source code evaluated in the active Lua VM.
        /// @return | LuaValue | Evaluation result shape produced by the devtools REPL backend.
        methods.add_method_mut("eval", |lua, this, code: String| {
            Ok(this.inner.eval(&code, lua))
        });
        // -- history --
        /// Returns this REPL console's recorded command history.
        /// @return | string[] | History entry strings.
        methods.add_method("history", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, entry) in this.inner.history().iter().enumerate() {
                t.set(i + 1, entry.clone())?;
            }
            Ok(t)
        });
        // -- clear --
        /// Clears this REPL console's command history.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- len --
        /// Returns the number of entries stored in this REPL console history.
        /// @return | integer | History entry count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        // -- type --
        /// Returns the Lua-visible type name for this REPL console handle.
        /// @return | string | The string `LReplConsole`.
        methods.add_method("type", |_, _, ()| Ok("LReplConsole"));
        // -- typeOf --
        /// Returns whether this REPL console handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LReplConsole` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LReplConsole" || name == "Object")
        });
    }
}
