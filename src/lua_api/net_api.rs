//! Registers the `luna.net` namespace — raw ENet bindings.
//!
//! Provides direct ENet-style functions with underscore naming and
//! multi-value returns from `service()`. Also accessible as the global
//! `enet` table for compatibility with existing ENet-based Lua code.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for net api-related operations and data management.
//! Key types exported from this module: `LuaENetHost`, `LuaENetPeer`.
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

/// Lua UserData wrapper for an ENet host (raw API).
///
/// # Fields
/// - `inner` — `Rc<RefCell<NetworkHost>>`.
/// - `peer_data` — `Rc<RefCell<HashMap<usize, LuaRegistryKey>>>`.
#[derive(Clone)]
pub struct LuaENetHost {
    /// Shared reference to the underlying host.
    inner: Rc<RefCell<NetworkHost>>,
    /// Per-peer Lua data storage.
    peer_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>,
}

impl LunaType for LuaENetHost {
    const TYPE_NAME: &'static str = "ENetHost";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua UserData wrapper for an ENet peer (raw API).
///
/// # Fields
/// - `host` — `Rc<RefCell<NetworkHost>>`.
/// - `peer_id` — `PeerID`.
/// - `peer_data` — `Rc<RefCell<HashMap<usize, LuaRegistryKey>>>`.
#[derive(Clone)]
pub struct LuaENetPeer {
    /// Back-reference to the owning host.
    host: Rc<RefCell<NetworkHost>>,
    /// ENet peer identifier.
    peer_id: PeerID,
    /// Shared per-peer Lua data map.
    peer_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>,
}

impl LunaType for LuaENetPeer {
    const TYPE_NAME: &'static str = "ENetPeer";
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

/// Map a [`NetworkError`] to an [`LuaError`].
fn net_err(e: NetworkError) -> LuaError {
    LuaError::external(e)
}

/// Parse a bind address string like `"*:12345"` or `nil` into a `SocketAddr`.
fn parse_bind_address(addr: Option<String>) -> LuaResult<SocketAddr> {
    match addr {
        Some(s) => {
            let s = s.replace("*:", "0.0.0.0:");
            s.parse::<SocketAddr>()
                .map_err(|e| LuaError::RuntimeError(format!("invalid bind address '{s}': {e}")))
        }
        None => Ok("0.0.0.0:0".parse().unwrap()),
    }
}

// ── LuaENetHost UserData ─────────────────────────────────────────────────

impl LuaUserData for LuaENetHost {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Poll for network events. Returns `event_type, peer, data, channel` or `nil`.
        /// @param timeout : number — milliseconds (default 0 = non-blocking)
        /// @return any
        ///
        /// # Parameters
        /// - `timeout` — `number`.
        ///
        /// # Returns
        /// `string, ENetPeer, any, number | nil`.
        methods.add_method("service", |lua, this, timeout: Option<u32>| {
            let _ = timeout; // non-blocking when socket is non-blocking
            let mut host = this.inner.borrow_mut();
            match host.service() {
                Ok(Some(event)) => match event {
                    NetworkEvent::Connect { peer_id, data } => {
                        let peer = LuaENetPeer {
                            host: this.inner.clone(),
                            peer_id,
                            peer_data: this.peer_data.clone(),
                        };
                        Ok(mlua::MultiValue::from_vec(vec![
                            mlua::Value::String(lua.create_string("connect")?),
                            mlua::Value::UserData(lua.create_userdata(peer)?),
                            mlua::Value::Integer(data as i64),
                            mlua::Value::Nil,
                        ]))
                    }
                    NetworkEvent::Disconnect { peer_id, data } => {
                        let peer = LuaENetPeer {
                            host: this.inner.clone(),
                            peer_id,
                            peer_data: this.peer_data.clone(),
                        };
                        Ok(mlua::MultiValue::from_vec(vec![
                            mlua::Value::String(lua.create_string("disconnect")?),
                            mlua::Value::UserData(lua.create_userdata(peer)?),
                            mlua::Value::Integer(data as i64),
                            mlua::Value::Nil,
                        ]))
                    }
                    NetworkEvent::Receive {
                        peer_id,
                        channel_id,
                        data,
                    } => {
                        let peer = LuaENetPeer {
                            host: this.inner.clone(),
                            peer_id,
                            peer_data: this.peer_data.clone(),
                        };
                        Ok(mlua::MultiValue::from_vec(vec![
                            mlua::Value::String(lua.create_string("receive")?),
                            mlua::Value::UserData(lua.create_userdata(peer)?),
                            mlua::Value::String(lua.create_string(&data)?),
                            mlua::Value::Integer(channel_id as i64),
                        ]))
                    }
                },
                Ok(None) => Ok(mlua::MultiValue::new()),
                Err(e) => Err(net_err(e)),
            }
        });

        /// Initiate a connection to `"host:port"`.
        /// @param address : string — in "host:port" format
        /// @param channel_count : number — optional (default 1)
        /// @param data : number — optional connect data integer (default 0)
        /// @return any
        ///
        /// # Parameters
        /// - `address` — `string`.
        /// - `channel_count` — `number`.
        /// - `data` — `number`.
        ///
        /// # Returns
        /// `ENetPeer`.
        methods.add_method(
            "connect",
            |_, this, (address, channel_count, data): (String, Option<usize>, Option<u32>)| {
                let addr: SocketAddr = address
                    .parse()
                    .map_err(|e| LuaError::RuntimeError(format!("invalid address: {e}")))?;
                let mut host = this.inner.borrow_mut();
                let peer_id = host
                    .connect(addr, channel_count.unwrap_or(1), data.unwrap_or(0))
                    .map_err(net_err)?;
                Ok(LuaENetPeer {
                    host: this.inner.clone(),
                    peer_id,
                    peer_data: this.peer_data.clone(),
                })
            },
        );

        /// Send a packet to all connected peers.
        /// @param data : string
        /// @param channel : number
        /// @param flag : string
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

        /// Get or set bandwidth limits. No args = get, with args = set.
        /// @param incoming : number
        /// @param outgoing : number
        /// @return any
        ///
        /// # Parameters
        /// - `incoming` — `number`.
        /// - `outgoing` — `number`.
        ///
        /// # Returns
        /// `number, number`.
        methods.add_method(
            "bandwidth_limit",
            |_, this, (incoming, outgoing): (Option<u32>, Option<u32>)| {
                if incoming.is_some() || outgoing.is_some() {
                    let mut host = this.inner.borrow_mut();
                    let inc = incoming.and_then(|v| if v == 0 { None } else { Some(v) });
                    let out = outgoing.and_then(|v| if v == 0 { None } else { Some(v) });
                    host.set_bandwidth_limit(inc, out).map_err(net_err)?;
                    Ok((incoming.unwrap_or(0), outgoing.unwrap_or(0)))
                } else {
                    let host = this.inner.borrow();
                    let (inc, out) = host.bandwidth_limit().map_err(net_err)?;
                    Ok((inc.unwrap_or(0), out.unwrap_or(0)))
                }
            },
        );

        /// Get or set the channel limit.
        /// @param limit : number
        /// @return any
        ///
        /// # Parameters
        /// - `limit` — `number`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("channel_limit", |_, this, limit: Option<usize>| {
            if let Some(l) = limit {
                let mut host = this.inner.borrow_mut();
                host.set_channel_limit(l).map_err(net_err)?;
                Ok(l)
            } else {
                let host = this.inner.borrow();
                host.channel_limit().map_err(net_err)
            }
        });

        /// Get the number of currently connected peers.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("connected_peers", |_, this, ()| {
            let mut host = this.inner.borrow_mut();
            host.connected_peer_count().map_err(net_err)
        });

        /// Get the bound socket address string.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("get_socket_address", |_, this, ()| {
            let host = this.inner.borrow();
            Ok(host.local_address().to_string())
        });

        /// Send queued packets immediately.
        methods.add_method("flush", |_, this, ()| {
            let mut host = this.inner.borrow_mut();
            host.flush().map_err(net_err)?;
            Ok(())
        });

        /// Destroy the host and close the socket.
        methods.add_method("destroy", |_, this, ()| {
            let mut host = this.inner.borrow_mut();
            host.destroy();
            Ok(())
        });

        /// Get or set the maximum packet size in bytes (stub — returns ENet default).
        /// @param size : number
        /// @return any
        ///
        /// # Parameters
        /// - `size` — `number`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("max_packet_size", |_, _, size: Option<usize>| {
            // rusty_enet does not expose a runtime max_packet_size setter/getter.
            // Return the ENet default (32 MiB) when called as a getter; silently ignore setter.
            let _ = size;
            Ok(32 * 1024 * 1024usize)
        });

        /// Get or set the maximum waiting data (stub — returns ENet default).
        /// @param size : number
        /// @return any
        ///
        /// # Parameters
        /// - `size` — `number`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("max_waiting_data", |_, _, size: Option<usize>| {
            let _ = size;
            Ok(32 * 1024 * 1024usize)
        });

        /// Get or set the duplicate peer limit (stub — returns default 1).
        /// @param count : number
        /// @return any
        ///
        /// # Parameters
        /// - `count` — `number`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("duplicate_peers", |_, _, count: Option<usize>| {
            let _ = count;
            Ok(1usize)
        });

        /// Enable or disable CRC32 checksum (stub — rusty_enet sets this at host creation only).
        /// @param enable : boolean
        /// @return any
        ///
        /// # Parameters
        /// - `enable` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("enable_checksum", |_, _, enable: Option<bool>| {
            Ok(enable.unwrap_or(false))
        });

        /// Enable ENet range coder compression (stub — no-op in rusty_enet).
        methods.add_method("compress_with_range_coder", |_, _, ()| Ok(()));

        /// Disable compression (stub — no-op).
        methods.add_method("compress_disable", |_, _, ()| Ok(()));

        /// Get host aggregate statistics. Returns an empty table (no host-level stats in rusty_enet).
        /// @return any
        ///
        /// # Returns
        /// `table`.
        methods.add_method("get_stats", |lua, _, ()| lua.create_table());

        /// Reset host statistics counters (stub — no-op).
        methods.add_method("reset_stats", |_, _, ()| Ok(()));

        /// Get the source address of the last received packet (stub — not exposed by rusty_enet).
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("received_address", |_, _, ()| Ok(""));
    }
}

// ── LuaENetPeer UserData ─────────────────────────────────────────────────

impl LuaUserData for LuaENetPeer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Send a packet to this peer.
        /// @param data : string
        /// @param channel : number
        /// @param flag : string
        ///
        /// # Parameters
        /// - `data` — `string`.
        /// - `channel` — `number`.
        /// - `flag` — `string`.
        methods.add_method(
            "send",
            |_, this, (data, channel, flag): (LuaString, Option<u8>, Option<String>)| {
                let packet = make_packet(data.as_bytes(), flag);
                let mut host = this.host.borrow_mut();
                host.send(this.peer_id, channel.unwrap_or(0), packet)
                    .map_err(net_err)?;
                Ok(())
            },
        );

        /// Request graceful disconnection.
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
        methods.add_method("disconnect_now", |_, this, data: Option<u32>| {
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
        methods.add_method("disconnect_later", |_, this, data: Option<u32>| {
            let mut host = this.host.borrow_mut();
            host.disconnect_later(this.peer_id, data.unwrap_or(0))
                .map_err(net_err)?;
            Ok(())
        });

        /// Reset peer without notifying remote side.
        methods.add_method("reset", |_, this, ()| {
            let mut host = this.host.borrow_mut();
            host.reset_peer(this.peer_id).map_err(net_err)?;
            Ok(())
        });

        /// Ping the peer.
        methods.add_method("ping", |_, this, ()| {
            let mut host = this.host.borrow_mut();
            host.ping(this.peer_id).map_err(net_err)?;
            Ok(())
        });

        /// Get round-trip time in milliseconds.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("get_roundtrip_time", |_, this, ()| {
            let host = this.host.borrow();
            let rtt = host.round_trip_time(this.peer_id).map_err(net_err)?;
            Ok(rtt.as_millis() as u64)
        });

        /// Get connection state string.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("get_state", |_, this, ()| {
            let host = this.host.borrow();
            let state = host.peer_state(this.peer_id).map_err(net_err)?;
            Ok(state.to_string())
        });

        /// Get peer address as `{ip, port}` table.
        /// @return any
        ///
        /// # Returns
        /// `table`.
        methods.add_method("get_address", |lua, this, ()| {
            let host = this.host.borrow();
            let addr = host.peer_address(this.peer_id).map_err(net_err)?;
            match addr {
                Some(a) => {
                    let tbl = lua.create_table()?;
                    tbl.set("ip", a.ip().to_string())?;
                    tbl.set("port", a.port())?;
                    Ok(mlua::Value::Table(tbl))
                }
                None => Ok(mlua::Value::Nil),
            }
        });

        /// Store arbitrary per-peer Lua data.
        /// @param value : any
        ///
        /// # Parameters
        /// - `value` — `any`.
        methods.add_method("set_data", |lua, this, value: LuaValue| {
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
        methods.add_method("get_data", |lua, this, ()| {
            let data = this.peer_data.borrow();
            match data.get(&this.peer_id.0) {
                Some(key) => {
                    let val: LuaValue = lua.registry_value(key)?;
                    Ok(val)
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// Get per-peer statistics as a table.
        ///
        /// # Returns
        /// `table` with fields: `round_trip_time`, `round_trip_time_variance`, `packets_sent`,
        /// `packets_lost`, `packet_loss`, `incoming_bandwidth`, `outgoing_bandwidth`,
        /// `incoming_data_total`, `outgoing_data_total`.
        methods.add_method("get_stats", |lua, this, ()| {
            let host = this.host.borrow();
            let stats = host.peer_stats(this.peer_id).map_err(net_err)?;
            let tbl = lua.create_table()?;
            tbl.set("round_trip_time", stats.round_trip_time)?;
            tbl.set("round_trip_time_variance", stats.round_trip_time_variance)?;
            tbl.set("packets_sent", stats.packets_sent)?;
            tbl.set("packets_lost", stats.packets_lost)?;
            tbl.set("packet_loss", stats.packet_loss)?;
            tbl.set("incoming_bandwidth", stats.incoming_bandwidth)?;
            tbl.set("outgoing_bandwidth", stats.outgoing_bandwidth)?;
            tbl.set("incoming_data_total", stats.incoming_data_total)?;
            tbl.set("outgoing_data_total", stats.outgoing_data_total)?;
            Ok(tbl)
        });
    }
}

// ── Registration ─────────────────────────────────────────────────────────

/// Registers all `luna.net.*` / `enet.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
///
/// # Functions registered
/// - `luna.net.host_create(bind_address?, peer_count?, channel_count?, in_bandwidth?, out_bandwidth?)` — create a raw ENet host
/// - `luna.net.linked_version()` — return the ENet library version string
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let net_table = lua.create_table()?;

    #[allow(unused_doc_comments)]
    /// Create a new ENet host. `bind_address` in `"*:port"` format for server,
    /// `nil` for client. `peer_count` defaults to 4 (max 8).
    // luna.net.host_create(bind_address?, peer_count?, channel_count?, in_bw?, out_bw?)
    /// @param bind_address : string
    /// @param peer_count : number
    /// @param channel_count : number
    /// @param in_bandwidth : number
    /// @param out_bandwidth : number
    /// @return any
    net_table.set(
        "host_create",
        lua.create_function(
            #[allow(clippy::type_complexity)]
            move |_,
                  (bind_address, peer_count, channel_count, in_bw, out_bw): (
                Option<String>,
                Option<usize>,
                Option<usize>,
                Option<u32>,
                Option<u32>,
            )| {
                let bind_addr = parse_bind_address(bind_address)?;

                let peers = peer_count.map(|p| if p > MAX_PEERS { MAX_PEERS } else { p });
                let in_bandwidth = in_bw.and_then(|v| if v == 0 { None } else { Some(v) });
                let out_bandwidth = out_bw.and_then(|v| if v == 0 { None } else { Some(v) });

                let host =
                    NetworkHost::new(bind_addr, peers, channel_count, in_bandwidth, out_bandwidth)
                        .map_err(LuaError::external)?;

                Ok(LuaENetHost {
                    inner: Rc::new(RefCell::new(host)),
                    peer_data: Rc::new(RefCell::new(HashMap::new())),
                })
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the linked ENet library version string.
    // luna.net.linked_version()
    /// @return any
    net_table.set(
        "linked_version",
        lua.create_function(|_, ()| Ok("rusty_enet 0.4"))?,
    )?;

    /// Returns a millisecond timestamp (ms since UNIX epoch).
    // luna.net.time_get()
    /// @return any
    net_table.set(
        "time_get",
        lua.create_function(|_, ()| {
            use std::time::{SystemTime, UNIX_EPOCH};
            let ms = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64;
            Ok(ms)
        })?,
    )?;

    /// Net.
    luna.set("net", net_table.clone())?;
    // ENet is also accessible as `enet` global for compat with enet.md spec.
    lua.globals().set("enet", net_table)?;
    Ok(())
}
