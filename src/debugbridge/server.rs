
use super::bridge::{BridgeShared, PendingRequest, PendingResponse};
use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;
/// Run the server loop and return when running flag becomes false.
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
        let mut had_activity = false;
        match listener.accept() {
            Ok((stream, _addr)) => {
                stream.set_nonblocking(true).ok();
                let reader = BufReader::new(stream.try_clone().expect("clone stream"));
                clients.push(Some((stream, reader)));
                had_activity = true;
                if let Ok(mut sh) = shared.lock() {
                    sh.client_count = clients.iter().filter(|c| c.is_some()).count();
                }
            }
            Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {}
            Err(_) => {}
        }
        let mut to_remove = Vec::new();
        for (idx, client) in clients.iter_mut().enumerate() {
            if let Some((_stream, reader)) = client {
                let mut line = String::new();
                match reader.read_line(&mut line) {
                    Ok(0) => {
                        to_remove.push(idx);
                        had_activity = true;
                    }
                    Ok(_) => {
                        let line = line.trim();
                        if !line.is_empty() {
                            had_activity = true;
                            handle_client_message(line, idx, &shared);
                        }
                    }
                    Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {}
                    Err(_) => {
                        to_remove.push(idx);
                        had_activity = true;
                    }
                }
            }
        }
        for idx in to_remove.into_iter().rev() {
            clients[idx] = None;
        }
        if let Ok(mut sh) = shared.lock() {
            for resp in sh.drain_responses() {
                if let Some(Some((stream, _))) = clients.get_mut(resp.client_idx) {
                    let json_str = serde_json::json!({
                        "id": resp.id,
                        "result": resp.result
                    });
                    let mut msg = json_str.to_string();
                    msg.push('\n');
                    let _ = stream.write_all(msg.as_bytes());
                    let _ = stream.flush();
                    had_activity = true;
                }
            }
            let mut sent_events = 0usize;
            let max_events_per_tick = 64usize;
            while sent_events < max_events_per_tick {
                let Some(event_str) = sh.broadcast_queue.pop_front() else {
                    break;
                };
                for (stream, _) in clients.iter_mut().flatten() {
                    let mut msg = event_str.clone();
                    if !msg.ends_with('\n') {
                        msg.push('\n');
                    }
                    let _ = stream.write_all(msg.as_bytes());
                    let _ = stream.flush();
                }
                sent_events += 1;
                had_activity = true;
            }
            sh.client_count = clients.iter().filter(|c| c.is_some()).count();
        }
        std::thread::sleep(if had_activity {
            Duration::from_millis(1)
        } else {
            Duration::from_millis(10)
        });
    }
}
/// Parse one client message, update shared state, and queue response side effects.
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
    let client_version = parsed
        .get("version")
        .and_then(|v| v.as_u64())
        .unwrap_or(sh.protocol_version as u64) as u32;
    let nonce_ok = params
        .get("nonce")
        .and_then(|v| v.as_str())
        .map(|v| v == sh.handshake_nonce)
        .unwrap_or(false);
    match method.as_str() {
        "ping" => {
            let time = sh.elapsed();
            let protocol_version = sh.protocol_version;
            let nonce = sh.handshake_nonce.clone();
            let capabilities = sh.capabilities.clone();
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({
                    "pong": true,
                    "time": time,
                    "protocolVersion": protocol_version,
                    "nonce": nonce,
                    "capabilities": capabilities,
                }),
                client_idx,
            });
        }
        "hello" => {
            if !nonce_ok {
                sh.pending_responses.push_back(PendingResponse {
                    id,
                    result: serde_json::json!({"error": "hello requires valid nonce"}),
                    client_idx,
                });
                return;
            }
            if client_version != sh.protocol_version {
                let protocol_version = sh.protocol_version;
                sh.pending_responses.push_back(PendingResponse {
                    id,
                    result: serde_json::json!({
                        "error": "protocol version mismatch",
                        "serverVersion": protocol_version,
                        "clientVersion": client_version,
                    }),
                    client_idx,
                });
                return;
            }
            let protocol_version = sh.protocol_version;
            let capabilities = sh.capabilities.clone();
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({
                    "ok": true,
                    "protocolVersion": protocol_version,
                    "capabilities": capabilities,
                }),
                client_idx,
            });
        }
        _ if method != "ping" && method != "hello" && !nonce_ok => {
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"error": "unauthorized: missing or invalid nonce"}),
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
                let rows: Vec<_> = sh.print_history.iter().skip(start).cloned().collect();
                serde_json::to_value(rows).unwrap_or_default()
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
        "triggerHotReload" => {
            sh.hot_reload_requested = true;
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"requested": true}),
                client_idx,
            });
        }
        "inspectScene" => {
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"nodes": [], "root": "scene"}),
                client_idx,
            });
        }
        "inspectEcs" => {
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"entities": [], "components": []}),
                client_idx,
            });
        }
        "dapSetBreakpoint" => {
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"ok": true, "implemented": "basic"}),
                client_idx,
            });
        }
        "dapStep" | "dapContinue" => {
            sh.pending_responses.push_back(PendingResponse {
                id,
                result: serde_json::json!({"ok": true, "implemented": "basic"}),
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
