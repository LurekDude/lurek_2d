-- ============================================================================
-- Signal Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/signal_demo/main.lua
-- Run with : cargo run -- content/games/showcase/signal_demo
-- ============================================================================
-- Complete pub-sub event signal system showcase demonstrating the
-- publisher-subscriber pattern with five signal types, cascading chain
-- reactions, and real-time subscriber/event log visualization.
-- Controls: A=player_hit, S=score_up, D=level_up, F=combo, Escape=quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- Layout
local GAME_AREA_W   = 480
local RIGHT_PANEL_X = 500
local RIGHT_PANEL_W = 290
local LOG_PANEL_Y   = 440
local LOG_PANEL_H   = 150
local LOG_MAX        = 15

-- Gameplay
local MAX_HEALTH     = 100
local HIT_DAMAGE     = 20
local SCORE_PER_HIT  = 10
local COMBO_THRESHOLD = 5
local BONUS_SCORE    = 50

-- Colors per signal type
local SIG_COLORS = {
    player_hit    = { 0.95, 0.25, 0.20 },
    score_up      = { 0.20, 0.90, 0.40 },
    level_up      = { 0.30, 0.50, 1.00 },
    combo_reached = { 1.00, 0.85, 0.10 },
    game_over     = { 0.70, 0.10, 0.10 },
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0, 1)
end

local function format_time(t)
    local m = math.floor(t / 60)
    local s = math.floor(t % 60)
    local ms = math.floor((t * 100) % 100)
    return string.format("%02d:%02d.%02d", m, s, ms)
end

-- ---------------------------------------------------------------------------
-- Inline Signal System (pub-sub)
-- ---------------------------------------------------------------------------
local signal_bus = {}
local subscriber_registry = {}  -- { signal_name = { {name, fn, color}, ... } }
local stats = { fired = 0, chain_reactions = 0, subscribers = 0 }
local event_log = {}
local game_time = 0

local function signal_subscribe(signal_name, sub_name, fn, color)
    if not subscriber_registry[signal_name] then
        subscriber_registry[signal_name] = {}
    end
    table.insert(subscriber_registry[signal_name], {
        name  = sub_name,
        fn    = fn,
        color = color or SIG_COLORS[signal_name] or { 0.8, 0.8, 0.8 },
        flash = 0,
    })
    stats.subscribers = stats.subscribers + 1
end

local chain_depth = 0

local function signal_emit(signal_name, data)
    stats.fired = stats.fired + 1
    if chain_depth > 0 then
        stats.chain_reactions = stats.chain_reactions + 1
    end
    -- Log event
    table.insert(event_log, 1, {
        time   = game_time or 0,
        signal = signal_name,
        chain  = chain_depth > 0,
    })
    if #event_log > LOG_MAX then
        table.remove(event_log, #event_log + 1)
    end
    -- Notify subscribers
    local subs = subscriber_registry[signal_name]
    if subs then
        chain_depth = chain_depth + 1
        for _, sub in ipairs(subs) do
            sub.flash = 1.0
            sub.fn(data)
        end
        chain_depth = chain_depth - 1
    end
end

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local _cam = nil ---@type any
local health          = MAX_HEALTH
local health_display  = MAX_HEALTH
local score           = 0
local score_display   = 0
local combo           = 0
local level           = 1
local game_speed      = 1.0
local title_timer     = 0
local title_alpha     = 0
local death_timer     = 0

-- Visual effects
local screen_flash    = { a = 0, r = 1, g = 1, b = 1 }
local bg_color        = { r = 0.06, g = 0.06, b = 0.10 }
local bg_target       = { r = 0.06, g = 0.06, b = 0.10 }
local floating_texts  = {}
local particles       = {}

-- Particle systems (engine)
local hit_ps          = nil
local score_ps        = nil
local level_ps        = nil
local combo_ps        = nil

-- Tweens
local health_tween    = nil
local score_tween     = nil
local flash_tween     = nil

-- ---------------------------------------------------------------------------
-- Particles (manual for variety)
-- ---------------------------------------------------------------------------
local function spawn_particles(x, y, r, g, b, count, spread)
    count = count or 12
    spread = spread or 60
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 30 + math.random() * spread
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = r, g = g, b = b, a = 1.0,
            life = 0.4 + math.random() * 0.6,
            size = 2 + math.random() * 4,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 80 * dt
        p.life = p.life - dt
        p.a = clamp(p.life / 0.6, 0, 1)
        p.size = p.size * (1 - dt * 0.5)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Floating text
-- ---------------------------------------------------------------------------
local function spawn_float_text(x, y, text, r, g, b)
    table.insert(floating_texts, {
        x = x, y = y, text = text,
        r = r, g = g, b = b,
        a = 1.0, vy = -60, life = 1.2,
    })
end

local function update_floating_texts(dt)
    local i = 1
    while i <= #floating_texts do
        local ft = floating_texts[i]
        ft.y = ft.y + ft.vy * dt
        ft.vy = ft.vy * 0.97
        ft.life = ft.life - dt
        ft.a = clamp(ft.life / 0.6, 0, 1)
        if ft.life <= 0 then
            table.remove(floating_texts, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Screen flash helper
-- ---------------------------------------------------------------------------
local function trigger_flash(r, g, b, intensity)
    screen_flash.r = r
    screen_flash.g = g
    screen_flash.b = b
    screen_flash.a = intensity or 0.4
    flash_tween = lurek.tween.to(
        screen_flash,
        { a = 0 },
        0.35,
        "outQuad"
    )
end

-- ---------------------------------------------------------------------------
-- Register subscribers
-- ---------------------------------------------------------------------------
local function register_subscribers()
    -- player_hit subscribers
    signal_subscribe("player_hit", "HealthDrain", function()
        health = clamp(health - HIT_DAMAGE, 0, MAX_HEALTH)
        health_tween = lurek.tween.to(
            { val = health_display },
            { val = health },
            0.4, "outQuad"
        )
        spawn_float_text(120, 120, "-" .. HIT_DAMAGE .. " HP", 1, 0.3, 0.2)
    end, { 0.95, 0.30, 0.25 })

    signal_subscribe("player_hit", "ScreenFlash", function()
        trigger_flash(0.9, 0.15, 0.1, 0.5)
    end, { 1.0, 0.5, 0.4 })

    signal_subscribe("player_hit", "ComboReset", function()
        if combo > 0 then
            spawn_float_text(120, 160, "Combo lost!", 0.8, 0.4, 0.2)
        end
        combo = 0
    end, { 0.9, 0.6, 0.3 })

    signal_subscribe("player_hit", "HitParticles", function()
        local c = SIG_COLORS.player_hit
        spawn_particles(GAME_AREA_W / 2, 200, c[1], c[2], c[3], 20, 80)
    end, { 0.85, 0.20, 0.15 })

    -- score_up subscribers
    signal_subscribe("score_up", "ScoreAdd", function(data)
        local amount = (data and data.amount) or SCORE_PER_HIT
        score = score + amount
        score_tween = lurek.tween.to(
            { val = score_display },
            { val = score },
            0.3, "outQuad"
        )
    end, { 0.25, 0.90, 0.45 })

    signal_subscribe("score_up", "FloatText", function(data)
        local amount = (data and data.amount) or SCORE_PER_HIT
        local label = "+" .. amount
        spawn_float_text(
            120 + math.random(-30, 30),
            240 + math.random(-10, 10),
            label, 0.2, 1.0, 0.4
        )
    end, { 0.30, 0.95, 0.50 })

    signal_subscribe("score_up", "ComboIncrement", function()
        combo = combo + 1
        if combo >= COMBO_THRESHOLD then
            signal_emit("combo_reached", { combo = combo })
            combo = 0
        end
    end, { 0.40, 0.80, 0.35 })

    signal_subscribe("score_up", "ScoreParticles", function()
        local c = SIG_COLORS.score_up
        spawn_particles(GAME_AREA_W / 2, 250, c[1], c[2], c[3], 10, 50)
    end, { 0.20, 0.85, 0.40 })

    -- level_up subscribers
    signal_subscribe("level_up", "BGColorShift", function()
        level = level + 1
        local hue = (level * 0.15) % 1.0
        bg_target.r = 0.04 + hue * 0.06
        bg_target.g = 0.04 + (1 - hue) * 0.04
        bg_target.b = 0.08 + math.sin(hue * math.pi) * 0.06
    end, { 0.35, 0.55, 1.00 })

    signal_subscribe("level_up", "ParticleBurst", function()
        local c = SIG_COLORS.level_up
        spawn_particles(GAME_AREA_W / 2, SCREEN_H / 2, c[1], c[2], c[3], 30, 100)
    end, { 0.40, 0.60, 1.00 })

    signal_subscribe("level_up", "SpeedIncrease", function()
        game_speed = game_speed + 0.1
        spawn_float_text(120, 300, "Speed +" .. string.format("%.0f%%", game_speed * 100 - 100),
            0.3, 0.5, 1.0)
    end, { 0.25, 0.45, 0.90 })

    signal_subscribe("level_up", "LevelFlash", function()
        trigger_flash(0.3, 0.5, 1.0, 0.35)
    end, { 0.30, 0.50, 0.95 })

    -- combo_reached subscribers
    signal_subscribe("combo_reached", "BonusScore", function()
        signal_emit("score_up", { amount = BONUS_SCORE })
    end, { 1.00, 0.90, 0.20 })

    signal_subscribe("combo_reached", "SpecialEffect", function()
        trigger_flash(1.0, 0.85, 0.1, 0.6)
        local c = SIG_COLORS.combo_reached
        spawn_particles(GAME_AREA_W / 2, 180, c[1], c[2], c[3], 40, 120)
        spawn_float_text(GAME_AREA_W / 2 - 40, 160, "COMBO x5!", 1.0, 0.9, 0.1)
    end, { 1.00, 0.80, 0.15 })

    -- game_over subscribers
    signal_subscribe("game_over", "DeathEffect", function()
        trigger_flash(0.7, 0.05, 0.05, 0.8)
        spawn_particles(GAME_AREA_W / 2, SCREEN_H / 2, 0.9, 0.1, 0.1, 50, 150)
    end, { 0.75, 0.15, 0.10 })

    signal_subscribe("game_over", "FinalStats", function()
        spawn_float_text(GAME_AREA_W / 2 - 50, SCREEN_H / 2 - 40,
            "GAME OVER", 0.9, 0.15, 0.1)
    end, { 0.70, 0.10, 0.10 })

    signal_subscribe("game_over", "StateTransition", function()
        death_timer = 0
        current_state = STATE.GAME_OVER
    end, { 0.60, 0.10, 0.10 })
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
lurek.input.bind("hit",   "a")
lurek.input.bind("score", "s")
lurek.input.bind("level", "d")
lurek.input.bind("combo", "f")
lurek.input.bind("quit",  "escape")

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------

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

function lurek.init()
    _cam = lurek.camera.new()
    lurek.window.setTitle("Signal Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.06, 0.06, 0.10)
    _cam:setPosition(0, 0)
end

local function _ready_setup()
    -- Engine particle systems per signal type
    hit_ps = lurek.particle.newSystem({
        maxParticles = 200, emissionRate = 0,
        lifetimeMin = 0.3, lifetimeMax = 0.7,
        speedMin = 60, speedMax = 160,
        direction = 0, spread = math.pi * 2,
        gravityY = 120,
        sizes = { 4, 3, 1.5, 0.5 },
        colors = { { 0.95, 0.25, 0.20 }, { 1.0, 0.5, 0.2 }, { 0.8, 0.1, 0.0, 0.0 } },
    })
    score_ps = lurek.particle.newSystem({
        maxParticles = 150, emissionRate = 0,
        lifetimeMin = 0.4, lifetimeMax = 0.9,
        speedMin = 40, speedMax = 100,
        direction = math.pi * 1.5, spread = math.pi / 3,
        gravityY = -40,
        sizes = { 3, 2.5, 1, 0.3 },
        colors = { { 0.2, 1.0, 0.4 }, { 0.4, 0.9, 0.5 }, { 0.1, 0.6, 0.2, 0.0 } },
    })
    level_ps = lurek.particle.newSystem({
        maxParticles = 300, emissionRate = 0,
        lifetimeMin = 0.5, lifetimeMax = 1.2,
        speedMin = 80, speedMax = 200,
        direction = 0, spread = math.pi * 2,
        gravityY = 60,
        sizes = { 5, 4, 2, 0.5 },
        colors = { { 0.3, 0.5, 1.0 }, { 0.5, 0.7, 1.0 }, { 0.1, 0.2, 0.8, 0.0 } },
    })
    combo_ps = lurek.particle.newSystem({
        maxParticles = 250, emissionRate = 0,
        lifetimeMin = 0.4, lifetimeMax = 1.0,
        speedMin = 100, speedMax = 250,
        direction = 0, spread = math.pi * 2,
        gravityY = 0,
        sizes = { 6, 4, 2, 0.5 },
        colors = { { 1.0, 0.9, 0.2 }, { 1.0, 0.7, 0.1 }, { 0.8, 0.5, 0.0, 0.0 } },
    })

    register_subscribers()
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    if current_state == STATE.TITLE then
        title_timer = title_timer + dt
        title_alpha = clamp(title_timer / 0.8, 0, 1)
        if title_timer > 1.5 then
            current_state = STATE.PLAYING
        end
        return
    end

    if current_state == STATE.GAME_OVER then
        death_timer = death_timer + dt
        update_particles(dt)
        update_floating_texts(dt)
        return
    end

    -- PLAYING
    game_time = game_time + dt

    -- Background color lerp
    bg_color.r = lerp(bg_color.r, bg_target.r, dt * 2)
    bg_color.g = lerp(bg_color.g, bg_target.g, dt * 2)
    bg_color.b = lerp(bg_color.b, bg_target.b, dt * 2)
    lurek.render.setBackgroundColor(bg_color.r, bg_color.g, bg_color.b)

    -- Tween-driven display values
    if health_tween then
        health_display = health_tween.val or health_display
    end
    if score_tween then
        score_display = score_tween.val or score_display
    end

    -- Fire signals from input
    if lurek.input.wasActionPressed("hit") then
        signal_emit("player_hit")
        if hit_ps then hit_ps:emit(15, GAME_AREA_W / 2, 200) end
        if health <= 0 then
            signal_emit("game_over")
        end
    end
    if lurek.input.wasActionPressed("score") then
        signal_emit("score_up", { amount = SCORE_PER_HIT })
        if score_ps then score_ps:emit(10, GAME_AREA_W / 2, 250) end
    end
    if lurek.input.wasActionPressed("level") then
        signal_emit("level_up")
        if level_ps then level_ps:emit(25, GAME_AREA_W / 2, SCREEN_H / 2) end
    end
    if lurek.input.wasActionPressed("combo") then
        signal_emit("combo_reached", { combo = COMBO_THRESHOLD })
        if combo_ps then combo_ps:emit(30, GAME_AREA_W / 2, 180) end
    end

    -- Update effects
    update_particles(dt)
    update_floating_texts(dt)

    -- Update subscriber flash decay
    for sig_name, subs in pairs(subscriber_registry) do
        for _, sub in ipairs(subs) do
            sub.flash = clamp(sub.flash - dt * 3, 0, 1)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render — game scene
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE.TITLE then
        -- Title screen
        local a = title_alpha
        text_("SIGNAL DEMO", 180, 180, 40, 0.9 * a, 0.85 * a, 0.3 * a, a)
        text_("PUB-SUB EVENTS", 210, 240, 22, 0.6 * a, 0.6 * a, 0.7 * a, a * 0.8)
        text_("Press any signal key to begin...", 180, 320, 14,
            0.5 * a, 0.5 * a, 0.5 * a, a * 0.5)
        return
    end

    -- Game area background
    rect(10, 60, GAME_AREA_W - 20, 360, 0.08, 0.08, 0.12, 0.5)

    -- Health bar
    local bar_w = 200
    local bar_h = 20
    local bar_x = 30
    local bar_y = 80
    rect(bar_x, bar_y, bar_w, bar_h, 0.2, 0.05, 0.05, 0.8)
    local fill = clamp(health_display / MAX_HEALTH, 0, 1)
    local hr = lerp(0.9, 0.2, fill)
    local hg = lerp(0.15, 0.8, fill)
    rect(bar_x, bar_y, bar_w * fill, bar_h, hr, hg, 0.15, 0.9)
    text_("HP: " .. health .. "/" .. MAX_HEALTH, bar_x + 4, bar_y + 3, 13,
        1, 1, 1, 0.9)

    -- Score display
    text_("Score: " .. math.floor(score_display), 30, 115, 18,
        0.2, 0.95, 0.4, 0.9)

    -- Combo display
    local combo_a = combo > 0 and 1.0 or 0.4
    text_("Combo: " .. combo .. "/" .. COMBO_THRESHOLD, 30, 145, 15,
        1.0, 0.85, 0.1, combo_a)

    -- Level / Speed
    text_("Level: " .. level, 30, 172, 14, 0.4, 0.6, 1.0, 0.8)
    text_(string.format("Speed: %.0f%%", game_speed * 100), 150, 172, 14,
        0.5, 0.5, 0.6, 0.7)

    -- Signal key hints
    local hint_y = 210
    local hints = {
        { key = "[A]", sig = "player_hit",    col = SIG_COLORS.player_hit },
        { key = "[S]", sig = "score_up",      col = SIG_COLORS.score_up },
        { key = "[D]", sig = "level_up",      col = SIG_COLORS.level_up },
        { key = "[F]", sig = "combo_reached", col = SIG_COLORS.combo_reached },
    }
    for _, h in ipairs(hints) do
        text_(h.key .. " " .. h.sig, 30, hint_y, 13,
            h.col[1], h.col[2], h.col[3], 0.8)
        hint_y = hint_y + 20
    end

    -- Manual particles
    for _, p in ipairs(particles) do
        rect(
            p.x - p.size / 2, p.y - p.size / 2,
            p.size, p.size,
            p.r, p.g, p.b, p.a
        )
    end

    -- Floating texts
    for _, ft in ipairs(floating_texts) do
        text_(ft.text, ft.x, ft.y, 16,
            ft.r, ft.g, ft.b, ft.a)
    end

    -- Engine particle systems
    if hit_ps then hit_ps:draw() end
    if score_ps then score_ps:draw() end
    if level_ps then level_ps:draw() end
    if combo_ps then combo_ps:draw() end

    -- Screen flash overlay
    if screen_flash.a > 0.01 then
        rect(0, 0, SCREEN_W, SCREEN_H,
            screen_flash.r, screen_flash.g, screen_flash.b, screen_flash.a)
    end

    -- Game Over overlay
    if current_state == STATE.GAME_OVER then
        local oa = clamp(death_timer / 0.8, 0, 0.7)
        rect(0, 0, SCREEN_W, SCREEN_H, 0.05, 0.02, 0.02, oa)
        local ta = clamp(death_timer / 1.0, 0, 1)
        text_("GAME OVER", 240, 200, 42, 0.9, 0.12, 0.1, ta)
        text_("Final Score: " .. score, 270, 260, 22, 1, 1, 1, ta * 0.9)
        text_("Signals fired: " .. stats.fired, 270, 295, 15,
            0.7, 0.7, 0.7, ta * 0.7)
        text_("Chain reactions: " .. stats.chain_reactions, 270, 315, 15,
            0.7, 0.7, 0.7, ta * 0.7)
        text_("Level reached: " .. level, 270, 335, 15,
            0.7, 0.7, 0.7, ta * 0.7)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI — panels (subscriber list, event log, stats)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state == STATE.TITLE then return end

    local fps = lurek.timer.getFPS and lurek.timer.getFPS() or 0
    text_(string.format("FPS: %d", fps), SCREEN_W - 80, 8, 12,
        0.5, 0.5, 0.5, 0.6)

    -- ── Right panel: subscriber list ──
    rect(RIGHT_PANEL_X, 50, RIGHT_PANEL_W, LOG_PANEL_Y - 60,
        0.10, 0.10, 0.14, 0.7)
    text_("SUBSCRIBERS", RIGHT_PANEL_X + 8, 55, 14,
        0.8, 0.8, 0.9, 0.9)

    local sy = 78
    local signal_order = { "player_hit", "score_up", "level_up", "combo_reached", "game_over" }
    for _, sig_name in ipairs(signal_order) do
        local subs = subscriber_registry[sig_name] or {}
        local sc = SIG_COLORS[sig_name] or { 0.6, 0.6, 0.6 }

        -- Signal header
        rect(RIGHT_PANEL_X + 8, sy + 2, 8, 8, sc[1], sc[2], sc[3], 0.9)
        text_(sig_name, RIGHT_PANEL_X + 22, sy, 12,
            sc[1], sc[2], sc[3], 0.85)
        sy = sy + 16

        -- Subscriber entries
        for _, sub in ipairs(subs) do
            local dot_a = 0.4 + sub.flash * 0.6
            local dot_r = lerp(sub.color[1] * 0.5, sub.color[1], sub.flash)
            local dot_g = lerp(sub.color[2] * 0.5, sub.color[2], sub.flash)
            local dot_b = lerp(sub.color[3] * 0.5, sub.color[3], sub.flash)
            rect(RIGHT_PANEL_X + 18, sy + 3, 5, 5,
                dot_r, dot_g, dot_b, dot_a)
            text_(sub.name, RIGHT_PANEL_X + 28, sy, 11,
                0.6, 0.6, 0.65, 0.5 + sub.flash * 0.5)
            sy = sy + 14
        end
        sy = sy + 4
    end

    -- ── Bottom panel: event log ──
    rect(10, LOG_PANEL_Y, SCREEN_W - 20, LOG_PANEL_H,
        0.10, 0.10, 0.14, 0.7)
    text_("EVENT LOG", 20, LOG_PANEL_Y + 5, 13,
        0.8, 0.8, 0.9, 0.9)

    local ly = LOG_PANEL_Y + 24
    for i, ev in ipairs(event_log) do
        if ly > LOG_PANEL_Y + LOG_PANEL_H - 12 then break end
        local ec = SIG_COLORS[ev.signal] or { 0.6, 0.6, 0.6 }
        local chain_tag = ev.chain and " [CHAIN]" or ""
        local age = clamp(1 - (i - 1) / LOG_MAX, 0.3, 1.0)
        rect(20, ly + 2, 6, 6, ec[1], ec[2], ec[3], age)
        text_(
            format_time(ev.time) .. "  " .. ev.signal .. chain_tag,
            32, ly, 11,
            ec[1] * 0.8, ec[2] * 0.8, ec[3] * 0.8, age * 0.85
        )
        ly = ly + 13
    end

    -- ── Stats bar ──
    rect(10, 30, SCREEN_W - 20, 22, 0.08, 0.08, 0.12, 0.6)
    text_(
        string.format("Signals: %d  |  Subscribers: %d  |  Chains: %d  |  Time: %s",
            stats.fired, stats.subscribers, stats.chain_reactions, format_time(game_time)),
        20, 34, 13, 0.7, 0.7, 0.75, 0.85
    )
end
