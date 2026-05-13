use super::SharedState;
use crate::network::constants::{DEFAULT_CHANNELS, DEFAULT_PEERS, MAX_CHANNELS, MAX_PEERS};
use crate::network::host::{HostRole, NetworkEvent, NetworkHost, PeerStats};
use crate::network::message::NetValue;
use crate::network::net_thread::NetworkRuntime;
use mlua::prelude::*;
use rusty_enet::PeerID;
use std::cell::RefCell;
use std::net::SocketAddr;
use std::rc::Rc;
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
fn parse_addr(s: &str) -> LuaResult<SocketAddr> {
    s.parse()
        .map_err(|_| LuaError::RuntimeError(format!("invalid address: {s}")))
}
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
fn room_to_table<'lua>(
    lua: &'lua Lua,
    room: &crate::network::lobby::RoomInfo,
) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    t.set("id", room.id.clone())?;
    t.set("name", room.name.clone())?;
    t.set("host", room.host.clone())?;
    t.set("player_count", room.player_count)?;
    t.set("max_players", room.max_players)?;
    Ok(t)
}
fn lua_table_to_netvalue(t: &LuaTable) -> LuaResult<NetValue> {
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
fn role_to_string(role: HostRole) -> &'static str {
    match role {
        HostRole::Server => "server",
        HostRole::Client => "client",
        HostRole::Host => "host",
    }
}
pub struct LuaNetworkHost {
    inner: RefCell<NetworkHost>,
}
impl LuaUserData for LuaNetworkHost {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("send", |_, this, (peer_id, channel_id, data, reliable): (usize, u8, LuaString, Option<bool>)| {
                this.inner
                    .borrow_mut()
                    .send_bytes(PeerID(peer_id), channel_id, data.as_bytes(), reliable.unwrap_or(true))
                    .map_err(LuaError::external)
            },
        );
        methods.add_method(
            "broadcast",
            |_, this, (channel_id, data, reliable): (u8, LuaString, Option<bool>)| {
                this.inner
                    .borrow_mut()
                    .broadcast_bytes(channel_id, data.as_bytes(), reliable.unwrap_or(true))
                    .map_err(LuaError::external)
            },
        );
        methods.add_method("flush", |_, this, ()| {
            this.inner.borrow_mut().flush().map_err(LuaError::external)
        });
        methods.add_method(
            "disconnect",
            |_, this, (peer_id, data): (usize, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .disconnect(PeerID(peer_id), data.unwrap_or(0))
                    .map_err(LuaError::external)
            },
        );
        methods.add_method(
            "disconnectNow",
            |_, this, (peer_id, data): (usize, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .disconnect_now(PeerID(peer_id), data.unwrap_or(0))
                    .map_err(LuaError::external)
            },
        );
        methods.add_method(
            "disconnectLater",
            |_, this, (peer_id, data): (usize, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .disconnect_later(PeerID(peer_id), data.unwrap_or(0))
                    .map_err(LuaError::external)
            },
        );
        methods.add_method("resetPeer", |_, this, peer_id: usize| {
            this.inner
                .borrow_mut()
                .reset_peer(PeerID(peer_id))
                .map_err(LuaError::external)
        });
        methods.add_method("ping", |_, this, peer_id: usize| {
            this.inner
                .borrow_mut()
                .ping(PeerID(peer_id))
                .map_err(LuaError::external)
        });
        methods.add_method("getRoundTripTime", |_, this, peer_id: usize| {
            let rtt = this
                .inner
                .borrow()
                .round_trip_time(PeerID(peer_id))
                .map_err(LuaError::external)?;
            Ok(rtt.as_millis() as f64)
        });
        methods.add_method("getPeerState", |_, this, peer_id: usize| {
            this.inner
                .borrow()
                .peer_state(PeerID(peer_id))
                .map_err(LuaError::external)
        });
        methods.add_method("getPeerAddress", |_, this, peer_id: usize| {
            let addr = this
                .inner
                .borrow()
                .peer_address(PeerID(peer_id))
                .map_err(LuaError::external)?;
            Ok(addr.map(|a| a.to_string()))
        });
        methods.add_method("getAddress", |_, this, ()| {
            Ok(this.inner.borrow().local_address().to_string())
        });
        methods.add_method("getPeerLimit", |_, this, ()| {
            this.inner.borrow().peer_limit().map_err(LuaError::external)
        });
        methods.add_method("getChannelLimit", |_, this, ()| {
            this.inner
                .borrow()
                .channel_limit()
                .map_err(LuaError::external)
        });
        methods.add_method("setChannelLimit", |_, this, limit: usize| {
            this.inner
                .borrow_mut()
                .set_channel_limit(limit)
                .map_err(LuaError::external)
        });
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
        methods.add_method(
            "setBandwidthLimit",
            |_, this, (incoming, outgoing): (Option<u32>, Option<u32>)| {
                this.inner
                    .borrow_mut()
                    .set_bandwidth_limit(incoming, outgoing)
                    .map_err(LuaError::external)
            },
        );
        methods.add_method("getConnectedPeerCount", |_, this, ()| {
            this.inner
                .borrow_mut()
                .connected_peer_count()
                .map_err(LuaError::external)
        });
        methods.add_method("getConnectedPeerIds", |_, this, ()| {
            let ids = this
                .inner
                .borrow_mut()
                .connected_peer_ids()
                .map_err(LuaError::external)?;
            let result: Vec<usize> = ids.into_iter().map(|id| id.0).collect();
            Ok(result)
        });
        methods.add_method("getPeerStats", |lua, this, peer_id: usize| {
            let stats = this
                .inner
                .borrow()
                .peer_stats(PeerID(peer_id))
                .map_err(LuaError::external)?;
            stats_to_table(lua, stats)
        });
        methods.add_method("destroy", |_, this, ()| {
            this.inner.borrow_mut().destroy();
            Ok(())
        });
        methods.add_method("isDestroyed", |_, this, ()| {
            Ok(this.inner.borrow().is_destroyed())
        });
        methods.add_method("getRole", |_, this, ()| {
            Ok(role_to_string(this.inner.borrow().role()))
        });
        methods.add_method("isServer", |_, this, ()| {
            Ok(this.inner.borrow().role() == HostRole::Server)
        });
        methods.add_method("isClient", |_, this, ()| {
            Ok(this.inner.borrow().role() == HostRole::Client)
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!(
                "NetworkHost({})",
                this.inner.borrow().local_address()
            ))
        });
        methods.add_method("type", |_, _, ()| Ok("LNetworkHost"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNetworkHost" || name == "Object")
        });
    }
}
pub struct LuaNetworkRuntime {
    inner: RefCell<NetworkRuntime>,
}
impl LuaUserData for LuaNetworkRuntime {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("tcpConnect", |_, this, addr: String| {
            let id = this
                .inner
                .borrow_mut()
                .tcp_connect(&addr)
                .map_err(LuaError::external)?;
            Ok(id)
        });
        methods.add_method("tcpSend", |_, this, (id, data): (u64, LuaString)| {
            this.inner
                .borrow_mut()
                .tcp_send(id, data.as_bytes())
                .map_err(LuaError::external)
        });
        methods.add_method("tcpClose", |_, this, id: u64| {
            this.inner
                .borrow_mut()
                .tcp_close(id)
                .map_err(LuaError::external)
        });
        methods.add_method("wsConnect", |_, this, url: String| {
            let id = this
                .inner
                .borrow_mut()
                .ws_connect(&url)
                .map_err(LuaError::external)?;
            Ok(id)
        });
        methods.add_method("wsSend", |_, this, (id, data): (u64, String)| {
            this.inner
                .borrow_mut()
                .ws_send(id, &data)
                .map_err(LuaError::external)
        });
        methods.add_method("wsClose", |_, this, id: u64| {
            this.inner
                .borrow_mut()
                .ws_close(id)
                .map_err(LuaError::external)
        });
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
        methods.add_method("shutdown", |_, this, ()| {
            this.inner.borrow_mut().shutdown();
            Ok(())
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, _this, ()| {
            Ok("NetworkRuntime".to_string())
        });
        methods.add_method("type", |_, _, ()| Ok("LNetworkRuntime"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNetworkRuntime" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("MAX_PEERS", MAX_PEERS as u64)?;
    tbl.set("DEFAULT_PEERS", DEFAULT_PEERS as u64)?;
    tbl.set("MAX_CHANNELS", MAX_CHANNELS as u64)?;
    tbl.set("DEFAULT_CHANNELS", DEFAULT_CHANNELS as u64)?;
    tbl.set(
        "newHost",
        lua.create_function(|_, opts: LuaTable| {
            let addr_str: String = opts
                .get::<_, String>("addr")
                .unwrap_or_else(|_| "0.0.0.0:0".to_string());
            let addr = parse_addr(&addr_str)?;
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
    tbl.set(
        "newServer",
        lua.create_function(|_, opts: LuaTable| {
            let port: u16 = opts.get("port").map_err(|_| {
                LuaError::RuntimeError("newServer: 'port' field is required".into())
            })?;
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
    tbl.set(
        "newRuntime",
        lua.create_function(|_, ()| {
            let rt = NetworkRuntime::new().map_err(LuaError::external)?;
            Ok(LuaNetworkRuntime {
                inner: RefCell::new(rt),
            })
        })?,
    )?;
    tbl.set(
        "pack",
        lua.create_function(|lua, value: LuaValue| {
            let net_val = lua_to_netvalue(&value)?;
            let bytes = crate::network::message::pack(&net_val).map_err(LuaError::external)?;
            lua.create_string(&bytes)
        })?,
    )?;
    tbl.set(
        "unpack",
        lua.create_function(|lua, data: LuaString| {
            let net_val =
                crate::network::message::unpack(data.as_bytes()).map_err(LuaError::external)?;
            netvalue_to_lua(lua, &net_val)
        })?,
    )?;
    tbl.set("createLobby", lua.create_function(
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
    tbl.set(
        "createRoom",
        lua.create_function(
            |lua, (name, host, max_players): (String, String, Option<u32>)| {
                let room =
                    crate::network::lobby::create_room(&name, &host, max_players.unwrap_or(8));
                room_to_table(lua, &room)
            },
        )?,
    )?;
    tbl.set(
        "listRooms",
        lua.create_function(|lua, ()| {
            let rooms = crate::network::lobby::list_rooms();
            let out = lua.create_table()?;
            for (i, room) in rooms.iter().enumerate() {
                out.set(i + 1, room_to_table(lua, room)?)?;
            }
            Ok(out)
        })?,
    )?;
    tbl.set(
        "joinRoom",
        lua.create_function(
            |lua, id: String| match crate::network::lobby::join_room(&id) {
                Some(room) => Ok(LuaValue::Table(room_to_table(lua, &room)?)),
                None => Ok(LuaValue::Nil),
            },
        )?,
    )?;
    tbl.set(
        "leaveRoom",
        lua.create_function(
            |lua, id: String| match crate::network::lobby::leave_room(&id) {
                Some(room) => Ok(LuaValue::Table(room_to_table(lua, &room)?)),
                None => Ok(LuaValue::Nil),
            },
        )?,
    )?;
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
    tbl.set(
        "newRelayTicket",
        lua.create_function(|_, (room_id, peer_id): (String, String)| {
            let ticket = crate::network::relay::RelayTicket { room_id, peer_id };
            Ok(crate::network::relay::encode_ticket(&ticket))
        })?,
    )?;
    tbl.set(
        "parseRelayTicket",
        lua.create_function(|lua, token: String| {
            match crate::network::relay::decode_ticket(&token) {
                Some(ticket) => {
                    let t = lua.create_table()?;
                    t.set("room_id", ticket.room_id)?;
                    t.set("peer_id", ticket.peer_id)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        })?,
    )?;
    tbl.set(
        "makePunchProbe",
        lua.create_function(|lua, peer_id: String| {
            lua.create_string(crate::network::relay::make_punch_probe(&peer_id))
        })?,
    )?;
    tbl.set(
        "parsePunchProbe",
        lua.create_function(|_, payload: LuaString| {
            Ok(crate::network::relay::parse_punch_probe(payload.as_bytes()))
        })?,
    )?;
    tbl.set(
        "predictLinear",
        lua.create_function(|lua, (snapshot, dt): (LuaTable, f32)| {
            let src = crate::network::net_sync::EntitySnapshot {
                id: snapshot.get("id")?,
                tick: snapshot.get("tick")?,
                x: snapshot.get("x")?,
                y: snapshot.get("y")?,
                vx: snapshot.get("vx")?,
                vy: snapshot.get("vy")?,
            };
            let out = crate::network::net_sync::predict_linear(&src, dt);
            let t = lua.create_table()?;
            t.set("id", out.id)?;
            t.set("tick", out.tick)?;
            t.set("x", out.x)?;
            t.set("y", out.y)?;
            t.set("vx", out.vx)?;
            t.set("vy", out.vy)?;
            Ok(t)
        })?,
    )?;
    tbl.set(
        "reconcileSnapshot",
        lua.create_function(|lua, (pred, auth, alpha): (LuaTable, LuaTable, f32)| {
            let predicted = crate::network::net_sync::EntitySnapshot {
                id: pred.get("id")?,
                tick: pred.get("tick")?,
                x: pred.get("x")?,
                y: pred.get("y")?,
                vx: pred.get("vx")?,
                vy: pred.get("vy")?,
            };
            let authoritative = crate::network::net_sync::EntitySnapshot {
                id: auth.get("id")?,
                tick: auth.get("tick")?,
                x: auth.get("x")?,
                y: auth.get("y")?,
                vx: auth.get("vx")?,
                vy: auth.get("vy")?,
            };
            let out = crate::network::net_sync::reconcile(&predicted, &authoritative, alpha);
            let t = lua.create_table()?;
            t.set("id", out.id)?;
            t.set("tick", out.tick)?;
            t.set("x", out.x)?;
            t.set("y", out.y)?;
            t.set("vx", out.vx)?;
            t.set("vy", out.vy)?;
            Ok(t)
        })?,
    )?;
    lurek.set("network", tbl)?;
    Ok(())
}
