-- content/examples/tween.lua
-- lurek.tween API examples: property tweening, sequences, parallels, springs, and easing.
-- Run: cargo run -- content/examples/tween.lua

--@api-stub: LSpring:update
-- Advances all active tweens, sequences, parallels, and springs by the given delta time
do
  -- Call once per frame inside lurek.process to drive all tween animations.
  -- Without this call, no tween will advance regardless of how many you create.
  function lurek.process(dt)
    lurek.tween.update(dt)
  end
end

--@api-stub: LTweenParallel:tween
-- Creates and starts a property tween that smoothly interpolates numeric fields on the target table over the given duration
do
  -- Fade in a HUD overlay and slide it down from above.
  -- The tween modifies the table fields in-place each frame.
  local hud = { alpha = 0, y = -32 }
  lurek.tween.tween(0.4, hud, { alpha = 1, y = 0 }, "outQuad")
  -- Parameters: duration (seconds), target table, end values, easing name.
  -- The easing parameter is optional — defaults to "linear" if omitted.
  -- After 0.4 seconds, hud.alpha = 1 and hud.y = 0.
end

--@api-stub: lurek.tween.sequence
-- Creates a new empty tween sequence
do
  -- A sequence runs steps one after another: open door, wait, close door.
  -- Chain :tween(), :delay(), and :callback() steps, then call :start().
  local door = { y = 0 }
  lurek.tween.sequence()
    :tween(0.5, door, { y = 64 }, "outQuad")   -- slide door up
    :delay(2.0)                                  -- hold open for 2 seconds
    :tween(0.5, door, { y = 0 }, "inQuad")      -- slide door closed
    :start()
  -- Sequences are ideal for cutscenes, multi-phase UI transitions,
  -- or any animation that must happen in strict order.
end

--@api-stub: lurek.tween.parallel
-- Creates a new empty parallel tween group
do
  -- A parallel group runs all its tweens at the same time.
  -- Useful for animating multiple properties that must stay in sync.
  local actor = { x = 0, alpha = 1 }
  lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 }, "inOutQuad")   -- slide right
    :tween(0.6, actor, { alpha = 0 }, "linear")     -- fade out simultaneously
    :start()
  -- The group completes when its longest tween finishes.
end

--@api-stub: LTweenSequence:delay
-- Creates a one-shot delay
do
  -- Schedule a callback to fire after a fixed wait time.
  -- Common for respawn timers, wave countdowns, or delayed sound effects.
  lurek.tween.delay(1.5, function()
    lurek.log.info("respawn now", "spawn")
  end)
  -- The callback parameter is optional — without it, the delay acts
  -- as a standalone timer you can :await() from a coroutine.
end

--@api-stub: lurek.tween.cancelAll
-- Immediately cancels all active tweens, sequences, parallels, and springs managed by the tween engine
do
  -- Use when transitioning between game states (e.g. menu → gameplay)
  -- to ensure stale animations from the old state stop immediately.
  lurek.tween.cancelAll()
  -- After this call, getActiveCount() returns 0.
end

--@api-stub: lurek.tween.getActiveCount
-- Returns the total number of currently active tweens, sequences, and parallels
do
  -- Monitor tween budget to detect animation leaks.
  -- If count keeps growing, you are likely creating tweens without finishing them.
  local n = lurek.tween.getActiveCount()
  if n > 100 then
    lurek.log.warn("tween budget exceeded: " .. n, "tween")
  end
end

--@api-stub: lurek.tween.registerEasing
-- Registers a custom easing function by name
do
  -- Define a custom "squared" ease that accelerates quadratically.
  -- The function receives t in [0,1] and must return the eased value.
  lurek.tween.registerEasing("squared", function(t)
    return t * t
  end)
  -- Now "squared" can be passed as the easing argument to any tween:
  -- lurek.tween.tween(1.0, obj, { x = 100 }, "squared")
end

--@api-stub: lurek.tween.getEasingNames
-- Returns an array of all available easing function names, including both built-in and custom-registered easings
do
  -- Useful for debug menus or easing-picker UI in editor tools.
  local names = lurek.tween.getEasingNames()
  for i = 1, #names do
    lurek.log.debug("easing[" .. i .. "]=" .. names[i], "tween")
  end
  -- Built-in names include: linear, inQuad, outQuad, inOutQuad,
  -- inCubic, outCubic, inOutCubic, inBack, outBack, outBounce, etc.
end

--@api-stub: lurek.tween.newState
-- Creates a standalone tween state for manual interpolation
do
  -- A TweenState gives you raw eased progress without modifying any table.
  -- Useful when you need eased values for custom rendering or logic.
  local s = lurek.tween.newState(0.5, "outCubic")
  -- Tick manually (normally done each frame):
  s:tick(1 / 60)
  -- Interpolate between any two values using the current eased progress:
  local x = s:lerp(0, 100)
  lurek.log.debug("hand-eased x=" .. x, "tween")
end

--@api-stub: lurek.tween.to
-- Creates and starts a property tween with a different parameter order: target first, then fields, duration, easing
do
  -- Alternative syntax: target comes first, making chaining with callbacks cleaner.
  -- lurek.tween.to(target, fields, duration, easing)
  -- vs. lurek.tween.tween(duration, target, fields, easing)
  local enemy = { hp = 100 }
  lurek.tween.to(enemy, { hp = 0 }, 0.8, "inQuad")
  -- Use whichever parameter order feels more natural for the call site.
end

--@api-stub: lurek.tween.spring
-- Creates a spring-physics animation that smoothly drives table fields toward target values with bounce and settle behavior
do
  -- Springs are ideal for camera follow, UI snapping, or any motion
  -- that should overshoot and settle naturally.
  local cam = { x = 0, y = 0 }
  lurek.tween.spring(cam, { x = 320, y = 180 }, {
    stiffness = 180,   -- higher = faster snap (default 100)
    damping   = 18,    -- higher = less bounce (default 10)
    precision = 0.01,  -- settle threshold (default 0.001)
  })
  -- The spring auto-updates via lurek.tween.update(dt).
  -- Unlike tweens, springs have no fixed duration — they settle organically.
end

--@api-stub: lurek.tween.tweenChain
-- Creates a sequence from a table of step descriptors
do
  -- Declarative alternative to :tween():delay():tween() chaining.
  -- Each step is a table with either tween fields or a "delay" key.
  local actor = { x = 0 }
  lurek.tween.tweenChain({
    { duration = 0.2, target = actor, fields = { x = 32 }, easing = "outQuad" },
    { delay = 0.1 },   -- pause between steps
    { duration = 0.2, target = actor, fields = { x = 64 }, easing = "outQuad" },
    { delay = 0.1, callback = function() lurek.log.debug("step done", "tween") end },
  })
  -- Useful when animation data comes from a config file or level script.
end

--@api-stub: lurek.tween.tweenColor
-- Creates and starts a color tween that smoothly interpolates r, g, b, and/or a fields on the target table
do
  -- Designed for color transitions: flash red on damage, fade to black, etc.
  -- Only present keys in the color table are tweened; others stay unchanged.
  local sprite_color = { r = 1, g = 1, b = 1, a = 1 }
  lurek.tween.tweenColor(0.4, sprite_color, { r = 1, g = 0.2, b = 0.2, a = 0.8 }, "linear")
  -- After 0.4s the sprite turns semi-transparent red (damage flash).
end


-- TweenState methods

--@api-stub: LTweenState:tick
-- Advances the tween state by the given delta time and returns the eased value
do
  -- Manually advance a standalone tween state each frame.
  -- Returns the eased interpolation value (0..1).
  local s = lurek.tween.newState(1.0, "inOutQuad")
  function lurek.process(dt)
    local eased = s:tick(dt)
    -- Use 'eased' to drive custom rendering like a shader uniform.
  end
end

--@api-stub: LTweenState:isComplete
-- Returns true if this tween state has finished its full duration
do
  -- Check completion to trigger the next phase of your logic.
  local s = lurek.tween.newState(0.5)
  s:tick(0.5)  -- advance to full duration
  if s:isComplete() then
    lurek.log.info("ease finished — switch to next state", "tween")
  end
end

--@api-stub: LTweenState:t
-- Returns the raw (un-eased) linear progress from 0.0 to 1.0
do
  -- The raw t value is useful for debug displays or custom math
  -- where you need the linear ratio independent of the easing curve.
  local s = lurek.tween.newState(0.5, "outBounce")
  s:tick(0.25)
  local raw = s:t()
  lurek.log.debug("raw linear t=" .. raw, "tween")
  -- raw will be 0.5 (half of 0.5s elapsed) regardless of easing.
end

--@api-stub: LTweenState:lerp
-- Linearly interpolates between two values using the current eased progress
do
  -- Map eased progress onto any numeric range.
  -- Call lerp multiple times with different ranges for multi-axis control.
  local s = lurek.tween.newState(0.5, "outQuad")
  s:tick(0.25)
  local x = s:lerp(0, 320)    -- horizontal position
  local y = s:lerp(180, 0)    -- vertical position (top to bottom)
  lurek.log.debug("ease x=" .. x .. " y=" .. y, "tween")
end

--@api-stub: LTweenState:reset
-- Resets this tween state to the beginning so it can be replayed
do
  -- Re-use the same TweenState for repeating animations
  -- without allocating a new object each cycle.
  local s = lurek.tween.newState(0.5, "outQuad")
  s:tick(0.5)   -- run to completion
  s:reset()     -- back to t=0, ready to play again
end


-- Tween methods

--@api-stub: LTween:pause
-- Pauses this tween so it stops advancing until resumed
do
  -- Pause a card-flip animation when the game is paused or a menu opens.
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 }, "outQuad")
  tw:pause()
  -- The tween freezes at its current progress until :resume() is called.
end

--@api-stub: LTween:resume
-- Resumes a paused tween so it continues advancing
do
  -- Resume after the pause menu closes.
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 }, "outQuad")
  tw:pause()
  -- ...later, when gameplay resumes:
  tw:resume()
end

--@api-stub: LSpring:isActive
-- Returns whether this tween is still running (not cancelled or completed)
do
  -- Check if an animation is still in-flight before starting a new one.
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 })
  if tw:isActive() then
    lurek.log.debug("card still moving — skip new animation", "ui")
  end
end

--@api-stub: LTweenSequence:getProgress
-- Returns the eased progress of this tween as a value from 0.0 to 1.0
do
  -- Use progress to drive a visual indicator (loading bar, progress ring).
  local bar = { fill = 0 }
  local tw = lurek.tween.tween(2.0, bar, { fill = 1 }, "linear")
  local p = tw:getProgress()
  lurek.log.debug("loading=" .. string.format("%.0f%%", p * 100), "ui")
end

--@api-stub: LTween:getElapsed
-- Returns the number of seconds elapsed since the tween started
do
  -- Useful for time-synced events like spawning particles mid-tween.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10 })
  lurek.tween.update(0.25)
  lurek.log.debug("elapsed=" .. tw:getElapsed() .. "s", "tween")
end

--@api-stub: LTween:getDuration
-- Returns the total duration of this tween in seconds
do
  -- Introspect duration for scheduling dependent events.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10 }, "outQuad")
  lurek.log.debug("duration=" .. tw:getDuration() .. "s", "tween")
end

--@api-stub: LTween:getRemaining
-- Returns the number of seconds remaining until this tween completes
do
  -- Display a countdown or decide whether to skip the rest.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10 })
  lurek.tween.update(0.25)
  lurek.log.debug("remaining=" .. tw:getRemaining() .. "s", "tween")
end

--@api-stub: LTween:getFields
-- Returns an array of field names being tweened on the target table
do
  -- Inspect which properties a tween is animating (useful for debugging).
  local obj = { x = 0, y = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10, y = 20 })
  local fields = tw:getFields()
  lurek.log.debug("tweening " .. #fields .. " fields", "tween")
end

--@api-stub: LTween:setRelative
-- Sets whether the tween end values are relative to the start values instead of absolute
do
  -- In relative mode, field values are offsets added to the starting value.
  -- obj.x starts at 10; end value 5 means final x = 10 + 5 = 15.
  local obj = { x = 10 }
  local tw = lurek.tween.tween(1.0, obj, { x = 5 }, "linear")
  tw:setRelative(true)
  -- Relative mode is handy for "move 5 pixels right" regardless of start.
end

--@api-stub: LTween:relative
-- Chainable version of setRelative — returns the tween for fluent API usage
do
  -- Same as setRelative but allows chaining in a single expression.
  local obj = { x = 10 }
  lurek.tween.tween(1.0, obj, { x = 5 }, "linear")
    :relative(true)
    :onComplete(function() lurek.log.debug("relative move done", "tween") end)
end

--@api-stub: LTweenSequence:await
-- Yields the current coroutine until this tween completes or is cancelled
do
  -- Must be called from inside a coroutine.
  -- Enables sequential async-style animation scripting.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(0.2, obj, { x = 1 }, "linear")
  local co = coroutine.create(function()
    tw:await()
    lurek.log.debug("await complete — obj.x is now 1", "tween")
  end)
  coroutine.resume(co)
end

--@api-stub: LTween:setRepeat
-- Sets how many times the tween repeats after the first play
do
  -- -1 means infinite repeat; 0 means play once (no repeat).
  -- Great for looping UI glow, pulsing icons, or idle animations.
  local glow = { alpha = 0.3 }
  local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 }, "inOutSine")
  tw:setRepeat(-1)  -- loop forever
end

--@api-stub: LTween:setYoyo
-- Enables or disables yoyo mode, which reverses the tween on each repeat
do
  -- Combine with setRepeat for a ping-pong effect (e.g. breathing glow).
  -- Without yoyo, the value snaps back to start on each repeat.
  local glow = { alpha = 0.3 }
  local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 }, "inOutSine")
  tw:setRepeat(-1)
  tw:setYoyo(true)
  -- alpha will smoothly oscillate between 0.3 and 1.0 forever.
end


-- TweenSequence methods

--@api-stub: LSpring:cancel
-- Cancels this sequence immediately and resumes any coroutines waiting on it
do
  -- Interrupt a door animation if the player backs away.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  seq:cancel()
  -- After cancel, seq:isActive() returns false.
end

--@api-stub: LSpring:isActive
-- Returns whether this sequence is still running
do
  -- Guard against starting overlapping sequences.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  if seq:isActive() then
    lurek.log.debug("door is still opening — wait", "scene")
  end
end

--@api-stub: LTweenSequence:getProgress
-- Returns the overall progress of this sequence from 0.0 to 1.0
do
  -- Use progress to drive a cutscene timeline scrubber or skip prompt.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  lurek.log.debug("seq progress=" .. seq:getProgress(), "scene")
end

--@api-stub: LTweenSequence:await
-- Yields the current coroutine until this sequence completes or is cancelled
do
  -- Write linear cutscene scripts using coroutines + await.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.2, door, { y = 64 }):start()
  local co = coroutine.create(function()
    seq:await()
    lurek.log.debug("sequence done — door fully open", "scene")
  end)
  coroutine.resume(co)
end


-- TweenParallel methods

--@api-stub: LSpring:cancel
-- Cancels all tweens in this parallel group immediately
do
  -- Stop a multi-property exit animation if the actor is destroyed.
  local actor = { x = 0, alpha = 1 }
  local par = lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 })
    :tween(0.6, actor, { alpha = 0 })
    :start()
  par:cancel()
end

--@api-stub: LSpring:isActive
-- Returns whether this parallel group is still running
do
  -- Check if the combined animation has finished before proceeding.
  local actor = { x = 0, alpha = 1 }
  local par = lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 })
    :tween(0.6, actor, { alpha = 0 })
    :start()
  if par:isActive() then
    lurek.log.debug("actor exit animation in progress", "scene")
  end
end


-- Spring methods

--@api-stub: LSpring:update
-- Manually advances this spring by the given delta time
do
  -- Springs are auto-updated by lurek.tween.update(dt), but you can
  -- also tick them manually for frame-independent physics tests.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:update(1 / 60)  -- returns true while still moving, false when settled
end

--@api-stub: LSpring:isSettled
-- Returns true when all spring axes have reached their targets within precision
do
  -- Use to detect when camera has stopped moving or a UI element has landed.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  if sp:isSettled() then
    lurek.log.debug("camera at rest", "camera")
  end
end

--@api-stub: LSpring:isActive
-- Returns whether this spring is still actively animating
do
  -- Differs from isSettled: a cancelled spring is inactive but may not be settled.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  if sp:isActive() then
    lurek.log.debug("camera following player", "camera")
  end
end

--@api-stub: LSpring:setTarget
-- Changes the spring target values, re-activating the spring if it was settled
do
  -- Redirect the spring to a new destination (e.g. camera follows new target).
  local cam = { x = 0, y = 0 }
  local sp = lurek.tween.spring(cam, { x = 320, y = 180 })
  -- Player moves — update camera target:
  sp:setTarget({ x = 480, y = 240 })
  -- The spring smoothly redirects without snapping.
end

--@api-stub: LSpring:setStiffness
-- Sets the spring stiffness for all axes
do
  -- Increase stiffness when the player is sprinting so camera keeps up.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:setStiffness(240)  -- snappier response (default is 100)
end

--@api-stub: LSpring:setDamping
-- Sets the spring damping for all axes
do
  -- Higher damping = less oscillation. Use for a heavy, sluggish feel.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:setDamping(24)  -- reduces bounce (default is 10)
end

--@api-stub: LSpring:cancel
-- Cancels this spring animation
do
  -- Stop following the player when a cutscene starts.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:cancel()
  -- cam.x freezes at whatever value it reached.
end

--@api-stub: LSpring:getPosition
-- Returns the current position of the given spring axis, or nil if the axis does not exist
do
  -- Read a single axis value without accessing the target table directly.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  local px = sp:getPosition("x")
  if px then
    lurek.log.debug("spring x=" .. px, "camera")
  end
end

--@api-stub: LSpring:type
-- Returns the type name string for this spring handle
do
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  lurek.log.debug("spring type: " .. sp:type(), "tween")  -- "LSpring"
end

--@api-stub: LSpring:typeOf
-- Checks whether this spring handle matches the given type name
do
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  lurek.log.info("is Spring: " .. tostring(sp:typeOf("LSpring")), "tween")
end

-- -----------------------------------------------------------------------------
-- Tween methods (continued)
-- -----------------------------------------------------------------------------

--@api-stub: LTweenParallel:onComplete
-- Sets a callback to fire when the tween completes; returns the tween for chaining
do
  -- Chain onComplete for fire-and-forget animations with cleanup.
  local box = { x = 0 }
  lurek.tween.tween(0.5, box, { x = 100 }, "outQuad"):onComplete(function()
    lurek.log.debug("box arrived at x=100", "tween")
  end)
end

--@api-stub: LTween:onUpdate
-- Sets a callback fired every frame with the current progress t (0..1)
do
  -- Use onUpdate to sync effects or debug-print progress each frame.
  local box = { x = 0 }
  lurek.tween.tween(0.5, box, { x = 100 }):onUpdate(function(t)
    -- t is the eased progress; use it to drive particles or sound pitch.
    lurek.log.debug("progress t=" .. string.format("%.2f", t), "tween")
  end)
end

--@api-stub: LTween:onCancel
-- Sets a callback fired when the tween is cancelled
do
  -- Clean up side effects if the tween is interrupted.
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  tw:onCancel(function()
    lurek.log.debug("tween was cancelled — reverting state", "tween")
  end)
  tw:cancel()  -- triggers the onCancel callback
end

--@api-stub: LSpring:type
-- Returns the type name string for this tween handle
do
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  lurek.log.info("Tween:type = " .. tw:type(), "tween")  -- "LTween"
end

--@api-stub: LSpring:typeOf
-- Checks whether this tween handle matches the given type name
do
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  lurek.log.info("is Tween: " .. tostring(tw:typeOf("LTween")), "tween")  -- true
end

-- -----------------------------------------------------------------------------
-- TweenParallel methods (continued)
-- -----------------------------------------------------------------------------

--@api-stub: LTweenParallel:add
-- Adds an existing tween handle to this parallel group
do
  -- Use :add() when you already have a tween handle from elsewhere.
  -- The tween becomes owned by the group and starts with it.
  local a = { x = 0 }
  local b = { y = 0 }
  local tw1 = lurek.tween.tween(0.4, a, { x = 80 })
  local par = lurek.tween.parallel()
  par:add(tw1)                       -- add pre-existing tween
  par:tween(0.4, b, { y = 80 })     -- add inline tween
  par:start()
end

--@api-stub: LTweenParallel:onComplete
-- Sets a callback fired when all tweens in the group finish; returns the group for chaining
do
  -- Know exactly when a complex multi-property animation is done.
  local actor = { x = 0, alpha = 1 }
  lurek.tween.parallel()
    :tween(0.6, actor, { x = 200 }, "outQuad")
    :tween(0.6, actor, { alpha = 0 }, "linear")
    :onComplete(function()
      lurek.log.debug("actor fully exited — safe to despawn", "tween")
    end)
    :start()
end

--@api-stub: LSpring:type
-- Returns the type name string for this parallel handle
do
  local par = lurek.tween.parallel()
  lurek.log.info("TweenParallel:type = " .. par:type(), "tween")  -- "LTweenParallel"
end

--@api-stub: LSpring:typeOf
-- Checks whether this parallel handle matches the given type name
do
  local par = lurek.tween.parallel()
  lurek.log.info("is Parallel: " .. tostring(par:typeOf("LTweenParallel")), "tween")
end

-- -----------------------------------------------------------------------------
-- TweenSequence methods (continued)
-- -----------------------------------------------------------------------------

--@api-stub: LTweenSequence:callback
-- Appends a callback step to the sequence that fires when reached during playback
do
  -- Insert logic between animation steps (e.g. play a sound mid-sequence).
  local door = { y = 0 }
  lurek.tween.sequence()
    :tween(0.3, door, { y = 64 }, "outQuad")
    :callback(function() lurek.log.debug("door open — play creak sound", "scene") end)
    :delay(1.0)
    :tween(0.3, door, { y = 0 }, "inQuad")
    :start()
end

--@api-stub: LTweenParallel:onComplete
-- Sets a callback fired when the sequence finishes all steps; returns the sequence for chaining
do
  -- Trigger game logic after the full sequence completes.
  local door = { y = 0 }
  lurek.tween.sequence()
    :tween(0.4, door, { y = 64 })
    :onComplete(function()
      lurek.log.debug("sequence done — enable player input", "scene")
    end)
    :start()
end

--@api-stub: LSpring:type
-- Returns the type name string for this sequence handle
do
  local seq = lurek.tween.sequence()
  lurek.log.info("TweenSequence:type = " .. seq:type(), "tween")  -- "LTweenSequence"
end

--@api-stub: LSpring:typeOf
-- Checks whether this sequence handle matches the given type name
do
  local seq = lurek.tween.sequence()
  lurek.log.info("is Sequence: " .. tostring(seq:typeOf("LTweenSequence")), "tween")
end

-- -----------------------------------------------------------------------------
-- LTween methods (duplicate stubs for LuaLS coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LSpring:cancel
-- Cancels this tween immediately, fires the onCancel callback if set, and resumes any coroutines waiting on it
do
  -- Cancel interrupts the tween mid-flight; target fields freeze at current values.
  local target = { x = 0 }
  local tw = lurek.tween.tween(1.0, target, { x = 100 })
  tw:cancel()
  lurek.log.info("tween cancelled, target.x=" .. tostring(target.x), "tween")
end

--@api-stub: LTweenParallel:tween
-- Creates and adds a new tween step directly to this parallel group
do
  -- Inline syntax for building parallel groups without separate handles.
  local obj = { x = 0, alpha = 1.0 }
  lurek.tween.parallel()
    :tween(0.5, obj, { x = 200 }, "outQuad")
    :tween(0.5, obj, { alpha = 0.0 }, "linear")
    :start()
end

--@api-stub: LTweenParallel:start
-- Starts all tweens in this parallel group simultaneously
do
  -- Call :start() after building the group to activate it.
  local pos = { x = 0 }
  local col = { a = 1.0 }
  lurek.tween.parallel()
    :tween(0.4, pos, { x = 100 }, "outQuad")
    :tween(0.4, col, { a = 0 }, "linear")
    :start()
end

--@api-stub: LTweenParallel:tween
-- Appends a tween step to this sequence
do
  -- Each :tween() step runs after the previous one finishes.
  local pos = { x = 0, y = 0 }
  lurek.tween.sequence()
    :tween(0.3, pos, { x = 100 }, "outQuad")   -- step 1: move right
    :tween(0.3, pos, { y = 80 }, "outQuad")    -- step 2: move down
    :start()
end

--@api-stub: LTweenSequence:delay
-- Appends a delay step to this sequence
do
  -- Insert a pause between animation steps.
  local obj = { x = 0 }
  lurek.tween.sequence()
    :tween(0.2, obj, { x = 100 }, "outQuad")
    :delay(0.5)                                 -- wait half a second
    :tween(0.2, obj, { x = 0 }, "outQuad")     -- return to start
    :start()
end

--@api-stub: LTweenParallel:start
-- Starts playback of this sequence from the first step
do
  -- Build the sequence first, then :start() activates it.
  local door = { y = 0 }
  local seq = lurek.tween.sequence()
    :tween(0.4, door, { y = 64 }, "outQuad")
    :delay(1.0)
    :tween(0.4, door, { y = 0 }, "inQuad")
  seq:start()
end

--@api-stub: LSpring:type
-- Returns the type name of this object
do
  local tween_state_obj = lurek.tween.newState(0.5)
  lurek.log.info("LTweenState:type = " .. tween_state_obj:type(), "tween")
end

--@api-stub: LSpring:typeOf
-- Checks whether this object matches the given type name
do
  local tween_state_obj = lurek.tween.newState(0.5)
  lurek.log.info("is LTweenState: " .. tostring(tween_state_obj:typeOf("LTweenState")), "tween")
  lurek.log.info("is Object: " .. tostring(tween_state_obj:typeOf("Object")), "tween")
end

print("content/examples/tween.lua")

-- =============================================================================
-- Additional LTween / LTweenParallel / LTweenSequence coverage
-- =============================================================================

--@api-stub: LTween:isActive
-- Returns whether this tween is still running (not cancelled or completed).
do
  -- Guard against starting a new animation while one is in-flight.
  local hp_bar = { width = 100 }
  local tw = lurek.tween.tween(0.3, hp_bar, { width = 60 }, "outQuad")
  if tw:isActive() then
    lurek.log.debug("hp bar animating — skip new tween", "ui")
  end
end

--@api-stub: LTween:getProgress
-- Returns the eased progress of this tween as a value from 0.0 to 1.0.
do
  -- Use progress to drive a fill indicator alongside the tween.
  local meter = { fill = 0 }
  local tw = lurek.tween.tween(1.0, meter, { fill = 1 }, "linear")
  lurek.tween.update(0.5)
  lurek.log.debug("meter progress=" .. string.format("%.2f", tw:getProgress()), "ui")
end

--@api-stub: LTween:await
-- Yields the current coroutine until this tween completes or is cancelled. Must be called from inside a coroutine.
do
  -- Write sequential animation scripts using coroutines.
  local badge = { scale = 0 }
  local tw = lurek.tween.tween(0.3, badge, { scale = 1 }, "outBack")
  local co = coroutine.create(function()
    tw:await()
    lurek.log.debug("badge pop-in done", "ui")
  end)
  coroutine.resume(co)
end

--@api-stub: LTween:onComplete
-- Sets a callback to fire when the tween completes. Returns the tween for chaining.
do
  -- Chain a sound effect after a slide animation finishes.
  local panel = { x = -200 }
  lurek.tween.tween(0.4, panel, { x = 0 }, "outQuad"):onComplete(function()
    lurek.log.info("panel arrived — play whoosh", "ui")
  end)
end

--@api-stub: LTween:type
-- Returns the type name of this object.
do
  local obj = { x = 0 }
  local tw = lurek.tween.tween(0.5, obj, { x = 10 })
  lurek.log.info("LTween:type = " .. tw:type(), "tween")
end

--@api-stub: LTween:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = { x = 0 }
  local tw = lurek.tween.tween(0.5, obj, { x = 10 })
  lurek.log.info("is LTween: " .. tostring(tw:typeOf("LTween")), "tween")
end

--@api-stub: LTweenParallel:cancel
-- Cancels all tweens in this parallel group immediately.
do
  -- Abort a multi-property exit animation if the actor respawns.
  local actor = { x = 0, alpha = 1 }
  local par = lurek.tween.parallel()
    :tween(0.6, actor, { x = 300 }, "outQuad")
    :tween(0.6, actor, { alpha = 0 }, "linear")
    :start()
  par:cancel()
  lurek.log.debug("parallel cancelled, active=" .. tostring(par:isActive()), "tween")
end

--@api-stub: LTweenParallel:isActive
-- Returns whether this parallel group is still running.
do
  -- Wait for all simultaneous tweens to finish before spawning loot.
  local actor = { x = 0, alpha = 1 }
  local par = lurek.tween.parallel()
    :tween(0.4, actor, { x = 100 })
    :tween(0.4, actor, { alpha = 0 })
    :start()
  if par:isActive() then
    lurek.log.debug("death anim in progress — defer loot spawn", "tween")
  end
end

--@api-stub: LTweenParallel:type
-- Returns the type name of this object.
do
  local par = lurek.tween.parallel()
  lurek.log.info("LTweenParallel:type = " .. par:type(), "tween")
end

--@api-stub: LTweenParallel:typeOf
-- Checks whether this object matches the given type name.
do
  local par = lurek.tween.parallel()
  lurek.log.info("is LTweenParallel: " .. tostring(par:typeOf("LTweenParallel")), "tween")
end

--@api-stub: LTweenSequence:cancel
-- Cancels this sequence immediately and resumes any coroutines waiting on it.
do
  -- Interrupt a cutscene sequence when the player presses skip.
  local cam = { x = 0 }
  local seq = lurek.tween.sequence()
    :tween(1.0, cam, { x = 200 }, "inOutQuad")
    :delay(0.5)
    :start()
  seq:cancel()
  lurek.log.debug("cutscene skipped, active=" .. tostring(seq:isActive()), "scene")
end

--@api-stub: LTweenSequence:isActive
-- Returns whether this sequence is still running.
do
  -- Prevent overlapping door sequences.
  local door = { y = 0 }
  local seq = lurek.tween.sequence()
    :tween(0.4, door, { y = 64 }, "outQuad")
    :start()
  if seq:isActive() then
    lurek.log.debug("door already opening", "scene")
  end
end

--@api-stub: LTweenSequence:onComplete
-- Sets a callback to fire when the sequence finishes all steps. Returns the sequence for chaining.
do
  -- Enable player input after the intro sequence finishes.
  local title = { alpha = 0 }
  lurek.tween.sequence()
    :tween(0.6, title, { alpha = 1 }, "outQuad")
    :delay(1.0)
    :onComplete(function()
      lurek.log.info("intro done — enable input", "scene")
    end)
    :start()
end

--@api-stub: LTweenSequence:type
-- Returns the type name of this object.
do
  local seq = lurek.tween.sequence()
  lurek.log.info("LTweenSequence:type = " .. seq:type(), "tween")
end

--@api-stub: LTweenSequence:typeOf
-- Checks whether this object matches the given type name.
do
  local seq = lurek.tween.sequence()
  lurek.log.info("is LTweenSequence: " .. tostring(seq:typeOf("LTweenSequence")), "tween")
end

-- =============================================================================
-- STUBS: 7 uncovered lurek.tween API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.tween.update --------------------------------------------
--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, parallels, and springs by the given delta time. Call once per frame.
do
  local obj = {x = 0}
  lurek.tween.tween(1.0, obj, {x = 100})
  -- Manually advance the tween by 0.5 s (simulating a frame tick).
  lurek.tween.update(0.5)
  lurek.log.debug("x after half-step: " .. string.format("%.1f", obj.x), "tween") -- ~50
end

-- ---- Stub: lurek.tween.delay ---------------------------------------------
--@api-stub: lurek.tween.delay
-- Creates a one-shot delay. After the specified seconds elapse, the optional callback is invoked.
do
  -- Create a tween that waits N seconds before proceeding in a sequence.
  local pause = lurek.tween.delay(1.5)
  lurek.log.debug("delay tween: " .. pause:type(), "tween")
end

-- -----------------------------------------------------------------------------
-- LTween methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTween:cancel -------------------------------------------------
--@api-stub: LTween:cancel
-- Cancels this tween immediately, fires the onCancel callback if set, and resumes any coroutines waiting on it.
do
  local obj = {x = 0}
  local tw = lurek.tween.to(obj, {x = 100}, 2.0)
  -- Cancel the tween before it completes.
  tw:cancel()
  lurek.log.debug("tween cancelled; obj.x frozen at: " .. obj.x, "tween")
end

-- -----------------------------------------------------------------------------
-- LTweenSequence methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTweenSequence:tween ------------------------------------------
--@api-stub: LTweenSequence:tween
-- Appends a tween step to this sequence that animates numeric fields on the target table.
do
  local obj = {alpha = 1}
  local seq = lurek.tween.sequence()
  -- Chain two tweens: fade out then fade in.
  seq:tween(0.3, obj, {alpha = 0})
  seq:tween(0.3, obj, {alpha = 1})
  lurek.log.debug("sequence has 2 tweens", "tween")
end

-- ---- Stub: LTweenSequence:start ------------------------------------------
--@api-stub: LTweenSequence:start
-- Starts playback of this sequence from the first step.
do
  local obj = {x = 0, y = 0}
  local seq = lurek.tween.sequence()
  seq:tween(0.5, obj, {x = 100})
  seq:tween(0.5, obj, {y = 100})
  seq:start()
  lurek.log.debug("sequence started", "tween")
end

-- -----------------------------------------------------------------------------
-- LTweenState methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTweenState:type ----------------------------------------------
--@api-stub: LTweenState:type
-- Returns the type name of this object.
do
  local obj = lurek.tween.newState(1.0)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LTweenState"
end

-- ---- Stub: LTweenState:typeOf --------------------------------------------
--@api-stub: LTweenState:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.tween.newState(1.0)
  lurek.log.debug("typeOf LTweenState: " .. tostring(obj:typeOf("LTweenState")), "example") -- true
end

-- ---- Stub: lurek.tween.tween --------------------------------------------
--@api-stub: lurek.tween.tween
-- Creates and starts a tween that interpolates a value over time.
do
  local state = { x = 0 }
  lurek.tween.tween(1.0, state, { x = 100 }, "linear")
  lurek.log.debug("tween started", "example")
end
