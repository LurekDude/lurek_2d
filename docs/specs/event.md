# event

## General Info

- Module group: `Core Runtime`
- Source path: `src/event/`
- Lua API path(s): `src/lua_api/event_api.rs`
- Primary Lua namespace: `lurek.event`
- Rust test path(s): tests/rust/unit/event_tests.rs, plus inline unit coverage in src/event/event_queue.rs and src/event/signal.rs
- Lua test path(s): tests/lua/unit/test_event.lua, tests/lua/integration/test_audio_event.lua

## Summary

The `event` module is Lurek2D's centralised event queue — the single channel through which OS input, window state changes, custom Lua events, and automation-injected synthetic input flow before being dispatched to Lua callbacks. It is a Core Runtime tier module with no upstream engine dependencies. All modules that raise or consume events route through this module rather than coupling directly to each other.

**EventQueue — dual-lane FIFO.** `EventQueue` uses two FIFO lanes (`high`, `normal`) backed by `VecDeque`. `poll()` always drains the high lane before the normal lane while preserving FIFO order inside each lane. `push(event)`, `push_with_priority(event, priority)`, `push_event(name, args)`, `push_event_with_priority(name, args, priority)`, `poll()`, `clear()`, `is_empty()`, `len()`. The `wait(timeout_ms)` variant sleeps on a condvar-backed notifier and wakes when new events arrive or timeout expires.

**Event payload model.** `Event` carries `name: String` and `args: Vec<EventArg>`. `EventArg` supports scalar values plus `Table` for shallow-cloned Lua tables (string/number/bool keys; scalar values). This allows Lua producers to pass structured payloads without serialization.

**Deferred dispatch.** The `EventBus` supports deferred batching: `push_deferred(event)` enqueues into a pending buffer; `flush()` atomically merges the buffer into the main queue; `drain()` discards the pending buffer without dispatching. This enables patterns where multiple events are committed as a group or discarded atomically — useful for undo/redo stacks and transaction-like game-state updates. Lua: `lurek.event.pushDeferred(name, data)`, `lurek.event.flush()`.

**Signal — handle-based pub-sub.** `Signal` is a separate pub-sub dispatcher providing handle-based subscriptions with exact-name and glob-wildcard matching. `subscribe(event_name, handler) → handle_id`, `remove(handle_id)`, `clear(event_name)`, `clear_all()`. Glob subscriptions (`"enemy.*"`) match any event whose name begins with the prefix. The Signal is Lua-accessible via `lurek.event.newSignal()`, providing scoped pub-sub within a module without routing through the global queue.

**Automation integration.** The `automation` module injects synthetic events through the same `push()` path as real hardware events, making playback transparent to downstream callbacks — a key property for deterministic test replay.

**Threading note.** `EventQueue` is shared via `Rc<RefCell<EventQueue>>` inside `SharedState` and is only safe on the main thread. Background threads communicate via `lurek.thread.Channel` instead.

**Lua surface.** `lurek.event.emit(name, data)` — emit a custom event. `lurek.event.on(name, callback) → handle` — subscribe. `lurek.event.off(handle)` — unsubscribe. `lurek.event.once(name, callback)` — subscribe for one delivery. `lurek.event.pushDeferred(name, data)`, `flush()`. `lurek.event.newSignal()` → `Signal` userdata: `subscribe(name, fn)`, `remove(handle)`, `clear(name)`, `clearAll()`, `fire(name, ...)`.

**Scope boundary.** Core Runtime tier. No upstream engine dependencies. Lua bridge in `src/lua_api/event_api.rs`; OS event dispatch via `app` module.

## Files

- `event_queue.rs`: Event types and FIFO event queue.
- `mod.rs`: Event queue for polling system and custom events.
- `signal.rs`: Handle-based pub-sub signal system with exact-name and glob-wildcard subscriptions.

## Types

- `EventPriority` (`enum`, `event_queue.rs`): Queue lane used during enqueue (`High` or `Normal`).
- `EventTableKey` (`enum`, `event_queue.rs`): Allowed key types for table payload cloning.
- `EventArg` (`enum`, `event_queue.rs`): Argument values that can be attached to events.
- `Event` (`struct`, `event_queue.rs`): A single event in the event queue.
- `EventQueue` (`struct`, `event_queue.rs`): FIFO event queue for system and custom events.
- `Subscription` (`struct`, `signal.rs`): A single subscription entry in a [`Signal`].
- `Signal` (`struct`, `signal.rs`): Handle-based pub-sub signal dispatcher.

## Functions

- `EventQueue::new` (`event_queue.rs`): Create a new empty event queue.
- `EventQueue::push` (`event_queue.rs`): Push an event onto the queue.
- `EventQueue::push_with_priority` (`event_queue.rs`): Push an event with explicit lane selection.
- `EventQueue::push_event` (`event_queue.rs`): Push an event by name and arguments.
- `EventQueue::push_event_with_priority` (`event_queue.rs`): Push an event by name/args to an explicit lane.
- `EventQueue::poll` (`event_queue.rs`): Poll the next event from the queue.
- `EventQueue::clear` (`event_queue.rs`): Clear all events from the queue.
- `EventQueue::is_empty` (`event_queue.rs`): Check if the queue is empty.
- `EventQueue::len` (`event_queue.rs`): Get the number of events in the queue.
- `EventQueue::pump` (`event_queue.rs`): Drains pending OS-level events into the queue (no-op in Lurek2D; documents as a sync point).
- `EventQueue::wait` (`event_queue.rs`): Blocks until an event is available or `timeout_ms` milliseconds elapse.
- `EventArg::from_lua_val` (`event_queue.rs`): Converts a [`LuaValue`] to an [`EventArg`] for event queue storage.
- `event_arg_to_lua_value` (`event_queue.rs`): Converts an `EventArg` back to a Lua value.
- `event_to_lua_multi` (`event_queue.rs`): Converts an [`Event`] into a Lua multi-value (name followed by args).
- `Signal::new` (`signal.rs`): Creates a new empty signal dispatcher.
- `Signal::subscribe` (`signal.rs`): Registers a subscription for the given event name.
- `Signal::remove` (`signal.rs`): Removes a subscription by its handle ID.
- `Signal::clear` (`signal.rs`): Removes all subscriptions for the given event name.
- `Signal::clear_all` (`signal.rs`): Removes all subscriptions across all event names.
- `Signal::get_handles` (`signal.rs`): Returns the handles registered for the given event name (in registration order).
- `Signal::get_count` (`signal.rs`): Returns the number of subscriptions for the given event name.
- `Signal::get_total_count` (`signal.rs`): Returns the total number of subscriptions across all event names.
- `Signal::subscribe_wildcard` (`signal.rs`): Registers a wildcard pattern subscription.
- `Signal::get_wildcard_handles` (`signal.rs`): Returns all wildcard handles whose pattern matches the given event name.
- `Signal::is_wildcard` (`signal.rs`): Returns `true` if `pattern` contains glob metacharacters (`*` or `?`).

## Lua API Reference

- Binding path(s): `src/lua_api/event_api.rs`
- Namespace: `lurek.event`

### Module Functions
- `lurek.event.exit`: Pushes an exit event onto the engine event queue, requesting a graceful shutdown at the end of the current frame.
- `lurek.event.poll`: Returns an iterator function that pops events one at a time from the engine event queue.
- `lurek.event.clear`: Discards every pending event in the engine event queue without processing them.
- `lurek.event.newSignal`: Creates and returns a new independent Signal pub-sub dispatcher.
- `lurek.event.pump`: Synchronises OS-level windowing events into the engine event queue.
- `lurek.event.wait`: Blocks the current thread until the next engine event arrives or the optional timeout elapses.
- `lurek.event.restart`: Requests that the engine perform a full restart at the beginning of the next frame.
- `lurek.event.quit`: Alias for `exit()` - requests the engine to stop gracefully at the end of the current frame with exit code 0.
- `lurek.event.pushDeferred`: Pushes a named event into the deferred buffer instead of the main queue.
- `lurek.event.pushDeferredPriority`: Pushes a named deferred event with explicit queue lane priority.
- `lurek.event.flushDeferred`: Moves all events from the deferred buffer into the main engine event queue and clears the buffer.
- `lurek.event.enableHistory`: Enables event history recording, keeping a ring buffer of the last `capacity` events pushed via `push()`.
- `lurek.event.getHistory`: Returns an array of recently pushed events as tables.
- `lurek.event.clearHistory`: Clears all recorded event history entries from the ring buffer.
- `lurek.event.push`: Pushes a custom named event onto the main engine event queue with optional payload arguments.
- `lurek.event.pushPriority`: Pushes a custom named event onto an explicit queue lane (`high` or `normal`).

### `LSignal` Methods
- `LSignal:register`: Registers a Lua callback function for the named event and returns a numeric handle ID.
- `LSignal:emit`: Fires all callbacks registered for the named event, passing any extra arguments to each callback function.
- `LSignal:remove`: Removes a previously registered subscription identified by its numeric handle.
- `LSignal:clear`: Removes every callback registered for the specified event name and releases their Lua registry entries.
- `LSignal:clearAll`: Removes every callback across all event names in this Signal instance, effectively resetting it to an empty state.
- `LSignal:getCount`: Returns the number of callbacks currently registered for the specified event name.
- `LSignal:getTotalCount`: Returns the total number of callbacks registered across all event names in this Signal instance.
- `LSignal:once`: Registers a one-shot callback that fires at most once for the named event and then automatically removes itself.
- `LSignal:registerWithFilter`: Registers a callback with an associated filter predicate function.
- `LSignal:connect`: Subscribes to an event name or wildcard glob pattern and returns a handle.
- `LSignal:type`: Returns the string type name of this userdata object.
- `LSignal:typeOf`: Returns true if the given type name matches this object's type or any parent type.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/event/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- **Wildcard semantics**: `*` matches any sequence of characters (excluding `/`); `?` matches exactly one character. Wildcard patterns are stored separately in `wildcard_subs: Vec<(String, u64)>` and evaluated via `glob_match` on every `emit` call after the exact-name callbacks have fired.
