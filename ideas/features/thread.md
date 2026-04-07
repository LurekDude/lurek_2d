# thread — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/thread.md`
**Files**: Isolated Lua VMs in OS threads + MPMC channels

## Purpose

Multi-threading with isolated Lua VMs: spawn worker threads with separate LuaJIT instances, communicate via typed MPMC channels. No shared mutable state.

## Current Feature Summary

- `luna.thread.new(code)`: spawn isolated Lua VM in OS thread
- Channel: MPMC with `push/pop/peek/demand/supply`
- 4 channel value types: Nil, Bool, Number, String (no tables!)
- `ThreadState` enum: Running, Finished, Error
- Worker VMs get minimal API (no graphics, audio, window)
- `defer_channels`: run channel processing on main thread after frame
- `call_in_main`: schedule function call on main thread from worker
- Thread error propagation via `getError()`

## Feature Gaps

1. **No table serialization across threads**: Only 4 primitive types can be sent through channels. Sending structured data requires manual JSON serialization. This is the #1 friction point.
2. **No thread pool**: Each `thread.new()` creates a new OS thread. For batch tasks (process 100 items), a thread pool would be more efficient.
3. **No Promise/Future pattern**: No way to spawn work and `await` the result. Must manually set up channels for request/response.
4. **No worker filesystem access**: Workers can't even read files. Must load data on main thread, serialize through channel, process in worker, send results back. Very cumbersome.
5. **No shared read-only data**: No mechanism for workers to read immutable data without copying through channels.
6. **No worker module system**: Can't `require` modules in workers. All code must be inlined in the thread creation call.
7. **No channel timeout**: `demand()` blocks forever. No `tryDemand(timeout)`.

## Structural Issues

- **Message type limitation is severe**: Only Nil/Bool/Number/String means any structured data must be JSON-encoded (string), which defeats much of the performance benefit of threading.
- **No integration with other modules**: Workers can't use filesystem, data, compute, or serial modules. Very limiting for background processing.
- **Clean isolation model**: The no-shared-state model is correct for LuaJIT. The limitation is in the channel value types, not the architecture.

## Suggestions

1. **Add table serialization**: `channel:pushTable(t)` — serialize Lua table to bytes internally, reconstruct on the other side. Even if limited to primitive-valued tables, this eliminates JSON round-trips.
2. **Add thread pool**: `luna.thread.newPool(workerCount, code)` — reusable worker pool. `pool:submit(data)` / `pool:collect()`.
3. **Add Promise/Future**: `local result = luna.thread.async(fn, args)` — returns a future that resolves in the next frame. Sugar over channel patterns.
4. **Allow filesystem access in workers**: Workers should be able to read files (read-only) for background loading tasks. This is the most common use case for game threading.
5. **Add channel timeout**: `channel:demand(timeout)` — blocks for at most N seconds. Returns nil on timeout.
6. **Add ByteData channel type**: Allow sending `data.ByteData` through channels as a 5th type — enables efficient binary data exchange.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Thread model | Isolated VMs | ✅ (Threads) | ❌ (coroutines) | ✅ (Rayon) |
| Channels | ✅ (4 types) | ✅ (any type) | N/A | ✅ (any type) |
| Thread pool | ❌ | ❌ | N/A | ✅ (built-in) |
| Shared data | ❌ | ❌ | N/A | ✅ (Resources) |
| Worker FS | ❌ | ✅ | N/A | ✅ |
| Worker modules | ❌ | ✅ (require) | N/A | ✅ |

## Priority

**MEDIUM-HIGH** — Table serialization through channels is critical for practical threaded game scripts. Thread pool and filesystem access in workers would make threading actually useful for background loading.
