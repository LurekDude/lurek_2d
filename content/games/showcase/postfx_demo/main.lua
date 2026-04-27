-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

-- ============================================================================
-- PostFX Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/postfx_demo/main.lua
-- Run with : cargo run -- content/games/showcase/postfx_demo
-- ============================================================================
-- Complete post-processing effects stacking showcase.  Toggle 10 effects by
-- key, stack them simultaneously, adjust intensity, and compare before/after.
-- Controls: B/U/C/V/A/P/S/G/I/F toggles, Tab cycle, +/- intensity,
--           Space compare, R reset, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, RUNNING = 2 }
local current_state = STATE.TITLE

-- Effect definitions: index, key name, display name, default intensity
local EFFECT_DEFS = {
    { key = "fx_bloom",     name = "Bloom",              default_int = 0.7 },
    { key = "fx_blur",      name = "Blur",               default_int = 0.5 },
    { key = "fx_crt",       name = "CRT",                default_int = 0.6 },
    { key = "fx_vignette",  name = "Vignette",           default_int = 0.8 },
    { key = "fx_chromatic", name = "Chromatic Aberr.",    default_int = 0.5 },
    { key = "fx_pixelate",  name = "Pixelate",           default_int = 0.6 },
    { key = "fx_sepia",     name = "Sepia",              default_int = 0.7 },
    { key = "fx_grayscale", name = "Grayscale",          default_int = 0.8 },
    { key = "fx_invert",    name = "Color Invert",       default_int = 1.0 },
    { key = "fx_grain",     name = "Film Grain",         default_int = 0.4 },
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local effects = {}          -- effects[i] = { enabled, intensity, target_intensity }
local selected_idx = 1      -- currently selected effect for intensity control
local compare_mode = false  -- true while Space held (bypass all effects)
---@type LCamera
local camera = nil
local title_timer = 0
local grain_seed = 0        -- rolling noise seed

-- Particles
---@type LParticleSystem
local toggle_particles = nil
---@type LParticleSystem
local sparkle_particles = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function lerp_color(r1, g1, b1, r2, g2, b2, t)
    return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t
end

local function count_active()
    local n = 0
    for i = 1, #effects do if effects[i].enabled then n = n + 1 end end
    return n
end

-- Find next active effect index (wrapping) for Tab cycling
local function next_active(from)
    for offset = 1, #effects do
        local idx = ((from - 1 + offset) % #effects) + 1
        if effects[idx].enabled then return idx end
    end
    return from
end

-- ---------------------------------------------------------------------------
-- Base scene drawing helpers  (always renders — the "before" image)
-- ---------------------------------------------------------------------------
local function draw_base_scene(time)
    -- Gradient background stripes
    for i = 0, 19 do
        local t = i / 20
        local r = 0.1 + 0.15 * math.sin(t * 3.14 + time * 0.3)
        local g = 0.12 + 0.1 * math.cos(t * 2.1 + time * 0.5)
        local b = 0.2 + 0.18 * math.sin(t * 4.0 + time * 0.4)
        lurek.render.setColor(r, g, b, 1)
        rect("fill", 0, i * 30, SCREEN_W, 30)
    end

    -- Rotating colorful squares (test for color transforms)
    local cx, cy = SCREEN_W / 2, SCREEN_H / 2
    local colors = {
        { 1.0, 0.2, 0.2 }, { 0.2, 1.0, 0.3 }, { 0.3, 0.3, 1.0 },
        { 1.0, 1.0, 0.2 }, { 1.0, 0.5, 0.0 }, { 0.8, 0.2, 1.0 },
    }
    for i, c in ipairs(colors) do
        local angle = time * 0.5 + (i - 1) * (6.2832 / #colors)
        local dist = 120 + 30 * math.sin(time * 1.2 + i)
        local sx = cx + math.cos(angle) * dist
        local sy = cy + math.sin(angle) * dist
        local sz = 30 + 10 * math.sin(time * 2 + i * 0.7)
        lurek.render.setColor(c[1], c[2], c[3], 0.9)
        rect("fill", sx - sz / 2, sy - sz / 2, sz, sz)
        lurek.render.setColor(1, 1, 1, 0.3)
        rect("line", sx - sz / 2, sy - sz / 2, sz, sz)
    end

    -- Central pulsing circle (bright — bloom test target)
    local pulse = 0.7 + 0.3 * math.sin(time * 3)
    lurek.render.setColor(1.0, 0.95, 0.8, pulse)
    circ("fill", cx, cy, 40 + 10 * math.sin(time * 2))
    lurek.render.setColor(1, 1, 1, 0.6)
    circ("line", cx, cy, 55)

    -- Grid of small dots (pixelation test target)
    for gx = 20, SCREEN_W - 20, 40 do
        for gy = 20, SCREEN_H - 20, 40 do
            local d = math.sqrt((gx - cx) ^ 2 + (gy - cy) ^ 2)
            local a = clamp(1.0 - d / 350, 0.05, 0.5)
            lurek.render.setColor(0.6, 0.7, 0.9, a)
            circ("fill", gx, gy, 2)
        end
    end

    -- Text label (for CRT/chromatic/blur readability test)
    lurek.render.setColor(1, 1, 1, 0.9)
    text_("LUREK2D POST-FX", cx - 100, 30, 24)
    lurek.render.setColor(0.7, 0.8, 1.0, 0.7)
    text_("Stacking Effects Engine", cx - 90, 60, 14)

    -- Horizontal rainbow bar (color transform test)
    local bar_y = SCREEN_H - 80
    for bx = 0, SCREEN_W - 1, 4 do
        local hue = bx / SCREEN_W
        local r = clamp(math.abs(hue * 6 - 3) - 1, 0, 1)
        local g = clamp(2 - math.abs(hue * 6 - 2), 0, 1)
        local b = clamp(2 - math.abs(hue * 6 - 4), 0, 1)
        lurek.render.setColor(r, g, b, 0.85)
        rect("fill", bx, bar_y, 4, 20)
    end
end

-- ---------------------------------------------------------------------------
-- Effect application helpers (simulated post-processing via draw tricks)
-- ---------------------------------------------------------------------------

local function apply_bloom(intensity, time)
    -- Simulate bloom: bright additive rectangles at bright regions
    local cx, cy = SCREEN_W / 2, SCREEN_H / 2
    local glow = 0.08 * intensity
    for r = 1, 5 do
        local rad = 50 + r * 18
        lurek.render.setColor(1.0, 0.95, 0.8, glow / r)
        circ("fill", cx, cy, rad)
    end
    -- Bloom halos on the rotating squares
    local colors = {
        { 1.0, 0.2, 0.2 }, { 0.2, 1.0, 0.3 }, { 0.3, 0.3, 1.0 },
        { 1.0, 1.0, 0.2 }, { 1.0, 0.5, 0.0 }, { 0.8, 0.2, 1.0 },
    }
    for i, c in ipairs(colors) do
        local angle = time * 0.5 + (i - 1) * (6.2832 / #colors)
        local dist = 120 + 30 * math.sin(time * 1.2 + i)
        local sx = cx + math.cos(angle) * dist
        local sy = cy + math.sin(angle) * dist
        lurek.render.setColor(c[1], c[2], c[3], 0.05 * intensity)
        circ("fill", sx, sy, 35)
    end
end

local function apply_blur(intensity)
    -- Simulate blur: overlay semi-transparent rects offset ±1-2px
    local offsets = { -2, -1, 1, 2 }
    local alpha = 0.02 * intensity
    for _, ox in ipairs(offsets) do
        for _, oy in ipairs(offsets) do
            lurek.render.setColor(0.5, 0.5, 0.55, alpha)
            rect("fill", ox, oy, SCREEN_W, SCREEN_H)
        end
    end
end

local function apply_crt(intensity, time)
    -- Scanlines
    local line_alpha = 0.12 * intensity
    for y = 0, SCREEN_H - 1, 3 do
        lurek.render.setColor(0, 0, 0, line_alpha)
        rect("fill", 0, y, SCREEN_W, 1)
    end
    -- Slight barrel curvature simulation (darkened edges)
    local cx, cy = SCREEN_W / 2, SCREEN_H / 2
    local max_dist = math.sqrt(cx * cx + cy * cy)
    local steps = 8
    for s = 0, steps - 1 do
        local t = s / steps
        local inset = t * 40 * intensity
        local alpha = t * t * 0.15 * intensity
        lurek.render.setColor(0, 0, 0, alpha)
        rect("fill", 0, 0, inset, SCREEN_H)
        rect("fill", SCREEN_W - inset, 0, inset, SCREEN_H)
        rect("fill", 0, 0, SCREEN_W, inset * 0.6)
        rect("fill", 0, SCREEN_H - inset * 0.6, SCREEN_W, inset * 0.6)
    end
    -- Color fringing (red/blue offset lines)
    local fringe = 1.5 * intensity
    lurek.render.setColor(1, 0, 0, 0.03 * intensity)
    rect("fill", -fringe, 0, SCREEN_W, SCREEN_H)
    lurek.render.setColor(0, 0, 1, 0.03 * intensity)
    rect("fill", fringe, 0, SCREEN_W, SCREEN_H)
end

local function apply_vignette(intensity)
    -- Radial darkening from edges
    local cx, cy = SCREEN_W / 2, SCREEN_H / 2
    local rings = 12
    for r = 0, rings - 1 do
        local t = r / rings
        local outer = math.sqrt(cx * cx + cy * cy) * (1.0 - t * 0.08)
        local inset = t * 60 * intensity
        local alpha = t * t * 0.08 * intensity
        lurek.render.setColor(0, 0, 0, alpha)
        -- Draw darkening borders
        rect("fill", 0, 0, inset, SCREEN_H)
        rect("fill", SCREEN_W - inset, 0, inset, SCREEN_H)
        rect("fill", 0, 0, SCREEN_W, inset * 0.75)
        rect("fill", 0, SCREEN_H - inset * 0.75, SCREEN_W, inset * 0.75)
    end
    -- Corner darkening (extra)
    local corner = 100 * intensity
    lurek.render.setColor(0, 0, 0, 0.15 * intensity)
    circ("fill", 0, 0, corner)
    circ("fill", SCREEN_W, 0, corner)
    circ("fill", 0, SCREEN_H, corner)
    circ("fill", SCREEN_W, SCREEN_H, corner)
end

local function apply_chromatic(intensity, time)
    -- Red/green/blue channel offsets
    local offset = 3 * intensity
    lurek.render.setColor(1, 0, 0, 0.06 * intensity)
    rect("fill", -offset, -offset * 0.5, SCREEN_W, SCREEN_H)
    lurek.render.setColor(0, 1, 0, 0.04 * intensity)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H)
    lurek.render.setColor(0, 0, 1, 0.06 * intensity)
    rect("fill", offset, offset * 0.5, SCREEN_W, SCREEN_H)
end

local function apply_pixelate(intensity)
    -- Draw a grid overlay that simulates lower resolution
    local block = math.floor(4 + intensity * 12)  -- 4px to 16px blocks
    local alpha = 0.25 * intensity
    lurek.render.setColor(0, 0, 0, alpha * 0.4)
    -- Vertical grid lines
    for gx = 0, SCREEN_W, block do
        ln(gx, 0, gx, SCREEN_H)
    end
    -- Horizontal grid lines
    for gy = 0, SCREEN_H, block do
        ln(0, gy, SCREEN_W, gy)
    end
    -- Fill alternating blocks for mosaic impression
    for gx = 0, SCREEN_W - 1, block * 2 do
        for gy = 0, SCREEN_H - 1, block * 2 do
            lurek.render.setColor(0, 0, 0, alpha * 0.15)
            rect("fill", gx, gy, block, block)
        end
    end
end

local function apply_sepia(intensity)
    -- Warm brown tone overlay
    lurek.render.setColor(0.45, 0.32, 0.18, 0.18 * intensity)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H)
    -- Slight yellow highlight
    lurek.render.setColor(0.6, 0.5, 0.3, 0.06 * intensity)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H / 2)
end

local function apply_grayscale(intensity)
    -- Desaturation overlay: neutral gray wash
    lurek.render.setColor(0.3, 0.3, 0.3, 0.3 * intensity)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H)
end

local function apply_invert(intensity)
    -- Simulated inversion: bright white overlay with subtractive hints
    lurek.render.setColor(1, 1, 1, 0.2 * intensity)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H)
    -- Dark contrast bars
    lurek.render.setColor(0, 0, 0, 0.08 * intensity)
    for y = 0, SCREEN_H - 1, 6 do
        rect("fill", 0, y, SCREEN_W, 2)
    end
end

local function apply_grain(intensity, seed)
    -- Random noise dots
    local count = math.floor(200 * intensity)
    for i = 1, count do
        -- Deterministic-ish pseudo-random from seed+i
        local rx = ((seed * 1103515245 + i * 12345) % SCREEN_W)
        local ry = ((seed * 6364136223846793005 + i * 1442695040888963407) % SCREEN_H)
        -- Ensure positive
        if rx < 0 then rx = -rx end
        if ry < 0 then ry = -ry end
        rx = rx % SCREEN_W
        ry = ry % SCREEN_H
        local bright = ((seed + i * 7) % 100) / 100
        lurek.render.setColor(bright, bright, bright, 0.12 * intensity)
        rect("fill", rx, ry, 2, 2)
    end
end

-- Dispatch table
local EFFECT_APPLY = {}
EFFECT_APPLY[1]  = function(int, time) apply_bloom(int, time) end
EFFECT_APPLY[2]  = function(int)       apply_blur(int) end
EFFECT_APPLY[3]  = function(int, time) apply_crt(int, time) end
EFFECT_APPLY[4]  = function(int)       apply_vignette(int) end
EFFECT_APPLY[5]  = function(int, time) apply_chromatic(int, time) end
EFFECT_APPLY[6]  = function(int)       apply_pixelate(int) end
EFFECT_APPLY[7]  = function(int)       apply_sepia(int) end
EFFECT_APPLY[8]  = function(int)       apply_grayscale(int) end
EFFECT_APPLY[9]  = function(int)       apply_invert(int) end
EFFECT_APPLY[10] = function(int, _, s) apply_grain(int, s) end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("PostFX Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.15)

    -- Input bindings (effect toggles)
    lurek.input.bind("fx_bloom",     { "b" })
    lurek.input.bind("fx_blur",      { "u" })
    lurek.input.bind("fx_crt",       { "c" })
    lurek.input.bind("fx_vignette",  { "v" })
    lurek.input.bind("fx_chromatic", { "a" })
    lurek.input.bind("fx_pixelate",  { "p" })
    lurek.input.bind("fx_sepia",     { "s" })
    lurek.input.bind("fx_grayscale", { "g" })
    lurek.input.bind("fx_invert",    { "i" })
    lurek.input.bind("fx_grain",     { "f" })

    -- Control bindings
    lurek.input.bind("reset",        { "r" })
    lurek.input.bind("compare",      { "space" })
    lurek.input.bind("cycle_fx",     { "tab" })
    lurek.input.bind("intensity_up", { "equal" })
    lurek.input.bind("intensity_dn", { "minus" })
    lurek.input.bind("quit",         { "escape" })
    lurek.input.bind("start",        { "return" })

    -- Camera
    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Initialize effect states
    for i, def in ipairs(EFFECT_DEFS) do
        effects[i] = {
            enabled          = false,
            intensity        = def.default_int,
            target_intensity = def.default_int,
        }
    end

    -- Toggle flash particles (burst on effect toggle)
    toggle_particles = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0,
        lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 60, speedMax = 160,
        direction = -1.57, spread = 6.28,
        gravityY = 40,
        sizes = { 5, 3, 1, 0 },
        colors = { 0.3, 1.0, 0.5, 1,  0.1, 0.8, 0.3, 0 },
    })

    -- Intensity change sparkle particles
    sparkle_particles = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 0,
        lifetimeMin = 0.15, lifetimeMax = 0.4,
        speedMin = 30, speedMax = 80,
        direction = 0, spread = 6.28,
        sizes = { 3, 2, 0 },
        colors = { 1, 1, 0.5, 0.9,  1, 0.8, 0.2, 0 },
    })
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
local function _ready_setup()
    -- nothing extra
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Quit
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Update subsystems
    lurek.tween.update(dt)
    toggle_particles:update(dt)
    sparkle_particles:update(dt)

    -- Advance grain seed
    grain_seed = grain_seed + 1

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        title_timer = title_timer + dt
        if lurek.input.wasActionPressed("start") then
            current_state = STATE.RUNNING
        end
        return
    end

    -- ── RUNNING ───────────────────────────────────────────────

    -- Compare mode (hold Space)
    compare_mode = lurek.input.isActionDown("compare")

    -- Toggle effects
    for i, def in ipairs(EFFECT_DEFS) do
        if lurek.input.wasActionPressed(def.key) then
            effects[i].enabled = not effects[i].enabled
            -- Burst particles at the HUD indicator position
            local px = SCREEN_W - 195
            local py = 14 + (i - 1) * 18
            toggle_particles:moveTo(px, py)
            toggle_particles:emit(12)
            -- Auto-select this effect for intensity editing
            if effects[i].enabled then selected_idx = i end
        end
    end

    -- Tab: cycle selected effect among active ones
    if lurek.input.wasActionPressed("cycle_fx") then
        selected_idx = next_active(selected_idx)
    end

    -- Intensity +/-
    if lurek.input.wasActionPressed("intensity_up") then
        local e = effects[selected_idx]
        if e.enabled then
            e.target_intensity = clamp(e.target_intensity + 0.1, 0.1, 1.0)
            lurek.tween.to(e, { intensity = e.target_intensity }, 0.25, "inOutSine")
            sparkle_particles:moveTo(SCREEN_W - 195, 14 + (selected_idx - 1) * 18)
            sparkle_particles:emit(8)
        end
    end
    if lurek.input.wasActionPressed("intensity_dn") then
        local e = effects[selected_idx]
        if e.enabled then
            e.target_intensity = clamp(e.target_intensity - 0.1, 0.1, 1.0)
            lurek.tween.to(e, { intensity = e.target_intensity }, 0.25, "inOutSine")
            sparkle_particles:moveTo(SCREEN_W - 195, 14 + (selected_idx - 1) * 18)
            sparkle_particles:emit(8)
        end
    end

    -- Reset all
    if lurek.input.wasActionPressed("reset") then
        for i, def in ipairs(EFFECT_DEFS) do
            effects[i].enabled = false
            effects[i].target_intensity = def.default_int
            lurek.tween.to(effects[i], { intensity = def.default_int }, 0.3, "inOutSine")
        end
        selected_idx = 1
    end
end

-- ---------------------------------------------------------------------------
-- Render (world space — base scene + effects overlay)
-- ---------------------------------------------------------------------------
function lurek.draw()
    camera:attach()

    local time = lurek.timer.getTime()

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        -- Animated demo of effects in background
        draw_base_scene(title_timer)
        -- Overlay a cycling effect preview
        local preview_idx = (math.floor(title_timer / 2) % #EFFECT_APPLY) + 1
        local fn = EFFECT_APPLY[preview_idx]
        if fn then fn(0.5, title_timer, math.floor(title_timer * 10)) end
        camera:detach()
        return
    end

    -- ── RUNNING ───────────────────────────────────────────────

    -- Always draw the base scene
    draw_base_scene(time)

    -- Apply stacked effects (unless compare mode)
    if not compare_mode then
        for i = 1, #effects do
            if effects[i].enabled then
                local fn = EFFECT_APPLY[i]
                if fn then fn(effects[i].intensity, time, grain_seed) end
            end
        end
    end

    -- Particle systems (world space)
    lurek.render.setColor(1, 1, 1, 1)
    toggle_particles:render()
    sparkle_particles:render()

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space — HUD, effect list, controls)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    local time = lurek.timer.getTime()

    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        -- Title
        lurek.render.setColor(0.4, 0.9, 1.0, 1)
        text_("POSTFX DEMO", SCREEN_W / 2 - 100, SCREEN_H / 2 - 80, 32)

        -- Subtitle
        lurek.render.setColor(0.7, 0.8, 0.9, 1)
        text_("STACK YOUR EFFECTS", SCREEN_W / 2 - 85, SCREEN_H / 2 - 30, 18)

        -- Blink prompt
        local blink = 0.5 + 0.5 * math.sin(time * 4)
        lurek.render.setColor(1, 1, 1, blink)
        text_("Press Enter to Start", SCREEN_W / 2 - 90, SCREEN_H / 2 + 40, 16)

        -- Engine credit
        lurek.render.setColor(0.4, 0.4, 0.4, 0.5)
        text_("Lurek2D Engine Showcase", SCREEN_W / 2 - 80, SCREEN_H - 40, 12)
        return
    end

    -- ── RUNNING HUD ───────────────────────────────────────────

    -- FPS (top-left)
    lurek.render.setColor(0.0, 0.0, 0.0, 0.4)
    rect("fill", 8, 8, 90, 20)
    lurek.render.setColor(0.8, 0.8, 0.8, 0.8)
    text_(string.format("FPS: %d", lurek.timer.getFPS()), 14, 10, 14)

    -- Effect list panel (right side)
    local panel_x = SCREEN_W - 210
    local panel_y = 8
    local panel_w = 200
    local panel_h = #EFFECT_DEFS * 18 + 28
    lurek.render.setColor(0.0, 0.0, 0.0, 0.55)
    rect("fill", panel_x, panel_y, panel_w, panel_h)
    lurek.render.setColor(0.3, 0.7, 0.9, 0.4)
    rect("line", panel_x, panel_y, panel_w, panel_h)

    -- Panel header
    local active_count = count_active()
    lurek.render.setColor(0.5, 0.9, 1.0, 1)
    text_("EFFECTS (" .. active_count .. " active)", panel_x + 6, panel_y + 4, 13)

    -- Effect entries
    local keys_display = { "B", "U", "C", "V", "A", "P", "S", "G", "I", "F" }
    for i, def in ipairs(EFFECT_DEFS) do
        local e = effects[i]
        local ey = panel_y + 22 + (i - 1) * 18
        local is_selected = (i == selected_idx)

        -- Selection highlight
        if is_selected and e.enabled then
            lurek.render.setColor(0.2, 0.5, 0.7, 0.2)
            rect("fill", panel_x + 2, ey - 1, panel_w - 4, 17)
        end

        -- Status indicator (green dot / gray dot)
        if e.enabled then
            lurek.render.setColor(0.2, 1.0, 0.4, 1)
        else
            lurek.render.setColor(0.3, 0.3, 0.3, 0.5)
        end
        circ("fill", panel_x + 12, ey + 6, 4)

        -- Key label
        lurek.render.setColor(0.9, 0.8, 0.3, e.enabled and 1 or 0.4)
        text_("[" .. keys_display[i] .. "]", panel_x + 20, ey, 12)

        -- Effect name
        if e.enabled then
            lurek.render.setColor(1, 1, 1, 1)
        else
            lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
        end
        text_(def.name, panel_x + 46, ey, 12)

        -- Intensity bar (only for enabled effects)
        if e.enabled then
            local bar_x = panel_x + 145
            local bar_w = 45
            local bar_h = 8
            lurek.render.setColor(0.2, 0.2, 0.2, 0.6)
            rect("fill", bar_x, ey + 2, bar_w, bar_h)
            lurek.render.setColor(0.3, 0.8, 0.5, 0.9)
            rect("fill", bar_x, ey + 2, bar_w * e.intensity, bar_h)
            lurek.render.setColor(0.5, 1.0, 0.7, 0.5)
            rect("line", bar_x, ey + 2, bar_w, bar_h)
        end
    end

    -- Compare indicator
    if compare_mode then
        lurek.render.setColor(1.0, 0.3, 0.3, 0.8 + 0.2 * math.sin(time * 8))
        text_("[ ORIGINAL — NO FX ]", SCREEN_W / 2 - 80, SCREEN_H / 2 - 10, 18)
    end

    -- Controls bar (bottom)
    lurek.render.setColor(0.0, 0.0, 0.0, 0.45)
    rect("fill", 8, SCREEN_H - 58, SCREEN_W - 16, 50)

    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    text_("B/U/C/V/A/P/S/G/I/F: Toggle FX   Tab: Select FX   +/-: Intensity", 14, SCREEN_H - 52, 12)
    text_("Space: Compare (hold)   R: Reset All   Esc: Quit", 14, SCREEN_H - 36, 12)

    -- Selected effect label (bottom-right)
    if effects[selected_idx].enabled then
        lurek.render.setColor(0.3, 0.9, 0.6, 0.8)
        text_("Editing: " .. EFFECT_DEFS[selected_idx].name, SCREEN_W - 200, SCREEN_H - 36, 12)
    end
end
