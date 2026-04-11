# network

## Module Info
- Module name: `network`
- Module group: `Core Runtime`
- Spec path: `docs/specs/network.md`
- Lua API path(s): `src/lua_api/network_api.rs`
- Rust test path(s): `tests/rust/unit/network_tests.rs`
- Lua test path(s): `tests/lua/unit/test_network.lua`

## Module Purpose

The network module gives Lurek2D a small ENet-backed UDP transport layer for multiplayer features. It owns host creation, peer connection lifecycle, packet send and broadcast operations, bandwidth and channel limits, and the typed event stream returned by servicing an ENet host.

This module exists so Lua gameplay code can use networking without depending directly on `rusty_enet` types or raw socket setup. The Rust side enforces Lurek2D-specific defaults such as peer caps and convenience byte-send helpers, while the Lua binding turns host operations and network events into script-friendly methods and tables.

It intentionally does not own matchmaking, replication strategy, game-state serialization, security, or NAT traversal. If the work involves packet schemas, rollback, prediction, or encrypted transport, that belongs in higher-level Lua code or another module. This module stops at transport reliability, peer management, and querying host or peer state.

## Files
- `mod.rs` is the public module root and architectural summary. It keeps the surface limited to constants, errors, and the ENet host wrapper.
- `constants.rs` defines the compile-time peer and channel limits plus their defaults. These values encode the scale the engine expects networking to target.
- `error.rs` defines `NetworkError`, the module's transport-level failure type. Use it when the issue is host lifecycle, peer selection, bind address parsing, or ENet and socket failures.
- `host.rs` implements `NetworkHost`, `NetworkEvent`, and `PeerStats`. This is the main operational file for binding, connecting, servicing, sending, disconnecting, and querying peers.

## Key Types
- `NetworkHost` is the module's main ownership object. It wraps the ENet host, tracks whether the host has been destroyed, and exposes the transport operations the Lua API needs.
- `NetworkEvent` is the typed output of the service pump. It is the boundary between ENet's raw event stream and the engine's higher-level scripting surface.
- `PeerStats` is a snapshot object for inspection and diagnostics. It keeps runtime peer metrics separate from connection-control methods.
- `NetworkError` is the transport-specific error enum. It distinguishes invalid peer access, destroyed hosts, invalid addresses, peer-limit violations, I/O errors, and ENet failures.
- `MAX_PEERS`, `DEFAULT_PEERS`, `MAX_CHANNELS`, and `DEFAULT_CHANNELS` are small constants, but they matter because they define the practical scale and defaults the rest of the module assumes.
- `LuaNetworkHost` in `src/lua_api/network_api.rs` is the public scripting wrapper around `NetworkHost`. It is the important bridge that fixes the method names, event-table layout, and options-table contract seen by Lua game code.