-- content/examples/effect.lua
-- Hand-written coverage of the lurek.effect API (142 items).
--
-- The effect namespace owns post-processing (built-in and custom shader
-- passes), per-image effect chains, full-screen overlays for weather, flash,
-- shake and fade, and screen transitions. Most snippets below build a fresh
-- handle inside the `do ... end` block so every example is self-contained.
--
-- Run: cargo run -- content/examples/effect.lua

-- ── lurek.effect.* functions ──

--@api-stub: lurek.effect.newEffect
-- Creates a new built-in post-processing effect by type name.
-- Pick a built-in type listed by getEffectTypes(); add the result to a stack with stack:add(eff).
do  -- lurek.effect.newEffect
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setThreshold(0.6)
  bloom:setIntensity(1.5)
  lurek.log.info("bloom built-in=" .. tostring(bloom:isBuiltIn()), "fx")
end

--@api-stub: lurek.effect.newCustomEffect
-- Creates a custom shader post-processing effect.
-- Use after lurek.render.newShader(...) returns a shader id; the effect runs that shader as a post-pass.
do  -- lurek.effect.newCustomEffect
  local shader_id = 7  -- returned earlier from lurek.render.newShader("shaders/glitch.wgsl")
  local glitch = lurek.effect.newCustomEffect(shader_id)
  glitch:setParameter("intensity", 0.4)
  lurek.log.info("custom fx built-in=" .. tostring(glitch:isBuiltIn()), "fx")
end

--@api-stub: lurek.effect.newStack
-- Creates a new post-processing pipeline stack.
-- Omit the size to pick up the current window dimensions; call resize() later when the window changes.
do  -- lurek.effect.newStack
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))
  lurek.log.info("stack ready w=" .. stack:getWidth() .. " h=" .. stack:getHeight(), "fx")
end

--@api-stub: lurek.effect.newPresetStack
-- Creates a pre-configured effect stack from a named preset.
-- Presets are 'retro_tv', 'horror', 'dream', 'neon', 'sepia_age' — saves wiring up effects by hand.
do  -- lurek.effect.newPresetStack
  local crt = lurek.effect.newPresetStack("retro_tv", 1280, 720)
  function lurek.render()
    crt:beginCapture(); crt:endCapture(); crt:apply()
  end
end

--@api-stub: lurek.effect.newPass
-- Creates a custom-shader post-processing effect (alias for newCustomEffect).
-- Alias for newCustomEffect kept for parity with engines that call shader passes 'passes'.
do  -- lurek.effect.newPass
  local shader_id = 3  -- from lurek.render.newShader("shaders/edge.wgsl")
  local edge_pass = lurek.effect.newPass(shader_id)
  edge_pass:setParameter("threshold", 0.2)
  lurek.log.debug("pass enabled=" .. tostring(edge_pass:isEnabled()), "fx")
end

--@api-stub: lurek.effect.getEffectTypes
-- Returns the list of all built-in effect type names.
-- Use to populate a debug dropdown of post-fx the player can toggle, or to validate a config string at startup.
do  -- lurek.effect.getEffectTypes
  local types = lurek.effect.getEffectTypes()
  for i, name in ipairs(types) do
    lurek.log.info("[" .. i .. "] " .. name, "fx-types")
  end
end

--@api-stub: lurek.effect.newImageEffect
-- Creates a new per-image effect chain.
-- Build a per-image effect chain by passing a list of {type=..., params}; useful for offscreen image processing.
do  -- lurek.effect.newImageEffect
  local chain = lurek.effect.newImageEffect({
    { type = "blur", radius = 3.0 },
    { type = "vignette", strength = 0.4 },
  })
  lurek.log.info("image chain count=" .. chain:effectCount(), "fx")
end

--@api-stub: lurek.effect.newOverlay
-- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
-- Pass the current window size; create one Overlay per scene and route weather/flash/shake through it.
do  -- lurek.effect.newOverlay
  local overlay = lurek.effect.newOverlay(1280, 720)
  overlay:setWeather("rain")
  overlay:setWeatherEnabled(true)
  function lurek.process(dt) overlay:update(dt) end
end

--@api-stub: lurek.effect.newTransition
-- Creates a new screen-transition controller.
-- Drive scene-change transitions; combine with overlay:render() to draw the fade rect in render_ui.
do  -- lurek.effect.newTransition
  local trans = lurek.effect.newTransition("wipe", 0.75, {0, 0, 0, 1})
  trans:play()
  function lurek.process(dt)
    if trans:update(dt) then lurek.log.debug("trans p=" .. trans:progress(), "fx") end
  end
end

--@api-stub: lurek.effect.setShaderErrorDisplay
-- Enables or disables the effect that renders shader compile errors as red text.
-- Enable in dev builds so shader compile errors appear as red text in the top-left instead of a silent black screen.
do  -- lurek.effect.setShaderErrorDisplay
  local in_dev = true
  lurek.effect.setShaderErrorDisplay(in_dev)
  lurek.log.info("shader err display=" .. tostring(in_dev), "fx-dev")
end

--@api-stub: lurek.effect.getShaderErrorDisplay
-- Returns whether shader error display is currently enabled.
-- Branch on the result to draw an extra in-game banner that warns the player a shader failed.
do  -- lurek.effect.getShaderErrorDisplay
  if lurek.effect.getShaderErrorDisplay() then
    lurek.log.warn("dev shader error overlay is ON — disable for shipping", "fx-dev")
  end
end

-- ── PostFxEffect methods ──

--@api-stub: PostFxEffect:getTypeName
-- Returns the display name of this effect type.
-- Use to label effects in a debug overlay or to write the active pipeline to a save file.
do  -- PostFxEffect:getTypeName
  local eff = lurek.effect.newEffect("crt")
  local name = eff:getTypeName()
  lurek.log.info("active fx: " .. name, "fx")
end

--@api-stub: PostFxEffect:isBuiltIn
-- Returns true if this is a built-in effect, false if custom.
-- Branch on the result before serialising — custom shader effects can't be persisted by name alone.
do  -- PostFxEffect:isBuiltIn
  local eff = lurek.effect.newEffect("vignette")
  if eff:isBuiltIn() then
    lurek.log.info("safe to serialise '" .. eff:getTypeName() .. "' by name", "fx")
  end
end

--@api-stub: PostFxEffect:isEnabled
-- Returns whether this effect is currently active.
-- Read it before reapplying parameters so you don't waste GPU work on a disabled pass.
do  -- PostFxEffect:isEnabled
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setEnabled(false)
  if not bloom:isEnabled() then
    lurek.log.debug("bloom currently muted", "fx")
  end
end

--@api-stub: PostFxEffect:setEnabled
-- Enables or disables this effect.
-- Toggle from a settings menu; cheaper than removing the effect from the stack since the GPU pass is just skipped.
do  -- PostFxEffect:setEnabled
  local crt = lurek.effect.newEffect("crt")
  local low_quality = true
  crt:setEnabled(not low_quality)
end

--@api-stub: PostFxEffect:setParameter
-- Sets a named float parameter on this effect.
-- Parameter names are documented per effect (e.g. bloom: 'threshold', 'intensity'); call once at startup or animate per frame.
do  -- PostFxEffect:setParameter
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setParameter("threshold", 0.5)
  bloom:setParameter("intensity", 1.2)
  lurek.log.debug("bloom configured", "fx")
end

--@api-stub: PostFxEffect:hasParameter
-- Returns true if the named parameter exists on this effect.
-- Probe before calling setParameter when the effect type is loaded from config and the param set isn't known statically.
do  -- PostFxEffect:hasParameter
  local eff = lurek.effect.newEffect("crt")
  if eff:hasParameter("scanline_strength") then
    eff:setParameter("scanline_strength", 0.7)
  end
end

--@api-stub: PostFxEffect:getParameterNames
-- Returns a list of all parameter names on this effect.
-- Use to build a generic 'tweak this effect' editor panel without hard-coding param names per type.
do  -- PostFxEffect:getParameterNames
  local eff = lurek.effect.newEffect("colourgrade")
  for _, name in ipairs(eff:getParameterNames()) do
    lurek.log.info("colourgrade param: " .. name, "fx-edit")
  end
end

--@api-stub: PostFxEffect:getEffectType
-- Returns the type name of this effect (alias for getTypeName).
-- Alias of getTypeName; use whichever reads better in your call site.
do  -- PostFxEffect:getEffectType
  local eff = lurek.effect.newEffect("sepia")
  local kind = eff:getEffectType()
  lurek.log.info("kind=" .. kind, "fx")
end

--@api-stub: PostFxEffect:getType
-- Returns the type name of this effect (alias for getTypeName).
-- Another alias of getTypeName retained for compatibility with code generated against the older API.
do  -- PostFxEffect:getType
  local eff = lurek.effect.newEffect("invert")
  if eff:getType() == "invert" then
    lurek.log.debug("invert pass detected", "fx")
  end
end

--@api-stub: PostFxEffect:type
-- Returns the type name "PostFxEffect".
-- Use the Lurek2D type/typeOf protocol to assert the userdata kind before passing it across module boundaries.
do  -- PostFxEffect:type
  local eff = lurek.effect.newEffect("bloom")
  assert(eff:type() == "PostFxEffect", "expected a PostFxEffect")
end

--@api-stub: PostFxEffect:typeOf
-- Returns true when the given name matches "PostFxEffect" or a parent type.
-- Returns true for the type name itself or 'Object'; useful in generic dispatch tables keyed on type.
do  -- PostFxEffect:typeOf
  local eff = lurek.effect.newEffect("blur")
  if eff:typeOf("Object") then
    lurek.log.debug("eff inherits from Object", "fx")
  end
end

--@api-stub: PostFxEffect:setThreshold
-- Sets the threshold parameter of this effect.
-- Convenience for setParameter('threshold', v); for bloom this is the brightness cutoff that begins to glow.
do  -- PostFxEffect:setThreshold
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setThreshold(0.75)
  lurek.log.debug("bloom threshold set", "fx")
end

--@api-stub: PostFxEffect:setIntensity
-- Sets the intensity parameter of this effect.
-- Common knob shared by bloom, godrays, film grain, etc.; safe range is roughly 0.0 to 2.0.
do  -- PostFxEffect:setIntensity
  local godrays = lurek.effect.newEffect("godrays")
  godrays:setIntensity(1.4)
end

--@api-stub: PostFxEffect:setRadius
-- Sets the radius parameter of this effect.
-- For blur/bloom this controls the kernel size in pixels; larger values cost more GPU time.
do  -- PostFxEffect:setRadius
  local blur = lurek.effect.newEffect("blur")
  blur:setRadius(4.0)
end

--@api-stub: PostFxEffect:setStrength
-- Sets the strength parameter of this effect.
-- Generic intensity-like knob used by vignette, sharpen, dither; clamp from a settings slider before passing in.
do  -- PostFxEffect:setStrength
  local vig = lurek.effect.newEffect("vignette")
  local from_slider = 0.6
  vig:setStrength(math.max(0.0, math.min(1.0, from_slider)))
end

--@api-stub: PostFxEffect:setScanlineStrength
-- Sets the scanline strength parameter of this effect.
-- CRT-specific darkening of horizontal scanlines; pair with setIntensity to dial in the retro look.
do  -- PostFxEffect:setScanlineStrength
  local crt = lurek.effect.newEffect("crt")
  crt:setScanlineStrength(0.35)
  crt:setIntensity(1.0)
end

--@api-stub: PostFxEffect:setOffset
-- Sets the offset parameter of this effect.
-- For chromatic aberration this shifts R/B channels in pixels; small values (1–4) are most pleasing.
do  -- PostFxEffect:setOffset
  local chroma = lurek.effect.newEffect("chromatic")
  chroma:setOffset(2.0)
end

--@api-stub: PostFxEffect:setBrightness
-- Sets the brightness parameter of this effect.
-- Used by colourgrade; 0.0 is no change, positive brightens, negative darkens.
do  -- PostFxEffect:setBrightness
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setBrightness(0.05)
end

--@api-stub: PostFxEffect:setContrast
-- Sets the contrast parameter of this effect.
-- Pairs with setBrightness/setSaturation; multiplicative around 0.5 grey, 1.0 = unchanged.
do  -- PostFxEffect:setContrast
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setContrast(1.15)
end

--@api-stub: PostFxEffect:setSaturation
-- Sets the saturation parameter of this effect.
-- Drop to 0.0 for full grayscale via colourgrade instead of swapping in the dedicated grayscale effect.
do  -- PostFxEffect:setSaturation
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setSaturation(0.7)  -- desaturated mood
end

-- ── PostFxStack methods ──

--@api-stub: PostFxStack:add
-- Appends a PostFxEffect to the end of the pipeline.
-- Order matters: blur before bloom is different from bloom before blur; build the chain bottom-up.
do  -- PostFxStack:add
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))
  lurek.log.info("stack size=" .. stack:getEffectCount(), "fx")
end

--@api-stub: PostFxStack:remove
-- Removes the given PostFxEffect from the pipeline.
-- Pass the original effect handle returned by newEffect; returns true when an effect was actually removed.
do  -- PostFxStack:remove
  local stack = lurek.effect.newStack()
  local crt = lurek.effect.newEffect("crt")
  stack:add(crt)
  local removed = stack:remove(crt)
  lurek.log.debug("crt removed=" .. tostring(removed), "fx")
end

--@api-stub: PostFxStack:isEnabled
-- Returns whether the effect at the given 1-based position is enabled.
-- Index is 1-based like Lua tables; check before triggering an expensive parameter retune.
do  -- PostFxStack:isEnabled
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  if stack:isEnabled(1) then
    lurek.log.debug("slot 1 active", "fx")
  end
end

--@api-stub: PostFxStack:getEffectCount
-- Returns the number of effects in the pipeline.
-- Iterate from 1..count to walk the pipeline, or compare against an expected size in tests.
do  -- PostFxStack:getEffectCount
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("crt"))
  for i = 1, stack:getEffectCount() do
    lurek.log.info("slot " .. i .. " = " .. stack:getEffect(i):getTypeName(), "fx")
  end
end

--@api-stub: PostFxStack:getEffect
-- Returns the effect at the given 1-based position, or nil.
-- Returns nil when the index is out of range; pair with getEffectCount when iterating.
do  -- PostFxStack:getEffect
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("vignette"))
  local first = stack:getEffect(1)
  if first then first:setStrength(0.8) end
end

--@api-stub: PostFxStack:getEnabledEffects
-- Returns a list of currently enabled effect objects.
-- Skips disabled slots so you don't have to filter manually; useful when serialising the active pipeline.
do  -- PostFxStack:getEnabledEffects
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  for _, eff in ipairs(stack:getEnabledEffects()) do
    lurek.log.debug("enabled: " .. eff:getTypeName(), "fx")
  end
end

--@api-stub: PostFxStack:getWidth
-- Returns the width of the render target.
-- Read after a window resize to confirm the stack picked up the new dimensions.
do  -- PostFxStack:getWidth
  local stack = lurek.effect.newStack(1920, 1080)
  if stack:getWidth() ~= 1920 then
    lurek.log.warn("stack width drift: " .. stack:getWidth(), "fx")
  end
end

--@api-stub: PostFxStack:getHeight
-- Returns the height of the render target.
-- Pair with getWidth or use getDimensions to fetch both at once.
do  -- PostFxStack:getHeight
  local stack = lurek.effect.newStack(1280, 720)
  if stack:getHeight() < 480 then
    lurek.log.warn("stack height too small for HUD layout", "fx")
  end
end

--@api-stub: PostFxStack:getDimensions
-- Returns width and height of the render target.
-- Multi-return convenience for resizing dependent render targets in lock-step with the stack.
do  -- PostFxStack:getDimensions
  local stack = lurek.effect.newStack()
  local w, h = stack:getDimensions()
  lurek.log.info("stack target = " .. w .. "x" .. h, "fx")
end

--@api-stub: PostFxStack:resize
-- Resizes the render target to the given dimensions.
-- Call from your window-resize handler so the post-fx capture texture matches the new framebuffer size.
do  -- PostFxStack:resize
  local stack = lurek.effect.newStack(800, 600)
  local new_w, new_h = 1600, 900
  stack:resize(new_w, new_h)
  lurek.log.info("stack resized to " .. new_w .. "x" .. new_h, "fx")
end

--@api-stub: PostFxStack:len
-- Returns the total number of effect slots in the pipeline.
-- Same value as getEffectCount, kept so Lua code can use #-style intent for stacks.
do  -- PostFxStack:len
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  lurek.log.debug("stack len=" .. stack:len(), "fx")
end

--@api-stub: PostFxStack:isEmpty
-- Returns true if the pipeline has no effect slots.
-- Skip the begin/end/apply triplet entirely when the pipeline has no effects to spare a wasted GPU render pass.
do  -- PostFxStack:isEmpty
  local stack = lurek.effect.newStack()
  if stack:isEmpty() then
    lurek.log.debug("post-fx pipeline empty — skipping capture", "fx")
  end
end

--@api-stub: PostFxStack:clear
-- Removes all effects from the pipeline.
-- Use at scene boundaries to drop the previous level's pipeline before adding the new one.
do  -- PostFxStack:clear
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("crt"))
  stack:clear()
  lurek.log.info("pipeline cleared, count=" .. stack:getEffectCount(), "fx")
end

--@api-stub: PostFxStack:dedup
-- Removes duplicate effects from the pipeline, keeping the first occurrence.
-- Returns the number of slots removed; safe to call after dynamic composition that might add the same effect twice.
do  -- PostFxStack:dedup
  local stack = lurek.effect.newStack()
  local bloom = lurek.effect.newEffect("bloom")
  stack:add(bloom); stack:add(bloom)
  local removed = stack:dedup()
  lurek.log.info("dedup removed " .. tostring(removed) .. " duplicate slot(s)", "fx")
end

--@api-stub: PostFxStack:isCapturing
-- Returns whether the stack is currently capturing the scene.
-- Use as an assertion inside your render code to make sure beginCapture/endCapture are correctly paired.
do  -- PostFxStack:isCapturing
  local stack = lurek.effect.newStack()
  function lurek.render()
    stack:beginCapture()
    assert(stack:isCapturing(), "post-fx capture should be active here")
    stack:endCapture(); stack:apply()
  end
end

--@api-stub: PostFxStack:beginCapture
-- Begins capturing the scene for post-processing.
-- Call FIRST in lurek.render to redirect all subsequent draws into the capture texture.
do  -- PostFxStack:beginCapture
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  function lurek.render()
    stack:beginCapture()
    -- scene draws happen here
    stack:endCapture(); stack:apply()
  end
end

--@api-stub: PostFxStack:endCapture
-- Ends scene capture for post-processing.
-- Closes the capture started by beginCapture; must come BEFORE apply() so the GPU knows the source is finalised.
do  -- PostFxStack:endCapture
  local stack = lurek.effect.newStack()
  function lurek.render()
    stack:beginCapture()
    stack:endCapture()
    stack:apply()
  end
end

--@api-stub: PostFxStack:apply
-- Applies all enabled effects in the stack and composites the result to screen.
-- Composites the processed result back to screen; this is where the GPU actually runs the shaders.
do  -- PostFxStack:apply
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  function lurek.render()
    stack:beginCapture(); stack:endCapture()
    stack:apply()
  end
end

--@api-stub: PostFxStack:type
-- Returns the type name "PostFxStack".
-- Type-check before passing a stack into a generic render helper that also accepts ImageEffect.
do  -- PostFxStack:type
  local stack = lurek.effect.newStack()
  if stack:type() == "PostFxStack" then
    lurek.log.debug("got a real post-fx stack", "fx")
  end
end

--@api-stub: PostFxStack:typeOf
-- Returns true when the given name matches "PostFxStack" or a parent type.
-- Returns true for 'PostFxStack' or 'Object'; use in dispatch tables that key on parent class.
do  -- PostFxStack:typeOf
  local stack = lurek.effect.newStack()
  assert(stack:typeOf("Object"), "PostFxStack should inherit Object")
end

--@api-stub: PostFxStack:setFeedback
-- Sets the feedback loop intensity.
-- Values near 1.0 produce phosphor / motion-trail looks; clamp from a 0..1 settings slider.
do  -- PostFxStack:setFeedback
  local stack = lurek.effect.newStack()
  stack:setFeedback(0.85)  -- strong trail for a dream sequence
  lurek.log.info("feedback=" .. stack:getFeedback(), "fx")
end

--@api-stub: PostFxStack:getFeedback
-- Returns the current feedback loop intensity `[0.0, 1.0]`.
-- Read once after configuration to confirm the slider value clamped into the [0,1] range.
do  -- PostFxStack:getFeedback
  local stack = lurek.effect.newStack()
  stack:setFeedback(2.0)  -- will be clamped
  lurek.log.info("clamped feedback=" .. stack:getFeedback(), "fx")
end

--@api-stub: PostFxStack:clearFeedback
-- Resets the feedback intensity to `0.0` (disables feedback).
-- Equivalent to setFeedback(0); use when leaving the dream scene back to normal play.
do  -- PostFxStack:clearFeedback
  local stack = lurek.effect.newStack()
  stack:setFeedback(0.6)
  stack:clearFeedback()
  lurek.log.debug("feedback cleared=" .. stack:getFeedback(), "fx")
end

-- ── ImageEffect methods ──

--@api-stub: ImageEffect:addEffect
-- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
-- Returns the shared PostFxEffect handle so you can tweak parameters in the same expression chain.
do  -- ImageEffect:addEffect
  local chain = lurek.effect.newImageEffect()
  local blur = chain:addEffect("blur")
  blur:setRadius(2.5)
  lurek.log.info("chain size=" .. chain:effectCount(), "fx")
end

--@api-stub: ImageEffect:getEffect
-- Returns the effect at the given 1-based index or with the given type name.
-- Look up by 1-based index OR by effect type name; returns nil when not present.
do  -- ImageEffect:getEffect
  local chain = lurek.effect.newImageEffect({{ type = "vignette" }})
  local vig = chain:getEffect("vignette")
  if vig then vig:setStrength(0.5) end
end

--@api-stub: ImageEffect:removeEffect
-- Removes the effect at the given 1-based index or with the given type name.
-- Accepts an integer index or a type-name string; returns true on success.
do  -- ImageEffect:removeEffect
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  local removed = chain:removeEffect("blur")
  lurek.log.debug("blur removed=" .. tostring(removed) .. " count=" .. chain:effectCount(), "fx")
end

--@api-stub: ImageEffect:clearEffects
-- Removes all effects from the chain.
-- Wipe the chain before re-populating with a different preset set.
do  -- ImageEffect:clearEffects
  local chain = lurek.effect.newImageEffect({{ type = "bloom" }})
  chain:clearEffects()
  assert(chain:effectCount() == 0, "chain should be empty")
end

--@api-stub: ImageEffect:clear
-- Removes all effects from the chain (alias for clearEffects).
-- Alias for clearEffects; use whichever reads better in your call site.
do  -- ImageEffect:clear
  local chain = lurek.effect.newImageEffect({{ type = "crt" }})
  chain:clear()
  lurek.log.debug("chain cleared", "fx")
end

--@api-stub: ImageEffect:effectCount
-- Returns the number of effects in the chain.
-- Use to walk the chain or to early-exit when there is nothing to apply.
do  -- ImageEffect:effectCount
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  if chain:effectCount() > 0 then
    lurek.log.info("image chain has " .. chain:effectCount() .. " passes", "fx")
  end
end

--@api-stub: ImageEffect:getEffectCount
-- Returns the number of effects in the chain (alias for effectCount).
-- Alias for effectCount; both names are kept so older example code keeps working.
do  -- ImageEffect:getEffectCount
  local chain = lurek.effect.newImageEffect({{ type = "sepia" }})
  lurek.log.debug("count=" .. chain:getEffectCount(), "fx")
end

--@api-stub: ImageEffect:clone
-- Returns a deep copy of this ImageEffect chain.
-- Useful when one chain serves as a template — clone, then tweak the copy without affecting the original.
do  -- ImageEffect:clone
  local base = lurek.effect.newImageEffect({{ type = "vignette", strength = 0.4 }})
  local night = base:clone()
  night:addEffect("colourgrade"):setBrightness(-0.1)
end

--@api-stub: ImageEffect:save
-- Stub: no-op serialisation placeholder.
-- Currently a no-op placeholder that always returns true; reserved for future on-disk serialisation.
do  -- ImageEffect:save
  local chain = lurek.effect.newImageEffect({{ type = "bloom" }})
  if chain:save() then
    lurek.log.debug("image chain save() acknowledged", "fx")
  end
end

--@api-stub: ImageEffect:type
-- Returns the type name "ImageEffect".
-- Use when a function accepts both ImageEffect and PostFxStack and must dispatch on the userdata kind.
do  -- ImageEffect:type
  local chain = lurek.effect.newImageEffect()
  if chain:type() == "ImageEffect" then
    lurek.log.debug("per-image chain detected", "fx")
  end
end

--@api-stub: ImageEffect:typeOf
-- Returns true when the given name matches "ImageEffect" or a parent type.
-- Returns true for 'ImageEffect' or 'Object'; check the parent name in generic frameworks.
do  -- ImageEffect:typeOf
  local chain = lurek.effect.newImageEffect()
  assert(chain:typeOf("Object"), "ImageEffect should be an Object")
end

--@api-stub: ImageEffect:removeByIndex
-- Removes the effect at the given 0-based index from the chain.
-- Legacy 0-based variant of removeEffect; prefer removeEffect for new code.
do  -- ImageEffect:removeByIndex
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "crt" }})
  local removed = chain:removeByIndex(0)  -- removes the blur
  lurek.log.debug("by-index removed=" .. tostring(removed), "fx")
end

--@api-stub: ImageEffect:removeByName
-- Removes the first effect matching the given type name.
-- Legacy variant of removeEffect that only takes a type name.
do  -- ImageEffect:removeByName
  local chain = lurek.effect.newImageEffect({{ type = "vignette" }, { type = "sepia" }})
  chain:removeByName("vignette")
  lurek.log.debug("after by-name remove count=" .. chain:effectCount(), "fx")
end

-- ── Overlay methods ──

--@api-stub: Overlay:update
-- Advances all effect subsystems by the given delta time.
-- Call once per simulation step from lurek.process; advances flash/fade/shake/weather animations.
do  -- Overlay:update
  local overlay = lurek.effect.newOverlay()
  function lurek.process(dt)
    overlay:update(dt)
  end
end

--@api-stub: Overlay:triggerLightning
-- Triggers a lightning flash effect.
-- Fires a one-shot bright flash; pair with audio:play('sfx/thunder.ogg') for the full effect.
do  -- Overlay:triggerLightning
  local overlay = lurek.effect.newOverlay()
  overlay:triggerLightning()
  lurek.log.info("lightning fired alpha=" .. overlay:getLightningAlpha(), "weather")
end

--@api-stub: Overlay:getShakeOffset
-- Returns the current shake displacement as x, y.
-- Returned x,y are pixel offsets to apply to the camera or the world transform during render.
do  -- Overlay:getShakeOffset
  local overlay = lurek.effect.newOverlay()
  overlay:shake(8.0, 0.4)
  function lurek.render()
    local ox, oy = overlay:getShakeOffset()
    lurek.log.debug("shake ox=" .. ox .. " oy=" .. oy, "shake")
  end
end

--@api-stub: Overlay:isActive
-- Returns true if any effect subsystem is currently active.
-- Use as an early-exit so you skip the overlay:render() call when nothing is going on.
do  -- Overlay:isActive
  local overlay = lurek.effect.newOverlay()
  if overlay:isActive() then
    function lurek.render() overlay:render() end
  end
end

--@api-stub: Overlay:clear
-- Resets all effect subsystems to their default inactive state.
-- Resets shake/flash/fade/lightning to inactive — use when teleporting the player to a calm scene.
do  -- Overlay:clear
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.5)
  overlay:clear()
  assert(not overlay:isFlashing(), "flash should be cancelled")
end

--@api-stub: Overlay:resize
-- Resizes the effect to match new window dimensions.
-- Call from your window-resize handler so weather particles cover the new viewport.
do  -- Overlay:resize
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:resize(1920, 1080)
  lurek.log.info("overlay resized to " .. overlay:getWidth() .. "x" .. overlay:getHeight(), "fx")
end

--@api-stub: Overlay:getWidth
-- Returns the effect width.
-- Read after resize() to confirm the overlay matches the active framebuffer width.
do  -- Overlay:getWidth
  local overlay = lurek.effect.newOverlay(1024, 768)
  lurek.log.debug("overlay w=" .. overlay:getWidth(), "fx")
end

--@api-stub: Overlay:getHeight
-- Returns the effect height.
-- Pair with getWidth or use getDimensions for both in one call.
do  -- Overlay:getHeight
  local overlay = lurek.effect.newOverlay(1024, 768)
  lurek.log.debug("overlay h=" .. overlay:getHeight(), "fx")
end

--@api-stub: Overlay:getDimensions
-- Returns the effect width and height.
-- Multi-return convenience to keep dependent render targets aligned with the overlay size.
do  -- Overlay:getDimensions
  local overlay = lurek.effect.newOverlay()
  local w, h = overlay:getDimensions()
  lurek.log.info("overlay = " .. w .. "x" .. h, "fx")
end

--@api-stub: Overlay:getFlashAlpha
-- Returns the current flash overlay alpha value.
-- Use to drive secondary effects like camera bloom that should peak in sync with the flash.
do  -- Overlay:getFlashAlpha
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.3)
  function lurek.process(dt)
    overlay:update(dt)
    if overlay:getFlashAlpha() > 0.5 then lurek.log.debug("flash peak", "fx") end
  end
end

--@api-stub: Overlay:getLightningAlpha
-- Returns the current lightning overlay alpha value.
-- Read each frame to brighten the level's ambient light in time with the lightning bolt.
do  -- Overlay:getLightningAlpha
  local overlay = lurek.effect.newOverlay()
  overlay:triggerLightning()
  function lurek.process(dt)
    overlay:update(dt)
    local a = overlay:getLightningAlpha()
    if a > 0.0 then lurek.log.debug("lightning a=" .. a, "fx") end
  end
end

--@api-stub: Overlay:setAmbientEnabled
-- Enables or disables the ambient light layer.
-- Disable in the title menu where time-of-day tinting would distort the logo colours.
do  -- Overlay:setAmbientEnabled
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  overlay:setTimeOfDay(20.0)  -- evening
end

--@api-stub: Overlay:isAmbientEnabled
-- Returns whether the ambient light layer is active.
-- Branch on it before reading getAmbientColor — the value is meaningless when ambient is off.
do  -- Overlay:isAmbientEnabled
  local overlay = lurek.effect.newOverlay()
  if overlay:isAmbientEnabled() then
    lurek.log.debug("ambient layer is live", "fx")
  end
end

--@api-stub: Overlay:getAmbientColor
-- Returns the current ambient tint as r, g, b, a components.
-- Returns r,g,b,a as four numbers in 0..1; combine with light tints for a colour-graded look.
do  -- Overlay:getAmbientColor
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  local r, g, b, a = overlay:getAmbientColor()
  lurek.log.info(string.format("ambient %.2f %.2f %.2f a=%.2f", r, g, b, a), "fx")
end

--@api-stub: Overlay:setTimeOfDay
-- Sets the simulated time-of-day (0â€“24) which drives ambient colour.
-- Pass an hour 0..24 — 0 and 24 are midnight, 12 is noon; the overlay drives ambient colour from this.
do  -- Overlay:setTimeOfDay
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  overlay:setTimeOfDay(7.5)  -- early morning
end

--@api-stub: Overlay:getTimeOfDay
-- Returns the current simulated time-of-day (0â€“24).
-- Read to drive game logic that depends on the in-world clock, e.g. NPC schedules.
do  -- Overlay:getTimeOfDay
  local overlay = lurek.effect.newOverlay()
  overlay:setTimeOfDay(18.0)
  if overlay:getTimeOfDay() > 18.0 then
    lurek.log.info("dusk — enable street lamps", "world")
  end
end

--@api-stub: Overlay:setFogEnabled
-- Enables or disables the fog layer.
-- Toggle for cinematic moments or to indicate weather change; combine with setFogDensity for ramping in.
do  -- Overlay:setFogEnabled
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  overlay:setFogDensity(0.4)
end

--@api-stub: Overlay:isFogEnabled
-- Returns whether the fog layer is active.
-- Use as a guard before tuning fog density so you don't enable it accidentally.
do  -- Overlay:isFogEnabled
  local overlay = lurek.effect.newOverlay()
  if not overlay:isFogEnabled() then
    overlay:setFogEnabled(true)
  end
end

--@api-stub: Overlay:setFogDensity
-- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
-- 0.0 is clear, 1.0 is fully opaque; ramp gradually to avoid a jarring transition.
do  -- Overlay:setFogDensity
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  local target = 0.6
  overlay:setFogDensity(target)
end

--@api-stub: Overlay:getFogDensity
-- Returns the current fog density.
-- Read each frame when ramping fog from the current density toward a target.
do  -- Overlay:getFogDensity
  local overlay = lurek.effect.newOverlay()
  overlay:setFogDensity(0.3)
  lurek.log.debug("fog density=" .. overlay:getFogDensity(), "fx")
end

--@api-stub: Overlay:getFogColor
-- Returns the current fog tint as r, g, b, a components.
-- Returns r,g,b,a in 0..1; tint pixel-perfect to your level's palette to avoid a 'green soup' look.
do  -- Overlay:getFogColor
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  local r, g, b = overlay:getFogColor()
  lurek.log.info(string.format("fog rgb %.2f %.2f %.2f", r, g, b), "fx")
end

--@api-stub: Overlay:setHeatHazeEnabled
-- Enables or disables the heat-haze distortion layer.
-- Switch on inside desert / volcano biomes; pair with rising heat haze intensity for a layering effect.
do  -- Overlay:setHeatHazeEnabled
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeEnabled(true)
  overlay:setHeatHazeIntensity(0.5)
end

--@api-stub: Overlay:isHeatHazeEnabled
-- Returns whether the heat-haze layer is active.
-- Branch on it before changing intensity to avoid waking up a dormant subsystem unintentionally.
do  -- Overlay:isHeatHazeEnabled
  local overlay = lurek.effect.newOverlay()
  if overlay:isHeatHazeEnabled() then
    lurek.log.debug("heat haze on", "fx")
  end
end

--@api-stub: Overlay:setHeatHazeIntensity
-- Sets the heat-haze distortion intensity (0.0â€“1.0).
-- Range is 0.0..1.0; tie to ambient temperature so the visual matches the simulation.
do  -- Overlay:setHeatHazeIntensity
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeEnabled(true)
  local temp_c = 42
  overlay:setHeatHazeIntensity(math.min(1.0, math.max(0.0, (temp_c - 30) / 20)))
end

--@api-stub: Overlay:getHeatHazeIntensity
-- Returns the current heat-haze distortion intensity.
-- Read to drive secondary effects like increased visual blur on top of the haze.
do  -- Overlay:getHeatHazeIntensity
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeIntensity(0.6)
  lurek.log.debug("heat haze i=" .. overlay:getHeatHazeIntensity(), "fx")
end

--@api-stub: Overlay:setVignetteEnabled
-- Enables or disables the screen-edge vignette layer.
-- Most cinematic shots want this on; performance cost is negligible.
do  -- Overlay:setVignetteEnabled
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteEnabled(true)
  overlay:setVignetteStrength(0.55)
end

--@api-stub: Overlay:isVignetteEnabled
-- Returns whether the vignette layer is active.
-- Use to skip vignette tuning code when the player has disabled it from the settings menu.
do  -- Overlay:isVignetteEnabled
  local overlay = lurek.effect.newOverlay()
  if overlay:isVignetteEnabled() then
    overlay:setVignetteStrength(0.7)
  end
end

--@api-stub: Overlay:setVignetteStrength
-- Sets the vignette darkening strength (0.0â€“1.0).
-- 0.0 is no darkening, 1.0 fully blacks out the corners; 0.3..0.6 reads as 'cinematic'.
do  -- Overlay:setVignetteStrength
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteEnabled(true)
  overlay:setVignetteStrength(0.45)
end

--@api-stub: Overlay:getVignetteStrength
-- Returns the current vignette strength.
-- Read to confirm what the player picked in their settings menu.
do  -- Overlay:getVignetteStrength
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteStrength(0.5)
  lurek.log.debug("vignette s=" .. overlay:getVignetteStrength(), "fx")
end

--@api-stub: Overlay:setFilmGrainEnabled
-- Enables or disables the film-grain noise layer.
-- Adds a subtle noise overlay; useful for horror or 'old film' aesthetics.
do  -- Overlay:setFilmGrainEnabled
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainEnabled(true)
  overlay:setFilmGrainIntensity(0.25)
end

--@api-stub: Overlay:isFilmGrainEnabled
-- Returns whether the film-grain layer is active.
-- Branch on it to expose a 'grain on/off' toggle in the player's accessibility menu.
do  -- Overlay:isFilmGrainEnabled
  local overlay = lurek.effect.newOverlay()
  if overlay:isFilmGrainEnabled() then
    lurek.log.debug("grain layer is live", "fx")
  end
end

--@api-stub: Overlay:setFilmGrainIntensity
-- Sets the film-grain noise intensity (0.0â€“1.0).
-- Keep below 0.4 to avoid making text hard to read.
do  -- Overlay:setFilmGrainIntensity
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainEnabled(true)
  overlay:setFilmGrainIntensity(0.18)
end

--@api-stub: Overlay:getFilmGrainIntensity
-- Returns the current film-grain intensity.
-- Read after applying a player setting to confirm the value was accepted.
do  -- Overlay:getFilmGrainIntensity
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainIntensity(0.3)
  lurek.log.debug("grain i=" .. overlay:getFilmGrainIntensity(), "fx")
end

--@api-stub: Overlay:setCloudShadows
-- Enables or disables scrolling cloud-shadow projection.
-- Drifting cloud shadows hide tile seams in outdoor scenes; pair with setCloudCount and setCloudSpeed.
do  -- Overlay:setCloudShadows
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudCount(8)
end

--@api-stub: Overlay:isCloudShadowsEnabled
-- Returns whether cloud shadows are active.
-- Use to gate the rest of the cloud setup so disabled clouds don't waste config calls.
do  -- Overlay:isCloudShadowsEnabled
  local overlay = lurek.effect.newOverlay()
  if overlay:isCloudShadowsEnabled() then
    overlay:setCloudOpacity(0.4)
  end
end

--@api-stub: Overlay:setCloudCount
-- Sets the number of cloud shadow instances to render.
-- Higher counts cost more GPU; 4..16 is a sweet spot for a busy sky.
do  -- Overlay:setCloudCount
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudCount(12)
end

--@api-stub: Overlay:getCloudCount
-- Returns the current cloud shadow instance count.
-- Read once to confirm config; the value is the number of shadow instances actually being drawn.
do  -- Overlay:getCloudCount
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudCount(6)
  lurek.log.debug("clouds=" .. overlay:getCloudCount(), "fx")
end

--@api-stub: Overlay:setCloudSpeed
-- Sets the horizontal scroll speed of cloud shadows in pixels per second.
-- Pixels per second; tie to wind speed for a coherent weather look.
do  -- Overlay:setCloudSpeed
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudSpeed(40.0)
end

--@api-stub: Overlay:getCloudSpeed
-- Returns the current cloud shadow scroll speed.
-- Read for a debug overlay or to ramp speed during weather changes.
do  -- Overlay:getCloudSpeed
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudSpeed(25.0)
  lurek.log.debug("cloud px/s=" .. overlay:getCloudSpeed(), "fx")
end

--@api-stub: Overlay:setCloudScale
-- Sets the scale multiplier applied to each cloud shadow.
-- 1.0 is the texture's native size; <1 makes them small and busy, >1 makes them broad.
do  -- Overlay:setCloudScale
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudScale(1.5)
end

--@api-stub: Overlay:getCloudScale
-- Returns the current cloud shadow scale.
-- Read after a config-load to confirm the saved scale was applied.
do  -- Overlay:getCloudScale
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudScale(0.8)
  lurek.log.debug("cloud scale=" .. overlay:getCloudScale(), "fx")
end

--@api-stub: Overlay:setCloudOpacity
-- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
-- 0.0 invisible, 1.0 fully dark; 0.2..0.5 is most natural.
do  -- Overlay:setCloudOpacity
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudOpacity(0.35)
end

--@api-stub: Overlay:getCloudOpacity
-- Returns the current cloud shadow opacity.
-- Read to drive a 'sunny vs overcast' state machine.
do  -- Overlay:getCloudOpacity
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudOpacity(0.4)
  if overlay:getCloudOpacity() > 0.3 then
    lurek.log.info("overcast skies", "weather")
  end
end

--@api-stub: Overlay:setWeatherEnabled
-- Enables or disables the weather particle system.
-- Master toggle; setWeather chooses the type and setWeatherIntensity dials it in.
do  -- Overlay:setWeatherEnabled
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  overlay:setWeatherEnabled(true)
end

--@api-stub: Overlay:isWeatherEnabled
-- Returns whether the weather particle system is active.
-- Use to gate the weather-driven gameplay logic (e.g. slippery floors when raining).
do  -- Overlay:isWeatherEnabled
  local overlay = lurek.effect.newOverlay()
  if overlay:isWeatherEnabled() then
    lurek.log.debug("weather active = " .. overlay:getWeather(), "weather")
  end
end

--@api-stub: Overlay:setWeather
-- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
-- Names: 'none', 'rain', 'snow', 'hail', 'dust', 'leaves', 'ash', 'pollen'; raises an error on an unknown name.
do  -- Overlay:setWeather
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("snow")
  overlay:setWeatherEnabled(true)
  overlay:setWeatherIntensity(0.7)
end

--@api-stub: Overlay:getWeather
-- Returns the name of the current weather type.
-- Returns the active weather name; useful for HUD widgets or for save-game serialisation.
do  -- Overlay:getWeather
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  lurek.log.info("current weather: " .. overlay:getWeather(), "weather")
end

--@api-stub: Overlay:setWeatherIntensity
-- Sets the particle spawn rate multiplier (0.0â€“1.0).
-- Spawn-rate multiplier 0..1; 0 stops new particles, 1 is a downpour.
do  -- Overlay:setWeatherIntensity
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  overlay:setWeatherIntensity(0.85)
end

--@api-stub: Overlay:getWeatherIntensity
-- Returns the current weather intensity.
-- Read to ramp intensity smoothly toward a target instead of snapping.
do  -- Overlay:getWeatherIntensity
  local overlay = lurek.effect.newOverlay()
  overlay:setWeatherIntensity(0.5)
  lurek.log.debug("weather i=" .. overlay:getWeatherIntensity(), "weather")
end

--@api-stub: Overlay:setWindDirection
-- Sets the wind direction in radians (0 = right, Ď€/2 = down).
-- Radians: 0 right, π/2 down, π left, 3π/2 up; affects how weather particles travel.
do  -- Overlay:setWindDirection
  local overlay = lurek.effect.newOverlay()
  overlay:setWindDirection(math.pi / 4)  -- down-right
  overlay:setWindSpeed(60.0)
end

--@api-stub: Overlay:getWindDirection
-- Returns the current wind direction in radians.
-- Read to point a HUD wind-vane indicator or to compute affected gameplay angles.
do  -- Overlay:getWindDirection
  local overlay = lurek.effect.newOverlay()
  overlay:setWindDirection(math.pi)
  lurek.log.debug("wind dir rad=" .. overlay:getWindDirection(), "weather")
end

--@api-stub: Overlay:setWindSpeed
-- Sets the wind speed applied to weather particles in units per second.
-- Units per second applied to weather particles; pair with setCloudSpeed to keep visuals coherent.
do  -- Overlay:setWindSpeed
  local overlay = lurek.effect.newOverlay()
  overlay:setWindSpeed(120.0)
  overlay:setCloudSpeed(60.0)
end

--@api-stub: Overlay:getWindSpeed
-- Returns the current wind speed.
-- Read for HUD wind speed display or to drive screen-shake intensity in storms.
do  -- Overlay:getWindSpeed
  local overlay = lurek.effect.newOverlay()
  overlay:setWindSpeed(80.0)
  lurek.log.debug("wind=" .. overlay:getWindSpeed(), "weather")
end

--@api-stub: Overlay:getLightningColor
-- Returns the lightning flash tint as r, g, b, a components.
-- Returns r,g,b,a; usually keep near white for natural lightning, shift toward purple for sci-fi storms.
do  -- Overlay:getLightningColor
  local overlay = lurek.effect.newOverlay()
  local r, g, b, a = overlay:getLightningColor()
  lurek.log.info(string.format("lightning rgba %.2f %.2f %.2f %.2f", r, g, b, a), "fx")
end

--@api-stub: Overlay:isFlashing
-- Returns true while a flash effect is in progress.
-- Use to suppress player input during a hit-stun flash.
do  -- Overlay:isFlashing
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 0, 0, 1, 0.2)
  if overlay:isFlashing() then
    lurek.log.debug("ignoring input during damage flash", "input")
  end
end

--@api-stub: Overlay:shake
-- Triggers a camera shake; duration defaults to 0.5 s.
-- Convenience wrapper; default duration is 0.5 s. Pair with audio to sell impacts.
do  -- Overlay:shake
  local overlay = lurek.effect.newOverlay()
  overlay:shake(12.0, 0.35)  -- explosion impact
  function lurek.process(dt) overlay:update(dt) end
end

--@api-stub: Overlay:isShaking
-- Returns true while a shake effect is in progress.
-- Read to drive secondary effects like camera blur during the shake interval.
do  -- Overlay:isShaking
  local overlay = lurek.effect.newOverlay()
  overlay:shake(6.0, 0.25)
  if overlay:isShaking() then
    lurek.log.debug("camera shaking", "fx")
  end
end

--@api-stub: Overlay:isFading
-- Returns true while a fade effect is in progress.
-- Branch on it to chain into a scene change once the fade completes.
do  -- Overlay:isFading
  local overlay = lurek.effect.newOverlay()
  overlay:fade(0, 0, 0, 1, 0.6)
  function lurek.process(dt)
    overlay:update(dt)
    if not overlay:isFading() then lurek.log.debug("fade done", "fx") end
  end
end

--@api-stub: Overlay:render
-- Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
-- Call inside lurek.render_ui after world geometry; emits the overlay's screen-space passes.
do  -- Overlay:render
  local overlay = lurek.effect.newOverlay()
  function lurek.render_ui()
    overlay:render()
  end
end

--@api-stub: Overlay:drawToImage
-- Renders the effect state (flash, fade, effects) to a CPU ImageData.
-- Returns a CPU ImageData of the overlay state; useful for screenshots or for offscreen compositing.
do  -- Overlay:drawToImage
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 1.0)
  local img = overlay:drawToImage(640, 360)
  lurek.log.info("overlay snapshot taken", "fx")
end

--@api-stub: Overlay:setCustomShader
-- Assigns a custom shader name to the effect, or clears it when `nil` is passed.
-- Pass a shader name registered via lurek.render, or nil to clear the override.
do  -- Overlay:setCustomShader
  local overlay = lurek.effect.newOverlay()
  overlay:setCustomShader("shaders/post_grade.wgsl")
  -- overlay:setCustomShader(nil)  -- to revert later
end

--@api-stub: Overlay:getWater
-- Returns a table describing the current water overlay state.
-- Returns a table of all water-overlay fields (enabled, amplitude, frequency, speed, tint, depth, time).
do  -- Overlay:getWater
  local overlay = lurek.effect.newOverlay()
  local w = overlay:getWater()
  lurek.log.info("water enabled=" .. tostring(w.enabled) .. " amp=" .. w.amplitude, "fx")
end

--@api-stub: Overlay:type
-- Returns the type name of this object ("Overlay").
-- Type-check before passing the overlay into a generic render helper.
do  -- Overlay:type
  local overlay = lurek.effect.newOverlay()
  assert(overlay:type() == "Overlay", "expected Overlay userdata")
end

--@api-stub: Overlay:typeOf
-- Returns true if this object is of the given type ("Object" or "Overlay").
-- Returns true for 'Overlay' or 'Object'; useful in dispatch tables.
do  -- Overlay:typeOf
  local overlay = lurek.effect.newOverlay()
  if overlay:typeOf("Object") then
    lurek.log.debug("overlay is an Object", "fx")
  end
end

-- ── mlua methods ──

--@api-stub: mlua:play
-- Starts the transition playing forward (scene fades/wipes out).
-- Starts the transition forward (scene fades/wipes out); call once when leaving the current scene.
do  -- mlua:play
  local trans = lurek.effect.newTransition("fade", 0.6, {0, 0, 0, 1})
  trans:play()
  function lurek.process(dt) trans:update(dt) end
end

--@api-stub: mlua:reverse
-- Starts the transition in reverse (scene fades/wipes in).
-- Plays the transition in reverse so the scene fades/wipes back IN; useful for the post-load reveal.
do  -- mlua:reverse
  local trans = lurek.effect.newTransition("iris", 0.5)
  trans:reverse()
  function lurek.process(dt) trans:update(dt) end
end

--@api-stub: mlua:update
-- Advances the transition by `dt` seconds.
-- Advances by dt seconds and returns true while still running; call once per frame in lurek.process.
do  -- mlua:update
  local trans = lurek.effect.newTransition("dissolve", 0.8)
  trans:play()
  function lurek.process(dt)
    if not trans:update(dt) then lurek.log.debug("transition complete", "fx") end
  end
end

--@api-stub: mlua:progress
-- Returns the fractional progress `[0, 1]` of the transition, taking.
-- Returns 0..1; use to lerp other animations in lockstep with the transition.
do  -- mlua:progress
  local trans = lurek.effect.newTransition("wipe", 1.0)
  trans:play()
  function lurek.process(dt)
    trans:update(dt)
    lurek.log.debug(string.format("trans p=%.2f", trans:progress()), "fx")
  end
end

--@api-stub: mlua:isActive
-- Returns `true` while the transition is running.
-- Branch on it to suppress player input or to hold the new scene's update logic until the transition finishes.
do  -- mlua:isActive
  local trans = lurek.effect.newTransition("fade", 0.5)
  trans:play()
  if trans:isActive() then
    lurek.log.debug("transition in progress — pausing input", "input")
  end
end

--@api-stub: mlua:isDone
-- Returns `true` after the transition has completed.
-- Use to chain into the next scene-load step once the transition finishes.
do  -- mlua:isDone
  local trans = lurek.effect.newTransition("fade", 0.4)
  trans:play()
  function lurek.process(dt)
    trans:update(dt)
    if trans:isDone() then lurek.log.info("ready for next scene", "scene") end
  end
end

--@api-stub: mlua:kind
-- Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,.
-- Returns one of 'fade', 'wipe', 'iris_wipe', 'dissolve'; use for serialising the transition type.
do  -- mlua:kind
  local trans = lurek.effect.newTransition("dissolve", 0.5)
  lurek.log.info("transition kind=" .. trans:kind(), "fx")
end

--@api-stub: mlua:color
-- Returns the fill color as four numbers: `r, g, b, a`.
-- Multi-return r,g,b,a; useful when you want to draw a matching tint behind UI during the transition.
do  -- mlua:color
  local trans = lurek.effect.newTransition("fade", 0.5, {0.05, 0.0, 0.1, 1.0})
  local r, g, b, a = trans:color()
  lurek.log.info(string.format("trans color %.2f %.2f %.2f %.2f", r, g, b, a), "fx")
end

--@api-stub: mlua:setColor
-- Updates the fill color from `{r, g, b, a?}`.
-- Pass a {r,g,b,a?} table; alpha defaults to 1.0. Change colour mid-game to match the destination scene.
do  -- mlua:setColor
  local trans = lurek.effect.newTransition("fade", 0.5)
  trans:setColor({0.0, 0.0, 0.0, 1.0})  -- fade to black
end

--@api-stub: mlua:type
-- Type.
-- Type-check before passing across module boundaries; the value is 'ScreenTransition'.
do  -- mlua:type
  local trans = lurek.effect.newTransition("wipe", 0.5)
  assert(trans:type() == "ScreenTransition", "expected ScreenTransition userdata")
end

--@api-stub: mlua:typeOf
-- Type of.
-- Returns true for 'ScreenTransition' or 'Object'; check the parent class in generic dispatch code.
do  -- mlua:typeOf
  local trans = lurek.effect.newTransition("fade", 0.5)
  if trans:typeOf("Object") then
    lurek.log.debug("transition inherits Object", "fx")
  end
end

