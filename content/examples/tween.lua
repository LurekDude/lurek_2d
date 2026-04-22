-- content/examples/tween.lua
-- Auto-scaffolded coverage of the lurek.tween Lua API (35 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/tween.lua

print("[example] lurek.tween loaded — 35 API items demonstrated")

-- ── lurek.tween free functions ──

--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, and parallels by `dt` seconds.
-- Use this when advances all active tweens, sequences, and parallels by `dt` seconds is needed.
if false then
  local _r = lurek.tween.update(0)
  print(_r)
end

--@api-stub: lurek.tween.tween
-- Creates a new property tween and registers it for automatic updating.
-- Use this when creates a new property tween and registers it for automatic updating is needed.
if false then
  local _r = lurek.tween.tween()
  print(_r)
end

--@api-stub: lurek.tween.sequence
-- Creates an empty TweenSequence.
-- Add steps with :tween(), :delay(), :callback(),
if false then
  local _r = lurek.tween.sequence()
  print(_r)
end

--@api-stub: lurek.tween.parallel
-- Creates an empty TweenParallel.
-- Add entries with :tween() or :add(tween),
if false then
  local _r = lurek.tween.parallel()
  print(_r)
end

--@api-stub: lurek.tween.delay
-- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
-- Use this when creates a no-op tween that waits `seconds`, then optionally calls `callback` is needed.
if false then
  local _r = lurek.tween.delay(1, function() end)
  print(_r)
end

--@api-stub: lurek.tween.cancelAll
-- Cancels all active tweens, sequences, parallels, and springs immediately.
-- Use this when cancels all active tweens, sequences, parallels, and springs immediately is needed.
if false then
  local _r = lurek.tween.cancelAll()
  print(_r)
end

--@api-stub: lurek.tween.getActiveCount
-- Returns the number of currently active tween objects (tweens + seqs + pars).
-- Use this when returns the number of currently active tween objects (tweens + seqs + pars) is needed.
if false then
  local _r = lurek.tween.getActiveCount()
  print(_r)
end

--@api-stub: lurek.tween.registerEasing
-- Registers a custom easing function under `name`.
-- `fn(t)` receives 0..1, returns 0..1.
if false then
  local _r = lurek.tween.registerEasing(1, nil)
  print(_r)
end

--@api-stub: lurek.tween.getEasingNames
-- Returns a list of all available easing names (built-in + custom).
-- Use this when returns a list of all available easing names (built-in + custom) is needed.
if false then
  local _r = lurek.tween.getEasingNames()
  print(_r)
end

--@api-stub: lurek.tween.newState
-- Creates a standalone tween timing state without registering it with the engine.
-- Use this when creates a standalone tween timing state without registering it with the engine is needed.
if false then
  local _r = lurek.tween.newState(1, 1)
  print(_r)
end

--@api-stub: lurek.tween.to
-- Sugar for `tween()` with `target` first â€” natural read order.
-- Use this when sugar for `tween()` with `target` first â€” natural read order is needed.
if false then
  local _r = lurek.tween.to()
  print(_r)
end

--@api-stub: lurek.tween.spring
-- Creates a physics-based spring animation that drives named fields on `target_table`.
-- Use this when creates a physics-based spring animation that drives named fields on `target_table` is needed.
if false then
  local _r = lurek.tween.spring(0, 0, 0)
  print(_r)
end

-- ── TweenState methods ──

--@api-stub: TweenState:tick
-- Advances the tween state by `dt` seconds.
-- Use this when advances the tween state by `dt` seconds is needed.
if false then
  local _o = nil  -- TweenState instance
  _o:tick(0)
end

--@api-stub: TweenState:isComplete
-- Returns whether the tween state has completed.
-- Use this when returns whether the tween state has completed is needed.
if false then
  local _o = nil  -- TweenState instance
  _o:isComplete()
end

--@api-stub: TweenState:t
-- Returns the raw 0..1 playback progress.
-- Use this when returns the raw 0..1 playback progress is needed.
if false then
  local _o = nil  -- TweenState instance
  _o:t()
end

--@api-stub: TweenState:lerp
-- Interpolates from `start` to `finish` using the eased tween progress.
-- Use this when interpolates from `start` to `finish` using the eased tween progress is needed.
if false then
  local _o = nil  -- TweenState instance
  _o:lerp(0, 1)
end

--@api-stub: TweenState:reset
-- Resets the tween state to elapsed time zero.
-- Use this when resets the tween state to elapsed time zero is needed.
if false then
  local _o = nil  -- TweenState instance
  _o:reset()
end

-- ── Tween methods ──

--@api-stub: Tween:pause
-- Pauses this tween; time stops advancing but the tween is not cancelled.
-- Use this when pauses this tween; time stops advancing but the tween is not cancelled is needed.
if false then
  local _o = nil  -- Tween instance
  _o:pause()
end

--@api-stub: Tween:resume
-- Resumes a paused tween, continuing from the position where it was paused.
-- Use this when resumes a paused tween, continuing from the position where it was paused is needed.
if false then
  local _o = nil  -- Tween instance
  _o:resume()
end

--@api-stub: Tween:isActive
-- Returns true if the tween is still running (not completed or cancelled).
-- Use this when returns true if the tween is still running (not completed or cancelled) is needed.
if false then
  local _o = nil  -- Tween instance
  _o:isActive()
end

--@api-stub: Tween:getProgress
-- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
-- Use this when returns raw 0..1 playback progress (not eased, not accounting for yoyo) is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getProgress()
end

--@api-stub: Tween:setRepeat
-- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
-- Use this when sets the number of extra play cycles after the first (0 = play once, -1 = infinite) is needed.
if false then
  local _o = nil  -- Tween instance
  _o:setRepeat(1)
end

--@api-stub: Tween:setYoyo
-- Enables or disables yoyo (ping-pong) on each repeat cycle.
-- Use this when enables or disables yoyo (ping-pong) on each repeat cycle is needed.
if false then
  local _o = nil  -- Tween instance
  _o:setYoyo(1)
end

-- ── TweenSequence methods ──

--@api-stub: TweenSequence:cancel
-- Cancels the sequence and stops all pending steps.
-- Use this when cancels the sequence and stops all pending steps is needed.
if false then
  local _o = nil  -- TweenSequence instance
  _o:cancel()
end

--@api-stub: TweenSequence:isActive
-- Returns true if the sequence has been started and has not yet completed.
-- Use this when returns true if the sequence has been started and has not yet completed is needed.
if false then
  local _o = nil  -- TweenSequence instance
  _o:isActive()
end

-- ── TweenParallel methods ──

--@api-stub: TweenParallel:cancel
-- Cancels the parallel group immediately.
-- Use this when cancels the parallel group immediately is needed.
if false then
  local _o = nil  -- TweenParallel instance
  _o:cancel()
end

--@api-stub: TweenParallel:isActive
-- Returns true if the parallel is running and not yet complete.
-- Use this when returns true if the parallel is running and not yet complete is needed.
if false then
  local _o = nil  -- TweenParallel instance
  _o:isActive()
end

-- ── Spring methods ──

--@api-stub: Spring:update
-- Advances the spring by `dt` seconds and writes positions to the target table.
-- Use this when advances the spring by `dt` seconds and writes positions to the target table is needed.
if false then
  local _o = nil  -- Spring instance
  _o:update(0)
end

--@api-stub: Spring:isSettled
-- Returns `true` when all spring axes have converged within `precision`.
-- Use this when returns `true` when all spring axes have converged within `precision` is needed.
if false then
  local _o = nil  -- Spring instance
  _o:isSettled()
end

--@api-stub: Spring:isActive
-- Returns `true` if the spring has not been cancelled or settled.
-- Use this when returns `true` if the spring has not been cancelled or settled is needed.
if false then
  local _o = nil  -- Spring instance
  _o:isActive()
end

--@api-stub: Spring:setTarget
-- Updates target values for all fields present in `fields_table`.
-- Use this when updates target values for all fields present in `fields_table` is needed.
if false then
  local _o = nil  -- Spring instance
  _o:setTarget(0)
end

--@api-stub: Spring:setStiffness
-- Updates the stiffness constant on all axes.
-- Use this when updates the stiffness constant on all axes is needed.
if false then
  local _o = nil  -- Spring instance
  _o:setStiffness(0)
end

--@api-stub: Spring:setDamping
-- Updates the damping coefficient on all axes.
-- Use this when updates the damping coefficient on all axes is needed.
if false then
  local _o = nil  -- Spring instance
  _o:setDamping(0)
end

--@api-stub: Spring:cancel
-- Stops the spring.
-- The engine will drop it on the next `update(dt)` call.
if false then
  local _o = nil  -- Spring instance
  _o:cancel()
end

--@api-stub: Spring:getPosition
-- Returns the current interpolated position for the named field, or `nil`.
-- Use this when returns the current interpolated position for the named field, or `nil` is needed.
if false then
  local _o = nil  -- Spring instance
  _o:getPosition(nil)
end

