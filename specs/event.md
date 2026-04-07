# `event` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.signal`                                         |
| **Source**     | `src/event/`                                         |
| **Rust Tests** | `tests/rust/unit/event_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_event.lua`                      |
| **Architecture** | —                                                  |

## Summary

The event module provides two complementary messaging primitives for Luna2D games: a FIFO **EventQueue** for pollable named events, and a handle-based **Signal** pub-sub dispatcher for callback-driven event handling. Together they give game scripts full control over inter-system communication without tight coupling.

The `EventQueue` stores `Event` values consisting of a string name and a list of typed `EventArg` arguments (`Str`, `Num`, `Bool`, `Nil`). The engine pushes system events (input, window lifecycle) into the queue automatically; game scripts can also push custom events with `luna.signal.push()`. Consumption is explicit via `luna.signal.poll()`, which returns a Lua iterator that pops events one at a time. The queue also supports `pump()` (a no-op sync point, since Luna2D uses a push model) and `wait(timeout)` for blocking until an event arrives or a timeout elapses.

The `Signal` type is an independent pub-sub dispatcher. Subscribers call `Signal:register(name, callback)` and receive a monotonically increasing handle ID. When `Signal:emit(name, ...)` fires, all callbacks registered for that name execute in registration order with the extra arguments forwarded. Handles can be removed individually via `Signal:remove(handle)`, per-event via `Signal:clear(name)`, or wholesale via `Signal:clearAll()`. Callback functions are stored in the Lua registry; the Rust-side `Signal` struct tracks only subscription metadata (handle→name mappings).

Engine lifecycle control is also routed through this module: `luna.signal.quit()` sets the quit flag, and `luna.signal.restart()` sets the restart flag, both read by the main loop at frame boundaries. This keeps shutdown and restart logic out of every other module.

## Architecture

```
luna.signal.*  (Lua API)
  │
  ├── push(name, ...) ──► EventQueue.push_event(name, args)
  ├── poll()           ──► iterator → EventQueue.poll() → Event
  ├── clear()          ──► EventQueue.clear()
  ├── pump()           ──► EventQueue.pump()  (no-op)
  ├── wait(timeout?)   ──► EventQueue.wait(timeout_ms)
  ├── quit(code?)      ──► SharedState.quit_requested = true
  ├── restart()        ──► SharedState.restart_requested = true
  │
  └── newSignal()      ──► LuaSignal UserData
                            │
                            ├── register(name, fn) → handle (u64)
                            ├── emit(name, ...)    → calls all matching callbacks
                            ├── remove(handle)     → bool
                            ├── clear(name)        → count removed
                            ├── clearAll()         → count removed
                            ├── getCount(name)     → usize
                            └── getTotalCount()    → usize

Internal Rust types:

  EventQueue { events: VecDeque<Event> }
    └── Event { name: String, args: Vec<EventArg> }
         └── EventArg::Str | Num | Bool | Nil

  Signal { next_handle: u64, subscriptions: HashMap<String, Vec<u64>>,
           handle_to_name: HashMap<u64, String> }
    └── Subscription { handle: u64, name: String }
```

## Source Files

| File        | Purpose                                                         |
|-------------|-----------------------------------------------------------------|
| `mod.rs`    | `EventArg` enum, `Event` struct, `EventQueue` FIFO queue       |
| `signal.rs` | `Subscription` struct, `Signal` handle-based pub-sub dispatcher |

## Submodules

### `event::mod`

Core FIFO event queue for named game events with typed arguments.

- **`EventArg`** (enum): Typed argument value attached to an event. Variants: `Str(String)`, `Num(f64)`, `Bool(bool)`, `Nil`.
- **`Event`** (struct): A single event in the queue. Fields: `name: String`, `args: Vec<EventArg>`.
- **`EventQueue`** (struct): FIFO queue backed by `VecDeque<Event>`. Methods: `new()`, `push(event)`, `push_event(name, args)`, `poll() → Option<Event>`, `clear()`, `is_empty() → bool`, `len() → usize`, `pump()`, `wait(timeout_ms) → Option<Event>`.

### `event::signal`

Handle-based pub-sub signal system. Callbacks are stored externally (Lua registry); the Rust struct tracks only subscription metadata.

- **`Subscription`** (struct): A single subscription entry. Fields: `handle: u64`, `name: String`.
- **`Signal`** (struct): Pub-sub dispatcher with monotonic handle allocation. Fields: `next_handle: u64`, `subscriptions: HashMap<String, Vec<u64>>`, `handle_to_name: HashMap<u64, String>`. Methods: `new()`, `subscribe(name) → u64`, `remove(handle) → bool`, `clear(name) → usize`, `clear_all() → usize`, `get_handles(name) → Vec<u64>`, `get_count(name) → usize`, `get_total_count() → usize`.

## Key Types

### Structs

#### `event::Event`

A single event in the event queue. Contains a string `name` identifying the event type and a `Vec<EventArg>` payload of typed arguments. Created by game scripts via `luna.signal.push()` or by the engine for system events.

#### `event::EventQueue`

FIFO event queue backed by `VecDeque<Event>`. Supports push, poll (pop front), clear, length queries, a no-op `pump()` for API parity, and a `wait(timeout_ms)` that spin-sleeps with 1 ms granularity until an event arrives or the timeout expires.

#### `event::signal::Subscription`

A single subscription entry in a `Signal`. Stores the unique `handle` ID and the event `name` it listens to. Used internally by `Signal` for bookkeeping.

#### `event::signal::Signal`

Handle-based pub-sub signal dispatcher. Listeners subscribe by event name and receive a monotonically increasing handle ID. When an event is emitted, all matching handles fire in registration order. The actual callback functions are stored externally (in the Lua registry via `LuaSignal`); this struct tracks only the subscription metadata.

### Enums

#### `event::EventArg`

Typed argument value that can be attached to an event. Four variants: `Str(String)` for text, `Num(f64)` for numbers, `Bool(bool)` for flags, and `Nil` for absent values. Maps directly to Lua primitive types at the API boundary.

## Lua API

Registered by `src/lua_api/event_api.rs` under the `luna.signal` namespace. Provides eight top-level functions and a `Signal` UserData type with seven methods.

### Top-level functions

| Function                     | Description                                                       |
|------------------------------|-------------------------------------------------------------------|
| `luna.signal.push(name, ...)` | Pushes a custom event with the given name and optional arguments  |
| `luna.signal.poll()`          | Returns an iterator function that pops events as `name, arg1, ...` |
| `luna.signal.clear()`         | Discards all pending events in the queue                          |
| `luna.signal.pump()`          | No-op sync point (Luna2D uses a push model)                      |
| `luna.signal.wait(timeout?)`  | Blocks until an event arrives or timeout (seconds) elapses        |
| `luna.signal.quit(code?)`     | Requests engine shutdown with optional exit code                  |
| `luna.signal.restart()`       | Requests engine restart at the next frame boundary                |
| `luna.signal.newSignal()`     | Creates and returns a new `Signal` UserData object                |

### Signal UserData methods

| Method                          | Description                                                  |
|---------------------------------|--------------------------------------------------------------|
| `Signal:register(name, fn)`     | Registers a callback for the named event; returns handle ID  |
| `Signal:emit(name, ...)`        | Fires all callbacks registered for the name with extra args  |
| `Signal:remove(handle)`         | Removes a subscription by handle; returns `true` if found    |
| `Signal:clear(name)`            | Removes all callbacks for the named event; returns count     |
| `Signal:clearAll()`             | Removes all callbacks across all events; returns count       |
| `Signal:getCount(name)`         | Returns the callback count for the named event               |
| `Signal:getTotalCount()`        | Returns the total callback count across all events           |

## Lua Examples

```lua
-- Polling events in the game loop
function luna.process(dt)
    for name, a1, a2 in luna.signal.poll() do
        if name == "coin_collected" then
            score = score + a1
        elseif name == "quit" then
            luna.signal.quit()
        end
    end
end

function luna.keypressed(key)
    if key == "space" then
        luna.signal.push("coin_collected", 10)
    end
end
```

```lua
-- Using Signal for decoupled pub-sub
local sig = luna.signal.newSignal()

function luna.init()
    -- Register two listeners for "damage"
    sig:register("damage", function(amount)
        hp = hp - amount
        print("Ouch! HP:", hp)
    end)

    local handle = sig:register("damage", function(amount)
        print("Damage log:", amount)
    end)

    -- Fire the event
    sig:emit("damage", 25)

    -- Remove one listener
    sig:remove(handle)

    -- Query counts
    print("damage listeners:", sig:getCount("damage"))   -- 1
    print("total listeners:", sig:getTotalCount())        -- 1
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 4     |
| `enum`     | 1     |
| `fn`       | 17    |
| **Total**  | **22**|

## References

| Module    | Relationship | Notes                                                           |
|-----------|--------------|-----------------------------------------------------------------|
| `engine`  | Imports from | `EventQueue` stored in `SharedState`; `quit_requested` / `restart_requested` / `exit_code` flags live on `SharedState` |
| `math`    | Imports from | Only indirectly (leaf module); no direct type imports            |
| `input`   | Related      | `input` manages hardware-level key/mouse/gamepad state; `event` provides a user-programmable message queue and pub-sub layer |
| `scene`   | Related      | Scene transitions may push events; scenes can subscribe via `Signal` |
| `lua_api`  | Imported by  | `src/lua_api/event_api.rs` registers `luna.signal.*` and wraps `Signal` as `LuaSignal` UserData |

## Notes

- The `EventQueue` is a FIFO buffer backed by `VecDeque`. Events are consumed one at a time by `luna.signal.poll()`, which returns an iterator — use `for name, a1, a2 in luna.signal.poll() do ... end`.
- `luna.signal.push(name, ...)` accepts variadic arguments of string, number, boolean, or nil. Non-primitive types (tables, userdata) are coerced to `Nil`.
- `luna.signal.pump()` is a no-op. Luna2D uses a push model where OS events are already enqueued by the time callbacks fire. It exists solely for API parity.
- `luna.signal.wait(timeout)` spin-sleeps with 1 ms granularity. It is intended for worker-thread synchronisation patterns, not for use inside the main game loop. Passing `0` performs a single non-blocking check.
- `Signal` callbacks fire in registration order. The Rust `Signal` struct stores only handle metadata; the actual Lua callback functions are stored in the Lua registry via `LuaRegistryKey` and cleaned up on `remove` / `clear` / `clearAll`.
- `luna.signal.quit(code?)` and `luna.signal.restart()` set flags on `SharedState` (`quit_requested`, `restart_requested`). The engine reads these at frame boundaries — calling them does not terminate execution immediately.
- Do not push events from inside `luna.draw()` — the draw callback should be side-effect free.
- The `Subscription` struct is `#[allow(dead_code)]` — it exists for bookkeeping but its fields are not directly read outside of `Signal` internals.
