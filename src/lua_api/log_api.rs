//! `lurek.log` - Structured game-level logging API.
//!
//! Exposes convenience logging functions so Lua scripts can emit messages at
//! specific severity levels and query or change the active log level at
//! runtime. Also supports configurable output sinks (file, memory ring buffer)
//! in addition to the default stderr channel, similar to Python's `logging`
//! module handlers.

use std::cell::RefCell;
use std::collections::BTreeMap;
use std::rc::Rc;

use super::SharedState;
use mlua::prelude::*;

use crate::log as log_domain;
use crate::log::sinks::{Sink, SinkLevel, SinkRegistry};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers the `lurek.log` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // Shared sinks registry for this VM - lives as long as the Lua closures do.
    let sinks: Rc<RefCell<SinkRegistry>> = Rc::new(RefCell::new(SinkRegistry::new()));

    // -- debug --
    /// Emits a message at debug severity to the engine log and all registered sinks.
    /// @param | message | string | The text content of the log message
    /// @param | tag | string? | Optional category tag (defaults to "Lua" when omitted)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "debug",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::debug!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Debug, t, &message);
            Ok(())
        })?,
    )?;

    // -- info --
    /// Emits a message at info severity to the engine log and all registered sinks.
    /// @param | message | string | The text content of the log message
    /// @param | tag | string? | Optional category tag (defaults to "Lua" when omitted)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "info",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::info!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Info, t, &message);
            Ok(())
        })?,
    )?;

    // -- warn --
    /// Emits a message at warning severity to the engine log and all registered sinks.
    /// @param | message | string | The text content of the warning message
    /// @param | tag | string? | Optional category tag (defaults to "Lua" when omitted)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "warn",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::warn!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Warn, t, &message);
            Ok(())
        })?,
    )?;

    // -- error --
    /// Emits a message at error severity to the engine log and all registered sinks.
    /// @param | message | string | The text content of the error message
    /// @param | tag | string? | Optional category tag (defaults to "Lua" when omitted)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "error",
        lua.create_function(move |_, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::error!("[{}] {}", t, message);
            dispatch(&s, SinkLevel::Error, t, &message);
            Ok(())
        })?,
    )?;

    // -- print --
    /// Emits a log message at an arbitrary severity level specified as a string.
    /// @param | level | string | Severity name: "debug", "info", "warn", "error", or "trace"
    /// @param | message | string | The text content of the log message
    /// @param | tag | string? | Optional category tag (defaults to "Lua" when omitted)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
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

    // -- setLevel --
    /// Sets the global minimum severity threshold for the engine log backend.
    /// @param | level | string | One of "error", "warn", "info", "debug", "trace", or "off"
    /// @return | nil | No return value.
    tbl.set("setLevel", lua.create_function(|_, level: String| {
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

    // -- getLevel --
    /// Returns the name of the current global minimum severity threshold as a lowercase string (e.g.
    /// @return | string | The active log level name
    tbl.set(
        "getLevel",
        lua.create_function(|_, ()| Ok(log_domain::get_level()))?,
    )?;

    // -- addSink --
    /// Creates and registers a new log output sink from the given configuration table.
    /// @param | config | table | Configuration table with keys: type (string), level (string), path (string, for file/rotating), capacity (integer, for memory), max_bytes (integer, for rotating), keep_files (integer, for rotating)
    /// @return | integer | The unique identifier of the newly created sink
    let s = sinks.clone();
    tbl.set(
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

    // -- removeSink --
    /// Removes a previously registered log sink by its numeric identifier.
    /// @param | id | integer | The sink identifier returned by addSink
    /// @return | boolean | True if the sink existed and was removed
    let s = sinks.clone();
    tbl.set(
        "removeSink",
        lua.create_function(move |_, id: u64| Ok(s.borrow_mut().remove(id)))?,
    )?;

    // -- clearSinks --
    /// Removes every registered log sink, returning the logging system to its default state where messages go only to the engine log backend (stderr).
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "clearSinks",
        lua.create_function(move |_, ()| {
            s.borrow_mut().clear();
            Ok(())
        })?,
    )?;

    // -- listSinks --
    /// Returns an array-like table where each entry is a table describing one registered sink.
    /// @return | table | Array of sink descriptor tables
    let s = sinks.clone();
    tbl.set(
        "listSinks",
        lua.create_function(move |lua, ()| {
            let out = lua.create_table()?;
            for (i, sink) in s.borrow().sinks.iter().enumerate() {
                let st = lua.create_table()?;
                st.set("id", sink.id)?;
                st.set("type", sink.type_name())?;
                st.set("level", sink.min_level.as_str())?;
                if let Some(p) = sink.path() {
                    st.set("path", p)?;
                }
                out.set(i + 1, st)?;
            }
            Ok(out)
        })?,
    )?;

    // -- readMemory --
    /// Reads log entries stored in a memory-type sink.
    /// @param | id | integer | The memory sink identifier returned by addSink
    /// @param | drain | boolean? | When true, clears read entries from the buffer (default false)
    /// @return | table | Array of log entry tables
    let s = sinks.clone();
    tbl.set(
        "readMemory",
        lua.create_function(move |lua, (id, drain): (u64, Option<bool>)| {
            let reg = s.borrow();
            let Some(sink) = reg.get(id) else {
                let out = lua.create_table()?;
                return Ok(LuaValue::Table(out));
            };
            let should_drain = drain.unwrap_or(false);
            match sink.read_memory(should_drain) {
                Some(entries) => {
                    drop(reg);
                    let out = lua.create_table()?;
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
                        out.set(i + 1, et)?;
                    }
                    Ok(LuaValue::Table(out))
                }
                None => {
                    let out = lua.create_table()?;
                    Ok(LuaValue::Table(out))
                }
            }
        })?,
    )?;

    // -- flushFile --
    /// Forces the operating system to write any buffered data for a file-type sink to disk.
    /// @param | id | integer | The file sink identifier returned by addSink
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "flushFile",
        lua.create_function(move |_, id: u64| {
            if let Some(sink) = s.borrow().get(id) {
                sink.flush();
            }
            Ok(())
        })?,
    )?;

    // -- struct --
    /// Emits a structured log message that includes arbitrary key-value metadata alongside the human-readable text.
    /// @param | level | string | Severity name: "debug", "info", "warn", or "error"
    /// @param | message | string | The human-readable log message
    /// @param | fields_table | table | Key-value pairs of metadata (string keys, any values)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
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

    // -- debug_fields --
    /// Emits a structured log message at debug severity with key-value metadata.
    /// @param | message | string | The human-readable log message
    /// @param | fields_table | table | Key-value pairs of metadata (string keys, any values)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "debug_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Debug, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Debug, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // -- info_fields --
    /// Emits a structured log message at info severity with key-value metadata.
    /// @param | message | string | The human-readable log message
    /// @param | fields_table | table | Key-value pairs of metadata (string keys, any values)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "info_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Info, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Info, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // -- warn_fields --
    /// Emits a structured log message at warning severity with key-value metadata.
    /// @param | message | string | The human-readable warning message
    /// @param | fields_table | table | Key-value pairs of metadata (string keys, any values)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "warn_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Warn, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Warn, t, &message, &fields);
            Ok(())
        })?,
    )?;

    // -- error_fields --
    /// Emits a structured log message at error severity with key-value metadata.
    /// @param | message | string | The human-readable error message
    /// @param | fields_table | table | Key-value pairs of metadata (string keys, any values)
    /// @return | nil | No return value.
    let s = sinks.clone();
    tbl.set(
        "error_fields",
        lua.create_function(move |_, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Error, Some(t), &message, &fields);
            dispatch_structured(&s, SinkLevel::Error, t, &message, &fields);
            Ok(())
        })?,
    )?;

    lurek.set("log", tbl)?;
    Ok(())
}
