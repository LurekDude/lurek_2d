-- content/examples/light.lua
-- Comprehensive lurek.light API examples: 2D lighting, shadows, occluders, flicker, transitions, cookies, and normal maps.
-- Run: cargo run -- content/examples/light.lua

--@api-stub: lurek.light.newLight
-- Creates a light and applies optional light settings
do
  -- newLight(x, y, radius, opts?) creates a point light at world position (x, y)
  -- with the given radius. The optional table configures color, intensity, blend mode,
  -- falloff, shadows, flicker, group, type, direction, and more in one call.
  local torch = lurek.light.newLight(200, 150, 180, {
    color       = {1.0, 0.7, 0.3, 1.0},  -- warm orange flame
    intensity   = 1.2,                     -- slightly brighter than default 1.0
    blend       = "add",                   -- additive blending for fire glow
    falloff     = "smooth",                -- smooth falloff feels natural for torches
    shadowEnabled = true,                  -- cast shadows from nearby occluders
    flickerSpeed    = 6.0,                 -- flicker animation speed
    flickerStrength = 0.12,                -- 12% intensity variance for a lively flame
    groupId     = 1,                       -- assign to group 1 (torches)
  })
  -- After creation, the handle can be stored and updated per-frame
  torch:setBlendMode("add")
  lurek.log.info("torch lit at (200, 150) radius=180", "light")
end

--@api-stub: lurek.light.newOccluder
-- Creates an occluder from a flat vertex coordinate table and optional settings
do
  -- Occluders block light and produce shadows. Vertices are a flat array: {x1,y1, x2,y2, ...}
  -- representing a closed polygon. Minimum 3 vertices (6 numbers).
  -- Use occluders for walls, pillars, crates, or any solid geometry that should block light.
  local wall = lurek.light.newOccluder(
    { 100, 100,  300, 100,  300, 120,  100, 120 },  -- a horizontal wall segment
    { opacity = 0.85, lightMask = 0xFFFF }           -- slightly translucent, blocks all lights
  )
  -- Translucent occluders (opacity < 1.0) let some light bleed through,
  -- useful for curtains, frosted glass, or thin wooden fences.
  wall:setEnabled(true)
end

--@api-stub: lurek.light.setAmbient
-- Sets global ambient light color
do
  -- Ambient color fills the entire scene before any lights are applied.
  -- Use low values for dark dungeons, higher for outdoor daylight.
  -- Format: setAmbient(r, g, b, a) with each channel 0.0 to 1.0.
  lurek.light.setAmbient(0.15, 0.18, 0.30, 1.0)  -- deep dusk blue for a nighttime scene
  lurek.log.info("ambient set to dusk blue", "light")
end

--@api-stub: lurek.light.getAmbient
-- Returns global ambient light color
do
  -- Returns r, g, b, a. Use this to adapt gameplay to current lighting conditions.
  local r, g, b, _ = lurek.light.getAmbient()
  -- If overall brightness is low, the player might need extra light sources
  if r + g + b < 0.5 then
    lurek.log.info("scene is dark — consider spawning extra torches", "light")
  end
end

--@api-stub: LOccluder:setEnabled
-- Enables or disables the shared light world
do
  -- When disabled, no lighting is rendered — the scene uses flat colors only.
  -- Useful for cutscenes, menus, or debug views where lighting distracts.
  local cinematic_mode = false
  lurek.light.setEnabled(not cinematic_mode)
end

--@api-stub: LOccluder:isEnabled
-- Returns whether the shared light world is enabled
do
  -- Check before performing expensive light operations to avoid wasted work
  if lurek.light.isEnabled() then
    lurek.log.info("lighting system active", "light")
  end
end

--@api-stub: lurek.light.getLightCount
-- Returns the number of live lights
do
  -- Use for performance budgeting: too many lights in one frame hurts fill rate
  local n = lurek.light.getLightCount()
  if n > 32 then
    lurek.log.warn("scene has " .. n .. " lights — may exceed GPU budget", "perf")
  end
end

--@api-stub: lurek.light.getOccluderCount
-- Returns the number of live occluders
do
  -- Each occluder generates shadow geometry. Monitor the count for performance.
  local n = lurek.light.getOccluderCount()
  lurek.log.info("active occluders: " .. n, "light")
end

--@api-stub: lurek.light.getMaxLights
-- Returns the maximum configured light count
do
  -- The engine enforces a hard cap on simultaneous lights (default varies by quality).
  -- Lights beyond the cap are silently skipped.
  local cap = lurek.light.getMaxLights()
  if cap < 64 then
    lurek.light.setMaxLights(64)  -- raise for levels with many torch sconces
  end
end

--@api-stub: lurek.light.setMaxLights
-- Sets the maximum configured light count, clamped to 1 through 256
do
  -- Adjust based on player graphics quality setting.
  -- Higher cap = more lights rendered but more GPU work per frame.
  local quality = "high"
  local cap = (quality == "high") and 128 or 32
  lurek.light.setMaxLights(cap)
end

--@api-stub: lurek.light.clear
-- Removes all lights and occluders from the light world
do
  -- Call on scene transitions to ensure no stale lights carry over.
  -- After clear(), getLightCount() and getOccluderCount() both return 0.
  lurek.light.clear()
  lurek.log.info("light world reset for new scene", "light")
end

--@api-stub: lurek.light.setGroupEnabled
-- Enables or disables all lights in a group
do
  -- Groups let you batch-control related lights without tracking each handle.
  -- Example: turn off all torches in a dungeon wing when the player leaves.
  local TORCHES_GROUP = 1
  lurek.light.setGroupEnabled(TORCHES_GROUP, false)  -- all group-1 torches go dark
end

--@api-stub: lurek.light.setGroupIntensity
-- Sets intensity for all lights in a group
do
  -- Dim an entire group at once — useful for "power failing" effect on streetlamps.
  local STREETLAMPS = 2
  lurek.light.setGroupIntensity(STREETLAMPS, 0.6)  -- dim to 60%
end

--@api-stub: lurek.light.setGroupColor
-- Sets color for all lights in a group
do
  -- Flash all alarm lights red simultaneously during an alert state.
  local ALARM_LIGHTS = 3
  lurek.light.setGroupColor(ALARM_LIGHTS, 1.0, 0.1, 0.1, 1.0)  -- intense red
end

--@api-stub: lurek.light.getGroupCount
-- Returns the number of lights in a group
do
  -- Useful to verify group population or balance light budgets across groups.
  local TORCHES_GROUP = 1
  local n = lurek.light.getGroupCount(TORCHES_GROUP)
  lurek.log.info("torches group has " .. n .. " lights", "light")
end

--@api-stub: lurek.light.advanceFlickers
-- Advances flicker animation for all indexed flickering lights
do
  -- Call once per frame in lurek.process(dt) to animate all flickering lights.
  -- This updates intensity modulation for every light that has flicker enabled.
  function lurek.process(dt) lurek.light.advanceFlickers(dt) end
end

--@api-stub: lurek.light.syncAmbient
-- Returns the light world's ambient color hint
do
  -- syncAmbient() returns the same ambient color set by setAmbient(),
  -- useful for other systems (fog, particles) that need the ambient reference.
  local r, g, b, a = lurek.light.syncAmbient()
  -- Tint fog color to match ambient for a cohesive look
  local fog_tint = { r * 0.8, g * 0.8, b * 0.8, a }
  lurek.log.debug("fog tint=(" .. fog_tint[1] .. "," .. fog_tint[2] .. ")", "fx")
end

--@api-stub: lurek.light.getGodRayHints
-- Returns directional light hints for god-ray style effects
do
  -- Returns a list of tables with {x, y, angle, intensity} for each light
  -- marked as volumetric. Use these hints to drive a post-process god-ray shader.
  local hints = lurek.light.getGodRayHints()
  for _, h in ipairs(hints) do
    -- Each hint gives the light's position and direction — feed into a radial blur
    lurek.log.debug("god-ray src x=" .. h.x .. " y=" .. h.y .. " angle=" .. h.angle, "fx")
  end
end

--@api-stub: lurek.light.getNormalMapHints
-- Returns light hints that reference normal maps
do
  -- Returns a list of hints for lights that have a normal map path set.
  -- Use to drive per-pixel normal-mapped lighting in a custom shader pass.
  local hints = lurek.light.getNormalMapHints()
  for _, h in ipairs(hints) do
    lurek.log.debug("normal-map=" .. h.normalMap .. " strength=" .. h.strength, "fx")
  end
end

-- Light methods

--@api-stub: LOccluder:setPosition
-- Sets the position of this light.
do
  -- Move a light to follow the player's lantern in world coordinates.
  local lamp = lurek.light.newLight(0, 0, 120)
  -- In a real game, call this each frame with the player's position:
  local player_x, player_y = 320, 240
  lamp:setPosition(player_x, player_y)
end

--@api-stub: LOccluder:getPosition
-- Returns the position of this light.
do
  -- Returns x, y — use to check distance from player or other objects.
  local lamp = lurek.light.newLight(150, 100, 80)
  local x, y = lamp:getPosition()
  lurek.log.info("lamp at (" .. x .. "," .. y .. ")", "light")
end

--@api-stub: LLight:setRadius
-- Sets the radius of this light.
do
  -- Radius controls how far the light reaches. Animate it to simulate
  -- a flickering lantern whose battery is draining.
  local lantern = lurek.light.newLight(50, 50, 100)
  local battery_pct = 0.6  -- 60% battery remaining
  lantern:setRadius(40 + 80 * battery_pct)  -- range shrinks as battery dies
end

--@api-stub: LLight:getRadius
-- Returns the radius of this light.
do
  -- Use to enforce minimum visibility radius for gameplay fairness
  local glow = lurek.light.newLight(0, 0, 75)
  if glow:getRadius() < 50 then
    glow:setRadius(50)  -- ensure player can always see at least 50px around them
  end
end

--@api-stub: LLight:getColor
-- Returns the color of this light.
do
  -- Returns r, g, b, a. Use to sample the light color for tinting particles
  -- spawned near the light source (sparks matching the flame color).
  local lamp = lurek.light.newLight(0, 0, 100, { color = {0.9, 0.7, 0.5, 1.0} })
  local r, g, b, a = lamp:getColor()
  lurek.log.debug("lamp color=(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "light")
end

--@api-stub: LLight:setIntensity
-- Sets the intensity of this light.
do
  -- Intensity multiplies the light's contribution. Values above 1.0 create
  -- overbright effects; useful for explosions or magical bursts.
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setIntensity(1.4)  -- 40% brighter than default
end

--@api-stub: LLight:getIntensity
-- Returns the intensity of this light.
do
  -- Use to warn about dim lights that players might not notice
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getIntensity() < 0.2 then
    lurek.log.warn("lamp intensity very low — may be invisible to player", "light")
  end
end

--@api-stub: LLight:setEnergy
-- Sets the energy of this light.
do
  -- Energy is a secondary brightness control separate from intensity.
  -- Combine both for fine-grained light appearance tuning.
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setEnergy(2.5)  -- high energy for a bright sunbeam shaft
end

--@api-stub: LLight:getEnergy
-- Returns the energy of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local e = lamp:getEnergy()
  lurek.log.debug("lamp energy=" .. e, "light")
end

--@api-stub: LLight:setBlendMode
-- Sets the blend mode of this light.
do
  -- "add" = additive (fire, neon, glowing objects)
  -- "sub" = subtractive (creates darkened areas)
  -- "mix" = alpha-blended (colored fog, stained glass)
  local glow = lurek.light.newLight(0, 0, 100)
  glow:setBlendMode("add")  -- neon sign glow added on top of scene
end

--@api-stub: LLight:getBlendMode
-- Returns the blend mode of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getBlendMode() ~= "add" then
    lamp:setBlendMode("add")  -- ensure additive for fire particles
  end
end

--@api-stub: LLight:setFalloff
-- Sets the falloff of this light.
do
  -- "linear" = brightness decreases linearly with distance (sharp edge)
  -- "smooth" = brightness fades with a soft curve (natural for most lights)
  -- "constant" = uniform brightness within radius (flat fill light)
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setFalloff("smooth")  -- best default for indoor scenes
end

--@api-stub: LLight:getFalloff
-- Returns the falloff of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local mode = lamp:getFalloff()
  lurek.log.debug("falloff=" .. mode, "light")
end

--@api-stub: LLight:setShadowEnabled
-- Enables or disables shadow casting for this light.
do
  -- Shadow casting is expensive. Enable only for key lights where shadows
  -- add gameplay value (player torch) and disable for ambient fill lights.
  local torch = lurek.light.newLight(100, 100, 200)
  torch:setShadowEnabled(true)  -- this is the player's main light
end

--@api-stub: LLight:isShadowEnabled
-- Returns whether this light casts shadows.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if not lamp:isShadowEnabled() then
    -- Enable shadows only when player enters stealth mode (visibility matters)
    lamp:setShadowEnabled(true)
  end
end

--@api-stub: LLight:getShadowColor
-- Returns the shadow color of this light.
do
  -- Shadow color tints the shadowed area. Dark blue shadows feel cold and eerie;
  -- warm brown shadows feel like indoor candlelight.
  local lamp = lurek.light.newLight(0, 0, 100)
  local _, _, _, a = lamp:getShadowColor()
  lurek.log.debug("shadow alpha=" .. a, "light")
end

--@api-stub: LLight:setShadowFilter
-- Sets the shadow filter of this light.
do
  -- "none" = hard pixel shadows (retro style, cheapest)
  -- "pcf5" = 5-sample percentage-closer filtering (soft edges, moderate cost)
  -- "pcf13" = 13-sample PCF (very soft shadows, expensive)
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowFilter("pcf13")  -- high quality for hero light
end

--@api-stub: LLight:getShadowFilter
-- Returns the shadow filter of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getShadowFilter() == "none" then
    lamp:setShadowFilter("pcf5")  -- upgrade from hard shadows
  end
end

--@api-stub: LLight:setShadowSmooth
-- Sets the shadow smooth value of this light.
do
  -- Shadow smooth controls the blur radius applied to shadow edges.
  -- Higher values produce softer, more diffuse shadow boundaries.
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowSmooth(2.5)  -- moderate softening
end

--@api-stub: LLight:getShadowSmooth
-- Returns the shadow smooth value of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local s = lamp:getShadowSmooth()
  lurek.log.debug("shadow smooth=" .. s, "light")
end

--@api-stub: LLight:setShadowSoftness
-- Sets the shadow softness of this light.
do
  -- Softness works with smooth to control penumbra width.
  -- Use higher values for large area lights (windows, sky panels).
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowSoftness(1.8)
end

--@api-stub: LLight:getShadowSoftness
-- Returns the shadow softness of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lurek.log.debug("shadow softness=" .. lamp:getShadowSoftness(), "light")
end

--@api-stub: LOccluder:setLightMask
-- Sets the light mask of this light.
do
  -- Light masks control which layers this light illuminates.
  -- Use bit flags to separate player, enemies, and background lighting.
  local PLAYER_LAYER = 0x01
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setLightMask(PLAYER_LAYER)  -- only lights the player layer
end

--@api-stub: LOccluder:getLightMask
-- Returns the light mask of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  local mask = lamp:getLightMask()
  lurek.log.debug("lamp mask=" .. mask, "light")
end

--@api-stub: LLight:setShadowMask
-- Sets the shadow mask of this light.
do
  -- Shadow mask controls which occluder layers cast shadows for this light.
  -- Set to match only wall/solid layers to avoid shadows from decorations.
  local WALLS_ONLY = 0x02
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setShadowMask(WALLS_ONLY)
end

--@api-stub: LLight:getShadowMask
-- Returns the shadow mask of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getShadowMask() == 0 then
    lamp:setShadowMask(0xFFFF)  -- receive shadows from all layers
  end
end

--@api-stub: LOccluder:setEnabled
-- Enables or disables this light.
do
  -- Disabled lights consume no GPU time. Toggle for on/off switches,
  -- broken bulbs, or lights outside the camera frustum.
  local lamp = lurek.light.newLight(0, 0, 100)
  local power_on = false
  lamp:setEnabled(power_on)  -- light is off until player flips the switch
end

--@api-stub: LOccluder:isEnabled
-- Returns whether this light is enabled.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:isEnabled() then
    lurek.log.debug("lamp is drawing", "light")
  end
end

--@api-stub: LLight:setLightType
-- Sets the light type of this light.
do
  -- "point" = omnidirectional (torches, lamps, campfires)
  -- "directional" = parallel rays from infinity (sunlight, moonlight)
  -- "spot" = cone-shaped beam (flashlights, stage lights, car headlamps)
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setLightType("directional")
  sun:setDirection(math.pi * 0.25)  -- sun angle: 45 degrees from right
end

--@api-stub: LLight:getLightType
-- Returns the light type of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:getLightType() == "spot" then
    lamp:setOuterAngle(math.pi / 4)  -- widen the cone if it's a spotlight
  end
end

--@api-stub: LLight:setDirection
-- Sets the direction of this light.
do
  -- Direction is an angle in radians. Used by spot and directional lights.
  -- Animate it to sweep a searchlight or follow player aim direction.
  local flashlight = lurek.light.newLight(100, 100, 200)
  flashlight:setLightType("spot")
  flashlight:setDirection(math.pi / 2)  -- pointing straight down
end

--@api-stub: LLight:getDirection
-- Returns the direction of this light.
do
  local sun = lurek.light.newLight(0, 0, 500)
  sun:setDirection(0.5)
  local angle = sun:getDirection()
  lurek.log.debug("sun angle=" .. angle .. " rad", "light")
end

--@api-stub: LLight:setInnerAngle
-- Sets the inner angle of this light.
do
  -- Inner angle defines the fully-lit central cone of a spotlight.
  -- Light is at full intensity within this angle from center.
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setLightType("spot")
  spot:setInnerAngle(math.pi / 8)  -- narrow bright center
end

--@api-stub: LLight:getInnerAngle
-- Returns the inner angle of this light.
do
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setInnerAngle(0.3)
  lurek.log.debug("inner=" .. spot:getInnerAngle(), "light")
end

--@api-stub: LLight:setOuterAngle
-- Sets the outer angle of this light.
do
  -- Outer angle defines where the spotlight fades to zero.
  -- The region between inner and outer angles is the penumbra (soft edge).
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setLightType("spot")
  spot:setOuterAngle(math.pi / 4)  -- wider falloff edge
end

--@api-stub: LLight:getOuterAngle
-- Returns the outer angle of this light.
do
  local spot = lurek.light.newLight(0, 0, 200)
  spot:setOuterAngle(0.7)
  if spot:getOuterAngle() > math.pi then
    spot:setOuterAngle(math.pi)  -- clamp to half-circle maximum
  end
end

--@api-stub: LLight:setAttenuation
-- Sets the attenuation of this light.
do
  -- Attenuation uses the classic formula: 1 / (constant + linear*d + quadratic*d^2)
  -- where d = distance from light center.
  -- (1.0, 0.09, 0.032) = typical indoor point light (~50px effective range)
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setAttenuation(1.0, 0.09, 0.032)
end

--@api-stub: LLight:getAttenuation
-- Returns the attenuation of this light.
do
  -- Returns constant, linear, quadratic coefficients
  local lamp = lurek.light.newLight(0, 0, 100)
  local c, l, q = lamp:getAttenuation()
  lurek.log.debug("att c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end

--@api-stub: LLight:setFlicker
-- Sets the flicker parameters of this light.
do
  -- Flicker modulates intensity over time using a noise function.
  -- speed = how fast the flicker oscillates (higher = more frantic)
  -- strength = amplitude of the flicker (0.0 = none, 0.5 = 50% variance)
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(8.0, 0.15)  -- fast candle-like flicker, 15% variance
end

--@api-stub: LLight:getFlicker
-- Returns the flicker parameters of this light.
do
  -- Returns speed, strength — use to verify flicker was configured correctly
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(6.0, 0.2)
  local speed, strength = torch:getFlicker()
  lurek.log.debug("flicker speed=" .. speed .. " strength=" .. strength, "light")
end

--@api-stub: LLight:setFlickerEnabled
-- Enables or disables this light's flicker animation.
do
  -- You can configure flicker parameters but keep it disabled until triggered.
  -- Example: torch starts steady, begins flickering when wind event fires.
  local torch = lurek.light.newLight(0, 0, 120)
  torch:setFlicker(5.0, 0.1)
  torch:setFlickerEnabled(true)  -- activate the flicker
end

--@api-stub: LLight:isFlickerEnabled
-- Returns whether this light's flicker is enabled.
do
  local torch = lurek.light.newLight(0, 0, 120)
  if not torch:isFlickerEnabled() then
    -- If flicker isn't active, set it up using addFlicker convenience
    torch:addFlicker(0.85, 1.15, 4.0)  -- intensity range 85%-115% at 4 Hz
  end
end

--@api-stub: LLight:setGroupId
-- Sets the group id of this light.
do
  -- Group IDs let you batch-control related lights without storing each handle.
  -- Assign all torches in a corridor to the same group for synchronized control.
  local TORCHES = 1
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setGroupId(TORCHES)
end

--@api-stub: LLight:getGroupId
-- Returns the group id of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setGroupId(7)
  if lamp:getGroupId() == 7 then
    lurek.log.debug("lamp in alarm group", "light")
  end
end

--@api-stub: LLight:setVolumetric
-- Enables or disables volumetric behavior for this light.
do
  -- Volumetric lights produce hints for god-ray post-processing.
  -- Use for dramatic beams: car headlamps in fog, sunlight through windows.
  local headlamp = lurek.light.newLight(0, 0, 200)
  headlamp:setVolumetric(true)
end

--@api-stub: LLight:isVolumetric
-- Returns whether this light is volumetric.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:isVolumetric() then
    lurek.log.debug("lamp produces god-ray hints", "fx")
  end
end

--@api-stub: LOccluder:remove
-- Removes this light from the light world.
do
  -- Removed lights free their slot immediately. Use for temporary effects:
  -- muzzle flashes, explosions, or sparks that live for a few frames.
  local muzzle_flash = lurek.light.newLight(64, 64, 60, { intensity = 2.0 })
  -- In a real game, remove after a brief timer
  muzzle_flash:remove()
end

--@api-stub: LOccluder:isValid
-- Returns whether this light handle still references a live light.
do
  -- After remove(), the handle becomes invalid. Always check isValid()
  -- if a light might have been removed by another system.
  local spark = lurek.light.newLight(0, 0, 30)
  spark:remove()
  if not spark:isValid() then
    lurek.log.debug("spark expired — handle is now stale", "light")
  end
end

--@api-stub: LLight:addFlicker
-- Adds a flicker using min/max intensity range and frequency in Hz.
do
  -- Convenience alternative to setFlicker(). Specify the visible intensity range
  -- and frequency. The engine computes speed and strength internally.
  -- addFlicker(min, max, hz): intensity oscillates between min and max at hz cycles/sec.
  local torch = lurek.light.newLight(0, 0, 120)
  torch:addFlicker(0.8, 1.2, 5.0)  -- 80%-120% intensity at 5 Hz
end

--@api-stub: LLight:updateTransition
-- Advances this light's transition by the given delta time.
do
  -- Call each frame to smoothly interpolate between start and target values.
  -- Returns true while the transition is active, false when complete.
  local lamp = lurek.light.newLight(0, 0, 100)
  function lurek.process(dt) lamp:updateTransition(dt) end
end

--@api-stub: LLight:stopTransition
-- Stops and clears the active transition on this light.
do
  -- Use when gameplay interrupts a transition (e.g., player extinguishes the torch
  -- mid-fade). The light stays at whatever values it had when stopped.
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:stopTransition()
end

--@api-stub: LLight:transitionProgress
-- Returns the current transition progress (0.0 to 1.0).
do
  -- Returns 1.0 when no transition is active (considered "complete").
  -- Use to trigger events at specific progress milestones.
  local lamp = lurek.light.newLight(0, 0, 100)
  if lamp:transitionProgress() >= 1.0 then
    lurek.log.debug("transition complete or none active", "light")
  end
end

--@api-stub: LLight:setCookie
-- Sets a cookie texture path on this light.
do
  -- Cookie textures project a pattern through the light, like window blinds
  -- casting shadow strips, or leaves creating dappled light on the ground.
  local projector = lurek.light.newLight(0, 0, 200)
  projector:setCookie("textures/window_pattern.png")
end

--@api-stub: LLight:getCookie
-- Returns the cookie texture path of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setCookie("textures/leaves.png")
  local path = lamp:getCookie()
  lurek.log.debug("cookie=" .. tostring(path), "light")
end

--@api-stub: LLight:clearCookie
-- Clears the cookie texture from this light.
do
  -- Remove the cookie to revert to a plain circular light shape
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setCookie("textures/leaves.png")
  lamp:clearCookie()  -- now just a normal point light again
end

--@api-stub: LLight:setNormalMap
-- Sets the normal map path for this light.
do
  -- Normal maps add per-pixel depth illusion to lit surfaces.
  -- The light uses the normal map to compute directional shading on flat sprites.
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setNormalMap("assets/textures/normals/brick.png")
end

--@api-stub: LLight:getNormalMap
-- Returns the normal map path of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lurek.log.debug("normal map=" .. tostring(lamp:getNormalMap()), "light")
end

--@api-stub: LLight:clearNormalMap
-- Clears the normal map from this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setNormalMap("assets/textures/normals/temp.png")
  lamp:clearNormalMap()  -- revert to flat lighting
end

--@api-stub: LLight:setNormalStrength
-- Sets the normal map strength for this light.
do
  -- Strength controls how pronounced the normal-mapped bumps appear.
  -- 0.0 = flat (no effect), 1.0 = full depth, >1.0 = exaggerated relief.
  local lamp = lurek.light.newLight(0, 0, 100)
  lamp:setNormalStrength(1.3)  -- slightly exaggerated for stylized look
end

--@api-stub: LLight:getNormalStrength
-- Returns the normal map strength of this light.
do
  local lamp = lurek.light.newLight(0, 0, 100)
  lurek.log.debug("normal strength=" .. lamp:getNormalStrength(), "light")
end

-- Occluder methods

--@api-stub: LOccluder:setVertices
-- Sets the vertices of this occluder.
do
  -- Replace occluder geometry at runtime — useful for destructible walls
  -- or doors that change shape when opened.
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  -- Door opened: widen the occluder to cover the new frame
  wall:setVertices({ 0, 0, 200, 0, 200, 20, 0, 20 })
end

--@api-stub: LOccluder:getVertices
-- Returns the vertices of this occluder.
do
  -- Returns a flat {x1,y1, x2,y2, ...} table. Divide length by 2 for vertex count.
  local crate = lurek.light.newOccluder({ 50, 50, 100, 50, 100, 100, 50, 100 })
  local v = crate:getVertices()
  lurek.log.debug("crate has " .. (#v / 2) .. " vertices", "light")
end

--@api-stub: LOccluder:setPosition
-- Sets the position offset of this occluder.
do
  -- Position offsets all vertices. Use to move an occluder with a physics body
  -- without recalculating vertex coordinates every frame.
  local crate = lurek.light.newOccluder({ 0, 0, 64, 0, 64, 64, 0, 64 })
  crate:setPosition(200, 150)  -- move crate shadow to match sprite position
end

--@api-stub: LOccluder:getPosition
-- Returns the position offset of this occluder.
do
  local crate = lurek.light.newOccluder({ 0, 0, 64, 0, 64, 64, 0, 64 })
  crate:setPosition(120, 80)
  local x, y = crate:getPosition()
  lurek.log.debug("crate at (" .. x .. "," .. y .. ")", "light")
end

--@api-stub: LOccluder:setOpacity
-- Sets the opacity of this occluder.
do
  -- Opacity 1.0 = fully opaque (hard shadow), 0.0 = invisible (no shadow).
  -- Partial opacity creates soft/translucent barriers: curtains, glass, foliage.
  local fence = lurek.light.newOccluder({ 0, 0, 200, 0, 200, 10, 0, 10 })
  fence:setOpacity(0.4)  -- chain-link fence lets most light through
end

--@api-stub: LOccluder:getOpacity
-- Returns the opacity of this occluder.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  if wall:getOpacity() < 1.0 then
    lurek.log.debug("translucent occluder — partial shadow", "light")
  end
end

--@api-stub: LOccluder:setLightMask
-- Sets the light mask of this occluder.
do
  -- An occluder only blocks lights whose mask bits overlap with its own mask.
  -- Use to make foreground objects cast shadows only from foreground lights.
  local FOREGROUND_LIGHTS = 0x01
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:setLightMask(FOREGROUND_LIGHTS)
end

--@api-stub: LOccluder:getLightMask
-- Returns the light mask of this occluder.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  local mask = wall:getLightMask()
  lurek.log.debug("wall mask=" .. mask, "light")
end

--@api-stub: LOccluder:setEnabled
-- Enables or disables this occluder.
do
  -- Disabled occluders stop casting shadows but stay in memory for quick reactivation.
  -- Use for doors: when open, disable the occluder so light passes through.
  local door = lurek.light.newOccluder({ 0, 0, 40, 0, 40, 80, 0, 80 })
  local door_open = true
  door:setEnabled(not door_open)  -- shadows only when door is closed
end

--@api-stub: LOccluder:isEnabled
-- Returns whether this occluder is currently casting shadows.
do
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  if wall:isEnabled() then
    lurek.log.debug("wall is casting shadows", "light")
  end
end

--@api-stub: LOccluder:remove
-- Removes this occluder from the light world.
do
  -- Permanently remove destroyed objects (exploded barrels, broken walls).
  local debris = lurek.light.newOccluder({ 0, 0, 30, 0, 30, 30, 0, 30 })
  debris:remove()  -- rubble no longer blocks light
end

--@api-stub: LOccluder:isValid
-- Returns whether this occluder handle is still valid.
do
  -- After remove(), the handle becomes stale. Check before any method call
  -- if the occluder might have been destroyed by physics or gameplay.
  local wall = lurek.light.newOccluder({ 0, 0, 100, 0, 100, 20, 0, 20 })
  wall:remove()
  if not wall:isValid() then
    lurek.log.debug("wall removed — handle is stale", "light")
  end
end

--@api-stub: LLight:setColor
-- Sets the color of this light.
do
  -- setColor(r, g, b) or setColor(r, g, b, a) — alpha defaults to 1.0.
  -- Use to change color dynamically: day/night cycle, damage flash, mood shifts.
  local lt = lurek.light.newLight(200, 300, 150)
  lt:setColor(1.0, 0.85, 0.5)  -- warm candlelight tone
  lurek.log.info("light colour set to warm gold", "light")
end

--@api-stub: LLight:setShadowColor
-- Sets the shadow color of this light.
do
  -- Shadow color tints the shadowed region instead of pure black.
  -- Blue shadows feel cold/night; warm shadows feel like firelight.
  local lt = lurek.light.newLight(200, 300, 120)
  lt:setShadowEnabled(true)
  lt:setShadowColor(0.0, 0.0, 0.1, 0.85)  -- dark navy shadows, slight transparency
  lurek.log.info("shadow colour set to deep blue", "light")
end

--@api-stub: LLight:transitionTo
-- Starts a smooth transition toward target values.
do
  -- transitionTo(target, duration) interpolates color, intensity, and radius
  -- over the given time. Use for day/night fades, alarm states, or dramatic reveals.
  -- Target table can have: color={r,g,b,a}, intensity=N, radius=N,
  -- or shorthand: r=, g=, b=, a= for color, x=, y= for position.
  local lt = lurek.light.newLight(100, 100, 80)
  lt:transitionTo(
    { x = 400, y = 300, radius = 200, r = 1, g = 0.5, b = 0 },  -- expand into warm glow
    2.0  -- over 2 seconds
  )
  lurek.log.info("transition started: expanding warm glow over 2s", "light")
end

-- -----------------------------------------------------------------------------
-- Light methods
-- -----------------------------------------------------------------------------

--@api-stub: LOccluder:type
-- Returns the Lua-visible type name string for this light handle.
do
  -- type() returns "LLight" — use for runtime type introspection
  local lamp = lurek.light.newLight(0, 0, 120)
  lamp:setPosition(320, 240)
  local t = lamp:type()
  lurek.log.info("Light:type = " .. t, "light")
end
--@api-stub: LOccluder:typeOf
-- Returns true if this light handle matches the given type name string.
do
  -- typeOf("LLight") and typeOf("Object") both return true
  local lamp = lurek.light.newLight(0, 0, 120)
  lamp:setPosition(320, 240)
  lurek.log.info("is Light: " .. tostring(lamp:typeOf("Light")), "light")
  lurek.log.info("is wrong: " .. tostring(lamp:typeOf("Unknown")), "light")
end

-- -----------------------------------------------------------------------------
-- LLight methods
-- -----------------------------------------------------------------------------

--@api-stub: LOccluder:type
-- Returns the Lua-visible type name for this light handle
do
  local light_obj = lurek.light.newLight(0, 0, 80)
  local t = light_obj:type()
  lurek.log.info("LLight:type = " .. t, "light")
end
--@api-stub: LOccluder:typeOf
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

--@api-stub: LOccluder:setPosition
-- Sets this light position
do
  -- Move a spotlight to track enemy patrol routes
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setPosition(512, 256)
  local x, y = lt:getPosition()
  lurek.log.info("position=" .. x .. "," .. y, "light")
end
--@api-stub: LOccluder:getPosition
-- Returns this light position
do
  local lt = lurek.light.newLight(100, 200, 150)
  local x, y = lt:getPosition()
  lurek.log.info("x=" .. x .. " y=" .. y, "light")
end
--@api-stub: LLight:setRadius
-- Sets this light radius
do
  -- Expand radius to simulate a growing fire
  local lt = lurek.light.newLight(400, 300, 100)
  lt:setRadius(250)  -- fire has spread, illuminate more area
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
  -- Animate color for a neon sign cycling between warm and cool tones
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setColor(1.0, 0.6, 0.2, 1.0)   -- warm orange neon
  local r, g, b, a = lt:getColor()
  lurek.log.info("color r=" .. r .. " g=" .. g, "light")
end
--@api-stub: LLight:getColor
-- Returns this light RGBA color
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setColor(0.2, 0.4, 1.0, 1.0)   -- cool blue security light
  local r, g, b, a = lt:getColor()
  lurek.log.info("r=" .. r .. " g=" .. g .. " b=" .. b, "light")
end
--@api-stub: LLight:setIntensity
-- Sets this light intensity
do
  -- Overbright intensity for explosion flash
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setIntensity(2.5)  -- 250% brightness burst
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
  -- "add" is the standard for self-luminous objects (lamps, fire, neon)
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setBlendMode("add")
  lurek.log.info("blend_mode=" .. lt:getBlendMode(), "light")
end
--@api-stub: LLight:getBlendMode
-- Returns this light blend mode string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setBlendMode("mix")  -- alpha-blend for colored ambient fill
  lurek.log.info("blend_mode=" .. lt:getBlendMode(), "light")
end
--@api-stub: LLight:setFalloff
-- Sets this light falloff mode
do
  -- "smooth" is most natural; "linear" is cheaper; "constant" for uniform fill
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
  -- Only enable shadows for lights where they add gameplay value
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
  -- Dark blue shadows create a cold night atmosphere
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lt:setShadowColor(0.0, 0.0, 0.2, 0.8)
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
  -- pcf5 is a good balance of quality and performance for most scenes
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lt:setShadowFilter("pcf5")
  lurek.log.info("shadow_filter=" .. lt:getShadowFilter(), "light")
end
--@api-stub: LLight:getShadowFilter
-- Returns this light shadow filter string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowFilter("pcf13")  -- highest quality for cinematic shots
  lurek.log.info("shadow_filter=" .. lt:getShadowFilter(), "light")
end
--@api-stub: LLight:setShadowSmooth
-- Sets this light shadow smoothing value
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowSmooth(2.0)  -- moderate blur on shadow edges
  lurek.log.info("shadow_smooth=" .. lt:getShadowSmooth(), "light")
end
--@api-stub: LLight:getShadowSmooth
-- Returns this light shadow smoothing value
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowSmooth(1.5)
  lurek.log.info("shadow_smooth=" .. lt:getShadowSmooth(), "light")
end
--@api-stub: LOccluder:setLightMask
-- Sets this light's inclusion mask
do
  -- Bit masks let you selectively light specific layers
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightMask(0b00000011)   -- illuminate layers 1 and 2 only
  lurek.log.info("light_mask=" .. lt:getLightMask(), "light")
end
--@api-stub: LOccluder:getLightMask
-- Returns this light's inclusion mask
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightMask(0b11111111)   -- illuminate all layers
  lurek.log.info("light_mask=" .. lt:getLightMask(), "light")
end
--@api-stub: LLight:setShadowMask
-- Sets this light's shadow receiver mask
do
  -- Only receive shadows from the first 4 layers (walls, not decorations)
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowEnabled(true)
  lt:setShadowMask(0b00001111)
  lurek.log.info("shadow_mask=" .. lt:getShadowMask(), "light")
end
--@api-stub: LLight:getShadowMask
-- Returns this light's shadow receiver mask
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setShadowMask(0b11111111)
  lurek.log.info("shadow_mask=" .. lt:getShadowMask(), "light")
end
--@api-stub: LOccluder:setEnabled
-- Enables or disables this light
do
  -- Toggle lights with player interaction (light switches, circuit breakers)
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setEnabled(false)
  lurek.log.info("enabled=" .. tostring(lt:isEnabled()), "light")
  lt:setEnabled(true)
  lurek.log.info("re-enabled=" .. tostring(lt:isEnabled()), "light")
end
--@api-stub: LOccluder:isEnabled
-- Returns whether this light is enabled
do
  local lt = lurek.light.newLight(400, 300, 200)
  lurek.log.info("enabled by default=" .. tostring(lt:isEnabled()), "light")
end
--@api-stub: LLight:setLightType
-- Sets this light type
do
  -- Configure a spotlight: set type, aim direction, and cone angles
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setDirection(math.pi / 2)       -- aim downward
  lt:setInnerAngle(math.pi / 8)     -- narrow bright center
  lt:setOuterAngle(math.pi / 4)     -- wider soft edge
  lurek.log.info("type=" .. lt:getLightType(), "light")
end
--@api-stub: LLight:getLightType
-- Returns this light type string
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("point")  -- default omnidirectional
  lurek.log.info("type=" .. lt:getLightType(), "light")
end
--@api-stub: LLight:setDirection
-- Sets this light direction angle
do
  -- Rotate a spotlight to sweep across a room (security camera effect)
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
  lt:setDirection(math.pi)  -- point left
  lurek.log.info("direction=" .. lt:getDirection(), "light")
end
--@api-stub: LLight:setInnerAngle
-- Sets this spot light inner cone angle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setInnerAngle(math.pi / 8)  -- tight center beam
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
  -- Outer must be >= inner. The penumbra zone is between inner and outer.
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setLightType("spot")
  lt:setInnerAngle(math.pi / 8)
  lt:setOuterAngle(math.pi / 4)  -- soft falloff zone from pi/8 to pi/4
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
  -- Classic OpenGL attenuation: 1/(c + l*d + q*d^2)
  -- (1.0, 0.09, 0.032) approximates a 50-unit range indoor lamp
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setAttenuation(1.0, 0.09, 0.032)
  local c, l, q = lt:getAttenuation()
  lurek.log.info("attenuation c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end
--@api-stub: LLight:getAttenuation
-- Returns this light attenuation coefficients
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setAttenuation(1.0, 0.14, 0.07)  -- steeper falloff, smaller effective range
  local c, l, q = lt:getAttenuation()
  lurek.log.info("c=" .. c .. " l=" .. l .. " q=" .. q, "light")
end
--@api-stub: LLight:setFlicker
-- Configures flicker speed and strength for this light
do
  -- speed=8 means 8 oscillation units/sec, strength=0.15 means 15% variance
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setFlicker(8.0, 0.15)
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
  -- Configure first, then enable — avoids one frame of uninitialized flicker
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
  lt:setFlickerEnabled(false)  -- pause flicker during cutscene
  lurek.log.info("flicker_enabled=" .. tostring(lt:isFlickerEnabled()), "light")
end
--@api-stub: LLight:setGroupId
-- Sets this light group id
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setGroupId(1)  -- assign to torches group
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
  -- Volumetric lights provide hints for god-ray post-process rendering
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
--@api-stub: LOccluder:remove
-- Removes this light from the shared light world
do
  -- After remove(), the handle is stale — isValid() returns false
  local lt = lurek.light.newLight(400, 300, 200)
  lurek.log.info("valid before remove=" .. tostring(lt:isValid()), "light")
  lt:remove()
  lurek.log.info("valid after remove=" .. tostring(lt:isValid()), "light")
end
--@api-stub: LOccluder:isValid
-- Returns whether this light handle still points to a live light
do
  local lt = lurek.light.newLight(400, 300, 200)
  lurek.log.info("valid=" .. tostring(lt:isValid()), "light")
end
--@api-stub: LLight:addFlicker
-- Adds flicker from min/max intensity range and frequency
do
  -- Convenience: specify intensity bounds and Hz instead of raw speed/strength.
  -- addFlicker(0.8, 1.2, 8.0) means oscillate between 80%-120% at 8 Hz.
  local lt = lurek.light.newLight(400, 300, 200)
  lt:addFlicker(0.8, 1.2, 8.0)
  lurek.log.info("flicker active=" .. tostring(lt:isFlickerEnabled()), "light")
end
--@api-stub: LLight:transitionTo
-- Starts a transition toward target color, intensity, and radius values
do
  -- Smooth day-to-night transition: fade from bright white to dim blue over 2 seconds
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setColor(1.0, 1.0, 0.8, 1.0)  -- start: warm white
  lt:transitionTo(
    { r = 0.0, g = 0.0, b = 1.0, a = 1.0, intensity = 0.3, radius = 100 },
    2.0  -- 2-second fade to dim blue
  )
  lt:updateTransition(0.5)  -- advance 0.5s into the transition
  lurek.log.info("transition progress=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:updateTransition
-- Advances this light's active transition and applies interpolated values
do
  -- Call every frame with dt to drive the transition forward
  local lt = lurek.light.newLight(400, 300, 200)
  lt:transitionTo({ r = 1.0, g = 0.0, b = 0.0, a = 1.0 }, 1.0)
  lt:updateTransition(0.25)  -- 25% through the 1-second transition
  lurek.log.info("progress=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:stopTransition
-- Stops and clears this light's active transition
do
  -- Interrupt a long fade if the player cancels the action
  local lt = lurek.light.newLight(400, 300, 200)
  lt:transitionTo({ intensity = 0.1 }, 5.0)
  lt:stopTransition()  -- cancel the fade, keep current values
  lurek.log.info("progress after stop=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:transitionProgress
-- Returns active transition progress or 1
do
  -- 0.0 = just started, 1.0 = complete (or no transition active)
  local lt = lurek.light.newLight(400, 300, 200)
  lt:transitionTo({ intensity = 0.2 }, 2.0)
  lt:updateTransition(1.0)   -- advance halfway through the 2s transition
  lurek.log.info("transition_progress=" .. lt:transitionProgress(), "light")
end
--@api-stub: LLight:setCookie
-- Stores a cookie texture path on this Lua light handle
do
  -- Cookie textures mask the light shape — window blinds, leaf patterns, gobos
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setCookie("assets/cookie_window.png")
  lurek.log.info("cookie=" .. tostring(lt:getCookie()), "light")
end
--@api-stub: LLight:getCookie
-- Returns the cookie texture path stored on this Lua light handle
do
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setCookie("assets/gobo_slats.png")  -- venetian blind pattern
  lurek.log.info("cookie=" .. tostring(lt:getCookie()), "light")
end
--@api-stub: LLight:clearCookie
-- Clears the cookie texture path stored on this Lua light handle
do
  -- Remove cookie to revert to plain circular light shape
  local lt = lurek.light.newLight(400, 300, 200)
  lt:setCookie("assets/gobo.png")
  lt:clearCookie()
  lurek.log.info("cookie after clear=" .. tostring(lt:getCookie()), "light")
end

--@api-stub: LLight:setNormalMap
-- Sets the normal map path used by this light
do
  -- Normal maps add per-pixel bump illusion to surfaces lit by this light
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
  -- Revert to flat lighting without normal-mapped bumps
  local l = lurek.light.newLight(100, 100, 64)
  l:clearNormalMap()
end

--@api-stub: LLight:setNormalStrength
-- Sets this light's normal map strength
do
  -- 0.0 = no bump, 1.0 = standard, >1.0 = exaggerated depth
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
  -- Higher softness = wider penumbra, looks like a large area light source
  local l = lurek.light.newLight(100, 100, 64)
  l:setShadowSoftness(0.5)
end

--@api-stub: LLight:getShadowSoftness
-- Returns this light shadow softness value
do
  local l = lurek.light.newLight(100, 100, 64)
  local s = l:getShadowSoftness()
end

print("content/examples/light.lua")

-- =============================================================================
-- STUBS: 12 uncovered lurek.light API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LOccluder methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 12 uncovered lurek.light API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.light.setEnabled ----------------------------------------
--@api-stub: lurek.light.setEnabled
-- Enables or disables the shared light world.
do
  -- Toggle the entire lighting system on/off (e.g., for a brightness option).
  lurek.light.setEnabled(false)
  lurek.log.debug("lighting disabled globally", "light")
  lurek.light.setEnabled(true)
end
lurek.light.setEnabled(true)

-- ---- Stub: lurek.light.isEnabled -----------------------------------------
--@api-stub: lurek.light.isEnabled
-- Returns whether the shared light world is enabled.
do
  lurek.light.setEnabled(true)
  local on = lurek.light.isEnabled()
  lurek.log.debug("lighting system enabled: " .. tostring(on), "light") -- true
end

-- -----------------------------------------------------------------------------
-- LLight methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLight:setPosition --------------------------------------------
--@api-stub: LLight:setPosition
-- Sets this light position. This method is available to Lua scripts.
do
  local l = lurek.light.newLight(400, 300, 200)
  l:setPosition(500, 200)
  local x, y = l:getPosition()
  lurek.log.debug("moved to: " .. x .. "," .. y, "light") -- 500, 200
end

-- ---- Stub: LLight:getPosition --------------------------------------------
--@api-stub: LLight:getPosition
-- Returns this light position. This method is available to Lua scripts.
do
  local l = lurek.light.newLight(200, 150, 180)
  local x, y = l:getPosition()
  lurek.log.debug("light pos: " .. x .. "," .. y, "light") -- 200, 150
end

-- ---- Stub: LLight:setLightMask -------------------------------------------
--@api-stub: LLight:setLightMask
-- Sets this light's inclusion mask. This method is available to Lua scripts.
do
  local l = lurek.light.newLight(400, 300, 200)
  l:setLightMask(0xFF)
  lurek.log.debug("light mask set", "light")
end

-- ---- Stub: LLight:getLightMask -------------------------------------------
--@api-stub: LLight:getLightMask
-- Returns this light's inclusion mask.
do
  local l = lurek.light.newLight(400, 300, 200)
  local mask = l:getLightMask()
  lurek.log.debug("light mask: " .. tostring(mask), "light")
end

-- ---- Stub: LLight:setEnabled ---------------------------------------------
--@api-stub: LLight:setEnabled
-- Enables or disables this light. This method is available to Lua scripts.
do
  local l = lurek.light.newLight(400, 300, 200)
  -- Flicker effect: disable then re-enable.
  l:setEnabled(false)
  lurek.log.debug("light off: " .. tostring(not l:isEnabled()), "light") -- true
  l:setEnabled(true)
end

-- ---- Stub: LLight:isEnabled ----------------------------------------------
--@api-stub: LLight:isEnabled
-- Returns whether this light is enabled.
do
  local l = lurek.light.newLight(400, 300, 200)
  lurek.log.debug("enabled: " .. tostring(l:isEnabled()), "light") -- true
end

-- ---- Stub: LLight:remove -------------------------------------------------
--@api-stub: LLight:remove
-- Removes this light from the shared light world.
do
  local l = lurek.light.newLight(400, 300, 150)
  l:remove()
  lurek.log.debug("light removed", "light")
end

-- ---- Stub: LLight:isValid ------------------------------------------------
--@api-stub: LLight:isValid
-- Returns whether this light handle still points to a live light.
do
  local l = lurek.light.newLight(400, 300, 200)
  lurek.log.debug("valid: " .. tostring(l:isValid()), "light") -- true
  l:remove()
  lurek.log.debug("valid after remove: " .. tostring(l:isValid()), "light") -- false
end

-- ---- Stub: LLight:type ---------------------------------------------------
--@api-stub: LLight:type
-- Returns the Lua-visible type name for this light handle.
do
  local obj = lurek.light.newLight(400, 300, 200)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LLight"
end

-- ---- Stub: LLight:typeOf -------------------------------------------------
--@api-stub: LLight:typeOf
-- Returns whether this light handle matches a supported type name.
do
  local obj = lurek.light.newLight(400, 300, 200)
  lurek.log.debug("typeOf LLight: " .. tostring(obj:typeOf("LLight")), "example") -- true
end
