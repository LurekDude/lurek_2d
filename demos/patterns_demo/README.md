# Patterns Demo

Demonstrates six classic software design patterns implemented in Lua using Luna2D APIs: EventBus, ObjectPool, CommandStack, ServiceLocator, Factory, and SimpleState FSM.

## What It Demonstrates

- `luna.patterns.newEventBus()` — global event routing
- `luna.patterns.newObjectPool()` — reusable object recycling
- `luna.patterns.newCommandStack()` — undo/redo history
- `luna.patterns.newServiceLocator()` — dependency injection container
- `luna.patterns.newFactory()` — typed object creation
- `luna.patterns.newSimpleState()` — lightweight finite state machine
- Each pattern shown in action with live status display

## How to Run

```powershell
cargo run -- examples/patterns_demo
```

## Controls

| Key | Action |
|-----|--------|
| 1–6 | Activate each pattern's demo action |
| R | Reset all state |

## Notes

- Good reference for architecting larger Luna2D projects
- Each pattern occupies its own section of the screen with a label
