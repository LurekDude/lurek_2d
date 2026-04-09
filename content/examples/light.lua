-- examples/light.lua
-- lurek.light — 2D lighting, shadow occluders, and ambient control.

-- ── System-level controls ─────────────────────────────────────────────────────

-- setEnabled(bool) — master switch for the lighting system
lurek.light.setEnabled(true)

-- isEnabled() → boolean
local active = lurek.light.isEnabled()

-- setAmbient(r, g, b, a?) — global background illumination (0..1 per channel)
lurek.light.setAmbient(0.05, 0.05, 0.15, 1.0)   -- near-dark blue night sky

-- getAmbient() → r, g, b, a
local ar, ag, ab, aa = lurek.light.getAmbient()

-- ── Creating a Light ──────────────────────────────────────────────────────────

-- newLight(x, y, radius, opts?) → Light
-- opts is an optional table of named properties (all optional):
color         {r,g,b,a}  -- tint (default white)
intensity     number  -- overall brightness scale (default 1)
energy        number  -- secondary multiplier
type          string  -- "point" | "directional" | "spot" (default "point")
blend         string  -- "add" | "sub" | "mix" (default "add")
falloff       string  -- "linear" | "smooth" | "constant" (default "linear")
shadowEnabled boolean  -- cast shadows (default false)
shadowColor   {r,g,b,a}  -- shadow tint
shadowFilter  string  -- "none" | "pcf5" | "pcf13" (softness)
shadowSmooth  number  -- soft-shadow edge blur
lightMask     integer  -- bitmask which occluders block this light
shadowMask    integer  -- bitmask which occluder groups cast shadows
enabled       boolean  -- on/off switch (default true)
direction     number  -- angle in radians (directional/spot lights)
innerAngle    number  -- spot inner cone angle (radians)
outerAngle    number  -- spot outer cone angle (radians)
groupId       integer  -- group for multi-pass or masking
volumetric    boolean  -- render light shaft
flickerSpeed  number  -- flicker frequency (enables flicker if > 0)
flickerStrength number  -- flicker amplitude
attConstant   number  -- attenuation constant term
attLinear     number  -- attenuation linear term
attQuadratic  number  -- attenuation quadratic term

-- Point light (torch)
local torch = lurek.light.newLight(400, 300, 200, {
    color         = {1.0, 0.8, 0.4, 1.0},
    intensity     = 1.2,
    blend         = "add",
    falloff       = "smooth",
    shadowEnabled = true,
    shadowFilter  = "pcf5",
    flickerSpeed  = 8.0,
    flickerStrength = 0.12,
})

-- Spot light (flashlight)
local flashlight = lurek.light.newLight(0, 0, 350, {
    type       = "spot",
    color      = {0.9, 0.95, 1.0, 1.0},
    intensity  = 2.0,
    direction  = 0.0,      -- radians, 0 = right
    innerAngle = 0.3,      -- narrow bright core
    outerAngle = 0.8,      -- soft penumbra edge
    shadowEnabled = true,
    shadowFilter  = "pcf13",
})

-- Directional light (sun / moon)
local sun = lurek.light.newLight(0, 0, 0, {
    type      = "directional",
    color     = {1.0, 0.95, 0.8, 1.0},
    intensity = 0.6,
    direction = 0.785,     -- 45 degrees
})

-- ── Light Methods ─────────────────────────────────────────────────────────────

-- setPosition(x, y)  /  getPosition() → x, y
torch:setPosition(500, 250)
local lx, ly = torch:getPosition()

-- setRadius(r)  /  getRadius() → number
torch:setRadius(250)
local radius = torch:getRadius()

-- setColor(r, g, b, a?)  /  getColor() → r, g, b, a
torch:setColor(1.0, 0.7, 0.3, 1.0)
local lr, lg, lb, la = torch:getColor()

-- setIntensity(v)  /  getIntensity() → number
torch:setIntensity(1.5)
local intensity = torch:getIntensity()

-- setEnabled(bool)  /  isEnabled() → boolean
torch:setEnabled(false)
local on = torch:isEnabled()

-- setBlendMode(mode)  /  getBlendMode() → string   ("add"|"sub"|"mix")
torch:setBlendMode("add")
local blend = torch:getBlendMode()

-- setFalloff(mode)  /  getFalloff() → string   ("linear"|"smooth"|"constant")
torch:setFalloff("smooth")
local falloff = torch:getFalloff()

-- setShadowEnabled(bool)  /  isShadowEnabled() → boolean
torch:setShadowEnabled(true)

-- setShadowFilter(mode)  /  getShadowFilter() → string   ("none"|"pcf5"|"pcf13")
torch:setShadowFilter("pcf13")

-- setShadowSmooth(v)  /  getShadowSmooth() → number
torch:setShadowSmooth(1.5)

-- setShadowColor(r, g, b, a?)  /  getShadowColor() → r, g, b, a
torch:setShadowColor(0, 0, 0, 0.9)

-- setLightMask(mask)  /  getLightMask() → integer
torch:setLightMask(0xFFFF)   -- affect all occluder groups

-- setDirection(radians)  /  getDirection() → number
flashlight:setDirection(math.pi / 4)   -- 45 degrees

-- setInnerAngle(radians)  /  getInnerAngle() → number
-- setOuterAngle(radians)  /  getOuterAngle() → number
flashlight:setInnerAngle(0.25)
flashlight:setOuterAngle(0.7)

-- remove() — destroys the light
torch:remove()

-- ── Shadow Occluders ──────────────────────────────────────────────────────────

-- newOccluder(vertices, opts?) → Occluder
-- vertices: flat table {x1,y1, x2,y2, ...} — polygon edges that block light
-- opts: opacity, lightMask, enabled

-- Wall segment
local wall = lurek.light.newOccluder(
    {100,100,  300,100,  300,200,  100,200},   -- rectangle
    { opacity = 1.0, lightMask = 0xFFFF, enabled = true }
)

-- LuaOccluder methods:
wall:setPosition(0, 0)           -- translate the whole occluder
local ox, oy = wall:getPosition()
wall:setOpacity(1.0)             -- 0=transparent shadow, 1=full opaque shadow
wall:setEnabled(true)
wall:setLightMask(0xFFFF)        -- bitmask controls which lights cast on it
wall:remove()  -- free the occluder

-- ── Typical Usage ─────────────────────────────────────────────────────────────

--[[
function lurek.init()
    lurek.light.setEnabled(true)
    lurek.light.setAmbient(0.04, 0.04, 0.1, 1.0)

    player_light = lurek.light.newLight(400, 300, 180, {
        color         = {1.0, 0.85, 0.5, 1.0},
        shadowEnabled = true,
        shadowFilter  = "pcf5",
        flickerSpeed  = 6,
        flickerStrength = 0.08,
    })
end

function lurek.process(dt)
    local mx, my = lurek.mouse.getPosition()
    player_light:setPosition(mx, my)
end

function lurek.render()
    -- draw scene (lighting composited automatically)
    lurek.gfx.setColor(0.6, 0.4, 0.2)
    lurek.gfx.rectangle("fill", 200, 200, 80, 80)
end
]]

-- ─── Light ─────────────────────────────────────────────────────────────────────

local attenuation = light:getAttenuation()  -- Returns the custom attenuation coefficients as (constant, linear, quadratic)
local direction = light:getDirection()  -- Returns the direction angle in radians
local energy = light:getEnergy()  -- Returns the energy scaling factor
local flicker = light:getFlicker()  -- Returns the flicker effect speed and strength
local group_id = light:getGroupId()  -- Returns the group identifier
local inner_angle = light:getInnerAngle()  -- Returns the inner cone angle in radians
local light_mask = light:getLightMask()  -- Returns the light interaction bitmask
local light_type = light:getLightType()  -- Returns the geometric light type as a string
local outer_angle = light:getOuterAngle()  -- Returns the outer cone angle in radians
local shadow_color = light:getShadowColor()  -- Returns the shadow region color as (r, g, b, a)
local shadow_filter = light:getShadowFilter()  -- Returns the shadow edge filter as a string
local shadow_mask = light:getShadowMask()  -- Returns the shadow casting bitmask
local shadow_smooth = light:getShadowSmooth()  -- Returns the shadow edge smoothing factor
local is_flicker_enabled = light:isFlickerEnabled()  -- Returns whether the flicker effect is active
local is_shadow_enabled = light:isShadowEnabled()  -- Returns whether this light casts shadows
local is_valid = light:isValid()  -- Returns whether this light handle is still valid
local is_volumetric = light:isVolumetric()  -- Returns whether this light hints at volumetric scattering
light:setAttenuation(1.0, 1.0, 1.0)  -- Sets the custom attenuation coefficients (constant, linear, quadratic)
light:setEnergy(1.0)  -- Sets the energy scaling factor
light:setFlicker(1.0, 1.0)  -- Sets the flicker effect speed and strength (enables flicker)
light:setFlickerEnabled(false)  -- Sets whether the flicker effect is active
light:setGroupId(1)  -- Sets the group identifier for batch operations
light:setLightType("point")  -- "point", "directional", or "spot"
light:setShadowMask(1)  -- Sets the shadow casting bitmask
light:setVolumetric(false)  -- Sets whether this light hints at volumetric scattering

-- ─── Occluder ──────────────────────────────────────────────────────────────────

local light_mask = occluder:getLightMask()  -- Returns the light interaction bitmask
local opacity = occluder:getOpacity()  -- Returns the shadow opacity
local vertices = occluder:getVertices()  -- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}
local is_valid = occluder:isValid()  -- Returns whether this occluder handle is still valid
occluder:setVertices({})  -- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}

-- ─── lurek.light ────────────────────────────────────────────────────────────────
lurek.light.advanceFlickers(1.0)  -- Advances flicker phase for all lights with flicker enabled
lurek.light.clear()  -- Removes all lights and occluders, resets ambient to default
local group_count = lurek.light.getGroupCount(1)  -- Returns the number of lights in the given group
local light_count = lurek.light.getLightCount()  -- Returns the number of lights in the world
local max_lights = lurek.light.getMaxLights()  -- Returns the maximum number of lights processed per frame
local occluder_count = lurek.light.getOccluderCount()  -- Returns the number of occluders in the world
lurek.light.setGroupColor(1, 1.0, 1.0, 1.0)  -- Sets the color for all lights in the given group
lurek.light.setGroupEnabled(1, false)  -- Sets the enabled state for all lights in the given group
lurek.light.setGroupIntensity(1, 1.0)  -- Sets the intensity for all lights in the given group
lurek.light.setMaxLights(1)  -- Sets the maximum number of lights processed per frame (clamped 1–256)
