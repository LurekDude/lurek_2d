-- examples/fx.lua
-- luna.postfx — Post-processing effects: stacking, per-image chains, screen overlays.
-- All luna.postfx API methods demonstrated with code and comments.

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
