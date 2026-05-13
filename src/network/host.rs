use super::constants::{DEFAULT_CHANNELS, DEFAULT_PEERS, MAX_PEERS};
use super::error::NetworkError;
use crate::log_msg;
use crate::runtime::log_messages::{NW01_HOST_BIND, NW04_NET_ERROR};
use rusty_enet::{self as enet, Host, HostSettings, Packet, PacketKind, PeerID};
use std::net::{SocketAddr, UdpSocket};
use std::time::Duration;
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HostRole {
    Server,
    Client,
    Host,
}
pub struct NetworkHost {
    inner: Option<Host<UdpSocket>>,
    local_addr: SocketAddr,
    role: HostRole,
}
pub enum NetworkEvent {
    Connect {
        peer_id: PeerID,
        data: u32,
    },
    Disconnect {
        peer_id: PeerID,
        data: u32,
    },
    Receive {
        peer_id: PeerID,
        channel_id: u8,
        data: Vec<u8>,
    },
}
impl NetworkHost {
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
    fn host(&self) -> Result<&Host<UdpSocket>, NetworkError> {
        self.inner.as_ref().ok_or(NetworkError::HostDestroyed)
    }
    fn host_mut(&mut self) -> Result<&mut Host<UdpSocket>, NetworkError> {
        self.inner.as_mut().ok_or(NetworkError::HostDestroyed)
    }
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
    pub fn broadcast(&mut self, channel_id: u8, packet: &Packet) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.broadcast(channel_id, packet);
        Ok(())
    }
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
    pub fn flush(&mut self) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.flush();
        Ok(())
    }
    pub fn disconnect(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect(data);
        Ok(())
    }
    pub fn disconnect_now(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect_now(data);
        Ok(())
    }
    pub fn disconnect_later(&mut self, peer_id: PeerID, data: u32) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).disconnect_later(data);
        Ok(())
    }
    pub fn reset_peer(&mut self, peer_id: PeerID) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).reset();
        Ok(())
    }
    pub fn ping(&mut self, peer_id: PeerID) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.peer_mut(peer_id).ping();
        Ok(())
    }
    pub fn round_trip_time(&self, peer_id: PeerID) -> Result<Duration, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(peer.round_trip_time())
    }
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
    pub fn peer_address(&self, peer_id: PeerID) -> Result<Option<SocketAddr>, NetworkError> {
        let host = self.host()?;
        let peer = host
            .get_peer(peer_id)
            .ok_or(NetworkError::InvalidPeer(peer_id.0))?;
        Ok(peer.address())
    }
    pub fn local_address(&self) -> SocketAddr {
        self.local_addr
    }
    pub fn peer_limit(&self) -> Result<usize, NetworkError> {
        let host = self.host()?;
        Ok(host.peer_limit())
    }
    pub fn channel_limit(&self) -> Result<usize, NetworkError> {
        let host = self.host()?;
        Ok(host.channel_limit())
    }
    pub fn set_channel_limit(&mut self, limit: usize) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.set_channel_limit(limit)
            .map_err(|e| NetworkError::Enet(format!("{e}")))
    }
    pub fn bandwidth_limit(&self) -> Result<(Option<u32>, Option<u32>), NetworkError> {
        let host = self.host()?;
        Ok(host.bandwidth_limit())
    }
    pub fn set_bandwidth_limit(
        &mut self,
        incoming: Option<u32>,
        outgoing: Option<u32>,
    ) -> Result<(), NetworkError> {
        let host = self.host_mut()?;
        host.set_bandwidth_limit(incoming, outgoing)
            .map_err(|e| NetworkError::Enet(format!("{e}")))
    }
    pub fn connected_peer_count(&mut self) -> Result<usize, NetworkError> {
        let host = self.host_mut()?;
        Ok(host.connected_peers().count())
    }
    pub fn destroy(&mut self) {
        self.inner = None;
    }
    pub fn is_destroyed(&self) -> bool {
        self.inner.is_none()
    }
    pub fn connected_peer_ids(&mut self) -> Result<Vec<PeerID>, NetworkError> {
        let host = self.host_mut()?;
        Ok(host.connected_peers().map(|p| p.id()).collect())
    }
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
    pub fn role(&self) -> HostRole {
        self.role
    }
    pub fn set_role(&mut self, role: HostRole) {
        self.role = role;
    }
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
pub struct PeerStats {
    pub round_trip_time: u32,
    pub round_trip_time_variance: u32,
    pub packets_sent: u32,
    pub packets_lost: u32,
    pub packet_loss: u32,
    pub incoming_bandwidth: u32,
    pub outgoing_bandwidth: u32,
    pub incoming_data_total: u32,
    pub outgoing_data_total: u32,
}
