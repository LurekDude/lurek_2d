# `timer` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.timer` |
| **Source** | `src/timer/` |
| **Tests** | `tests/timer_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_timer.lua` |

## Summary

The timer module provides two orthogonal timing mechanisms that together cover
all time-related needs in a game loop.  `Clock` measures wall-clock time: it
tracks frame delta (elapsed seconds since the last tick), total elapsed time
since game start, rolling FPS computed over a 1-second sliding window, and a
60-frame rolling average delta useful for smooth HUD display of frame time.
The `dt` that `luna.update(dt)` receives is the `Clock`'s last-tick delta.

`Scheduler` handles game-logic timing — "execute something after 3 seconds"
and "repeat something every 0.5 seconds for 10 iterations".  Unlike the raw
clock, the Scheduler's perceived time is affected by a `time_scale` multiplier
that the game controls: set it to 0.0 for a full pause, 0.5 for slow-motion
bullet-time, or 2.0 for fast-forward.  Named events replace existing events
with the same name, preventing timer accumulation when setup code runs
repeatedly on scene re-entry.  Per-event pause and resume allow individual
timers to be suspended without stopping the entire scheduler.

## Architecture

```
timer/
  │
  ├── Clock ── frame timing
  │     ├── tick() → delta time (f64 seconds)
  │     ├── delta() → last frame delta
  │     ├── total() → total elapsed time
  │     ├── fps() → frames per second (rolling 1-second window)
  │     ├── frame_count() → total frames
  │     └── average_delta() → rolling average over 60 frames
  │
  └── Scheduler ── timed event system
        ├── after(delay, one_shot) → fire once after delay
        ├── every(interval, count) → fire repeatedly at interval
        ├── Named variants → replace existing by name
        ├── cancel / cancel_all / cancel_named
        ├── pause / resume per-event
        ├── time_scale (0.0–100.0) — global speed multiplier
        └── update(dt) → Vec<u32> (fired event IDs)
```

## Source Files

| File | Purpose |
|------|---------|
| `clock.rs` | Clock implementation for the `timer` subsystem |
| `scheduler.rs` | Scheduled event manager for delayed and repeating timed callbacks |

## Submodules

### `timer::clock`

Clock implementation for the `timer` subsystem.

- **`Clock`** (struct): Tracks per-frame delta time, accumulated total time, and a rolling FPS measurement.

### `timer::scheduler`

Scheduled event manager for delayed and repeating timed callbacks.

- **`ScheduledEvent`** (struct): A single scheduled event with optional name and pause state.
- **`Scheduler`** (struct): Manages a collection of timed events (one-shot and repeating).  Each event has an integer ID (returned on creation)...

## Key Types

### Structs

#### `timer::clock::Clock`

Tracks per-frame delta time, accumulated total time, and a rolling FPS measurement.

#### `timer::scheduler::ScheduledEvent`

A single scheduled event with optional name and pause state.

#### `timer::scheduler::Scheduler`

Manages a collection of timed events (one-shot and repeating).  Each event has an integer ID (returned on creation)...

## Lua API

Exposed under `luna.timer.*` by `src/lua_api/timer_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `mod` | 2 |
| `struct` | 3 |
| **Total** | **5** |

