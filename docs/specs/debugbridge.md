# debugbridge

## General Info

- Module group: `Edge/Integration`
- Source path: `src/debugbridge/`
- Lua API path(s): `src/lua_api/debugbridge_api.rs`
- Primary Lua namespace: `lurek.debugbridge`
- Rust test path(s): tests/rust/unit/debugbridge_tests.rs
- Lua test path(s): tests/lua/unit/test_debugbridge.lua

## Summary

The `debugbridge` module provides Lurek2D's TCP debug bridge — a JSON-over-TCP server bound to `127.0.0.1` that external tools (the VS Code extension, the MCP server, and any compatible debugger client) can connect to for runtime inspection and game control while the engine is running. It is an Edge/Integration tier module.

**Protocol model.** The bridge exposes a command protocol over persistent TCP connections. Each JSON message from a connected client carries a command name and typed parameters. The bridge dispatches to the appropriate handler and sends a JSON reply. Supported commands include: querying current log output (`log`), evaluating arbitrary Lua expressions in the running VM (`eval`), reading/writing engine state fields, listing loaded modules, querying frame performance metrics, taking screenshots, and injecting synthetic input via the automation system. All messages are newline-delimited JSON so they are easy to consume from any language.

Protocol access now includes a lightweight handshake: clients call `ping` to receive a nonce and protocol metadata, then call `hello` with the nonce and matching protocol version. Non-`ping` methods require the valid nonce in `params.nonce`.

**Threading design.** TCP I/O runs on a dedicated background OS thread (`server_thread`) that runs the accept loop and handles all socket reads/writes. This thread cannot call into the Lua VM or touch `SharedState` directly — LuaJIT VMs are single-threaded and not safe to call from any thread other than the one that created them. The bridge resolves this constraint via a two-queue design: operations requiring VM access are serialised as `PendingRequest` entries in `BridgeShared` (guarded by a `Mutex`). The main engine thread calls `bridge.poll()` once per frame to drain the pending-request queue, execute each request on the main thread, and push the resulting `PendingResponse` entries back through the client channel for the background thread to transmit.

**`BridgeShared` — the synchronisation boundary.** `BridgeShared` is the central shared record behind an `Arc<Mutex<BridgeShared>>` alias `SharedBridge`. It holds:
- The pending-request queue (background → main thread).
- The pending-response queue (main thread → background).
- Broadcast queues for log events and game state changes to all connected clients.
- A ring buffer of `PrintEntry` records capturing Lua `print()` output for tooling visibility.
- A ring buffer of frame delta-time samples for the performance endpoint.
- Screenshot request/response flags.

`BridgeShared::push_print(entry)` adds a log record and trims history to `max_print_history` in O(1) using `VecDeque`. `BridgeShared::record_frame(dt)` appends to the frame-time ring buffer with O(1) eviction and incrementally maintained performance aggregates. `BridgeShared::get_performance()` serialises cached stats to JSON (fps, min, max, avg frame time) without rescanning the full history every call.

**`PrintEntry`.** Timestamped print-capture record. Lua-side `print()` calls are intercepted and routed through `capture_print_with_broadcast`, which both records the entry and queues a broadcast event so all connected debug clients see live log output without polling.

**Server thread.** `server_thread` runs the TCP accept loop. Per-client goroutine-equivalent logic handles partial reads and newline framing. `handle_client_message` parses each complete JSON message: background-safe methods (connection status, port query, performance snapshot) respond immediately without queuing; VM-access methods (Lua eval, state reads, screenshot request) enqueue a `PendingRequest` and block the client reader until the main thread fulfils it via `poll()`.

**Lua surface.** `lurek.debugbridge.start(port)` binds the server. `stop()` disconnects all clients and shuts the thread. `isRunning()` / `getPort()` / `getClientCount()` expose status. The bridge's own Lua surface is intentionally minimal — the rich capability is on the external-tooling side of the TCP connection, not in Lua game code.

**Scope boundary.** Edge/Integration tier. Depends on `runtime` (shared state access) and `lua_api` indirectly via poll dispatch. Lua bridge in `src/lua_api/debugbridge_api.rs` (Lua scripts start/stop the server; the bridge protocol itself operates outside the Lua VM).

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
- `lurek.debugbridge.getProtocolInfo`: Returns bridge protocol metadata (version, capabilities, nonce).
- `lurek.debugbridge.consumeHotReloadRequest`: Consumes and clears a pending remote hot-reload request.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/debugbridge/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
