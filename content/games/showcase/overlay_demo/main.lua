-- ============================================================================
-- Overlay Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/overlay_demo/main.lua
-- Run with : cargo run -- content/games/showcase/overlay_demo
-- ============================================================================
-- Screen overlay effects showcase: weather particles, time-of-day tinting,
-- fog, and vignette. All composable with adjustable intensity.
-- Controls: 1-7 weather, T time, F fog, V vignette, +/- intensity, C clear
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local GROUND_Y   = 460
local SKY_TOP     = 0
local TREE_COUNT  = 8
local SUN_X, SUN_Y, SUN_R = 650, 80, 40

local STATE = { TITLE = 1, RUNNING = 2 }
local current_state = STATE.TITLE
local title_timer   = 0

-- ---------------------------------------------------------------------------
-- Time-of-day definitions
-- ---------------------------------------------------------------------------
local TOD_DAWN  = 1
local TOD_DAY   = 2
local TOD_DUSK  = 3
local TOD_NIGHT = 4
local TOD_NAMES = { "Dawn", "Day", "Dusk", "Night" }
local TOD_COLORS = {
    [TOD_DAWN]  = { r = 0.95, g = 0.55, b = 0.25, a = 0.35 },
    [TOD_DAY]   = { r = 0.0,  g = 0.0,  b = 0.0,  a = 0.0  },
    [TOD_DUSK]  = { r = 0.50, g = 0.20, b = 0.55, a = 0.30 },
    [TOD_NIGHT] = { r = 0.05, g = 0.05, b = 0.20, a = 0.55 },
}
local TOD_BG = {
    [TOD_DAWN]  = { 0.85, 0.50, 0.30 },
    [TOD_DAY]   = { 0.40, 0.65, 0.90 },
    [TOD_DUSK]  = { 0.35, 0.18, 0.40 },
    [TOD_NIGHT] = { 0.05, 0.05, 0.12 },
}
local current_tod   = TOD_DAY
local tod_tween     = { r = 0.0, g = 0.0, b = 0.0, a = 0.0 }
local bg_tween      = { r = 0.40, g = 0.65, b = 0.90 }

-- ---------------------------------------------------------------------------
-- Weather overlays
-- ---------------------------------------------------------------------------
local WEATHER = {
    { name = "Rain",   key = "weather1", active = false },
    { name = "Snow",   key = "weather2", active = false },
    { name = "Hail",   key = "weather3", active = false },
    { name = "Dust",   key = "weather4", active = false },
    { name = "Leaves", key = "weather5", active = false },
    { name = "Ash",    key = "weather6", active = false },
    { name = "Pollen", key = "weather7", active = false },
}
local weather_ps = {}

-- Fog & vignette
local fog_active      = false
local vignette_active = false
local fog_ps          = nil

-- Intensity
local intensity       = { val = 0.6 }
local INTENSITY_MIN   = 0.1
local INTENSITY_MAX   = 1.0
local INTENSITY_STEP  = 0.1

-- ---------------------------------------------------------------------------
-- Scenery: trees
-- ---------------------------------------------------------------------------
local trees = {}
for i = 1, TREE_COUNT do
    trees[i] = {
        x = 40 + (i - 1) * 100 + math.random(-20, 20),
        h = 60 + math.random(0, 50),
        w = 20 + math.random(0, 10),
        crown = 30 + math.random(0, 20),
        green = { 0.15 + math.random() * 0.2, 0.45 + math.random() * 0.3, 0.10 + math.random() * 0.15 },
    }
end

-- ---------------------------------------------------------------------------
-- FPS tracking
-- ---------------------------------------------------------------------------
local fps = 0
local fps_timer = 0
local fps_count = 0

-- ---------------------------------------------------------------------------
-- Particle system configs
-- ---------------------------------------------------------------------------
local function make_rain_ps()
    return lurek.particles.newSystem({
        emitRate = 120, lifetime = { 0.6, 1.2 },
        x = SCREEN_W / 2, y = -20,
        spread = SCREEN_W, angle = 1.7,
        speed = { 350, 500 }, size = { 1, 2 },
        color = { 0.5, 0.6, 0.9, 0.7 },
    })
end

local function make_snow_ps()
    return lurek.particles.newSystem({
        emitRate = 50, lifetime = { 2.0, 4.0 },
        x = SCREEN_W / 2, y = -10,
        spread = SCREEN_W, angle = 1.57,
        speed = { 30, 70 }, size = { 2, 4 },
        color = { 1.0, 1.0, 1.0, 0.8 },
    })
end

local function make_hail_ps()
    return lurek.particles.newSystem({
        emitRate = 40, lifetime = { 0.4, 0.8 },
        x = SCREEN_W / 2, y = -15,
        spread = SCREEN_W, angle = 1.6,
        speed = { 400, 600 }, size = { 3, 5 },
        color = { 0.7, 0.7, 0.75, 0.9 },
    })
end

local function make_dust_ps()
    return lurek.particles.newSystem({
        emitRate = 35, lifetime = { 1.5, 3.0 },
        x = -20, y = SCREEN_H / 2,
        spread = SCREEN_H * 0.6, angle = 0.0,
        speed = { 80, 160 }, size = { 1, 3 },
        color = { 0.82, 0.72, 0.50, 0.5 },
    })
end

local function make_leaves_ps()
    return lurek.particles.newSystem({
        emitRate = 18, lifetime = { 2.0, 4.5 },
        x = SCREEN_W / 2, y = -10,
        spread = SCREEN_W, angle = 1.57,
        speed = { 20, 60 }, size = { 3, 6 },
        color = { 0.85, 0.55, 0.15, 0.7 },
    })
end

local function make_ash_ps()
    return lurek.particles.newSystem({
        emitRate = 25, lifetime = { 3.0, 5.0 },
        x = SCREEN_W / 2, y = -10,
        spread = SCREEN_W, angle = 1.57,
        speed = { 15, 35 }, size = { 1, 2 },
        color = { 0.55, 0.55, 0.55, 0.5 },
    })
end

local function make_pollen_ps()
    return lurek.particles.newSystem({
        emitRate = 20, lifetime = { 3.0, 5.0 },
        x = SCREEN_W / 2, y = SCREEN_H + 10,
        spread = SCREEN_W, angle = -1.57,
        speed = { 10, 30 }, size = { 2, 3 },
        color = { 0.95, 0.90, 0.30, 0.6 },
    })
end

local function make_fog_ps()
    return lurek.particles.newSystem({
        emitRate = 12, lifetime = { 4.0, 7.0 },
        x = SCREEN_W / 2, y = SCREEN_H - 60,
        spread = SCREEN_W, angle = -1.57,
        speed = { 5, 15 }, size = { 20, 50 },
        color = { 1.0, 1.0, 1.0, 0.15 },
    })
end

local PS_FACTORIES = {
    make_rain_ps, make_snow_ps, make_hail_ps,
    make_dust_ps, make_leaves_ps, make_ash_ps, make_pollen_ps,
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function active_overlay_count()
    local n = 0
    for i = 1, #WEATHER do
        if WEATHER[i].active then n = n + 1 end
    end
    if fog_active then n = n + 1 end
    if vignette_active then n = n + 1 end
    if current_tod ~= TOD_DAY then n = n + 1 end
    return n
end

local function transition_tod(tod)
    current_tod = tod
    local c = TOD_COLORS[tod]
    lurek.tween.to(tod_tween, 1.2, { r = c.r, g = c.g, b = c.b, a = c.a }, "inOutSine")
    local bg = TOD_BG[tod]
    lurek.tween.to(bg_tween, 1.2, { r = bg[1], g = bg[2], b = bg[3] }, "inOutSine")
end

local function clear_all()
    for i = 1, #WEATHER do
        WEATHER[i].active = false
        if weather_ps[i] then
            weather_ps[i]:stop()
        end
    end
    fog_active = false
    vignette_active = false
    if fog_ps then fog_ps:stop() end
    current_tod = TOD_DAY
    transition_tod(TOD_DAY)
end

-- ---------------------------------------------------------------------------
-- lurek.init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Overlay Demo — Lurek2D")
    lurek.gfx.setBackgroundColor(0.40, 0.65, 0.90)

    -- Input bindings
    lurek.input.bind("weather1", "1")
    lurek.input.bind("weather2", "2")
    lurek.input.bind("weather3", "3")
    lurek.input.bind("weather4", "4")
    lurek.input.bind("weather5", "5")
    lurek.input.bind("weather6", "6")
    lurek.input.bind("weather7", "7")
    lurek.input.bind("time_cycle", "t")
    lurek.input.bind("fog_toggle", "f")
    lurek.input.bind("vignette_toggle", "v")
    lurek.input.bind("intensity_up", {"=", "+"})
    lurek.input.bind("intensity_down", "-")
    lurek.input.bind("clear_all", "c")
    lurek.input.bind("quit", "escape")
    lurek.input.bind("start", {"space", "return"})

    -- Create weather particle systems (stopped initially)
    for i = 1, #PS_FACTORIES do
        weather_ps[i] = PS_FACTORIES[i]()
        weather_ps[i]:stop()
    end

    -- Fog particles
    fog_ps = make_fog_ps()
    fog_ps:stop()

    -- Camera
    lurek.camera.attach()
end

-- ---------------------------------------------------------------------------
-- lurek.process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- FPS
    fps_count = fps_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    -- Title screen
    if current_state == STATE.TITLE then
        title_timer = title_timer + dt
        if lurek.input.pressed("start") then
            current_state = STATE.RUNNING
        end
        return
    end

    -- Quit
    if lurek.input.pressed("quit") then
        lurek.signal.quit()
        return
    end

    -- Weather toggles (1-7)
    for i = 1, #WEATHER do
        if lurek.input.pressed(WEATHER[i].key) then
            WEATHER[i].active = not WEATHER[i].active
            if WEATHER[i].active then
                weather_ps[i]:start()
            else
                weather_ps[i]:stop()
            end
        end
    end

    -- Time of day cycle
    if lurek.input.pressed("time_cycle") then
        local next_tod = (current_tod % 4) + 1
        transition_tod(next_tod)
    end

    -- Fog toggle
    if lurek.input.pressed("fog_toggle") then
        fog_active = not fog_active
        if fog_active then fog_ps:start() else fog_ps:stop() end
    end

    -- Vignette toggle
    if lurek.input.pressed("vignette_toggle") then
        vignette_active = not vignette_active
    end

    -- Intensity +/-
    if lurek.input.pressed("intensity_up") then
        local target = clamp(intensity.val + INTENSITY_STEP, INTENSITY_MIN, INTENSITY_MAX)
        lurek.tween.to(intensity, 0.2, { val = target }, "outQuad")
    end
    if lurek.input.pressed("intensity_down") then
        local target = clamp(intensity.val - INTENSITY_STEP, INTENSITY_MIN, INTENSITY_MAX)
        lurek.tween.to(intensity, 0.2, { val = target }, "outQuad")
    end

    -- Clear all
    if lurek.input.pressed("clear_all") then
        clear_all()
    end

    -- Update particle systems
    for i = 1, #weather_ps do
        if WEATHER[i].active then
            weather_ps[i]:update(dt)
        end
    end
    if fog_active then fog_ps:update(dt) end

    -- Dynamic background color
    lurek.gfx.setBackgroundColor(bg_tween.r, bg_tween.g, bg_tween.b)

    -- Dynamic title
    local n = active_overlay_count()
    local suffix = n > 0 and (" [" .. n .. " active]") or ""
    lurek.window.setTitle("Overlay Demo" .. suffix)
end

-- ---------------------------------------------------------------------------
-- lurek.render — scene + overlays (camera-space)
-- ---------------------------------------------------------------------------
function lurek.render()
    if current_state == STATE.TITLE then
        -- Title screen
        local pulse = 0.7 + 0.3 * math.sin(title_timer * 2.5)
        lurek.gfx.setColor(1.0, 1.0, 1.0, 1.0)
        lurek.gfx.print("OVERLAY DEMO", SCREEN_W / 2 - 120, SCREEN_H / 2 - 60, 32)
        lurek.gfx.setColor(0.8, 0.85, 1.0, 0.8)
        lurek.gfx.print("WEATHER & ATMOSPHERE", SCREEN_W / 2 - 130, SCREEN_H / 2 - 15, 18)
        lurek.gfx.setColor(1.0, 1.0, 1.0, pulse)
        lurek.gfx.print("Press SPACE to start", SCREEN_W / 2 - 95, SCREEN_H / 2 + 50, 14)
        return
    end

    -- ── Base scene ────────────────────────────────────────────
    -- Sky is the background color (set in process)

    -- Sun
    local sun_alpha = 1.0
    if current_tod == TOD_NIGHT then sun_alpha = 0.15
    elseif current_tod == TOD_DUSK then sun_alpha = 0.5
    elseif current_tod == TOD_DAWN then sun_alpha = 0.7 end
    lurek.gfx.setColor(1.0, 0.92, 0.40, sun_alpha)
    lurek.gfx.circle("fill", SUN_X, SUN_Y, SUN_R)
    -- Sun glow
    lurek.gfx.setColor(1.0, 0.95, 0.60, sun_alpha * 0.25)
    lurek.gfx.circle("fill", SUN_X, SUN_Y, SUN_R * 1.8)

    -- Trees
    for _, t in ipairs(trees) do
        -- Trunk
        lurek.gfx.setColor(0.40, 0.25, 0.12, 1.0)
        lurek.gfx.rectangle("fill", t.x - 4, GROUND_Y - t.h, 8, t.h)
        -- Crown
        lurek.gfx.setColor(t.green[1], t.green[2], t.green[3], 1.0)
        lurek.gfx.circle("fill", t.x, GROUND_Y - t.h - t.crown * 0.4, t.crown)
    end

    -- Ground
    lurek.gfx.setColor(0.22, 0.55, 0.18, 1.0)
    lurek.gfx.rectangle("fill", 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y)
    -- Ground detail
    lurek.gfx.setColor(0.18, 0.48, 0.15, 1.0)
    lurek.gfx.rectangle("fill", 0, GROUND_Y, SCREEN_W, 4)

    -- ── Weather particle overlays ─────────────────────────────
    local alpha_mult = intensity.val
    for i = 1, #weather_ps do
        if WEATHER[i].active then
            weather_ps[i]:draw(alpha_mult)
        end
    end

    -- ── Fog overlay ───────────────────────────────────────────
    if fog_active then
        fog_ps:draw(alpha_mult)
        -- Gradient fog band at bottom
        for row = 0, 5 do
            local a = (1.0 - row / 6.0) * 0.35 * alpha_mult
            lurek.gfx.setColor(0.90, 0.92, 0.95, a)
            lurek.gfx.rectangle("fill", 0, SCREEN_H - 120 + row * 20, SCREEN_W, 20)
        end
    end

    -- ── Time-of-day tint overlay ──────────────────────────────
    if tod_tween.a > 0.01 then
        lurek.gfx.setColor(tod_tween.r, tod_tween.g, tod_tween.b, tod_tween.a * alpha_mult)
        lurek.gfx.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    -- ── Vignette overlay ──────────────────────────────────────
    if vignette_active then
        local vig_a = 0.6 * alpha_mult
        -- Top
        for row = 0, 4 do
            local a = (1.0 - row / 5.0) * vig_a
            lurek.gfx.setColor(0, 0, 0, a)
            lurek.gfx.rectangle("fill", 0, row * 24, SCREEN_W, 24)
        end
        -- Bottom
        for row = 0, 4 do
            local a = (1.0 - row / 5.0) * vig_a
            lurek.gfx.setColor(0, 0, 0, a)
            lurek.gfx.rectangle("fill", 0, SCREEN_H - (row + 1) * 24, SCREEN_W, 24)
        end
        -- Left
        for col = 0, 3 do
            local a = (1.0 - col / 4.0) * vig_a * 0.6
            lurek.gfx.setColor(0, 0, 0, a)
            lurek.gfx.rectangle("fill", col * 30, 0, 30, SCREEN_H)
        end
        -- Right
        for col = 0, 3 do
            local a = (1.0 - col / 4.0) * vig_a * 0.6
            lurek.gfx.setColor(0, 0, 0, a)
            lurek.gfx.rectangle("fill", SCREEN_W - (col + 1) * 30, 0, 30, SCREEN_H)
        end
    end
end

-- ---------------------------------------------------------------------------
-- lurek.render_ui — HUD and overlay list (screen-space)
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    if current_state == STATE.TITLE then return end

    lurek.camera.detach()

    -- Top bar background
    lurek.gfx.setColor(0, 0, 0, 0.55)
    lurek.gfx.rectangle("fill", 0, 0, SCREEN_W, 28)

    -- FPS
    lurek.gfx.setColor(0.7, 0.7, 0.7, 1.0)
    lurek.gfx.print("FPS: " .. fps, 10, 6, 12)

    -- Time of day
    lurek.gfx.setColor(1.0, 0.9, 0.6, 1.0)
    lurek.gfx.print("Time: " .. TOD_NAMES[current_tod] .. " [T]", 100, 6, 12)

    -- Intensity
    lurek.gfx.setColor(0.8, 0.8, 1.0, 1.0)
    lurek.gfx.print(string.format("Intensity: %.1f [+/-]", intensity.val), 280, 6, 12)

    -- Controls hint
    lurek.gfx.setColor(0.6, 0.6, 0.6, 1.0)
    lurek.gfx.print("1-7:Weather  F:Fog  V:Vignette  C:Clear", 470, 6, 11)

    -- ── Active overlay list (right side) ──────────────────────
    local list_x = SCREEN_W - 180
    local list_y = 40
    local count = 0

    lurek.gfx.setColor(0, 0, 0, 0.45)
    lurek.gfx.rectangle("fill", list_x - 8, list_y - 4, 185, 180)

    lurek.gfx.setColor(1.0, 1.0, 1.0, 0.9)
    lurek.gfx.print("Active Overlays:", list_x, list_y, 12)
    list_y = list_y + 18

    -- Weather entries
    local weather_colors = {
        { 0.5, 0.6, 0.9 },  -- Rain (blue)
        { 1.0, 1.0, 1.0 },  -- Snow (white)
        { 0.7, 0.7, 0.75 }, -- Hail (gray)
        { 0.82, 0.72, 0.50 }, -- Dust (tan)
        { 0.85, 0.55, 0.15 }, -- Leaves (orange)
        { 0.55, 0.55, 0.55 }, -- Ash (gray)
        { 0.95, 0.90, 0.30 }, -- Pollen (yellow)
    }

    for i = 1, #WEATHER do
        if WEATHER[i].active then
            local wc = weather_colors[i]
            lurek.gfx.setColor(wc[1], wc[2], wc[3], 0.9)
            lurek.gfx.print(string.format("  %s [%d]", WEATHER[i].name, i), list_x, list_y, 11)
            list_y = list_y + 15
            count = count + 1
        end
    end

    -- Fog
    if fog_active then
        lurek.gfx.setColor(0.9, 0.92, 0.95, 0.9)
        lurek.gfx.print("  Fog [F]", list_x, list_y, 11)
        list_y = list_y + 15
        count = count + 1
    end

    -- Vignette
    if vignette_active then
        lurek.gfx.setColor(0.4, 0.4, 0.4, 0.9)
        lurek.gfx.print("  Vignette [V]", list_x, list_y, 11)
        list_y = list_y + 15
        count = count + 1
    end

    -- Time-of-day (if not day)
    if current_tod ~= TOD_DAY then
        lurek.gfx.setColor(0.9, 0.8, 0.5, 0.9)
        lurek.gfx.print("  " .. TOD_NAMES[current_tod] .. " tint [T]", list_x, list_y, 11)
        list_y = list_y + 15
        count = count + 1
    end

    -- Empty message
    if count == 0 then
        lurek.gfx.setColor(0.5, 0.5, 0.5, 0.6)
        lurek.gfx.print("  (none — press 1-7)", list_x, list_y, 11)
    end

    lurek.camera.attach()
end
