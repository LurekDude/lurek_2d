# `debugbridge` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.debugbridge`                                     |
| **Source**       | `src/debugbridge/`                                     |
| **Rust Tests**   | `tests/rust/unit/debugbridge_tests.rs`                 |
| **Lua Tests**    | `tests/lua/unit/test_debugbridge.lua`                  |
| **Architecture** | —                                                      |

## Purpose

The `debugbridge` module embeds a JSON-over-TCP server (bound to 127.0.0.1 only) inside the running game. External tools — the Lurek2D VS Code extension and the MCP server — connect to the bridge to inspect global variables, evaluate Lua code, walk the call stack, capture print output, and request screenshots. All TCP I/O runs on a background Rust thread via `std::net::TcpListener`; methods that require Lua access (`eval`, `getCallStack`, `getLocals`, `getGlobals`) are queued through `BridgeShared` and dispatched each frame by calling `lurek.debugbridge.poll()` on the main thread. `poll()` also automatically records the current frame delta from `lurek.time.getDelta()` into `BridgeShared.frame_times` each call — so `getPerformance()` tracks live fps/dt without any manual `recordFrame()` call in game scripts.

## Source Files

| File        | Purpose                                                                                                         |
|-------------|-----------------------------------------------------------------------------------------------------------------|
| `bridge.rs` | `BridgeShared`, `PendingRequest`, `PendingResponse`, `PrintEntry`, `SharedBridge` — shared state exchanged between the TCP thread and the Lua main thread |
| `server.rs` | `server_thread()`, `handle_client_message()` — non-blocking TCP accept loop and client message dispatch         |
| `mod.rs`    | Re-exports all public types                                                                                     |

## Full Specification

See [`docs/specs/debugbridge.md`](../../../docs/specs/debugbridge.md) for full architecture, type details, Lua API, examples, and notes.
