//! INTERNAL ONLY: Public debugbridge behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_debugbridge_unit.lua`.
//!
//! Rust-only coverage remains below for the low-level JSON-RPC message handler.

// ── server ────────────────────────────────────────────────────────────────────

mod server_tests {
    use lurek2d::debugbridge::{handle_client_message, BridgeShared};
    use std::sync::{Arc, Mutex};

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
    }

    #[test]
    fn get_performance_responds() {
        let shared = make_shared();
        handle_client_message(r#"{"id":2,"method":"getPerformance"}"#, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses.len(), 1);
        assert_eq!(sh.pending_responses[0].id, 2);
        assert!(sh.pending_responses[0].result.get("fps").is_some());
    }

    #[test]
    fn get_client_count_responds() {
        let shared = make_shared();
        handle_client_message(r#"{"id":3,"method":"getClientCount"}"#, 0, &shared);
        let sh = shared.lock().unwrap();
        assert_eq!(sh.pending_responses[0].result["count"], 0);
    }

    #[test]
    fn get_status_responds() {
        let shared = make_shared();
        handle_client_message(r#"{"id":4,"method":"getStatus"}"#, 0, &shared);
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
        handle_client_message(r#"{"id":5,"method":"clearPrintHistory"}"#, 0, &shared);
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
        handle_client_message(r#"{"id":6,"method":"getPrintHistory"}"#, 0, &shared);
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
        handle_client_message(
            r#"{"id":7,"method":"getPrintHistory","params":{"count":2}}"#,
            0,
            &shared,
        );
        let sh = shared.lock().unwrap();
        let result = &sh.pending_responses[0].result;
        assert_eq!(result.as_array().unwrap().len(), 2);
    }

    #[test]
    fn request_screenshot_sets_flag() {
        let shared = make_shared();
        handle_client_message(
            r#"{"id":8,"method":"requestScreenshot","params":{"scale":4}}"#,
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
        handle_client_message(
            r#"{"id":9,"method":"eval","params":{"code":"print(1)"}}"#,
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
        handle_client_message(r#"{"id":10,"method":"foobar"}"#, 0, &shared);
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
}
