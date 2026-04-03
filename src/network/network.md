# network — UDP Networking Module (ENet)

> **Lua namespace:** `luna.network`
> **C++ module:** `src/modules/network/`
> **Purpose:** Provides reliable and unreliable UDP networking via ENet for multiplayer game communication. Supports client-server and peer-to-peer architectures with connection management, packet delivery modes, bandwidth limits, and per-peer statistics.

## Reimplementation Notes

- Built on top of **ENet** (http://enet.besra.com/) — a thin reliable UDP library
- Two types: `Host` (network endpoint) and `Peer` (remote connection)
- Event-driven: call `host:service()` repeatedly to receive events
- Three packet delivery modes: `"reliable"` (TCP-like ordered), `"unreliable"` (UDP fire-and-forget), `"unsequenced"` (unreliable + no ordering)
- Channels provide independent ordered streams (default 1 channel)
- A Host with `port=0` or no port is client-only (cannot accept incoming connections)
- A Host with `port>0` binds to `*:port` and can accept connections
- Peer states follow the ENet state machine: disconnected → connecting → connected → disconnecting
- `host:service()` returns one event at a time — must call repeatedly until nil
- Data is sent/received as raw Lua strings (binary-safe)
- `peer:setData()`/`getData()` stores arbitrary per-peer Lua values (via Lua registry)
- `host:destroy()` immediately tears down the socket

## Dependencies

- ENet library (vendored or linked)
- No other module dependencies

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newHost` | `opts?: table` | `Host` | Create a network host |

### newHost Options Table

| Field | Type | Default | Description |
|---|---|---|---|
| `port` | `int` | `0` | Port to bind. 0 = client-only (no incoming connections) |
| `maxPeers` | `int` | `64` | Maximum number of simultaneous peer connections |
| `channels` | `int` | `1` | Number of independent packet channels |
| `inBandwidth` | `int` | `0` | Incoming bandwidth limit in bytes/sec (0 = unlimited) |
| `outBandwidth` | `int` | `0` | Outgoing bandwidth limit in bytes/sec (0 = unlimited) |

---

## Type: Host

A network endpoint that manages connections and delivers events.

**Created by:** `luna.network.newHost(opts?)`

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `service` | `timeout?: int` | `event \| nil` | Poll for events. Timeout in milliseconds (0 = non-blocking). Returns an event table or nil |
| `connect` | `address, port, data?` | `Peer` | Initiate a connection to a remote host. `data` is an optional integer sent with the connect event |
| `broadcast` | `data, channel?, flag?` | — | Send a packet to all connected peers |
| `getPeers` | — | `table<Peer>` | Get all connected peers |
| `getPeerCount` | — | `int` | Get number of allocated peer slots |
| `setBandwidthLimit` | `inBps, outBps` | — | Set bandwidth limits (bytes per second). 0 = unlimited |
| `getStats` | — | `table` | Get host statistics |
| `getAddress` | — | `address, port` | Get the bound IP address and port |
| `destroy` | — | — | Immediately destroy the host and close the socket |

### service() Event Table

The event table returned by `service()` contains:

| Field | Type | Description |
|---|---|---|
| `type` | `string` | Event type: `"connect"`, `"disconnect"`, `"receive"` |
| `peer` | `Peer` | The peer associated with this event |
| `data` | `string \| int` | For `"receive"`: the packet data (string). For `"connect"`/`"disconnect"`: an integer data value |
| `channel` | `int` | Channel the packet was received on (for `"receive"`) |

### Packet Flags

| Flag | Description |
|---|---|
| `"reliable"` | Guaranteed delivery in order (default). Like TCP |
| `"unreliable"` | No delivery guarantee, no ordering |
| `"unsequenced"` | No delivery guarantee, no ordering enforcement |

---

## Type: Peer

A connection to a remote host.

**Created by:** Returned by `Host:connect()` or received in `service()` events.

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `send` | `data, channel?, flag?` | `boolean` | Send a packet. Returns true on success |
| `disconnect` | `data?: int` | — | Request graceful disconnection. Optional data integer sent with disconnect event |
| `disconnectNow` | `data?: int` | — | Immediately disconnect without handshake |
| `disconnectLater` | `data?: int` | — | Disconnect after all queued packets are sent |
| `reset` | — | — | Forcefully reset the peer without notifying the remote side |
| `ping` | — | — | Send a ping to measure round-trip time |
| `getRoundTripTime` | — | `int` | Get current estimated RTT in milliseconds |
| `getState` | — | `string` | Get connection state string |
| `getAddress` | — | `address, port` | Get the peer's IP address and port |
| `setData` | `value: any` | — | Store arbitrary per-peer Lua data |
| `getData` | — | `any` | Retrieve stored per-peer data |

### Peer States

| State | Description |
|---|---|
| `"disconnected"` | Not connected |
| `"connecting"` | Connection handshake in progress |
| `"acknowledging_connect"` | Server acknowledging connection |
| `"connection_pending"` | Connection pending |
| `"connection_succeeded"` | Connection succeeded, waiting for ack |
| `"connected"` | Fully connected |
| `"disconnect_later"` | Disconnecting after pending packets |
| `"disconnecting"` | Disconnection handshake in progress |
| `"acknowledging_disconnect"` | Acknowledging disconnection |
| `"zombie"` | Connection timed out |

---

## Usage Example

### Server

```lua
local server = luna.network.newHost({port = 12345, maxPeers = 32})

function luna.update(dt)
    local event = server:service(0)
    while event do
        if event.type == "connect" then
            print("Client connected: " .. event.peer:getAddress())
            event.peer:setData({name = "unknown"})
        elseif event.type == "receive" then
            print("Received: " .. event.data)
            -- Echo back
            event.peer:send("Echo: " .. event.data)
        elseif event.type == "disconnect" then
            print("Client disconnected")
        end
        event = server:service(0)
    end
end
```

### Client

```lua
local client = luna.network.newHost()  -- port=0 → client only
local serverPeer = client:connect("127.0.0.1", 12345)

function luna.update(dt)
    local event = client:service(0)
    while event do
        if event.type == "connect" then
            serverPeer:send("Hello server!")
        elseif event.type == "receive" then
            print("Server says: " .. event.data)
        end
        event = client:service(0)
    end
end
```

---

## Game Design Role

- **LAN party**: Connect players on the same network for co-op or competitive play without internet.
- **Online multiplayer**: Client-server architecture with authoritative server and reliable state sync.
- **Dedicated servers**: Headless host with `maxPeers` matching player count; no rendering needed.
- **Splitscreen + rollback**: Local input with network rollback for fighting games or co-op platformers.
- **Game jam prototyping**: Quick peer-to-peer networking for multiplayer prototypes — minimal setup.

---

## Module Boundaries

**vs luna.thread** — Thread provides Lua worker threads with Channels. Network provides UDP sockets. Run `host:service()` on a dedicated thread for non-blocking I/O, communicate results back via Channel.

**vs luna.event** — Event delivers OS-level input events. Network events (`connect`, `disconnect`, `receive`) come from `host:service()` polling — they are not pushed to `luna.event`. Game code bridges them manually.

**vs luna.data** — Data provides serialisation primitives (compress, pack, hash). Encode game state with `luna.data.pack()` before sending as a string packet via `peer:send()`.

**vs luna.filesystem** — Filesystem provides file I/O. For file transfer over the network, read the file with `luna.filesystem.read()`, then send the contents as reliable packets.

---

## Technical Notes

1. **ENet is bundled** in `src/libraries/` — no external dependency needed at runtime.
2. **`service()` timeout semantics**: timeout of 0 = non-blocking poll. Positive timeout = block up to that many milliseconds waiting for an event. Always call service in a loop until it returns `nil`.
3. **Reliable ≠ TCP**: ENet's reliable packets are sequenced and acknowledged but still use UDP underneath. Latency characteristics differ from TCP — no Nagle delay, no head-of-line blocking cross-channel.
4. **Peer lifetime tied to Host**: When `host:destroy()` is called, all Peer objects become invalid. Do not access Peers after destroying their Host.
5. **255 max channels**: ENet supports up to 255 independent channels per connection. Each channel maintains its own sequence counter.
6. **`host:destroy()` disconnects all**: Destroying a host does NOT send graceful disconnect messages. Call `peer:disconnect()` on each peer first if you need clean shutdown.

---

## Recipes & Workflows

- **LAN discovery**: Broadcast a "discovery" packet on a known port. Listening hosts reply with their game info. Client collects responses for a server browser.
- **Client-server chat**: Server receives `"receive"` events, prefixes sender name, broadcasts to all peers.
- **Authoritative game server**: Server owns game state. Clients send input packets (reliable). Server simulates, broadcasts state snapshots (unreliable) at a fixed tick rate.

---

## Edge Cases & Pitfalls

- **Service frequency**: `host:service()` must be called frequently (every frame or faster). Long gaps cause event queue buildup and timeout disconnects.
- **Send before connect**: Calling `peer:send()` before the `"connect"` event fires silently queues the packet. It will be sent once the handshake completes — but may surprise you if the connection fails.
- **Broadcast includes all peers**: `host:broadcast()` sends to ALL connected peers, including ones you may not intend (e.g. spectators). Filter recipients manually with `peer:send()` if needed.
- **Firewall / NAT**: UDP packets are blocked by many corporate firewalls. Home NAT requires port forwarding or a relay server. ENet does not include NAT traversal.
- **iOS / Android background**: Mobile platforms may kill UDP sockets when the app is backgrounded. Handle reconnection logic in your game code.

---

## Planned / To Implement

- **Auto channel negotiation**: Automatically assign channel IDs based on message type registration.
- **Message framing**: Higher-level message protocol with type IDs, serialisation, and dispatch to handler functions.
- **Ping utility**: Built-in ping/latency display helper for HUD integration.
- **Connection timeout**: Configurable timeout for detecting stale peers (currently uses ENet defaults).
- **Lockstep example**: Reference implementation for deterministic lockstep multiplayer.
- **Snapshot interpolation**: Reference implementation for entity interpolation between server snapshots.
