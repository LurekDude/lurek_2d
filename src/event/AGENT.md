# `event` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.event` |
| **Source** | `src/event/` |
| **Tests** | `tests/event_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_event.lua` |

## Summary

The event module implements a lightweight publish/subscribe message bus that
decouples game systems from one another.  A game system emits a named event
with an optional Lua-table payload; any number of listeners registered for
that name receive the payload in priority order.  This lets systems like UI,
camera, analytics, and audio all respond to gameplay events ("player_died",
"item_collected", "level_complete") without knowing about each other or the
system that originated the event.

Two bus scopes exist to prevent cross-scene event leakage: a global `GameBus`
that lives for the entire session, and a `SceneBus` that is automatically
flushed when the active scene is popped from the stack, so listeners
registered for a gameplay scene cannot fire during the title screen.
Subscriptions may be permanent, one-shot (auto-unsubscribed after the first
firing), or priority-ordered to control call sequence when multiple unrelated
systems handle the same event name.

## Architecture

```
EventQueue (FIFO queue)
  │
  ├── push(name, args) ── enqueue event
  ├── poll() ── dequeue next event
  └── clear() ── drain all events
  │
  Event { name: String, args: Vec<EventArg> }
  │
  EventArg ── Str(String) | Num(f64) | Bool(bool) | Nil
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | EventArg, Event, and EventQueue — core FIFO event queue |
| `signal.rs` | Handle-based pub-sub signal system |

## Submodules

### `event::mod`

Core FIFO event queue for named game events with typed arguments.

- **`EventArg`** (enum): Typed argument that can accompany an event. Variants: `Str(String)`, `Num(f64)`, `Bool(bool)`, `Nil`.
- **`Event`** (struct): A single event in the queue. Fields: `name: String`, `args: Vec<EventArg>`. Represents one named occurrence with optional payload.
- **`EventQueue`** (struct): FIFO queue for buffering events between game systems. Fields: `events: VecDeque<Event>`. Methods: `new()`, `push(event)`, `push_event(name, args)`, `poll() → Option<Event>`, `clear()`, `is_empty()`, `len()`.

### `event::signal`

Handle-based pub-sub signal system.

- **`Subscription`** (struct): A single subscription entry in a [`Signal`].
- **`Signal`** (struct): Handle-based pub-sub signal dispatcher. Consult the module-level documentation for the broader usage context and...

## Key Types

### Structs

#### `event::Event`

A single event in the event queue. Consult the module-level documentation for the broader usage context and...

#### `event::EventQueue`

FIFO event queue for system and custom events.

#### `event::signal::Signal`

Handle-based pub-sub signal dispatcher. Consult the module-level documentation for the broader usage context and...

#### `event::signal::Subscription`

A single subscription entry in a [`Signal`].

### Enums

#### `event::EventArg`

Argument values that can be attached to events.

## Lua API

Exposed under `luna.event.*` by `src/lua_api/event_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `struct` | 4 |
| **Total** | **5** |

