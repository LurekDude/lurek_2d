---
name: threading
description: "Load this skill when using lurek.thread, worker VMs, Channel messaging, or Lua work across threads. Skip it for Rust thread internals or general game scripts."
---
# threading

## Mission
- Own lurek.thread usage patterns, worker VM rules, and Channel-based coordination.

## When To Load
- Use worker VMs.
- Send messages across Channels.
- Design Lua work across threads.
- Review thread lifecycle and blocking behavior.

## When To Skip
- Rust thread internals.
- General game scripting.

## Domain Knowledge
- Worker VMs are strictly isolated Lua states (binding constraint B-04). No global tables, no shared userdata handles, no shared metatables cross VM boundaries. The only valid communication path is `lurek.thread.channel` — typed MPSC/MPMC message passing. Designs that attempt shared state will silently produce wrong behavior or crash.
- Worker-safe `lurek.*` surface: rendering, input, windowing, and audio APIs are main-thread-only. A worker VM can use `lurek.math`, `lurek.data`, `lurek.fs` (read-only), `lurek.log`, and `lurek.thread.channel`. Calling a non-worker-safe API from a worker raises a runtime error.
- Channel message payloads must be serializable: booleans, numbers, strings, and flat tables of those types. No functions, no userdata, no metatables. If complex state needs to cross a worker boundary, serialize to a plain table or a JSON string first.
- Polling pattern (preferred over blocking): `local msg = chan:try_recv()` returns nil immediately if no message is available. Check it inside `on_process(dt)`. Never call `chan:recv()` (blocking) from the main thread — it stalls the frame loop.
- Worker lifecycle: `lurek.thread.spawn(script_path, init_data)` creates and starts a worker. The worker runs until its script returns or until the main thread calls `worker:terminate()`. Workers do not automatically restart on error — handle failure in the message protocol by including a status field in every reply.
- Backpressure: if a channel's send queue fills (capacity is set at creation), `chan:send(msg)` blocks or returns false depending on the channel mode. Design protocols to drain the queue or drop stale messages rather than relying on unbounded buffering.
- `src/thread/` owns: `Channel<T>` (typed MPMC), `WorkerPool`, `Promise<T>`, and worker VM spawn/join logic. Lua-facing bindings are in `src/lua_api/thread_api.rs`. Rust internal threading (e.g., audio IO thread) is separate from the Lua worker system.
- Shutdown sequencing: always terminate workers before the main VM shuts down. A worker holding an open channel to a dropped receiver panics at the Rust level. `lurek.game.on_quit` is the correct place to call `worker:terminate()` and drain any pending messages.
- Debugging thread bugs: because each VM is isolated, a failing worker does not produce a Rust stack trace on the main thread — it sends an error message through its channel or silently stops. Add explicit error-status messages to every worker protocol and log them in `on_process`.
- Do not use Rust `std::thread::spawn` directly in game scripts or library modules. Worker VMs are the only supported Lua-level concurrency model. Rust internal threads are a Lurek2D implementation detail.
## Companion File Index
- None.

## References
- src/thread/
- src/lua_api/thread_api.rs
- docs/specs/thread.md
