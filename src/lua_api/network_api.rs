//! `luna.network` Lua API bindings.
//!
//! Auto-generated skeleton from `src/network/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaNetworkHost ────────────────────────────────────────────────────────────

pub struct LuaNetworkHost(/* TODO: add key + state fields */);


impl LuaNetworkHost {
    /// Get the round-trip time estimate for a peer.
    ///
    /// @param peer_id : PeerID
    /// @return Result<Duration
    pub fn round_trip_time(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the connection state of a peer as a string.
    ///
    /// @param peer_id : PeerID
    /// @return Result<
    pub fn peer_state(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the remote address of a peer.
    ///
    /// @param peer_id : PeerID
    /// @return Result<Option<SocketAddr>
    pub fn peer_address(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the local bind address.
    ///
    ///
    /// @return SocketAddr
    pub fn local_address(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of allocated peer slots.
    ///
    ///
    /// @return Result<usize
    pub fn peer_limit(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the channel limit.
    ///
    ///
    /// @return Result<usize
    pub fn channel_limit(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the bandwidth limits.
    ///
    ///
    /// @return Result<(Option<u32>
    pub fn bandwidth_limit(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the host has been destroyed.
    ///
    ///
    /// @return boolean
    pub fn is_destroyed(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get per-peer statistics.
    ///
    /// @param peer_id : PeerID
    /// @return Result<PeerStats
    pub fn peer_stats(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaNetworkHost {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("roundTripTime", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("peerState", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("peerAddress", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("localAddress", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("peerLimit", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("channelLimit", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("bandwidthLimit", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isDestroyed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("peerStats", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.network.* functions ──────────────────────────────────────────

/// Poll for one network event.
///
///
/// @return Result<Option<NetworkEvent>
pub fn service(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Initiate a connection to a remote host.
///
/// @param address : SocketAddr
/// @param channel_count : integer
/// @param data : integer
/// @return Result<PeerID
pub fn connect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Send a packet to a specific peer.
///
/// @param peer_id : PeerID
/// @param channel_id : u8
/// @param packet : Packet
/// @return Result<()
pub fn send(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Broadcast a packet to all connected peers.
///
/// @param channel_id : u8
/// @param packet : Packet
/// @return Result<()
pub fn broadcast(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Flush all queued packets without waiting for the next `service()`.
///
///
/// @return Result<()
pub fn flush(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Request graceful disconnection from a peer.
///
/// @param peer_id : PeerID
/// @param data : integer
/// @return Result<()
pub fn disconnect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Immediately disconnect a peer without handshake.
///
/// @param peer_id : PeerID
/// @param data : integer
/// @return Result<()
pub fn disconnect_now(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Disconnect a peer after all queued packets have been sent.
///
/// @param peer_id : PeerID
/// @param data : integer
/// @return Result<()
pub fn disconnect_later(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Reset a peer connection immediately without notifying the remote side.
///
/// @param peer_id : PeerID
/// @return Result<()
pub fn reset_peer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Send a ping to a peer to measure RTT.
///
/// @param peer_id : PeerID
/// @return Result<()
pub fn ping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the channel limit for future connections.
///
/// @param limit : integer
/// @return Result<()
pub fn set_channel_limit(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set bandwidth limits.
///
/// @param incoming : integer?
/// @param outgoing : integer?
/// @return Result<()
pub fn set_bandwidth_limit(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Get the number of currently connected peers.
///
///
/// @return Result<usize
pub fn connected_peer_count(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Get the IDs of all currently connected peers.
///
///
/// @return Result<Vec<PeerID>
pub fn connected_peer_ids(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.network` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("service", lua.create_function(service)?)?;
    tbl.set("connect", lua.create_function(connect)?)?;
    tbl.set("send", lua.create_function(send)?)?;
    tbl.set("broadcast", lua.create_function(broadcast)?)?;
    tbl.set("flush", lua.create_function(flush)?)?;
    tbl.set("disconnect", lua.create_function(disconnect)?)?;
    tbl.set("disconnectNow", lua.create_function(disconnect_now)?)?;
    tbl.set("disconnectLater", lua.create_function(disconnect_later)?)?;
    tbl.set("resetPeer", lua.create_function(reset_peer)?)?;
    tbl.set("ping", lua.create_function(ping)?)?;
    tbl.set("setChannelLimit", lua.create_function(set_channel_limit)?)?;
    tbl.set("setBandwidthLimit", lua.create_function(set_bandwidth_limit)?)?;
    tbl.set("connectedPeerCount", lua.create_function(connected_peer_count)?)?;
    tbl.set("connectedPeerIds", lua.create_function(connected_peer_ids)?)?;
    luna.set("network", tbl)?;
    Ok(())
}
