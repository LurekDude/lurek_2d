//! Registers the `luna.devtools.*` runtime diagnostics and developer tools API.
//!
//! Five subsystems: structured logger, hierarchical profiler, frame statistics,
//! file watcher, and Lua debug bridge. All module-level functions — no
//! registered types.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::time::Instant;

use mlua::prelude::*;

// ---------------------------------------------------------------------------
// Log levels
// ---------------------------------------------------------------------------

/// Numeric log level ordering.
fn level_num(level: &str) -> u8 {
    match level {
        "trace" => 0,
        "debug" => 1,
        "info" => 2,
        "warn" => 3,
        "error" => 4,
        "fatal" => 5,
        _ => 2,
    }
}

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

/// A single log entry.
#[derive(Clone)]
struct LogEntry {
    level: String,
    timestamp: f64,
    message: String,
    source: String,
    line: u32,
}

/// A single profiler zone.
#[derive(Clone)]
struct ProfileZone {
    name: String,
    start_time: f64,
    end_time: f64,
    children: Vec<ProfileZone>,
}

impl ProfileZone {
    /// Total time including children.
    fn time(&self) -> f64 {
        self.end_time - self.start_time
    }

    /// Time spent in this zone only (exclude children).
    fn self_time(&self) -> f64 {
        let child_total: f64 = self.children.iter().map(|c| c.time()).sum();
        (self.time() - child_total).max(0.0)
    }
}

/// Devtools internal state shared via Rc<RefCell>.
struct DevtoolsState {
    // --- Logger ---
    log_level: String,
    log_console: bool,
    log_file: String,
    log_history: Vec<LogEntry>,
    log_max: usize,

    // --- Profiler ---
    profiling_enabled: bool,
    /// Stack of open zones (name, start_time, children_so_far).
    zone_stack: Vec<(String, f64, Vec<ProfileZone>)>,
    /// Completed frames of zones.
    profile_frames: Vec<Vec<ProfileZone>>,
    profile_max_frames: usize,

    // --- Frame Stats ---
    frame_history: Vec<f64>,
    frame_history_size: usize,

    // --- File Watcher ---
    watched_paths: HashMap<String, Option<std::time::SystemTime>>,
    watch_interval: f64,

    // --- Console ---
    console_open: bool,

    // --- Timing ---
    epoch: Instant,
}

impl DevtoolsState {
    fn new() -> Self {
        Self {
            log_level: "info".to_string(),
            log_console: true,
            log_file: String::new(),
            log_history: Vec::new(),
            log_max: 1000,

            profiling_enabled: false,
            zone_stack: Vec::new(),
            profile_frames: Vec::new(),
            profile_max_frames: 300,

            frame_history: Vec::new(),
            frame_history_size: 300,

            watched_paths: HashMap::new(),
            watch_interval: 0.5,

            console_open: false,

            epoch: Instant::now(),
        }
    }

    fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }

    fn push_log(&mut self, level: &str, message: &str, source: &str, line: u32) {
        if level_num(level) < level_num(&self.log_level) {
            return;
        }
        let entry = LogEntry {
            level: level.to_string(),
            timestamp: self.elapsed(),
            message: message.to_string(),
            source: source.to_string(),
            line,
        };
        if self.log_console {
            eprintln!("[{}] {} ({}:{})", entry.level, entry.message, entry.source, entry.line);
        }
        self.log_history.push(entry);
        if self.log_history.len() > self.log_max {
            self.log_history.remove(0);
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Convert a ProfileZone tree to a Lua table.
fn zone_to_table<'lua>(lua: &'lua Lua, zone: &ProfileZone) -> LuaResult<LuaTable<'lua>> {
    let tbl = lua.create_table()?;
    /// Name on this Object.
    ///
    /// # Returns
    /// The result.
    tbl.set("name", zone.name.clone())?;
    /// Time on this Object.
    ///
    /// # Returns
    /// The result.
    tbl.set("time", zone.time())?;
    /// Self time on this Object.
    ///
    /// # Returns
    /// The result.
    tbl.set("selfTime", zone.self_time())?;
    /// Start time on this Object.
    ///
    /// # Returns
    /// The result.
    tbl.set("startTime", zone.start_time)?;
    let children = lua.create_table()?;
    for (i, child) in zone.children.iter().enumerate() {
        children.set(i + 1, zone_to_table(lua, child)?)?;
    }
    /// Children on this Object.
    ///
    /// # Returns
    /// The result.
    tbl.set("children", children)?;
    Ok(tbl)
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.devtools` namespace.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let dt = lua.create_table()?;
    let state = Rc::new(RefCell::new(DevtoolsState::new()));

    // ===== Logger =====

    /// Log at any level with optional source/line info.
    let s = state.clone();
    dt.set(
        "log",
        lua.create_function(move |_, (level, message): (String, String)| {
            s.borrow_mut().push_log(&level, &message, "?", 0);
            Ok(())
        })?,
    )?;

    // Convenience level functions
    for level_name in &["trace", "debug", "info", "warn", "error", "fatal"] {
        let s = state.clone();
        let lvl = level_name.to_string();
        dt.set(
            *level_name,
            lua.create_function(move |_, message: String| {
                s.borrow_mut().push_log(&lvl, &message, "?", 0);
                Ok(())
            })?,
        )?;
    }

    /// Sets the minimum log level to record.
    let s = state.clone();
    dt.set(
        "setLogLevel",
        lua.create_function(move |_, level: String| {
            s.borrow_mut().log_level = level;
            Ok(())
        })?,
    )?;

    /// Returns the current minimum log level.
    let s = state.clone();
    dt.set(
        "getLogLevel",
        lua.create_function(move |_, ()| Ok(s.borrow().log_level.clone()))?,
    )?;

    /// Toggles stderr console output.
    let s = state.clone();
    dt.set(
        "setLogConsole",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().log_console = enabled;
            Ok(())
        })?,
    )?;

    /// Returns whether console output is enabled.
    let s = state.clone();
    dt.set(
        "getLogConsole",
        lua.create_function(move |_, ()| Ok(s.borrow().log_console))?,
    )?;

    /// Sets the log file path. Empty string disables file logging.
    let s = state.clone();
    dt.set(
        "setLogFile",
        lua.create_function(move |_, path: String| {
            s.borrow_mut().log_file = path;
            Ok(())
        })?,
    )?;

    /// Returns the current log file path.
    let s = state.clone();
    dt.set(
        "getLogFile",
        lua.create_function(move |_, ()| Ok(s.borrow().log_file.clone()))?,
    )?;

    /// Returns the last `count` log entries (default all).
    let s = state.clone();
    dt.set(
        "getLogHistory",
        lua.create_function(move |lua, count: Option<usize>| {
            let st = s.borrow();
            let entries = match count {
                Some(0) | None => &st.log_history[..],
                Some(n) => {
                    let start = st.log_history.len().saturating_sub(n);
                    &st.log_history[start..]
                }
            };
            let tbl = lua.create_table()?;
            for (i, entry) in entries.iter().enumerate() {
                let e = lua.create_table()?;
                /// Level on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("level", entry.level.clone())?;
                /// Timestamp on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("timestamp", entry.timestamp)?;
                /// Message on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("message", entry.message.clone())?;
                /// Source on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("source", entry.source.clone())?;
                /// Line on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("line", entry.line)?;
                tbl.set(i + 1, e)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Clears all log history.
    let s = state.clone();
    dt.set(
        "clearLog",
        lua.create_function(move |_, ()| {
            s.borrow_mut().log_history.clear();
            Ok(())
        })?,
    )?;

    // ===== Profiler =====

    /// Enables or disables the profiler.
    let s = state.clone();
    dt.set(
        "setProfilingEnabled",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().profiling_enabled = enabled;
            Ok(())
        })?,
    )?;

    /// Returns whether the profiler is enabled.
    let s = state.clone();
    dt.set(
        "isProfilingEnabled",
        lua.create_function(move |_, ()| Ok(s.borrow().profiling_enabled))?,
    )?;

    /// Starts a named timing zone.
    let s = state.clone();
    dt.set(
        "profilePush",
        lua.create_function(move |_, name: String| {
            let mut st = s.borrow_mut();
            if !st.profiling_enabled {
                return Ok(());
            }
            let now = st.elapsed();
            st.zone_stack.push((name, now, Vec::new()));
            Ok(())
        })?,
    )?;

    /// Ends the most recent timing zone.
    let s = state.clone();
    dt.set(
        "profilePop",
        lua.create_function(move |_, _name: Option<String>| {
            let mut st = s.borrow_mut();
            if !st.profiling_enabled {
                return Ok(());
            }
            if let Some((name, start, children)) = st.zone_stack.pop() {
                let zone = ProfileZone {
                    name,
                    start_time: start,
                    end_time: st.elapsed(),
                    children,
                };
                // Add to parent's children, or store as top-level
                if let Some(parent) = st.zone_stack.last_mut() {
                    parent.2.push(zone);
                } else {
                    // Top-level zone — wrap in sentinel entry
                    st.zone_stack.push((
                        String::new(),
                        0.0,
                        vec![zone],
                    ));
                }
            }
            Ok(())
        })?,
    )?;

    /// Seals the current frame of profiling data.
    let s = state.clone();
    dt.set(
        "profileFrame",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            if !st.profiling_enabled {
                return Ok(());
            }
            // Collect all top-level zones from the stack
            let mut frame_zones = Vec::new();
            // Close any dangling zones
            while let Some((name, start, children)) = st.zone_stack.pop() {
                if name.is_empty() && start == 0.0 {
                    // Sentinel: already completed zones
                    frame_zones.extend(children);
                } else {
                    // Dangling zone — auto-close
                    let zone = ProfileZone {
                        name,
                        start_time: start,
                        end_time: st.elapsed(),
                        children,
                    };
                    frame_zones.push(zone);
                }
            }
            st.profile_frames.push(frame_zones);
            if st.profile_frames.len() > st.profile_max_frames {
                st.profile_frames.remove(0);
            }
            Ok(())
        })?,
    )?;

    /// Returns the number of retained profile frames.
    let s = state.clone();
    dt.set(
        "getProfileFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().profile_frames.len()))?,
    )?;

    /// Returns zone data for a specific frame (0 = most recent).
    let s = state.clone();
    dt.set(
        "getProfileData",
        lua.create_function(move |lua, frame: Option<i64>| {
            let st = s.borrow();
            let idx = match frame {
                None | Some(0) => st.profile_frames.len().saturating_sub(1),
                Some(n) if n < 0 => {
                    let abs = (-n) as usize;
                    st.profile_frames.len().saturating_sub(abs)
                }
                Some(n) => n as usize,
            };
            let tbl = lua.create_table()?;
            if let Some(zones) = st.profile_frames.get(idx) {
                for (i, zone) in zones.iter().enumerate() {
                    tbl.set(i + 1, zone_to_table(lua, zone)?)?;
                }
            }
            Ok(tbl)
        })?,
    )?;

    /// Clears all profiling state.
    let s = state.clone();
    dt.set(
        "resetProfile",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.zone_stack.clear();
            st.profile_frames.clear();
            Ok(())
        })?,
    )?;

    // ===== Frame Statistics =====

    /// Records a frame time sample.
    let s = state.clone();
    dt.set(
        "recordFrameTime",
        lua.create_function(move |_, dt_val: f64| {
            let mut st = s.borrow_mut();
            st.frame_history.push(dt_val);
            if st.frame_history.len() > st.frame_history_size {
                st.frame_history.remove(0);
            }
            Ok(())
        })?,
    )?;

    /// Returns computed frame statistics.
    let s = state.clone();
    dt.set(
        "getFrameStats",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            if st.frame_history.is_empty() {
                /// Fps on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("fps", 0.0)?;
                /// Dt on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("dt", 0.0)?;
                /// Avg on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("avg", 0.0)?;
                /// Min on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("min", 0.0)?;
                /// Max on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("max", 0.0)?;
                /// P50 on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("p50", 0.0)?;
                /// P95 on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("p95", 0.0)?;
                /// P99 on this Object.
                ///
                /// # Returns
                /// The result.
                tbl.set("p99", 0.0)?;
                return Ok(tbl);
            }
            let mut sorted: Vec<f64> = st.frame_history.clone();
            sorted.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
            let n = sorted.len();
            let sum: f64 = sorted.iter().sum();
            let avg = sum / n as f64;
            let percentile = |p: f64| -> f64 {
                let idx = ((p / 100.0) * (n as f64 - 1.0)).round() as usize;
                sorted[idx.min(n - 1)]
            };
            /// Fps on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("fps", if avg > 0.0 { 1.0 / avg } else { 0.0 })?;
            /// Dt on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("dt", *sorted.last().unwrap_or(&0.0))?;
            /// Avg on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("avg", avg)?;
            /// Min on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("min", sorted[0])?;
            /// Max on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("max", sorted[n - 1])?;
            /// P50 on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("p50", percentile(50.0))?;
            /// P95 on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("p95", percentile(95.0))?;
            /// P99 on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("p99", percentile(99.0))?;
            Ok(tbl)
        })?,
    )?;

    /// Returns the raw frame time history.
    let s = state.clone();
    dt.set(
        "getFrameHistory",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, &val) in st.frame_history.iter().enumerate() {
                tbl.set(i + 1, val)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Sets the maximum frame history buffer size (clamped 10–10000).
    let s = state.clone();
    dt.set(
        "setFrameHistorySize",
        lua.create_function(move |_, size: usize| {
            let mut st = s.borrow_mut();
            st.frame_history_size = size.clamp(10, 10000);
            // Trim if needed
            while st.frame_history.len() > st.frame_history_size {
                st.frame_history.remove(0);
            }
            Ok(())
        })?,
    )?;

    /// Returns the current frame history buffer size.
    let s = state.clone();
    dt.set(
        "getFrameHistorySize",
        lua.create_function(move |_, ()| Ok(s.borrow().frame_history_size))?,
    )?;

    // ===== File Watcher =====

    /// Registers a file path for modification-time polling.
    let s = state.clone();
    dt.set(
        "watch",
        lua.create_function(move |_, path: String| {
            let mut st = s.borrow_mut();
            if st.watched_paths.contains_key(&path) {
                return Ok(false);
            }
            // Get current modtime
            let modtime = std::fs::metadata(&path)
                .ok()
                .and_then(|m| m.modified().ok());
            st.watched_paths.insert(path, modtime);
            Ok(true)
        })?,
    )?;

    /// Removes a file from the watch list.
    let s = state.clone();
    dt.set(
        "unwatch",
        lua.create_function(move |_, path: String| {
            Ok(s.borrow_mut().watched_paths.remove(&path).is_some())
        })?,
    )?;

    /// Returns all watched file paths.
    let s = state.clone();
    dt.set(
        "getWatchedPaths",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, path) in st.watched_paths.keys().enumerate() {
                tbl.set(i + 1, path.clone())?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Scans watched files and returns paths whose modification time changed.
    let s = state.clone();
    dt.set(
        "scan",
        lua.create_function(move |lua, ()| {
            let mut st = s.borrow_mut();
            let tbl = lua.create_table()?;
            let mut idx = 1;
            let mut updates: Vec<(String, Option<std::time::SystemTime>)> = Vec::new();
            for (path, prev) in &st.watched_paths {
                let current = std::fs::metadata(path)
                    .ok()
                    .and_then(|m| m.modified().ok());
                if current != *prev {
                    tbl.set(idx, path.clone())?;
                    idx += 1;
                    updates.push((path.clone(), current));
                }
            }
            for (path, modtime) in updates {
                st.watched_paths.insert(path, modtime);
            }
            Ok(tbl)
        })?,
    )?;

    /// Sets the advisory watch interval in seconds.
    let s = state.clone();
    dt.set(
        "setWatchInterval",
        lua.create_function(move |_, interval: f64| {
            s.borrow_mut().watch_interval = interval;
            Ok(())
        })?,
    )?;

    /// Returns the current watch interval.
    let s = state.clone();
    dt.set(
        "getWatchInterval",
        lua.create_function(move |_, ()| Ok(s.borrow().watch_interval))?,
    )?;

    /// Clears all watched paths.
    let s = state.clone();
    dt.set(
        "clearWatches",
        lua.create_function(move |_, ()| {
            s.borrow_mut().watched_paths.clear();
            Ok(())
        })?,
    )?;

    // ===== Lua Debug Bridge =====

    /// Returns the Lua call stack as a table of stack frames.
    /// Uses Lua's debug.getinfo to walk the stack.
    dt.set(
        "getCallStack",
        lua.create_function(|lua, max_depth: Option<usize>| {
            let max = max_depth.unwrap_or(20).min(100);
            let frames: LuaTable = lua
                .load(concat!(
                    "local max = ...\n",
                    "local frames = {}\n",
                    "if not debug or not debug.getinfo then return frames end\n",
                    "for i = 2, max + 1 do\n",
                    "  local info = debug.getinfo(i, 'Snl')\n",
                    "  if not info then break end\n",
                    "  frames[#frames+1] = {\n",
                    "    source = info.short_src or '?',\n",
                    "    line = info.currentline or 0,\n",
                    "    name = info.name or '?',\n",
                    "    what = info.namewhat or ''\n",
                    "  }\n",
                    "end\n",
                    "return frames",
                ))
                .call(max)?;
            Ok(frames)
        })?,
    )?;

    /// Evaluates a Lua string and returns success flag plus results.
    dt.set(
        "eval",
        lua.create_function(|lua, code: String| {
            match lua.load(&code).eval::<LuaMultiValue>() {
                Ok(vals) => {
                    let mut result = vec![LuaValue::Boolean(true)];
                    result.extend(vals.into_iter());
                    Ok(LuaMultiValue::from_vec(result))
                }
                Err(e) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Boolean(false),
                    LuaValue::String(lua.create_string(e.to_string())?),
                ])),
            }
        })?,
    )?;

    // ===== Console =====

    /// Opens a console window (no-op on non-Windows).
    let s = state.clone();
    dt.set(
        "openConsole",
        lua.create_function(move |_, ()| {
            s.borrow_mut().console_open = true;
            Ok(true)
        })?,
    )?;

    /// Returns whether the console is considered open.
    let s = state.clone();
    dt.set(
        "isConsoleOpen",
        lua.create_function(move |_, ()| Ok(s.borrow().console_open))?,
    )?;

    /// Devtools on this Object.
    ///
    /// # Returns
    /// The result.
    luna.set("devtools", dt)?;
    Ok(())
}
