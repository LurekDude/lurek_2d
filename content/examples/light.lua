-- content/examples/light.lua
-- Hand-written coverage of the lurek.light API (83 items).
--
-- Manages a 2D lighting world: point/directional/spot Light handles,
-- polygon Occluder shadow casters, ambient colour, group batching,
-- flicker, transitions, cookies, and god-ray hints. Lights persist
-- once added; call `lurek.light.clear()` between scenes.
--
-- Run: cargo run -- content/examples/light.lua

-- ── lurek.light.* functions ──

--@api-stub: lurek.light.newLight
-- Creates a new light at (x, y) with the given radius and optional settings.
-- Pass an opts table (color, intensity, blendMode, ...) to avoid chained setters when seeding a level.
do  -- lurek.light.newLight
  local torch = lurek.light.newLight(200, 150, 180, { color = {1.0, 0.7, 0.3, 1.0}, intensity = 1.2 })
  torch:setBlendMode("add")
  lurek.log.info("torch lit at (200, 150)", "light")
end

--@api-stub: lurek.light.newOccluder
-- Creates a new shadow occluder from a vertex table and optional settings.
-- Vertices are a flat {x1,y1,x2,y2,...} table in world space; opacity controls how solid the cast shadow looks.
do  -- lurek.light.newOccluder
  local wall = lurek.light.newOccluder({ 100, 100, 300, 100, 300, 120, 100, 120 }, { opacity = 0.85 })
  wall:setEnabled(true)
end

--@api-stub: lurek.light.setAmbient
-- Sets the global ambient light color.
-- Call once per scene/time-of-day; ambient is the floor brightness applied where no light reaches.
do  -- lurek.light.setAmbient
  lurek.light.setAmbient(0.15, 0.18, 0.30, 1.0)
  lurek.log.info("ambient set to dusk blue", "light")
end

--@api-stub: lurek.light.getAmbient
-- Returns the global ambient light color as (r, g, b, a).
-- Branch on the result to decide whether the scene needs torches or sunbeam effects this frame.
do  -- lurek.light.getAmbient
  local r, g, b, _ = lurek.light.getAmbient()
  if r + g + b < 0.5 then
    lurek.log.info("scene is dark, spawning extra torches", "light")
  end
end

--@api-stub: lurek.light.setEnabled
-- Sets whether the lighting system is active.
-- Toggle off during cinematics or fully-lit menus to skip the entire light pass.
do  -- lurek.light.setEnabled
  local cinematic_mode = false
  lurek.light.setEnabled(not cinematic_mode)
end

--@api-stub: lurek.light.isEnabled
-- Returns whether the lighting system is active.
-- Use as a guard before queuing per-frame light updates that would be wasted otherwise.
do  -- lurek.light.isEnabled
  if lurek.light.isEnabled() then
    lurek.log.info("lighting active", "light")
  end
end

--@api-stub: lurek.light.getLightCount
-- Returns the number of lights in the world.
-- Useful for budget warnings — getMaxLights caps how many actually render per frame.
do  -- lurek.light.getLightCount
  local n = lurek.light.getLightCount()
  if n > 32 then
    lurek.log.warn("scene has " .. n .. " lights, may exceed budget", "perf")
  end
end

--@api-stub: lurek.light.getOccluderCount
-- Returns the number of occluders in the world.
-- Useful for level-loading sanity checks; very high counts hurt the shadow pass.
do  -- lurek.light.getOccluderCount
  local n = lurek.light.getOccluderCount()
  lurek.log.info("scene occluders: " .. n, "light")
end

--@api-stub: lurek.light.getMaxLights
-- Returns the maximum number of lights processed per frame.
-- Read at startup to detect a low cap and bump it before the first frame renders.
do  -- lurek.light.getMaxLights
  local cap = lurek.light.getMaxLights()
  if cap < 64 then
    lurek.light.setMaxLights(64)
  end
end

--@api-stub: lurek.light.setMaxLights
-- Sets the maximum number of lights processed per frame (clamped 1–256).
-- Drive from a graphics-quality preset; 32 for low-end, 128 for high-end.
do  -- lurek.light.setMaxLights
  local quality = "high"
  local cap = (quality == "high") and 128 or 32
  lurek.light.setMaxLights(cap)
end

--@api-stub: lurek.light.clear
-- Removes all lights and occluders, resets ambient to default.
-- Call between scene transitions so stale handles do not leak into the next level.
do  -- lurek.light.clear
  lurek.light.clear()
  lurek.log.info("light world reset for new scene", "light")
end

--@api-stub: lurek.light.setGroupEnabled
-- Sets the enabled state for all lights in the given group.
-- Group ids are user-assigned via setGroupId; great for "blackout the streetlamps" style triggers.
do  -- lurek.light.setGroupEnabled
  local TORCHES_GROUP = 1
  lurek.light.setGroupEnabled(TORCHES_GROUP, false)
end

--@api-stub: lurek.light.setGroupIntensity
-- Sets the intensity for all lights in the given group.
-- Use for ambient dimming: lower a whole group's intensity over time without touching colour or radius.
do  -- lurek.light.setGroupIntensity
  local STREETLAMPS = 2
  lurek.light.setGroupIntensity(STREETLAMPS, 0.6)
end

--@api-stub: lurek.light.setGroupColor
-- Sets the color for all lights in the given group.
-- Tinting the alarm-light group red is a one-call effect once setGroupId has been assigned.
do  -- lurek.light.setGroupColor
  local ALARM_LIGHTS = 3
  lurek.light.setGroupColor(ALARM_LIGHTS, 1.0, 0.1, 0.1, 1.0)
end

--@api-stub: lurek.light.getGroupCount
-- Returns the number of lights in the given group.
-- Useful for verifying setGroupId wiring after spawning a batch of identical fixtures.
do  -- lurek.light.getGroupCount
  local TORCHES_GROUP = 1
  local n = lurek.light.getGroupCount(TORCHES_GROUP)
  lurek.log.info("torches group has " .. n .. " lights", "light")
end

--@api-stub: lurek.light.advanceFlickers
-- Advances flicker phase for all lights with flicker enabled.
-- Call exactly once per frame from `lurek.process(dt)` so torches breathe in real time.
do  -- lurek.light.advanceFlickers
  function lurek.process(dt) lurek.light.advanceFlickers(dt) end
end

--@api-stub: lurek.light.syncAmbient
-- Returns the current ambient light colour as (r, g, b, a).
-- Use the snapshot to tint fog or shader uniforms so they stay in step with day/night transitions.
do  -- lurek.light.syncAmbient
  local r, g, b, a = lurek.light.syncAmbient()
  local fog_tint = { r * 0.8, g * 0.8, b * 0.8, a }
  lurek.log.debug("fog tint=(" .. fog_tint[1] .. "," .. fog_tint[2] .. ")", "fx")
end

--@api-stub: lurek.light.getGodRayHints
-- Returns a list of directional light hints for god-ray rendering.
-- Feed each {x, y, angle} entry into a post-process volumetric streak shader.
do  -- lurek.light.getGodRayHints
  local hints = lurek.light.getGodRayHints()
  for _, h in ipairs(hints) do
    lurek.log.debug("god-ray src x=" .. h.x .. " y=" .. h.y .. " angle=" .. h.angle, "fx")
  end
end

-- ── Light methods ──

--@api-stub: Light:setPosition
-- Sets the light's world-space position.
-- Call from `lurek.process` to pin a light to a moving entity (player torch, projectile glow).
do  -- Light:setPosition
  local lamp = lurek.light.newLight(0, 0, 120)
  lamp:setPosition(320, 240)
end

--@api-stub: Light:getPosition
-- Returns the light's world-space position.
-- Use to sample world coordinates back, e.g. for screen-space god-ray projection.
do  -- Light:getPosition
  local lamp = lurek.light.newLight(150, 100, 80)
  local x, y = lamp:getPosition()
  lurek.log.info("lamp at (" .. x .. "," .. y .. ")", "light")
end

--@api-stub: Light:setRadius
-- Sets the light's influence radius.
-- Animate radius for "battery dying" or "explosion bloom" effects rather than toggling enabled.
do  -- Light:setRadius
  local lantern = lurek.light.newLight(50, 50, 100)
  local battery_pct = 0.6
  lantern:setRadius(40 + 80 * battery_pct)
end

--@api-stub: Light:getRadius
-- Returns the light's influence radius.
-- Clamp the read value before tween logic to keep too-small lights visible.
do  -- Light:getRadius
  local glow = lurek.light.newLight(0, 0, 75)
  if glow:getRadius() < 50 then
    glow:setRadius(50)
  end
end

--@api-stub: Light:getColor
-- Returns the light's tint color as (r, g, b, a).
-- Read once and reuse instead of guessing a fixture's colour to derive shadow tint or particle hue.
do  -- Light:getColor
  local lamp = lurek.light.newLight(0, 0, 100, { color = {0.9, 0.7, 0.5, 1.0} })
  local r, g, b, a = lamp:getColor()
  lurek.log.debug("lamp color=(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "light")
end

--@api-stub: Light:setIntensity
-- Sets the brightness multiplier.
-- Values >1 push beyond base brightness; pair with HDR / bloom for blown-out highlights.
do  -- Light:setIntensity
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setIntensity(1.4)
end

--@api-stub: Light:getIntensity
-- Returns the brightness multiplier.
-- Compare against a low threshold to flag "barely visible" fixtures during a debug overlay.
do  -- Light:getIntensity
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getIntensity() < 0.2 then
    lurek.log.warn("lamp intensity very low", "light")
  end
end

--@api-stub: Light:setEnergy
-- Sets the energy scaling factor.
-- Distinct from intensity — energy affects falloff strength, useful for sun-like contributors.
do  -- Light:setEnergy
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setEnergy(2.5)
end

--@api-stub: Light:getEnergy
-- Returns the energy scaling factor.
-- Pull current energy when serialising fixture state for save files.
do  -- Light:getEnergy
  local lamp = lurek.light.newLight(0, 0, 100)
  local e = lamp:getEnergy()
  lurek.log.debug("lamp energy=" .. e, "light")
end

--@api-stub: Light:setBlendMode
-- Sets the blend mode ('add', 'sub', or 'mix').
-- 'add' is the default for emissive lights; 'sub' lets you carve dark patches (anti-light).
do  -- Light:setBlendMode
  local glow = lurek.light.newLight(0, 0, 100)
  glow:setBlendMode("add")
end

--@api-stub: Light:getBlendMode
-- Returns the blend mode as a string.
-- Verify the mode after loading saved fixtures so additive lights do not silently switch to mix.
do  -- Light:getBlendMode
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getBlendMode() ~= "add" then
    lamp:setBlendMode("add")
  end
end

--@api-stub: Light:setFalloff
-- Sets the falloff mode ('linear', 'smooth', or 'constant').
-- 'smooth' looks best for organic fixtures; 'constant' keeps full brightness to the radius edge.
do  -- Light:setFalloff
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setFalloff("smooth")
end

--@api-stub: Light:getFalloff
-- Returns the falloff mode as a string.
-- Inspect when debugging "why does this light look harsh?" — likely 'linear' on a small radius.
do  -- Light:getFalloff
  local lamp = lurek.light.newLight(0, 0, 100)
  local mode = lamp:getFalloff()
  lurek.log.debug("falloff=" .. mode, "light")
end

--@api-stub: Light:setShadowEnabled
-- Sets whether this light casts shadows.
-- Disable on small ambient fill lights to keep the shadow pass cheap.
do  -- Light:setShadowEnabled
  local torch = lurek.light.newLight(100, 100, 200)
  torch:setShadowEnabled(true)
end

--@api-stub: Light:isShadowEnabled
-- Returns whether this light casts shadows.
-- Promote a cheap fill-light to a shadow caster only after it becomes the player's primary source.
do  -- Light:isShadowEnabled
  local lamp = lurek.light.newLight(0, 0, 100)
  if not lamp:isShadowEnabled() then
    lamp:setShadowEnabled(true)
  end
end

--@api-stub: Light:getShadowColor
-- Returns the shadow region color as (r, g, b, a).
-- Read alpha to detect translucent shadows (e.g. cloth) and tweak occluder opacity to match.
do  -- Light:getShadowColor
  local lamp = lurek.light.newLight(0, 0, 100)
  local _, _, _, a = lamp:getShadowColor()
  lurek.log.debug("shadow alpha=" .. a, "light")
end

--@api-stub: Light:setShadowFilter
-- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
-- 'pcf13' = soft 13-tap PCF, costliest but smoothest; 'none' for crisp pixel-art aesthetics.
do  -- Light:setShadowFilter
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowFilter("pcf13")
end

--@api-stub: Light:getShadowFilter
-- Returns the shadow edge filter as a string.
-- Auto-bump 'none' to 'pcf5' when high-quality preset is enabled.
do  -- Light:getShadowFilter
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getShadowFilter() == "none" then
    lamp:setShadowFilter("pcf5")
  end
end

--@api-stub: Light:setShadowSmooth
-- Sets the shadow edge smoothing factor.
-- Higher values blur the penumbra; pair with pcf13 for soft hero-character shadows.
do  -- Light:setShadowSmooth
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowSmooth(2.5)
end

--@api-stub: Light:getShadowSmooth
-- Returns the shadow edge smoothing factor.
-- Read to round-trip a value through a slider widget without integer-truncation.
do  -- Light:getShadowSmooth
  local lamp = lurek.light.newLight(0, 0, 100)
  local s = lamp:getShadowSmooth()
  lurek.log.debug("shadow smooth=" .. s, "light")
end

--@api-stub: Light:setLightMask
-- Sets the light interaction bitmask.
-- Bits decide which occluder layers a light interacts with; great for foreground/background separation.
do  -- Light:setLightMask
  local PLAYER_LAYER = 0x01
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setLightMask(PLAYER_LAYER)
end

--@api-stub: Light:getLightMask
-- Returns the light interaction bitmask.
-- Read to verify a fixture's mask after loading from a level file before its first render.
do  -- Light:getLightMask
  local lamp = lurek.light.newLight(0, 0, 100)
  local mask = lamp:getLightMask()
  lurek.log.debug("lamp mask=" .. mask, "light")
end

--@api-stub: Light:setShadowMask
-- Sets the shadow casting bitmask.
-- Independent of light mask: e.g. a light hits everything but only casts shadows from solid walls.
do  -- Light:setShadowMask
  local WALLS_ONLY = 0x02
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowMask(WALLS_ONLY)
end

--@api-stub: Light:getShadowMask
-- Returns the shadow casting bitmask.
-- A zero result means the light never casts shadows — promote to 0xFFFF to enable everything.
do  -- Light:getShadowMask
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getShadowMask() == 0 then
    lamp:setShadowMask(0xFFFF)
  end
end

--@api-stub: Light:setEnabled
-- Sets whether this light is active.
-- Cheaper than remove/add for fixtures that toggle frequently (switches, blinking signs).
do  -- Light:setEnabled
  local lamp = lurek.light.newLight(0, 0, 100)
  local power_on = false
  lamp:setEnabled(power_on)
end

--@api-stub: Light:isEnabled
-- Returns whether this light is active.
-- Skip animating intensity on disabled fixtures to save Lua/Rust hops.
do  -- Light:isEnabled
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:isEnabled() then
    lurek.log.debug("lamp on", "light")
  end
end

--@api-stub: Light:setLightType
-- Sets the geometric light type ('point', 'directional', or 'spot').
-- Switching to 'directional' makes a light behave like the sun — direction matters, position does not.
do  -- Light:setLightType
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setLightType("directional")
  sun:setDirection(math.pi * 0.25)
end

--@api-stub: Light:getLightType
-- Returns the geometric light type as a string.
-- Branch on the type to know whether direction / inner-angle / outer-angle setters apply.
do  -- Light:getLightType
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getLightType() == "spot" then
    lamp:setOuterAngle(math.pi / 4)
  end
end

--@api-stub: Light:setDirection
-- Sets the direction angle in radians.
-- Drive a flashlight cone by setting direction from the player's facing each frame.
do  -- Light:setDirection
  local flashlight = lurek.light.newLight(100, 100, 200)
  flashlight:setLightType("spot")
  flashlight:setDirection(math.pi / 2)
end

--@api-stub: Light:getDirection
-- Returns the direction angle in radians.
-- Read after a tween to confirm the angle wrapped correctly across pi / -pi boundaries.
do  -- Light:getDirection
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setDirection(0.5)
  local angle = sun:getDirection()
  lurek.log.debug("sun angle=" .. angle, "light")
end

--@api-stub: Light:setInnerAngle
-- Sets the inner cone angle in radians for spot lights.
-- Inside the inner cone the light is at full intensity; outside, it ramps down to the outer angle.
do  -- Light:setInnerAngle
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setLightType("spot")
  spot:setInnerAngle(math.pi / 8)
end

--@api-stub: Light:getInnerAngle
-- Returns the inner cone angle in radians.
-- Use to derive a UI cone-width slider value without re-reading from your config table.
do  -- Light:getInnerAngle
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setInnerAngle(0.3)
  lurek.log.debug("inner=" .. spot:getInnerAngle(), "light")
end

--@api-stub: Light:setOuterAngle
-- Sets the outer cone angle in radians for spot lights.
-- Should be >= inner angle; sets the hard cut-off where the spot light contributes nothing.
do  -- Light:setOuterAngle
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setLightType("spot")
  spot:setOuterAngle(math.pi / 4)
end

--@api-stub: Light:getOuterAngle
-- Returns the outer cone angle in radians.
-- Clamp to <= pi after reading; an outer angle bigger than pi means a degenerate full-circle cone.
do  -- Light:getOuterAngle
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setOuterAngle(0.7)
  if spot:getOuterAngle() > math.pi then
    spot:setOuterAngle(math.pi)
  end
end

--@api-stub: Light:setAttenuation
-- Sets the custom attenuation coefficients (constant, linear, quadratic).
-- Standard physical falloff is roughly (1.0, 0.09, 0.032); raise quadratic for sharper drop-off.
do  -- Light:setAttenuation
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setAttenuation(1.0, 0.09, 0.032)
end

--@api-stub: Light:getAttenuation
-- Returns the custom attenuation coefficients as (constant, linear, quadratic).
-- Read all three at once when copying lighting parameters between sister fixtures.
do  -- Light:getAttenuation
  local lamp = lurek.light.newLight(0, 0, 100)
  local c, l, q = lamp:getAttenuation()
  lurek.log.debug("att c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end

--@api-stub: Light:setFlicker
-- Sets the flicker effect speed and strength (enables flicker).
-- Speed is radians/sec, strength is 0..1 modulation depth; 8.0 / 0.15 reads as nervous candle.
do  -- Light:setFlicker
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(8.0, 0.15)
end

--@api-stub: Light:getFlicker
-- Returns the flicker effect speed and strength.
-- Read both back when storing live tuning values from an editor slider.
do  -- Light:getFlicker
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(6.0, 0.2)
  local speed, strength = torch:getFlicker()
  lurek.log.debug("flicker speed=" .. speed .. " strength=" .. strength, "light")
end

--@api-stub: Light:setFlickerEnabled
-- Sets whether the flicker effect is active.
-- Pause flicker during cinematics so cutscene lighting stays still on every frame.
do  -- Light:setFlickerEnabled
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(5.0, 0.1)
  torch:setFlickerEnabled(true)
end

--@api-stub: Light:isFlickerEnabled
-- Returns whether the flicker effect is active.
-- Promote a still light to a flickering one only when it becomes the only light source nearby.
do  -- Light:isFlickerEnabled
  local torch = lurek.light.newLight(0, 0, 120)
  if not torch:isFlickerEnabled() then
    torch:addFlicker(0.85, 1.15, 4.0)
  end
end

--@api-stub: Light:setGroupId
-- Sets the group identifier for batch operations.
-- Tag fixtures by purpose (torches, alarms, neon) so lurek.light.setGroup* can hit them all at once.
do  -- Light:setGroupId
  local TORCHES = 1
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setGroupId(TORCHES)
end

--@api-stub: Light:getGroupId
-- Returns the group identifier.
-- Test the group id against your enum constants to drive UI tooltips ("Alarm light").
do  -- Light:getGroupId
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setGroupId(7)
  if lamp:getGroupId() == 7 then
    lurek.log.debug("lamp in alarm group", "light")
  end
end

--@api-stub: Light:setVolumetric
-- Sets whether this light hints at volumetric scattering.
-- Marks the light to appear in `getGodRayHints` so a post-process pass can render light streaks.
do  -- Light:setVolumetric
  local headlamp = lurek.light.newLight(0, 0, 200)
  headlamp:setVolumetric(true)
end

--@api-stub: Light:isVolumetric
-- Returns whether this light hints at volumetric scattering.
-- Use to drive an editor toggle without re-reading from saved level data.
do  -- Light:isVolumetric
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:isVolumetric() then
    lurek.log.debug("lamp produces god rays", "fx")
  end
end

--@api-stub: Light:remove
-- Removes this light from the world.
-- Pair with a transient muzzle-flash or impact spark; the handle becomes invalid afterwards.
do  -- Light:remove
  local muzzle_flash = lurek.light.newLight(64, 64, 60, { intensity = 2.0 })
  muzzle_flash:remove()
end

--@api-stub: Light:isValid
-- Returns whether this light handle is still valid.
-- Always check before reusing a stored handle that may have been removed by another system.
do  -- Light:isValid
  local spark = lurek.light.newLight(0, 0, 30)
  spark:remove()
  if not spark:isValid() then
    lurek.log.debug("spark expired", "light")
  end
end

--@api-stub: Light:addFlicker
-- Convenience method to set a flicker effect using amplitude range and frequency.
-- Pass min/max intensity multipliers (e.g. 0.8, 1.2 = ±20%) and frequency in Hz; engine converts internally.
do  -- Light:addFlicker
  local torch = lurek.light.newLight(0, 0, 120)
  torch:addFlicker(0.8, 1.2, 5.0)
end

--@api-stub: Light:updateTransition
-- Advances the active transition by `dt` seconds and applies the interpolated values.
-- Call from `lurek.process` so a transitionTo fade actually progresses each frame.
do  -- Light:updateTransition
  local lamp = lurek.light.newLight(0, 0, 100)
  function lurek.process(dt) lamp:updateTransition(dt) end
end

--@api-stub: Light:stopTransition
-- Cancels the active light transition.
-- Use when interrupting a fade-out because the player re-triggered the lamp switch.
do  -- Light:stopTransition
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:stopTransition()
end

--@api-stub: Light:transitionProgress
-- Returns the fractional progress `[0, 1]` of the active transition, or 1 if none is running.
-- Compare against >= 1.0 to chain a follow-up transition once the current fade completes.
do  -- Light:transitionProgress
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:transitionProgress() >= 1.0 then
    lurek.log.debug("transition complete", "light")
  end
end

--@api-stub: Light:setCookie
-- Sets the texture path used as a light cookie (mask) for projection.
-- Cookie textures project a pattern (window grid, leaves, logo) through the light's beam.
do  -- Light:setCookie
  local projector = lurek.light.newLight(0, 0, 200)
  projector:setCookie("textures/window_pattern.png")
end

--@api-stub: Light:getCookie
-- Returns the current cookie texture path, or `nil` if unset.
-- Read to detect whether a fixture currently projects a pattern before swapping textures.
do  -- Light:getCookie
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setCookie("textures/leaves.png")
  local path = lamp:getCookie()
  lurek.log.debug("cookie=" .. tostring(path), "light")
end

--@api-stub: Light:clearCookie
-- Removes the cookie texture assignment.
-- Call when a projector turns off, returning the light to a plain unmasked beam.
do  -- Light:clearCookie
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setCookie("textures/leaves.png")
  lamp:clearCookie()
end

-- ── Occluder methods ──

--@api-stub: Occluder:setVertices
-- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
-- Use to morph the silhouette of a destructible wall after damage without recreating the occluder.
do  -- Occluder:setVertices
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:setVertices({ 0, 0, 200, 0, 200, 20, 0, 20 })
end

--@api-stub: Occluder:getVertices
-- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
-- Useful for collision-debug overlays or for serialising procedural geometry.
do  -- Occluder:getVertices
  local crate = lurek.light.newOccluder({ 50, 50, 100, 50, 100, 100, 50, 100 })
  local v = crate:getVertices()
  lurek.log.debug("crate has " .. (#v / 2) .. " vertices", "light")
end

--@api-stub: Occluder:setPosition
-- Sets the translation offset applied to all vertices.
-- Cheaper than rewriting the vertex table when an occluder slides with a moving platform.
do  -- Occluder:setPosition
  local crate = lurek.light.newOccluder({ 0, 0, 64, 0, 64, 64, 0, 64 })
  crate:setPosition(200, 150)
end

--@api-stub: Occluder:getPosition
-- Returns the translation offset as (x, y).
-- Read to keep a cosmetic sprite aligned with the invisible occluder it represents.
do  -- Occluder:getPosition
  local crate = lurek.light.newOccluder({ 0, 0, 64, 0, 64, 64, 0, 64 })
  crate:setPosition(120, 80)
  local x, y = crate:getPosition()
  lurek.log.debug("crate at (" .. x .. "," .. y .. ")", "light")
end

--@api-stub: Occluder:setOpacity
-- Sets the shadow opacity (0.0–1.0).
-- Drop below 1.0 for translucent obstacles like fences or stained glass.
do  -- Occluder:setOpacity
  local fence = lurek.light.newOccluder({ 0, 0, 200, 0, 200, 10, 0, 10 })
  fence:setOpacity(0.4)
end

--@api-stub: Occluder:getOpacity
-- Returns the shadow opacity.
-- Branch on the value to flag translucent occluders for special rendering or sound (clinking glass).
do  -- Occluder:getOpacity
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  if wall:getOpacity() < 1.0 then
    lurek.log.debug("translucent occluder", "light")
  end
end

--@api-stub: Occluder:setLightMask
-- Sets the light interaction bitmask.
-- Match this against light:setLightMask so each occluder only blocks the layers it should.
do  -- Occluder:setLightMask
  local FOREGROUND_LIGHTS = 0x01
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:setLightMask(FOREGROUND_LIGHTS)
end

--@api-stub: Occluder:getLightMask
-- Returns the light interaction bitmask.
-- Read after loading a level to assert occluders are tagged into the layers you expect.
do  -- Occluder:getLightMask
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  local mask = wall:getLightMask()
  lurek.log.debug("wall mask=" .. mask, "light")
end

--@api-stub: Occluder:setEnabled
-- Sets whether this occluder is active.
-- Toggle a doorway off when the door opens so light can spill through without rebuilding geometry.
do  -- Occluder:setEnabled
  local door = lurek.light.newOccluder({ 0, 0, 40, 0, 40, 80, 0, 80 })
  local door_open = true
  door:setEnabled(not door_open)
end

--@api-stub: Occluder:isEnabled
-- Returns whether this occluder is active.
-- Inspect before piping debug-overlay rendering so disabled occluders are drawn dimmer.
do  -- Occluder:isEnabled
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  if wall:isEnabled() then
    lurek.log.debug("wall casting shadows", "light")
  end
end

--@api-stub: Occluder:remove
-- Removes this occluder from the world.
-- Use when destructible cover is shattered; the handle becomes invalid afterwards.
do  -- Occluder:remove
  local debris = lurek.light.newOccluder({ 0, 0, 30, 0, 30, 30, 0, 30 })
  debris:remove()
end

--@api-stub: Occluder:isValid
-- Returns whether this occluder handle is still valid.
-- Always check before reusing a saved handle that another system may have removed.
do  -- Occluder:isValid
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:remove()
  if not wall:isValid() then
    lurek.log.debug("wall removed", "light")
  end
end

--@api-stub: Light:setColor
-- Sets the RGB colour of the light source.
-- Warm (1, 0.8, 0.5) for candles; cool (0.7, 0.8, 1) for moonlight.
do  -- Light:setColor
  local lt = lurek.light.newLight(200, 300, 150)
  lt:setColor(1.0, 0.85, 0.5)
  lurek.log.info("light colour set", "light")
end

--@api-stub: Light:setShadowColor
-- Sets the RGBA colour used where the light casts shadows.
-- Full black (0,0,0,1) for harsh shadows; tinted for indirect-light approximation.
do  -- Light:setShadowColor
  local lt = lurek.light.newLight(200, 300, 120)
  lt:setShadowEnabled(true)
  lt:setShadowColor(0.0, 0.0, 0.1, 0.85)
  lurek.log.info("shadow colour set", "light")
end

--@api-stub: Light:transitionTo
-- Smoothly interpolates the light's position, radius, and colour to target values.
-- duration in seconds; fires optional callback on completion.
do  -- Light:transitionTo
  local lt = lurek.light.newLight(100, 100, 80)
  lt:transitionTo({x=400, y=300, radius=200, r=1, g=0.5, b=0}, 2.0)
  lurek.log.info("transition started", "light")
end

-- =============================================================================
-- STUBS: 4 uncovered lurek.light API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Light methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Light:type ----------------------------------------------------
--@api-stub: Light:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- light_stub:type()  -- -> string
-- (replace light_stub with your real Light instance above)

-- ---- Stub: Light:typeOf --------------------------------------------------
--@api-stub: Light:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- light_stub:typeOf("hero")  -- -> boolean
-- (replace light_stub with your real Light instance above)

-- -----------------------------------------------------------------------------
-- Occluder methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Occluder:type -------------------------------------------------
--@api-stub: Occluder:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- occluder_stub:type()  -- -> string
-- (replace occluder_stub with your real Occluder instance above)

-- ---- Stub: Occluder:typeOf -----------------------------------------------
--@api-stub: Occluder:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- occluder_stub:typeOf("hero")  -- -> boolean
-- (replace occluder_stub with your real Occluder instance above)
