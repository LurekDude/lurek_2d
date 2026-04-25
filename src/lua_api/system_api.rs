//! `lurek.platform` â€” Platform queries: OS name, CPU count, memory size, power state,
//! preferred locales, clipboard access, and safe URL opening.
//!
//! Registered as `lurek.platform.*` in the Lua VM. Domain logic is minimal â€”
//! most functions delegate directly to `std` or `sysinfo`.
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::SharedState;
use crate::log_msg;
use crate::runtime::log_messages::{
    self, LA03_OPEN_URL_REJECTED, LA04_CLIPBOARD_WRITE_FAIL, LA05_CLIPBOARD_UNAVAIL,
    LA06_CLIPBOARD_READ_FAIL,
};
use crate::runtime::messages;

/// Returns the number of logical processors available.
///
/// @return usize
pub fn get_processor_count() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1)
}

/// Returns total system RAM in MiB using the `sysinfo` crate.
///
/// u64
pub fn get_memory_size() -> u64 {
    use sysinfo::System;
    let sys = System::new_with_specifics(
        sysinfo::RefreshKind::new().with_memory(sysinfo::MemoryRefreshKind::everything()),
    );
    sys.total_memory() / (1024 * 1024)
}

/// Opens a URL in the default browser/application.
///
/// Only `http://`, `https://`, and `mailto:` schemes are allowed.
/// Returns `true` if the command was spawned, `false` if the scheme was
/// rejected or the spawn failed.
///
/// @param url &str
/// @return bool
pub fn open_url(url: &str) -> bool {
    let url_lower = url.to_lowercase();
    if !url_lower.starts_with("http://")
        && !url_lower.starts_with("https://")
        && !url_lower.starts_with("mailto:")
    {
        log_msg!(warn, LA03_OPEN_URL_REJECTED);
        return false;
    }

    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("cmd")
            .args(["/C", "start", "", url])
            .spawn()
            .is_ok()
    }
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open").arg(url).spawn().is_ok()
    }
    #[cfg(target_os = "linux")]
    {
        std::process::Command::new("xdg-open")
            .arg(url)
            .spawn()
            .is_ok()
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = url;
        false
    }
}

/// Returns the user's preferred locale strings.
///
/// @return Vec<String>
pub fn get_preferred_locales() -> Vec<String> {
    let locales: Vec<String> = sys_locale::get_locales().map(|l| l.to_string()).collect();
    if locales.is_empty() {
        if let Ok(lang) = std::env::var("LANG") {
            vec![lang.split('.').next().unwrap_or("en_US").to_string()]
        } else {
            vec!["en_US".to_string()]
        }
    } else {
        locales
    }
}

/// Power state of the host device.
///
/// Returned by [`get_power_info`] and exposed to Lua via `lurek.platform.getPowerInfo()`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PowerState {
    /// Cannot determine power state.
    Unknown,
    /// Running on battery.
    Battery,
    /// No battery (desktop plugged in).
    NoBattery,
    /// Battery is charging.
    Charging,
    /// Battery is fully charged.
    Charged,
}

impl PowerState {
    /// Returns the string representation used in Lua.
    ///
    /// One of `"unknown"`, `"battery"`, `"nobattery"`, `"charging"`, or `"charged"`.
    pub fn as_str(&self) -> &'static str {
        match self {
            PowerState::Unknown => "unknown",
            PowerState::Battery => "battery",
            PowerState::NoBattery => "nobattery",
            PowerState::Charging => "charging",
            PowerState::Charged => "charged",
        }
    }
}

/// Returns power/battery information as `(state, percent, seconds)`.
///
/// On desktop platforms this always returns `(Unknown, None, None)`.
///
/// @return (PowerState, Option<u32>, Option<u32>)
pub fn get_power_info() -> (PowerState, Option<u32>, Option<u32>) {
    (PowerState::Unknown, None, None)
}

/// Registers `lurek.platform.*` platform query functions into the Lua VM.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param state Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let system = lua.create_table()?;

    // lurek.platform.getOS() -> string
    /// Returns the host operating system name ('Windows', 'Linux', 'macOS').
    /// @return string
    system.set(
        "getOS",
        lua.create_function(|_, ()| {
            Ok(if cfg!(target_os = "windows") {
                "Windows"
            } else if cfg!(target_os = "linux") {
                "Linux"
            } else if cfg!(target_os = "macos") {
                "macOS"
            } else if cfg!(target_os = "android") {
                "Android"
            } else if cfg!(target_os = "ios") {
                "iOS"
            } else {
                "Unknown"
            })
        })?,
    )?;

    // lurek.platform.getVersion() -> string
    /// Returns the Lurek2D engine version string.
    /// @return string
    system.set(
        "getVersion",
        lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION").to_string()))?,
    )?;

    // lurek.platform.getProcessorCount() -> integer
    /// Returns the number of logical CPU cores available.
    /// @return integer
    system.set(
        "getProcessorCount",
        lua.create_function(|_, ()| Ok(get_processor_count()))?,
    )?;

    // lurek.platform.getMemorySize() -> integer (MiB)
    /// Returns the total amount of installed system RAM in megabytes.
    /// @return integer
    /// RAM size in megabytes as an integer.
    system.set(
        "getMemorySize",
        lua.create_function(|_, ()| Ok(get_memory_size()))?,
    )?;

    // lurek.platform.openURL(url) -> bool
    /// Opens a URL in the system's default browser.
    /// @param url string
    /// @return boolean
    system.set(
        "openURL",
        lua.create_function(|_, url: String| Ok(open_url(&url)))?,
    )?;

    // lurek.platform.getPreferredLocales() -> table of strings
    /// Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
    /// @return table
    /// Table of locale strings ordered from most to least preferred.
    system.set(
        "getPreferredLocales",
        lua.create_function(|_, ()| Ok(get_preferred_locales()))?,
    )?;

    // lurek.platform.getPowerInfo() -> state, percent_or_nil, seconds_or_nil
    /// Returns battery state, percentage charged, and estimated time remaining.
    /// @return table
    /// string, integer?, integer?
    /// Table with fields state ('battery','charging','charged','unknown'), percent, and seconds.
    system.set(
        "getPowerInfo",
        lua.create_function(|_, ()| {
            let (state, percent, seconds) = get_power_info();
            Ok((state.as_str().to_string(), percent, seconds))
        })?,
    )?;

    // lurek.platform.getInfo() -> table { engine, version, lua_version, renderer, os, processors, memory }
    /// Returns a table of system information including OS name, CPU model, and installed RAM.
    /// @return table
    /// Table with fields os, cpu, cores, and ram.
    system.set(
        "getInfo",
        lua.create_function(|lua, ()| {
            let info = lua.create_table()?;
            /// Engine.
            info.set("engine", "Lurek2D")?;
            /// Version.
            info.set("version", env!("CARGO_PKG_VERSION"))?;
            /// Lua_version.
            info.set("lua_version", "Lua 5.4")?;
            /// Renderer.
            info.set("renderer", "wgpu")?;
            /// Os.
            info.set(
                "os",
                if cfg!(target_os = "windows") {
                    "Windows"
                } else if cfg!(target_os = "linux") {
                    "Linux"
                } else if cfg!(target_os = "macos") {
                    "macOS"
                } else {
                    "Unknown"
                },
            )?;
            /// Processors.
            info.set("processors", get_processor_count())?;
            /// Memory.
            info.set("memory", get_memory_size())?;
            Ok(info)
        })?,
    )?;

    // lurek.platform.getMessage(id) -> string
    /// Resolves a stable runtime message ID such as 'L001' to its human-readable text.
    /// @param id string
    /// @return string
    system.set(
        "getMessage",
        lua.create_function(|_, id: String| Ok(messages::resolve_message(&id)))?,
    )?;

    // lurek.platform.hasMessage(id) -> boolean
    /// Returns true when the runtime message catalog contains the given stable message ID.
    /// @param id string
    /// @return boolean
    system.set(
        "hasMessage",
        lua.create_function(|_, id: String| Ok(messages::has_message(&id)))?,
    )?;

    // lurek.platform.getMessageCount() -> integer
    /// Returns the total number of message entries loaded into the runtime message catalog.
    /// @return integer
    system.set(
        "getMessageCount",
        lua.create_function(|_, ()| Ok(messages::message_count()))?,
    )?;

    // lurek.platform.setClipboardText(text) Ă”Ă‡Ă¶ writes text to the system clipboard.
    /// Replaces the system clipboard contents with the given string.
    /// @param text string
    system.set(
        "setClipboardText",
        lua.create_function(|_, text: String| {
            match arboard::Clipboard::new() {
                Ok(mut cb) => {
                    if let Err(e) = cb.set_text(text) {
                        log_msg!(warn, LA04_CLIPBOARD_WRITE_FAIL, "{}", e);
                    }
                }
                Err(e) => {
                    log_msg!(warn, LA05_CLIPBOARD_UNAVAIL, "setClipboardText: {}", e);
                }
            }
            Ok(())
        })?,
    )?;

    // lurek.platform.getClipboardText() -> string Ă”Ă‡Ă¶ reads text from the system clipboard.
    /// Returns the current contents of the system clipboard.
    /// @return string
    system.set(
        "getClipboardText",
        lua.create_function(|_, ()| match arboard::Clipboard::new() {
            Ok(mut cb) => match cb.get_text() {
                Ok(text) => Ok(text),
                Err(e) => {
                    log_msg!(warn, LA06_CLIPBOARD_READ_FAIL, "{}", e);
                    Ok(String::new())
                }
            },
            Err(e) => {
                log_msg!(warn, LA05_CLIPBOARD_UNAVAIL, "getClipboardText: {}", e);
                Ok(String::new())
            }
        })?,
    )?;

    // Clone for getLastError below (before state is consumed by getDebugOverlay)
    let state_for_error = state.clone();

    // lurek.platform.setDebugOverlay(enabled)
    /// Shows or hides the FPS/draw-call debug overlay.
    let s = state.clone();
    /// @param enabled boolean
    system.set(
        "setDebugOverlay",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().debug_overlay_enabled = enabled;
            Ok(())
        })?,
    )?;

    // lurek.platform.getDebugOverlay() -> bool
    let s = state;
    /// Returns whether the debug overlay is currently visible.
    system.set(
        "getDebugOverlay",
        lua.create_function(move |_, ()| Ok(s.borrow().debug_overlay_enabled))?,
    )?;

    // -----------------------------------------------------------------------
    // Structured logging API
    // -----------------------------------------------------------------------

    #[allow(unused_doc_comments)]
    /// Sets the minimum severity level for runtime log messages.
    /// - `level` Ă”Ă‡Ă¶ One of 'debug', 'info', 'warn', or 'error'.
    // lurek.platform.setLogLevel(level)
    /// @param level string
    system.set(
        "setLogLevel",
        lua.create_function(|_, level: String| {
            log_messages::set_log_level(&level);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the name of the current minimum log level for runtime messages.
    /// One of 'debug', 'info', 'warn', or 'error'.
    // lurek.platform.getLogLevel()
    system.set(
        "getLogLevel",
        lua.create_function(|_, ()| Ok(log_messages::get_log_level().to_string()))?,
    )?;

    #[allow(unused_doc_comments)]
    /// Emit a log message from Lua at the specified level.
    // lurek.platform.log(level, message)
    /// @param level string
    /// @param message string
    system.set(
        "log",
        lua.create_function(|_, (level, message): (String, String)| {
            match level.to_lowercase().as_str() {
                "error" => log::error!("[Lua] {}", message),
                "warn" | "warning" => log::warn!("[Lua] {}", message),
                "info" => log::info!("[Lua] {}", message),
                "debug" => log::debug!("[Lua] {}", message),
                "trace" => log::trace!("[Lua] {}", message),
                _ => log::info!("[Lua] {}", message),
            }
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Get the last engine error as a structured table, or nil.
    // lurek.platform.getLastError()
    {
        /// Returns the last unhandled error message, or nil.
        let s = state_for_error.clone();
        /// @return table?
        system.set(
            "getLastError",
            lua.create_function(move |lua, ()| {
                let state = s.borrow();
                if let Some(ref err_info) = state.last_error {
                    let tbl = lua.create_table()?;
                    /// Message.
                    tbl.set("message", err_info.message.as_str())?;
                    /// Code.
                    tbl.set("code", err_info.code.as_str())?;
                    /// Category.
                    tbl.set("category", err_info.category.as_str())?;
                    if let Some(ref hint) = err_info.hint {
                        /// Hint.
                        tbl.set("hint", hint.as_str())?;
                    }
                    Ok(mlua::Value::Table(tbl))
                } else {
                    Ok(mlua::Value::Nil)
                }
            })?,
        )?;
    }

    // lurek.platform.errorSnapshot(err) -> string
    /// Serialises an engine error message to a compact JSON string.
    ///
    /// Pass the error string from a Lua `pcall` catch block. Returns a JSON
    /// object with `message`, `code`, `category`, and `hint` fields.
    ///
    /// @param err string  Error message (e.g. the second return of `pcall`).
    /// @return string  JSON: `{"message":"...","code":"...","category":"...","hint":"..."}`.
    system.set(
        "errorSnapshot",
        lua.create_function(|_, msg: String| {
            use crate::runtime::EngineError;
            let snap = EngineError::LuaError(msg).snapshot();
            Ok(snap.to_json())
        })?,
    )?;

    // lurek.platform.getArch() -> string
    /// Returns the CPU architecture string for the current machine.
    /// @return string
    /// One of 'x86_64', 'aarch64', 'arm', etc.
    system.set(
        "getArch",
        lua.create_function(|_, ()| Ok(std::env::consts::ARCH.to_string()))?,
    )?;

    // lurek.platform.getEnv(name) -> string?
    /// Returns the value of an environment variable, or nil if not set.
    /// @param name string Environment variable name (case-sensitive on Linux/macOS).
    /// @return string? String value of the variable, or nil if it is not set.
    system.set(
        "getEnv",
        lua.create_function(|_, name: String| match std::env::var(&name) {
            Ok(val) => Ok(Some(val)),
            Err(_) => Ok(None),
        })?,
    )?;

    // lurek.platform.getArgs() -> table
    /// Returns the command-line arguments as a table.
    /// @return table
    system.set(
        "getArgs",
        lua.create_function(|lua, ()| {
            let args: Vec<String> = std::env::args().collect();
            let tbl = lua.create_table()?;
            for (i, arg) in args.iter().enumerate() {
                tbl.set(i as i64 + 1, arg.as_str())?;
            }
            Ok(tbl)
        })?,
    )?;

    // lurek.platform.parseArgs([argTable]) -> { flags={}, options={}, positional={} }
    /// Parses a command-line argument string and returns a structured key/value table.
    /// @param args table?
    /// @return table
    /// - `args` Ă”Ă‡Ă¶ Argument string or table (e.g. '--flag=value --bool').
    /// Table mapping flag names to their values or true for boolean flags.
    system.set(
        "parseArgs",
        lua.create_function(|lua, args: Option<LuaTable>| {
            let raw_args: Vec<String> = if let Some(tbl) = args {
                let mut v = Vec::new();
                for i in 1..=tbl.len()? {
                    if let Ok(s) = tbl.get::<_, String>(i) {
                        v.push(s);
                    }
                }
                v
            } else {
                std::env::args().collect()
            };

            let flags = lua.create_table()?;
            let options = lua.create_table()?;
            let positional = lua.create_table()?;
            let mut pos_idx = 1i64;
            let mut end_of_options = false;
            let mut i = 0;

            while i < raw_args.len() {
                let arg = &raw_args[i];
                if end_of_options {
                    positional.set(pos_idx, arg.as_str())?;
                    pos_idx += 1;
                } else if arg == "--" {
                    end_of_options = true;
                } else if let Some(rest) = arg.strip_prefix("--") {
                    if let Some(eq_pos) = rest.find('=') {
                        let key = &rest[..eq_pos];
                        let val = &rest[eq_pos + 1..];
                        options.set(key, val)?;
                    } else if i + 1 < raw_args.len() && !raw_args[i + 1].starts_with('-') {
                        options.set(rest, raw_args[i + 1].as_str())?;
                        i += 1;
                    } else {
                        flags.set(rest, true)?;
                    }
                } else if let Some(rest) = arg.strip_prefix('-') {
                    if !rest.is_empty() {
                        flags.set(rest, true)?;
                    }
                } else {
                    positional.set(pos_idx, arg.as_str())?;
                    pos_idx += 1;
                }
                i += 1;
            }

            let result = lua.create_table()?;
            /// Flags.
            result.set("flags", flags)?;
            /// Options.
            result.set("options", options)?;
            /// Positional.
            result.set("positional", positional)?;
            Ok(result)
        })?,
    )?;

    // lurek.platform.runBatch(tasks [, opts]) -> results table
    /// Runs a list of shell commands in parallel and returns immediately without blocking.
    /// @param tasks table
    /// @param opts table?
    /// @return table
    /// - `commands` Ă”Ă‡Ă¶ Table of command strings to execute concurrently.
    /// A batch handle ID used to retrieve results with getBatchResults.
    system.set(
        "runBatch",
        lua.create_function(|lua, (tasks, opts): (LuaTable, Option<LuaTable>)| {
            let stop_on_error = opts
                .as_ref()
                .and_then(|o| o.get::<_, bool>("stopOnError").ok())
                .unwrap_or(false);

            let results = lua.create_table()?;
            let mut had_error = false;

            for pair in tasks.pairs::<String, LuaFunction>() {
                let (name, func) = pair?;
                if had_error && stop_on_error {
                    let entry = lua.create_table()?;
                    /// Status.
                    entry.set("status", "skipped")?;
                    /// Time.
                    entry.set("time", 0.0)?;
                    results.set(name, entry)?;
                    continue;
                }

                let start = std::time::Instant::now();
                let entry = lua.create_table()?;
                match func.call::<_, LuaMultiValue>(()) {
                    Ok(_) => {
                        /// Status.
                        entry.set("status", "passed")?;
                    }
                    Err(e) => {
                        /// Status.
                        entry.set("status", "failed")?;
                        /// Error.
                        entry.set("error", e.to_string())?;
                        had_error = true;
                    }
                }
                /// Time.
                entry.set("time", start.elapsed().as_secs_f64())?;
                results.set(name, entry)?;
            }

            Ok(results)
        })?,
    )?;

    // lurek.platform.getBatchResults(results) -> passed, failed, skipped
    /// Returns the output table from the most recently completed runBatch call.
    /// @param results table
    /// @return integer, integer, integer
    /// - `handle` Ă”Ă‡Ă¶ Batch handle returned by runBatch.
    /// Table mapping each command to its stdout string, or nil if not yet done.
    system.set(
        "getBatchResults",
        lua.create_function(|_, results: LuaTable| {
            let mut passed = 0i64;
            let mut failed = 0i64;
            let mut skipped = 0i64;
            for pair in results.pairs::<LuaValue, LuaTable>() {
                let (_, entry) = pair?;
                if let Ok(s) = entry.get::<_, String>("status") {
                    match s.as_str() {
                        "passed" => passed += 1,
                        "failed" => failed += 1,
                        "skipped" => skipped += 1,
                        _ => {}
                    }
                }
            }
            Ok((passed, failed, skipped))
        })?,
    )?;

    /// System.
    lurek.set("runtime", system)?;
    Ok(())
}
