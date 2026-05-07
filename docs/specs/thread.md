# thread

## General Info

- Module group: `Core Runtime`
- Source path: `src/thread/`
- Lua API path(s): `src/lua_api/thread_api.rs`
- Primary Lua namespace: `lurek.thread`
- Rust test path(s): tests/rust/unit/thread_tests.rs, plus inline unit coverage in src/thread/channel.rs, src/thread/promise.rs, src/thread/pool.rs, src/thread/worker.rs
- Lua test path(s): tests/lua/unit/test_thread.lua, tests/lua/stress/test_thread_stress.lua, tests/lua/integration/test_thread_data.lua

## Summary

The `thread` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Core Runtime group rather than absorb behavior owned by those neighbors.

## Files

- `channel.rs`: `ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions
- `mod.rs`: Module root — re-exports `channel` and `worker` submodules
- `pool.rs`: Thread pool of reusable worker Lua VMs.
- `promise.rs`: Single-result future for one-shot background computation.
- `worker.rs`: `ThreadState` enum, `LuaThread` struct, worker VM registration

## Types

- `ChannelValue` (`enum`, `channel.rs`): Serializable values that can be sent between threads.
- `Channel` (`struct`, `channel.rs`): Thread-safe MPMC channel for Lua inter-thread communication.
- `LuaChannel` (`struct`, `channel.rs`): Lua UserData wrapper for a thread-safe channel.
- `ThreadPool` (`struct`, `pool.rs`): A pool of N persistent worker threads that accept tasks from a shared input channel and send results to a shared output channel.
- `PromiseState` (`enum`, `promise.rs`): Execution state of a [`Promise`].
- `Promise` (`struct`, `promise.rs`): A one-shot async computation that produces a single `ChannelValue` result.
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
- `ThreadPool::new` (`pool.rs`): Create a pool of `size` workers, all executing `code`.
- `ThreadPool::submit` (`pool.rs`): Submit a value to the pool input channel.
- `ThreadPool::collect` (`pool.rs`): Collect a result from the pool output channel (non-blocking).
- `ThreadPool::join` (`pool.rs`): Block until all workers have finished execution.
- `ThreadPool::size` (`pool.rs`): Returns the number of workers in this pool.
- `Promise::new` (`promise.rs`): Create and immediately start a promise executing `code`.
- `Promise::is_done` (`promise.rs`): Check if the promise has a result ready, without blocking.
- `Promise::result` (`promise.rs`): Retrieve the result value if ready.
- `Promise::get_error` (`promise.rs`): Returns the error string if the worker thread failed, otherwise `None`.
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
- `lurek.thread.newChannel`: Creates a new unnamed channel for inter-thread communication.
- `lurek.thread.getChannel`: Gets or creates a named global channel shared across threads.
- `lurek.thread.newPool`: Creates a thread pool whose workers all run the same Lua code.
- `lurek.thread.async`: Starts a one-shot background computation and returns a promise.

### `LChannel` Methods
- `LChannel:type`: Returns the type name of this object.
- `LChannel:typeOf`: Returns whether this object is of the given type.
- `LChannel:push`: Pushes a value to the channel.
- `LChannel:pop`: Retrieves and removes a value from the channel.
- `LChannel:peek`: Retrieves the next value from the channel without removing it.
- `LChannel:demand`: Waits for a value or until the timeout expires, then removes and returns it.
- `LChannel:getCount`: Returns the number of items in the channel.
- `LChannel:clear`: Clears all items from the channel.
- `LChannel:supply`: Blocks until the channel has space, then adds the value.
- `LChannel:pushTable`: Serializes a Lua table and pushes it to the channel.
- `LChannel:popTable`: Pops a value from the channel expecting a table.
- `LChannel:pushBytes`: Pushes raw binary data (a Lua string treated as a byte array) to the channel.
- `LChannel:popBytes`: Pops a bytes value from the channel and returns it as a Lua string.

### `LPromise` Methods
- `LPromise:type`: Returns the type name of this object.
- `LPromise:typeOf`: Returns whether this object is of the given type.
- `LPromise:isDone`: Returns whether the promise has completed.
- `LPromise:result`: Pops and returns the promise result.
- `LPromise:getError`: Returns the worker error string if the promise failed.

### `LThread` Methods
- `LThread:type`: Returns the type name of this object.
- `LThread:typeOf`: Returns whether this object is of the given type.
- `LThread:start`: Launches the background thread, passing optional varargs.
- `LThread:wait`: Blocks the calling thread until the background thread finishes.
- `LThread:isRunning`: Returns whether the thread is currently executing.
- `LThread:getError`: Returns the error message if the thread failed.

### `LThreadPool` Methods
- `LThreadPool:type`: Returns the type name of this object.
- `LThreadPool:typeOf`: Returns whether this object is of the given type.
- `LThreadPool:submit`: Submits a value to the pool's input channel for processing by a worker.
- `LThreadPool:collect`: Retrieves the next result from the pool's output channel.
- `LThreadPool:size`: Returns the number of workers in this pool.
- `LThreadPool:join`: Blocks until all workers in the pool have finished execution.
- `LThreadPool:getInputChannel`: Returns the shared input channel.
- `LThreadPool:getOutputChannel`: Returns the shared output channel.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/thread/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
