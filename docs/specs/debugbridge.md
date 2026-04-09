# `debugbridge` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.debugbridge`                                     |
| **Source**       | `src/debugbridge/`                                     |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_debugbridge.lua`                  |
| **Architecture** | —                                                      |

## Summary

The `debugbridge` module embeds a JSON-over-TCP server (bound to 127.0.0.1 only) inside the running Luna2D game. It serves **both audiences**: game developers debugging game logic via the VS Code extension, and engine developers inspecting engine internals via the MCP server. Neither audience requires any embed or plugin in the game script.

The server accepts newline-delimited JSON messages from multiple concurrent TCP clients. Requests fall into two categories: **background-safe** (methods the server thread handles directly using cached data) and **main-thread** (methods that require Lua execution — `eval`, `getCallStack`, `getLocals`, `getGlobals`). Main-thread methods are placed in `BridgeShared::pending_requests` and dispatched by calling `luna.debugbridge.poll()` from the game's update loop each frame. Responses queue into `BridgeShared::pending_responses` and are written back to the originating client by the server thread.

Key features:
- **`eval`** — evaluate arbitrary Lua code in-process and return the result as JSON
- **`getCallStack`** — walk the Lua debug call stack via `debug.getinfo`
- **`getLocals`** — enumerate local variables at a specific stack level via `debug.getlocal`
- **`getGlobals`** — capture up to 200 primitive global variables
- **Print capture** — game scripts call `luna.debugbridge.capturePrint` to feed a circular history buffer; the server broadcasts each entry as a `"print"` event to all clients
- **Performance sampling** — `poll()` automatically records the current frame delta from `luna.time.getDelta()` each call; `getPerformance()` returns fps, dt, avgDt, minDt, maxDt for connected external tools
- **Screenshot request** — tools set `screenshot_requested` via `requestScreenshot(scale?)`; the render loop checks `isScreenshotRequested()` and clears the flag after capture
- **Broadcast** — any game script can push a named JSON event to all connected clients with `broadcast(event, json_data)`

The server binds to 127.0.0.1 only. Ports below 1024 are rejected with a Lua error. The default port is 19740.

This module intentionally does **not** provide:
- Encrypted or authenticated connections (loopback-only, trusted development environment)
- A Lua-side coroutine or async model — `poll()` is a synchronous drain
- Persistent session storage — all state is in-memory and resets when the server stops

## Ownership Rule

`debugbridge` manages **three distinct channels** — each has a separate purpose and must not be conflated:

| Channel | Owner | Purpose |
|---|---|---|
| `luna.debugbridge.print_history` | `debugbridge` | TCP delivery feed for external tools (VS Code extension, MCP server). Push via `capturePrint()`. |
| `luna.log.*` | `log` | Engine-level operational log — routes through the Rust `log` crate to stdout/stderr. |
| `luna.devtools.logger` | `devtools` | In-game structured diagnostic history for in-game UI panels. |

These three channels are independent by design. Emitting to one does not affect the others.

For frame timing: `debugbridge.getPerformance()` reads from an internal sample buffer populated automatically by `poll()`. For basic fps/delta in game scripts, use `luna.time.getDelta()` and `luna.time.getFps()` directly (zero setup — the engine auto-ticks the clock).

## Architecture

```
src/debugbridge/
├── mod.rs        Re-exports BridgeShared, PendingRequest, PendingResponse,
│                 PrintEntry, SharedBridge, server_thread, handle_client_message
├── bridge.rs     BridgeShared — Arc<Mutex<>> shared between TCP thread and Lua
│                 PendingRequest, PendingResponse — main-thread method queue
│                 PrintEntry — timestamped print history entry
│                 SharedBridge — type alias for Arc<Mutex<BridgeShared>>
└── server.rs     server_thread(listener, shared, running) — accept loop on bg thread
                  handle_client_message(line, idx, shared) — parse + dispatch one message

src/lua_api/
└── debugbridge_api.rs  Registers luna.debugbridge.*
                        Owns: Arc<Mutex<BridgeShared>>, Arc<AtomicBool> running,
                              Arc<Mutex<Option<JoinHandle<()>>>> thread_handle

Thread model:
  Main thread (Lua):  start(), stop(), poll(), capturePrint(),
                      getPerformance(), requestScreenshot(), isScreenshotRequested(),
                      broadcast(), getPort(), getClientCount(), isRunning(),
                      getPrintHistory(), clearPrintHistory(), setMaxPrintHistory()

  Background thread:  server_thread() — TCP accept + read + write
                      Communicates only via Arc<Mutex<BridgeShared>>

Request flow:
  Client TCP → server_thread reads line → handle_client_message:
    background-safe: writes response directly to broadcast_queue or inline
    main-thread:     pushes PendingRequest to pending_requests
  Lua poll() → drains pending_requests → executes method → pushes PendingResponse
  server_thread → drains pending_responses → writes JSON to client TCP stream
```

## Source Files

| File        | Purpose                                                                                                          |
|-------------|------------------------------------------------------------------------------------------------------------------|
| `bridge.rs` | `BridgeShared`, `PendingRequest`, `PendingResponse`, `PrintEntry`, `SharedBridge` — shared state types           |
| `server.rs` | `server_thread()`, `handle_client_message()` — non-blocking TCP accept loop and message dispatch                  |
| `mod.rs`    | Re-exports all public types                                                                                       |

## Submodules

### `debugbridge::bridge`

- `PendingRequest`: `id: u64`, `method: String`, `params: serde_json::Value`, `client_idx: usize`
- `PendingResponse`: `id: u64`, `result: serde_json::Value`, `client_idx: usize`
- `PrintEntry`: `timestamp: f64`, `message: String`, `source: String`, `line: u32`
- `BridgeShared`: See Key Types below.
- `SharedBridge`: type alias `Arc<Mutex<BridgeShared>>`

### `debugbridge::server`

- `server_thread(listener, shared, running)` — blocking accept loop; sets non-blocking on the listener and polls all clients each iteration. Stops when `running` is set `false`.
- `handle_client_message(line, idx, shared)` — parses a JSON line, routes background-safe methods immediately, pushes main-thread methods to `pending_requests`.

## Key Types

### Structs

#### `debugbridge::bridge::BridgeShared`
Central shared state. Fields:
- `pending_requests: VecDeque<PendingRequest>` — main-thread method queue
- `pending_responses: VecDeque<PendingResponse>` — responses awaiting TCP delivery
- `broadcast_queue: VecDeque<String>` — JSON event strings for all clients
- `print_history: Vec<PrintEntry>` — circular print log (capacity `max_print_history`, default 2000)
- `frame_times: Vec<f64>` — recent dt samples (capacity `max_frame_times`, default 300)
- `screenshot_requested: bool` — flag set by `requestScreenshot()`
- `screenshot_scale: u32` — downscale factor for next screenshot (1–8)
- `client_count: usize` — number of currently connected TCP clients
- `port: u16` — bound port (0 if not running)
- `epoch: Instant` — start time for `elapsed()` timestamps
- `BridgeShared::new()` — default capacities, `port = 0`, `epoch = Instant::now()`
- `elapsed()→f64` — seconds since bridge creation
- `get_performance()→serde_json::Value` — `{fps, dt, avgDt, minDt, maxDt}` from frame_times
- `push_print(msg, source, line)` — appends a `PrintEntry`, evicts oldest if over capacity

#### `debugbridge::bridge::PendingRequest`
A request from a TCP client that requires main-thread Lua execution. Carries a JSON-RPC `id`, method name, raw JSON `params`, and the `client_idx` of the sender.

#### `debugbridge::bridge::PendingResponse`
A response to send back to a TCP client after main-thread execution. Carries the matching JSON-RPC `id`, the JSON `result`, and the target `client_idx`.

#### `debugbridge::bridge::PrintEntry`
One structured `luna.print` log entry. `timestamp` is seconds since bridge start. Serialisable with `serde::Serialize` for JSON broadcast.

### Enums

No public enums.

## Lua API

The Lua API is registered in `src/lua_api/debugbridge_api.rs` under `luna.debugbridge.*`. There are no UserData objects — all functions operate directly on the shared `Arc<Mutex<BridgeShared>>` state.

### Lifecycle

| Function | Signature | Description |
|---|---|---|
| `luna.debugbridge.start(port?)` | `→ boolean` | Bind to `127.0.0.1:port` and start the server thread. Default port 19740. Returns `false` if already running. Errors if `port < 1024` or bind fails. |
| `luna.debugbridge.stop()` | — | Set `running = false` and join the server thread. |
| `luna.debugbridge.isRunning()` | `→ boolean` | True when the server thread is active. |
| `luna.debugbridge.getPort()` | `→ integer` | Bound port, or 0 if not running. |
| `luna.debugbridge.getClientCount()` | `→ integer` | Number of currently connected TCP clients. |

### Main-Thread Dispatch

| Function | Signature | Description |
|---|---|---|
| `luna.debugbridge.poll()` | — | Drain `pending_requests` and execute each on the Lua main thread. Must be called each frame. Also auto-records the current frame delta from `luna.time.getDelta()` into the performance buffer — no manual `recordFrame()` call is needed. Supported methods: `eval`, `getCallStack`, `getLocals`, `getGlobals`. |

### Print Capture

| Function | Signature | Description |
|---|---|---|
| `luna.debugbridge.capturePrint(msg, source?, line?)` | — | Append a print entry and broadcast a `"print"` event to all clients. |
| `luna.debugbridge.getPrintHistory(count?)` | `→ table` | Return up to `count` most recent print entries as `{timestamp, message, source, line}` records. |
| `luna.debugbridge.clearPrintHistory()` | — | Clear the print history buffer. |
| `luna.debugbridge.setMaxPrintHistory(max)` | — | Set the print history capacity (clamped 1–100000). Truncates oldest entries immediately if needed. |

### Performance

| Function | Signature | Description |
|---|---|---|
| `luna.debugbridge.getPerformance()` | `→ table` | Returns `{fps, dt, avgDt, minDt, maxDt}` computed from frame samples that `poll()` records automatically each call. |

### Screenshots

| Function | Signature | Description |
|---|---|---|
| `luna.debugbridge.requestScreenshot(scale?)` | — | Set `screenshot_requested = true` and `screenshot_scale` (1–8, default 1). |
| `luna.debugbridge.isScreenshotRequested()` | `→ boolean` | True when a screenshot has been requested. |

### Broadcast

| Function | Signature | Description |
|---|---|---|
| `luna.debugbridge.broadcast(event, json_data)` | — | Push a named JSON event (`{event, data}`) to all connected clients. |

## Lua Examples

```lua
-- Start the bridge at game init
function luna.init()
    if luna.debugbridge.start(19740) then
        print("Debug bridge active on port", luna.debugbridge.getPort())
    end
end

-- Poll for debugger requests each frame (also auto-records frame time)
function luna.process(dt)
    luna.debugbridge.poll()
end

-- Forward print calls to connected tools
local real_print = print
print = function(...)
    local msg = table.concat({...}, "\t")
    real_print(msg)
    local info = debug.getinfo(2, "Sl")
    luna.debugbridge.capturePrint(
        msg,
        info and info.short_src or "?",
        info and info.currentline or 0
    )
end

-- Broadcast a custom game event to the VS Code extension
function on_player_died(cause)
    luna.debugbridge.broadcast("player_died", require("json").encode({ cause = cause }))
end

-- Graceful shutdown
function luna.quit()
    luna.debugbridge.stop()
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 4     |
| `enum`    | 0     |
| `fn`      | 14    |
| **Total** | **18** |

## References

| Module       | Relationship | Notes                                                              |
|--------------|--------------|--------------------------------------------------------------------|
| `engine`     | —            | `debugbridge_api.rs` receives no `SharedState`; uses only Lua context |
| `lua_api`    | Imported by  | `debugbridge_api.rs` registers the `luna.debugbridge.*` surface    |
| `vscode-extension` | Consumer | Connects to the TCP bridge for runtime inspection features        |
| `thread`     | Similar      | `luna.thread` uses `Channel` for Lua-to-Lua VM comms; `debugbridge` uses raw TCP for external tool comms |
| `graphics`   | Coordinates  | Screenshot capture requires the graphics module to export a frame |

## Notes

- `poll()` must be called from the Lua main thread (typically in `luna.process`). Forgetting `poll()` means all `eval` / inspect requests from the VS Code extension will silently queue forever. `poll()` also auto-records the current frame delta from `luna.time.getDelta()` — so `getPerformance()` will always reflect the current frame rate as long as `poll()` is called each frame.
- The bridge blocks on `running.store(false)` and then `handle.join()` during `stop()`. If the server thread is stuck on a blocking operation, `stop()` may hang briefly. This should not occur in practice because the listener is set non-blocking.
- `requestScreenshot` only sets the flag — actually capturing and delivering the screenshot is the responsibility of the engine render loop or game code that checks `isScreenshotRequested()`.
- Ports below 1024 are rejected with a `LuaError::RuntimeError`. On some systems, even ports above 1024 may require firewall adjustment; however, since the bridge binds to 127.0.0.1 only, external network access is never possible.
- `push_print` evicts from the front of the `Vec<PrintEntry>` buffer, which is O(n). For scripts that emit very high print volumes, consider reducing `max_print_history` with `setMaxPrintHistory`.
- The `getLocals` method inspects locals at a fixed stack level relative to the `poll()` call frame. The level reported to clients is offset by the call depth introduced by `poll()` itself; clients should account for this.
