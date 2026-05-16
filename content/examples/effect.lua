-- content/examples/effect.lua
-- lurek.effect API examples.
-- Run: cargo run -- content/examples/effect.lua

--@api-stub: lurek.effect.newEffect
-- Creates a built-in post-processing effect by type name
do
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setThreshold(0.6)
  bloom:setIntensity(1.5)
  lurek.log.info("bloom built-in=" .. tostring(bloom:isBuiltIn()), "fx")
end

--@api-stub: lurek.effect.newCustomEffect
-- Creates a custom post-processing effect that references an existing shader id
do
  local shader_id = 7  -- shader handle created during setup
  local glitch = lurek.effect.newCustomEffect(shader_id)
  glitch:setParameter("intensity", 0.4)
  lurek.log.info("custom fx built-in=" .. tostring(glitch:isBuiltIn()), "fx")
end

--@api-stub: lurek.effect.newStack
-- Creates a post-processing stack using optional dimensions or the current window size
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))
  lurek.log.info("stack ready w=" .. stack:getWidth() .. " h=" .. stack:getHeight(), "fx")
end

--@api-stub: lurek.effect.newPresetStack
-- Creates a named preset post-processing stack with optional dimensions
do
  local crt = lurek.effect.newPresetStack("retro_tv", 1280, 720)
  function lurek.draw()
    crt:beginCapture(); crt:endCapture(); crt:apply()
  end
end

--@api-stub: lurek.effect.newPass
-- Creates a custom post-processing pass from an existing shader id
do
  local shader_id = 3  -- shader handle created during setup
  local edge_pass = lurek.effect.newPass(shader_id)
  edge_pass:setParameter("threshold", 0.2)
  lurek.log.debug("pass enabled=" .. tostring(edge_pass:isEnabled()), "fx")
end

--@api-stub: lurek.effect.getEffectTypes
-- Returns all built-in post-processing effect type names
do
  local types = lurek.effect.getEffectTypes()
  for i, name in ipairs(types) do
    lurek.log.info("[" .. i .. "] " .. name, "fx-types")
  end
end

--@api-stub: lurek.effect.newImageEffect
-- Creates an image effect chain from no arguments, a type name and optional parameters, or a chain table
do
  local chain = lurek.effect.newImageEffect({
    { type = "blur", radius = 3.0 },
    { type = "vignette", strength = 0.4 },
  })
  lurek.log.info("image chain count=" .. chain:effectCount(), "fx")
end

--@api-stub: lurek.effect.newOverlay
-- Creates an overlay controller for screen effects using optional dimensions
do
  local overlay = lurek.effect.newOverlay(1280, 720)
  overlay:setWeather("rain")
  overlay:setWeatherEnabled(true)
  function lurek.process(dt) overlay:update(dt) end
end

--@api-stub: lurek.effect.newTransition
-- Creates a timed screen transition with optional kind, duration, and color
do
  local trans = lurek.effect.newTransition("wipe", 0.75, {0, 0, 0, 1})
  trans:play()
  function lurek.process(dt)
    if trans:update(dt) then lurek.log.debug("trans p=" .. trans:progress(), "fx") end
  end
end

--@api-stub: lurek.effect.setShaderErrorDisplay
-- Enables or disables renderer shader error display overlays
do
  local in_dev = true
  lurek.effect.setShaderErrorDisplay(in_dev)
  lurek.log.info("shader err display=" .. tostring(in_dev), "fx-dev")
end

--@api-stub: lurek.effect.getShaderErrorDisplay
-- Returns whether renderer shader error display overlays are enabled
do
  if lurek.effect.getShaderErrorDisplay() then
    lurek.log.warn("dev shader error overlay is ON â€” disable for shipping", "fx-dev")
  end
end

-- PostFxEffect methods

--@api-stub: PostFxEffect:getTypeName
-- Returns the type name of this post fx effect.
do
  local eff = lurek.effect.newEffect("crt")
  local name = eff:getTypeName()
  lurek.log.info("active fx: " .. name, "fx")
end

--@api-stub: PostFxEffect:isBuiltIn
-- Returns true if this post fx effect built in.
do
  local eff = lurek.effect.newEffect("vignette")
  if eff:isBuiltIn() then
    lurek.log.info("safe to serialise '" .. eff:getTypeName() .. "' by name", "fx")
  end
end

--@api-stub: PostFxEffect:isEnabled
-- Returns true if this post fx effect is currently enabled.
do
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setEnabled(false)
  if not bloom:isEnabled() then
    lurek.log.debug("bloom currently muted", "fx")
  end
end

--@api-stub: PostFxEffect:setEnabled
-- Sets whether this post fx effect is enabled and accepts input.
do
  local crt = lurek.effect.newEffect("crt")
  local low_quality = true
  crt:setEnabled(not low_quality)
end

--@api-stub: PostFxEffect:setParameter
-- Sets the parameter of this post fx effect.
do
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setParameter("threshold", 0.5)
  bloom:setParameter("intensity", 1.2)
  lurek.log.debug("bloom configured", "fx")
end

--@api-stub: PostFxEffect:hasParameter
-- Returns true if this post fx effect has a parameter.
do
  local eff = lurek.effect.newEffect("crt")
  if eff:hasParameter("scanline_strength") then
    eff:setParameter("scanline_strength", 0.7)
  end
end

--@api-stub: PostFxEffect:getParameterNames
-- Returns the parameter names of this post fx effect.
do
  local eff = lurek.effect.newEffect("colourgrade")
  for _, name in ipairs(eff:getParameterNames()) do
    lurek.log.info("colourgrade param: " .. name, "fx-edit")
  end
end

--@api-stub: PostFxEffect:getEffectType
-- Returns the effect type of this post fx effect.
do
  local eff = lurek.effect.newEffect("sepia")
  local kind = eff:getEffectType()
  lurek.log.info("kind=" .. kind, "fx")
end

--@api-stub: PostFxEffect:getType
-- Returns the type of this post fx effect.
do
  local eff = lurek.effect.newEffect("invert")
  if eff:getType() == "invert" then
    lurek.log.debug("invert pass detected", "fx")
  end
end

--@api-stub: PostFxEffect:type
-- Returns the Lua-visible type name string for this post fx effect handle.
do
  local eff = lurek.effect.newEffect("bloom")
  lurek.log.debug("effect type: " .. eff:type(), "fx")
end

--@api-stub: PostFxEffect:typeOf
-- Returns true if this post fx effect handle matches the given type name string.
do
  local eff = lurek.effect.newEffect("blur")
  if eff:typeOf("Object") then
    lurek.log.debug("eff inherits from Object", "fx")
  end
end

--@api-stub: PostFxEffect:setThreshold
-- Sets the threshold of this post fx effect.
do
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setThreshold(0.75)
  lurek.log.debug("bloom threshold set", "fx")
end

--@api-stub: PostFxEffect:setIntensity
-- Sets the intensity of this post fx effect.
do
  local godrays = lurek.effect.newEffect("godrays")
  godrays:setIntensity(1.4)
end

--@api-stub: PostFxEffect:setRadius
-- Sets the radius of this post fx effect.
do
  local blur = lurek.effect.newEffect("blur")
  blur:setRadius(4.0)
end

--@api-stub: PostFxEffect:setStrength
-- Sets the strength of this post fx effect.
do
  local vig = lurek.effect.newEffect("vignette")
  local from_slider = 0.6
  vig:setStrength(math.max(0.0, math.min(1.0, from_slider)))
end

--@api-stub: PostFxEffect:setScanlineStrength
-- Sets the scanline strength of this post fx effect.
do
  local crt = lurek.effect.newEffect("crt")
  crt:setScanlineStrength(0.35)
  crt:setIntensity(1.0)
end

--@api-stub: PostFxEffect:setOffset
-- Sets the offset of this post fx effect.
do
  local chroma = lurek.effect.newEffect("chromatic")
  chroma:setOffset(2.0)
end

--@api-stub: PostFxEffect:setBrightness
-- Sets the brightness of this post fx effect.
do
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setBrightness(0.05)
end

--@api-stub: PostFxEffect:setContrast
-- Sets the contrast of this post fx effect.
do
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setContrast(1.15)
end

--@api-stub: PostFxEffect:setSaturation
-- Sets the saturation of this post fx effect.
do
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setSaturation(0.7)  -- desaturated mood
end

-- PostFxStack methods

--@api-stub: PostFxStack:add
-- Adds a  to this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))
  lurek.log.info("stack size=" .. stack:getEffectCount(), "fx")
end

--@api-stub: PostFxStack:remove
-- Removes a  from this post fx stack.
do
  local stack = lurek.effect.newStack()
  local crt = lurek.effect.newEffect("crt")
  stack:add(crt)
  local removed = stack:remove(crt)
  lurek.log.debug("crt removed=" .. tostring(removed), "fx")
end

--@api-stub: PostFxStack:isEnabled
-- Returns true if this post fx stack is currently enabled.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  if stack:isEnabled(1) then
    lurek.log.debug("slot 1 active", "fx")
  end
end

--@api-stub: PostFxStack:getEffectCount
-- Returns the number of effect items in this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("crt"))
  for i = 1, stack:getEffectCount() do
    local effect = assert(stack:getEffect(i))
    lurek.log.info("slot " .. i .. " = " .. effect:getTypeName(), "fx")
  end
end

--@api-stub: PostFxStack:getEffect
-- Returns the effect of this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("vignette"))
  local first = stack:getEffect(1)
  if first then first:setStrength(0.8) end
end

--@api-stub: PostFxStack:getEnabledEffects
-- Returns the enabled effects of this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  for _, eff in ipairs(stack:getEnabledEffects()) do
    lurek.log.debug("enabled: " .. eff:getTypeName(), "fx")
  end
end

--@api-stub: PostFxStack:getWidth
-- Returns the width of this post fx stack.
do
  local stack = lurek.effect.newStack(1920, 1080)
  if stack:getWidth() ~= 1920 then
    lurek.log.warn("stack width drift: " .. stack:getWidth(), "fx")
  end
end

--@api-stub: PostFxStack:getHeight
-- Returns the height of this post fx stack.
do
  local stack = lurek.effect.newStack(1280, 720)
  if stack:getHeight() < 480 then
    lurek.log.warn("stack height too small for HUD layout", "fx")
  end
end

--@api-stub: PostFxStack:getDimensions
-- Returns the dimensions of this post fx stack.
do
  local stack = lurek.effect.newStack()
  local w, h = stack:getDimensions()
  lurek.log.info("stack target = " .. w .. "x" .. h, "fx")
end

--@api-stub: PostFxStack:resize
-- Performs the resize operation on this post fx stack.
do
  local stack = lurek.effect.newStack(800, 600)
  local new_w, new_h = 1600, 900
  stack:resize(new_w, new_h)
  lurek.log.info("stack resized to " .. new_w .. "x" .. new_h, "fx")
end

--@api-stub: PostFxStack:len
-- Performs the len operation on this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  lurek.log.debug("stack len=" .. stack:len(), "fx")
end

--@api-stub: PostFxStack:isEmpty
-- Returns true if this post fx stack contains no items.
do
  local stack = lurek.effect.newStack()
  if stack:isEmpty() then
    lurek.log.debug("post-fx pipeline empty â€” skipping capture", "fx")
  end
end

--@api-stub: PostFxStack:clear
-- Clears all items from this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("crt"))
  stack:clear()
  lurek.log.info("pipeline cleared, count=" .. stack:getEffectCount(), "fx")
end

--@api-stub: PostFxStack:dedup
-- Performs the dedup operation on this post fx stack.
do
  local stack = lurek.effect.newStack()
  local bloom = lurek.effect.newEffect("bloom")
  stack:add(bloom); stack:add(bloom)
  local removed = stack:dedup()
  lurek.log.info("dedup removed " .. tostring(removed) .. " duplicate slot(s)", "fx")
end

--@api-stub: PostFxStack:isCapturing
-- Returns true if this post fx stack capturing.
do
  local stack = lurek.effect.newStack()
  function lurek.draw()
    stack:beginCapture()
    assert(stack:isCapturing(), "post-fx capture should be active here")
    stack:endCapture(); stack:apply()
  end
end

--@api-stub: PostFxStack:beginCapture
-- Performs the begin capture operation on this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  function lurek.draw()
    stack:beginCapture()
    -- scene draws happen here
    stack:endCapture(); stack:apply()
  end
end

--@api-stub: PostFxStack:endCapture
-- Performs the end capture operation on this post fx stack.
do
  local stack = lurek.effect.newStack()
  function lurek.draw()
    stack:beginCapture()
    stack:endCapture()
    stack:apply()
  end
end

--@api-stub: PostFxStack:apply
-- Applies  to this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  function lurek.draw()
    stack:beginCapture(); stack:endCapture()
    stack:apply()
  end
end

--@api-stub: PostFxStack:type
-- Returns the Lua-visible type name string for this post fx stack handle.
do
  local stack = lurek.effect.newStack()
  if stack:type() == "PostFxStack" then
    lurek.log.debug("got a real post-fx stack", "fx")
  end
end

--@api-stub: PostFxStack:typeOf
-- Returns true if this post fx stack handle matches the given type name string.
do
  local stack = lurek.effect.newStack()
  assert(stack:typeOf("Object"), "PostFxStack should inherit Object")
end

--@api-stub: PostFxStack:setFeedback
-- Sets the feedback of this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:setFeedback(0.85)  -- strong trail for a dream sequence
  lurek.log.info("feedback=" .. stack:getFeedback(), "fx")
end

--@api-stub: PostFxStack:getFeedback
-- Returns the feedback of this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:setFeedback(2.0)  -- will be clamped
  lurek.log.info("clamped feedback=" .. stack:getFeedback(), "fx")
end

--@api-stub: PostFxStack:clearFeedback
-- Clears all feedback items from this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:setFeedback(0.6)
  stack:clearFeedback()
  lurek.log.debug("feedback cleared=" .. stack:getFeedback(), "fx")
end

-- ImageEffect methods

--@api-stub: ImageEffect:addEffect
-- Adds a effect to this image effect.
do
  local chain = lurek.effect.newImageEffect()
  local blur = chain:addEffect("blur")
  blur:setRadius(2.5)
  lurek.log.info("chain size=" .. chain:effectCount(), "fx")
end

--@api-stub: ImageEffect:getEffect
-- Returns the effect of this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "vignette" }})
  local vig = chain:getEffect("vignette")
  if vig then vig:setStrength(0.5) end
end

--@api-stub: ImageEffect:removeEffect
-- Removes a effect from this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  local removed = chain:removeEffect("blur")
  lurek.log.debug("blur removed=" .. tostring(removed) .. " count=" .. chain:effectCount(), "fx")
end

--@api-stub: ImageEffect:clearEffects
-- Clears all effects items from this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "bloom" }})
  chain:clearEffects()
  assert(chain:effectCount() == 0, "chain should be empty")
end

--@api-stub: ImageEffect:clear
-- Clears all items from this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "crt" }})
  chain:clear()
  lurek.log.debug("chain cleared", "fx")
end

--@api-stub: ImageEffect:effectCount
-- Performs the effect count operation on this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  if chain:effectCount() > 0 then
    lurek.log.info("image chain has " .. chain:effectCount() .. " passes", "fx")
  end
end

--@api-stub: ImageEffect:getEffectCount
-- Returns the number of effect items in this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "sepia" }})
  lurek.log.debug("count=" .. chain:getEffectCount(), "fx")
end

--@api-stub: ImageEffect:clone
-- Performs the clone operation on this image effect.
do
  local base = lurek.effect.newImageEffect({{ type = "vignette", strength = 0.4 }})
  local night = base:clone()
  night:addEffect("colourgrade"):setBrightness(-0.1)
end

--@api-stub: ImageEffect:save
-- Saves the current state of this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "bloom" }})
  if chain:save() then
    lurek.log.debug("image chain save() acknowledged", "fx")
  end
end

--@api-stub: ImageEffect:type
-- Returns the Lua-visible type name string for this image effect handle.
do
  local chain = lurek.effect.newImageEffect()
  if chain:type() == "ImageEffect" then
    lurek.log.debug("per-image chain detected", "fx")
  end
end

--@api-stub: ImageEffect:typeOf
-- Returns true if this image effect handle matches the given type name string.
do
  local chain = lurek.effect.newImageEffect()
  assert(chain:typeOf("Object"), "ImageEffect should be an Object")
end

--@api-stub: ImageEffect:removeByIndex
-- Removes a by index from this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "crt" }})
  local removed = chain:removeByIndex(0)  -- removes the blur
  lurek.log.debug("by-index removed=" .. tostring(removed), "fx")
end

--@api-stub: ImageEffect:removeByName
-- Removes a by name from this image effect.
do
  local chain = lurek.effect.newImageEffect({{ type = "vignette" }, { type = "sepia" }})
  chain:removeByName("vignette")
  lurek.log.debug("after by-name remove count=" .. chain:effectCount(), "fx")
end

-- Overlay methods

--@api-stub: Overlay:update
-- Advances this overlay by the given delta time.
do
  local overlay = lurek.effect.newOverlay()
  function lurek.process(dt)
    overlay:update(dt)
  end
end

--@api-stub: Overlay:triggerLightning
-- Performs the trigger lightning operation on this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:triggerLightning()
  lurek.log.info("lightning fired alpha=" .. overlay:getLightningAlpha(), "weather")
end

--@api-stub: Overlay:getShakeOffset
-- Returns the shake offset of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:shake(8.0, 0.4)
  function lurek.draw()
    local ox, oy = overlay:getShakeOffset()
    lurek.log.debug("shake ox=" .. ox .. " oy=" .. oy, "shake")
  end
end

--@api-stub: Overlay:isActive
-- Returns true if this overlay is currently active.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isActive() then
    function lurek.draw() overlay:render() end
  end
end

--@api-stub: Overlay:clear
-- Clears all items from this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.5)
  overlay:clear()
  assert(not overlay:isFlashing(), "flash should be cancelled")
end

--@api-stub: Overlay:resize
-- Performs the resize operation on this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:resize(1920, 1080)
  lurek.log.info("overlay resized to " .. overlay:getWidth() .. "x" .. overlay:getHeight(), "fx")
end

--@api-stub: Overlay:getWidth
-- Returns the width of this overlay.
do
  local overlay = lurek.effect.newOverlay(1024, 768)
  lurek.log.debug("overlay w=" .. overlay:getWidth(), "fx")
end

--@api-stub: Overlay:getHeight
-- Returns the height of this overlay.
do
  local overlay = lurek.effect.newOverlay(1024, 768)
  lurek.log.debug("overlay h=" .. overlay:getHeight(), "fx")
end

--@api-stub: Overlay:getDimensions
-- Returns the dimensions of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  local w, h = overlay:getDimensions()
  lurek.log.info("overlay = " .. w .. "x" .. h, "fx")
end

--@api-stub: Overlay:getFlashAlpha
-- Returns the flash alpha of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.3)
  function lurek.process(dt)
    overlay:update(dt)
    if overlay:getFlashAlpha() > 0.5 then lurek.log.debug("flash peak", "fx") end
  end
end

--@api-stub: Overlay:getLightningAlpha
-- Returns the lightning alpha of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:triggerLightning()
  function lurek.process(dt)
    overlay:update(dt)
    local a = overlay:getLightningAlpha()
    if a > 0.0 then lurek.log.debug("lightning a=" .. a, "fx") end
  end
end

--@api-stub: Overlay:setAmbientEnabled
-- Sets whether this overlay is enabled and accepts input.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  overlay:setTimeOfDay(20.0)  -- evening
end

--@api-stub: Overlay:isAmbientEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isAmbientEnabled() then
    lurek.log.debug("ambient layer is live", "fx")
  end
end

--@api-stub: Overlay:getAmbientColor
-- Returns the ambient color of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  local r, g, b, a = overlay:getAmbientColor()
  lurek.log.info(string.format("ambient %.2f %.2f %.2f a=%.2f", r, g, b, a), "fx")
end

--@api-stub: Overlay:setTimeOfDay
-- Sets the time of day of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  overlay:setTimeOfDay(7.5)  -- early morning
end

--@api-stub: Overlay:getTimeOfDay
-- Returns the time of day of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setTimeOfDay(18.0)
  if overlay:getTimeOfDay() > 18.0 then
    lurek.log.info("dusk â€” enable street lamps", "world")
  end
end

--@api-stub: Overlay:setFogEnabled
-- Sets whether this overlay is enabled and accepts input.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  overlay:setFogDensity(0.4)
end

--@api-stub: Overlay:isFogEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if not overlay:isFogEnabled() then
    overlay:setFogEnabled(true)
  end
end

--@api-stub: Overlay:setFogDensity
-- Sets the fog density of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  local target = 0.6
  overlay:setFogDensity(target)
end

--@api-stub: Overlay:getFogDensity
-- Returns the fog density of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFogDensity(0.3)
  lurek.log.debug("fog density=" .. overlay:getFogDensity(), "fx")
end

--@api-stub: Overlay:getFogColor
-- Returns the fog color of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  local r, g, b = overlay:getFogColor()
  lurek.log.info(string.format("fog rgb %.2f %.2f %.2f", r, g, b), "fx")
end

--@api-stub: Overlay:setHeatHazeEnabled
-- Sets whether this overlay is enabled and accepts input.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeEnabled(true)
  overlay:setHeatHazeIntensity(0.5)
end

--@api-stub: Overlay:isHeatHazeEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isHeatHazeEnabled() then
    lurek.log.debug("heat haze on", "fx")
  end
end

--@api-stub: Overlay:setHeatHazeIntensity
-- Sets the heat haze intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeEnabled(true)
  local temp_c = 42
  overlay:setHeatHazeIntensity(math.min(1.0, math.max(0.0, (temp_c - 30) / 20)))
end

--@api-stub: Overlay:getHeatHazeIntensity
-- Returns the heat haze intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeIntensity(0.6)
  lurek.log.debug("heat haze i=" .. overlay:getHeatHazeIntensity(), "fx")
end

--@api-stub: Overlay:setVignetteEnabled
-- Sets whether this overlay is enabled and accepts input.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteEnabled(true)
  overlay:setVignetteStrength(0.55)
end

--@api-stub: Overlay:isVignetteEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isVignetteEnabled() then
    overlay:setVignetteStrength(0.7)
  end
end

--@api-stub: Overlay:setVignetteStrength
-- Sets the vignette strength of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteEnabled(true)
  overlay:setVignetteStrength(0.45)
end

--@api-stub: Overlay:getVignetteStrength
-- Returns the vignette strength of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteStrength(0.5)
  lurek.log.debug("vignette s=" .. overlay:getVignetteStrength(), "fx")
end

--@api-stub: Overlay:setFilmGrainEnabled
-- Sets whether this overlay is enabled and accepts input.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainEnabled(true)
  overlay:setFilmGrainIntensity(0.25)
end

--@api-stub: Overlay:isFilmGrainEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isFilmGrainEnabled() then
    lurek.log.debug("grain layer is live", "fx")
  end
end

--@api-stub: Overlay:setFilmGrainIntensity
-- Sets the film grain intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainEnabled(true)
  overlay:setFilmGrainIntensity(0.18)
end

--@api-stub: Overlay:getFilmGrainIntensity
-- Returns the film grain intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainIntensity(0.3)
  lurek.log.debug("grain i=" .. overlay:getFilmGrainIntensity(), "fx")
end

--@api-stub: Overlay:setCloudShadows
-- Sets the cloud shadows of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudCount(8)
end

--@api-stub: Overlay:isCloudShadowsEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isCloudShadowsEnabled() then
    overlay:setCloudOpacity(0.4)
  end
end

--@api-stub: Overlay:setCloudCount
-- Sets the cloud count of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudCount(12)
end

--@api-stub: Overlay:getCloudCount
-- Returns the number of cloud items in this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudCount(6)
  lurek.log.debug("clouds=" .. overlay:getCloudCount(), "fx")
end

--@api-stub: Overlay:setCloudSpeed
-- Sets the cloud speed of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudSpeed(40.0)
end

--@api-stub: Overlay:getCloudSpeed
-- Returns the cloud speed of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudSpeed(25.0)
  lurek.log.debug("cloud px/s=" .. overlay:getCloudSpeed(), "fx")
end

--@api-stub: Overlay:setCloudScale
-- Sets the cloud scale of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudScale(1.5)
end

--@api-stub: Overlay:getCloudScale
-- Returns the cloud scale of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudScale(0.8)
  lurek.log.debug("cloud scale=" .. overlay:getCloudScale(), "fx")
end

--@api-stub: Overlay:setCloudOpacity
-- Sets the cloud opacity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudOpacity(0.35)
end

--@api-stub: Overlay:getCloudOpacity
-- Returns the cloud opacity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudOpacity(0.4)
  if overlay:getCloudOpacity() > 0.3 then
    lurek.log.info("overcast skies", "weather")
  end
end

--@api-stub: Overlay:setWeatherEnabled
-- Sets whether this overlay is enabled and accepts input.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  overlay:setWeatherEnabled(true)
end

--@api-stub: Overlay:isWeatherEnabled
-- Returns true if this overlay is currently enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isWeatherEnabled() then
    lurek.log.debug("weather active = " .. overlay:getWeather(), "weather")
  end
end

--@api-stub: Overlay:setWeather
-- Sets the weather of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("snow")
  overlay:setWeatherEnabled(true)
  overlay:setWeatherIntensity(0.7)
end

--@api-stub: Overlay:getWeather
-- Returns the weather of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  lurek.log.info("current weather: " .. overlay:getWeather(), "weather")
end

--@api-stub: Overlay:setWeatherIntensity
-- Sets the weather intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  overlay:setWeatherIntensity(0.85)
end

--@api-stub: Overlay:getWeatherIntensity
-- Returns the weather intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeatherIntensity(0.5)
  lurek.log.debug("weather i=" .. overlay:getWeatherIntensity(), "weather")
end

--@api-stub: Overlay:setWindDirection
-- Sets the wind direction of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWindDirection(math.pi / 4)  -- down-right
  overlay:setWindSpeed(60.0)
end

--@api-stub: Overlay:getWindDirection
-- Returns the wind direction of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWindDirection(math.pi)
  lurek.log.debug("wind dir rad=" .. overlay:getWindDirection(), "weather")
end

--@api-stub: Overlay:setWindSpeed
-- Sets the wind speed of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWindSpeed(120.0)
  overlay:setCloudSpeed(60.0)
end

--@api-stub: Overlay:getWindSpeed
-- Returns the wind speed of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWindSpeed(80.0)
  lurek.log.debug("wind=" .. overlay:getWindSpeed(), "weather")
end

--@api-stub: Overlay:getLightningColor
-- Returns the lightning color of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  local r, g, b, a = overlay:getLightningColor()
  lurek.log.info(string.format("lightning rgba %.2f %.2f %.2f %.2f", r, g, b, a), "fx")
end

--@api-stub: Overlay:isFlashing
-- Returns true if this overlay flashing.
do
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 0, 0, 1, 0.2)
  if overlay:isFlashing() then
    lurek.log.debug("ignoring input during damage flash", "input")
  end
end

--@api-stub: Overlay:shake
-- Performs the shake operation on this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:shake(12.0, 0.35)  -- explosion impact
  function lurek.process(dt) overlay:update(dt) end
end

--@api-stub: Overlay:isShaking
-- Returns true if this overlay shaking.
do
  local overlay = lurek.effect.newOverlay()
  overlay:shake(6.0, 0.25)
  if overlay:isShaking() then
    lurek.log.debug("camera shaking", "fx")
  end
end

--@api-stub: Overlay:isFading
-- Returns true if this overlay fading.
do
  local overlay = lurek.effect.newOverlay()
  overlay:fade(0, 0, 0, 1, 0.6)
  function lurek.process(dt)
    overlay:update(dt)
    if not overlay:isFading() then lurek.log.debug("fade done", "fx") end
  end
end

--@api-stub: Overlay:render
-- Draws or renders this overlay to the current render target.
do
  local overlay = lurek.effect.newOverlay()
  function lurek.draw_ui()
    overlay:render()
  end
end

--@api-stub: Overlay:drawToImage
-- Draws or renders this overlay to the current render target.
do
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 1.0)
  local img = overlay:drawToImage(640, 360)
  lurek.log.info("overlay snapshot taken", "fx")
end

--@api-stub: Overlay:setCustomShader
-- Sets the custom shader of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCustomShader("shaders/post_grade.wgsl")
  -- overlay:setCustomShader(nil)  -- to revert later
end

--@api-stub: Overlay:getWater
-- Returns the water of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  local w = overlay:getWater()
  lurek.log.info("water enabled=" .. tostring(w.enabled) .. " amp=" .. w.amplitude, "fx")
end

--@api-stub: Overlay:type
-- Returns the Lua-visible type name string for this overlay handle.
do
  local overlay = lurek.effect.newOverlay()
  lurek.log.info("Overlay:type = " .. overlay:type(), "fx")
end

--@api-stub: Overlay:typeOf
-- Returns true if this overlay handle matches the given type name string.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:typeOf("Object") then
    lurek.log.debug("overlay is an Object", "fx")
  end
end

-- mlua methods

--@api-stub: mlua:play
-- Starts playback of on this mlua.
do
  local trans = lurek.effect.newTransition("fade", 0.6, {0, 0, 0, 1})
  trans:play()
  function lurek.process(dt) trans:update(dt) end
end

--@api-stub: mlua:reverse
-- Performs the reverse operation on this mlua.
do
  local trans = lurek.effect.newTransition("iris", 0.5)
  trans:reverse()
  function lurek.process(dt) trans:update(dt) end
end

--@api-stub: mlua:update
-- Advances this mlua by the given delta time.
do
  local trans = lurek.effect.newTransition("dissolve", 0.8)
  trans:play()
  function lurek.process(dt)
    if not trans:update(dt) then lurek.log.debug("transition complete", "fx") end
  end
end

--@api-stub: mlua:progress
-- Performs the progress operation on this mlua.
do
  local trans = lurek.effect.newTransition("wipe", 1.0)
  trans:play()
  function lurek.process(dt)
    trans:update(dt)
    lurek.log.debug(string.format("trans p=%.2f", trans:progress()), "fx")
  end
end

--@api-stub: mlua:isActive
-- Returns true if this mlua is currently active.
do
  local trans = lurek.effect.newTransition("fade", 0.5)
  trans:play()
  if trans:isActive() then
    lurek.log.debug("transition in progress â€” pausing input", "input")
  end
end

--@api-stub: mlua:isDone
-- Returns true if this mlua has completed its task.
do
  local trans = lurek.effect.newTransition("fade", 0.4)
  trans:play()
  function lurek.process(dt)
    trans:update(dt)
    if trans:isDone() then lurek.log.info("ready for next scene", "scene") end
  end
end

--@api-stub: mlua:kind
-- Performs the kind operation on this mlua.
do
  local trans = lurek.effect.newTransition("dissolve", 0.5)
  lurek.log.info("transition kind=" .. trans:kind(), "fx")
end

--@api-stub: mlua:color
-- Performs the color operation on this mlua.
do
  local trans = lurek.effect.newTransition("fade", 0.5, {0.05, 0.0, 0.1, 1.0})
  local r, g, b, a = trans:color()
  lurek.log.info(string.format("trans color %.2f %.2f %.2f %.2f", r, g, b, a), "fx")
end

--@api-stub: mlua:setColor
-- Sets the color of this mlua.
do
  local trans = lurek.effect.newTransition("fade", 0.5)
  trans:setColor({0.0, 0.0, 0.0, 1.0})  -- fade to black
end

--@api-stub: mlua:type
-- Returns the Lua-visible type name string for this mlua handle.
do
  local trans = lurek.effect.newTransition("wipe", 0.5)
  lurek.log.info("ScreenTransition:type = " .. tostring(trans and trans:type() or "nil"), "fx")
end

--@api-stub: mlua:typeOf
-- Returns true if this mlua handle matches the given type name string.
do
  local trans = lurek.effect.newTransition("fade", 0.5)
  if trans:typeOf("Object") then
    lurek.log.debug("transition inherits Object", "fx")
  end
end


--     struct PostFxParams { p: array<vec4<f32>, 4>, }
--     @group(0) @binding(2) var<uniform> params: PostFxParams;

--     // p[3] auto-uniform layout when enableAutoUniforms() is active:
--     //   p[3].x = total elapsed time (seconds)
--     //   p[3].y = frame count (cast to f32)
--     //   p[3].z = render target width (pixels)
--     //   p[3].w = render target height (pixels)

--     @fragment
--     fn fs_main(
--         @location(0) color: vec4<f32>,
--         @location(1) uv: vec2<f32>
--     ) -> @location(0) vec4<f32> {
--         let time = params.p[3].x;
--         let wave = sin(uv.x * 20.0 + time * 3.0) * 0.005;
--         let distorted_uv = vec2<f32>(uv.x, uv.y + wave);
--         return textureSample(t_src, s_src, distorted_uv);
--     }
--   ]]

--   lurek.render.newShader(wgsl)
--   local shader_id = 1
--   local wave_effect = lurek.effect.newCustomEffect(shader_id)
--   wave_effect:enableAutoUniforms()
--   lurek.log.info("auto_uniforms=" .. tostring(wave_effect:isAutoUniforms()), "fx")

--   local stack = lurek.effect.newStack(1280, 720)
--   stack:add(wave_effect)

--   function lurek.draw()
--     stack:beginCapture()
    -- draw scene here
--     stack:endCapture()
--     stack:apply()
--   end
-- end

--@api-stub: PostFxEffect:enableAutoUniforms
-- Performs the enable auto uniforms operation on this post fx effect.
do
  local fx = lurek.effect.newCustomEffect(0)
  fx:enableAutoUniforms()
  lurek.log.debug("enableAutoUniforms called", "fx")
end

--@api-stub: PostFxEffect:isAutoUniforms
-- Returns true if this post fx effect auto uniforms.
do
  local fx = lurek.effect.newCustomEffect(0)
  fx:enableAutoUniforms()
  lurek.log.debug("isAutoUniforms=" .. tostring(fx:isAutoUniforms()), "fx")
end

--@api-stub: PostFxEffect:disableAutoUniforms
-- Performs the disable auto uniforms operation on this post fx effect.
do
  local fx = lurek.effect.newCustomEffect(0)
  fx:enableAutoUniforms()
  fx:disableAutoUniforms()
  lurek.log.debug("auto_uniforms=" .. tostring(fx:isAutoUniforms()), "fx")
end

--@api-stub: Overlay:fade
-- Performs the fade operation on this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:fade(0, 0, 0, 1.0, 1.0)
  lurek.log.info("fade started", "effect")
end

--@api-stub: Overlay:flash
-- Performs the flash operation on this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:flash(0.15, 1, 1, 1, 1)
  lurek.log.info("flash triggered", "effect")
end

--@api-stub: PostFxEffect:getParameter
-- Returns the parameter of this post fx effect.
do
  local stack = lurek.effect.newStack(800, 600)
  stack:add(lurek.effect.newEffect("bloom"))
  local effect = assert(stack:getEffect(1))
  local intensity = effect:getParameter("intensity")
  lurek.log.info("bloom intensity: " .. tostring(intensity), "effect")
end

--@api-stub: PostFxStack:insert
-- Performs the insert operation on this post fx stack.
do
  local stack = lurek.effect.newStack(800, 600)
  stack:add(lurek.effect.newEffect("crt"))
  stack:insert(1, lurek.effect.newEffect("vignette"))
  lurek.log.info("stack count: " .. stack:getEffectCount(), "effect")
end

--@api-stub: Overlay:setAmbientColor
-- Sets the ambient color of this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setAmbientEnabled(true)
  overlay:setAmbientColor(0.1, 0.1, 0.3, 0.6)
  lurek.log.info("ambient colour set", "effect")
end

--@api-stub: PostFxStack:setEnabled
-- Sets whether this post fx stack is enabled and accepts input.
do
  local stack = lurek.effect.newStack(800, 600)
  stack:add(lurek.effect.newEffect("bloom"))
  stack:setEnabled(1, false)
  lurek.log.info("stack enabled: " .. tostring(stack:isEnabled(1)), "effect")
end

--@api-stub: Overlay:setFogColor
-- Sets the fog color of this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setFogEnabled(true)
  overlay:setFogColor(0.6, 0.6, 0.7)
  lurek.log.info("fog colour set", "effect")
end

--@api-stub: Overlay:setLightningColor
-- Sets the lightning color of this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setLightningColor(0.9, 0.95, 1.0)
  lurek.log.info("lightning colour set", "effect")
end

--@api-stub: Overlay:setWater
-- Sets the water of this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setWater(0.02, 12.0, 1.5)
  lurek.log.info("water effect set", "effect")
end

--@api-stub: Overlay:setWaterTint
-- Sets the water tint of this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setWater(0.02, 12.0, 1.5)
  overlay:setWaterTint(0.2, 0.6, 0.8, 0.5)
  lurek.log.info("water tint set", "effect")
end

--@api-stub: Overlay:triggerFade
-- Performs the trigger fade operation on this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:triggerFade(0, 0, 0, 1.0, 1.5)
  lurek.log.info("fade out triggered", "effect")
end

--@api-stub: Overlay:triggerFlash
-- Performs the trigger flash operation on this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:triggerFlash(1.0, 0.0, 0.0, 0.8, 0.12)
  lurek.log.info("flash triggered", "effect")
end

--@api-stub: Overlay:triggerShake
-- Performs the trigger shake operation on this overlay.
do
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:triggerShake(8.0, 0.4)
  lurek.log.info("shake triggered", "effect")
end

-- -----------------------------------------------------------------------------
-- LScreenTransition methods
-- -----------------------------------------------------------------------------

--@api-stub: LScreenTransition:play
-- Starts this screen transition forward from its current state
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:play()
  lurek.log.info("transition playing, active=" .. tostring(tr:isActive()), "effect")
end
--@api-stub: LScreenTransition:reverse
-- Starts this screen transition in reverse from its current state
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:reverse()
  lurek.log.info("transition reversed, active=" .. tostring(tr:isActive()), "effect")
end
--@api-stub: LScreenTransition:update
-- Advances this transition timer and returns whether it remains active
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:play()
  local running = tr:update(0.1)
  lurek.log.info("still_active=" .. tostring(running), "effect")
end
--@api-stub: LScreenTransition:progress
-- Returns normalized transition progress
do
  local tr = lurek.effect.newTransition("fade", 1.0, {0, 0, 0, 1})
  tr:play()
  tr:update(0.25)
  lurek.log.info("progress=" .. tr:progress(), "effect")
end
--@api-stub: LScreenTransition:isActive
-- Returns whether the transition is currently active
do
  local tr = lurek.effect.newTransition("wipe", 0.4, {0, 0, 0, 1})
  lurek.log.info("before play: " .. tostring(tr:isActive()), "effect")
  tr:play()
  lurek.log.info("after play: " .. tostring(tr:isActive()), "effect")
end
--@api-stub: LScreenTransition:isDone
-- Returns whether the transition has finished
do
  local tr = lurek.effect.newTransition("fade", 0.1, {0, 0, 0, 1})
  tr:play()
  while not tr:isDone() do
    tr:update(0.05)
  end
  lurek.log.info("transition is done", "effect")
end
--@api-stub: LScreenTransition:kind
-- Returns the transition kind name
do
  local tr = lurek.effect.newTransition("iris_wipe", 0.5, {0, 0, 0, 1})
  lurek.log.info("kind=" .. tr:kind(), "effect")
end
--@api-stub: LScreenTransition:color
-- Returns the transition RGBA color
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0.1, 0.2, 0.3, 1.0})
  local r, g, b, a = tr:color()
  lurek.log.info("color r=" .. r .. " g=" .. g .. " b=" .. b, "effect")
end
--@api-stub: LScreenTransition:setColor
-- Sets the transition RGBA color from a numeric array table
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:setColor({1.0, 1.0, 1.0, 1.0})   -- switch to white flash
  local r, g, b = tr:color()
  lurek.log.info("updated color r=" .. r .. " g=" .. g, "effect")
end
--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name for this transition handle
do
  local screen_transition_obj = lurek.effect.newTransition(nil, nil, nil)
  local t = screen_transition_obj:type()
  lurek.log.info("LScreenTransition:type = " .. t, "effect")
end
--@api-stub: LScreenTransition:typeOf
-- Returns whether this transition handle matches a supported type name
do
  local screen_transition_obj = lurek.effect.newTransition(nil, nil, nil)
  lurek.log.info("is LScreenTransition: " .. tostring(screen_transition_obj:typeOf("LScreenTransition")), "effect")
  lurek.log.info("is wrong: " .. tostring(screen_transition_obj:typeOf("Unknown")), "effect")
end

--@api-stub: LOverlay:pullAmbientFromLight
-- Copies ambient color from the shared light world into this overlay
do
  local overlay = lurek.effect.newOverlay()
  overlay:pullAmbientFromLight()
end

--@api-stub: LOverlay:pushAmbientToLight
-- Copies this overlay ambient color into the shared light world
do
  local overlay = lurek.effect.newOverlay()
  overlay:pushAmbientToLight()
end

--@api-stub: LOverlay:syncAmbientWithLight
-- Resolves overlay and light ambient colors using a named mode and writes both stores
do
  local overlay = lurek.effect.newOverlay()
  overlay:syncAmbientWithLight("avg")
end
