//! TCP server thread for the Lurek2D debug bridge.
//!
//! Runs a non-blocking accept loop that multiplexes reads from all connected
//! clients, dispatches background-safe methods immediately, and queues
//! main-thread methods for later execution via `poll()`.

use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use super::bridge::{BridgeShared, PendingRequest, PendingResponse};

/// Accept loop: runs on a background thread and handles all TCP I/O.
///
/// Accepts new connections, reads newline-delimited JSON messages from each
/// client, and writes pending responses back.  Stops when `running` is set to
/// `false`.
///
/// # Parameters
/// - `listener` — `TcpListener`.
/// - `shared` — `Arc<Mutex<BridgeShared>>`.
/// - `running` — `Arc<AtomicBool>`.
pub fn server_thread(
    listener: TcpListener,
    shared: Arc<Mutex<BridgeShared>>,
    running: Arc<AtomicBool>,
) {
    listener
        .set_nonblocking(true)
        .expect("Cannot set non-blocking");

    let mut clients: Vec<Option<(std::net::TcpStream, BufReader<std::net::TcpStream>)>> =
        Vec::new();

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

        // Write pending responses and broadcasts to clients
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

            while let Some(event_str) = sh.broadcast_queue.pop_front() {
                for (stream, _) in clients.iter_mut().flatten() {
                    let mut msg = event_str.clone();
                    if !msg.ends_with('\n') {
                        msg.push('\n');
                    }
                    let _ = stream.write_all(msg.as_bytes());
                    let _ = stream.flush();
                }
            }

            sh.client_count = clients.iter().filter(|c| c.is_some()).count();
        }

        std::thread::sleep(std::time::Duration::from_millis(5));
    }
}

/// Parses a newline-terminated JSON message from a client and either responds
/// immediately (background-safe methods) or queues a [`PendingRequest`] for the
/// main thread.
///
/// # Parameters
/// - `line` — `&str`.
/// - `client_idx` — `usize`.
/// - `shared` — `&Arc<Mutex<BridgeShared>>`.
pub fn handle_client_message(line: &str, client_idx: usize, shared: &Arc<Mutex<BridgeShared>>) {
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
            let count = params.get("count").and_then(|v| v.as_u64()).unwrap_or(0) as usize;
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
