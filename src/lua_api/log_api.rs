//! `lurek.log` -- Logging bindings for severity helpers, global level control, memory/file/rotating/callback sinks, sink listing and flushing, memory reads, structured field logs, tag filters, and Lua callback dispatch.

use super::SharedState;
use crate::log as log_domain;
use crate::log::sinks::{Sink, SinkKind, SinkLevel, SinkRegistry};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::BTreeMap;
use std::rc::Rc;
/// Dispatches a plain log record to registered sinks and Lua callback sinks.
fn dispatch(
    lua: &Lua,
    sinks: &Rc<RefCell<SinkRegistry>>,
    callback_keys: &Rc<RefCell<BTreeMap<u64, LuaRegistryKey>>>,
    level: SinkLevel,
    tag: &str,
    message: &str,
) {
    let reg = sinks.borrow();
    for sink in &reg.sinks {
        match &sink.kind {
            SinkKind::Callback { .. } => {
                if let Some(key) = callback_keys.borrow().get(&sink.id) {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        if let Ok(record_table) = lua.create_table() {
                            /// Performs the 'level' operation.
                            /// @return | nil | No value is returned.
                            let _ = record_table.set("level", level.as_str().to_lowercase());
                            /// Performs the 'tag' operation.
                            /// @return | nil | No value is returned.
                            let _ = record_table.set("tag", tag);
                            /// Performs the 'message' operation.
                            /// @return | nil | No value is returned.
                            let _ = record_table.set("message", message);
                            let _ = func.call::<LuaTable, ()>(record_table);
                        }
                    }
                }
            }
            _ => sink.write(level, tag, message),
        }
    }
}
/// Dispatches a structured log record with fields to registered sinks and Lua callback sinks.
fn dispatch_structured(
    lua: &Lua,
    sinks: &Rc<RefCell<SinkRegistry>>,
    callback_keys: &Rc<RefCell<BTreeMap<u64, LuaRegistryKey>>>,
    level: SinkLevel,
    tag: &str,
    message: &str,
    fields: &BTreeMap<String, String>,
) {
    let reg = sinks.borrow();
    for sink in &reg.sinks {
        match &sink.kind {
            SinkKind::Callback { .. } => {
                if let Some(key) = callback_keys.borrow().get(&sink.id) {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        if let Ok(record_table) = lua.create_table() {
                            /// Performs the 'level' operation.
                            /// @return | nil | No value is returned.
                            let _ = record_table.set("level", level.as_str().to_lowercase());
                            /// Performs the 'tag' operation.
                            /// @return | nil | No value is returned.
                            let _ = record_table.set("tag", tag);
                            /// Performs the 'message' operation.
                            /// @return | nil | No value is returned.
                            let _ = record_table.set("message", message);
                            if !fields.is_empty() {
                                if let Ok(fields_table) = lua.create_table() {
                                    for (key, value) in fields {
                                        let _ = fields_table.set(key.as_str(), value.clone());
                                    }
                                    /// Performs the 'fields' operation.
                                    /// @return | nil | No value is returned.
                                    let _ = record_table.set("fields", fields_table);
                                }
                            }
                            let _ = func.call::<LuaTable, ()>(record_table);
                        }
                    }
                }
            }
            _ => sink.write_structured(level, tag, message, fields),
        }
    }
}
/// Converts a Lua table of scalar fields into string field values.
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
/// Converts nil, string, or array table tag config into optional tag filters.
fn lua_table_to_tags(value: LuaValue) -> LuaResult<Option<Vec<String>>> {
    match value {
        LuaValue::Nil => Ok(None),
        LuaValue::String(s) => Ok(Some(vec![s.to_str()?.to_string()])),
        LuaValue::Table(tbl) => {
            let mut tags = Vec::new();
            for entry in tbl.sequence_values::<LuaValue>() {
                match entry? {
                    LuaValue::String(s) => tags.push(s.to_str()?.to_string()),
                    LuaValue::Nil => {}
                    other => {
                        return Err(LuaError::external(format!(
                            "addSink: tags must contain strings, got {:?}",
                            other.type_name()
                        )))
                    }
                }
            }
            Ok(Some(tags))
        }
        other => Err(LuaError::external(format!(
            "addSink: tags must be a string or an array of strings, got {:?}",
            other.type_name()
        ))),
    }
}
/// Reads a boolean config field with a default value.
fn config_bool(config: &LuaTable, key: &str, default: bool) -> bool {
    config
        .get::<_, Option<bool>>(key)
        .ok()
        .flatten()
        .unwrap_or(default)
}
/// Reads a string config field with a default value.
fn config_string(config: &LuaTable, key: &str, default: &str) -> String {
    config
        .get::<_, Option<String>>(key)
        .ok()
        .flatten()
        .unwrap_or_else(|| default.to_string())
}
/// Registers `lurek.log` severity helpers, sink management, and structured logging functions.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let sinks: Rc<RefCell<SinkRegistry>> = Rc::new(RefCell::new(SinkRegistry::new()));
    let callback_keys: Rc<RefCell<BTreeMap<u64, LuaRegistryKey>>> =
        Rc::new(RefCell::new(BTreeMap::new()));
    let callback_keys_all = callback_keys.clone();
    let s = sinks.clone();
    let callback_keys_print = callback_keys_all.clone();
    // -- debug --
    /// Logs a debug message with an optional tag.
    /// @param | message | string | Message text.
    /// @param | tag | string? | Log tag shown in the sink output (default `"Lua"`).
    /// @return | nil | No value is returned.
    tbl.set(
        "debug",
        lua.create_function(move |lua, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::debug!("[{}] {}", t, message);
            dispatch(lua, &s, &callback_keys, SinkLevel::Debug, t, &message);
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- info --
    /// Logs an info message with an optional tag.
    /// @param | message | string | Message text.
    /// @param | tag | string? | Log tag shown in the sink output (default `"Lua"`).
    /// @return | nil | No value is returned.
    tbl.set(
        "info",
        lua.create_function(move |lua, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::info!("[{}] {}", t, message);
            dispatch(lua, &s, &callback_keys, SinkLevel::Info, t, &message);
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- warn --
    /// Logs a warning message with an optional tag.
    /// @param | message | string | Message text.
    /// @param | tag | string? | Log tag shown in the sink output (default `"Lua"`).
    /// @return | nil | No value is returned.
    tbl.set(
        "warn",
        lua.create_function(move |lua, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::warn!("[{}] {}", t, message);
            dispatch(lua, &s, &callback_keys, SinkLevel::Warn, t, &message);
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- error --
    /// Logs an error message with an optional tag.
    /// @param | message | string | Message text.
    /// @param | tag | string? | Log tag shown in the sink output (default `"Lua"`).
    /// @return | nil | No value is returned.
    tbl.set(
        "error",
        lua.create_function(move |lua, (message, tag): (String, Option<String>)| {
            let t = tag.as_deref().unwrap_or("Lua");
            log::error!("[{}] {}", t, message);
            dispatch(lua, &s, &callback_keys, SinkLevel::Error, t, &message);
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- print --
    /// Logs a message at a runtime-selected level with an optional tag.
    /// @param | level | string | Log level string.
    /// @param | message | string | Message text.
    /// @param | tag? | string | Optional tag, defaulting to `Lua`.
    /// @return | nil | No value is returned.
    tbl.set(
        "print",
        lua.create_function(
            move |lua, (level, message, tag): (String, String, Option<String>)| {
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
                        SinkLevel::Trace
                    }
                    _ => {
                        log::info!("[{}] {}", t, message);
                        SinkLevel::Info
                    }
                };
                dispatch(lua, &s, &callback_keys_print, sink_level, t, &message);
                Ok(())
            },
        )?,
    )?;
    // -- setLevel --
    /// Sets the global log level. This function is exposed to Lua scripts.
    /// @param | level | string | Level `error`, `warn`, `info`, `debug`, `trace`, `off`, or `none`.
    /// @return | nil | No value is returned.
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
    /// Returns the global log level string.
    /// @return | string | Current global log level.
    tbl.set(
        "getLevel",
        lua.create_function(|_, ()| Ok(log_domain::get_level()))?,
    )?;
    let s = sinks.clone();
    let callback_keys_for_add = callback_keys_all.clone();
    // -- addSink --
    /// Adds a memory, file, rotating, or callback sink from a config table.
    /// @param | config | table | Sink config with `type`, `level`, format, tag, path, capacity, or callback fields.
    /// @return | integer | Sink id.
    tbl.set(
        "addSink",
        lua.create_function(move |lua, config: LuaTable| {
            let kind: String = config.get("type").unwrap_or_else(|_| "memory".to_string());
            let level_str: String = config.get("level").unwrap_or_else(|_| "debug".to_string());
            let min_level = level_str.parse::<SinkLevel>().unwrap_or(SinkLevel::Debug);
            let format = config_string(&config, "format", "plain");
            let timestamp = config_bool(&config, "timestamp", false);
            let use_color = config_bool(&config, "ansi", config_bool(&config, "color", false));
            let tags = match config.get::<_, LuaValue>("tags") {
                Ok(value) => lua_table_to_tags(value)?,
                Err(_) => None,
            };
            let id = match kind.as_str() {
                "file" => {
                    let path: String = config.get("path").map_err(|_| {
                        LuaError::external("addSink: path required for type='file'")
                    })?;
                    let sink = Sink::file(0, &path, min_level).map_err(LuaError::external)?;
                    let mut sink = sink;
                    sink.configure_output(&format, timestamp, use_color, tags.clone());
                    s.borrow_mut().add(sink)
                }
                "memory" => {
                    let cap: usize = config.get("capacity").unwrap_or(1000);
                    let mut sink = Sink::memory(0, cap, min_level);
                    sink.configure_output(&format, timestamp, use_color, tags.clone());
                    s.borrow_mut().add(sink)
                }
                "rotating" => {
                    let path: String = config.get("path").map_err(|_| {
                        LuaError::external("addSink: path required for type='rotating'")
                    })?;
                    let max_bytes: u64 = config.get("max_bytes").unwrap_or(0);
                    let keep_files: usize = config.get("keep_files").unwrap_or(0);
                    let sink = Sink::rotating_file(0, &path, min_level, max_bytes, keep_files)
                        .map_err(LuaError::external)?;
                    let mut sink = sink;
                    sink.configure_output(&format, timestamp, use_color, tags.clone());
                    s.borrow_mut().add(sink)
                }
                "callback" => {
                    let callback: LuaFunction = config.get("callback").map_err(|_| {
                        LuaError::external("addSink: callback required for type='callback'")
                    })?;
                    let callback_key = lua.create_registry_value(callback)?;
                    let key_store = callback_keys_for_add.clone();
                    let mut sink = Sink::callback(0, min_level, 0);
                    sink.configure_output(&format, timestamp, use_color, tags.clone());
                    let id = s.borrow_mut().add(sink);
                    key_store.borrow_mut().insert(id, callback_key);
                    return Ok(id);
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
    let s = sinks.clone();
    let callback_keys_for_remove = callback_keys.clone();
    // -- removeSink --
    /// Removes a sink by id and releases any callback registry key.
    /// @param | id | integer | Sink id.
    /// @return | boolean | True when a sink was removed.
    tbl.set(
        "removeSink",
        lua.create_function(move |lua, id: u64| {
            let removed = s.borrow_mut().remove(id);
            if removed {
                if let Some(key) = callback_keys_for_remove.borrow_mut().remove(&id) {
                    let _ = lua.remove_registry_value(key);
                }
            }
            Ok(removed)
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys_for_clear = callback_keys.clone();
    // -- clearSinks --
    /// Removes all sinks and releases callback registry keys.
    /// @return | nil | No value is returned.
    tbl.set(
        "clearSinks",
        lua.create_function(move |lua, ()| {
            s.borrow_mut().clear();
            for (_, key) in std::mem::take(&mut *callback_keys_for_clear.borrow_mut()) {
                let _ = lua.remove_registry_value(key);
            }
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    // -- listSinks --
    /// Returns metadata for all registered sinks.
    /// @return | table | Array table of sink records with id, type, level, and optional path.
    tbl.set(
        "listSinks",
        lua.create_function(move |lua, ()| {
            let out = lua.create_table()?;
            for (i, sink) in s.borrow().sinks.iter().enumerate() {
                let st = lua.create_table()?;
                /// Performs the 'id' operation.
                /// @return | nil | No value is returned.
                st.set("id", sink.id)?;
                /// Performs the 'type' operation.
                /// @return | nil | No value is returned.
                st.set("type", sink.type_name())?;
                /// Performs the 'level' operation.
                /// @return | nil | No value is returned.
                st.set("level", sink.min_level.as_str())?;
                if let Some(p) = sink.path() {
                    /// Performs the 'path' operation.
                    /// @return | nil | No value is returned.
                    st.set("path", p)?;
                }
                out.set(i + 1, st)?;
            }
            Ok(out)
        })?,
    )?;
    let s = sinks.clone();
    // -- readMemory --
    /// Reads entries from a memory sink and optionally drains them.
    /// @param | id | integer | Memory sink id.
    /// @param | drain? | boolean | Optional drain flag, defaulting to false.
    /// @return | table | Array table of memory log entries.
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
                        /// Performs the 'level' operation.
                        /// @return | nil | No value is returned.
                        et.set("level", entry.level.as_str())?;
                        /// Performs the 'tag' operation.
                        /// @return | nil | No value is returned.
                        et.set("tag", entry.tag.as_str())?;
                        /// Performs the 'message' operation.
                        /// @return | nil | No value is returned.
                        et.set("message", entry.message.as_str())?;
                        if let Some(ref fields) = entry.fields {
                            let ft = lua.create_table()?;
                            for (k, v) in fields {
                                ft.set(k.as_str(), v.as_str())?;
                            }
                            /// Performs the 'fields' operation.
                            /// @return | nil | No value is returned.
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
    let s = sinks.clone();
    // -- flushFile --
    /// Flushes a file-backed sink by id when it exists.
    /// @param | id | integer | Sink id.
    /// @return | nil | No value is returned.
    tbl.set(
        "flushFile",
        lua.create_function(move |_lua, id: u64| {
            if let Some(sink) = s.borrow().get(id) {
                sink.flush();
            }
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- struct --
    /// Logs a structured message at a runtime-selected level.
    /// @param | level_str | string | Log level string.
    /// @param | message | string | Message text.
    /// @param | fields_tbl | table | Scalar field table converted to strings.
    /// @return | nil | No value is returned.
    tbl.set(
        "struct",
        lua.create_function(
            move |lua, (level_str, message, fields_tbl): (String, String, LuaTable)| {
                let t = "Lua";
                let fields = lua_table_to_fields(fields_tbl)?;
                let sink_level = level_str.parse::<SinkLevel>().unwrap_or(SinkLevel::Debug);
                let log_level = match sink_level {
                    SinkLevel::Error => ::log::Level::Error,
                    SinkLevel::Warn => ::log::Level::Warn,
                    SinkLevel::Info => ::log::Level::Info,
                    SinkLevel::Debug => ::log::Level::Debug,
                    SinkLevel::Trace => ::log::Level::Trace,
                };
                log_domain::log_structured(log_level, Some(t), &message, &fields);
                dispatch_structured(lua, &s, &callback_keys, sink_level, t, &message, &fields);
                Ok(())
            },
        )?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- debug_fields --
    /// Logs a debug message with structured fields.
    /// @param | message | string | Message text.
    /// @param | fields_tbl | table | Scalar field table converted to strings.
    /// @return | nil | No value is returned.
    tbl.set(
        "debug_fields",
        lua.create_function(move |lua, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Debug, Some(t), &message, &fields);
            dispatch_structured(
                lua,
                &s,
                &callback_keys,
                SinkLevel::Debug,
                t,
                &message,
                &fields,
            );
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- info_fields --
    /// Logs an info message with structured fields.
    /// @param | message | string | Message text.
    /// @param | fields_tbl | table | Scalar field table converted to strings.
    /// @return | nil | No value is returned.
    tbl.set(
        "info_fields",
        lua.create_function(move |lua, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Info, Some(t), &message, &fields);
            dispatch_structured(
                lua,
                &s,
                &callback_keys,
                SinkLevel::Info,
                t,
                &message,
                &fields,
            );
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- warn_fields --
    /// Logs a warning message with structured fields.
    /// @param | message | string | Message text.
    /// @param | fields_tbl | table | Scalar field table converted to strings.
    /// @return | nil | No value is returned.
    tbl.set(
        "warn_fields",
        lua.create_function(move |lua, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Warn, Some(t), &message, &fields);
            dispatch_structured(
                lua,
                &s,
                &callback_keys,
                SinkLevel::Warn,
                t,
                &message,
                &fields,
            );
            Ok(())
        })?,
    )?;
    let s = sinks.clone();
    let callback_keys = callback_keys_all.clone();
    // -- error_fields --
    /// Logs an error message with structured fields.
    /// @param | message | string | Message text.
    /// @param | fields_tbl | table | Scalar field table converted to strings.
    /// @return | nil | No value is returned.
    tbl.set(
        "error_fields",
        lua.create_function(move |lua, (message, fields_tbl): (String, LuaTable)| {
            let t = "Lua";
            let fields = lua_table_to_fields(fields_tbl)?;
            log_domain::log_structured(::log::Level::Error, Some(t), &message, &fields);
            dispatch_structured(
                lua,
                &s,
                &callback_keys,
                SinkLevel::Error,
                t,
                &message,
                &fields,
            );
            Ok(())
        })?,
    )?;
    /// Performs the 'log' operation.
    /// @return | nil | No value is returned.
    lurek.set("log", tbl)?;
    Ok(())
}
