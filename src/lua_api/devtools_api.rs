//! Registers the `lurek.devtools.*` runtime diagnostics and developer-tools API.
//!
//! Thin Lua bridge that delegates to the [`devtools`][crate::devtools] domain module.
//! All state management happens in [`crate::devtools`]; this file only converts
//! between Lua values and domain types.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::devtools::{FileWatcher, FrameStats, Logger, ProfileZone, Profiler, ReplConsole};
use crate::runtime::SharedState;

// ---------------------------------------------------------------------------
// Bridge state
// ---------------------------------------------------------------------------

/// A named live watch â€” calls a getter function to sample a value at any time.
struct WatchEntry {
    /// Display name for this watch.
    name: String,
    /// Lua getter function stored in the registry.
    getter: LuaRegistryKey,
    /// Optional category tag.
    category: String,
}

struct DevtoolsShared {
    logger: Logger,
    profiler: Profiler,
    frame_stats: FrameStats,
    watcher: FileWatcher,
    console_open: bool,
    watch_interval: f32,
    /// Named live watches registered via `exposeWatch`.
    watches: Vec<WatchEntry>,
    /// Incrementing id counter for watch entries.
    next_watch_id: u64,
}

impl DevtoolsShared {
    fn new() -> Self {
        Self {
            logger: Logger::new(),
            profiler: Profiler::new(),
            frame_stats: FrameStats::default(),
            watcher: FileWatcher::new(),
            console_open: false,
            watch_interval: 0.5,
            watches: Vec::new(),
            next_watch_id: 1,
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Recursively converts a [`ProfileZone`] tree into a nested Lua table.
fn zone_to_table<'a>(lua: &'a Lua, zone: &ProfileZone) -> LuaResult<LuaTable<'a>> {
    let tbl = lua.create_table()?;
    /// @return table
    tbl.set("name", zone.name.clone())?;
    /// @return table
    tbl.set("time", zone.total_time())?;
    /// @return table
    tbl.set("selfTime", zone.self_time())?;
    /// @return table
    tbl.set("startTime", zone.start_time)?;
    let children = lua.create_table()?;
    for (i, child) in zone.children.iter().enumerate() {
        children.set(i + 1, zone_to_table(lua, child)?)?;
    }
    /// @return table
    tbl.set("children", children)?;
    Ok(tbl)
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

// Registers `lurek.devtools.*`.
//
// @param lua &Lua
// @param lurek &LuaTable
// @param _state Rc<RefCell<SharedState>>

// ---------------------------------------------------------------------------
// LuaFileWatcher â€” standalone per-path file-change watcher userdata
// ---------------------------------------------------------------------------

/// Lua-side handle for a per-path file watcher.
///
/// Created by `lurek.devtools.newFileWatcher(path)`. Call `:check()` once per
/// frame from within `lurek.process` to poll for changes.
struct LuaFileWatcher {
    /// Domain watcher watching a single path.
    watcher: FileWatcher,
    /// Watched path (informational).
    path: String,
    /// Optional Lua callback fired when the path changes.
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LuaUserData for LuaFileWatcher {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- onChanged --
        /// Registers a callback invoked (with no arguments) when the watched path changes.
        /// @param fn function
        /// @return nil
        methods.add_method_mut("onChanged", |lua, this, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            if let Some(old) = this.callback.borrow_mut().replace(key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // -- check --
        /// Polls the watcher. If the file has changed since the last call, fires the
        /// `onChanged` callback (if set) and returns `true`.
        /// @return boolean
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
        /// Returns the watched path string.
        /// @return string
        methods.add_method("getPath", |_, this, ()| Ok(this.path.clone()));

        // -- cancel --
        /// Removes the stored `onChanged` callback and stops future notifications.
        /// @return nil
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.watcher.clear();
            if let Some(key) = this.callback.borrow_mut().take() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}

/// Registers the `lurek.devtools` Lua API table into the engine namespace.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let dt = lua.create_table()?;
    let shared = Rc::new(RefCell::new(DevtoolsShared::new()));

    // â”€â”€ Logger â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Logs a message at the given level.
    /// @param level string
    /// @param message string
    let s = shared.clone();
    /// @return nil
    dt.set(
        "log",
        lua.create_function(move |_, (level, message): (String, String)| {
            s.borrow_mut().logger.push(&level, &message, "?", 0, None);
            Ok(())
        })?,
    )?;

    /// Logs a message at TRACE level.
    /// @param message string
    /// @return nil
    let s = shared.clone();
    dt.set("trace", lua.create_function(move |_, message: String| {
        s.borrow_mut().logger.push("trace", &message, "?", 0, None); Ok(()) })?)?;

    /// Logs a message at DEBUG level.
    /// @param message string
    /// @return nil
    let s = shared.clone();
    dt.set("debug", lua.create_function(move |_, message: String| {
        s.borrow_mut().logger.push("debug", &message, "?", 0, None); Ok(()) })?)?;

    /// Logs a message at INFO level.
    /// @param message string
    /// @return nil
    let s = shared.clone();
    dt.set("info", lua.create_function(move |_, message: String| {
        s.borrow_mut().logger.push("info", &message, "?", 0, None); Ok(()) })?)?;

    /// Logs a message at WARN level.
    /// @param message string
    /// @return nil
    let s = shared.clone();
    dt.set("warn", lua.create_function(move |_, message: String| {
        s.borrow_mut().logger.push("warn", &message, "?", 0, None); Ok(()) })?)?;

    /// Logs a message at ERROR level.
    /// @param message string
    /// @return nil
    let s = shared.clone();
    dt.set("error", lua.create_function(move |_, message: String| {
        s.borrow_mut().logger.push("error", &message, "?", 0, None); Ok(()) })?)?;

    /// Logs a message at FATAL level.
    /// @param message string
    /// @return nil
    let s = shared.clone();
    dt.set("fatal", lua.create_function(move |_, message: String| {
        s.borrow_mut().logger.push("fatal", &message, "?", 0, None); Ok(()) })?)?;

    /// Sets the minimum log level.
    /// @param level string
    let s = shared.clone();
    /// @return nil
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

    /// Returns the current minimum log level.
    let s = shared.clone();
    /// @return string
    dt.set(
        "getLogLevel",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.min_level.as_str().to_string()))?,
    )?;

    /// Enables or disables console log output.
    /// @param enabled boolean
    let s = shared.clone();
    /// @return nil
    dt.set(
        "setLogConsole",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().logger.console_enabled = enabled;
            Ok(())
        })?,
    )?;

    /// Returns whether console log output is enabled.
    let s = shared.clone();
    /// @return boolean
    dt.set(
        "getLogConsole",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.console_enabled))?,
    )?;

    /// Sets the log file path (empty string disables file output).
    /// @param path string
    let s = shared.clone();
    /// @return nil
    dt.set(
        "setLogFile",
        lua.create_function(move |_, path: String| {
            s.borrow_mut().logger.log_file = path;
            Ok(())
        })?,
    )?;

    /// Returns the current log file path.
    let s = shared.clone();
    /// @return string
    dt.set(
        "getLogFile",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.log_file.clone()))?,
    )?;

    /// Returns recent log entries as an array of tables.
    /// @param count integer?
    let s = shared.clone();
    /// @return table
    dt.set(
        "getLogHistory",
        lua.create_function(move |lua, count: Option<usize>| {
            let st = s.borrow();
            let entries = st.logger.tail(count);
            let tbl = lua.create_table()?;
            for (i, entry) in entries.iter().enumerate() {
                let e = lua.create_table()?;
                e.set("level", entry.level.clone())?;
                e.set("timestamp", entry.timestamp)?;
                e.set("message", entry.message.clone())?;
                e.set("source", entry.source.clone())?;
                e.set("line", entry.line)?;
                if let Some(ref cat) = entry.category {
                    e.set("category", cat.clone())?;
                }
                tbl.set(i + 1, e)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Discards all accumulated log entries from the in-memory devtools log buffer.
    let s = shared.clone();
    /// @return nil
    dt.set(
        "clearLog",
        lua.create_function(move |_, ()| {
            s.borrow_mut().logger.clear();
            Ok(())
        })?,
    )?;

    // â”€â”€ Profiler â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Enables or disables the profiler.
    /// @param enabled boolean
    let s = shared.clone();
    /// @return nil
    dt.set(
        "setProfilingEnabled",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().profiler.enabled = enabled;
            Ok(())
        })?,
    )?;

    /// Returns whether the profiler is enabled.
    let s = shared.clone();
    /// @return boolean
    dt.set(
        "isProfilingEnabled",
        lua.create_function(move |_, ()| Ok(s.borrow().profiler.enabled))?,
    )?;

    /// Opens a named profiling zone on the stack.
    /// @param name string
    let s = shared.clone();
    /// @return nil
    dt.set(
        "profilePush",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().profiler.push(&name);
            Ok(())
        })?,
    )?;

    /// Closes the most recent profiling zone.
    let s = shared.clone();
    /// @param  : string?
    /// @return nil
    dt.set(
        "profilePop",
        lua.create_function(move |_, _: Option<String>| {
            s.borrow_mut().profiler.pop();
            Ok(())
        })?,
    )?;

    /// Seals the current frame of profiling data.
    let s = shared.clone();
    /// @return nil
    dt.set(
        "profileFrame",
        lua.create_function(move |_, ()| {
            s.borrow_mut().profiler.end_frame();
            Ok(())
        })?,
    )?;

    /// Returns the number of retained profile frames.
    let s = shared.clone();
    /// @return integer
    dt.set(
        "getProfileFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().profiler.frames.len()))?,
    )?;

    /// Returns zone data table for a specific frame (0 or nil = most recent).
    /// @param frame integer?
    let s = shared.clone();
    /// @return table
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

    /// Clears all profiling data and resets the zone stack.
    let s = shared.clone();
    /// @return nil
    dt.set(
        "resetProfile",
        lua.create_function(move |_, ()| {
            s.borrow_mut().profiler.reset();
            Ok(())
        })?,
    )?;

    // â”€â”€ Frame Statistics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Records a frame-time sample (call each frame with delta time in seconds).
    /// @param dt number
    let s = shared.clone();
    /// @return nil
    dt.set(
        "recordFrameTime",
        lua.create_function(move |_, dt_val: f64| {
            s.borrow_mut().frame_stats.record(dt_val);
            Ok(())
        })?,
    )?;

    /// Returns a table of computed frame statistics.
    let s = shared.clone();
    /// @return table
    dt.set(
        "getFrameStats",
        lua.create_function(move |lua, ()| {
            let snap = s.borrow().frame_stats.snapshot();
            let tbl = lua.create_table()?;
            tbl.set("fps", snap.fps)?;
            tbl.set("dt", snap.dt)?;
            tbl.set("avg", snap.avg)?;
            tbl.set("min", snap.min)?;
            tbl.set("max", snap.max)?;
            tbl.set("p50", snap.p50)?;
            tbl.set("p95", snap.p95)?;
            tbl.set("p99", snap.p99)?;
            tbl.set("samples", snap.samples)?;
            Ok(tbl)
        })?,
    )?;

    /// Returns the raw frame-time sample array.
    let s = shared.clone();
    /// @return table
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

    /// Sets the frame-history buffer capacity (clamped 10-10000).
    /// @param size integer
    let s = shared.clone();
    /// @return nil
    dt.set(
        "setFrameHistorySize",
        lua.create_function(move |_, size: usize| {
            s.borrow_mut().frame_stats.set_capacity(size);
            Ok(())
        })?,
    )?;

    /// Returns the current frame-history buffer capacity.
    let s = shared.clone();
    /// @return integer
    dt.set(
        "getFrameHistorySize",
        lua.create_function(move |_, ()| Ok(s.borrow().frame_stats.capacity))?,
    )?;

    // â”€â”€ File Watcher â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Adds a file path to the watch list. Returns false if already watched.
    /// @param path string
    let s = shared.clone();
    /// @return boolean
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

    /// Removes a file path from the watch list.
    /// @param path string
    let s = shared.clone();
    /// @return boolean
    dt.set(
        "unwatch",
        lua.create_function(move |_, path: String| Ok(s.borrow_mut().watcher.unwatch(&path)))?,
    )?;

    /// Returns an array of all watched paths.
    let s = shared.clone();
    /// @return table
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

    /// Polls all watched paths and returns paths whose mtime changed.
    let s = shared.clone();
    /// @return table
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

    /// Clears all watched paths.
    let s = shared.clone();
    /// @return nil
    dt.set(
        "clearWatches",
        lua.create_function(move |_, ()| {
            s.borrow_mut().watcher.clear();
            Ok(())
        })?,
    )?;

    /// Returns the file watch poll interval in seconds.
    let s = shared.clone();
    /// @return number
    dt.set(
        "getWatchInterval",
        lua.create_function(move |_, ()| Ok(s.borrow().watch_interval))?,
    )?;

    /// Sets the file watch poll interval in seconds.
    /// @param interval number
    let s = shared.clone();
    /// @return nil
    dt.set(
        "setWatchInterval",
        lua.create_function(move |_, interval: f32| {
            s.borrow_mut().watch_interval = interval.max(0.01);
            Ok(())
        })?,
    )?;

    // â”€â”€ Lua Debug Bridge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Returns the Lua call stack as a table of frames.
    /// @param max_depth integer?
    /// @return table
    dt.set(
        "getCallStack",
        lua.create_function(|lua, max_depth: Option<usize>| {
            let max = max_depth.unwrap_or(20).min(100);
            // LUA-EVAL-JUSTIFIED: lua.load() is required because `debug.getinfo` is a Lua C
            // function operating in the Lua VM's debug state; mlua exposes no Rust
            // equivalent for inspecting Lua call-stack frames at runtime.
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
            // LUA-EVAL-JUSTIFIED: calls lua.load() above â€” debug.getinfo requires the Lua VM's debug state.
            let frames: LuaTable = lua.load(code).call(max)?;
            Ok(frames)
        })?,
    )?;

    /// Evaluates a Lua string and returns (success, results...).
    /// @param code string
    /// @return boolean
    dt.set(
        "eval",
        lua.create_function(
            // LUA-EVAL-JUSTIFIED: lua.load() here IS the feature â€” devtools.eval() evaluates
            // arbitrary Lua code supplied by the developer at runtime.
            |lua, code: String| match lua.load(&code).eval::<LuaMultiValue>() {
                Ok(vals) => {
                    let mut result = vec![LuaValue::Boolean(true)];
                    result.extend(vals.into_iter());
                    Ok(LuaMultiValue::from_vec(result))
                }
                Err(e) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Boolean(false),
                    LuaValue::String(lua.create_string(e.to_string().as_bytes())?),
                ])),
            },
        )?,
    )?;

    // â”€â”€ Console â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Opens the console window (updates the console flag; returns true).
    let s = shared.clone();
    /// @return boolean
    dt.set(
        "openConsole",
        lua.create_function(move |_, ()| {
            s.borrow_mut().console_open = true;
            Ok(true)
        })?,
    )?;

    /// Returns whether the console is considered open.
    let s = shared.clone();
    /// @return boolean
    dt.set(
        "isConsoleOpen",
        lua.create_function(move |_, ()| Ok(s.borrow().console_open))?,
    )?;

    // â”€â”€ Live Watch / Snapshot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Registers a named live watch. The getter function is called on demand to sample a value.
    /// Returns an integer id that can be passed to removeWatch.
    /// @param name string
    /// @param getter function
    /// @param category string?
    let s = shared.clone();
    /// @return integer
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

    /// Removes a watch by the id returned from exposeWatch. Returns true if removed.
    /// @param id integer
    let s = shared.clone();
    /// @return boolean
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

    /// Calls all registered watch getters and returns a table of {name, category, value} records.
    let s = shared.clone();
    /// @return table
    dt.set(
        "getWatches",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, entry) in st.watches.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("name", entry.name.clone())?;
                row.set("category", entry.category.clone())?;
                let getter: LuaFunction = lua.registry_value(&entry.getter)?;
                match getter.call::<_, LuaValue>(()) {
                    Ok(v) => {
                        row.set("value", v)?;
                    }
                    Err(e) => {
                        row.set("value", format!("(error: {})", e))?;
                    }
                }
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Takes a structured snapshot of all watches + frame stats + last profile frame.
    /// Returns a single table suitable for logging or sending to the VS Code extension.
    let s = shared.clone();
    /// @return table
    dt.set(
        "snapshot",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let snap = lua.create_table()?;

            // Frame stats.
            let fs = st.frame_stats.snapshot();
            let fst = lua.create_table()?;
            fst.set("fps", fs.fps)?;
            fst.set("dt", fs.dt)?;
            fst.set("avg", fs.avg)?;
            fst.set("p95", fs.p95)?;
            fst.set("p99", fs.p99)?;
            snap.set("frameStats", fst)?;

            // Watches.
            let watches_tbl = lua.create_table()?;
            for (i, entry) in st.watches.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("name", entry.name.clone())?;
                row.set("category", entry.category.clone())?;
                let getter: LuaFunction = lua.registry_value(&entry.getter)?;
                match getter.call::<_, LuaValue>(()) {
                    Ok(v) => {
                        row.set("value", v)?;
                    }
                    Err(e) => {
                        row.set("value", format!("(error: {})", e))?;
                    }
                }
                watches_tbl.set(i + 1, row)?;
            }
            snap.set("watches", watches_tbl)?;

            // Last profiler frame summary.
            let profile_tbl = lua.create_table()?;
            if let Some(zones) = st.profiler.get_frame(0) {
                for (i, zone) in zones.iter().enumerate() {
                    profile_tbl.set(i + 1, zone_to_table(lua, zone)?)?;
                }
            }
            snap.set("profile", profile_tbl)?;

            // Recent log tail (last 10 entries).
            let log_tbl = lua.create_table()?;
            for (i, entry) in st.logger.tail(Some(10)).iter().enumerate() {
                let et = lua.create_table()?;
                et.set("level", entry.level.clone())?;
                et.set("message", entry.message.clone())?;
                et.set("source", entry.source.clone())?;
                log_tbl.set(i + 1, et)?;
            }
            snap.set("log", log_tbl)?;

            snap.set("watchCount", st.watches.len())?;
            Ok(snap)
        })?,
    )?;

    // -- profilerReport --
    /// Returns a flat summary table of all recorded profiler zones across all stored
    /// frames. Each entry is `{name, calls, total_ms, avg_ms, min_ms, max_ms, self_ms}`.
    /// Useful for CSV export or performance dashboards.
    /// @return table
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
                row.set("name", name.clone())?;
                row.set("calls", *calls)?;
                row.set("total_ms", *total)?;
                row.set(
                    "avg_ms",
                    if *calls > 0 {
                        total / (*calls as f64)
                    } else {
                        0.0
                    },
                )?;
                row.set("min_ms", if *min == f64::MAX { 0.0 } else { *min })?;
                row.set("max_ms", *max)?;
                row.set("self_ms", *self_ms)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        })?,
    )?;

    // -- newFileWatcher --
    /// Creates a standalone per-path file watcher. Call `:check()` once per frame
    /// to poll for changes.
    ///
    /// Methods on the returned userdata:
    /// - `onChanged(fn)` â€” register a no-arg callback fired when the file changes
    /// - `check()` â†’ boolean â€” polls and fires callback if changed; returns `true` if changed
    /// - `cancel()` â€” removes the stored callback
    /// @param path string   file or directory path to watch
    /// @return FileWatcher
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
    /// Creates an interactive Lua REPL console with a bounded history buffer.
    ///
    /// The returned object evaluates Lua snippets against the live Lua VM and
    /// keeps a scrollable input history.  Useful for in-game debug consoles.
    ///
    /// Methods on the returned userdata:
    /// - `eval(code)` â†’ string  â€” runs `code`, returns result or error text
    /// - `history()` â†’ table    â€” ordered array of past inputs (oldest first)
    /// - `clear()` â€” wipes the history buffer
    /// - `len()` â†’ integer      â€” number of history entries
    ///
    /// # Usage
    /// ```lua
    /// local repl = lurek.devtools.newRepl(100)
    /// local result = repl:eval("1 + 1")
    /// ```
    /// @param max_history integer?
    /// @return ReplConsole
    dt.set(
        "newRepl",
        lua.create_function(|lua, max_history: Option<usize>| {
            lua.create_userdata(LuaReplConsole {
                inner: ReplConsole::new(max_history.unwrap_or(200)),
            })
        })?,
    )?;

    // -- devtools namespace --
    lurek.set("devtools", dt)?;
    Ok(())
}

// -------------------------------------------------------------------------------
// LuaReplConsole UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`ReplConsole`] interactive evaluator.
pub struct LuaReplConsole {
    inner: ReplConsole,
}

impl LuaUserData for LuaReplConsole {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- eval --
        /// Evaluates a Lua snippet and records the input in history.
        ///
        /// Single-expression inputs (e.g. `"1 + 2"`) return the result as a string.
        /// Statement blocks (e.g. `"x = 10"`) return `"(ok)"` on success.
        /// Any Lua error is caught and returned as an error string.
        ///
        /// @param code string
        /// @return string
        methods.add_method_mut("eval", |lua, this, code: String| {
            Ok(this.inner.eval(&code, lua))
        });

        // -- history --
        /// Returns an ordered array of past inputs (oldest first).
        /// @return table
        methods.add_method("history", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, entry) in this.inner.history().iter().enumerate() {
                t.set(i + 1, entry.clone())?;
            }
            Ok(t)
        });

        // -- clear --
        /// Clears the REPL history buffer.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- len --
        /// Returns the number of history entries.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
    }
}
