//! `lurek.debugbridge` -- Debug bridge bindings for starting the local TCP bridge, polling debugger requests, print capture, performance data, screenshots, protocol metadata, and hot reload flags.

use super::SharedState;
use crate::debugbridge::{server_thread, BridgeShared, PendingRequest, PendingResponse};
use mlua::prelude::*;
use std::cell::RefCell;
use std::net::TcpListener;
use std::rc::Rc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
/// Registers the `lurek.debugbridge` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let db = lua.create_table()?;
    let shared: Arc<Mutex<BridgeShared>> = Arc::new(Mutex::new(BridgeShared::new()));
    let running: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
    let thread_handle: Arc<Mutex<Option<std::thread::JoinHandle<()>>>> = Arc::new(Mutex::new(None));
    // -- start --
    /// Starts the localhost debug bridge server on a port.
    /// @param | port? | integer | TCP port to bind on `127.0.0.1`; defaults to 19740 and must be at least 1024.
    /// @return | boolean | True when the server was started, false when it was already running.
    let sh = shared.clone();
    let run = running.clone();
    let th = thread_handle.clone();
    db.set(
        "start",
        lua.create_function(move |_, port: Option<u16>| {
            if run.load(Ordering::Relaxed) {
                return Ok(false);
            }
            let port = port.unwrap_or(19740);
            if port < 1024 {
                return Err(LuaError::RuntimeError("port must be >= 1024".to_string()));
            }
            let addr = format!("127.0.0.1:{}", port);
            let listener = TcpListener::bind(&addr)
                .map_err(|e| LuaError::RuntimeError(format!("failed to bind {}: {}", addr, e)))?;
            if let Ok(mut s) = sh.lock() {
                s.port = port;
            }
            run.store(true, Ordering::Relaxed);
            let sh2 = sh.clone();
            let run2 = run.clone();
            let handle = std::thread::spawn(move || {
                server_thread(listener, sh2, run2);
            });
            if let Ok(mut h) = th.lock() {
                *h = Some(handle);
            }
            Ok(true)
        })?,
    )?;
    // -- stop --
    /// Stops the debug bridge server and joins its server thread.
    /// @return | nil | No value is returned.
    let run = running.clone();
    let th = thread_handle.clone();
    db.set(
        "stop",
        lua.create_function(move |_, ()| {
            run.store(false, Ordering::Relaxed);
            if let Ok(mut h) = th.lock() {
                if let Some(handle) = h.take() {
                    let _ = handle.join();
                }
            }
            Ok(())
        })?,
    )?;
    // -- isRunning --
    /// Returns whether the debug bridge server is currently running.
    /// @return | boolean | True when the server thread is active.
    let run = running.clone();
    db.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(run.load(Ordering::Relaxed)))?,
    )?;
    // -- getPort --
    /// Returns the configured TCP port for the debug bridge.
    /// @return | integer | Active or configured port, or zero when unavailable.
    let sh = shared.clone();
    db.set(
        "getPort",
        lua.create_function(move |_, ()| Ok(sh.lock().map(|s| s.port).unwrap_or(0)))?,
    )?;
    // -- getClientCount --
    /// Returns the number of connected debug bridge clients.
    /// @return | integer | Connected client count.
    let sh = shared.clone();
    db.set(
        "getClientCount",
        lua.create_function(move |_, ()| Ok(sh.lock().map(|s| s.client_count).unwrap_or(0)))?,
    )?;
    // -- poll --
    /// Polls pending debugger requests, evaluates supported methods, and queues responses.
    /// @return | nil | No value is returned.
    let sh = shared.clone();
    db.set("poll", lua.create_function(move |lua, ()| {
            if let Ok(lurek_tbl) = lua.globals().get::<_, LuaTable>("lurek") {
                if let Ok(time_tbl) = lurek_tbl.get::<_, LuaTable>("time") {
                    if let Ok(get_delta) = time_tbl.get::<_, LuaFunction>("getDelta") {
                        let dt: f64 = get_delta.call(()).unwrap_or(0.0);
                        if dt > 0.0 {
                            if let Ok(mut s) = sh.lock() {
                                s.record_frame(dt);
                            }
                        }
                    }
                }
            }
            let requests: Vec<PendingRequest> = {
                let mut s = sh
                    .lock()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                s.pending_requests.drain(..).collect()
            };
            for req in requests {
                let result = match req.method.as_str() {
                    "eval" => {
                        let code = req
                            .params
                            .get("code")
                            .and_then(|v| v.as_str())
                            .unwrap_or("");
                        // LUA-EVAL-JUSTIFIED: debugbridge.poll implements debugger-requested Lua eval.
                        match lua.load(code).eval::<LuaMultiValue>() {
                            Ok(vals) => {
                                let values: Vec<serde_json::Value> = vals
                                    .iter()
                                    .map(|v| lua_value_to_json(v))
                                    .collect();
                                serde_json::json!({"values": values})
                            }
                            Err(e) => {
                                serde_json::json!({"error": e.to_string()})
                            }
                        }
                    }
                    "getCallStack" => {
                        let stack_result: LuaResult<LuaTable> = lua
                            // LUA-EVAL-JUSTIFIED: debugbridge.poll queries Lua debug stack metadata.
                            .load(concat!(
                                "local frames = {}\n",
                                "if not debug or not debug.getinfo then return frames end\n",
                                "for i = 1, 50 do\n",
                                "  local info = debug.getinfo(i, 'Snl')\n",
                                "  if not info then break end\n",
                                "  frames[#frames+1] = {\n",
                                "    level = i,\n",
                                "    name = info.name or '?',\n",
                                "    source = info.short_src or '?',\n",
                                "    line = info.currentline or 0,\n",
                                "    what = info.namewhat or ''\n",
                                "  }\n",
                                "end\n",
                                "return frames",
                            ))
                            .eval();
                        match stack_result {
                            Ok(tbl) => {
                                let mut stack = Vec::new();
                                for i in 1..=tbl.len().unwrap_or(0) {
                                    if let Ok(frame) = tbl.get::<_, LuaTable>(i) {
                                        let entry = serde_json::json!({
                                            "level": frame.get::<_, i32>("level").unwrap_or(0),
                                            "name": frame.get::<_, String>("name").unwrap_or_default(),
                                            "source": frame.get::<_, String>("source").unwrap_or_default(),
                                            "line": frame.get::<_, i32>("line").unwrap_or(0),
                                            "what": frame.get::<_, String>("what").unwrap_or_default(),
                                        });
                                        stack.push(entry);
                                    }
                                }
                                serde_json::json!({"stack": stack})
                            }
                            Err(e) => serde_json::json!({"error": e.to_string()}),
                        }
                    }
                    "getLocals" => {
                        let level = req
                            .params
                            .get("level")
                            .and_then(|v| v.as_i64())
                            .unwrap_or(1);
                        let locals_result: LuaResult<LuaTable> = lua
                            // LUA-EVAL-JUSTIFIED: debugbridge.poll queries Lua debug locals metadata.
                            .load(format!(
                                concat!(
                                    "local locals = {{}}\n",
                                    "if not debug or not debug.getlocal then return locals end\n",
                                    "local i = 1\n",
                                    "while true do\n",
                                    "  local name, val = debug.getlocal({}, i)\n",
                                    "  if not name then break end\n",
                                    "  locals[#locals+1] = {{name=name, type=type(val), value=tostring(val)}}\n",
                                    "  i = i + 1\n",
                                    "end\n",
                                    "return locals",
                                ),
                                level
                            ))
                            .eval();
                        match locals_result {
                            Ok(tbl) => {
                                let mut locals = Vec::new();
                                for i in 1..=tbl.len().unwrap_or(0) {
                                    if let Ok(entry) = tbl.get::<_, LuaTable>(i) {
                                        locals.push(serde_json::json!({
                                            "name": entry.get::<_, String>("name").unwrap_or_default(),
                                            "type": entry.get::<_, String>("type").unwrap_or_default(),
                                            "value": entry.get::<_, String>("value").unwrap_or_default(),
                                        }));
                                    }
                                }
                                serde_json::json!({"locals": locals})
                            }
                            Err(e) => serde_json::json!({"error": e.to_string()}),
                        }
                    }
                    "getGlobals" => {
                        let globals_result: LuaResult<LuaTable> = lua
                            // LUA-EVAL-JUSTIFIED: debugbridge.poll queries simple Lua globals for debugger inspection.
                            .load(concat!(
                                "local result = {}\n",
                                "local count = 0\n",
                                "for k, v in pairs(_G) do\n",
                                "  if count >= 200 then break end\n",
                                "  local t = type(v)\n",
                                "  if t == 'number' or t == 'string' or t == 'boolean' then\n",
                                "    result[k] = v\n",
                                "    count = count + 1\n",
                                "  end\n",
                                "end\n",
                                "return result",
                            ))
                            .eval();
                        match globals_result {
                            Ok(tbl) => {
                                let mut globals = serde_json::Map::new();
                                for (k, v) in tbl.pairs::<String, LuaValue>().flatten() {
                                    globals.insert(k, lua_value_to_json(&v));
                                }
                                serde_json::json!({"globals": globals})
                            }
                            Err(e) => serde_json::json!({"error": e.to_string()}),
                        }
                    }
                    _ => serde_json::json!({"error": "unknown method"}),
                };
                if let Ok(mut s) = sh.lock() {
                    s.pending_responses.push_back(PendingResponse {
                        id: req.id,
                        result,
                        client_idx: req.client_idx,
                    });
                }
            }
            Ok(())
        })?,
    )?;
    // -- capturePrint --
    /// Captures a print message and broadcasts it to debug bridge clients.
    /// @param | msg | string | Printed message text.
    /// @param | source? | string | Source label; defaults to `?`.
    /// @param | line? | integer | Source line; defaults to zero.
    /// @return | nil | No value is returned.
    let sh = shared.clone();
    db.set(
        "capturePrint",
        lua.create_function(
            move |_, (msg, source, line): (String, Option<String>, Option<u32>)| {
                let mut s = sh
                    .lock()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                let src = source.unwrap_or_else(|| "?".to_string());
                let ln = line.unwrap_or(0);
                s.capture_print_with_broadcast(&msg, &src, ln);
                Ok(())
            },
        )?,
    )?;
    // -- getPrintHistory --
    /// Returns captured print history entries.
    /// @param | count? | integer | Number of newest entries; nil or zero returns all entries.
    /// @return | table | Array table of entries with `timestamp`, `message`, `source`, and `line` fields.
    let sh = shared.clone();
    db.set(
        "getPrintHistory",
        lua.create_function(move |lua, count: Option<usize>| {
            let s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let entries = match count {
                Some(0) | None => s.print_history.iter().cloned().collect::<Vec<_>>(),
                Some(n) => {
                    let start = s.print_history.len().saturating_sub(n);
                    s.print_history
                        .iter()
                        .skip(start)
                        .cloned()
                        .collect::<Vec<_>>()
                }
            };
            let tbl = lua.create_table()?;
            for (i, entry) in entries.iter().enumerate() {
                let e = lua.create_table()?;
                /// Performs the 'timestamp' operation.
                /// @return | nil | No value is returned.
                e.set("timestamp", entry.timestamp)?;
                /// Performs the 'message' operation.
                /// @return | nil | No value is returned.
                e.set("message", entry.message.clone())?;
                /// Performs the 'source' operation.
                /// @return | nil | No value is returned.
                e.set("source", entry.source.clone())?;
                /// Performs the 'line' operation.
                /// @return | nil | No value is returned.
                e.set("line", entry.line)?;
                tbl.set(i + 1, e)?;
            }
            Ok(tbl)
        })?,
    )?;
    // -- clearPrintHistory --
    /// Clears all entries from the captured print history buffer.
    /// @return | nil | No value is returned.
    let sh = shared.clone();
    db.set(
        "clearPrintHistory",
        lua.create_function(move |_, ()| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            s.print_history.clear();
            Ok(())
        })?,
    )?;
    // -- setMaxPrintHistory --
    /// Sets the maximum retained print history entry count.
    /// @param | max | integer | Maximum retained print entries.
    /// @return | nil | No value is returned.
    let sh = shared.clone();
    db.set(
        "setMaxPrintHistory",
        lua.create_function(move |_, max: usize| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            s.set_max_print_history(max);
            Ok(())
        })?,
    )?;
    // -- getPerformance --
    /// Returns debug bridge performance metrics.
    /// @return | table | Table of numeric performance metrics.
    let sh = shared.clone();
    db.set(
        "getPerformance",
        lua.create_function(move |lua, ()| {
            let s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let perf = s.get_performance();
            let tbl = lua.create_table()?;
            if let serde_json::Value::Object(map) = perf {
                for (k, v) in map {
                    if let Some(n) = v.as_f64() {
                        tbl.set(k, n)?;
                    }
                }
            }
            Ok(tbl)
        })?,
    )?;
    // -- requestScreenshot --
    /// Requests a screenshot from the runtime.
    /// @param | scale? | integer | Screenshot scale clamped from 1 to 8; defaults to 1.
    /// @return | nil | No value is returned.
    let sh = shared.clone();
    db.set(
        "requestScreenshot",
        lua.create_function(move |_, scale: Option<u32>| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            s.screenshot_requested = true;
            s.screenshot_scale = scale.unwrap_or(1).clamp(1, 8);
            Ok(())
        })?,
    )?;
    // -- isScreenshotRequested --
    /// Returns whether a screenshot request is pending.
    /// @return | boolean | True when a screenshot request is pending.
    let sh = shared.clone();
    db.set(
        "isScreenshotRequested",
        lua.create_function(move |_, ()| {
            Ok(sh.lock().map(|s| s.screenshot_requested).unwrap_or(false))
        })?,
    )?;
    // -- broadcast --
    /// Queues a JSON string payload broadcast for debug bridge clients.
    /// @param | event | string | Event name sent to clients.
    /// @param | json_data | string | Payload string wrapped as JSON for clients.
    /// @return | nil | No value is returned.
    let sh = shared.clone();
    db.set(
        "broadcast",
        lua.create_function(move |_, (event, json_data): (String, String)| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            s.queue_broadcast_json(&event, serde_json::json!(json_data));
            Ok(())
        })?,
    )?;
    // -- getProtocolInfo --
    /// Returns debug bridge protocol version, capabilities, and handshake nonce.
    /// @return | table | Protocol info table with `version`, `capabilities`, and `nonce` fields.
    let sh = shared.clone();
    db.set(
        "getProtocolInfo",
        lua.create_function(move |lua, ()| {
            let s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let t = lua.create_table()?;
            /// Performs the 'version' operation.
            /// @return | nil | No value is returned.
            t.set("version", s.protocol_version)?;
            let caps = lua.create_table()?;
            for (i, cap) in s.capabilities.iter().enumerate() {
                caps.set(i + 1, cap.clone())?;
            }
            /// Performs the 'capabilities' operation.
            /// @return | nil | No value is returned.
            t.set("capabilities", caps)?;
            /// Performs the 'nonce' operation.
            /// @return | nil | No value is returned.
            t.set("nonce", s.handshake_nonce.clone())?;
            Ok(t)
        })?,
    )?;
    // -- consumeHotReloadRequest --
    /// Returns and clears the pending hot reload request flag.
    /// @return | boolean | True when a hot reload request was pending.
    let sh = shared.clone();
    db.set(
        "consumeHotReloadRequest",
        lua.create_function(move |_, ()| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let requested = s.hot_reload_requested;
            s.hot_reload_requested = false;
            Ok(requested)
        })?,
    )?;
    /// Performs the 'debugbridge' operation.
    /// @return | nil | No value is returned.
    lurek.set("debugbridge", db)?;
    Ok(())
}
/// Converts a Lua value into JSON for debug bridge responses.
fn lua_value_to_json(val: &LuaValue) -> serde_json::Value {
    match val {
        LuaValue::Nil => serde_json::Value::Null,
        LuaValue::Boolean(b) => serde_json::Value::Bool(*b),
        LuaValue::Integer(n) => serde_json::json!(*n),
        LuaValue::Number(n) => serde_json::json!(*n),
        LuaValue::String(s) => serde_json::Value::String(s.to_str().unwrap_or("").to_string()),
        _ => serde_json::Value::String(format!("<{}>", val.type_name())),
    }
}
