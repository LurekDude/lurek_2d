//! INTERNAL ONLY: Public debugbridge behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_debugbridge_unit.lua`.
//!
//! Rust-only coverage remains below for the low-level JSON-RPC message handler.

// ── server ────────────────────────────────────────────────────────────────────

mod server_tests {
    use lurek2d::debugbridge::{handle_client_message, BridgeShared};
    use std::io::{BufRead, BufReader, Write};
    use std::net::{TcpListener, TcpStream};
    use std::sync::atomic::{AtomicBool, Ordering};
    use std::sync::{Arc, Mutex};
    use std::time::Duration;

    fn with_nonce(shared: &Arc<Mutex<BridgeShared>>, body: &str) -> String {
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        format!("{{\"params\":{{\"nonce\":\"{}\"}},{}", nonce, &body[1..])
    }

    fn make_shared() -> Arc<Mutex<BridgeShared>> {
        Arc::new(Mutex::new(BridgeShared::new()))
    }

    #[test]
    fn ping_responds_immediately() {
        let shared = make_shared();
        handle_client_message(r#"{"id":1,"method":"ping"}"#, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses.len(), 1);
        let resp = &sh.pending_responses[0];
        assert_eq!(resp.id, 1);
        assert_eq!(resp.client_idx, 0);
        assert_eq!(resp.result["pong"], true);
        assert!(resp.result["nonce"].as_str().is_some());
    }

    #[test]
    fn get_performance_responds() {
        let shared = make_shared();
        let req = with_nonce(&shared, r#"{"id":2,"method":"getPerformance"}"#);
        handle_client_message(&req, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses.len(), 1);
        assert_eq!(sh.pending_responses[0].id, 2);
        assert!(sh.pending_responses[0].result.get("fps").is_some());
    }

    #[test]
    fn get_client_count_responds() {
        let shared = make_shared();
        let req = with_nonce(&shared, r#"{"id":3,"method":"getClientCount"}"#);
        handle_client_message(&req, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses[0].result["count"], 0);
    }

    #[test]
    fn get_status_responds() {
        let shared = make_shared();
        let req = with_nonce(&shared, r#"{"id":4,"method":"getStatus"}"#);
        handle_client_message(&req, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses[0].result["running"], true);
    }

    #[test]
    fn clear_print_history_clears() {
        let shared = make_shared();
        {
            let mut sh = shared.lock().unwrap();
            sh.push_print("msg", "s", 1);
        }
        let req = with_nonce(&shared, r#"{"id":5,"method":"clearPrintHistory"}"#);
        handle_client_message(&req, 0, &shared);
        let sh = shared.lock().unwrap();
        assert!(sh.print_history.is_empty());
        assert_eq!(sh.pending_responses[0].result["cleared"], true);
    }

    #[test]
    fn get_print_history_returns_all() {
        let shared = make_shared();
        {
            let mut sh = shared.lock().unwrap();
            sh.push_print("a", "s", 1);
            sh.push_print("b", "s", 2);
        }
        let req = with_nonce(&shared, r#"{"id":6,"method":"getPrintHistory"}"#);
        handle_client_message(&req, 0, &shared);
        let sh = shared.lock().unwrap();
        let result = &sh.pending_responses[0].result;
        assert_eq!(result.as_array().unwrap().len(), 2);
    }

    #[test]
    fn get_print_history_with_count() {
        let shared = make_shared();
        {
            let mut sh = shared.lock().unwrap();
            for i in 0..5 {
                sh.push_print(&format!("m{i}"), "s", 1);
            }
        }
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        let msg = format!(
            r#"{{"id":7,"method":"getPrintHistory","params":{{"count":2,"nonce":"{}"}}}}"#,
            nonce
        );
        handle_client_message(&msg, 0, &shared);
        let sh = shared.lock().unwrap();
        let result = &sh.pending_responses[0].result;
        assert_eq!(result.as_array().unwrap().len(), 2);
    }

    #[test]
    fn request_screenshot_sets_flag() {
        let shared = make_shared();
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        handle_client_message(
            &format!(
                r#"{{"id":8,"method":"requestScreenshot","params":{{"scale":4,"nonce":"{}"}}}}"#,
                nonce
            ),
            0,
            &shared,
        );
        let sh = shared.lock().unwrap();
        assert!(sh.screenshot_requested);
        assert_eq!(sh.screenshot_scale, 4);
        assert_eq!(sh.pending_responses[0].result["requested"], true);
    }

    #[test]
    fn eval_queued_as_pending_request() {
        let shared = make_shared();
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        handle_client_message(
            &format!(
                r#"{{"id":9,"method":"eval","params":{{"code":"print(1)","nonce":"{}"}}}}"#,
                nonce
            ),
            0,
            &shared,
        );
        let sh = shared.lock().unwrap();
        assert!(sh.pending_responses.is_empty());
        assert_eq!(sh.pending_requests.len(), 1);
        assert_eq!(sh.pending_requests[0].method, "eval");
        assert_eq!(sh.pending_requests[0].id, 9);
    }

    #[test]
    fn unknown_method_returns_error() {
        let shared = make_shared();
        let req = with_nonce(&shared, r#"{"id":10,"method":"foobar"}"#);
        handle_client_message(&req, 0, &shared);
        let sh = shared.lock().unwrap();
        assert!(sh.pending_responses[0].result["error"]
            .as_str()
            .unwrap()
            .contains("unknown method"));
    }

    #[test]
    fn invalid_json_ignored() {
        let shared = make_shared();
        handle_client_message("not json at all", 0, &shared);
        let sh = shared.lock().unwrap();
        assert!(sh.pending_responses.is_empty());
        assert!(sh.pending_requests.is_empty());
    }

    #[test]
    fn non_hello_methods_require_nonce() {
        let shared = make_shared();
        handle_client_message(r#"{"id":11,"method":"getStatus"}"#, 0, &shared);
        let sh = shared.lock().unwrap();
        assert!(sh.pending_responses[0].result["error"]
            .as_str()
            .unwrap()
            .contains("unauthorized"));
    }

    #[test]
    fn hello_validates_protocol_and_nonce() {
        let shared = make_shared();
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        let msg = format!(
            r#"{{"id":12,"method":"hello","version":1,"params":{{"nonce":"{}"}}}}"#,
            nonce
        );
        handle_client_message(&msg, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses[0].result["ok"], true);
    }

    #[test]
    fn request_screenshot_clamps_scale() {
        let shared = make_shared();
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        handle_client_message(
            &format!(
                r#"{{"id":13,"method":"requestScreenshot","params":{{"scale":0,"nonce":"{}"}}}}"#,
                nonce
            ),
            0,
            &shared,
        );
        {
            let sh = shared.lock().unwrap();
            assert_eq!(sh.screenshot_scale, 1);
        }
        handle_client_message(
            &format!(
                r#"{{"id":14,"method":"requestScreenshot","params":{{"scale":99,"nonce":"{}"}}}}"#,
                nonce
            ),
            0,
            &shared,
        );
        let sh = shared.lock().unwrap();
        assert_eq!(sh.screenshot_scale, 8);
    }

    #[test]
    fn trigger_hot_reload_sets_flag() {
        let shared = make_shared();
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        let msg = format!(
            r#"{{"id":15,"method":"triggerHotReload","params":{{"nonce":"{}"}}}}"#,
            nonce
        );
        handle_client_message(&msg, 0, &shared);
        let sh = shared.lock().unwrap();
        assert!(sh.hot_reload_requested);
    }

    #[test]
    fn concurrent_requests_do_not_panic() {
        let shared = make_shared();
        let nonce = shared.lock().unwrap().handshake_nonce.clone();
        let mut joins = Vec::new();
        for i in 0..8u64 {
            let shared_cloned = shared.clone();
            let nonce_cloned = nonce.clone();
            joins.push(std::thread::spawn(move || {
                let msg = format!(
                    r#"{{"id":{},"method":"getClientCount","params":{{"nonce":"{}"}}}}"#,
                    i, nonce_cloned
                );
                handle_client_message(&msg, i as usize, &shared_cloned);
            }));
        }
        for j in joins {
            j.join().unwrap();
        }
        let sh = shared.lock().unwrap();
        assert!(sh.pending_responses.len() >= 8);
    }

    #[test]
    fn server_thread_handles_basic_tcp_flow() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let addr = listener.local_addr().unwrap();
        let shared = Arc::new(Mutex::new(BridgeShared::new()));
        let running = Arc::new(AtomicBool::new(true));

        let server_shared = shared.clone();
        let server_running = running.clone();
        let server = std::thread::spawn(move || {
            lurek2d::debugbridge::server_thread(listener, server_shared, server_running);
        });

        let mut stream = TcpStream::connect(addr).unwrap();
        stream
            .set_read_timeout(Some(Duration::from_secs(1)))
            .unwrap();
        let mut reader = BufReader::new(stream.try_clone().unwrap());

        writeln!(stream, "{{\"id\":1,\"method\":\"ping\"}}").unwrap();
        stream.flush().unwrap();
        let mut line = String::new();
        reader.read_line(&mut line).unwrap();
        let ping_resp: serde_json::Value = serde_json::from_str(line.trim()).unwrap();
        let nonce = ping_resp["result"]["nonce"].as_str().unwrap().to_string();

        writeln!(
            stream,
            "{{\"id\":2,\"method\":\"hello\",\"version\":1,\"params\":{{\"nonce\":\"{}\"}}}}",
            nonce
        )
        .unwrap();
        stream.flush().unwrap();
        line.clear();
        reader.read_line(&mut line).unwrap();
        let hello_resp: serde_json::Value = serde_json::from_str(line.trim()).unwrap();
        assert_eq!(hello_resp["result"]["ok"], true);

        running.store(false, Ordering::Relaxed);
        server.join().unwrap();
    }
}
