-- content/examples/timer.lua
-- lurek.timer API examples.
-- Run: cargo run -- content/examples/timer.lua

--@api-stub: lurek.timer.getDelta
-- Returns the time in seconds elapsed since the last frame
do
  function lurek.process()
    local dt = lurek.timer.getDelta()
    local speed = 200
    local x = 0
    x = x + speed * dt
  end
end

--@api-stub: lurek.timer.getFPS
-- Returns the current frames-per-second count
do
  function lurek.draw_ui()
    local fps = lurek.timer.getFPS()
    if fps < 30 then
      lurek.log.warn("low fps: " .. fps, "perf")
    end
  end
end

--@api-stub: lurek.timer.getTime
-- Returns the total elapsed game time in seconds since the engine started
do
  function lurek.draw()
    local t = lurek.timer.getTime()
    local pulse = 0.5 + 0.5 * math.sin(t * 2.0)
    lurek.log.debug("pulse=" .. pulse, "fx")
  end
end

--@api-stub: lurek.timer.getAverageDelta
-- Returns the smoothed average delta time in seconds over a recent window of frames
do
  function lurek.process()
    local avg = lurek.timer.getAverageDelta()
    local budget_ms = avg * 1000
    if budget_ms > 20 then
      lurek.log.warn("frame budget exceeded: " .. budget_ms .. "ms", "perf")
    end
  end
end

--@api-stub: lurek.timer.getFrameCount
-- Returns the total number of frames rendered since the engine started
do
  function lurek.process()
    local n = lurek.timer.getFrameCount()
    if n % 60 == 0 then
      lurek.log.info("frame " .. n, "tick")
    end
  end
end

--@api-stub: lurek.timer.step
-- Advances the internal clock by one tick and returns the delta time for that tick
do
  function lurek.process()
    local dt = lurek.timer.step()
    local accumulator = 0
    accumulator = accumulator + dt
  end
end

--@api-stub: lurek.timer.getMicroTime
-- Returns high-resolution elapsed time in seconds since engine start
do
  local t0 = lurek.timer.getMicroTime()
  local sum = 0
  for i = 1, 10000 do sum = sum + i end
  local elapsed = lurek.timer.getMicroTime() - t0
  lurek.log.debug("loop took " .. elapsed .. "s, sum=" .. sum, "bench")
end

--@api-stub: lurek.timer.getPhysicsDelta
-- Returns the fixed timestep used for physics simulation in seconds
do
  local pdt = lurek.timer.getPhysicsDelta()
  local hz = 1.0 / pdt
  lurek.log.info("physics step: " .. pdt .. "s (" .. hz .. "Hz)", "physics")
end

--@api-stub: lurek.timer.setPhysicsDelta
-- Sets the fixed timestep for physics simulation
do
  lurek.timer.setPhysicsDelta(1 / 120)
  local pdt = lurek.timer.getPhysicsDelta()
  lurek.log.info("physics now stepping at " .. (1.0 / pdt) .. "Hz", "physics")
end

--@api-stub: lurek.timer.getPhysicsMaxSteps
-- Returns the maximum number of physics steps allowed per frame
do
  local max_steps = lurek.timer.getPhysicsMaxSteps()
  if max_steps < 4 then
    lurek.log.warn("physics may stutter on slow frames: max_steps=" .. max_steps, "physics")
  end
end

--@api-stub: lurek.timer.setPhysicsMaxSteps
-- Sets the maximum number of physics steps allowed per frame
do
  lurek.timer.setPhysicsMaxSteps(8)
  local n = lurek.timer.getPhysicsMaxSteps()
  lurek.log.info("physics catch-up cap = " .. n, "physics")
end

--@api-stub: lurek.timer.sleep
-- Blocks the current thread for the given number of seconds
do
  local before = lurek.timer.getMicroTime()
  lurek.timer.sleep(0.05)
  local elapsed = lurek.timer.getMicroTime() - before
  lurek.log.debug("slept ~" .. elapsed .. "s", "tools")
end

--@api-stub: lurek.timer.newScheduler
-- Creates a new LScheduler instance for managing timed and frame-based callbacks independently from the global timer
do
  local boss_timers = lurek.timer.newScheduler()
  boss_timers:after(2.5, function() lurek.log.info("boss enrages", "ai") end)
  function lurek.process(dt) boss_timers:update(dt) end
end

--@api-stub: lurek.timer.chain
-- Creates a scheduler pre-loaded with a sequence of delayed callbacks
do
  local intro = lurek.timer.chain({
    { delay = 0.0, func = function() lurek.log.info("scene: fade in", "cutscene") end },
    { delay = 1.5, func = function() lurek.log.info("scene: dialog", "cutscene") end },
    { delay = 2.0, func = function() lurek.log.info("scene: gameplay", "cutscene") end },
  })
  function lurek.process(dt) intro:update(dt) end
end

--@api-stub: lurek.timer.afterReal
-- Schedules a one-shot callback based on real (wall-clock) time, unaffected by game pausing or time scaling
do
  lurek.timer.afterReal(3.0, function()
    lurek.log.info("3 real seconds elapsed", "ui")
  end)
  function lurek.process() lurek.timer.tickRealTimers() end
end

--@api-stub: lurek.timer.tickRealTimers
-- Checks all real-time timers and fires any whose deadline has passed
do
  lurek.timer.afterReal(0.25, function() lurek.log.debug("toast hide", "ui") end)
  function lurek.process()
    local fired = lurek.timer.tickRealTimers()
    if fired > 0 then lurek.log.debug("real timers fired: " .. fired, "ui") end
  end
end

--@api-stub: lurek.timer.setSmoothingFactor
-- Sets the exponential smoothing factor used by getSmoothedDelta
do
  lurek.timer.setSmoothingFactor(0.1)
  function lurek.process()
    local sdt = lurek.timer.getSmoothedDelta()
    lurek.log.debug("smoothed dt=" .. sdt, "perf")
  end
end

--@api-stub: lurek.timer.getSmoothedDelta
-- Returns an exponentially smoothed delta time in seconds, reducing frame-to-frame jitter
do
  function lurek.draw_ui()
    local sdt = lurek.timer.getSmoothedDelta()
    local ms = sdt * 1000
    lurek.log.debug(string.format("frame %.2fms", ms), "hud")
  end
end

--@api-stub: lurek.timer.waitSeconds
-- Yields the current coroutine for the given number of real-time seconds
do
  local co = coroutine.wrap(function()
    lurek.log.info("phase 1", "intro")
    lurek.timer.waitSeconds(1.0)
    lurek.log.info("phase 2", "intro")
  end)
  function lurek.init() co() end
  function lurek.process() lurek.timer.tickWaits() end
end

--@api-stub: lurek.timer.waitFrames
-- Yields the current coroutine for the given number of frames
do
  local co = coroutine.wrap(function()
    lurek.log.debug("waiting 60 frames", "test")
    lurek.timer.waitFrames(60)
    lurek.log.debug("60 frames done", "test")
  end)
  function lurek.init() co() end
  function lurek.process() lurek.timer.tickWaits() end
end

--@api-stub: lurek.timer.tickWaits
-- Checks all pending waitSeconds and waitFrames coroutines, resumes any whose deadline or frame target has been reached, and cleans up completed entries
do
  function lurek.process()
    local resumed = lurek.timer.tickWaits()
    if resumed > 0 then
      lurek.log.debug("resumed " .. resumed .. " coroutines", "timer")
    end
  end
end

-- Scheduler methods

--@api-stub: Scheduler:after
-- Performs the after operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:after(1.5, function() lurek.log.info("spawn wave", "ai") end)
  lurek.log.debug("scheduled id=" .. id, "timer")
  function lurek.process(dt) sched:update(dt) end
end

--@api-stub: Scheduler:afterFrames
-- Performs the after frames operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:afterFrames(30, function() lurek.log.debug("30 frames in", "test") end)
  function lurek.process() sched:updateFrames() end
end

--@api-stub: Scheduler:cancel
-- Cancels the current operation of this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:after(5.0, function() lurek.log.info("never fires", "demo") end)
  local ok = sched:cancel(id)
  lurek.log.debug("cancel returned " .. tostring(ok), "timer")
end

--@api-stub: Scheduler:cancelNamed
-- Performs the cancel named operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:afterNamed("invuln", 2.0, function() lurek.log.debug("invuln end", "combat") end)
  local cancelled = sched:cancelNamed("invuln")
  lurek.log.debug("invuln cancelled=" .. tostring(cancelled), "combat")
end

--@api-stub: Scheduler:cancelAll
-- Performs the cancel all operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:after(1, function() end)
  sched:every(0.5, function() end)
  local removed = sched:cancelAll()
  lurek.log.info("dropped " .. removed .. " timers on scene exit", "scene")
end

--@api-stub: Scheduler:pause
-- Pauses the current operation or playback on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(1.0, function() lurek.log.debug("tick", "ai") end)
  sched:pause(id)
  lurek.log.debug("paused id=" .. id, "ai")
end

--@api-stub: Scheduler:resume
-- Resumes a previously paused operation or playback on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(0.5, function() end)
  sched:pause(id)
  local ok = sched:resume(id)
  lurek.log.debug("resume returned " .. tostring(ok), "timer")
end

--@api-stub: Scheduler:isPaused
-- Returns true if this scheduler paused.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(2.0, function() end)
  sched:pause(id)
  if sched:isPaused(id) then
    lurek.log.debug("timer " .. id .. " is paused", "ui")
  end
end

--@api-stub: Scheduler:pauseNamed
-- Pauses the current operation or playback on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("regen", 1.0, function() lurek.log.debug("+1 hp", "rpg") end)
  sched:pauseNamed("regen")
  lurek.log.debug("regen paused", "rpg")
end

--@api-stub: Scheduler:resumeNamed
-- Resumes a previously paused operation or playback on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("regen", 1.0, function() end)
  sched:pauseNamed("regen")
  local ok = sched:resumeNamed("regen")
  lurek.log.debug("regen resumed=" .. tostring(ok), "rpg")
end

--@api-stub: Scheduler:isPausedNamed
-- Returns true if this scheduler paused named.
do
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("spawn", 5.0, function() end)
  sched:pauseNamed("spawn")
  if sched:isPausedNamed("spawn") then
    lurek.log.debug("spawner paused", "ai")
  end
end

--@api-stub: Scheduler:getRemaining
-- Returns the remaining of this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:after(3.0, function() end)
  local found, remaining = sched:getRemaining(id)
  if found then
    lurek.log.debug(string.format("ready in %.1fs", remaining), "cooldown")
  end
end

--@api-stub: Scheduler:getInterval
-- Returns the interval of this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(2.5, function() end)
  local found, interval = sched:getInterval(id)
  if not found then interval = 0 end
  lurek.log.debug("event interval = " .. interval .. "s", "timer")
end

--@api-stub: Scheduler:getRepeatCount
-- Returns the number of repeat items in this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(1.0, function() end)
  local found, left = sched:getRepeatCount(id)
  if not found then left = 0 end
  lurek.log.debug("charges left = " .. left, "ability")
end

--@api-stub: Scheduler:getCount
-- Returns the total count of items held by this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:after(1, function() end)
  sched:every(0.5, function() end)
  local n = sched:getCount()
  lurek.log.debug("active timers = " .. n, "timer")
end

--@api-stub: Scheduler:isEmpty
-- Returns true if this scheduler contains no items.
do
  local sched = lurek.timer.newScheduler()
  function lurek.process(dt)
    if not sched:isEmpty() then sched:update(dt) end
  end
end

--@api-stub: Scheduler:setInterval
-- Sets the interval of this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(2.0, function() lurek.log.debug("spawn", "ai") end)
  sched:setInterval(id, 0.5)
  lurek.log.info("spawn rate increased", "ai")
end

--@api-stub: Scheduler:resetEvent
-- Resets event this scheduler to its default state.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:after(10.0, function() lurek.log.info("buff expired", "rpg") end)
  sched:resetEvent(id)
  lurek.log.debug("buff timer refreshed", "rpg")
end

--@api-stub: Scheduler:setTimeScale
-- Sets the time scale of this scheduler.
do
  local enemies = lurek.timer.newScheduler()
  enemies:every(1.0, function() lurek.log.debug("enemy think", "ai") end)
  enemies:setTimeScale(0.25)
  lurek.log.info("enemies in slow-motion", "fx")
end

--@api-stub: Scheduler:getTimeScale
-- Returns the time scale of this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:setTimeScale(2.0)
  local scale = sched:getTimeScale()
  if scale ~= 1.0 then
    lurek.log.info("time scale = " .. scale, "ui")
  end
end

--@api-stub: Scheduler:update
-- Advances this scheduler by the given delta time.
do
  local sched = lurek.timer.newScheduler()
  sched:after(0.5, function() lurek.log.debug("fired", "demo") end)
  function lurek.process(dt) sched:update(dt) end
end

--@api-stub: Scheduler:updateFrames
-- Advances frames this scheduler by the given delta time.
do
  local sched = lurek.timer.newScheduler()
  sched:everyFrames(15, function() lurek.log.debug("quarter-second tick", "test") end)
  function lurek.process() sched:updateFrames() end
end

--@api-stub: Scheduler:afterNamed
-- Performs the after named operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:afterNamed("respawn", 3.0, function()
    lurek.log.info("respawn fired", "timer")
  end)
  lurek.log.info("named timer registered", "timer")
end

--@api-stub: Scheduler:every
-- Performs the every operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:every(1.0, function()
    lurek.log.info("tick", "timer")
  end)
  lurek.log.info("repeating id: " .. id, "timer")
end

--@api-stub: Scheduler:everyFrames
-- Performs the every frames operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  local id = sched:everyFrames(30, function()
    lurek.log.info("every 30 frames", "timer")
  end)
  lurek.log.info("frame-rate timer id: " .. id, "timer")
end

--@api-stub: Scheduler:everyNamed
-- Performs the every named operation on this scheduler.
do
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("regen", 2.0, function()
    lurek.log.info("hp regen", "timer")
  end)
  lurek.log.info("named repeating timer registered", "timer")
end

-- -----------------------------------------------------------------------------
-- Scheduler methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LScheduler methods
-- -----------------------------------------------------------------------------


--@api-stub: LScheduler:type
-- Returns the Lua-visible type name string for this scheduler handle.
do
  local s = lurek.timer.newScheduler()
  lurek.log.info(s:type(), "timer")
end

--@api-stub: LScheduler:typeOf
-- Returns true if this scheduler handle matches the given type name string.
do
  local s = lurek.timer.newScheduler()
  lurek.log.info(tostring(s:typeOf("LScheduler")), "timer")
end
