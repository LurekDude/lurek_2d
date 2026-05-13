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
pub fn get_processor_count() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1)
}
pub fn get_memory_size() -> u64 {
    use sysinfo::System;
    let sys = System::new_with_specifics(
        sysinfo::RefreshKind::new().with_memory(sysinfo::MemoryRefreshKind::everything()),
    );
    sys.total_memory() / (1024 * 1024)
}
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
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PowerState {
    Unknown,
    Battery,
    NoBattery,
    Charging,
    Charged,
}
impl PowerState {
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
pub fn get_power_info() -> (PowerState, Option<u32>, Option<u32>) {
    (PowerState::Unknown, None, None)
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let system = lua.create_table()?;
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
    system.set(
        "getVersion",
        lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION").to_string()))?,
    )?;
    system.set(
        "getProcessorCount",
        lua.create_function(|_, ()| Ok(get_processor_count()))?,
    )?;
    system.set(
        "getMemorySize",
        lua.create_function(|_, ()| Ok(get_memory_size()))?,
    )?;
    system.set(
        "openURL",
        lua.create_function(|_, url: String| Ok(open_url(&url)))?,
    )?;
    system.set(
        "getPreferredLocales",
        lua.create_function(|_, ()| Ok(get_preferred_locales()))?,
    )?;
    system.set(
        "getPowerInfo",
        lua.create_function(|_, ()| {
            let (state, percent, seconds) = get_power_info();
            Ok((state.as_str().to_string(), percent, seconds))
        })?,
    )?;
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
    system.set(
        "getMessage",
        lua.create_function(|_, id: String| Ok(messages::resolve_message(&id)))?,
    )?;
    system.set(
        "hasMessage",
        lua.create_function(|_, id: String| Ok(messages::has_message(&id)))?,
    )?;
    system.set(
        "getMessageCount",
        lua.create_function(|_, ()| Ok(messages::message_count()))?,
    )?;
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
    system.set(
        "reloadConfig",
        lua.create_function(move |_, ()| {
            s.borrow_mut().pending_config_reload = true;
            Ok(())
        })?,
    )?;
    let s = state.clone();
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
    system.set(
        "setDebugOverlay",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().debug_overlay_enabled = enabled;
            Ok(())
        })?,
    )?;
    let s = state;
    system.set(
        "getDebugOverlay",
        lua.create_function(move |_, ()| Ok(s.borrow().debug_overlay_enabled))?,
    )?;
    #[allow(unused_doc_comments)]
    system.set(
        "setLogLevel",
        lua.create_function(|_, level: String| {
            log_messages::set_log_level(&level);
            Ok(())
        })?,
    )?;
    #[allow(unused_doc_comments)]
    system.set(
        "getLogLevel",
        lua.create_function(|_, ()| Ok(log_messages::get_log_level().to_string()))?,
    )?;
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
    #[allow(unused_doc_comments)]
    {
        let s = state_for_error.clone();
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
    system.set(
        "errorSnapshot",
        lua.create_function(|_, msg: String| {
            use crate::runtime::EngineError;
            let snap = EngineError::LuaError(msg).snapshot();
            Ok(snap.to_json())
        })?,
    )?;
    system.set(
        "getArch",
        lua.create_function(|_, ()| Ok(std::env::consts::ARCH.to_string()))?,
    )?;
    system.set(
        "getEnv",
        lua.create_function(|_, name: String| match std::env::var(&name) {
            Ok(val) => Ok(Some(val)),
            Err(_) => Ok(None),
        })?,
    )?;
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
