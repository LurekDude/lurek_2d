//! `lurek.runtime` - Runtime engine metadata and introspection.
//!
//! Exposes read-only properties about the running engine: version, target
//! frame budget, memory usage, host platform, and total uptime.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Registers the `lurek.runtime.*` namespace.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- getVersion --
    /// Returns the engine version string (from `Cargo.toml`).
    /// @return | string | Engine version string.
    tbl.set("getVersion", lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION")))?,
    )?;

    // -- getFrameBudget --
    /// Returns the target frame budget in milliseconds (default: 1000 / 60 ~ 16.667 ms).
    /// @return | number | Target frame budget in milliseconds.
    tbl.set("getFrameBudget", lua.create_function(|_, ()| Ok(1000.0_f64 / 60.0_f64))?,
    )?;

    // -- memoryUsage --
    /// Returns Lua memory usage in bytes and kilobytes.
    /// @return | table | Table with `lua_bytes` and `lua_kb` fields.
    tbl.set("memoryUsage", lua.create_function(|lua, ()| {
            let bytes = lua.used_memory();
            let out = lua.create_table()?;
            out.set("lua_bytes", bytes as u64)?;
            out.set("lua_kb", (bytes as f64 / 1024.0 * 100.0).round() / 100.0)?;
            Ok(out)
        })?,
    )?;

    // -- platform --
    /// Returns the host operating system name.
    /// @return | string | One of `windows`, `linux`, `macos`, or `unknown`.
    tbl.set("platform", lua.create_function(|_, ()| {
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
    /// @return | number | Total engine uptime in seconds.
    let s = state.clone();
    tbl.set("uptime", lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;

    let s = state.clone();
    // -- fps --
    /// Returns the current measured frames-per-second.
    /// @return | number | Current frames-per-second estimate.
    tbl.set("fps", lua.create_function(move |_, ()| Ok(s.borrow().fps))?)?;

    // -- frameCount --
    /// Returns the total number of frames processed since engine start.
    /// @return | integer | Total processed frame count.
    let s = state.clone();
    tbl.set("frameCount", lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;

    // -- isDebug --
    /// Returns `true` if the engine was compiled in debug mode.
    /// @return | boolean | Whether debug assertions are enabled.
    tbl.set("isDebug", lua.create_function(|_, ()| Ok(cfg!(debug_assertions)))?,
    )?;

    // -- setResourceBudget --
    /// Sets the maximum resident texture memory budget in bytes.
    /// @param | budget_bytes | integer | Maximum texture memory budget in bytes, or 0 for unlimited.
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("setResourceBudget", lua.create_function(move |_, budget_bytes: u64| {
            s.borrow_mut().resource_budget_bytes = budget_bytes;
            Ok(())
        })?,
    )?;

    // -- getResourceStats --
    /// Returns a table with resident resource memory statistics.
    /// @return | table | Table with `texture_bytes`, `budget_bytes`, and `texture_count` fields.
    let s = state.clone();
    tbl.set("getResourceStats", lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let (tex_bytes, budget) = st.resource_memory_stats();
            let out = lua.create_table()?;
            out.set("texture_bytes", tex_bytes)?;
            out.set("budget_bytes", budget)?;
            out.set("texture_count", st.textures.len() as u64)?;
            Ok(out)
        })?,
    )?;

    lurek.set("engine", tbl)?;
    Ok(())
}
