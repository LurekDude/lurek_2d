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

- `Clock::new` (`clock.rs`): Creates a new `Clock`, recording the current instant as the start time.
- `Clock::tick` (`clock.rs`): Advances the clock by one frame, updating delta time, total time, and rolling FPS.
- `Clock::delta` (`clock.rs`): Returns the delta time for the most recently completed frame in seconds.
- `Clock::total` (`clock.rs`): Returns the total elapsed time since the clock was created, in seconds.
- `Clock::fps` (`clock.rs`): Returns the rolling frames-per-second measurement.
- `Clock::frame_count` (`clock.rs`): Returns the total number of frames that have elapsed since the clock was created.
- `Clock::elapsed` (`clock.rs`): Returns a live high-resolution elapsed time since the clock was created, in seconds.
- `Clock::average_delta` (`clock.rs`): Returns the average delta time over the last N frames (up to 60).
- `Scheduler::new` (`scheduler.rs`): Create a new empty Scheduler with time-scale 1.0.
- `Scheduler::after` (`scheduler.rs`): Schedule a one-shot callback after `delay` seconds.
- `Scheduler::after_named` (`scheduler.rs`): Schedule a one-shot callback with a `name` for cancel-by-name support.
- `Scheduler::every` (`scheduler.rs`): Schedule a repeating callback at `interval` seconds.
- `Scheduler::every_named` (`scheduler.rs`): Schedule a named repeating callback.
- `Scheduler::after_frames` (`scheduler.rs`): Schedule a one-shot event that fires after `n` frames.
- `Scheduler::every_frames` (`scheduler.rs`): Schedule a repeating event that fires every `n` frames.
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
- `Scheduler::update_frames` (`scheduler.rs`): Advance all non-paused frame-based events by one frame.
- `Scheduler::count` (`scheduler.rs`): Get the number of active (non-expired) scheduled events.
- `Scheduler::active_ids` (`scheduler.rs`): Get the IDs of all active events.
- `Scheduler::is_empty` (`scheduler.rs`): Returns `true` if no events are scheduled.
- `sleep` (`sleep.rs`): Suspends the current thread for the given number of seconds.

## Lua API Reference

- Binding path(s): `src/lua_api/timer_api.rs`
- Namespace: `lurek.timer`

### Module Functions
- `lurek.timer.getDelta`: Returns the time elapsed since the previous frame in seconds.
- `lurek.timer.getFPS`: Returns the current instantaneous frames-per-second as measured by the engine clock.
- `lurek.timer.getTime`: Returns the total wall-clock time that has elapsed since the engine was initialised, in seconds.
- `lurek.timer.getAverageDelta`: Returns a rolling average of recent frame delta times in seconds.
- `lurek.timer.getFrameCount`: Returns the total number of frames that have been rendered since the engine was initialised.
- `lurek.timer.step`: Manually advances the engine timer by one frame tick and returns the resulting delta time.
- `lurek.timer.getMicroTime`: Returns the high-resolution (microsecond-precision) elapsed time since engine start in seconds.
- `lurek.timer.getPhysicsDelta`: Returns the fixed timestep interval used by the `process_physics` callback loop, in seconds.
- `lurek.timer.setPhysicsDelta`: Sets the fixed timestep interval for the `process_physics` callback loop, in seconds.
- `lurek.timer.getPhysicsMaxSteps`: Returns the maximum number of physics simulation sub-steps that the engine will perform in a single frame.
- `lurek.timer.setPhysicsMaxSteps`: Sets the maximum number of physics simulation sub-steps allowed per frame.
- `lurek.timer.sleep`: Blocks the current thread for the specified number of seconds using an OS-level sleep.
- `lurek.timer.newScheduler`: Creates and returns a new independent Scheduler userdata object for managing timed and frame-based callbacks.
- `lurek.timer.chain`: Creates a new Scheduler pre-loaded with a sequence of one-shot callbacks that fire in order with cumulative delays.
- `lurek.timer.afterReal`: Schedules a one-shot callback that fires after `delay` wall-clock seconds, completely unaffected by the engine's time scale or pause state.
- `lurek.timer.tickRealTimers`: Checks all registered real-time timers and fires any whose wall-clock deadline has passed.
- `lurek.timer.setSmoothingFactor`: Sets the exponential moving-average smoothing factor (alpha) used by `getSmoothedDelta`.
- `lurek.timer.getSmoothedDelta`: Returns the exponentially smoothed frame delta time in seconds.
- `lurek.timer.waitSeconds`: Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
- `lurek.timer.waitFrames`: Yields the current Lua coroutine until at least `frames` engine frames have elapsed.
- `lurek.timer.tickWaits`: Resumes all coroutines waiting via `waitSeconds` or `waitFrames` whose deadline or frame target has been reached.

### `LScheduler` Methods
- `LScheduler:after`: Schedules a callback to fire once after a delay.
- `LScheduler:afterFrames`: Schedules a callback to fire once after `n` frames.
- `LScheduler:afterNamed`: Schedules a named one-shot callback, replacing any existing event with the same name.
- `LScheduler:every`: Schedules a callback to fire repeatedly at the given interval.
- `LScheduler:everyFrames`: Schedules a callback to fire every `n` frames.
- `LScheduler:everyNamed`: Schedules a named repeating callback, replacing any existing event with the same name.
- `LScheduler:cancel`: Cancels a scheduled event by its numeric ID.
- `LScheduler:cancelNamed`: Cancels and removes a previously scheduled event identified by its string name assigned via `afterNamed` or `everyNamed`.
- `LScheduler:cancelAll`: Cancels all scheduled events and returns the count removed.
- `LScheduler:pause`: Pauses a scheduled event by its ID.
- `LScheduler:resume`: Resumes a paused event by its ID.
- `LScheduler:isPaused`: Returns whether the given event is currently paused.
- `LScheduler:pauseNamed`: Temporarily suspends the named scheduled event so it stops accumulating time.
- `LScheduler:resumeNamed`: Resumes a previously paused named event so it continues accumulating time.
- `LScheduler:isPausedNamed`: Checks whether the named scheduled event is currently in the paused state.
- `LScheduler:getRemaining`: Returns whether the event exists and how many seconds remain until it fires next.
- `LScheduler:getInterval`: Returns whether the event exists and its configured base interval in seconds.
- `LScheduler:getRepeatCount`: Returns whether the event exists and its remaining repetition count.
- `LScheduler:getCount`: Returns the total number of currently active (not yet completed or cancelled) events in this scheduler instance.
- `LScheduler:isEmpty`: Returns true if this scheduler has zero active events.
- `LScheduler:setInterval`: Modifies the repeat interval of an already-scheduled repeating event.
- `LScheduler:resetEvent`: Resets the countdown for a scheduled event back to its full configured interval, as if it had just been created.
- `LScheduler:setTimeScale`: Sets a time-scale multiplier that affects all events in this scheduler.
- `LScheduler:getTimeScale`: Returns the current time-scale multiplier for this scheduler instance.
- `LScheduler:update`: Advances all time-based events in this scheduler by `dt` seconds (scaled by the scheduler's time-scale multiplier).
- `LScheduler:updateFrames`: Advances all frame-based events by one frame tick.
- `LScheduler:type`: Returns the string type name of this userdata object.
- `LScheduler:typeOf`: Checks whether this object matches the given type name.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/timer/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
