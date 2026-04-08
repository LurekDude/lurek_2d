# `timer` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.time`                                         |
| **Source**     | `src/timer/`                                         |
| **Rust Tests** | `tests/rust/unit/timer_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_timer.lua`                      |
| **Architecture** | —                                                  |

## Summary

The timer module provides two orthogonal timing mechanisms that together cover
all time-related needs in a game loop. `Clock` measures wall-clock time: it
tracks frame delta (elapsed seconds since the last tick), total elapsed time
since game start, rolling FPS computed over a 1-second sliding window, and a
60-frame rolling average delta useful for smooth HUD display of frame time.
`Clock` is stored inside `SharedState` and ticked once per engine frame by the
main loop in `src/engine/app.rs`; the `dt` that `luna.update(dt)` receives is
the `Clock`'s last-tick delta. The module also exposes a free function
`sleep(seconds)` that blocks the calling thread — a convenience for loading
screens or startup delays that should never be called in the hot loop.

`Scheduler` handles game-logic timing — "execute something after 3 seconds"
and "repeat something every 0.5 seconds for 10 iterations". Unlike the raw
clock, the Scheduler's perceived time is affected by a `time_scale` multiplier
that the game controls: set it to 0.0 for a full pause, 0.5 for slow-motion
bullet-time, or 2.0 for fast-forward (clamped to 0.0–100.0). Named events
replace existing events with the same name, preventing timer accumulation when
setup code runs repeatedly on scene re-entry. Per-event pause and resume allow
individual timers to be suspended without stopping the entire scheduler.
Schedulers are created on the Lua side via `luna.time.newScheduler()` and
wrapped in a `LuaScheduler` UserData that pairs the Rust `Scheduler` with a
`HashMap<u32, LuaRegistryKey>` for callback storage. Expired callbacks are
automatically unregistered from the Lua registry after each `update()` call.

The module intentionally does not include tweening or interpolation — those
live in `src/animation/`. It also does not own the engine's fixed-timestep
accumulator; frame stepping is the responsibility of `src/engine/app.rs`.

## Architecture

```
timer/
  │
  ├── mod.rs ── re-exports Clock, Scheduler; free fn sleep()
  │
  ├── Clock ── wall-clock frame timing (clock.rs)
  │     ├── new() → Clock
  │     ├── tick() → f64 delta (call once per frame)
  │     ├── delta() → last frame delta
  │     ├── total() → total elapsed time (cached at tick)
  │     ├── elapsed() → live high-res time (queries Instant)
  │     ├── fps() → rolling 1-second FPS window
  │     ├── frame_count() → cumulative u64
  │     └── average_delta() → 60-frame rolling average
  │
  └── Scheduler ── timed event system (scheduler.rs)
        ├── after(delay) / after_named(name, delay) → u32 ID
        ├── every(interval, count) / every_named(name, interval, count) → u32 ID
        ├── cancel(id) / cancel_named(name) / cancel_all()
        ├── pause(id) / resume(id) / is_paused(id)
        ├── get_remaining(id) / get_interval(id) / get_repeat_count(id)
        ├── set_interval(id, new) / reset_event(id)
        ├── set_time_scale(scale) / get_time_scale()
        ├── update(dt) → Vec<u32> fired IDs
        └── count() / active_ids() / is_empty()

         ScheduledEvent ── per-event data
           id, name?, remaining, interval, count, one_shot, paused

lua_api/timer_api.rs
  ├── LuaScheduler (UserData) ── wraps Scheduler + callback registry
  │     └── methods: after, afterNamed, every, everyNamed, cancel,
  │         cancelNamed, cancelAll, pause, resume, isPaused,
  │         getRemaining, getInterval, getRepeatCount, getCount,
  │         isEmpty, setInterval, resetEvent, setTimeScale,
  │         getTimeScale, update
  └── luna.time table
        ├── getDelta, getFPS, getTime, getAverageDelta
        ├── step, getMicroTime, sleep
        └── newScheduler → LuaScheduler
```

## Source Files

| File           | Purpose                                                              |
|----------------|----------------------------------------------------------------------|
| `mod.rs`       | Re-exports `Clock` and `Scheduler`; provides free function `sleep()` |
| `clock.rs`     | `Clock` struct — frame delta, total time, FPS, and rolling average   |
| `scheduler.rs` | `Scheduler` and `ScheduledEvent` — delayed and repeating events      |

## Submodules

### `timer::clock`

Wall-clock frame timing. Measures real elapsed time with `std::time::Instant`.
Maintains an internal 60-frame ring buffer for the rolling average delta.

- **`Clock`** (struct) — Tracks per-frame delta time, accumulated total time, rolling FPS over a 1-second window, and a 60-frame rolling average delta.

### `timer::scheduler`

Game-logic event scheduler with time-scale support. Events are identified by
auto-incrementing `u32` IDs. Count-limited events remove themselves when their
count reaches zero; infinite events (`count = -1`) persist until cancelled.

- **`ScheduledEvent`** (struct) — A single scheduled event holding `id`, optional `name`, `remaining` time, `interval`, `count`, `one_shot` flag, and `paused` flag.
- **`Scheduler`** (struct) — Manages a `Vec<ScheduledEvent>` with a global `time_scale` multiplier. Provides creation, cancellation, pause/resume, query, modification, and update methods.

## Key Types

### Structs

#### `timer::clock::Clock`

Tracks per-frame delta time, accumulated total time, and a rolling FPS
measurement. Uses `std::time::Instant` for high-resolution timing. Fields:
`start_time`, `last_frame` (both `Instant`), `delta` and `total` (`f64`),
`frame_count` (`u64`), `fps` and `fps_timer` (`f64`), `fps_frame_count`
(`u64`), and a 60-element `delta_buffer` ring with `delta_buffer_index` and
`delta_buffer_filled` for the rolling average.

Public methods:
- `new()` — Create with the current instant as the start time.
- `tick()` → `f64` — Advance one frame; returns delta seconds.
- `delta()` → `f64` — Last frame delta.
- `total()` → `f64` — Total elapsed time (cached at last tick).
- `elapsed()` → `f64` — Live high-resolution elapsed time (queries `Instant` directly).
- `fps()` → `f64` — Rolling FPS updated once per second.
- `frame_count()` → `u64` — Cumulative frame count.
- `average_delta()` → `f64` — Rolling average delta over up to 60 frames.

Implements `Default` (delegates to `new()`).

#### `timer::scheduler::ScheduledEvent`

A single scheduled event with optional name and pause state. All fields are
`pub`:

- `id: u32` — Unique numeric identifier.
- `name: Option<String>` — Optional human-readable name for cancel-by-name.
- `remaining: f64` — Seconds until the next firing.
- `interval: f64` — Base interval between firings.
- `count: i32` — Remaining fire count (0 = expired, -1 = infinite).
- `one_shot: bool` — Whether this fires once then auto-removes.
- `paused: bool` — Whether individually paused.

Derives `Debug`, `Clone`.

#### `timer::scheduler::Scheduler`

Manages a `Vec<ScheduledEvent>` with a `next_id` counter and a global
`time_scale` multiplier. Public methods grouped by category:

**Scheduling:**
- `new()` — Empty scheduler, time-scale 1.0.
- `after(delay)` → `u32` — One-shot event.
- `after_named(name, delay)` → `u32` — Named one-shot; replaces existing same-name event.
- `every(interval, count)` → `u32` — Repeating event (-1 = infinite).
- `every_named(name, interval, count)` → `u32` — Named repeating; replaces existing.

**Cancellation:**
- `cancel(id)` → `bool` — Cancel by ID.
- `cancel_named(name)` → `Option<u32>` — Cancel by name; returns cancelled ID.
- `cancel_all()` → `u32` — Cancel all; returns count.

**Pause/Resume:**
- `pause(id)` → `bool` — Freeze an event's remaining time.
- `resume(id)` → `bool` — Unfreeze.
- `is_paused(id)` → `bool` — Query pause state.

**Queries:**
- `get_remaining(id)` → `Option<f64>` — Time until next fire.
- `get_interval(id)` → `Option<f64>` — Base interval.
- `get_repeat_count(id)` → `Option<i32>` — Remaining repeats.
- `count()` → `usize` — Number of active events.
- `active_ids()` → `Vec<u32>` — All active event IDs.
- `is_empty()` → `bool` — Whether no events are scheduled.

**Modification:**
- `set_interval(id, new_interval)` → `bool` — Change interval and reset remaining.
- `reset_event(id)` → `bool` — Reset remaining to original interval.

**Time scale:**
- `set_time_scale(scale)` — Clamped to [0.0, 100.0].
- `get_time_scale()` → `f64`.

**Update:**
- `update(dt)` → `Vec<u32>` — Advance all non-paused timers by `dt * time_scale`. Returns IDs that fired. Expired events are auto-removed.

Implements `Default` (delegates to `new()`). Derives `Debug`, `Clone`.

### Enums

No public enums in this module.

## Lua API

Registered by `src/lua_api/timer_api.rs` under `luna.time`. The file defines
a `LuaScheduler` UserData struct that wraps a Rust `Scheduler` with a
`HashMap<u32, LuaRegistryKey>` for Lua callback storage and a
`HashMap<String, u32>` for named event ID tracking. Expired callbacks are
automatically unregistered from the Lua registry after each `update()` call.

### `luna.time` table functions

| Function                          | Signature                 | Description                                                                      |
|-----------------------------------|---------------------------|----------------------------------------------------------------------------------|
| `luna.time.getDelta()`           | `() → number`            | Frame delta time in seconds from `SharedState.delta_time`                        |
| `luna.time.getFPS()`             | `() → number`            | Current FPS from `SharedState.fps`                                               |
| `luna.time.getTime()`            | `() → number`            | Total elapsed time from `SharedState.total_time`                                 |
| `luna.time.getAverageDelta()`    | `() → number`            | Rolling 60-frame average delta from `Clock.average_delta()`                      |
| `luna.time.step()`               | `() → number`            | Advance clock one tick; returns delta. Calls `SharedState.step_timer()`          |
| `luna.time.getMicroTime()`       | `() → number`            | High-resolution elapsed time from `Clock.elapsed()`                              |
| `luna.time.sleep(seconds)`       | `(number) → nil`         | Block the main thread for `seconds` (≤ 0 is ignored)                            |
| `luna.time.newScheduler()`       | `() → Scheduler`         | Create a new independent `LuaScheduler` UserData                                 |
| `luna.time.getPhysicsDelta()`    | `() → number`            | Returns the current fixed physics timestep in seconds (default `1/60`)           |
| `luna.time.setPhysicsDelta(dt)`  | `(number) → nil`         | Sets the physics timestep; clamped to [1/240, 1/10]. See also `performance.physics_tick_rate` in `conf.lua` |

### `Scheduler` UserData methods

| Method                                     | Signature                                   | Description                                       |
|--------------------------------------------|---------------------------------------------|---------------------------------------------------|
| `sched:after(delay, func)`                 | `(number, function) → integer`              | One-shot callback after `delay` seconds            |
| `sched:afterNamed(name, delay, func)`      | `(string, number, function) → integer`      | Named one-shot; replaces existing same-name event  |
| `sched:every(interval, func, count?)`      | `(number, function, integer?) → integer`    | Repeating callback; `count` defaults to -1 (infinite) |
| `sched:everyNamed(name, interval, func, count?)` | `(string, number, function, integer?) → integer` | Named repeating; replaces existing       |
| `sched:cancel(id)`                         | `(integer) → boolean`                       | Cancel by ID                                       |
| `sched:cancelNamed(name)`                  | `(string) → boolean`                        | Cancel by name                                     |
| `sched:cancelAll()`                        | `() → integer`                              | Cancel all; returns count removed                  |
| `sched:pause(id)`                          | `(integer) → boolean`                       | Pause an event                                     |
| `sched:resume(id)`                         | `(integer) → boolean`                       | Resume a paused event                              |
| `sched:isPaused(id)`                       | `(integer) → boolean`                       | Check if event is paused                           |
| `sched:getRemaining(id)`                   | `(integer) → number?`                       | Seconds until next fire, or nil                    |
| `sched:getInterval(id)`                    | `(integer) → number?`                       | Base interval, or nil                              |
| `sched:getRepeatCount(id)`                 | `(integer) → integer?`                      | Remaining repeat count, or nil                     |
| `sched:getCount()`                         | `() → integer`                              | Number of active events                            |
| `sched:isEmpty()`                          | `() → boolean`                              | Whether scheduler has no events                    |
| `sched:setInterval(id, interval)`          | `(integer, number) → boolean`               | Change interval and reset remaining                |
| `sched:resetEvent(id)`                     | `(integer) → boolean`                       | Reset remaining to original interval               |
| `sched:setTimeScale(scale)`                | `(number) → nil`                            | Set global time-scale multiplier                   |
| `sched:getTimeScale()`                     | `() → number`                               | Get current time-scale                             |
| `sched:update(dt)`                         | `(number) → integer`                        | Advance timers; fire callbacks; returns fire count |

## Lua Examples

```lua
-- Basic frame timing
function luna.process(dt)
    local fps = luna.time.getFPS()
    local total = luna.time.getTime()
    local avg = luna.time.getAverageDelta()
end
```

```lua
-- Scheduler: one-shot, repeating, named, pause/resume
function luna.init()
    sched = luna.time.newScheduler()

    -- Fire once after 3 seconds
    sched:after(3.0, function()
        print("3 seconds elapsed!")
    end)

    -- Fire every 0.5 seconds, 10 times
    sched:every(0.5, function()
        score = (score or 0) + 1
    end, 10)

    -- Named timer — safe to call repeatedly (replaces previous)
    sched:afterNamed("boss_spawn", 5.0, function()
        spawn_boss()
    end)

    -- Slow-motion mode
    sched:setTimeScale(0.5)
end

function luna.process(dt)
    sched:update(dt)

    -- Pause/resume example
    if luna.keyboard.isDown("p") then
        sched:pause(some_id)
    end
    if luna.keyboard.isDown("r") then
        sched:resume(some_id)
    end
end
```

```lua
-- High-resolution timing for benchmarks
local t1 = luna.time.getMicroTime()
do_expensive_work()
local elapsed = luna.time.getMicroTime() - t1
print("Took " .. elapsed .. " seconds")
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 3     |
| `enum`    | 0     |
| `fn`      | 31    |
| **Total** | **34**|

## References

| Module    | Relationship  | Notes                                                        |
|-----------|---------------|--------------------------------------------------------------|
| `engine`  | Imports from  | `Clock` stored in `SharedState`; `delta_time`, `fps`, `total_time` fields mirrored from `Clock` |
| `math`    | —             | No direct dependency; timer is pure `std::time`              |
| `lua_api`  | Imported by  | `src/lua_api/timer_api.rs` registers `luna.time.*`          |
| `animation` | Similar     | Animation/tweening uses delta time but does NOT own timing — consumes `dt` from timer |
| `engine::log_messages` | Imports from | Uses log message constants `TI01`–`TI04` for debug logging |

## Notes

- **Clock is engine-owned**: `Clock` lives inside `SharedState` and is ticked by the engine loop. Game scripts read timing through `luna.time.getDelta()` / `luna.time.getFPS()` / `luna.time.getTime()` rather than ticking the clock themselves. `luna.time.step()` exists but is primarily for test harness use.
- **Schedulers are Lua-owned**: Each call to `luna.time.newScheduler()` creates an independent scheduler. Games can have multiple schedulers (e.g., one for UI, one for gameplay with different time scales). The scheduler is a UserData object — its lifetime is managed by Lua's garbage collector.
- **Callback cleanup**: `LuaScheduler` stores callbacks as `LuaRegistryKey` values. After `update()`, any event IDs no longer in the Scheduler's active set are cleaned up from both the callback map and the named-IDs map, preventing registry leaks.
- **Named event replacement**: `afterNamed` / `everyNamed` cancel and remove the old callback before inserting the new one. This is safe for scene re-entry patterns where `luna.load()` sets up timers that might already exist.
- **Time scale clamping**: `set_time_scale` clamps to [0.0, 100.0]. A scale of 0.0 freezes all timers without cancelling them. Scale does not affect `Clock` — only `Scheduler`.
- **`sleep()` blocks the thread**: `timer::sleep(seconds)` calls `std::thread::sleep`. Values ≤ 0 are silently ignored. Never call this in the game loop — it freezes the entire engine.
- **No heap allocation in update**: `Scheduler::update()` allocates a `Vec<u32>` for fired IDs. This is acceptable because scheduler updates are not per-draw-call — they run once per frame in `luna.update`.
- **Test coverage**: 11 Rust integration tests in `tests/rust/unit/timer_tests.rs` covering `Clock` and `Scheduler`. 17 inline unit tests in `scheduler.rs` `#[cfg(test)]` module. 21 Lua BDD tests in `tests/lua/unit/test_timer.lua`. Additional Lua integration tests in `tests/lua/integration/test_timer_math.lua`.
