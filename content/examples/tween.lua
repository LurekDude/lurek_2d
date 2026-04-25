-- content/examples/tween.lua
-- Hand-written coverage of the lurek.tween API (35 items).
--
-- The lurek.tween namespace drives table-field interpolation: classic
-- duration-based tweens, chained sequences, parallel groups, and
-- physics-based springs. Build animations once at startup or in
-- response to events; advance the global engine each frame with
-- lurek.tween.update(dt) inside lurek.process(dt).
--
-- Run: cargo run -- content/examples/tween.lua

-- ── lurek.tween.* functions ──

--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, and parallels by `dt` seconds.
-- Call once per frame in lurek.process(dt) so all active tweens, sequences, and springs advance.
do  -- lurek.tween.update
  function lurek.process(dt)
    lurek.tween.update(dt)
  end
end

--@api-stub: lurek.tween.tween
-- Creates a new property tween and registers it for automatic updating.
-- Pass any plain Lua table; start values are captured lazily on the first update tick.
do  -- lurek.tween.tween
  local hud = { alpha = 0, y = -32 }
  lurek.tween.tween(0.4, hud, { alpha = 1, y = 0 }, "outQuad")
end

--@api-stub: lurek.tween.sequence
-- Creates an empty TweenSequence.
-- Build a chain with :tween, :delay, and :callback, then :start to register it for ticking.
do  -- lurek.tween.sequence
  local door = { y = 0 }
  lurek.tween.sequence()
    :tween(0.5, door, { y = 64 }, "outQuad")
    :delay(0.25)
    :start()
end

--@api-stub: lurek.tween.parallel
-- Creates an empty TweenParallel.
-- Use to fire multiple tweens that share a start time and run in lockstep on the same target.
do  -- lurek.tween.parallel
  local actor = { x = 0, alpha = 1 }
  lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 }, "inOutQuad")
    :tween(0.6, actor, { alpha = 0 }, "linear")
    :start()
end

--@api-stub: lurek.tween.delay
-- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
-- Handy for one-shot timers like respawn delays; the callback fires once `seconds` elapse.
do  -- lurek.tween.delay
  lurek.tween.delay(1.5, function()
    lurek.log.info("respawn now", "spawn")
  end)
end

--@api-stub: lurek.tween.cancelAll
-- Cancels all active tweens, sequences, parallels, and springs immediately.
-- Call at scene transitions to clear any animation that would race the new scene state.
do  -- lurek.tween.cancelAll
  lurek.tween.cancelAll()
end

--@api-stub: lurek.tween.getActiveCount
-- Returns the number of currently active tween objects (tweens + seqs + pars).
-- Useful for debug overlays or asserting that scene cleanup left no orphaned tweens behind.
do  -- lurek.tween.getActiveCount
  local n = lurek.tween.getActiveCount()
  if n > 100 then
    lurek.log.warn("tween budget exceeded: " .. n, "tween")
  end
end

--@api-stub: lurek.tween.registerEasing
-- Registers a custom easing function under `name`.
-- Register at startup; `fn(t)` receives 0..1 and must return 0..1 for predictable behaviour.
do  -- lurek.tween.registerEasing
  lurek.tween.registerEasing("squared", function(t)
    return t * t
  end)
end

--@api-stub: lurek.tween.getEasingNames
-- Returns a list of all available easing names (built-in + custom).
-- Useful for editor-style dropdowns or to validate a config string before passing to tween().
do  -- lurek.tween.getEasingNames
  local names = lurek.tween.getEasingNames()
  for i = 1, #names do
    lurek.log.debug("easing[" .. i .. "]=" .. names[i], "tween")
  end
end

--@api-stub: lurek.tween.newState
-- Creates a standalone tween timing state without registering it with the engine.
-- Use when you want to drive interpolation by hand; the engine will not tick this state for you.
do  -- lurek.tween.newState
  local s = lurek.tween.newState(0.5, "outCubic")
  s:tick(1 / 60)
  local x = s:lerp(0, 100)
  lurek.log.debug("hand-eased x=" .. x, "tween")
end

--@api-stub: lurek.tween.to
-- Sugar for `tween()` with `target` first — natural read order.
-- Reads more naturally than tween() when the table being animated is the focus of the call.
do  -- lurek.tween.to
  local enemy = { hp = 100 }
  lurek.tween.to(enemy, { hp = 0 }, 0.8, "inQuad")
end

--@api-stub: lurek.tween.spring
-- Creates a physics-based spring animation that drives named fields on `target_table`.
-- Springs feel snappier than fixed-duration tweens for UI bounces, follow cameras, and pop-ins.
do  -- lurek.tween.spring
  local cam = { x = 0, y = 0 }
  lurek.tween.spring(cam, { x = 320, y = 180 }, { stiffness = 180, damping = 18 })
end


-- ── TweenState methods ──

--@api-stub: TweenState:tick
-- Advances the tween state by `dt` seconds.
-- Drive a standalone state when you do not want the engine to own its lifecycle.
do  -- TweenState:tick
  local s = lurek.tween.newState(1.0)
  function lurek.process(dt) s:tick(dt) end
end

--@api-stub: TweenState:isComplete
-- Returns whether the tween state has completed.
-- Poll inside a process callback to react when a hand-driven state finishes its run.
do  -- TweenState:isComplete
  local s = lurek.tween.newState(0.5)
  s:tick(0.5)
  if s:isComplete() then
    lurek.log.info("ease finished", "tween")
  end
end

--@api-stub: TweenState:t
-- Returns the raw 0..1 playback progress.
-- Use the raw 0..1 progress when you need the linear input to a custom easing curve.
do  -- TweenState:t
  local s = lurek.tween.newState(0.5)
  s:tick(0.25)
  local raw = s:t()
  lurek.log.debug("raw t=" .. raw, "tween")
end

--@api-stub: TweenState:lerp
-- Interpolates from `start` to `finish` using the eased tween progress.
-- Apply the eased progress to a numeric range; one state can drive several lerps per frame.
do  -- TweenState:lerp
  local s = lurek.tween.newState(0.5, "outQuad")
  s:tick(0.25)
  local x = s:lerp(0, 320)
  local y = s:lerp(180, 0)
  lurek.log.debug("ease x=" .. x .. " y=" .. y, "tween")
end

--@api-stub: TweenState:reset
-- Resets the tween state to elapsed time zero.
-- Call when you want to replay the same animation without allocating a fresh state object.
do  -- TweenState:reset
  local s = lurek.tween.newState(0.5)
  s:tick(0.5)
  s:reset()
end


-- ── Tween methods ──

--@api-stub: Tween:pause
-- Pauses this tween; time stops advancing but the tween is not cancelled.
-- Pause when the player opens a menu so the in-game tween freezes exactly mid-flight.
do  -- Tween:pause
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 })
  tw:pause()
end

--@api-stub: Tween:resume
-- Resumes a paused tween, continuing from the position where it was paused.
-- Pair with :pause; :resume picks up exactly where the tween was suspended.
do  -- Tween:resume
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 })
  tw:pause()
  tw:resume()
end

--@api-stub: Tween:isActive
-- Returns true if the tween is still running (not completed or cancelled).
-- Check before queueing a follow-up to avoid stacking duplicate animations on the same target.
do  -- Tween:isActive
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 })
  if tw:isActive() then
    lurek.log.debug("card moving", "ui")
  end
end

--@api-stub: Tween:getProgress
-- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
-- Pair with isActive to drive a UI element like a loading bar that mirrors the tween.
do  -- Tween:getProgress
  local bar = { fill = 0 }
  local tw = lurek.tween.tween(2.0, bar, { fill = 1 })
  local p = tw:getProgress()
  lurek.log.debug("loading=" .. p, "ui")
end

--@api-stub: Tween:setRepeat
-- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
-- Pass -1 for infinite; useful for idle loops like a heartbeat glow or a beacon flash.
do  -- Tween:setRepeat
  local glow = { alpha = 0.3 }
  local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 })
  tw:setRepeat(-1)
end

--@api-stub: Tween:setYoyo
-- Enables or disables yoyo (ping-pong) on each repeat cycle.
-- Combine with setRepeat so the value bounces back-and-forth rather than snapping to start.
do  -- Tween:setYoyo
  local glow = { alpha = 0.3 }
  local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 })
  tw:setRepeat(-1)
  tw:setYoyo(true)
end


-- ── TweenSequence methods ──

--@api-stub: TweenSequence:cancel
-- Cancels the sequence and stops all pending steps.
-- Stop a chained intro animation when the player skips the cinematic mid-playback.
do  -- TweenSequence:cancel
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  seq:cancel()
end

--@api-stub: TweenSequence:isActive
-- Returns true if the sequence has been started and has not yet completed.
-- Gate input on isActive so the player cannot interrupt a critical mid-sequence step.
do  -- TweenSequence:isActive
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  if seq:isActive() then
    lurek.log.debug("door opening", "scene")
  end
end


-- ── TweenParallel methods ──

--@api-stub: TweenParallel:cancel
-- Cancels the parallel group immediately.
-- Cancel the group as a unit; do not iterate child tweens and cancel them one at a time.
do  -- TweenParallel:cancel
  local actor = { x = 0, alpha = 1 }
  local par = lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 })
    :tween(0.6, actor, { alpha = 0 })
    :start()
  par:cancel()
end

--@api-stub: TweenParallel:isActive
-- Returns true if the parallel is running and not yet complete.
-- Check before chaining a follow-up so two groups do not race each other on shared fields.
do  -- TweenParallel:isActive
  local actor = { x = 0, alpha = 1 }
  local par = lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 })
    :tween(0.6, actor, { alpha = 0 })
    :start()
  if par:isActive() then
    lurek.log.debug("actor exiting", "scene")
  end
end


-- ── Spring methods ──

--@api-stub: Spring:update
-- Advances the spring by `dt` seconds and writes positions to the target table.
-- Tick manually only when you skipped lurek.tween.update; otherwise let the engine drive it.
do  -- Spring:update
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  function lurek.process(dt) sp:update(dt) end
end

--@api-stub: Spring:isSettled
-- Returns `true` when all spring axes have converged within `precision`.
-- Detect convergence by precision rather than by waiting on a fixed duration as with tweens.
do  -- Spring:isSettled
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  if sp:isSettled() then
    lurek.log.debug("camera at rest", "camera")
  end
end

--@api-stub: Spring:isActive
-- Returns `true` if the spring has not been cancelled or settled.
-- isActive flips false after the spring settles or is cancelled; safer than checking isSettled.
do  -- Spring:isActive
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  if sp:isActive() then
    lurek.log.debug("camera following", "camera")
  end
end

--@api-stub: Spring:setTarget
-- Updates target values for all fields present in `fields_table`.
-- Update mid-flight to chase a moving point; the spring keeps its current velocity for smoothness.
do  -- Spring:setTarget
  local cam = { x = 0, y = 0 }
  local sp = lurek.tween.spring(cam, { x = 320, y = 180 })
  sp:setTarget({ x = 480, y = 240 })
end

--@api-stub: Spring:setStiffness
-- Updates the stiffness constant on all axes.
-- Higher stiffness reaches the target faster but overshoots more unless damping rises with it.
do  -- Spring:setStiffness
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:setStiffness(240)
end

--@api-stub: Spring:setDamping
-- Updates the damping coefficient on all axes.
-- Raise damping alongside stiffness to keep the spring near-critical; under-damped springs ring.
do  -- Spring:setDamping
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:setDamping(24)
end

--@api-stub: Spring:cancel
-- Stops the spring.
-- Cancel does not snap the field to the target; clamp the value yourself if you need it landed.
do  -- Spring:cancel
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:cancel()
end

--@api-stub: Spring:getPosition
-- Returns the current interpolated position for the named field, or `nil`.
-- Returns nil for unknown field names; useful for debug overlays without writing to the table.
do  -- Spring:getPosition
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  local px = sp:getPosition("x")
  if px then
    lurek.log.debug("spring x=" .. px, "camera")
  end
end

-- ---- Stub: Spring:type ---------------------------------------------------
--@api-stub: Spring:type
do  -- Spring:type
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  assert(sp:type() == "Spring")
end

-- ---- Stub: Spring:typeOf -------------------------------------------------
--@api-stub: Spring:typeOf
do  -- Spring:typeOf
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  assert(sp:typeOf("Spring") == true)
end

-- -----------------------------------------------------------------------------
-- Tween methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Tween:onComplete ----------------------------------------------
--@api-stub: Tween:onComplete
do  -- Tween:onComplete
  local box = { x = 0 }
  -- onComplete registers a callback; tween auto-starts via lurek.tween.tween.
  lurek.tween.tween(0.5, box, { x = 100 }):onComplete(function()
    lurek.log.debug("done", "tween")
  end)
end

-- ---- Stub: Tween:onUpdate ------------------------------------------------
--@api-stub: Tween:onUpdate
do  -- Tween:onUpdate
  local box = { x = 0 }
  lurek.tween.tween(0.5, box, { x = 100 }):onUpdate(function(t)
    lurek.log.debug("t=" .. t, "tween")
  end)
end

-- ---- Stub: Tween:onCancel ------------------------------------------------
--@api-stub: Tween:onCancel
do  -- Tween:onCancel
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  tw:onCancel(function() lurek.log.debug("cancelled", "tween") end)
  tw:cancel()
end

-- ---- Stub: Tween:type ----------------------------------------------------
--@api-stub: Tween:type
do  -- Tween:type
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  assert(tw:type() == "Tween")
end

-- ---- Stub: Tween:typeOf --------------------------------------------------
--@api-stub: Tween:typeOf
do  -- Tween:typeOf
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  assert(tw:typeOf("Tween") == true)
end

-- -----------------------------------------------------------------------------
-- TweenParallel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: TweenParallel:add ---------------------------------------------
--@api-stub: TweenParallel:add
do  -- TweenParallel:add
  local a = { x = 0 }
  local b = { y = 0 }
  local tw1 = lurek.tween.tween(0.4, a, { x = 80 })
  local par = lurek.tween.parallel()
  par:add(tw1)
  par:tween(0.4, b, { y = 80 })
  par:start()
end

-- ---- Stub: TweenParallel:onComplete --------------------------------------
--@api-stub: TweenParallel:onComplete
do  -- TweenParallel:onComplete
  local actor = { x = 0, alpha = 1 }
  lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 })
    :tween(0.6, actor, { alpha = 0 })
    :onComplete(function() lurek.log.debug("parallel done", "tween") end)
    :start()
end

-- ---- Stub: TweenParallel:type --------------------------------------------
--@api-stub: TweenParallel:type
do  -- TweenParallel:type
  local par = lurek.tween.parallel()
  assert(par:type() == "TweenParallel")
end

-- ---- Stub: TweenParallel:typeOf ------------------------------------------
--@api-stub: TweenParallel:typeOf
do  -- TweenParallel:typeOf
  local par = lurek.tween.parallel()
  assert(par:typeOf("TweenParallel") == true)
end

-- -----------------------------------------------------------------------------
-- TweenSequence methods
-- -----------------------------------------------------------------------------

-- ---- Stub: TweenSequence:callback ----------------------------------------
--@api-stub: TweenSequence:callback
do  -- TweenSequence:callback
  local door = { y = 0 }
  lurek.tween.sequence()
    :tween(0.3, door, { y = 64 })
    :callback(function() lurek.log.debug("door open", "scene") end)
    :tween(0.3, door, { y = 0 })
    :start()
end

-- ---- Stub: TweenSequence:onComplete --------------------------------------
--@api-stub: TweenSequence:onComplete
do  -- TweenSequence:onComplete
  local door = { y = 0 }
  lurek.tween.sequence()
    :tween(0.4, door, { y = 64 })
    :onComplete(function() lurek.log.debug("sequence done", "scene") end)
    :start()
end

-- ---- Stub: TweenSequence:type --------------------------------------------
--@api-stub: TweenSequence:type
do  -- TweenSequence:type
  local seq = lurek.tween.sequence()
  assert(seq:type() == "TweenSequence")
end

-- ---- Stub: TweenSequence:typeOf ------------------------------------------
--@api-stub: TweenSequence:typeOf
do  -- TweenSequence:typeOf
  local seq = lurek.tween.sequence()
  assert(seq:typeOf("TweenSequence") == true)
end
