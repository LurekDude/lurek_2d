# `timer` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Core Runtime |
| **Status** | Implemented |
| **Lua API** | `lurek.time` |
| **Source** | `src/timer/` |
| **Rust Tests** | `tests/rust/unit/timer_tests.rs`, `tests/fixtures/timer_api_fixture.rs`, plus inline unit coverage in `src/timer/scheduler.rs` |
| **Lua Tests** | `tests/lua/unit/test_timer.lua`, `tests/lua/stress/test_timer_stress.lua`, `tests/lua/integration/test_timer_math.lua`, `tests/lua/integration/test_physics_timer.lua`, `tests/lua/integration/test_particle_timer.lua`, `tests/lua/integration/test_audio_timer.lua`, `tests/lua/integration/test_animation_timer.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Core Runtime` |

---

## Summary

The timer module owns Lurek2D's generic notion of time. It provides the frame clock used to derive delta time, total uptime, rolling FPS, and average frame duration, and it provides a standalone scheduler for delayed or repeating callbacks that can run at a caller-controlled time scale.

This module exists so time measurement and timer-driven behavior are consistent across the engine. `SharedState` keeps a `Clock` as the canonical per-frame timing source, while Lua scripts can create independent `Scheduler` instances for gameplay timing without having to implement their own event bookkeeping, repeat counts, pause state, or named timer replacement.

It intentionally does not own interpolation systems, animation state machines, or the engine's overall fixed-step orchestration. Tweening belongs in `tween`, animation playback belongs in `animation`, and the app loop decides when frame and physics callbacks run. The Lua wrapper in `src/lua_api/timer_api.rs` owns callback registry management; the core timer module only manages timing data and event IDs.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Core Runtime responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.time.* (Lua API — src/lua_api/timer_api.rs)
    |
    v
src/timer/mod.rs
    |- clock.rs - clock
    |- scheduler.rs - scheduler
```

---

## Source Files

| File | Purpose |
|------|---------|
| `clock.rs` | `Clock` struct � frame delta, total time, FPS, and rolling average |
| `mod.rs` | Re-exports `Clock` and `Scheduler`; provides free function `sleep()` |
| `scheduler.rs` | `Scheduler` and `ScheduledEvent` � delayed and repeating events |

---

## Submodules

### `timer::clock`

`Clock` struct � frame delta, total time, FPS, and rolling average

- **`Clock`** (struct): Tracks per-frame delta time, accumulated total time, and a rolling FPS measurement.

### `timer::scheduler`

`Scheduler` and `ScheduledEvent` � delayed and repeating events

- **`ScheduledEvent`** (struct): A single scheduled event with optional name and pause state.
- **`Scheduler`** (struct): Manages a collection of timed events (one-shot and repeating).

---

## Key Types

### Public Types

#### `Scheduler` is a standalone timed-event manager for delayed and repeating work. It is intentionally generic`

it knows about seconds, intervals, IDs, names, and pause state, but not about Lua callbacks or engine subsystems.

#### `sleep(seconds)` is a very small helper, but it is an important boundary marker`

blocking waits live here only as an explicit utility, not as part of frame scheduling logic.

#### `Clock`

Principal type for the `timer` module.

#### `ScheduledEvent`

Principal type for the `timer` module.

#### `Scheduler`

Principal type for the `timer` module.

---

## Lua API

Exposed under `lurek.time.*` by `src/lua_api/timer_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.timer.getDelta` | Returns the delta time in seconds for the current frame. |
| `lurek.timer.getFPS` | Returns the current frames-per-second measurement. |
| `lurek.timer.getTime` | Returns the total elapsed time since engine start in seconds. |
| `lurek.timer.getAverageDelta` | Returns the rolling-average frame delta time in seconds. |
| `lurek.timer.step` | Advances the timer by one frame, returning the delta time. |
| `lurek.timer.getMicroTime` | Returns the high-resolution elapsed time since engine start in seconds. |
| `lurek.timer.getPhysicsDelta` | Returns the fixed timestep used by `process_physics` callbacks (seconds). |
| `lurek.timer.setPhysicsDelta` | Sets the fixed timestep for `process_physics` callbacks (seconds). |
| `lurek.timer.sleep` | Suspends execution for the given number of seconds. |
| `lurek.timer.newScheduler` | Creates a new independent Scheduler for managing timed callbacks. |

### `Scheduler` Methods

| Method | Description |
|--------|-------------|
| `scheduler:after(...)` | Schedules a callback to fire once after a delay. |
| `scheduler:cancel(...)` | Cancels a scheduled event by its numeric ID. |
| `scheduler:cancelNamed(...)` | Cancels a scheduled event by its string name. |
| `scheduler:cancelAll(...)` | Cancels all scheduled events and returns the count removed. |
| `scheduler:pause(...)` | Pauses a scheduled event by its ID. |
| `scheduler:resume(...)` | Resumes a paused event by its ID. |
| `scheduler:isPaused(...)` | Returns whether the given event is currently paused. |
| `scheduler:getRemaining(...)` | Returns the seconds remaining until the next fire for an event, or nil. |
| `scheduler:getInterval(...)` | Returns the base interval in seconds for an event, or nil. |
| `scheduler:getRepeatCount(...)` | Returns the repeat count remaining for an event, or nil. |
| `scheduler:getCount(...)` | Returns the number of active scheduled events. |
| `scheduler:isEmpty(...)` | Returns whether the scheduler has no active events. |
| `scheduler:setInterval(...)` | Changes the repeat interval of an existing event. |
| `scheduler:resetEvent(...)` | Resets an event's remaining time back to its original interval. |
| `scheduler:setTimeScale(...)` | Sets a global time-scale multiplier for this scheduler. |
| `scheduler:getTimeScale(...)` | Returns the current time-scale multiplier. |
| `scheduler:update(...)` | Advances all timers by dt seconds, firing due callbacks. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.time.
if lurek.time then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 3 |
| `enum` | 0 |
| `fn` (Lua API) | 27 |
| **Total** | **30** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/timer/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
