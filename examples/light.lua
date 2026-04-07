-- examples/light.lua
-- luna.light — 2D lighting, shadow occluders, and ambient control.
-- All luna.light API methods demonstrated with code and comments.

-- ── System-level controls ─────────────────────────────────────────────────────

-- setEnabled(bool) — master switch for the lighting system
luna.light.setEnabled(true)

-- isEnabled() → boolean
local active = luna.light.isEnabled()

-- setAmbient(r, g, b, a?) — global background illumination (0..1 per channel)
luna.light.setAmbient(0.05, 0.05, 0.15, 1.0)   -- near-dark blue night sky

-- getAmbient() → r, g, b, a
local ar, ag, ab, aa = luna.light.getAmbient()

-- ── Creating a Light ──────────────────────────────────────────────────────────

-- newLight(x, y, radius, opts?) → Light
-- opts is an optional table of named properties (all optional):
--   color         {r,g,b,a}   — tint (default white)
--   intensity     number      — overall brightness scale (default 1)
--   energy        number      — secondary multiplier
--   type          string      — "point" | "directional" | "spot" (default "point")
--   blend         string      — "add" | "sub" | "mix" (default "add")
--   falloff       string      — "linear" | "smooth" | "constant" (default "linear")
--   shadowEnabled boolean     — cast shadows (default false)
--   shadowColor   {r,g,b,a}   — shadow tint
--   shadowFilter  string      — "none" | "pcf5" | "pcf13" (softness)
--   shadowSmooth  number      — soft-shadow edge blur
--   lightMask     integer     — bitmask which occluders block this light
--   shadowMask    integer     — bitmask which occluder groups cast shadows
--   enabled       boolean     — on/off switch (default true)
--   direction     number      — angle in radians (directional/spot lights)
--   innerAngle    number      — spot inner cone angle (radians)
--   outerAngle    number      — spot outer cone angle (radians)
--   groupId       integer     — group for multi-pass or masking
--   volumetric    boolean     — render light shaft
--   flickerSpeed  number      — flicker frequency (enables flicker if > 0)
--   flickerStrength number    — flicker amplitude
--   attConstant   number      — attenuation constant term
--   attLinear     number      — attenuation linear term
--   attQuadratic  number      — attenuation quadratic term

-- Point light (torch)
local torch = luna.light.newLight(400, 300, 200, {
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
local flashlight = luna.light.newLight(0, 0, 350, {
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
local sun = luna.light.newLight(0, 0, 0, {
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
-- torch:remove()

-- ── Shadow Occluders ──────────────────────────────────────────────────────────

-- newOccluder(vertices, opts?) → Occluder
-- vertices: flat table {x1,y1, x2,y2, ...} — polygon edges that block light
-- opts: opacity, lightMask, enabled

-- Wall segment
local wall = luna.light.newOccluder(
    {100,100,  300,100,  300,200,  100,200},   -- rectangle
    { opacity = 1.0, lightMask = 0xFFFF, enabled = true }
)

-- LuaOccluder methods:
wall:setPosition(0, 0)           -- translate the whole occluder
local ox, oy = wall:getPosition()
wall:setOpacity(1.0)             -- 0=transparent shadow, 1=full opaque shadow
wall:setEnabled(true)
wall:setLightMask(0xFFFF)        -- bitmask controls which lights cast on it
-- wall:remove()                  -- free the occluder

-- ── Typical Usage ─────────────────────────────────────────────────────────────

--[[
function luna.init()
    luna.light.setEnabled(true)
    luna.light.setAmbient(0.04, 0.04, 0.1, 1.0)

    player_light = luna.light.newLight(400, 300, 180, {
        color         = {1.0, 0.85, 0.5, 1.0},
        shadowEnabled = true,
        shadowFilter  = "pcf5",
        flickerSpeed  = 6,
        flickerStrength = 0.08,
    })
end

function luna.process(dt)
    local mx, my = luna.mouse.getPosition()
    player_light:setPosition(mx, my)
end

function luna.render()
    -- draw scene (lighting composited automatically)
    luna.gfx.setColor(0.6, 0.4, 0.2)
    luna.gfx.rectangle("fill", 200, 200, 80, 80)
end
]]
