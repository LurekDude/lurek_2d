//! Structured game-level logging API (`luna.log.*`).
//!
//! Exposes convenience logging functions so Lua scripts can emit messages at
//! specific severity levels and query or change the active log level at
//! runtime without going through the `luna.system` namespace.

use mlua::prelude::*;

use crate::engine::log_messages;

/// Registers the `luna.log.*` namespace into the shared `luna` table.
///
/// # Errors
/// Returns a `LuaError` if any function or table registration fails.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let log_table = lua.create_table()?;

    #[allow(unused_doc_comments)]
    /// Emit a debug-severity log message from Lua.
    /// @param message : string
    log_table.set(
        "debug",
        lua.create_function(|_, message: String| {
            log::debug!("[Lua] {}", message);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Emit an info-severity log message from Lua.
    /// @param message : string
    log_table.set(
        "info",
        lua.create_function(|_, message: String| {
            log::info!("[Lua] {}", message);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Emit a warn-severity log message from Lua.
    /// @param message : string
    log_table.set(
        "warn",
        lua.create_function(|_, message: String| {
            log::warn!("[Lua] {}", message);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Emit an error-severity log message from Lua.
    /// @param message : string
    log_table.set(
        "error",
        lua.create_function(|_, message: String| {
            log::error!("[Lua] {}", message);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Emit a log message from Lua at the specified severity level.
    /// @param level : string
    /// @param message : string
    ///
    /// Accepts the same level strings as `luna.log.setLevel`:
    /// `"debug"`, `"info"`, `"warn"`, `"error"`, `"trace"`.
    /// Unknown levels fall back to `info`.
    log_table.set(
        "print",
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
    /// Set the minimum severity level for runtime log messages.
    /// @param level : string
    log_table.set(
        "setLevel",
        lua.create_function(|_, level: String| {
            log_messages::set_log_level(&level);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Return the name of the currently active minimum log level.
    /// @return string
    log_table.set(
        "getLevel",
        lua.create_function(|_, ()| Ok(log_messages::get_log_level().to_string()))?,
    )?;

    luna.set("log", log_table)?;
    Ok(())
}
