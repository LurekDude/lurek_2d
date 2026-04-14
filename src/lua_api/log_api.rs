//! Structured game-level logging API (`lurek.log.*`).
//!
//! Exposes convenience logging functions so Lua scripts can emit messages at
//! specific severity levels and query or change the active log level at
//! runtime. Also supports configurable output sinks (file, memory ring buffer)
//! in addition to the default stderr channel, similar to Python's `logging`
//! module handlers.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::log as log_domain;
use crate::log::sinks::{Sink, SinkLevel, SinkRegistry};

// Helper: dispatch a message to the given sinks registry.
fn dispatch(sinks: &Rc<RefCell<SinkRegistry>>, level: SinkLevel, tag: &str, message: &str) {
    sinks.borrow().dispatch(level, tag, message);
}

/// Registers the `lurek.log.*` namespace into the shared `luna` table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let log_table = lua.create_table()?;

    // Shared sinks registry for this VM – lives as long as the Lua closures do.
    let sinks: Rc<RefCell<SinkRegistry>> = Rc::new(RefCell::new(SinkRegistry::new()));

    // ── debug ────────────────────────────────────────────────────────────
    /// Emits a debug-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set("debug", lua.create_function(move |_, (message, tag): (String, Option<String>)| {
        let t = tag.as_deref().unwrap_or("Lua");
        log::debug!("[{}] {}", t, message);
        dispatch(&s, SinkLevel::Debug, t, &message);
        Ok(())
    })?)?;

    // ── info ─────────────────────────────────────────────────────────────
    /// Emits an info-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set("info", lua.create_function(move |_, (message, tag): (String, Option<String>)| {
        let t = tag.as_deref().unwrap_or("Lua");
        log::info!("[{}] {}", t, message);
        dispatch(&s, SinkLevel::Info, t, &message);
        Ok(())
    })?)?;

    // ── warn ─────────────────────────────────────────────────────────────
    /// Emits a warn-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set("warn", lua.create_function(move |_, (message, tag): (String, Option<String>)| {
        let t = tag.as_deref().unwrap_or("Lua");
        log::warn!("[{}] {}", t, message);
        dispatch(&s, SinkLevel::Warn, t, &message);
        Ok(())
    })?)?;

    // ── error ────────────────────────────────────────────────────────────
    /// Emits an error-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set("error", lua.create_function(move |_, (message, tag): (String, Option<String>)| {
        let t = tag.as_deref().unwrap_or("Lua");
        log::error!("[{}] {}", t, message);
        dispatch(&s, SinkLevel::Error, t, &message);
        Ok(())
    })?)?;

    // ── print ────────────────────────────────────────────────────────────
    /// Emits a log message at the specified level. Also dispatches to sinks.
    /// @param level : string
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set("print", lua.create_function(move |_, (level, message, tag): (String, String, Option<String>)| {
        let t = tag.as_deref().unwrap_or("Lua");
        let sink_level = match level.to_lowercase().as_str() {
            "error" => { log::error!("[{}] {}", t, message); SinkLevel::Error }
            "warn" | "warning" => { log::warn!("[{}] {}", t, message); SinkLevel::Warn }
            "debug" => { log::debug!("[{}] {}", t, message); SinkLevel::Debug }
            "trace" => { log::trace!("[{}] {}", t, message); SinkLevel::Debug }
            _ => { log::info!("[{}] {}", t, message); SinkLevel::Info }
        };
        dispatch(&s, sink_level, t, &message);
        Ok(())
    })?)?;

    // ── setLevel ────────────────────────────────────────────────────────
    /// Sets the minimum severity level for the default log channel.
    /// @param level : string
    /// @return nil
    log_table.set("setLevel", lua.create_function(|_, level: String| {
        log_domain::set_level(&level);
        Ok(())
    })?)?;

    // ── getLevel ────────────────────────────────────────────────────────
    /// Returns the name of the currently active minimum log level.
    /// @return string
    log_table.set("getLevel", lua.create_function(|_, ()| Ok(log_domain::get_level()))?)?;

    // ── addSink ──────────────────────────────────────────────────────────
    /// Registers a new output sink. Returns its numeric id.
    ///
    /// Config fields:
    ///   type      : "file" | "memory"
    ///   path      : string   (required for type="file")
    ///   capacity  : integer  (for type="memory", default 1000)
    ///   level     : string   (min level, default "debug")
    ///
    /// @param config : table
    let s = sinks.clone();
    /// @return integer
    log_table.set("addSink", lua.create_function(move |_, config: LuaTable| {
        let kind: String = config.get("type").unwrap_or_else(|_| "memory".to_string());
        let level_str: String = config.get("level").unwrap_or_else(|_| "debug".to_string());
        let min_level = SinkLevel::from_str(&level_str);
        let id = match kind.as_str() {
            "file" => {
                let path: String = config.get("path")
                    .map_err(|_| LuaError::external("addSink: path required for type='file'"))?;
                let sink = Sink::file(0, &path, min_level).map_err(LuaError::external)?;
                s.borrow_mut().add(sink)
            }
            "memory" => {
                let cap: usize = config.get("capacity").unwrap_or(1000);
                s.borrow_mut().add(Sink::memory(0, cap, min_level))
            }
            _ => return Err(LuaError::external(format!("addSink: unknown type '{kind}'"))),
        };
        Ok(id)
    })?)?;

    // ── removeSink ───────────────────────────────────────────────────────
    /// Removes a sink by id. Returns true if one was removed.
    /// @param id : integer
    let s = sinks.clone();
    /// @return boolean
    log_table.set("removeSink", lua.create_function(move |_, id: u64| {
        Ok(s.borrow_mut().remove(id))
    })?)?;

    // ── clearSinks ───────────────────────────────────────────────────────
    /// Removes all registered sinks (the default stderr channel is unaffected).
    let s = sinks.clone();
    /// @return nil
    log_table.set("clearSinks", lua.create_function(move |_, ()| {
        s.borrow_mut().clear();
        Ok(())
    })?)?;

    // ── listSinks ────────────────────────────────────────────────────────
    /// Returns a table describing all registered sinks.
    let s = sinks.clone();
    /// @return table
    log_table.set("listSinks", lua.create_function(move |lua, ()| {
        let tbl = lua.create_table()?;
        for (i, sink) in s.borrow().sinks.iter().enumerate() {
            let st = lua.create_table()?;
            st.set("id", sink.id)?;
            st.set("type", sink.type_name())?;
            st.set("level", sink.min_level.as_str())?;
            if let Some(p) = sink.path() { st.set("path", p)?; }
            tbl.set(i + 1, st)?;
        }
        Ok(tbl)
    })?)?;

    // ── readMemory ───────────────────────────────────────────────────────
    /// Reads entries from a memory sink. If drain=true the buffer is cleared.
    /// Returns an array of {level, tag, message} tables. Returns nil if id not found or wrong type.
    /// @param id : integer
    /// @param drain : boolean?
    let s = sinks.clone();
    /// @return table?
    log_table.set("readMemory", lua.create_function(move |lua, (id, drain): (u64, Option<bool>)| {
        let reg = s.borrow();
        let Some(sink) = reg.get(id) else { return Ok(LuaValue::Nil) };
        let should_drain = drain.unwrap_or(false);
        match sink.read_memory(should_drain) {
            Some(entries) => {
                drop(reg);
                let tbl = lua.create_table()?;
                for (i, entry) in entries.iter().enumerate() {
                    let et = lua.create_table()?;
                    et.set("level", entry.level.as_str())?;
                    et.set("tag", entry.tag.as_str())?;
                    et.set("message", entry.message.as_str())?;
                    tbl.set(i + 1, et)?;
                }
                Ok(LuaValue::Table(tbl))
            }
            None => Ok(LuaValue::Nil),
        }
    })?)?;

    // ── flushFile ────────────────────────────────────────────────────────
    /// Flushes the OS write buffer for a file sink.
    /// @param id : integer
    let s = sinks.clone();
    /// @return nil
    log_table.set("flushFile", lua.create_function(move |_, id: u64| {
        if let Some(sink) = s.borrow().get(id) {
            sink.flush();
        }
        Ok(())
    })?)?;

    // -- log namespace --
    luna.set("log", log_table)?;
    Ok(())
}
