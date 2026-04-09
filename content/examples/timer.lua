-- examples/timer.lua
-- Lurek2D lurek.time API Reference
-- Every lurek.time function is demonstrated with inline comments.

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame Timing (call from lurek.process / lurek.render)
-- ─────────────────────────────────────────────────────────────────────────────

-- Seconds since last frame (kept below 0.1 to avoid physics tunnelling)
local dt = lurek.time.getDelta()

-- Total seconds elapsed since the game started
local elapsed = lurek.time.getTime()

-- Current frames-per-second (averaged over recent frames)
local fps = lurek.time.getFPS()

-- Smoothed mean frame delta (less noisy than getDelta() for display)
local avg_dt = lurek.time.getAverageDelta()

-- Block the current thread for a fixed duration (use sparingly — pauses the game loop)
lurek.time.sleep(0.001)  -- sleep 1 ms

-- ─────────────────────────────────────────────────────────────────────────────
-- Scheduler
-- A scheduler manages delayed and repeating callbacks.
-- Call scheduler:update(dt) each frame to drive it.
-- ─────────────────────────────────────────────────────────────────────────────

local sched = lurek.time.newScheduler()

-- ── One-shot callbacks ────────────────────────────────────────────────────────

-- Fire a callback once after 2 seconds; returns a numeric handle
local id1 = sched:after(2.0, function()
    print("2 seconds have passed!")
end)

-- Named one-shot (name is for lifecycle management, not guaranteed unique)
sched:afterNamed("spawn_boss", 30.0, function()
    -- spawn the final boss 30 s in
end)

-- ── Repeating callbacks ───────────────────────────────────────────────────────

-- Fire every 0.5 seconds, indefinitely
local id2 = sched:every(0.5, function()
    -- tick every half-second
end)

-- Fire every 1 second, but only 5 times (count = 5)
local id3 = sched:every(1.0, function(n)
    -- n is the remaining call count (5 → 4 → 3 → 2 → 1)
    print("countdown:", n)
end, 5)

-- Named repeating event
sched:everyNamed("enemy_wave", 10.0, function()
    -- spawn a wave every 10 s
end)

-- ── Cancellation ─────────────────────────────────────────────────────────────

-- Cancel a specific event by handle
sched:cancel(id1)

-- Cancel a named event
sched:cancelNamed("spawn_boss")

-- Cancel ALL pending events on this scheduler
sched:cancelAll()

-- ── Inspection ────────────────────────────────────────────────────────────────

-- Total pending events (including repeating ones)
local count = sched:getCount()

-- True when there are no pending events
local done = sched:isEmpty()

-- Seconds until event fires (nil if already cancelled or expired)
local remaining = sched:getRemaining(id2)

-- Current repeat interval of a repeating event
local interval = sched:getInterval(id3)

-- Remaining call count for a count-limited repeating event
local reps = sched:getRepeatCount(id3)

-- ── Dynamic modification ──────────────────────────────────────────────────────

-- Change the repeat interval of an existing event
sched:setInterval(id2, 0.25)  -- now fires every 0.25 s instead of 0.5 s

-- Reset the countdown of an event to its full interval
sched:resetEvent(id2)

-- ── Pause / resume all callbacks ──────────────────────────────────────────────

sched:pause()         -- stop all callbacks from firing
sched:resume()        -- resume
local paused = sched:isPaused()

-- ── Time scaling ─────────────────────────────────────────────────────────────

-- Multiply all intervals by a time scale factor
sched:setTimeScale(0.5)  -- slow-motion: callbacks fire at half speed
sched:setTimeScale(2.0)  -- fast-forward: callbacks fire at double speed
local scale = sched:getTimeScale()

-- ── Drive the scheduler each frame ───────────────────────────────────────────

-- This is mandatory — put it inside lurek.process:
function lurek.process(dt)
    sched:update(dt)
end


-- ─── lurek.time ─────────────────────────────────────────────────────────────────
local micro_time = lurek.time.getMicroTime()  -- Returns the high-resolution elapsed time since engine start in seconds
local physics_delta = lurek.time.getPhysicsDelta()  -- Returns the fixed timestep used by `process_physics` callbacks (seconds)
lurek.time.setPhysicsDelta(1.0)  -- Sets the fixed timestep for `process_physics` callbacks (seconds)
local step = lurek.time.step()  -- Advances the timer by one frame, returning the delta time
