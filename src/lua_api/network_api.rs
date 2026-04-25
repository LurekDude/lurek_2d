//! `lurek.network` — Full networking toolkit for multiplayer games.
//!
//! Provides ENet UDP, HTTP, TCP, WebSocket, and MessagePack serialization
//! through the `lurek.network` Lua namespace.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::net::SocketAddr;
use std::rc::Rc;

use crate::network::constants::{DEFAULT_CHANNELS, DEFAULT_PEERS, MAX_CHANNELS, MAX_PEERS};
use crate::network::host::{HostRole, NetworkEvent, NetworkHost, PeerStats};
use crate::network::message::NetValue;
use crate::network::net_thread::NetworkRuntime;
use rusty_enet::PeerID;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Converts a [`NetworkEvent`] to a Lua event table.
fn event_to_table(lua: &Lua, ev: NetworkEvent) -> LuaResult<LuaTable<'_>> {
    let t = lua.create_table()?;
    match ev {
        NetworkEvent::Connect { peer_id, data } => {
            t.set("type", "connect")?;
            t.set("peer_id", peer_id.0)?;
            t.set("data", data)?;
        }
        NetworkEvent::Disconnect { peer_id, data } => {
            t.set("type", "disconnect")?;
            t.set("peer_id", peer_id.0)?;
            t.set("data", data)?;
        }
        NetworkEvent::Receive {
            peer_id,
            channel_id,
            data,
        } => {
            t.set("type", "receive")?;
            t.set("peer_id", peer_id.0)?;
            t.set("channel_id", channel_id)?;
            t.set("data", lua.create_string(&data)?)?;
        }
    }
    Ok(t)
}

/// Parses `"host:port"` into a [`SocketAddr`].
fn parse_addr(s: &str) -> LuaResult<SocketAddr> {
    s.parse()
        .map_err(|_| LuaError::RuntimeError(format!("invalid address: {s}")))
}

/// Converts a [`PeerStats`] snapshot to a Lua table.
fn stats_to_table(lua: &Lua, stats: PeerStats) -> LuaResult<LuaTable<'_>> {
    let t = lua.create_table()?;
    t.set("round_trip_time", stats.round_trip_time)?;
    t.set("round_trip_time_variance", stats.round_trip_time_variance)?;
    t.set("packets_sent", stats.packets_sent)?;
    t.set("packets_lost", stats.packets_lost)?;
    t.set("packet_loss", stats.packet_loss)?;
    t.set("incoming_bandwidth", stats.incoming_bandwidth)?;
    t.set("outgoing_bandwidth", stats.outgoing_bandwidth)?;
    t.set("incoming_data_total", stats.incoming_data_total)?;
    t.set("outgoing_data_total", stats.outgoing_data_total)?;
    Ok(t)
}

/// Converts a Lua table into a [`NetValue::Array`] or [`NetValue::Map`].
fn lua_table_to_netvalue(t: &LuaTable) -> LuaResult<NetValue> {
    // Detect array vs map: check if key 1 exists
    if t.raw_get::<_, LuaValue>(1i64).is_ok()
        && !matches!(t.raw_get::<_, LuaValue>(1i64)?, LuaValue::Nil)
    {
        let mut arr = Vec::new();
        for pair in t.clone().sequence_values::<LuaValue>() {
            arr.push(lua_to_netvalue(&pair?)?);
        }
        Ok(NetValue::Array(arr))
    } else {
        let mut map = Vec::new();
        for pair in t.clone().pairs::<LuaValue, LuaValue>() {
            let (k, v) = pair?;
            let key_str = match &k {
                LuaValue::String(s) => s.to_str()?.to_string(),
                LuaValue::Integer(i) => i.to_string(),
                LuaValue::Number(n) => n.to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "pack: map keys must be strings or numbers".into(),
                    ))
                }
            };
            map.push((key_str, lua_to_netvalue(&v)?));
        }
        Ok(NetValue::Map(map))
    }
}

/// Converts a Lua value to a [`NetValue`] for MessagePack serialization.
fn lua_to_netvalue(val: &LuaValue) -> LuaResult<NetValue> {
    match val {
        LuaValue::Nil => Ok(NetValue::Nil),
        LuaValue::Boolean(b) => Ok(NetValue::Bool(*b)),
        LuaValue::Integer(i) => Ok(NetValue::Integer(*i)),
        LuaValue::Number(n) => Ok(NetValue::Float(*n)),
        LuaValue::String(s) => Ok(NetValue::String(s.to_str()?.to_string())),
        LuaValue::Table(t) => lua_table_to_netvalue(t),
        _ => Err(LuaError::RuntimeError(format!(
            "pack: unsupported type: {}",
            val.type_name()
        ))),
    }
}

/// Converts a [`NetValue`] back to a Lua value.
fn netvalue_to_lua<'lua>(lua: &'lua Lua, val: &NetValue) -> LuaResult<LuaValue<'lua>> {
    match val {
        NetValue::Nil => Ok(LuaValue::Nil),
        NetValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
        NetValue::Integer(i) => Ok(LuaValue::Integer(*i)),
        NetValue::Float(f) => Ok(LuaValue::Number(*f)),
        NetValue::String(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        NetValue::Array(arr) => {
            let t = lua.create_table()?;
            for (i, v) in arr.iter().enumerate() {
                t.set(i + 1, netvalue_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
        NetValue::Map(map) => {
            let t = lua.create_table()?;
            for (k, v) in map {
                t.set(k.as_str(), netvalue_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
    }
}

/// Converts a [`HostRole`] to a Lua-friendly string.
fn role_to_string(role: HostRole) -> &'static str {
    match role {
        HostRole::Server => "server",
        HostRole::Client => "client",
        HostRole::Host => "host",
    }
}

// -------------------------------------------------------------------------------
// LuaNetworkHost UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`NetworkHost`].
pub struct LuaNetworkHost {
    inner: RefCell<NetworkHost>,
}

impl LuaUserData for LuaNetworkHost {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- service --
        /// Polls the network for one event, returning an event table or nil.
        /// @param timeout_ms? integer
        /// @return table?
        methods.add_method("service", |lua, this, ()| {
            match this
                .inner
                .borrow_mut()
                .service()
                .map_err(LuaError::external)?
            {
                Some(ev) => Ok(LuaValue::Table(event_to_table(lua, ev)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- connect --
        /// Initiates a connection to a remote host, returning the peer ID.
        /// @param addr string
        /// @param channels integer?
        /// @param data integer?
        /// @return integer
        methods.add_method(
            "connect",
            |_, this, (addr_str, channels, data): (String, Option<usize>, Option<u32>)| {
                let addr = parse_addr(&addr_str)?;
                Ok(this
                    .inner
                    .borrow_mut()
                    .connect(addr, channels.unwrap_or(1), data.unwrap_or(0))
                    .map_err(LuaError::external)?
                    .0)
            },
        );

        // -- send --
        /// Sends data to a specific peer on a channel.
        /// @param peer_id integer
        /// @param channel_id integer
        /// @param data string
        /// @param reliable boolean?
        /// @return nil
        methods.add_method(
            "send",
            |_, this, (peer_id, channel_id, data, reliable): (usize, u8, LuaString, Option<bool>)| {
                this.inner
                    .borrow_mut()
                    .send_bytes(PeerID(peer_id), channel_id, data.as_bytes(), reliable.unwrap_or(true))
                    .map_err(LuaError::external)
            },
        );

        // -- broadcast --
        /// Broadcasts data to all connected peers on a channel.
        /// @param channel_id integer
        /// @param data string
        /// @param reliable boolean?
        /// @return nil
        methods.add_method(
            "broadcast",
            |_, this, (channel_id, data, reliable): (u8, LuaString, Option<bool>)| {
                this.inner
                    .borrow_mut()
                    .broadcast_bytes(channel_id, data.as_bytes(), reliable.unwrap_or(true))
                    .map_err(LuaError::external)
            },
        );

        // -- flush --
        /// Flushes all pending sends immediately.
        /// @return nil
        methods.add_method("flush", |_, this, ()| {
            this.inner.borrow_mut().flush().map_err(LuaError::external)
        });

        // -- disconnect --
        /// Gracefully disconnects a peer.
        /// @param peer_id integer
        /// @param data integer?
        /// @return nil
        methods.add_method(
            "disconnect",
            |_, this, (peer_id, data): (usize, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .disconnect(PeerID(peer_id), data.unwrap_or(0))
                    .map_err(LuaError::external)
            },
        );

        // -- disconnectNow --
        /// Immediately disconnects a peer without handshake.
        /// @param peer_id integer
        /// @param data integer?
        /// @return nil
        methods.add_method(
            "disconnectNow",
            |_, this, (peer_id, data): (usize, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .disconnect_now(PeerID(peer_id), data.unwrap_or(0))
                    .map_err(LuaError::external)
            },
        );

        // -- disconnectLater --
        /// Disconnects a peer after all queued packets have been sent.
        /// @param peer_id integer
        /// @param data integer?
        /// @return nil
        methods.add_method(
            "disconnectLater",
            |_, this, (peer_id, data): (usize, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .disconnect_later(PeerID(peer_id), data.unwrap_or(0))
                    .map_err(LuaError::external)
            },
        );

        // -- resetPeer --
        /// Resets a peer connection immediately without notifying the remote side.
        /// @param peer_id integer
        /// @return nil
        methods.add_method("resetPeer", |_, this, peer_id: usize| {
            this.inner
                .borrow_mut()
                .reset_peer(PeerID(peer_id))
                .map_err(LuaError::external)
        });

        // -- ping --
        /// Sends a ping to a peer to measure round-trip time.
        /// @param peer_id integer
        /// @return nil
        methods.add_method("ping", |_, this, peer_id: usize| {
            this.inner
                .borrow_mut()
                .ping(PeerID(peer_id))
                .map_err(LuaError::external)
        });

        // -- getRoundTripTime --
        /// Returns the round-trip time estimate for a peer in milliseconds.
        /// @param peer_id integer
        /// @return number
        methods.add_method("getRoundTripTime", |_, this, peer_id: usize| {
            let rtt = this
                .inner
                .borrow()
                .round_trip_time(PeerID(peer_id))
                .map_err(LuaError::external)?;
            Ok(rtt.as_millis() as f64)
        });

        // -- getPeerState --
        /// Returns the connection state of a peer as a string.
        /// @param peer_id integer
        /// @return string
        methods.add_method("getPeerState", |_, this, peer_id: usize| {
            this.inner
                .borrow()
                .peer_state(PeerID(peer_id))
                .map_err(LuaError::external)
        });

        // -- getPeerAddress --
        /// Returns the remote address of a peer, or nil if unavailable.
        /// @param peer_id integer
        /// @return string?
        methods.add_method("getPeerAddress", |_, this, peer_id: usize| {
            let addr = this
                .inner
                .borrow()
                .peer_address(PeerID(peer_id))
                .map_err(LuaError::external)?;
            Ok(addr.map(|a| a.to_string()))
        });

        // -- getAddress --
        /// Returns the local bind address as a string.
        /// @return string
        methods.add_method("getAddress", |_, this, ()| {
            Ok(this.inner.borrow().local_address().to_string())
        });

        // -- getPeerLimit --
        /// Returns the maximum number of peer slots.
        /// @return integer
        methods.add_method("getPeerLimit", |_, this, ()| {
            this.inner.borrow().peer_limit().map_err(LuaError::external)
        });

        // -- getChannelLimit --
        /// Returns the maximum number of channels per connection.
        /// @return integer
        methods.add_method("getChannelLimit", |_, this, ()| {
            this.inner
                .borrow()
                .channel_limit()
                .map_err(LuaError::external)
        });

        // -- setChannelLimit --
        /// Sets the channel limit for future connections.
        /// @param limit integer
        /// @return nil
        methods.add_method("setChannelLimit", |_, this, limit: usize| {
            this.inner
                .borrow_mut()
                .set_channel_limit(limit)
                .map_err(LuaError::external)
        });

        // -- getBandwidthLimit --
        /// Returns the bandwidth limits as a table with incoming and outgoing fields.
        /// @return table
        methods.add_method("getBandwidthLimit", |lua, this, ()| {
            let (inc, out) = this
                .inner
                .borrow()
                .bandwidth_limit()
                .map_err(LuaError::external)?;
            let t = lua.create_table()?;
            t.set("incoming", inc)?;
            t.set("outgoing", out)?;
            Ok(t)
        });

        // -- setBandwidthLimit --
        /// Sets the bandwidth limits in bytes per second.
        /// @param incoming integer?
        /// @param outgoing integer?
        /// @return nil
        methods.add_method(
            "setBandwidthLimit",
            |_, this, (incoming, outgoing): (Option<u32>, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .set_bandwidth_limit(incoming, outgoing)
                    .map_err(LuaError::external)
            },
        );

        // -- getConnectedPeerCount --
        /// Returns the number of currently connected peers.
        /// @return integer
        methods.add_method("getConnectedPeerCount", |_, this, ()| {
            this.inner
                .borrow_mut()
                .connected_peer_count()
                .map_err(LuaError::external)
        });

        // -- getConnectedPeerIds --
        /// Returns a table of connected peer IDs.
        /// @return table
        methods.add_method("getConnectedPeerIds", |_, this, ()| {
            let ids = this
                .inner
                .borrow_mut()
                .connected_peer_ids()
                .map_err(LuaError::external)?;
            let result: Vec<usize> = ids.into_iter().map(|id| id.0).collect();
            Ok(result)
        });

        // -- getPeerStats --
        /// Returns a statistics table for a peer.
        /// @param peer_id integer
        /// @return table
        methods.add_method("getPeerStats", |lua, this, peer_id: usize| {
            let stats = this
                .inner
                .borrow()
                .peer_stats(PeerID(peer_id))
                .map_err(LuaError::external)?;
            stats_to_table(lua, stats)
        });

        // -- destroy --
        /// Destroys the host, closing the underlying socket.
        /// @return nil
        methods.add_method("destroy", |_, this, ()| {
            this.inner.borrow_mut().destroy();
            Ok(())
        });

        // -- isDestroyed --
        /// Returns true if the host has been destroyed.
        /// @return boolean
        methods.add_method("isDestroyed", |_, this, ()| {
            Ok(this.inner.borrow().is_destroyed())
        });

        // -- getRole --
        /// Returns the multiplayer role of this host ("server", "client", or "host").
        /// @return string
        methods.add_method("getRole", |_, this, ()| {
            Ok(role_to_string(this.inner.borrow().role()))
        });

        // -- isServer --
        /// Returns true if this host was created as a server.
        /// @return boolean
        methods.add_method("isServer", |_, this, ()| {
            Ok(this.inner.borrow().role() == HostRole::Server)
        });

        // -- isClient --
        /// Returns true if this host was created as a client.
        /// @return boolean
        methods.add_method("isClient", |_, this, ()| {
            Ok(this.inner.borrow().role() == HostRole::Client)
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!(
                "NetworkHost({})",
                this.inner.borrow().local_address()
            ))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LNetworkHost"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNetworkHost" || name == "Object")
        });
    }
}

/// Lua-side wrapper around [`NetworkRuntime`] for async HTTP/TCP/WebSocket.
pub struct LuaNetworkRuntime {
    inner: RefCell<NetworkRuntime>,
}

impl LuaUserData for LuaNetworkRuntime {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- httpRequest --
        /// Sends an HTTP request asynchronously. Poll with `poll()` for the response.
        /// @param opts table — { method, url, headers?, body?, timeout? }
        /// @return nil
        /// integer — request ID
        methods.add_method("httpRequest", |_, this, opts: LuaTable| {
            let method: String = opts.get("method").unwrap_or_else(|_| "GET".into());
            let url: String = opts.get("url").map_err(|_| {
                LuaError::RuntimeError("httpRequest: 'url' field is required".into())
            })?;
            let headers: Option<Vec<(String, String)>> =
                opts.get::<_, LuaTable>("headers").ok().map(|t| {
                    let mut h = Vec::new();
                    if let Ok(pairs) = t.pairs::<String, String>().collect::<Result<Vec<_>, _>>() {
                        h = pairs;
                    }
                    h
                });
            let body: Option<String> = opts.get("body").ok();
            let timeout: Option<u64> = opts.get("timeout").ok();

            let id = this
                .inner
                .borrow_mut()
                .http_request(&method, &url, headers.as_deref(), body.as_deref(), timeout)
                .map_err(LuaError::external)?;
            Ok(id)
        });

        // -- httpGet --
        /// Convenience: sends an HTTP GET request.
        /// @param url string
        /// @param headers table?
        /// @return integer
        methods.add_method(
            "httpGet",
            |_, this, (url, headers): (String, Option<LuaTable>)| {
                let h: Option<Vec<(String, String)>> = headers.map(|t| {
                    t.pairs::<String, String>()
                        .collect::<Result<Vec<_>, _>>()
                        .unwrap_or_default()
                });
                let id = this
                    .inner
                    .borrow_mut()
                    .http_request("GET", &url, h.as_deref(), None, None)
                    .map_err(LuaError::external)?;
                Ok(id)
            },
        );

        // -- httpPost --
        /// Convenience: sends an HTTP POST request.
        /// @param url string
        /// @param body string
        /// @param headers table?
        /// @return integer
        methods.add_method(
            "httpPost",
            |_, this, (url, body, headers): (String, String, Option<LuaTable>)| {
                let h: Option<Vec<(String, String)>> = headers.map(|t| {
                    t.pairs::<String, String>()
                        .collect::<Result<Vec<_>, _>>()
                        .unwrap_or_default()
                });
                let id = this
                    .inner
                    .borrow_mut()
                    .http_request("POST", &url, h.as_deref(), Some(&body), None)
                    .map_err(LuaError::external)?;
                Ok(id)
            },
        );

        // -- tcpConnect --
        /// Opens a TCP connection to a remote address.
        /// @param addr string
        /// @return integer
        methods.add_method("tcpConnect", |_, this, addr: String| {
            let id = this
                .inner
                .borrow_mut()
                .tcp_connect(&addr)
                .map_err(LuaError::external)?;
            Ok(id)
        });

        // -- tcpSend --
        /// Sends data over a TCP connection.
        /// @param id integer — connection ID
        /// @param data string
        /// @return nil
        methods.add_method("tcpSend", |_, this, (id, data): (u64, LuaString)| {
            this.inner
                .borrow_mut()
                .tcp_send(id, data.as_bytes())
                .map_err(LuaError::external)
        });

        // -- tcpClose --
        /// Closes the TCP connection identified by the given connection handle.
        /// @param id integer — connection ID
        /// @return nil
        methods.add_method("tcpClose", |_, this, id: u64| {
            this.inner
                .borrow_mut()
                .tcp_close(id)
                .map_err(LuaError::external)
        });

        // -- wsConnect --
        /// Opens a WebSocket connection.
        /// @param url string
        /// @return integer
        methods.add_method("wsConnect", |_, this, url: String| {
            let id = this
                .inner
                .borrow_mut()
                .ws_connect(&url)
                .map_err(LuaError::external)?;
            Ok(id)
        });

        // -- wsSend --
        /// Sends a text message over a WebSocket connection.
        /// @param id integer — connection ID
        /// @param data string
        /// @return nil
        methods.add_method("wsSend", |_, this, (id, data): (u64, String)| {
            this.inner
                .borrow_mut()
                .ws_send(id, &data)
                .map_err(LuaError::external)
        });

        // -- wsClose --
        /// Closes a WebSocket connection.
        /// @param id integer — connection ID
        /// @return nil
        methods.add_method("wsClose", |_, this, id: u64| {
            this.inner
                .borrow_mut()
                .ws_close(id)
                .map_err(LuaError::external)
        });

        // -- poll --
        /// Polls for completed async responses (HTTP, TCP events, WebSocket events).
        /// Returns a table array of response/event tables, or empty table if none.
        /// @return table
        methods.add_method("poll", |lua, this, ()| {
            let responses = this.inner.borrow_mut().poll();
            let results = lua.create_table()?;
            for (i, resp) in responses.iter().enumerate() {
                let t = lua.create_table()?;
                match resp {
                    crate::network::net_thread::NetworkResponse::HttpResponse {
                        id,
                        status,
                        body,
                        headers,
                        error,
                    } => {
                        t.set("type", "http")?;
                        t.set("request_id", *id)?;
                        t.set("status", *status)?;
                        t.set("body", lua.create_string(body)?)?;
                        if let Some(ref err) = error {
                            t.set("error", err.as_str())?;
                        }
                        let headers_table = lua.create_table()?;
                        for (k, v) in headers {
                            headers_table.set(k.as_str(), v.as_str())?;
                        }
                        t.set("headers", headers_table)?;
                    }
                    crate::network::net_thread::NetworkResponse::TcpEvent { id, event } => {
                        t.set("type", "tcp")?;
                        t.set("id", *id)?;
                        match event {
                            crate::network::net_thread::TcpEvent::Connected => {
                                t.set("event", "connected")?;
                            }
                            crate::network::net_thread::TcpEvent::Data(data) => {
                                t.set("event", "data")?;
                                t.set("data", lua.create_string(data)?)?;
                            }
                            crate::network::net_thread::TcpEvent::Disconnected(reason) => {
                                t.set("event", "disconnected")?;
                                if !reason.is_empty() {
                                    t.set("reason", reason.as_str())?;
                                }
                            }
                            crate::network::net_thread::TcpEvent::Error(err) => {
                                t.set("event", "error")?;
                                t.set("error", err.as_str())?;
                            }
                        }
                    }
                    crate::network::net_thread::NetworkResponse::WebSocketEvent { id, event } => {
                        t.set("type", "websocket")?;
                        t.set("id", *id)?;
                        match event {
                            crate::network::net_thread::WsEvent::Open => {
                                t.set("event", "open")?;
                            }
                            crate::network::net_thread::WsEvent::Text(data) => {
                                t.set("event", "text")?;
                                t.set("data", data.as_str())?;
                            }
                            crate::network::net_thread::WsEvent::Binary(data) => {
                                t.set("event", "binary")?;
                                t.set("data", lua.create_string(data)?)?;
                            }
                            crate::network::net_thread::WsEvent::Close { code, reason } => {
                                t.set("event", "close")?;
                                t.set("code", *code)?;
                                if !reason.is_empty() {
                                    t.set("reason", reason.as_str())?;
                                }
                            }
                            crate::network::net_thread::WsEvent::Error(err) => {
                                t.set("event", "error")?;
                                t.set("error", err.as_str())?;
                            }
                        }
                    }
                }
                results.set(i + 1, t)?;
            }
            Ok(results)
        });

        // -- shutdown --
        /// Shuts down the background network thread.
        /// @return nil
        methods.add_method("shutdown", |_, this, ()| {
            this.inner.borrow_mut().shutdown();
            Ok(())
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, _this, ()| {
            Ok("NetworkRuntime".to_string())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LNetworkRuntime"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNetworkRuntime" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.network` API table with the Lua VM.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param _state Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- MAX_PEERS constant --
    /// Maximum number of simultaneous peer connections a single host supports.
    tbl.set("MAX_PEERS", MAX_PEERS as u64)?;

    // -- DEFAULT_PEERS constant --
    /// Default number of peers when no explicit value is provided.
    tbl.set("DEFAULT_PEERS", DEFAULT_PEERS as u64)?;

    // -- MAX_CHANNELS constant --
    /// Maximum number of independent ENet channels per connection.
    tbl.set("MAX_CHANNELS", MAX_CHANNELS as u64)?;

    // -- DEFAULT_CHANNELS constant --
    /// Default channel count for new connections when none is specified.
    tbl.set("DEFAULT_CHANNELS", DEFAULT_CHANNELS as u64)?;

    // -- newHost --
    /// Creates a new network host bound to the given address.
    ///
    /// Accepts `maxPeers` (preferred) or `peers` (legacy alias) to set the peer limit.
    /// Valid range is `[1, MAX_PEERS]`. Defaults to `DEFAULT_PEERS` when omitted.
    /// @param opts? table — { addr?, maxPeers?, peers?, channels?, inBandwidth?, outBandwidth? }
    /// @return NetworkHost
    tbl.set(
        "newHost",
        lua.create_function(|_, opts: LuaTable| {
            let addr_str: String = opts
                .get::<_, String>("addr")
                .unwrap_or_else(|_| "0.0.0.0:0".to_string());
            let addr = parse_addr(&addr_str)?;
            // Accept `maxPeers` (documented) or `peers` (legacy alias).
            let peers: Option<usize> = opts
                .get::<_, usize>("maxPeers")
                .ok()
                .or_else(|| opts.get("peers").ok());
            let host = NetworkHost::new(
                addr,
                peers,
                opts.get("channels").ok(),
                opts.get("inBandwidth").ok(),
                opts.get("outBandwidth").ok(),
            )
            .map_err(LuaError::external)?;
            Ok(LuaNetworkHost {
                inner: RefCell::new(host),
            })
        })?,
    )?;

    // -- newServer --
    /// Creates a server host that binds to a port and accepts connections.
    ///
    /// Accepts `maxPeers` (preferred) or `peers` (legacy alias) to set the peer limit.
    /// Valid range is `[1, MAX_PEERS]`. Defaults to `DEFAULT_PEERS` when omitted.
    /// @param opts table — { port, maxPeers?, peers?, channels? }
    /// @return NetworkHost
    tbl.set(
        "newServer",
        lua.create_function(|_, opts: LuaTable| {
            let port: u16 = opts.get("port").map_err(|_| {
                LuaError::RuntimeError("newServer: 'port' field is required".into())
            })?;
            // Accept `maxPeers` (documented) or `peers` (legacy alias).
            let peers: Option<usize> = opts
                .get::<_, usize>("maxPeers")
                .ok()
                .or_else(|| opts.get("peers").ok());
            let host = NetworkHost::create_server(port, peers, opts.get("channels").ok())
                .map_err(LuaError::external)?;
            Ok(LuaNetworkHost {
                inner: RefCell::new(host),
            })
        })?,
    )?;

    // -- newClient --
    /// Creates a client host that connects to a remote server.
    /// @param opts table — { addr, channels?, data? }
    /// @return NetworkHost
    tbl.set(
        "newClient",
        lua.create_function(|_, opts: LuaTable| {
            let addr_str: String = opts.get("addr").map_err(|_| {
                LuaError::RuntimeError("newClient: 'addr' field is required".into())
            })?;
            let addr = parse_addr(&addr_str)?;
            let host =
                NetworkHost::create_client(addr, opts.get("channels").ok(), opts.get("data").ok())
                    .map_err(LuaError::external)?;
            Ok(LuaNetworkHost {
                inner: RefCell::new(host),
            })
        })?,
    )?;

    // -- newRuntime --
    /// Creates a background network runtime for async HTTP, TCP, and WebSocket.
    /// @return NetworkRuntime
    tbl.set(
        "newRuntime",
        lua.create_function(|_, ()| {
            let rt = NetworkRuntime::new().map_err(LuaError::external)?;
            Ok(LuaNetworkRuntime {
                inner: RefCell::new(rt),
            })
        })?,
    )?;

    // -- pack --
    /// Serializes a Lua value to a binary MessagePack string.
    /// @param value any
    /// @return string
    tbl.set(
        "pack",
        lua.create_function(|lua, value: LuaValue| {
            let net_val = lua_to_netvalue(&value)?;
            let bytes = crate::network::message::pack(&net_val).map_err(LuaError::external)?;
            lua.create_string(&bytes)
        })?,
    )?;

    // -- unpack --
    /// Deserializes a MessagePack binary string back to a Lua value.
    /// @param data string
    /// @return table|nil
    tbl.set(
        "unpack",
        lua.create_function(|lua, data: LuaString| {
            let net_val =
                crate::network::message::unpack(data.as_bytes()).map_err(LuaError::external)?;
            netvalue_to_lua(lua, &net_val)
        })?,
    )?;

    // -- createLobby --
    /// Creates a LobbyInfo record and broadcasts it once on the local network.
    /// @return table|nil
    /// Other machines on the same subnet can discover it via lurek.network.discoverLobbies().
    /// @param name string
    /// @param port integer
    /// @param player_count integer?
    /// @param max_players integer?
    /// table  { name, host, port, player_count, max_players }
    tbl.set(
        "createLobby",
        lua.create_function(
            |lua, (name, port, player_count, max_players): (String, u16, Option<u32>, Option<u32>)| {
                let info = crate::network::lobby::LobbyInfo {
                    name,
                    host: "0.0.0.0".to_string(),
                    port,
                    player_count: player_count.unwrap_or(1),
                    max_players: max_players.unwrap_or(8),
                };
                crate::network::lobby::broadcast_lobby(&info).map_err(LuaError::external)?;
                let t = lua.create_table()?;
                t.set("name", info.name.clone())?;
                t.set("host", info.host.clone())?;
                t.set("port", info.port)?;
                t.set("player_count", info.player_count)?;
                t.set("max_players", info.max_players)?;
                Ok(t)
            },
        )?,
    )?;

    // -- discoverLobbies --
    /// Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
    /// @return table|nil
    /// Returns an array of lobby tables: { name, host, port, player_count, max_players }.
    /// @param timeout_ms integer?
    /// table  array of lobby tables
    tbl.set(
        "discoverLobbies",
        lua.create_function(|lua, timeout_ms: Option<u64>| {
            let lobbies = crate::network::lobby::discover_lobbies(timeout_ms.unwrap_or(500));
            let arr = lua.create_table()?;
            for (i, info) in lobbies.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("name", info.name.clone())?;
                t.set("host", info.host.clone())?;
                t.set("port", info.port)?;
                t.set("player_count", info.player_count)?;
                t.set("max_players", info.max_players)?;
                arr.set(i + 1, t)?;
            }
            Ok(arr)
        })?,
    )?;

    // -- syncEntity --
    /// Convenience helper: packs an entity snapshot and broadcasts it to all peers.
    /// The data table may contain any MessagePack-serializable values.
    /// Wraps the data in { id = entity_id, data = data } before serialization.
    /// @param host NetworkHost
    /// @param entity_id integer
    /// @param data table
    /// @param channel integer?   (default 0)
    /// @param reliable boolean?  (default false)
    /// @return nil
    tbl.set(
        "syncEntity",
        lua.create_function(
            |_lua,
             (host_ud, entity_id, data_tbl, channel, reliable): (
                LuaAnyUserData,
                u32,
                LuaTable,
                Option<u8>,
                Option<bool>,
            )| {
                let host = host_ud.borrow_mut::<LuaNetworkHost>()?;
                // Build envelope: { id = entity_id, data = <table fields> }
                let mut fields: Vec<(String, NetValue)> = Vec::new();
                for pair in data_tbl.pairs::<LuaValue, LuaValue>() {
                    let (k, v) = pair?;
                    let key = match &k {
                        LuaValue::String(s) => s.to_str()?.to_string(),
                        LuaValue::Integer(i) => i.to_string(),
                        _ => continue,
                    };
                    fields.push((key, lua_to_netvalue(&v)?));
                }
                let envelope = vec![
                    ("id".to_string(), NetValue::Integer(entity_id as i64)),
                    ("data".to_string(), NetValue::Map(fields)),
                ];
                let payload = crate::network::message::pack(&NetValue::Map(envelope))
                    .map_err(LuaError::external)?;
                host.inner
                    .borrow_mut()
                    .broadcast_bytes(channel.unwrap_or(0), &payload, reliable.unwrap_or(false))
                    .map_err(LuaError::external)?;
                Ok(())
            },
        )?,
    )?;

    lurek.set("network", tbl)?;
    Ok(())
}
