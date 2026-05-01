//! INTERNAL ONLY: Rust-only tests for network helpers and internal data structures that are
//! not directly asserted through `lurek.network.*`.
//!
//! Public networking behaviour is covered by `tests/lua/unit/test_network_unit.lua`.
//! The remaining Rust tests keep constant/error/type/message/runtime helpers.

use lurek2d::network::constants::*;
use lurek2d::network::error::NetworkError;
use lurek2d::network::host::{HostRole, PeerStats};
use lurek2d::network::http::HttpResponse;
use lurek2d::network::lobby::{LobbyInfo, LOBBY_PORT};
use lurek2d::network::message::{estimate_size, pack, unpack, NetValue};
use lurek2d::network::net_thread::NetworkRuntime;
use std::net::{Ipv4Addr, SocketAddr};

// ── constants tests ──────────────────────────────────────────────────────────

mod constants_tests {
    use super::*;

    #[test]
    fn buffer_sizes_are_power_of_two() {
        assert!(TCP_BUFFER_SIZE.is_power_of_two());
        assert!(WS_BUFFER_SIZE.is_power_of_two());
    }

    #[test]
    fn http_timeout_nonzero() {
        assert!(HTTP_TIMEOUT_SECS > 0);
    }
}

// ── error tests ──────────────────────────────────────────────────────────────

mod error_tests {
    use super::*;

    #[test]
    fn peer_limit_display() {
        let e = NetworkError::PeerLimitExceeded {
            requested: 5000,
            max: 4096,
        };
        let msg = format!("{e}");
        assert!(msg.contains("5000"));
        assert!(msg.contains("4096"));
    }

    #[test]
    fn host_destroyed_display() {
        let e = NetworkError::HostDestroyed;
        assert_eq!(format!("{e}"), "host has been destroyed");
    }

    #[test]
    fn invalid_peer_display() {
        let e = NetworkError::InvalidPeer(99);
        assert!(format!("{e}").contains("99"));
    }

    #[test]
    fn io_error_from_conversion() {
        let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "no socket");
        let net_err: NetworkError = io_err.into();
        assert!(format!("{net_err}").contains("no socket"));
    }

    #[test]
    fn serialization_error_display() {
        let e = NetworkError::Serialization("bad data".to_string());
        assert!(format!("{e}").contains("bad data"));
    }
}

// ── host tests ───────────────────────────────────────────────────────────────

mod host_tests {
    use super::*;

    #[test]
    fn host_role_equality() {
        assert_eq!(HostRole::Server, HostRole::Server);
        assert_eq!(HostRole::Client, HostRole::Client);
        assert_eq!(HostRole::Host, HostRole::Host);
        assert_ne!(HostRole::Server, HostRole::Client);
    }

    #[test]
    fn host_role_copy_clone() {
        let r = HostRole::Server;
        let r2 = r; // Copy
        let r3 = r; // Clone
        assert_eq!(r, r2);
        assert_eq!(r, r3);
    }

    #[test]
    fn host_role_debug_format() {
        assert_eq!(format!("{:?}", HostRole::Server), "Server");
        assert_eq!(format!("{:?}", HostRole::Client), "Client");
        assert_eq!(format!("{:?}", HostRole::Host), "Host");
    }

    #[test]
    fn peer_stats_has_all_fields() {
        let stats = PeerStats {
            round_trip_time: 42,
            round_trip_time_variance: 5,
            packets_sent: 100,
            packets_lost: 2,
            packet_loss: 200,
            incoming_bandwidth: 0,
            outgoing_bandwidth: 0,
            incoming_data_total: 50000,
            outgoing_data_total: 30000,
        };
        assert_eq!(stats.round_trip_time, 42);
        assert_eq!(stats.packets_lost, 2);
        assert_eq!(stats.incoming_data_total, 50000);
    }
}

// ── http tests ───────────────────────────────────────────────────────────────

mod http_tests {
    use super::*;

    #[test]
    fn http_response_default_fields() {
        let resp = HttpResponse {
            status: 200,
            body: vec![72, 105],
            headers: vec![("Content-Type".to_string(), "text/plain".to_string())],
            error: None,
        };
        assert_eq!(resp.status, 200);
        assert_eq!(resp.body, b"Hi");
        assert!(resp.error.is_none());
    }

    #[test]
    fn http_response_with_error() {
        let resp = HttpResponse {
            status: 0,
            body: Vec::new(),
            headers: Vec::new(),
            error: Some("connection refused".to_string()),
        };
        assert_eq!(resp.status, 0);
        assert!(resp.error.unwrap().contains("connection refused"));
    }

    #[test]
    fn http_response_empty_body_and_headers() {
        let resp = HttpResponse {
            status: 204,
            body: Vec::new(),
            headers: Vec::new(),
            error: None,
        };
        assert_eq!(resp.status, 204);
        assert!(resp.body.is_empty());
        assert!(resp.headers.is_empty());
    }

    #[test]
    fn http_response_multiple_headers() {
        let resp = HttpResponse {
            status: 200,
            body: Vec::new(),
            headers: vec![
                ("X-A".to_string(), "1".to_string()),
                ("X-B".to_string(), "2".to_string()),
            ],
            error: None,
        };
        assert_eq!(resp.headers.len(), 2);
        assert_eq!(resp.headers[0].0, "X-A");
    }
}

// ── lobby tests ──────────────────────────────────────────────────────────────

mod lobby_tests {
    use super::*;

    fn dummy_addr() -> SocketAddr {
        SocketAddr::new(Ipv4Addr::new(192, 168, 1, 10).into(), 47777)
    }

    #[test]
    fn lobby_info_roundtrip_wire_format() {
        let info = LobbyInfo {
            name: "MyGame".to_string(),
            host: "192.168.1.10".to_string(),
            port: 7777,
            player_count: 2,
            max_players: 8,
        };
        let wire = info.to_wire();
        let parsed = LobbyInfo::from_wire(&wire, dummy_addr()).unwrap();
        assert_eq!(parsed.name, "MyGame");
        assert_eq!(parsed.port, 7777);
        assert_eq!(parsed.player_count, 2);
        assert_eq!(parsed.max_players, 8);
    }

    #[test]
    fn lobby_info_from_wire_missing_name_returns_none() {
        let wire = "host=127.0.0.1;port=7777;players=1;max=4";
        assert!(LobbyInfo::from_wire(wire, dummy_addr()).is_none());
    }

    #[test]
    fn lobby_info_from_wire_missing_port_returns_none() {
        let wire = "name=Test;host=127.0.0.1;players=1;max=4";
        assert!(LobbyInfo::from_wire(wire, dummy_addr()).is_none());
    }

    #[test]
    fn lobby_info_fallback_host_from_sender() {
        let wire = "name=Test;port=7777;players=0;max=2";
        let sender: SocketAddr = "10.0.0.5:47777".parse().unwrap();
        let info = LobbyInfo::from_wire(wire, sender).unwrap();
        assert_eq!(info.host, "10.0.0.5");
    }

    #[test]
    fn lobby_info_defaults_for_optional_fields() {
        let wire = "name=Test;port=8000";
        let parsed = LobbyInfo::from_wire(wire, dummy_addr()).unwrap();
        assert_eq!(parsed.player_count, 0);
        assert_eq!(parsed.max_players, 0);
    }

    #[test]
    fn lobby_info_ignores_unknown_fields() {
        let wire = "name=Test;port=8000;extra=foo;players=3;max=10";
        let parsed = LobbyInfo::from_wire(wire, dummy_addr()).unwrap();
        assert_eq!(parsed.name, "Test");
        assert_eq!(parsed.player_count, 3);
    }

    #[test]
    fn lobby_info_equality() {
        let a = LobbyInfo {
            name: "A".to_string(),
            host: "1.2.3.4".to_string(),
            port: 7777,
            player_count: 1,
            max_players: 4,
        };
        let b = a.clone();
        assert_eq!(a, b);
    }

    #[test]
    fn lobby_port_constant() {
        assert_eq!(LOBBY_PORT, 47_777);
    }
}

// ── message tests ────────────────────────────────────────────────────────────

mod message_tests {
    use super::*;

    #[test]
    fn round_trip_nil() {
        let val = NetValue::Nil;
        let packed = pack(&val).unwrap();
        let unpacked = unpack(&packed).unwrap();
        assert_eq!(val, unpacked);
    }

    #[test]
    fn round_trip_bool() {
        for b in &[true, false] {
            let val = NetValue::Bool(*b);
            let packed = pack(&val).unwrap();
            let unpacked = unpack(&packed).unwrap();
            assert_eq!(val, unpacked);
        }
    }

    #[test]
    fn round_trip_integer() {
        for n in &[0i64, 1, -1, 127, -32, 1000, -1000, i64::MAX, i64::MIN] {
            let val = NetValue::Integer(*n);
            let packed = pack(&val).unwrap();
            let unpacked = unpack(&packed).unwrap();
            assert_eq!(val, unpacked);
        }
    }

    #[test]
    fn round_trip_float() {
        let val = NetValue::Float(3.14159);
        let packed = pack(&val).unwrap();
        let unpacked = unpack(&packed).unwrap();
        assert_eq!(val, unpacked);
    }

    #[test]
    fn round_trip_string() {
        let val = NetValue::String("hello world".to_string());
        let packed = pack(&val).unwrap();
        let unpacked = unpack(&packed).unwrap();
        assert_eq!(val, unpacked);
    }

    #[test]
    fn round_trip_array() {
        let val = NetValue::Array(vec![
            NetValue::Integer(1),
            NetValue::String("two".to_string()),
            NetValue::Bool(true),
        ]);
        let packed = pack(&val).unwrap();
        let unpacked = unpack(&packed).unwrap();
        assert_eq!(val, unpacked);
    }

    #[test]
    fn round_trip_nested_map() {
        let val = NetValue::Map(vec![
            ("type".to_string(), NetValue::String("move".to_string())),
            ("x".to_string(), NetValue::Float(150.5)),
            ("y".to_string(), NetValue::Float(200.0)),
            (
                "nested".to_string(),
                NetValue::Map(vec![("deep".to_string(), NetValue::Integer(42))]),
            ),
        ]);
        let packed = pack(&val).unwrap();
        let unpacked = unpack(&packed).unwrap();
        assert_eq!(val, unpacked);
    }

    #[test]
    fn empty_data_returns_error() {
        assert!(unpack(&[]).is_err());
    }

    #[test]
    fn estimate_size_basic() {
        assert_eq!(estimate_size(&NetValue::Nil), 1);
        assert_eq!(estimate_size(&NetValue::Bool(true)), 1);
        assert!(estimate_size(&NetValue::Integer(42)) <= 2);
    }
}

// ── net_thread tests ─────────────────────────────────────────────────────────

mod net_thread_tests {
    use super::*;
    use lurek2d::network::net_thread::{NetworkRequest, TcpEvent, WsEvent};

    #[test]
    fn network_request_debug_format() {
        let req = NetworkRequest::Shutdown;
        let dbg = format!("{:?}", req);
        assert!(dbg.contains("Shutdown"));
    }

    #[test]
    fn tcp_event_clone() {
        let e = TcpEvent::Connected;
        let e2 = e.clone();
        assert!(matches!(e2, TcpEvent::Connected));
    }

    #[test]
    fn tcp_event_data_clone() {
        let e = TcpEvent::Data(vec![1, 2, 3]);
        let e2 = e.clone();
        if let TcpEvent::Data(d) = e2 {
            assert_eq!(d, vec![1, 2, 3]);
        } else {
            panic!("expected Data variant");
        }
    }

    #[test]
    fn ws_event_clone() {
        let e = WsEvent::Open;
        let e2 = e.clone();
        assert!(matches!(e2, WsEvent::Open));
    }

    #[test]
    fn ws_event_text_clone() {
        let e = WsEvent::Text("hello".to_string());
        let e2 = e.clone();
        if let WsEvent::Text(s) = e2 {
            assert_eq!(s, "hello");
        } else {
            panic!("expected Text variant");
        }
    }

    #[test]
    fn ws_event_close_clone() {
        let e = WsEvent::Close {
            code: 1000,
            reason: "normal".to_string(),
        };
        let e2 = e.clone();
        if let WsEvent::Close { code, reason } = e2 {
            assert_eq!(code, 1000);
            assert_eq!(reason, "normal");
        } else {
            panic!("expected Close variant");
        }
    }

    #[test]
    fn network_runtime_starts_and_shuts_down() {
        let mut rt = NetworkRuntime::new().expect("should spawn network thread");
        assert!(rt.is_running());
        let responses = rt.poll();
        assert!(responses.is_empty());
        rt.shutdown();
        assert!(!rt.is_running());
    }

    #[test]
    fn network_runtime_double_shutdown_is_safe() {
        let mut rt = NetworkRuntime::new().expect("should spawn");
        rt.shutdown();
        rt.shutdown();
        assert!(!rt.is_running());
    }

    #[test]
    fn next_request_id_monotonically_increases() {
        let mut rt = NetworkRuntime::new().expect("should spawn");
        let id1 = rt.next_request_id();
        let id2 = rt.next_request_id();
        let id3 = rt.next_request_id();
        assert!(id2 > id1);
        assert!(id3 > id2);
        rt.shutdown();
    }
}

// ── tcp tests ────────────────────────────────────────────────────────────────

mod tcp_tests {
    use lurek2d::network::net_thread::{NetworkResponse, TcpEvent};
    use lurek2d::network::tcp::TcpConnectionManager;
    use std::sync::mpsc;

    #[test]
    fn new_manager_has_no_connections() {
        let mgr = TcpConnectionManager::new();
        assert!(mgr.is_empty());
    }

    #[test]
    fn default_matches_new() {
        let mgr = TcpConnectionManager::default();
        assert!(mgr.is_empty());
    }

    #[test]
    fn close_all_on_empty_is_noop() {
        let mut mgr = TcpConnectionManager::new();
        mgr.close_all();
        assert!(mgr.is_empty());
    }

    #[test]
    fn close_nonexistent_sends_disconnect() {
        let mut mgr = TcpConnectionManager::new();
        let (tx, rx) = mpsc::channel();
        // Closing an ID that was never connected should silently do nothing
        // (no entry in the map → no response sent).
        mgr.close(999, &tx);
        assert!(rx.try_recv().is_err());
    }

    #[test]
    fn send_to_nonexistent_sends_error() {
        let mut mgr = TcpConnectionManager::new();
        let (tx, rx) = mpsc::channel();
        mgr.send(42, b"hello", &tx);
        let resp = rx.try_recv().unwrap();
        if let NetworkResponse::TcpEvent { id, event } = resp {
            assert_eq!(id, 42);
            match event {
                TcpEvent::Error(msg) => assert!(msg.contains("not found")),
                other => panic!("expected Error, got {:?}", other),
            }
        } else {
            panic!("expected TcpEvent");
        }
    }
}

// ── websocket tests ──────────────────────────────────────────────────────────

mod websocket_tests {
    use lurek2d::network::net_thread::{NetworkResponse, WsEvent};
    use lurek2d::network::websocket::WebSocketManager;
    use std::sync::mpsc;

    #[test]
    fn new_manager_has_no_connections() {
        let mgr = WebSocketManager::new();
        assert!(mgr.is_empty());
    }

    #[test]
    fn default_matches_new() {
        let mgr = WebSocketManager::default();
        assert!(mgr.is_empty());
    }

    #[test]
    fn close_all_on_empty_is_noop() {
        let mut mgr = WebSocketManager::new();
        mgr.close_all();
        assert!(mgr.is_empty());
    }

    #[test]
    fn send_to_nonexistent_sends_error() {
        let mut mgr = WebSocketManager::new();
        let (tx, rx) = mpsc::channel();
        mgr.send(77, b"msg", true, &tx);
        let resp = rx.try_recv().unwrap();
        if let NetworkResponse::WebSocketEvent { id, event } = resp {
            assert_eq!(id, 77);
            match event {
                WsEvent::Error(msg) => assert!(msg.contains("not found")),
                other => panic!("expected Error, got {:?}", other),
            }
        } else {
            panic!("expected WebSocketEvent");
        }
    }
}
