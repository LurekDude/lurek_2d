//! Registers the `lurek.debugbridge.*` TCP debug server API.
//!
//! Embeds a JSON-over-TCP server (127.0.0.1 only) inside the running game.
//! External tools (VS Code extension, MCP server) connect to inspect and
//! control the game at runtime. Network I/O runs on a background thread;
//! Lua-dependent methods are queued and dispatched via `poll()` on the main thread.

use std::net::TcpListener;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use mlua::prelude::*;

use crate::debugbridge::{server_thread, BridgeShared, PendingRequest, PendingResponse};

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `lurek.debugbridge` namespace.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let db = lua.create_table()?;

    // Shared state between Lua closures and the TCP thread
    let shared: Arc<Mutex<BridgeShared>> = Arc::new(Mutex::new(BridgeShared::new()));
    let running: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
    // Store thread join handle
    let thread_handle: Arc<Mutex<Option<std::thread::JoinHandle<()>>>> = Arc::new(Mutex::new(None));

    // ----- Lifecycle -----

    /// Start the TCP debug server on 127.0.0.1:port.
    let sh = shared.clone();
    let run = running.clone();
    let th = thread_handle.clone();
    /// @param port : u16?
    /// @return boolean
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

    /// Stop the TCP debug server and close all connections.
    let run = running.clone();
    let th = thread_handle.clone();
    db.set(
        "stop",
        lua.create_function(move |_, ()| {
            run.store(false, Ordering::Relaxed);
            // Wait for thread to finish
            if let Ok(mut h) = th.lock() {
                if let Some(handle) = h.take() {
                    let _ = handle.join();
                }
            }
            Ok(())
        })?,
    )?;

    /// Returns whether the server is currently running.
    let run = running.clone();
    /// @return bool
    db.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(run.load(Ordering::Relaxed)))?,
    )?;

    /// Returns the server port (0 if not running).
    let sh = shared.clone();
    /// @return integer
    db.set(
        "getPort",
        lua.create_function(move |_, ()| Ok(sh.lock().map(|s| s.port).unwrap_or(0)))?,
    )?;

    /// Returns the number of connected TCP clients.
    let sh = shared.clone();
    /// @return integer
    db.set(
        "getClientCount",
        lua.create_function(move |_, ()| Ok(sh.lock().map(|s| s.client_count).unwrap_or(0)))?,
    )?;

    /// Poll for pending Lua-dependent requests from TCP clients.
    /// Must be called each frame from lurek.update(). Automatically records
    /// the current frame delta from `lurek.time.getDelta()` into the performance
    /// buffer — no manual `recordFrame()` call is needed.
    let sh = shared.clone();
    db.set(
        "poll",
        lua.create_function(move |lua, ()| {
            // Auto-record frame time from lurek.time.getDelta — no manual call needed.
            if let Ok(luna_tbl) = lua.globals().get::<_, LuaTable>("luna") {
                if let Ok(time_tbl) = luna_tbl.get::<_, LuaTable>("time") {
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
                        // Use debug.getinfo if available
                        let stack_result: LuaResult<LuaTable> = lua
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
                        // Locals introspection requires debug library
                        let level = req
                            .params
                            .get("level")
                            .and_then(|v| v.as_i64())
                            .unwrap_or(1);
                        let locals_result: LuaResult<LuaTable> = lua
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

    // ----- Print Capture -----

    /// Captures a print message and broadcasts it to connected clients.
    let sh = shared.clone();
    /// @param msg : string
    /// @param source : string?
    /// @param line : integer?
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

    /// Returns the print history.
    let sh = shared.clone();
    /// @param count : integer?
    /// @return table
    db.set(
        "getPrintHistory",
        lua.create_function(move |lua, count: Option<usize>| {
            let s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let entries = match count {
                Some(0) | None => &s.print_history[..],
                Some(n) => {
                    let start = s.print_history.len().saturating_sub(n);
                    &s.print_history[start..]
                }
            };
            let tbl = lua.create_table()?;
            for (i, entry) in entries.iter().enumerate() {
                let e = lua.create_table()?;
                e.set("timestamp", entry.timestamp)?;
                e.set("message", entry.message.clone())?;
                e.set("source", entry.source.clone())?;
                e.set("line", entry.line)?;
                tbl.set(i + 1, e)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Clears the print history.
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

    /// Sets the maximum print history size.
    let sh = shared.clone();
    /// @param max : integer
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

    // ----- Performance -----

    /// Returns performance statistics.
    let sh = shared.clone();
    /// @return table
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

    // ----- Screenshots -----

    /// Flags a screenshot request for the next frame.
    let sh = shared.clone();
    /// @param scale : integer?
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

    /// Returns whether a screenshot is currently requested.
    let sh = shared.clone();
    /// @return bool
    db.set(
        "isScreenshotRequested",
        lua.create_function(move |_, ()| {
            Ok(sh.lock().map(|s| s.screenshot_requested).unwrap_or(false))
        })?,
    )?;

    // ----- Broadcast -----

    /// Broadcasts a JSON event to all connected clients.
    let sh = shared.clone();
    /// @param event : string
    /// @param json_data : string
    db.set(
        "broadcast",
        lua.create_function(move |_, (event, json_data): (String, String)| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let msg = serde_json::json!({"event": event, "data": json_data});
            s.broadcast_queue.push_back(msg.to_string());
            Ok(())
        })?,
    )?;

    luna.set("debugbridge", db)?;
    Ok(())
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Convert a Lua value to a serde_json::Value for TCP responses.
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
