//! `lurek.platform` - Platform queries: OS name, CPU count, memory size, power state,
//! preferred locales, clipboard access, and safe URL opening.
//!
//! Registered as `lurek.platform.*` in the Lua VM. Domain logic is minimal -
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
pub fn get_processor_count() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1)
}

/// Returns total system RAM in MiB using the `sysinfo` crate.
pub fn get_memory_size() -> u64 {
    use sysinfo::System;
    let sys = System::new_with_specifics(
        sysinfo::RefreshKind::new().with_memory(sysinfo::MemoryRefreshKind::everything()),
    );
    sys.total_memory() / (1024 * 1024)
}

/// Opens a URL in the default browser/application.
/// Only `http://`, `https://`, and `mailto:` schemes are allowed, and the function returns `true` when the command was spawned.
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
/// On desktop platforms this always returns `(Unknown, None, None)`.
pub fn get_power_info() -> (PowerState, Option<u32>, Option<u32>) {
    (PowerState::Unknown, None, None)
}

/// Registers `lurek.platform.*` platform query functions into the Lua VM.
/// @param | lua | Lua | Active Lua state.
/// @param | lurek | table | Root `lurek` table.
/// @param | state | SharedState | Shared engine state.
/// @return | nil | Registers the platform API table.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let system = lua.create_table()?;

    // -- getOS --
    /// Returns the host operating system name ('Windows', 'Linux', 'macOS').
    /// @return | string | Returns the host operating system name.
    system.set("getOS", lua.create_function(|_, ()| {
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

        // -- getVersion --
    /// Returns the Lurek2D engine version string.
        /// @return | string | Returns the engine version string.
    system.set("getVersion", lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION").to_string()))?,
    )?;

        // -- getProcessorCount --
    /// Returns the number of logical CPU cores available.
        /// @return | integer | Returns the number of logical CPU cores.
    system.set("getProcessorCount", lua.create_function(|_, ()| Ok(get_processor_count()))?,
    )?;

        // -- getMemorySize --
    /// Returns the total amount of installed system RAM in megabytes.
        /// @return | integer | Returns the RAM size in megabytes.
    system.set("getMemorySize", lua.create_function(|_, ()| Ok(get_memory_size()))?,
    )?;

        // -- openURL --
    /// Opens a URL in the system's default browser.
        /// @param | url | string | URL to open.
        /// @return | boolean | Returns whether the URL launch command was spawned.
    system.set("openURL", lua.create_function(|_, url: String| Ok(open_url(&url)))?,
    )?;

        // -- getPreferredLocales --
    /// Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
        /// @return | table | Returns locale strings ordered from most to least preferred.
    system.set("getPreferredLocales", lua.create_function(|_, ()| Ok(get_preferred_locales()))?,
    )?;

        // -- getPowerInfo --
    /// Returns battery state, percentage charged, and estimated time remaining.
        /// @return | string | Battery state name.
        /// @return | integer | Battery percentage.
        /// @return | integer | Estimated seconds remaining.
    system.set("getPowerInfo", lua.create_function(|_, ()| {
            let (state, percent, seconds) = get_power_info();
            Ok((state.as_str().to_string(), percent, seconds))
        })?,
    )?;

        // -- getInfo --
    /// Returns a table of system information including OS name, CPU model, and installed RAM.
        /// @return | table | Returns engine and platform information fields.
    system.set("getInfo", lua.create_function(|lua, ()| {
            let info = lua.create_table()?;
            // Engine.
            info.set("engine", "Lurek2D")?;
            // Version.
            info.set("version", env!("CARGO_PKG_VERSION"))?;
            // Lua version.
            info.set("lua_version", "Lua 5.4")?;
            // Renderer.
            info.set("renderer", "wgpu")?;
            // OS.
            info.set("os", if cfg!(target_os = "windows") {
                    "Windows"
                } else if cfg!(target_os = "linux") {
                    "Linux"
                } else if cfg!(target_os = "macos") {
                    "macOS"
                } else {
                    "Unknown"
                },
            )?;
            // Processors.
            info.set("processors", get_processor_count())?;
            // Memory.
            info.set("memory", get_memory_size())?;
            Ok(info)
        })?,
    )?;

    // -- getMessage --
    /// Resolves a stable runtime message ID such as 'L001' to its human-readable text.
    /// @param | id | string | Stable runtime message identifier.
    /// @return | string | Returns the resolved message text.
    system.set("getMessage", lua.create_function(|_, id: String| Ok(messages::resolve_message(&id)))?,
    )?;

    // -- hasMessage --
    /// Returns true when the runtime message catalog contains the given stable message ID.
    /// @param | id | string | Stable runtime message identifier.
    /// @return | boolean | Returns whether the message catalog contains the ID.
    system.set("hasMessage", lua.create_function(|_, id: String| Ok(messages::has_message(&id)))?,
    )?;

    // -- getMessageCount --
    /// Returns the total number of message entries loaded into the runtime message catalog.
    /// @return | integer | Returns the total number of message entries.
    system.set("getMessageCount", lua.create_function(|_, ()| Ok(messages::message_count()))?,
    )?;

    // -- setClipboardText --
    /// Replaces the system clipboard contents with the given string.
    /// @param | text | string | Clipboard text to write.
    /// @return | nil | No value is returned.
    system.set("setClipboardText", lua.create_function(|_, text: String| {
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

    // -- getClipboardText --
    /// Returns the current contents of the system clipboard.
    /// @return | string | Returns the current clipboard text or an empty string on failure.
    system.set("getClipboardText", lua.create_function(|_, ()| match arboard::Clipboard::new() {
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

    // -- setDebugOverlay --
    /// Shows or hides the FPS/draw-call debug overlay.
    /// @param | enabled | boolean | Whether the debug overlay should be visible.
    /// @return | nil | No value is returned.
    let s = state.clone();
    system.set("setDebugOverlay", lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().debug_overlay_enabled = enabled;
            Ok(())
        })?,
    )?;

    // -- getDebugOverlay --
    /// Returns whether the debug overlay is currently visible.
    /// @return | boolean | Returns whether the debug overlay is visible.
    let s = state;
    system.set("getDebugOverlay", lua.create_function(move |_, ()| Ok(s.borrow().debug_overlay_enabled))?,
    )?;

    // -----------------------------------------------------------------------
    // Structured logging API
    // -----------------------------------------------------------------------

    #[allow(unused_doc_comments)]
    // -- setLogLevel --
    /// Sets the minimum severity level for runtime log messages.
    /// @param | level | string | Minimum log level such as `debug`, `info`, `warn`, or `error`.
    /// @return | nil | No value is returned.
    system.set("setLogLevel", lua.create_function(|_, level: String| {
            log_messages::set_log_level(&level);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    // -- getLogLevel --
    /// Returns the name of the current minimum log level for runtime messages.
    /// @return | string | Returns the current minimum log level name.
    system.set("getLogLevel", lua.create_function(|_, ()| Ok(log_messages::get_log_level().to_string()))?,
    )?;

    #[allow(unused_doc_comments)]
    // -- log --
    /// Emit a log message from Lua at the specified level.
    /// @param | level | string | Log level to emit.
    /// @param | message | string | Log message text.
    /// @return | nil | No value is returned.
    system.set("log", lua.create_function(|_, (level, message): (String, String)| {
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
    // -- getLastError --
    {
        /// Returns the last unhandled error message, or nil.
        /// @return | table | Returns the last error snapshot table when one exists.
        let s = state_for_error.clone();
        system.set("getLastError", lua.create_function(move |lua, ()| {
                let state = s.borrow();
                if let Some(ref err_info) = state.last_error {
                    let tbl = lua.create_table()?;
                    // Message.
                    tbl.set("message", err_info.message.as_str())?;
                    // Code.
                    tbl.set("code", err_info.code.as_str())?;
                    // Category.
                    tbl.set("category", err_info.category.as_str())?;
                    if let Some(ref hint) = err_info.hint {
                        // Hint.
                        tbl.set("hint", hint.as_str())?;
                    }
                    Ok(mlua::Value::Table(tbl))
                } else {
                    Ok(mlua::Value::Nil)
                }
            })?,
        )?;
    }

    // -- errorSnapshot --
    /// Serialises an engine error message to a compact JSON string.
    /// @param | err | string | Error message, such as the second return value from `pcall`.
    /// @return | string | Returns a compact JSON object with `message`, `code`, `category`, and `hint` fields.
    system.set("errorSnapshot", lua.create_function(|_, msg: String| {
            use crate::runtime::EngineError;
            let snap = EngineError::LuaError(msg).snapshot();
            Ok(snap.to_json())
        })?,
    )?;

    // -- getArch --
    /// Returns the CPU architecture string for the current machine.
    /// @return | string | Returns the current machine architecture string.
    system.set("getArch", lua.create_function(|_, ()| Ok(std::env::consts::ARCH.to_string()))?,
    )?;

    // -- getEnv --
    /// Returns the value of an environment variable, or nil if not set.
    /// @param | name | string | Environment variable name.
    /// @return | string | Returns the variable value when it is set.
    system.set("getEnv", lua.create_function(|_, name: String| match std::env::var(&name) {
            Ok(val) => Ok(Some(val)),
            Err(_) => Ok(None),
        })?,
    )?;

    // -- getArgs --
    /// Returns the command-line arguments as a table.
    /// @return | table | Returns the command-line arguments as an array table.
    system.set("getArgs", lua.create_function(|lua, ()| {
            let args: Vec<String> = std::env::args().collect();
            let tbl = lua.create_table()?;
            for (i, arg) in args.iter().enumerate() {
                tbl.set(i as i64 + 1, arg.as_str())?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- parseArgs --
    /// Parses a command-line argument string and returns a structured key/value table.
    /// @param | args | table? | Optional argument table to parse instead of process arguments.
    /// @return | table | Returns a table with `flags`, `options`, and `positional` fields.
    system.set("parseArgs", lua.create_function(|lua, args: Option<LuaTable>| {
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
            // Flags.
            result.set("flags", flags)?;
            // Options.
            result.set("options", options)?;
            // Positional.
            result.set("positional", positional)?;
            Ok(result)
        })?,
    )?;

    // -- runBatch --
    /// Runs a list of shell commands in parallel and returns immediately without blocking.
    /// @param | tasks | table | Table of named batch tasks to execute.
    /// @param | opts | table? | Optional batch settings such as `stopOnError`.
    /// @return | table | Returns the batch results table.
    system.set("runBatch", lua.create_function(|lua, (tasks, opts): (LuaTable, Option<LuaTable>)| {
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
                    // Status.
                    entry.set("status", "skipped")?;
                    // Time.
                    entry.set("time", 0.0)?;
                    results.set(name, entry)?;
                    continue;
                }

                let start = std::time::Instant::now();
                let entry = lua.create_table()?;
                match func.call::<_, LuaMultiValue>(()) {
                    Ok(_) => {
                        // Status.
                        entry.set("status", "passed")?;
                    }
                    Err(e) => {
                        // Status.
                        entry.set("status", "failed")?;
                        // Error.
                        entry.set("error", e.to_string())?;
                        had_error = true;
                    }
                }
                // Time.
                entry.set("time", start.elapsed().as_secs_f64())?;
                results.set(name, entry)?;
            }

            Ok(results)
        })?,
    )?;

    // -- getBatchResults --
    /// Returns the output table from the most recently completed runBatch call.
    /// @param | results | table | Results table returned by `runBatch`.
    /// @return | integer | Number of passed tasks.
    /// @return | integer | Number of failed tasks.
    /// @return | integer | Number of skipped tasks.
    system.set("getBatchResults", lua.create_function(|_, results: LuaTable| {
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

    // System.
    lurek.set("runtime", system)?;
    Ok(())
}
