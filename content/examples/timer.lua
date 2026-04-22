-- content/examples/timer.lua
-- Hand-written coverage of the lurek.timer API (43 items).
--
-- The lurek.timer namespace owns frame-time queries (delta, fps, smoothed
-- delta), the fixed physics timestep, real-clock timers, coroutine waits,
-- and Scheduler userdata for one-shot, recurring, named, and chained
-- callbacks. Most update-loop calls below live inside lurek.process(dt).
--
-- Run: cargo run -- content/examples/timer.lua

-- ── lurek.timer.* functions ──

--@api-stub: lurek.timer.getDelta
-- Returns the delta time in seconds for the current frame.
-- Use inside lurek.process to integrate motion frame-rate independently.
do  -- lurek.timer.getDelta
  function lurek.process()
    local dt = lurek.timer.getDelta()
    local speed = 200
    local x = 0
    x = x + speed * dt
  end
end

--@api-stub: lurek.timer.getFPS
-- Returns the current frames-per-second measurement.
-- Sample once per second to drive an HUD readout; the engine averages internally.
do  -- lurek.timer.getFPS
  function lurek.render_ui()
    local fps = lurek.timer.getFPS()
    if fps < 30 then
      lurek.log.warn("low fps: " .. fps, "perf")
    end
  end
end

--@api-stub: lurek.timer.getTime
-- Returns the total elapsed time since engine start in seconds.
-- Good for animation phases; engine-time, so it is paused when the engine is paused.
do  -- lurek.timer.getTime
  function lurek.render()
    local t = lurek.timer.getTime()
    local pulse = 0.5 + 0.5 * math.sin(t * 2.0)
    lurek.log.debug("pulse=" .. pulse, "fx")
  end
end

--@api-stub: lurek.timer.getAverageDelta
-- Returns the rolling-average frame delta time in seconds.
-- More stable than getDelta for budgeting work; use to estimate per-frame headroom.
do  -- lurek.timer.getAverageDelta
  function lurek.process()
    local avg = lurek.timer.getAverageDelta()
    local budget_ms = avg * 1000
    if budget_ms > 20 then
      lurek.log.warn("frame budget exceeded: " .. budget_ms .. "ms", "perf")
    end
  end
end

--@api-stub: lurek.timer.getFrameCount
-- Returns the total number of frames rendered since engine start.
-- Useful as a deterministic monotonic counter for periodic work without time drift.
do  -- lurek.timer.getFrameCount
  function lurek.process()
    local n = lurek.timer.getFrameCount()
    if n % 60 == 0 then
      lurek.log.info("frame " .. n, "tick")
    end
  end
end

--@api-stub: lurek.timer.step
-- Advances the timer by one frame, returning the delta time.
-- Engine calls this internally each frame; call manually only inside custom inner loops.
do  -- lurek.timer.step
  function lurek.process()
    local dt = lurek.timer.step()
    local accumulator = 0
    accumulator = accumulator + dt
  end
end

--@api-stub: lurek.timer.getMicroTime
-- Returns the high-resolution elapsed time since engine start in seconds.
-- Use for ad-hoc benchmarks: capture before and after, subtract for elapsed.
do  -- lurek.timer.getMicroTime
  local t0 = lurek.timer.getMicroTime()
  local sum = 0
  for i = 1, 10000 do sum = sum + i end
  local elapsed = lurek.timer.getMicroTime() - t0
  lurek.log.debug("loop took " .. elapsed .. "s, sum=" .. sum, "bench")
end

--@api-stub: lurek.timer.getPhysicsDelta
-- Returns the fixed timestep used by `process_physics` callbacks (seconds).
-- Read at startup to size your physics integration constants (e.g. impulse magnitudes).
do  -- lurek.timer.getPhysicsDelta
  local pdt = lurek.timer.getPhysicsDelta()
  local hz = 1.0 / pdt
  lurek.log.info("physics step: " .. pdt .. "s (" .. hz .. "Hz)", "physics")
end

--@api-stub: lurek.timer.setPhysicsDelta
-- Sets the fixed timestep for `process_physics` callbacks (seconds).
-- Call once at startup; clamped to [1/240, 1/10]. Smaller = more accurate, more CPU.
do  -- lurek.timer.setPhysicsDelta
  lurek.timer.setPhysicsDelta(1 / 120)
  local pdt = lurek.timer.getPhysicsDelta()
  lurek.log.info("physics now stepping at " .. (1.0 / pdt) .. "Hz", "physics")
end

--@api-stub: lurek.timer.getPhysicsMaxSteps
-- Returns the maximum number of physics sub-steps allowed per frame.
-- Read this to ensure your scene tolerates spiral-of-death conditions on slow frames.
do  -- lurek.timer.getPhysicsMaxSteps
  local max_steps = lurek.timer.getPhysicsMaxSteps()
  if max_steps < 4 then
    lurek.log.warn("physics may stutter on slow frames: max_steps=" .. max_steps, "physics")
  end
end

--@api-stub: lurek.timer.setPhysicsMaxSteps
-- Sets the maximum number of physics sub-steps allowed per frame (clamped 1–64).
-- Raise for scenes that occasionally need a long catch-up; cap to avoid stalls.
do  -- lurek.timer.setPhysicsMaxSteps
  lurek.timer.setPhysicsMaxSteps(8)
  local n = lurek.timer.getPhysicsMaxSteps()
  lurek.log.info("physics catch-up cap = " .. n, "physics")
end

--@api-stub: lurek.timer.sleep
-- Suspends execution for the given number of seconds.
-- Blocks the whole engine thread; use only in tools/scripts, never in lurek.process.
do  -- lurek.timer.sleep
  local before = lurek.timer.getMicroTime()
  lurek.timer.sleep(0.05)
  local elapsed = lurek.timer.getMicroTime() - before
  lurek.log.debug("slept ~" .. elapsed .. "s", "tools")
end

--@api-stub: lurek.timer.newScheduler
-- Creates a new independent Scheduler for managing timed callbacks.
-- Use when one subsystem needs its own time-scale or pause semantics.
do  -- lurek.timer.newScheduler
  local boss_timers = lurek.timer.newScheduler()
  boss_timers:after(2.5, function() lurek.log.info("boss enrages", "ai") end)
  function lurek.process(dt) boss_timers:update(dt) end
end

--@api-stub: lurek.timer.chain
-- Creates a new Scheduler loaded with a sequenced one-shot chain.
-- Each step's delay is added to the previous; perfect for cutscene beats.
do  -- lurek.timer.chain
  local intro = lurek.timer.chain({
    { delay = 0.0, func = function() lurek.log.info("scene: fade in", "cutscene") end },
    { delay = 1.5, func = function() lurek.log.info("scene: dialog", "cutscene") end },
    { delay = 2.0, func = function() lurek.log.info("scene: gameplay", "cutscene") end },
  })
  function lurek.process(dt) intro:update(dt) end
end

--@api-stub: lurek.timer.afterReal
-- Schedules a one-shot callback that fires after `delay` wall-clock seconds.
-- Wall-clock based, so it ignores engine time-scale and pause; pair with tickRealTimers().
do  -- lurek.timer.afterReal
  lurek.timer.afterReal(3.0, function()
    lurek.log.info("3 real seconds elapsed", "ui")
  end)
  function lurek.process() lurek.timer.tickRealTimers() end
end

--@api-stub: lurek.timer.tickRealTimers
-- Advances all real-time timers by one tick; called automatically each frame.
-- Call manually only if you scheduled afterReal() before the engine started ticking.
do  -- lurek.timer.tickRealTimers
  lurek.timer.afterReal(0.25, function() lurek.log.debug("toast hide", "ui") end)
  function lurek.process()
    local fired = lurek.timer.tickRealTimers()
    if fired > 0 then lurek.log.debug("real timers fired: " .. fired, "ui") end
  end
end

--@api-stub: lurek.timer.setSmoothingFactor
-- Sets the smoothing factor (alpha) for `getSmoothedDelta`.
-- Lower (0.05) = very smooth, slow to react; 1.0 = no smoothing. Set once at startup.
do  -- lurek.timer.setSmoothingFactor
  lurek.timer.setSmoothingFactor(0.1)
  function lurek.process()
    local sdt = lurek.timer.getSmoothedDelta()
    lurek.log.debug("smoothed dt=" .. sdt, "perf")
  end
end

--@api-stub: lurek.timer.getSmoothedDelta
-- Returns the exponential moving-average of frame deltas in seconds.
-- Use for HUD frame-time graphs where raw delta is too jittery to read.
do  -- lurek.timer.getSmoothedDelta
  function lurek.render_ui()
    local sdt = lurek.timer.getSmoothedDelta()
    local ms = sdt * 1000
    lurek.log.debug(string.format("frame %.2fms", ms), "hud")
  end
end

--@api-stub: lurek.timer.waitSeconds
-- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
-- Must be called from inside a coroutine; drive resumes with tickWaits() each frame.
do  -- lurek.timer.waitSeconds
  local co = coroutine.wrap(function()
    lurek.log.info("phase 1", "intro")
    lurek.timer.waitSeconds(1.0)
    lurek.log.info("phase 2", "intro")
  end)
  function lurek.init() co() end
  function lurek.process() lurek.timer.tickWaits() end
end

--@api-stub: lurek.timer.waitFrames
-- Yields the current Lua coroutine for at least `frames` engine frames.
-- Frame-deterministic alternative to waitSeconds; useful for replays and tests.
do  -- lurek.timer.waitFrames
  local co = coroutine.wrap(function()
    lurek.log.debug("waiting 60 frames", "test")
    lurek.timer.waitFrames(60)
    lurek.log.debug("60 frames done", "test")
  end)
  function lurek.init() co() end
  function lurek.process() lurek.timer.tickWaits() end
end

--@api-stub: lurek.timer.tickWaits
-- Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
-- Call once per frame in lurek.process; returns the count of coroutines resumed.
do  -- lurek.timer.tickWaits
  function lurek.process()
    local resumed = lurek.timer.tickWaits()
    if resumed > 0 then
      lurek.log.debug("resumed " .. resumed .. " coroutines", "timer")
    end
  end
end

-- ── Scheduler methods ──

--@api-stub: Scheduler:after
-- Schedules a callback to fire once after a delay.
-- Returned id can be passed to cancel/pause/resume; nil callback is a noop slot.
do  -- Scheduler:after
  local sched = lurek.timer.newScheduler()
  local id = sched:after(1.5, function() lurek.log.info("spawn wave", "ai") end)
  lurek.log.debug("scheduled id=" .. id, "timer")
  function lurek.process(dt) sched:update(dt) end
end

--@api-stub: Scheduler:afterFrames
-- Schedules a callback to fire once after `n` frames.
-- Frame-based variant; immune to time-scale, advances via :updateFrames() each frame.
do  -- Scheduler:afterFrames
  local sched = lurek.timer.newScheduler()
  sched:afterFrames(30, function() lurek.log.debug("30 frames in", "test") end)
  function lurek.process() sched:updateFrames() end
end

--@api-stub: Scheduler:cancel
-- Cancels a scheduled event by its numeric ID.
-- Returns true if it was active; safe to call on already-fired or unknown ids.
do  -- Scheduler:cancel
  local sched = lurek.timer.newScheduler()
  local id = sched:after(5.0, function() lurek.log.info("never fires", "demo") end)
  local ok = sched:cancel(id)
  lurek.log.debug("cancel returned " .. tostring(ok), "timer")
end

--@api-stub: Scheduler:cancelNamed
-- Cancels a scheduled event by its string name.
-- Use named events to cancel without tracking ids; great for per-entity timers.
do  -- Scheduler:cancelNamed
  local sched = lurek.timer.newScheduler()
  sched:afterNamed("invuln", 2.0, function() lurek.log.debug("invuln end", "combat") end)
  local cancelled = sched:cancelNamed("invuln")
  lurek.log.debug("invuln cancelled=" .. tostring(cancelled), "combat")
end

--@api-stub: Scheduler:cancelAll
-- Cancels all scheduled events and returns the count removed.
-- Call on scene unload to drop pending callbacks before swapping state.
do  -- Scheduler:cancelAll
  local sched = lurek.timer.newScheduler()
  sched:after(1, function() end)
  sched:every(0.5, function() end)
  local removed = sched:cancelAll()
  lurek.log.info("dropped " .. removed .. " timers on scene exit", "scene")
end

--@api-stub: Scheduler:pause
-- Pauses a scheduled event by its ID.
-- Pair with :resume(id); paused events keep their remaining time intact.
do  -- Scheduler:pause
  local sched = lurek.timer.newScheduler()
  local id = sched:every(1.0, function() lurek.log.debug("tick", "ai") end)
  sched:pause(id)
  lurek.log.debug("paused id=" .. id, "ai")
end

--@api-stub: Scheduler:resume
-- Resumes a paused event by its ID.
-- Returns true if the event existed and was paused; mirror of :pause().
do  -- Scheduler:resume
  local sched = lurek.timer.newScheduler()
  local id = sched:every(0.5, function() end)
  sched:pause(id)
  local ok = sched:resume(id)
  lurek.log.debug("resume returned " .. tostring(ok), "timer")
end

--@api-stub: Scheduler:isPaused
-- Returns whether the given event is currently paused.
-- Useful to drive UI state (greyed-out icon) without tracking the flag yourself.
do  -- Scheduler:isPaused
  local sched = lurek.timer.newScheduler()
  local id = sched:every(2.0, function() end)
  sched:pause(id)
  if sched:isPaused(id) then
    lurek.log.debug("timer " .. id .. " is paused", "ui")
  end
end

--@api-stub: Scheduler:pauseNamed
-- Pauses a scheduled event by its string name.
-- Named-key analogue of :pause(); use when you only have the name in scope.
do  -- Scheduler:pauseNamed
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("regen", 1.0, function() lurek.log.debug("+1 hp", "rpg") end)
  sched:pauseNamed("regen")
  lurek.log.debug("regen paused", "rpg")
end

--@api-stub: Scheduler:resumeNamed
-- Resumes a paused event by its string name.
-- Returns true if the named event was paused before the call.
do  -- Scheduler:resumeNamed
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("regen", 1.0, function() end)
  sched:pauseNamed("regen")
  local ok = sched:resumeNamed("regen")
  lurek.log.debug("regen resumed=" .. tostring(ok), "rpg")
end

--@api-stub: Scheduler:isPausedNamed
-- Returns whether the named event is currently paused.
-- Lets UI code query state by name without retaining the numeric id.
do  -- Scheduler:isPausedNamed
  local sched = lurek.timer.newScheduler()
  sched:everyNamed("spawn", 5.0, function() end)
  sched:pauseNamed("spawn")
  if sched:isPausedNamed("spawn") then
    lurek.log.debug("spawner paused", "ai")
  end
end

--@api-stub: Scheduler:getRemaining
-- Returns the seconds remaining until the next fire for an event, or nil.
-- Drive cooldown UI bars: divide by getInterval(id) to get a 0..1 progress value.
do  -- Scheduler:getRemaining
  local sched = lurek.timer.newScheduler()
  local id = sched:after(3.0, function() end)
  local remaining = sched:getRemaining(id)
  if remaining then
    lurek.log.debug(string.format("ready in %.1fs", remaining), "cooldown")
  end
end

--@api-stub: Scheduler:getInterval
-- Returns the base interval in seconds for an event, or nil.
-- Combine with getRemaining to compute progress; nil means the id is unknown.
do  -- Scheduler:getInterval
  local sched = lurek.timer.newScheduler()
  local id = sched:every(2.5, function() end)
  local interval = sched:getInterval(id) or 0
  lurek.log.debug("event interval = " .. interval .. "s", "timer")
end

--@api-stub: Scheduler:getRepeatCount
-- Returns the repeat count remaining for an event, or nil.
-- -1 means infinite; use to display "3 charges left" style HUD elements.
do  -- Scheduler:getRepeatCount
  local sched = lurek.timer.newScheduler()
  local id = sched:every(1.0, function() end)
  local left = sched:getRepeatCount(id) or 0
  lurek.log.debug("charges left = " .. left, "ability")
end

--@api-stub: Scheduler:getCount
-- Returns the number of active scheduled events.
-- Useful for sanity checks and leak detection in long-running scenes.
do  -- Scheduler:getCount
  local sched = lurek.timer.newScheduler()
  sched:after(1, function() end)
  sched:every(0.5, function() end)
  local n = sched:getCount()
  lurek.log.debug("active timers = " .. n, "timer")
end

--@api-stub: Scheduler:isEmpty
-- Returns whether the scheduler has no active events.
-- Cheap early-out before calling :update(dt) on a scheduler that's almost always idle.
do  -- Scheduler:isEmpty
  local sched = lurek.timer.newScheduler()
  function lurek.process(dt)
    if not sched:isEmpty() then sched:update(dt) end
  end
end

--@api-stub: Scheduler:setInterval
-- Changes the repeat interval of an existing event.
-- Use to ramp difficulty: shorten the spawn interval as the wave progresses.
do  -- Scheduler:setInterval
  local sched = lurek.timer.newScheduler()
  local id = sched:every(2.0, function() lurek.log.debug("spawn", "ai") end)
  sched:setInterval(id, 0.5)
  lurek.log.info("spawn rate increased", "ai")
end

--@api-stub: Scheduler:resetEvent
-- Resets an event's remaining time back to its original interval.
-- Use to refresh a buff's duration when a new pickup is collected.
do  -- Scheduler:resetEvent
  local sched = lurek.timer.newScheduler()
  local id = sched:after(10.0, function() lurek.log.info("buff expired", "rpg") end)
  sched:resetEvent(id)
  lurek.log.debug("buff timer refreshed", "rpg")
end

--@api-stub: Scheduler:setTimeScale
-- Sets a global time-scale multiplier for this scheduler.
-- 0.5 = bullet-time, 2.0 = fast-forward; affects every event in the scheduler.
do  -- Scheduler:setTimeScale
  local enemies = lurek.timer.newScheduler()
  enemies:every(1.0, function() lurek.log.debug("enemy think", "ai") end)
  enemies:setTimeScale(0.25)
  lurek.log.info("enemies in slow-motion", "fx")
end

--@api-stub: Scheduler:getTimeScale
-- Returns the current time-scale multiplier.
-- Read to display a slow-mo indicator or to tune dependent systems.
do  -- Scheduler:getTimeScale
  local sched = lurek.timer.newScheduler()
  sched:setTimeScale(2.0)
  local scale = sched:getTimeScale()
  if scale ~= 1.0 then
    lurek.log.info("time scale = " .. scale, "ui")
  end
end

--@api-stub: Scheduler:update
-- Advances all timers by dt seconds, firing due callbacks.
-- Call once per frame in lurek.process; pass the engine delta from getDelta() or arg.
do  -- Scheduler:update
  local sched = lurek.timer.newScheduler()
  sched:after(0.5, function() lurek.log.debug("fired", "demo") end)
  function lurek.process(dt) sched:update(dt) end
end

--@api-stub: Scheduler:updateFrames
-- Advances frame-based events by one frame, firing due callbacks.
-- Pair with :afterFrames / :everyFrames; takes no dt because steps are discrete.
do  -- Scheduler:updateFrames
  local sched = lurek.timer.newScheduler()
  sched:everyFrames(15, function() lurek.log.debug("quarter-second tick", "test") end)
  function lurek.process() sched:updateFrames() end
end
