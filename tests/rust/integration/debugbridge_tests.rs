//! Integration tests for `lurek2d::debugbridge` — BridgeShared, PendingRequest,
//! PendingResponse, PrintEntry, and SharedBridge.

use lurek2d::debugbridge::{BridgeShared, PendingRequest, PendingResponse, PrintEntry};

// ── BridgeShared::new ─────────────────────────────────────────────────────────

#[test]
fn bridge_shared_new_frame_times_empty() {
    let b = BridgeShared::new();
    assert!(b.frame_times.is_empty());
}

#[test]
fn bridge_shared_new_client_count_zero() {
    let b = BridgeShared::new();
    assert_eq!(b.client_count, 0);
}

#[test]
fn bridge_shared_new_screenshot_not_requested() {
    let b = BridgeShared::new();
    assert!(!b.screenshot_requested);
}

#[test]
fn bridge_shared_new_print_history_empty() {
    let b = BridgeShared::new();
    assert!(b.print_history.is_empty());
}

#[test]
fn bridge_shared_new_max_print_history_default() {
    let b = BridgeShared::new();
    assert_eq!(b.max_print_history, 2000);
}

#[test]
fn bridge_shared_new_pending_queues_empty() {
    let b = BridgeShared::new();
    assert!(b.pending_requests.is_empty());
    assert!(b.pending_responses.is_empty());
}

#[test]
fn bridge_shared_new_screenshot_scale_default() {
    let b = BridgeShared::new();
    assert_eq!(b.screenshot_scale, 1);
}

// ── BridgeShared::push_print ──────────────────────────────────────────────────

#[test]
fn bridge_shared_push_print_adds_to_history() {
    let mut b = BridgeShared::new();
    b.push_print("hello", "main.lua", 10);
    assert_eq!(b.print_history.len(), 1);
    assert_eq!(b.print_history[0].message, "hello");
}

#[test]
fn bridge_shared_push_print_records_source_and_line() {
    let mut b = BridgeShared::new();
    b.push_print("msg", "game.lua", 42);
    assert_eq!(b.print_history[0].source, "game.lua");
    assert_eq!(b.print_history[0].line, 42);
}

#[test]
fn bridge_shared_push_print_respects_max_history_limit() {
    let mut b = BridgeShared::new();
    b.max_print_history = 3;
    b.push_print("first", "a.lua", 1);
    b.push_print("second", "a.lua", 2);
    b.push_print("third", "a.lua", 3);
    b.push_print("fourth", "a.lua", 4); // should evict "first"
    assert_eq!(b.print_history.len(), 3);
    assert_eq!(b.print_history[0].message, "second");
    assert_eq!(b.print_history[2].message, "fourth");
}

#[test]
fn bridge_shared_push_print_multiple_preserves_order() {
    let mut b = BridgeShared::new();
    b.push_print("alpha", "x.lua", 1);
    b.push_print("beta", "x.lua", 2);
    assert_eq!(b.print_history[0].message, "alpha");
    assert_eq!(b.print_history[1].message, "beta");
}

// ── BridgeShared::elapsed ─────────────────────────────────────────────────────

#[test]
fn bridge_shared_elapsed_returns_non_negative() {
    let b = BridgeShared::new();
    assert!(b.elapsed() >= 0.0);
}

// ── BridgeShared::get_performance ────────────────────────────────────────────

#[test]
fn bridge_shared_get_performance_empty_returns_zero_fps() {
    let b = BridgeShared::new();
    let perf = b.get_performance();
    let fps = perf["fps"].as_f64().unwrap();
    assert!((fps - 0.0).abs() < 1e-5);
}

#[test]
fn bridge_shared_get_performance_has_expected_keys() {
    let b = BridgeShared::new();
    let perf = b.get_performance();
    assert!(perf.get("fps").is_some());
    assert!(perf.get("dt").is_some());
    assert!(perf.get("avgDt").is_some());
    assert!(perf.get("minDt").is_some());
    assert!(perf.get("maxDt").is_some());
}

#[test]
fn bridge_shared_get_performance_calculates_fps_from_frame_times() {
    let mut b = BridgeShared::new();
    // 10 frames at exactly 1/60 s each → should yield 60 fps
    for _ in 0..10 {
        b.frame_times.push(1.0 / 60.0);
    }
    let perf = b.get_performance();
    let fps = perf["fps"].as_f64().unwrap();
    assert!((fps - 60.0).abs() < 0.1);
}

#[test]
fn bridge_shared_get_performance_min_max_correct() {
    let mut b = BridgeShared::new();
    b.frame_times.push(0.010); // fast frame: 100 fps
    b.frame_times.push(0.020); // slow frame: 50 fps
    let perf = b.get_performance();
    let min_dt = perf["minDt"].as_f64().unwrap();
    let max_dt = perf["maxDt"].as_f64().unwrap();
    assert!((min_dt - 0.010).abs() < 1e-6);
    assert!((max_dt - 0.020).abs() < 1e-6);
}

// ── PrintEntry serialization ──────────────────────────────────────────────────

#[test]
fn print_entry_serializes_to_json_without_panic() {
    let entry = PrintEntry {
        timestamp: 1.23,
        message: "test message".to_string(),
        source: "main.lua".to_string(),
        line: 5,
    };
    let json = serde_json::to_string(&entry);
    assert!(json.is_ok());
    let s = json.unwrap();
    assert!(s.contains("test message"));
    assert!(s.contains("main.lua"));
}

// ── PendingRequest FIFO ordering ─────────────────────────────────────────────

#[test]
fn pending_request_fifo_ordering() {
    let mut b = BridgeShared::new();
    b.pending_requests.push_back(PendingRequest {
        id: 1,
        method: "eval".to_string(),
        params: serde_json::Value::Null,
        client_idx: 0,
    });
    b.pending_requests.push_back(PendingRequest {
        id: 2,
        method: "getLocals".to_string(),
        params: serde_json::Value::Null,
        client_idx: 0,
    });
    let first = b.pending_requests.pop_front().unwrap();
    let second = b.pending_requests.pop_front().unwrap();
    assert_eq!(first.id, 1);
    assert_eq!(second.id, 2);
}

// ── PendingResponse FIFO ordering ────────────────────────────────────────────

#[test]
fn pending_response_fifo_ordering() {
    let mut b = BridgeShared::new();
    b.pending_responses.push_back(PendingResponse {
        id: 10,
        result: serde_json::json!({"ok": true}),
        client_idx: 0,
    });
    b.pending_responses.push_back(PendingResponse {
        id: 20,
        result: serde_json::json!({"ok": false}),
        client_idx: 1,
    });
    let first = b.pending_responses.pop_front().unwrap();
    let second = b.pending_responses.pop_front().unwrap();
    assert_eq!(first.id, 10);
    assert_eq!(second.id, 20);
}

#[test]
fn pending_response_carries_client_idx() {
    let mut b = BridgeShared::new();
    b.pending_responses.push_back(PendingResponse {
        id: 5,
        result: serde_json::json!(42),
        client_idx: 3,
    });
    let r = b.pending_responses.pop_front().unwrap();
    assert_eq!(r.client_idx, 3);
}
