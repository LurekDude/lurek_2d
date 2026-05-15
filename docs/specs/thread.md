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
- `OverflowPolicy` (`enum`, `channel.rs`): Policy applied when a bounded `Channel` is full and `push` is called.
- `Channel` (`struct`, `channel.rs`): Thread-safe MPMC channel for Lua inter-thread communication.
- `LuaChannel` (`struct`, `channel.rs`): Lua UserData wrapper for a thread-safe channel.
- `ThreadPool` (`struct`, `pool.rs`): A pool of N persistent worker threads that accept tasks from a shared input channel and send results to a shared output channel.
- `PromiseState` (`enum`, `promise.rs`): Execution state of a [`Promise`].
- `Promise` (`struct`, `promise.rs`): A one-shot async computation that produces a single `ChannelValue` result.
- `ThreadState` (`enum`, `worker.rs`): Execution state of a background Lua thread.
- `LuaThread` (`struct`, `worker.rs`): A background Lua thread running its own VM.

## Functions

- `Channel::new` (`channel.rs`): Create an unbounded, unnamed channel.
- `Channel::bounded` (`channel.rs`): Create a bounded, unnamed channel with a capacity of at least 1.
- `Channel::named` (`channel.rs`): Create an unbounded channel with a diagnostic `name`.
- `Channel::named_bounded` (`channel.rs`): Create a bounded channel with a diagnostic `name` and capacity of at least 1.
- `Channel::push` (`channel.rs`): Push `value` onto the queue, blocking when the channel is full; return the 1-based push sequence ID.
- `Channel::try_push` (`channel.rs`): Push `value` without blocking; return `false` immediately when the channel is full.
- `Channel::pop` (`channel.rs`): Remove and return the front value without blocking; return `None` when the queue is empty.
- `Channel::peek` (`channel.rs`): Return a clone of the front value without removing it; return `None` when the queue is empty.
- `Channel::demand` (`channel.rs`): Block until a value is available or `timeout` seconds elapse; return `None` on timeout.
- `Channel::get_count` (`channel.rs`): Return the number of values currently in the queue.
- `Channel::clear` (`channel.rs`): Drain the queue and wake all blocked senders.
- `Channel::supply` (`channel.rs`): Push `value` only when the queue is empty and has capacity; return `true` when pushed.
- `Channel::name` (`channel.rs`): Return the channel's diagnostic name, or `None` for anonymous channels.
- `Channel::capacity` (`channel.rs`): Return the capacity limit, or `None` for unbounded channels.
- `Channel::is_bounded` (`channel.rs`): Return `true` when the channel was created with a capacity limit.
- `lua_to_channel_value` (`channel.rs`): Convert a Lua value into a `ChannelValue` for cross-thread transfer.
- `channel_value_to_lua` (`channel.rs`): Convert a `ChannelValue` back into a Lua value.
- `ThreadPool::new` (`pool.rs`): Create a pool of `size` workers, each executing `code`, wired to shared input/output channels.
- `ThreadPool::submit` (`pool.rs`): Push `value` onto the input channel for the next available worker.
- `ThreadPool::collect` (`pool.rs`): Non-blocking pop from the output channel; return `None` when no result is ready.
- `ThreadPool::join` (`pool.rs`): Block until all workers finish their current work items.
- `ThreadPool::join_with_timeout` (`pool.rs`): Block until all workers finish or `timeout_secs` elapses; return `false` if any worker did not finish in time.
- `ThreadPool::size` (`pool.rs`): Return the pool size (number of worker threads).
- `Promise::new` (`promise.rs`): Spawn a `LuaThread` running `code` with `args` and return a pending `Promise`.
- `Promise::is_done` (`promise.rs`): Poll whether the worker has finished; update `state` to `Done` or `Error` and return `true` when complete.
- `Promise::result` (`promise.rs`): Pop and return the result value; returns `None` when not yet done.
- `Promise::get_error` (`promise.rs`): Return the worker's error message if it terminated with an error, or `None`.
- `LuaThread::new` (`worker.rs`): Create a `LuaThread` ready to run `code` with access to `channels`; does not start the OS thread.
- `LuaThread::start` (`worker.rs`): Spawn the OS thread, inject `args` into the `arg` global, and begin executing `code`; returns an error when already running.
- `LuaThread::wait` (`worker.rs`): Block the calling thread until the worker finishes; no-op when no handle is present.
- `LuaThread::wait_timeout` (`worker.rs`): Poll every millisecond until the worker finishes or `timeout_secs` elapses; return `true` when finished in time.
- `LuaThread::is_running` (`worker.rs`): Return `true` while the worker OS thread state is `Running`.
- `LuaThread::get_error` (`worker.rs`): Return the error message when the worker terminated with `ThreadState::Error`, or `None`.
- `worker_capabilities` (`worker.rs`): Return the `lurek.*` capabilities available inside worker VMs.

## Lua API Reference

- Binding path(s): `src/lua_api/thread_api.rs`
- Namespace: `lurek.thread`

### Module Functions
- `lurek.thread.newThread`: Creates a new worker thread that will execute the given Lua code string when started.
- `lurek.thread.newChannel`: Creates a new unbounded channel for sending typed values between threads.
- `lurek.thread.newBoundedChannel`: Creates a new bounded channel with a fixed capacity, blocking pushes when full.
- `lurek.thread.getChannel`: Returns a named shared channel, creating it on first access. Repeated calls with the same name return the same channel.
- `lurek.thread.newPool`: Creates a fixed-size thread pool where each worker runs the same Lua code and consumes items from a shared input channel.
- `lurek.thread.async`: Runs a Lua code string or dumped function asynchronously on a new worker thread, returning a promise for the result.
- `lurek.thread.getWorkerCapabilities`: Returns a list of capability names available inside worker VMs (e.g. which `lurek.*` modules are accessible).

### `LChannel` Methods
- `LChannel:type`: Returns the type name of this object.
- `LChannel:typeOf`: Checks whether this object matches the given type name.
- `LChannel:push`: Pushes a value onto the channel. Blocks on bounded channels if the channel is full.
- `LChannel:pop`: Removes and returns the next value from the channel without blocking.
- `LChannel:peek`: Returns the next value from the channel without removing it.
- `LChannel:demand`: Blocks until a value is available on the channel or the optional timeout expires.
- `LChannel:getCount`: Returns the number of values currently queued in the channel.
- `LChannel:getCapacity`: Returns the maximum capacity of a bounded channel, or `nil` for unbounded channels.
- `LChannel:isBounded`: Checks whether this channel has a fixed capacity limit.
- `LChannel:tryPush`: Attempts to push a value onto a bounded channel without blocking.
- `LChannel:clear`: Removes all pending values from the channel.
- `LChannel:supply`: Pushes a value and blocks until a consumer pops it (synchronous handoff).
- `LChannel:pushTable`: Pushes a table value onto the channel, raising an error if the value is not a table.
- `LChannel:popTable`: Pops the next value from the channel only if it is a table, discarding non-table values.
- `LChannel:pushBytes`: Pushes raw binary data onto the channel as a byte blob.
- `LChannel:popBytes`: Pops the next value from the channel only if it is a byte blob, discarding non-bytes values.

### `LPromise` Methods
- `LPromise:type`: Returns the type name of this object.
- `LPromise:typeOf`: Checks whether this object matches the given type name.
- `LPromise:isDone`: Checks whether the asynchronous computation has completed.
- `LPromise:result`: Returns the result value of the completed promise.
- `LPromise:getError`: Returns the error message from the promise, if it terminated with an error.
- `LPromise:chain`: Creates a new promise that runs the given code with the parent promise's result as its first argument.

### `LThread` Methods
- `LThread:type`: Returns the type name of this object.
- `LThread:typeOf`: Checks whether this object matches the given type name.
- `LThread:start`: Launches the worker thread, executing the Lua code string supplied at creation time.
- `LThread:wait`: Blocks the calling thread until the worker thread finishes execution.
- `LThread:isRunning`: Checks whether the worker thread is still executing.
- `LThread:getError`: Returns the error message from the worker thread, if it terminated with an error.

### `LThreadPool` Methods
- `LThreadPool:type`: Returns the type name of this object.
- `LThreadPool:typeOf`: Checks whether this object matches the given type name.
- `LThreadPool:submit`: Pushes a value into the pool's input channel for processing by a worker thread.
- `LThreadPool:collect`: Pops and returns the next result from the pool's output channel.
- `LThreadPool:size`: Returns the number of worker threads in the pool.
- `LThreadPool:join`: Blocks until all workers finish or the optional timeout elapses.
- `LThreadPool:getInputChannel`: Returns the pool's shared input channel that feeds work items to worker threads.
- `LThreadPool:getOutputChannel`: Returns the pool's shared output channel where worker threads place their results.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/thread/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### Recent sync (1.0.9-fix.73)

- Added bounded-channel support with backpressure:
  - `Channel::bounded(capacity)` and `lurek.thread.newBoundedChannel(capacity)`.
  - `LChannel:isBounded`, `LChannel:getCapacity`, `LChannel:tryPush`.
- Improved blocking semantics:
  - `Channel::demand(timeout)` now uses deadline-based waiting to avoid timeout extension under wakeups.
  - bounded producer paths now unblock when consumers pop.
- Improved thread-pool resilience:
  - `ThreadPool::join_with_timeout` and Lua `LThreadPool:join(timeout?)`.
- Added worker introspection:
  - `lurek.thread.getWorkerCapabilities()` returns worker-safe API list.
- Added composable promise chain:
  - `LPromise:chain(code, ...)` to build multi-stage async pipelines.
- Added async helper ergonomics:
  - `lurek.thread.async` now accepts both source string and function form.
- Queue overlap decision:
  - `thread::Channel` remains cross-VM/thread communication transport.
  - `event::EventQueue` remains main-thread gameplay/event routing queue.
