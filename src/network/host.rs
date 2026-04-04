//! ENet host wrapper for the Luna2D networking subsystem.
//!
//! [`NetworkHost`] owns a `rusty_enet::Host<UdpSocket>` and provides a safe
//! Rust API that the Lua binding layers (`network_api`, `net_api`) consume.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::net::{SocketAddr, UdpSocket};
use std::time::Duration;

use rusty_enet::{self as enet, Host, HostSettings, Packet, PeerID};

use super::constants::{DEFAULT_CHANNELS, DEFAULT_PEERS, MAX_PEERS};
use super::error::NetworkError;

/// Wraps a `rusty_enet::Host<UdpSocket>` with Luna2D-specific defaults and
/// limit enforcement.
///
/// Created once per logical network endpoint (server or client). The caller
/// must pump [`service`](Self::service) every frame to process I/O.
pub struct NetworkHost {
    /// The underlying ENet host. `None` after [`destroy`](Self::destroy).
    inner: Option<Host<UdpSocket>>,
    /// The local address the socket is bound to.
    local_addr: SocketAddr,
}

/// Result of a single [`NetworkHost::service`] call.
pub enum NetworkEvent {
    /// A remote peer completed the connection handshake.
    Connect {
        /// Index of the newly connected peer.
        peer_id: PeerID,
        /// Application-defined data carried in the connect packet.
        data: u32,
    },
    /// A remote peer disconnected (gracefully or timed out).
    Disconnect {
        /// Index of the disconnected peer.
        peer_id: PeerID,
        /// Application-defined data carried in the disconnect packet.
        data: u32,
    },
    /// A data packet arrived from a remote peer.
    Receive {
        /// Index of the sending peer.
        peer_id: PeerID,
        /// Channel the packet arrived on.
        channel_id: u8,
        /// Packet payload (binary data).
        data: Vec<u8>,
    },
}

impl NetworkHost {
    /// Create a new ENet host bound to `bind_addr`.
    ///
    /// # Parameters
    /// - `bind_addr` — `SocketAddr`: address to bind; use port 0 for client-only.
    /// - `peer_count` — `Option<usize>`: max peers (default [`DEFAULT_PEERS`], capped at [`MAX_PEERS`]).
    /// - `channel_count` — `Option<usize>`: max channels (default [`DEFAULT_CHANNELS`]).
    /// - `in_bandwidth` — `Option<u32>`: incoming bandwidth limit in bytes/sec (`None` = unlimited).
    /// - `out_bandwidth` — `Option<u32>`: outgoing bandwidth limit in bytes/sec (`None` = unlimited).
    ///
    /// # Returns
    /// `Result<NetworkHost, NetworkError>`.
    pub fn new(
        bind_addr: SocketAddr,
        peer_count: Option<usize>,
        channel_count: Option<usize>,
        in_bandwidth: Option<u32>,
        out_bandwidth: Option<u32>,
    ) -> Result<Self, NetworkError> {
        let peers = peer_count.unwrap_or(DEFAULT_PEERS);
        if peers > MAX_PEERS {
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

        Ok(Self {
            inner: Some(host),
            local_addr,
        })
    }

    /// Returns a reference to the inner ENet host, or an error if destroyed.
    fn host(&self) -> Result<&Host<UdpSocket>, NetworkError> {
        self.inner.as_ref().ok_or(NetworkError::HostDestroyed)
    }

    /// Returns a mutable reference to the inner ENet host, or an error if destroyed.
    fn host_mut(&mut self) -> Result<&mut Host<UdpSocket>, NetworkError> {
        self.inner.as_mut().ok_or(NetworkError::HostDestroyed)
    }

    /// Poll for one network event.
    ///
    /// # Returns
    /// `Result<Option<NetworkEvent>, NetworkError>`.
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

    /// Initiate a connection to a remote host.
    ///
    /// # Parameters
    /// - `address` — `SocketAddr`: remote host address.
    /// - `channel_count` — `usize`: number of channels for this connection.
    /// - `data` — `u32`: application data sent with the connect event.
    ///
    /// # Returns
    /// `Result<PeerID, NetworkError>`.
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

    /// Send a packet to a specific peer.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`: target peer.
    /// - `channel_id` — `u8`: channel to send on.
    /// - `packet` — `Packet`: the packet data.
    ///
    /// # Returns
    /// `Result<(), NetworkError>`.
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

    /// Broadcast a packet to all connected peers.
    ///
    /// # Parameters
    /// - `channel_id` — `u8`: channel to broadcast on.
    /// - `packet` — `&Packet`: the packet data.
    pub fn broadcast(&mut self, channel_id: u8, packet: &Packet) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.broadcast(channel_id, packet);
        Ok(())
    }

    /// Flush all queued packets without waiting for the next `service()`.
    pub fn flush(&mut self) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.flush();
        Ok(())
    }

    /// Request graceful disconnection from a peer.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    /// - `data` — `u32`: application data sent with the disconnect event.
    pub fn disconnect(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect(data);
        Ok(())
    }

    /// Immediately disconnect a peer without handshake.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    /// - `data` — `u32`.
    pub fn disconnect_now(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect_now(data);
        Ok(())
    }

    /// Disconnect a peer after all queued packets have been sent.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    /// - `data` — `u32`.
    pub fn disconnect_later(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect_later(data);
        Ok(())
    }

    /// Reset a peer connection immediately without notifying the remote side.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    pub fn reset_peer(&mut self, peer_id: PeerID) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).reset();
        Ok(())
    }

    /// Send a ping to a peer to measure RTT.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    pub fn ping(&mut self, peer_id: PeerID) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).ping();
        Ok(())
    }

    /// Get the round-trip time estimate for a peer.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    ///
    /// # Returns
    /// `Result<Duration, NetworkError>`.
    pub fn round_trip_time(&self, peer_id: PeerID) -> Result<Duration, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(peer.round_trip_time())
    }

    /// Get the connection state of a peer as a string.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    ///
    /// # Returns
    /// `Result<&'static str, NetworkError>`.
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

    /// Get the remote address of a peer.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    ///
    /// # Returns
    /// `Result<Option<SocketAddr>, NetworkError>`.
    pub fn peer_address(&self, peer_id: PeerID) -> Result<Option<SocketAddr>, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(peer.address())
    }

    /// Get the local bind address.
    ///
    /// # Returns
    /// `SocketAddr`.
    pub fn local_address(&self) -> SocketAddr {
        self.local_addr
    }

    /// Get the number of allocated peer slots.
    ///
    /// # Returns
    /// `Result<usize, NetworkError>`.
    pub fn peer_limit(&self) -> Result<usize, NetworkError> {
        let host = self.host()?;
        Ok(host.peer_limit())
    }

    /// Get the channel limit.
    ///
    /// # Returns
    /// `Result<usize, NetworkError>`.
    pub fn channel_limit(&self) -> Result<usize, NetworkError> {
        let host = self.host()?;
        Ok(host.channel_limit())
    }

    /// Set the channel limit for future connections.
    ///
    /// # Parameters
    /// - `limit` — `usize`.
    pub fn set_channel_limit(&mut self, limit: usize) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.set_channel_limit(limit)
            .map_err(|e| NetworkError::Enet(format!("{e}")))
    }

    /// Get the bandwidth limits.
    ///
    /// # Returns
    /// `Result<(Option<u32>, Option<u32>), NetworkError>` — (incoming, outgoing).
    pub fn bandwidth_limit(&self) -> Result<(Option<u32>, Option<u32>), NetworkError> {
        let host = self.host()?;
        Ok(host.bandwidth_limit())
    }

    /// Set bandwidth limits.
    ///
    /// # Parameters
    /// - `incoming` — `Option<u32>`: bytes/sec, `None` for unlimited.
    /// - `outgoing` — `Option<u32>`: bytes/sec, `None` for unlimited.
    pub fn set_bandwidth_limit(
        &mut self,
        incoming: Option<u32>,
        outgoing: Option<u32>,
    ) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.set_bandwidth_limit(incoming, outgoing)
            .map_err(|e| NetworkError::Enet(format!("{e}")))
    }

    /// Get the number of currently connected peers.
    ///
    /// # Returns
    /// `Result<usize, NetworkError>`.
    pub fn connected_peer_count(&mut self) -> Result<usize, NetworkError> {
        let host = self.host_mut()?;
        Ok(host.connected_peers().count())
    }

    /// Destroy the host, closing the underlying socket.
    ///
    /// All peer references become invalid after this call.
    pub fn destroy(&mut self) {
        self.inner = None;
    }

    /// Returns `true` if the host has been destroyed.
    pub fn is_destroyed(&self) -> bool {
        self.inner.is_none()
    }

    /// Get the IDs of all currently connected peers.
    ///
    /// # Returns
    /// `Result<Vec<PeerID>, NetworkError>`.
    pub fn connected_peer_ids(&mut self) -> Result<Vec<PeerID>, NetworkError> {
        let host = self.host_mut()?;
        Ok(host.connected_peers().map(|p| p.id()).collect())
    }

    /// Get per-peer statistics.
    ///
    /// # Parameters
    /// - `peer_id` — `PeerID`.
    ///
    /// # Returns
    /// `Result<PeerStats, NetworkError>`.
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

/// Statistics snapshot for a single peer.
///
/// # Fields
/// - `round_trip_time` — `u32`.
/// - `round_trip_time_variance` — `u32`.
/// - `packets_sent` — `u32`.
/// - `packets_lost` — `u32`.
/// - `packet_loss` — `u32`.
/// - `incoming_bandwidth` — `u32`.
/// - `outgoing_bandwidth` — `u32`.
/// - `incoming_data_total` — `u32`.
/// - `outgoing_data_total` — `u32`.
pub struct PeerStats {
    /// Estimated round-trip time in milliseconds.
    pub round_trip_time: u32,
    /// RTT measurement variance in milliseconds.
    pub round_trip_time_variance: u32,
    /// Total packets sent to this peer.
    pub packets_sent: u32,
    /// Total packets lost to this peer.
    pub packets_lost: u32,
    /// Packet loss as a fixed-point value (scaled by ENET_PEER_PACKET_LOSS_SCALE).
    pub packet_loss: u32,
    /// Peer incoming bandwidth in bytes/sec (0 = unlimited).
    pub incoming_bandwidth: u32,
    /// Peer outgoing bandwidth in bytes/sec (0 = unlimited).
    pub outgoing_bandwidth: u32,
    /// Total bytes received from this peer.
    pub incoming_data_total: u32,
    /// Total bytes sent to this peer.
    pub outgoing_data_total: u32,
}
