//! `lurek.system` - Provides OS-level utilities including clipboard, system info, environment variables, and platform detection.

use super::SharedState;
use crate::log_msg;
use crate::runtime::log_messages::{
    self, LA03_OPEN_URL_REJECTED, LA04_CLIPBOARD_WRITE_FAIL, LA05_CLIPBOARD_UNAVAIL,
    LA06_CLIPBOARD_READ_FAIL,
};
use crate::runtime::messages;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Returns the number of logical processors available on the host system.
pub fn get_processor_count() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1)
}

/// Returns total physical memory in megabytes reported by the operating system.
pub fn get_memory_size() -> u64 {
    use sysinfo::System;
    let sys = System::new_with_specifics(
        sysinfo::RefreshKind::new().with_memory(sysinfo::MemoryRefreshKind::everything()),
    );
    sys.total_memory() / (1024 * 1024)
}

/// Opens a URL in the default system browser. Only `http://`, `https://`, and `mailto:` schemes are allowed.
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

/// Returns the user's preferred locale list from the operating system, falling back to `"en_US"` if unavailable.
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
/// Describes the current power supply state of the host device.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PowerState {
    Unknown,
    Battery,
    NoBattery,
    Charging,
    Charged,
}

impl PowerState {
    /// Returns the Lua-visible power state string.
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

/// Returns the current power state, battery percentage (0-100), and estimated seconds remaining.
pub fn get_power_info() -> (PowerState, Option<u32>, Option<u32>) {
    (PowerState::Unknown, None, None)
}

/// Registers all `lurek.system` functions into the Lua runtime table.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let system = lua.create_table()?;

    // -- getOS --
    /// Returns the name of the host operating system as a string.
    /// @return | string | Operating system name: `"Windows"`, `"Linux"`, `"macOS"`, `"Android"`, `"iOS"`, or `"Unknown"`.
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

    // -- getVersion --
    /// Returns the semantic version string of the Lurek2D engine.
    /// @return | string | Engine version in `"MAJOR.MINOR.PATCH"` format.
    system.set(
        "getVersion",
        lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION").to_string()))?,
    )?;

    // -- getProcessorCount --
    /// Returns the number of logical processors available on the host machine.
    /// @return | number | Logical processor count (minimum 1).
    system.set(
        "getProcessorCount",
        lua.create_function(|_, ()| Ok(get_processor_count()))?,
    )?;

    // -- getMemorySize --
    /// Returns the total physical memory of the host system in megabytes.
    /// @return | number | Total RAM in MB.
    system.set(
        "getMemorySize",
        lua.create_function(|_, ()| Ok(get_memory_size()))?,
    )?;

    // -- openURL --
    /// Opens a URL in the default system browser. Only `http://`, `https://`, and `mailto:` schemes are permitted.
    /// @param | url | string | The URL to open.
    /// @return | boolean | `true` if the URL was accepted and the open command launched successfully.
    system.set(
        "openURL",
        lua.create_function(|_, url: String| Ok(open_url(&url)))?,
    )?;

    // -- getPreferredLocales --
    /// Returns a list of the user's preferred locale identifiers from the operating system.
    /// @return | table | Array of locale strings (e.g. `{"en_US", "pl_PL"}`). Falls back to `{"en_US"}` if detection fails.
    system.set(
        "getPreferredLocales",
        lua.create_function(|_, ()| Ok(get_preferred_locales()))?,
    )?;

    // -- getPowerInfo --
    /// Returns the current power supply state, battery percentage, and estimated time remaining.
    /// @return | string | Power state: `"unknown"`, `"battery"`, `"nobattery"`, `"charging"`, or `"charged"`.
    /// @return | integer | Battery charge percentage from 0 to 100. This value may be `nil` when the platform does not provide battery data.
    /// @return | integer | Estimated battery life remaining in seconds. This value may be `nil` when the platform does not provide battery data.
    system.set(
        "getPowerInfo",
        lua.create_function(|_, ()| {
            let (state, percent, seconds) = get_power_info();
            Ok((state.as_str().to_string(), percent, seconds))
        })?,
    )?;

    // -- getInfo --
    /// Returns a table with comprehensive engine and host information.
    /// @return | table | Table with fields: `engine` (string), `version` (string), `lua_version` (string), `renderer` (string), `os` (string), `processors` (number), `memory` (number).
    system.set(
        "getInfo",
        lua.create_function(|lua, ()| {
            let info = lua.create_table()?;
            info.set("engine", "Lurek2D")?;
            info.set("version", env!("CARGO_PKG_VERSION"))?;
            info.set("lua_version", "Lua 5.4")?;
            info.set("renderer", "wgpu")?;
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
            info.set("processors", get_processor_count())?;
            info.set("memory", get_memory_size())?;
            Ok(info)
        })?,
    )?;

    // -- getMessage --
    /// Resolves a message string by its identifier from the engine message catalog.
    /// @param | id | string | The message identifier to look up.
    /// @return | string | The resolved message text. Returns `nil` when the identifier is not found.
    system.set(
        "getMessage",
        lua.create_function(|_, id: String| Ok(messages::resolve_message(&id)))?,
    )?;

    // -- hasMessage --
    /// Checks whether a message identifier exists in the engine message catalog.
    /// @param | id | string | The message identifier to check.
    /// @return | boolean | `true` if the message identifier is registered.
    system.set(
        "hasMessage",
        lua.create_function(|_, id: String| Ok(messages::has_message(&id)))?,
    )?;

    // -- getMessageCount --
    /// Returns the total number of messages registered in the engine message catalog.
    /// @return | number | Count of registered message identifiers.
    system.set(
        "getMessageCount",
        lua.create_function(|_, ()| Ok(messages::message_count()))?,
    )?;

    // -- setClipboardText --
    /// Copies a string to the system clipboard. Logs a warning if the clipboard is unavailable or the write fails.
    /// @param | text | string | The text to place on the clipboard.
    /// @return | nil | No value is returned.
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

    // -- getClipboardText --
    /// Reads the current text content from the system clipboard. Returns an empty string if the clipboard is unavailable or contains no text.
    /// @return | string | The clipboard text, or `""` on failure.
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
    let state_for_error = state.clone();
    let s = state.clone();

    // -- reloadConfig --
    /// Requests a reload of the engine configuration from `conf.lua`. The reload is deferred until the next frame.
    /// @return | nil | No value is returned.
    system.set(
        "reloadConfig",
        lua.create_function(move |_, ()| {
            s.borrow_mut().pending_config_reload = true;
            Ok(())
        })?,
    )?;

    let s = state.clone();

    // -- getConfig --
    /// Returns a table containing the current engine runtime configuration values.
    /// @return | table | Table with fields: `physics_tick_rate` (number), `fixed_update_tick_rate` (number?), `frame_budget_warn_ms` (number?), `lua_callback_timeout_ms` (number?), `vsync` (boolean), `log_level` (string), `config_reload_revision` (number).
    system.set(
        "getConfig",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            let fixed_dt = st.physics_run.fixed_dt;
            let physics_tick_rate = if fixed_dt > 0.0 { 1.0 / fixed_dt } else { 0.0 };
            tbl.set("physics_tick_rate", physics_tick_rate)?;
            let fixed_update_dt = st.physics_run.fixed_update_dt;
            if fixed_update_dt > 0.0 {
                tbl.set("fixed_update_tick_rate", 1.0 / fixed_update_dt)?;
            } else {
                tbl.set("fixed_update_tick_rate", mlua::Value::Nil)?;
            }
            if let Some(ms) = st.frame_budget_warn_ms {
                tbl.set("frame_budget_warn_ms", ms)?;
            } else {
                tbl.set("frame_budget_warn_ms", mlua::Value::Nil)?;
            }
            if let Some(ms) = st.lua_callback_timeout_ms {
                tbl.set("lua_callback_timeout_ms", ms)?;
            } else {
                tbl.set("lua_callback_timeout_ms", mlua::Value::Nil)?;
            }
            tbl.set("vsync", st.window_state.vsync_mode != 0)?;
            tbl.set("log_level", log_messages::get_log_level().to_string())?;
            tbl.set("config_reload_revision", st.config_reload_revision)?;
            Ok(tbl)
        })?,
    )?;

    let s = state.clone();

    // -- setDebugOverlay --
    /// Enables or disables the on-screen debug overlay that shows FPS, draw calls, and other diagnostics.
    /// @param | enabled | boolean | `true` to show the debug overlay, `false` to hide it.
    /// @return | nil | No value is returned.
    system.set(
        "setDebugOverlay",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().debug_overlay_enabled = enabled;
            Ok(())
        })?,
    )?;

    let s = state;

    // -- getDebugOverlay --
    /// Returns whether the on-screen debug overlay is currently enabled.
    /// @return | boolean | `true` if the debug overlay is visible.
    system.set(
        "getDebugOverlay",
        lua.create_function(move |_, ()| Ok(s.borrow().debug_overlay_enabled))?,
    )?;

    // -- setLogLevel --
    /// Sets the engine-wide log verbosity level at runtime.
    /// @param | level | string | Log level: `"error"`, `"warn"`, `"info"`, `"debug"`, or `"trace"`.
    /// @return | nil | No value is returned.
    #[allow(unused_doc_comments)]
    system.set(
        "setLogLevel",
        lua.create_function(|_, level: String| {
            log_messages::set_log_level(&level);
            Ok(())
        })?,
    )?;

    // -- getLogLevel --
    /// Returns the current engine log verbosity level as a string.
    /// @return | string | Current log level: `"error"`, `"warn"`, `"info"`, `"debug"`, or `"trace"`.
    #[allow(unused_doc_comments)]
    system.set(
        "getLogLevel",
        lua.create_function(|_, ()| Ok(log_messages::get_log_level().to_string()))?,
    )?;

    // -- log --
    /// Writes a message to the engine log at the specified severity level.
    /// @param | level | string | Log level: `"error"`, `"warn"`, `"info"`, `"debug"`, or `"trace"`. Defaults to `"info"` if unrecognized.
    /// @param | message | string | The message text to log.
    /// @return | nil | No value is returned.
    #[allow(unused_doc_comments)]
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
    // -- getLastError --
    /// Returns the most recent engine error as a table, or `nil` if no error has occurred.
    /// @return | table | Table with fields: `message` (string), `code` (string), `category` (string), and optional `hint` (string). Returns `nil` when no error is recorded.
    #[allow(unused_doc_comments)]
    {
        let s = state_for_error.clone();
        /// Returns the last error for Lua scripts in this module.
        /// @return | table | Table result returned by this call.
        system.set(
            "getLastError",
            lua.create_function(move |lua, ()| {
                let state = s.borrow();
                if let Some(ref err_info) = state.last_error {
                    let tbl = lua.create_table()?;
                    tbl.set("message", err_info.message.as_str())?;
                    tbl.set("code", err_info.code.as_str())?;
                    tbl.set("category", err_info.category.as_str())?;
                    if let Some(ref hint) = err_info.hint {
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
    /// Creates a JSON-encoded error snapshot from a message string, useful for diagnostics and error reporting.
    /// @param | msg | string | The error message to capture.
    /// @return | string | JSON string containing the error snapshot with stack and context information.
    system.set(
        "errorSnapshot",
        lua.create_function(|_, msg: String| {
            use crate::runtime::EngineError;
            let snap = EngineError::LuaError(msg).snapshot();
            Ok(snap.to_json())
        })?,
    )?;

    // -- getArch --
    /// Returns the CPU architecture of the host system.
    /// @return | string | Architecture identifier (e.g. `"x86_64"`, `"aarch64"`).
    system.set(
        "getArch",
        lua.create_function(|_, ()| Ok(std::env::consts::ARCH.to_string()))?,
    )?;

    // -- getEnv --
    /// Reads an environment variable by name. Returns `nil` if the variable is not set.
    /// @param | name | string | The environment variable name.
    /// @return | string | The variable value. Returns `nil` when the variable is not set.
    system.set(
        "getEnv",
        lua.create_function(|_, name: String| match std::env::var(&name) {
            Ok(val) => Ok(Some(val)),
            Err(_) => Ok(None),
        })?,
    )?;

    // -- getArgs --
    /// Returns the command-line arguments passed to the engine as a 1-indexed table of strings.
    /// @return | table | Array of argument strings.
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

    // -- parseArgs --
    /// Parses command-line arguments into structured flags, options, and positional values. Supports `--key=value`, `--key value`, `-flag`, and `--` end-of-options.
    /// @param | args | table? | Optional table of argument strings. Uses `os.args` if omitted.
    /// @return | table | Table with fields: `flags` (table of boolean), `options` (table of string), `positional` (array of string).
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
            result.set("flags", flags)?;
            result.set("options", options)?;
            result.set("positional", positional)?;
            Ok(result)
        })?,
    )?;

    // -- runBatch --
    /// Executes a table of named task functions sequentially, collecting pass/fail results and elapsed time for each.
    /// @param | tasks | table | Table mapping task names (string) to task functions (function).
    /// @param | opts | table? | Options table. Set `stopOnError = true` to skip remaining tasks after the first failure.
    /// @return | table | Table mapping each task name to a result table with `status` (`"passed"`, `"failed"`, or `"skipped"`), `time` (number), and optionally `error` (string).
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
                    entry.set("status", "skipped")?;
                    entry.set("time", 0.0)?;
                    results.set(name, entry)?;
                    continue;
                }
                let start = std::time::Instant::now();
                let entry = lua.create_table()?;
                match func.call::<_, LuaMultiValue>(()) {
                    Ok(_) => {
                        entry.set("status", "passed")?;
                    }
                    Err(e) => {
                        entry.set("status", "failed")?;
                        entry.set("error", e.to_string())?;
                        had_error = true;
                    }
                }
                entry.set("time", start.elapsed().as_secs_f64())?;
                results.set(name, entry)?;
            }
            Ok(results)
        })?,
    )?;

    // -- getBatchResults --
    /// Summarizes batch results by counting passed, failed, and skipped tasks.
    /// @param | results | table | The results table returned by `runBatch`.
    /// @return | number | Count of passed tasks.
    /// @return | number | Count of failed tasks.
    /// @return | number | Count of skipped tasks.
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
    lurek.set("runtime", system)?;
    Ok(())
}
