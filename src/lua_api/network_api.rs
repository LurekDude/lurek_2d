//! `lurek.network` - UDP networking via ENet for multiplayer games.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::net::SocketAddr;
use std::rc::Rc;

use crate::network::host::{NetworkEvent, NetworkHost, PeerStats};
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
        /// @return table?
        methods.add_method("service", |lua, this, ()| {
            match this.inner.borrow_mut().service().map_err(LuaError::external)? {
                Some(ev) => Ok(LuaValue::Table(event_to_table(lua, ev)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- connect --
        /// Initiates a connection to a remote host, returning the peer ID.
        /// @param addr : string
        /// @param channels : integer?
        /// @param data : integer?
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
        /// @param peer_id : integer
        /// @param channel_id : integer
        /// @param data : string
        /// @param reliable : boolean?
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
        /// @param channel_id : integer
        /// @param data : string
        /// @param reliable : boolean?
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
        /// @param peer_id : integer
        /// @param data : integer?
        /// @return nil
        methods.add_method("disconnect", |_, this, (peer_id, data): (usize, Option<u32>)| {
            this.inner
                .borrow_mut()
                .disconnect(PeerID(peer_id), data.unwrap_or(0))
                .map_err(LuaError::external)
        });

        // -- disconnectNow --
        /// Immediately disconnects a peer without handshake.
        /// @param peer_id : integer
        /// @param data : integer?
        /// @return nil
        methods.add_method("disconnectNow", |_, this, (peer_id, data): (usize, Option<u32>)| {
            this.inner
                .borrow_mut()
                .disconnect_now(PeerID(peer_id), data.unwrap_or(0))
                .map_err(LuaError::external)
        });

        // -- disconnectLater --
        /// Disconnects a peer after all queued packets have been sent.
        /// @param peer_id : integer
        /// @param data : integer?
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
        /// @param peer_id : integer
        /// @return nil
        methods.add_method("resetPeer", |_, this, peer_id: usize| {
            this.inner
                .borrow_mut()
                .reset_peer(PeerID(peer_id))
                .map_err(LuaError::external)
        });

        // -- ping --
        /// Sends a ping to a peer to measure round-trip time.
        /// @param peer_id : integer
        /// @return nil
        methods.add_method("ping", |_, this, peer_id: usize| {
            this.inner
                .borrow_mut()
                .ping(PeerID(peer_id))
                .map_err(LuaError::external)
        });

        // -- getRoundTripTime --
        /// Returns the round-trip time estimate for a peer in milliseconds.
        /// @param peer_id : integer
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
        /// @param peer_id : integer
        /// @return string
        methods.add_method("getPeerState", |_, this, peer_id: usize| {
            this.inner
                .borrow()
                .peer_state(PeerID(peer_id))
                .map_err(LuaError::external)
        });

        // -- getPeerAddress --
        /// Returns the remote address of a peer, or nil if unavailable.
        /// @param peer_id : integer
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
            this.inner.borrow().channel_limit().map_err(LuaError::external)
        });

        // -- setChannelLimit --
        /// Sets the channel limit for future connections.
        /// @param limit : integer
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
            let (inc, out) = this.inner.borrow().bandwidth_limit().map_err(LuaError::external)?;
            let t = lua.create_table()?;
            t.set("incoming", inc)?;
            t.set("outgoing", out)?;
            Ok(t)
        });

        // -- setBandwidthLimit --
        /// Sets the bandwidth limits in bytes per second.
        /// @param incoming : integer?
        /// @param outgoing : integer?
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
            this.inner.borrow_mut().connected_peer_count().map_err(LuaError::external)
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
        /// @param peer_id : integer
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

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("NetworkHost({})", this.inner.borrow().local_address()))
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.network` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newHost --
    /// Creates a new network host bound to the given address.
    /// @param opts : table
    /// @return NetworkHost
    tbl.set(
        "newHost",
        lua.create_function(|_, opts: LuaTable| {
            let addr_str: String = opts
                .get::<_, String>("addr")
                .unwrap_or_else(|_| "0.0.0.0:0".to_string());
            let addr = parse_addr(&addr_str)?;
            let host = NetworkHost::new(
                addr,
                opts.get("peers").ok(),
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

    luna.set("network", tbl)?;
    Ok(())
}
