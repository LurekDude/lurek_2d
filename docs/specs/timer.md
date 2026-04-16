# timer

## General Info

- Module group: `Core Runtime`
- Source path: `src/timer/`
- Lua API path(s): `src/lua_api/timer_api.rs`
- Primary Lua namespace: `lurek.time`
- Rust test path(s): tests/rust/unit/timer_tests.rs, tests/fixtures/timer_api_fixture.rs, plus inline unit coverage in src/timer/scheduler.rs
- Lua test path(s): tests/lua/unit/test_timer.lua, tests/lua/stress/test_timer_stress.lua, tests/lua/integration/test_timer_math.lua, tests/lua/integration/test_physics_timer.lua, tests/lua/integration/test_particle_timer.lua, tests/lua/integration/test_audio_timer.lua, tests/lua/integration/test_animation_timer.lua

## Summary

The `timer` module provides Lurek2D's frame-timing infrastructure and scheduled-event system. It owns two complementary types: `Clock` for frame pacing and elapsed-time tracking, and `Scheduler` for deferred and repeating callback execution.

`Clock` is the frame-timer used by `App` to compute `dt` each frame. `Clock::tick()` measures wall-clock elapsed time since the last tick, clamps it to 0.1s to prevent runaway physics on slow frames, updates a smoothed FPS estimate using an exponential moving average, and increments the frame counter and total elapsed time. Accessors: `dt()`, `fps()`, `elapsed()`, `frame_count()`.

`Scheduler` manages three categories of deferred Lua callbacks: `schedule(delay, fn)` fires once after `delay` seconds; `every(interval, fn)` fires repeatedly every `interval` seconds until explicitly cancelled; `after_frames(n, fn)` fires after exactly `n` rendered frames — frame-precise and unaffected by pausing. All callbacks execute synchronously on the main thread during `Scheduler::tick(dt)`. Lua errors from callbacks are caught and forwarded through the engine's Lua error channel rather than panicking. A cancellation handle is returned from `schedule` and `every` for programmatic cancellation.

`sleep(seconds)` pauses the calling OS thread and is intended only for worker VM threads (from `lurek.thread`); calling it from the main VM blocks the engine's frame loop and is therefore prohibited in the Lua API documentation.

The timer module has been extended with physics step controls: `setPhysicsMaxSteps` and `getPhysicsMaxSteps` allow game scripts to configure the maximum number of physics sub-steps the engine processes in a single frame, preventing spiral-of-death behavior when frame time spikes. Schedule improvements to `lurek.time.schedule` provide more expressive deferred callback registration patterns for scripts that need fine-grained timing control.

**Scope boundary**: Core Runtime tier. Depends only on `runtime`. Lua bridge in `src/lua_api/timer_api.rs`.

## Files

- `clock.rs`: `Clock` struct � frame delta, total time, FPS, and rolling average
- `mod.rs`: Re-exports `Clock` and `Scheduler`; provides free function `sleep()`
- `scheduler.rs`: `Scheduler` and `ScheduledEvent` � delayed and repeating events

## Types

- `Clock` (`struct`, `clock.rs`): Tracks per-frame delta time, accumulated total time, and a rolling FPS measurement.
- `ScheduledEvent` (`struct`, `scheduler.rs`): A single scheduled event with optional name and pause state.
- `Scheduler` (`struct`, `scheduler.rs`): Manages a collection of timed events (one-shot and repeating).

## Functions

- `Clock::new` (`clock.rs`): Creates a new `Clock`, recording the current instant as the start time.
- `Clock::tick` (`clock.rs`): Advances the clock by one frame, updating delta time, total time, and rolling FPS.
- `Clock::delta` (`clock.rs`): Returns the delta time for the most recently completed frame in seconds.
- `Clock::total` (`clock.rs`): Returns the total elapsed time since the clock was created, in seconds.
- `Clock::fps` (`clock.rs`): Returns the rolling frames-per-second measurement.
- `Clock::frame_count` (`clock.rs`): Returns the total number of frames that have elapsed since the clock was created.
- `Clock::elapsed` (`clock.rs`): Returns a live high-resolution elapsed time since the clock was created, in seconds.
- `Clock::average_delta` (`clock.rs`): Returns the average delta time over the last N frames (up to 60).
- `sleep` (`mod.rs`): Suspends the current thread for the given number of seconds.
- `Scheduler::new` (`scheduler.rs`): Create a new empty Scheduler with time-scale 1.0.
- `Scheduler::after` (`scheduler.rs`): Schedule a one-shot callback after `delay` seconds.
- `Scheduler::after_named` (`scheduler.rs`): Schedule a one-shot callback with a `name` for cancel-by-name support.
- `Scheduler::every` (`scheduler.rs`): Schedule a repeating callback at `interval` seconds.
- `Scheduler::every_named` (`scheduler.rs`): Schedule a named repeating callback.
- `Scheduler::cancel` (`scheduler.rs`): Cancel a scheduled event by its ID.
- `Scheduler::cancel_named` (`scheduler.rs`): Cancel a scheduled event by its name.
- `Scheduler::cancel_all` (`scheduler.rs`): Cancel all scheduled events.
- `Scheduler::pause` (`scheduler.rs`): Pause a single event by ID.
- `Scheduler::resume` (`scheduler.rs`): Resume a previously paused event by ID.
- `Scheduler::is_paused` (`scheduler.rs`): Returns `true` if the event with `id` is currently paused.
- `Scheduler::pause_named` (`scheduler.rs`): Pauses a scheduled event by its string name.
- `Scheduler::resume_named` (`scheduler.rs`): Resumes a previously paused event by its string name.
- `Scheduler::is_paused_named` (`scheduler.rs`): Returns `true` if the named event is currently paused.
- `Scheduler::get_remaining` (`scheduler.rs`): Returns the time remaining until the next fire for event `id`, or `None` if not found.
- `Scheduler::get_interval` (`scheduler.rs`): Returns the base interval for event `id`, or `None` if not found.
- `Scheduler::get_repeat_count` (`scheduler.rs`): Returns the repeat count remaining for event `id` (-1 = infinite), or `None` if not found.
- `Scheduler::set_interval` (`scheduler.rs`): Change the interval of a repeating event.
- `Scheduler::reset_event` (`scheduler.rs`): Reset an event's remaining time to its original interval.
- `Scheduler::set_time_scale` (`scheduler.rs`): Set the global time-scale multiplier for this scheduler.
- `Scheduler::get_time_scale` (`scheduler.rs`): Returns the current global time-scale.
- `Scheduler::update` (`scheduler.rs`): Advance all non-paused timers by `dt * time_scale` seconds.
- `Scheduler::count` (`scheduler.rs`): Get the number of active (non-expired) scheduled events.
- `Scheduler::active_ids` (`scheduler.rs`): Get the IDs of all active events.
- `Scheduler::is_empty` (`scheduler.rs`): Returns `true` if no events are scheduled.

## Lua API Reference

- Binding path(s): `src/lua_api/timer_api.rs`
- Namespace: `lurek.time`

### Module Functions
- `lurek.timer.getDelta`: Returns the delta time in seconds for the current frame.
- `lurek.timer.getFPS`: Returns the current frames-per-second measurement.
- `lurek.timer.getTime`: Returns the total elapsed time since engine start in seconds.
- `lurek.timer.getAverageDelta`: Returns the rolling-average frame delta time in seconds.
- `lurek.timer.getFrameCount`: Returns the total number of frames rendered since engine start.
- `lurek.timer.step`: Advances the timer by one frame, returning the delta time.
- `lurek.timer.getMicroTime`: Returns the high-resolution elapsed time since engine start in seconds.
- `lurek.timer.getPhysicsDelta`: Returns the fixed timestep used by `process_physics` callbacks (seconds).
- `lurek.timer.setPhysicsDelta`: Sets the fixed timestep for `process_physics` callbacks (seconds).
- `lurek.timer.getPhysicsMaxSteps`: Returns the maximum number of physics sub-steps allowed per frame.
- `lurek.timer.setPhysicsMaxSteps`: Sets the maximum number of physics sub-steps allowed per frame (clamped 1–64).
- `lurek.timer.sleep`: Suspends execution for the given number of seconds.
- `lurek.timer.newScheduler`: Creates a new independent Scheduler for managing timed callbacks.
- `lurek.timer.chain`: Creates a new Scheduler loaded with a sequenced one-shot chain.
- `lurek.timer.afterReal`: Schedules a one-shot callback that fires after `delay` wall-clock seconds,
- `lurek.timer.tickRealTimers`: Advances all real-time timers by one tick; called automatically each frame.
- `lurek.timer.setSmoothingFactor`: Sets the smoothing factor (alpha) for `getSmoothedDelta`. Must be in [0.01, 1.0].
- `lurek.timer.getSmoothedDelta`: Returns the exponential moving-average of frame deltas in seconds.
- `lurek.timer.waitSeconds`: Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
- `lurek.timer.waitFrames`: Yields the current Lua coroutine for at least `frames` engine frames.
- `lurek.timer.tickWaits`: Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.

### `Scheduler` Methods
- `Scheduler:after`: Schedules a callback to fire once after a delay.
- `Scheduler:cancel`: Cancels a scheduled event by its numeric ID.
- `Scheduler:cancelNamed`: Cancels a scheduled event by its string name.
- `Scheduler:cancelAll`: Cancels all scheduled events and returns the count removed.
- `Scheduler:pause`: Pauses a scheduled event by its ID.
- `Scheduler:resume`: Resumes a paused event by its ID.
- `Scheduler:isPaused`: Returns whether the given event is currently paused.
- `Scheduler:pauseNamed`: Pauses a scheduled event by its string name.
- `Scheduler:resumeNamed`: Resumes a paused event by its string name.
- `Scheduler:isPausedNamed`: Returns whether the named event is currently paused.
- `Scheduler:getRemaining`: Returns the seconds remaining until the next fire for an event, or nil.
- `Scheduler:getInterval`: Returns the base interval in seconds for an event, or nil.
- `Scheduler:getRepeatCount`: Returns the repeat count remaining for an event, or nil.
- `Scheduler:getCount`: Returns the number of active scheduled events.
- `Scheduler:isEmpty`: Returns whether the scheduler has no active events.
- `Scheduler:setInterval`: Changes the repeat interval of an existing event.
- `Scheduler:resetEvent`: Resets an event's remaining time back to its original interval.
- `Scheduler:setTimeScale`: Sets a global time-scale multiplier for this scheduler.
- `Scheduler:getTimeScale`: Returns the current time-scale multiplier.
- `Scheduler:update`: Advances all timers by dt seconds, firing due callbacks.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/timer/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
