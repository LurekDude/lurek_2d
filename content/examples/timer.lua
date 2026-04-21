-- content/examples/timer.lua
-- Lurek2D lurek.timer API Reference
-- Run with: cargo run -- content/examples/timer

-- =============================================================================
-- lurek.timer — Frame timing, schedulers, and time control
--
-- The timer module provides frame delta time, FPS counters, physics timing,
-- and a Scheduler object for game-logic timers (cooldowns, delayed spawns,
-- repeating effects).  It also offers real-time timers, coroutine-style waits,
-- and a chaining API for sequencing timed events.
-- =============================================================================

-- ---- Stub: lurek.timer.getDelta ------------------------------------------
--@api-stub: lurek.timer.getDelta
-- Read the frame delta time to move the player at a consistent speed
-- regardless of frame rate.  At 60 FPS delta is ~0.0167 seconds.
local dt = lurek.timer.getDelta()
print(string.format("frame delta: %.4f sec", dt))
local player_speed = 200   -- pixels per second
local move_x = player_speed * dt
print(string.format("player moves %.2f pixels this frame", move_x))

-- ---- Stub: lurek.timer.getFPS --------------------------------------------
--@api-stub: lurek.timer.getFPS
-- Display a live FPS counter in the debug overlay.  Compare against the
-- target (60 FPS) to detect performance regressions.
local fps = lurek.timer.getFPS()
print(string.format("current FPS: %.1f", fps))
if fps < 55 then
    print("  WARNING: below 60 FPS target")
end

-- ---- Stub: lurek.timer.getTime -------------------------------------------
--@api-stub: lurek.timer.getTime
-- Get the total elapsed time since engine start.  Use it to drive continuous
-- animations like a sine-wave idle bob on the player sprite.
local t = lurek.timer.getTime()
local bob_offset = math.sin(t * 3.0) * 4.0   -- 3 Hz oscillation, 4 px amplitude
print(string.format("time: %.2f sec  idle bob offset: %.1f px", t, bob_offset))

-- ---- Stub: lurek.timer.getAverageDelta -----------------------------------
--@api-stub: lurek.timer.getAverageDelta
-- Smoothed delta time for UI display (avoids jittery FPS counters).
local avg_dt = lurek.timer.getAverageDelta()
local smooth_fps = 1.0 / math.max(avg_dt, 0.001)
print(string.format("avg delta: %.4f sec  smooth FPS: %.1f", avg_dt, smooth_fps))

-- ---- Stub: lurek.timer.getFrameCount -------------------------------------
--@api-stub: lurek.timer.getFrameCount
-- Use the frame counter to trigger periodic tasks: auto-save every 3600
-- frames (~60 sec at 60 FPS) without tracking wall-clock time.
local frames = lurek.timer.getFrameCount()
print("total frames: " .. frames)
if frames > 0 and frames % 3600 == 0 then
    print("  auto-save triggered at frame " .. frames)
end

-- ---- Stub: lurek.timer.step ----------------------------------------------
--@api-stub: lurek.timer.step
-- Manually step the timer by a fixed amount.  Used in headless test harnesses
-- or deterministic replay systems where real clock time is unreliable.
lurek.timer.step(0.016)   -- advance exactly one 60-FPS frame
print("timer stepped by 0.016 sec (1 frame at 60 FPS)")

-- ---- Stub: lurek.timer.getMicroTime --------------------------------------
--@api-stub: lurek.timer.getMicroTime
-- High-resolution timestamp for micro-benchmarking code sections.
local t0 = lurek.timer.getMicroTime()
-- simulate work
local sum = 0
for i = 1, 10000 do sum = sum + i end
local t1 = lurek.timer.getMicroTime()
local elapsed_us = (t1 - t0) * 1000000
print(string.format("loop took %.1f microseconds", elapsed_us))

-- ---- Stub: lurek.timer.getPhysicsDelta -----------------------------------
--@api-stub: lurek.timer.getPhysicsDelta
-- Read the fixed physics timestep to synchronize physics-dependent logic
-- (e.g. applying constant force per physics step).
local phys_dt = lurek.timer.getPhysicsDelta()
print(string.format("physics delta: %.4f sec (%.0f Hz)", phys_dt, 1.0 / phys_dt))

-- ---- Stub: lurek.timer.setPhysicsDelta -----------------------------------
--@api-stub: lurek.timer.setPhysicsDelta
-- Increase the physics step to 120 Hz for a fighting game that needs
-- precise collision detection at high speed.
lurek.timer.setPhysicsDelta(1.0 / 120.0)
print("physics rate set to 120 Hz")
print("  new physics delta: " .. lurek.timer.getPhysicsDelta())

-- ---- Stub: lurek.timer.getPhysicsMaxSteps --------------------------------
--@api-stub: lurek.timer.getPhysicsMaxSteps
-- Cap how many physics sub-steps run per frame to prevent a spiral of death
-- when the CPU cannot keep up.
local max_steps = lurek.timer.getPhysicsMaxSteps()
print("max physics steps per frame: " .. max_steps)

-- ---- Stub: lurek.timer.setPhysicsMaxSteps --------------------------------
--@api-stub: lurek.timer.setPhysicsMaxSteps
-- Limit to 4 sub-steps.  If the frame takes longer than 4 * physics_delta
-- the simulation will slow down rather than stutter.
lurek.timer.setPhysicsMaxSteps(4)
print("physics max steps capped at 4")

-- ---- Stub: lurek.timer.sleep ---------------------------------------------
--@api-stub: lurek.timer.sleep
-- Artificial delay for tool scripts or splash screens.  Never use in
-- gameplay code (blocks the entire frame loop).
if false then
    -- Guarded: would block the engine
    lurek.timer.sleep(1.5)
end
print("lurek.timer.sleep(1.5) would pause for 1.5 seconds")

-- ---- Stub: lurek.timer.setSmoothingFactor --------------------------------
--@api-stub: lurek.timer.setSmoothingFactor
-- Adjust delta smoothing.  Higher values (closer to 1.0) smooth more but
-- react slower to genuine frame rate changes.
lurek.timer.setSmoothingFactor(0.9)
print("delta smoothing factor set to 0.9 (high smoothing)")

-- ---- Stub: lurek.timer.getSmoothedDelta ----------------------------------
--@api-stub: lurek.timer.getSmoothedDelta
-- Read the exponentially smoothed delta for camera interpolation where
-- jitter must be minimized.
local smooth_dt = lurek.timer.getSmoothedDelta()
print(string.format("smoothed delta: %.4f sec", smooth_dt))


-- =============================================================================
-- Scheduler — game-logic timers: cooldowns, delayed spawns, repeating effects
-- =============================================================================

-- ---- Stub: lurek.timer.newScheduler --------------------------------------
--@api-stub: lurek.timer.newScheduler
-- Create a Scheduler to manage all game timers: ability cooldowns, delayed
-- enemy spawns, repeating damage-over-time ticks.
local sched = lurek.timer.newScheduler()
print("scheduler created: " .. tostring(sched))

-- ---- Stub: Scheduler:after -----------------------------------------------
--@api-stub: Scheduler:after
-- Schedule a bullet despawn 3 seconds after firing.  The callback removes
-- the bullet from the world.
local despawn_id = sched:after(3.0, function()
    print("  [timer] bullet despawned after 3 seconds")
end)
print("despawn timer id: " .. tostring(despawn_id))

-- Schedule a repeating damage-over-time tick every 0.5 seconds, 6 times total.
local dot_id = sched:after(0.5, function()
    print("  [timer] poison tick: -5 HP")
end, 6)   -- repeat count
print("poison DOT timer id: " .. tostring(dot_id))

-- ---- Stub: Scheduler:cancel ----------------------------------------------
--@api-stub: Scheduler:cancel
-- Cancel the despawn timer when the bullet hits an enemy before the timeout.
local cancelled = sched:cancel(despawn_id)
print("despawn timer cancelled: " .. tostring(cancelled))

-- ---- Stub: Scheduler:cancelNamed -----------------------------------------
--@api-stub: Scheduler:cancelNamed
-- Cancel a named timer by tag.  Named timers are easier to manage than
-- tracking integer IDs when many systems use the scheduler.
sched:after(5.0, function() print("shield expires") end):setName("shield_buff")
sched:cancelNamed("shield_buff")
print("shield_buff timer cancelled by name")

-- ---- Stub: Scheduler:cancelAll -------------------------------------------
--@api-stub: Scheduler:cancelAll
-- Remove all timers when transitioning to a new level so stale callbacks
-- from the previous level do not fire.
sched:cancelAll()
print("all timers cancelled for level transition")

-- ---- Stub: Scheduler:update ----------------------------------------------
--@api-stub: Scheduler:update
-- Advance all active timers by the frame delta.  Call this once per frame
-- in lurek.process().  Expired timers fire their callbacks.
sched:after(0.1, function() print("  [timer] quick ping!") end)
sched:update(0.05)   -- half the delay
print("updated by 0.05 sec -- timer not yet expired")
sched:update(0.06)   -- past the 0.1 threshold
print("updated by 0.06 sec -- timer should have fired")

-- ---- Stub: Scheduler:getCount --------------------------------------------
--@api-stub: Scheduler:getCount
-- Show the number of active timers in a debug overlay to track timer leaks.
local active = sched:getCount()
print("active timers: " .. active)

-- ---- Stub: Scheduler:isEmpty ---------------------------------------------
--@api-stub: Scheduler:isEmpty
-- Skip the update() call entirely when no timers are active to save CPU.
if sched:isEmpty() then
    print("scheduler is empty -- skipping update")
else
    print("scheduler has " .. sched:getCount() .. " active timers")
end

-- ---- Stub: Scheduler:pause -----------------------------------------------
--@api-stub: Scheduler:pause
-- Pause all timers when the game is paused (e.g. pause menu, phone call).
sched:after(2.0, function() print("ability ready") end)
sched:pause()
print("all timers paused")

-- ---- Stub: Scheduler:isPaused --------------------------------------------
--@api-stub: Scheduler:isPaused
-- Check if the scheduler is paused to show a "PAUSED" indicator on the
-- cooldown bars in the HUD.
local is_paused = sched:isPaused()
print("scheduler paused: " .. tostring(is_paused))

-- ---- Stub: Scheduler:resume ----------------------------------------------
--@api-stub: Scheduler:resume
-- Resume all timers when the player closes the pause menu.
sched:resume()
print("timers resumed -- cooldowns continue ticking")

-- ---- Stub: Scheduler:pauseNamed ------------------------------------------
--@api-stub: Scheduler:pauseNamed
-- Pause only the "shield_buff" timer while keeping combat timers running.
-- Useful for time-stop abilities that freeze buffs but not attack cooldowns.
sched:after(10.0, function() end):setName("shield_buff_2")
sched:pauseNamed("shield_buff_2")
print("shield_buff_2 paused independently")

-- ---- Stub: Scheduler:resumeNamed -----------------------------------------
--@api-stub: Scheduler:resumeNamed
-- Resume a specific named timer when the time-stop effect ends.
sched:resumeNamed("shield_buff_2")
print("shield_buff_2 resumed")

-- ---- Stub: Scheduler:isPausedNamed ---------------------------------------
--@api-stub: Scheduler:isPausedNamed
-- Check if a named timer is paused before displaying its remaining time.
local buff_paused = sched:isPausedNamed("shield_buff_2")
print("shield_buff_2 paused: " .. tostring(buff_paused))

-- ---- Stub: Scheduler:getRemaining ----------------------------------------
--@api-stub: Scheduler:getRemaining
-- Display the remaining seconds on a cooldown bar.  Create a fresh timer
-- to query its remaining time.
local cd_id = sched:after(5.0, function() print("fireball ready!") end)
local remaining = sched:getRemaining(cd_id)
print(string.format("fireball cooldown: %.1f sec remaining", remaining or 0))

-- ---- Stub: Scheduler:getInterval -----------------------------------------
--@api-stub: Scheduler:getInterval
-- Show the original interval of a repeating timer for UI tooltip display
-- (e.g. "ticks every 0.5 sec").
local tick_id = sched:after(0.5, function() end, 10)
local interval = sched:getInterval(tick_id)
print("DOT tick interval: " .. tostring(interval) .. " sec")

-- ---- Stub: Scheduler:getRepeatCount --------------------------------------
--@api-stub: Scheduler:getRepeatCount
-- Display how many ticks remain on a DOT debuff icon.
local repeats = sched:getRepeatCount(tick_id)
print("DOT remaining ticks: " .. tostring(repeats))

-- ---- Stub: Scheduler:setInterval -----------------------------------------
--@api-stub: Scheduler:setInterval
-- Speed up a repeating timer mid-game (e.g. poison intensifies over time).
sched:setInterval(tick_id, 0.25)
print("DOT tick rate doubled: 0.25 sec interval")

-- ---- Stub: Scheduler:resetEvent ------------------------------------------
--@api-stub: Scheduler:resetEvent
-- Reset a timer to its original delay without cancelling and re-creating it.
-- Useful for "refresh on hit" mechanics like parry windows.
sched:resetEvent(cd_id)
print("fireball cooldown reset -- timer restarted from full duration")

-- ---- Stub: Scheduler:setTimeScale ----------------------------------------
--@api-stub: Scheduler:setTimeScale
-- Slow all timers to 50% during a slow-motion effect (e.g. bullet time).
sched:setTimeScale(0.5)
print("scheduler time scale: 0.5x (bullet time)")

-- ---- Stub: Scheduler:getTimeScale ----------------------------------------
--@api-stub: Scheduler:getTimeScale
-- Read the time scale to adjust UI animations proportionally.
local scale = sched:getTimeScale()
print("current time scale: " .. scale .. "x")

-- Reset to normal
sched:setTimeScale(1.0)


-- =============================================================================
-- Chaining, real-time timers, and coroutine-style waits
-- =============================================================================

-- ---- Stub: lurek.timer.chain ---------------------------------------------
--@api-stub: lurek.timer.chain
-- Chain timed events for a cutscene: fade in -> show text -> fade out.
-- Each step starts after the previous one finishes.
lurek.timer.chain({
    { delay = 0.5, fn = function() print("  [chain] fade in complete") end },
    { delay = 2.0, fn = function() print("  [chain] dialog text shown for 2 sec") end },
    { delay = 0.5, fn = function() print("  [chain] fade out complete") end },
})
print("cutscene chain queued: 3 steps")

-- ---- Stub: lurek.timer.afterReal -----------------------------------------
--@api-stub: lurek.timer.afterReal
-- Schedule a real-time callback that fires even when the game is paused.
-- Use for UI animations in the pause menu.
lurek.timer.afterReal(1.0, function()
    print("  [real-time] 1 second of wall-clock time passed")
end)
print("real-time timer set for 1.0 sec")

-- ---- Stub: lurek.timer.tickRealTimers ------------------------------------
--@api-stub: lurek.timer.tickRealTimers
-- Advance real-time timers independently of game time.  Call this even
-- when the game logic is paused.
lurek.timer.tickRealTimers(0.5)
print("real-time timers advanced by 0.5 sec")

-- ---- Stub: lurek.timer.waitSeconds ---------------------------------------
--@api-stub: lurek.timer.waitSeconds
-- Coroutine-style wait in a sequential script.  The caller yields for
-- the specified duration, then resumes.
local wait_handle = lurek.timer.waitSeconds(2.0)
print("wait handle: " .. tostring(wait_handle))
print("  -> in a coroutine, execution resumes after 2 seconds")

-- ---- Stub: lurek.timer.waitFrames ----------------------------------------
--@api-stub: lurek.timer.waitFrames
-- Wait a fixed number of frames instead of seconds.  Useful for effects
-- that need to last exactly N frames regardless of timestep.
local frame_wait = lurek.timer.waitFrames(10)
print("waiting for 10 frames: " .. tostring(frame_wait))

-- ---- Stub: lurek.timer.tickWaits -----------------------------------------
--@api-stub: lurek.timer.tickWaits
-- Advance all pending waits by the frame delta.  Call alongside the
-- scheduler update in the main loop.
lurek.timer.tickWaits(0.016)
print("waits ticked by 0.016 sec")

-- ---- Stub: lurek.timer.delay ----------------------------------------------
--@api-stub: lurek.timer.delay
-- Coroutine-based yield-for-duration sugar.  Call from within a coroutine to
-- pause execution for a given number of seconds without blocking the main loop.
-- Requires lurek.timer.tickWaits() to be called each frame.
--
-- Example: cutscene scripted with sequential delays in a single coroutine.
local cutscene = coroutine.create(function()
    print("[cutscene] Part 1: fade in")
    lurek.timer.delay(1.0)        -- yield until 1 second passes
    print("[cutscene] Part 2: show dialog")
    lurek.timer.delay(3.0)
    print("[cutscene] Part 3: fade out")
end)
-- The game loop would call coroutine.resume(cutscene) once, then
-- lurek.timer.tickWaits() each frame to resume it at the right moment.
-- Here we just start it to show the API:
coroutine.resume(cutscene)
print("delay: cutscene coroutine started and waiting for tick advances")

-- =============================================================================
-- New in 0.15.0: Frame-count Based Scheduler Events
-- =============================================================================

-- Create a scheduler and use afterFrames to trigger a one-shot callback.
local sched = lurek.timer.newScheduler()

sched:afterFrames(3, function()
  print("fired: afterFrames(3)")
end)

-- everyFrames with a count limit.
sched:everyFrames(2, function()
  print("everyFrames(2) fired")
end, 4)  -- fires at most 4 times

-- Simulate 6 game ticks.
for i = 1, 6 do
  local fired_count = sched:updateFrames()
  print(string.format("tick %d: %d event(s) fired", i, fired_count))
end
