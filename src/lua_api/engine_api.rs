//! `lurek.engine` — Runtime engine metadata and introspection.
//!
//! Exposes read-only properties about the running engine: version, target
//! frame budget, memory usage, host platform, and total uptime.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Registers the `lurek.engine.*` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- getVersion --
    /// Returns the engine version string (from `Cargo.toml`).
    /// @return string
    tbl.set(
        "getVersion",
        lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION")))?,
    )?;

    // -- getFrameBudget --
    /// Returns the target frame budget in milliseconds (default: 1000 / 60 ≈ 16.667 ms).
    /// @return number
    tbl.set(
        "getFrameBudget",
        lua.create_function(|_, ()| Ok(1000.0_f64 / 60.0_f64))?,
    )?;

    // -- memoryUsage --
    /// Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and
    /// `lua_kb` (same in kilobytes, rounded to two decimal places).
    /// @return table
    tbl.set(
        "memoryUsage",
        lua.create_function(|lua, ()| {
            let bytes = lua.used_memory();
            let out = lua.create_table()?;
            out.set("lua_bytes", bytes as u64)?;
            out.set("lua_kb", (bytes as f64 / 1024.0 * 100.0).round() / 100.0)?;
            Ok(out)
        })?,
    )?;

    // -- platform --
    /// Returns a string identifying the host operating system:
    /// `"windows"`, `"linux"`, or `"macos"`.
    /// @return string
    tbl.set(
        "platform",
        lua.create_function(|_, ()| {
            let name = if cfg!(target_os = "windows") {
                "windows"
            } else if cfg!(target_os = "linux") {
                "linux"
            } else if cfg!(target_os = "macos") {
                "macos"
            } else {
                "unknown"
            };
            Ok(name)
        })?,
    )?;

    // -- uptime --
    /// Returns the total engine uptime in seconds (sum of all processed deltas).
    /// @return number
    let s = state.clone();
    tbl.set(
        "uptime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;

    // -- fps --
    /// Returns the current measured frames-per-second.
    /// @return number
    let s = state.clone();
    tbl.set(
        "fps",
        lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;

    // -- frameCount --
    /// Returns the total number of frames processed since engine start.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "frameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;

    // -- isDebug --
    /// Returns `true` if the engine was compiled in debug mode.
    /// @return boolean
    tbl.set(
        "isDebug",
        lua.create_function(|_, ()| Ok(cfg!(debug_assertions)))?,
    )?;

    luna.set("engine", tbl)?;
    Ok(())
}
