# `thread` — Agent Reference

| Property       | Value                                          |
|----------------|------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                |
| **Status**     | Implemented — Full                             |
| **Lua API**    | `lurek.thread`                                  |
| **Source**     | `src/thread/`                                  |
| **Rust Tests** | `tests/rust/unit/thread_tests.rs`              |
| **Lua Tests**  | `tests/lua/unit/test_thread.lua`               |
| **Architecture** | —                                            |

## Summary

The `thread` module provides Lurek2D's only concurrency primitive: background Lua worker threads communicating through typed MPMC channels. It directly implements design constraint B-04 — concurrency lives in Rust threads; LuaJIT VMs cannot share state; cross-VM communication uses typed `Channel` objects.

Each `LuaThread` accepts a Lua code string, spawns a dedicated OS thread running its own isolated `mlua::Lua` VM, and communicates with the main game thread exclusively through `Channel` objects. The worker VM receives a minimal API surface — only `lurek.thread.getChannel(name)` and a global `arg` table — deliberately excluding `lurek.gfx`, `lurek.audio`, `lurek.window`, `lurek.input`, `lurek.physics`, `lurek.particles`, and anything that touches `SharedState`. This hard boundary prevents an entire category of concurrency bugs.

`ChannelValue` is the wire format: `Nil`, `Bool(bool)`, `Number(f64)`, or `String(String)`. Only these four Lua-native primitive types can cross thread boundaries. Tables, functions, coroutines, and UserData are rejected at the send boundary with a descriptive runtime error. The `Channel` struct is an MPMC queue backed by `Mutex<VecDeque<ChannelValue>>` with a `Condvar` for the blocking `demand()` call. Channels can be unnamed (created per-use) or named (registered in a global `HashMap` shared across all worker threads for the session).

The module intentionally does not include: thread pools, async/await, futures, work-stealing schedulers, or shared-memory concurrency. It is designed so that a game script author writes synchronous Lua, delegates heavy work to a background thread via `lurek.thread.newThread(code)`, and polls results each frame with `channel:pop()`.

## Architecture

```
Main Thread                          Worker Thread N
┌────────────────────────┐           ┌────────────────────────┐
│ Lua VM (full lurek.*)   │           │ Lua VM (isolated)      │
│ SharedState (Rc<Ref>)  │           │ lurek.thread.getChannel  │
│ GpuRenderer            │           │ arg table               │
│ Game Loop              │           │ NO SharedState          │
└────────┬───────────────┘           └───────────┬────────────┘
         │                                       │
         │       Arc<Channel>                     │
         ├───────────────────────────────────────►│
         │  push(ChannelValue) / pop() / demand() │
         │◄───────────────────────────────────────┤
         │                                       │
         │  Named channels registered in          │
         │  Arc<Mutex<HashMap<String, Arc<Ch>>>>  │
         └────────────────────────────────────────┘

ChannelValue wire format:
  Nil | Bool(bool) | Number(f64) | String(String)

Channel internals:
  Mutex<VecDeque<ChannelValue>> + Condvar (for demand)
  + Mutex<u64> push_count (monotonic ID)
```

## Source Files

| File         | Purpose                                                         |
|--------------|-----------------------------------------------------------------|
| `mod.rs`     | Module root — re-exports `channel` and `worker` submodules      |
| `channel.rs` | `ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions |
| `worker.rs`  | `ThreadState` enum, `LuaThread` struct, worker VM registration  |

## Submodules

### `thread::channel`

Thread-safe MPMC channel for Lua inter-thread communication.

- **`ChannelValue`** (enum) — Wire format for cross-thread values: `Nil`, `Bool`, `Number`, `String`.
- **`Channel`** (struct) — MPMC queue using `Mutex<VecDeque>` + `Condvar`. Wraps in `Arc` for thread sharing. Supports `push`, `pop`, `peek`, `demand` (blocking), `supply` (push-if-empty), `get_count`, `clear`.
- **`LuaChannel`** (struct) — Lua UserData wrapper holding `Arc<Channel>`. Exposes all Channel operations as Lua methods plus `type()` and `typeOf()`.
- **`lua_to_channel_value`** (fn) — Converts a `LuaValue` to `ChannelValue`. Rejects tables, functions, and UserData with a runtime error.
- **`channel_value_to_lua`** (fn) — Converts a `ChannelValue` back to a `LuaValue` in a given Lua VM.

### `thread::worker`

Background Lua thread with independent VM.

- **`ThreadState`** (enum) — Execution lifecycle: `Pending`, `Running`, `Completed`, `Error(String)`.
- **`LuaThread`** (struct) — Owns a Lua code string, spawns an OS thread via `std::thread::spawn`, runs an isolated `mlua::Lua` VM. Tracks state via `Arc<Mutex<ThreadState>>`. Methods: `new`, `start`, `wait`, `is_running`, `get_error`.
- **`register_thread_safe_modules`** (fn, private) — Sets up the worker VM with only `lurek.thread.getChannel` and the `arg` global table.

## Key Types

### Structs

#### `thread::channel::Channel`

Thread-safe MPMC channel for Lua inter-thread communication. Internally uses a `Mutex<VecDeque<ChannelValue>>` protected queue with a `Condvar` for blocking `demand()` calls. Constructed via `Channel::new()` (unnamed) or `Channel::named(name)` (globally registered). Both return `Arc<Self>` for thread-safe sharing.

**Fields**: `name: Option<String>`, `queue: Mutex<VecDeque<ChannelValue>>`, `condvar: Condvar`, `push_count: Mutex<u64>`.

**Public methods**: `new() → Arc<Self>`, `named(String) → Arc<Self>`, `push(ChannelValue) → u64`, `pop() → Option<ChannelValue>`, `peek() → Option<ChannelValue>`, `demand(Option<f64>) → Option<ChannelValue>`, `get_count() → usize`, `clear()`, `supply(ChannelValue) → bool`, `name() → Option<&str>`.

#### `thread::channel::LuaChannel`

Lua UserData wrapper for a thread-safe channel. Holds `Arc<Channel>` so the same underlying channel can be shared across multiple Lua VMs (main thread and workers each hold their own `LuaChannel` handle pointing to the same `Arc<Channel>`).

**Fields**: `inner: Arc<Channel>` (pub(crate)).

**Lua methods**: `type()`, `typeOf(name)`, `push(value)`, `pop()`, `peek()`, `demand(timeout?)`, `getCount()`, `clear()`, `supply(value)`.

#### `thread::worker::LuaThread`

A background Lua thread running its own isolated VM. Created via `lurek.thread.newThread(code)`. The thread starts in `Pending` state and does not execute until `start()` is called with optional arguments.

**Fields**: `code: String`, `state: Arc<Mutex<ThreadState>>`, `handle: Option<thread::JoinHandle<()>>`, `channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>`.

**Public methods**: `new(code, channels) → Self`, `start(args: Vec<ChannelValue>) → Result<(), String>`, `wait()`, `is_running() → bool`, `get_error() → Option<String>`.

### Enums

#### `thread::channel::ChannelValue`

Serializable values that can cross thread boundaries. Only Lua-native primitive types are supported — UserData, tables, and functions cannot be transferred.

**Variants**: `Nil`, `Bool(bool)`, `Number(f64)`, `String(String)`.

#### `thread::worker::ThreadState`

Execution state of a background Lua thread, tracked via `Arc<Mutex<ThreadState>>` shared between the spawning thread and the worker.

**Variants**: `Pending` (created, not started), `Running` (executing Lua code), `Completed` (finished successfully), `Error(String)` (finished with error message).

## Lua API

Registered by `src/lua_api/thread_api.rs` under `lurek.thread.*`. The register function creates a shared `Arc<Mutex<HashMap<String, Arc<Channel>>>>` for named channel resolution across all threads in the session.

### Module Functions

| Function                        | Signature                            | Description                                                     |
|---------------------------------|--------------------------------------|-----------------------------------------------------------------|
| `lurek.thread.newThread(code)`   | `(string) → Thread`                 | Creates a background thread handle from a Lua code string       |
| `lurek.thread.newChannel()`      | `() → Channel`                      | Creates an unnamed channel for inter-thread communication       |
| `lurek.thread.getChannel(name)`  | `(string) → Channel`                | Gets or creates a named global channel shared across threads    |

### Thread UserData Methods (`LuaThreadHandle`)

| Method             | Signature           | Description                                                |
|--------------------|---------------------|------------------------------------------------------------|
| `thread:start(...)` | `(varargs) → nil`  | Spawns the OS thread; args available as `arg` table in worker VM |
| `thread:wait()`    | `() → nil`          | Blocks until the background thread finishes                |
| `thread:isRunning()` | `() → boolean`    | Returns whether the thread is currently executing          |
| `thread:getError()` | `() → string?`     | Returns the error message if the thread failed, or nil     |
| `thread:type()`    | `() → string`       | Returns `"Thread"`                                         |
| `thread:typeOf(name)` | `(string) → boolean` | Returns whether this object is of the given type       |

### Channel UserData Methods (`LuaChannel`)

| Method                    | Signature                | Description                                          |
|---------------------------|--------------------------|------------------------------------------------------|
| `channel:push(value)`     | `(any) → number`        | Pushes a value; returns a monotonic push ID          |
| `channel:pop()`           | `() → any`              | Pops front value or returns nil if empty             |
| `channel:peek()`          | `() → any`              | Returns front value without removing, or nil         |
| `channel:demand(timeout?)` | `(number?) → any`      | Blocks until a value arrives; optional timeout in seconds |
| `channel:getCount()`      | `() → number`           | Returns the number of values currently in the channel |
| `channel:clear()`         | `() → nil`              | Removes all values from the channel                  |
| `channel:supply(value)`   | `(any) → boolean`       | Pushes only if empty; returns true if pushed         |
| `channel:type()`          | `() → string`           | Returns `"Channel"`                                  |
| `channel:typeOf(name)`    | `(string) → boolean`    | Returns whether this object is of the given type     |

### Worker VM API

Inside a worker thread's Lua VM, only the following are available:

- `lurek.thread.getChannel(name)` — access named channels shared with the main thread
- `arg` — table of arguments passed to `thread:start(...)`

All other `lurek.*` modules are unavailable.

## Lua Examples

### Background computation with channel polling

```lua
function lurek.init()
    -- Create a named channel for results
    local ch = lurek.thread.getChannel("results")

    -- Spawn a background worker that computes squares
    worker = lurek.thread.newThread([[
        local ch = lurek.thread.getChannel("results")
        for i = 1, 1000 do
            ch:push(i * i)
        end
        ch:push("done")
    ]])
    worker:start()
end

function lurek.process(dt)
    -- Poll for results without blocking the game loop
    local ch = lurek.thread.getChannel("results")
    local val = ch:pop()
    if val == "done" then
        print("Worker finished all computations")
    elseif val ~= nil then
        -- Process result
    end
end
```

### Bidirectional communication with arguments

```lua
function lurek.init()
    local ch = lurek.thread.getChannel("pipe")

    worker = lurek.thread.newThread([[
        local ch = lurek.thread.getChannel("pipe")
        -- Read arguments passed to start()
        local multiplier = arg[1]
        -- Wait for input from main thread
        local val = ch:demand(10.0)
        -- Send result back
        ch:push(val * multiplier)
    ]])
    worker:start(5)  -- pass multiplier as argument

    ch:push(10)  -- send input value
end

function lurek.process(dt)
    local ch = lurek.thread.getChannel("pipe")
    local result = ch:pop()
    if result then
        print("Result: " .. result)  -- prints 50
    end
end
```

### Error handling

```lua
function lurek.init()
    worker = lurek.thread.newThread([[
        error("something went wrong")
    ]])
    worker:start()
end

function lurek.process(dt)
    if not worker:isRunning() then
        local err = worker:getError()
        if err then
            print("Worker failed: " .. err)
        end
    end
end
```

## Item Summary

| Kind     | Count |
|----------|-------|
| `struct` | 3     |
| `enum`   | 2     |
| `fn`     | 17    |
| **Total** | **22** |

## References

| Module       | Relationship | Notes                                                        |
|--------------|--------------|--------------------------------------------------------------|
| `engine`     | Imports from | Uses `log_messages` constants for structured logging         |
| `math`       | Peer (Tier 1)| Leaf module — safe to use conceptually alongside thread, but not exposed in worker VMs |
| `lua_api`    | Imported by  | `src/lua_api/thread_api.rs` registers `lurek.thread.*` and defines `LuaThreadHandle` UserData |

### Similar Modules

- **`thread` vs `event`**: `thread` handles OS-level background concurrency; `event` handles the single-threaded event queue within the main game loop. They do not overlap.
- **`thread` vs `timer`**: `timer` provides frame-level timing on the main thread; `thread` provides true parallel execution on separate OS threads.

## Notes

- **Constraint B-04**: Each worker thread creates its own isolated Lua VM via `mlua::Lua::new()`. Worker VMs do NOT share `SharedState` — they have no access to `Rc<RefCell<SharedState>>` at all. This is the fundamental concurrency safety guarantee.
- **Worker VM surface**: Worker threads receive only `lurek.thread.getChannel(name)` and `arg`. No graphics, audio, window, input, physics, particle, or filesystem modules are registered. The `register_thread_safe_modules()` function in `worker.rs` is the gatekeeper.
- **Channel safety**: `Channel` uses `Arc` + `Mutex<VecDeque>` + `Condvar` — standard Rust thread-safe primitives. No `unsafe` code anywhere in the module.
- **Named channel registry**: Named channels are stored in `Arc<Mutex<HashMap<String, Arc<Channel>>>>` created once during `lurek.thread` registration. The same `Arc` is cloned into every `LuaThread`, so all workers share the same named channel namespace.
- **`demand()` deadlock risk**: `demand(None)` blocks forever if no value is ever pushed. Always use a timeout (`demand(5.0)`) or ensure the producer will push. Never call `demand()` on the main game thread without a timeout.
- **Thread restart prevention**: `LuaThread::start()` returns `Err` if the thread is already in `Running` state, preventing double-start bugs.
- **Argument passing**: `thread:start(...)` converts varargs to `Vec<ChannelValue>` and injects them as the global `arg` table in the worker VM (1-indexed).
- **`supply()` semantics**: `channel:supply(value)` is an atomic push-if-empty — useful for producer-consumer patterns where the consumer processes one value at a time and the producer should not flood the queue.
- **Push ID**: `channel:push(value)` returns a monotonic `u64` counter, useful for tracking message ordering across threads.
