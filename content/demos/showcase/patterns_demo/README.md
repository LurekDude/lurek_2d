# Patterns Demo

Demonstrates six classic software design patterns implemented in Lua using Lurek2D APIs: EventBus, ObjectPool, CommandStack, ServiceLocator, Factory, and SimpleState FSM.

## What It Demonstrates

- `lurek.patterns.newEventBus()` — global event routing
- `lurek.patterns.newObjectPool()` — reusable object recycling
- `lurek.patterns.newCommandStack()` — undo/redo history
- `lurek.patterns.newServiceLocator()` — dependency injection container
- `lurek.patterns.newFactory()` — typed object creation
- `lurek.patterns.newSimpleState()` — lightweight finite state machine
- Each pattern shown in action with live status display

## How to Run

```powershell
cargo run -- content/demos/patterns_demo
```

## Controls

| Key | Action |
|-----|--------|
| 1–6 | Activate each pattern's demo action |
| R | Reset all state |

## Notes

- Good reference for architecting larger Lurek2D projects
- Each pattern occupies its own section of the screen with a label
