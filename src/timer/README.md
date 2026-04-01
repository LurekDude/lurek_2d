# `src/timer/` — Frame Timing and Scheduled Events

## Purpose

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

### How It Works

The `Scheduler` returns a `Vec<u32>` of fired event IDs from `update(dt)`
rather than calling Lua callbacks internally.  This pull design is deliberate:
if fired events called Lua directly from inside Rust's `update()`, the Lua
state would be partially borrowed during the call, potentially violating
mlua's borrow rules.  Returning fire IDs and letting Lua check them in its own
`update()` callback keeps the execution boundary clean.

The average-delta ring buffer stores the last 60 frame deltas in a circular
`[f64; 60]` array.  `average_delta()` computes the mean of all filled slots.
This moving average smooths out frame-time spikes in HUD displays, giving a
stable "ms per frame" reading even when individual frames vary.

Named events are stored in the same `Vec<ScheduledEvent>` as anonymous events
and are located by a linear scan keyed on the `Option<String>` name.  The
linear cost is negligible for the number of named timers typical in a game
(fewer than 20); hashing would add more code complexity than speed benefit
at this scale.

### Dependency Direction

```
timer/ ──────► (none)
```

**Leaf module** — no Luna2D dependencies. Uses `std::time::Instant`.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `Clock`, `Scheduler`.

**~5 lines** — re-exports.

---

### `clock.rs` — `Clock` (Frame Timing)

**~113 lines** | High-precision frame timing with rolling FPS calculation.

#### Constants

`AVERAGE_DELTA_WINDOW = 60` — ring buffer size for average delta.

#### Struct: `Clock`

```rust
pub struct Clock {
    start_time: Instant,
    last_frame: Instant,
    delta: f64,
    total: f64,
    frame_count: u64,
    fps: f64,
    fps_timer: f64,
    fps_frame_count: u64,
    delta_buffer: [f64; 60],
    delta_buffer_index: usize,
    delta_buffer_filled: bool,
}
```

#### Methods

| Method | Returns | Notes |
|--------|---------|-------|
| `new()` | Clock | Initialized with current instant |
| `tick()` | `f64` | Delta since last tick (seconds) |
| `delta()` | `f64` | Last computed delta |
| `total()` | `f64` | Total elapsed since creation |
| `fps()` | `f64` | Rolling 1-second FPS |
| `frame_count()` | `u64` | Total frames ticked |
| `average_delta()` | `f64` | Mean of last 60 deltas |

**FPS calculation**: Accumulates frames over 1-second windows. When the
timer exceeds 1.0 seconds, computes `frames / elapsed` and resets.

**Average delta**: Uses a 60-slot ring buffer. `average_delta()` returns
the mean of all filled slots — smooths out frame time spikes.

---

### `scheduler.rs` — `Scheduler` (Timed Events)

**~511 lines** | Time-based event scheduling with repeat, pause, and time scale.

#### Struct: `ScheduledEvent`

```rust
pub struct ScheduledEvent {
    pub id: u32,
    pub name: Option<String>,
    pub remaining: f64,       // seconds until next fire
    pub interval: f64,        // repeat interval (0 = one-shot)
    pub count: u32,           // remaining repeat count (0 = infinite)
    pub one_shot: bool,
    pub paused: bool,
}
```

#### Struct: `Scheduler`

```rust
pub struct Scheduler {
    events: Vec<ScheduledEvent>,
    next_id: u32,
    time_scale: f64,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `new()` | Create scheduler |
| `count()` / `is_empty()` / `active_ids()` | Query state |
| `after(delay)` → `u32` | One-shot delayed event |
| `after_named(name, delay)` → `u32` | Named one-shot (replaces existing) |
| `every(interval, count)` → `u32` | Repeating event |
| `every_named(name, interval, count)` → `u32` | Named repeating |
| `cancel(id)` | Cancel specific event |
| `cancel_named(name)` | Cancel by name |
| `cancel_all()` | Cancel everything |
| `pause(id)` / `resume(id)` | Per-event pause |
| `is_paused(id)` | Check pause state |
| `get_remaining(id)` | Time until next fire |
| `get_interval(id)` | Repeat interval |
| `get_repeat_count(id)` | Remaining repeats |
| `set_interval(id, interval)` | Change interval |
| `reset_event(id)` | Reset timer to initial |
| `set_time_scale(scale)` / `get_time_scale()` | Global speed (0–100) |
| `update(dt)` → `Vec<u32>` | Advance all events, return fired IDs |

**Design**: Named events replace existing events with the same name — prevents
duplicate timers from accumulating. Time scale is clamped to [0, 100] and
multiplies delta before advancing events. `update()` detects fire-in-place
(when dt >= remaining) and handles auto-cleanup of expired one-shots.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/timer_api.rs` (~280 lines), exposing
timing under `luna.timer.*`.

### Usage from Lua

```lua
-- Frame timing
function luna.update(dt)
    local fps = luna.timer.getFPS()
    local total = luna.timer.getTime()
end

-- Scheduled events
local id = luna.timer.after(3.0)  -- fires in 3 seconds
local repeater = luna.timer.every(1.0, 5)  -- fires 5 times, once per second

-- Check fired events
local fired = luna.timer.getFired()
for _, event_id in ipairs(fired) do
    if event_id == id then
        print("Timer fired!")
    end
end

-- Time scale (slow motion)
luna.timer.setTimeScale(0.5)
```
