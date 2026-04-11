# `event` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Core Runtime |
| **Status** | Implemented |
| **Lua API** | `lurek.event` |
| **Source** | `src/event/` |
| **Rust Tests** | `tests/rust/unit/event_tests.rs`, plus inline unit coverage in `src/event/event_queue.rs` and `src/event/signal.rs` |
| **Lua Tests** | `tests/lua/unit/test_event.lua`, `tests/lua/integration/test_audio_event.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Core Runtime` |

---

## Summary

The event module gives Lurek2D two lightweight messaging primitives: a FIFO event queue for polling named events and a handle-based signal dispatcher for callback-style fan-out. It exists so gameplay code can communicate across systems without introducing direct ownership or import dependencies between those systems.

The queue side is about ordered delivery and explicit consumption. Engine or gameplay code can push named events with primitive payload values, and scripts can poll or wait for them later. The signal side is about local pub-sub: listeners subscribe by name, get handles back, and can be removed or cleared without needing a full feature-rich event bus.

This module intentionally does not own OS input capture, scene transitions, or higher-order event orchestration policies. Hardware events originate in `input` and the app loop, richer callback patterns live under `patterns`, and Lua registry management for callbacks belongs in `src/lua_api/event_api.rs` rather than in the core `event` data structures.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Core Runtime responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.event.* (Lua API — src/lua_api/event_api.rs)
    |
    v
src/event/mod.rs
    |- event_queue.rs - event_queue
    |- signal.rs - signal
```

---

## Source Files

| File | Purpose |
|------|---------|
| `event_queue.rs` | Event types and FIFO event queue. |
| `mod.rs` | Event queue for polling system and custom events. |
| `signal.rs` | Handle-based pub-sub signal system. |

---

## Submodules

### `event::event_queue`

Event types and FIFO event queue.

- **`EventArg`** (enum): Argument values that can be attached to events.
- **`Event`** (struct): A single event in the event queue.
- **`EventQueue`** (struct): FIFO event queue for system and custom events.

### `event::signal`

Handle-based pub-sub signal system.

- **`Subscription`** (struct): A single subscription entry in a [`Signal`].
- **`Signal`** (struct): Handle-based pub-sub signal dispatcher.

---

## Key Types

### Public Types

#### `EventArg`

Argument values that can be attached to events.

#### `Event`

A single event in the event queue.

#### `EventQueue`

FIFO event queue for system and custom events.

#### `Subscription`

A single subscription entry in a [`Signal`].

#### `Signal`

Handle-based pub-sub signal dispatcher.

---

## Lua API

Exposed under `lurek.event.*` by `src/lua_api/event_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.event.exit` | Pushes an exit event, requesting the engine to stop. |
| `lurek.event.push` | Pushes a custom event onto the event queue. |
| `lurek.event.poll` | Returns an iterator function that pops events from the queue. |
| `lurek.event.clear` | Discards all pending events in the queue. |
| `lurek.event.newSignal` | Creates a new pub-sub Signal dispatcher. |
| `lurek.event.pump` | Syncs OS-level events into the queue (no-op in Lurek2D push model). |
| `lurek.event.wait` | Blocks until the next event arrives or the optional timeout elapses. |
| `lurek.event.restart` | Requests that the engine restart at the beginning of the next frame. |
| `lurek.event.quit` | Alias for `exit()` — requests the engine to stop at the end of the current frame. |

### `Signal` Methods

| Method | Description |
|--------|-------------|
| `signal:emit(...)` | Emits the named event, calling all registered callbacks with extra arguments. |
| `signal:remove(...)` | Removes a subscription by handle ID. |
| `signal:clear(...)` | Removes all callbacks for the named event. |
| `signal:clearAll(...)` | Removes all callbacks across all events. |
| `signal:getCount(...)` | Returns the callback count for the named event. |
| `signal:getTotalCount(...)` | Returns the total callback count across all events. |
| `signal:type(...)` | Returns the type name of this object. |
| `signal:typeOf(...)` | Returns true if the given type name matches this object's type or any parent type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.event.
if lurek.event then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 1 |
| `fn` (Lua API) | 17 |
| **Total** | **22** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/event/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
