-- content/examples/light.lua
-- Scaffolded coverage of the lurek.light API (83 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/light_api.rs   (Lua binding, arg types, return shape)
--   * src/light/                 (semantics, side effects)
--   * docs/specs/light.md        (canonical reference)
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
-- Run: cargo run -- content/examples/light.lua

-- ── lurek.light.* functions ──

--@api-stub: lurek.light.newLight
-- Creates a new light at (x, y) with the given radius and optional settings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.newLight
  local _todo = "TODO: write a real lurek.light.newLight usage example"
  print(_todo)
end

--@api-stub: lurek.light.newOccluder
-- Creates a new shadow occluder from a vertex table and optional settings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.newOccluder
  local _todo = "TODO: write a real lurek.light.newOccluder usage example"
  print(_todo)
end

--@api-stub: lurek.light.setAmbient
-- Sets the global ambient light color.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.setAmbient
  local _todo = "TODO: write a real lurek.light.setAmbient usage example"
  print(_todo)
end

--@api-stub: lurek.light.getAmbient
-- Returns the global ambient light color as (r, g, b, a).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.getAmbient
  local _todo = "TODO: write a real lurek.light.getAmbient usage example"
  print(_todo)
end

--@api-stub: lurek.light.setEnabled
-- Sets whether the lighting system is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.setEnabled
  local _todo = "TODO: write a real lurek.light.setEnabled usage example"
  print(_todo)
end

--@api-stub: lurek.light.isEnabled
-- Returns whether the lighting system is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.isEnabled
  local _todo = "TODO: write a real lurek.light.isEnabled usage example"
  print(_todo)
end

--@api-stub: lurek.light.getLightCount
-- Returns the number of lights in the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.getLightCount
  local _todo = "TODO: write a real lurek.light.getLightCount usage example"
  print(_todo)
end

--@api-stub: lurek.light.getOccluderCount
-- Returns the number of occluders in the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.getOccluderCount
  local _todo = "TODO: write a real lurek.light.getOccluderCount usage example"
  print(_todo)
end

--@api-stub: lurek.light.getMaxLights
-- Returns the maximum number of lights processed per frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.getMaxLights
  local _todo = "TODO: write a real lurek.light.getMaxLights usage example"
  print(_todo)
end

--@api-stub: lurek.light.setMaxLights
-- Sets the maximum number of lights processed per frame (clamped 1â€“256).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.setMaxLights
  local _todo = "TODO: write a real lurek.light.setMaxLights usage example"
  print(_todo)
end

--@api-stub: lurek.light.clear
-- Removes all lights and occluders, resets ambient to default.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.clear
  local _todo = "TODO: write a real lurek.light.clear usage example"
  print(_todo)
end

--@api-stub: lurek.light.setGroupEnabled
-- Sets the enabled state for all lights in the given group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.setGroupEnabled
  local _todo = "TODO: write a real lurek.light.setGroupEnabled usage example"
  print(_todo)
end

--@api-stub: lurek.light.setGroupIntensity
-- Sets the intensity for all lights in the given group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.setGroupIntensity
  local _todo = "TODO: write a real lurek.light.setGroupIntensity usage example"
  print(_todo)
end

--@api-stub: lurek.light.setGroupColor
-- Sets the color for all lights in the given group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.setGroupColor
  local _todo = "TODO: write a real lurek.light.setGroupColor usage example"
  print(_todo)
end

--@api-stub: lurek.light.getGroupCount
-- Returns the number of lights in the given group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.getGroupCount
  local _todo = "TODO: write a real lurek.light.getGroupCount usage example"
  print(_todo)
end

--@api-stub: lurek.light.advanceFlickers
-- Advances flicker phase for all lights with flicker enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.advanceFlickers
  local _todo = "TODO: write a real lurek.light.advanceFlickers usage example"
  print(_todo)
end

--@api-stub: lurek.light.syncAmbient
-- Returns the current ambient light colour as (r, g, b, a).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.syncAmbient
  local _todo = "TODO: write a real lurek.light.syncAmbient usage example"
  print(_todo)
end

--@api-stub: lurek.light.getGodRayHints
-- Returns a list of directional light hints for god-ray rendering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: lurek.light.getGodRayHints
  local _todo = "TODO: write a real lurek.light.getGodRayHints usage example"
  print(_todo)
end

-- ── Light methods ──

--@api-stub: Light:setPosition
-- Sets the light's world-space position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setPosition
  local _todo = "TODO: write a real Light:setPosition usage example"
  print(_todo)
end

--@api-stub: Light:getPosition
-- Returns the light's world-space position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getPosition
  local _todo = "TODO: write a real Light:getPosition usage example"
  print(_todo)
end

--@api-stub: Light:setRadius
-- Sets the light's influence radius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setRadius
  local _todo = "TODO: write a real Light:setRadius usage example"
  print(_todo)
end

--@api-stub: Light:getRadius
-- Returns the light's influence radius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getRadius
  local _todo = "TODO: write a real Light:getRadius usage example"
  print(_todo)
end

--@api-stub: Light:getColor
-- Returns the light's tint color as (r, g, b, a).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getColor
  local _todo = "TODO: write a real Light:getColor usage example"
  print(_todo)
end

--@api-stub: Light:setIntensity
-- Sets the brightness multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setIntensity
  local _todo = "TODO: write a real Light:setIntensity usage example"
  print(_todo)
end

--@api-stub: Light:getIntensity
-- Returns the brightness multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getIntensity
  local _todo = "TODO: write a real Light:getIntensity usage example"
  print(_todo)
end

--@api-stub: Light:setEnergy
-- Sets the energy scaling factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setEnergy
  local _todo = "TODO: write a real Light:setEnergy usage example"
  print(_todo)
end

--@api-stub: Light:getEnergy
-- Returns the energy scaling factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getEnergy
  local _todo = "TODO: write a real Light:getEnergy usage example"
  print(_todo)
end

--@api-stub: Light:setBlendMode
-- Sets the blend mode ('add', 'sub', or 'mix').
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setBlendMode
  local _todo = "TODO: write a real Light:setBlendMode usage example"
  print(_todo)
end

--@api-stub: Light:getBlendMode
-- Returns the blend mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getBlendMode
  local _todo = "TODO: write a real Light:getBlendMode usage example"
  print(_todo)
end

--@api-stub: Light:setFalloff
-- Sets the falloff mode ('linear', 'smooth', or 'constant').
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setFalloff
  local _todo = "TODO: write a real Light:setFalloff usage example"
  print(_todo)
end

--@api-stub: Light:getFalloff
-- Returns the falloff mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getFalloff
  local _todo = "TODO: write a real Light:getFalloff usage example"
  print(_todo)
end

--@api-stub: Light:setShadowEnabled
-- Sets whether this light casts shadows.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setShadowEnabled
  local _todo = "TODO: write a real Light:setShadowEnabled usage example"
  print(_todo)
end

--@api-stub: Light:isShadowEnabled
-- Returns whether this light casts shadows.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:isShadowEnabled
  local _todo = "TODO: write a real Light:isShadowEnabled usage example"
  print(_todo)
end

--@api-stub: Light:getShadowColor
-- Returns the shadow region color as (r, g, b, a).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getShadowColor
  local _todo = "TODO: write a real Light:getShadowColor usage example"
  print(_todo)
end

--@api-stub: Light:setShadowFilter
-- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setShadowFilter
  local _todo = "TODO: write a real Light:setShadowFilter usage example"
  print(_todo)
end

--@api-stub: Light:getShadowFilter
-- Returns the shadow edge filter as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getShadowFilter
  local _todo = "TODO: write a real Light:getShadowFilter usage example"
  print(_todo)
end

--@api-stub: Light:setShadowSmooth
-- Sets the shadow edge smoothing factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setShadowSmooth
  local _todo = "TODO: write a real Light:setShadowSmooth usage example"
  print(_todo)
end

--@api-stub: Light:getShadowSmooth
-- Returns the shadow edge smoothing factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getShadowSmooth
  local _todo = "TODO: write a real Light:getShadowSmooth usage example"
  print(_todo)
end

--@api-stub: Light:setLightMask
-- Sets the light interaction bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setLightMask
  local _todo = "TODO: write a real Light:setLightMask usage example"
  print(_todo)
end

--@api-stub: Light:getLightMask
-- Returns the light interaction bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getLightMask
  local _todo = "TODO: write a real Light:getLightMask usage example"
  print(_todo)
end

--@api-stub: Light:setShadowMask
-- Sets the shadow casting bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setShadowMask
  local _todo = "TODO: write a real Light:setShadowMask usage example"
  print(_todo)
end

--@api-stub: Light:getShadowMask
-- Returns the shadow casting bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getShadowMask
  local _todo = "TODO: write a real Light:getShadowMask usage example"
  print(_todo)
end

--@api-stub: Light:setEnabled
-- Sets whether this light is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setEnabled
  local _todo = "TODO: write a real Light:setEnabled usage example"
  print(_todo)
end

--@api-stub: Light:isEnabled
-- Returns whether this light is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:isEnabled
  local _todo = "TODO: write a real Light:isEnabled usage example"
  print(_todo)
end

--@api-stub: Light:setLightType
-- Sets the geometric light type ('point', 'directional', or 'spot').
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setLightType
  local _todo = "TODO: write a real Light:setLightType usage example"
  print(_todo)
end

--@api-stub: Light:getLightType
-- Returns the geometric light type as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getLightType
  local _todo = "TODO: write a real Light:getLightType usage example"
  print(_todo)
end

--@api-stub: Light:setDirection
-- Sets the direction angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setDirection
  local _todo = "TODO: write a real Light:setDirection usage example"
  print(_todo)
end

--@api-stub: Light:getDirection
-- Returns the direction angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getDirection
  local _todo = "TODO: write a real Light:getDirection usage example"
  print(_todo)
end

--@api-stub: Light:setInnerAngle
-- Sets the inner cone angle in radians for spot lights.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setInnerAngle
  local _todo = "TODO: write a real Light:setInnerAngle usage example"
  print(_todo)
end

--@api-stub: Light:getInnerAngle
-- Returns the inner cone angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getInnerAngle
  local _todo = "TODO: write a real Light:getInnerAngle usage example"
  print(_todo)
end

--@api-stub: Light:setOuterAngle
-- Sets the outer cone angle in radians for spot lights.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setOuterAngle
  local _todo = "TODO: write a real Light:setOuterAngle usage example"
  print(_todo)
end

--@api-stub: Light:getOuterAngle
-- Returns the outer cone angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getOuterAngle
  local _todo = "TODO: write a real Light:getOuterAngle usage example"
  print(_todo)
end

--@api-stub: Light:setAttenuation
-- Sets the custom attenuation coefficients (constant, linear, quadratic).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setAttenuation
  local _todo = "TODO: write a real Light:setAttenuation usage example"
  print(_todo)
end

--@api-stub: Light:getAttenuation
-- Returns the custom attenuation coefficients as (constant, linear, quadratic).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getAttenuation
  local _todo = "TODO: write a real Light:getAttenuation usage example"
  print(_todo)
end

--@api-stub: Light:setFlicker
-- Sets the flicker effect speed and strength (enables flicker).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setFlicker
  local _todo = "TODO: write a real Light:setFlicker usage example"
  print(_todo)
end

--@api-stub: Light:getFlicker
-- Returns the flicker effect speed and strength.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getFlicker
  local _todo = "TODO: write a real Light:getFlicker usage example"
  print(_todo)
end

--@api-stub: Light:setFlickerEnabled
-- Sets whether the flicker effect is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setFlickerEnabled
  local _todo = "TODO: write a real Light:setFlickerEnabled usage example"
  print(_todo)
end

--@api-stub: Light:isFlickerEnabled
-- Returns whether the flicker effect is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:isFlickerEnabled
  local _todo = "TODO: write a real Light:isFlickerEnabled usage example"
  print(_todo)
end

--@api-stub: Light:setGroupId
-- Sets the group identifier for batch operations.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setGroupId
  local _todo = "TODO: write a real Light:setGroupId usage example"
  print(_todo)
end

--@api-stub: Light:getGroupId
-- Returns the group identifier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getGroupId
  local _todo = "TODO: write a real Light:getGroupId usage example"
  print(_todo)
end

--@api-stub: Light:setVolumetric
-- Sets whether this light hints at volumetric scattering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setVolumetric
  local _todo = "TODO: write a real Light:setVolumetric usage example"
  print(_todo)
end

--@api-stub: Light:isVolumetric
-- Returns whether this light hints at volumetric scattering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:isVolumetric
  local _todo = "TODO: write a real Light:isVolumetric usage example"
  print(_todo)
end

--@api-stub: Light:remove
-- Removes this light from the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:remove
  local _todo = "TODO: write a real Light:remove usage example"
  print(_todo)
end

--@api-stub: Light:isValid
-- Returns whether this light handle is still valid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:isValid
  local _todo = "TODO: write a real Light:isValid usage example"
  print(_todo)
end

--@api-stub: Light:addFlicker
-- Convenience method to set a flicker effect using amplitude range and.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:addFlicker
  local _todo = "TODO: write a real Light:addFlicker usage example"
  print(_todo)
end

--@api-stub: Light:updateTransition
-- Advances the active transition by `dt` seconds and applies the.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:updateTransition
  local _todo = "TODO: write a real Light:updateTransition usage example"
  print(_todo)
end

--@api-stub: Light:stopTransition
-- Cancels the active light transition.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:stopTransition
  local _todo = "TODO: write a real Light:stopTransition usage example"
  print(_todo)
end

--@api-stub: Light:transitionProgress
-- Returns the fractional progress `[0, 1]` of the active transition,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:transitionProgress
  local _todo = "TODO: write a real Light:transitionProgress usage example"
  print(_todo)
end

--@api-stub: Light:setCookie
-- Sets the texture path used as a light cookie (mask) for projection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:setCookie
  local _todo = "TODO: write a real Light:setCookie usage example"
  print(_todo)
end

--@api-stub: Light:getCookie
-- Returns the current cookie texture path, or `nil` if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:getCookie
  local _todo = "TODO: write a real Light:getCookie usage example"
  print(_todo)
end

--@api-stub: Light:clearCookie
-- Removes the cookie texture assignment.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Light:clearCookie
  local _todo = "TODO: write a real Light:clearCookie usage example"
  print(_todo)
end

-- ── Occluder methods ──

--@api-stub: Occluder:setVertices
-- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:setVertices
  local _todo = "TODO: write a real Occluder:setVertices usage example"
  print(_todo)
end

--@api-stub: Occluder:getVertices
-- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:getVertices
  local _todo = "TODO: write a real Occluder:getVertices usage example"
  print(_todo)
end

--@api-stub: Occluder:setPosition
-- Sets the translation offset applied to all vertices.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:setPosition
  local _todo = "TODO: write a real Occluder:setPosition usage example"
  print(_todo)
end

--@api-stub: Occluder:getPosition
-- Returns the translation offset as (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:getPosition
  local _todo = "TODO: write a real Occluder:getPosition usage example"
  print(_todo)
end

--@api-stub: Occluder:setOpacity
-- Sets the shadow opacity (0.0â€“1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:setOpacity
  local _todo = "TODO: write a real Occluder:setOpacity usage example"
  print(_todo)
end

--@api-stub: Occluder:getOpacity
-- Returns the shadow opacity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:getOpacity
  local _todo = "TODO: write a real Occluder:getOpacity usage example"
  print(_todo)
end

--@api-stub: Occluder:setLightMask
-- Sets the light interaction bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:setLightMask
  local _todo = "TODO: write a real Occluder:setLightMask usage example"
  print(_todo)
end

--@api-stub: Occluder:getLightMask
-- Returns the light interaction bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:getLightMask
  local _todo = "TODO: write a real Occluder:getLightMask usage example"
  print(_todo)
end

--@api-stub: Occluder:setEnabled
-- Sets whether this occluder is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:setEnabled
  local _todo = "TODO: write a real Occluder:setEnabled usage example"
  print(_todo)
end

--@api-stub: Occluder:isEnabled
-- Returns whether this occluder is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:isEnabled
  local _todo = "TODO: write a real Occluder:isEnabled usage example"
  print(_todo)
end

--@api-stub: Occluder:remove
-- Removes this occluder from the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:remove
  local _todo = "TODO: write a real Occluder:remove usage example"
  print(_todo)
end

--@api-stub: Occluder:isValid
-- Returns whether this occluder handle is still valid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/light_api.rs and docs/specs/light.md).
do  -- TODO: Occluder:isValid
  local _todo = "TODO: write a real Occluder:isValid usage example"
  print(_todo)
end

