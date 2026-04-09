# `timer` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 � Core Engine Subsystems                      |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.time`                                         |
| **Source**     | `src/timer/`                                         |
| **Rust Tests** | `tests/rust/unit/timer_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_timer.lua`                      |
| **Architecture** | �                                                  |

## Purpose

The timer module provides two orthogonal timing mechanisms that together cover
all time-related needs in a game loop. `Clock` measures wall-clock time: it
tracks frame delta (elapsed seconds since the last tick), total elapsed time
since game start, rolling FPS computed over a 1-second sliding window, and a
60-frame rolling average delta useful for smooth HUD display of frame time.
`Clock` is stored inside `SharedState` and ticked once per engine frame by the
main loop in `src/engine/app.rs`; the `dt` that `lurek.update(dt)` receives is
the `Clock`'s last-tick delta. The module also exposes a free function
`sleep(seconds)` that blocks the calling thread � a convenience for loading
screens or startup delays that should never be called in the hot loop.

## Source Files

| File           | Purpose                                                              |
|----------------|----------------------------------------------------------------------|
| `mod.rs`       | Re-exports `Clock` and `Scheduler`; provides free function `sleep()` |
| `clock.rs`     | `Clock` struct � frame delta, total time, FPS, and rolling average   |
| `scheduler.rs` | `Scheduler` and `ScheduledEvent` � delayed and repeating events      |

## Key Types

| Type | Description |
|------|-------------|
| `Clock` | Principal type for the `timer` module. |
| `ScheduledEvent` | Principal type for the `timer` module. |
| `Scheduler` | Principal type for the `timer` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.timer.getDelta()` | See `docs/specs/timer.md`. |
| `lurek.timer.getFPS()` | See `docs/specs/timer.md`. |
| `lurek.timer.getTime()` | See `docs/specs/timer.md`. |
| `lurek.timer.getAverageDelta()` | See `docs/specs/timer.md`. |
| `lurek.timer.step()` | See `docs/specs/timer.md`. |
| `lurek.timer.getMicroTime()` | See `docs/specs/timer.md`. |
| `lurek.timer.getPhysicsDelta()` | See `docs/specs/timer.md`. |
| `lurek.timer.setPhysicsDelta()` | See `docs/specs/timer.md`. |
| `lurek.timer.sleep()` | See `docs/specs/timer.md`. |
| `lurek.timer.newScheduler()` | See `docs/specs/timer.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/timer.md`](../../docs/specs/timer.md)

_Update both this file **and** `docs/specs/timer.md` whenever source files, public types, or Lua bindings change._
