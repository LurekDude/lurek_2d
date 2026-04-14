# thread

## General Info

- Module group: `Core Runtime`
- Source path: `src/thread/`
- Lua API path(s): `src/lua_api/thread_api.rs`
- Primary Lua namespace: `lurek.thread`
- Rust test path(s): tests/rust/unit/thread_tests.rs
- Lua test path(s): tests/lua/unit/test_thread.lua, tests/lua/stress/test_thread_stress.lua, tests/lua/integration/test_thread_data.lua

## Summary

The `thread` module provides Lurek2D's background threading infrastructure for game scripts, allowing CPU-intensive work to run off the main Lua VM thread. Because LuaJIT VMs cannot be shared across OS threads (design constraint B-04), each background thread runs an isolated VM with its own script load.

`Channel` is the cross-thread communication primitive: an MPSC queue backed by `Mutex<VecDeque<ChannelValue>>` plus a `Condvar` for blocking waits. `ChannelValue` is deliberately restricted to Nil, Bool, Number(f64), and String — Lua tables, UserData, and functions cannot cross thread boundaries safely. Operations: `push(v)` (non-blocking, always succeeds unless the channel is closed), `pop()` (non-blocking, returns nil if empty), `demand()` (blocking, waits until a value is available). Channels can be named and retrieved globally by name for pub-sub patterns.

`Worker` wraps an OS thread running an isolated LuaJIT VM: it loads a specified script file, then loops pulling tasks from an input `Channel`, executing the script's registered callback function with the task payload, and sending results to an output `Channel`. Workers can be paused, resumed, and terminated gracefully. Uncaught errors are captured in an error slot accessible from the main thread via `worker:get_error()`.

The `thread_pool` submodule provides a managed pool of workers for the common case of running many short tasks in parallel (e.g. `PathThreadPool` for background pathfinding).

**Scope boundary**: Core Runtime tier. Depends on `runtime`. Lua bridge in `src/lua_api/thread_api.rs`.

## Files

- `channel.rs`: `ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions
- `mod.rs`: Module root — re-exports `channel` and `worker` submodules
- `worker.rs`: `ThreadState` enum, `LuaThread` struct, worker VM registration

## Types

- `ChannelValue` (`enum`, `channel.rs`): Serializable values that can be sent between threads.
- `Channel` (`struct`, `channel.rs`): Thread-safe MPMC channel for Lua inter-thread communication.
- `LuaChannel` (`struct`, `channel.rs`): Lua UserData wrapper for a thread-safe channel.
- `ThreadState` (`enum`, `worker.rs`): Execution state of a background Lua thread.
- `LuaThread` (`struct`, `worker.rs`): A background Lua thread running its own VM.

## Functions

- `Channel::new` (`channel.rs`): Create an unnamed channel.
- `Channel::named` (`channel.rs`): Creates a named bidirectional channel pair, binding the channel name in the global registry.
- `Channel::push` (`channel.rs`): Push a value to the back of the channel.
- `Channel::pop` (`channel.rs`): Pop a value from the front of the channel (non-blocking).
- `Channel::peek` (`channel.rs`): Peek at the front value without removing it.
- `Channel::demand` (`channel.rs`): Wait for a value, blocking the calling thread.
- `Channel::get_count` (`channel.rs`): Get the number of values currently in the channel.
- `Channel::clear` (`channel.rs`): Remove all values from the channel.
- `Channel::supply` (`channel.rs`): Push a value only if the channel is currently empty.
- `Channel::name` (`channel.rs`): Get the channel name, if it is a named channel.
- `lua_to_channel_value` (`channel.rs`): Convert a Lua value into a `ChannelValue` for cross-thread transfer.
- `channel_value_to_lua` (`channel.rs`): Convert a `ChannelValue` back into a Lua value.
- `LuaThread::new` (`worker.rs`): Create a new thread that will execute the given Lua code.
- `LuaThread::start` (`worker.rs`): Start the thread, spawning a new OS thread with its own Lua VM.
- `LuaThread::wait` (`worker.rs`): Block until the thread finishes execution.
- `LuaThread::is_running` (`worker.rs`): Check whether the thread is currently running.
- `LuaThread::get_error` (`worker.rs`): Get the error message if the thread terminated with an error.

## Lua API Reference

- Binding path(s): `src/lua_api/thread_api.rs`
- Namespace: `lurek.thread`

### Module Functions
- `lurek.thread.newThread`: Creates a new background thread from a Lua code string.
- `lurek.thread.newChannel`: Creates an unnamed thread-safe channel for inter-thread communication.
- `lurek.thread.getChannel`: Gets or creates a named global channel shared across threads.

### `Channel` Methods
- `Channel:type`: Returns the type of the object.
- `Channel:typeOf`: Checks if the object is of the specified type.
- `Channel:push`: Pushes a value to the channel.
- `Channel:pop`: Retrieves and removes a value from the channel.
- `Channel:peek`: Retrieves the value from the channel without removing it.
- `Channel:demand`: Blocks until a value is available or the timeout expires, then removes and returns it.
- `Channel:getCount`: Returns the number of items in the channel.
- `Channel:clear`: Clears all items from the channel.
- `Channel:supply`: Blocks until the channel has space, then adds the value.

### `ThreadHandle` Methods
- `ThreadHandle:type`: Returns the type name of this object.
- `ThreadHandle:typeOf`: Returns whether this object is of the given type.
- `ThreadHandle:start`: Launches the background thread, passing optional arguments via varargs.
- `ThreadHandle:wait`: Blocks the calling thread until the background thread finishes.
- `ThreadHandle:isRunning`: Returns whether the thread is currently executing.
- `ThreadHandle:getError`: Returns the error message if the thread failed, or nil.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/thread/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
