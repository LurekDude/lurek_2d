# Signal Demo

Demonstrates the pub-sub `luna.event.newSignal()` system for decoupled event-driven communication between game systems.

## What It Demonstrates

- `luna.event.newSignal()` — create a typed signal bus
- `signal:connect(fn)` — subscribe a handler
- `signal:fire(...)` — publish an event to all subscribers
- `signal:disconnect(id)` — unsubscribe a handler by ID
- Combo chain: multiple connected handlers updating score and combo multiplier
- Log display: rendering a scrolling event history

## How to Run

```powershell
cargo run -- examples/signal_demo
```

## Controls

| Key | Action |
|-----|--------|
| Space | Fire a "hit" event |
| C | Clear the event log |

## Notes

- Shows how signals replace direct function calls for loose coupling
- Multiple handlers can respond to the same signal independently
