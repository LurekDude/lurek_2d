---
name: event-systems
description: "Load this skill when implementing event-driven patterns in Luna2D: EventQueue polling, Signal pub-sub, or decoupled communication between game systems. Skip it for engine callbacks (luna.update/draw), physics, or rendering."
---

# Event Systems — Luna2D Engine

## Load When

- Working with `luna.event.*` API for event polling
- Implementing Signal pub-sub patterns for decoupled communication
- Designing event-driven game architecture (observer, mediator)
- Choosing between callbacks and event queue polling
- Adding custom event types to the event system

## Owns

- `src/event/mod.rs` — EventQueue and EventArg types
- `src/event/signal.rs` — Signal pub-sub with handle-based subscriptions
- `src/lua_api/event_api.rs` — `luna.event.*` and `luna.signal.*` Lua bindings

## Does Not Cover

- Engine lifecycle callbacks (`luna.load`, `luna.update`, `luna.draw`) → use `game-loop` skill
- Input events (keypressed, mousepressed) → use `input-handling` skill
- Physics collision events → use `physics-engine` skill

## Live Repository Contracts

- `src/event/mod.rs` — `EventQueue`, `Event`, `EventArg` (FIFO queue)
- `src/event/signal.rs` — `Signal` (handle-based pub-sub)

## Decision Rules

- **EventQueue is FIFO** — events polled in insertion order; first-in-first-out
- **EventArg supports four types** — `Str(String)`, `Num(f64)`, `Bool(bool)`, `Nil`
- **Signal handles are monotonic** — each subscription gets a unique, incrementing handle
- **Callbacks vs EventQueue**: Engine callbacks (`luna.keypressed`) fire immediately; EventQueue stores events for later polling in `luna.update()`
- **Signal is pub-sub**: Multiple listeners can subscribe to the same signal; all fire on emit
- **Event names are strings** — use lowercase, descriptive names (`"player_died"`, `"item_collected"`)

## When to Use What

| Pattern | Mechanism | Best For |
|---|---|---|
| Immediate reaction | Engine callbacks (`luna.keypressed`) | Input handling, frame updates |
| Deferred processing | EventQueue (`luna.event.push/poll`) | Game events processed in update loop |
| Decoupled broadcast | Signal (`luna.signal.emit/on`) | Multi-listener notifications |
| One-to-one message | EventQueue with filtered polling | Specific system communication |

## Best Practices

- Use EventQueue for game-level events (player actions, world state changes)
- Use Signal for broadcast notifications (score changed, level completed)
- Poll EventQueue in `luna.update()` — never in `luna.draw()`
- Keep event names consistent — establish a naming convention early
- Clear EventQueue each frame if not processing all events — prevent unbounded growth

## Anti-Patterns

- **Event soup**: Pushing dozens of event types without naming convention — establish categories
- **Polling in draw**: Processing EventQueue during `luna.draw()` — state mutations belong in `luna.update()`
- **Unbounded queue**: Never polling events — queue grows without limit
- **Signal for everything**: Using Signal where a direct function call suffices — Signal adds overhead
- **Forgetting unsubscribe**: Accumulating Signal listeners without removing old ones
