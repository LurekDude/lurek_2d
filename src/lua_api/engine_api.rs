//! `lurek.runtime` - Runtime engine metadata and introspection.
//!
//! Exposes read-only properties about the running engine: version, target
//! frame budget, memory usage, host platform, and total uptime.

use super::SharedState;
use crate::app::frame_profile::format_frame_profile_line;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Registers the `lurek.runtime.*` namespace.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- getVersion --
    /// Returns the engine version string (from `Cargo.toml`).
    /// @return | string | Engine version string.
    tbl.set(
        "getVersion",
        lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION")))?,
    )?;

    // -- getFrameBudget --
    /// Returns the target frame budget in milliseconds (default: 1000 / 60 ~Â 16.667 ms).
    /// @return | number | Target frame budget in milliseconds.
    tbl.set(
        "getFrameBudget",
        lua.create_function(|_, ()| Ok(1000.0_f64 / 60.0_f64))?,
    )?;

    // -- memoryUsage --
    /// Returns Lua memory usage in bytes and kilobytes.
    /// @return | table | Table with `lua_bytes` and `lua_kb` fields.
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
    /// Returns the host operating system name.
    /// @return | string | One of `windows`, `linux`, `macos`, or `unknown`.
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
    /// @return | number | Total engine uptime in seconds.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "uptime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
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
    // Auto-doc: Lua API binding.
    tbl.set(
        "frameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;

    // -- isDebug --
    /// Returns `true` if the engine was compiled in debug mode.
    /// @return | boolean | Whether debug assertions are enabled.
    tbl.set(
        "isDebug",
        lua.create_function(|_, ()| Ok(cfg!(debug_assertions)))?,
    )?;

    // -- setResourceBudget --
    /// Sets the maximum resident texture memory budget in bytes.
    /// @param | budget_bytes | integer | Maximum texture memory budget in bytes, or 0 for unlimited.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "setResourceBudget",
        lua.create_function(move |_, budget_bytes: u64| {
            s.borrow_mut().resource_budget_bytes = budget_bytes;
            Ok(())
        })?,
    )?;

    // -- getResourceStats --
    /// Returns a table with resident resource memory statistics.
    /// @return | table | Table with per-kind bytes/counts and aggregate totals.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getResourceStats",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let stats = st.resource_memory_stats();
            let out = lua.create_table()?;
            out.set("texture_bytes", stats.texture_bytes)?;
            out.set("font_bytes", stats.font_bytes)?;
            out.set("canvas_bytes", stats.canvas_bytes)?;
            out.set("shader_bytes", stats.shader_bytes)?;
            out.set("total_bytes", stats.total_bytes)?;
            out.set("budget_bytes", stats.budget_bytes)?;
            out.set("texture_count", stats.texture_count)?;
            out.set("font_count", stats.font_count)?;
            out.set("canvas_count", stats.canvas_count)?;
            out.set("shader_count", stats.shader_count)?;
            Ok(out)
        })?,
    )?;

    // -- getFrameProfile --
    /// Returns CPU callback timing for the most recently completed frame.
    /// @return | table | Table with per-callback millisecond timings and `callback_total_ms`.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getFrameProfile",
        lua.create_function(move |lua, ()| {
            let profile = s.borrow().frame_profile;
            let out = lua.create_table()?;
            out.set("app_tick_ms", profile.app_tick_ms)?;
            out.set("app_update_ms", profile.app_update_ms)?;
            out.set("app_render_ms", profile.app_render_ms)?;
            out.set("app_frame_total_ms", profile.app_frame_total_ms)?;
            out.set("process_physics_ms", profile.process_physics_ms)?;
            out.set("fixed_update_ms", profile.fixed_update_ms)?;
            out.set("process_ms", profile.process_ms)?;
            out.set("process_late_ms", profile.process_late_ms)?;
            out.set("draw_ms", profile.draw_ms)?;
            out.set("draw_ui_ms", profile.draw_ui_ms)?;
            out.set("callback_total_ms", profile.callback_total_ms)?;
            Ok(out)
        })?,
    )?;

    // -- getFrameProfileText --
    /// Returns a compact one-line summary of the latest frame timings.
    /// @return | string | Text summary including tick, update, render, and callback timing buckets.
    let s = state.clone();
    tbl.set(
        "getFrameProfileText",
        lua.create_function(move |_, ()| {
            let profile = s.borrow().frame_profile;
            Ok(format_frame_profile_line(&profile))
        })?,
    )?;

    // -- getConfigRevision --
    /// Returns the monotonic config revision counter.
    /// @return | integer | Increments after each successful hot-reload of `conf.toml`.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getConfigRevision",
        lua.create_function(move |_, ()| Ok(s.borrow().config_reload_revision))?,
    )?;

    lurek.set("engine", tbl)?;
    Ok(())
}
