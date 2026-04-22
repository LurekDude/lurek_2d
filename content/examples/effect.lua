-- content/examples/effect.lua
-- Practical usage examples for the lurek.effect API (142 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.effect.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/effect.lua

print("[example] lurek.effect — 142 API entries")

-- ── lurek.effect.* free functions ──

--@api-stub: lurek.effect.newEffect
-- Creates a new built-in post-processing effect by type name.
-- Call when you need to create a new effect.
local ok, obj = pcall(function() return lurek.effect.newEffect("type_name") end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newEffect ok=", ok)

--@api-stub: lurek.effect.newCustomEffect
-- Creates a custom shader post-processing effect.
-- Call when you need to create a new custom effect.
local ok, obj = pcall(function() return lurek.effect.newCustomEffect(1) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newCustomEffect ok=", ok)

--@api-stub: lurek.effect.newStack
-- Creates a new post-processing pipeline stack.
-- Call when you need to create a new stack.
local ok, obj = pcall(function() return lurek.effect.newStack(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newStack ok=", ok)

--@api-stub: lurek.effect.newPresetStack
-- Creates a pre-configured effect stack from a named preset.
-- Call when you need to create a new preset stack.
local ok, obj = pcall(function() return lurek.effect.newPresetStack("name", 100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newPresetStack ok=", ok)

--@api-stub: lurek.effect.newPass
-- Creates a custom-shader post-processing effect (alias for newCustomEffect).
-- Call when you need to create a new pass.
local ok, obj = pcall(function() return lurek.effect.newPass(1) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newPass ok=", ok)

--@api-stub: lurek.effect.getEffectTypes
-- Returns the list of all built-in effect type names.
-- Call when you need to read effect types.
local ok, value = pcall(function() return lurek.effect.getEffectTypes() end)
local v = ok and value or "(unavailable)"
print("lurek.effect.getEffectTypes ->", v)

--@api-stub: lurek.effect.newImageEffect
-- Creates a new per-image effect chain.
-- Accepts:.
local ok, obj = pcall(function() return lurek.effect.newImageEffect({}) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newImageEffect ok=", ok)

--@api-stub: lurek.effect.newOverlay
-- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
-- Call when you need to create a new overlay.
local ok, obj = pcall(function() return lurek.effect.newOverlay(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newOverlay ok=", ok)

--@api-stub: lurek.effect.newTransition
-- Creates a new screen-transition controller.
-- `kind` is one of:.
local ok, obj = pcall(function() return lurek.effect.newTransition(nil, 1.0, {1, 1, 1, 1}) end)
if ok and obj then print("created:", obj) end
print("lurek.effect.newTransition ok=", ok)

--@api-stub: lurek.effect.setShaderErrorDisplay
-- Enables or disables the effect that renders shader compile errors as red text.
-- Call when you need to assign shader error display.
local ok, err = pcall(function() lurek.effect.setShaderErrorDisplay(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.effect.setShaderErrorDisplay applied=", ok)

--@api-stub: lurek.effect.getShaderErrorDisplay
-- Returns whether shader error display is currently enabled.
-- Call when you need to read shader error display.
local ok, value = pcall(function() return lurek.effect.getShaderErrorDisplay() end)
local v = ok and value or "(unavailable)"
print("lurek.effect.getShaderErrorDisplay ->", v)

-- ── PostFxEffect methods ──

--@api-stub: PostFxEffect:getTypeName
-- Returns the display name of this effect type.
-- Call when you need to read type name.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:getTypeName() end)
  print("PostFxEffect:getTypeName ->", ok, result)
end

--@api-stub: PostFxEffect:isBuiltIn
-- Returns true if this is a built-in effect, false if custom.
-- Call when you need to check is built in.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:isBuiltIn() end)
  print("PostFxEffect:isBuiltIn ->", ok, result)
end

--@api-stub: PostFxEffect:isEnabled
-- Returns whether this effect is currently active.
-- Call when you need to check is enabled.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:isEnabled() end)
  print("PostFxEffect:isEnabled ->", ok, result)
end

--@api-stub: PostFxEffect:setEnabled
-- Enables or disables this effect.
-- Call when you need to assign enabled.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(nil) end)
  print("PostFxEffect:setEnabled ->", ok, result)
end

--@api-stub: PostFxEffect:setParameter
-- Sets a named float parameter on this effect.
-- Call when you need to assign parameter.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setParameter("name", nil) end)
  print("PostFxEffect:setParameter ->", ok, result)
end

--@api-stub: PostFxEffect:hasParameter
-- Returns true if the named parameter exists on this effect.
-- Call when you need to check has parameter.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:hasParameter("name") end)
  print("PostFxEffect:hasParameter ->", ok, result)
end

--@api-stub: PostFxEffect:getParameterNames
-- Returns a list of all parameter names on this effect.
-- Call when you need to read parameter names.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:getParameterNames() end)
  print("PostFxEffect:getParameterNames ->", ok, result)
end

--@api-stub: PostFxEffect:getEffectType
-- Returns the type name of this effect (alias for getTypeName).
-- Call when you need to read effect type.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:getEffectType() end)
  print("PostFxEffect:getEffectType ->", ok, result)
end

--@api-stub: PostFxEffect:getType
-- Returns the type name of this effect (alias for getTypeName).
-- Call when you need to read type.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("PostFxEffect:getType ->", ok, result)
end

--@api-stub: PostFxEffect:type
-- Returns the type name "PostFxEffect".
-- Call when you need to invoke type.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("PostFxEffect:type ->", ok, result)
end

--@api-stub: PostFxEffect:typeOf
-- Returns true when the given name matches "PostFxEffect" or a parent type.
-- Call when you need to invoke type of.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("PostFxEffect:typeOf ->", ok, result)
end

--@api-stub: PostFxEffect:setThreshold
-- Sets the threshold parameter of this effect.
-- Call when you need to assign threshold.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setThreshold(nil) end)
  print("PostFxEffect:setThreshold ->", ok, result)
end

--@api-stub: PostFxEffect:setIntensity
-- Sets the intensity parameter of this effect.
-- Call when you need to assign intensity.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setIntensity(nil) end)
  print("PostFxEffect:setIntensity ->", ok, result)
end

--@api-stub: PostFxEffect:setRadius
-- Sets the radius parameter of this effect.
-- Call when you need to assign radius.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setRadius(nil) end)
  print("PostFxEffect:setRadius ->", ok, result)
end

--@api-stub: PostFxEffect:setStrength
-- Sets the strength parameter of this effect.
-- Call when you need to assign strength.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setStrength(nil) end)
  print("PostFxEffect:setStrength ->", ok, result)
end

--@api-stub: PostFxEffect:setScanlineStrength
-- Sets the scanline strength parameter of this effect.
-- Call when you need to assign scanline strength.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setScanlineStrength(nil) end)
  print("PostFxEffect:setScanlineStrength ->", ok, result)
end

--@api-stub: PostFxEffect:setOffset
-- Sets the offset parameter of this effect.
-- Call when you need to assign offset.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setOffset(nil) end)
  print("PostFxEffect:setOffset ->", ok, result)
end

--@api-stub: PostFxEffect:setBrightness
-- Sets the brightness parameter of this effect.
-- Call when you need to assign brightness.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setBrightness(nil) end)
  print("PostFxEffect:setBrightness ->", ok, result)
end

--@api-stub: PostFxEffect:setContrast
-- Sets the contrast parameter of this effect.
-- Call when you need to assign contrast.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setContrast(nil) end)
  print("PostFxEffect:setContrast ->", ok, result)
end

--@api-stub: PostFxEffect:setSaturation
-- Sets the saturation parameter of this effect.
-- Call when you need to assign saturation.
-- Build a PostFxEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxEffect(...)
if instance then
  local ok, result = pcall(function() return instance:setSaturation(nil) end)
  print("PostFxEffect:setSaturation ->", ok, result)
end

-- ── PostFxStack methods ──

--@api-stub: PostFxStack:add
-- Appends a PostFxEffect to the end of the pipeline.
-- Call when you need to invoke add.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:add(nil) end)
  print("PostFxStack:add ->", ok, result)
end

--@api-stub: PostFxStack:remove
-- Removes the given PostFxEffect from the pipeline.
-- Call when you need to invoke remove.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:remove(nil) end)
  print("PostFxStack:remove ->", ok, result)
end

--@api-stub: PostFxStack:isEnabled
-- Returns whether the effect at the given 1-based position is enabled.
-- Call when you need to check is enabled.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:isEnabled(nil) end)
  print("PostFxStack:isEnabled ->", ok, result)
end

--@api-stub: PostFxStack:getEffectCount
-- Returns the number of effects in the pipeline.
-- Call when you need to read effect count.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getEffectCount() end)
  print("PostFxStack:getEffectCount ->", ok, result)
end

--@api-stub: PostFxStack:getEffect
-- Returns the effect at the given 1-based position, or nil.
-- Call when you need to read effect.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getEffect(1) end)
  print("PostFxStack:getEffect ->", ok, result)
end

--@api-stub: PostFxStack:getEnabledEffects
-- Returns a list of currently enabled effect objects.
-- Call when you need to read enabled effects.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getEnabledEffects() end)
  print("PostFxStack:getEnabledEffects ->", ok, result)
end

--@api-stub: PostFxStack:getWidth
-- Returns the width of the render target.
-- Call when you need to read width.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("PostFxStack:getWidth ->", ok, result)
end

--@api-stub: PostFxStack:getHeight
-- Returns the height of the render target.
-- Call when you need to read height.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("PostFxStack:getHeight ->", ok, result)
end

--@api-stub: PostFxStack:getDimensions
-- Returns width and height of the render target.
-- Call when you need to read dimensions.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("PostFxStack:getDimensions ->", ok, result)
end

--@api-stub: PostFxStack:resize
-- Resizes the render target to the given dimensions.
-- Call when you need to invoke resize.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:resize(100, 100) end)
  print("PostFxStack:resize ->", ok, result)
end

--@api-stub: PostFxStack:len
-- Returns the total number of effect slots in the pipeline.
-- Call when you need to invoke len.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("PostFxStack:len ->", ok, result)
end

--@api-stub: PostFxStack:isEmpty
-- Returns true if the pipeline has no effect slots.
-- Call when you need to check is empty.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("PostFxStack:isEmpty ->", ok, result)
end

--@api-stub: PostFxStack:clear
-- Removes all effects from the pipeline.
-- Call when you need to invoke clear.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("PostFxStack:clear ->", ok, result)
end

--@api-stub: PostFxStack:dedup
-- Removes duplicate effects from the pipeline, keeping the first occurrence.
-- Call when you need to invoke dedup.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:dedup() end)
  print("PostFxStack:dedup ->", ok, result)
end

--@api-stub: PostFxStack:isCapturing
-- Returns whether the stack is currently capturing the scene.
-- Call when you need to check is capturing.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:isCapturing() end)
  print("PostFxStack:isCapturing ->", ok, result)
end

--@api-stub: PostFxStack:beginCapture
-- Begins capturing the scene for post-processing.
-- Call when you need to invoke begin capture.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:beginCapture() end)
  print("PostFxStack:beginCapture ->", ok, result)
end

--@api-stub: PostFxStack:endCapture
-- Ends scene capture for post-processing.
-- Call when you need to invoke end capture.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:endCapture() end)
  print("PostFxStack:endCapture ->", ok, result)
end

--@api-stub: PostFxStack:apply
-- Applies all enabled effects in the stack and composites the result to screen.
-- Call when you need to invoke apply.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:apply() end)
  print("PostFxStack:apply ->", ok, result)
end

--@api-stub: PostFxStack:type
-- Returns the type name "PostFxStack".
-- Call when you need to invoke type.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("PostFxStack:type ->", ok, result)
end

--@api-stub: PostFxStack:typeOf
-- Returns true when the given name matches "PostFxStack" or a parent type.
-- Call when you need to invoke type of.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("PostFxStack:typeOf ->", ok, result)
end

--@api-stub: PostFxStack:setFeedback
-- Sets the feedback loop intensity.
-- At `0.0` (default) there is no.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:setFeedback(1) end)
  print("PostFxStack:setFeedback ->", ok, result)
end

--@api-stub: PostFxStack:getFeedback
-- Returns the current feedback loop intensity `[0.0, 1.0]`.
-- Call when you need to read feedback.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:getFeedback() end)
  print("PostFxStack:getFeedback ->", ok, result)
end

--@api-stub: PostFxStack:clearFeedback
-- Resets the feedback intensity to `0.0` (disables feedback).
-- Call when you need to invoke clear feedback.
-- Build a PostFxStack via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newPostFxStack(...)
if instance then
  local ok, result = pcall(function() return instance:clearFeedback() end)
  print("PostFxStack:clearFeedback ->", ok, result)
end

-- ── ImageEffect methods ──

--@api-stub: ImageEffect:addEffect
-- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
-- Call when you need to add effect.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:addEffect("name") end)
  print("ImageEffect:addEffect ->", ok, result)
end

--@api-stub: ImageEffect:getEffect
-- Returns the effect at the given 1-based index or with the given type name.
-- Call when you need to read effect.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:getEffect("key") end)
  print("ImageEffect:getEffect ->", ok, result)
end

--@api-stub: ImageEffect:removeEffect
-- Removes the effect at the given 1-based index or with the given type name.
-- Call when you need to remove effect.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:removeEffect("key") end)
  print("ImageEffect:removeEffect ->", ok, result)
end

--@api-stub: ImageEffect:clearEffects
-- Removes all effects from the chain.
-- Call when you need to invoke clear effects.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:clearEffects() end)
  print("ImageEffect:clearEffects ->", ok, result)
end

--@api-stub: ImageEffect:clear
-- Removes all effects from the chain (alias for clearEffects).
-- Call when you need to invoke clear.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("ImageEffect:clear ->", ok, result)
end

--@api-stub: ImageEffect:effectCount
-- Returns the number of effects in the chain.
-- Call when you need to invoke effect count.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:effectCount() end)
  print("ImageEffect:effectCount ->", ok, result)
end

--@api-stub: ImageEffect:getEffectCount
-- Returns the number of effects in the chain (alias for effectCount).
-- Call when you need to read effect count.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:getEffectCount() end)
  print("ImageEffect:getEffectCount ->", ok, result)
end

--@api-stub: ImageEffect:clone
-- Returns a deep copy of this ImageEffect chain.
-- Call when you need to invoke clone.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("ImageEffect:clone ->", ok, result)
end

--@api-stub: ImageEffect:save
-- Stub: no-op serialisation placeholder.
-- Call when you need to invoke save.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:save() end)
  print("ImageEffect:save ->", ok, result)
end

--@api-stub: ImageEffect:type
-- Returns the type name "ImageEffect".
-- Call when you need to invoke type.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ImageEffect:type ->", ok, result)
end

--@api-stub: ImageEffect:typeOf
-- Returns true when the given name matches "ImageEffect" or a parent type.
-- Call when you need to invoke type of.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("ImageEffect:typeOf ->", ok, result)
end

--@api-stub: ImageEffect:removeByIndex
-- Removes the effect at the given 0-based index from the chain.
-- Call when you need to remove by index.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:removeByIndex(1) end)
  print("ImageEffect:removeByIndex ->", ok, result)
end

--@api-stub: ImageEffect:removeByName
-- Removes the first effect matching the given type name.
-- Call when you need to remove by name.
-- Build a ImageEffect via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newImageEffect(...)
if instance then
  local ok, result = pcall(function() return instance:removeByName("name") end)
  print("ImageEffect:removeByName ->", ok, result)
end

-- ── Overlay methods ──

--@api-stub: Overlay:update
-- Advances all effect subsystems by the given delta time.
-- Call when you need to invoke update.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Overlay:update ->", ok, result)
end

--@api-stub: Overlay:triggerLightning
-- Triggers a lightning flash effect.
-- Call when you need to invoke trigger lightning.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:triggerLightning() end)
  print("Overlay:triggerLightning ->", ok, result)
end

--@api-stub: Overlay:getShakeOffset
-- Returns the current shake displacement as x, y.
-- Call when you need to read shake offset.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getShakeOffset() end)
  print("Overlay:getShakeOffset ->", ok, result)
end

--@api-stub: Overlay:isActive
-- Returns true if any effect subsystem is currently active.
-- Call when you need to check is active.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("Overlay:isActive ->", ok, result)
end

--@api-stub: Overlay:clear
-- Resets all effect subsystems to their default inactive state.
-- Call when you need to invoke clear.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Overlay:clear ->", ok, result)
end

--@api-stub: Overlay:resize
-- Resizes the effect to match new window dimensions.
-- Call when you need to invoke resize.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:resize(100, 100) end)
  print("Overlay:resize ->", ok, result)
end

--@api-stub: Overlay:getWidth
-- Returns the effect width.
-- Call when you need to read width.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("Overlay:getWidth ->", ok, result)
end

--@api-stub: Overlay:getHeight
-- Returns the effect height.
-- Call when you need to read height.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("Overlay:getHeight ->", ok, result)
end

--@api-stub: Overlay:getDimensions
-- Returns the effect width and height.
-- Call when you need to read dimensions.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("Overlay:getDimensions ->", ok, result)
end

--@api-stub: Overlay:getFlashAlpha
-- Returns the current flash overlay alpha value.
-- Call when you need to read flash alpha.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getFlashAlpha() end)
  print("Overlay:getFlashAlpha ->", ok, result)
end

--@api-stub: Overlay:getLightningAlpha
-- Returns the current lightning overlay alpha value.
-- Call when you need to read lightning alpha.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getLightningAlpha() end)
  print("Overlay:getLightningAlpha ->", ok, result)
end

--@api-stub: Overlay:setAmbientEnabled
-- Enables or disables the ambient light layer.
-- Call when you need to assign ambient enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setAmbientEnabled(nil) end)
  print("Overlay:setAmbientEnabled ->", ok, result)
end

--@api-stub: Overlay:isAmbientEnabled
-- Returns whether the ambient light layer is active.
-- Call when you need to check is ambient enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isAmbientEnabled() end)
  print("Overlay:isAmbientEnabled ->", ok, result)
end

--@api-stub: Overlay:getAmbientColor
-- Returns the current ambient tint as r, g, b, a components.
-- Call when you need to read ambient color.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getAmbientColor() end)
  print("Overlay:getAmbientColor ->", ok, result)
end

--@api-stub: Overlay:setTimeOfDay
-- Sets the simulated time-of-day (0â€“24) which drives ambient colour.
-- Call when you need to assign time of day.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setTimeOfDay(nil) end)
  print("Overlay:setTimeOfDay ->", ok, result)
end

--@api-stub: Overlay:getTimeOfDay
-- Returns the current simulated time-of-day (0â€“24).
-- Call when you need to read time of day.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getTimeOfDay() end)
  print("Overlay:getTimeOfDay ->", ok, result)
end

--@api-stub: Overlay:setFogEnabled
-- Enables or disables the fog layer.
-- Call when you need to assign fog enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setFogEnabled(nil) end)
  print("Overlay:setFogEnabled ->", ok, result)
end

--@api-stub: Overlay:isFogEnabled
-- Returns whether the fog layer is active.
-- Call when you need to check is fog enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isFogEnabled() end)
  print("Overlay:isFogEnabled ->", ok, result)
end

--@api-stub: Overlay:setFogDensity
-- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
-- Call when you need to assign fog density.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setFogDensity(nil) end)
  print("Overlay:setFogDensity ->", ok, result)
end

--@api-stub: Overlay:getFogDensity
-- Returns the current fog density.
-- Call when you need to read fog density.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getFogDensity() end)
  print("Overlay:getFogDensity ->", ok, result)
end

--@api-stub: Overlay:getFogColor
-- Returns the current fog tint as r, g, b, a components.
-- Call when you need to read fog color.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getFogColor() end)
  print("Overlay:getFogColor ->", ok, result)
end

--@api-stub: Overlay:setHeatHazeEnabled
-- Enables or disables the heat-haze distortion layer.
-- Call when you need to assign heat haze enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setHeatHazeEnabled(nil) end)
  print("Overlay:setHeatHazeEnabled ->", ok, result)
end

--@api-stub: Overlay:isHeatHazeEnabled
-- Returns whether the heat-haze layer is active.
-- Call when you need to check is heat haze enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isHeatHazeEnabled() end)
  print("Overlay:isHeatHazeEnabled ->", ok, result)
end

--@api-stub: Overlay:setHeatHazeIntensity
-- Sets the heat-haze distortion intensity (0.0â€“1.0).
-- Call when you need to assign heat haze intensity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setHeatHazeIntensity(nil) end)
  print("Overlay:setHeatHazeIntensity ->", ok, result)
end

--@api-stub: Overlay:getHeatHazeIntensity
-- Returns the current heat-haze distortion intensity.
-- Call when you need to read heat haze intensity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getHeatHazeIntensity() end)
  print("Overlay:getHeatHazeIntensity ->", ok, result)
end

--@api-stub: Overlay:setVignetteEnabled
-- Enables or disables the screen-edge vignette layer.
-- Call when you need to assign vignette enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setVignetteEnabled(nil) end)
  print("Overlay:setVignetteEnabled ->", ok, result)
end

--@api-stub: Overlay:isVignetteEnabled
-- Returns whether the vignette layer is active.
-- Call when you need to check is vignette enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isVignetteEnabled() end)
  print("Overlay:isVignetteEnabled ->", ok, result)
end

--@api-stub: Overlay:setVignetteStrength
-- Sets the vignette darkening strength (0.0â€“1.0).
-- Call when you need to assign vignette strength.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setVignetteStrength(nil) end)
  print("Overlay:setVignetteStrength ->", ok, result)
end

--@api-stub: Overlay:getVignetteStrength
-- Returns the current vignette strength.
-- Call when you need to read vignette strength.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getVignetteStrength() end)
  print("Overlay:getVignetteStrength ->", ok, result)
end

--@api-stub: Overlay:setFilmGrainEnabled
-- Enables or disables the film-grain noise layer.
-- Call when you need to assign film grain enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setFilmGrainEnabled(nil) end)
  print("Overlay:setFilmGrainEnabled ->", ok, result)
end

--@api-stub: Overlay:isFilmGrainEnabled
-- Returns whether the film-grain layer is active.
-- Call when you need to check is film grain enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isFilmGrainEnabled() end)
  print("Overlay:isFilmGrainEnabled ->", ok, result)
end

--@api-stub: Overlay:setFilmGrainIntensity
-- Sets the film-grain noise intensity (0.0â€“1.0).
-- Call when you need to assign film grain intensity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setFilmGrainIntensity(nil) end)
  print("Overlay:setFilmGrainIntensity ->", ok, result)
end

--@api-stub: Overlay:getFilmGrainIntensity
-- Returns the current film-grain intensity.
-- Call when you need to read film grain intensity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getFilmGrainIntensity() end)
  print("Overlay:getFilmGrainIntensity ->", ok, result)
end

--@api-stub: Overlay:setCloudShadows
-- Enables or disables scrolling cloud-shadow projection.
-- Call when you need to assign cloud shadows.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setCloudShadows(nil) end)
  print("Overlay:setCloudShadows ->", ok, result)
end

--@api-stub: Overlay:isCloudShadowsEnabled
-- Returns whether cloud shadows are active.
-- Call when you need to check is cloud shadows enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isCloudShadowsEnabled() end)
  print("Overlay:isCloudShadowsEnabled ->", ok, result)
end

--@api-stub: Overlay:setCloudCount
-- Sets the number of cloud shadow instances to render.
-- Call when you need to assign cloud count.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setCloudCount(nil) end)
  print("Overlay:setCloudCount ->", ok, result)
end

--@api-stub: Overlay:getCloudCount
-- Returns the current cloud shadow instance count.
-- Call when you need to read cloud count.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getCloudCount() end)
  print("Overlay:getCloudCount ->", ok, result)
end

--@api-stub: Overlay:setCloudSpeed
-- Sets the horizontal scroll speed of cloud shadows in pixels per second.
-- Call when you need to assign cloud speed.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setCloudSpeed(nil) end)
  print("Overlay:setCloudSpeed ->", ok, result)
end

--@api-stub: Overlay:getCloudSpeed
-- Returns the current cloud shadow scroll speed.
-- Call when you need to read cloud speed.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getCloudSpeed() end)
  print("Overlay:getCloudSpeed ->", ok, result)
end

--@api-stub: Overlay:setCloudScale
-- Sets the scale multiplier applied to each cloud shadow.
-- Call when you need to assign cloud scale.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setCloudScale(nil) end)
  print("Overlay:setCloudScale ->", ok, result)
end

--@api-stub: Overlay:getCloudScale
-- Returns the current cloud shadow scale.
-- Call when you need to read cloud scale.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getCloudScale() end)
  print("Overlay:getCloudScale ->", ok, result)
end

--@api-stub: Overlay:setCloudOpacity
-- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
-- Call when you need to assign cloud opacity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setCloudOpacity(nil) end)
  print("Overlay:setCloudOpacity ->", ok, result)
end

--@api-stub: Overlay:getCloudOpacity
-- Returns the current cloud shadow opacity.
-- Call when you need to read cloud opacity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getCloudOpacity() end)
  print("Overlay:getCloudOpacity ->", ok, result)
end

--@api-stub: Overlay:setWeatherEnabled
-- Enables or disables the weather particle system.
-- Call when you need to assign weather enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setWeatherEnabled(nil) end)
  print("Overlay:setWeatherEnabled ->", ok, result)
end

--@api-stub: Overlay:isWeatherEnabled
-- Returns whether the weather particle system is active.
-- Call when you need to check is weather enabled.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isWeatherEnabled() end)
  print("Overlay:isWeatherEnabled ->", ok, result)
end

--@api-stub: Overlay:setWeather
-- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
-- Call when you need to assign weather.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setWeather("name") end)
  print("Overlay:setWeather ->", ok, result)
end

--@api-stub: Overlay:getWeather
-- Returns the name of the current weather type.
-- Call when you need to read weather.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getWeather() end)
  print("Overlay:getWeather ->", ok, result)
end

--@api-stub: Overlay:setWeatherIntensity
-- Sets the particle spawn rate multiplier (0.0â€“1.0).
-- Call when you need to assign weather intensity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setWeatherIntensity(nil) end)
  print("Overlay:setWeatherIntensity ->", ok, result)
end

--@api-stub: Overlay:getWeatherIntensity
-- Returns the current weather intensity.
-- Call when you need to read weather intensity.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getWeatherIntensity() end)
  print("Overlay:getWeatherIntensity ->", ok, result)
end

--@api-stub: Overlay:setWindDirection
-- Sets the wind direction in radians (0 = right, Ď€/2 = down).
-- Call when you need to assign wind direction.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setWindDirection(nil) end)
  print("Overlay:setWindDirection ->", ok, result)
end

--@api-stub: Overlay:getWindDirection
-- Returns the current wind direction in radians.
-- Call when you need to read wind direction.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getWindDirection() end)
  print("Overlay:getWindDirection ->", ok, result)
end

--@api-stub: Overlay:setWindSpeed
-- Sets the wind speed applied to weather particles in units per second.
-- Call when you need to assign wind speed.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setWindSpeed(nil) end)
  print("Overlay:setWindSpeed ->", ok, result)
end

--@api-stub: Overlay:getWindSpeed
-- Returns the current wind speed.
-- Call when you need to read wind speed.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getWindSpeed() end)
  print("Overlay:getWindSpeed ->", ok, result)
end

--@api-stub: Overlay:getLightningColor
-- Returns the lightning flash tint as r, g, b, a components.
-- Call when you need to read lightning color.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getLightningColor() end)
  print("Overlay:getLightningColor ->", ok, result)
end

--@api-stub: Overlay:isFlashing
-- Returns true while a flash effect is in progress.
-- Call when you need to check is flashing.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isFlashing() end)
  print("Overlay:isFlashing ->", ok, result)
end

--@api-stub: Overlay:shake
-- Triggers a camera shake; duration defaults to 0.5 s.
-- Call when you need to invoke shake.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:shake(nil, nil) end)
  print("Overlay:shake ->", ok, result)
end

--@api-stub: Overlay:isShaking
-- Returns true while a shake effect is in progress.
-- Call when you need to check is shaking.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isShaking() end)
  print("Overlay:isShaking ->", ok, result)
end

--@api-stub: Overlay:isFading
-- Returns true while a fade effect is in progress.
-- Call when you need to check is fading.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:isFading() end)
  print("Overlay:isFading ->", ok, result)
end

--@api-stub: Overlay:render
-- Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
-- Call when you need to invoke render.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:render() end)
  print("Overlay:render ->", ok, result)
end

--@api-stub: Overlay:drawToImage
-- Renders the effect state (flash, fade, effects) to a CPU ImageData.
-- Call when you need to render to image.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("Overlay:drawToImage ->", ok, result)
end

--@api-stub: Overlay:setCustomShader
-- Assigns a custom shader name to the effect, or clears it when `nil` is passed.
-- Call when you need to assign custom shader.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:setCustomShader("name") end)
  print("Overlay:setCustomShader ->", ok, result)
end

--@api-stub: Overlay:getWater
-- Returns a table describing the current water overlay state.
-- Call when you need to read water.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:getWater() end)
  print("Overlay:getWater ->", ok, result)
end

--@api-stub: Overlay:type
-- Returns the type name of this object ("Overlay").
-- Call when you need to invoke type.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Overlay:type ->", ok, result)
end

--@api-stub: Overlay:typeOf
-- Returns true if this object is of the given type ("Object" or "Overlay").
-- Call when you need to invoke type of.
-- Build a Overlay via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newOverlay(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Overlay:typeOf ->", ok, result)
end

-- ── mlua methods ──

--@api-stub: mlua:play
-- Starts the transition playing forward (scene fades/wipes out).
-- Call when you need to invoke play.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:play() end)
  print("mlua:play ->", ok, result)
end

--@api-stub: mlua:reverse
-- Starts the transition in reverse (scene fades/wipes in).
-- Call when you need to invoke reverse.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:reverse() end)
  print("mlua:reverse ->", ok, result)
end

--@api-stub: mlua:update
-- Advances the transition by `dt` seconds.
-- Returns `true` while.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("mlua:update ->", ok, result)
end

--@api-stub: mlua:progress
-- Returns the fractional progress `[0, 1]` of the transition, taking.
-- Call when you need to invoke progress.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:progress() end)
  print("mlua:progress ->", ok, result)
end

--@api-stub: mlua:isActive
-- Returns `true` while the transition is running.
-- Call when you need to check is active.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("mlua:isActive ->", ok, result)
end

--@api-stub: mlua:isDone
-- Returns `true` after the transition has completed.
-- Call when you need to check is done.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:isDone() end)
  print("mlua:isDone ->", ok, result)
end

--@api-stub: mlua:kind
-- Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,.
-- Call when you need to invoke kind.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:kind() end)
  print("mlua:kind ->", ok, result)
end

--@api-stub: mlua:color
-- Returns the fill color as four numbers: `r, g, b, a`.
-- Call when you need to invoke color.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:color() end)
  print("mlua:color ->", ok, result)
end

--@api-stub: mlua:setColor
-- Updates the fill color from `{r, g, b, a?}`.
-- Call when you need to assign color.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:setColor() end)
  print("mlua:setColor ->", ok, result)
end

--@api-stub: mlua:type
-- Type.
-- Call when you need to invoke type.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("mlua:type ->", ok, result)
end

--@api-stub: mlua:typeOf
-- Type of.
-- Call when you need to invoke type of.
-- Build a mlua via the appropriate lurek.effect.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.effect.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("mlua:typeOf ->", ok, result)
end

