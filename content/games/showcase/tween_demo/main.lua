-- Tween Demo — Lurek2D
-- Category: showcase
-- 12 easing curves animated simultaneously with interactive controls

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W  = 800
local SCREEN_H  = 600
local NUM_EASINGS    = 12
local TWEEN_DURATION = 2.0
local RECT_W    = 30
local RECT_H    = 20
local START_X   = 150
local END_X     = 650
local LIST_Y    = 60
local ROW_H     = 28
local GRAPH_X   = 150
local GRAPH_Y   = 420
local GRAPH_W   = 500
local GRAPH_H   = 130
local MAX_PARTICLES = 200

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE   = "TITLE"
local STATE_RUNNING = "RUNNING"

local state       = STATE_TITLE
local title_timer = 0
local title_alpha = 0

-- ============================================================
-- Easing definitions
-- ============================================================
local easing_names = {
    "linear",    "inQuad",     "outQuad",    "inOutQuad",
    "inCubic",   "outCubic",   "inOutCubic", "inSine",
    "outSine",   "inOutSine",  "inExpo",     "outExpo",
}

local easing_colors = {
    {1.0, 0.4, 0.4},   -- 1  red
    {1.0, 0.6, 0.3},   -- 2  orange
    {1.0, 0.9, 0.3},   -- 3  yellow
    {0.6, 1.0, 0.3},   -- 4  lime
    {0.3, 1.0, 0.5},   -- 5  green
    {0.3, 1.0, 0.9},   -- 6  cyan
    {0.3, 0.7, 1.0},   -- 7  blue
    {0.5, 0.3, 1.0},   -- 8  indigo
    {0.8, 0.3, 1.0},   -- 9  violet
    {1.0, 0.3, 0.8},   -- 10 pink
    {1.0, 0.5, 0.6},   -- 11 salmon
    {0.8, 0.8, 0.8},   -- 12 silver
}

-- Local easing functions for curve graph rendering
local PI = math.pi
local easing_funcs = {
    linear    = function(t) return t end,
    inQuad    = function(t) return t * t end,
    outQuad   = function(t) return t * (2 - t) end,
    inOutQuad = function(t)
        if t < 0.5 then return 2 * t * t end
        return -1 + (4 - 2 * t) * t
    end,
    inCubic    = function(t) return t * t * t end,
    outCubic   = function(t) local u = t - 1; return u * u * u + 1 end,
    inOutCubic = function(t)
        if t < 0.5 then return 4 * t * t * t end
        return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    end,
    inSine    = function(t) return 1 - math.cos(t * PI / 2) end,
    outSine   = function(t) return math.sin(t * PI / 2) end,
    inOutSine = function(t) return -(math.cos(PI * t) - 1) / 2 end,
    inExpo    = function(t) return t == 0 and 0 or math.pow(2, 10 * (t - 1)) end,
    outExpo   = function(t) return t == 1 and 1 or 1 - math.pow(2, -10 * t) end,
}

-- ============================================================
-- Animation state
-- ============================================================
local selected    = 1
local speed_mult  = 1.0
local paused      = false
local elapsed     = 0
local cycle_count = 0

-- Property modes
local PROP_POSITION = 1
local PROP_SCALE    = 2
local PROP_ROTATION = 3
local PROP_ALPHA    = 4
local PROP_COLOR    = 5
local prop_names = { "Position", "Scale", "Rotation", "Alpha", "Color" }
local current_prop = PROP_POSITION

-- Per-easing tween targets and handles
local targets = {}
local tweens  = {}

-- ============================================================
-- Particle systems
-- ============================================================
local psys_burst = nil
local psys_flash = nil

-- ============================================================
-- FPS
-- ============================================================
local fps       = 0
local fps_timer = 0
local fps_count = 0

-- ============================================================
-- Helpers
-- ============================================================
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function hue_to_rgb(h)
    h = h % 1.0
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    if     i == 0 then r, g, b = 1, f, 0
    elseif i == 1 then r, g, b = 1 - f, 1, 0
    elseif i == 2 then r, g, b = 0, 1, f
    elseif i == 3 then r, g, b = 0, 1 - f, 1
    elseif i == 4 then r, g, b = f, 0, 1
    else               r, g, b = 1, 0, 1 - f
    end
    return r, g, b
end

-- ============================================================
-- Create / restart tweens for current property
-- ============================================================
local function create_tweens()
    lurek.tween.cancelAll()
    tweens  = {}
    targets = {}
    elapsed = 0

    for i = 1, NUM_EASINGS do
        local t = {}
        if current_prop == PROP_POSITION then
            t = { x = START_X }
            tweens[i] = lurek.tween.to(t, { x = END_X }, TWEEN_DURATION, easing_names[i])
        elseif current_prop == PROP_SCALE then
            t = { scale = 0.5 }
            tweens[i] = lurek.tween.to(t, { scale = 2.0 }, TWEEN_DURATION, easing_names[i])
        elseif current_prop == PROP_ROTATION then
            t = { angle = 0 }
            tweens[i] = lurek.tween.to(t, { angle = 360 }, TWEEN_DURATION, easing_names[i])
        elseif current_prop == PROP_ALPHA then
            t = { alpha = 0.2 }
            tweens[i] = lurek.tween.to(t, { alpha = 1.0 }, TWEEN_DURATION, easing_names[i])
        elseif current_prop == PROP_COLOR then
            t = { hue = 0.0 }
            tweens[i] = lurek.tween.to(t, { hue = 1.0 }, TWEEN_DURATION, easing_names[i])
        end
        targets[i] = t
    end
end

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("pause",        "space")
lurek.input.bind("speed_half",   "1")
lurek.input.bind("speed_normal", "2")
lurek.input.bind("speed_double", "3")
lurek.input.bind("step_back",    "left")
lurek.input.bind("step_forward", "right")
lurek.input.bind("select_up",    "up")
lurek.input.bind("select_down",  "down")
lurek.input.bind("switch_prop",  "p")
lurek.input.bind("quit",         "escape")

-- ============================================================
-- Init
-- ============================================================
lurek.init(function()
    lurek.window.setTitle("Tween Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.06, 0.1)
    lurek.camera.setPosition(0, 0)
end)

-- ============================================================
-- Ready
-- ============================================================
lurek.ready(function()
    -- Burst particles: animation cycle complete
    psys_burst = lurek.particle.newSystem(MAX_PARTICLES)
    psys_burst:setEmissionRate(0)
    psys_burst:setParticleLifetime(0.3, 0.8)
    psys_burst:setSpeed(60, 150)
    psys_burst:setDirection(0)
    psys_burst:setSpread(math.pi * 2)
    psys_burst:setGravity(0, 60)
    psys_burst:setSizes(1.5, 0.8, 0.2)
    psys_burst:setColors(
        1.0, 0.9, 0.3, 1.0,
        1.0, 0.6, 0.1, 0.8,
        1.0, 0.3, 0.0, 0.0
    )
    psys_burst:setPosition(END_X + RECT_W / 2, SCREEN_H / 2)
    psys_burst:start()

    -- Flash particles: property switch
    psys_flash = lurek.particle.newSystem(MAX_PARTICLES)
    psys_flash:setEmissionRate(0)
    psys_flash:setParticleLifetime(0.2, 0.5)
    psys_flash:setSpeed(80, 200)
    psys_flash:setDirection(0)
    psys_flash:setSpread(math.pi * 2)
    psys_flash:setGravity(0, 0)
    psys_flash:setSizes(1.0, 1.5, 0.5, 0.0)
    psys_flash:setColors(
        0.6, 0.4, 1.0, 1.0,
        0.8, 0.6, 1.0, 0.7,
        1.0, 0.8, 1.0, 0.0
    )
    psys_flash:setPosition(SCREEN_W / 2, 30)
    psys_flash:start()
end)

-- ============================================================
-- Process
-- ============================================================
lurek.process(function(dt)
    -- FPS
    fps_count = fps_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps       = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    -- Quit
    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── Title state ────────────────────────────────────────
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        title_alpha = clamp(title_timer / 0.8, 0, 1)

        if lurek.input.pressed("pause") or lurek.input.pressed("select_down") then
            state = STATE_RUNNING
            create_tweens()
            return
        end
        return
    end

    -- ── Running state ──────────────────────────────────────
    -- Speed control
    if lurek.input.pressed("speed_half")   then speed_mult = 0.5 end
    if lurek.input.pressed("speed_normal") then speed_mult = 1.0 end
    if lurek.input.pressed("speed_double") then speed_mult = 2.0 end

    -- Pause / Resume
    if lurek.input.pressed("pause") then
        paused = not paused
        for i = 1, NUM_EASINGS do
            if tweens[i] then
                if paused then tweens[i]:pause() else tweens[i]:resume() end
            end
        end
    end

    -- Manual scrub (while paused)
    if paused then
        if lurek.input.pressed("step_forward") then
            lurek.tween.update(0.05)
            elapsed = elapsed + 0.05
        end
        if lurek.input.pressed("step_back") then
            local target_elapsed = math.max(0, elapsed - 0.05)
            create_tweens()
            if target_elapsed > 0 then
                lurek.tween.update(target_elapsed)
            end
            elapsed = target_elapsed
            -- Re-pause after rewinding
            for i = 1, NUM_EASINGS do
                if tweens[i] then tweens[i]:pause() end
            end
        end
    end

    -- Selection
    if lurek.input.pressed("select_up") then
        selected = selected - 1
        if selected < 1 then selected = NUM_EASINGS end
    end
    if lurek.input.pressed("select_down") then
        selected = selected + 1
        if selected > NUM_EASINGS then selected = 1 end
    end

    -- Property switch
    if lurek.input.pressed("switch_prop") then
        current_prop = current_prop + 1
        if current_prop > PROP_COLOR then current_prop = PROP_POSITION end
        create_tweens()
        if psys_flash then
            psys_flash:setPosition(SCREEN_W / 2, 30)
            psys_flash:emit(30)
        end
    end

    -- Update tweens
    if not paused then
        lurek.tween.update(dt * speed_mult)
        elapsed = elapsed + dt * speed_mult

        -- Check if all tweens finished → restart cycle
        local all_done = true
        for i = 1, NUM_EASINGS do
            if tweens[i] and tweens[i]:isActive() then
                all_done = false
                break
            end
        end
        if all_done and elapsed >= TWEEN_DURATION * 0.9 then
            cycle_count = cycle_count + 1
            if psys_burst then
                psys_burst:setPosition(END_X + RECT_W / 2, LIST_Y + NUM_EASINGS * ROW_H / 2)
                psys_burst:emit(40)
            end
            create_tweens()
        end
    end

    -- Update particles
    if psys_burst then psys_burst:update(dt) end
    if psys_flash then psys_flash:update(dt) end
end)

-- ============================================================
-- Render: animated rectangles + particles (world-space)
-- ============================================================
lurek.render(function()
    if state == STATE_TITLE then return end

    for i = 1, NUM_EASINGS do
        local y = LIST_Y + (i - 1) * ROW_H
        local c = easing_colors[i]
        local t = targets[i]
        if not t then goto continue end

        -- Selection highlight bar
        if i == selected then
            lurek.render.setColor(1.0, 1.0, 0.3, 0.12)
            lurek.render.drawRectFill(START_X - 5, y - 3, END_X - START_X + RECT_W + 10, RECT_H + 6)
        end

        if current_prop == PROP_POSITION then
            local x = t.x or START_X
            lurek.render.setColor(c[1], c[2], c[3], 1.0)
            lurek.render.drawRectFill(x, y, RECT_W, RECT_H)

        elseif current_prop == PROP_SCALE then
            local s = t.scale or 0.5
            local w = RECT_W * s
            local h = RECT_H * s
            local cx = (START_X + END_X) / 2
            lurek.render.setColor(c[1], c[2], c[3], 1.0)
            lurek.render.drawRectFill(cx - w / 2, y + RECT_H / 2 - h / 2, w, h)

        elseif current_prop == PROP_ROTATION then
            local angle = t.angle or 0
            local rad = math.rad(angle)
            local ox = math.cos(rad) * 20
            local oy = math.sin(rad) * 10
            local cx = (START_X + END_X) / 2
            lurek.render.setColor(c[1], c[2], c[3], 1.0)
            lurek.render.drawRectFill(cx + ox - RECT_W / 2, y + oy, RECT_W, RECT_H)

        elseif current_prop == PROP_ALPHA then
            local a = t.alpha or 0.2
            local cx = (START_X + END_X) / 2
            lurek.render.setColor(c[1], c[2], c[3], a)
            lurek.render.drawRectFill(cx - RECT_W / 2, y, RECT_W, RECT_H)

        elseif current_prop == PROP_COLOR then
            local hue = t.hue or 0
            local r, g, b = hue_to_rgb(hue * 0.66)
            local cx = (START_X + END_X) / 2
            lurek.render.setColor(r, g, b, 1.0)
            lurek.render.drawRectFill(cx - RECT_W / 2, y, RECT_W, RECT_H)
        end

        -- Track line (faint)
        lurek.render.setColor(0.2, 0.2, 0.3, 0.25)
        lurek.render.drawLine(START_X, y + RECT_H / 2, END_X + RECT_W, y + RECT_H / 2)

        ::continue::
    end

    -- Burst particles (world-space)
    if psys_burst then psys_burst:render() end
end)

-- ============================================================
-- Render UI: labels, curve graph, controls, title
-- ============================================================
lurek.render_ui(function()
    -- ── Title screen ───────────────────────────────────────
    if state == STATE_TITLE then
        local a = title_alpha

        lurek.render.setColor(0.12, 0.08, 0.2, a * 0.5)
        lurek.render.drawRectFill(0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1.0, 0.85, 0.4, a)
        lurek.render.print("TWEEN DEMO", SCREEN_W / 2 - 80, SCREEN_H / 2 - 50)

        lurek.render.setColor(0.6, 0.4, 1.0, a * 0.8)
        lurek.render.print("EASING CURVES", SCREEN_W / 2 - 75, SCREEN_H / 2 - 20)

        lurek.render.setColor(0.6, 0.6, 0.7, a * 0.6)
        lurek.render.print("Press SPACE or DOWN to start", SCREEN_W / 2 - 110, SCREEN_H / 2 + 30)

        lurek.render.setColor(0.4, 0.4, 0.5, a * 0.4)
        lurek.render.print("12 easing types — interactive curve viewer", SCREEN_W / 2 - 150, SCREEN_H / 2 + 60)

        lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
        lurek.render.print("FPS: " .. fps, 10, SCREEN_H - 20)
        return
    end

    -- ── Top bar ────────────────────────────────────────────
    lurek.render.setColor(0.0, 0.0, 0.0, 0.55)
    lurek.render.drawRectFill(0, 0, SCREEN_W, 44)

    lurek.render.setColor(1.0, 0.9, 0.4, 1.0)
    lurek.render.print("Tween Demo", 12, 6)

    lurek.render.setColor(0.7, 0.8, 0.9, 0.85)
    lurek.render.print("Property: " .. prop_names[current_prop], 160, 6)

    local speed_label = speed_mult == 0.5 and "0.5x" or (speed_mult == 2.0 and "2.0x" or "1.0x")
    lurek.render.setColor(0.7, 0.8, 0.9, 0.85)
    lurek.render.print("Speed: " .. speed_label, 360, 6)

    if paused then
        lurek.render.setColor(1.0, 0.4, 0.4, 1.0)
        lurek.render.print("PAUSED", 500, 6)
    end

    lurek.render.setColor(0.5, 0.5, 0.6, 0.7)
    lurek.render.print("Cycle: " .. cycle_count, 620, 6)

    lurek.render.setColor(0.5, 0.5, 0.6, 0.7)
    lurek.render.print(string.format("Elapsed: %.2fs / %.1fs", math.min(elapsed, TWEEN_DURATION), TWEEN_DURATION), 160, 26)

    lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
    lurek.render.print("Active tweens: " .. lurek.tween.getActiveCount(), 420, 26)

    -- ── Easing labels (left side) ──────────────────────────
    for i = 1, NUM_EASINGS do
        local y = LIST_Y + (i - 1) * ROW_H + 3
        if i == selected then
            lurek.render.setColor(1.0, 1.0, 0.3, 1.0)
        else
            lurek.render.setColor(0.6, 0.6, 0.7, 0.75)
        end
        lurek.render.print(string.format("%2d. %s", i, easing_names[i]), 10, y)
    end

    -- ── Easing curve graph ─────────────────────────────────
    local gx, gy, gw, gh = GRAPH_X, GRAPH_Y, GRAPH_W, GRAPH_H

    -- Background
    lurek.render.setColor(0.0, 0.0, 0.0, 0.4)
    lurek.render.drawRectFill(gx - 8, gy - 22, gw + 16, gh + 34)

    -- Border
    lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
    lurek.render.drawRect(gx, gy, gw, gh)

    -- Grid lines
    lurek.render.setColor(0.2, 0.2, 0.3, 0.3)
    for gi = 1, 3 do
        local frac = gi / 4
        lurek.render.drawLine(gx, gy + gh * (1 - frac), gx + gw, gy + gh * (1 - frac))
        lurek.render.drawLine(gx + gw * frac, gy, gx + gw * frac, gy + gh)
    end

    -- Axis labels
    lurek.render.setColor(0.4, 0.4, 0.5, 0.5)
    lurek.render.print("0", gx - 14, gy + gh - 6)
    lurek.render.print("1", gx - 14, gy - 4)
    lurek.render.print("time ->", gx + gw / 2 - 20, gy + gh + 4)

    -- Draw the selected easing curve
    local sel_name  = easing_names[selected]
    local sel_func  = easing_funcs[sel_name]
    local sel_color = easing_colors[selected]

    if sel_func then
        local steps = 80
        lurek.render.setColor(sel_color[1], sel_color[2], sel_color[3], 0.9)
        for s = 0, steps - 1 do
            local t1 = s / steps
            local t2 = (s + 1) / steps
            local v1 = sel_func(t1)
            local v2 = sel_func(t2)
            lurek.render.drawLine(
                gx + t1 * gw, gy + gh - v1 * gh,
                gx + t2 * gw, gy + gh - v2 * gh
            )
        end

        -- Linear reference line (faint)
        lurek.render.setColor(0.3, 0.3, 0.4, 0.25)
        lurek.render.drawLine(gx, gy + gh, gx + gw, gy)

        -- Progress indicator dot
        local progress = clamp(elapsed / TWEEN_DURATION, 0, 1)
        local v = sel_func(progress)
        lurek.render.setColor(1.0, 1.0, 1.0, 1.0)
        lurek.render.drawCircleFill(gx + progress * gw, gy + gh - v * gh, 5)

        -- Crosshair lines at progress point
        lurek.render.setColor(1.0, 1.0, 1.0, 0.2)
        lurek.render.drawLine(gx + progress * gw, gy, gx + progress * gw, gy + gh)
        lurek.render.drawLine(gx, gy + gh - v * gh, gx + gw, gy + gh - v * gh)
    end

    -- Graph title: selected easing name
    lurek.render.setColor(sel_color[1], sel_color[2], sel_color[3], 1.0)
    lurek.render.print(sel_name, gx, gy - 18)

    -- ── Bottom controls bar ────────────────────────────────
    lurek.render.setColor(0.0, 0.0, 0.0, 0.45)
    lurek.render.drawRectFill(0, SCREEN_H - 26, SCREEN_W, 26)

    lurek.render.setColor(0.5, 0.5, 0.6, 0.6)
    lurek.render.print(
        "SPACE: Pause  |  1-3: Speed  |  Left/Right: Scrub  |  Up/Down: Select  |  P: Property  |  ESC: Quit",
        10, SCREEN_H - 19
    )

    -- FPS
    lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
    lurek.render.print("FPS: " .. fps, SCREEN_W - 70, SCREEN_H - 19)

    -- Flash particles (UI layer)
    if psys_flash then psys_flash:render() end
end)
