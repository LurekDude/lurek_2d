-- content/examples/tween.lua
-- Practical usage examples for the lurek.tween API (35 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.tween.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/tween.lua

print("[example] lurek.tween — 35 API entries")

-- ── lurek.tween.* free functions ──

--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, and parallels by `dt` seconds.
-- Call when you need to invoke update.
local ok, err = pcall(function() lurek.tween.update(1.0) end)
if not ok then print("set skipped:", err) end
print("lurek.tween.update applied=", ok)

--@api-stub: lurek.tween.tween
-- Creates a new property tween and registers it for automatic updating.
-- Call when you need to invoke tween.
local ok, result = pcall(function() return lurek.tween.tween() end)
if ok then print("lurek.tween.tween ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tween.sequence
-- Creates an empty TweenSequence.
-- Add steps with :tween(), :delay(), :callback(),.
local ok, result = pcall(function() return lurek.tween.sequence() end)
if ok then print("lurek.tween.sequence ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tween.parallel
-- Creates an empty TweenParallel.
-- Add entries with :tween() or :add(tween),.
local ok, result = pcall(function() return lurek.tween.parallel() end)
if ok then print("lurek.tween.parallel ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tween.delay
-- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
-- Call when you need to invoke delay.
local ok, result = pcall(function() return lurek.tween.delay(1.0, function() end) end)
if ok then print("lurek.tween.delay ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tween.cancelAll
-- Cancels all active tweens, sequences, parallels, and springs immediately.
-- Call when you need to invoke cancel all.
local ok, result = pcall(function() return lurek.tween.cancelAll() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.tween.cancelAll ok=", ok)

--@api-stub: lurek.tween.getActiveCount
-- Returns the number of currently active tween objects (tweens + seqs + pars).
-- Call when you need to read active count.
local ok, value = pcall(function() return lurek.tween.getActiveCount() end)
local v = ok and value or "(unavailable)"
print("lurek.tween.getActiveCount ->", v)

--@api-stub: lurek.tween.registerEasing
-- Registers a custom easing function under `name`.
-- `fn(t)` receives 0..1, returns 0..1.
local ok, err = pcall(function() lurek.tween.registerEasing("name", nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.tween.registerEasing done=", ok)

--@api-stub: lurek.tween.getEasingNames
-- Returns a list of all available easing names (built-in + custom).
-- Call when you need to read easing names.
local ok, value = pcall(function() return lurek.tween.getEasingNames() end)
local v = ok and value or "(unavailable)"
print("lurek.tween.getEasingNames ->", v)

--@api-stub: lurek.tween.newState
-- Creates a standalone tween timing state without registering it with the engine.
-- Call when you need to create a new state.
local ok, obj = pcall(function() return lurek.tween.newState(1.0, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tween.newState ok=", ok)

--@api-stub: lurek.tween.to
-- Sugar for `tween()` with `target` first â€” natural read order.
-- Call when you need to invoke to.
local ok, result = pcall(function() return lurek.tween.to() end)
if ok then print("lurek.tween.to ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tween.spring
-- Creates a physics-based spring animation that drives named fields on `target_table`.
-- Call when you need to invoke spring.
local ok, result = pcall(function() return lurek.tween.spring(nil, {}, {}) end)
if ok then print("lurek.tween.spring ->", result)
else print("unavailable:", result) end

-- ── TweenState methods ──

--@api-stub: TweenState:tick
-- Advances the tween state by `dt` seconds.
-- Call when you need to invoke tick.
-- Build a TweenState via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenState(...)
if instance then
  local ok, result = pcall(function() return instance:tick(1.0) end)
  print("TweenState:tick ->", ok, result)
end

--@api-stub: TweenState:isComplete
-- Returns whether the tween state has completed.
-- Call when you need to check is complete.
-- Build a TweenState via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenState(...)
if instance then
  local ok, result = pcall(function() return instance:isComplete() end)
  print("TweenState:isComplete ->", ok, result)
end

--@api-stub: TweenState:t
-- Returns the raw 0..1 playback progress.
-- Call when you need to invoke t.
-- Build a TweenState via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenState(...)
if instance then
  local ok, result = pcall(function() return instance:t() end)
  print("TweenState:t ->", ok, result)
end

--@api-stub: TweenState:lerp
-- Interpolates from `start` to `finish` using the eased tween progress.
-- Call when you need to invoke lerp.
-- Build a TweenState via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenState(...)
if instance then
  local ok, result = pcall(function() return instance:lerp(nil, nil) end)
  print("TweenState:lerp ->", ok, result)
end

--@api-stub: TweenState:reset
-- Resets the tween state to elapsed time zero.
-- Call when you need to invoke reset.
-- Build a TweenState via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenState(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("TweenState:reset ->", ok, result)
end

-- ── Tween methods ──

--@api-stub: Tween:pause
-- Pauses this tween; time stops advancing but the tween is not cancelled.
-- Call when you need to invoke pause.
-- Build a Tween via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:pause() end)
  print("Tween:pause ->", ok, result)
end

--@api-stub: Tween:resume
-- Resumes a paused tween, continuing from the position where it was paused.
-- Call when you need to invoke resume.
-- Build a Tween via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:resume() end)
  print("Tween:resume ->", ok, result)
end

--@api-stub: Tween:isActive
-- Returns true if the tween is still running (not completed or cancelled).
-- Call when you need to check is active.
-- Build a Tween via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("Tween:isActive ->", ok, result)
end

--@api-stub: Tween:getProgress
-- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
-- Call when you need to read progress.
-- Build a Tween via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getProgress() end)
  print("Tween:getProgress ->", ok, result)
end

--@api-stub: Tween:setRepeat
-- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
-- Call when you need to assign repeat.
-- Build a Tween via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:setRepeat(10) end)
  print("Tween:setRepeat ->", ok, result)
end

--@api-stub: Tween:setYoyo
-- Enables or disables yoyo (ping-pong) on each repeat cycle.
-- Call when you need to assign yoyo.
-- Build a Tween via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:setYoyo(nil) end)
  print("Tween:setYoyo ->", ok, result)
end

-- ── TweenSequence methods ──

--@api-stub: TweenSequence:cancel
-- Cancels the sequence and stops all pending steps.
-- Call when you need to invoke cancel.
-- Build a TweenSequence via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenSequence(...)
if instance then
  local ok, result = pcall(function() return instance:cancel() end)
  print("TweenSequence:cancel ->", ok, result)
end

--@api-stub: TweenSequence:isActive
-- Returns true if the sequence has been started and has not yet completed.
-- Call when you need to check is active.
-- Build a TweenSequence via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenSequence(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("TweenSequence:isActive ->", ok, result)
end

-- ── TweenParallel methods ──

--@api-stub: TweenParallel:cancel
-- Cancels the parallel group immediately.
-- Call when you need to invoke cancel.
-- Build a TweenParallel via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenParallel(...)
if instance then
  local ok, result = pcall(function() return instance:cancel() end)
  print("TweenParallel:cancel ->", ok, result)
end

--@api-stub: TweenParallel:isActive
-- Returns true if the parallel is running and not yet complete.
-- Call when you need to check is active.
-- Build a TweenParallel via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newTweenParallel(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("TweenParallel:isActive ->", ok, result)
end

-- ── Spring methods ──

--@api-stub: Spring:update
-- Advances the spring by `dt` seconds and writes positions to the target table.
-- Call when you need to invoke update.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Spring:update ->", ok, result)
end

--@api-stub: Spring:isSettled
-- Returns `true` when all spring axes have converged within `precision`.
-- Call when you need to check is settled.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:isSettled() end)
  print("Spring:isSettled ->", ok, result)
end

--@api-stub: Spring:isActive
-- Returns `true` if the spring has not been cancelled or settled.
-- Call when you need to check is active.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("Spring:isActive ->", ok, result)
end

--@api-stub: Spring:setTarget
-- Updates target values for all fields present in `fields_table`.
-- Call when you need to assign target.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:setTarget({}) end)
  print("Spring:setTarget ->", ok, result)
end

--@api-stub: Spring:setStiffness
-- Updates the stiffness constant on all axes.
-- Call when you need to assign stiffness.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:setStiffness(nil) end)
  print("Spring:setStiffness ->", ok, result)
end

--@api-stub: Spring:setDamping
-- Updates the damping coefficient on all axes.
-- Call when you need to assign damping.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:setDamping(nil) end)
  print("Spring:setDamping ->", ok, result)
end

--@api-stub: Spring:cancel
-- Stops the spring.
-- The engine will drop it on the next `update(dt)` call.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:cancel() end)
  print("Spring:cancel ->", ok, result)
end

--@api-stub: Spring:getPosition
-- Returns the current interpolated position for the named field, or `nil`.
-- Call when you need to read position.
-- Build a Spring via the appropriate lurek.tween.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tween.newSpring(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition(nil) end)
  print("Spring:getPosition ->", ok, result)
end

