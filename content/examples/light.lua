-- content/examples/light.lua
-- Practical usage examples for the lurek.light API (83 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.light.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/light.lua

print("[example] lurek.light — 83 API entries")

-- ── lurek.light.* free functions ──

--@api-stub: lurek.light.newLight
-- Creates a new light at (x, y) with the given radius and optional settings.
-- Call when you need to create a new light.
local ok, obj = pcall(function() return lurek.light.newLight(0, 0, nil, {}) end)
if ok and obj then print("created:", obj) end
print("lurek.light.newLight ok=", ok)

--@api-stub: lurek.light.newOccluder
-- Creates a new shadow occluder from a vertex table and optional settings.
-- Call when you need to create a new occluder.
local ok, obj = pcall(function() return lurek.light.newOccluder(nil, {}) end)
if ok and obj then print("created:", obj) end
print("lurek.light.newOccluder ok=", ok)

--@api-stub: lurek.light.setAmbient
-- Sets the global ambient light color.
-- Call when you need to assign ambient.
local ok, err = pcall(function() lurek.light.setAmbient(1, 1, 1, 1) end)
if not ok then print("set skipped:", err) end
print("lurek.light.setAmbient applied=", ok)

--@api-stub: lurek.light.getAmbient
-- Returns the global ambient light color as (r, g, b, a).
-- Call when you need to read ambient.
local ok, value = pcall(function() return lurek.light.getAmbient() end)
local v = ok and value or "(unavailable)"
print("lurek.light.getAmbient ->", v)

--@api-stub: lurek.light.setEnabled
-- Sets whether the lighting system is active.
-- Call when you need to assign enabled.
local ok, err = pcall(function() lurek.light.setEnabled(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.light.setEnabled applied=", ok)

--@api-stub: lurek.light.isEnabled
-- Returns whether the lighting system is active.
-- Call when you need to check is enabled.
local ok, result = pcall(function() return lurek.light.isEnabled() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.light.isEnabled ok=", ok)

--@api-stub: lurek.light.getLightCount
-- Returns the number of lights in the world.
-- Call when you need to read light count.
local ok, value = pcall(function() return lurek.light.getLightCount() end)
local v = ok and value or "(unavailable)"
print("lurek.light.getLightCount ->", v)

--@api-stub: lurek.light.getOccluderCount
-- Returns the number of occluders in the world.
-- Call when you need to read occluder count.
local ok, value = pcall(function() return lurek.light.getOccluderCount() end)
local v = ok and value or "(unavailable)"
print("lurek.light.getOccluderCount ->", v)

--@api-stub: lurek.light.getMaxLights
-- Returns the maximum number of lights processed per frame.
-- Call when you need to read max lights.
local ok, value = pcall(function() return lurek.light.getMaxLights() end)
local v = ok and value or "(unavailable)"
print("lurek.light.getMaxLights ->", v)

--@api-stub: lurek.light.setMaxLights
-- Sets the maximum number of lights processed per frame (clamped 1â€“256).
-- Call when you need to assign max lights.
local ok, err = pcall(function() lurek.light.setMaxLights(10) end)
if not ok then print("set skipped:", err) end
print("lurek.light.setMaxLights applied=", ok)

--@api-stub: lurek.light.clear
-- Removes all lights and occluders, resets ambient to default.
-- Call when you need to invoke clear.
local ok, err = pcall(function() lurek.light.clear() end)
if not ok then print("skipped:", err) end
print("lurek.light.clear cleared=", ok)

--@api-stub: lurek.light.setGroupEnabled
-- Sets the enabled state for all lights in the given group.
-- Call when you need to assign group enabled.
local ok, err = pcall(function() lurek.light.setGroupEnabled(1, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.light.setGroupEnabled applied=", ok)

--@api-stub: lurek.light.setGroupIntensity
-- Sets the intensity for all lights in the given group.
-- Call when you need to assign group intensity.
local ok, err = pcall(function() lurek.light.setGroupIntensity(1, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.light.setGroupIntensity applied=", ok)

--@api-stub: lurek.light.setGroupColor
-- Sets the color for all lights in the given group.
-- Call when you need to assign group color.
local ok, err = pcall(function() lurek.light.setGroupColor(1, 1, 1, 1, 1) end)
if not ok then print("set skipped:", err) end
print("lurek.light.setGroupColor applied=", ok)

--@api-stub: lurek.light.getGroupCount
-- Returns the number of lights in the given group.
-- Call when you need to read group count.
local ok, value = pcall(function() return lurek.light.getGroupCount(1) end)
local v = ok and value or "(unavailable)"
print("lurek.light.getGroupCount ->", v)

--@api-stub: lurek.light.advanceFlickers
-- Advances flicker phase for all lights with flicker enabled.
-- Call when you need to invoke advance flickers.
local ok, result = pcall(function() return lurek.light.advanceFlickers(1.0) end)
if ok then print("lurek.light.advanceFlickers ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.light.syncAmbient
-- Returns the current ambient light colour as (r, g, b, a).
-- Call when you need to invoke sync ambient.
local ok, result = pcall(function() return lurek.light.syncAmbient() end)
if ok then print("lurek.light.syncAmbient ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.light.getGodRayHints
-- Returns a list of directional light hints for god-ray rendering.
-- Call when you need to read god ray hints.
local ok, value = pcall(function() return lurek.light.getGodRayHints() end)
local v = ok and value or "(unavailable)"
print("lurek.light.getGodRayHints ->", v)

-- ── Light methods ──

--@api-stub: Light:setPosition
-- Sets the light's world-space position.
-- Call when you need to assign position.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("Light:setPosition ->", ok, result)
end

--@api-stub: Light:getPosition
-- Returns the light's world-space position.
-- Call when you need to read position.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("Light:getPosition ->", ok, result)
end

--@api-stub: Light:setRadius
-- Sets the light's influence radius.
-- Call when you need to assign radius.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setRadius(1) end)
  print("Light:setRadius ->", ok, result)
end

--@api-stub: Light:getRadius
-- Returns the light's influence radius.
-- Call when you need to read radius.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getRadius() end)
  print("Light:getRadius ->", ok, result)
end

--@api-stub: Light:getColor
-- Returns the light's tint color as (r, g, b, a).
-- Call when you need to read color.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getColor() end)
  print("Light:getColor ->", ok, result)
end

--@api-stub: Light:setIntensity
-- Sets the brightness multiplier.
-- Call when you need to assign intensity.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setIntensity(nil) end)
  print("Light:setIntensity ->", ok, result)
end

--@api-stub: Light:getIntensity
-- Returns the brightness multiplier.
-- Call when you need to read intensity.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getIntensity() end)
  print("Light:getIntensity ->", ok, result)
end

--@api-stub: Light:setEnergy
-- Sets the energy scaling factor.
-- Call when you need to assign energy.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setEnergy(nil) end)
  print("Light:setEnergy ->", ok, result)
end

--@api-stub: Light:getEnergy
-- Returns the energy scaling factor.
-- Call when you need to read energy.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getEnergy() end)
  print("Light:getEnergy ->", ok, result)
end

--@api-stub: Light:setBlendMode
-- Sets the blend mode ('add', 'sub', or 'mix').
-- Call when you need to assign blend mode.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setBlendMode(nil) end)
  print("Light:setBlendMode ->", ok, result)
end

--@api-stub: Light:getBlendMode
-- Returns the blend mode as a string.
-- Call when you need to read blend mode.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getBlendMode() end)
  print("Light:getBlendMode ->", ok, result)
end

--@api-stub: Light:setFalloff
-- Sets the falloff mode ('linear', 'smooth', or 'constant').
-- Call when you need to assign falloff.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setFalloff(nil) end)
  print("Light:setFalloff ->", ok, result)
end

--@api-stub: Light:getFalloff
-- Returns the falloff mode as a string.
-- Call when you need to read falloff.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getFalloff() end)
  print("Light:getFalloff ->", ok, result)
end

--@api-stub: Light:setShadowEnabled
-- Sets whether this light casts shadows.
-- Call when you need to assign shadow enabled.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setShadowEnabled(1) end)
  print("Light:setShadowEnabled ->", ok, result)
end

--@api-stub: Light:isShadowEnabled
-- Returns whether this light casts shadows.
-- Call when you need to check is shadow enabled.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:isShadowEnabled() end)
  print("Light:isShadowEnabled ->", ok, result)
end

--@api-stub: Light:getShadowColor
-- Returns the shadow region color as (r, g, b, a).
-- Call when you need to read shadow color.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getShadowColor() end)
  print("Light:getShadowColor ->", ok, result)
end

--@api-stub: Light:setShadowFilter
-- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
-- Call when you need to assign shadow filter.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setShadowFilter(nil) end)
  print("Light:setShadowFilter ->", ok, result)
end

--@api-stub: Light:getShadowFilter
-- Returns the shadow edge filter as a string.
-- Call when you need to read shadow filter.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getShadowFilter() end)
  print("Light:getShadowFilter ->", ok, result)
end

--@api-stub: Light:setShadowSmooth
-- Sets the shadow edge smoothing factor.
-- Call when you need to assign shadow smooth.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setShadowSmooth(nil) end)
  print("Light:setShadowSmooth ->", ok, result)
end

--@api-stub: Light:getShadowSmooth
-- Returns the shadow edge smoothing factor.
-- Call when you need to read shadow smooth.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getShadowSmooth() end)
  print("Light:getShadowSmooth ->", ok, result)
end

--@api-stub: Light:setLightMask
-- Sets the light interaction bitmask.
-- Call when you need to assign light mask.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setLightMask(nil) end)
  print("Light:setLightMask ->", ok, result)
end

--@api-stub: Light:getLightMask
-- Returns the light interaction bitmask.
-- Call when you need to read light mask.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getLightMask() end)
  print("Light:getLightMask ->", ok, result)
end

--@api-stub: Light:setShadowMask
-- Sets the shadow casting bitmask.
-- Call when you need to assign shadow mask.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setShadowMask(nil) end)
  print("Light:setShadowMask ->", ok, result)
end

--@api-stub: Light:getShadowMask
-- Returns the shadow casting bitmask.
-- Call when you need to read shadow mask.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getShadowMask() end)
  print("Light:getShadowMask ->", ok, result)
end

--@api-stub: Light:setEnabled
-- Sets whether this light is active.
-- Call when you need to assign enabled.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(1) end)
  print("Light:setEnabled ->", ok, result)
end

--@api-stub: Light:isEnabled
-- Returns whether this light is active.
-- Call when you need to check is enabled.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:isEnabled() end)
  print("Light:isEnabled ->", ok, result)
end

--@api-stub: Light:setLightType
-- Sets the geometric light type ('point', 'directional', or 'spot').
-- Call when you need to assign light type.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setLightType(nil) end)
  print("Light:setLightType ->", ok, result)
end

--@api-stub: Light:getLightType
-- Returns the geometric light type as a string.
-- Call when you need to read light type.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getLightType() end)
  print("Light:getLightType ->", ok, result)
end

--@api-stub: Light:setDirection
-- Sets the direction angle in radians.
-- Call when you need to assign direction.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setDirection("dir") end)
  print("Light:setDirection ->", ok, result)
end

--@api-stub: Light:getDirection
-- Returns the direction angle in radians.
-- Call when you need to read direction.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getDirection() end)
  print("Light:getDirection ->", ok, result)
end

--@api-stub: Light:setInnerAngle
-- Sets the inner cone angle in radians for spot lights.
-- Call when you need to assign inner angle.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setInnerAngle(1) end)
  print("Light:setInnerAngle ->", ok, result)
end

--@api-stub: Light:getInnerAngle
-- Returns the inner cone angle in radians.
-- Call when you need to read inner angle.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getInnerAngle() end)
  print("Light:getInnerAngle ->", ok, result)
end

--@api-stub: Light:setOuterAngle
-- Sets the outer cone angle in radians for spot lights.
-- Call when you need to assign outer angle.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setOuterAngle(1) end)
  print("Light:setOuterAngle ->", ok, result)
end

--@api-stub: Light:getOuterAngle
-- Returns the outer cone angle in radians.
-- Call when you need to read outer angle.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getOuterAngle() end)
  print("Light:getOuterAngle ->", ok, result)
end

--@api-stub: Light:setAttenuation
-- Sets the custom attenuation coefficients (constant, linear, quadratic).
-- Call when you need to assign attenuation.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setAttenuation(nil, nil, nil) end)
  print("Light:setAttenuation ->", ok, result)
end

--@api-stub: Light:getAttenuation
-- Returns the custom attenuation coefficients as (constant, linear, quadratic).
-- Call when you need to read attenuation.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getAttenuation() end)
  print("Light:getAttenuation ->", ok, result)
end

--@api-stub: Light:setFlicker
-- Sets the flicker effect speed and strength (enables flicker).
-- Call when you need to assign flicker.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setFlicker(nil, "strength value") end)
  print("Light:setFlicker ->", ok, result)
end

--@api-stub: Light:getFlicker
-- Returns the flicker effect speed and strength.
-- Call when you need to read flicker.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getFlicker() end)
  print("Light:getFlicker ->", ok, result)
end

--@api-stub: Light:setFlickerEnabled
-- Sets whether the flicker effect is active.
-- Call when you need to assign flicker enabled.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setFlickerEnabled(1) end)
  print("Light:setFlickerEnabled ->", ok, result)
end

--@api-stub: Light:isFlickerEnabled
-- Returns whether the flicker effect is active.
-- Call when you need to check is flicker enabled.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:isFlickerEnabled() end)
  print("Light:isFlickerEnabled ->", ok, result)
end

--@api-stub: Light:setGroupId
-- Sets the group identifier for batch operations.
-- Call when you need to assign group id.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setGroupId(1) end)
  print("Light:setGroupId ->", ok, result)
end

--@api-stub: Light:getGroupId
-- Returns the group identifier.
-- Call when you need to read group id.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getGroupId() end)
  print("Light:getGroupId ->", ok, result)
end

--@api-stub: Light:setVolumetric
-- Sets whether this light hints at volumetric scattering.
-- Call when you need to assign volumetric.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setVolumetric(1) end)
  print("Light:setVolumetric ->", ok, result)
end

--@api-stub: Light:isVolumetric
-- Returns whether this light hints at volumetric scattering.
-- Call when you need to check is volumetric.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:isVolumetric() end)
  print("Light:isVolumetric ->", ok, result)
end

--@api-stub: Light:remove
-- Removes this light from the world.
-- Call when you need to invoke remove.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:remove() end)
  print("Light:remove ->", ok, result)
end

--@api-stub: Light:isValid
-- Returns whether this light handle is still valid.
-- Call when you need to check is valid.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:isValid() end)
  print("Light:isValid ->", ok, result)
end

--@api-stub: Light:addFlicker
-- Convenience method to set a flicker effect using amplitude range and.
-- Call when you need to add flicker.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:addFlicker(0, 100, nil) end)
  print("Light:addFlicker ->", ok, result)
end

--@api-stub: Light:updateTransition
-- Advances the active transition by `dt` seconds and applies the.
-- Call when you need to invoke update transition.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:updateTransition(1.0) end)
  print("Light:updateTransition ->", ok, result)
end

--@api-stub: Light:stopTransition
-- Cancels the active light transition.
-- Call when you need to invoke stop transition.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:stopTransition() end)
  print("Light:stopTransition ->", ok, result)
end

--@api-stub: Light:transitionProgress
-- Returns the fractional progress `[0, 1]` of the active transition,.
-- Call when you need to invoke transition progress.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:transitionProgress() end)
  print("Light:transitionProgress ->", ok, result)
end

--@api-stub: Light:setCookie
-- Sets the texture path used as a light cookie (mask) for projection.
-- Call when you need to assign cookie.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:setCookie("path") end)
  print("Light:setCookie ->", ok, result)
end

--@api-stub: Light:getCookie
-- Returns the current cookie texture path, or `nil` if unset.
-- Call when you need to read cookie.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:getCookie() end)
  print("Light:getCookie ->", ok, result)
end

--@api-stub: Light:clearCookie
-- Removes the cookie texture assignment.
-- Call when you need to invoke clear cookie.
-- Build a Light via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newLight(...)
if instance then
  local ok, result = pcall(function() return instance:clearCookie() end)
  print("Light:clearCookie ->", ok, result)
end

-- ── Occluder methods ──

--@api-stub: Occluder:setVertices
-- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
-- Call when you need to assign vertices.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:setVertices(nil) end)
  print("Occluder:setVertices ->", ok, result)
end

--@api-stub: Occluder:getVertices
-- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
-- Call when you need to read vertices.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:getVertices() end)
  print("Occluder:getVertices ->", ok, result)
end

--@api-stub: Occluder:setPosition
-- Sets the translation offset applied to all vertices.
-- Call when you need to assign position.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("Occluder:setPosition ->", ok, result)
end

--@api-stub: Occluder:getPosition
-- Returns the translation offset as (x, y).
-- Call when you need to read position.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("Occluder:getPosition ->", ok, result)
end

--@api-stub: Occluder:setOpacity
-- Sets the shadow opacity (0.0â€“1.0).
-- Call when you need to assign opacity.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:setOpacity(nil) end)
  print("Occluder:setOpacity ->", ok, result)
end

--@api-stub: Occluder:getOpacity
-- Returns the shadow opacity.
-- Call when you need to read opacity.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:getOpacity() end)
  print("Occluder:getOpacity ->", ok, result)
end

--@api-stub: Occluder:setLightMask
-- Sets the light interaction bitmask.
-- Call when you need to assign light mask.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:setLightMask(nil) end)
  print("Occluder:setLightMask ->", ok, result)
end

--@api-stub: Occluder:getLightMask
-- Returns the light interaction bitmask.
-- Call when you need to read light mask.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:getLightMask() end)
  print("Occluder:getLightMask ->", ok, result)
end

--@api-stub: Occluder:setEnabled
-- Sets whether this occluder is active.
-- Call when you need to assign enabled.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(1) end)
  print("Occluder:setEnabled ->", ok, result)
end

--@api-stub: Occluder:isEnabled
-- Returns whether this occluder is active.
-- Call when you need to check is enabled.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:isEnabled() end)
  print("Occluder:isEnabled ->", ok, result)
end

--@api-stub: Occluder:remove
-- Removes this occluder from the world.
-- Call when you need to invoke remove.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:remove() end)
  print("Occluder:remove ->", ok, result)
end

--@api-stub: Occluder:isValid
-- Returns whether this occluder handle is still valid.
-- Call when you need to check is valid.
-- Build a Occluder via the appropriate lurek.light.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.light.newOccluder(...)
if instance then
  local ok, result = pcall(function() return instance:isValid() end)
  print("Occluder:isValid ->", ok, result)
end

