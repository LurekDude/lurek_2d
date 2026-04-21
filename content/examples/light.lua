-- content/examples/light.lua
-- Lurek2D lurek.light API Reference
-- Run with: cargo run -- content/examples/light
--
Scenario: A dungeon crawler with dynamic lighting — a player torch (point
-- light), flickering wall sconces, a directional moonbeam through windows,
-- shadow-casting occluders for walls, and light groups for room transitions.

print("=== lurek.light — 2D Lighting System ===\n")

-- =============================================================================
-- Global Lighting Setup
-- =============================================================================

lurek.light.setEnabled(true)

print("lighting enabled: " .. tostring(lurek.light.isEnabled()))

-- Dark dungeon ambient (dim blue-grey).
lurek.light.setAmbient(0.05, 0.05, 0.08, 1.0)

local ar, ag, ab, aa = lurek.light.getAmbient()
print("ambient: " .. ar .. "," .. ag .. "," .. ab)

lurek.light.syncAmbient()

lurek.light.setMaxLights(64)

print("max lights: " .. lurek.light.getMaxLights())

print("active lights: " .. lurek.light.getLightCount())

print("occluders: " .. lurek.light.getOccluderCount())

-- =============================================================================
-- Point Light — Player Torch
-- =============================================================================

local torch = lurek.light.newLight()

torch:setPosition(400, 300)

local lx, ly = torch:getPosition()
print("torch at: " .. lx .. "," .. ly)

torch:setRadius(200)

print("torch radius: " .. torch:getRadius())

torch:setColor(1.0, 0.85, 0.6)

local lr, lg, lb = torch:getColor()
print("torch color: " .. lr .. "," .. lg .. "," .. lb)

torch:setIntensity(1.2)

print("torch intensity: " .. torch:getIntensity())

torch:setEnergy(1.0)

print("torch energy: " .. torch:getEnergy())

torch:setFalloff(1.5)

print("falloff: " .. torch:getFalloff())

torch:setAttenuation(0.5)

print("attenuation: " .. torch:getAttenuation())

torch:setBlendMode("additive")

print("blend: " .. torch:getBlendMode())

torch:setEnabled(true)

print("torch on: " .. tostring(torch:isEnabled()))

print("torch valid: " .. tostring(torch:isValid()))

torch:setLightType("point")

print("type: " .. torch:getLightType())

-- =============================================================================
-- Spot Light — Moonbeam through window
-- =============================================================================

local moon = lurek.light.newLight()
moon:setLightType("spot")
moon:setPosition(600, 50)
moon:setColor(0.6, 0.7, 1.0)
moon:setRadius(400)

moon:setDirection(math.pi / 2)  -- pointing down

print("moon direction: " .. moon:getDirection())

moon:setInnerAngle(math.pi / 12)

print("inner angle: " .. moon:getInnerAngle())

moon:setOuterAngle(math.pi / 6)

print("outer angle: " .. moon:getOuterAngle())

-- =============================================================================
-- Shadows
-- =============================================================================

torch:setShadowEnabled(true)

print("shadows: " .. tostring(torch:isShadowEnabled()))

local sr, sg, sb = torch:getShadowColor()

torch:setShadowFilter("pcf")

print("shadow filter: " .. torch:getShadowFilter())

torch:setShadowSmooth(2.0)

print("shadow smooth: " .. torch:getShadowSmooth())

-- =============================================================================
-- Light/Shadow Masks
-- =============================================================================

torch:setLightMask(0x01)

print("light mask: " .. torch:getLightMask())

torch:setShadowMask(0xFF)

print("shadow mask: " .. torch:getShadowMask())

-- =============================================================================
-- Flicker Effect — Wall Sconces
-- =============================================================================

local sconce = lurek.light.newLight()
sconce:setPosition(200, 150)
sconce:setColor(1.0, 0.6, 0.3)
sconce:setRadius(120)

-- Flicker parameters: min intensity, max intensity, speed.
sconce:setFlicker(0.6, 1.0, 5.0)

local fmin, fmax, fspd = sconce:getFlicker()
print("flicker: " .. fmin .. "-" .. fmax .. " speed " .. fspd)

sconce:setFlickerEnabled(true)

print("flicker on: " .. tostring(sconce:isFlickerEnabled()))

lurek.light.advanceFlickers(1/60)

-- =============================================================================
-- Light Groups — Room transitions
-- =============================================================================

torch:setGroupId(1)
sconce:setGroupId(2)
moon:setGroupId(3)

print("torch group: " .. torch:getGroupId())

-- Disable a room's lights when the player leaves.
lurek.light.setGroupEnabled(2, false)

lurek.light.setGroupIntensity(1, 1.0)

lurek.light.setGroupColor(3, 0.4, 0.5, 0.8)

print("light groups: " .. lurek.light.getGroupCount())

-- =============================================================================
-- Volumetric Light
-- =============================================================================

moon:setVolumetric(true)

print("moon volumetric: " .. tostring(moon:isVolumetric()))

local hints = lurek.light.getGodRayHints()
print("god ray hints: " .. #hints)

-- =============================================================================
-- Occluders — Shadow-casting walls
-- =============================================================================

local wall = lurek.light.newOccluder()

-- Define a rectangular wall that casts shadows.
wall:setVertices({300,200, 350,200, 350,400, 300,400})

local verts = wall:getVertices()
print("wall vertices: " .. #verts / 2 .. " points")

wall:setPosition(300, 200)

local ox, oy = wall:getPosition()
print("wall at: " .. ox .. "," .. oy)

wall:setOpacity(1.0)

print("wall opacity: " .. wall:getOpacity())

wall:setLightMask(0xFF)

print("occluder mask: " .. wall:getLightMask())

wall:setEnabled(true)

print("wall enabled: " .. tostring(wall:isEnabled()))

print("wall valid: " .. tostring(wall:isValid()))

wall:remove()

-- =============================================================================
-- Occluder Transitions & Cookies
-- =============================================================================

-- Make a broken window occluder flicker.
wall:addFlicker(0.8, 1.0, 3.0)

-- Smoothly fade occluder opacity (e.g. door opening).
wall:transitionTo(0.0, 1.5)

wall:updateTransition(1/60)

print("transition: " .. wall:transitionProgress())

wall:stopTransition()

wall:setCookie("assets/cookies/window_bars.png")

print("cookie: " .. tostring(wall:getCookie()))

wall:clearCookie()

-- =============================================================================
-- Cleanup
-- =============================================================================

lurek.light.clear()

torch:remove()

print("\n-- light.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- Removes all lights and occluders, resets ambient to default.
lurek.light.clear()

-- -----------------------------------------------------------------------------
-- Light methods
-- -----------------------------------------------------------------------------

-- Removes this light from the world.
torch:remove()
-- -----------------------------------------------------------------------------
-- Occluder methods
-- -----------------------------------------------------------------------------

-- Removes this occluder from the world.
wall:remove()
