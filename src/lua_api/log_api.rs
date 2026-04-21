//! Structured game-level logging API (`lurek.log.*`).
//!
//! Exposes convenience logging functions so Lua scripts can emit messages at
//! specific severity levels and query or change the active log level at
//! runtime. Also supports configurable output sinks (file, memory ring buffer)
//! in addition to the default stderr channel, similar to Python's `logging`
//! module handlers.

use std::cell::RefCell;
use std::collections::BTreeMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::log as log_domain;
use crate::log::sinks::{Sink, SinkLevel, SinkRegistry};

// Helper: dispatch a plain message to the given sinks registry.
fn dispatch(sinks: &Rc<RefCell<SinkRegistry>>, level: SinkLevel, tag: &str, message: &str) {
    sinks.borrow().dispatch(level, tag, message);
}

// Helper: dispatch a structured message with key-value fields to sinks.
fn dispatch_structured(
    sinks: &Rc<RefCell<SinkRegistry>>,
    level: SinkLevel,
    tag: &str,
    message: &str,
    fields: &BTreeMap<String, String>,
) {
    sinks
        .borrow()
        .dispatch_structured(level, tag, message, fields);
}

// Helper: convert a Lua table of mixed values to a BTreeMap<String, String>.
fn lua_table_to_fields(tbl: LuaTable) -> LuaResult<BTreeMap<String, String>> {
    let mut fields = BTreeMap::new();
    for pair in tbl.pairs::<String, LuaValue>() {
        let (k, v) = pair?;
        let vs = match v {
            LuaValue::String(s) => s.to_str().unwrap_or("").to_string(),
            LuaValue::Integer(i) => i.to_string(),
            LuaValue::Number(n) => format!("{n}"),
            LuaValue::Boolean(b) => b.to_string(),
            LuaValue::Nil => "nil".to_string(),
            _ => "(complex)".to_string(),
        };
        fields.insert(k, vs);
    }
    Ok(fields)
}

/// Registers the `lurek.log.*` namespace into the shared `lurek` table.
///
/// @param lua : &Lua
/// @param lurek : &LuaTable
///
pub fn register(lua: &Lua, lurek: &LuaTable) -> LuaResult<()> {
    let log_table = lua.create_table()?;

    // Shared sinks registry for this VM â€“ lives as long as the Lua closures do.
    let sinks: Rc<RefCell<SinkRegistry>> = Rc::new(RefCell::new(SinkRegistry::new()));

    // â”€â”€ debug â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits a debug-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "debug",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::debug!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Debug, t, &message);
            Ok(())
        })?,
    )?;

    // â”€â”€ info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits an info-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "info",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::info!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Info, t, &message);
            Ok(())
        })?,
    )?;

    // â”€â”€ warn â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits a warn-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "warn",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::warn!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Warn, t, &message);
            Ok(())
        })?,
    )?;

    // â”€â”€ error â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits an error-severity log message. Also dispatches to configured sinks.
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "error",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::error!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Error, t, &message);
            Ok(())
        })?,
    )?;

    // â”€â”€ print â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits a log message at the specified level. Also dispatches to sinks.
    /// @param level : string
    /// @param message : string
    /// @param tag : string?
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "print",
        lua.create_function(
            move |_, (level, message, tag): (String, String, Option<String>)| {
                let t = tag.as_deref().unwrap_or("Lua");
                let sink_level = match level.to_lowercase().as_str() {
                    "error" => {
                        log::error!("[{}] {}", t, message);
                        SinkLevel::Error
                    }
                    "warn" | "warning" => {
                        log::warn!("[{}] {}", t, message);
                        SinkLevel::Warn
                    }
                    "debug" => {
                        log::debug!("[{}] {}", t, message);
                        SinkLevel::Debug
                    }
                    "trace" => {
                        log::trace!("[{}] {}", t, message);
                        SinkLevel::Debug
                    }
                    _ => {
                        log::info!("[{}] {}", t, message);
                        SinkLevel::Info
                    }
                };
                dispatch(&s, sink_level, t, &message);
                Ok(())
            },
        )?,
    )?;

    // â”€â”€ setLevel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Sets the minimum severity level for the default log channel.
    /// Accepted values: "error", "warn", "info", "debug", "trace", "off".
    /// Returns a LuaError when an unrecognised level is supplied.
    /// @param level : string
    /// @return nil
    log_table.set("setLevel", lua.create_function(|_, level: String| {
        match level.to_lowercase().as_str() {
            "error" | "warn" | "warning" | "info" | "debug" | "trace" | "off" | "none" => {
                log_domain::set_level(&level);
                Ok(())
            }
            _ => Err(LuaError::RuntimeError(format!(
                "lurek.log.setLevel: unknown level '{level}'; expected error/warn/info/debug/trace/off"
            ))),
        }
    })?)?;

    // â”€â”€ getLevel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Returns the name of the currently active minimum log level.
    /// @return string
    log_table.set(
        "getLevel",
        lua.create_function(|_, ()| Ok(log_domain::get_level()))?,
    )?;

    // â”€â”€ addSink â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Registers a new output sink. Returns its numeric id.
    ///
    /// Config fields:
    ///   type       : "file" | "memory" | "rotating"
    ///   path       : string   (required for type="file" or "rotating")
    ///   capacity   : integer  (for type="memory", default 1000)
    ///   level      : string   (min level, default "debug")
    ///   max_bytes  : integer  (for type="rotating", default 10_485_760 = 10 MiB)
    ///   keep_files : integer  (for type="rotating", default 3)
    ///
    /// @param config : table
    let s = sinks.clone();
    /// @return integer
    log_table.set(
        "addSink",
        lua.create_function(move |_, config: LuaTable| {
            let kind: String = config.get("type").unwrap_or_else(|_| "memory".to_string());
            let level_str: String = config.get("level").unwrap_or_else(|_| "debug".to_string());
            let min_level = SinkLevel::from_str(&level_str);
            let id = match kind.as_str() {
                "file" => {
                    let path: String = config.get("path").map_err(|_| {
                        LuaError::external("addSink: path required for type='file'")
                    })?;
                    let sink = Sink::file(0, &path, min_level).map_err(LuaError::external)?;
                    s.borrow_mut().add(sink)
                }
                "memory" => {
                    let cap: usize = config.get("capacity").unwrap_or(1000);
                    s.borrow_mut().add(Sink::memory(0, cap, min_level))
                }
                "rotating" => {
                    let path: String = config.get("path").map_err(|_| {
                        LuaError::external("addSink: path required for type='rotating'")
                    })?;
                    let max_bytes: u64 = config.get("max_bytes").unwrap_or(0);
                    let keep_files: usize = config.get("keep_files").unwrap_or(0);
                    let sink = Sink::rotating_file(0, &path, min_level, max_bytes, keep_files)
                        .map_err(LuaError::external)?;
                    s.borrow_mut().add(sink)
                }
                _ => {
                    return Err(LuaError::external(format!(
                        "addSink: unknown type '{kind}'"
                    )))
                }
            };
            Ok(id)
        })?,
    )?;

    // â”€â”€ removeSink â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Removes a sink by id. Returns true if one was removed.
    /// @param id : integer
    let s = sinks.clone();
    /// @return boolean
    log_table.set(
        "removeSink",
        lua.create_function(move |_, id: u64| Ok(s.borrow_mut().remove(id)))?,
    )?;

    // â”€â”€ clearSinks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Removes all registered sinks (the default stderr channel is unaffected).
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "clearSinks",
        lua.create_function(move |_, ()| {
            s.borrow_mut().clear();
            Ok(())
        })?,
    )?;

    // â”€â”€ listSinks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Returns a table describing all registered sinks.
    let s = sinks.clone();
    /// @return table
    log_table.set(
        "listSinks",
        lua.create_function(move |lua, ()| {
            let tbl = lua.create_table()?;
            for (i, sink) in s.borrow().sinks.iter().enumerate() {
                let st = lua.create_table()?;
                st.set("id", sink.id)?;
                st.set("type", sink.type_name())?;
                st.set("level", sink.min_level.as_str())?;
                if let Some(p) = sink.path() {
                    st.set("path", p)?;
                }
                tbl.set(i + 1, st)?;
            }
            Ok(tbl)
        })?,
    )?;

    // â”€â”€ readMemory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Reads entries from a memory sink. If drain=true the buffer is cleared.
    /// Returns an array of {level, tag, message} tables. Returns nil if id not found or wrong type.
    /// @param id : integer
    /// @param drain : boolean?
    let s = sinks.clone();
    /// @return table?
    log_table.set(
        "readMemory",
        lua.create_function(move |lua, (id, drain): (u64, Option<bool>)| {
            let reg = s.borrow();
            let Some(sink) = reg.get(id) else {
                return Ok(LuaValue::Nil);
            };
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
                        if let Some(ref fields) = entry.fields {
                            let ft = lua.create_table()?;
                            for (k, v) in fields {
                                ft.set(k.as_str(), v.as_str())?;
                            }
                            et.set("fields", ft)?;
                        }
                        tbl.set(i + 1, et)?;
                    }
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        })?,
    )?;

    // â”€â”€ flushFile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Flushes the OS write buffer for a file sink.
    /// @param id : integer
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "flushFile",
        lua.create_function(move |_, id: u64| {
            if let Some(sink) = s.borrow().get(id) {
                sink.flush();
            }
            Ok(())
        })?,
    )?;

    // â”€â”€ struct â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits a structured log message with key-value fields.
    /// `fields_table` values are converted to strings (string/number/bool/nil supported).
    /// @param level : string
    /// @param message : string
    /// @param fields_table : table
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "struct",
        lua.create_function(
            move |_, (level_str, message, fields_tbl): (String, String, LuaTable)| {
                let t = "Lua";
                let fields = lua_table_to_fields(fields_tbl)?;
                let sink_level = SinkLevel::from_str(&level_str);
                let log_level = match sink_level {
                    SinkLevel::Error => ::log::Level::Error,
                    SinkLevel::Warn => ::log::Level::Warn,
                    SinkLevel::Info => ::log::Level::Info,
                    SinkLevel::Debug => ::log::Level::Debug,
                };
                log_domain::log_structured(log_level, Some(t), &message, &fields);
                dispatch_structured(&s, sink_level, t, &message, &fields);
                Ok(())
            },
        )?,
    )?;

    // â”€â”€ debug_fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits a debug structured log message. Shorthand for `struct("debug", ...)`.
    /// @param message : string
    /// @param fields_table : table
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "debug_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Debug, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Debug, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // â”€â”€ info_fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits an info structured log message. Shorthand for `struct("info", ...)`.
    /// @param message : string
    /// @param fields_table : table
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "info_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Info, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Info, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // â”€â”€ warn_fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits a warn structured log message. Shorthand for `struct("warn", ...)`.
    /// @param message : string
    /// @param fields_table : table
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "warn_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Warn, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Warn, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // â”€â”€ error_fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Emits an error structured log message. Shorthand for `struct("error", ...)`.
    /// @param message : string
    /// @param fields_table : table
    let s = sinks.clone();
    /// @return nil
    log_table.set(
        "error_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Error, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Error, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // -- log namespace --
    lurek.set("log", log_table)?;
    Ok(())
}
