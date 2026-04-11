# `debugbridge` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | `lurek.debugbridge` |
| **Source** | `src/debugbridge/` |
| **Rust Tests** | tests/rust/unit/debugbridge_tests.rs |
| **Lua Tests** | tests/lua/unit/test_debugbridge.lua |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The debugbridge module exposes a local TCP bridge so external tools can inspect and interact with a running Lurek2D game. It exists primarily to support editor integration, remote diagnostics, eval-style tooling, and light runtime telemetry without embedding those tool protocols throughout the rest of the engine.

The module is built around a strict thread boundary. A background server thread accepts newline-delimited JSON requests from local clients, handles the background-safe methods immediately, and queues main-thread work for Lua-facing operations such as eval or stack inspection. Shared bridge state then carries pending requests, pending responses, print history, broadcast messages, and rolling performance samples between the two sides.

This module does not own the engine's scripting model, screenshot rendering, or general logging infrastructure. It transports tool requests and responses safely, but the actual work is still performed by the main thread, the Lua VM, or other engine modules.

**Scope boundary**: This module currently acts as a mostly self-contained part of the Edge/Integration layer. Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below.

---

## Architecture

```
lurek.debugbridge.* (Lua API — src/lua_api/debugbridge_api.rs)
    |
    v
src/debugbridge/mod.rs
    |- bridge.rs - bridge
    |- server.rs - server
```

---

## Source Files

| File | Purpose |
|------|---------|
| `bridge.rs` | Defines the shared state records that move data between the TCP thread and the main thread. This file owns bridge-side queues, print-history tracking, and lightweight performance aggregation. |
| `mod.rs` | Module root that re-exports the shared bridge types and server entry points. It provides the small public surface other modules use when they need to start or interact with the bridge. |
| `server.rs` | Implements the TCP accept loop and client-message dispatch layer. It is the networking and protocol entry point for the bridge. |

---

## Submodules

### `debugbridge::bridge`

Defines the shared state records that move data between the TCP thread and the main thread. This file owns bridge-side queues, print-history tracking, and lightweight performance aggregation.

- **`PendingRequest`** (struct): A request from a TCP client that requires main-thread (Lua) execution.
- **`PendingResponse`** (struct): A response produced on the main thread for delivery back to a TCP client.
- **`PrintEntry`** (struct): A single structured print log entry captured from `lurek.print`.
- **`BridgeShared`** (struct): State shared between the TCP server background thread and the Lua main thread.
- **`SharedBridge`** (type): Type alias for the shared state handle passed between threads.

### `debugbridge::server`

Implements the TCP accept loop and client-message dispatch layer. It is the networking and protocol entry point for the bridge.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `BridgeShared`

Central shared bridge state wrapped behind Arc<Mutex<...>>.

#### `SharedBridge`

Type alias for the shared bridge handle used across the module and Lua bridge.

#### `PendingRequest`

Queued main-thread request record containing the request id, method name, params, and source client index.

#### `PendingResponse`

Queued reply destined for a specific client.

#### `PrintEntry`

Timestamped print-capture record used for tooling visibility into Lua-side print output.

---

## Lua API

Exposed under `lurek.debugbridge.*` by `src/lua_api/debugbridge_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.debugbridge.start` | Start the TCP debug server on 127.0.0.1:port. |
| `lurek.debugbridge.stop` | Stop the TCP debug server and close all connections. |
| `lurek.debugbridge.isRunning` | Returns whether the server is currently running. |
| `lurek.debugbridge.getPort` | Returns the server port (0 if not running). |
| `lurek.debugbridge.getClientCount` | Returns the number of connected TCP clients. |
| `lurek.debugbridge.poll` | Poll for pending Lua-dependent requests from TCP clients. |
| `lurek.debugbridge.capturePrint` | Captures a print message and broadcasts it to connected clients. |
| `lurek.debugbridge.getPrintHistory` | Returns the print history. |
| `lurek.debugbridge.clearPrintHistory` | Clears the print history. |
| `lurek.debugbridge.setMaxPrintHistory` | Sets the maximum print history size. |
| `lurek.debugbridge.getPerformance` | Returns performance statistics. |
| `lurek.debugbridge.requestScreenshot` | Flags a screenshot request for the next frame. |
| `lurek.debugbridge.isScreenshotRequested` | Returns whether a screenshot is currently requested. |
| `lurek.debugbridge.broadcast` | Broadcasts a JSON event to all connected clients. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.debugbridge.
if lurek.debugbridge then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 0 |
| `fn` (Lua API) | 14 |
| **Total** | **18** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/debugbridge/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
