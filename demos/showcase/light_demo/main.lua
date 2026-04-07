-- Luna2D Light Demo
-- Demonstrates the 2D lighting system: point lights, shadow occluders,
-- blend modes, falloff modes, and ambient control.
--
-- Controls:
--   WASD           move player light
--   1/2/3          switch blend mode (add/sub/mix)
--   F/G/H          switch falloff (linear/smooth/constant)
--   +/-            adjust ambient brightness
--   SPACE          toggle shadows on player light
--   T              toggle torch lights on/off
--   C              clear all lights and recreate

local W = 900
local H = 600

-- ── State ──────────────────────────────────────────────────────────────────
local player_light
local torch_lights = {}
local walls = {}
local player_x, player_y = W / 2, H / 2
local ambient_level = 0.08
local torches_enabled = true

-- ── Setup ──────────────────────────────────────────────────────────────────
local function create_scene()
    -- Dark ambient for atmosphere
    luna.light.setAmbient(ambient_level, ambient_level, ambient_level * 1.2)

    -- Player light — warm white, smooth falloff, shadows
    player_light = luna.light.newLight(player_x, player_y, 250, {
        color = {1.0, 0.95, 0.85},
        intensity = 1.3,
        energy = 1.0,
        falloff = "smooth",
        blend = "add",
        shadowEnabled = true,
        shadowFilter = "pcf5",
        shadowColor = {0.02, 0.02, 0.05},
        shadowSmooth = 1.5,
    })

    -- Wall torches — orange flickering lights
    local torch_positions = {
        {100, 100}, {450, 80},  {800, 100},
        {100, 500}, {450, 520}, {800, 500},
    }
    for _, pos in ipairs(torch_positions) do
        local t = luna.light.newLight(pos[1], pos[2], 140, {
            color = {1.0, 0.55, 0.15},
            intensity = 0.7,
            falloff = "linear",
            shadowEnabled = true,
            shadowFilter = "none",
        })
        table.insert(torch_lights, {
            light = t,
            base_x = pos[1],
            base_y = pos[2],
            base_intensity = 0.7,
            phase = math.random() * math.pi * 2,
        })
    end

    -- Shadow-casting wall occluders
    local wall_rects = {
        -- Vertical pillars
        {250, 180, 280, 180, 280, 380, 250, 380},
        {620, 180, 650, 180, 650, 380, 620, 380},
        -- Horizontal walls
        {350, 250, 500, 250, 500, 270, 350, 270},
        -- L-shaped wall (two rectangles)
        {150, 300, 200, 300, 200, 320, 150, 320},
        {180, 320, 200, 320, 200, 420, 180, 420},
        -- Small obstacles
        {700, 300, 730, 280, 760, 300, 730, 320},
    }
    for _, verts in ipairs(wall_rects) do
        table.insert(walls, luna.light.newOccluder(verts))
    end
end

function luna.init()
    create_scene()
end

-- ── Update ─────────────────────────────────────────────────────────────────
function luna.process(dt)
    -- Player movement
    local speed = 250 * dt
    if luna.keyboard.isDown("w") then player_y = player_y - speed end
    if luna.keyboard.isDown("s") then player_y = player_y + speed end
    if luna.keyboard.isDown("a") then player_x = player_x - speed end
    if luna.keyboard.isDown("d") then player_x = player_x + speed end

    -- Clamp to window
    player_x = math.max(0, math.min(W, player_x))
    player_y = math.max(0, math.min(H, player_y))

    -- Update player light position
    if player_light and player_light:isValid() then
        player_light:setPosition(player_x, player_y)
    end

    -- Torch flicker effect
    for _, t in ipairs(torch_lights) do
        if t.light:isValid() then
            t.phase = t.phase + dt * (3 + math.random() * 2)
            local flicker = 1.0 + 0.15 * math.sin(t.phase) + 0.05 * math.sin(t.phase * 3.7)
            t.light:setIntensity(t.base_intensity * flicker)
            -- Slight position wobble
            local wobble = math.sin(t.phase * 1.3) * 2
            t.light:setPosition(t.base_x + wobble, t.base_y)
        end
    end
end

-- ── Draw ───────────────────────────────────────────────────────────────────
function luna.render()
    -- Dark background
    luna.gfx.clear(0.02, 0.02, 0.03)

    -- Draw walls as dark rectangles
    luna.gfx.setColor(0.15, 0.12, 0.1)
    -- Pillar 1
    luna.gfx.rectangle("fill", 250, 180, 30, 200)
    -- Pillar 2
    luna.gfx.rectangle("fill", 620, 180, 30, 200)
    -- Horizontal wall
    luna.gfx.rectangle("fill", 350, 250, 150, 20)
    -- L-shape
    luna.gfx.rectangle("fill", 150, 300, 50, 20)
    luna.gfx.rectangle("fill", 180, 320, 20, 100)
    -- Diamond obstacle
    luna.gfx.polygon("fill", 700, 300, 730, 280, 760, 300, 730, 320)

    -- Draw player marker
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.circle("fill", player_x, player_y, 8)

    -- Draw torch markers
    luna.gfx.setColor(1, 0.6, 0.2)
    for _, t in ipairs(torch_lights) do
        if t.light:isValid() then
            local tx, ty = t.light:getPosition()
            luna.gfx.circle("fill", tx, ty, 5)
        end
    end

    -- HUD
    luna.gfx.setColor(1, 1, 1)
    local blend = player_light and player_light:isValid() and player_light:getBlendMode() or "?"
    local falloff = player_light and player_light:isValid() and player_light:getFalloff() or "?"
    local shadows = player_light and player_light:isValid() and player_light:isShadowEnabled()
    local lights_count = luna.light.getLightCount()
    local occluder_count = luna.light.getOccluderCount()

    luna.gfx.print("Luna2D Light Demo", 10, 10)
    luna.gfx.print(string.format("Lights: %d  Occluders: %d", lights_count, occluder_count), 10, 30)
    luna.gfx.print(string.format("Blend: %s  Falloff: %s  Shadows: %s", blend, falloff, tostring(shadows)), 10, 50)
    luna.gfx.print(string.format("Ambient: %.2f", ambient_level), 10, 70)
    luna.gfx.print("WASD=move  1/2/3=blend  F/G/H=falloff  SPACE=shadows  +/-=ambient  T=torches  C=clear", 10, H - 25)
end

-- ── Key handling ───────────────────────────────────────────────────────────
function luna.keypressed(key)
    if not player_light or not player_light:isValid() then return end

    -- Blend modes
    if key == "1" then player_light:setBlendMode("add") end
    if key == "2" then player_light:setBlendMode("sub") end
    if key == "3" then player_light:setBlendMode("mix") end

    -- Falloff modes
    if key == "f" then player_light:setFalloff("linear") end
    if key == "g" then player_light:setFalloff("smooth") end
    if key == "h" then player_light:setFalloff("constant") end

    -- Toggle shadows
    if key == "space" then
        player_light:setShadowEnabled(not player_light:isShadowEnabled())
    end

    -- Ambient adjustment
    if key == "=" or key == "+" then
        ambient_level = math.min(1.0, ambient_level + 0.02)
        luna.light.setAmbient(ambient_level, ambient_level, ambient_level * 1.2)
    end
    if key == "-" then
        ambient_level = math.max(0.0, ambient_level - 0.02)
        luna.light.setAmbient(ambient_level, ambient_level, ambient_level * 1.2)
    end

    -- Toggle torches
    if key == "t" then
        torches_enabled = not torches_enabled
        for _, t in ipairs(torch_lights) do
            if t.light:isValid() then
                t.light:setEnabled(torches_enabled)
            end
        end
    end

    -- Clear and recreate
    if key == "c" then
        luna.light.clear()
        torch_lights = {}
        walls = {}
        player_x, player_y = W / 2, H / 2
        create_scene()
    end
end
