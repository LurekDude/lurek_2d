-- Particles Demo — Lurek2D
-- Category: showcase
-- 8 particle presets with interactive controls

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W = 800
local SCREEN_H = 600
local NUM_PRESETS = 8
local BURST_COUNT = 50
local MAX_PARTICLES = 2000

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE   = "TITLE"
local STATE_RUNNING = "RUNNING"

local state = STATE_TITLE
local title_timer = 0
local title_alpha = 0

-- ============================================================
-- Preset definitions
-- ============================================================
local preset_index = 1
local preset_names = {
    "Fire", "Water Splash", "Smoke", "Magic Sparkle",
    "Explosion", "Snow", "Fireflies", "Confetti",
}

local preset_configs = {
    -- 1: Fire
    {
        rate = 80, lifetime = {0.4, 1.2}, speed = {60, 140},
        direction = math.pi * 1.5, spread = math.pi / 5,
        gravity = {0, -100}, sizes = {2.5, 1.8, 0.5, 0.0},
        colors = {
            1.0, 1.0, 0.9, 1.0,
            1.0, 0.8, 0.2, 1.0,
            1.0, 0.4, 0.05, 0.7,
            0.6, 0.1, 0.0, 0.0,
        },
        area = {"uniform", 12, 4},
    },
    -- 2: Water Splash
    {
        rate = 60, lifetime = {0.5, 1.0}, speed = {80, 200},
        direction = math.pi * 1.5, spread = math.pi / 3,
        gravity = {0, 300}, sizes = {1.5, 1.0, 0.4},
        colors = {
            0.6, 0.85, 1.0, 1.0,
            0.3, 0.6, 1.0, 0.8,
            0.1, 0.3, 0.8, 0.0,
        },
        area = {"uniform", 6, 2},
    },
    -- 3: Smoke
    {
        rate = 30, lifetime = {1.5, 3.0}, speed = {15, 40},
        direction = math.pi * 1.5, spread = math.pi / 6,
        gravity = {0, -30}, sizes = {1.0, 2.0, 3.5, 4.0},
        colors = {
            0.5, 0.5, 0.5, 0.6,
            0.4, 0.4, 0.4, 0.35,
            0.3, 0.3, 0.3, 0.1,
            0.25, 0.25, 0.25, 0.0,
        },
        area = {"uniform", 8, 4},
    },
    -- 4: Magic Sparkle
    {
        rate = 50, lifetime = {0.8, 1.8}, speed = {30, 90},
        direction = 0, spread = math.pi * 2,
        gravity = {0, 0}, sizes = {1.2, 1.8, 0.8, 0.0},
        colors = {
            1.0, 1.0, 1.0, 1.0,
            0.8, 0.4, 1.0, 1.0,
            0.6, 0.2, 0.9, 0.6,
            0.4, 0.1, 0.7, 0.0,
        },
        area = {"uniform", 4, 4},
    },
    -- 5: Explosion
    {
        rate = 0, lifetime = {0.3, 0.8}, speed = {150, 350},
        direction = 0, spread = math.pi * 2,
        gravity = {0, 80}, sizes = {2.5, 1.5, 0.5, 0.0},
        colors = {
            1.0, 1.0, 0.9, 1.0,
            1.0, 0.7, 0.1, 1.0,
            1.0, 0.3, 0.0, 0.6,
            0.5, 0.1, 0.0, 0.0,
        },
        area = {"uniform", 2, 2},
    },
    -- 6: Snow
    {
        rate = 40, lifetime = {3.0, 6.0}, speed = {10, 30},
        direction = math.pi * 0.55, spread = math.pi / 4,
        gravity = {0, 25}, sizes = {0.8, 1.0, 0.6},
        colors = {
            1.0, 1.0, 1.0, 0.9,
            0.9, 0.95, 1.0, 0.7,
            0.85, 0.9, 1.0, 0.0,
        },
        area = {"uniform", SCREEN_W / 2, 4},
    },
    -- 7: Fireflies
    {
        rate = 15, lifetime = {2.0, 4.0}, speed = {8, 25},
        direction = 0, spread = math.pi * 2,
        gravity = {0, 0}, sizes = {0.6, 1.2, 0.8, 0.3},
        colors = {
            0.9, 1.0, 0.3, 0.0,
            0.8, 1.0, 0.4, 0.9,
            0.6, 0.9, 0.2, 0.7,
            0.4, 0.7, 0.1, 0.0,
        },
        area = {"uniform", 60, 60},
    },
    -- 8: Confetti
    {
        rate = 45, lifetime = {1.5, 3.5}, speed = {40, 100},
        direction = math.pi * 0.5, spread = math.pi / 2,
        gravity = {0, 80}, sizes = {1.5, 1.5, 1.0, 0.5},
        colors = {
            1.0, 0.3, 0.4, 1.0,
            0.3, 0.8, 1.0, 1.0,
            1.0, 0.9, 0.2, 0.8,
            0.4, 1.0, 0.4, 0.0,
        },
        area = {"uniform", 40, 4},
    },
}

-- ============================================================
-- Toggle states
-- ============================================================
local continuous     = true
local gravity_on     = true
local rainbow_mode   = false
local wind_on        = false
local wind_force     = 120

-- ============================================================
-- Stats
-- ============================================================
local total_emitted  = 0
local emit_this_sec  = 0
local emit_per_sec   = 0
local stat_timer     = 0

-- ============================================================
-- FPS
-- ============================================================
local fps       = 0
local fps_timer = 0
local fps_count = 0

-- ============================================================
-- Time
-- ============================================================
local time_acc = 0

-- ============================================================
-- Particle system
-- ============================================================
local psys = nil

local function apply_preset(idx)
    local cfg = preset_configs[idx]
    if not cfg then return end

    if psys then psys:stop(); psys:reset() end
    psys = lurek.particle.newSystem(MAX_PARTICLES)

    psys:setEmissionRate(continuous and cfg.rate or 0)
    psys:setParticleLifetime(cfg.lifetime[1], cfg.lifetime[2])
    psys:setSpeed(cfg.speed[1], cfg.speed[2])
    psys:setDirection(cfg.direction)
    psys:setSpread(cfg.spread)

    if gravity_on then
        psys:setGravity(cfg.gravity[1], cfg.gravity[2])
    else
        psys:setGravity(0, 0)
    end

    psys:setSizes(unpack(cfg.sizes))
    psys:setSizeVariation(0.2)
    psys:setColors(unpack(cfg.colors))
    psys:setEmissionArea(cfg.area[1], cfg.area[2], cfg.area[3])
    psys:setLinearDamping(0.1, 0.3)
    psys:setSpin(-1, 1)
    psys:setRotation(0, math.pi * 2)

    local mx, my = lurek.input.getMousePosition()
    if idx == 6 then
        psys:setPosition(SCREEN_W / 2, 10)
    else
        psys:setPosition(mx or SCREEN_W / 2, my or SCREEN_H / 2)
    end

    psys:start()
    total_emitted = 0
    emit_this_sec = 0
    emit_per_sec = 0
    stat_timer = 0
end

-- ============================================================
-- Tween state
-- ============================================================
local preset_tween_alpha = 1.0
local preset_tween_timer = 0
local PRESET_TWEEN_DUR = 0.4

local function switch_preset(idx)
    if idx < 1 then idx = NUM_PRESETS end
    if idx > NUM_PRESETS then idx = 1 end
    if idx == preset_index and state == STATE_RUNNING then return end
    preset_index = idx
    apply_preset(idx)
    preset_tween_alpha = 0.0
    preset_tween_timer = 0
end

-- ============================================================
-- Helpers
-- ============================================================
local function lerp(a, b, t)
    return a + (b - a) * math.min(math.max(t, 0), 1)
end

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
    if i == 0 then     r, g, b = 1, f, 0
    elseif i == 1 then r, g, b = 1 - f, 1, 0
    elseif i == 2 then r, g, b = 0, 1, f
    elseif i == 3 then r, g, b = 0, 1 - f, 1
    elseif i == 4 then r, g, b = f, 0, 1
    else               r, g, b = 1, 0, 1 - f
    end
    return r, g, b
end

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("preset_1", "1")
lurek.input.bind("preset_2", "2")
lurek.input.bind("preset_3", "3")
lurek.input.bind("preset_4", "4")
lurek.input.bind("preset_5", "5")
lurek.input.bind("preset_6", "6")
lurek.input.bind("preset_7", "7")
lurek.input.bind("preset_8", "8")
lurek.input.bind("burst", "space")
lurek.input.bind("toggle_continuous", "c")
lurek.input.bind("toggle_gravity", "g")
lurek.input.bind("toggle_rainbow", "r")
lurek.input.bind("toggle_wind", "w")
lurek.input.bind("quit", "escape")

-- ============================================================
-- Init
-- ============================================================
function lurek.init()
    lurek.window.setTitle("Particles Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.08)
    lurek.camera.setPosition(0, 0)
end

function lurek.ready()
    -- system created on first preset switch
end

-- ============================================================
-- Process
-- ============================================================
lurek.process(function(dt)
    -- FPS
    fps_count = fps_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    time_acc = time_acc + dt

    -- Quit
    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── Title state ────────────────────────────────────────
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        title_alpha = clamp(title_timer / 0.8, 0, 1)

        for i = 1, NUM_PRESETS do
            if lurek.input.pressed("preset_" .. i) then
                state = STATE_RUNNING
                switch_preset(i)
                return
            end
        end
        if lurek.input.pressed("burst") then
            state = STATE_RUNNING
            switch_preset(1)
            return
        end
        return
    end

    -- ── Running state ──────────────────────────────────────
    -- Preset switching
    for i = 1, NUM_PRESETS do
        if lurek.input.pressed("preset_" .. i) then
            switch_preset(i)
        end
    end

    -- Toggle continuous
    if lurek.input.pressed("toggle_continuous") then
        continuous = not continuous
        if psys then
            local cfg = preset_configs[preset_index]
            psys:setEmissionRate(continuous and cfg.rate or 0)
        end
    end

    -- Toggle gravity
    if lurek.input.pressed("toggle_gravity") then
        gravity_on = not gravity_on
        if psys then
            local cfg = preset_configs[preset_index]
            if gravity_on then
                psys:setGravity(cfg.gravity[1], cfg.gravity[2])
            else
                psys:setGravity(0, 0)
            end
        end
    end

    -- Toggle rainbow
    if lurek.input.pressed("toggle_rainbow") then
        rainbow_mode = not rainbow_mode
    end

    -- Toggle wind
    if lurek.input.pressed("toggle_wind") then
        wind_on = not wind_on
    end

    -- Burst
    if lurek.input.pressed("burst") then
        if psys then
            psys:emit(BURST_COUNT)
            total_emitted = total_emitted + BURST_COUNT
            emit_this_sec = emit_this_sec + BURST_COUNT
        end
    end

    -- Mouse follow (except snow which emits from top)
    if psys then
        local mx, my = lurek.input.getMousePosition()
        if preset_index == 6 then
            psys:setPosition(SCREEN_W / 2, 10)
        else
            psys:setPosition(mx, my)
        end
    end

    -- Wind force
    if psys and wind_on then
        local wx = math.sin(time_acc * 0.7) * wind_force
        local cfg = preset_configs[preset_index]
        local gy = gravity_on and cfg.gravity[2] or 0
        psys:setGravity(wx, gy)
    elseif psys and not wind_on then
        local cfg = preset_configs[preset_index]
        if gravity_on then
            psys:setGravity(cfg.gravity[1], cfg.gravity[2])
        else
            psys:setGravity(0, 0)
        end
    end

    -- Rainbow color cycling
    if rainbow_mode and psys then
        local h = (time_acc * 0.3) % 1.0
        local r1, g1, b1 = hue_to_rgb(h)
        local r2, g2, b2 = hue_to_rgb(h + 0.15)
        local r3, g3, b3 = hue_to_rgb(h + 0.35)
        psys:setColors(
            r1, g1, b1, 1.0,
            r2, g2, b2, 0.8,
            r3, g3, b3, 0.3,
            r3, g3, b3, 0.0
        )
    end

    -- Update particle system
    if psys then
        psys:update(dt)
    end

    -- Stats tracking
    if continuous and psys then
        local cfg = preset_configs[preset_index]
        total_emitted = total_emitted + cfg.rate * dt
        emit_this_sec = emit_this_sec + cfg.rate * dt
    end
    stat_timer = stat_timer + dt
    if stat_timer >= 1.0 then
        emit_per_sec = math.floor(emit_this_sec)
        emit_this_sec = 0
        stat_timer = stat_timer - 1.0
    end

    -- Preset name tween
    if preset_tween_timer < PRESET_TWEEN_DUR then
        preset_tween_timer = preset_tween_timer + dt
        preset_tween_alpha = clamp(preset_tween_timer / PRESET_TWEEN_DUR, 0, 1)
    end
end)

-- ============================================================
-- Render: particles (world-space)
-- ============================================================
function lurek.render()
    if state == STATE_TITLE then return end

    -- Draw the particle system
    if psys then
        psys:render()
    end

    -- Subtle floor line
    lurek.render.setColor(0.15, 0.15, 0.2, 0.3)
    lurek.render.rectangle(0, SCREEN_H - 2, SCREEN_W, 2)
end

-- ============================================================
-- Render UI: HUD, preset name, stats, title screen
-- ============================================================
lurek.render_ui(function()
    -- ── Title screen ───────────────────────────────────────
    if state == STATE_TITLE then
        local a = title_alpha

        -- Background glow
        lurek.render.setColor(0.15, 0.08, 0.25, a * 0.4)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)

        -- Title
        lurek.render.setColor(1.0, 0.85, 0.4, a)
        lurek.render.print("PARTICLES DEMO", SCREEN_W / 2 - 110, SCREEN_H / 2 - 60)

        -- Subtitle
        lurek.render.setColor(0.7, 0.5, 1.0, a * 0.8)
        lurek.render.print("BEAUTIFUL EFFECTS", SCREEN_W / 2 - 95, SCREEN_H / 2 - 30)

        -- Instructions
        lurek.render.setColor(0.6, 0.6, 0.7, a * 0.6)
        lurek.render.print("Press 1-8 to select a preset or SPACE to start", SCREEN_W / 2 - 195, SCREEN_H / 2 + 30)

        -- Preset list preview
        for i = 1, NUM_PRESETS do
            local y = SCREEN_H / 2 + 60 + (i - 1) * 18
            lurek.render.setColor(0.5, 0.5, 0.6, a * 0.5)
            lurek.render.print(i .. ". " .. preset_names[i], SCREEN_W / 2 - 60, y)
        end

        -- FPS
        lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
        lurek.render.print("FPS: " .. fps, 10, SCREEN_H - 20)
        return
    end

    -- ── Running HUD ────────────────────────────────────────
    local active_count = psys and psys:getCount() or 0

    -- Top bar background
    lurek.render.setColor(0.0, 0.0, 0.0, 0.5)
    lurek.render.rectangle(0, 0, SCREEN_W, 50)

    -- Preset name with tween fade-in
    local pa = preset_tween_alpha
    lurek.render.setColor(1.0, 0.9, 0.4, pa)
    lurek.render.print("[" .. preset_index .. "] " .. preset_names[preset_index], 12, 6)

    -- Stats line
    lurek.render.setColor(0.7, 0.8, 0.9, 0.8)
    lurek.render.print(
        "Active: " .. active_count
        .. "  |  Total: " .. math.floor(total_emitted)
        .. "  |  Rate: " .. emit_per_sec .. "/s",
        12, 28
    )

    -- Toggle indicators (right side)
    local rx = SCREEN_W - 220
    local ry = 6
    local function toggle_text(label, on, y_off)
        if on then
            lurek.render.setColor(0.3, 1.0, 0.4, 0.9)
        else
            lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
        end
        lurek.render.print(label, rx, ry + y_off)
    end
    toggle_text("[C]ontinuous", continuous, 0)
    toggle_text("[G]ravity", gravity_on, 14)
    toggle_text("[R]ainbow", rainbow_mode, 28)

    local rx2 = SCREEN_W - 100
    toggle_text = function(label, on, y_off)
        if on then
            lurek.render.setColor(0.3, 1.0, 0.4, 0.9)
        else
            lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
        end
        lurek.render.print(label, rx2, ry + y_off)
    end
    toggle_text("[W]ind", wind_on, 0)

    -- Bottom bar: controls hint
    lurek.render.setColor(0.0, 0.0, 0.0, 0.4)
    lurek.render.rectangle(0, SCREEN_H - 24, SCREEN_W, 24)

    lurek.render.setColor(0.5, 0.5, 0.6, 0.6)
    lurek.render.print(
        "1-8: Preset  |  SPACE: Burst  |  C: Continuous  |  G: Gravity  |  R: Rainbow  |  W: Wind  |  ESC: Quit",
        10, SCREEN_H - 18
    )

    -- FPS
    lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
    lurek.render.print("FPS: " .. fps, SCREEN_W - 70, SCREEN_H - 18)
end)
