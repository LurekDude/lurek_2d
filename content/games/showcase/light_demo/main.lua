-- ============================================================================
-- Light Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/light_demo/main.lua
-- Run with : cargo run -- content/games/showcase/light_demo
-- ============================================================================
-- Complete 2D lighting system demo: point lights, spotlights, flickering
-- torches, shadow-casting walls, ambient control, and light color blending.
-- Controls: WASD move, 1-4 colors, T torches, S spotlight, A ambient tint,
--           Q/E radius, +/- ambient level, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
-- Capture lurek.render API table before `function lurek.render()` shadows it.
local gfx = lurek.render

local SCREEN_W, SCREEN_H = 800, 600
local PLAYER_SPEED = 200
local MIN_RADIUS, MAX_RADIUS = 100, 400
local RADIUS_STEP = 20
local SPOTLIGHT_ANGLE = math.pi / 3  -- 60 degrees

local STATE = { TITLE = 1, RUNNING = 2 }
local current_state = STATE.TITLE

-- ---------------------------------------------------------------------------
-- Light colors
-- ---------------------------------------------------------------------------
local LIGHT_COLORS = {
    { 1.0, 1.0, 1.0, "White" },
    { 1.0, 0.3, 0.2, "Red" },
    { 0.3, 0.5, 1.0, "Blue" },
    { 0.3, 1.0, 0.4, "Green" },
}
local color_index = 1

-- Ambient tints: { r, g, b, name }
local AMBIENT_TINTS = {
    { 1.0, 1.0, 1.0, "Neutral" },
    { 1.0, 0.85, 0.6, "Warm" },
    { 0.6, 0.8, 1.0, "Cool" },
    { 0.5, 1.0, 0.5, "Eerie" },
}
local ambient_tint_index = 1

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local player = { x = 400, y = 300 }
local ambient_level = 0.1
local light_radius = 200
local spotlight_mode = false
local torches_on = true
local player_light = nil
local torch_lights = {}
local torch_particles = {}
local glow_particles = nil
local occluders = {}
local camera = nil

-- Wall definitions: { x, y, w, h }
local WALLS = {
    { 100,  80, 120,  20 },
    { 350,  60,  20, 140 },
    { 550, 120, 160,  20 },
    { 680, 200,  20, 180 },
    {  60, 280, 140,  20 },
    { 250, 350,  20, 160 },
    { 450, 400, 180,  20 },
    { 100, 480, 120,  20 },
    { 600, 500,  20, 100 },
    { 350, 540, 160,  20 },
}

-- Torch positions: { x, y }
local TORCH_POSITIONS = {
    { 160,  70 },
    { 360,  50 },
    { 630, 110 },
    {  70, 270 },
    { 260, 340 },
    { 540, 390 },
}

-- Tween state for smooth transitions
local ambient_tween = { r = 0.1, g = 0.1, b = 0.1 }
local color_tween = { r = 1.0, g = 1.0, b = 1.0 }
local title_timer = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function lerp(a, b, t) return a + (b - a) * t end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Light Demo — Lurek2D")
    gfx.setBackgroundColor(0.02, 0.02, 0.04)

    -- Input bindings
    lurek.input.bind("move_up",       { "w" })
    lurek.input.bind("move_down",     { "s" })
    lurek.input.bind("move_left",     { "a" })
    lurek.input.bind("move_right",    { "d" })
    lurek.input.bind("torches",       { "t" })
    lurek.input.bind("color_white",   { "1" })
    lurek.input.bind("color_red",     { "2" })
    lurek.input.bind("color_blue",    { "3" })
    lurek.input.bind("color_green",   { "4" })
    lurek.input.bind("radius_down",   { "q" })
    lurek.input.bind("radius_up",     { "e" })
    lurek.input.bind("spotlight",     { "f" })
    lurek.input.bind("ambient_tint",  { "r" })
    lurek.input.bind("ambient_up",    { "equal" })
    lurek.input.bind("ambient_down",  { "minus" })
    lurek.input.bind("quit",          { "escape" })
    lurek.input.bind("start",         { "return" })

    -- Camera
    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Enable lighting system
    lurek.light.setEnabled(true)
    lurek.light.setAmbient(0.1, 0.1, 0.1, 1.0)

    -- Player light
    player_light = lurek.light.newLight()
    player_light:setLightType("point")
    player_light:setPosition(player.x, player.y)
    player_light:setRadius(light_radius)
    player_light:setIntensity(1.0)
    player_light:setColor(1.0, 1.0, 1.0)
    player_light:setBlendMode("additive")
    player_light:setShadowEnabled(true)

    -- Create torches (orange flickering lights)
    for i, pos in ipairs(TORCH_POSITIONS) do
        local t = lurek.light.newLight()
        t:setLightType("point")
        t:setPosition(pos[1], pos[2])
        t:setRadius(120)
        t:setIntensity(0.85)
        t:setColor(1.0, 0.6, 0.2)
        t:setBlendMode("additive")
        t:setFlicker(0.7, 1.0, 5.0)
        t:setFlickerEnabled(true)
        torch_lights[i] = t

        -- Torch flame particles
        local ps = lurek.particle.newSystem({
            maxParticles = 40, emissionRate = 20,
            lifetimeMin = 0.2, lifetimeMax = 0.6,
            speedMin = 10, speedMax = 40,
            direction = -1.57, spread = 0.8,
            gravityY = -30,
            sizes = { 4, 3, 1, 0 },
            colors = { 1, 0.7, 0.2, 1,  1, 0.4, 0.1, 0.7,  0.6, 0.1, 0.0, 0 },
        })
        torch_particles[i] = { system = ps, x = pos[1], y = pos[2] }
    end

    -- Player glow particles
    glow_particles = lurek.particle.newSystem({
        maxParticles = 30, emissionRate = 15,
        lifetimeMin = 0.3, lifetimeMax = 0.8,
        speedMin = 5, speedMax = 25,
        direction = 0, spread = 6.28,
        sizes = { 3, 2, 0 },
        colors = { 1, 1, 0.8, 0.6,  0.8, 0.8, 1.0, 0 },
    })

    -- Create wall occluders
    for i, w in ipairs(WALLS) do
        local occ = lurek.light.newOccluder()
        occ:setVertices({
            w[1],        w[2],
            w[1] + w[3], w[2],
            w[1] + w[3], w[2] + w[4],
            w[1],        w[2] + w[4],
        })
        occ:setEnabled(true)
        occluders[i] = occ
    end
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
function lurek.ready()
    -- Initial ambient color tween target
    local tint = AMBIENT_TINTS[ambient_tint_index]
    ambient_tween.r = ambient_level * tint[1]
    ambient_tween.g = ambient_level * tint[2]
    ambient_tween.b = ambient_level * tint[3]
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Global quit
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Update tweens & flickers
    lurek.tween.update(dt)
    lurek.light.advanceFlickers(dt)

    -- Update particles
    glow_particles:update(dt)
    for _, tp in ipairs(torch_particles) do
        tp.system:update(dt)
    end

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        title_timer = title_timer + dt
        if lurek.input.wasActionPressed("start") then
            current_state = STATE.RUNNING
        end
        return
    end

    -- ── RUNNING ───────────────────────────────────────────────

    -- Player movement (WASD via held check)
    local dx, dy = 0, 0
    if lurek.input.isActionDown("move_up")    then dy = dy - 1 end
    if lurek.input.isActionDown("move_down")  then dy = dy + 1 end
    if lurek.input.isActionDown("move_left")  then dx = dx - 1 end
    if lurek.input.isActionDown("move_right") then dx = dx + 1 end

    -- Normalize diagonal
    if dx ~= 0 and dy ~= 0 then
        local inv = 1.0 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end

    player.x = clamp(player.x + dx * PLAYER_SPEED * dt, 10, SCREEN_W - 10)
    player.y = clamp(player.y + dy * PLAYER_SPEED * dt, 10, SCREEN_H - 10)

    -- Update player light position
    player_light:setPosition(player.x, player.y)

    -- Spotlight direction: towards mouse
    if spotlight_mode then
        local mx, my = lurek.input.getMousePosition()
        local angle = math.atan2(my - player.y, mx - player.x)
        player_light:setDirection(angle)
    end

    -- Emit glow at player position
    glow_particles:emit(player.x, player.y, 1)

    -- Toggle torches
    if lurek.input.wasActionPressed("torches") then
        torches_on = not torches_on
        for _, t in ipairs(torch_lights) do
            t:setEnabled(torches_on)
            t:setFlickerEnabled(torches_on)
        end
    end

    -- Light color selection (1-4) with smooth tween
    local new_color = nil
    if lurek.input.wasActionPressed("color_white") then new_color = 1 end
    if lurek.input.wasActionPressed("color_red")   then new_color = 2 end
    if lurek.input.wasActionPressed("color_blue")  then new_color = 3 end
    if lurek.input.wasActionPressed("color_green") then new_color = 4 end
    if new_color and new_color ~= color_index then
        color_index = new_color
        local c = LIGHT_COLORS[color_index]
        lurek.tween.to(color_tween, 0.4, { r = c[1], g = c[2], b = c[3] }, "inOutSine")
    end
    player_light:setColor(color_tween.r, color_tween.g, color_tween.b)

    -- Light radius (Q/E or scroll)
    if lurek.input.wasActionPressed("radius_down") then
        light_radius = clamp(light_radius - RADIUS_STEP, MIN_RADIUS, MAX_RADIUS)
        player_light:setRadius(light_radius)
    end
    if lurek.input.wasActionPressed("radius_up") then
        light_radius = clamp(light_radius + RADIUS_STEP, MIN_RADIUS, MAX_RADIUS)
        player_light:setRadius(light_radius)
    end
    local scroll = lurek.input.getMouseScroll()
    if scroll ~= 0 then
        light_radius = clamp(light_radius + scroll * RADIUS_STEP, MIN_RADIUS, MAX_RADIUS)
        player_light:setRadius(light_radius)
    end

    -- Toggle spotlight mode
    if lurek.input.wasActionPressed("spotlight") then
        spotlight_mode = not spotlight_mode
        if spotlight_mode then
            player_light:setLightType("spot")
            player_light:setInnerAngle(SPOTLIGHT_ANGLE * 0.4)
            player_light:setOuterAngle(SPOTLIGHT_ANGLE)
        else
            player_light:setLightType("point")
        end
    end

    -- Ambient tint cycling
    if lurek.input.wasActionPressed("ambient_tint") then
        ambient_tint_index = ambient_tint_index % #AMBIENT_TINTS + 1
        local tint = AMBIENT_TINTS[ambient_tint_index]
        lurek.tween.to(ambient_tween, 0.6, {
            r = ambient_level * tint[1],
            g = ambient_level * tint[2],
            b = ambient_level * tint[3],
        }, "inOutSine")
    end

    -- Ambient level (+/-)
    local ambient_changed = false
    if lurek.input.wasActionPressed("ambient_up") then
        ambient_level = clamp(ambient_level + 0.05, 0.0, 1.0)
        ambient_changed = true
    end
    if lurek.input.wasActionPressed("ambient_down") then
        ambient_level = clamp(ambient_level - 0.05, 0.0, 1.0)
        ambient_changed = true
    end
    if ambient_changed then
        local tint = AMBIENT_TINTS[ambient_tint_index]
        lurek.tween.to(ambient_tween, 0.3, {
            r = ambient_level * tint[1],
            g = ambient_level * tint[2],
            b = ambient_level * tint[3],
        }, "inOutSine")
    end

    -- Apply ambient
    lurek.light.setAmbient(ambient_tween.r, ambient_tween.g, ambient_tween.b, 1.0)
end

-- ---------------------------------------------------------------------------
-- Render (world space — scene, walls, lights, shadows)
-- ---------------------------------------------------------------------------
function lurek.render()
    camera:attach()

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        -- Dark background with subtle animated shapes
        local time = title_timer
        for i = 1, 8 do
            local pulse = 0.03 + 0.02 * math.sin(time * 2 + i * 0.8)
            gfx.setColor(pulse, pulse, pulse * 1.5, 0.4)
            local cx = 100 + (i - 1) * 90
            local cy = 300 + math.sin(time * 1.5 + i) * 60
            gfx.drawCircle("fill", cx, cy, 30 + math.sin(time + i) * 10)
        end
        camera:detach()
        return
    end

    -- ── RUNNING ───────────────────────────────────────────────

    -- Draw room floor (subtle grid pattern)
    gfx.setColor(0.06, 0.06, 0.08, 0.5)
    for gx = 0, SCREEN_W, 40 do
        gfx.drawLine(gx, 0, gx, SCREEN_H)
    end
    for gy = 0, SCREEN_H, 40 do
        gfx.drawLine(0, gy, SCREEN_W, gy)
    end

    -- Draw walls
    for _, w in ipairs(WALLS) do
        gfx.setColor(0.25, 0.22, 0.18, 1.0)
        gfx.drawRect("fill", w[1], w[2], w[3], w[4])
        gfx.setColor(0.35, 0.30, 0.25, 1.0)
        gfx.drawRect("line", w[1], w[2], w[3], w[4])
    end

    -- Draw torch markers (small orange squares at torch positions)
    if torches_on then
        for _, pos in ipairs(TORCH_POSITIONS) do
            gfx.setColor(0.6, 0.35, 0.1, 1.0)
            gfx.drawRect("fill", pos[1] - 4, pos[2] - 4, 8, 8)
            gfx.setColor(1.0, 0.7, 0.3, 0.8)
            gfx.drawRect("line", pos[1] - 5, pos[2] - 5, 10, 10)
        end

        -- Draw torch flame particles
        gfx.setColor(1, 1, 1, 1)
        for _, tp in ipairs(torch_particles) do
            tp.system:draw()
        end
    end

    -- Draw player
    local pc = LIGHT_COLORS[color_index]
    gfx.setColor(pc[1], pc[2], pc[3], 1.0)
    gfx.drawCircle("fill", player.x, player.y, 8)
    gfx.setColor(1.0, 1.0, 1.0, 0.5)
    gfx.drawCircle("line", player.x, player.y, 10)

    -- Spotlight direction indicator
    if spotlight_mode then
        local mx, my = lurek.input.getMousePosition()
        local angle = math.atan2(my - player.y, mx - player.x)
        local ex = player.x + math.cos(angle) * 30
        local ey = player.y + math.sin(angle) * 30
        gfx.setColor(pc[1], pc[2], pc[3], 0.6)
        gfx.drawLine(player.x, player.y, ex, ey)
    end

    -- Player glow particles
    gfx.setColor(1, 1, 1, 1)
    glow_particles:draw()

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space — HUD, controls, stats)
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    local time = lurek.timer.getTime()

    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        -- Title
        gfx.setColor(1.0, 0.85, 0.3, 1)
        gfx.print("LIGHT DEMO", SCREEN_W / 2 - 90, SCREEN_H / 2 - 80, 32)

        -- Subtitle
        gfx.setColor(0.7, 0.6, 0.4, 1)
        gfx.print("ILLUMINATE THE DARKNESS", SCREEN_W / 2 - 130, SCREEN_H / 2 - 30, 20)

        -- Blink prompt
        local blink = 0.5 + 0.5 * math.sin(time * 4)
        gfx.setColor(1, 1, 1, blink)
        gfx.print("Press Enter to Start", SCREEN_W / 2 - 90, SCREEN_H / 2 + 40, 16)

        -- Engine credit
        gfx.setColor(0.4, 0.4, 0.4, 0.5)
        gfx.print("Lurek2D Engine Showcase", SCREEN_W / 2 - 80, SCREEN_H - 40, 12)
        return
    end

    -- ── RUNNING HUD ───────────────────────────────────────────

    -- Stats panel (top-left)
    gfx.setColor(0.0, 0.0, 0.0, 0.5)
    gfx.drawRect("fill", 8, 8, 200, 110)

    gfx.setColor(0.9, 0.85, 0.6, 1)
    gfx.print("LIGHT DEMO", 14, 12, 16)

    gfx.setColor(0.8, 0.8, 0.8, 0.9)
    local lc = LIGHT_COLORS[color_index]
    local mode_str = spotlight_mode and "Spotlight" or "Point"
    local total_lights = 1 + (torches_on and #torch_lights or 0)

    gfx.print("Lights: " .. total_lights, 14, 32, 13)
    gfx.print("Ambient: " .. string.format("%.2f", ambient_level), 14, 48, 13)
    gfx.print("Radius: " .. light_radius .. "px", 14, 64, 13)
    gfx.print("Mode: " .. mode_str, 14, 80, 13)
    gfx.print(string.format("Pos: %d, %d", player.x, player.y), 14, 96, 13)

    -- Light color indicator
    gfx.setColor(lc[1], lc[2], lc[3], 1)
    gfx.drawRect("fill", 170, 32, 12, 12)
    gfx.setColor(1, 1, 1, 0.5)
    gfx.drawRect("line", 170, 32, 12, 12)

    -- Ambient tint name
    local tint = AMBIENT_TINTS[ambient_tint_index]
    gfx.setColor(tint[1] * 0.8, tint[2] * 0.8, tint[3] * 0.8, 0.9)
    gfx.print("Tint: " .. tint[4], 120, 48, 13)

    -- Torch status
    gfx.setColor(torches_on and {1.0, 0.7, 0.3, 1} or {0.4, 0.4, 0.4, 0.6})
    gfx.print("Torches: " .. (torches_on and "ON" or "OFF"), 120, 64, 13)

    -- Controls (bottom)
    gfx.setColor(0.0, 0.0, 0.0, 0.4)
    gfx.drawRect("fill", 8, SCREEN_H - 58, SCREEN_W - 16, 50)

    gfx.setColor(0.6, 0.6, 0.6, 0.7)
    gfx.print("WASD: Move   1-4: Color   Q/E: Radius   Scroll: Radius   F: Spotlight", 14, SCREEN_H - 52, 12)
    gfx.print("T: Torches   R: Ambient Tint   +/-: Ambient Level   Esc: Quit", 14, SCREEN_H - 36, 12)

    -- Color legend (bottom right)
    local legend_x = SCREEN_W - 130
    local legend_y = SCREEN_H - 52
    for i, c in ipairs(LIGHT_COLORS) do
        local a = (i == color_index) and 1.0 or 0.4
        gfx.setColor(c[1], c[2], c[3], a)
        gfx.drawRect("fill", legend_x + (i - 1) * 28, legend_y, 10, 10)
        gfx.setColor(0.7, 0.7, 0.7, a)
        gfx.print(tostring(i), legend_x + (i - 1) * 28 + 1, legend_y + 12, 10)
    end

    -- FPS (top-right)
    gfx.setColor(0.5, 0.5, 0.5, 0.6)
    gfx.print("FPS: " .. tostring(lurek.timer.getFPS()), SCREEN_W - 80, 12, 12)
end
