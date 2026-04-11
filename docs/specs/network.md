# `network` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Core Runtime |
| **Status** | Implemented |
| **Lua API** | `lurek.network` |
| **Source** | `src/network/` |
| **Rust Tests** | `tests/rust/unit/network_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_network.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Core Runtime` |

---

## Summary

The network module gives Lurek2D a small ENet-backed UDP transport layer for multiplayer features. It owns host creation, peer connection lifecycle, packet send and broadcast operations, bandwidth and channel limits, and the typed event stream returned by servicing an ENet host.

This module exists so Lua gameplay code can use networking without depending directly on `rusty_enet` types or raw socket setup. The Rust side enforces Lurek2D-specific defaults such as peer caps and convenience byte-send helpers, while the Lua binding turns host operations and network events into script-friendly methods and tables.

It intentionally does not own matchmaking, replication strategy, game-state serialization, security, or NAT traversal. If the work involves packet schemas, rollback, prediction, or encrypted transport, that belongs in higher-level Lua code or another module. This module stops at transport reliability, peer management, and querying host or peer state.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Core Runtime responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.network.* (Lua API — src/lua_api/network_api.rs)
    |
    v
src/network/mod.rs
    |- constants.rs - constants
    |- error.rs - error
    |- host.rs - host
```

---

## Source Files

| File | Purpose |
|------|---------|
| `constants.rs` | Compile-time limits and defaults for the networking subsystem. |
| `error.rs` | Network-specific error types. |
| `host.rs` | ENet host wrapper for the Lurek2D networking subsystem. |
| `mod.rs` | UDP networking via ENet — reliable packet transport for multiplayer games. |

---

## Submodules

### `network::constants`

Compile-time limits and defaults for the networking subsystem.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `network::error`

Network-specific error types.

- **`NetworkError`** (enum): Errors produced by the networking subsystem.

### `network::host`

ENet host wrapper for the Lurek2D networking subsystem.

- **`NetworkHost`** (struct): Wraps a `rusty_enet::Host<UdpSocket>` with Lurek2D-specific defaults and limit enforcement.
- **`NetworkEvent`** (enum): Result of a single [`NetworkHost::service`] call.
- **`PeerStats`** (struct): Statistics snapshot for a single peer.

---

## Key Types

### Public Types

#### `NetworkError`

Errors produced by the networking subsystem.

#### `NetworkHost`

Wraps a `rusty_enet::Host<UdpSocket>` with Lurek2D-specific defaults and limit enforcement.

#### `NetworkEvent`

Result of a single [`NetworkHost::service`] call.

#### `PeerStats`

Statistics snapshot for a single peer.

---

## Lua API

Exposed under `lurek.network.*` by `src/lua_api/network_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.network.newHost` | Creates a new network host bound to the given address. |

### `NetworkHost` Methods

| Method | Description |
|--------|-------------|
| `networkhost:service(...)` | Polls the network for one event, returning an event table or nil. |
| `networkhost:flush(...)` | Flushes all pending sends immediately. |
| `networkhost:disconnect(...)` | Gracefully disconnects a peer. |
| `networkhost:disconnectNow(...)` | Immediately disconnects a peer without handshake. |
| `networkhost:resetPeer(...)` | Resets a peer connection immediately without notifying the remote side. |
| `networkhost:ping(...)` | Sends a ping to a peer to measure round-trip time. |
| `networkhost:getRoundTripTime(...)` | Returns the round-trip time estimate for a peer in milliseconds. |
| `networkhost:getPeerState(...)` | Returns the connection state of a peer as a string. |
| `networkhost:getPeerAddress(...)` | Returns the remote address of a peer, or nil if unavailable. |
| `networkhost:getAddress(...)` | Returns the local bind address as a string. |
| `networkhost:getPeerLimit(...)` | Returns the maximum number of peer slots. |
| `networkhost:getChannelLimit(...)` | Returns the maximum number of channels per connection. |
| `networkhost:setChannelLimit(...)` | Sets the channel limit for future connections. |
| `networkhost:getBandwidthLimit(...)` | Returns the bandwidth limits as a table with incoming and outgoing fields. |
| `networkhost:getConnectedPeerCount(...)` | Returns the number of currently connected peers. |
| `networkhost:getConnectedPeerIds(...)` | Returns a table of connected peer IDs. |
| `networkhost:getPeerStats(...)` | Returns a statistics table for a peer. |
| `networkhost:destroy(...)` | Destroys the host, closing the underlying socket. |
| `networkhost:isDestroyed(...)` | Returns true if the host has been destroyed. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.network.
if lurek.network then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 2 |
| `enum` | 2 |
| `fn` (Lua API) | 20 |
| **Total** | **24** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/network/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
