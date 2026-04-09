-- examples/fx.lua
-- luna.postfx — Post-processing effects: stacking, per-image chains, screen overlays.
-- All luna.postfx API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- ── Effect Types ──────────────────────────────────────────────────────────────
-- Use one of these string names with luna.postfx.newEffect(type_name):
--   "blur", "bloom", "chromatic_aberration", "color_grading", "crt",
--   "fisheye", "grain", "scanlines", "sepia", "vignette"

-- ── Creating Effects ──────────────────────────────────────────────────────────

-- newEffect(type_name) → PostFxEffect  — built-in effect by name
local blur   = luna.postfx.newEffect("blur")
local vign   = luna.postfx.newEffect("vignette")
local grain  = luna.postfx.newEffect("grain")
local sepia  = luna.postfx.newEffect("sepia")

-- newCustomEffect(shader_id) → PostFxEffect  — custom WGSL shader effect
-- shader_id is the id returned by luna.gfx.newShader(...)
-- local my_shader = luna.gfx.newShader(nil, frag_src)
-- local custom_fx = luna.postfx.newCustomEffect(my_shader:getId())

-- ── Configuring Effects ───────────────────────────────────────────────────────

-- setParameter(name, value)
blur:setParameter("radius", 4.0)
blur:setParameter("sigma", 1.5)

vign:setParameter("intensity", 0.65)
vign:setParameter("smoothness", 0.4)

grain:setParameter("intensity", 0.15)
grain:setParameter("animated", 1.0)   -- 1 = update per frame, 0 = static

-- getParameter(name, default?) → value
local radius = blur:getParameter("radius", 2.0)

-- hasParameter(name) → bool
local has_r = blur:hasParameter("radius")

-- getParameterNames() → table (array of string)
local param_names = blur:getParameterNames()

-- getTypeName() → string
local tn = blur:getTypeName()     -- "blur"

-- isBuiltIn() → bool
local bi = blur:isBuiltIn()       -- true (false for custom effects)

-- ── Enable / Disable ─────────────────────────────────────────────────────────

-- setEnabled(bool) / isEnabled() → bool
blur:setEnabled(true)
local en = blur:isEnabled()

-- ── PostFxStack (full-screen pipeline) ───────────────────────────────────────

-- newStack(w, h) → PostFxStack  — w/h should match screen or canvas dimensions
local W, H = 1280, 720
local fx_stack = luna.postfx.newStack(W, H)

-- add(effect_index) — add a slot by integer index (arbitrary allocation)
-- Internally the stack manages effect positions; use the effect's own add_method index.
-- In practice: add, then reference position for other operations:
fx_stack:add(1)
fx_stack:add(2)
fx_stack:add(3)

-- len() → integer  — total number of slots
local n_slots = fx_stack:len()

-- isEmpty() → bool
local empty = fx_stack:isEmpty()

-- getEffectCount() → integer
local n_eff = fx_stack:getEffectCount()

-- getEffect(position) → integer?  — slot at 1-based position
local slot = fx_stack:getEffect(1)

-- getEnabledEffects() → table  — list of enabled slot indices
local enabled = fx_stack:getEnabledEffects()

-- setEnabled(index, bool) / isEnabled(index) → bool
fx_stack:setEnabled(1, true)
fx_stack:setEnabled(3, false)
local is_en = fx_stack:isEnabled(2)

-- remove(index) → bool  — remove a slot by index
fx_stack:remove(3)

-- insert(position, index)
fx_stack:insert(1, 4)   -- put effect slot #4 at position 1

-- getWidth / getHeight / getDimensions
local w = fx_stack:getWidth()
local h = fx_stack:getHeight()
local sw, sh = fx_stack:getDimensions()

-- resize(w, h)  — resize the render target
fx_stack:resize(640, 360)

-- clear()  — remove all effects
-- fx_stack:clear()

-- ── ImageEffect (per-image effect chain) ─────────────────────────────────────

-- newImageEffect(name) → ImageEffect  — named per-image chain
local img_fx = luna.postfx.newImageEffect("hero_glow")

-- addEffect(effect) — append a PostFxEffect to this chain
img_fx:addEffect(blur)
img_fx:addEffect(vign)

-- getEffectCount() → integer
local nc = img_fx:getEffectCount()

-- removeByIndex(idx) → bool
img_fx:removeByIndex(2)

-- removeByName(type_name) → bool  — remove first effect matching the type name
img_fx:removeByName("blur")

-- clear()
-- img_fx:clear()

-- ── Overlay (screen-wide transient effects) ───────────────────────────────────

-- newOverlay(w, h) → Overlay
local overlay = luna.postfx.newOverlay(W, H)

-- triggerFlash(r, g, b, a, duration)  — brief colour flash (e.g. hit, explosion)
overlay:triggerFlash(1.0, 0.0, 0.0, 0.8, 0.15)   -- fast red flash

-- triggerShake(intensity, duration?)  — screen shake (use in update loop)
overlay:triggerShake(12.0, 0.3)                    -- short camera shake

-- triggerFade(r, g, b, target_alpha, duration)  — fade to colour
overlay:triggerFade(0.0, 0.0, 0.0, 1.0, 0.5)       -- fade to black over 0.5s

-- triggerLightning()  — lightning flash
overlay:triggerLightning()

-- getShakeOffset() → x, y  — apply to camera or draw translate each frame
local sx, sy = overlay:getShakeOffset()

-- isActive() → bool  — true if any overlay animation is still running
local active = overlay:isActive()

-- getFlashAlpha() → number  — current flash transparency (0–1)
local fa = overlay:getFlashAlpha()

-- getLightningAlpha() → number  — current lightning transparency (0–1)
local la = overlay:getLightningAlpha()

-- update(dt) → nil  — advance all overlay animations
overlay:update(0.016)

-- resize(w, h) / getWidth / getHeight / getDimensions
overlay:resize(1280, 720)

-- clear()  — cancel all active animations
-- overlay:clear()

-- ── Typical Game Usage ───────────────────────────────────────────────────────

--[[
local fx_overlay, shake_x, shake_y

function luna.init()
    fx_overlay = luna.postfx.newOverlay(luna.window.getWidth(), luna.window.getHeight())
end

function luna.process(dt)
    -- react to hit
    if player_was_hit then
        fx_overlay:triggerFlash(1, 0, 0, 0.6, 0.12)
        fx_overlay:triggerShake(8.0, 0.2)
    end
    fx_overlay:update(dt)
    shake_x, shake_y = fx_overlay:getShakeOffset()
end

function luna.render()
    luna.gfx.push()
    luna.gfx.translate(shake_x, shake_y)
    -- ... draw world ...
    luna.gfx.pop()

    -- draw flash overlay on top
    if fx_overlay:getFlashAlpha() > 0 then
        luna.gfx.setColor(1, 0, 0, fx_overlay:getFlashAlpha())
        luna.gfx.rectangle("fill", 0, 0, luna.window.getWidth(), luna.window.getHeight())
        luna.gfx.setColor(1, 1, 1, 1)
    end
end
]]

-- ─── ImageEffect ───────────────────────────────────────────────────────────────

imageeffect:clearEffects()  -- Removes all effects from the chain
local clone = imageeffect:clone()  -- Returns a deep copy of this ImageEffect chain
local effect_count = imageeffect:effectCount()  -- Returns the number of effects in the chain
local remove_effect = imageeffect:removeEffect(1)  -- Removes the effect at the given 1-based index or with the given type name
local save = imageeffect:save()  -- Stub: no-op serialisation placeholder
imageeffect:type()
imageeffect:typeOf("myName")

-- ─── Overlay ───────────────────────────────────────────────────────────────────

overlay:draw()  -- No-op placeholder; the overlay is rendered by the engine's draw pass
local ambient_color = overlay:getAmbientColor()  -- Returns the current ambient tint as r, g, b, a components
local cloud_count = overlay:getCloudCount()  -- Returns the current cloud shadow instance count
local cloud_opacity = overlay:getCloudOpacity()  -- Returns the current cloud shadow opacity
local cloud_scale = overlay:getCloudScale()  -- Returns the current cloud shadow scale
local cloud_speed = overlay:getCloudSpeed()  -- Returns the current cloud shadow scroll speed
local film_grain_intensity = overlay:getFilmGrainIntensity()  -- Returns the current film-grain intensity
local fog_color = overlay:getFogColor()  -- Returns the current fog tint as r, g, b, a components
local fog_density = overlay:getFogDensity()  -- Returns the current fog density
local heat_haze_intensity = overlay:getHeatHazeIntensity()  -- Returns the current heat-haze distortion intensity
local lightning_color = overlay:getLightningColor()  -- Returns the lightning flash tint as r, g, b, a components
local time_of_day = overlay:getTimeOfDay()  -- Returns the current simulated time-of-day (0–24)
local vignette_strength = overlay:getVignetteStrength()  -- Returns the current vignette strength
local weather = overlay:getWeather()  -- Returns the name of the current weather type
local weather_intensity = overlay:getWeatherIntensity()  -- Returns the current weather intensity
local wind_direction = overlay:getWindDirection()  -- Returns the current wind direction in radians
local wind_speed = overlay:getWindSpeed()  -- Returns the current wind speed
local is_ambient_enabled = overlay:isAmbientEnabled()  -- Returns whether the ambient light layer is active
local is_cloud_shadows_enabled = overlay:isCloudShadowsEnabled()  -- Returns whether cloud shadows are active
local is_fading = overlay:isFading()  -- Returns true while a fade effect is in progress
local is_film_grain_enabled = overlay:isFilmGrainEnabled()  -- Returns whether the film-grain layer is active
local is_flashing = overlay:isFlashing()  -- Returns true while a flash effect is in progress
local is_fog_enabled = overlay:isFogEnabled()  -- Returns whether the fog layer is active
local is_heat_haze_enabled = overlay:isHeatHazeEnabled()  -- Returns whether the heat-haze layer is active
local is_shaking = overlay:isShaking()  -- Returns true while a shake effect is in progress
local is_vignette_enabled = overlay:isVignetteEnabled()  -- Returns whether the vignette layer is active
local is_weather_enabled = overlay:isWeatherEnabled()  -- Returns whether the weather particle system is active
overlay:setAmbientEnabled(false)  -- Enables or disables the ambient light layer
overlay:setCloudCount(1)  -- Sets the number of cloud shadow instances to render
overlay:setCloudOpacity(1.0)  -- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark)
overlay:setCloudScale(1.0)  -- Sets the scale multiplier applied to each cloud shadow
overlay:setCloudShadows(false)  -- Enables or disables scrolling cloud-shadow projection
overlay:setCloudSpeed(1.0)  -- Sets the horizontal scroll speed of cloud shadows in pixels per second
overlay:setFilmGrainEnabled(false)  -- Enables or disables the film-grain noise layer
overlay:setFilmGrainIntensity(1.0)  -- Sets the film-grain noise intensity (0.0–1.0)
overlay:setFogDensity(1.0)  -- Sets the fog density (0.0 = clear, 1.0 = fully opaque)
overlay:setFogEnabled(false)  -- Enables or disables the fog layer
overlay:setHeatHazeEnabled(false)  -- Enables or disables the heat-haze distortion layer
overlay:setHeatHazeIntensity(1.0)  -- Sets the heat-haze distortion intensity (0.0–1.0)
overlay:setTimeOfDay(1.0)  -- Sets the simulated time-of-day (0–24) which drives ambient colour
overlay:setVignetteEnabled(false)  -- Enables or disables the screen-edge vignette layer
overlay:setVignetteStrength(1.0)  -- Sets the vignette darkening strength (0.0–1.0)
overlay:setWeather("name")  -- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen")
overlay:setWeatherEnabled(false)  -- Enables or disables the weather particle system
overlay:setWeatherIntensity(1.0)  -- Sets the particle spawn rate multiplier (0.0–1.0)
overlay:setWindDirection(1.0)  -- Sets the wind direction in radians (0 = right, π/2 = down)
overlay:setWindSpeed(1.0)  -- Sets the wind speed applied to weather particles in units per second
local overlay_type = overlay:type()  -- "Overlay"
local overlay_is_type = overlay:typeOf("Overlay")  -- Returns true if this object is of the given type ("Object" or "Overlay")

-- ─── PostFxEffect ──────────────────────────────────────────────────────────────

local effect_type = postfxeffect:getEffectType()  -- Returns the type name of this effect (alias for getTypeName)
local type_val = postfxeffect:getType()  -- Returns the type name of this effect (alias for getTypeName)
postfxeffect:setBrightness(true)
postfxeffect:setContrast(true)
postfxeffect:setIntensity(true)
postfxeffect:setOffset(true)
postfxeffect:setRadius(true)
postfxeffect:setSaturation(true)
postfxeffect:setScanlineStrength(true)
postfxeffect:setStrength(true)
postfxeffect:setThreshold(true)
postfxeffect:type()
postfxeffect:typeOf("myName")

-- ─── PostFxStack ───────────────────────────────────────────────────────────────

local is_capturing = postfxstack:isCapturing()  -- Returns whether the stack is currently capturing the scene
postfxstack:type()
postfxstack:typeOf("myName")

-- ─── luna.fx ───────────────────────────────────────────────────────────────────
local effect_types = luna.fx.getEffectTypes()  -- Returns the list of all built-in effect type names
local pass = luna.fx.newPass(1)  -- Creates a custom-shader post-processing effect (alias for newCustomEffect)
