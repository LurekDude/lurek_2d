-- content/examples/tween.lua
-- Scaffolded coverage of the lurek.tween API (35 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/tween_api.rs   (Lua binding, arg types, return shape)
--   * src/tween/                 (semantics, side effects)
--   * docs/specs/tween.md        (canonical reference)
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
-- Run: cargo run -- content/examples/tween.lua

-- ── lurek.tween.* functions ──

--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, and parallels by `dt` seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.update
  local _todo = "TODO: write a real lurek.tween.update usage example"
  print(_todo)
end

--@api-stub: lurek.tween.tween
-- Creates a new property tween and registers it for automatic updating.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.tween
  local _todo = "TODO: write a real lurek.tween.tween usage example"
  print(_todo)
end

--@api-stub: lurek.tween.sequence
-- Creates an empty TweenSequence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.sequence
  local _todo = "TODO: write a real lurek.tween.sequence usage example"
  print(_todo)
end

--@api-stub: lurek.tween.parallel
-- Creates an empty TweenParallel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.parallel
  local _todo = "TODO: write a real lurek.tween.parallel usage example"
  print(_todo)
end

--@api-stub: lurek.tween.delay
-- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.delay
  local _todo = "TODO: write a real lurek.tween.delay usage example"
  print(_todo)
end

--@api-stub: lurek.tween.cancelAll
-- Cancels all active tweens, sequences, parallels, and springs immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.cancelAll
  local _todo = "TODO: write a real lurek.tween.cancelAll usage example"
  print(_todo)
end

--@api-stub: lurek.tween.getActiveCount
-- Returns the number of currently active tween objects (tweens + seqs + pars).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.getActiveCount
  local _todo = "TODO: write a real lurek.tween.getActiveCount usage example"
  print(_todo)
end

--@api-stub: lurek.tween.registerEasing
-- Registers a custom easing function under `name`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.registerEasing
  local _todo = "TODO: write a real lurek.tween.registerEasing usage example"
  print(_todo)
end

--@api-stub: lurek.tween.getEasingNames
-- Returns a list of all available easing names (built-in + custom).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.getEasingNames
  local _todo = "TODO: write a real lurek.tween.getEasingNames usage example"
  print(_todo)
end

--@api-stub: lurek.tween.newState
-- Creates a standalone tween timing state without registering it with the engine.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.newState
  local _todo = "TODO: write a real lurek.tween.newState usage example"
  print(_todo)
end

--@api-stub: lurek.tween.to
-- Sugar for `tween()` with `target` first â€” natural read order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.to
  local _todo = "TODO: write a real lurek.tween.to usage example"
  print(_todo)
end

--@api-stub: lurek.tween.spring
-- Creates a physics-based spring animation that drives named fields on `target_table`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: lurek.tween.spring
  local _todo = "TODO: write a real lurek.tween.spring usage example"
  print(_todo)
end

-- ── TweenState methods ──

--@api-stub: TweenState:tick
-- Advances the tween state by `dt` seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenState:tick
  local _todo = "TODO: write a real TweenState:tick usage example"
  print(_todo)
end

--@api-stub: TweenState:isComplete
-- Returns whether the tween state has completed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenState:isComplete
  local _todo = "TODO: write a real TweenState:isComplete usage example"
  print(_todo)
end

--@api-stub: TweenState:t
-- Returns the raw 0..1 playback progress.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenState:t
  local _todo = "TODO: write a real TweenState:t usage example"
  print(_todo)
end

--@api-stub: TweenState:lerp
-- Interpolates from `start` to `finish` using the eased tween progress.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenState:lerp
  local _todo = "TODO: write a real TweenState:lerp usage example"
  print(_todo)
end

--@api-stub: TweenState:reset
-- Resets the tween state to elapsed time zero.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenState:reset
  local _todo = "TODO: write a real TweenState:reset usage example"
  print(_todo)
end

-- ── Tween methods ──

--@api-stub: Tween:pause
-- Pauses this tween; time stops advancing but the tween is not cancelled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Tween:pause
  local _todo = "TODO: write a real Tween:pause usage example"
  print(_todo)
end

--@api-stub: Tween:resume
-- Resumes a paused tween, continuing from the position where it was paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Tween:resume
  local _todo = "TODO: write a real Tween:resume usage example"
  print(_todo)
end

--@api-stub: Tween:isActive
-- Returns true if the tween is still running (not completed or cancelled).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Tween:isActive
  local _todo = "TODO: write a real Tween:isActive usage example"
  print(_todo)
end

--@api-stub: Tween:getProgress
-- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Tween:getProgress
  local _todo = "TODO: write a real Tween:getProgress usage example"
  print(_todo)
end

--@api-stub: Tween:setRepeat
-- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Tween:setRepeat
  local _todo = "TODO: write a real Tween:setRepeat usage example"
  print(_todo)
end

--@api-stub: Tween:setYoyo
-- Enables or disables yoyo (ping-pong) on each repeat cycle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Tween:setYoyo
  local _todo = "TODO: write a real Tween:setYoyo usage example"
  print(_todo)
end

-- ── TweenSequence methods ──

--@api-stub: TweenSequence:cancel
-- Cancels the sequence and stops all pending steps.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenSequence:cancel
  local _todo = "TODO: write a real TweenSequence:cancel usage example"
  print(_todo)
end

--@api-stub: TweenSequence:isActive
-- Returns true if the sequence has been started and has not yet completed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenSequence:isActive
  local _todo = "TODO: write a real TweenSequence:isActive usage example"
  print(_todo)
end

-- ── TweenParallel methods ──

--@api-stub: TweenParallel:cancel
-- Cancels the parallel group immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenParallel:cancel
  local _todo = "TODO: write a real TweenParallel:cancel usage example"
  print(_todo)
end

--@api-stub: TweenParallel:isActive
-- Returns true if the parallel is running and not yet complete.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: TweenParallel:isActive
  local _todo = "TODO: write a real TweenParallel:isActive usage example"
  print(_todo)
end

-- ── Spring methods ──

--@api-stub: Spring:update
-- Advances the spring by `dt` seconds and writes positions to the target table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:update
  local _todo = "TODO: write a real Spring:update usage example"
  print(_todo)
end

--@api-stub: Spring:isSettled
-- Returns `true` when all spring axes have converged within `precision`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:isSettled
  local _todo = "TODO: write a real Spring:isSettled usage example"
  print(_todo)
end

--@api-stub: Spring:isActive
-- Returns `true` if the spring has not been cancelled or settled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:isActive
  local _todo = "TODO: write a real Spring:isActive usage example"
  print(_todo)
end

--@api-stub: Spring:setTarget
-- Updates target values for all fields present in `fields_table`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:setTarget
  local _todo = "TODO: write a real Spring:setTarget usage example"
  print(_todo)
end

--@api-stub: Spring:setStiffness
-- Updates the stiffness constant on all axes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:setStiffness
  local _todo = "TODO: write a real Spring:setStiffness usage example"
  print(_todo)
end

--@api-stub: Spring:setDamping
-- Updates the damping coefficient on all axes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:setDamping
  local _todo = "TODO: write a real Spring:setDamping usage example"
  print(_todo)
end

--@api-stub: Spring:cancel
-- Stops the spring.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:cancel
  local _todo = "TODO: write a real Spring:cancel usage example"
  print(_todo)
end

--@api-stub: Spring:getPosition
-- Returns the current interpolated position for the named field, or `nil`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tween_api.rs and docs/specs/tween.md).
do  -- TODO: Spring:getPosition
  local _todo = "TODO: write a real Spring:getPosition usage example"
  print(_todo)
end

