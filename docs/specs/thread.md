# `thread` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Core Runtime |
| **Status** | Implemented |
| **Lua API** | `lurek.thread` |
| **Source** | `src/thread/` |
| **Rust Tests** | `tests/rust/unit/thread_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_thread.lua`, `tests/lua/stress/test_thread_stress.lua`, `tests/lua/integration/test_thread_data.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Core Runtime` |

---

## Summary

The thread module provides Lurek2D's explicit concurrency boundary. It lets scripts spawn background Lua workers and exchange simple values through thread-safe channels without sharing a Lua VM or the engine's central runtime state.

This module exists to enforce the repository's concurrency rule: Rust threads may run in parallel, but Lua state must stay isolated per VM. The module therefore centers on two primitives only: `Channel`, which moves primitive values across threads, and `LuaThread`, which owns an isolated worker VM with a tightly restricted API surface.

It intentionally does not own async runtimes, shared-memory game objects, or cross-thread access to rendering, input, physics, or audio state. If a design needs full engine APIs inside a worker, it is pushing against a deliberate boundary. The Lua wrapper in `src/lua_api/thread_api.rs` is also part of the safety story because it decides what worker threads can see and how named channels are shared.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Core Runtime responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.thread.* (Lua API — src/lua_api/thread_api.rs)
    |
    v
src/thread/mod.rs
    |- channel.rs - channel
    |- worker.rs - worker
```

---

## Source Files

| File | Purpose |
|------|---------|
| `channel.rs` | `ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions |
| `mod.rs` | Module root — re-exports `channel` and `worker` submodules |
| `worker.rs` | `ThreadState` enum, `LuaThread` struct, worker VM registration |

---

## Submodules

### `thread::channel`

`ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions

- **`ChannelValue`** (enum): Serializable values that can be sent between threads.
- **`Channel`** (struct): Thread-safe MPMC channel for Lua inter-thread communication.
- **`LuaChannel`** (struct): Lua UserData wrapper for a thread-safe channel.

### `thread::worker`

`ThreadState` enum, `LuaThread` struct, worker VM registration

- **`ThreadState`** (enum): Execution state of a background Lua thread.
- **`LuaThread`** (struct): A background Lua thread running its own VM.

---

## Key Types

### Public Types

#### `ChannelValue`

Principal type for the `thread` module.

#### `Channel`

Principal type for the `thread` module.

#### `LuaChannel`

Principal type for the `thread` module.

#### `ThreadState`

Principal type for the `thread` module.

#### `LuaThread`

Principal type for the `thread` module.

---

## Lua API

Exposed under `lurek.thread.*` by `src/lua_api/thread_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.thread.newThread` | Creates a new background thread from a Lua code string. |
| `lurek.thread.newChannel` | Creates an unnamed thread-safe channel for inter-thread communication. |
| `lurek.thread.getChannel` | Gets or creates a named global channel shared across threads. |

### `Channel` Methods

| Method | Description |
|--------|-------------|
| `channel:type(...)` | Lua-facing function documented in the binding source. |
| `channel:typeOf(...)` | Lua-facing function documented in the binding source. |
| `channel:push(...)` | Lua-facing function documented in the binding source. |
| `channel:pop(...)` | Lua-facing function documented in the binding source. |
| `channel:peek(...)` | Lua-facing function documented in the binding source. |
| `channel:demand(...)` | Lua-facing function documented in the binding source. |
| `channel:getCount(...)` | Lua-facing function documented in the binding source. |
| `channel:clear(...)` | Lua-facing function documented in the binding source. |
| `channel:supply(...)` | Lua-facing function documented in the binding source. |

### `ThreadHandle` Methods

| Method | Description |
|--------|-------------|
| `threadhandle:type(...)` | Returns the type name of this object. |
| `threadhandle:typeOf(...)` | Returns whether this object is of the given type. |
| `threadhandle:start(...)` | Launches the background thread, passing optional arguments via varargs. |
| `threadhandle:wait(...)` | Blocks the calling thread until the background thread finishes. |
| `threadhandle:isRunning(...)` | Returns whether the thread is currently executing. |
| `threadhandle:getError(...)` | Returns the error message if the thread failed, or nil. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.thread.
if lurek.thread then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 3 |
| `enum` | 2 |
| `fn` (Lua API) | 18 |
| **Total** | **23** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/thread/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
