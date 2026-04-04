//! Registers the `luna.network` namespace — high-level multiplayer networking.
//!
//! Provides `Host` and `Peer` types with camelCase methods and event-table
//! returns. This is the recommended API for new Lua game code.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for network api-related operations and data management.
//! Key types exported from this module: `LuaNetworkHost`, `LuaNetworkPeer`.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::cell::RefCell;
use std::collections::HashMap;
use std::net::SocketAddr;
use std::rc::Rc;

use mlua::prelude::*;
use rusty_enet::{Packet, PeerID};

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::network::constants::MAX_PEERS;
use crate::network::error::NetworkError;
use crate::network::host::{NetworkEvent, NetworkHost};

/// Lua UserData wrapper for a [`NetworkHost`].
///
/// Holds the host in an `Rc<RefCell>` so that both the host table and its
/// child peer references can mutably access it.
///
/// # Fields
/// - `inner` — `Rc<RefCell<NetworkHost>>`.
/// - `peer_data` — `Rc<RefCell<HashMap<usize, LuaRegistryKey>>>`.
#[derive(Clone)]
pub struct LuaNetworkHost {
    /// Shared reference to the underlying host.
    inner: Rc<RefCell<NetworkHost>>,
    /// Per-peer Lua data keyed by peer index. Stored here rather than in ENet
    /// because Lua values cannot be stored inside `rusty_enet::Peer`.
    peer_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>,
}

impl LunaType for LuaNetworkHost {
    const TYPE_NAME: &'static str = "NetworkHost";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua UserData wrapper for an ENet peer, identified by its [`PeerID`].
///
/// # Fields
/// - `host` — `Rc<RefCell<NetworkHost>>`.
/// - `peer_id` — `PeerID`.
/// - `peer_data` — `Rc<RefCell<HashMap<usize, LuaRegistryKey>>>`.
#[derive(Clone)]
pub struct LuaNetworkPeer {
    /// Back-reference to the owning host (needed for send / disconnect).
    host: Rc<RefCell<NetworkHost>>,
    /// ENet peer identifier.
    peer_id: PeerID,
    /// Shared per-peer Lua data map.
    peer_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>,
}

impl LunaType for LuaNetworkPeer {
    const TYPE_NAME: &'static str = "NetworkPeer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Convert a flag string to a [`Packet`].
fn make_packet(data: &[u8], flag: Option<String>) -> Packet {
    match flag.as_deref() {
        Some("unreliable") => Packet::unreliable(data),
        Some("unsequenced") => Packet::unreliable_unsequenced(data),
        _ => Packet::reliable(data),
    }
}

/// Parse `"host:port"` or `"*:port"` into a `SocketAddr`.
fn parse_address(host: &str, port: u16) -> LuaResult<SocketAddr> {
    let addr_str = format!("{host}:{port}");
    addr_str
        .parse::<SocketAddr>()
        .map_err(|e| LuaError::RuntimeError(format!("invalid address '{addr_str}': {e}")))
}

/// Map a [`NetworkError`] to an [`LuaError`].
fn net_err(e: NetworkError) -> LuaError {
    LuaError::external(e)
}

// ── LuaNetworkHost UserData ──────────────────────────────────────────────

impl LuaUserData for LuaNetworkHost {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Poll for one network event. Returns an event table `{type, peer, data, channel}` or `nil`.
        /// @param timeout : number — milliseconds (default 0 = non-blocking)
        /// @return any
        ///
        /// # Parameters
        /// - `timeout` — `number`.
        ///
        /// # Returns
        /// `table | nil`.
        methods.add_method("service", |lua, this, timeout: Option<u32>| {
            let _ = timeout; // rusty_enet service() is non-blocking when socket is non-blocking
            let mut host = this.inner.borrow_mut();
            match host.service() {
                Ok(Some(event)) => {
                    let tbl = lua.create_table()?;
                    match event {
                        NetworkEvent::Connect { peer_id, data } => {
                            tbl.set("type", "connect")?;
                            tbl.set(
                                "peer",
                                LuaNetworkPeer {
                                    host: this.inner.clone(),
                                    peer_id,
                                    peer_data: this.peer_data.clone(),
                                },
                            )?;
                            tbl.set("data", data)?;
                        }
                        NetworkEvent::Disconnect { peer_id, data } => {
                            tbl.set("type", "disconnect")?;
                            tbl.set(
                                "peer",
                                LuaNetworkPeer {
                                    host: this.inner.clone(),
                                    peer_id,
                                    peer_data: this.peer_data.clone(),
                                },
                            )?;
                            tbl.set("data", data)?;
                        }
                        NetworkEvent::Receive {
                            peer_id,
                            channel_id,
                            data,
                        } => {
                            tbl.set("type", "receive")?;
                            tbl.set(
                                "peer",
                                LuaNetworkPeer {
                                    host: this.inner.clone(),
                                    peer_id,
                                    peer_data: this.peer_data.clone(),
                                },
                            )?;
                            tbl.set("data", lua.create_string(&data)?)?;
                            tbl.set("channel", channel_id)?;
                        }
                    }
                    Ok(mlua::Value::Table(tbl))
                }
                Ok(None) => Ok(mlua::Value::Nil),
                Err(e) => Err(net_err(e)),
            }
        });

        /// Initiate a connection to a remote host.
        /// @param address : string — IP address or hostname
        /// @param port : number — remote port
        /// @param data : number — optional connect data integer (default 0)
        /// @return any
        ///
        /// # Parameters
        /// - `address` — `string`.
        /// - `port` — `number`.
        /// - `data` — `number`.
        ///
        /// # Returns
        /// `NetworkPeer`.
        methods.add_method(
            "connect",
            |_, this, (address, port, data): (String, u16, Option<u32>)| {
                let addr = parse_address(&address, port)?;
                let mut host = this.inner.borrow_mut();
                let peer_id = host.connect(addr, 1, data.unwrap_or(0)).map_err(net_err)?;
                Ok(LuaNetworkPeer {
                    host: this.inner.clone(),
                    peer_id,
                    peer_data: this.peer_data.clone(),
                })
            },
        );

        /// Send a packet to all connected peers.
        /// @param data : string — packet payload
        /// @param channel : number — channel index (default 0)
        /// @param flag : string — "reliable" (default), "unreliable", or "unsequenced"
        ///
        /// # Parameters
        /// - `data` — `string`.
        /// - `channel` — `number`.
        /// - `flag` — `string`.
        methods.add_method(
            "broadcast",
            |_, this, (data, channel, flag): (LuaString, Option<u8>, Option<String>)| {
                let packet = make_packet(data.as_bytes(), flag);
                let mut host = this.inner.borrow_mut();
                host.broadcast(channel.unwrap_or(0), &packet)
                    .map_err(net_err)?;
                Ok(())
            },
        );

        /// Get the number of allocated peer slots.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getPeerCount", |_, this, ()| {
            let host = this.inner.borrow();
            host.peer_limit().map_err(net_err)
        });

        /// Set bandwidth limits (bytes per second). 0 = unlimited.
        /// @param inBps : number — incoming limit
        /// @param outBps : number — outgoing limit
        ///
        /// # Parameters
        /// - `inBps` — `number`.
        /// - `outBps` — `number`.
        methods.add_method(
            "setBandwidthLimit",
            |_, this, (in_bps, out_bps): (u32, u32)| {
                let mut host = this.inner.borrow_mut();
                let incoming = if in_bps == 0 { None } else { Some(in_bps) };
                let outgoing = if out_bps == 0 { None } else { Some(out_bps) };
                host.set_bandwidth_limit(incoming, outgoing)
                    .map_err(net_err)?;
                Ok(())
            },
        );

        /// Get the bound IP address and port.
        /// @return any
        ///
        /// # Returns
        /// `string, number`.
        methods.add_method("getAddress", |_, this, ()| {
            let host = this.inner.borrow();
            let addr = host.local_address();
            Ok((addr.ip().to_string(), addr.port()))
        });

        /// Immediately destroy the host and close the socket. All peers become invalid.
        methods.add_method("destroy", |_, this, ()| {
            let mut host = this.inner.borrow_mut();
            host.destroy();
            Ok(())
        });

        /// Send all queued packets immediately.
        methods.add_method("flush", |_, this, ()| {
            let mut host = this.inner.borrow_mut();
            host.flush().map_err(net_err)?;
            Ok(())
        });

        /// Get all currently connected peers as a table.
        /// @return any
        ///
        /// # Returns
        /// `table<NetworkPeer>`.
        methods.add_method("getPeers", |lua, this, ()| {
            let ids = this
                .inner
                .borrow_mut()
                .connected_peer_ids()
                .map_err(net_err)?;
            let tbl = lua.create_table()?;
            for (i, pid) in ids.into_iter().enumerate() {
                tbl.set(
                    i + 1,
                    LuaNetworkPeer {
                        host: this.inner.clone(),
                        peer_id: pid,
                        peer_data: this.peer_data.clone(),
                    },
                )?;
            }
            Ok(tbl)
        });

        /// Get host statistics. Returns an empty table (no host-level aggregate stats available).
        /// @return any
        ///
        /// # Returns
        /// `table`.
        methods.add_method("getStats", |lua, _, ()| lua.create_table());
    }
}

// ── LuaNetworkPeer UserData ──────────────────────────────────────────────

impl LuaUserData for LuaNetworkPeer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Send a packet to this peer.
        /// @param data : string — packet payload
        /// @param channel : number — channel index (default 0)
        /// @param flag : string — "reliable" (default), "unreliable", or "unsequenced"
        /// @return any
        ///
        /// # Parameters
        /// - `data` — `string`.
        /// - `channel` — `number`.
        /// - `flag` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method(
            "send",
            |_, this, (data, channel, flag): (LuaString, Option<u8>, Option<String>)| {
                let packet = make_packet(data.as_bytes(), flag);
                let mut host = this.host.borrow_mut();
                match host.send(this.peer_id, channel.unwrap_or(0), packet) {
                    Ok(()) => Ok(true),
                    Err(e) => Err(net_err(e)),
                }
            },
        );

        /// Request graceful disconnection. Optional data integer sent with disconnect event.
        /// @param data : number
        ///
        /// # Parameters
        /// - `data` — `number`.
        methods.add_method("disconnect", |_, this, data: Option<u32>| {
            let mut host = this.host.borrow_mut();
            host.disconnect(this.peer_id, data.unwrap_or(0))
                .map_err(net_err)?;
            Ok(())
        });

        /// Immediately disconnect without handshake.
        /// @param data : number
        ///
        /// # Parameters
        /// - `data` — `number`.
        methods.add_method("disconnectNow", |_, this, data: Option<u32>| {
            let mut host = this.host.borrow_mut();
            host.disconnect_now(this.peer_id, data.unwrap_or(0))
                .map_err(net_err)?;
            Ok(())
        });

        /// Disconnect after all queued packets are sent.
        /// @param data : number
        ///
        /// # Parameters
        /// - `data` — `number`.
        methods.add_method("disconnectLater", |_, this, data: Option<u32>| {
            let mut host = this.host.borrow_mut();
            host.disconnect_later(this.peer_id, data.unwrap_or(0))
                .map_err(net_err)?;
            Ok(())
        });

        /// Forcefully reset the peer without notifying the remote side.
        methods.add_method("reset", |_, this, ()| {
            let mut host = this.host.borrow_mut();
            host.reset_peer(this.peer_id).map_err(net_err)?;
            Ok(())
        });

        /// Send a ping to measure round-trip time.
        methods.add_method("ping", |_, this, ()| {
            let mut host = this.host.borrow_mut();
            host.ping(this.peer_id).map_err(net_err)?;
            Ok(())
        });

        /// Get current estimated round-trip time in milliseconds.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getRoundTripTime", |_, this, ()| {
            let host = this.host.borrow();
            let rtt = host.round_trip_time(this.peer_id).map_err(net_err)?;
            Ok(rtt.as_millis() as u64)
        });

        /// Get the connection state string.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getState", |_, this, ()| {
            let host = this.host.borrow();
            let state = host.peer_state(this.peer_id).map_err(net_err)?;
            Ok(state.to_string())
        });

        /// Get the peer's IP address and port.
        /// @return any
        ///
        /// # Returns
        /// `string, number`.
        methods.add_method("getAddress", |_, this, ()| {
            let host = this.host.borrow();
            let addr = host.peer_address(this.peer_id).map_err(net_err)?;
            match addr {
                Some(a) => Ok((a.ip().to_string(), a.port())),
                None => Err(LuaError::RuntimeError(
                    "peer address not available".to_string(),
                )),
            }
        });

        /// Store arbitrary per-peer Lua data.
        /// @param value : any
        ///
        /// # Parameters
        /// - `value` — `any`.
        methods.add_method("setData", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            let mut data = this.peer_data.borrow_mut();
            data.insert(this.peer_id.0, key);
            Ok(())
        });

        /// Retrieve stored per-peer data.
        /// @return any
        ///
        /// # Returns
        /// `any`.
        methods.add_method("getData", |lua, this, ()| {
            let data = this.peer_data.borrow();
            match data.get(&this.peer_id.0) {
                Some(key) => {
                    let val: LuaValue = lua.registry_value(key)?;
                    Ok(val)
                }
                None => Ok(LuaValue::Nil),
            }
        });
    }
}

// ── Registration ─────────────────────────────────────────────────────────

/// Registers all `luna.network.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
///
/// # Functions registered
/// - `luna.network.newHost(opts?)` — create a new network host
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let network_table = lua.create_table()?;

    #[allow(unused_doc_comments)]
    /// Create a new network host. Options table fields:
    /// `port` (int, default 0), `maxPeers` (int, default 4, max 8),
    /// `channels` (int, default 1), `inBandwidth` (int, 0=unlimited),
    /// `outBandwidth` (int, 0=unlimited).
    // luna.network.newHost(opts?)
    /// @param opts : table
    /// @return any
    network_table.set(
        "newHost",
        lua.create_function(move |_, opts: Option<LuaTable>| {
            let (port, max_peers, channels, in_bw, out_bw) = if let Some(t) = opts {
                (
                    t.get::<_, Option<u16>>("port")?.unwrap_or(0),
                    t.get::<_, Option<usize>>("maxPeers")?,
                    t.get::<_, Option<usize>>("channels")?,
                    t.get::<_, Option<u32>>("inBandwidth")?,
                    t.get::<_, Option<u32>>("outBandwidth")?,
                )
            } else {
                (0, None, None, None, None)
            };

            // Clamp maxPeers
            let peers = max_peers.map(|p| if p > MAX_PEERS { MAX_PEERS } else { p });

            // Convert 0 bandwidth to None (unlimited)
            let in_bandwidth = in_bw.and_then(|v| if v == 0 { None } else { Some(v) });
            let out_bandwidth = out_bw.and_then(|v| if v == 0 { None } else { Some(v) });

            let bind_addr: SocketAddr = format!("0.0.0.0:{port}")
                .parse()
                .map_err(|e| LuaError::RuntimeError(format!("invalid port: {e}")))?;

            let host = NetworkHost::new(bind_addr, peers, channels, in_bandwidth, out_bandwidth)
                .map_err(LuaError::external)?;

            Ok(LuaNetworkHost {
                inner: Rc::new(RefCell::new(host)),
                peer_data: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    /// Network.
    luna.set("network", network_table)?;
    Ok(())
}
