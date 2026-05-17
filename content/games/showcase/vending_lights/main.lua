-- ============================================================================
-- Vending Lights — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/vending_lights/main.lua
-- Run with : cargo run -- content/games/showcase/vending_lights
-- ============================================================================
-- Dark room with 4 vending machines, each with a colored point light
-- casting glow on the ground. Machine bodies act as occluders blocking
-- light from passing through, creating realistic shadows behind them.
-- Demonstrates: multi-color lights, occluders, low ambient, falloff.
-- ============================================================================

local SCREEN_W = 840
local SCREEN_H = 480

-- Machine definitions: { x, y, w, h, light_color, light_radius, light_intensity }
local MACHINES = {
    {
        x = 120, y = 160, w = 70, h = 140,
        color = { 0.2, 1.0, 0.9, 1.0 },  -- cyan/teal
        radius = 180, intensity = 1.3,
        screen_color = { 0.3, 1.0, 0.9 },
    },
    {
        x = 280, y = 175, w = 65, h = 130,
        color = { 0.3, 0.4, 1.0, 1.0 },  -- blue/purple
        radius = 160, intensity = 1.2,
        screen_color = { 0.4, 0.5, 1.0 },
    },
    {
        x = 440, y = 155, w = 60, h = 145,
        color = { 0.8, 0.95, 0.1, 1.0 },  -- yellow/green
        radius = 170, intensity = 1.25,
        screen_color = { 0.9, 0.95, 0.2 },
    },
    {
        x = 620, y = 185, w = 55, h = 110,
        color = { 0.2, 0.3, 0.9, 1.0 },  -- deep blue
        radius = 130, intensity = 1.1,
        screen_color = { 0.3, 0.4, 1.0 },
    },
}

-- State
local lights = {}
local occluders = {}
local particles = {}
local time_elapsed = 0

-- Helpers
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- ============================================================================
-- Init
-- ============================================================================
function lurek.init()
    lurek.window.setTitle("Vending Lights — Lurek2D")
    lurek.render.setBackgroundColor(0.01, 0.02, 0.03)

    -- Input
    lurek.input.bind("quit", "escape")

    -- Enable lighting — very dark ambient (almost pitch black)
    lurek.light.setEnabled(true)
    lurek.light.setAmbient(0.02, 0.025, 0.04, 1.0)

    -- Create lights and occluders for each machine
    for i, m in ipairs(MACHINES) do
        -- Point light below center of machine (floor glow)
        local lx = m.x + m.w * 0.5
        local ly = m.y + m.h - 10  -- near the base
        local light = lurek.light.newLight(lx, ly, m.radius, {
            color = m.color,
            intensity = m.intensity,
            blend = "add",
            falloff = "smooth",
            shadowEnabled = true,
            shadowFilter = "pcf5",
            shadowSmooth = 1.2,
        })
        light:setAttenuation(1.0, 0.04, 0.008)
        lights[i] = light

        -- Machine body as occluder (rectangle polygon)
        local occ = lurek.light.newOccluder({
            m.x,       m.y,
            m.x + m.w, m.y,
            m.x + m.w, m.y + m.h,
            m.x,       m.y + m.h,
        }, {
            opacity = 0.92,
        })
        occluders[i] = occ
    end

    -- Subtle flicker on the first machine (fluorescent buzz)
    lights[1]:setFlicker(3.0, 0.08)
    -- Neon flicker on third machine
    lights[3]:setFlicker(6.0, 0.12)
end

-- ============================================================================
-- Process
-- ============================================================================
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
    end

    time_elapsed = time_elapsed + dt
    lurek.light.advanceFlickers(dt)

    -- Spawn ambient particles (dust/fireflies near bottom-right)
    if math.random() < dt * 4.0 then
        table.insert(particles, {
            x = 580 + math.random() * 200,
            y = 320 + math.random() * 120,
            vx = -5 + math.random() * 10,
            vy = -15 - math.random() * 20,
            life = 1.0 + math.random() * 2.0,
            max_life = 3.0,
            size = 1.5 + math.random() * 2.5,
        })
    end

    -- Update particles
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ============================================================================
-- Draw
-- ============================================================================
function lurek.draw()
    local gfx = lurek.render

    -- Dark floor plane
    gfx.setColor(0.02, 0.03, 0.04, 1.0)
    gfx.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Draw vending machine bodies (darker rectangles)
    for _, m in ipairs(MACHINES) do
        -- Machine body
        gfx.setColor(0.04, 0.05, 0.07, 1.0)
        gfx.rectangle("fill", m.x, m.y, m.w, m.h)

        -- Machine screen (bright panel on front)
        local sw = m.w - 12
        local sh = m.h * 0.45
        local sx = m.x + 6
        local sy = m.y + 12
        gfx.setColor(m.screen_color[1] * 0.4, m.screen_color[2] * 0.4, m.screen_color[3] * 0.4, 0.8)
        gfx.rectangle("fill", sx, sy, sw, sh)

        -- Machine outline
        gfx.setColor(0.08, 0.10, 0.14, 1.0)
        gfx.rectangle("line", m.x, m.y, m.w, m.h)
    end

    -- Draw particles (dust/fireflies)
    for _, p in ipairs(particles) do
        local alpha = clamp(p.life / p.max_life, 0, 1)
        gfx.setColor(0.5, 0.7, 1.0, alpha * 0.6)
        gfx.circle("fill", p.x, p.y, p.size * alpha)
    end

    -- HUD
    gfx.setColor(0.6, 0.7, 0.8, 0.5)
    gfx.print("Vending Lights — ESC to quit", 10, SCREEN_H - 22)
end
