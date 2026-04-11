# thread

## Module Info
- Module name: `thread`
- Module group: `Core Runtime`
- Spec path: `docs/specs/thread.md`
- Lua API path(s): `src/lua_api/thread_api.rs`
- Rust test path(s): `tests/rust/unit/thread_tests.rs`
- Lua test path(s): `tests/lua/unit/test_thread.lua`, `tests/lua/stress/test_thread_stress.lua`, `tests/lua/integration/test_thread_data.lua`

## Module Purpose

The thread module provides Lurek2D's explicit concurrency boundary. It lets scripts spawn background Lua workers and exchange simple values through thread-safe channels without sharing a Lua VM or the engine's central runtime state.

This module exists to enforce the repository's concurrency rule: Rust threads may run in parallel, but Lua state must stay isolated per VM. The module therefore centers on two primitives only: `Channel`, which moves primitive values across threads, and `LuaThread`, which owns an isolated worker VM with a tightly restricted API surface.

It intentionally does not own async runtimes, shared-memory game objects, or cross-thread access to rendering, input, physics, or audio state. If a design needs full engine APIs inside a worker, it is pushing against a deliberate boundary. The Lua wrapper in `src/lua_api/thread_api.rs` is also part of the safety story because it decides what worker threads can see and how named channels are shared.

## Files
- `mod.rs` is the module root and export surface. It keeps the public API small by exposing only the channel and worker submodules.
- `channel.rs` implements the MPMC queue used for inter-thread communication, the `ChannelValue` wire format, and Lua conversion helpers. This is where transfer restrictions are enforced.
- `worker.rs` implements background Lua worker lifecycle, thread state tracking, and the restricted worker-VM bootstrap. This is the file to change when thread startup or worker isolation rules change.

## Key Types
- `ChannelValue` is the only cross-thread payload format. It is intentionally limited to nil, bool, number, and string so workers cannot smuggle tables, userdata, or engine handles across VM boundaries.
- `Channel` is the core queue object shared through `Arc`. It owns buffered send and receive behavior, optional naming, blocking demand, and lightweight queue inspection.
- `LuaChannel` is the Lua-facing wrapper around `Channel`. It matters because it defines the exact scripting contract for channel push, pop, peek, demand, clear, and supply operations.
- `ThreadState` is the worker lifecycle enum used to report whether a thread is pending, running, completed, or failed with an error message. It is the control-plane state for worker supervision.
- `LuaThread` is the Rust-side worker object that stores source code, spawns the OS thread, bootstraps the isolated Lua VM, and exposes completion and error status. It is the module's main ownership boundary for background work.
- `LuaThreadHandle` in `src/lua_api/thread_api.rs` is the public scripting object for worker control. It is the important bridge between safe Rust-side thread management and the `lurek.thread` API.