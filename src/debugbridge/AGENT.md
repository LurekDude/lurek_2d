# `debugbridge` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.debugbridge`                                     |
| **Source**       | `src/debugbridge/`                                     |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_debugbridge.lua`                  |
| **Architecture** | —                                                      |

## Purpose

The `debugbridge` module embeds a JSON-over-TCP server (bound to 127.0.0.1 only) inside the running game. External tools — the Luna2D VS Code extension and the MCP server — connect to the bridge to inspect global variables, evaluate Lua code, walk the call stack, capture print output, and request screenshots. All TCP I/O runs on a background Rust thread via `std::net::TcpListener`; methods that require Lua access (`eval`, `getCallStack`, `getLocals`, `getGlobals`) are queued through `BridgeShared` and dispatched each frame by calling `luna.debugbridge.poll()` on the main thread. `poll()` also automatically records the current frame delta from `luna.time.getDelta()` into `BridgeShared.frame_times` each call — so `getPerformance()` tracks live fps/dt without any manual `recordFrame()` call in game scripts.

## Ownership Rule

`debugbridge` manages **three distinct channels** — each has a separate purpose and must not be conflated:

| Channel | Owner | Purpose |
|---|---|---|
| `luna.debugbridge.print_history` | `debugbridge` | TCP delivery feed for external tools (VS Code extension, MCP server). Push via `capturePrint()`. |
| `luna.log.*` | `log` | Engine-level operational log — routes through the Rust `log` crate to stdout/stderr. |
| `luna.devtools.logger` | `devtools` | In-game structured diagnostic history for in-game UI panels. |

These three channels are independent by design. Emitting to one does not affect the others. For frame timing: `getPerformance()` reads from `poll()`'s internal sample buffer; for basic fps/delta in game scripts use `luna.time.getDelta()` and `luna.time.getFps()` directly.

## Source Files

| File        | Purpose                                                                                                         |
|-------------|-----------------------------------------------------------------------------------------------------------------|
| `bridge.rs` | `BridgeShared`, `PendingRequest`, `PendingResponse`, `PrintEntry`, `SharedBridge` — shared state exchanged between the TCP thread and the Lua main thread |
| `server.rs` | `server_thread()`, `handle_client_message()` — non-blocking TCP accept loop and client message dispatch         |
| `mod.rs`    | Re-exports all public types                                                                                     |

## Full Specification

See [`specs/debugbridge.md`](../../../specs/debugbridge.md) for full architecture, type details, Lua API, examples, and notes.
