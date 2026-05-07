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

-- â”€â”€ lurek.tween.* functions â”€â”€

--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, and parallels by `dt` seconds.
-- Call once per frame in lurek.process(dt) so all active tweens, sequences, and springs advance.
-- if false then -- lurek.tween.update
--   function lurek.process(dt)
--     lurek.tween.update(dt)
--   end
-- end

--@api-stub: lurek.tween.tween
-- Creates a new property tween and registers it for automatic updating.
-- Pass any plain Lua table; start values are captured lazily on the first update tick.
-- if false then -- lurek.tween.tween
--   local hud = { alpha = 0, y = -32 }
--   lurek.tween.tween(0.4, hud, { alpha = 1, y = 0 }, "outQuad")
-- end

--@api-stub: lurek.tween.sequence
-- Creates an empty TweenSequence.
-- Build a chain with :tween, :delay, and :callback, then :start to register it for ticking.
-- if false then -- lurek.tween.sequence
--   local door = { y = 0 }
--   lurek.tween.sequence()
--     :tween(0.5, door, { y = 64 }, "outQuad")
--     :delay(0.25)
--     :start()
-- end

--@api-stub: lurek.tween.parallel
-- Creates an empty TweenParallel.
-- Use to fire multiple tweens that share a start time and run in lockstep on the same target.
-- if false then -- lurek.tween.parallel
--   local actor = { x = 0, alpha = 1 }
--   lurek.tween.parallel()
--     :tween(0.6, actor, { x = 200 }, "inOutQuad")
--     :tween(0.6, actor, { alpha = 0 }, "linear")
--     :start()
-- end

--@api-stub: lurek.tween.delay
-- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
-- Handy for one-shot timers like respawn delays; the callback fires once `seconds` elapse.
-- if false then -- lurek.tween.delay
--   lurek.tween.delay(1.5, function()
--     lurek.log.info("respawn now", "spawn")
--   end)
-- end

--@api-stub: lurek.tween.cancelAll
-- Cancels all active tweens, sequences, parallels, and springs immediately.
-- Call at scene transitions to clear any animation that would race the new scene state.
-- if false then -- lurek.tween.cancelAll
--   lurek.tween.cancelAll()
-- end

--@api-stub: lurek.tween.getActiveCount
-- Returns the number of currently active tween objects (tweens + seqs + pars).
-- Useful for debug overlays or asserting that scene cleanup left no orphaned tweens behind.
-- if false then -- lurek.tween.getActiveCount
--   local n = lurek.tween.getActiveCount()
--   if n > 100 then
--     lurek.log.warn("tween budget exceeded: " .. n, "tween")
--   end
-- end

--@api-stub: lurek.tween.registerEasing
-- Registers a custom easing function under `name`.
-- Register at startup; `fn(t)` receives 0..1 and must return 0..1 for predictable behaviour.
-- if false then -- lurek.tween.registerEasing
--   lurek.tween.registerEasing("squared", function(t)
--     return t * t
--   end)
-- end

--@api-stub: lurek.tween.getEasingNames
-- Returns a list of all available easing names (built-in + custom).
-- Useful for editor-style dropdowns or to validate a config string before passing to tween().
-- if false then -- lurek.tween.getEasingNames
--   local names = lurek.tween.getEasingNames()
--   for i = 1, #names do
--     lurek.log.debug("easing[" .. i .. "]=" .. names[i], "tween")
--   end
-- end

--@api-stub: lurek.tween.newState
-- Creates a standalone tween timing state without registering it with the engine.
-- Use when you want to drive interpolation by hand; the engine will not tick this state for you.
-- if false then -- lurek.tween.newState
--   local s = lurek.tween.newState(0.5, "outCubic")
--   s:tick(1 / 60)
--   local x = s:lerp(0, 100)
--   lurek.log.debug("hand-eased x=" .. x, "tween")
-- end

--@api-stub: lurek.tween.to
-- Sugar for `tween()` with `target` first â€” natural read order.
-- Reads more naturally than tween() when the table being animated is the focus of the call.
-- if false then -- lurek.tween.to
--   local enemy = { hp = 100 }
--   lurek.tween.to(enemy, { hp = 0 }, 0.8, "inQuad")
-- end

--@api-stub: lurek.tween.spring
-- Creates a physics-based spring animation that drives named fields on `target_table`.
-- Springs feel snappier than fixed-duration tweens for UI bounces, follow cameras, and pop-ins.
-- if false then -- lurek.tween.spring
--   local cam = { x = 0, y = 0 }
--   lurek.tween.spring(cam, { x = 320, y = 180 }, { stiffness = 180, damping = 18 })
-- end


-- â”€â”€ TweenState methods â”€â”€

--@api-stub: LTweenState:tick
-- Advances the tween state by `dt` seconds.
-- Drive a standalone state when you do not want the engine to own its lifecycle.
-- if false then -- TweenState:tick
--   local s = lurek.tween.newState(1.0)
--   function lurek.process(dt) s:tick(dt) end
-- end

--@api-stub: LTweenState:isComplete
-- Returns whether the tween state has completed.
-- Poll inside a process callback to react when a hand-driven state finishes its run.
-- if false then -- TweenState:isComplete
--   local s = lurek.tween.newState(0.5)
--   s:tick(0.5)
--   if s:isComplete() then
--     lurek.log.info("ease finished", "tween")
--   end
-- end

--@api-stub: LTweenState:t
-- Returns the raw 0..1 playback progress.
-- Use the raw 0..1 progress when you need the linear input to a custom easing curve.
-- if false then -- TweenState:t
--   local s = lurek.tween.newState(0.5)
--   s:tick(0.25)
--   local raw = s:t()
--   lurek.log.debug("raw t=" .. raw, "tween")
-- end

--@api-stub: LTweenState:lerp
-- Interpolates from `start` to `finish` using the eased tween progress.
-- Apply the eased progress to a numeric range; one state can drive several lerps per frame.
-- if false then -- TweenState:lerp
--   local s = lurek.tween.newState(0.5, "outQuad")
--   s:tick(0.25)
--   local x = s:lerp(0, 320)
--   local y = s:lerp(180, 0)
--   lurek.log.debug("ease x=" .. x .. " y=" .. y, "tween")
-- end

--@api-stub: LTweenState:reset
-- Resets the tween state to elapsed time zero.
-- Call when you want to replay the same animation without allocating a fresh state object.
-- if false then -- TweenState:reset
--   local s = lurek.tween.newState(0.5)
--   s:tick(0.5)
--   s:reset()
-- end


-- â”€â”€ Tween methods â”€â”€

--@api-stub: LTween:pause
-- Pauses this tween; time stops advancing but the tween is not cancelled.
-- Pause when the player opens a menu so the in-game tween freezes exactly mid-flight.
-- if false then -- Tween:pause
--   local card = { y = 0 }
--   local tw = lurek.tween.tween(0.6, card, { y = 200 })
--   tw:pause()
-- end

--@api-stub: LTween:resume
-- Resumes a paused tween, continuing from the position where it was paused.
-- Pair with :pause; :resume picks up exactly where the tween was suspended.
-- if false then -- Tween:resume
--   local card = { y = 0 }
--   local tw = lurek.tween.tween(0.6, card, { y = 200 })
--   tw:pause()
--   tw:resume()
-- end

--@api-stub: LTween:isActive
-- Returns true if the tween is still running (not completed or cancelled).
-- Check before queueing a follow-up to avoid stacking duplicate animations on the same target.
-- if false then -- Tween:isActive
--   local card = { y = 0 }
--   local tw = lurek.tween.tween(0.6, card, { y = 200 })
--   if tw:isActive() then
--     lurek.log.debug("card moving", "ui")
--   end
-- end

--@api-stub: LTween:getProgress
-- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
-- Pair with isActive to drive a UI element like a loading bar that mirrors the tween.
-- if false then -- Tween:getProgress
--   local bar = { fill = 0 }
--   local tw = lurek.tween.tween(2.0, bar, { fill = 1 })
--   local p = tw:getProgress()
--   lurek.log.debug("loading=" .. p, "ui")
-- end

--@api-stub: LTween:setRepeat
-- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
-- Pass -1 for infinite; useful for idle loops like a heartbeat glow or a beacon flash.
-- if false then -- Tween:setRepeat
--   local glow = { alpha = 0.3 }
--   local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 })
--   tw:setRepeat(-1)
-- end

--@api-stub: LTween:setYoyo
-- Enables or disables yoyo (ping-pong) on each repeat cycle.
-- Combine with setRepeat so the value bounces back-and-forth rather than snapping to start.
-- if false then -- Tween:setYoyo
--   local glow = { alpha = 0.3 }
--   local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 })
--   tw:setRepeat(-1)
--   tw:setYoyo(true)
-- end


-- â”€â”€ TweenSequence methods â”€â”€

--@api-stub: LTweenSequence:cancel
-- Cancels the sequence and stops all pending steps.
-- Stop a chained intro animation when the player skips the cinematic mid-playback.
-- if false then -- TweenSequence:cancel
--   local door = { y = 0 }
--   local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
--   seq:cancel()
-- end

--@api-stub: LTweenSequence:isActive
-- Returns true if the sequence has been started and has not yet completed.
-- Gate input on isActive so the player cannot interrupt a critical mid-sequence step.
-- if false then -- TweenSequence:isActive
--   local door = { y = 0 }
--   local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
--   if seq:isActive() then
--     lurek.log.debug("door opening", "scene")
--   end
-- end


-- â”€â”€ TweenParallel methods â”€â”€

--@api-stub: LTweenParallel:cancel
-- Cancels the parallel group immediately.
-- Cancel the group as a unit; do not iterate child tweens and cancel them one at a time.
-- if false then -- TweenParallel:cancel
--   local actor = { x = 0, alpha = 1 }
--   local par = lurek.tween.parallel()
--     :tween(0.6, actor, { x = 200 })
--     :tween(0.6, actor, { alpha = 0 })
--     :start()
--   par:cancel()
-- end

--@api-stub: LTweenParallel:isActive
-- Returns true if the parallel is running and not yet complete.
-- Check before chaining a follow-up so two groups do not race each other on shared fields.
-- if false then -- TweenParallel:isActive
--   local actor = { x = 0, alpha = 1 }
--   local par = lurek.tween.parallel()
--     :tween(0.6, actor, { x = 200 })
--     :tween(0.6, actor, { alpha = 0 })
--     :start()
--   if par:isActive() then
--     lurek.log.debug("actor exiting", "scene")
--   end
-- end


-- â”€â”€ Spring methods â”€â”€

--@api-stub: LSpring:update
-- Advances the spring by `dt` seconds and writes positions to the target table.
-- Tick manually only when you skipped lurek.tween.update; otherwise let the engine drive it.
-- if false then -- Spring:update
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   function lurek.process(dt) sp:update(dt) end
-- end

--@api-stub: LSpring:isSettled
-- Returns `true` when all spring axes have converged within `precision`.
-- Detect convergence by precision rather than by waiting on a fixed duration as with tweens.
-- if false then -- Spring:isSettled
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   if sp:isSettled() then
--     lurek.log.debug("camera at rest", "camera")
--   end
-- end

--@api-stub: LSpring:isActive
-- Returns `true` if the spring has not been cancelled or settled.
-- isActive flips false after the spring settles or is cancelled; safer than checking isSettled.
-- if false then -- Spring:isActive
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   if sp:isActive() then
--     lurek.log.debug("camera following", "camera")
--   end
-- end

--@api-stub: LSpring:setTarget
-- Updates target values for all fields present in `fields_table`.
-- Update mid-flight to chase a moving point; the spring keeps its current velocity for smoothness.
-- if false then -- Spring:setTarget
--   local cam = { x = 0, y = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320, y = 180 })
--   sp:setTarget({ x = 480, y = 240 })
-- end

--@api-stub: LSpring:setStiffness
-- Updates the stiffness constant on all axes.
-- Higher stiffness reaches the target faster but overshoots more unless damping rises with it.
-- if false then -- Spring:setStiffness
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   sp:setStiffness(240)
-- end

--@api-stub: LSpring:setDamping
-- Updates the damping coefficient on all axes.
-- Raise damping alongside stiffness to keep the spring near-critical; under-damped springs ring.
-- if false then -- Spring:setDamping
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   sp:setDamping(24)
-- end

--@api-stub: LSpring:cancel
-- Stops the spring.
-- Cancel does not snap the field to the target; clamp the value yourself if you need it landed.
-- if false then -- Spring:cancel
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   sp:cancel()
-- end

--@api-stub: LSpring:getPosition
-- Returns the current interpolated position for the named field, or `nil`.
-- Returns nil for unknown field names; useful for debug overlays without writing to the table.
-- if false then -- Spring:getPosition
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   local px = sp:getPosition("x")
--   if px then
--     lurek.log.debug("spring x=" .. px, "camera")
--   end
-- end

-- ---- Stub: Spring:type ---------------------------------------------------
--@api-stub: LSpring:type
-- if false then -- Spring:type
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   lurek.log.debug("spring type: " .. sp:type(), "tween")
-- end

-- ---- Stub: Spring:typeOf -------------------------------------------------
--@api-stub: LSpring:typeOf
-- if false then -- Spring:typeOf
--   local cam = { x = 0 }
--   local sp = lurek.tween.spring(cam, { x = 320 })
--   lurek.log.info("is Spring: " .. tostring(sp:typeOf("Spring")), "tween")
-- end

-- -----------------------------------------------------------------------------
-- Tween methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Tween:onComplete ----------------------------------------------
--@api-stub: LTween:onComplete
-- if false then -- Tween:onComplete
--   local box = { x = 0 }
  -- onComplete registers a callback; tween auto-starts via lurek.tween.tween.
--   lurek.tween.tween(0.5, box, { x = 100 }):onComplete(function()
--     lurek.log.debug("done", "tween")
--   end)
-- end

-- ---- Stub: Tween:onUpdate ------------------------------------------------
--@api-stub: LTween:onUpdate
-- if false then -- Tween:onUpdate
--   local box = { x = 0 }
--   lurek.tween.tween(0.5, box, { x = 100 }):onUpdate(function(t)
--     lurek.log.debug("t=" .. t, "tween")
--   end)
-- end

-- ---- Stub: Tween:onCancel ------------------------------------------------
--@api-stub: LTween:onCancel
-- if false then -- Tween:onCancel
--   local box = { x = 0 }
--   local tw = lurek.tween.tween(0.5, box, { x = 100 })
--   tw:onCancel(function() lurek.log.debug("cancelled", "tween") end)
--   tw:cancel()
-- end

-- ---- Stub: Tween:type ----------------------------------------------------
--@api-stub: LTween:type
-- if false then -- Tween:type
--   local box = { x = 0 }
--   local tw = lurek.tween.tween(0.5, box, { x = 100 })
--   lurek.log.info("Tween:type = " .. tostring(tw and tw:type() or "nil"), "tween")
-- end

-- ---- Stub: Tween:typeOf --------------------------------------------------
--@api-stub: LTween:typeOf
-- if false then -- Tween:typeOf
--   local box = { x = 0 }
--   local tw = lurek.tween.tween(0.5, box, { x = 100 })
--   lurek.log.info("Tween:typeOf = " .. tostring(tw and tw:typeOf("Tween") or false), "tween")
-- end

-- -----------------------------------------------------------------------------
-- TweenParallel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: TweenParallel:add ---------------------------------------------
--@api-stub: LTweenParallel:add
-- if false then -- TweenParallel:add
--   local a = { x = 0 }
--   local b = { y = 0 }
--   local tw1 = lurek.tween.tween(0.4, a, { x = 80 })
--   local par = lurek.tween.parallel()
--   par:add(tw1)
--   par:tween(0.4, b, { y = 80 })
--   par:start()
-- end

-- ---- Stub: TweenParallel:onComplete --------------------------------------
--@api-stub: LTweenParallel:onComplete
-- if false then -- TweenParallel:onComplete
--   local actor = { x = 0, alpha = 1 }
--   lurek.tween.parallel()
--     :tween(0.6, actor, { x = 200 })
--     :tween(0.6, actor, { alpha = 0 })
--     :onComplete(function() lurek.log.debug("parallel done", "tween") end)
--     :start()
-- end

-- ---- Stub: TweenParallel:type --------------------------------------------
--@api-stub: LTweenParallel:type
-- if false then -- TweenParallel:type
--   local par = lurek.tween.parallel()
--   lurek.log.info("TweenParallel:type = " .. tostring(par:type()), "tween")
-- end

-- ---- Stub: TweenParallel:typeOf ------------------------------------------
--@api-stub: LTweenParallel:typeOf
-- if false then -- TweenParallel:typeOf
--   local par = lurek.tween.parallel()
--   lurek.log.info("TweenParallel:typeOf = " .. tostring(par:typeOf("TweenParallel")), "tween")
-- end

-- -----------------------------------------------------------------------------
-- TweenSequence methods
-- -----------------------------------------------------------------------------

-- ---- Stub: TweenSequence:callback ----------------------------------------
--@api-stub: LTweenSequence:callback
-- if false then -- TweenSequence:callback
--   local door = { y = 0 }
--   lurek.tween.sequence()
--     :tween(0.3, door, { y = 64 })
--     :callback(function() lurek.log.debug("door open", "scene") end)
--     :tween(0.3, door, { y = 0 })
--     :start()
-- end

-- ---- Stub: TweenSequence:onComplete --------------------------------------
--@api-stub: LTweenSequence:onComplete
-- if false then -- TweenSequence:onComplete
--   local door = { y = 0 }
--   lurek.tween.sequence()
--     :tween(0.4, door, { y = 64 })
--     :onComplete(function() lurek.log.debug("sequence done", "scene") end)
--     :start()
-- end

-- ---- Stub: TweenSequence:type --------------------------------------------
--@api-stub: LTweenSequence:type
-- if false then -- TweenSequence:type
--   local seq = lurek.tween.sequence()
--   lurek.log.info("TweenSequence:type = " .. tostring(seq:type()), "tween")
-- end

-- ---- Stub: TweenSequence:typeOf ------------------------------------------
--@api-stub: LTweenSequence:typeOf
-- if false then -- TweenSequence:typeOf
--   local seq = lurek.tween.sequence()
--   lurek.log.info("TweenSequence:typeOf = " .. tostring(seq:typeOf("TweenSequence")), "tween")
-- end

-- =============================================================================
-- STUBS: 46 uncovered lurek.tween API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LTween methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTween:cancel -------------------------------------------------
--@api-stub: LTween:cancel
-- Cancels this tween immediately; fires the onCancel callback if set.
-- Use to interrupt tweens on scene exit or player death.
-- if false then -- LTween:cancel
--   local target = { x = 0 }
--   local tw = lurek.tween.tween(1.0, target, { x = 100 })
--   tw:cancel()   -- interrupt before it finishes
--   lurek.log.info("tween cancelled, target.x=" .. tostring(target.x), "tween")
-- end
--@api-stub: LTweenParallel:tween
-- Creates and adds an inline tween entry to the parallel group. Returns self.
-- Lets you chain multiple property animations that run simultaneously.
-- if false then -- LTweenParallel:tween
--   local obj = { x = 0, alpha = 1.0 }
--   lurek.tween.parallel()
--     :tween(0.5, obj, { x = 200 })
--     :tween(0.5, obj, { alpha = 0.0 })
--     :start()
--   lurek.log.info("parallel group with two tweens started", "tween")
-- end
--@api-stub: LTweenParallel:start
-- Marks the parallel as active. Returns self.
-- Call once all child tweens have been added; lurek.tween.update(dt) then ticks it.
-- if false then -- LTweenParallel:start
--   local pos = { x = 0 }
--   local col = { a = 1.0 }
--   lurek.tween.parallel()
--     :tween(0.4, pos, { x = 100 })
--     :tween(0.4, col, { a = 0 })
--     :start()   -- activates the group
--   lurek.log.info("parallel group started", "tween")
-- end
--@api-stub: LTweenSequence:tween
-- Appends a tween step: animates fields on target over duration. Returns self.
-- Chain multiple calls to build a step-by-step animation sequence.
-- if false then -- LTweenSequence:tween
--   local pos = { x = 0, y = 0 }
--   lurek.tween.sequence()
--     :tween(0.3, pos, { x = 100 })  -- step 1: move right
--     :tween(0.3, pos, { y = 80 })   -- step 2: move down
--     :start()
--   lurek.log.info("sequence with two tween steps queued", "tween")
-- end
--@api-stub: LTweenSequence:delay
-- Appends a delay step that waits seconds before proceeding. Returns self.
-- Insert pauses between animation steps for dramatic timing.
-- if false then -- LTweenSequence:delay
--   local obj = { x = 0 }
--   lurek.tween.sequence()
--     :tween(0.2, obj, { x = 100 })
--     :delay(0.5)                    -- pause half a second
--     :tween(0.2, obj, { x = 0 })
--     :start()
--   lurek.log.info("sequence with delay inserted", "tween")
-- end
--@api-stub: LTweenSequence:start
-- Marks the sequence as active so lurek.tween.update(dt) begins ticking it.
-- Without start() the sequence is dormant even after all steps are appended.
-- if false then -- LTweenSequence:start
--   local door = { y = 0 }
--   local seq = lurek.tween.sequence()
--     :tween(0.4, door, { y = 64 })
--     :delay(1.0)
--     :tween(0.4, door, { y = 0 })
--   seq:start()   -- begin the sequence
--   lurek.log.info("door open/wait/close sequence started", "tween")
-- end
--@api-stub: LTweenState:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LTweenState:type
--   local tween_state_obj = lurek.tween.newState(0.5)
--   local t = tween_state_obj:type()
--   lurek.log.info("LTweenState:type = " .. t, "tween")
-- end
--@api-stub: LTweenState:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LTweenState:typeOf
--   local tween_state_obj = lurek.tween.newState(0.5)
--   lurek.log.info("is LTweenState: " .. tostring(tween_state_obj:typeOf("LTweenState")), "tween")
--   lurek.log.info("is wrong: " .. tostring(tween_state_obj:typeOf("Unknown")), "tween")
-- end
