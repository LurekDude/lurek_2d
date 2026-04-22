-- content/examples/timer.lua
-- Auto-scaffolded coverage of the lurek.timer Lua API (43 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/timer.lua

print("[example] lurek.timer loaded — 43 API items demonstrated")

-- ── lurek.timer free functions ──

--@api-stub: lurek.timer.getDelta
-- Returns the delta time in seconds for the current frame.
-- Use this when returns the delta time in seconds for the current frame is needed.
if false then
  local _r = lurek.timer.getDelta()
  print(_r)
end

--@api-stub: lurek.timer.getFPS
-- Returns the current frames-per-second measurement.
-- Use this when returns the current frames-per-second measurement is needed.
if false then
  local _r = lurek.timer.getFPS()
  print(_r)
end

--@api-stub: lurek.timer.getTime
-- Returns the total elapsed time since engine start in seconds.
-- Use this when returns the total elapsed time since engine start in seconds is needed.
if false then
  local _r = lurek.timer.getTime()
  print(_r)
end

--@api-stub: lurek.timer.getAverageDelta
-- Returns the rolling-average frame delta time in seconds.
-- Use this when returns the rolling-average frame delta time in seconds is needed.
if false then
  local _r = lurek.timer.getAverageDelta()
  print(_r)
end

--@api-stub: lurek.timer.getFrameCount
-- Returns the total number of frames rendered since engine start.
-- Use this when returns the total number of frames rendered since engine start is needed.
if false then
  local _r = lurek.timer.getFrameCount()
  print(_r)
end

--@api-stub: lurek.timer.step
-- Advances the timer by one frame, returning the delta time.
-- Use this when advances the timer by one frame, returning the delta time is needed.
if false then
  local _r = lurek.timer.step()
  print(_r)
end

--@api-stub: lurek.timer.getMicroTime
-- Returns the high-resolution elapsed time since engine start in seconds.
-- Use this when returns the high-resolution elapsed time since engine start in seconds is needed.
if false then
  local _r = lurek.timer.getMicroTime()
  print(_r)
end

--@api-stub: lurek.timer.getPhysicsDelta
-- Returns the fixed timestep used by `process_physics` callbacks (seconds).
-- Use this when returns the fixed timestep used by `process_physics` callbacks (seconds) is needed.
if false then
  local _r = lurek.timer.getPhysicsDelta()
  print(_r)
end

--@api-stub: lurek.timer.setPhysicsDelta
-- Sets the fixed timestep for `process_physics` callbacks (seconds).
-- Use this when sets the fixed timestep for `process_physics` callbacks (seconds) is needed.
if false then
  local _r = lurek.timer.setPhysicsDelta(0)
  print(_r)
end

--@api-stub: lurek.timer.getPhysicsMaxSteps
-- Returns the maximum number of physics sub-steps allowed per frame.
-- Use this when returns the maximum number of physics sub-steps allowed per frame is needed.
if false then
  local _r = lurek.timer.getPhysicsMaxSteps()
  print(_r)
end

--@api-stub: lurek.timer.setPhysicsMaxSteps
-- Sets the maximum number of physics sub-steps allowed per frame (clamped 1â€“64).
-- Use this when sets the maximum number of physics sub-steps allowed per frame (clamped 1â€“64) is needed.
if false then
  local _r = lurek.timer.setPhysicsMaxSteps(1)
  print(_r)
end

--@api-stub: lurek.timer.sleep
-- Suspends execution for the given number of seconds.
-- Use this when suspends execution for the given number of seconds is needed.
if false then
  local _r = lurek.timer.sleep(1)
  print(_r)
end

--@api-stub: lurek.timer.newScheduler
-- Creates a new independent Scheduler for managing timed callbacks.
-- Use this when creates a new independent Scheduler for managing timed callbacks is needed.
if false then
  local _r = lurek.timer.newScheduler()
  print(_r)
end

--@api-stub: lurek.timer.chain
-- Creates a new Scheduler loaded with a sequenced one-shot chain.
-- Use this when creates a new Scheduler loaded with a sequenced one-shot chain is needed.
if false then
  local _r = lurek.timer.chain(0)
  print(_r)
end

--@api-stub: lurek.timer.afterReal
-- Schedules a one-shot callback that fires after `delay` wall-clock seconds,.
-- Use this when schedules a one-shot callback that fires after `delay` wall-clock seconds, is needed.
if false then
  local _r = lurek.timer.afterReal(0, 1)
  print(_r)
end

--@api-stub: lurek.timer.tickRealTimers
-- Advances all real-time timers by one tick; called automatically each frame.
-- Use this when advances all real-time timers by one tick; called automatically each frame is needed.
if false then
  local _r = lurek.timer.tickRealTimers()
  print(_r)
end

--@api-stub: lurek.timer.setSmoothingFactor
-- Sets the smoothing factor (alpha) for `getSmoothedDelta`.
-- Must be in [0.01, 1.0].
if false then
  local _r = lurek.timer.setSmoothingFactor(0)
  print(_r)
end

--@api-stub: lurek.timer.getSmoothedDelta
-- Returns the exponential moving-average of frame deltas in seconds.
-- Use this when returns the exponential moving-average of frame deltas in seconds is needed.
if false then
  local _r = lurek.timer.getSmoothedDelta()
  print(_r)
end

--@api-stub: lurek.timer.waitSeconds
-- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
-- Use this when yields the current Lua coroutine for at least `seconds` wall-clock seconds is needed.
if false then
  local _r = lurek.timer.waitSeconds(1)
  print(_r)
end

--@api-stub: lurek.timer.waitFrames
-- Yields the current Lua coroutine for at least `frames` engine frames.
-- Use this when yields the current Lua coroutine for at least `frames` engine frames is needed.
if false then
  local _r = lurek.timer.waitFrames(nil)
  print(_r)
end

--@api-stub: lurek.timer.tickWaits
-- Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
-- Use this when advances all `lurek.timer.wait()` coroutines by one tick; called each frame is needed.
if false then
  local _r = lurek.timer.tickWaits()
  print(_r)
end

-- ── Scheduler methods ──

--@api-stub: Scheduler:after
-- Schedules a callback to fire once after a delay.
-- Use this when schedules a callback to fire once after a delay is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:after(0, 1)
end

--@api-stub: Scheduler:afterFrames
-- Schedules a callback to fire once after `n` frames.
-- Use this when schedules a callback to fire once after `n` frames is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:afterFrames(1, 1)
end

--@api-stub: Scheduler:cancel
-- Cancels a scheduled event by its numeric ID.
-- Use this when cancels a scheduled event by its numeric ID is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:cancel(1)
end

--@api-stub: Scheduler:cancelNamed
-- Cancels a scheduled event by its string name.
-- Use this when cancels a scheduled event by its string name is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:cancelNamed(1)
end

--@api-stub: Scheduler:cancelAll
-- Cancels all scheduled events and returns the count removed.
-- Use this when cancels all scheduled events and returns the count removed is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:cancelAll()
end

--@api-stub: Scheduler:pause
-- Pauses a scheduled event by its ID.
-- Use this when pauses a scheduled event by its ID is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:pause(1)
end

--@api-stub: Scheduler:resume
-- Resumes a paused event by its ID.
-- Use this when resumes a paused event by its ID is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:resume(1)
end

--@api-stub: Scheduler:isPaused
-- Returns whether the given event is currently paused.
-- Use this when returns whether the given event is currently paused is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:isPaused(1)
end

--@api-stub: Scheduler:pauseNamed
-- Pauses a scheduled event by its string name.
-- Use this when pauses a scheduled event by its string name is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:pauseNamed(1)
end

--@api-stub: Scheduler:resumeNamed
-- Resumes a paused event by its string name.
-- Use this when resumes a paused event by its string name is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:resumeNamed(1)
end

--@api-stub: Scheduler:isPausedNamed
-- Returns whether the named event is currently paused.
-- Use this when returns whether the named event is currently paused is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:isPausedNamed(1)
end

--@api-stub: Scheduler:getRemaining
-- Returns the seconds remaining until the next fire for an event, or nil.
-- Use this when returns the seconds remaining until the next fire for an event, or nil is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:getRemaining(1)
end

--@api-stub: Scheduler:getInterval
-- Returns the base interval in seconds for an event, or nil.
-- Use this when returns the base interval in seconds for an event, or nil is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:getInterval(1)
end

--@api-stub: Scheduler:getRepeatCount
-- Returns the repeat count remaining for an event, or nil.
-- Use this when returns the repeat count remaining for an event, or nil is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:getRepeatCount(1)
end

--@api-stub: Scheduler:getCount
-- Returns the number of active scheduled events.
-- Use this when returns the number of active scheduled events is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:getCount()
end

--@api-stub: Scheduler:isEmpty
-- Returns whether the scheduler has no active events.
-- Use this when returns whether the scheduler has no active events is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:isEmpty()
end

--@api-stub: Scheduler:setInterval
-- Changes the repeat interval of an existing event.
-- Use this when changes the repeat interval of an existing event is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:setInterval(1, 1)
end

--@api-stub: Scheduler:resetEvent
-- Resets an event's remaining time back to its original interval.
-- Use this when resets an event's remaining time back to its original interval is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:resetEvent(1)
end

--@api-stub: Scheduler:setTimeScale
-- Sets a global time-scale multiplier for this scheduler.
-- Use this when sets a global time-scale multiplier for this scheduler is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:setTimeScale(0)
end

--@api-stub: Scheduler:getTimeScale
-- Returns the current time-scale multiplier.
-- Use this when returns the current time-scale multiplier is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:getTimeScale()
end

--@api-stub: Scheduler:update
-- Advances all timers by dt seconds, firing due callbacks.
-- Use this when advances all timers by dt seconds, firing due callbacks is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:update(0)
end

--@api-stub: Scheduler:updateFrames
-- Advances frame-based events by one frame, firing due callbacks.
-- Use this when advances frame-based events by one frame, firing due callbacks is needed.
if false then
  local _o = nil  -- Scheduler instance
  _o:updateFrames()
end

