# IDEA.md — `network` module

| Field           | Value          |
| --------------- | -------------- |
| **Module**      | `network`      |
| **Path**        | `src/network/` |
| **Date**        | 2026-04-18     |
| **Plugin Tier** | TIER-1-PLUGIN  |

---

## Mission Summary

The `network` module provides Lurek2D's multiplayer networking stack: ENet reliable UDP (`host.rs`), non-blocking TCP (`tcp.rs`), async HTTP via `ureq` (`http.rs`), WebSocket via `tungstenite` (`websocket.rs`), compact MessagePack serialization (`message.rs`), LAN lobby discovery (`lobby.rs`), and a dedicated background I/O thread (`net_thread.rs`). All non-ENet transport runs on the `NetworkRuntime` background thread with `mpsc` channels, keeping the Lua VM single-threaded per constraint B-04. Exposed to Lua as `lurek.network.*`.

## Existing Strengths

- Four transport layers covering all common multiplayer patterns (UDP, TCP, HTTP, WebSocket).
- Dedicated I/O thread with clean `mpsc` bridge — Lua VM never blocks on network I/O.
- MessagePack serialization 40–70% smaller than JSON for typical game messages.
- LAN lobby via UDP broadcast — zero-config discovery for local multiplayer.
- `HostRole` metadata distinguishes server/client/host without changing ENet behaviour.
- `PeerStats` exposes RTT, packet loss, and bandwidth metrics for network debugging.
- Comprehensive error enum (`NetworkError`) covers all transport types.

## Gap List

1. **BUG FIXED**: `constants.rs` had duplicate constant definitions (`HTTP_TIMEOUT_SECS`, `TCP_BUFFER_SIZE`, `WS_BUFFER_SIZE` defined twice each) — removed duplicates.
2. **BUG FIXED**: `error.rs` had duplicate enum variants (`Http`, `WebSocket`, `Tcp`, `Serialization`, `Thread` all defined twice) and `InvalidPeer` was misplaced without its `#[error]` attribute — fixed.
3. No NAT punchthrough or relay server support.
4. No input prediction / rollback for action games.
5. No built-in room/matchmaking beyond LAN lobby.
6. No encryption for ENet packets (TLS only for HTTP/WebSocket).
7. `DEFAULT_PEERS = 166` is an unusual default (not a power of 2, not a round number).
8. `WebSocketManager::connect` does a blocking `tungstenite::connect` on the network thread — could stall other connections during DNS/TLS handshake.

## Feature Ideas

1. **NAT punchthrough** — Enable peer-to-peer connections across NATs using STUN/TURN. Requires relay server infrastructure. *Citation*: Godot's ENet integration includes NAT punchthrough helpers; Defold has a built-in relay server option.
2. **Room/matchmaking API** — `lurek.network.createRoom()` / `joinRoom()` for internet multiplayer beyond LAN. *Citation*: LÖVE2D's `lua-enet` community lib is LAN-only; Godot provides `MultiplayerAPI` with room semantics built in.
3. **Packet encryption** — Optional AES-GCM or ChaCha20 encryption for ENet UDP packets. *Citation*: Bevy's `bevy_replicon` supports encrypted channels; Godot's DTLS integration provides UDP encryption.

## Perf/Quality Ideas

- `net_thread.rs` uses `recv_timeout(10ms)` — consider adaptive timeout or `select!`-style multiplexing to reduce latency for burst traffic.
- `TcpConnectionManager::poll_all` iterates all connections linearly — could use `mio` or `polling` crate for O(1) readiness notification.
- `WebSocketManager::close` drains remaining messages synchronously — could timeout after N iterations.
- `lobby.rs` `discover_lobbies` binds to a fixed port (47777) — port conflicts with multiple instances.

## Test Coverage Gaps

- `constants.rs` has 4 tests for invariant checks.
- `error.rs` has 5 tests for Display formatting and From conversion.
- `host.rs` has 4 tests for `HostRole` and `PeerStats` (socket-dependent methods untestable in unit tests).
- `lobby.rs` has 8 tests covering wire roundtrip, missing fields, fallback host, optional fields, unknown fields, equality, and constant.
- `message.rs` has 9 tests (good coverage for pack/unpack/estimate_size).
- `http.rs` has 4 tests — **added this pass** covering `HttpResponse` struct fields, error encoding, empty body, and multiple headers.
- `tcp.rs` has 5 tests — **added this pass** covering `TcpConnectionManager::new()`, `Default`, `close_all` no-op, close-nonexistent, and send-to-nonexistent error.
- `websocket.rs` has 4 tests — **added this pass** covering `WebSocketManager::new()`, `Default`, `close_all` no-op, and send-to-nonexistent error.
- `net_thread.rs` has 9 tests — **added this pass** covering event clone/debug, `NetworkRuntime` start/shutdown/double-shutdown, poll-empty, and monotonic request IDs.
- Inline comments expanded in `tcp.rs` (DNS fallback), `lobby.rs` (poll loop), and `net_thread.rs` (main loop).

## TODO(dedup): Entries

- `TODO(dedup): thread::Channel — network::net_thread uses raw mpsc channels while the thread module provides Channel for Lua-visible inter-VM comms. Consider whether NetworkRuntime should integrate with or use the thread module's Channel type.`
- `TODO(dedup): serial::msgpack — network::message provides its own NetValue+MessagePack serialization. If serial module adds MessagePack support, consider consolidating.`

## TODO(helper): Entries

- `TODO(helper): net-sync — A content/library/ helper providing common patterns: entity state sync, client-side prediction, interpolation buffers, and lobby UI widgets.`

## TODO(plugin): Entry

- `TODO(plugin): TIER-1-PLUGIN — network pulls in heavy crates (rusty_enet, ureq, tungstenite, rmp-serde, rustls). Many games (single-player, local-only) don't need networking at all. Extracting as a Cargo feature or plugin crate would significantly reduce binary size (~2–5 MB savings). The module has no reverse dependencies — nothing in the engine imports crate::network except lua_api/network_api.rs.`

## References

- `src/lua_api/network_api.rs` — Lua binding layer
- `src/thread/` — Thread module (Channel for inter-VM comms)
- `docs/specs/network.md` — Module specification
- ENet protocol: <http://enet.bespin.org/>
- MessagePack spec: <https://msgpack.org/>
