# `network` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Design-stage / Stub |
| **Lua API** | `luna.network` |
| **Source** | `src/network/` |
| **Tests** | `tests/unit/network_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_network.lua` |

## Summary

Multiplayer networking via ENet — a reliable-UDP transport library that
adds opt-in per-packet reliability, sequencing, and fragmentation over raw
UDP sockets. Two API layers are exposed: `luna.net` and `enet` provide
direct ENet C-library bindings (`ENetHost`, `ENetPeer`, raw service loop),
while `luna.network` provides a higher-level abstraction with `Server` and
`Client` convenience types. An `ENetHost` acts as both server and client
endpoint simultaneously: `host_create(address, peer_count, channels, in_bw,
out_bw)` opens a socket that can both listen and connect. `service(timeout)`
is the single event pump, returning one event at a time — "connect",
"receive" (with data and channel index), or "disconnect". Multiple
independent channels per peer enable priority separation (e.g. game state
on channel 0, chat on channel 1) without head-of-line blocking. CRC32
checksum verification and bandwidth throttling are opt-in per-host settings.
Lua string payloads are used for all data; serialisation format (MessagePack,
JSON, custom binary) is left to game scripts.

## Architecture

```
luna.network (high-level API layer)
  ├── Server / Client abstraction over ENet
  ├── Options tables for host creation
  └── Event tables returned by service()

luna.net / enet (raw ENet bindings)
  ├── ENetHost
  │     ├── host_create(bind_address, peer_count, channels, bw_in, bw_out)
  │     ├── service(timeout) → (event_type, peer, data, channel)
  │     ├── broadcast(channel, data, flags)
  │     ├── flush()
  │     └── destroy()
  ├── ENetPeer
  │     ├── send(channel, data, flags)
  │     ├── disconnect([data])
  │     ├── get_address() → { ip, port }
  │     └── get_stats() → { rtt, packets_sent, ... }
  └── Event types: "connect" | "receive" | "disconnect"

Transport: ENet reliable UDP
  ├── Per-packet reliability and sequencing optional per packet
  ├── Multiple independent channels per connection
  └── CRC32 checksum optional
```

## Lua API

Exposed under `luna.network.*` by `src/lua_api/network_api/`.

## enet — Raw ENet UDP Networking Library

> **Lua namespace:** `luna.net` (also accessible as `enet`)
> **C++ module:** `src/libraries/enet/` (vendored ENet library with Lua bindings)
> **Purpose:** Provides direct access to the ENet reliable UDP networking library. ENet adds optional per-packet reliability, sequencing, and fragmentation over raw UDP sockets. An ENetHost acts as both server and client endpoint; peers represent connected remote hosts. Supports multiple independent channels per connection for priority separation (e.g. game state and chat on separate channels).

## Reimplementation Notes

- This module exposes the **raw ENet C library** API with Lua-idiomatic bindings — it is a separate module from `luna.network`
- `luna.network` provides a higher-level API with options tables, string-based packet flags, and event tables — `luna.net` uses the traditional ENet function signatures directly
- `host_create()` binds a UDP socket; passing `"*:port"` as `bind_address` creates a server, `nil` or `"*:0"` creates a client-only host
- `host:service(timeout)` is the main event pump — returns `event_type, peer, data, channel` or nil. Must be called in a loop until nil
- Getter/setter duality: many methods act as both getter and setter — calling with no argument returns current value, calling with an argument sets a new value
- `host:connected_peers()` returns the count of currently connected peers
- `peer:get_address()` returns a structured table `{ip = "...", port = N}` instead of separate return values
- `peer:get_stats()` returns a comprehensive statistics table with RTT, packet counts, and bandwidth data
- CRC32 packet checksum can be enabled via `host:enable_checksum(true)` for packet integrity verification
- Per-host limits: `max_packet_size`, `max_waiting_data`, and `duplicate_peers` are configurable
- `host:compress_disable()` reverses any previously enabled compression (like range coder)
- `host:reset_stats()` zeroes cumulative host-level statistics counters

## Dependencies

- ENet library (vendored in `src/libraries/enet/`)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `host_create` | `bind_address?: string, peer_count?: number, channel_count?: number, in_bandwidth?: number, out_bandwidth?: number` | `ENetHost` | Create a new ENet host. `bind_address` format: `"*:port"` for server, `nil` for client-only. `peer_count` defaults to 64. `in_bandwidth`/`out_bandwidth` of 0 = unlimited |
| `linked_version` | — | `string` | Returns the linked ENet library version string |
| `time_get` | — | `number` | Returns ENet's internal clock time in milliseconds |

---

## Type: ENetHost

A network endpoint that manages connections, delivers events, and controls bandwidth.

**Created by:** `enet.host_create()`

### Event Polling

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `service` | `timeout?: number` | `event_type, peer, data, channel \| nil` | Poll for network events. Timeout in ms (0 = non-blocking). Returns nil when no events are pending. Event types: `"connect"`, `"disconnect"`, `"receive"` |

### Connection

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `connect` | `address: string, channel_count?: number, data?: number` | `ENetPeer` | Initiate a connection to `"host:port"`. Optional channel count and connect data integer |
| `broadcast` | `data: string, channel?: number, flag?: string` | — | Send a packet to all connected peers |

### Configuration

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `bandwidth_limit` | `incoming?: number, outgoing?: number` | `number` | Get or set bandwidth limits in bytes/sec. Called with no args returns current value |
| `channel_limit` | `limit?: number` | `number` | Get or set the maximum channel count for future connections |
| `max_packet_size` | `size?: number` | `number` | Get or set the maximum allowed packet size |
| `max_waiting_data` | `size?: number` | `number` | Get or set the maximum waiting data size |
| `duplicate_peers` | `count?: number` | `number` | Get or set the limit for duplicate peer connections from the same address |
| `enable_checksum` | `enable?: boolean` | `boolean` | Enable or disable CRC32 packet checksum verification |

### Compression

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `compress_with_range_coder` | — | — | Enable ENet's built-in range coder compression for all packets |
| `compress_disable` | — | — | Disable compression (reverses `compress_with_range_coder`) |

### Statistics & Query

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `get_stats` | — | `table` | Returns aggregated host statistics (total packets sent/received, bandwidth usage, etc.) |
| `reset_stats` | — | — | Resets cumulative host statistics counters to zero |
| `connected_peers` | — | `number` | Returns the number of currently connected peers |
| `received_address` | — | `string` | Returns the source address string of the last received packet |
| `get_socket_address` | — | `string` | Get the bound socket address and port |

### Lifecycle

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `flush` | — | — | Sends any queued packets immediately without waiting for the next `service()` call |
| `destroy` | — | — | Immediately destroy the host and close the socket. All peers become invalid |

---

## Type: ENetPeer

A connection to a remote host.

**Created by:** Returned by `ENetHost:connect()` or received in `service()` events.

### Communication

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `send` | `data: string, channel?: number, flag?: string` | — | Send a packet to this peer. Flags: `"reliable"`, `"unreliable"`, `"unsequenced"` |

### Disconnection

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `disconnect` | `data?: number` | — | Request graceful disconnection with optional data integer |
| `disconnect_now` | `data?: number` | — | Immediately disconnect without handshake |
| `disconnect_later` | `data?: number` | — | Disconnect after all queued packets are sent |
| `reset` | — | — | Forcefully reset the peer without notifying the remote side |

### Query

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `ping` | — | — | Send a ping to measure round-trip time |
| `get_roundtrip_time` | — | `number` | Get estimated round-trip time in milliseconds |
| `get_state` | — | `string` | Get connection state: `"disconnected"`, `"connecting"`, `"connected"`, etc. |
| `get_address` | — | `table` | Returns `{ip = "...", port = N}` |

### Data & Statistics

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `set_data` | `value: any` | — | Store arbitrary Lua data on this peer (string, number, table, boolean, or nil) |
| `get_data` | — | `any` | Retrieve previously stored Lua data |
| `get_stats` | — | `table` | Returns comprehensive per-peer statistics (RTT, packets, bandwidth) |

---

## Usage Example

### Server

```lua
local enet = require("enet")
local server = enet.host_create("*:12345", 32, 2)
server:enable_checksum(true)

function luna.update(dt)
    local event_type, peer, data, channel = server:service(0)
    while event_type do
        if event_type == "connect" then
            print("Client connected from: " .. peer:get_address().ip)
            peer:set_data({name = "unknown"})
        elseif event_type == "receive" then
            print("Received on channel " .. channel .. ": " .. data)
            peer:send("Echo: " .. data, 0, "reliable")
        elseif event_type == "disconnect" then
            print("Client disconnected")
        end
        event_type, peer, data, channel = server:service(0)
    end
end
```

### Client

```lua
local enet = require("enet")
local client = enet.host_create()  -- no bind = client only
local serverPeer = client:connect("127.0.0.1:12345")

function luna.update(dt)
    local event_type, peer, data = client:service(0)
    while event_type do
        if event_type == "connect" then
            print("Connected to server!")
            peer:send("Hello!", 0, "reliable")
        elseif event_type == "receive" then
            print("Server says: " .. data)
        end
        event_type, peer, data = client:service(0)
    end
end
```

---

## Module Boundaries

**vs luna.network** — `luna.network` provides a higher-level API with options tables, `Host`/`Peer` types with Luna2D-style method naming (camelCase), and structured event table returns. `luna.net` provides the traditional ENet C API with underscore naming (`host_create`, `get_address`, `disconnect_now`). Use `luna.network` for new code; `luna.net` when you need direct ENet control or compatibility with existing ENet-based code.

**vs luna.thread** — Run `host:service()` on a dedicated thread for non-blocking network I/O. Communicate results back to the game thread via `luna.thread.Channel`.

**vs luna.data** — Encode game state with `luna.data.pack()` before sending as string packets. Decode received data with `luna.data.unpack()`.

---

## Technical Notes

1. **ENet is bundled** in `src/libraries/enet/` — no external dependency at runtime.
2. **service() return convention**: Unlike `luna.network` which returns event tables, `luna.enet.service()` returns multiple values: `(event_type, peer, data, channel)` or `nil`.
3. **Getter/setter duality**: Methods like `bandwidth_limit()`, `channel_limit()`, `max_packet_size()`, and `duplicate_peers()` act as both getter (no args) and setter (with args).
4. **Peer lifetime**: When `host:destroy()` is called, all associated Peer objects become invalid.
5. **Packet flags**: `"reliable"` = guaranteed ordered delivery, `"unreliable"` = fire-and-forget, `"unsequenced"` = unreliable + no ordering.

## Reimplementation Notes

- This module exposes the **raw ENet C library** API with Lua-idiomatic bindings — it is a separate module from `luna.network`
- `luna.network` provides a higher-level API with options tables, string-based packet flags, and event tables — `luna.net` uses the traditional ENet function signatures directly
- `host_create()` binds a UDP socket; passing `"*:port"` as `bind_address` creates a server, `nil` or `"*:0"` creates a client-only host
- `host:service(timeout)` is the main event pump — returns `event_type, peer, data, channel` or nil. Must be called in a loop until nil
- Getter/setter duality: many methods act as both getter and setter — calling with no argument returns current value, calling with an argument sets a new value
- `host:connected_peers()` returns the count of currently connected peers
- `peer:get_address()` returns a structured table `{ip = "...", port = N}` instead of separate return values
- `peer:get_stats()` returns a comprehensive statistics table with RTT, packet counts, and bandwidth data
- CRC32 packet checksum can be enabled via `host:enable_checksum(true)` for packet integrity verification
- Per-host limits: `max_packet_size`, `max_waiting_data`, and `duplicate_peers` are configurable
- `host:compress_disable()` reverses any previously enabled compression (like range coder)
- `host:reset_stats()` zeroes cumulative host-level statistics counters

## Dependencies

- ENet library (vendored in `src/libraries/enet/`)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `host_create` | `bind_address?: string, peer_count?: number, channel_count?: number, in_bandwidth?: number, out_bandwidth?: number` | `ENetHost` | Create a new ENet host. `bind_address` format: `"*:port"` for server, `nil` for client-only. `peer_count` defaults to 64. `in_bandwidth`/`out_bandwidth` of 0 = unlimited |
| `linked_version` | — | `string` | Returns the linked ENet library version string |
| `time_get` | — | `number` | Returns ENet's internal clock time in milliseconds |

---

## Type: ENetHost

A network endpoint that manages connections, delivers events, and controls bandwidth.

**Created by:** `enet.host_create()`

### Event Polling

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `service` | `timeout?: number` | `event_type, peer, data, channel \| nil` | Poll for network events. Timeout in ms (0 = non-blocking). Returns nil when no events are pending. Event types: `"connect"`, `"disconnect"`, `"receive"` |

### Connection

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `connect` | `address: string, channel_count?: number, data?: number` | `ENetPeer` | Initiate a connection to `"host:port"`. Optional channel count and connect data integer |
| `broadcast` | `data: string, channel?: number, flag?: string` | — | Send a packet to all connected peers |

### Configuration

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `bandwidth_limit` | `incoming?: number, outgoing?: number` | `number` | Get or set bandwidth limits in bytes/sec. Called with no args returns current value |
| `channel_limit` | `limit?: number` | `number` | Get or set the maximum channel count for future connections |
| `max_packet_size` | `size?: number` | `number` | Get or set the maximum allowed packet size |
| `max_waiting_data` | `size?: number` | `number` | Get or set the maximum waiting data size |
| `duplicate_peers` | `count?: number` | `number` | Get or set the limit for duplicate peer connections from the same address |
| `enable_checksum` | `enable?: boolean` | `boolean` | Enable or disable CRC32 packet checksum verification |

### Compression

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `compress_with_range_coder` | — | — | Enable ENet's built-in range coder compression for all packets |
| `compress_disable` | — | — | Disable compression (reverses `compress_with_range_coder`) |

### Statistics & Query

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `get_stats` | — | `table` | Returns aggregated host statistics (total packets sent/received, bandwidth usage, etc.) |
| `reset_stats` | — | — | Resets cumulative host statistics counters to zero |
| `connected_peers` | — | `number` | Returns the number of currently connected peers |
| `received_address` | — | `string` | Returns the source address string of the last received packet |
| `get_socket_address` | — | `string` | Get the bound socket address and port |

### Lifecycle

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `flush` | — | — | Sends any queued packets immediately without waiting for the next `service()` call |
| `destroy` | — | — | Immediately destroy the host and close the socket. All peers become invalid |

---

## Event Polling

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `service` | `timeout?: number` | `event_type, peer, data, channel \| nil` | Poll for network events. Timeout in ms (0 = non-blocking). Returns nil when no events are pending. Event types: `"connect"`, `"disconnect"`, `"receive"` |
