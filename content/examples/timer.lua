-- content/examples/timer.lua
-- Practical usage examples for the lurek.timer API (43 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.timer.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/timer.lua

print("[example] lurek.timer — 43 API entries")

-- ── lurek.timer.* free functions ──

--@api-stub: lurek.timer.getDelta
-- Returns the delta time in seconds for the current frame.
-- Call when you need to read delta.
local ok, value = pcall(function() return lurek.timer.getDelta() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getDelta ->", v)

--@api-stub: lurek.timer.getFPS
-- Returns the current frames-per-second measurement.
-- Call when you need to read f p s.
local ok, value = pcall(function() return lurek.timer.getFPS() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getFPS ->", v)

--@api-stub: lurek.timer.getTime
-- Returns the total elapsed time since engine start in seconds.
-- Call when you need to read time.
local ok, value = pcall(function() return lurek.timer.getTime() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getTime ->", v)

--@api-stub: lurek.timer.getAverageDelta
-- Returns the rolling-average frame delta time in seconds.
-- Call when you need to read average delta.
local ok, value = pcall(function() return lurek.timer.getAverageDelta() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getAverageDelta ->", v)

--@api-stub: lurek.timer.getFrameCount
-- Returns the total number of frames rendered since engine start.
-- Call when you need to read frame count.
local ok, value = pcall(function() return lurek.timer.getFrameCount() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getFrameCount ->", v)

--@api-stub: lurek.timer.step
-- Advances the timer by one frame, returning the delta time.
-- Call when you need to invoke step.
local ok, result = pcall(function() return lurek.timer.step() end)
if not ok then print("action skipped:", result) end
print("lurek.timer.step fired=", ok)

--@api-stub: lurek.timer.getMicroTime
-- Returns the high-resolution elapsed time since engine start in seconds.
-- Call when you need to read micro time.
local ok, value = pcall(function() return lurek.timer.getMicroTime() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getMicroTime ->", v)

--@api-stub: lurek.timer.getPhysicsDelta
-- Returns the fixed timestep used by `process_physics` callbacks (seconds).
-- Call when you need to read physics delta.
local ok, value = pcall(function() return lurek.timer.getPhysicsDelta() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getPhysicsDelta ->", v)

--@api-stub: lurek.timer.setPhysicsDelta
-- Sets the fixed timestep for `process_physics` callbacks (seconds).
-- Call when you need to assign physics delta.
local ok, err = pcall(function() lurek.timer.setPhysicsDelta(1.0) end)
if not ok then print("set skipped:", err) end
print("lurek.timer.setPhysicsDelta applied=", ok)

--@api-stub: lurek.timer.getPhysicsMaxSteps
-- Returns the maximum number of physics sub-steps allowed per frame.
-- Call when you need to read physics max steps.
local ok, value = pcall(function() return lurek.timer.getPhysicsMaxSteps() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getPhysicsMaxSteps ->", v)

--@api-stub: lurek.timer.setPhysicsMaxSteps
-- Sets the maximum number of physics sub-steps allowed per frame (clamped 1â€“64).
-- Call when you need to assign physics max steps.
local ok, err = pcall(function() lurek.timer.setPhysicsMaxSteps(10) end)
if not ok then print("set skipped:", err) end
print("lurek.timer.setPhysicsMaxSteps applied=", ok)

--@api-stub: lurek.timer.sleep
-- Suspends execution for the given number of seconds.
-- Call when you need to invoke sleep.
local ok, result = pcall(function() return lurek.timer.sleep(1.0) end)
if ok then print("lurek.timer.sleep ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.timer.newScheduler
-- Creates a new independent Scheduler for managing timed callbacks.
-- Call when you need to create a new scheduler.
local ok, obj = pcall(function() return lurek.timer.newScheduler() end)
if ok and obj then print("created:", obj) end
print("lurek.timer.newScheduler ok=", ok)

--@api-stub: lurek.timer.chain
-- Creates a new Scheduler loaded with a sequenced one-shot chain.
-- Call when you need to invoke chain.
local ok, result = pcall(function() return lurek.timer.chain(nil) end)
if ok then print("lurek.timer.chain ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.timer.afterReal
-- Schedules a one-shot callback that fires after `delay` wall-clock seconds,.
-- Call when you need to invoke after real.
local ok, result = pcall(function() return lurek.timer.afterReal(1.0, function() end) end)
if ok then print("lurek.timer.afterReal ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.timer.tickRealTimers
-- Advances all real-time timers by one tick; called automatically each frame.
-- Call when you need to invoke tick real timers.
local ok, result = pcall(function() return lurek.timer.tickRealTimers() end)
if not ok then print("action skipped:", result) end
print("lurek.timer.tickRealTimers fired=", ok)

--@api-stub: lurek.timer.setSmoothingFactor
-- Sets the smoothing factor (alpha) for `getSmoothedDelta`.
-- Must be in [0.01, 1.0].
local ok, err = pcall(function() lurek.timer.setSmoothingFactor(1) end)
if not ok then print("set skipped:", err) end
print("lurek.timer.setSmoothingFactor applied=", ok)

--@api-stub: lurek.timer.getSmoothedDelta
-- Returns the exponential moving-average of frame deltas in seconds.
-- Call when you need to read smoothed delta.
local ok, value = pcall(function() return lurek.timer.getSmoothedDelta() end)
local v = ok and value or "(unavailable)"
print("lurek.timer.getSmoothedDelta ->", v)

--@api-stub: lurek.timer.waitSeconds
-- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
-- Call when you need to invoke wait seconds.
local ok, result = pcall(function() return lurek.timer.waitSeconds(1.0) end)
if ok then print("lurek.timer.waitSeconds ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.timer.waitFrames
-- Yields the current Lua coroutine for at least `frames` engine frames.
-- Call when you need to invoke wait frames.
local ok, result = pcall(function() return lurek.timer.waitFrames(nil) end)
if ok then print("lurek.timer.waitFrames ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.timer.tickWaits
-- Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
-- Call when you need to invoke tick waits.
local ok, result = pcall(function() return lurek.timer.tickWaits() end)
if not ok then print("action skipped:", result) end
print("lurek.timer.tickWaits fired=", ok)

-- ── Scheduler methods ──

--@api-stub: Scheduler:after
-- Schedules a callback to fire once after a delay.
-- Call when you need to invoke after.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:after(1.0, function() end) end)
  print("Scheduler:after ->", ok, result)
end

--@api-stub: Scheduler:afterFrames
-- Schedules a callback to fire once after `n` frames.
-- Call when you need to invoke after frames.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:afterFrames(10, function() end) end)
  print("Scheduler:afterFrames ->", ok, result)
end

--@api-stub: Scheduler:cancel
-- Cancels a scheduled event by its numeric ID.
-- Call when you need to invoke cancel.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:cancel(1) end)
  print("Scheduler:cancel ->", ok, result)
end

--@api-stub: Scheduler:cancelNamed
-- Cancels a scheduled event by its string name.
-- Call when you need to invoke cancel named.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:cancelNamed("name") end)
  print("Scheduler:cancelNamed ->", ok, result)
end

--@api-stub: Scheduler:cancelAll
-- Cancels all scheduled events and returns the count removed.
-- Call when you need to invoke cancel all.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:cancelAll() end)
  print("Scheduler:cancelAll ->", ok, result)
end

--@api-stub: Scheduler:pause
-- Pauses a scheduled event by its ID.
-- Call when you need to invoke pause.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:pause(1) end)
  print("Scheduler:pause ->", ok, result)
end

--@api-stub: Scheduler:resume
-- Resumes a paused event by its ID.
-- Call when you need to invoke resume.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:resume(1) end)
  print("Scheduler:resume ->", ok, result)
end

--@api-stub: Scheduler:isPaused
-- Returns whether the given event is currently paused.
-- Call when you need to check is paused.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:isPaused(1) end)
  print("Scheduler:isPaused ->", ok, result)
end

--@api-stub: Scheduler:pauseNamed
-- Pauses a scheduled event by its string name.
-- Call when you need to invoke pause named.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:pauseNamed("name") end)
  print("Scheduler:pauseNamed ->", ok, result)
end

--@api-stub: Scheduler:resumeNamed
-- Resumes a paused event by its string name.
-- Call when you need to invoke resume named.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:resumeNamed("name") end)
  print("Scheduler:resumeNamed ->", ok, result)
end

--@api-stub: Scheduler:isPausedNamed
-- Returns whether the named event is currently paused.
-- Call when you need to check is paused named.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:isPausedNamed("name") end)
  print("Scheduler:isPausedNamed ->", ok, result)
end

--@api-stub: Scheduler:getRemaining
-- Returns the seconds remaining until the next fire for an event, or nil.
-- Call when you need to read remaining.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:getRemaining(1) end)
  print("Scheduler:getRemaining ->", ok, result)
end

--@api-stub: Scheduler:getInterval
-- Returns the base interval in seconds for an event, or nil.
-- Call when you need to read interval.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:getInterval(1) end)
  print("Scheduler:getInterval ->", ok, result)
end

--@api-stub: Scheduler:getRepeatCount
-- Returns the repeat count remaining for an event, or nil.
-- Call when you need to read repeat count.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:getRepeatCount(1) end)
  print("Scheduler:getRepeatCount ->", ok, result)
end

--@api-stub: Scheduler:getCount
-- Returns the number of active scheduled events.
-- Call when you need to read count.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("Scheduler:getCount ->", ok, result)
end

--@api-stub: Scheduler:isEmpty
-- Returns whether the scheduler has no active events.
-- Call when you need to check is empty.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("Scheduler:isEmpty ->", ok, result)
end

--@api-stub: Scheduler:setInterval
-- Changes the repeat interval of an existing event.
-- Call when you need to assign interval.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:setInterval(1, nil) end)
  print("Scheduler:setInterval ->", ok, result)
end

--@api-stub: Scheduler:resetEvent
-- Resets an event's remaining time back to its original interval.
-- Call when you need to invoke reset event.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:resetEvent(1) end)
  print("Scheduler:resetEvent ->", ok, result)
end

--@api-stub: Scheduler:setTimeScale
-- Sets a global time-scale multiplier for this scheduler.
-- Call when you need to assign time scale.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:setTimeScale(1) end)
  print("Scheduler:setTimeScale ->", ok, result)
end

--@api-stub: Scheduler:getTimeScale
-- Returns the current time-scale multiplier.
-- Call when you need to read time scale.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:getTimeScale() end)
  print("Scheduler:getTimeScale ->", ok, result)
end

--@api-stub: Scheduler:update
-- Advances all timers by dt seconds, firing due callbacks.
-- Call when you need to invoke update.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Scheduler:update ->", ok, result)
end

--@api-stub: Scheduler:updateFrames
-- Advances frame-based events by one frame, firing due callbacks.
-- Call when you need to invoke update frames.
-- Build a Scheduler via the appropriate lurek.timer.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.timer.newScheduler(...)
if instance then
  local ok, result = pcall(function() return instance:updateFrames() end)
  print("Scheduler:updateFrames ->", ok, result)
end

