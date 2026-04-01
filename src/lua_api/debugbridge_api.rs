//! Registers the `luna.debugbridge.*` TCP debug server API.
//!
//! Embeds a JSON-over-TCP server (127.0.0.1 only) inside the running game.
//! External tools (VS Code extension, MCP server) connect to inspect and
//! control the game at runtime. Network I/O runs on a background thread;
//! Lua-dependent methods are queued and dispatched via `poll()` on the main thread.

use std::collections::VecDeque;
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Instant;

use mlua::prelude::*;

// ---------------------------------------------------------------------------
// Shared cross-thread state
// ---------------------------------------------------------------------------

/// A pending request from a TCP client that needs Lua (main-thread) execution.
#[derive(Clone)]
struct PendingRequest {
    id: u64,
    method: String,
    params: serde_json::Value,
    /// Index of the client in the clients Vec that sent this request.
    client_idx: usize,
}

/// A response produced on the main thread for delivery back to a TCP client.
#[derive(Clone)]
struct PendingResponse {
    id: u64,
    result: serde_json::Value,
    client_idx: usize,
}

/// Print log entry.
#[derive(Clone, serde::Serialize)]
struct PrintEntry {
    timestamp: f64,
    message: String,
    source: String,
    line: u32,
}

/// State shared between the TCP server thread and the main thread.
struct BridgeShared {
    /// Incoming requests that require Lua execution.
    pending_requests: VecDeque<PendingRequest>,
    /// Responses to be written back to clients.
    pending_responses: VecDeque<PendingResponse>,
    /// Events to broadcast to all clients.
    broadcast_queue: VecDeque<String>,
    /// Print history.
    print_history: Vec<PrintEntry>,
    max_print_history: usize,
    /// Frame times (last N).
    frame_times: Vec<f64>,
    max_frame_times: usize,
    /// Screenshot requested flag.
    screenshot_requested: bool,
    screenshot_scale: u32,
    /// Number of connected clients.
    client_count: usize,
    /// Server port.
    port: u16,
    /// Timing epoch.
    epoch: Instant,
}

impl BridgeShared {
    fn new() -> Self {
        Self {
            pending_requests: VecDeque::new(),
            pending_responses: VecDeque::new(),
            broadcast_queue: VecDeque::new(),
            print_history: Vec::new(),
            max_print_history: 2000,
            frame_times: Vec::new(),
            max_frame_times: 300,
            screenshot_requested: false,
            screenshot_scale: 1,
            client_count: 0,
            port: 0,
            epoch: Instant::now(),
        }
    }

    fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }

    fn push_print(&mut self, msg: &str, source: &str, line: u32) {
        let entry = PrintEntry {
            timestamp: self.elapsed(),
            message: msg.to_string(),
            source: source.to_string(),
            line,
        };
        self.print_history.push(entry);
        if self.print_history.len() > self.max_print_history {
            self.print_history.remove(0);
        }
    }

    fn get_performance(&self) -> serde_json::Value {
        if self.frame_times.is_empty() {
            return serde_json::json!({
                "fps": 0.0, "dt": 0.0, "avgDt": 0.0,
                "minDt": 0.0, "maxDt": 0.0
            });
        }
        let n = self.frame_times.len() as f64;
        let sum: f64 = self.frame_times.iter().sum();
        let avg = sum / n;
        let min = self.frame_times.iter().cloned().fold(f64::MAX, f64::min);
        let max = self.frame_times.iter().cloned().fold(0.0_f64, f64::max);
        let last = *self.frame_times.last().unwrap_or(&0.0);
        serde_json::json!({
            "fps": if avg > 0.0 { 1.0 / avg } else { 0.0 },
            "dt": last,
            "avgDt": avg,
            "minDt": min,
            "maxDt": max
        })
    }
}

// ---------------------------------------------------------------------------
// TCP server thread
// ---------------------------------------------------------------------------

/// Runs the TCP accept loop on a background thread.
fn server_thread(
    listener: TcpListener,
    shared: Arc<Mutex<BridgeShared>>,
    running: Arc<AtomicBool>,
) {
    listener
        .set_nonblocking(true)
        .expect("Cannot set non-blocking");

    let mut clients: Vec<Option<(TcpStream, BufReader<TcpStream>)>> = Vec::new();

    while running.load(Ordering::Relaxed) {
        // Accept new connections
        match listener.accept() {
            Ok((stream, _addr)) => {
                stream.set_nonblocking(true).ok();
                let reader = BufReader::new(stream.try_clone().expect("clone stream"));
                clients.push(Some((stream, reader)));
                if let Ok(mut sh) = shared.lock() {
                    sh.client_count = clients.iter().filter(|c| c.is_some()).count();
                }
            }
            Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {}
            Err(_) => {}
        }

        // Read from clients
        let mut to_remove = Vec::new();
        for (idx, client) in clients.iter_mut().enumerate() {
            if let Some((_stream, reader)) = client {
                let mut line = String::new();
                match reader.read_line(&mut line) {
                    Ok(0) => {
                        // Client disconnected
                        to_remove.push(idx);
                    }
                    Ok(_) => {
                        let line = line.trim();
                        if !line.is_empty() {
                            handle_client_message(line, idx, &shared);
                        }
                    }
                    Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {}
                    Err(_) => {
                        to_remove.push(idx);
                    }
                }
            }
        }

        // Remove disconnected clients
        for idx in to_remove.into_iter().rev() {
            clients[idx] = None;
        }

        // Write pending responses back to clients
        if let Ok(mut sh) = shared.lock() {
            while let Some(resp) = sh.pending_responses.pop_front() {
                if let Some(Some((stream, _))) = clients.get_mut(resp.client_idx) {
                    let json_str = serde_json::json!({
                        "id": resp.id,
                        "result": resp.result
                    });
                    let mut msg = json_str.to_string();
                    msg.push('\n');
                    let _ = stream.write_all(msg.as_bytes());
                    let _ = stream.flush();
                }
            }

            // Broadcast events
            while let Some(event_str) = sh.broadcast_queue.pop_front() {
                for client in &mut clients {
                    if let Some((stream, _)) = client {
                        let mut msg = event_str.clone();
                        if !msg.ends_with('\n') {
                            msg.push('\n');
                        }
                        let _ = stream.write_all(msg.as_bytes());
                        let _ = stream.flush();
                    }
                }
            }

            sh.client_count = clients.iter().filter(|c| c.is_some()).count();
        }

        // Sleep briefly to avoid busy-waiting
        std::thread::sleep(std::time::Duration::from_millis(5));
    }
}

/// Parse and handle a JSON request from a client.
fn handle_client_message(line: &str, client_idx: usize, shared: &Arc<Mutex<BridgeShared>>) {
    let parsed: serde_json::Value = match serde_json::from_str(line) {
        Ok(v) => v,
        Err(_) => return,
    };

    let id = parsed.get("id").and_then(|v| v.as_u64()).unwrap_or(0);
    let method = parsed
        .get("method")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let params = parsed
        .get("params")
        .cloned()
        .unwrap_or(serde_json::Value::Null);

    let mut sh = match shared.lock() {
        Ok(s) => s,
        Err(_) => return,
    };

    // Background-thread methods (respond immediately)
    match method.as_str() {
        "ping" => {
            let time = sh.elapsed();
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"pong": true, "time": time}),
                client_idx,
            });
        }
        "getPerformance" => {
            let perf = sh.get_performance();
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: perf,
                client_idx,
            });
        }
        "getPrintHistory" => {
            let count = params
                .get("count")
                .and_then(|v| v.as_u64())
                .unwrap_or(0) as usize;
            let result = if count == 0 {
                serde_json::to_value(&sh.print_history).unwrap_or_default()
            } else {
                let start = sh.print_history.len().saturating_sub(count);
                serde_json::to_value(&sh.print_history[start..]).unwrap_or_default()
            };
            sh.pending_responses.push_back(PendingResponse {
                id,
                result,
                client_idx,
            });
        }
        "getClientCount" => {
            let count = sh.client_count;
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"count": count}),
                client_idx,
            });
        }
        "getStatus" => {
            let perf = sh.get_performance();
            let port = sh.port;
            let clients = sh.client_count;
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({
                    "running": true,
                    "port": port,
                    "clients": clients,
                    "performance": perf
                }),
                client_idx,
            });
        }
        "clearPrintHistory" => {
            sh.print_history.clear();
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"cleared": true}),
                client_idx,
            });
        }
        "requestScreenshot" => {
            let scale = params
                .get("scale")
                .and_then(|v| v.as_u64())
                .unwrap_or(1)
                .clamp(1, 8) as u32;
            sh.screenshot_requested = true;
            sh.screenshot_scale = scale;
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"requested": true}),
                client_idx,
            });
        }
        // Main-thread methods: queue for poll()
        "eval" | "getCallStack" | "getLocals" | "getGlobals" => {
            sh.pending_requests.push_back(PendingRequest {
                id,
                method,
                params,
                client_idx,
            });
        }
        _ => {
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"error": format!("unknown method: {}", method)}),
                client_idx,
            });
        }
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.debugbridge` namespace.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let db = lua.create_table()?;

    // Shared state between Lua closures and the TCP thread
    let shared: Arc<Mutex<BridgeShared>> = Arc::new(Mutex::new(BridgeShared::new()));
    let running: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
    // Store thread join handle
    let thread_handle: Arc<Mutex<Option<std::thread::JoinHandle<()>>>> =
        Arc::new(Mutex::new(None));

    // ----- Lifecycle -----

    /// Start the TCP debug server on 127.0.0.1:port.
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
                return Err(LuaError::RuntimeError(
                    "port must be >= 1024".to_string(),
                ));
            }
            let addr = format!("127.0.0.1:{}", port);
            let listener = TcpListener::bind(&addr).map_err(|e| {
                LuaError::RuntimeError(format!("failed to bind {}: {}", addr, e))
            })?;
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
    db.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(run.load(Ordering::Relaxed)))?,
    )?;

    /// Returns the server port (0 if not running).
    let sh = shared.clone();
    db.set(
        "getPort",
        lua.create_function(move |_, ()| {
            Ok(sh.lock().map(|s| s.port).unwrap_or(0))
        })?,
    )?;

    /// Returns the number of connected TCP clients.
    let sh = shared.clone();
    db.set(
        "getClientCount",
        lua.create_function(move |_, ()| {
            Ok(sh.lock().map(|s| s.client_count).unwrap_or(0))
        })?,
    )?;

    /// Poll for pending Lua-dependent requests from TCP clients.
    /// Must be called each frame from luna.update().
    let sh = shared.clone();
    db.set(
        "poll",
        lua.create_function(move |lua, ()| {
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
                            .load(&format!(
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
                                for pair in tbl.pairs::<String, LuaValue>() {
                                    if let Ok((k, v)) = pair {
                                        globals.insert(k, lua_value_to_json(&v));
                                    }
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
    db.set(
        "capturePrint",
        lua.create_function(move |_, (msg, source, line): (String, Option<String>, Option<u32>)| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            let src = source.unwrap_or_else(|| "?".to_string());
            let ln = line.unwrap_or(0);
            s.push_print(&msg, &src, ln);

            // Broadcast print event
            let ts = s.elapsed();
            let event = serde_json::json!({
                "event": "print",
                "data": {"timestamp": ts, "message": msg, "source": src, "line": ln}
            });
            s.broadcast_queue.push_back(event.to_string());
            Ok(())
        })?,
    )?;

    /// Returns the print history.
    let sh = shared.clone();
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
                /// Timestamp on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("timestamp", entry.timestamp)?;
                /// Message on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("message", entry.message.clone())?;
                /// Source on this Object.
                ///
                /// # Returns
                /// The result.
                e.set("source", entry.source.clone())?;
                /// Line on this Object.
                ///
                /// # Returns
                /// The result.
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
    db.set(
        "setMaxPrintHistory",
        lua.create_function(move |_, max: usize| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            s.max_print_history = max.clamp(1, 100000);
            while s.print_history.len() > s.max_print_history {
                s.print_history.remove(0);
            }
            Ok(())
        })?,
    )?;

    // ----- Performance -----

    /// Records a frame time sample.
    let sh = shared.clone();
    db.set(
        "recordFrame",
        lua.create_function(move |_, dt: f64| {
            let mut s = sh
                .lock()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            s.frame_times.push(dt);
            if s.frame_times.len() > s.max_frame_times {
                s.frame_times.remove(0);
            }
            Ok(())
        })?,
    )?;

    /// Returns performance statistics.
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

    // ----- Screenshots -----

    /// Flags a screenshot request for the next frame.
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

    /// Returns whether a screenshot is currently requested.
    let sh = shared.clone();
    db.set(
        "isScreenshotRequested",
        lua.create_function(move |_, ()| {
            Ok(sh
                .lock()
                .map(|s| s.screenshot_requested)
                .unwrap_or(false))
        })?,
    )?;

    // ----- Broadcast -----

    /// Broadcasts a JSON event to all connected clients.
    let sh = shared.clone();
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

    /// Debugbridge on this Object.
    ///
    /// # Returns
    /// The result.
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
        LuaValue::String(s) => {
            serde_json::Value::String(s.to_str().unwrap_or("").to_string())
        }
        _ => serde_json::Value::String(format!("<{}>", val.type_name())),
    }
}
