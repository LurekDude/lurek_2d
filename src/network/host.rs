//! ENet-based network host: peer management, send/receive, and connection lifecycle.
//! Wraps `rusty_enet` for reliable and unreliable UDP transport over a `UdpSocket`.
//! Does not own the Tokio thread or game-state sync; those live in `net_thread` and `net_sync`.
//! Key dependencies: `rusty_enet`, `constants` for limits, `error::NetworkError`.

use super::constants::{DEFAULT_CHANNELS, DEFAULT_PEERS, MAX_PEERS};
use super::error::NetworkError;
use crate::log_msg;
use crate::runtime::log_messages::{NW01_HOST_BIND, NW04_NET_ERROR};
use rusty_enet::{self as enet, Host, HostSettings, Packet, PacketKind, PeerID};
use std::net::{SocketAddr, UdpSocket};
use std::time::Duration;
/// Logical role of this host in a multiplayer session.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HostRole {
    /// Dedicated or listen server that accepts incoming peers.
    Server,
    /// Client that connects to a remote server with a single peer slot.
    Client,
    /// Combined host/client running both sides locally.
    Host,
}
/// ENet host wrapping a UDP socket; owns all peer slots for one network endpoint.
pub struct NetworkHost {
    /// Underlying ENet host; `None` after `destroy()` is called.
    inner: Option<Host<UdpSocket>>,
    /// Bound socket address resolved at creation time.
    local_addr: SocketAddr,
    /// Role assigned at creation or via `set_role`.
    role: HostRole,
}
/// Events emitted by `NetworkHost::service` on each poll cycle.
pub enum NetworkEvent {
    /// A remote peer completed the ENet handshake and is now connected.
    Connect {
        /// ENet peer identifier assigned to the new peer.
        peer_id: PeerID,
        /// Application-defined connection data sent by the peer.
        data: u32,
    },
    /// A remote peer disconnected or timed out.
    Disconnect {
        /// ENet peer identifier of the disconnected peer.
        peer_id: PeerID,
        /// Application-defined disconnection reason code.
        data: u32,
    },
    /// A packet arrived from a remote peer on a specific channel.
    Receive {
        /// ENet peer identifier of the sender.
        peer_id: PeerID,
        /// Channel index the packet was sent on.
        channel_id: u8,
        /// Raw packet payload bytes.
        data: Vec<u8>,
    },
}
impl NetworkHost {
    /// Create and bind a new ENet host; returns `PeerLimitExceeded` if `peer_count` exceeds `MAX_PEERS`.
    pub fn new(
        bind_addr: SocketAddr,
        peer_count: Option<usize>,
        channel_count: Option<usize>,
        in_bandwidth: Option<u32>,
        out_bandwidth: Option<u32>,
    ) -> Result<Self, NetworkError> {
        let peers = peer_count.unwrap_or(DEFAULT_PEERS);
        if peers > MAX_PEERS {
            log_msg!(
                error,
                NW04_NET_ERROR,
                "peer limit: {} > {}",
                peers,
                MAX_PEERS
            );
            return Err(NetworkError::PeerLimitExceeded {
                requested: peers,
                max: MAX_PEERS,
            });
        }
        let channels = channel_count.unwrap_or(DEFAULT_CHANNELS);
        let socket = UdpSocket::bind(bind_addr)?;
        socket.set_nonblocking(true)?;
        let local_addr = socket.local_addr()?;
        let settings = HostSettings {
            peer_limit: peers,
            channel_limit: channels,
            incoming_bandwidth_limit: in_bandwidth,
            outgoing_bandwidth_limit: out_bandwidth,
            ..HostSettings::default()
        };
        let host = Host::new(socket, settings).map_err(|e| NetworkError::Enet(format!("{e}")))?;
        log_msg!(info, NW01_HOST_BIND, "{}", local_addr);
        Ok(Self {
            inner: Some(host),
            local_addr,
            role: HostRole::Host,
        })
    }
    /// Return a shared reference to the inner ENet host; returns `HostDestroyed` if destroyed.
    fn host(&self) -> Result<&Host<UdpSocket>, NetworkError> {
        self.inner.as_ref().ok_or(NetworkError::HostDestroyed)
    }
    /// Return a mutable reference to the inner ENet host; returns `HostDestroyed` if destroyed.
    fn host_mut(&mut self) -> Result<&mut Host<UdpSocket>, NetworkError> {
        self.inner.as_mut().ok_or(NetworkError::HostDestroyed)
    }
    /// Poll the ENet host for one pending event; returns `None` when the queue is empty.
    pub fn service(&mut self) -> Result<Option<NetworkEvent>, NetworkError> {
        let host = self.host_mut()?;
        match host.service() {
            Ok(Some(event)) => {
                let net_event = match event.no_ref() {
                    enet::EventNoRef::Connect { peer, data } => NetworkEvent::Connect {
                        peer_id: peer,
                        data,
                    },
                    enet::EventNoRef::Disconnect { peer, data } => NetworkEvent::Disconnect {
                        peer_id: peer,
                        data,
                    },
                    enet::EventNoRef::Receive {
                        peer,
                        channel_id,
                        packet,
                    } => NetworkEvent::Receive {
                        peer_id: peer,
                        channel_id,
                        data: packet.data().to_vec(),
                    },
                };
                Ok(Some(net_event))
            }
            Ok(None) => Ok(None),
            Err(e) => Err(NetworkError::Enet(format!("{e}"))),
        }
    }
    /// Initiate a connection to `address` and return the assigned `PeerID` on success.
    pub fn connect(
        &mut self,
        address: SocketAddr,
        channel_count: usize,
        data: u32,
    ) -> Result<PeerID, NetworkError> {
        let host = self.host_mut()?;
        let peer = host
            .connect(address, channel_count, data)
            .map_err(|e| NetworkError::Enet(format!("{e}")))?;
        Ok(peer.id())
    }
    /// Send a pre-built `Packet` to the given peer on `channel_id`.
    pub fn send(
        &mut self,
        peer_id: PeerID,
        channel_id: u8,
        packet: Packet,
    ) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        let peer = host.peer_mut(peer_id);
        let _ = peer.send(channel_id, &packet);
        Ok(())
    }
    /// Send raw bytes to a peer; uses reliable ordered delivery when `reliable` is `true`.
    pub fn send_bytes(
        &mut self,
        peer_id: PeerID,
        channel_id: u8,
        data: &[u8],
        reliable: bool,
    ) -> Result<(), NetworkError> {
        let kind = if reliable {
            PacketKind::Reliable
        } else {
            PacketKind::Unreliable { sequenced: true }
        };
        self.send(peer_id, channel_id, Packet::new(data, kind))
    }
    /// Broadcast a pre-built `Packet` to all connected peers on `channel_id`.
    pub fn broadcast(&mut self, channel_id: u8, packet: &Packet) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.broadcast(channel_id, packet);
        Ok(())
    }
    /// Broadcast raw bytes to all connected peers; uses reliable delivery when `reliable` is `true`.
    pub fn broadcast_bytes(
        &mut self,
        channel_id: u8,
        data: &[u8],
        reliable: bool,
    ) -> Result<(), NetworkError> {
        let kind = if reliable {
            PacketKind::Reliable
        } else {
            PacketKind::Unreliable { sequenced: true }
        };
        let packet = Packet::new(data, kind);
        self.broadcast(channel_id, &packet)
    }
    /// Flush the host's outgoing packet queue to the socket immediately.
    pub fn flush(&mut self) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.flush();
        Ok(())
    }
    /// Begin a graceful ENet disconnect handshake with the peer.
    pub fn disconnect(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect(data);
        Ok(())
    }
    /// Immediately forcibly disconnect the peer without a handshake.
    pub fn disconnect_now(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect_now(data);
        Ok(())
    }
    /// Queue a graceful disconnect after all queued outgoing packets have been sent.
    pub fn disconnect_later(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect_later(data);
        Ok(())
    }
    /// Reset a peer's state to `Disconnected` without sending any disconnect notification.
    pub fn reset_peer(&mut self, peer_id: PeerID) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).reset();
        Ok(())
    }
    /// Send a ping packet to the peer to refresh the round-trip-time estimate.
    pub fn ping(&mut self, peer_id: PeerID) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).ping();
        Ok(())
    }
    /// Return the current measured round-trip time for the peer; returns `InvalidPeer` if unknown.
    pub fn round_trip_time(&self, peer_id: PeerID) -> Result<Duration, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(peer.round_trip_time())
    }
    /// Return the ENet connection state of the peer as a static string label.
    pub fn peer_state(&self, peer_id: PeerID) -> Result<&'static str, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        let state_str = match peer.state() {
            enet::PeerState::Disconnected => "disconnected",
            enet::PeerState::Connecting => "connecting",
            enet::PeerState::AcknowledgingConnect => "acknowledging_connect",
            enet::PeerState::ConnectionPending => "connection_pending",
            enet::PeerState::ConnectionSucceeded => "connection_succeeded",
            enet::PeerState::Connected => "connected",
            enet::PeerState::DisconnectLater => "disconnect_later",
            enet::PeerState::Disconnecting => "disconnecting",
            enet::PeerState::AcknowledgingDisconnect => "acknowledging_disconnect",
            enet::PeerState::Zombie => "zombie",
        };
        Ok(state_str)
    }
    /// Return the remote socket address of the peer, or `None` if the address is not available.
    pub fn peer_address(&self, peer_id: PeerID) -> Result<Option<SocketAddr>, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(peer.address())
    }
    /// Return the local socket address this host is bound to.
    pub fn local_address(&self) -> SocketAddr {
        self.local_addr
    }
    /// Return the maximum number of peer slots configured for this host.
    pub fn peer_limit(&self) -> Result<usize, NetworkError> {
        let host = self.host()?;
        Ok(host.peer_limit())
    }
    /// Return the current per-peer channel count limit.
    pub fn channel_limit(&self) -> Result<usize, NetworkError> {
        let host = self.host()?;
        Ok(host.channel_limit())
    }
    /// Set the per-peer channel count limit; returns `Enet` error if rejected.
    pub fn set_channel_limit(&mut self, limit: usize) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.set_channel_limit(limit)
            .map_err(|e| NetworkError::Enet(format!("{e}")))
    }
    /// Return the current `(incoming, outgoing)` bandwidth limits in bytes/sec; `None` means unlimited.
    pub fn bandwidth_limit(&self) -> Result<(Option<u32>, Option<u32>), NetworkError> {
        let host = self.host()?;
        Ok(host.bandwidth_limit())
    }
    /// Set the incoming and outgoing bandwidth limits in bytes/sec; `None` removes the limit.
    pub fn set_bandwidth_limit(
        &mut self,
        incoming: Option<u32>,
        outgoing: Option<u32>,
    ) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.set_bandwidth_limit(incoming, outgoing)
            .map_err(|e| NetworkError::Enet(format!("{e}")))
    }
    /// Return the number of currently connected peers.
    pub fn connected_peer_count(&mut self) -> Result<usize, NetworkError> {
        let host = self.host_mut()?;
        Ok(host.connected_peers().count())
    }
    /// Drop the inner ENet host, releasing the socket; subsequent calls to methods return `HostDestroyed`.
    pub fn destroy(&mut self) {
        self.inner = None;
    }
    /// Return `true` if `destroy()` has been called and the host is no longer usable.
    pub fn is_destroyed(&self) -> bool {
        self.inner.is_none()
    }
    /// Return a list of `PeerID` values for all currently connected peers.
    pub fn connected_peer_ids(&mut self) -> Result<Vec<PeerID>, NetworkError> {
        let host = self.host_mut()?;
        Ok(host.connected_peers().map(|p| p.id()).collect())
    }
    /// Convenience constructor that binds a server on `0.0.0.0:<port>` with `Server` role.
    pub fn create_server(
        port: u16,
        max_peers: Option<usize>,
        channels: Option<usize>,
    ) -> Result<Self, NetworkError> {
        let addr_str = format!("0.0.0.0:{}", port);
        let addr: SocketAddr = addr_str
            .parse()
            .map_err(|e: std::net::AddrParseError| NetworkError::InvalidAddress(e.to_string()))?;
        let mut host = Self::new(
            addr,
            max_peers.or(Some(DEFAULT_PEERS)),
            channels,
            None,
            None,
        )?;
        host.role = HostRole::Server;
        Ok(host)
    }
    /// Convenience constructor that binds an ephemeral port, connects to `address`, and sets `Client` role.
    pub fn create_client(
        address: SocketAddr,
        channels: Option<usize>,
        data: Option<u32>,
    ) -> Result<Self, NetworkError> {
        let bind_addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
        let mut host = Self::new(bind_addr, Some(1), channels, None, None)?;
        host.role = HostRole::Client;
        let _ = host.connect(
            address,
            channels.unwrap_or(DEFAULT_CHANNELS),
            data.unwrap_or(0),
        )?;
        Ok(host)
    }
    /// Return the current `HostRole` of this host.
    pub fn role(&self) -> HostRole {
        self.role
    }
    /// Override the host role; used when role is determined after creation.
    pub fn set_role(&mut self, role: HostRole) {
        self.role = role;
    }
    /// Collect and return a `PeerStats` snapshot for the given peer; returns `InvalidPeer` if unknown.
    pub fn peer_stats(&self, peer_id: PeerID) -> Result<PeerStats, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(PeerStats {
            round_trip_time: peer.round_trip_time().as_millis() as u32,
            round_trip_time_variance: peer.round_trip_time_variance().as_millis() as u32,
            packets_sent: peer.packets_sent(),
            packets_lost: peer.packets_lost(),
            packet_loss: peer.packet_loss(),
            incoming_bandwidth: peer.incoming_bandwidth(),
            outgoing_bandwidth: peer.outgoing_bandwidth(),
            incoming_data_total: peer.incoming_data_total(),
            outgoing_data_total: peer.outgoing_data_total(),
        })
    }
}
/// Point-in-time network statistics snapshot for a single ENet peer.
pub struct PeerStats {
    /// Smoothed round-trip time in milliseconds.
    pub round_trip_time: u32,
    /// Variance of the round-trip time measurement in milliseconds.
    pub round_trip_time_variance: u32,
    /// Total packets sent to this peer since connection.
    pub packets_sent: u32,
    /// Total packets lost in transit to this peer since connection.
    pub packets_lost: u32,
    /// Fixed-point packet loss ratio (0 = no loss, 65536 = 100% loss).
    pub packet_loss: u32,
    /// Negotiated incoming bandwidth limit in bytes/sec (0 = unlimited).
    pub incoming_bandwidth: u32,
    /// Negotiated outgoing bandwidth limit in bytes/sec (0 = unlimited).
    pub outgoing_bandwidth: u32,
    /// Total bytes received from this peer since connection.
    pub incoming_data_total: u32,
    /// Total bytes sent to this peer since connection.
    pub outgoing_data_total: u32,
}
