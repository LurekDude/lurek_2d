# event

## General Info

- Module group: `Core Runtime`
- Source path: `src/event/`
- Lua API path(s): `src/lua_api/event_api.rs`
- Primary Lua namespace: `lurek.event`
- Rust test path(s): tests/rust/unit/event_tests.rs, plus inline unit coverage in src/event/event_queue.rs and src/event/signal.rs
- Lua test path(s): tests/lua/unit/test_event.lua, tests/lua/integration/test_audio_event.lua

## Summary

The `event` module provides Lurek2D's centralised event queue — the single channel through which OS input, window state changes, custom Lua events, and automation-injected synthetic input flow before being dispatched to Lua callbacks. All modules that raise or consume events route through this module rather than coupling directly to each other.

The core type is `EventQueue`, a double-buffered ring of `Event` values. `App` pushes events during the winit event handler; at the start of each logical-update tick the queue is drained and dispatched to the registered Lua listeners (key-down, key-up, mouse-move, etc.). Double-buffering means that events raised during a tick dispatch do not affect the same tick — they accumulate in the pending buffer and are visible on the next tick. This prevents re-entrant event-handling hazards.

`Event` is a flat tagged enum that covers: keyboard events (key code, scancode, modifiers, repeat flag), mouse events (button, position, scroll delta), gamepad events (axis, button, device ID), text input (Unicode character), window events (resize, focus, close, file-drop), touch events, and user-defined events (`UserEvent` with a string key and an optional Lua value payload). The user event variant is what `lurek.event.emit(name, data)` uses to implement the publish-subscribe pattern between Lua scripts.

The `automation` module also injects synthetic events into the queue through the same `push()` path as real hardware events, which is what makes automation playback transparent to downstream callbacks.

Because the event queue is shared via `Rc<RefCell<EventQueue>>` inside `SharedState`, it is only safe to access on the main thread. Background threads that need to communicate use `lurek.thread.Channel` instead.

The `EventBus` has been extended with deferred-dispatch support: `push_deferred(event)` enqueues an event into a pending buffer that is only merged into the main queue on an explicit `flush()` call, and `drain()` consumes all pending deferred events without dispatching them. Lua scripts access these through `lurek.event.pushDeferred(name, data)` and `lurek.event.flush()`, enabling batched event delivery patterns where multiple events should be committed as a group or discarded atomically.

**Scope boundary**: Core Runtime tier. No upstream engine dependencies. Lua bridge handled through `app` dispatch.

## Files

- `event_queue.rs`: Event types and FIFO event queue.
- `mod.rs`: Event queue for polling system and custom events.
- `signal.rs`: Handle-based pub-sub signal system with exact-name and glob-wildcard subscriptions.

## Types

- `EventArg` (`enum`, `event_queue.rs`): Argument values that can be attached to events.
- `Event` (`struct`, `event_queue.rs`): A single event in the event queue.
- `EventQueue` (`struct`, `event_queue.rs`): FIFO event queue for system and custom events.
- `Subscription` (`struct`, `signal.rs`): A single subscription entry in a [`Signal`].
- `Signal` (`struct`, `signal.rs`): Handle-based pub-sub signal dispatcher.

## Functions

- `EventQueue::new` (`event_queue.rs`): Create a new empty event queue.
- `EventQueue::push` (`event_queue.rs`): Push an event onto the queue.
- `EventQueue::push_event` (`event_queue.rs`): Push an event by name and arguments.
- `EventQueue::poll` (`event_queue.rs`): Poll the next event from the queue.
- `EventQueue::clear` (`event_queue.rs`): Clear all events from the queue.
- `EventQueue::is_empty` (`event_queue.rs`): Check if the queue is empty.
- `EventQueue::len` (`event_queue.rs`): Get the number of events in the queue.
- `EventQueue::pump` (`event_queue.rs`): Drains pending OS-level events into the queue (no-op in Lurek2D; documents as a sync point).
- `EventQueue::wait` (`event_queue.rs`): Blocks until an event is available or `timeout_ms` milliseconds elapse.
- `EventArg::from_lua_val` (`event_queue.rs`): Converts a [`LuaValue`] to an [`EventArg`] for event queue storage.
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
- `lurek.event.exit`: Pushes an exit event, requesting the engine to stop.
- `lurek.event.poll`: Returns an iterator function that pops events from the queue.
- `lurek.event.clear`: Discards all pending events in the queue.
- `lurek.event.newSignal`: Creates a new pub-sub Signal dispatcher.
- `lurek.event.pump`: Syncs OS-level events into the queue (no-op in Lurek2D push model).
- `lurek.event.wait`: Blocks until the next event arrives or the optional timeout elapses.
- `lurek.event.restart`: Requests that the engine restart at the beginning of the next frame.
- `lurek.event.quit`: Alias for `exit()` — requests the engine to stop at the end of the current frame.
- `lurek.event.pushDeferred`: Pushes a named event to the deferred buffer; it will not reach the main queue
- `lurek.event.flushDeferred`: Moves all buffered deferred events into the main event queue and clears the buffer.
- `lurek.event.enableHistory`: Enables event history recording, keeping the last `capacity` pushed events.
- `lurek.event.getHistory`: Returns an array of recent events as `{name, args}` tables.
- `lurek.event.clearHistory`: Clears all recorded event history.
- `lurek.event.push`: Adds an event item to the end of the event queue for processing.

### `Signal` Methods
- `Signal:emit`: Emits the named event, calling all registered callbacks with extra arguments.
- `Signal:remove`: Removes a subscription by handle ID.
- `Signal:clear`: Removes all callbacks for the named event.
- `Signal:clearAll`: Removes all callbacks across all events.
- `Signal:getCount`: Returns the callback count for the named event.
- `Signal:getTotalCount`: Returns the total callback count across all events.
- `Signal:type`: Returns the type name of this object.
- `Signal:typeOf`: Returns true if the given type name matches this object's type or any parent type.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/event/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- **Wildcard semantics**: `*` matches any sequence of characters (excluding `/`); `?` matches exactly one character. Wildcard patterns are stored separately in `wildcard_subs: Vec<(String, u64)>` and evaluated via `glob_match` on every `emit` call after the exact-name callbacks have fired.
