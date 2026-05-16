-- content/examples/light.lua
-- lurek.light API examples.
-- Run: cargo run -- content/examples/light.lua

--@api-stub: lurek.light.newLight
-- Creates a light and applies optional light settings
do
  local torch = lurek.light.newLight(200, 150, 180, { color = {1.0, 0.7, 0.3, 1.0}, intensity = 1.2 })
  torch:setBlendMode("add")
  lurek.log.info("torch lit at (200, 150)", "light")
end

--@api-stub: lurek.light.newOccluder
-- Creates an occluder from a flat vertex coordinate table and optional settings
do
  local wall = lurek.light.newOccluder({ 100, 100, 300, 100, 300, 120, 100, 120 }, { opacity = 0.85 })
  wall:setEnabled(true)
end

--@api-stub: lurek.light.setAmbient
-- Sets global ambient light color
do
  lurek.light.setAmbient(0.15, 0.18, 0.30, 1.0)
  lurek.log.info("ambient set to dusk blue", "light")
end

--@api-stub: lurek.light.getAmbient
-- Returns global ambient light color
do
  local r, g, b, _ = lurek.light.getAmbient()
  if r + g + b < 0.5 then
    lurek.log.info("scene is dark, spawning extra torches", "light")
  end
end

--@api-stub: lurek.light.setEnabled
-- Enables or disables the shared light world
do
  local cinematic_mode = false
  lurek.light.setEnabled(not cinematic_mode)
end

--@api-stub: lurek.light.isEnabled
-- Returns whether the shared light world is enabled
do
  if lurek.light.isEnabled() then
    lurek.log.info("lighting active", "light")
  end
end

--@api-stub: lurek.light.getLightCount
-- Returns the number of live lights
do
  local n = lurek.light.getLightCount()
  if n > 32 then
    lurek.log.warn("scene has " .. n .. " lights, may exceed budget", "perf")
  end
end

--@api-stub: lurek.light.getOccluderCount
-- Returns the number of live occluders
do
  local n = lurek.light.getOccluderCount()
  lurek.log.info("scene occluders: " .. n, "light")
end

--@api-stub: lurek.light.getMaxLights
-- Returns the maximum configured light count
do
  local cap = lurek.light.getMaxLights()
  if cap < 64 then
    lurek.light.setMaxLights(64)
  end
end

--@api-stub: lurek.light.setMaxLights
-- Sets the maximum configured light count, clamped to 1 through 256
do
  local quality = "high"
  local cap = (quality == "high") and 128 or 32
  lurek.light.setMaxLights(cap)
end

--@api-stub: lurek.light.clear
-- Removes all lights and occluders from the light world
do
  lurek.light.clear()
  lurek.log.info("light world reset for new scene", "light")
end

--@api-stub: lurek.light.setGroupEnabled
-- Enables or disables all lights in a group
do
  local TORCHES_GROUP = 1
  lurek.light.setGroupEnabled(TORCHES_GROUP, false)
end

--@api-stub: lurek.light.setGroupIntensity
-- Sets intensity for all lights in a group
do
  local STREETLAMPS = 2
  lurek.light.setGroupIntensity(STREETLAMPS, 0.6)
end

--@api-stub: lurek.light.setGroupColor
-- Sets color for all lights in a group
do
  local ALARM_LIGHTS = 3
  lurek.light.setGroupColor(ALARM_LIGHTS, 1.0, 0.1, 0.1, 1.0)
end

--@api-stub: lurek.light.getGroupCount
-- Returns the number of lights in a group
do
  local TORCHES_GROUP = 1
  local n = lurek.light.getGroupCount(TORCHES_GROUP)
  lurek.log.info("torches group has " .. n .. " lights", "light")
end

--@api-stub: lurek.light.advanceFlickers
-- Advances flicker animation for all indexed flickering lights
do
  function lurek.process(dt) lurek.light.advanceFlickers(dt) end
end

--@api-stub: lurek.light.syncAmbient
-- Returns the light world's ambient color hint
do
  local r, g, b, a = lurek.light.syncAmbient()
  local fog_tint = { r * 0.8, g * 0.8, b * 0.8, a }
  lurek.log.debug("fog tint=(" .. fog_tint[1] .. "," .. fog_tint[2] .. ")", "fx")
end

--@api-stub: lurek.light.getGodRayHints
-- Returns directional light hints for god-ray style effects
do
  local hints = lurek.light.getGodRayHints()
  for _, h in ipairs(hints) do
    lurek.log.debug("god-ray src x=" .. h.x .. " y=" .. h.y .. " angle=" .. h.angle, "fx")
  end
end

--@api-stub: lurek.light.getNormalMapHints
-- Returns light hints that reference normal maps
do
  local hints = lurek.light.getNormalMapHints()
  for _, h in ipairs(hints) do
    lurek.log.debug("normal-map=" .. h.normalMap .. " strength=" .. h.strength, "fx")
  end
end

-- Light methods

--@api-stub: Light:setPosition
-- Sets the position of this light.
do
  local lamp = lurek.light.newLight(0, 0, 120)
  lamp:setPosition(320, 240)
end

--@api-stub: Light:getPosition
-- Returns the position of this light.
do
  local lamp = lurek.light.newLight(150, 100, 80)
  local x, y = lamp:getPosition()
  lurek.log.info("lamp at (" .. x .. "," .. y .. ")", "light")
end

--@api-stub: Light:setRadius
-- Sets the radius of this light.
do
  local lantern = lurek.light.newLight(50, 50, 100)
  local battery_pct = 0.6
  lantern:setRadius(40 + 80 * battery_pct)
end

--@api-stub: Light:getRadius
-- Returns the radius of this light.
do
  local glow = lurek.light.newLight(0, 0, 75)
  if glow:getRadius() < 50 then
    glow:setRadius(50)
  end
end

--@api-stub: Light:getColor
-- Returns the color of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100, { color = {0.9, 0.7, 0.5, 1.0} })
  local r, g, b, a = lamp:getColor()
  lurek.log.debug("lamp color=(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "light")
end

--@api-stub: Light:setIntensity
-- Sets the intensity of this light.
do
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setIntensity(1.4)
end

--@api-stub: Light:getIntensity
-- Returns the intensity of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getIntensity() < 0.2 then
    lurek.log.warn("lamp intensity very low", "light")
  end
end

--@api-stub: Light:setEnergy
-- Sets the energy of this light.
do
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setEnergy(2.5)
end

--@api-stub: Light:getEnergy
-- Returns the energy of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local e = lamp:getEnergy()
  lurek.log.debug("lamp energy=" .. e, "light")
end

--@api-stub: Light:setBlendMode
-- Sets the blend mode of this light.
do
  local glow = lurek.light.newLight(0, 0, 100)
  glow:setBlendMode("add")
end

--@api-stub: Light:getBlendMode
-- Returns the blend mode of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getBlendMode() ~= "add" then
    lamp:setBlendMode("add")
  end
end

--@api-stub: Light:setFalloff
-- Sets the falloff of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setFalloff("smooth")
end

--@api-stub: Light:getFalloff
-- Returns the falloff of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local mode = lamp:getFalloff()
  lurek.log.debug("falloff=" .. mode, "light")
end

--@api-stub: Light:setShadowEnabled
-- Sets whether this light is enabled and accepts input.
do
  local torch = lurek.light.newLight(100, 100, 200)
  torch:setShadowEnabled(true)
end

--@api-stub: Light:isShadowEnabled
-- Returns true if this light is currently enabled.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if not lamp:isShadowEnabled() then
    lamp:setShadowEnabled(true)
  end
end

--@api-stub: Light:getShadowColor
-- Returns the shadow color of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local _, _, _, a = lamp:getShadowColor()
  lurek.log.debug("shadow alpha=" .. a, "light")
end

--@api-stub: Light:setShadowFilter
-- Sets the shadow filter of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowFilter("pcf13")
end

--@api-stub: Light:getShadowFilter
-- Returns the shadow filter of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getShadowFilter() == "none" then
    lamp:setShadowFilter("pcf5")
  end
end

--@api-stub: Light:setShadowSmooth
-- Sets the shadow smooth of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowSmooth(2.5)
end

--@api-stub: Light:getShadowSmooth
-- Returns the shadow smooth of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local s = lamp:getShadowSmooth()
  lurek.log.debug("shadow smooth=" .. s, "light")
end

--@api-stub: Light:setShadowSoftness
-- Sets the shadow softness of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowSoftness(1.8)
end

--@api-stub: Light:getShadowSoftness
-- Returns the shadow softness of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lurek.log.debug("shadow softness=" .. lamp:getShadowSoftness(), "light")
end

--@api-stub: Light:setLightMask
-- Sets the light mask of this light.
do
  local PLAYER_LAYER = 0x01
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setLightMask(PLAYER_LAYER)
end

--@api-stub: Light:getLightMask
-- Returns the light mask of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local mask = lamp:getLightMask()
  lurek.log.debug("lamp mask=" .. mask, "light")
end

--@api-stub: Light:setShadowMask
-- Sets the shadow mask of this light.
do
  local WALLS_ONLY = 0x02
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowMask(WALLS_ONLY)
end

--@api-stub: Light:getShadowMask
-- Returns the shadow mask of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getShadowMask() == 0 then
    lamp:setShadowMask(0xFFFF)
  end
end

--@api-stub: Light:setEnabled
-- Sets whether this light is enabled and accepts input.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local power_on = false
  lamp:setEnabled(power_on)
end

--@api-stub: Light:isEnabled
-- Returns true if this light is currently enabled.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:isEnabled() then
    lurek.log.debug("lamp on", "light")
  end
end

--@api-stub: Light:setLightType
-- Sets the light type of this light.
do
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setLightType("directional")
  sun:setDirection(math.pi * 0.25)
end

--@api-stub: Light:getLightType
-- Returns the light type of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getLightType() == "spot" then
    lamp:setOuterAngle(math.pi / 4)
  end
end

--@api-stub: Light:setDirection
-- Sets the direction of this light.
do
  local flashlight = lurek.light.newLight(100, 100, 200)
  flashlight:setLightType("spot")
  flashlight:setDirection(math.pi / 2)
end

--@api-stub: Light:getDirection
-- Returns the direction of this light.
do
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setDirection(0.5)
  local angle = sun:getDirection()
  lurek.log.debug("sun angle=" .. angle, "light")
end

--@api-stub: Light:setInnerAngle
-- Sets the inner angle of this light.
do
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setLightType("spot")
  spot:setInnerAngle(math.pi / 8)
end

--@api-stub: Light:getInnerAngle
-- Returns the inner angle of this light.
do
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setInnerAngle(0.3)
  lurek.log.debug("inner=" .. spot:getInnerAngle(), "light")
end

--@api-stub: Light:setOuterAngle
-- Sets the outer angle of this light.
do
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setLightType("spot")
  spot:setOuterAngle(math.pi / 4)
end

--@api-stub: Light:getOuterAngle
-- Returns the outer angle of this light.
do
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setOuterAngle(0.7)
  if spot:getOuterAngle() > math.pi then
    spot:setOuterAngle(math.pi)
  end
end

--@api-stub: Light:setAttenuation
-- Sets the attenuation of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setAttenuation(1.0, 0.09, 0.032)
end

--@api-stub: Light:getAttenuation
-- Returns the attenuation of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local c, l, q = lamp:getAttenuation()
  lurek.log.debug("att c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end

--@api-stub: Light:setFlicker
-- Sets the flicker of this light.
do
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(8.0, 0.15)
end

--@api-stub: Light:getFlicker
-- Returns the flicker of this light.
do
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(6.0, 0.2)
  local speed, strength = torch:getFlicker()
  lurek.log.debug("flicker speed=" .. speed .. " strength=" .. strength, "light")
end

--@api-stub: Light:setFlickerEnabled
-- Sets whether this light is enabled and accepts input.
do
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(5.0, 0.1)
  torch:setFlickerEnabled(true)
end

--@api-stub: Light:isFlickerEnabled
-- Returns true if this light is currently enabled.
do
  local torch = lurek.light.newLight(0, 0, 120)
  if not torch:isFlickerEnabled() then
    torch:addFlicker(0.85, 1.15, 4.0)
  end
end

--@api-stub: Light:setGroupId
-- Sets the group id of this light.
do
  local TORCHES = 1
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setGroupId(TORCHES)
end

--@api-stub: Light:getGroupId
-- Returns the group id of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setGroupId(7)
  if lamp:getGroupId() == 7 then
    lurek.log.debug("lamp in alarm group", "light")
  end
end

--@api-stub: Light:setVolumetric
-- Sets the volumetric of this light.
do
  local headlamp = lurek.light.newLight(0, 0, 200)
  headlamp:setVolumetric(true)
end

--@api-stub: Light:isVolumetric
-- Returns true if this light volumetric.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:isVolumetric() then
    lurek.log.debug("lamp produces god rays", "fx")
  end
end

--@api-stub: Light:remove
-- Removes a  from this light.
do
  local muzzle_flash = lurek.light.newLight(64, 64, 60, { intensity = 2.0 })
  muzzle_flash:remove()
end

--@api-stub: Light:isValid
-- Returns true if this light valid.
do
  local spark = lurek.light.newLight(0, 0, 30)
  spark:remove()
  if not spark:isValid() then
    lurek.log.debug("spark expired", "light")
  end
end

--@api-stub: Light:addFlicker
-- Adds a flicker to this light.
do
  local torch = lurek.light.newLight(0, 0, 120)
  torch:addFlicker(0.8, 1.2, 5.0)
end

--@api-stub: Light:updateTransition
-- Advances transition this light by the given delta time.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  function lurek.process(dt) lamp:updateTransition(dt) end
end

--@api-stub: Light:stopTransition
-- Stops the current operation or playback on this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:stopTransition()
end

--@api-stub: Light:transitionProgress
-- Performs the transition progress operation on this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:transitionProgress() >= 1.0 then
    lurek.log.debug("transition complete", "light")
  end
end

--@api-stub: Light:setCookie
-- Sets the cookie of this light.
do
  local projector = lurek.light.newLight(0, 0, 200)
  projector:setCookie("textures/window_pattern.png")
end

--@api-stub: Light:getCookie
-- Returns the cookie of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setCookie("textures/leaves.png")
  local path = lamp:getCookie()
  lurek.log.debug("cookie=" .. tostring(path), "light")
end

--@api-stub: Light:clearCookie
-- Clears all cookie items from this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setCookie("textures/leaves.png")
  lamp:clearCookie()
end

--@api-stub: Light:setNormalMap
-- Sets the normal map of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setNormalMap("assets/textures/normals/brick.png")
end

--@api-stub: Light:getNormalMap
-- Returns the normal map of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lurek.log.debug("normal map=" .. tostring(lamp:getNormalMap()), "light")
end

--@api-stub: Light:clearNormalMap
-- Clears all normal map items from this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setNormalMap("assets/textures/normals/temp.png")
  lamp:clearNormalMap()
end

--@api-stub: Light:setNormalStrength
-- Sets the normal strength of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setNormalStrength(1.3)
end

--@api-stub: Light:getNormalStrength
-- Returns the normal strength of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lurek.log.debug("normal strength=" .. lamp:getNormalStrength(), "light")
end

-- Occluder methods

--@api-stub: Occluder:setVertices
-- Sets the vertices of this occluder.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:setVertices({ 0, 0, 200, 0, 200, 20, 0, 20 })
end

--@api-stub: Occluder:getVertices
-- Returns the vertices of this occluder.
do
  local crate = lurek.light.newOccluder({ 50, 50, 100, 50, 100, 100, 50, 100 })
  local v = crate:getVertices()
  lurek.log.debug("crate has " .. (#v / 2) .. " vertices", "light")
end

--@api-stub: Occluder:setPosition
-- Sets the position of this occluder.
do
  local crate = lurek.light.newOccluder({ 0, 0, 64, 0, 64, 64, 0, 64 })
  crate:setPosition(200, 150)
end

--@api-stub: Occluder:getPosition
-- Returns the position of this occluder.
do
  local crate = lurek.light.newOccluder({ 0, 0, 64, 0, 64, 64, 0, 64 })
  crate:setPosition(120, 80)
  local x, y = crate:getPosition()
  lurek.log.debug("crate at (" .. x .. "," .. y .. ")", "light")
end

--@api-stub: Occluder:setOpacity
-- Sets the opacity of this occluder.
do
  local fence = lurek.light.newOccluder({ 0, 0, 200, 0, 200, 10, 0, 10 })
  fence:setOpacity(0.4)
end

--@api-stub: Occluder:getOpacity
-- Returns the opacity of this occluder.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  if wall:getOpacity() < 1.0 then
    lurek.log.debug("translucent occluder", "light")
  end
end

--@api-stub: Occluder:setLightMask
-- Sets the light mask of this occluder.
do
  local FOREGROUND_LIGHTS = 0x01
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:setLightMask(FOREGROUND_LIGHTS)
end

--@api-stub: Occluder:getLightMask
-- Returns the light mask of this occluder.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  local mask = wall:getLightMask()
  lurek.log.debug("wall mask=" .. mask, "light")
end

--@api-stub: Occluder:setEnabled
-- Sets whether this occluder is enabled and accepts input.
do
  local door = lurek.light.newOccluder({ 0, 0, 40, 0, 40, 80, 0, 80 })
  local door_open = true
  door:setEnabled(not door_open)
end

--@api-stub: Occluder:isEnabled
-- Returns true if this occluder is currently enabled.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  if wall:isEnabled() then
    lurek.log.debug("wall casting shadows", "light")
  end
end

--@api-stub: Occluder:remove
-- Removes a  from this occluder.
do
  local debris = lurek.light.newOccluder({ 0, 0, 30, 0, 30, 30, 0, 30 })
  debris:remove()
end

--@api-stub: Occluder:isValid
-- Returns true if this occluder valid.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:remove()
  if not wall:isValid() then
    lurek.log.debug("wall removed", "light")
  end
end

--@api-stub: Light:setColor
-- Sets the color of this light.
do
  local lt = lurek.light.newLight(200, 300, 150)
  lt:setColor(1.0, 0.85, 0.5)
  lurek.log.info("light colour set", "light")
end

--@api-stub: Light:setShadowColor
-- Sets the shadow color of this light.
do
  local lt = lurek.light.newLight(200, 300, 120)
  lt:setShadowEnabled(true)
  lt:setShadowColor(0.0, 0.0, 0.1, 0.85)
  lurek.log.info("shadow colour set", "light")
end

--@api-stub: Light:transitionTo
-- Performs the transition to operation on this light.
do
  local lt = lurek.light.newLight(100, 100, 80)
  lt:transitionTo({x=400, y=300, radius=200, r=1, g=0.5, b=0}, 2.0)
  lurek.log.info("transition started", "light")
end

-- -----------------------------------------------------------------------------
-- Light methods
-- -----------------------------------------------------------------------------

--@api-stub: Light:type
-- Returns the Lua-visible type name string for this light handle.
do
  local lamp = lurek.light.newLight(0, 0, 120)
  lamp:setPosition(320, 240)
  local t = lamp:type()
  lurek.log.info("Light:type = " .. t, "light")
end
--@api-stub: Light:typeOf
-- Returns true if this light handle matches the given type name string.
do
  local lamp = lurek.light.newLight(0, 0, 120)
  lamp:setPosition(320, 240)
  lurek.log.info("is Light: " .. tostring(lamp:typeOf("Light")), "light")
  lurek.log.info("is wrong: " .. tostring(lamp:typeOf("Unknown")), "light")
end

-- -----------------------------------------------------------------------------
-- LLight methods
-- -----------------------------------------------------------------------------

--@api-stub: LLight:type
-- Returns the Lua-visible type name for this light handle
do
  local light_obj = lurek.light.newLight(0, 0, 80)
  local t = light_obj:type()
  lurek.log.info("LLight:type = " .. t, "light")
end
--@api-stub: LLight:typeOf
-- Returns whether this light handle matches a supported type name
do
  local light_obj = lurek.light.newLight(0, 0, 80)
  lurek.log.info("is LLight: " .. tostring(light_obj:typeOf("LLight")), "light")
  lurek.log.info("is wrong: " .. tostring(light_obj:typeOf("Unknown")), "light")
end
--@api-stub: LOccluder:type
-- Returns the Lua-visible type name for this occluder handle
do
  local occluder_obj = lurek.light.newOccluder({0,0,100,0,100,50,0,50})
  local t = occluder_obj:type()
  lurek.log.info("LOccluder:type = " .. t, "light")
end
--@api-stub: LOccluder:typeOf
-- Returns whether this occluder handle matches a supported type name
do
  local occluder_obj = lurek.light.newOccluder({0,0,100,0,100,50,0,50})
  lurek.log.info("is LOccluder: " .. tostring(occluder_obj:typeOf("LOccluder")), "light")
  lurek.log.info("is wrong: " .. tostring(occluder_obj:typeOf("Unknown")), "light")
end

-- -----------------------------------------------------------------------------
-- LLight methods
-- -----------------------------------------------------------------------------

--@api-stub: LLight:setPosition
-- Sets this light position
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setPosition(512, 256)
  local x, y = lt:getPosition()
  lurek.log.info("position=" .. x .. "," .. y, "light")
end
--@api-stub: LLight:getPosition
-- Returns this light position
do
  local lt = lurek.light.newLight(100, 200, 150)
  local x, y = lt:getPosition()
  lurek.log.info("x=" .. x .. " y=" .. y, "light")
end
--@api-stub: LLight:setRadius
-- Sets this light radius
do
  local lt = lurek.light.newLight(400, 300, 100)
  lt:setRadius(250)
  lurek.log.info("radius=" .. lt:getRadius(), "light")
end
--@api-stub: LLight:getRadius
-- Returns this light radius
do
  local lt = lurek.light.newLight(400, 300, 180)
  lurek.log.info("radius=" .. lt:getRadius(), "light")
end
--@api-stub: LLight:setColor
-- Sets this light RGBA color
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setColor(1.0, 0.6, 0.2, 1.0)   -- warm orange
  local r, g, b, a = lt:getColor()
  lurek.log.info("color r=" .. r .. " g=" .. g, "light")
end
--@api-stub: LLight:getColor
-- Returns this light RGBA color
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setColor(0.2, 0.4, 1.0, 1.0)   -- cool blue
  local r, g, b, a = lt:getColor()
  lurek.log.info("r=" .. r .. " g=" .. g .. " b=" .. b, "light")
end
--@api-stub: LLight:setIntensity
-- Sets this light intensity
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setIntensity(2.5)
  lurek.log.info("intensity=" .. lt:getIntensity(), "light")
end
--@api-stub: LLight:getIntensity
-- Returns this light intensity
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setIntensity(0.8)
  lurek.log.info("intensity=" .. lt:getIntensity(), "light")
end
--@api-stub: LLight:setEnergy
-- Sets this light energy value
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setEnergy(1.5)
  lurek.log.info("energy=" .. lt:getEnergy(), "light")
end
--@api-stub: LLight:getEnergy
-- Returns this light energy value
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setEnergy(0.7)
  lurek.log.info("energy=" .. lt:getEnergy(), "light")
end
--@api-stub: LLight:setBlendMode
-- Sets this light blend mode
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setBlendMode("add")
  lurek.log.info("blend_mode=" .. lt:getBlendMode(), "light")
end
--@api-stub: LLight:getBlendMode
-- Returns this light blend mode string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setBlendMode("mix")
  lurek.log.info("blend_mode=" .. lt:getBlendMode(), "light")
end
--@api-stub: LLight:setFalloff
-- Sets this light falloff mode
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFalloff("smooth")
  lurek.log.info("falloff=" .. lt:getFalloff(), "light")
end
--@api-stub: LLight:getFalloff
-- Returns this light falloff mode string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFalloff("linear")
  lurek.log.info("falloff=" .. lt:getFalloff(), "light")
end
--@api-stub: LLight:setShadowEnabled
-- Enables or disables shadow casting for this light
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lurek.log.info("shadow=" .. tostring(lt:isShadowEnabled()), "light")
end
--@api-stub: LLight:isShadowEnabled
-- Returns whether this light casts shadows
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(false)
  lurek.log.info("shadow=" .. tostring(lt:isShadowEnabled()), "light")
end
--@api-stub: LLight:setShadowColor
-- Sets this light shadow RGBA color
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lt:setShadowColor(0.0, 0.0, 0.2, 0.8)   -- dark blue shadows
  local r, g, b, a = lt:getShadowColor()
  lurek.log.info("shadow_color b=" .. b .. " a=" .. a, "light")
end
--@api-stub: LLight:getShadowColor
-- Returns this light shadow RGBA color
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowColor(0.1, 0.1, 0.3, 0.9)
  local r, g, b, a = lt:getShadowColor()
  lurek.log.info("shadow_color=" .. r .. "," .. g .. "," .. b, "light")
end
--@api-stub: LLight:setShadowFilter
-- Sets this light shadow filter
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lt:setShadowFilter("pcf5")
  lurek.log.info("shadow_filter=" .. lt:getShadowFilter(), "light")
end
--@api-stub: LLight:getShadowFilter
-- Returns this light shadow filter string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowFilter("pcf13")
  lurek.log.info("shadow_filter=" .. lt:getShadowFilter(), "light")
end
--@api-stub: LLight:setShadowSmooth
-- Sets this light shadow smoothing value
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowSmooth(2.0)
  lurek.log.info("shadow_smooth=" .. lt:getShadowSmooth(), "light")
end
--@api-stub: LLight:getShadowSmooth
-- Returns this light shadow smoothing value
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowSmooth(1.5)
  lurek.log.info("shadow_smooth=" .. lt:getShadowSmooth(), "light")
end
--@api-stub: LLight:setLightMask
-- Sets this light's inclusion mask
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightMask(0b00000011)   -- illuminate layers 1 and 2
  lurek.log.info("light_mask=" .. lt:getLightMask(), "light")
end
--@api-stub: LLight:getLightMask
-- Returns this light's inclusion mask
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightMask(0b11111111)   -- illuminate all layers
  lurek.log.info("light_mask=" .. lt:getLightMask(), "light")
end
--@api-stub: LLight:setShadowMask
-- Sets this light's shadow receiver mask
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lt:setShadowMask(0b00001111)   -- only first 4 layers cast shadows
  lurek.log.info("shadow_mask=" .. lt:getShadowMask(), "light")
end
--@api-stub: LLight:getShadowMask
-- Returns this light's shadow receiver mask
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowMask(0b11111111)
  lurek.log.info("shadow_mask=" .. lt:getShadowMask(), "light")
end
--@api-stub: LLight:setEnabled
-- Enables or disables this light
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setEnabled(false)
  lurek.log.info("enabled=" .. tostring(lt:isEnabled()), "light")
  lt:setEnabled(true)
  lurek.log.info("re-enabled=" .. tostring(lt:isEnabled()), "light")
end
--@api-stub: LLight:isEnabled
-- Returns whether this light is enabled
do
  local lt = lurek.light.newLight(400, 300, 200)
  lurek.log.info("enabled by default=" .. tostring(lt:isEnabled()), "light")
end
--@api-stub: LLight:setLightType
-- Sets this light type
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setDirection(math.pi / 2)
  lt:setInnerAngle(math.pi / 8)
  lt:setOuterAngle(math.pi / 4)
  lurek.log.info("type=" .. lt:getLightType(), "light")
end
--@api-stub: LLight:getLightType
-- Returns this light type string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("point")
  lurek.log.info("type=" .. lt:getLightType(), "light")
end
--@api-stub: LLight:setDirection
-- Sets this light direction angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setDirection(math.pi / 4)   -- point northeast
  lurek.log.info("direction=" .. lt:getDirection(), "light")
end
--@api-stub: LLight:getDirection
-- Returns this light direction angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setDirection(math.pi)
  lurek.log.info("direction=" .. lt:getDirection(), "light")
end
--@api-stub: LLight:setInnerAngle
-- Sets this spot light inner cone angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setInnerAngle(math.pi / 8)
  lurek.log.info("inner_angle=" .. lt:getInnerAngle(), "light")
end
--@api-stub: LLight:getInnerAngle
-- Returns this spot light inner cone angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setInnerAngle(math.pi / 6)
  lurek.log.info("inner_angle=" .. lt:getInnerAngle(), "light")
end
--@api-stub: LLight:setOuterAngle
-- Sets this spot light outer cone angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setInnerAngle(math.pi / 8)
  lt:setOuterAngle(math.pi / 4)
  lurek.log.info("outer_angle=" .. lt:getOuterAngle(), "light")
end
--@api-stub: LLight:getOuterAngle
-- Returns this spot light outer cone angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setOuterAngle(math.pi / 3)
  lurek.log.info("outer_angle=" .. lt:getOuterAngle(), "light")
end
--@api-stub: LLight:setAttenuation
-- Sets this light attenuation coefficients
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setAttenuation(1.0, 0.09, 0.032)   -- typical indoor point light
  local c, l, q = lt:getAttenuation()
  lurek.log.info("attenuation c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end
--@api-stub: LLight:getAttenuation
-- Returns this light attenuation coefficients
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setAttenuation(1.0, 0.14, 0.07)
  local c, l, q = lt:getAttenuation()
  lurek.log.info("c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end
--@api-stub: LLight:setFlicker
-- Configures flicker speed and strength for this light
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFlicker(8.0, 0.15)   -- speed=8 Hz, strength=15%
  local speed, strength = lt:getFlicker()
  lurek.log.info("flicker speed=" .. speed .. " strength=" .. strength, "light")
end
--@api-stub: LLight:getFlicker
-- Returns this light flicker speed and strength
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFlicker(5.0, 0.2)
  local speed, strength = lt:getFlicker()
  lurek.log.info("speed=" .. speed .. " strength=" .. strength, "light")
end
--@api-stub: LLight:setFlickerEnabled
-- Enables or disables this light flicker state
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFlicker(6.0, 0.1)
  lt:setFlickerEnabled(true)
  lurek.log.info("flicker=" .. tostring(lt:isFlickerEnabled()), "light")
end
--@api-stub: LLight:isFlickerEnabled
-- Returns whether this light flicker is enabled
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFlicker(4.0, 0.1)
  lt:setFlickerEnabled(false)
  lurek.log.info("flicker_enabled=" .. tostring(lt:isFlickerEnabled()), "light")
end
--@api-stub: LLight:setGroupId
-- Sets this light group id
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setGroupId(1)
  lurek.log.info("group_id=" .. lt:getGroupId(), "light")
end
--@api-stub: LLight:getGroupId
-- Returns this light group id
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setGroupId(2)
  lurek.log.info("group_id=" .. lt:getGroupId(), "light")
end
--@api-stub: LLight:setVolumetric
-- Enables or disables volumetric behavior for this light
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setVolumetric(true)
  lurek.log.info("volumetric=" .. tostring(lt:isVolumetric()), "light")
end
--@api-stub: LLight:isVolumetric
-- Returns whether this light is volumetric
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setVolumetric(false)
  lurek.log.info("volumetric=" .. tostring(lt:isVolumetric()), "light")
end
--@api-stub: LLight:remove
-- Removes this light from the shared light world
do
  local lt = lurek.light.newLight(400, 300, 200)
  lurek.log.info("valid before remove=" .. tostring(lt:isValid()), "light")
  lt:remove()
  lurek.log.info("valid after remove=" .. tostring(lt:isValid()), "light")
end
--@api-stub: LLight:isValid
-- Returns whether this light handle still points to a live light
do
  local lt = lurek.light.newLight(400, 300, 200)
  lurek.log.info("valid=" .. tostring(lt:isValid()), "light")
end
--@api-stub: LLight:addFlicker
-- Adds flicker from min/max intensity range and frequency
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:addFlicker(0.8, 1.2, 8.0)   -- amplitude between 80%â€“120% of base, 8 Hz
  lurek.log.info("flicker active=" .. tostring(lt:isFlickerEnabled()), "light")
end
--@api-stub: LLight:transitionTo
-- Starts a transition toward target color, intensity, and radius values
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setColor(1.0, 1.0, 0.8, 1.0)
  lt:transitionTo({r=0.0, g=0.0, b=1.0, a=1.0, intensity=0.3, radius=100}, 2.0)
  lt:updateTransition(0.5)
  lurek.log.info("transition progress=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:updateTransition
-- Advances this light's active transition and applies interpolated values
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:transitionTo({r=1.0, g=0.0, b=0.0, a=1.0}, 1.0)
  lt:updateTransition(0.25)
  lurek.log.info("progress=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:stopTransition
-- Stops and clears this light's active transition
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:transitionTo({intensity=0.1}, 5.0)
  lt:stopTransition()
  lurek.log.info("progress after stop=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:transitionProgress
-- Returns active transition progress or 1
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:transitionTo({intensity=0.2}, 2.0)
  lt:updateTransition(1.0)   -- advance halfway
  lurek.log.info("transition_progress=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:setCookie
-- Stores a cookie texture path on this Lua light handle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setCookie("assets/cookie_window.png")
  lurek.log.info("cookie=" .. tostring(lt:getCookie()), "light")
end
--@api-stub: LLight:getCookie
-- Returns the cookie texture path stored on this Lua light handle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setCookie("assets/gobo_slats.png")
  lurek.log.info("cookie=" .. tostring(lt:getCookie()), "light")
end
--@api-stub: LLight:clearCookie
-- Clears the cookie texture path stored on this Lua light handle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setCookie("assets/gobo.png")
  lt:clearCookie()
  lurek.log.info("cookie after clear=" .. tostring(lt:getCookie()), "light")
end

--@api-stub: LLight:setNormalMap
-- Sets the normal map path used by this light
do
  local l = lurek.light.newLight(100, 100, 64)
  l:setNormalMap("assets/textures/normal.png")
end

--@api-stub: LLight:getNormalMap
-- Returns the normal map path used by this light
do
  local l = lurek.light.newLight(100, 100, 64)
  local map = l:getNormalMap()
end

--@api-stub: LLight:clearNormalMap
-- Clears the normal map path used by this light
do
  local l = lurek.light.newLight(100, 100, 64)
  l:clearNormalMap()
end

--@api-stub: LLight:setNormalStrength
-- Sets this light's normal map strength
do
  local l = lurek.light.newLight(100, 100, 64)
  l:setNormalStrength(0.75)
end

--@api-stub: LLight:getNormalStrength
-- Returns this light's normal map strength
do
  local l = lurek.light.newLight(100, 100, 64)
  local s = l:getNormalStrength()
end

--@api-stub: LLight:setShadowSoftness
-- Sets this light shadow softness value
do
  local l = lurek.light.newLight(100, 100, 64)
  l:setShadowSoftness(0.5)
end

--@api-stub: LLight:getShadowSoftness
-- Returns this light shadow softness value
do
  local l = lurek.light.newLight(100, 100, 64)
  local s = l:getShadowSoftness()
end
