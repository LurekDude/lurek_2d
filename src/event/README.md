# `src/event/` — Custom Event Queue

## Purpose

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

### How It Works

The bus stores listeners as a `Vec<Listener>` sorted by priority at
subscription time.  `emit(name, data)` iterates the sorted list and skips
entries marked dead without removing them inline — removal is batched at the
next `cleanup()` call to avoid iterator-invalidation bugs during emission.

Event data is passed as an `Option<LuaTable>` — `None` for pure signals that
carry no payload, `Some(table)` for rich events.  The bus holds a
`mlua::RegistryKey` per listener closure so stored Lua functions survive GC
cycles between frames.  Unsubscribing via the returned subscription ID drops
the registry key, allowing the Lua closure to be collected on the next GC pass.

One-shot listeners are marked dead after firing in the same `emit()` pass,
so they are never double-fired even if two emissions happen before the next
cleanup.  Priority 0 is the default; negative priorities fire before the
default group, positive priorities fire after — useful for "run physics
response before cosmetic particle effects".

### Dependency Direction

```
event/ ──────► (none)
```

**Leaf module** — zero dependencies. Pure data structures.

---

## File-by-File Analysis

### `mod.rs` — Event System (Single File Module)

**~70 lines** | Complete event queue implementation.

#### Enum: `EventArg`

```rust
pub enum EventArg {
    Str(String),
    Num(f64),
    Bool(bool),
    Nil,
}
```

#### Struct: `Event`

```rust
pub struct Event {
    pub name: String,
    pub args: Vec<EventArg>,
}
```

#### Struct: `EventQueue`

```rust
pub struct EventQueue {
    queue: VecDeque<Event>,
}
```

Methods: `new`, `push(name, args)`, `poll() → Option<Event>`, `clear()`, `len()`,
`is_empty()`.

**Design**: Simple FIFO queue using `VecDeque`. No priority, no filtering, no
subscriber patterns — kept intentionally minimal for Lua game scripts that
poll events per frame.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/event_api.rs`, exposing the queue under
`luna.event.*`.

### Usage from Lua

```lua
-- Push custom events
luna.event.push("player_died", "Player1", 42)
luna.event.push("level_complete")

-- Poll events in update loop
function luna.update(dt)
    while true do
        local event = luna.event.poll()
        if not event then break end
        if event.name == "player_died" then
            -- handle death
        end
    end
end
```
