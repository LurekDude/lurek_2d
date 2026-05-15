# timer

## General Info

- Module group: `Core Runtime`
- Source path: `src/timer/`
- Lua API path(s): `src/lua_api/timer_api.rs`
- Primary Lua namespace: `lurek.timer`
- Rust test path(s): tests/rust/unit/timer_tests.rs, tests/fixtures/timer_api_fixture.rs, plus inline unit coverage in src/timer/scheduler.rs
- Lua test path(s): tests/lua/unit/test_timer.lua, tests/lua/stress/test_timer_stress.lua, tests/lua/integration/test_timer_math.lua, tests/lua/integration/test_physics_timer.lua, tests/lua/integration/test_particle_timer.lua, tests/lua/integration/test_audio_timer.lua, tests/lua/integration/test_animation_timer.lua

## Summary

The `timer` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Core Runtime group rather than absorb behavior owned by those neighbors.

## Files

- `accumulator.rs`: - Drift-free microsecond accumulation for scaled elapsed-time tracking.
- `clock.rs`: `Clock` struct � frame delta, total time, FPS, and rolling average
- `mod.rs`: Re-exports `Clock` and `Scheduler`; provides free function `sleep()`
- `scheduler.rs`: `Scheduler` and `ScheduledEvent` � delayed and repeating events
- `sleep.rs`: Thread-blocking sleep helper used by `lurek.timer.sleep`.

## Types

- `Clock` (`struct`, `clock.rs`): Tracks per-frame delta time, accumulated total time, and a rolling FPS measurement.
- `ScheduledEvent` (`struct`, `scheduler.rs`): A single scheduled event with optional name and pause state.
- `FrameEvent` (`struct`, `scheduler.rs`): A frame-count–based scheduled event.
- `Scheduler` (`struct`, `scheduler.rs`): Manages a collection of timed events (one-shot and repeating).

## Functions

- `accumulate_scaled_micros` (`accumulator.rs`): Advance `elapsed_micros` by `dt_seconds * scale`, accumulating fractional microseconds in `carry_micros` to avoid drift; clamps negative inputs to zero.
- `Clock::new` (`clock.rs`): Create a new clock with all counters zeroed and both `start_time` and `last_frame` set to now.
- `Clock::tick` (`clock.rs`): Advance the clock by one frame: compute delta, update FPS every second, append to rolling buffer; return delta in seconds.
- `Clock::delta` (`clock.rs`): Return seconds elapsed between the last two `tick` calls.
- `Clock::total` (`clock.rs`): Return seconds elapsed since the clock was created, as of the last `tick`.
- `Clock::fps` (`clock.rs`): Return the most recently computed frames-per-second value, updated once per second.
- `Clock::frame_count` (`clock.rs`): Return the total number of `tick` calls since clock creation.
- `Clock::elapsed` (`clock.rs`): Return live wall-clock seconds since the clock was created, measured at call time (not last tick).
- `Clock::average_delta` (`clock.rs`): Return the mean delta over the last `AVERAGE_DELTA_WINDOW` frames, or 0.0 if no frames have been ticked.
- `Scheduler::new` (`scheduler.rs`): Create an empty scheduler with `time_scale` 1.0 and log the creation event.
- `Scheduler::after` (`scheduler.rs`): Schedule a one-shot event to fire after `delay` seconds; return its ID.
- `Scheduler::after_named` (`scheduler.rs`): Schedule a named one-shot event after `delay` seconds, replacing any existing event with the same name; return its ID.
- `Scheduler::every` (`scheduler.rs`): Schedule a repeating event with `interval` seconds between firings; `count` -1 means infinite; return its ID.
- `Scheduler::every_named` (`scheduler.rs`): Schedule a named repeating event, replacing any existing event with the same name; return its ID.
- `Scheduler::after_frames` (`scheduler.rs`): Schedule a one-shot frame event to fire after `n` frames; return its ID.
- `Scheduler::every_frames` (`scheduler.rs`): Schedule a repeating frame event firing every `n` frames for `count` repetitions (-1 = infinite); return its ID.
- `Scheduler::cancel` (`scheduler.rs`): Cancel the event with `id` from either list; return true if it was found and removed.
- `Scheduler::cancel_named` (`scheduler.rs`): Cancel the first time-based event with `name`; return its ID if found.
- `Scheduler::cancel_all` (`scheduler.rs`): Cancel all events in both lists; return the count removed.
- `Scheduler::pause` (`scheduler.rs`): Pause the time-based event with `id` so `update` skips it; return true if found.
- `Scheduler::resume` (`scheduler.rs`): Resume the time-based event with `id`; return true if found.
- `Scheduler::is_paused` (`scheduler.rs`): Return true if the time-based event with `id` is paused; false if not found.
- `Scheduler::pause_named` (`scheduler.rs`): Pause the first time-based event matching `name`; return true if found.
- `Scheduler::resume_named` (`scheduler.rs`): Resume the first time-based event matching `name`; return true if found.
- `Scheduler::is_paused_named` (`scheduler.rs`): Return true if the first time-based event matching `name` is paused; false if not found.
- `Scheduler::get_remaining` (`scheduler.rs`): Return seconds remaining on the time-based event with `id`, or `None` if not found.
- `Scheduler::get_interval` (`scheduler.rs`): Return the interval in seconds of the event with `id`, or `None` if not found.
- `Scheduler::get_repeat_count` (`scheduler.rs`): Return the remaining repeat count of the event with `id`, or `None` if not found.
- `Scheduler::set_interval` (`scheduler.rs`): Set a new interval on the event with `id` and reset `remaining` to `new_interval`; return true if found.
- `Scheduler::reset_event` (`scheduler.rs`): Reset `remaining` of the event with `id` back to its `interval`; return true if found.
- `Scheduler::set_time_scale` (`scheduler.rs`): Set the global time-scale applied to `dt` in `update`; clamped to [0.0, 100.0].
- `Scheduler::get_time_scale` (`scheduler.rs`): Return the current time-scale multiplier.
- `Scheduler::update` (`scheduler.rs`): Advance all non-paused time-based events by `dt * time_scale` seconds; return IDs of events that fired this frame.
- `Scheduler::update_frames` (`scheduler.rs`): Advance all non-paused frame-based events by one frame; return IDs of events that fired this frame.
- `Scheduler::count` (`scheduler.rs`): Return the total number of active time-based and frame-based events.
- `Scheduler::active_ids` (`scheduler.rs`): Return a vec of IDs for all currently active events across both lists.
- `Scheduler::is_empty` (`scheduler.rs`): Return true if there are no active events in either list.
- `sleep` (`sleep.rs`): Suspends the current thread for the given number of seconds.

## Lua API Reference

- Binding path(s): `src/lua_api/timer_api.rs`
- Namespace: `lurek.timer`

### Module Functions
- `lurek.timer.getDelta`: Returns the time in seconds elapsed since the last frame. Use this to make movement and animations frame-rate independent.
- `lurek.timer.getFPS`: Returns the current frames-per-second count. Useful for performance monitoring overlays and debug HUDs.
- `lurek.timer.getTime`: Returns the total elapsed game time in seconds since the engine started. Useful for time-based animations, effects, and shader uniforms.
- `lurek.timer.getAverageDelta`: Returns the smoothed average delta time in seconds over a recent window of frames. More stable than getDelta for display or adaptive logic.
- `lurek.timer.getFrameCount`: Returns the total number of frames rendered since the engine started.
- `lurek.timer.step`: Advances the internal clock by one tick and returns the delta time for that tick. Typically called by the engine loop; game scripts rarely need this.
- `lurek.timer.getMicroTime`: Returns high-resolution elapsed time in seconds since engine start. Useful for precise benchmarking and profiling.
- `lurek.timer.getPhysicsDelta`: Returns the fixed timestep used for physics simulation in seconds. The default is typically 1/60.
- `lurek.timer.setPhysicsDelta`: Sets the fixed timestep for physics simulation. Clamped between 1/240 and 1/10 seconds. Lower values increase accuracy but cost more CPU.
- `lurek.timer.getPhysicsMaxSteps`: Returns the maximum number of physics steps allowed per frame. Prevents the spiral of death when the game runs slowly.
- `lurek.timer.setPhysicsMaxSteps`: Sets the maximum number of physics steps allowed per frame. Clamped between 1 and 64. Higher values improve accuracy under lag but cost more CPU.
- `lurek.timer.sleep`: Blocks the current thread for the given number of seconds. Use sparingly — this halts the entire game loop. Intended for loading screens or synchronization.
- `lurek.timer.newScheduler`: Creates a new LScheduler instance for managing timed and frame-based callbacks independently from the global timer. Each scheduler has its own time scale and event list.
- `lurek.timer.chain`: Creates a scheduler pre-loaded with a sequence of delayed callbacks. Each step is a table with an optional `delay` (seconds) and optional `func` (callback). Delays accumulate so each step fires after the sum of all preceding delays. Returns the scheduler for manual update calls.
- `lurek.timer.afterReal`: Schedules a one-shot callback based on real (wall-clock) time, unaffected by game pausing or time scaling. Use for UI fade-outs, notifications, or anything that should run on real time.
- `lurek.timer.tickRealTimers`: Checks all real-time timers and fires any whose deadline has passed. Returns the number of callbacks that fired. Call this once per frame after afterReal scheduling.
- `lurek.timer.setSmoothingFactor`: Sets the exponential smoothing factor used by getSmoothedDelta. Lower values produce smoother (more lagged) results; higher values track changes faster. Clamped to [0.01, 1.0].
- `lurek.timer.getSmoothedDelta`: Returns an exponentially smoothed delta time in seconds, reducing frame-to-frame jitter. Call once per frame for consistent results. The smoothing factor is set via setSmoothingFactor.
- `lurek.timer.waitSeconds`: Yields the current coroutine for the given number of real-time seconds. Must be called from within a coroutine. The coroutine is resumed automatically when tickWaits is called and the deadline has passed.
- `lurek.timer.waitFrames`: Yields the current coroutine for the given number of frames. Must be called from within a coroutine. The coroutine is resumed automatically when tickWaits is called and the target frame count has been reached.
- `lurek.timer.tickWaits`: Checks all pending waitSeconds and waitFrames coroutines, resumes any whose deadline or frame target has been reached, and cleans up completed entries. Returns the number of coroutines that were resumed. Call once per frame.

### `LScheduler` Methods
- `LScheduler:after`: Schedules a one-shot callback to fire after the given delay in seconds. Returns an event ID that can be used to cancel, pause, or query the event.
- `LScheduler:afterFrames`: Schedules a one-shot callback to fire after the given number of frames. Returns an event ID for management.
- `LScheduler:afterNamed`: Schedules a named one-shot callback after a delay in seconds. If a callback with the same name already exists, the old one is cancelled and replaced. Useful for debouncing or resettable delays.
- `LScheduler:every`: Schedules a repeating callback that fires at a fixed interval in seconds. Pass a positive count to limit repetitions, or omit/pass -1 to repeat indefinitely.
- `LScheduler:everyFrames`: Schedules a repeating callback that fires every N frames. Pass a positive count to limit repetitions, or omit/pass -1 to repeat indefinitely.
- `LScheduler:everyNamed`: Schedules a named repeating callback at a fixed interval. If a callback with the same name already exists, the old one is cancelled and replaced. Useful for restartable periodic effects like health regeneration or status ticks.
- `LScheduler:cancel`: Cancels a scheduled event by its ID. Returns true if the event was found and removed, false if it did not exist.
- `LScheduler:cancelNamed`: Cancels a named scheduled event. Returns true if the named event was found and removed.
- `LScheduler:cancelAll`: Cancels all scheduled events in this scheduler and frees their callbacks. Returns the number of events that were removed.
- `LScheduler:pause`: Pauses a scheduled event so it stops accumulating time. Returns true if the event was found and paused.
- `LScheduler:resume`: Resumes a previously paused event so it continues accumulating time. Returns true if the event was found and resumed.
- `LScheduler:isPaused`: Checks whether a scheduled event is currently paused.
- `LScheduler:pauseNamed`: Pauses a named scheduled event. Returns true if the named event was found and paused.
- `LScheduler:resumeNamed`: Resumes a previously paused named event. Returns true if the named event was found and resumed.
- `LScheduler:isPausedNamed`: Checks whether a named scheduled event is currently paused.
- `LScheduler:getRemaining`: Returns the remaining time in seconds before the event fires. The first return value indicates whether the event was found; the second is the remaining time (0.0 if not found).
- `LScheduler:getInterval`: Returns the interval duration in seconds for a repeating event. The first return value indicates whether the event was found; the second is the interval (0.0 if not found).
- `LScheduler:getRepeatCount`: Returns the remaining repeat count for a repeating event. The first return value indicates whether the event was found; the second is the count (0 if not found). A value of -1 means infinite repeats.
- `LScheduler:getCount`: Returns the total number of active scheduled events in this scheduler.
- `LScheduler:isEmpty`: Returns true if the scheduler has no active events.
- `LScheduler:setInterval`: Changes the interval duration in seconds for an existing repeating event. Returns true if the event was found and updated.
- `LScheduler:resetEvent`: Resets the elapsed time of a scheduled event back to zero, restarting its delay or interval countdown. Returns true if the event was found and reset.
- `LScheduler:setTimeScale`: Sets the time scale multiplier for this scheduler. A value of 2.0 makes events fire twice as fast; 0.5 makes them fire at half speed. Does not affect frame-based events.
- `LScheduler:getTimeScale`: Returns the current time scale multiplier for this scheduler.
- `LScheduler:update`: Advances all time-based events by dt seconds, fires any callbacks whose delay has elapsed, and cleans up completed one-shot events. Call this once per frame with delta time. Returns the number of callbacks that fired.
- `LScheduler:updateFrames`: Advances all frame-based events by one frame, fires any callbacks whose frame count has been reached, and cleans up completed one-shot events. Call this once per frame. Returns the number of callbacks that fired.
- `LScheduler:type`: Returns the type name of this object as a string.
- `LScheduler:typeOf`: Checks whether this object matches the given type name. Accepts "LScheduler" or "Object".

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/timer/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### Recent sync (1.0.9-fix.73)

- Improved large-scheduler scaling:
  - `Scheduler::update` and `Scheduler::update_frames` switched from `retain` compaction to in-place `swap_remove` loops.
  - Reduces per-frame allocation and copy churn under high active timer counts.
- Added internal scheduler stress coverage:
  - Rust tests for 1500-2000 event update paths.
- Responsibility boundary clarification (`timer` vs `tween`):
  - `timer::Scheduler` owns callback scheduling and coarse event timing.
  - `tween` owns property interpolation and animation progression.
