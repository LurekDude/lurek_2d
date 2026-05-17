//! `lurek.engine` -- Runtime metadata and diagnostics bindings for version, platform, uptime, FPS, frame counters, resource memory budgets, frame timing profile tables, and configuration reload revision exposed to Lua scripts.

use super::SharedState;
use crate::app::frame_profile::format_frame_profile_line;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Registers `lurek.engine` runtime metadata, timing, memory, and profiling helpers.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- getVersion --
    /// Returns the engine crate version string embedded at build time.
    /// @return | string | Engine version from Cargo package metadata.
    tbl.set(
        "getVersion",
        lua.create_function(|_, ()| Ok(env!("CARGO_PKG_VERSION")))?,
    )?;
    // -- getFrameBudget --
    /// Returns the target frame budget for a 60 FPS update loop.
    /// @return | number | Frame budget in milliseconds.
    tbl.set(
        "getFrameBudget",
        lua.create_function(|_, ()| Ok(1000.0_f64 / 60.0_f64))?,
    )?;
    // -- memoryUsage --
    /// Returns Lua VM memory usage as bytes and rounded kilobytes.
    /// @return | table | Table with `lua_bytes` and `lua_kb` fields.
    /// @field | lua_bytes | integer | Lua bytes.
    /// @field | lua_kb | number | Lua kb.
    tbl.set(
        "memoryUsage",
        lua.create_function(|lua, ()| {
            let bytes = lua.used_memory();
            let out = lua.create_table()?;
            /// Performs the 'lua_bytes' operation.
            out.set("lua_bytes", bytes as u64)?;
            /// Performs the 'lua_kb' operation.
            out.set("lua_kb", (bytes as f64 / 1024.0 * 100.0).round() / 100.0)?;
            Ok(out)
        })?,
    )?;
    // -- platform --
    /// Returns the current desktop operating system name.
    /// @return | string | `windows`, `linux`, `macos`, or `unknown`.
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
    let s = state.clone();
    // -- uptime --
    /// Returns total engine runtime accumulated by the main loop.
    /// @return | number | Uptime in seconds.
    tbl.set(
        "uptime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;
    let s = state.clone();
    // -- fps --
    /// Returns the latest frames-per-second value stored by the runtime.
    /// @return | number | Current FPS estimate.
    tbl.set("fps", lua.create_function(move |_, ()| Ok(s.borrow().fps))?)?;
    let s = state.clone();
    // -- frameCount --
    /// Returns the number of frames counted by the shared runtime clock.
    /// @return | integer | Total frame count.
    tbl.set(
        "frameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;
    // -- isDebug --
    /// Returns whether the engine binary was built with debug assertions.
    /// @return | boolean | True for debug builds, false for release builds.
    tbl.set(
        "isDebug",
        lua.create_function(|_, ()| Ok(cfg!(debug_assertions)))?,
    )?;
    let s = state.clone();
    // -- setResourceBudget --
    /// Sets the resource memory budget used by resource statistics reporting.
    /// @param | budget_bytes | integer | Resource budget in bytes.
    tbl.set(
        "setResourceBudget",
        lua.create_function(move |_, budget_bytes: u64| {
            s.borrow_mut().resource_budget_bytes = budget_bytes;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getResourceStats --
    /// Returns current resource memory usage and object counts by resource kind.
    /// @return | table | Table with byte totals, budget, and texture/font/canvas/shader counts.
    /// @field | texture_bytes | integer | Texture bytes.
    /// @field | font_bytes | integer | Font bytes.
    /// @field | canvas_bytes | integer | Canvas bytes.
    /// @field | shader_bytes | integer | Shader bytes.
    /// @field | total_bytes | integer | Total bytes.
    /// @field | budget_bytes | integer | Budget bytes.
    /// @field | texture_count | integer | Texture count.
    /// @field | font_count | integer | Font count.
    /// @field | canvas_count | integer | Canvas count.
    /// @field | shader_count | integer | Shader count.
    /// @field | app_tick_ms | number | App tick ms.
    /// @field | app_update_ms | number | App update ms.
    /// @field | app_render_ms | number | App render ms.
    /// @field | app_frame_total_ms | number | App frame total ms.
    /// @field | process_physics_ms | number | Process physics ms.
    /// @field | fixed_update_ms | number | Fixed update ms.
    /// @field | process_ms | number | Process ms.
    /// @field | process_late_ms | number | Process late ms.
    /// @field | draw_ms | number | Draw ms.
    /// @field | draw_ui_ms | number | Draw ui ms.
    /// @field | callback_total_ms | number | Callback total ms.
    tbl.set(
        "getResourceStats",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let stats = st.resource_memory_stats();
            let out = lua.create_table()?;
            /// Performs the 'texture_bytes' operation.
            out.set("texture_bytes", stats.texture_bytes)?;
            /// Performs the 'font_bytes' operation.
            out.set("font_bytes", stats.font_bytes)?;
            /// Performs the 'canvas_bytes' operation.
            out.set("canvas_bytes", stats.canvas_bytes)?;
            /// Performs the 'shader_bytes' operation.
            out.set("shader_bytes", stats.shader_bytes)?;
            /// Performs the 'total_bytes' operation.
            out.set("total_bytes", stats.total_bytes)?;
            /// Performs the 'budget_bytes' operation.
            out.set("budget_bytes", stats.budget_bytes)?;
            /// Performs the 'texture_count' operation.
            out.set("texture_count", stats.texture_count)?;
            /// Performs the 'font_count' operation.
            out.set("font_count", stats.font_count)?;
            /// Performs the 'canvas_count' operation.
            out.set("canvas_count", stats.canvas_count)?;
            /// Performs the 'shader_count' operation.
            out.set("shader_count", stats.shader_count)?;
            Ok(out)
        })?,
    )?;
    let s = state.clone();
    // -- getFrameProfile --
    /// Returns the latest frame timing profile split by engine phase.
    /// @return | table | Table of frame phase timings in milliseconds.
    /// @field | app_tick_ms | number | App tick ms.
    /// @field | app_update_ms | number | App update ms.
    /// @field | app_render_ms | number | App render ms.
    /// @field | app_frame_total_ms | number | App frame total ms.
    /// @field | process_physics_ms | number | Process physics ms.
    /// @field | fixed_update_ms | number | Fixed update ms.
    /// @field | process_ms | number | Process ms.
    /// @field | process_late_ms | number | Process late ms.
    /// @field | draw_ms | number | Draw ms.
    /// @field | draw_ui_ms | number | Draw ui ms.
    /// @field | callback_total_ms | number | Callback total ms.
    tbl.set(
        "getFrameProfile",
        lua.create_function(move |lua, ()| {
            let profile = s.borrow().frame_profile;
            let out = lua.create_table()?;
            /// Performs the 'app_tick_ms' operation.
            out.set("app_tick_ms", profile.app_tick_ms)?;
            /// Performs the 'app_update_ms' operation.
            out.set("app_update_ms", profile.app_update_ms)?;
            /// Performs the 'app_render_ms' operation.
            out.set("app_render_ms", profile.app_render_ms)?;
            /// Performs the 'app_frame_total_ms' operation.
            out.set("app_frame_total_ms", profile.app_frame_total_ms)?;
            /// Performs the 'process_physics_ms' operation.
            out.set("process_physics_ms", profile.process_physics_ms)?;
            /// Performs the 'fixed_update_ms' operation.
            out.set("fixed_update_ms", profile.fixed_update_ms)?;
            /// Performs the 'process_ms' operation.
            out.set("process_ms", profile.process_ms)?;
            /// Performs the 'process_late_ms' operation.
            out.set("process_late_ms", profile.process_late_ms)?;
            /// Performs the 'draw_ms' operation.
            out.set("draw_ms", profile.draw_ms)?;
            /// Performs the 'draw_ui_ms' operation.
            out.set("draw_ui_ms", profile.draw_ui_ms)?;
            /// Performs the 'callback_total_ms' operation.
            out.set("callback_total_ms", profile.callback_total_ms)?;
            Ok(out)
        })?,
    )?;
    let s = state.clone();
    // -- getFrameProfileText --
    /// Returns the latest frame timing profile formatted as one text line.
    /// @return | string | Human-readable frame profile summary.
    tbl.set(
        "getFrameProfileText",
        lua.create_function(move |_, ()| {
            let profile = s.borrow().frame_profile;
            Ok(format_frame_profile_line(&profile))
        })?,
    )?;
    let s = state.clone();
    // -- getConfigRevision --
    /// Returns the configuration reload revision counter.
    /// @return | integer | Revision value incremented when runtime config reloads.
    tbl.set(
        "getConfigRevision",
        lua.create_function(move |_, ()| Ok(s.borrow().config_reload_revision))?,
    )?;
    /// Performs the 'engine' operation.
    lurek.set("engine", tbl)?;
    Ok(())
}
