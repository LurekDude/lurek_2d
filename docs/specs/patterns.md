# `patterns` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.patterns` |
| **Source** | `src/patterns/` |
| **Rust Tests** | `tests/rust/unit/patterns_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_patterns.lua`; `tests/lua/stress/test_patterns_stress.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `patterns` module owns reusable coordination primitives for Lurek2D gameplay code. It gathers small, pure-Rust building blocks such as event buses, state trackers, queues, registries, object pools, throttles, blackboards, and similar logic helpers that can be shared across many higher-level systems.

This module exists so common gameplay-control patterns do not have to be reimplemented ad hoc in Lua or buried inside unrelated engine modules. Most types here intentionally store only the domain-side bookkeeping and metadata, while the Lua API layer adds callback storage, registry keys, and UserData wrappers on top.

`patterns` intentionally does not own the engine's global event system, ECS state, AI decision policies, or task-graph execution. It provides generic mechanics and containers; feature modules are responsible for deciding when and why to use them.

**Scope boundary**: This module currently acts as a mostly self-contained part of the Foundations layer. Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below.

---

## Architecture

```
lurek.patterns.* (Lua API — src/lua_api/patterns_api.rs)
    |
    v
src/patterns/mod.rs
    |- blackboard.rs - blackboard
    |- command_stack.rs - command_stack
    |- event_bus.rs - event_bus
    |- factory.rs - factory
    |- funnel.rs - funnel
    |- object_pool.rs - object_pool
    |- observer.rs - observer
    |- priority_queue.rs - priority_queue
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `blackboard.rs` | Implements a shared typed key-value board with revision tracking for cross-system facts. |
| `command_stack.rs` | Tracks undo and redo history metadata, including cursor position and batching state. |
| `event_bus.rs` | Implements named event-subscription metadata with priority ordering and one-shot listeners. |
| `factory.rs` | Implements a constructor-name registry with optional alias resolution. |
| `funnel.rs` | Implements a time-windowed event collector that can batch inputs before flushing. |
| `mod.rs` | Declares the patterns submodules and re-exports the public helper types. |
| `object_pool.rs` | Implements slot bookkeeping for reusable pooled objects, including idle and active tracking. |
| `observer.rs` | Implements per-key watcher metadata for reactive property changes. |
| `priority_queue.rs` | Implements a stable highest-priority-first queue for small agenda or turn-order workloads. |
| `ring.rs` | Implements a fixed-capacity circular history buffer for numeric or string-tagged entries. |
| `service_locator.rs` | Implements a named-service presence registry used by the Lua layer to store actual values. |
| `simple_state.rs` | Implements a lightweight named-state tracker with a single active state and no validated transition graph. |
| `state_machine.rs` | Implements a fuller finite-state machine with registered states, explicit transition rules, and history. |
| `throttle.rs` | Implements leading-edge throttle and trailing-edge debounce timers for callback rate limiting. |

---

## Submodules

### `patterns::blackboard`

Implements a shared typed key-value board with revision tracking for cross-system facts.

- **`BlackboardValue`** (enum): A value that can be stored on a [`Blackboard`].
- **`Blackboard`** (struct): Shared key-value data store for coordinating AI and game subsystems.

### `patterns::command_stack`

Tracks undo and redo history metadata, including cursor position and batching state.

- **`CommandEntry`** (struct): Metadata for a single recorded command.
- **`CommandStack`** (struct): Undo/redo command history with named groups and batch support.

### `patterns::event_bus`

Implements named event-subscription metadata with priority ordering and one-shot listeners.

- **`Subscription`** (struct): Event subscription record (metadata only).
- **`EventBus`** (struct): Ordered subscription registry for a named event bus.

### `patterns::factory`

Implements a constructor-name registry with optional alias resolution.

- **`Factory`** (struct): Constructor-name registry (metadata only; constructors stored in lua_api layer).

### `patterns::funnel`

Implements a time-windowed event collector that can batch inputs before flushing.

- **`FunnelEntry`** (struct): A single event collected by a [`Funnel`].
- **`Funnel`** (struct): Batching event collector.

### `patterns::object_pool`

Implements slot bookkeeping for reusable pooled objects, including idle and active tracking.

- **`ObjectPool`** (struct): Slot-tracking object pool (metadata only; Lua objects stored in lua_api layer).

### `patterns::observer`

Implements per-key watcher metadata for reactive property changes.

- **`ObserverEntry`** (struct): A single observer subscription record (metadata only; callback in Lua layer).
- **`Observer`** (struct): Reactive property bag: stores string-keyed string values and tracks subscriptions by property key.

### `patterns::priority_queue`

Implements a stable highest-priority-first queue for small agenda or turn-order workloads.

- **`PriorityItem`** (struct): A single queued item record (payload stored in Lua API layer).
- **`PriorityQueue`** (struct): Stable priority queue for game tasks, spells, turn orders, and agendas.

### `patterns::ring`

Implements a fixed-capacity circular history buffer for numeric or string-tagged entries.

- **`Ring`** (struct): Fixed-capacity circular value ring.
- **`RingEntry`** (struct): A single entry in a [`Ring`].

### `patterns::service_locator`

Implements a named-service presence registry used by the Lua layer to store actual values.

- **`ServiceLocator`** (struct): Named-service registry (metadata only; values stored in lua_api layer).

### `patterns::simple_state`

Implements a lightweight named-state tracker with a single active state and no validated transition graph.

- **`SimpleState`** (struct): Finite state machine that tracks a set of named states and the current one.

### `patterns::state_machine`

Implements a fuller finite-state machine with registered states, explicit transition rules, and history.

- **`TransitionRule`** (struct): A permitted transition between two states.
- **`StateMachine`** (struct): Finite-state machine with history stack and transition validation.

### `patterns::throttle`

Implements leading-edge throttle and trailing-edge debounce timers for callback rate limiting.

- **`Throttle`** (struct): Enforces a minimum interval between callback invocations (leading-edge).
- **`Debounce`** (struct): Delays callback invocation until the input stream is idle (trailing-edge).

---

## Key Types

### Public Types

#### `Blackboard`

Shared fact store for lightweight cross-system coordination.

#### `BlackboardValue`

Tagged value enum stored inside a `Blackboard`.

#### `CommandStack`

Undo and redo metadata tracker.

#### `CommandEntry`

Single recorded command inside a `CommandStack`.

#### `EventBus`

Named pub-sub registry that orders listeners by priority.

#### `Subscription`

Metadata record for one event-bus listener.

#### `Factory`

Named constructor registry.

#### `ObjectPool`

Slot manager for reusable objects.

#### `Observer`

Per-key subscription registry for reactive property changes.

#### `ObserverEntry`

Metadata for one observer subscription.

#### `PriorityQueue`

Stable priority queue for small scheduling and agenda workloads.

#### `PriorityItem`

Entry stored inside a `PriorityQueue`.

#### `Ring`

Fixed-capacity rolling history buffer.

#### `RingEntry`

One retained ring-buffer entry with optional numeric or string payload and a tag.

#### `ServiceLocator`

Named-service registry.

#### `SimpleState`

Minimal state tracker with one active named state.

#### `StateMachine`

Transition-aware finite-state machine with registered states and visit history.

#### `TransitionRule`

Declares one allowed transition in a `StateMachine`.

#### `Throttle`

Leading-edge rate limiter that decides when a callback is allowed to fire.

#### `Debounce`

Trailing-edge idle timer that delays firing until input settles.

#### `Funnel`

Batch collector that groups time-adjacent events before a flush.

#### `FunnelEntry`

Single buffered record inside a `Funnel`.

---

## Lua API

Exposed under `lurek.patterns.*` by `src/lua_api/patterns_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.patterns.newEventBus` | Creates a new EventBus instance. |
| `lurek.patterns.newObjectPool` | Creates a new ObjectPool instance. |
| `lurek.patterns.newCommandStack` | Creates a new CommandStack instance. |
| `lurek.patterns.newServiceLocator` | Creates a new ServiceLocator instance. |
| `lurek.patterns.newFactory` | Creates a new Factory instance. |
| `lurek.patterns.newSimpleState` | Creates a new SimpleState finite state machine instance. |
| `lurek.patterns.newBlackboard` | Creates a new Blackboard shared key-value store. |
| `lurek.patterns.newObserver` | Creates a new reactive property Observer. |
| `lurek.patterns.newThrottle` | Creates a leading-edge rate limiter that fires at most once per interval seconds. |
| `lurek.patterns.newDebounce` | Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds. |
| `lurek.patterns.newPriorityQueue` | Creates a stable priority-ordered task queue. |
| `lurek.patterns.newRing` | Creates a fixed-capacity circular history buffer. |
| `lurek.patterns.newFunnel` | Creates a time-windowed event aggregator. window=0 means flush on every push. |

### `Blackboard` Methods

| Method | Description |
|--------|-------------|
| `blackboard:set(...)` | Sets a fact on the blackboard. Accepts boolean, number, or string values. |
| `blackboard:get(...)` | Gets a fact from the blackboard. Returns nil if not set. |
| `blackboard:has(...)` | Returns true when the key has a non-nil value. |
| `blackboard:clear(...)` | Removes a fact from the blackboard. |
| `blackboard:keys(...)` | Returns all set fact keys as a table. |
| `blackboard:watch(...)` | Subscribes to changes on a specific key (or "*" for all changes). |
| `blackboard:unwatch(...)` | Removes a watcher subscription by id. |
| `blackboard:getRevision(...)` | Returns the monotonic revision counter (incremented on every write). |
| `blackboard:snapshot(...)` | Returns all facts as a flat key→value table. |
| `blackboard:clearAll(...)` | Clears all facts from the blackboard. |

### `CommandStack` Methods

| Method | Description |
|--------|-------------|
| `commandstack:execute(...)` | Executes a named command and records it in undo/redo history. |
| `commandstack:undo(...)` | Undoes the most recent command. Returns true if successful. |
| `commandstack:redo(...)` | Re-executes the next undone command. Returns true if successful. |
| `commandstack:canUndo(...)` | Returns true if the most recent command can be undone. |
| `commandstack:canRedo(...)` | Returns true if there is a command available to redo. |
| `commandstack:getHistorySize(...)` | Returns the total number of recorded commands (undo + redo). |
| `commandstack:getCurrentName(...)` | Returns the name of the most recently executed command, or nil. |
| `commandstack:clearAll(...)` | Clears all command history, releasing Lua registry values. |

### `Debounce` Methods

| Method | Description |
|--------|-------------|
| `debounce:onFire(...)` | Sets the callback invoked when the debounce fires. |
| `debounce:trigger(...)` | Records an input event, resetting the idle timer. |
| `debounce:update(...)` | Advances the idle timer by dt seconds; fires the callback if idle wait expired. |
| `debounce:cancel(...)` | Cancels the pending trigger without firing. |
| `debounce:isPending(...)` | Returns true when a trigger is pending. |
| `debounce:getFireCount(...)` | Returns the total number of times this debounce has fired. |

### `EventBus` Methods

| Method | Description |
|--------|-------------|
| `eventbus:on(...)` | Registers a listener callback for an event. |
| `eventbus:off(...)` | Removes a previously registered event listener by subscription ID. |
| `eventbus:emit(...)` | Dispatches an event, calling all registered listeners in priority order. |
| `eventbus:clear(...)` | Removes all listeners for a specific event. |
| `eventbus:clearAll(...)` | Removes all listeners on this EventBus. |
| `eventbus:getListenerCount(...)` | Returns the number of listeners registered for an event. |
| `eventbus:getEvents(...)` | Returns all event names that have at least one listener. |

### `Factory` Methods

| Method | Description |
|--------|-------------|
| `factory:register(...)` | Registers a named type constructor function. |
| `factory:create(...)` | Creates an instance of the named type by invoking its constructor. |
| `factory:has(...)` | Returns true if the named type (or alias) is registered. |
| `factory:alias(...)` | Registers an alias pointing to an existing canonical type name. |
| `factory:getTypes(...)` | Returns a table of all registered type names. |
| `factory:remove(...)` | Unregisters a type constructor (and any aliases pointing to it). |
| `factory:clearAll(...)` | Removes all registered type constructors and aliases. |

### `Funnel` Methods

| Method | Description |
|--------|-------------|
| `funnel:onFlush(...)` | Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries. |
| `funnel:push(...)` | Adds an event to the funnel. Immediately flushes if max_entries reached or window is 0. |
| `funnel:update(...)` | Advances the window timer by dt seconds; flushes when window expires. |
| `funnel:flush(...)` | Manually flushes all pending entries, invoking the onFlush callback. |
| `funnel:discard(...)` | Discards all buffered entries without flushing. |
| `funnel:pendingCount(...)` | Returns the number of buffered entries not yet flushed. |
| `funnel:getFlushCount(...)` | Returns the total number of flushes performed. |

### `ObjectPool` Methods

| Method | Description |
|--------|-------------|
| `objectpool:add(...)` | Inserts a pre-built object into the available pool. |
| `objectpool:acquire(...)` | Acquires an available object from the pool; returns nil if empty. |
| `objectpool:release(...)` | Returns an object to the available pool. |
| `objectpool:getActiveCount(...)` | Returns the number of currently active (acquired) objects. |
| `objectpool:getAvailableCount(...)` | Returns the number of available (idle) objects in the pool. |
| `objectpool:getTotalCount(...)` | Returns the total number of tracked objects (active + available). |
| `objectpool:clearAll(...)` | Clears all objects from the pool, releasing Lua registry values. |

### `Observer` Methods

| Method | Description |
|--------|-------------|
| `observer:set(...)` | Sets a property value and fires subscribed watchers. |
| `observer:get(...)` | Gets a property value, or nil if not set. |
| `observer:subscribe(...)` | Subscribes to changes on a property key (or "*" for all). |
| `observer:unsubscribe(...)` | Removes a subscription by id. |
| `observer:getCount(...)` | Returns the total number of active subscriptions. |

### `PriorityQueue` Methods

| Method | Description |
|--------|-------------|
| `priorityqueue:push(...)` | Inserts an item with a priority. Higher priorities are dequeued first. |
| `priorityqueue:pop(...)` | Removes and returns the highest-priority item, or nil if empty. |
| `priorityqueue:peek(...)` | Returns the highest-priority item without removing it, or nil if empty. |
| `priorityqueue:len(...)` | Returns the number of items in the queue. |
| `priorityqueue:isEmpty(...)` | Returns true when the queue has no items. |
| `priorityqueue:clearAll(...)` | Removes all items from the queue. |

### `Ring` Methods

| Method | Description |
|--------|-------------|
| `ring:push(...)` | Pushes a value (number or string) with an optional tag. Overwrites oldest on overflow. |
| `ring:latest(...)` | Returns the most recently pushed entry, or nil. |
| `ring:toArray(...)` | Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables. |
| `ring:sum(...)` | Returns the sum of all numeric values in the ring. |
| `ring:average(...)` | Returns the average of all numeric values, or 0 if empty. |
| `ring:len(...)` | Returns the number of entries currently in the ring. |
| `ring:isFull(...)` | Returns true when the ring is at capacity. |
| `ring:clear(...)` | Removes all entries from the ring. |

### `ServiceLocator` Methods

| Method | Description |
|--------|-------------|
| `servicelocator:provide(...)` | Registers a named service with an associated Lua value. |
| `servicelocator:locate(...)` | Retrieves a registered service by name; returns nil if not found. |
| `servicelocator:has(...)` | Returns true if a service with the given name is registered. |
| `servicelocator:remove(...)` | Unregisters and removes a named service. |
| `servicelocator:getServices(...)` | Returns a table of all registered service names. |
| `servicelocator:clearAll(...)` | Removes all registered services. |

### `SimpleState` Methods

| Method | Description |
|--------|-------------|
| `simplestate:addState(...)` | Registers a named state with optional enter, exit, and update callbacks. |
| `simplestate:transitionTo(...)` | Transitions to a named state, calling exit/enter callbacks as needed. |
| `simplestate:update(...)` | Calls the update callback of the current state with the given delta time. |
| `simplestate:getCurrent(...)` | Returns the name of the current state, or nil if none is active. |
| `simplestate:hasState(...)` | Returns true if a state with the given name is registered. |
| `simplestate:getStates(...)` | Returns a table of all registered state names. |
| `simplestate:clearAll(...)` | Removes all states and callbacks from this state machine. |

### `Throttle` Methods

| Method | Description |
|--------|-------------|
| `throttle:onFire(...)` | Sets the callback invoked when the throttle fires. |
| `throttle:update(...)` | Advances the timer by dt seconds; fires the callback if the interval elapsed. |
| `throttle:reset(...)` | Resets the elapsed counter without firing. |
| `throttle:getProgress(...)` | Returns the normalised progress through the current interval [0, 1]. |
| `throttle:getFireCount(...)` | Returns the total number of times this throttle has fired. |
| `throttle:setEnabled(...)` | Enables or disables the throttle. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.patterns.
if lurek.patterns then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 21 |
| `enum` | 1 |
| `fn` (Lua API) | 103 |
| **Total** | **125** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/patterns/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
