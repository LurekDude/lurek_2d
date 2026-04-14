# debugbridge

## General Info

- Module group: `Edge/Integration`
- Source path: `src/debugbridge/`
- Lua API path(s): `src/lua_api/debugbridge_api.rs`
- Primary Lua namespace: `lurek.debugbridge`
- Rust test path(s): tests/rust/unit/debugbridge_tests.rs
- Lua test path(s): tests/lua/unit/test_debugbridge.lua

## Summary

The `debugbridge` module provides Lurek2D's TCP debug bridge — a JSON-over-TCP server bound to `127.0.0.1` that external tools such as the VS Code extension and MCP server can connect to for runtime inspection and game control while the engine is running.

The bridge exposes a command protocol over TCP. Each JSON message from a connected client carries a command name and parameters; the bridge dispatches it to the appropriate handler. Supported commands include: querying current log output, evaluating arbitrary Lua expressions, reading/writing `SharedState` fields, listing loaded modules, profiling frame time, and injecting synthetic input via the automation system.

Network I/O runs on a dedicate background OS thread (`server_thread`) that accepts TCP connections and sends/receives JSON. Operations that require Lua VM access (Lua eval, state reads) cannot run directly on the background thread because LuaJIT VMs are single-threaded. Instead, these are queued as `PendingRequest` entries in `BridgeShared` (protected by a `Mutex`). The main engine thread calls `bridge.poll()` once per frame to drain pending requests, execute them on the main thread, and push `PendingResponse` results back to the client channel.

`SharedBridge` is an `Arc<Mutex<BridgeShared>>` shared between the main thread and the server background thread, providing the synchronization boundary. `PrintEntry` records log messages captured for the debug bridge's log-stream endpoint.

**Scope boundary**: Edge/Integration tier. Depends on `runtime`, `lua_api` (indirectly via poll dispatch). Lua bridge not applicable (this module IS the bridge).

## Files

- `bridge.rs`: Defines the shared state records that move data between the TCP thread and the main thread. This file owns bridge-side queues, print-history tracking, and lightweight performance aggregation.
- `mod.rs`: Module root that re-exports the shared bridge types and server entry points. It provides the small public surface other modules use when they need to start or interact with the bridge.
- `server.rs`: Implements the TCP accept loop and client-message dispatch layer. It is the networking and protocol entry point for the bridge.

## Types

- `PendingRequest` (`struct`, `bridge.rs`): Queued main-thread request record containing the request id, method name, params, and source client index. It is the handoff format for operations that must run on the game thread.
- `PendingResponse` (`struct`, `bridge.rs`): Queued reply destined for a specific client. It is the final step between completed work and wire-level transmission.
- `PrintEntry` (`struct`, `bridge.rs`): Timestamped print-capture record used for tooling visibility into Lua-side print output. It exists so editor tooling can observe runtime textual output without scraping stdout.
- `BridgeShared` (`struct`, `bridge.rs`): Central shared bridge state wrapped behind Arc<Mutex<...>>. It holds pending requests, pending responses, broadcasts, print history, screenshot flags, and frame metrics, so it is the main object to inspect when the bridge appears to stall or misroute data.
- `SharedBridge` (`type`, `bridge.rs`): Type alias for the shared bridge handle used across the module and Lua bridge. It is important because the whole design assumes one synchronized shared object moving between threads.

## Functions

- `BridgeShared::new` (`bridge.rs`): Creates a new `BridgeShared` with default capacities.
- `BridgeShared::elapsed` (`bridge.rs`): Returns seconds elapsed since the bridge was created.
- `BridgeShared::get_performance` (`bridge.rs`): Returns a JSON performance summary computed from recent frame-time data.
- `BridgeShared::push_print` (`bridge.rs`): Appends a print entry to the history, evicting the oldest if the buffer is full.
- `BridgeShared::record_frame` (`bridge.rs`): Appends a delta-time sample to the frame-time ring buffer.
- `BridgeShared::set_max_print_history` (`bridge.rs`): Sets the maximum print-history capacity and trims excess entries.
- `BridgeShared::capture_print_with_broadcast` (`bridge.rs`): Appends a print entry and queues a broadcast event for all connected clients.
- `server_thread` (`server.rs`): Accept loop: runs on a background thread and handles all TCP I/O.
- `handle_client_message` (`server.rs`): Parses a newline-terminated JSON message from a client and either responds immediately (background-safe methods) or queues a [`PendingRequest`] for the main thread.

## Lua API Reference

- Binding path(s): `src/lua_api/debugbridge_api.rs`
- Namespace: `lurek.debugbridge`

### Module Functions
- `lurek.debugbridge.start`: Start the TCP debug server on 127.0.0.1:port.
- `lurek.debugbridge.stop`: Stop the TCP debug server and close all connections.
- `lurek.debugbridge.isRunning`: Returns whether the server is currently running.
- `lurek.debugbridge.getPort`: Returns the server port (0 if not running).
- `lurek.debugbridge.getClientCount`: Returns the number of connected TCP clients.
- `lurek.debugbridge.poll`: Poll for pending Lua-dependent requests from TCP clients.
- `lurek.debugbridge.capturePrint`: Captures a print message and broadcasts it to connected clients.
- `lurek.debugbridge.getPrintHistory`: Returns the print history.
- `lurek.debugbridge.clearPrintHistory`: Clears the print history.
- `lurek.debugbridge.setMaxPrintHistory`: Sets the maximum print history size.
- `lurek.debugbridge.getPerformance`: Returns performance statistics.
- `lurek.debugbridge.requestScreenshot`: Flags a screenshot request for the next frame.
- `lurek.debugbridge.isScreenshotRequested`: Returns whether a screenshot is currently requested.
- `lurek.debugbridge.broadcast`: Broadcasts a JSON event to all connected clients.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/debugbridge/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
