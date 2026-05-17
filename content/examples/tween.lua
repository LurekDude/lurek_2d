-- content/examples/tween.lua
-- lurek.tween API examples: property tweening, sequences, parallels, springs, and easing.
-- Run: cargo run -- content/examples/tween.lua

--@api-stub: lurek.tween.update
-- Advances all active tweens, sequences, parallels, and springs by the given delta time
do
  -- Call once per frame inside lurek.process to drive all tween animations.
  -- Without this call, no tween will advance regardless of how many you create.
  function lurek.process(dt)
    lurek.tween.update(dt)
  end
end

--@api-stub: lurek.tween.tween
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

--@api-stub: lurek.tween.delay
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

--@api-stub: TweenState:tick
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

--@api-stub: TweenState:isComplete
-- Returns true if this tween state has finished its full duration
do
  -- Check completion to trigger the next phase of your logic.
  local s = lurek.tween.newState(0.5)
  s:tick(0.5)  -- advance to full duration
  if s:isComplete() then
    lurek.log.info("ease finished — switch to next state", "tween")
  end
end

--@api-stub: TweenState:t
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

--@api-stub: TweenState:lerp
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

--@api-stub: TweenState:reset
-- Resets this tween state to the beginning so it can be replayed
do
  -- Re-use the same TweenState for repeating animations
  -- without allocating a new object each cycle.
  local s = lurek.tween.newState(0.5, "outQuad")
  s:tick(0.5)   -- run to completion
  s:reset()     -- back to t=0, ready to play again
end


-- Tween methods

--@api-stub: Tween:pause
-- Pauses this tween so it stops advancing until resumed
do
  -- Pause a card-flip animation when the game is paused or a menu opens.
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 }, "outQuad")
  tw:pause()
  -- The tween freezes at its current progress until :resume() is called.
end

--@api-stub: Tween:resume
-- Resumes a paused tween so it continues advancing
do
  -- Resume after the pause menu closes.
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 }, "outQuad")
  tw:pause()
  -- ...later, when gameplay resumes:
  tw:resume()
end

--@api-stub: Tween:isActive
-- Returns whether this tween is still running (not cancelled or completed)
do
  -- Check if an animation is still in-flight before starting a new one.
  local card = { y = 0 }
  local tw = lurek.tween.tween(0.6, card, { y = 200 })
  if tw:isActive() then
    lurek.log.debug("card still moving — skip new animation", "ui")
  end
end

--@api-stub: Tween:getProgress
-- Returns the eased progress of this tween as a value from 0.0 to 1.0
do
  -- Use progress to drive a visual indicator (loading bar, progress ring).
  local bar = { fill = 0 }
  local tw = lurek.tween.tween(2.0, bar, { fill = 1 }, "linear")
  local p = tw:getProgress()
  lurek.log.debug("loading=" .. string.format("%.0f%%", p * 100), "ui")
end

--@api-stub: Tween:getElapsed
-- Returns the number of seconds elapsed since the tween started
do
  -- Useful for time-synced events like spawning particles mid-tween.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10 })
  lurek.tween.update(0.25)
  lurek.log.debug("elapsed=" .. tw:getElapsed() .. "s", "tween")
end

--@api-stub: Tween:getDuration
-- Returns the total duration of this tween in seconds
do
  -- Introspect duration for scheduling dependent events.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10 }, "outQuad")
  lurek.log.debug("duration=" .. tw:getDuration() .. "s", "tween")
end

--@api-stub: Tween:getRemaining
-- Returns the number of seconds remaining until this tween completes
do
  -- Display a countdown or decide whether to skip the rest.
  local obj = { x = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10 })
  lurek.tween.update(0.25)
  lurek.log.debug("remaining=" .. tw:getRemaining() .. "s", "tween")
end

--@api-stub: Tween:getFields
-- Returns an array of field names being tweened on the target table
do
  -- Inspect which properties a tween is animating (useful for debugging).
  local obj = { x = 0, y = 0 }
  local tw = lurek.tween.tween(1.0, obj, { x = 10, y = 20 })
  local fields = tw:getFields()
  lurek.log.debug("tweening " .. #fields .. " fields", "tween")
end

--@api-stub: Tween:setRelative
-- Sets whether the tween end values are relative to the start values instead of absolute
do
  -- In relative mode, field values are offsets added to the starting value.
  -- obj.x starts at 10; end value 5 means final x = 10 + 5 = 15.
  local obj = { x = 10 }
  local tw = lurek.tween.tween(1.0, obj, { x = 5 }, "linear")
  tw:setRelative(true)
  -- Relative mode is handy for "move 5 pixels right" regardless of start.
end

--@api-stub: Tween:relative
-- Chainable version of setRelative — returns the tween for fluent API usage
do
  -- Same as setRelative but allows chaining in a single expression.
  local obj = { x = 10 }
  lurek.tween.tween(1.0, obj, { x = 5 }, "linear")
    :relative(true)
    :onComplete(function() lurek.log.debug("relative move done", "tween") end)
end

--@api-stub: Tween:await
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

--@api-stub: Tween:setRepeat
-- Sets how many times the tween repeats after the first play
do
  -- -1 means infinite repeat; 0 means play once (no repeat).
  -- Great for looping UI glow, pulsing icons, or idle animations.
  local glow = { alpha = 0.3 }
  local tw = lurek.tween.tween(0.8, glow, { alpha = 1.0 }, "inOutSine")
  tw:setRepeat(-1)  -- loop forever
end

--@api-stub: Tween:setYoyo
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

--@api-stub: TweenSequence:cancel
-- Cancels this sequence immediately and resumes any coroutines waiting on it
do
  -- Interrupt a door animation if the player backs away.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  seq:cancel()
  -- After cancel, seq:isActive() returns false.
end

--@api-stub: TweenSequence:isActive
-- Returns whether this sequence is still running
do
  -- Guard against starting overlapping sequences.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  if seq:isActive() then
    lurek.log.debug("door is still opening — wait", "scene")
  end
end

--@api-stub: TweenSequence:getProgress
-- Returns the overall progress of this sequence from 0.0 to 1.0
do
  -- Use progress to drive a cutscene timeline scrubber or skip prompt.
  local door = { y = 0 }
  local seq = lurek.tween.sequence():tween(0.4, door, { y = 64 }):start()
  lurek.log.debug("seq progress=" .. seq:getProgress(), "scene")
end

--@api-stub: TweenSequence:await
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

--@api-stub: TweenParallel:cancel
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

--@api-stub: TweenParallel:isActive
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

--@api-stub: Spring:update
-- Manually advances this spring by the given delta time
do
  -- Springs are auto-updated by lurek.tween.update(dt), but you can
  -- also tick them manually for frame-independent physics tests.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:update(1 / 60)  -- returns true while still moving, false when settled
end

--@api-stub: Spring:isSettled
-- Returns true when all spring axes have reached their targets within precision
do
  -- Use to detect when camera has stopped moving or a UI element has landed.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  if sp:isSettled() then
    lurek.log.debug("camera at rest", "camera")
  end
end

--@api-stub: Spring:isActive
-- Returns whether this spring is still actively animating
do
  -- Differs from isSettled: a cancelled spring is inactive but may not be settled.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  if sp:isActive() then
    lurek.log.debug("camera following player", "camera")
  end
end

--@api-stub: Spring:setTarget
-- Changes the spring target values, re-activating the spring if it was settled
do
  -- Redirect the spring to a new destination (e.g. camera follows new target).
  local cam = { x = 0, y = 0 }
  local sp = lurek.tween.spring(cam, { x = 320, y = 180 })
  -- Player moves — update camera target:
  sp:setTarget({ x = 480, y = 240 })
  -- The spring smoothly redirects without snapping.
end

--@api-stub: Spring:setStiffness
-- Sets the spring stiffness for all axes
do
  -- Increase stiffness when the player is sprinting so camera keeps up.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:setStiffness(240)  -- snappier response (default is 100)
end

--@api-stub: Spring:setDamping
-- Sets the spring damping for all axes
do
  -- Higher damping = less oscillation. Use for a heavy, sluggish feel.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:setDamping(24)  -- reduces bounce (default is 10)
end

--@api-stub: Spring:cancel
-- Cancels this spring animation
do
  -- Stop following the player when a cutscene starts.
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  sp:cancel()
  -- cam.x freezes at whatever value it reached.
end

--@api-stub: Spring:getPosition
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

--@api-stub: Spring:type
-- Returns the type name string for this spring handle
do
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  lurek.log.debug("spring type: " .. sp:type(), "tween")  -- "LSpring"
end

--@api-stub: Spring:typeOf
-- Checks whether this spring handle matches the given type name
do
  local cam = { x = 0 }
  local sp = lurek.tween.spring(cam, { x = 320 })
  lurek.log.info("is Spring: " .. tostring(sp:typeOf("LSpring")), "tween")
end

-- -----------------------------------------------------------------------------
-- Tween methods (continued)
-- -----------------------------------------------------------------------------

--@api-stub: Tween:onComplete
-- Sets a callback to fire when the tween completes; returns the tween for chaining
do
  -- Chain onComplete for fire-and-forget animations with cleanup.
  local box = { x = 0 }
  lurek.tween.tween(0.5, box, { x = 100 }, "outQuad"):onComplete(function()
    lurek.log.debug("box arrived at x=100", "tween")
  end)
end

--@api-stub: Tween:onUpdate
-- Sets a callback fired every frame with the current progress t (0..1)
do
  -- Use onUpdate to sync effects or debug-print progress each frame.
  local box = { x = 0 }
  lurek.tween.tween(0.5, box, { x = 100 }):onUpdate(function(t)
    -- t is the eased progress; use it to drive particles or sound pitch.
    lurek.log.debug("progress t=" .. string.format("%.2f", t), "tween")
  end)
end

--@api-stub: Tween:onCancel
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

--@api-stub: Tween:type
-- Returns the type name string for this tween handle
do
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  lurek.log.info("Tween:type = " .. tw:type(), "tween")  -- "LTween"
end

--@api-stub: Tween:typeOf
-- Checks whether this tween handle matches the given type name
do
  local box = { x = 0 }
  local tw = lurek.tween.tween(0.5, box, { x = 100 })
  lurek.log.info("is Tween: " .. tostring(tw:typeOf("LTween")), "tween")  -- true
end

-- -----------------------------------------------------------------------------
-- TweenParallel methods (continued)
-- -----------------------------------------------------------------------------

--@api-stub: TweenParallel:add
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

--@api-stub: TweenParallel:onComplete
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

--@api-stub: TweenParallel:type
-- Returns the type name string for this parallel handle
do
  local par = lurek.tween.parallel()
  lurek.log.info("TweenParallel:type = " .. par:type(), "tween")  -- "LTweenParallel"
end

--@api-stub: TweenParallel:typeOf
-- Checks whether this parallel handle matches the given type name
do
  local par = lurek.tween.parallel()
  lurek.log.info("is Parallel: " .. tostring(par:typeOf("LTweenParallel")), "tween")
end

-- -----------------------------------------------------------------------------
-- TweenSequence methods (continued)
-- -----------------------------------------------------------------------------

--@api-stub: TweenSequence:callback
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

--@api-stub: TweenSequence:onComplete
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

--@api-stub: TweenSequence:type
-- Returns the type name string for this sequence handle
do
  local seq = lurek.tween.sequence()
  lurek.log.info("TweenSequence:type = " .. seq:type(), "tween")  -- "LTweenSequence"
end

--@api-stub: TweenSequence:typeOf
-- Checks whether this sequence handle matches the given type name
do
  local seq = lurek.tween.sequence()
  lurek.log.info("is Sequence: " .. tostring(seq:typeOf("LTweenSequence")), "tween")
end

-- -----------------------------------------------------------------------------
-- LTween methods (duplicate stubs for LuaLS coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LTween:cancel
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

--@api-stub: LTweenSequence:tween
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

--@api-stub: LTweenSequence:start
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

--@api-stub: LTweenState:type
-- Returns the type name of this object
do
  local tween_state_obj = lurek.tween.newState(0.5)
  lurek.log.info("LTweenState:type = " .. tween_state_obj:type(), "tween")
end

--@api-stub: LTweenState:typeOf
-- Checks whether this object matches the given type name
do
  local tween_state_obj = lurek.tween.newState(0.5)
  lurek.log.info("is LTweenState: " .. tostring(tween_state_obj:typeOf("LTweenState")), "tween")
  lurek.log.info("is Object: " .. tostring(tween_state_obj:typeOf("Object")), "tween")
end

print("content/examples/tween.lua")

-- =============================================================================
-- STUBS: 46 uncovered lurek.tween API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LSpring methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSpring:update ------------------------------------------------
--@api-stub: LSpring:update
-- Manually advances this spring by the given delta time and writes updated positions to the target table. Returns `true` if still animating, `false` if settled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:update(0.016)  -- -> boolean
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:isSettled ---------------------------------------------
--@api-stub: LSpring:isSettled
-- Returns whether all spring axes have reached their targets within the precision threshold.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:isSettled()  -- -> boolean
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:isActive ----------------------------------------------
--@api-stub: LSpring:isActive
-- Returns whether this spring is still actively animating.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:isActive()  -- -> boolean
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:setTarget ---------------------------------------------
--@api-stub: LSpring:setTarget
-- Changes the spring target values for one or more axes. Re-activates the spring if it was settled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:setTarget(fields_tbl)
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:setStiffness ------------------------------------------
--@api-stub: LSpring:setStiffness
-- Sets the spring stiffness for all axes. Higher values make the spring snap faster.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:setStiffness(42)
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:setDamping --------------------------------------------
--@api-stub: LSpring:setDamping
-- Sets the spring damping for all axes. Higher values reduce oscillation and overshoot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:setDamping(42)
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:cancel ------------------------------------------------
--@api-stub: LSpring:cancel
-- Cancels this spring animation and cleans up the on-settle callback if one was registered.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:cancel()
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:getPosition -------------------------------------------
--@api-stub: LSpring:getPosition
-- Returns the current position of the given spring axis, or `nil` if the axis does not exist.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:getPosition(field)  -- -> LuaValue
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:type --------------------------------------------------
--@api-stub: LSpring:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:type()  -- -> string
-- (replace lSpring_stub with your real LSpring instance above)

-- ---- Stub: LSpring:typeOf ------------------------------------------------
--@api-stub: LSpring:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpring_stub:typeOf("hero")  -- -> boolean
-- (replace lSpring_stub with your real LSpring instance above)

-- -----------------------------------------------------------------------------
-- LTween methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTween:pause --------------------------------------------------
--@api-stub: LTween:pause
-- Pauses this tween so it stops advancing until resumed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:pause()
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:resume -------------------------------------------------
--@api-stub: LTween:resume
-- Resumes a paused tween so it continues advancing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:resume()
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:isActive -----------------------------------------------
--@api-stub: LTween:isActive
-- Returns whether this tween is still running (not cancelled or completed).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:isActive()  -- -> boolean
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:getProgress --------------------------------------------
--@api-stub: LTween:getProgress
-- Returns the eased progress of this tween as a value from 0.0 to 1.0.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:getProgress()  -- -> number
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:getElapsed ---------------------------------------------
--@api-stub: LTween:getElapsed
-- Returns the number of seconds that have elapsed since the tween started.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:getElapsed()  -- -> number
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:getDuration --------------------------------------------
--@api-stub: LTween:getDuration
-- Returns the total duration of this tween in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:getDuration()  -- -> number
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:getRemaining -------------------------------------------
--@api-stub: LTween:getRemaining
-- Returns the number of seconds remaining until this tween completes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:getRemaining()  -- -> number
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:getFields ----------------------------------------------
--@api-stub: LTween:getFields
-- Returns an array of field names being tweened on the target table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:getFields()  -- -> table
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:setRelative --------------------------------------------
--@api-stub: LTween:setRelative
-- Sets whether the tween end values are relative to the start values instead of absolute.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:setRelative(true)
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:relative -----------------------------------------------
--@api-stub: LTween:relative
-- Chainable version of `setRelative`. Returns the tween for fluent API usage.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:relative(true)  -- -> LTween
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:await --------------------------------------------------
--@api-stub: LTween:await
-- Yields the current coroutine until this tween completes or is cancelled. Must be called from inside a coroutine.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:await()
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:setRepeat ----------------------------------------------
--@api-stub: LTween:setRepeat
-- Sets how many times the tween should repeat after the first play. Use -1 for infinite repeat.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:setRepeat(5)
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:setYoyo ------------------------------------------------
--@api-stub: LTween:setYoyo
-- Enables or disables yoyo mode, which reverses the tween direction on each repeat cycle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:setYoyo(true)
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:onComplete ---------------------------------------------
--@api-stub: LTween:onComplete
-- Sets a callback to fire when the tween completes. Returns the tween for chaining.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:onComplete(ud, f)  -- -> LTween
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:onUpdate -----------------------------------------------
--@api-stub: LTween:onUpdate
-- Sets a callback to fire every frame while the tween is active. Returns the tween for chaining.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:onUpdate(f)  -- -> LTween
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:onCancel -----------------------------------------------
--@api-stub: LTween:onCancel
-- Sets a callback to fire when the tween is cancelled. Returns the tween for chaining.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:onCancel(f)  -- -> LTween
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:type ---------------------------------------------------
--@api-stub: LTween:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:type()  -- -> string
-- (replace lTween_stub with your real LTween instance above)

-- ---- Stub: LTween:typeOf -------------------------------------------------
--@api-stub: LTween:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTween_stub:typeOf("hero")  -- -> boolean
-- (replace lTween_stub with your real LTween instance above)

-- -----------------------------------------------------------------------------
-- LTweenParallel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTweenParallel:add --------------------------------------------
--@api-stub: LTweenParallel:add
-- Adds an existing tween handle to this parallel group. The tween becomes owned by the group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenParallel_stub:add(par_ud, tw_ud)
-- (replace lTweenParallel_stub with your real LTweenParallel instance above)

-- ---- Stub: LTweenParallel:cancel -----------------------------------------
--@api-stub: LTweenParallel:cancel
-- Cancels all tweens in this parallel group immediately.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenParallel_stub:cancel()
-- (replace lTweenParallel_stub with your real LTweenParallel instance above)

-- ---- Stub: LTweenParallel:isActive ---------------------------------------
--@api-stub: LTweenParallel:isActive
-- Returns whether this parallel group is still running.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenParallel_stub:isActive()  -- -> boolean
-- (replace lTweenParallel_stub with your real LTweenParallel instance above)

-- ---- Stub: LTweenParallel:onComplete -------------------------------------
--@api-stub: LTweenParallel:onComplete
-- Sets a callback to fire when all tweens in this parallel group have finished. Returns the group for chaining.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenParallel_stub:onComplete(ud, f)  -- -> LTweenParallel
-- (replace lTweenParallel_stub with your real LTweenParallel instance above)

-- ---- Stub: LTweenParallel:type -------------------------------------------
--@api-stub: LTweenParallel:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenParallel_stub:type()  -- -> string
-- (replace lTweenParallel_stub with your real LTweenParallel instance above)

-- ---- Stub: LTweenParallel:typeOf -----------------------------------------
--@api-stub: LTweenParallel:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenParallel_stub:typeOf("hero")  -- -> boolean
-- (replace lTweenParallel_stub with your real LTweenParallel instance above)

-- -----------------------------------------------------------------------------
-- LTweenSequence methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTweenSequence:callback ---------------------------------------
--@api-stub: LTweenSequence:callback
-- Appends a callback step to this sequence that fires when reached during playback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:callback(f)  -- -> LTweenSequence
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:cancel -----------------------------------------
--@api-stub: LTweenSequence:cancel
-- Cancels this sequence immediately and resumes any coroutines waiting on it.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:cancel()
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:isActive ---------------------------------------
--@api-stub: LTweenSequence:isActive
-- Returns whether this sequence is still running.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:isActive()  -- -> boolean
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:getProgress ------------------------------------
--@api-stub: LTweenSequence:getProgress
-- Returns the overall progress ratio of this sequence from 0.0 to 1.0.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:getProgress()  -- -> number
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:await ------------------------------------------
--@api-stub: LTweenSequence:await
-- Yields the current coroutine until this sequence completes or is cancelled. Must be called from inside a coroutine.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:await()
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:onComplete -------------------------------------
--@api-stub: LTweenSequence:onComplete
-- Sets a callback to fire when the sequence finishes all steps. Returns the sequence for chaining.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:onComplete(ud, f)  -- -> LTweenSequence
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:type -------------------------------------------
--@api-stub: LTweenSequence:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:type()  -- -> string
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- ---- Stub: LTweenSequence:typeOf -----------------------------------------
--@api-stub: LTweenSequence:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenSequence_stub:typeOf("hero")  -- -> boolean
-- (replace lTweenSequence_stub with your real LTweenSequence instance above)

-- -----------------------------------------------------------------------------
-- LTweenState methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTweenState:tick ----------------------------------------------
--@api-stub: LTweenState:t
-- Returns the raw elapsed time (0..duration) of this tween state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenState_stub:t()  -- -> number
-- (replace lTweenState_stub with your real LTweenState instance above)

-- ---- Stub: LTweenState:tick ----------------------------------------------
--@api-stub: LTweenState:tick
-- Advances the tween state by the given delta time and returns the eased interpolation value (0..1).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenState_stub:tick(0.016)  -- -> number
-- (replace lTweenState_stub with your real LTweenState instance above)

-- ---- Stub: LTweenState:isComplete ----------------------------------------
--@api-stub: LTweenState:isComplete
-- Returns whether this tween state has finished its full duration.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenState_stub:isComplete()  -- -> boolean
-- (replace lTweenState_stub with your real LTweenState instance above)

-- ---- Stub: LTweenState:lerp ----------------------------------------------
--@api-stub: LTweenState:lerp
-- Linearly interpolates between two values using the current eased progress.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenState_stub:lerp(start, finish)  -- -> number
-- (replace lTweenState_stub with your real LTweenState instance above)

-- ---- Stub: LTweenState:reset ---------------------------------------------
--@api-stub: LTweenState:reset
-- Resets the tween state to the beginning so it can be replayed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTweenState_stub:reset()
-- (replace lTweenState_stub with your real LTweenState instance above)
