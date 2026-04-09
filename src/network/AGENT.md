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

## Purpose

The `network` module provides UDP networking for peer-to-peer and client-server multiplayer games via the ENet protocol. It wraps the `rusty_enet` crate behind a safe Rust API (`NetworkHost`) that the Lua binding layer consumes. A `NetworkHost` binds to a local UDP socket and acts simultaneously as server (accepting incoming connections) and client (initiating outgoing connections). All I/O is driven by a single `service()` event pump that returns typed `NetworkEvent` values (`Connect`, `Disconnect`, `Receive`). Packets are delivered over numbered channels with configurable reliability (reliable ordered or unreliable sequenced). The module enforces a hard ceiling of 8 simultaneous peers (`MAX_PEERS`) targeting small-scale multiplayer (LAN co-op, local tournaments). Constants for peer limits, channel counts, and their defaults live in `constants.rs`. Error handling uses a dedicated `NetworkError` enum with six variants covering peer limits, I/O failures, ENet internals, destroyed hosts, invalid peers, and address parsing. The Lua API is exposed under `lurek.network` with a single factory function `newHost` that accepts an options table and returns a `NetworkHost` UserData object with 22 methods. The Lua tests also verify a `lurek.net` / `enet` compatibility surface that mirrors raw ENet function signatures for LÖVE portability.

## Source Files

| File           | Purpose                                                              |
|----------------|----------------------------------------------------------------------|
| `constants.rs` | Compile-time limits and defaults: `MAX_PEERS`, `DEFAULT_PEERS`, `MAX_CHANNELS`, `DEFAULT_CHANNELS` |
| `error.rs`     | `NetworkError` enum with six variants for Lua-friendly error messages |
| `host.rs`      | `NetworkHost` wrapper around `rusty_enet::Host<UdpSocket>`, `NetworkEvent` enum, `PeerStats` struct |

## Key Types

| Type | Description |
|------|-------------|
| `NetworkError` | Principal type for the `network` module. |
| `NetworkHost` | Principal type for the `network` module. |
| `NetworkEvent` | Principal type for the `network` module. |
| `PeerStats` | Principal type for the `network` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.network.newHost()` | See `docs/specs/network.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/network.md`](../../docs/specs/network.md)

_Update both this file **and** `docs/specs/network.md` whenever source files, public types, or Lua bindings change._
