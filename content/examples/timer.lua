-- content/examples/timer.lua
-- Scaffolded coverage of the lurek.timer API (43 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/timer_api.rs   (Lua binding, arg types, return shape)
--   * src/timer/                 (semantics, side effects)
--   * docs/specs/timer.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/timer.lua

-- ── lurek.timer.* functions ──

--@api-stub: lurek.timer.getDelta
-- Returns the delta time in seconds for the current frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getDelta
  local _todo = "TODO: write a real lurek.timer.getDelta usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getFPS
-- Returns the current frames-per-second measurement.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getFPS
  local _todo = "TODO: write a real lurek.timer.getFPS usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getTime
-- Returns the total elapsed time since engine start in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getTime
  local _todo = "TODO: write a real lurek.timer.getTime usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getAverageDelta
-- Returns the rolling-average frame delta time in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getAverageDelta
  local _todo = "TODO: write a real lurek.timer.getAverageDelta usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getFrameCount
-- Returns the total number of frames rendered since engine start.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getFrameCount
  local _todo = "TODO: write a real lurek.timer.getFrameCount usage example"
  print(_todo)
end

--@api-stub: lurek.timer.step
-- Advances the timer by one frame, returning the delta time.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.step
  local _todo = "TODO: write a real lurek.timer.step usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getMicroTime
-- Returns the high-resolution elapsed time since engine start in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getMicroTime
  local _todo = "TODO: write a real lurek.timer.getMicroTime usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getPhysicsDelta
-- Returns the fixed timestep used by `process_physics` callbacks (seconds).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getPhysicsDelta
  local _todo = "TODO: write a real lurek.timer.getPhysicsDelta usage example"
  print(_todo)
end

--@api-stub: lurek.timer.setPhysicsDelta
-- Sets the fixed timestep for `process_physics` callbacks (seconds).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.setPhysicsDelta
  local _todo = "TODO: write a real lurek.timer.setPhysicsDelta usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getPhysicsMaxSteps
-- Returns the maximum number of physics sub-steps allowed per frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getPhysicsMaxSteps
  local _todo = "TODO: write a real lurek.timer.getPhysicsMaxSteps usage example"
  print(_todo)
end

--@api-stub: lurek.timer.setPhysicsMaxSteps
-- Sets the maximum number of physics sub-steps allowed per frame (clamped 1â€“64).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.setPhysicsMaxSteps
  local _todo = "TODO: write a real lurek.timer.setPhysicsMaxSteps usage example"
  print(_todo)
end

--@api-stub: lurek.timer.sleep
-- Suspends execution for the given number of seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.sleep
  local _todo = "TODO: write a real lurek.timer.sleep usage example"
  print(_todo)
end

--@api-stub: lurek.timer.newScheduler
-- Creates a new independent Scheduler for managing timed callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.newScheduler
  local _todo = "TODO: write a real lurek.timer.newScheduler usage example"
  print(_todo)
end

--@api-stub: lurek.timer.chain
-- Creates a new Scheduler loaded with a sequenced one-shot chain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.chain
  local _todo = "TODO: write a real lurek.timer.chain usage example"
  print(_todo)
end

--@api-stub: lurek.timer.afterReal
-- Schedules a one-shot callback that fires after `delay` wall-clock seconds,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.afterReal
  local _todo = "TODO: write a real lurek.timer.afterReal usage example"
  print(_todo)
end

--@api-stub: lurek.timer.tickRealTimers
-- Advances all real-time timers by one tick; called automatically each frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.tickRealTimers
  local _todo = "TODO: write a real lurek.timer.tickRealTimers usage example"
  print(_todo)
end

--@api-stub: lurek.timer.setSmoothingFactor
-- Sets the smoothing factor (alpha) for `getSmoothedDelta`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.setSmoothingFactor
  local _todo = "TODO: write a real lurek.timer.setSmoothingFactor usage example"
  print(_todo)
end

--@api-stub: lurek.timer.getSmoothedDelta
-- Returns the exponential moving-average of frame deltas in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.getSmoothedDelta
  local _todo = "TODO: write a real lurek.timer.getSmoothedDelta usage example"
  print(_todo)
end

--@api-stub: lurek.timer.waitSeconds
-- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.waitSeconds
  local _todo = "TODO: write a real lurek.timer.waitSeconds usage example"
  print(_todo)
end

--@api-stub: lurek.timer.waitFrames
-- Yields the current Lua coroutine for at least `frames` engine frames.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.waitFrames
  local _todo = "TODO: write a real lurek.timer.waitFrames usage example"
  print(_todo)
end

--@api-stub: lurek.timer.tickWaits
-- Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: lurek.timer.tickWaits
  local _todo = "TODO: write a real lurek.timer.tickWaits usage example"
  print(_todo)
end

-- ── Scheduler methods ──

--@api-stub: Scheduler:after
-- Schedules a callback to fire once after a delay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:after
  local _todo = "TODO: write a real Scheduler:after usage example"
  print(_todo)
end

--@api-stub: Scheduler:afterFrames
-- Schedules a callback to fire once after `n` frames.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:afterFrames
  local _todo = "TODO: write a real Scheduler:afterFrames usage example"
  print(_todo)
end

--@api-stub: Scheduler:cancel
-- Cancels a scheduled event by its numeric ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:cancel
  local _todo = "TODO: write a real Scheduler:cancel usage example"
  print(_todo)
end

--@api-stub: Scheduler:cancelNamed
-- Cancels a scheduled event by its string name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:cancelNamed
  local _todo = "TODO: write a real Scheduler:cancelNamed usage example"
  print(_todo)
end

--@api-stub: Scheduler:cancelAll
-- Cancels all scheduled events and returns the count removed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:cancelAll
  local _todo = "TODO: write a real Scheduler:cancelAll usage example"
  print(_todo)
end

--@api-stub: Scheduler:pause
-- Pauses a scheduled event by its ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:pause
  local _todo = "TODO: write a real Scheduler:pause usage example"
  print(_todo)
end

--@api-stub: Scheduler:resume
-- Resumes a paused event by its ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:resume
  local _todo = "TODO: write a real Scheduler:resume usage example"
  print(_todo)
end

--@api-stub: Scheduler:isPaused
-- Returns whether the given event is currently paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:isPaused
  local _todo = "TODO: write a real Scheduler:isPaused usage example"
  print(_todo)
end

--@api-stub: Scheduler:pauseNamed
-- Pauses a scheduled event by its string name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:pauseNamed
  local _todo = "TODO: write a real Scheduler:pauseNamed usage example"
  print(_todo)
end

--@api-stub: Scheduler:resumeNamed
-- Resumes a paused event by its string name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:resumeNamed
  local _todo = "TODO: write a real Scheduler:resumeNamed usage example"
  print(_todo)
end

--@api-stub: Scheduler:isPausedNamed
-- Returns whether the named event is currently paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:isPausedNamed
  local _todo = "TODO: write a real Scheduler:isPausedNamed usage example"
  print(_todo)
end

--@api-stub: Scheduler:getRemaining
-- Returns the seconds remaining until the next fire for an event, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:getRemaining
  local _todo = "TODO: write a real Scheduler:getRemaining usage example"
  print(_todo)
end

--@api-stub: Scheduler:getInterval
-- Returns the base interval in seconds for an event, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:getInterval
  local _todo = "TODO: write a real Scheduler:getInterval usage example"
  print(_todo)
end

--@api-stub: Scheduler:getRepeatCount
-- Returns the repeat count remaining for an event, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:getRepeatCount
  local _todo = "TODO: write a real Scheduler:getRepeatCount usage example"
  print(_todo)
end

--@api-stub: Scheduler:getCount
-- Returns the number of active scheduled events.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:getCount
  local _todo = "TODO: write a real Scheduler:getCount usage example"
  print(_todo)
end

--@api-stub: Scheduler:isEmpty
-- Returns whether the scheduler has no active events.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:isEmpty
  local _todo = "TODO: write a real Scheduler:isEmpty usage example"
  print(_todo)
end

--@api-stub: Scheduler:setInterval
-- Changes the repeat interval of an existing event.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:setInterval
  local _todo = "TODO: write a real Scheduler:setInterval usage example"
  print(_todo)
end

--@api-stub: Scheduler:resetEvent
-- Resets an event's remaining time back to its original interval.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:resetEvent
  local _todo = "TODO: write a real Scheduler:resetEvent usage example"
  print(_todo)
end

--@api-stub: Scheduler:setTimeScale
-- Sets a global time-scale multiplier for this scheduler.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:setTimeScale
  local _todo = "TODO: write a real Scheduler:setTimeScale usage example"
  print(_todo)
end

--@api-stub: Scheduler:getTimeScale
-- Returns the current time-scale multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:getTimeScale
  local _todo = "TODO: write a real Scheduler:getTimeScale usage example"
  print(_todo)
end

--@api-stub: Scheduler:update
-- Advances all timers by dt seconds, firing due callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:update
  local _todo = "TODO: write a real Scheduler:update usage example"
  print(_todo)
end

--@api-stub: Scheduler:updateFrames
-- Advances frame-based events by one frame, firing due callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/timer_api.rs and docs/specs/timer.md).
do  -- TODO: Scheduler:updateFrames
  local _todo = "TODO: write a real Scheduler:updateFrames usage example"
  print(_todo)
end

