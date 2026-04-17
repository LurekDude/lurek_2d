-- content/examples/light.lua
-- Lurek2D lurek.light API Reference
-- Run with: cargo run -- content/examples/light
--
-- Scenario: A dungeon crawler with dynamic lighting — a player torch (point
-- light), flickering wall sconces, a directional moonbeam through windows,
-- shadow-casting occluders for walls, and light groups for room transitions.

print("=== lurek.light — 2D Lighting System ===\n")

-- =============================================================================
-- Global Lighting Setup
-- =============================================================================

--@api-stub: lurek.light.setEnabled
lurek.light.setEnabled(true)

--@api-stub: lurek.light.isEnabled
print("lighting enabled: " .. tostring(lurek.light.isEnabled()))

--@api-stub: lurek.light.setAmbient
-- Dark dungeon ambient (dim blue-grey).
lurek.light.setAmbient(0.05, 0.05, 0.08, 1.0)

--@api-stub: lurek.light.getAmbient
local ar, ag, ab, aa = lurek.light.getAmbient()
print("ambient: " .. ar .. "," .. ag .. "," .. ab)

--@api-stub: lurek.light.syncAmbient
lurek.light.syncAmbient()

--@api-stub: lurek.light.setMaxLights
lurek.light.setMaxLights(64)

--@api-stub: lurek.light.getMaxLights
print("max lights: " .. lurek.light.getMaxLights())

--@api-stub: lurek.light.getLightCount
print("active lights: " .. lurek.light.getLightCount())

--@api-stub: lurek.light.getOccluderCount
print("occluders: " .. lurek.light.getOccluderCount())

-- =============================================================================
-- Point Light — Player Torch
-- =============================================================================

--@api-stub: lurek.light.newLight
local torch = lurek.light.newLight()

--@api-stub: Light:setPosition
torch:setPosition(400, 300)

--@api-stub: Light:getPosition
local lx, ly = torch:getPosition()
print("torch at: " .. lx .. "," .. ly)

--@api-stub: Light:setRadius
torch:setRadius(200)

--@api-stub: Light:getRadius
print("torch radius: " .. torch:getRadius())

--@api-stub: Light:setColor
torch:setColor(1.0, 0.85, 0.6)

--@api-stub: Light:getColor
local lr, lg, lb = torch:getColor()
print("torch color: " .. lr .. "," .. lg .. "," .. lb)

--@api-stub: Light:setIntensity
torch:setIntensity(1.2)

--@api-stub: Light:getIntensity
print("torch intensity: " .. torch:getIntensity())

--@api-stub: Light:setEnergy
torch:setEnergy(1.0)

--@api-stub: Light:getEnergy
print("torch energy: " .. torch:getEnergy())

--@api-stub: Light:setFalloff
torch:setFalloff(1.5)

--@api-stub: Light:getFalloff
print("falloff: " .. torch:getFalloff())

--@api-stub: Light:setAttenuation
torch:setAttenuation(0.5)

--@api-stub: Light:getAttenuation
print("attenuation: " .. torch:getAttenuation())

--@api-stub: Light:setBlendMode
torch:setBlendMode("additive")

--@api-stub: Light:getBlendMode
print("blend: " .. torch:getBlendMode())

--@api-stub: Light:setEnabled
torch:setEnabled(true)

--@api-stub: Light:isEnabled
print("torch on: " .. tostring(torch:isEnabled()))

--@api-stub: Light:isValid
print("torch valid: " .. tostring(torch:isValid()))

--@api-stub: Light:setLightType
torch:setLightType("point")

--@api-stub: Light:getLightType
print("type: " .. torch:getLightType())

-- =============================================================================
-- Spot Light — Moonbeam through window
-- =============================================================================

local moon = lurek.light.newLight()
moon:setLightType("spot")
moon:setPosition(600, 50)
moon:setColor(0.6, 0.7, 1.0)
moon:setRadius(400)

--@api-stub: Light:setDirection
moon:setDirection(math.pi / 2)  -- pointing down

--@api-stub: Light:getDirection
print("moon direction: " .. moon:getDirection())

--@api-stub: Light:setInnerAngle
moon:setInnerAngle(math.pi / 12)

--@api-stub: Light:getInnerAngle
print("inner angle: " .. moon:getInnerAngle())

--@api-stub: Light:setOuterAngle
moon:setOuterAngle(math.pi / 6)

--@api-stub: Light:getOuterAngle
print("outer angle: " .. moon:getOuterAngle())

-- =============================================================================
-- Shadows
-- =============================================================================

--@api-stub: Light:setShadowEnabled
torch:setShadowEnabled(true)

--@api-stub: Light:isShadowEnabled
print("shadows: " .. tostring(torch:isShadowEnabled()))

--@api-stub: Light:getShadowColor
local sr, sg, sb = torch:getShadowColor()

--@api-stub: Light:setShadowFilter
torch:setShadowFilter("pcf")

--@api-stub: Light:getShadowFilter
print("shadow filter: " .. torch:getShadowFilter())

--@api-stub: Light:setShadowSmooth
torch:setShadowSmooth(2.0)

--@api-stub: Light:getShadowSmooth
print("shadow smooth: " .. torch:getShadowSmooth())

-- =============================================================================
-- Light/Shadow Masks
-- =============================================================================

--@api-stub: Light:setLightMask
torch:setLightMask(0x01)

--@api-stub: Light:getLightMask
print("light mask: " .. torch:getLightMask())

--@api-stub: Light:setShadowMask
torch:setShadowMask(0xFF)

--@api-stub: Light:getShadowMask
print("shadow mask: " .. torch:getShadowMask())

-- =============================================================================
-- Flicker Effect — Wall Sconces
-- =============================================================================

local sconce = lurek.light.newLight()
sconce:setPosition(200, 150)
sconce:setColor(1.0, 0.6, 0.3)
sconce:setRadius(120)

--@api-stub: Light:setFlicker
-- Flicker parameters: min intensity, max intensity, speed.
sconce:setFlicker(0.6, 1.0, 5.0)

--@api-stub: Light:getFlicker
local fmin, fmax, fspd = sconce:getFlicker()
print("flicker: " .. fmin .. "-" .. fmax .. " speed " .. fspd)

--@api-stub: Light:setFlickerEnabled
sconce:setFlickerEnabled(true)

--@api-stub: Light:isFlickerEnabled
print("flicker on: " .. tostring(sconce:isFlickerEnabled()))

--@api-stub: lurek.light.advanceFlickers
lurek.light.advanceFlickers(1/60)

-- =============================================================================
-- Light Groups — Room transitions
-- =============================================================================

--@api-stub: Light:setGroupId
torch:setGroupId(1)
sconce:setGroupId(2)
moon:setGroupId(3)

--@api-stub: Light:getGroupId
print("torch group: " .. torch:getGroupId())

--@api-stub: lurek.light.setGroupEnabled
-- Disable a room's lights when the player leaves.
lurek.light.setGroupEnabled(2, false)

--@api-stub: lurek.light.setGroupIntensity
lurek.light.setGroupIntensity(1, 1.0)

--@api-stub: lurek.light.setGroupColor
lurek.light.setGroupColor(3, 0.4, 0.5, 0.8)

--@api-stub: lurek.light.getGroupCount
print("light groups: " .. lurek.light.getGroupCount())

-- =============================================================================
-- Volumetric Light
-- =============================================================================

--@api-stub: Light:setVolumetric
moon:setVolumetric(true)

--@api-stub: Light:isVolumetric
print("moon volumetric: " .. tostring(moon:isVolumetric()))

--@api-stub: lurek.light.getGodRayHints
local hints = lurek.light.getGodRayHints()
print("god ray hints: " .. #hints)

-- =============================================================================
-- Occluders — Shadow-casting walls
-- =============================================================================

--@api-stub: lurek.light.newOccluder
local wall = lurek.light.newOccluder()

--@api-stub: Occluder:setVertices
-- Define a rectangular wall that casts shadows.
wall:setVertices({300,200, 350,200, 350,400, 300,400})

--@api-stub: Occluder:getVertices
local verts = wall:getVertices()
print("wall vertices: " .. #verts / 2 .. " points")

--@api-stub: Occluder:setPosition
wall:setPosition(300, 200)

--@api-stub: Occluder:getPosition
local ox, oy = wall:getPosition()
print("wall at: " .. ox .. "," .. oy)

--@api-stub: Occluder:setOpacity
wall:setOpacity(1.0)

--@api-stub: Occluder:getOpacity
print("wall opacity: " .. wall:getOpacity())

--@api-stub: Occluder:setLightMask
wall:setLightMask(0xFF)

--@api-stub: Occluder:getLightMask
print("occluder mask: " .. wall:getLightMask())

--@api-stub: Occluder:setEnabled
wall:setEnabled(true)

--@api-stub: Occluder:isEnabled
print("wall enabled: " .. tostring(wall:isEnabled()))

--@api-stub: Occluder:isValid
print("wall valid: " .. tostring(wall:isValid()))

--@api-stub: Occluder:remove
-- wall:remove()

-- =============================================================================
-- Occluder Transitions & Cookies
-- =============================================================================

--@api-stub: Occluder:addFlicker
-- Make a broken window occluder flicker.
wall:addFlicker(0.8, 1.0, 3.0)

--@api-stub: Occluder:transitionTo
-- Smoothly fade occluder opacity (e.g. door opening).
wall:transitionTo(0.0, 1.5)

--@api-stub: Occluder:updateTransition
wall:updateTransition(1/60)

--@api-stub: Occluder:transitionProgress
print("transition: " .. wall:transitionProgress())

--@api-stub: Occluder:stopTransition
wall:stopTransition()

--@api-stub: Occluder:setCookie
wall:setCookie("assets/cookies/window_bars.png")

--@api-stub: Occluder:getCookie
print("cookie: " .. tostring(wall:getCookie()))

--@api-stub: Occluder:clearCookie
wall:clearCookie()

-- =============================================================================
-- Cleanup
-- =============================================================================

--@api-stub: lurek.light.clear
-- lurek.light.clear()

--@api-stub: Light:remove
-- torch:remove()

print("\n-- light.lua example complete --")
