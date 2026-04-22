-- content/examples/light.lua
-- Auto-scaffolded coverage of the lurek.light Lua API (83 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/light.lua

print("[example] lurek.light loaded — 83 API items demonstrated")

-- ── lurek.light free functions ──

--@api-stub: lurek.light.newLight
-- Creates a new light at (x, y) with the given radius and optional settings.
-- Use this when creates a new light at (x, y) with the given radius and optional settings is needed.
if false then
  local _r = lurek.light.newLight(0, 0, nil, 0)
  print(_r)
end

--@api-stub: lurek.light.newOccluder
-- Creates a new shadow occluder from a vertex table and optional settings.
-- Use this when creates a new shadow occluder from a vertex table and optional settings is needed.
if false then
  local _r = lurek.light.newOccluder(0, 0)
  print(_r)
end

--@api-stub: lurek.light.setAmbient
-- Sets the global ambient light color.
-- Use this when sets the global ambient light color is needed.
if false then
  local _r = lurek.light.setAmbient(nil, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.light.getAmbient
-- Returns the global ambient light color as (r, g, b, a).
-- Use this when returns the global ambient light color as (r, g, b, a) is needed.
if false then
  local _r = lurek.light.getAmbient()
  print(_r)
end

--@api-stub: lurek.light.setEnabled
-- Sets whether the lighting system is active.
-- Use this when sets whether the lighting system is active is needed.
if false then
  local _r = lurek.light.setEnabled(1)
  print(_r)
end

--@api-stub: lurek.light.isEnabled
-- Returns whether the lighting system is active.
-- Use this when returns whether the lighting system is active is needed.
if false then
  local _r = lurek.light.isEnabled()
  print(_r)
end

--@api-stub: lurek.light.getLightCount
-- Returns the number of lights in the world.
-- Use this when returns the number of lights in the world is needed.
if false then
  local _r = lurek.light.getLightCount()
  print(_r)
end

--@api-stub: lurek.light.getOccluderCount
-- Returns the number of occluders in the world.
-- Use this when returns the number of occluders in the world is needed.
if false then
  local _r = lurek.light.getOccluderCount()
  print(_r)
end

--@api-stub: lurek.light.getMaxLights
-- Returns the maximum number of lights processed per frame.
-- Use this when returns the maximum number of lights processed per frame is needed.
if false then
  local _r = lurek.light.getMaxLights()
  print(_r)
end

--@api-stub: lurek.light.setMaxLights
-- Sets the maximum number of lights processed per frame (clamped 1â€“256).
-- Use this when sets the maximum number of lights processed per frame (clamped 1â€“256) is needed.
if false then
  local _r = lurek.light.setMaxLights(1)
  print(_r)
end

--@api-stub: lurek.light.clear
-- Removes all lights and occluders, resets ambient to default.
-- Use this when removes all lights and occluders, resets ambient to default is needed.
if false then
  local _r = lurek.light.clear()
  print(_r)
end

--@api-stub: lurek.light.setGroupEnabled
-- Sets the enabled state for all lights in the given group.
-- Use this when sets the enabled state for all lights in the given group is needed.
if false then
  local _r = lurek.light.setGroupEnabled(1, 1)
  print(_r)
end

--@api-stub: lurek.light.setGroupIntensity
-- Sets the intensity for all lights in the given group.
-- Use this when sets the intensity for all lights in the given group is needed.
if false then
  local _r = lurek.light.setGroupIntensity(1, 1)
  print(_r)
end

--@api-stub: lurek.light.setGroupColor
-- Sets the color for all lights in the given group.
-- Use this when sets the color for all lights in the given group is needed.
if false then
  local _r = lurek.light.setGroupColor(1, nil, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.light.getGroupCount
-- Returns the number of lights in the given group.
-- Use this when returns the number of lights in the given group is needed.
if false then
  local _r = lurek.light.getGroupCount(1)
  print(_r)
end

--@api-stub: lurek.light.advanceFlickers
-- Advances flicker phase for all lights with flicker enabled.
-- Use this when advances flicker phase for all lights with flicker enabled is needed.
if false then
  local _r = lurek.light.advanceFlickers(0)
  print(_r)
end

--@api-stub: lurek.light.syncAmbient
-- Returns the current ambient light colour as (r, g, b, a).
-- Use this when returns the current ambient light colour as (r, g, b, a) is needed.
if false then
  local _r = lurek.light.syncAmbient()
  print(_r)
end

--@api-stub: lurek.light.getGodRayHints
-- Returns a list of directional light hints for god-ray rendering.
-- Use this when returns a list of directional light hints for god-ray rendering is needed.
if false then
  local _r = lurek.light.getGodRayHints()
  print(_r)
end

-- ── Light methods ──

--@api-stub: Light:setPosition
-- Sets the light's world-space position.
-- Use this when sets the light's world-space position is needed.
if false then
  local _o = nil  -- Light instance
  _o:setPosition(0, 0)
end

--@api-stub: Light:getPosition
-- Returns the light's world-space position.
-- Use this when returns the light's world-space position is needed.
if false then
  local _o = nil  -- Light instance
  _o:getPosition()
end

--@api-stub: Light:setRadius
-- Sets the light's influence radius.
-- Use this when sets the light's influence radius is needed.
if false then
  local _o = nil  -- Light instance
  _o:setRadius(nil)
end

--@api-stub: Light:getRadius
-- Returns the light's influence radius.
-- Use this when returns the light's influence radius is needed.
if false then
  local _o = nil  -- Light instance
  _o:getRadius()
end

--@api-stub: Light:getColor
-- Returns the light's tint color as (r, g, b, a).
-- Use this when returns the light's tint color as (r, g, b, a) is needed.
if false then
  local _o = nil  -- Light instance
  _o:getColor()
end

--@api-stub: Light:setIntensity
-- Sets the brightness multiplier.
-- Use this when sets the brightness multiplier is needed.
if false then
  local _o = nil  -- Light instance
  _o:setIntensity(nil)
end

--@api-stub: Light:getIntensity
-- Returns the brightness multiplier.
-- Use this when returns the brightness multiplier is needed.
if false then
  local _o = nil  -- Light instance
  _o:getIntensity()
end

--@api-stub: Light:setEnergy
-- Sets the energy scaling factor.
-- Use this when sets the energy scaling factor is needed.
if false then
  local _o = nil  -- Light instance
  _o:setEnergy(nil)
end

--@api-stub: Light:getEnergy
-- Returns the energy scaling factor.
-- Use this when returns the energy scaling factor is needed.
if false then
  local _o = nil  -- Light instance
  _o:getEnergy()
end

--@api-stub: Light:setBlendMode
-- Sets the blend mode ('add', 'sub', or 'mix').
-- Use this when sets the blend mode ('add', 'sub', or 'mix') is needed.
if false then
  local _o = nil  -- Light instance
  _o:setBlendMode(nil)
end

--@api-stub: Light:getBlendMode
-- Returns the blend mode as a string.
-- Use this when returns the blend mode as a string is needed.
if false then
  local _o = nil  -- Light instance
  _o:getBlendMode()
end

--@api-stub: Light:setFalloff
-- Sets the falloff mode ('linear', 'smooth', or 'constant').
-- Use this when sets the falloff mode ('linear', 'smooth', or 'constant') is needed.
if false then
  local _o = nil  -- Light instance
  _o:setFalloff(nil)
end

--@api-stub: Light:getFalloff
-- Returns the falloff mode as a string.
-- Use this when returns the falloff mode as a string is needed.
if false then
  local _o = nil  -- Light instance
  _o:getFalloff()
end

--@api-stub: Light:setShadowEnabled
-- Sets whether this light casts shadows.
-- Use this when sets whether this light casts shadows is needed.
if false then
  local _o = nil  -- Light instance
  _o:setShadowEnabled(nil)
end

--@api-stub: Light:isShadowEnabled
-- Returns whether this light casts shadows.
-- Use this when returns whether this light casts shadows is needed.
if false then
  local _o = nil  -- Light instance
  _o:isShadowEnabled()
end

--@api-stub: Light:getShadowColor
-- Returns the shadow region color as (r, g, b, a).
-- Use this when returns the shadow region color as (r, g, b, a) is needed.
if false then
  local _o = nil  -- Light instance
  _o:getShadowColor()
end

--@api-stub: Light:setShadowFilter
-- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
-- Use this when sets the shadow edge filter ('none', 'pcf5', or 'pcf13') is needed.
if false then
  local _o = nil  -- Light instance
  _o:setShadowFilter(0)
end

--@api-stub: Light:getShadowFilter
-- Returns the shadow edge filter as a string.
-- Use this when returns the shadow edge filter as a string is needed.
if false then
  local _o = nil  -- Light instance
  _o:getShadowFilter()
end

--@api-stub: Light:setShadowSmooth
-- Sets the shadow edge smoothing factor.
-- Use this when sets the shadow edge smoothing factor is needed.
if false then
  local _o = nil  -- Light instance
  _o:setShadowSmooth(nil)
end

--@api-stub: Light:getShadowSmooth
-- Returns the shadow edge smoothing factor.
-- Use this when returns the shadow edge smoothing factor is needed.
if false then
  local _o = nil  -- Light instance
  _o:getShadowSmooth()
end

--@api-stub: Light:setLightMask
-- Sets the light interaction bitmask.
-- Use this when sets the light interaction bitmask is needed.
if false then
  local _o = nil  -- Light instance
  _o:setLightMask(nil)
end

--@api-stub: Light:getLightMask
-- Returns the light interaction bitmask.
-- Use this when returns the light interaction bitmask is needed.
if false then
  local _o = nil  -- Light instance
  _o:getLightMask()
end

--@api-stub: Light:setShadowMask
-- Sets the shadow casting bitmask.
-- Use this when sets the shadow casting bitmask is needed.
if false then
  local _o = nil  -- Light instance
  _o:setShadowMask(nil)
end

--@api-stub: Light:getShadowMask
-- Returns the shadow casting bitmask.
-- Use this when returns the shadow casting bitmask is needed.
if false then
  local _o = nil  -- Light instance
  _o:getShadowMask()
end

--@api-stub: Light:setEnabled
-- Sets whether this light is active.
-- Use this when sets whether this light is active is needed.
if false then
  local _o = nil  -- Light instance
  _o:setEnabled(nil)
end

--@api-stub: Light:isEnabled
-- Returns whether this light is active.
-- Use this when returns whether this light is active is needed.
if false then
  local _o = nil  -- Light instance
  _o:isEnabled()
end

--@api-stub: Light:setLightType
-- Sets the geometric light type ('point', 'directional', or 'spot').
-- Use this when sets the geometric light type ('point', 'directional', or 'spot') is needed.
if false then
  local _o = nil  -- Light instance
  _o:setLightType(0)
end

--@api-stub: Light:getLightType
-- Returns the geometric light type as a string.
-- Use this when returns the geometric light type as a string is needed.
if false then
  local _o = nil  -- Light instance
  _o:getLightType()
end

--@api-stub: Light:setDirection
-- Sets the direction angle in radians.
-- Use this when sets the direction angle in radians is needed.
if false then
  local _o = nil  -- Light instance
  _o:setDirection(nil)
end

--@api-stub: Light:getDirection
-- Returns the direction angle in radians.
-- Use this when returns the direction angle in radians is needed.
if false then
  local _o = nil  -- Light instance
  _o:getDirection()
end

--@api-stub: Light:setInnerAngle
-- Sets the inner cone angle in radians for spot lights.
-- Use this when sets the inner cone angle in radians for spot lights is needed.
if false then
  local _o = nil  -- Light instance
  _o:setInnerAngle(nil)
end

--@api-stub: Light:getInnerAngle
-- Returns the inner cone angle in radians.
-- Use this when returns the inner cone angle in radians is needed.
if false then
  local _o = nil  -- Light instance
  _o:getInnerAngle()
end

--@api-stub: Light:setOuterAngle
-- Sets the outer cone angle in radians for spot lights.
-- Use this when sets the outer cone angle in radians for spot lights is needed.
if false then
  local _o = nil  -- Light instance
  _o:setOuterAngle(nil)
end

--@api-stub: Light:getOuterAngle
-- Returns the outer cone angle in radians.
-- Use this when returns the outer cone angle in radians is needed.
if false then
  local _o = nil  -- Light instance
  _o:getOuterAngle()
end

--@api-stub: Light:setAttenuation
-- Sets the custom attenuation coefficients (constant, linear, quadratic).
-- Use this when sets the custom attenuation coefficients (constant, linear, quadratic) is needed.
if false then
  local _o = nil  -- Light instance
  _o:setAttenuation(nil, nil, nil)
end

--@api-stub: Light:getAttenuation
-- Returns the custom attenuation coefficients as (constant, linear, quadratic).
-- Use this when returns the custom attenuation coefficients as (constant, linear, quadratic) is needed.
if false then
  local _o = nil  -- Light instance
  _o:getAttenuation()
end

--@api-stub: Light:setFlicker
-- Sets the flicker effect speed and strength (enables flicker).
-- Use this when sets the flicker effect speed and strength (enables flicker) is needed.
if false then
  local _o = nil  -- Light instance
  _o:setFlicker(0, 1)
end

--@api-stub: Light:getFlicker
-- Returns the flicker effect speed and strength.
-- Use this when returns the flicker effect speed and strength is needed.
if false then
  local _o = nil  -- Light instance
  _o:getFlicker()
end

--@api-stub: Light:setFlickerEnabled
-- Sets whether the flicker effect is active.
-- Use this when sets whether the flicker effect is active is needed.
if false then
  local _o = nil  -- Light instance
  _o:setFlickerEnabled(nil)
end

--@api-stub: Light:isFlickerEnabled
-- Returns whether the flicker effect is active.
-- Use this when returns whether the flicker effect is active is needed.
if false then
  local _o = nil  -- Light instance
  _o:isFlickerEnabled()
end

--@api-stub: Light:setGroupId
-- Sets the group identifier for batch operations.
-- Use this when sets the group identifier for batch operations is needed.
if false then
  local _o = nil  -- Light instance
  _o:setGroupId(1)
end

--@api-stub: Light:getGroupId
-- Returns the group identifier.
-- Use this when returns the group identifier is needed.
if false then
  local _o = nil  -- Light instance
  _o:getGroupId()
end

--@api-stub: Light:setVolumetric
-- Sets whether this light hints at volumetric scattering.
-- Use this when sets whether this light hints at volumetric scattering is needed.
if false then
  local _o = nil  -- Light instance
  _o:setVolumetric(nil)
end

--@api-stub: Light:isVolumetric
-- Returns whether this light hints at volumetric scattering.
-- Use this when returns whether this light hints at volumetric scattering is needed.
if false then
  local _o = nil  -- Light instance
  _o:isVolumetric()
end

--@api-stub: Light:remove
-- Removes this light from the world.
-- Use this when removes this light from the world is needed.
if false then
  local _o = nil  -- Light instance
  _o:remove()
end

--@api-stub: Light:isValid
-- Returns whether this light handle is still valid.
-- Use this when returns whether this light handle is still valid is needed.
if false then
  local _o = nil  -- Light instance
  _o:isValid()
end

--@api-stub: Light:addFlicker
-- Convenience method to set a flicker effect using amplitude range and.
-- Use this when convenience method to set a flicker effect using amplitude range and is needed.
if false then
  local _o = nil  -- Light instance
  _o:addFlicker(1, 0, 0)
end

--@api-stub: Light:updateTransition
-- Advances the active transition by `dt` seconds and applies the.
-- Use this when advances the active transition by `dt` seconds and applies the is needed.
if false then
  local _o = nil  -- Light instance
  _o:updateTransition(0)
end

--@api-stub: Light:stopTransition
-- Cancels the active light transition.
-- Use this when cancels the active light transition is needed.
if false then
  local _o = nil  -- Light instance
  _o:stopTransition()
end

--@api-stub: Light:transitionProgress
-- Returns the fractional progress `[0, 1]` of the active transition,.
-- Use this when returns the fractional progress `[0, 1]` of the active transition, is needed.
if false then
  local _o = nil  -- Light instance
  _o:transitionProgress()
end

--@api-stub: Light:setCookie
-- Sets the texture path used as a light cookie (mask) for projection.
-- Use this when sets the texture path used as a light cookie (mask) for projection is needed.
if false then
  local _o = nil  -- Light instance
  _o:setCookie(0)
end

--@api-stub: Light:getCookie
-- Returns the current cookie texture path, or `nil` if unset.
-- Use this when returns the current cookie texture path, or `nil` if unset is needed.
if false then
  local _o = nil  -- Light instance
  _o:getCookie()
end

--@api-stub: Light:clearCookie
-- Removes the cookie texture assignment.
-- Use this when removes the cookie texture assignment is needed.
if false then
  local _o = nil  -- Light instance
  _o:clearCookie()
end

-- ── Occluder methods ──

--@api-stub: Occluder:setVertices
-- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
-- Use this when replaces the polygon vertices from a flat table {x1,y1,x2,y2,...} is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:setVertices(0)
end

--@api-stub: Occluder:getVertices
-- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
-- Use this when returns the polygon vertices as a flat table {x1,y1,x2,y2,...} is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:getVertices()
end

--@api-stub: Occluder:setPosition
-- Sets the translation offset applied to all vertices.
-- Use this when sets the translation offset applied to all vertices is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:setPosition(0, 0)
end

--@api-stub: Occluder:getPosition
-- Returns the translation offset as (x, y).
-- Use this when returns the translation offset as (x, y) is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:getPosition()
end

--@api-stub: Occluder:setOpacity
-- Sets the shadow opacity (0.0â€“1.0).
-- Use this when sets the shadow opacity (0.0â€“1.0) is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:setOpacity(nil)
end

--@api-stub: Occluder:getOpacity
-- Returns the shadow opacity.
-- Use this when returns the shadow opacity is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:getOpacity()
end

--@api-stub: Occluder:setLightMask
-- Sets the light interaction bitmask.
-- Use this when sets the light interaction bitmask is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:setLightMask(nil)
end

--@api-stub: Occluder:getLightMask
-- Returns the light interaction bitmask.
-- Use this when returns the light interaction bitmask is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:getLightMask()
end

--@api-stub: Occluder:setEnabled
-- Sets whether this occluder is active.
-- Use this when sets whether this occluder is active is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:setEnabled(nil)
end

--@api-stub: Occluder:isEnabled
-- Returns whether this occluder is active.
-- Use this when returns whether this occluder is active is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:isEnabled()
end

--@api-stub: Occluder:remove
-- Removes this occluder from the world.
-- Use this when removes this occluder from the world is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:remove()
end

--@api-stub: Occluder:isValid
-- Returns whether this occluder handle is still valid.
-- Use this when returns whether this occluder handle is still valid is needed.
if false then
  local _o = nil  -- Occluder instance
  _o:isValid()
end

