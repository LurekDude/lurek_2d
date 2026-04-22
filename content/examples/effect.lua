-- content/examples/effect.lua
-- Scaffolded coverage of the lurek.effect API (142 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/effect_api.rs   (Lua binding, arg types, return shape)
--   * src/effect/                 (semantics, side effects)
--   * docs/specs/effect.md        (canonical reference)
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
-- Run: cargo run -- content/examples/effect.lua

-- ── lurek.effect.* functions ──

--@api-stub: lurek.effect.newEffect
-- Creates a new built-in post-processing effect by type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newEffect
  local _todo = "TODO: write a real lurek.effect.newEffect usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newCustomEffect
-- Creates a custom shader post-processing effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newCustomEffect
  local _todo = "TODO: write a real lurek.effect.newCustomEffect usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newStack
-- Creates a new post-processing pipeline stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newStack
  local _todo = "TODO: write a real lurek.effect.newStack usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newPresetStack
-- Creates a pre-configured effect stack from a named preset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newPresetStack
  local _todo = "TODO: write a real lurek.effect.newPresetStack usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newPass
-- Creates a custom-shader post-processing effect (alias for newCustomEffect).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newPass
  local _todo = "TODO: write a real lurek.effect.newPass usage example"
  print(_todo)
end

--@api-stub: lurek.effect.getEffectTypes
-- Returns the list of all built-in effect type names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.getEffectTypes
  local _todo = "TODO: write a real lurek.effect.getEffectTypes usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newImageEffect
-- Creates a new per-image effect chain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newImageEffect
  local _todo = "TODO: write a real lurek.effect.newImageEffect usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newOverlay
-- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newOverlay
  local _todo = "TODO: write a real lurek.effect.newOverlay usage example"
  print(_todo)
end

--@api-stub: lurek.effect.newTransition
-- Creates a new screen-transition controller.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.newTransition
  local _todo = "TODO: write a real lurek.effect.newTransition usage example"
  print(_todo)
end

--@api-stub: lurek.effect.setShaderErrorDisplay
-- Enables or disables the effect that renders shader compile errors as red text.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.setShaderErrorDisplay
  local _todo = "TODO: write a real lurek.effect.setShaderErrorDisplay usage example"
  print(_todo)
end

--@api-stub: lurek.effect.getShaderErrorDisplay
-- Returns whether shader error display is currently enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: lurek.effect.getShaderErrorDisplay
  local _todo = "TODO: write a real lurek.effect.getShaderErrorDisplay usage example"
  print(_todo)
end

-- ── PostFxEffect methods ──

--@api-stub: PostFxEffect:getTypeName
-- Returns the display name of this effect type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:getTypeName
  local _todo = "TODO: write a real PostFxEffect:getTypeName usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:isBuiltIn
-- Returns true if this is a built-in effect, false if custom.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:isBuiltIn
  local _todo = "TODO: write a real PostFxEffect:isBuiltIn usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:isEnabled
-- Returns whether this effect is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:isEnabled
  local _todo = "TODO: write a real PostFxEffect:isEnabled usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setEnabled
-- Enables or disables this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setEnabled
  local _todo = "TODO: write a real PostFxEffect:setEnabled usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setParameter
-- Sets a named float parameter on this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setParameter
  local _todo = "TODO: write a real PostFxEffect:setParameter usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:hasParameter
-- Returns true if the named parameter exists on this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:hasParameter
  local _todo = "TODO: write a real PostFxEffect:hasParameter usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:getParameterNames
-- Returns a list of all parameter names on this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:getParameterNames
  local _todo = "TODO: write a real PostFxEffect:getParameterNames usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:getEffectType
-- Returns the type name of this effect (alias for getTypeName).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:getEffectType
  local _todo = "TODO: write a real PostFxEffect:getEffectType usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:getType
-- Returns the type name of this effect (alias for getTypeName).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:getType
  local _todo = "TODO: write a real PostFxEffect:getType usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:type
-- Returns the type name "PostFxEffect".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:type
  local _todo = "TODO: write a real PostFxEffect:type usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:typeOf
-- Returns true when the given name matches "PostFxEffect" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:typeOf
  local _todo = "TODO: write a real PostFxEffect:typeOf usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setThreshold
-- Sets the threshold parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setThreshold
  local _todo = "TODO: write a real PostFxEffect:setThreshold usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setIntensity
-- Sets the intensity parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setIntensity
  local _todo = "TODO: write a real PostFxEffect:setIntensity usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setRadius
-- Sets the radius parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setRadius
  local _todo = "TODO: write a real PostFxEffect:setRadius usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setStrength
-- Sets the strength parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setStrength
  local _todo = "TODO: write a real PostFxEffect:setStrength usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setScanlineStrength
-- Sets the scanline strength parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setScanlineStrength
  local _todo = "TODO: write a real PostFxEffect:setScanlineStrength usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setOffset
-- Sets the offset parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setOffset
  local _todo = "TODO: write a real PostFxEffect:setOffset usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setBrightness
-- Sets the brightness parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setBrightness
  local _todo = "TODO: write a real PostFxEffect:setBrightness usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setContrast
-- Sets the contrast parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setContrast
  local _todo = "TODO: write a real PostFxEffect:setContrast usage example"
  print(_todo)
end

--@api-stub: PostFxEffect:setSaturation
-- Sets the saturation parameter of this effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxEffect:setSaturation
  local _todo = "TODO: write a real PostFxEffect:setSaturation usage example"
  print(_todo)
end

-- ── PostFxStack methods ──

--@api-stub: PostFxStack:add
-- Appends a PostFxEffect to the end of the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:add
  local _todo = "TODO: write a real PostFxStack:add usage example"
  print(_todo)
end

--@api-stub: PostFxStack:remove
-- Removes the given PostFxEffect from the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:remove
  local _todo = "TODO: write a real PostFxStack:remove usage example"
  print(_todo)
end

--@api-stub: PostFxStack:isEnabled
-- Returns whether the effect at the given 1-based position is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:isEnabled
  local _todo = "TODO: write a real PostFxStack:isEnabled usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getEffectCount
-- Returns the number of effects in the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getEffectCount
  local _todo = "TODO: write a real PostFxStack:getEffectCount usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getEffect
-- Returns the effect at the given 1-based position, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getEffect
  local _todo = "TODO: write a real PostFxStack:getEffect usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getEnabledEffects
-- Returns a list of currently enabled effect objects.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getEnabledEffects
  local _todo = "TODO: write a real PostFxStack:getEnabledEffects usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getWidth
-- Returns the width of the render target.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getWidth
  local _todo = "TODO: write a real PostFxStack:getWidth usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getHeight
-- Returns the height of the render target.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getHeight
  local _todo = "TODO: write a real PostFxStack:getHeight usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getDimensions
-- Returns width and height of the render target.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getDimensions
  local _todo = "TODO: write a real PostFxStack:getDimensions usage example"
  print(_todo)
end

--@api-stub: PostFxStack:resize
-- Resizes the render target to the given dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:resize
  local _todo = "TODO: write a real PostFxStack:resize usage example"
  print(_todo)
end

--@api-stub: PostFxStack:len
-- Returns the total number of effect slots in the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:len
  local _todo = "TODO: write a real PostFxStack:len usage example"
  print(_todo)
end

--@api-stub: PostFxStack:isEmpty
-- Returns true if the pipeline has no effect slots.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:isEmpty
  local _todo = "TODO: write a real PostFxStack:isEmpty usage example"
  print(_todo)
end

--@api-stub: PostFxStack:clear
-- Removes all effects from the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:clear
  local _todo = "TODO: write a real PostFxStack:clear usage example"
  print(_todo)
end

--@api-stub: PostFxStack:dedup
-- Removes duplicate effects from the pipeline, keeping the first occurrence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:dedup
  local _todo = "TODO: write a real PostFxStack:dedup usage example"
  print(_todo)
end

--@api-stub: PostFxStack:isCapturing
-- Returns whether the stack is currently capturing the scene.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:isCapturing
  local _todo = "TODO: write a real PostFxStack:isCapturing usage example"
  print(_todo)
end

--@api-stub: PostFxStack:beginCapture
-- Begins capturing the scene for post-processing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:beginCapture
  local _todo = "TODO: write a real PostFxStack:beginCapture usage example"
  print(_todo)
end

--@api-stub: PostFxStack:endCapture
-- Ends scene capture for post-processing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:endCapture
  local _todo = "TODO: write a real PostFxStack:endCapture usage example"
  print(_todo)
end

--@api-stub: PostFxStack:apply
-- Applies all enabled effects in the stack and composites the result to screen.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:apply
  local _todo = "TODO: write a real PostFxStack:apply usage example"
  print(_todo)
end

--@api-stub: PostFxStack:type
-- Returns the type name "PostFxStack".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:type
  local _todo = "TODO: write a real PostFxStack:type usage example"
  print(_todo)
end

--@api-stub: PostFxStack:typeOf
-- Returns true when the given name matches "PostFxStack" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:typeOf
  local _todo = "TODO: write a real PostFxStack:typeOf usage example"
  print(_todo)
end

--@api-stub: PostFxStack:setFeedback
-- Sets the feedback loop intensity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:setFeedback
  local _todo = "TODO: write a real PostFxStack:setFeedback usage example"
  print(_todo)
end

--@api-stub: PostFxStack:getFeedback
-- Returns the current feedback loop intensity `[0.0, 1.0]`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:getFeedback
  local _todo = "TODO: write a real PostFxStack:getFeedback usage example"
  print(_todo)
end

--@api-stub: PostFxStack:clearFeedback
-- Resets the feedback intensity to `0.0` (disables feedback).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: PostFxStack:clearFeedback
  local _todo = "TODO: write a real PostFxStack:clearFeedback usage example"
  print(_todo)
end

-- ── ImageEffect methods ──

--@api-stub: ImageEffect:addEffect
-- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:addEffect
  local _todo = "TODO: write a real ImageEffect:addEffect usage example"
  print(_todo)
end

--@api-stub: ImageEffect:getEffect
-- Returns the effect at the given 1-based index or with the given type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:getEffect
  local _todo = "TODO: write a real ImageEffect:getEffect usage example"
  print(_todo)
end

--@api-stub: ImageEffect:removeEffect
-- Removes the effect at the given 1-based index or with the given type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:removeEffect
  local _todo = "TODO: write a real ImageEffect:removeEffect usage example"
  print(_todo)
end

--@api-stub: ImageEffect:clearEffects
-- Removes all effects from the chain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:clearEffects
  local _todo = "TODO: write a real ImageEffect:clearEffects usage example"
  print(_todo)
end

--@api-stub: ImageEffect:clear
-- Removes all effects from the chain (alias for clearEffects).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:clear
  local _todo = "TODO: write a real ImageEffect:clear usage example"
  print(_todo)
end

--@api-stub: ImageEffect:effectCount
-- Returns the number of effects in the chain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:effectCount
  local _todo = "TODO: write a real ImageEffect:effectCount usage example"
  print(_todo)
end

--@api-stub: ImageEffect:getEffectCount
-- Returns the number of effects in the chain (alias for effectCount).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:getEffectCount
  local _todo = "TODO: write a real ImageEffect:getEffectCount usage example"
  print(_todo)
end

--@api-stub: ImageEffect:clone
-- Returns a deep copy of this ImageEffect chain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:clone
  local _todo = "TODO: write a real ImageEffect:clone usage example"
  print(_todo)
end

--@api-stub: ImageEffect:save
-- Stub: no-op serialisation placeholder.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:save
  local _todo = "TODO: write a real ImageEffect:save usage example"
  print(_todo)
end

--@api-stub: ImageEffect:type
-- Returns the type name "ImageEffect".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:type
  local _todo = "TODO: write a real ImageEffect:type usage example"
  print(_todo)
end

--@api-stub: ImageEffect:typeOf
-- Returns true when the given name matches "ImageEffect" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:typeOf
  local _todo = "TODO: write a real ImageEffect:typeOf usage example"
  print(_todo)
end

--@api-stub: ImageEffect:removeByIndex
-- Removes the effect at the given 0-based index from the chain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:removeByIndex
  local _todo = "TODO: write a real ImageEffect:removeByIndex usage example"
  print(_todo)
end

--@api-stub: ImageEffect:removeByName
-- Removes the first effect matching the given type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: ImageEffect:removeByName
  local _todo = "TODO: write a real ImageEffect:removeByName usage example"
  print(_todo)
end

-- ── Overlay methods ──

--@api-stub: Overlay:update
-- Advances all effect subsystems by the given delta time.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:update
  local _todo = "TODO: write a real Overlay:update usage example"
  print(_todo)
end

--@api-stub: Overlay:triggerLightning
-- Triggers a lightning flash effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:triggerLightning
  local _todo = "TODO: write a real Overlay:triggerLightning usage example"
  print(_todo)
end

--@api-stub: Overlay:getShakeOffset
-- Returns the current shake displacement as x, y.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getShakeOffset
  local _todo = "TODO: write a real Overlay:getShakeOffset usage example"
  print(_todo)
end

--@api-stub: Overlay:isActive
-- Returns true if any effect subsystem is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isActive
  local _todo = "TODO: write a real Overlay:isActive usage example"
  print(_todo)
end

--@api-stub: Overlay:clear
-- Resets all effect subsystems to their default inactive state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:clear
  local _todo = "TODO: write a real Overlay:clear usage example"
  print(_todo)
end

--@api-stub: Overlay:resize
-- Resizes the effect to match new window dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:resize
  local _todo = "TODO: write a real Overlay:resize usage example"
  print(_todo)
end

--@api-stub: Overlay:getWidth
-- Returns the effect width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getWidth
  local _todo = "TODO: write a real Overlay:getWidth usage example"
  print(_todo)
end

--@api-stub: Overlay:getHeight
-- Returns the effect height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getHeight
  local _todo = "TODO: write a real Overlay:getHeight usage example"
  print(_todo)
end

--@api-stub: Overlay:getDimensions
-- Returns the effect width and height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getDimensions
  local _todo = "TODO: write a real Overlay:getDimensions usage example"
  print(_todo)
end

--@api-stub: Overlay:getFlashAlpha
-- Returns the current flash overlay alpha value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getFlashAlpha
  local _todo = "TODO: write a real Overlay:getFlashAlpha usage example"
  print(_todo)
end

--@api-stub: Overlay:getLightningAlpha
-- Returns the current lightning overlay alpha value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getLightningAlpha
  local _todo = "TODO: write a real Overlay:getLightningAlpha usage example"
  print(_todo)
end

--@api-stub: Overlay:setAmbientEnabled
-- Enables or disables the ambient light layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setAmbientEnabled
  local _todo = "TODO: write a real Overlay:setAmbientEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:isAmbientEnabled
-- Returns whether the ambient light layer is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isAmbientEnabled
  local _todo = "TODO: write a real Overlay:isAmbientEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:getAmbientColor
-- Returns the current ambient tint as r, g, b, a components.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getAmbientColor
  local _todo = "TODO: write a real Overlay:getAmbientColor usage example"
  print(_todo)
end

--@api-stub: Overlay:setTimeOfDay
-- Sets the simulated time-of-day (0â€“24) which drives ambient colour.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setTimeOfDay
  local _todo = "TODO: write a real Overlay:setTimeOfDay usage example"
  print(_todo)
end

--@api-stub: Overlay:getTimeOfDay
-- Returns the current simulated time-of-day (0â€“24).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getTimeOfDay
  local _todo = "TODO: write a real Overlay:getTimeOfDay usage example"
  print(_todo)
end

--@api-stub: Overlay:setFogEnabled
-- Enables or disables the fog layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setFogEnabled
  local _todo = "TODO: write a real Overlay:setFogEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:isFogEnabled
-- Returns whether the fog layer is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isFogEnabled
  local _todo = "TODO: write a real Overlay:isFogEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:setFogDensity
-- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setFogDensity
  local _todo = "TODO: write a real Overlay:setFogDensity usage example"
  print(_todo)
end

--@api-stub: Overlay:getFogDensity
-- Returns the current fog density.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getFogDensity
  local _todo = "TODO: write a real Overlay:getFogDensity usage example"
  print(_todo)
end

--@api-stub: Overlay:getFogColor
-- Returns the current fog tint as r, g, b, a components.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getFogColor
  local _todo = "TODO: write a real Overlay:getFogColor usage example"
  print(_todo)
end

--@api-stub: Overlay:setHeatHazeEnabled
-- Enables or disables the heat-haze distortion layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setHeatHazeEnabled
  local _todo = "TODO: write a real Overlay:setHeatHazeEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:isHeatHazeEnabled
-- Returns whether the heat-haze layer is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isHeatHazeEnabled
  local _todo = "TODO: write a real Overlay:isHeatHazeEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:setHeatHazeIntensity
-- Sets the heat-haze distortion intensity (0.0â€“1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setHeatHazeIntensity
  local _todo = "TODO: write a real Overlay:setHeatHazeIntensity usage example"
  print(_todo)
end

--@api-stub: Overlay:getHeatHazeIntensity
-- Returns the current heat-haze distortion intensity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getHeatHazeIntensity
  local _todo = "TODO: write a real Overlay:getHeatHazeIntensity usage example"
  print(_todo)
end

--@api-stub: Overlay:setVignetteEnabled
-- Enables or disables the screen-edge vignette layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setVignetteEnabled
  local _todo = "TODO: write a real Overlay:setVignetteEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:isVignetteEnabled
-- Returns whether the vignette layer is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isVignetteEnabled
  local _todo = "TODO: write a real Overlay:isVignetteEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:setVignetteStrength
-- Sets the vignette darkening strength (0.0â€“1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setVignetteStrength
  local _todo = "TODO: write a real Overlay:setVignetteStrength usage example"
  print(_todo)
end

--@api-stub: Overlay:getVignetteStrength
-- Returns the current vignette strength.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getVignetteStrength
  local _todo = "TODO: write a real Overlay:getVignetteStrength usage example"
  print(_todo)
end

--@api-stub: Overlay:setFilmGrainEnabled
-- Enables or disables the film-grain noise layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setFilmGrainEnabled
  local _todo = "TODO: write a real Overlay:setFilmGrainEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:isFilmGrainEnabled
-- Returns whether the film-grain layer is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isFilmGrainEnabled
  local _todo = "TODO: write a real Overlay:isFilmGrainEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:setFilmGrainIntensity
-- Sets the film-grain noise intensity (0.0â€“1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setFilmGrainIntensity
  local _todo = "TODO: write a real Overlay:setFilmGrainIntensity usage example"
  print(_todo)
end

--@api-stub: Overlay:getFilmGrainIntensity
-- Returns the current film-grain intensity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getFilmGrainIntensity
  local _todo = "TODO: write a real Overlay:getFilmGrainIntensity usage example"
  print(_todo)
end

--@api-stub: Overlay:setCloudShadows
-- Enables or disables scrolling cloud-shadow projection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setCloudShadows
  local _todo = "TODO: write a real Overlay:setCloudShadows usage example"
  print(_todo)
end

--@api-stub: Overlay:isCloudShadowsEnabled
-- Returns whether cloud shadows are active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isCloudShadowsEnabled
  local _todo = "TODO: write a real Overlay:isCloudShadowsEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:setCloudCount
-- Sets the number of cloud shadow instances to render.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setCloudCount
  local _todo = "TODO: write a real Overlay:setCloudCount usage example"
  print(_todo)
end

--@api-stub: Overlay:getCloudCount
-- Returns the current cloud shadow instance count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getCloudCount
  local _todo = "TODO: write a real Overlay:getCloudCount usage example"
  print(_todo)
end

--@api-stub: Overlay:setCloudSpeed
-- Sets the horizontal scroll speed of cloud shadows in pixels per second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setCloudSpeed
  local _todo = "TODO: write a real Overlay:setCloudSpeed usage example"
  print(_todo)
end

--@api-stub: Overlay:getCloudSpeed
-- Returns the current cloud shadow scroll speed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getCloudSpeed
  local _todo = "TODO: write a real Overlay:getCloudSpeed usage example"
  print(_todo)
end

--@api-stub: Overlay:setCloudScale
-- Sets the scale multiplier applied to each cloud shadow.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setCloudScale
  local _todo = "TODO: write a real Overlay:setCloudScale usage example"
  print(_todo)
end

--@api-stub: Overlay:getCloudScale
-- Returns the current cloud shadow scale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getCloudScale
  local _todo = "TODO: write a real Overlay:getCloudScale usage example"
  print(_todo)
end

--@api-stub: Overlay:setCloudOpacity
-- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setCloudOpacity
  local _todo = "TODO: write a real Overlay:setCloudOpacity usage example"
  print(_todo)
end

--@api-stub: Overlay:getCloudOpacity
-- Returns the current cloud shadow opacity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getCloudOpacity
  local _todo = "TODO: write a real Overlay:getCloudOpacity usage example"
  print(_todo)
end

--@api-stub: Overlay:setWeatherEnabled
-- Enables or disables the weather particle system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setWeatherEnabled
  local _todo = "TODO: write a real Overlay:setWeatherEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:isWeatherEnabled
-- Returns whether the weather particle system is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isWeatherEnabled
  local _todo = "TODO: write a real Overlay:isWeatherEnabled usage example"
  print(_todo)
end

--@api-stub: Overlay:setWeather
-- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setWeather
  local _todo = "TODO: write a real Overlay:setWeather usage example"
  print(_todo)
end

--@api-stub: Overlay:getWeather
-- Returns the name of the current weather type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getWeather
  local _todo = "TODO: write a real Overlay:getWeather usage example"
  print(_todo)
end

--@api-stub: Overlay:setWeatherIntensity
-- Sets the particle spawn rate multiplier (0.0â€“1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setWeatherIntensity
  local _todo = "TODO: write a real Overlay:setWeatherIntensity usage example"
  print(_todo)
end

--@api-stub: Overlay:getWeatherIntensity
-- Returns the current weather intensity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getWeatherIntensity
  local _todo = "TODO: write a real Overlay:getWeatherIntensity usage example"
  print(_todo)
end

--@api-stub: Overlay:setWindDirection
-- Sets the wind direction in radians (0 = right, Ď€/2 = down).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setWindDirection
  local _todo = "TODO: write a real Overlay:setWindDirection usage example"
  print(_todo)
end

--@api-stub: Overlay:getWindDirection
-- Returns the current wind direction in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getWindDirection
  local _todo = "TODO: write a real Overlay:getWindDirection usage example"
  print(_todo)
end

--@api-stub: Overlay:setWindSpeed
-- Sets the wind speed applied to weather particles in units per second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setWindSpeed
  local _todo = "TODO: write a real Overlay:setWindSpeed usage example"
  print(_todo)
end

--@api-stub: Overlay:getWindSpeed
-- Returns the current wind speed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getWindSpeed
  local _todo = "TODO: write a real Overlay:getWindSpeed usage example"
  print(_todo)
end

--@api-stub: Overlay:getLightningColor
-- Returns the lightning flash tint as r, g, b, a components.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getLightningColor
  local _todo = "TODO: write a real Overlay:getLightningColor usage example"
  print(_todo)
end

--@api-stub: Overlay:isFlashing
-- Returns true while a flash effect is in progress.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isFlashing
  local _todo = "TODO: write a real Overlay:isFlashing usage example"
  print(_todo)
end

--@api-stub: Overlay:shake
-- Triggers a camera shake; duration defaults to 0.5 s.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:shake
  local _todo = "TODO: write a real Overlay:shake usage example"
  print(_todo)
end

--@api-stub: Overlay:isShaking
-- Returns true while a shake effect is in progress.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isShaking
  local _todo = "TODO: write a real Overlay:isShaking usage example"
  print(_todo)
end

--@api-stub: Overlay:isFading
-- Returns true while a fade effect is in progress.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:isFading
  local _todo = "TODO: write a real Overlay:isFading usage example"
  print(_todo)
end

--@api-stub: Overlay:render
-- Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:render
  local _todo = "TODO: write a real Overlay:render usage example"
  print(_todo)
end

--@api-stub: Overlay:drawToImage
-- Renders the effect state (flash, fade, effects) to a CPU ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:drawToImage
  local _todo = "TODO: write a real Overlay:drawToImage usage example"
  print(_todo)
end

--@api-stub: Overlay:setCustomShader
-- Assigns a custom shader name to the effect, or clears it when `nil` is passed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:setCustomShader
  local _todo = "TODO: write a real Overlay:setCustomShader usage example"
  print(_todo)
end

--@api-stub: Overlay:getWater
-- Returns a table describing the current water overlay state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:getWater
  local _todo = "TODO: write a real Overlay:getWater usage example"
  print(_todo)
end

--@api-stub: Overlay:type
-- Returns the type name of this object ("Overlay").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:type
  local _todo = "TODO: write a real Overlay:type usage example"
  print(_todo)
end

--@api-stub: Overlay:typeOf
-- Returns true if this object is of the given type ("Object" or "Overlay").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: Overlay:typeOf
  local _todo = "TODO: write a real Overlay:typeOf usage example"
  print(_todo)
end

-- ── mlua methods ──

--@api-stub: mlua:play
-- Starts the transition playing forward (scene fades/wipes out).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:play
  local _todo = "TODO: write a real mlua:play usage example"
  print(_todo)
end

--@api-stub: mlua:reverse
-- Starts the transition in reverse (scene fades/wipes in).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:reverse
  local _todo = "TODO: write a real mlua:reverse usage example"
  print(_todo)
end

--@api-stub: mlua:update
-- Advances the transition by `dt` seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:update
  local _todo = "TODO: write a real mlua:update usage example"
  print(_todo)
end

--@api-stub: mlua:progress
-- Returns the fractional progress `[0, 1]` of the transition, taking.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:progress
  local _todo = "TODO: write a real mlua:progress usage example"
  print(_todo)
end

--@api-stub: mlua:isActive
-- Returns `true` while the transition is running.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:isActive
  local _todo = "TODO: write a real mlua:isActive usage example"
  print(_todo)
end

--@api-stub: mlua:isDone
-- Returns `true` after the transition has completed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:isDone
  local _todo = "TODO: write a real mlua:isDone usage example"
  print(_todo)
end

--@api-stub: mlua:kind
-- Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:kind
  local _todo = "TODO: write a real mlua:kind usage example"
  print(_todo)
end

--@api-stub: mlua:color
-- Returns the fill color as four numbers: `r, g, b, a`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:color
  local _todo = "TODO: write a real mlua:color usage example"
  print(_todo)
end

--@api-stub: mlua:setColor
-- Updates the fill color from `{r, g, b, a?}`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:setColor
  local _todo = "TODO: write a real mlua:setColor usage example"
  print(_todo)
end

--@api-stub: mlua:type
-- Type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:type
  local _todo = "TODO: write a real mlua:type usage example"
  print(_todo)
end

--@api-stub: mlua:typeOf
-- Type of.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/effect_api.rs and docs/specs/effect.md).
do  -- TODO: mlua:typeOf
  local _todo = "TODO: write a real mlua:typeOf usage example"
  print(_todo)
end

