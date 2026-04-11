# debugbridge

## Module Info
- Module name: debugbridge
- Module group: Edge/Integration
- Spec path: docs/specs/debugbridge.md
- Lua API path(s): src/lua_api/debugbridge_api.rs
- Rust test path(s): tests/rust/unit/debugbridge_tests.rs
- Lua test path(s): tests/lua/unit/test_debugbridge.lua

## Module Purpose

The debugbridge module exposes a local TCP bridge so external tools can inspect and interact with a running Lurek2D game. It exists primarily to support editor integration, remote diagnostics, eval-style tooling, and light runtime telemetry without embedding those tool protocols throughout the rest of the engine.

The module is built around a strict thread boundary. A background server thread accepts newline-delimited JSON requests from local clients, handles the background-safe methods immediately, and queues main-thread work for Lua-facing operations such as eval or stack inspection. Shared bridge state then carries pending requests, pending responses, print history, broadcast messages, and rolling performance samples between the two sides.

This module does not own the engine's scripting model, screenshot rendering, or general logging infrastructure. It transports tool requests and responses safely, but the actual work is still performed by the main thread, the Lua VM, or other engine modules.

## Files
- mod.rs: Module root that re-exports the shared bridge types and server entry points. It provides the small public surface other modules use when they need to start or interact with the bridge.
- bridge.rs: Defines the shared state records that move data between the TCP thread and the main thread. This file owns bridge-side queues, print-history tracking, and lightweight performance aggregation.
- server.rs: Implements the TCP accept loop and client-message dispatch layer. It is the networking and protocol entry point for the bridge.

## Key Types
- BridgeShared: Central shared bridge state wrapped behind Arc<Mutex<...>>. It holds pending requests, pending responses, broadcasts, print history, screenshot flags, and frame metrics, so it is the main object to inspect when the bridge appears to stall or misroute data.
- SharedBridge: Type alias for the shared bridge handle used across the module and Lua bridge. It is important because the whole design assumes one synchronized shared object moving between threads.
- PendingRequest: Queued main-thread request record containing the request id, method name, params, and source client index. It is the handoff format for operations that must run on the game thread.
- PendingResponse: Queued reply destined for a specific client. It is the final step between completed work and wire-level transmission.
- PrintEntry: Timestamped print-capture record used for tooling visibility into Lua-side print output. It exists so editor tooling can observe runtime textual output without scraping stdout.