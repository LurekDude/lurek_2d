-- Light Showcase — Lurek2D
-- Category: showcase
-- 8 screens demonstrating lighting techniques

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W = 800
local SCREEN_H = 600
local PANEL_W  = SCREEN_W / 3
local HUD_H    = 50
local DESC_Y   = 36
local NAV_Y    = SCREEN_H - 18
local NUM_SCREENS = 8

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE    = "TITLE"
local STATE_SCREEN_1 = "SCREEN_1"
local STATE_SCREEN_2 = "SCREEN_2"
local STATE_SCREEN_3 = "SCREEN_3"
local STATE_SCREEN_4 = "SCREEN_4"
local STATE_SCREEN_5 = "SCREEN_5"
local STATE_SCREEN_6 = "SCREEN_6"
local STATE_SCREEN_7 = "SCREEN_7"
local STATE_SCREEN_8 = "SCREEN_8"

local SCREEN_STATES = {
local _cam = lurek.camera.new()  -- injected by fix_games.py
    STATE_SCREEN_1, STATE_SCREEN_2, STATE_SCREEN_3, STATE_SCREEN_4,
    STATE_SCREEN_5, STATE_SCREEN_6, STATE_SCREEN_7, STATE_SCREEN_8,
}

local state = STATE_TITLE
local screen_index = 1
local title_timer = 0

local screen_names = {
    [STATE_SCREEN_1] = "Point Lights",
    [STATE_SCREEN_2] = "Spot Lights",
    [STATE_SCREEN_3] = "Directional Light",
    [STATE_SCREEN_4] = "Flicker Effects",
    [STATE_SCREEN_5] = "Attenuation",
    [STATE_SCREEN_6] = "Light Groups",
    [STATE_SCREEN_7] = "Shadow Filtering",
    [STATE_SCREEN_8] = "Blend Modes",
}

local screen_descs = {
    [STATE_SCREEN_1] = "5 colored point lights orbiting center — mouse Y adjusts radius",
    [STATE_SCREEN_2] = "3 spotlights with cone angles — rotating sweep pattern",
    [STATE_SCREEN_3] = "Sunlight day/night cycle — mouse X controls sun angle",
    [STATE_SCREEN_4] = "Candle / Torch / Neon / Strobe — 4 flicker patterns",
    [STATE_SCREEN_5] = "Linear / Quadratic / Cubic falloff — 3-panel comparison",
    [STATE_SCREEN_6] = "R / G / B light groups — press R/G/B to toggle",
    [STATE_SCREEN_7] = "Hard / Soft / None — 3-panel shadow comparison",
    [STATE_SCREEN_8] = "Additive / Multiply / Screen — 3-panel blend comparison",
}

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

-- ============================================================
-- Particles (lightweight inline system)
-- ============================================================
local particles = {}

local function spawn_particles(x, y, r, g, b, count, spread, life_base)
    count = count or 6
    spread = spread or 40
    life_base = life_base or 0.6
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 10 + math.random() * spread
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 8,
            r = r, g = g, b = b, a = 0.8,
            life = life_base + math.random() * 0.4,
            max_life = life_base + 0.4,
            size = 1.5 + math.random() * 2.5,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy - 5 * dt
        p.life = p.life - dt
        p.a = math.max(0, (p.life / p.max_life) * 0.8)
        p.size = p.size * (1 - dt * 0.8)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function spawn_ambient_particles(screen_state)
    local count = 1
    if math.random() > 0.4 then return end
    if screen_state == STATE_SCREEN_1 then
        spawn_particles(math.random() * SCREEN_W, SCREEN_H + 5, 0.4, 0.6, 1.0, count, 15, 2.0)
    elseif screen_state == STATE_SCREEN_2 then
        spawn_particles(math.random() * SCREEN_W, math.random() * SCREEN_H, 1.0, 1.0, 0.8, count, 10, 1.5)
    elseif screen_state == STATE_SCREEN_3 then
        spawn_particles(math.random() * SCREEN_W, SCREEN_H + 5, 0.9, 0.8, 0.3, count, 20, 2.5)
    elseif screen_state == STATE_SCREEN_4 then
        spawn_particles(math.random() * SCREEN_W, SCREEN_H * 0.8, 1.0, 0.6, 0.2, count, 12, 1.0)
    elseif screen_state == STATE_SCREEN_5 then
        spawn_particles(math.random() * SCREEN_W, SCREEN_H + 5, 0.6, 0.8, 1.0, count, 15, 2.0)
    elseif screen_state == STATE_SCREEN_6 then
        local cr = math.random(3)
        local r, g, b = 1, 0.3, 0.3
        if cr == 2 then r, g, b = 0.3, 1, 0.3 end
        if cr == 3 then r, g, b = 0.3, 0.3, 1 end
        spawn_particles(math.random() * SCREEN_W, SCREEN_H + 5, r, g, b, count, 15, 2.0)
    elseif screen_state == STATE_SCREEN_7 then
        spawn_particles(math.random() * SCREEN_W, SCREEN_H + 5, 0.5, 0.5, 0.6, count, 10, 2.0)
    elseif screen_state == STATE_SCREEN_8 then
        spawn_particles(math.random() * SCREEN_W, SCREEN_H + 5, 0.8, 0.7, 1.0, count, 15, 2.0)
    end
end

-- ============================================================
-- Tween state
-- ============================================================
local slide_offset = 0
local slide_target = 0
local SLIDE_SPEED = 10

-- ============================================================
-- Light simulation state (all screens)
-- ============================================================
local time_acc = 0

-- Screen 1: point lights
local point_lights = {}
local point_colors = {
    {1.0, 0.3, 0.3}, {0.3, 1.0, 0.3}, {0.3, 0.3, 1.0},
    {1.0, 1.0, 0.3}, {1.0, 0.3, 1.0},
}
local point_orbit_radius = 150

-- Screen 2: spot lights
local spot_angles = {0, 2.094, 4.189}
local spot_colors = {{1.0, 0.9, 0.5}, {0.5, 0.9, 1.0}, {1.0, 0.5, 0.8}}

-- Screen 3: directional
local sun_angle = 0
local day_cycle_speed = 0.3

-- Screen 4: flicker
local flicker_patterns = {
    {name = "Candle",  min = 0.4, max = 1.0, speed = 8.0,  color = {1.0, 0.7, 0.3}},
    {name = "Torch",   min = 0.6, max = 1.0, speed = 12.0, color = {1.0, 0.5, 0.2}},
    {name = "Neon",    min = 0.0, max = 1.0, speed = 25.0, color = {0.3, 1.0, 0.8}},
    {name = "Strobe",  min = 0.0, max = 1.0, speed = 40.0, color = {1.0, 1.0, 1.0}},
}
local flicker_values = {1.0, 1.0, 1.0, 1.0}

-- Screen 5: attenuation
local atten_labels = {"Linear", "Quadratic", "Cubic"}
local atten_falloffs = {1.0, 2.0, 3.0}

-- Screen 6: groups
local group_enabled = {true, true, true}
local group_colors = {{1.0, 0.2, 0.2}, {0.2, 0.2, 1.0}, {0.2, 1.0, 0.2}}
local group_names = {"Red", "Blue", "Green"}

-- Screen 7: shadow
local shadow_labels = {"Hard", "Soft (PCF)", "No Shadows"}

-- Screen 8: blend
local blend_labels = {"Additive", "Multiply", "Screen"}

-- ============================================================
-- FPS tracking
-- ============================================================
local fps = 0
local fps_timer = 0
local fps_count = 0

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("screen_1", "1")
lurek.input.bind("screen_2", "2")
lurek.input.bind("screen_3", "3")
lurek.input.bind("screen_4", "4")
lurek.input.bind("screen_5", "5")
lurek.input.bind("screen_6", "6")
lurek.input.bind("screen_7", "7")
lurek.input.bind("screen_8", "8")
lurek.input.bind("nav_left", "left")
lurek.input.bind("nav_right", "right")
lurek.input.bind("toggle_red", "r")
lurek.input.bind("toggle_green", "g")
lurek.input.bind("toggle_blue", "b")
lurek.input.bind("quit", "escape")

-- ============================================================
-- Screen transitions
-- ============================================================
local function switch_screen(idx)
    idx = clamp(idx, 1, NUM_SCREENS)
    if SCREEN_STATES[idx] == state then return end
    local direction = idx > screen_index and 1 or -1
    screen_index = idx
    state = SCREEN_STATES[idx]
    slide_offset = direction * SCREEN_W
    slide_target = 0
    particles = {}
    spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 0.5, 0.7, 1.0, 12, 60, 0.8)
end

-- ============================================================
-- Flicker simulation
-- ============================================================
local function update_flickers(dt)
    for i, pat in ipairs(flicker_patterns) do
        local noise = math.sin(time_acc * pat.speed + i * 17.3) * 0.5 + 0.5
        local jitter = math.sin(time_acc * pat.speed * 2.7 + i * 7.1) * 0.3
        local raw = noise + jitter
        flicker_values[i] = clamp(lerp(pat.min, pat.max, raw), pat.min, pat.max)
    end
end

-- ============================================================
-- Init
-- ============================================================

function lurek.init()
    lurek.window.setTitle("Light Showcase — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.05)
    _cam:setPosition(0, 0)
end

local function _ready_setup()
    -- nothing extra needed
end

-- ============================================================
-- Process
-- ============================================================
function lurek.process(dt)
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
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Title screen
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        for i = 1, NUM_SCREENS do
            if lurek.input.wasActionPressed("screen_" .. i) then
                switch_screen(i)
                return
            end
        end
        if lurek.input.wasActionPressed("nav_right") then
            switch_screen(1)
            return
        end
        return
    end

    -- Screen switching
    for i = 1, NUM_SCREENS do
        if lurek.input.wasActionPressed("screen_" .. i) then
            switch_screen(i)
            return
        end
    end
    if lurek.input.wasActionPressed("nav_left") then
        switch_screen(screen_index - 1 >= 1 and screen_index - 1 or NUM_SCREENS)
    end
    if lurek.input.wasActionPressed("nav_right") then
        switch_screen(screen_index + 1 <= NUM_SCREENS and screen_index + 1 or 1)
    end

    -- Slide tween
    slide_offset = lerp(slide_offset, slide_target, dt * SLIDE_SPEED)
    if math.abs(slide_offset - slide_target) < 0.5 then slide_offset = slide_target end

    -- Mouse position
    local mx, my = lurek.input.mouse.getPosition()

    -- Per-screen updates
    if state == STATE_SCREEN_1 then
        point_orbit_radius = lerp(80, 220, my / SCREEN_H)

    elseif state == STATE_SCREEN_3 then
        sun_angle = sun_angle + day_cycle_speed * dt
        if sun_angle > math.pi * 2 then sun_angle = sun_angle - math.pi * 2 end

    elseif state == STATE_SCREEN_4 then
        update_flickers(dt)

    elseif state == STATE_SCREEN_6 then
        if lurek.input.wasActionPressed("toggle_red") then
            group_enabled[1] = not group_enabled[1]
        end
        if lurek.input.wasActionPressed("toggle_blue") then
            group_enabled[2] = not group_enabled[2]
        end
        if lurek.input.wasActionPressed("toggle_green") then
            group_enabled[3] = not group_enabled[3]
        end
    end

    -- Ambient particles
    spawn_ambient_particles(state)
    update_particles(dt)
end

-- ============================================================
-- Render: light scenes (world-space)
-- ============================================================
function lurek.draw()
    if state == STATE_TITLE then return end

    local ox = slide_offset

    -- Draw ground plane hint (dark rectangles)
    lurek.render.setColor(0.06, 0.06, 0.10, 1.0)
    lurek.render.rectangle(ox + 20, HUD_H + 10, SCREEN_W - 40, SCREEN_H - HUD_H - 40)

    -- Screen-specific light visualizations
    if state == STATE_SCREEN_1 then
        -- Point lights orbiting center
        local cx, cy = SCREEN_W / 2 + ox, SCREEN_H / 2
        for i = 1, 5 do
            local angle = time_acc * 0.8 + (i - 1) * (math.pi * 2 / 5)
            local lx = cx + math.cos(angle) * point_orbit_radius
            local ly = cy + math.sin(angle) * point_orbit_radius
            local c = point_colors[i]
            -- Glow circle
            local radius = 80 + math.sin(time_acc * 2 + i) * 15
            for ring = 4, 1, -1 do
                local a = 0.08 * ring
                local rr = radius * ring * 0.35
                lurek.render.setColor(c[1], c[2], c[3], a)
                lurek.render.circle("fill", lx, ly, rr)
            end
            -- Core
            lurek.render.setColor(c[1], c[2], c[3], 0.9)
            lurek.render.circle("fill", lx, ly, 8)
        end
        -- Center marker
        lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
        lurek.render.circle(cx, cy, 6)

    elseif state == STATE_SCREEN_2 then
        -- 3 spotlights with cone sweep
        local cx, cy = SCREEN_W / 2 + ox, SCREEN_H * 0.3
        for i = 1, 3 do
            local base_angle = spot_angles[i] + time_acc * 0.6
            local dir = base_angle
            local cone_half = math.pi / 8
            local reach = 260
            local c = spot_colors[i]
            -- Draw cone as a filled triangle fan
            local steps = 12
            for s = 0, steps - 1 do
                local a1 = dir - cone_half + (cone_half * 2) * (s / steps)
                local a2 = dir - cone_half + (cone_half * 2) * ((s + 1) / steps)
                local x1 = cx + math.cos(a1) * reach
                local y1 = cy + math.sin(a1) * reach
                local x2 = cx + math.cos(a2) * reach
                local y2 = cy + math.sin(a2) * reach
                local fade = 0.12 - 0.06 * (math.abs(s - steps / 2) / (steps / 2))
                lurek.render.setColor(c[1], c[2], c[3], fade)
                lurek.render.polygon("fill", cx, cy, x1, y1, x2, y2)
            end
            -- Source dot
            lurek.render.setColor(c[1], c[2], c[3], 0.9)
            lurek.render.circle("fill", cx, cy, 6)
        end

    elseif state == STATE_SCREEN_3 then
        -- Directional sunlight day/night cycle
        local sky_t = (math.sin(sun_angle) + 1) / 2
        local sr = lerp(0.02, 0.4, sky_t)
        local sg = lerp(0.02, 0.55, sky_t)
        local sb = lerp(0.08, 0.85, sky_t)
        lurek.render.setColor(sr, sg, sb, 0.6)
        lurek.render.rectangle(ox + 20, HUD_H + 10, SCREEN_W - 40, SCREEN_H - HUD_H - 40)

        -- Sun/moon circle
        local sun_x = SCREEN_W / 2 + ox + math.cos(sun_angle) * 250
        local sun_y = SCREEN_H / 2 - math.sin(sun_angle) * 200
        if sky_t > 0.3 then
            -- Sun
            lurek.render.setColor(1.0, 0.9, 0.4, sky_t)
            lurek.render.circle("fill", sun_x, sun_y, 30)
            -- Sun rays
            for r = 1, 8 do
                local ra = r * math.pi / 4 + time_acc * 0.3
                local rx1 = sun_x + math.cos(ra) * 35
                local ry1 = sun_y + math.sin(ra) * 35
                local rx2 = sun_x + math.cos(ra) * 50
                local ry2 = sun_y + math.sin(ra) * 50
                lurek.render.setColor(1.0, 0.9, 0.4, sky_t * 0.5)
                lurek.render.line(rx1, ry1, rx2, ry2)
            end
        else
            -- Moon
            lurek.render.setColor(0.7, 0.75, 0.9, 0.7)
            lurek.render.circle("fill", sun_x, sun_y, 22)
        end

        -- Ground shadow line
        local shadow_len = lerp(200, 20, sky_t)
        lurek.render.setColor(0.0, 0.0, 0.0, 0.3 * sky_t)
        lurek.render.rectangle(ox + SCREEN_W / 2 - 15, SCREEN_H - 100, shadow_len, 6)

        -- Scene objects (trees/buildings silhouette)
        lurek.render.setColor(0.08, 0.12, 0.08, 1.0)
        lurek.render.rectangle(ox + 150, SCREEN_H - 180, 30, 80)
        lurek.render.polygon("fill", ox + 115, SCREEN_H - 180, ox + 195, SCREEN_H - 180, ox + 165, SCREEN_H - 260)
        lurek.render.rectangle(ox + 500, SCREEN_H - 200, 60, 100)
        lurek.render.rectangle(ox + 490, SCREEN_H - 220, 80, 20)

    elseif state == STATE_SCREEN_4 then
        -- 4 flicker patterns side by side
        local col_w = (SCREEN_W - 60) / 4
        for i = 1, 4 do
            local pat = flicker_patterns[i]
            local val = flicker_values[i]
            local cx = ox + 30 + (i - 1) * col_w + col_w / 2
            local cy = SCREEN_H / 2
            local radius = 60 + val * 40
            -- Glow rings
            for ring = 5, 1, -1 do
                local a = val * 0.06 * ring
                local rr = radius * ring * 0.3
                lurek.render.setColor(pat.color[1], pat.color[2], pat.color[3], a)
                lurek.render.circle("fill", cx, cy, rr)
            end
            -- Core
            lurek.render.setColor(pat.color[1], pat.color[2], pat.color[3], val)
            lurek.render.circle("fill", cx, cy, 10 + val * 5)
        end

    elseif state == STATE_SCREEN_5 then
        -- 3-panel attenuation comparison
        for p = 1, 3 do
            local px = ox + 20 + (p - 1) * PANEL_W
            local cy = SCREEN_H / 2
            local cx = px + PANEL_W / 2
            local falloff = atten_falloffs[p]

            -- Panel divider
            if p > 1 then
                lurek.render.setColor(0.15, 0.15, 0.2, 1.0)
                lurek.render.line(px, HUD_H + 10, px, SCREEN_H - 30)
            end

            -- Attenuation rings: intensity = 1 / (1 + d^falloff)
            local max_r = 130
            for ring = 20, 1, -1 do
                local d = ring / 20
                local intensity = 1.0 / (1.0 + (d * 3) ^ falloff)
                local rr = d * max_r
                lurek.render.setColor(0.9, 0.85, 0.6, intensity * 0.3)
                lurek.render.circle("fill", cx, cy, rr)
            end
            -- Core
            lurek.render.setColor(1.0, 0.95, 0.7, 0.9)
            lurek.render.circle("fill", cx, cy, 8)
        end

    elseif state == STATE_SCREEN_6 then
        -- 3 light groups (red, blue, green)
        local positions = {
            {SCREEN_W * 0.25, SCREEN_H * 0.45},
            {SCREEN_W * 0.5,  SCREEN_H * 0.55},
            {SCREEN_W * 0.75, SCREEN_H * 0.45},
        }
        for i = 1, 3 do
            local gx = positions[i][1] + ox
            local gy = positions[i][2]
            local c = group_colors[i]
            local enabled = group_enabled[i]
            local alpha = enabled and 1.0 or 0.1
            -- Glow
            for ring = 6, 1, -1 do
                local a = alpha * 0.05 * ring
                local rr = 30 * ring
                lurek.render.setColor(c[1], c[2], c[3], a)
                lurek.render.circle("fill", gx, gy, rr)
            end
            -- Core
            lurek.render.setColor(c[1], c[2], c[3], alpha * 0.9)
            lurek.render.circle("fill", gx, gy, 12)
            -- Disabled cross
            if not enabled then
                lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
                lurek.render.line(gx - 15, gy - 15, gx + 15, gy + 15)
                lurek.render.line(gx + 15, gy - 15, gx - 15, gy + 15)
            end
        end

    elseif state == STATE_SCREEN_7 then
        -- 3-panel shadow comparison
        for p = 1, 3 do
            local px = ox + 20 + (p - 1) * PANEL_W
            local cy = SCREEN_H * 0.4
            local cx = px + PANEL_W / 2

            -- Panel divider
            if p > 1 then
                lurek.render.setColor(0.15, 0.15, 0.2, 1.0)
                lurek.render.line(px, HUD_H + 10, px, SCREEN_H - 30)
            end

            -- Light source
            lurek.render.setColor(1.0, 0.9, 0.6, 0.8)
            lurek.render.circle("fill", cx, cy - 60, 10)
            for ring = 4, 1, -1 do
                lurek.render.setColor(1.0, 0.9, 0.6, 0.06 * ring)
                lurek.render.circle("fill", cx, cy - 60, 20 * ring)
            end

            -- Occluder block
            lurek.render.setColor(0.2, 0.2, 0.25, 1.0)
            lurek.render.rectangle(cx - 20, cy, 40, 25)

            -- Shadow below occluder
            if p == 1 then
                -- Hard shadow: solid edge
                lurek.render.setColor(0.0, 0.0, 0.0, 0.6)
                lurek.render.rectangle(cx - 25, cy + 25, 50, 120)
            elseif p == 2 then
                -- Soft shadow: fading penumbra
                for s = 6, 1, -1 do
                    local spread = s * 8
                    local a = 0.08 * (7 - s)
                    lurek.render.setColor(0.0, 0.0, 0.0, a)
                    lurek.render.rectangle(cx - 20 - spread / 2, cy + 25, 40 + spread, 120)
                end
            end
            -- p == 3: no shadow drawn
        end

    elseif state == STATE_SCREEN_8 then
        -- 3-panel blend mode comparison
        local base_colors = {{0.8, 0.2, 0.2}, {0.2, 0.8, 0.2}, {0.2, 0.2, 0.8}}
        for p = 1, 3 do
            local px = ox + 20 + (p - 1) * PANEL_W
            local cy = SCREEN_H / 2
            local cx = px + PANEL_W / 2

            -- Panel divider
            if p > 1 then
                lurek.render.setColor(0.15, 0.15, 0.2, 1.0)
                lurek.render.line(px, HUD_H + 10, px, SCREEN_H - 30)
            end

            -- Two overlapping light circles
            local offset = 40
            local c1 = base_colors[1]
            local c2 = base_colors[3]

            if p == 1 then
                -- Additive: brighter where lights overlap
                for ring = 5, 1, -1 do
                    local a = 0.1 * ring
                    local rr = 20 * ring
                    lurek.render.setColor(c1[1], c1[2], c1[3], a)
                    lurek.render.circle("fill", cx - offset, cy, rr)
                    lurek.render.setColor(c2[1], c2[2], c2[3], a)
                    lurek.render.circle("fill", cx + offset, cy, rr)
                end
            elseif p == 2 then
                -- Multiply: darker where lights overlap
                for ring = 5, 1, -1 do
                    local a = 0.08 * ring
                    local rr = 20 * ring
                    lurek.render.setColor(c1[1] * 0.5, c1[2] * 0.5, c1[3] * 0.5, a)
                    lurek.render.circle("fill", cx - offset, cy, rr)
                    lurek.render.setColor(c2[1] * 0.5, c2[2] * 0.5, c2[3] * 0.5, a)
                    lurek.render.circle("fill", cx + offset, cy, rr)
                end
                -- Dark overlap zone
                lurek.render.setColor(0.05, 0.02, 0.08, 0.4)
                lurek.render.circle("fill", cx, cy, 40)
            else
                -- Screen: bright, washed-out overlap
                for ring = 5, 1, -1 do
                    local a = 0.12 * ring
                    local rr = 20 * ring
                    lurek.render.setColor(c1[1], c1[2], c1[3], a)
                    lurek.render.circle("fill", cx - offset, cy, rr)
                    lurek.render.setColor(c2[1], c2[2], c2[3], a)
                    lurek.render.circle("fill", cx + offset, cy, rr)
                end
                -- Bright overlap
                lurek.render.setColor(0.85, 0.7, 0.95, 0.35)
                lurek.render.circle("fill", cx, cy, 45)
            end
        end
    end

    -- Draw particles (world-space)
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.a)
        lurek.render.circle("fill", p.x + ox, p.y, p.size)
    end
end

-- ============================================================
-- Render UI: labels, descriptions, navigation
-- ============================================================
function lurek.draw_ui()
    -- Title screen
    if state == STATE_TITLE then
        local pulse = 0.7 + 0.3 * math.sin(title_timer * 2)

        lurek.render.setColor(0.9, 0.85, 1.0, 1.0)
        lurek.render.print("LIGHT SHOWCASE", SCREEN_W / 2 - 120, SCREEN_H / 2 - 80)

        lurek.render.setColor(0.6, 0.7, 0.9, pulse)
        lurek.render.print("8 LIGHTING TECHNIQUES", SCREEN_W / 2 - 100, SCREEN_H / 2 - 40)

        lurek.render.setColor(0.5, 0.5, 0.6, 0.8)
        lurek.render.print("Press 1-8 to select a technique, or Right Arrow to start", SCREEN_W / 2 - 210, SCREEN_H / 2 + 30)

        -- Screen list
        for i = 1, NUM_SCREENS do
            local sy = SCREEN_H / 2 + 65 + (i - 1) * 18
            lurek.render.setColor(0.5, 0.6, 0.8, 0.7)
            lurek.render.print(i .. ". " .. screen_names[SCREEN_STATES[i]], SCREEN_W / 2 - 80, sy)
        end

        lurek.render.setColor(0.4, 0.4, 0.5, 0.6)
        lurek.render.print("ESC to quit", SCREEN_W / 2 - 40, SCREEN_H - 40)
        return
    end

    -- HUD bar
    lurek.render.setColor(0.04, 0.04, 0.08, 0.85)
    lurek.render.rectangle(0, 0, SCREEN_W, HUD_H)

    -- Screen title
    local title = screen_index .. "/" .. NUM_SCREENS .. "  " .. (screen_names[state] or "")
    lurek.render.setColor(0.9, 0.85, 1.0, 1.0)
    lurek.render.print(title, 12, 8)

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.6, 0.8)
    lurek.render.print("FPS: " .. fps, SCREEN_W - 80, 8)

    -- Description
    local desc = screen_descs[state] or ""
    lurek.render.setColor(0.6, 0.65, 0.75, 0.9)
    lurek.render.print(desc, 12, DESC_Y)

    -- Per-screen labels
    if state == STATE_SCREEN_4 then
        local col_w = (SCREEN_W - 60) / 4
        for i = 1, 4 do
            local cx = 30 + (i - 1) * col_w + col_w / 2
            lurek.render.setColor(0.7, 0.7, 0.8, 0.9)
            lurek.render.print(flicker_patterns[i].name, cx - 18, SCREEN_H - 80)
            local bar_w = 60
            local bar_h = 6
            local bx = cx - bar_w / 2
            local by = SCREEN_H - 60
            lurek.render.setColor(0.15, 0.15, 0.2, 1.0)
            lurek.render.rectangle(bx, by, bar_w, bar_h)
            local c = flicker_patterns[i].color
            lurek.render.setColor(c[1], c[2], c[3], 0.9)
            lurek.render.rectangle(bx, by, bar_w * flicker_values[i], bar_h)
        end
    end

    if state == STATE_SCREEN_5 then
        for p = 1, 3 do
            local px = 20 + (p - 1) * PANEL_W
            lurek.render.setColor(0.7, 0.7, 0.8, 0.9)
            lurek.render.print(atten_labels[p], px + PANEL_W / 2 - 25, SCREEN_H - 55)
        end
    end

    if state == STATE_SCREEN_6 then
        for i = 1, 3 do
            local label = group_names[i] .. ": " .. (group_enabled[i] and "ON" or "OFF")
            local key = ({"R", "B", "G"})[i]
            local c = group_colors[i]
            lurek.render.setColor(c[1], c[2], c[3], group_enabled[i] and 0.9 or 0.4)
            lurek.render.print("[" .. key .. "] " .. label, 20 + (i - 1) * 240, SCREEN_H - 55)
        end
    end

    if state == STATE_SCREEN_7 then
        for p = 1, 3 do
            local px = 20 + (p - 1) * PANEL_W
            lurek.render.setColor(0.7, 0.7, 0.8, 0.9)
            lurek.render.print(shadow_labels[p], px + PANEL_W / 2 - 30, SCREEN_H - 55)
        end
    end

    if state == STATE_SCREEN_8 then
        for p = 1, 3 do
            local px = 20 + (p - 1) * PANEL_W
            lurek.render.setColor(0.7, 0.7, 0.8, 0.9)
            lurek.render.print(blend_labels[p], px + PANEL_W / 2 - 28, SCREEN_H - 55)
        end
    end

    -- Navigation footer
    lurek.render.setColor(0.04, 0.04, 0.08, 0.7)
    lurek.render.rectangle(0, SCREEN_H - 28, SCREEN_W, 28)
    lurek.render.setColor(0.45, 0.45, 0.55, 0.8)
    lurek.render.print("<Left/Right> Navigate   |   1-8 Jump   |   ESC Quit", SCREEN_W / 2 - 200, NAV_Y)
end
