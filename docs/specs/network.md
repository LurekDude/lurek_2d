# `network` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extension                            |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.network`                                       |
| **Source**      | `src/network/`                                       |
| **Rust Tests** | `tests/rust/unit/network_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_network.lua`                    |
| **Architecture** | —                                                  |

## Summary

The `network` module provides UDP networking for peer-to-peer and client-server multiplayer games via the ENet protocol. It wraps the `rusty_enet` crate behind a safe Rust API (`NetworkHost`) that the Lua binding layer consumes. A `NetworkHost` binds to a local UDP socket and acts simultaneously as server (accepting incoming connections) and client (initiating outgoing connections). All I/O is driven by a single `service()` event pump that returns typed `NetworkEvent` values (`Connect`, `Disconnect`, `Receive`). Packets are delivered over numbered channels with configurable reliability (reliable ordered or unreliable sequenced). The module enforces a hard ceiling of 8 simultaneous peers (`MAX_PEERS`) targeting small-scale multiplayer (LAN co-op, local tournaments). Constants for peer limits, channel counts, and their defaults live in `constants.rs`. Error handling uses a dedicated `NetworkError` enum with six variants covering peer limits, I/O failures, ENet internals, destroyed hosts, invalid peers, and address parsing. The Lua API is exposed under `lurek.network` with a single factory function `newHost` that accepts an options table and returns a `NetworkHost` UserData object with 22 methods. The Lua tests also verify a `lurek.net` / `enet` compatibility surface that mirrors raw ENet function signatures for LÖVE portability.

**Scope boundary**: This module handles transport only — UDP packet delivery, connection lifecycle, and bandwidth control. It does not provide encryption, matchmaking, game protocol serialization, or NAT traversal. Higher-level networking logic is implemented in Lua game scripts.

## Architecture

```
lurek.network.newHost(opts)                    lurek.net.host_create(addr, peers, channels, in, out)
        │                                              │
        ▼                                              ▼
┌──────────────────── network_api.rs ──────────────────────────┐
│   LuaNetworkHost (UserData)                                  │
│     inner: RefCell<NetworkHost>                               │
│     22 methods: service, connect, send, broadcast, ...       │
│   Helpers: event_to_table(), parse_addr(), stats_to_table()  │
└──────────────────────────┬───────────────────────────────────┘
                           │ calls
                           ▼
┌──────────────────── host.rs ─────────────────────────────────┐
│   NetworkHost                                                │
│     inner: Option<Host<UdpSocket>>                           │
│     local_addr: SocketAddr                                   │
│     27 pub fn methods                                        │
│                                                              │
│   NetworkEvent (Connect | Disconnect | Receive)              │
│   PeerStats (9-field snapshot)                               │
└──────────────────────────┬───────────────────────────────────┘
                           │ wraps
                           ▼
┌──────────────────── rusty_enet ───────────────────────────────┐
│   Host<UdpSocket>   Packet   PacketKind   PeerID             │
│   HostSettings   PeerState   EventNoRef                      │
└──────────────────────────────────────────────────────────────┘

constants.rs ──► MAX_PEERS=8  DEFAULT_PEERS=4  MAX_CHANNELS=255  DEFAULT_CHANNELS=1
error.rs     ──► NetworkError (6 variants, thiserror derive)
```

## Source Files

| File           | Purpose                                                              |
|----------------|----------------------------------------------------------------------|
| `constants.rs` | Compile-time limits and defaults: `MAX_PEERS`, `DEFAULT_PEERS`, `MAX_CHANNELS`, `DEFAULT_CHANNELS` |
| `error.rs`     | `NetworkError` enum with six variants for Lua-friendly error messages |
| `host.rs`      | `NetworkHost` wrapper around `rusty_enet::Host<UdpSocket>`, `NetworkEvent` enum, `PeerStats` struct |

## Submodules

### `network::constants`

Compile-time limits and defaults for the networking subsystem.

- **`MAX_PEERS`** (const `usize = 8`): Hard ceiling on simultaneous peer connections per host.
- **`DEFAULT_PEERS`** (const `usize = 4`): Default peer count when none is specified.
- **`MAX_CHANNELS`** (const `usize = 255`): Maximum ENet channels per connection.
- **`DEFAULT_CHANNELS`** (const `usize = 1`): Default channel count for new connections.

### `network::error`

Network-specific error types using `thiserror` derive.

- **`NetworkError`** (enum): Six-variant error covering peer limits, I/O, ENet internals, destroyed hosts, invalid peers, and address parsing.

### `network::host`

ENet host wrapper providing the safe Rust API consumed by Lua bindings.

- **`NetworkHost`** (struct): Owns `Option<Host<UdpSocket>>` and local address; 27 public methods for connection management, packet I/O, and peer queries.
- **`NetworkEvent`** (enum): Result of a `service()` call — `Connect`, `Disconnect`, or `Receive`.
- **`PeerStats`** (struct): Statistics snapshot for a single peer (RTT, packet counts, bandwidth, data totals).

## Key Types

### Structs

#### `network::host::NetworkHost`

Wraps a `rusty_enet::Host<UdpSocket>` with Lurek2D-specific defaults and limit enforcement. Created once per logical network endpoint (server or client). The caller must pump `service()` every frame to process I/O. Fields: `inner: Option<Host<UdpSocket>>` (becomes `None` after `destroy()`), `local_addr: SocketAddr`. Key methods: `new()`, `service()`, `connect()`, `send()`, `send_bytes()`, `broadcast()`, `broadcast_bytes()`, `flush()`, `disconnect()`, `disconnect_now()`, `disconnect_later()`, `reset_peer()`, `ping()`, `round_trip_time()`, `peer_state()`, `peer_address()`, `local_address()`, `peer_limit()`, `channel_limit()`, `set_channel_limit()`, `bandwidth_limit()`, `set_bandwidth_limit()`, `connected_peer_count()`, `destroy()`, `is_destroyed()`, `connected_peer_ids()`, `peer_stats()`.

#### `network::host::PeerStats`

Statistics snapshot for a single peer with nine `u32` fields: `round_trip_time`, `round_trip_time_variance`, `packets_sent`, `packets_lost`, `packet_loss`, `incoming_bandwidth`, `outgoing_bandwidth`, `incoming_data_total`, `outgoing_data_total`.

### Enums

#### `network::error::NetworkError`

Errors produced by the networking subsystem. Six variants:

- `PeerLimitExceeded { requested, max }` — Requested peer count exceeds `MAX_PEERS`.
- `Io(std::io::Error)` — Socket-level I/O error.
- `Enet(String)` — ENet-internal error from `rusty_enet`.
- `HostDestroyed` — Host already destroyed; further calls invalid.
- `InvalidPeer(usize)` — Peer index out of range.
- `InvalidAddress(String)` — Failed to parse bind address string.

#### `network::host::NetworkEvent`

Result of a single `NetworkHost::service()` call. Three variants:

- `Connect { peer_id: PeerID, data: u32 }` — Remote peer completed connection handshake.
- `Disconnect { peer_id: PeerID, data: u32 }` — Remote peer disconnected.
- `Receive { peer_id: PeerID, channel_id: u8, data: Vec<u8> }` — Data packet arrived.

## Lua API

Exposed under `lurek.network.*` by `src/lua_api/network_api.rs`. The module is gated by the `modules.network` config flag. The Lua tests also verify a `lurek.net` / `enet` compatibility surface with raw ENet function signatures for LÖVE portability.

### Factory Functions (on `lurek.network` table)

| Function | Signature | Description |
|----------|-----------|-------------|
| `newHost` | `newHost(opts?)` → `NetworkHost` | Creates a new ENet host. Options table: `addr` (string, default `"0.0.0.0:0"`), `peers` (int), `channels` (int), `inBandwidth` (int), `outBandwidth` (int). |

### NetworkHost Methods (UserData)

| Method | Signature | Description |
|--------|-----------|-------------|
| `service` | `service()` → `table?` | Polls for one network event; returns event table or nil. |
| `connect` | `connect(addr, channels?, data?)` → `integer` | Initiates connection to remote host; returns peer ID. |
| `send` | `send(peer_id, channel_id, data, reliable?)` | Sends data to a peer (reliable by default). |
| `broadcast` | `broadcast(channel_id, data, reliable?)` | Broadcasts data to all connected peers. |
| `flush` | `flush()` | Flushes all pending sends immediately. |
| `disconnect` | `disconnect(peer_id, data?)` | Graceful disconnect. |
| `disconnectNow` | `disconnectNow(peer_id, data?)` | Immediate disconnect without handshake. |
| `disconnectLater` | `disconnectLater(peer_id, data?)` | Disconnect after queued packets sent. |
| `resetPeer` | `resetPeer(peer_id)` | Reset peer without notification. |
| `ping` | `ping(peer_id)` | Send ping to measure RTT. |
| `getRoundTripTime` | `getRoundTripTime(peer_id)` → `number` | RTT estimate in milliseconds. |
| `getPeerState` | `getPeerState(peer_id)` → `string` | Connection state string (e.g. `"connected"`, `"disconnected"`). |
| `getPeerAddress` | `getPeerAddress(peer_id)` → `string?` | Remote address of peer, or nil. |
| `getAddress` | `getAddress()` → `string` | Local bind address. |
| `getPeerLimit` | `getPeerLimit()` → `integer` | Maximum peer slots. |
| `getChannelLimit` | `getChannelLimit()` → `integer` | Maximum channels per connection. |
| `setChannelLimit` | `setChannelLimit(limit)` | Set channel limit for future connections. |
| `getBandwidthLimit` | `getBandwidthLimit()` → `table` | Table with `incoming` and `outgoing` fields. |
| `setBandwidthLimit` | `setBandwidthLimit(incoming?, outgoing?)` | Set bandwidth limits in bytes/sec. |
| `getConnectedPeerCount` | `getConnectedPeerCount()` → `integer` | Number of connected peers. |
| `getConnectedPeerIds` | `getConnectedPeerIds()` → `table` | Table of connected peer ID integers. |
| `getPeerStats` | `getPeerStats(peer_id)` → `table` | Statistics table for a peer. |
| `destroy` | `destroy()` | Destroys host and closes socket. |
| `isDestroyed` | `isDestroyed()` → `boolean` | Whether host has been destroyed. |

### Event Table Format

Returned by `service()`:

| Field | Type | Present In |
|-------|------|-----------|
| `type` | `string` | All events (`"connect"`, `"disconnect"`, `"receive"`) |
| `peer_id` | `integer` | All events |
| `data` | `integer` or `string` | `connect`/`disconnect`: `integer`; `receive`: binary `string` |
| `channel_id` | `integer` | `receive` only |

## Lua Examples

```lua
-- Server: host a game on port 12345 with up to 4 peers
local server

function lurek.init()
    server = lurek.network.newHost({ addr = "0.0.0.0:12345", peers = 4, channels = 2 })
end

function lurek.process(dt)
    local event = server:service()
    while event do
        if event.type == "connect" then
            print("Peer " .. event.peer_id .. " connected")
        elseif event.type == "receive" then
            print("Received from peer " .. event.peer_id .. ": " .. event.data)
            -- Echo back
            server:send(event.peer_id, 0, "ack:" .. event.data)
        elseif event.type == "disconnect" then
            print("Peer " .. event.peer_id .. " disconnected")
        end
        event = server:service()
    end
end
```

```lua
-- Client: connect to a server and send a message
local client
local peer_id

function lurek.init()
    client = lurek.network.newHost()
    peer_id = client:connect("127.0.0.1:12345", 2, 0)
end

function lurek.process(dt)
    local event = client:service()
    while event do
        if event.type == "connect" then
            client:send(peer_id, 0, "hello from client!")
        elseif event.type == "receive" then
            print("Server says: " .. event.data)
        end
        event = client:service()
    end
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 2     |
| `enum`     | 2     |
| `const`    | 4     |
| `pub fn`   | 27    |
| **Total**  | **35** |

## References

| Module     | Relationship | Notes                                            |
|------------|--------------|--------------------------------------------------|
| `engine`   | Imports from | Uses `log_messages` constants and `log_msg!` macro |
| `lua_api`  | Imported by  | `network_api.rs` binds `NetworkHost` to `lurek.network`, also exposes `lurek.net` / `enet` compat layer |
| `thread`   | Related      | Worker threads use separate Lua VMs; `NetworkHost` is not `Send` — networking runs on the main thread only |
| `data`     | Related      | Game protocols may use `lurek.data` for binary serialization alongside `lurek.network` for transport |

## Notes

- **External crate**: `rusty_enet` — a pure-Rust ENet implementation. The host is `!Send` because it wraps a `UdpSocket` bound to the calling thread. All networking must run on the main thread.
- **Peer limit**: Hard-capped at 8 (`MAX_PEERS`). This is intentional — Lurek2D targets LAN/co-op multiplayer, not MMO-scale. Requesting more than 8 peers returns `NetworkError::PeerLimitExceeded`.
- **Non-blocking I/O**: The `UdpSocket` is set to non-blocking mode immediately after bind. `service()` never blocks the game loop — it returns `None` when no events are pending.
- **Destroyed host guard**: After `destroy()` is called, every method that accesses the inner host returns `NetworkError::HostDestroyed` via the private `host()` / `host_mut()` helpers. Double-destroy is safe and idempotent.
- **Lua compatibility layer**: The Lua tests verify a `lurek.net` / `_G.enet` surface with underscore-style naming (`host_create`, `linked_version`, `get_socket_address`, etc.) for developers porting code from LÖVE's `lua-enet` binding.
- **No encryption**: Packets are plain UDP datagrams. Applications requiring security must implement encryption at the Lua level or use a VPN/tunnel.
- **Config gating**: The module is behind `modules.network` in `conf.lua`. When disabled, `lurek.network` is not registered and the `rusty_enet` host is never created.
- **Breaking change surface**: Renaming UserData methods (e.g. `service`, `send`, `broadcast`) or changing the event table field names would break all multiplayer game scripts.
