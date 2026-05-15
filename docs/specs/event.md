# event

## General Info

- Module group: `Core Runtime`
- Source path: `src/event/`
- Lua API path(s): `src/lua_api/event_api.rs`
- Primary Lua namespace: `lurek.event`
- Rust test path(s): tests/rust/unit/event_tests.rs
- Lua test path(s): tests/lua/unit/test_event.lua, tests/lua/integration/test_audio_event.lua

## Summary

The `event` module is Lurek2D's centralized queue and signal dispatch layer. It owns queue storage, queue ordering semantics, queue wait behavior, and the `Signal` pub-sub primitive used by Lua scripts through `lurek.event`.

Event queue behavior:
- `EventQueue` is a dual-lane FIFO (`high` and `normal`) backed by `VecDeque`.
- `poll()` always drains `high` before `normal`, while keeping FIFO order inside each lane.
- `wait(timeout_ms)` blocks on a condvar wake path (no spin loop), returning an event immediately when available.
- `pump()` is intentionally a no-op in Lurek2D and exists for API parity.

Payload behavior:
- `Event` payload is `Vec<EventArg>`.
- `EventArg` supports scalar values plus shallow-cloned table payloads.
- Table payload conversion stores only scalar keys (`string`, `number`, `boolean`) and scalar values; nested tables are not deep-cloned.

Lua-facing API behavior:
- Queue APIs: `poll`, `wait`, `clear`, `push`, `pushPriority`, `pushDeferred`, `pushDeferredPriority`, `flushDeferred`.
- Runtime control APIs: `exit`, `quit`, `restart`.
- History APIs: `enableHistory`, `getHistory`, `clearHistory`.
- Signal factory: `newSignal()` returning `LSignal` with methods `register`, `emit`, `remove`, `clear`, `clearAll`, `getCount`, `getTotalCount`, `once`, `registerWithFilter`, `connect`, `type`, `typeOf`.

Scope boundary:
- Core Runtime tier module with thin Lua bridge in `src/lua_api/event_api.rs`.
- OS/window/input events are pushed from `app`; synthetic events are pushed by `automation`.
- Cross-thread messaging is out of scope for this module and belongs to `lurek.thread.Channel`.

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

- `EventQueue::new` (`event_queue.rs`): Creates an empty event queue with fresh wait state.
- `EventQueue::push` (`event_queue.rs`): Enqueues an event at normal priority.
- `EventQueue::push_with_priority` (`event_queue.rs`): Enqueues an event into the queue selected by the supplied priority.
- `EventQueue::push_event` (`event_queue.rs`): Constructs and enqueues a normal-priority event from raw parts.
- `EventQueue::push_event_with_priority` (`event_queue.rs`): Constructs and enqueues an event from raw parts using the supplied priority.
- `EventQueue::poll` (`event_queue.rs`): Pops the next event, preferring the high-priority queue.
- `EventQueue::clear` (`event_queue.rs`): Removes every pending event from both priority queues.
- `EventQueue::is_empty` (`event_queue.rs`): Returns whether both priority queues are empty.
- `EventQueue::len` (`event_queue.rs`): Returns the total number of pending events across both queues.
- `EventQueue::pump` (`event_queue.rs`): Placeholder pump hook kept for API symmetry.
- `EventQueue::wait` (`event_queue.rs`): Waits for queue activity until timeout and then returns the next event if one is available.
- `EventArg::from_lua_val` (`event_queue.rs`): Converts a Lua value into the shallow event payload representation.
- `event_arg_to_lua_value` (`event_queue.rs`): Converts an `EventArg` back to a Lua value.
- `event_to_lua_multi` (`event_queue.rs`): Converts an [`Event`] into a Lua multi-value (name followed by args).
- `Signal::new` (`signal.rs`): Creates an empty signal registry.
- `Signal::subscribe` (`signal.rs`): Registers a subscription for one exact signal name and returns its id.
- `Signal::remove` (`signal.rs`): Removes a subscription id from exact-name and wildcard storage.
- `Signal::clear` (`signal.rs`): Removes every exact-name subscription registered for the given signal name.
- `Signal::clear_all` (`signal.rs`): Removes every stored subscription and returns the number removed.
- `Signal::get_handles` (`signal.rs`): Returns the subscription ids registered for one exact signal name.
- `Signal::get_count` (`signal.rs`): Returns the number of subscriptions registered for one exact signal name.
- `Signal::get_total_count` (`signal.rs`): Returns the total number of registered subscriptions.
- `Signal::subscribe_wildcard` (`signal.rs`): Registers a wildcard subscription pattern and returns its id.
- `Signal::get_wildcard_handles` (`signal.rs`): Returns wildcard subscription ids whose pattern matches the signal name.
- `Signal::is_wildcard` (`signal.rs`): Returns whether a subscription name contains wildcard metacharacters.

## Lua API Reference

- Binding path(s): `src/lua_api/event_api.rs`
- Namespace: `lurek.event`

### Module Functions
- `lurek.event.exit`: Requests engine shutdown with an optional process exit code.
- `lurek.event.poll`: Creates a polling function that returns the next queued event each time it is called.
- `lurek.event.clear`: Clears all pending events from the shared event queue.
- `lurek.event.newSignal`: Creates an isolated signal dispatcher for Lua callbacks.
- `lurek.event.pump`: Pumps the shared event queue without removing events for Lua.
- `lurek.event.wait`: Waits for the next queued event and returns success, name, and argument table.
- `lurek.event.restart`: Requests an engine restart.
- `lurek.event.quit`: Requests engine shutdown with exit code zero.
- `lurek.event.pushDeferred`: Adds a normal-priority event to the deferred buffer instead of the live queue.
- `lurek.event.pushDeferredPriority`: Adds an event with explicit priority to the deferred buffer.
- `lurek.event.flushDeferred`: Moves all deferred events into the shared event queue and clears the deferred buffer.
- `lurek.event.enableHistory`: Enables event push history with a maximum retained capacity.
- `lurek.event.getHistory`: Returns retained pushed event history entries.
- `lurek.event.clearHistory`: Clears retained pushed event history.
- `lurek.event.push`: Pushes a normal-priority event into the shared event queue and optional history.
- `lurek.event.pushPriority`: Pushes an event with explicit priority into the shared event queue and optional history.

### `LSignal` Methods
- `LSignal:register`: Registers a callback for an exact signal event name.
- `LSignal:emit`: Emits a signal event and invokes matching callbacks with the remaining arguments.
- `LSignal:remove`: Removes a signal callback by subscription handle.
- `LSignal:clear`: Removes all callbacks registered for one exact signal event name.
- `LSignal:clearAll`: Removes every callback from this signal object.
- `LSignal:getCount`: Returns the callback count for one exact signal event name.
- `LSignal:getTotalCount`: Returns the total callback count across all signal event names.
- `LSignal:once`: Registers a callback that is removed after its next matching emission.
- `LSignal:registerWithFilter`: Registers a callback that runs only when a filter callback returns true.
- `LSignal:connect`: Registers a callback for an exact name or wildcard signal pattern.
- `LSignal:type`: Returns the Lua-visible type name for this signal handle.
- `LSignal:typeOf`: Returns whether this signal handle matches a supported type name.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/event/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- **Wildcard semantics**: `*` matches any sequence of characters (excluding `/`); `?` matches exactly one character. Wildcard patterns are stored separately in `wildcard_subs: Vec<(String, u64)>` and evaluated via `glob_match` on every `emit` call after the exact-name callbacks have fired.
