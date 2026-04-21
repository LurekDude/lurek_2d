-- ============================================================================
-- Hello World — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/hello_world/main.lua
-- Run with : cargo run -- content/games/showcase/hello_world
-- ============================================================================
-- Complete hello world engine feature sampler: animated text, shapes, mouse
-- tracking, particle bursts, tween animations, camera, and input bindings.
-- Controls: Space randomize BG, 1-5 spawn shapes, C cycle palette,
--           +/- speed, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, RUNNING = 2 }
local current_state = STATE.TITLE

-- 8-color palette
local PALETTE = {
    { 1.0, 0.3, 0.3 },   -- red
    { 1.0, 0.6, 0.2 },   -- orange
    { 1.0, 1.0, 0.3 },   -- yellow
    { 0.3, 1.0, 0.4 },   -- green
    { 0.3, 0.8, 1.0 },   -- cyan
    { 0.4, 0.4, 1.0 },   -- blue
    { 0.8, 0.3, 1.0 },   -- purple
    { 1.0, 0.5, 0.8 },   -- pink
}
local palette_index = 1

-- Background
local bg = { r = 0.08, g = 0.08, b = 0.12 }

-- Speed multiplier
local speed_mult = 1.0

-- Timer
local anim_timer = 0

-- Shape counter
local shape_count = 0

-- ---------------------------------------------------------------------------
-- Rainbow header text
-- ---------------------------------------------------------------------------
local header_text = "HELLO LUREK2D!"
local header_color = { r = 1, g = 0.3, b = 0.3 }
local header_scale = { s = 1.0 }

-- ---------------------------------------------------------------------------
-- Orbiting rectangle
-- ---------------------------------------------------------------------------
local orbit = {
    cx = SCREEN_W / 2, cy = SCREEN_H / 2 + 30,
    radius = 100, angle = 0, size = 24,
}

-- ---------------------------------------------------------------------------
-- Bouncing circle
-- ---------------------------------------------------------------------------
local ball = {
    x = 200, y = 300, vx = 160, vy = 120, r = 14,
}

-- ---------------------------------------------------------------------------
-- Sine-wave grid
-- ---------------------------------------------------------------------------
local GRID_COLS, GRID_ROWS = 12, 4
local GRID_X, GRID_Y = 120, 400
local GRID_SPACING = 16
local GRID_BASE_SIZE = 8

-- ---------------------------------------------------------------------------
-- Mouse follower
-- ---------------------------------------------------------------------------
local follower = { x = SCREEN_W / 2, y = SCREEN_H / 2 }
local mouse = { x = SCREEN_W / 2, y = SCREEN_H / 2 }
local LERP_SPEED = 6

-- ---------------------------------------------------------------------------
-- Spawned shapes
-- ---------------------------------------------------------------------------
local shapes = {}

-- ---------------------------------------------------------------------------
-- Engine objects
-- ---------------------------------------------------------------------------
local camera = nil
local ps_confetti = nil
local ps_spawn = nil

-- Title tween values
local title_alpha = { a = 1.0 }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function lerp(a, b, t) return a + (b - a) * t end

local function random_color()
    return PALETTE[math.random(1, #PALETTE)]
end

local function hsv_to_rgb(h)
    -- Simple hue-only HSV → RGB (s=1, v=1)
    local s = h * 6
    local c = math.floor(s)
    local f = s - c
    local r, g, b = 1, 1, 1
    if     c == 0 then r, g, b = 1, f, 0
    elseif c == 1 then r, g, b = 1 - f, 1, 0
    elseif c == 2 then r, g, b = 0, 1, f
    elseif c == 3 then r, g, b = 0, 1 - f, 1
    elseif c == 4 then r, g, b = f, 0, 1
    else               r, g, b = 1, 0, 1 - f
    end
    return r, g, b
end

-- ---------------------------------------------------------------------------
-- Shape spawning
-- ---------------------------------------------------------------------------
local function spawn_shape(kind)
    local x = math.random(60, SCREEN_W - 60)
    local y = math.random(100, SCREEN_H - 100)
    local col = random_color()
    local s = {
        kind = kind, x = x, y = y,
        col = col, scale = 0.0, rot = 0, size = math.random(16, 32),
        age = 0,
    }
    shapes[#shapes + 1] = s
    shape_count = shape_count + 1

    -- Scale-bounce tween on spawn
    lurek.tween.to(s, 0.4, { scale = 1.0 }, "outBack")

    -- Particle burst at spawn point
    if ps_spawn then ps_spawn:emit(x, y, 15) end
end

-- ---------------------------------------------------------------------------
-- Background randomize with confetti
-- ---------------------------------------------------------------------------
local function randomize_background()
    bg.r = 0.05 + math.random() * 0.2
    bg.g = 0.05 + math.random() * 0.2
    bg.b = 0.05 + math.random() * 0.2
    lurek.render.setBackgroundColor(bg.r, bg.g, bg.b)

    -- Confetti burst
    if ps_confetti then
        for i = 1, 5 do
            ps_confetti:emit(math.random(50, SCREEN_W - 50), math.random(50, SCREEN_H - 50), 12)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Hello World — Lurek2D")
    lurek.render.setBackgroundColor(bg.r, bg.g, bg.b)

    -- Input bindings
    lurek.input.bind("randomize",  { "space" })
    lurek.input.bind("shape_rect", { "1" })
    lurek.input.bind("shape_circ", { "2" })
    lurek.input.bind("shape_line", { "3" })
    lurek.input.bind("shape_tri",  { "4" })
    lurek.input.bind("shape_poly", { "5" })
    lurek.input.bind("cycle_col",  { "c" })
    lurek.input.bind("faster",     { "equal" })  -- + key
    lurek.input.bind("slower",     { "minus" })
    lurek.input.bind("quit",       { "escape" })
    lurek.input.bind("start",      { "return" })

    -- Camera
    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Confetti particles (background change)
    ps_confetti = lurek.particle.newSystem({
        maxParticles = 200, emissionRate = 0,
        lifetimeMin = 0.5, lifetimeMax = 1.2,
        speedMin = 60, speedMax = 200, direction = -1.57, spread = 6.28,
        gravityY = 150,
        sizes = { 5, 3, 0 },
        colors = { 1, 0.8, 0.2, 1, 0.9, 0.3, 0.5, 0 },
    })

    -- Shape spawn burst particles
    ps_spawn = lurek.particle.newSystem({
        maxParticles = 120, emissionRate = 0,
        lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 40, speedMax = 140, direction = 0, spread = 6.28,
        sizes = { 4, 2, 0 },
        colors = { 1, 1, 0.6, 1, 0.5, 0.8, 1.0, 0 },
    })
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
function lurek.ready()
    -- Start header color cycling tween (loops via callback restart)
    local function cycle_header()
        lurek.tween.to(header_color, 2.0, { r = math.random(), g = math.random(), b = math.random() }, "inOutSine", function()
            cycle_header()
        end)
    end
    cycle_header()
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    local sdt = dt * speed_mult

    -- Global quit
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Update particles & tweens
    ps_confetti:update(dt)
    ps_spawn:update(dt)
    lurek.tween.update(dt)

    -- Mouse position
    mouse.x, mouse.y = lurek.input.getMousePosition()

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("start") then
            current_state = STATE.RUNNING
            -- Bounce the header on transition
            header_scale.s = 1.5
            lurek.tween.to(header_scale, 0.5, { s = 1.0 }, "outElastic")
        end
        return
    end

    -- ── RUNNING ───────────────────────────────────────────────
    anim_timer = anim_timer + sdt

    -- Input: randomize background
    if lurek.input.wasActionPressed("randomize") then
        randomize_background()
    end

    -- Input: spawn shapes (1-5)
    if lurek.input.wasActionPressed("shape_rect") then spawn_shape("rect") end
    if lurek.input.wasActionPressed("shape_circ") then spawn_shape("circle") end
    if lurek.input.wasActionPressed("shape_line") then spawn_shape("line") end
    if lurek.input.wasActionPressed("shape_tri")  then spawn_shape("triangle") end
    if lurek.input.wasActionPressed("shape_poly") then spawn_shape("polygon") end

    -- Input: cycle palette
    if lurek.input.wasActionPressed("cycle_col") then
        palette_index = palette_index % #PALETTE + 1
    end

    -- Input: speed control
    if lurek.input.wasActionPressed("faster") then
        speed_mult = clamp(speed_mult + 0.25, 0.25, 4.0)
    end
    if lurek.input.wasActionPressed("slower") then
        speed_mult = clamp(speed_mult - 0.25, 0.25, 4.0)
    end

    -- Orbiting rectangle
    orbit.angle = orbit.angle + 1.2 * sdt

    -- Bouncing circle
    ball.x = ball.x + ball.vx * sdt
    ball.y = ball.y + ball.vy * sdt
    if ball.x - ball.r < 0 then ball.x = ball.r; ball.vx = -ball.vx end
    if ball.x + ball.r > SCREEN_W then ball.x = SCREEN_W - ball.r; ball.vx = -ball.vx end
    if ball.y - ball.r < 0 then ball.y = ball.r; ball.vy = -ball.vy end
    if ball.y + ball.r > SCREEN_H then ball.y = SCREEN_H - ball.r; ball.vy = -ball.vy end

    -- Mouse follower (smooth lerp)
    local lt = clamp(LERP_SPEED * dt, 0, 1)
    follower.x = lerp(follower.x, mouse.x, lt)
    follower.y = lerp(follower.y, mouse.y, lt)

    -- Age shapes
    for i = 1, #shapes do
        shapes[i].age = shapes[i].age + sdt
        shapes[i].rot = shapes[i].rot + 1.5 * sdt
    end
end

-- ---------------------------------------------------------------------------
-- Render (world space — shapes)
-- ---------------------------------------------------------------------------
function lurek.render()
    camera:attach()

    if current_state ~= STATE.RUNNING then
        camera:detach()
        return
    end

    local time = lurek.timer.getTime()

    -- ── Sine-wave grid ────────────────────────────────────────
    for row = 0, GRID_ROWS - 1 do
        for col = 0, GRID_COLS - 1 do
            local gx = GRID_X + col * (GRID_SPACING + GRID_BASE_SIZE)
            local gy = GRID_Y + row * (GRID_SPACING + GRID_BASE_SIZE)
            local wave = math.sin(time * 3 * speed_mult + col * 0.5 + row * 0.7)
            local sz = GRID_BASE_SIZE + wave * 4
            local bright = 0.5 + wave * 0.3
            local hr, hg, hb = hsv_to_rgb(((col + row * GRID_COLS) / (GRID_COLS * GRID_ROWS) + time * 0.1) % 1.0)
            lurek.render.setColor(hr * bright, hg * bright, hb * bright, 0.9)
            lurek.render.drawRect("fill", gx - sz / 2, gy - sz / 2, sz, sz)
        end
    end

    -- ── Orbiting rectangle ────────────────────────────────────
    local ox = orbit.cx + math.cos(orbit.angle) * orbit.radius
    local oy = orbit.cy + math.sin(orbit.angle) * orbit.radius
    local pcol = PALETTE[palette_index]
    lurek.render.setColor(pcol[1], pcol[2], pcol[3], 0.9)
    lurek.render.drawRect("fill", ox - orbit.size / 2, oy - orbit.size / 2, orbit.size, orbit.size)
    lurek.render.setColor(1, 1, 1, 0.4)
    lurek.render.drawRect("line", ox - orbit.size / 2, oy - orbit.size / 2, orbit.size, orbit.size)

    -- ── Bouncing circle ───────────────────────────────────────
    lurek.render.setColor(0.3, 0.85, 1.0, 0.9)
    lurek.render.drawCircle("fill", ball.x, ball.y, ball.r)
    lurek.render.setColor(1, 1, 1, 0.3)
    lurek.render.drawCircle("line", ball.x, ball.y, ball.r + 2)

    -- ── Mouse follower ────────────────────────────────────────
    local fpulse = 0.6 + 0.4 * math.sin(time * 5)
    lurek.render.setColor(1.0, 0.8, 0.2, fpulse)
    lurek.render.drawCircle("fill", follower.x, follower.y, 10)
    lurek.render.setColor(1, 1, 1, 0.5)
    lurek.render.drawCircle("line", follower.x, follower.y, 14)

    -- ── Spawned shapes ────────────────────────────────────────
    for i = 1, #shapes do
        local s = shapes[i]
        local sc = s.scale
        local c = s.col
        lurek.render.setColor(c[1], c[2], c[3], 0.85)

        if s.kind == "rect" then
            local hw = s.size * sc / 2
            lurek.render.drawRect("fill", s.x - hw, s.y - hw, s.size * sc, s.size * sc)

        elseif s.kind == "circle" then
            lurek.render.drawCircle("fill", s.x, s.y, s.size * sc / 2)

        elseif s.kind == "line" then
            local len = s.size * sc
            local dx = math.cos(s.rot) * len
            local dy = math.sin(s.rot) * len
            lurek.render.drawLine(s.x - dx, s.y - dy, s.x + dx, s.y + dy)

        elseif s.kind == "triangle" then
            local r = s.size * sc / 2
            local x1 = s.x + math.cos(s.rot) * r
            local y1 = s.y + math.sin(s.rot) * r
            local x2 = s.x + math.cos(s.rot + 2.094) * r
            local y2 = s.y + math.sin(s.rot + 2.094) * r
            local x3 = s.x + math.cos(s.rot + 4.189) * r
            local y3 = s.y + math.sin(s.rot + 4.189) * r
            lurek.render.drawLine(x1, y1, x2, y2)
            lurek.render.drawLine(x2, y2, x3, y3)
            lurek.render.drawLine(x3, y3, x1, y1)

        elseif s.kind == "polygon" then
            local r = s.size * sc / 2
            local sides = 6
            local step = 6.2832 / sides
            for n = 0, sides - 1 do
                local a1 = s.rot + n * step
                local a2 = s.rot + (n + 1) * step
                lurek.render.drawLine(
                    s.x + math.cos(a1) * r, s.y + math.sin(a1) * r,
                    s.x + math.cos(a2) * r, s.y + math.sin(a2) * r
                )
            end
        end
    end

    -- ── Particles ─────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1, 1)
    ps_confetti:draw()
    ps_spawn:draw()

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space — HUD and text)
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    local time = lurek.timer.getTime()

    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(1.0, 0.85, 0.3, 1)
        lurek.render.print("HELLO WORLD", SCREEN_W / 2 - 100, SCREEN_H / 2 - 60, 32)

        lurek.render.setColor(0.7, 0.65, 0.5, 1)
        lurek.render.print("YOUR FIRST LUREK2D APP", SCREEN_W / 2 - 130, SCREEN_H / 2 - 10, 20)

        local blink = 0.5 + 0.5 * math.sin(time * 4)
        lurek.render.setColor(1, 1, 1, blink)
        lurek.render.print("Press Enter to Start", SCREEN_W / 2 - 90, SCREEN_H / 2 + 60, 16)

        -- Version
        lurek.render.setColor(0.4, 0.4, 0.4, 0.6)
        lurek.render.print("Lurek2D Engine Showcase", SCREEN_W / 2 - 80, SCREEN_H - 40, 12)
        return
    end

    -- ── RUNNING HUD ───────────────────────────────────────────

    -- Rainbow header text (center top)
    local hs = header_scale.s
    local hc = header_color
    lurek.render.setColor(hc.r, hc.g, hc.b, 1)
    lurek.render.print(header_text, SCREEN_W / 2 - 110, 16, math.floor(28 * hs))

    -- Shape counter (top left)
    lurek.render.setColor(0.9, 0.9, 0.9, 0.9)
    lurek.render.print("Shapes: " .. tostring(shape_count), 16, 16, 16)

    -- Animation timer (top left, second row)
    lurek.render.print("Time: " .. string.format("%.1f", anim_timer) .. "s", 16, 38, 14)

    -- Speed multiplier
    lurek.render.print("Speed: " .. string.format("%.2f", speed_mult) .. "x", 16, 56, 14)

    -- Active palette color swatch
    local pcol = PALETTE[palette_index]
    lurek.render.setColor(pcol[1], pcol[2], pcol[3], 1)
    lurek.render.drawRect("fill", 16, 78, 14, 14)
    lurek.render.setColor(0.9, 0.9, 0.9, 0.8)
    lurek.render.print("Palette " .. tostring(palette_index), 36, 78, 14)

    -- Controls reminder (bottom left)
    lurek.render.setColor(0.6, 0.6, 0.6, 0.6)
    lurek.render.print("Space: BG  1-5: Shapes  C: Color  +/-: Speed", 16, SCREEN_H - 24, 12)

    -- FPS (bottom right)
    lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
    lurek.render.print("FPS: " .. tostring(lurek.timer.getFPS()), SCREEN_W - 80, SCREEN_H - 24, 12)
end
