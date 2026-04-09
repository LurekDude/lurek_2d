# `patterns` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.patterns`                                        |
| **Source**       | `src/patterns/`                                        |
| **Rust Tests**   | `tests/rust/unit/patterns_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_patterns.lua`                     |
| **Architecture** | —                                                      |

## Summary

The `patterns` module provides pure-Rust implementations of classic game-programming design patterns, exposed via `lurek.patterns.*` factory functions. Each factory returns a Lua UserData object wrapping the corresponding domain type. All six domain types are pure Rust with no mlua dependency; Lua plumbing (registry keys, UserData) lives in `src/lua_api/patterns_api.rs`. The API is gated by `modules.pipeline = true` in `conf.lua`.

The patterns are:

1. **EventBus** — Priority-ordered publish/subscribe bus. Listeners fire sorted by numeric priority; `once` listeners auto-remove after the first call.
2. **ObjectPool** — Capacity-bounded ID-pool. `acquire()` moves an ID from idle to active; `release(id)` returns it. `prewarm(n)` pre-populates the idle pool.
3. **CommandStack** — Undo/redo history. Each command stores execute/undo Lua callbacks. `beginBatch()`/`endBatch()` groups commands into one undoable unit.
4. **ServiceLocator** — Named Lua-value registry. `provide(name, value)` registers any value; `locate(name)` retrieves it at runtime without direct references.
5. **Factory** — Named constructor registry. `register(typeName, fn)` stores a constructor; `create(typeName, ...)` calls it.
6. **SimpleState** — Named-state tracker with enter/exit/update callbacks per state. Any registered state can be entered at any time; no guard-validated transitions.

Also includes: **Blackboard** (shared key-value store), **Debounce/Throttle** (rate-limiting wrappers), **Funnel** (data-pipeline combiner), and **PriorityQueue** / **Ring** utilities.

## Architecture

```
src/patterns/
├── mod.rs             re-exports all public types
├── event_bus.rs       EventBus + Subscription
├── object_pool.rs     ObjectPool
├── command_stack.rs   CommandStack + CommandEntry
├── service_locator.rs ServiceLocator
├── factory.rs         Factory
└── state_machine.rs   StateMachine + TransitionRule + StateInfo

src/lua_api/
└── patterns_api.rs    Lua UserData wrappers (callbacks stored via LuaRegistryKey)
    ├── LuaEventBus    → EventBusInner (Lua listener keys + Subscription metadata)
    ├── LuaObjectPool  → ObjectPoolInner
    ├── LuaCommandStack → CommandStackInner (Lua execute/undo keys)
    ├── LuaServiceLocator → ServiceLocatorInner (Lua value keys)
    ├── LuaFactory     → FactoryInner (Lua constructor keys)
    └── LuaSimpleState → SimpleStateInner (Lua enter/exit/update keys)
```

Note: The Lua API wrappers in `patterns_api.rs` use their own inner structs that store `LuaRegistryKey` for callbacks. The domain types in `src/patterns/` provide pure-Rust reference implementations suitable for Rust-side tests and future non-Lua use (e.g., automation scripts, test harnesses).

## Source Files

| File                | Purpose                                                                          |
|---------------------|----------------------------------------------------------------------------------|
| `event_bus.rs`      | `EventBus`, `Subscription` — pub/sub event bus with priority and once semantics  |
| `object_pool.rs`    | `ObjectPool` — capacity-bounded ID-based idle/active object pool                |
| `command_stack.rs`  | `CommandStack`, `CommandEntry` — undo/redo stack with batch grouping             |
| `service_locator.rs`| `ServiceLocator` — named string-keyed service registry                           |
| `factory.rs`        | `Factory` — named type registry with alias resolution                            |
| `state_machine.rs`  | `StateMachine`, `TransitionRule`, `StateInfo` — validated FSM with history       |
| `mod.rs`            | Re-exports all public types                                                      |

## Submodules

### `patterns::event_bus`

- `Subscription`: `id: u64`, `event: String`, `priority: i32`, `once: bool`
- `EventBus`: subscribe/unsubscribe/emit metadata, `get_listeners()`, `drain_once()`, `clear_event()`, `clear_all()`

### `patterns::object_pool`

- `ObjectPool`: `idle: Vec<u64>`, `active: HashSet<u64>`, `next_id: u64`, `capacity: usize`
- Methods: `acquire()→Option<u64>`, `release(id)→bool`, `prewarm(n)`, `is_active(id)→bool`, `idle_count()`, `active_count()`

### `patterns::command_stack`

- `CommandEntry`: `id: u64`, `name: String`, `has_undo: bool`
- `CommandStack`: `push(name,has_undo)→u64`, `step_undo()→Option<u64>`, `step_redo()→Option<u64>`, `peek_undo()→Option<&CommandEntry>`, `peek_redo()→Option<&CommandEntry>`, `begin_batch()`, `end_batch()→Option<Vec<u64>>`, `clear()`, `undo_count()`, `redo_count()`

### `patterns::service_locator`

- `ServiceLocator`: `HashSet<String>` for registered service names
- Methods: `register(name)`, `unregister(name)→bool`, `has(name)→bool`, `names()→Vec<&str>`, `clear()`

Note: Domain `ServiceLocator` only tracks name presence; actual Lua values are stored via `LuaRegistryKey` in the Lua wrapper.

### `patterns::factory`

- `Factory`: `types: HashSet<String>`, `aliases: HashMap<String,String>`
- Methods: `register(type_name)`, `unregister(type_name)→bool`, `has(type_name)→bool`, `resolve(alias)→Option<&str>`, `add_alias(alias,target)`, `type_names()→Vec<&str>`, `clear()`

### `patterns::state_machine`

- `TransitionRule`: `from: String`, `to: String`, `label: Option<String>`, `has_guard: bool`
- `StateInfo`: `has_enter: bool`, `has_exit: bool`, `has_update: bool`
- `StateMachine`: `current: String`, `states: HashMap<String,StateInfo>`, `transitions: Vec<TransitionRule>`, `history: Vec<String>`, `history_cap: usize`
- Methods: `new(initial)`, `add_state(name,has_enter,has_exit,has_update)`, `has_state(name)→bool`, `state_names()→Vec<&str>`, `add_transition(from,to,label,has_guard)`, `can_transition(to)→bool`, `get_transition(from,to)→Option<&TransitionRule>`, `transition_to(to)→bool`, `history()→&[String]`, `reachable_from(state)→Vec<String>`, `has_update_callback()→bool`

## Key Types

### Structs

#### `patterns::event_bus::EventBus`
Pub/sub event bus. `subscribe(event, priority, once)→u64` returns a subscription ID. `unsubscribe(id)→bool` removes it. `get_listeners(event)→Vec<&Subscription>` returns sorted (by priority desc) listener records. `drain_once(event)` removes all `once=true` listeners for an event. Actual callback invocation is done in `patterns_api.rs`.

#### `patterns::object_pool::ObjectPool`
ID-based capacity-bounded pool. IDs are `u64` integers. `acquire()` returns the next idle ID or `None` if at capacity. `release(id)→bool` returns true if the ID was active. `prewarm(n)` pre-creates `n` idle entries up to capacity.

#### `patterns::command_stack::CommandStack`
Undo/redo command history with cursor-based navigation. `begin_batch()` / `end_batch()` group multiple commands. `clear()` wipes history and resets cursor. The domain type stores only names and undo-capability flags; Lua callbacks live in `patterns_api.rs`.

#### `patterns::service_locator::ServiceLocator`
Name-presence registry. Only tracks which service names have been registered — no values stored at the domain level (values are `LuaRegistryKey` in the Lua wrapper).

#### `patterns::factory::Factory`
Named type registry with alias resolution. `resolve(name)` follows the alias chain until a canonical registered type is found. Circular aliases are prevented by `resolve()` returning `None` after a fixed iteration limit.

#### `patterns::state_machine::StateMachine`
Validated FSM. Transitions are only allowed along pre-registered edges. `can_transition(to)→bool` checks without side effects. `transition_to(to)→bool` performs the transition, fires enter/exit callbacks (via `patterns_api.rs`), and appends to history. History is a ring capped at `history_cap` (default 64).

#### `patterns::command_stack::CommandEntry`
A single entry in the undo/redo history. Fields: `id: u64`, `name: String`, `has_undo: bool`. Read via `CommandStack::peek_undo()` / `peek_redo()`.

#### `patterns::blackboard::Blackboard`
Shared key-value store. `set(key, value)` inserts a `BlackboardValue`; `get(key)` returns `Option<&BlackboardValue>`; `remove(key)` deletes an entry; `clear()` empties the board; `keys()` returns all stored keys.

#### `patterns::throttle::Debounce`
Rate-limiting wrapper. `update(dt)→bool` returns `true` once the debounce interval has elapsed since the last trigger. `reset()` restarts the timer.

#### `patterns::funnel::Funnel`
Data-pipeline aggregator. Collects values from multiple sources via `push(value)`, then `flush()` processes the batch. `is_ready()→bool` returns `true` when the funnel has reached its drain threshold.

#### `patterns::funnel::FunnelEntry`
A single item held inside a [`Funnel`] pending the next flush. Fields: `value: LuaRegistryKey` (Lua API wrapper value).

### Enums

#### `patterns::blackboard::BlackboardValue`
Typed variant stored inside a [`Blackboard`]. Variants: `Boolean(bool)`, `Integer(i64)`, `Float(f64)`, `Text(String)`, `Nil`.

No other public enums in this module.

## Lua API

The Lua API is registered in `src/lua_api/patterns_api.rs` under `lurek.patterns.*`.

Each factory function returns a new Lua UserData object. All callback-holding inner types in `patterns_api.rs` use `LuaRegistryKey` to hold Lua function references.

| Function | Signature | Description |
|---|---|---|
| `lurek.patterns.newEventBus()` | `→ EventBus` | Create a new publish/subscribe bus |
| `bus:on(event, cb, priority?)` | `→ id` | Subscribe; returns subscription ID |
| `bus:off(id)` | — | Unsubscribe by subscription ID |
| `bus:emit(event, ...)` | — | Fire all listeners for an event |
| `bus:clear(event)` | — | Remove all listeners for one event |
| `bus:clearAll()` | — | Remove all listeners on all events |
| `bus:getListenerCount(event)` | `→ int` | Count subscribers for an event |
| `bus:getEvents()` | `→ table` | Array of registered event names |
| `lurek.patterns.newObjectPool()` | `→ ObjectPool` | Create a new object pool |
| `pool:add(value)` | — | Add a pre-built Lua value to the pool |
| `pool:acquire()` | `→ any\|nil` | Borrow an available value (nil if empty) |
| `pool:release(value)` | — | Return a borrowed value to the pool |
| `pool:getActiveCount()` | `→ int` | Number of currently borrowed values |
| `pool:getAvailableCount()` | `→ int` | Number of idle (available) values |
| `pool:getTotalCount()` | `→ int` | Total tracked values (active + available) |
| `pool:clearAll()` | — | Empty the pool and release all registry values |
| `lurek.patterns.newCommandStack(maxSize?)` | `→ CommandStack` | Create a new undo/redo stack |
| `stack:execute(name, exec_fn, undo_fn?)` | — | Call exec_fn immediately and push to history |
| `stack:undo()` | `→ boolean` | Execute undo on top command |
| `stack:redo()` | `→ boolean` | Re-execute last undone command |
| `stack:canUndo()` | `→ boolean` | Whether undo is available |
| `stack:canRedo()` | `→ boolean` | Whether redo is available |
| `stack:getHistorySize()` | `→ int` | Number of commands |
| `stack:getCurrentName()` | `→ string\|nil` | Name of the last executed command |
| `stack:clearAll()` | — | Clear history and free callbacks |
| `lurek.patterns.newServiceLocator()` | `→ ServiceLocator` | Create a new service registry |
| `sl:provide(name, value)` | — | Register a value under a name |
| `sl:locate(name)` | `→ any\|nil` | Retrieve a registered value |
| `sl:has(name)` | `→ boolean` | Check if a name is registered |
| `sl:remove(name)` | — | Unregister a service |
| `sl:getServices()` | `→ table` | Array of registered service names |
| `sl:clearAll()` | — | Remove all services |
| `lurek.patterns.newFactory()` | `→ Factory` | Create a new constructor registry |
| `factory:register(type, fn)` | — | Register a constructor function |
| `factory:create(type, ...)` | `→ any` | Call the constructor with args |
| `factory:has(type)` | `→ boolean` | Check if a type is registered |
| `factory:getTypes()` | `→ table` | Array of registered type names |
| `factory:remove(type)` | — | Unregister a type |
| `factory:clearAll()` | — | Remove all registrations |
| `lurek.patterns.newSimpleState()` | `→ SimpleState` | Create a new FSM |
| `fsm:addState(name, {enter?,exit?,update?})` | — | Register a state with callbacks |
| `fsm:transitionTo(name)` | `→ boolean` | Move to a new state |
| `fsm:update(dt)` | — | Call current state's update |
| `fsm:getCurrent()` | `→ string\|nil` | Current state name |
| `fsm:hasState(name)` | `→ boolean` | Check if a state exists |
| `fsm:getStates()` | `→ table` | Array of all state names |
| `fsm:clearAll()` | — | Remove all states and callbacks |

## Lua Examples

```lua
-- === EventBus ===
local bus = lurek.patterns.newEventBus()

bus:on("player_died", function(cause)
    print("Player died:", cause)
end, 10)  -- priority 10

bus:on("player_died", function()
    -- plays sound (lower priority — fires second)
end, 5)

bus:emit("player_died", "lava")  -- fires both listeners

-- === ObjectPool (bullet pool) ===
local pool = lurek.patterns.newObjectPool()
pool:setCapacity(100)
pool:prewarm(20)

local bullets = {}
local function spawn_bullet()
    local id = pool:acquire()
    if id then
        bullets[id] = { x=100, y=200, vx=5, vy=0 }
    end
end

local function destroy_bullet(id)
    bullets[id] = nil
    pool:release(id)
end

-- === CommandStack (editor undo-redo) ===
local cmds = lurek.patterns.newCommandStack()
local placed = {}

local function place_tile(x, y, tile)
    local old = placed[x .. "," .. y]
    cmds:push("place_tile",
        function() placed[x..","..y] = tile end,
        function() placed[x..","..y] = old end
    )
end

-- lurek.input.onKeyDown("z") → cmds:undo()
-- lurek.input.onKeyDown("y") → cmds:redo()

-- === ServiceLocator ===
local services = lurek.patterns.newServiceLocator()

-- Register at boot
services:provide("audio", { play = function(snd) lurek.audio.play(snd) end })
services:provide("ui", require("ui_manager"))

-- Access anywhere
services:locate("audio").play("explosion.ogg")

-- === Factory ===
local factory = lurek.patterns.newFactory()

factory:register("goblin", function(x, y)
    return { type="goblin", x=x, y=y, hp=10 }
end)
factory:register("troll", function(x, y)
    return { type="troll", x=x, y=y, hp=50 }
end)

local enemy = factory:create("goblin", 100, 200)

-- === SimpleState (game state machine) ===
local game_fsm = lurek.patterns.newSimpleState()

game_fsm:addState("menu", {
    enter = function() print("Entering menu") end,
    exit  = function() print("Leaving menu") end,
})
game_fsm:addState("playing", {
    enter  = function() print("Game started!") end,
    update = function(dt) -- move entities end
end,
})
game_fsm:addState("paused", {
    enter = function() print("Paused") end,
})

game_fsm:transitionTo("menu")  -- fires enter

lurek.process = function(dt)
    game_fsm:update(dt)
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 8     |
| `enum`    | 0     |
| `fn`      | 50+   |
| **Total** | **58+** |

## References

| Module       | Relationship | Notes                                                       |
|--------------|--------------|-------------------------------------------------------------|
| `engine`     | Imports from | `SharedState` used in `patterns_api.rs` only (`_state`)     |
| `lua_api`    | Imported by  | `patterns_api.rs` registers the Lua surface                 |
| `pipeline`   | —            | Patterns are logic utilities; pipeline composes task graphs |
| `event`      | Similar      | `lurek.signal` is the engine event bus; `EventBus` is per-game-system |
| `ai`         | Could use    | FSM in `ai` is behaviour-tree driven; `SimpleState` is lighter-weight |

## Notes

- `LuaSimpleState` stores callbacks as `LuaRegistryKey` — `clearAll()` must be called to release them if the FSM is discarded, otherwise they are never GC'd.
- `CommandStack::push` in the Lua API immediately calls the execute function — there is no deferred execution.
- `ObjectPool::acquire()` returns `nil` when at capacity — always check before use.
- The domain pattern types (`EventBus`, `ObjectPool`, etc.) in `src/patterns/` are pure Rust and can be used in Rust tests without Lua. The `LuaXxx` wrappers in `patterns_api.rs` are Lua-specific and cannot be used from Rust tests.
- The Lua `SimpleState` does **not** validate transitions — any `transitionTo` succeeds if the state exists. Use the domain `StateMachine` from Rust code if transition guards are required.
