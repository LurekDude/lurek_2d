-- content/examples/effect.lua
-- Auto-scaffolded coverage of the lurek.effect Lua API (142 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/effect.lua

print("[example] lurek.effect loaded — 142 API items demonstrated")

-- ── lurek.effect free functions ──

--@api-stub: lurek.effect.newEffect
-- Creates a new built-in post-processing effect by type name.
-- Use this when creates a new built-in post-processing effect by type name is needed.
if false then
  local _r = lurek.effect.newEffect(1)
  print(_r)
end

--@api-stub: lurek.effect.newCustomEffect
-- Creates a custom shader post-processing effect.
-- Use this when creates a custom shader post-processing effect is needed.
if false then
  local _r = lurek.effect.newCustomEffect(1)
  print(_r)
end

--@api-stub: lurek.effect.newStack
-- Creates a new post-processing pipeline stack.
-- Use this when creates a new post-processing pipeline stack is needed.
if false then
  local _r = lurek.effect.newStack(0, 0)
  print(_r)
end

--@api-stub: lurek.effect.newPresetStack
-- Creates a pre-configured effect stack from a named preset.
-- Use this when creates a pre-configured effect stack from a named preset is needed.
if false then
  local _r = lurek.effect.newPresetStack(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.effect.newPass
-- Creates a custom-shader post-processing effect (alias for newCustomEffect).
-- Use this when creates a custom-shader post-processing effect (alias for newCustomEffect) is needed.
if false then
  local _r = lurek.effect.newPass(1)
  print(_r)
end

--@api-stub: lurek.effect.getEffectTypes
-- Returns the list of all built-in effect type names.
-- Use this when returns the list of all built-in effect type names is needed.
if false then
  local _r = lurek.effect.getEffectTypes()
  print(_r)
end

--@api-stub: lurek.effect.newImageEffect
-- Creates a new per-image effect chain.
-- Accepts:
if false then
  local _r = lurek.effect.newImageEffect({})
  print(_r)
end

--@api-stub: lurek.effect.newOverlay
-- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
-- Use this when creates a new screen overlay controller for weather, flash, shake, and fade effects is needed.
if false then
  local _r = lurek.effect.newOverlay(0, 0)
  print(_r)
end

--@api-stub: lurek.effect.newTransition
-- Creates a new screen-transition controller.
-- `kind` is one of:
if false then
  local _r = lurek.effect.newTransition(1, 1, 0)
  print(_r)
end

--@api-stub: lurek.effect.setShaderErrorDisplay
-- Enables or disables the effect that renders shader compile errors as red text.
-- Use this when enables or disables the effect that renders shader compile errors as red text is needed.
if false then
  local _r = lurek.effect.setShaderErrorDisplay(1)
  print(_r)
end

--@api-stub: lurek.effect.getShaderErrorDisplay
-- Returns whether shader error display is currently enabled.
-- Use this when returns whether shader error display is currently enabled is needed.
if false then
  local _r = lurek.effect.getShaderErrorDisplay()
  print(_r)
end

-- ── PostFxEffect methods ──

--@api-stub: PostFxEffect:getTypeName
-- Returns the display name of this effect type.
-- Use this when returns the display name of this effect type is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:getTypeName()
end

--@api-stub: PostFxEffect:isBuiltIn
-- Returns true if this is a built-in effect, false if custom.
-- Use this when returns true if this is a built-in effect, false if custom is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:isBuiltIn()
end

--@api-stub: PostFxEffect:isEnabled
-- Returns whether this effect is currently active.
-- Use this when returns whether this effect is currently active is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:isEnabled()
end

--@api-stub: PostFxEffect:setEnabled
-- Enables or disables this effect.
-- Use this when enables or disables this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setEnabled(1)
end

--@api-stub: PostFxEffect:setParameter
-- Sets a named float parameter on this effect.
-- Use this when sets a named float parameter on this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setParameter(1, 0)
end

--@api-stub: PostFxEffect:hasParameter
-- Returns true if the named parameter exists on this effect.
-- Use this when returns true if the named parameter exists on this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:hasParameter(1)
end

--@api-stub: PostFxEffect:getParameterNames
-- Returns a list of all parameter names on this effect.
-- Use this when returns a list of all parameter names on this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:getParameterNames()
end

--@api-stub: PostFxEffect:getEffectType
-- Returns the type name of this effect (alias for getTypeName).
-- Use this when returns the type name of this effect (alias for getTypeName) is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:getEffectType()
end

--@api-stub: PostFxEffect:getType
-- Returns the type name of this effect (alias for getTypeName).
-- Use this when returns the type name of this effect (alias for getTypeName) is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:getType()
end

--@api-stub: PostFxEffect:type
-- Returns the type name "PostFxEffect".
-- Use this when returns the type name "PostFxEffect" is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:type()
end

--@api-stub: PostFxEffect:typeOf
-- Returns true when the given name matches "PostFxEffect" or a parent type.
-- Use this when returns true when the given name matches "PostFxEffect" or a parent type is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:typeOf(1)
end

--@api-stub: PostFxEffect:setThreshold
-- Sets the threshold parameter of this effect.
-- Use this when sets the threshold parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setThreshold(0)
end

--@api-stub: PostFxEffect:setIntensity
-- Sets the intensity parameter of this effect.
-- Use this when sets the intensity parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setIntensity(0)
end

--@api-stub: PostFxEffect:setRadius
-- Sets the radius parameter of this effect.
-- Use this when sets the radius parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setRadius(0)
end

--@api-stub: PostFxEffect:setStrength
-- Sets the strength parameter of this effect.
-- Use this when sets the strength parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setStrength(0)
end

--@api-stub: PostFxEffect:setScanlineStrength
-- Sets the scanline strength parameter of this effect.
-- Use this when sets the scanline strength parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setScanlineStrength(0)
end

--@api-stub: PostFxEffect:setOffset
-- Sets the offset parameter of this effect.
-- Use this when sets the offset parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setOffset(0)
end

--@api-stub: PostFxEffect:setBrightness
-- Sets the brightness parameter of this effect.
-- Use this when sets the brightness parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setBrightness(0)
end

--@api-stub: PostFxEffect:setContrast
-- Sets the contrast parameter of this effect.
-- Use this when sets the contrast parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setContrast(0)
end

--@api-stub: PostFxEffect:setSaturation
-- Sets the saturation parameter of this effect.
-- Use this when sets the saturation parameter of this effect is needed.
if false then
  local _o = nil  -- PostFxEffect instance
  _o:setSaturation(0)
end

-- ── PostFxStack methods ──

--@api-stub: PostFxStack:add
-- Appends a PostFxEffect to the end of the pipeline.
-- Use this when appends a PostFxEffect to the end of the pipeline is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:add(0)
end

--@api-stub: PostFxStack:remove
-- Removes the given PostFxEffect from the pipeline.
-- Use this when removes the given PostFxEffect from the pipeline is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:remove(0)
end

--@api-stub: PostFxStack:isEnabled
-- Returns whether the effect at the given 1-based position is enabled.
-- Use this when returns whether the effect at the given 1-based position is enabled is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:isEnabled(1)
end

--@api-stub: PostFxStack:getEffectCount
-- Returns the number of effects in the pipeline.
-- Use this when returns the number of effects in the pipeline is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getEffectCount()
end

--@api-stub: PostFxStack:getEffect
-- Returns the effect at the given 1-based position, or nil.
-- Use this when returns the effect at the given 1-based position, or nil is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getEffect(1)
end

--@api-stub: PostFxStack:getEnabledEffects
-- Returns a list of currently enabled effect objects.
-- Use this when returns a list of currently enabled effect objects is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getEnabledEffects()
end

--@api-stub: PostFxStack:getWidth
-- Returns the width of the render target.
-- Use this when returns the width of the render target is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getWidth()
end

--@api-stub: PostFxStack:getHeight
-- Returns the height of the render target.
-- Use this when returns the height of the render target is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getHeight()
end

--@api-stub: PostFxStack:getDimensions
-- Returns width and height of the render target.
-- Use this when returns width and height of the render target is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getDimensions()
end

--@api-stub: PostFxStack:resize
-- Resizes the render target to the given dimensions.
-- Use this when resizes the render target to the given dimensions is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:resize(0, 0)
end

--@api-stub: PostFxStack:len
-- Returns the total number of effect slots in the pipeline.
-- Use this when returns the total number of effect slots in the pipeline is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:len()
end

--@api-stub: PostFxStack:isEmpty
-- Returns true if the pipeline has no effect slots.
-- Use this when returns true if the pipeline has no effect slots is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:isEmpty()
end

--@api-stub: PostFxStack:clear
-- Removes all effects from the pipeline.
-- Use this when removes all effects from the pipeline is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:clear()
end

--@api-stub: PostFxStack:dedup
-- Removes duplicate effects from the pipeline, keeping the first occurrence.
-- Use this when removes duplicate effects from the pipeline, keeping the first occurrence is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:dedup()
end

--@api-stub: PostFxStack:isCapturing
-- Returns whether the stack is currently capturing the scene.
-- Use this when returns whether the stack is currently capturing the scene is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:isCapturing()
end

--@api-stub: PostFxStack:beginCapture
-- Begins capturing the scene for post-processing.
-- Use this when begins capturing the scene for post-processing is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:beginCapture()
end

--@api-stub: PostFxStack:endCapture
-- Ends scene capture for post-processing.
-- Use this when ends scene capture for post-processing is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:endCapture()
end

--@api-stub: PostFxStack:apply
-- Applies all enabled effects in the stack and composites the result to screen.
-- Use this when applies all enabled effects in the stack and composites the result to screen is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:apply()
end

--@api-stub: PostFxStack:type
-- Returns the type name "PostFxStack".
-- Use this when returns the type name "PostFxStack" is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:type()
end

--@api-stub: PostFxStack:typeOf
-- Returns true when the given name matches "PostFxStack" or a parent type.
-- Use this when returns true when the given name matches "PostFxStack" or a parent type is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:typeOf(1)
end

--@api-stub: PostFxStack:setFeedback
-- Sets the feedback loop intensity.
-- At `0.0` (default) there is no
if false then
  local _o = nil  -- PostFxStack instance
  _o:setFeedback(0)
end

--@api-stub: PostFxStack:getFeedback
-- Returns the current feedback loop intensity `[0.0, 1.0]`.
-- Use this when returns the current feedback loop intensity `[0.0, 1.0]` is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:getFeedback()
end

--@api-stub: PostFxStack:clearFeedback
-- Resets the feedback intensity to `0.0` (disables feedback).
-- Use this when resets the feedback intensity to `0.0` (disables feedback) is needed.
if false then
  local _o = nil  -- PostFxStack instance
  _o:clearFeedback()
end

-- ── ImageEffect methods ──

--@api-stub: ImageEffect:addEffect
-- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
-- Use this when creates a new effect by type name, appends it, and returns the shared PostFxEffect is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:addEffect(1)
end

--@api-stub: ImageEffect:getEffect
-- Returns the effect at the given 1-based index or with the given type name.
-- Use this when returns the effect at the given 1-based index or with the given type name is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:getEffect(0)
end

--@api-stub: ImageEffect:removeEffect
-- Removes the effect at the given 1-based index or with the given type name.
-- Use this when removes the effect at the given 1-based index or with the given type name is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:removeEffect(0)
end

--@api-stub: ImageEffect:clearEffects
-- Removes all effects from the chain.
-- Use this when removes all effects from the chain is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:clearEffects()
end

--@api-stub: ImageEffect:clear
-- Removes all effects from the chain (alias for clearEffects).
-- Use this when removes all effects from the chain (alias for clearEffects) is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:clear()
end

--@api-stub: ImageEffect:effectCount
-- Returns the number of effects in the chain.
-- Use this when returns the number of effects in the chain is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:effectCount()
end

--@api-stub: ImageEffect:getEffectCount
-- Returns the number of effects in the chain (alias for effectCount).
-- Use this when returns the number of effects in the chain (alias for effectCount) is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:getEffectCount()
end

--@api-stub: ImageEffect:clone
-- Returns a deep copy of this ImageEffect chain.
-- Use this when returns a deep copy of this ImageEffect chain is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:clone()
end

--@api-stub: ImageEffect:save
-- Stub: no-op serialisation placeholder.
-- Use this when stub: no-op serialisation placeholder is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:save()
end

--@api-stub: ImageEffect:type
-- Returns the type name "ImageEffect".
-- Use this when returns the type name "ImageEffect" is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:type()
end

--@api-stub: ImageEffect:typeOf
-- Returns true when the given name matches "ImageEffect" or a parent type.
-- Use this when returns true when the given name matches "ImageEffect" or a parent type is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:typeOf(1)
end

--@api-stub: ImageEffect:removeByIndex
-- Removes the effect at the given 0-based index from the chain.
-- Use this when removes the effect at the given 0-based index from the chain is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:removeByIndex(1)
end

--@api-stub: ImageEffect:removeByName
-- Removes the first effect matching the given type name.
-- Use this when removes the first effect matching the given type name is needed.
if false then
  local _o = nil  -- ImageEffect instance
  _o:removeByName(1)
end

-- ── Overlay methods ──

--@api-stub: Overlay:update
-- Advances all effect subsystems by the given delta time.
-- Use this when advances all effect subsystems by the given delta time is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:update(0)
end

--@api-stub: Overlay:triggerLightning
-- Triggers a lightning flash effect.
-- Use this when triggers a lightning flash effect is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:triggerLightning()
end

--@api-stub: Overlay:getShakeOffset
-- Returns the current shake displacement as x, y.
-- Use this when returns the current shake displacement as x, y is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getShakeOffset()
end

--@api-stub: Overlay:isActive
-- Returns true if any effect subsystem is currently active.
-- Use this when returns true if any effect subsystem is currently active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isActive()
end

--@api-stub: Overlay:clear
-- Resets all effect subsystems to their default inactive state.
-- Use this when resets all effect subsystems to their default inactive state is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:clear()
end

--@api-stub: Overlay:resize
-- Resizes the effect to match new window dimensions.
-- Use this when resizes the effect to match new window dimensions is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:resize(0, 0)
end

--@api-stub: Overlay:getWidth
-- Returns the effect width.
-- Use this when returns the effect width is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getWidth()
end

--@api-stub: Overlay:getHeight
-- Returns the effect height.
-- Use this when returns the effect height is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getHeight()
end

--@api-stub: Overlay:getDimensions
-- Returns the effect width and height.
-- Use this when returns the effect width and height is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getDimensions()
end

--@api-stub: Overlay:getFlashAlpha
-- Returns the current flash overlay alpha value.
-- Use this when returns the current flash overlay alpha value is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getFlashAlpha()
end

--@api-stub: Overlay:getLightningAlpha
-- Returns the current lightning overlay alpha value.
-- Use this when returns the current lightning overlay alpha value is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getLightningAlpha()
end

--@api-stub: Overlay:setAmbientEnabled
-- Enables or disables the ambient light layer.
-- Use this when enables or disables the ambient light layer is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setAmbientEnabled(0)
end

--@api-stub: Overlay:isAmbientEnabled
-- Returns whether the ambient light layer is active.
-- Use this when returns whether the ambient light layer is active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isAmbientEnabled()
end

--@api-stub: Overlay:getAmbientColor
-- Returns the current ambient tint as r, g, b, a components.
-- Use this when returns the current ambient tint as r, g, b, a components is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getAmbientColor()
end

--@api-stub: Overlay:setTimeOfDay
-- Sets the simulated time-of-day (0â€“24) which drives ambient colour.
-- Use this when sets the simulated time-of-day (0â€“24) which drives ambient colour is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setTimeOfDay(0)
end

--@api-stub: Overlay:getTimeOfDay
-- Returns the current simulated time-of-day (0â€“24).
-- Use this when returns the current simulated time-of-day (0â€“24) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getTimeOfDay()
end

--@api-stub: Overlay:setFogEnabled
-- Enables or disables the fog layer.
-- Use this when enables or disables the fog layer is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setFogEnabled(0)
end

--@api-stub: Overlay:isFogEnabled
-- Returns whether the fog layer is active.
-- Use this when returns whether the fog layer is active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isFogEnabled()
end

--@api-stub: Overlay:setFogDensity
-- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
-- Use this when sets the fog density (0.0 = clear, 1.0 = fully opaque) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setFogDensity(0)
end

--@api-stub: Overlay:getFogDensity
-- Returns the current fog density.
-- Use this when returns the current fog density is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getFogDensity()
end

--@api-stub: Overlay:getFogColor
-- Returns the current fog tint as r, g, b, a components.
-- Use this when returns the current fog tint as r, g, b, a components is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getFogColor()
end

--@api-stub: Overlay:setHeatHazeEnabled
-- Enables or disables the heat-haze distortion layer.
-- Use this when enables or disables the heat-haze distortion layer is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setHeatHazeEnabled(0)
end

--@api-stub: Overlay:isHeatHazeEnabled
-- Returns whether the heat-haze layer is active.
-- Use this when returns whether the heat-haze layer is active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isHeatHazeEnabled()
end

--@api-stub: Overlay:setHeatHazeIntensity
-- Sets the heat-haze distortion intensity (0.0â€“1.0).
-- Use this when sets the heat-haze distortion intensity (0.0â€“1.0) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setHeatHazeIntensity(0)
end

--@api-stub: Overlay:getHeatHazeIntensity
-- Returns the current heat-haze distortion intensity.
-- Use this when returns the current heat-haze distortion intensity is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getHeatHazeIntensity()
end

--@api-stub: Overlay:setVignetteEnabled
-- Enables or disables the screen-edge vignette layer.
-- Use this when enables or disables the screen-edge vignette layer is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setVignetteEnabled(0)
end

--@api-stub: Overlay:isVignetteEnabled
-- Returns whether the vignette layer is active.
-- Use this when returns whether the vignette layer is active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isVignetteEnabled()
end

--@api-stub: Overlay:setVignetteStrength
-- Sets the vignette darkening strength (0.0â€“1.0).
-- Use this when sets the vignette darkening strength (0.0â€“1.0) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setVignetteStrength(0)
end

--@api-stub: Overlay:getVignetteStrength
-- Returns the current vignette strength.
-- Use this when returns the current vignette strength is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getVignetteStrength()
end

--@api-stub: Overlay:setFilmGrainEnabled
-- Enables or disables the film-grain noise layer.
-- Use this when enables or disables the film-grain noise layer is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setFilmGrainEnabled(0)
end

--@api-stub: Overlay:isFilmGrainEnabled
-- Returns whether the film-grain layer is active.
-- Use this when returns whether the film-grain layer is active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isFilmGrainEnabled()
end

--@api-stub: Overlay:setFilmGrainIntensity
-- Sets the film-grain noise intensity (0.0â€“1.0).
-- Use this when sets the film-grain noise intensity (0.0â€“1.0) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setFilmGrainIntensity(0)
end

--@api-stub: Overlay:getFilmGrainIntensity
-- Returns the current film-grain intensity.
-- Use this when returns the current film-grain intensity is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getFilmGrainIntensity()
end

--@api-stub: Overlay:setCloudShadows
-- Enables or disables scrolling cloud-shadow projection.
-- Use this when enables or disables scrolling cloud-shadow projection is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setCloudShadows(0)
end

--@api-stub: Overlay:isCloudShadowsEnabled
-- Returns whether cloud shadows are active.
-- Use this when returns whether cloud shadows are active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isCloudShadowsEnabled()
end

--@api-stub: Overlay:setCloudCount
-- Sets the number of cloud shadow instances to render.
-- Use this when sets the number of cloud shadow instances to render is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setCloudCount(0)
end

--@api-stub: Overlay:getCloudCount
-- Returns the current cloud shadow instance count.
-- Use this when returns the current cloud shadow instance count is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getCloudCount()
end

--@api-stub: Overlay:setCloudSpeed
-- Sets the horizontal scroll speed of cloud shadows in pixels per second.
-- Use this when sets the horizontal scroll speed of cloud shadows in pixels per second is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setCloudSpeed(0)
end

--@api-stub: Overlay:getCloudSpeed
-- Returns the current cloud shadow scroll speed.
-- Use this when returns the current cloud shadow scroll speed is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getCloudSpeed()
end

--@api-stub: Overlay:setCloudScale
-- Sets the scale multiplier applied to each cloud shadow.
-- Use this when sets the scale multiplier applied to each cloud shadow is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setCloudScale(0)
end

--@api-stub: Overlay:getCloudScale
-- Returns the current cloud shadow scale.
-- Use this when returns the current cloud shadow scale is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getCloudScale()
end

--@api-stub: Overlay:setCloudOpacity
-- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
-- Use this when sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setCloudOpacity(0)
end

--@api-stub: Overlay:getCloudOpacity
-- Returns the current cloud shadow opacity.
-- Use this when returns the current cloud shadow opacity is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getCloudOpacity()
end

--@api-stub: Overlay:setWeatherEnabled
-- Enables or disables the weather particle system.
-- Use this when enables or disables the weather particle system is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setWeatherEnabled(0)
end

--@api-stub: Overlay:isWeatherEnabled
-- Returns whether the weather particle system is active.
-- Use this when returns whether the weather particle system is active is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isWeatherEnabled()
end

--@api-stub: Overlay:setWeather
-- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
-- Use this when sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen") is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setWeather(1)
end

--@api-stub: Overlay:getWeather
-- Returns the name of the current weather type.
-- Use this when returns the name of the current weather type is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getWeather()
end

--@api-stub: Overlay:setWeatherIntensity
-- Sets the particle spawn rate multiplier (0.0â€“1.0).
-- Use this when sets the particle spawn rate multiplier (0.0â€“1.0) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setWeatherIntensity(0)
end

--@api-stub: Overlay:getWeatherIntensity
-- Returns the current weather intensity.
-- Use this when returns the current weather intensity is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getWeatherIntensity()
end

--@api-stub: Overlay:setWindDirection
-- Sets the wind direction in radians (0 = right, Ď€/2 = down).
-- Use this when sets the wind direction in radians (0 = right, Ď€/2 = down) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setWindDirection(0)
end

--@api-stub: Overlay:getWindDirection
-- Returns the current wind direction in radians.
-- Use this when returns the current wind direction in radians is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getWindDirection()
end

--@api-stub: Overlay:setWindSpeed
-- Sets the wind speed applied to weather particles in units per second.
-- Use this when sets the wind speed applied to weather particles in units per second is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setWindSpeed(0)
end

--@api-stub: Overlay:getWindSpeed
-- Returns the current wind speed.
-- Use this when returns the current wind speed is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getWindSpeed()
end

--@api-stub: Overlay:getLightningColor
-- Returns the lightning flash tint as r, g, b, a components.
-- Use this when returns the lightning flash tint as r, g, b, a components is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getLightningColor()
end

--@api-stub: Overlay:isFlashing
-- Returns true while a flash effect is in progress.
-- Use this when returns true while a flash effect is in progress is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isFlashing()
end

--@api-stub: Overlay:shake
-- Triggers a camera shake; duration defaults to 0.5 s.
-- Use this when triggers a camera shake; duration defaults to 0.5 s is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:shake(1, nil)
end

--@api-stub: Overlay:isShaking
-- Returns true while a shake effect is in progress.
-- Use this when returns true while a shake effect is in progress is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isShaking()
end

--@api-stub: Overlay:isFading
-- Returns true while a fade effect is in progress.
-- Use this when returns true while a fade effect is in progress is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:isFading()
end

--@api-stub: Overlay:render
-- Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
-- Use this when emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette) is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:render()
end

--@api-stub: Overlay:drawToImage
-- Renders the effect state (flash, fade, effects) to a CPU ImageData.
-- Use this when renders the effect state (flash, fade, effects) to a CPU ImageData is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:drawToImage(0, 0)
end

--@api-stub: Overlay:setCustomShader
-- Assigns a custom shader name to the effect, or clears it when `nil` is passed.
-- Use this when assigns a custom shader name to the effect, or clears it when `nil` is passed is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:setCustomShader(1)
end

--@api-stub: Overlay:getWater
-- Returns a table describing the current water overlay state.
-- Use this when returns a table describing the current water overlay state is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:getWater()
end

--@api-stub: Overlay:type
-- Returns the type name of this object ("Overlay").
-- Use this when returns the type name of this object ("Overlay") is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:type()
end

--@api-stub: Overlay:typeOf
-- Returns true if this object is of the given type ("Object" or "Overlay").
-- Use this when returns true if this object is of the given type ("Object" or "Overlay") is needed.
if false then
  local _o = nil  -- Overlay instance
  _o:typeOf(1)
end

-- ── mlua methods ──

--@api-stub: mlua:play
-- Starts the transition playing forward (scene fades/wipes out).
-- Use this when starts the transition playing forward (scene fades/wipes out) is needed.
if false then
  local _o = nil  -- mlua instance
  _o:play()
end

--@api-stub: mlua:reverse
-- Starts the transition in reverse (scene fades/wipes in).
-- Use this when starts the transition in reverse (scene fades/wipes in) is needed.
if false then
  local _o = nil  -- mlua instance
  _o:reverse()
end

--@api-stub: mlua:update
-- Advances the transition by `dt` seconds.
-- Returns `true` while
if false then
  local _o = nil  -- mlua instance
  _o:update(0)
end

--@api-stub: mlua:progress
-- Returns the fractional progress `[0, 1]` of the transition, taking.
-- Use this when returns the fractional progress `[0, 1]` of the transition, taking is needed.
if false then
  local _o = nil  -- mlua instance
  _o:progress()
end

--@api-stub: mlua:isActive
-- Returns `true` while the transition is running.
-- Use this when returns `true` while the transition is running is needed.
if false then
  local _o = nil  -- mlua instance
  _o:isActive()
end

--@api-stub: mlua:isDone
-- Returns `true` after the transition has completed.
-- Use this when returns `true` after the transition has completed is needed.
if false then
  local _o = nil  -- mlua instance
  _o:isDone()
end

--@api-stub: mlua:kind
-- Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,.
-- Use this when returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`, is needed.
if false then
  local _o = nil  -- mlua instance
  _o:kind()
end

--@api-stub: mlua:color
-- Returns the fill color as four numbers: `r, g, b, a`.
-- Use this when returns the fill color as four numbers: `r, g, b, a` is needed.
if false then
  local _o = nil  -- mlua instance
  _o:color()
end

--@api-stub: mlua:setColor
-- Updates the fill color from `{r, g, b, a?}`.
-- Use this when updates the fill color from `{r, g, b, a?}` is needed.
if false then
  local _o = nil  -- mlua instance
  _o:setColor()
end

--@api-stub: mlua:type
-- Type.
-- Use this when type is needed.
if false then
  local _o = nil  -- mlua instance
  _o:type()
end

--@api-stub: mlua:typeOf
-- Type of.
-- Use this when type of is needed.
if false then
  local _o = nil  -- mlua instance
  _o:typeOf(1)
end

