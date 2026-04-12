//! Integration tests for the Lurek2D network module.

use lurek2d::network::constants::{DEFAULT_CHANNELS, DEFAULT_PEERS, MAX_CHANNELS, MAX_PEERS};
use lurek2d::network::error::NetworkError;
use lurek2d::network::host::NetworkHost;
use std::net::SocketAddr;

// ── Constants ────────────────────────────────────────────────────────

#[test]
fn constants_values() {
    assert_eq!(MAX_PEERS, 8);
    assert_eq!(DEFAULT_PEERS, 4);
    assert_eq!(MAX_CHANNELS, 255);
    assert_eq!(DEFAULT_CHANNELS, 1);
}

#[test]
fn default_peers_within_max() {
    assert!(DEFAULT_PEERS <= MAX_PEERS);
}

// ── Host creation ────────────────────────────────────────────────────

#[test]
fn create_host_client_defaults() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, None, None, None, None).unwrap();
    assert!(!host.is_destroyed());
    assert_eq!(host.peer_limit().unwrap(), DEFAULT_PEERS);
    assert_eq!(host.channel_limit().unwrap(), DEFAULT_CHANNELS);
}

#[test]
fn create_host_custom_peers() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, Some(6), None, None, None).unwrap();
    assert_eq!(host.peer_limit().unwrap(), 6);
}

#[test]
fn create_host_max_peers() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, Some(MAX_PEERS), None, None, None).unwrap();
    assert_eq!(host.peer_limit().unwrap(), MAX_PEERS);
}

#[test]
fn create_host_exceeds_peer_limit() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let result = NetworkHost::new(addr, Some(MAX_PEERS + 1), None, None, None);
    assert!(result.is_err());
    match result {
        Err(NetworkError::PeerLimitExceeded { requested, max }) => {
            assert_eq!(requested, MAX_PEERS + 1);
            assert_eq!(max, MAX_PEERS);
        }
        Err(other) => panic!("Expected PeerLimitExceeded, got {:?}", other),
        Ok(_) => panic!("Expected error, got Ok"),
    }
}

#[test]
fn create_host_custom_channels() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, None, Some(4), None, None).unwrap();
    assert_eq!(host.channel_limit().unwrap(), 4);
}

#[test]
fn create_host_with_bandwidth() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, None, None, Some(56000), Some(14000)).unwrap();
    let (in_bw, out_bw) = host.bandwidth_limit().unwrap();
    assert_eq!(in_bw, Some(56000));
    assert_eq!(out_bw, Some(14000));
}

#[test]
fn create_host_unlimited_bandwidth() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, None, None, None, None).unwrap();
    let (in_bw, out_bw) = host.bandwidth_limit().unwrap();
    assert_eq!(in_bw, None);
    assert_eq!(out_bw, None);
}

// ── Local address ────────────────────────────────────────────────────

#[test]
fn local_address_assigned() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, None, None, None, None).unwrap();
    let local = host.local_address();
    // OS should have assigned a real port
    assert_ne!(local.port(), 0);
}

// ── Service (no events) ─────────────────────────────────────────────

#[test]
fn service_no_events() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    let event = host.service().unwrap();
    assert!(event.is_none());
}

#[test]
fn service_multiple_calls_no_events() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    for _ in 0..10 {
        let event = host.service().unwrap();
        assert!(event.is_none());
    }
}

// ── Connected peer count ─────────────────────────────────────────────

#[test]
fn connected_peer_count_initially_zero() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    assert_eq!(host.connected_peer_count().unwrap(), 0);
}

// ── Destroy ──────────────────────────────────────────────────────────

#[test]
fn destroy_host() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    assert!(!host.is_destroyed());
    host.destroy();
    assert!(host.is_destroyed());
}

#[test]
fn service_after_destroy_errors() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    host.destroy();
    let result = host.service();
    assert!(result.is_err());
    match result {
        Err(NetworkError::HostDestroyed) => {}
        Err(other) => panic!("Expected HostDestroyed, got {:?}", other),
        Ok(_) => panic!("Expected error, got Ok"),
    }
}

#[test]
fn peer_limit_after_destroy_errors() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    host.destroy();
    assert!(host.peer_limit().is_err());
}

#[test]
fn flush_after_destroy_errors() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    host.destroy();
    assert!(host.flush().is_err());
}

#[test]
fn double_destroy_safe() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    host.destroy();
    host.destroy(); // should not panic
    assert!(host.is_destroyed());
}

// ── Bandwidth limits ─────────────────────────────────────────────────

#[test]
fn set_bandwidth_limit() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    host.set_bandwidth_limit(Some(100_000), Some(50_000))
        .unwrap();
    let (in_bw, out_bw) = host.bandwidth_limit().unwrap();
    assert_eq!(in_bw, Some(100_000));
    assert_eq!(out_bw, Some(50_000));
}

// ── Flush ────────────────────────────────────────────────────────────

#[test]
fn flush_no_pending() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let mut host = NetworkHost::new(addr, None, None, None, None).unwrap();
    host.flush().unwrap();
}

// ── Server bind ──────────────────────────────────────────────────────

#[test]
fn create_server_host() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host = NetworkHost::new(addr, Some(4), Some(2), None, None).unwrap();
    let local = host.local_address();
    assert_ne!(local.port(), 0);
    assert_eq!(host.peer_limit().unwrap(), 4);
    assert_eq!(host.channel_limit().unwrap(), 2);
}

// ── Multiple hosts ───────────────────────────────────────────────────

#[test]
fn multiple_hosts_different_ports() {
    let addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
    let host1 = NetworkHost::new(addr, None, None, None, None).unwrap();
    let host2 = NetworkHost::new(addr, None, None, None, None).unwrap();
    assert_ne!(host1.local_address().port(), host2.local_address().port());
}

// ── Error display ────────────────────────────────────────────────────

#[test]
fn error_display_peer_limit() {
    let err = NetworkError::PeerLimitExceeded {
        requested: 16,
        max: 8,
    };
    let msg = format!("{err}");
    assert!(msg.contains("16"));
    assert!(msg.contains("8"));
}

#[test]
fn error_display_host_destroyed() {
    let err = NetworkError::HostDestroyed;
    let msg = format!("{err}");
    assert!(msg.contains("destroyed"));
}

#[test]
fn error_display_invalid_peer() {
    let err = NetworkError::InvalidPeer(42);
    let msg = format!("{err}");
    assert!(msg.contains("42"));
}

#[test]
fn error_display_invalid_address() {
    let err = NetworkError::InvalidAddress("bad:addr".to_string());
    let msg = format!("{err}");
    assert!(msg.contains("bad:addr"));
}
