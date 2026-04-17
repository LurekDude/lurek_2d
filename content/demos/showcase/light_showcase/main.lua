-- Light Showcase — A multi-screen demo of Lurek2D's 2D lighting system
-- Press number keys 1-8 to switch screens.  WASD moves the player light.
-- Each screen demonstrates a different lighting feature.
-- Run with: cargo run -- content/demos/showcase/light_showcase

local W, H = 1024, 768
local screen = 1        -- current screen index
local NUM_SCREENS = 8
local time = 0           -- running clock for animations
local player_x, player_y = W / 2, H / 2  -- movable light position
local MOVE_SPEED = 200

-- ── Screens ──────────────────────────────────────────────────────────────

local screens = {
    { id = 1, title = "Point Lights",       desc = "Classic omnidirectional point lights with different colors" },
    { id = 2, title = "Spot Lights",         desc = "Cone-shaped lights with inner/outer angle falloff" },
    { id = 3, title = "Directional Light",   desc = "Parallel-ray light simulating sunlight from a direction" },
    { id = 4, title = "Flicker Effects",     desc = "Built-in torch/fire flicker at different speeds" },
    { id = 5, title = "Attenuation Curves",  desc = "Custom constant/linear/quadratic intensity decay" },
    { id = 6, title = "Light Groups",        desc = "Batch-control lights by group ID (toggle with G)" },
    { id = 7, title = "Shadow Filters",      desc = "None / PCF5 / PCF13 shadow edge quality" },
    { id = 8, title = "Blend Modes",         desc = "Add / Sub / Mix blending of light color" },
}

-- Track group toggle state
local group1_on = true

-- ── Helpers ──────────────────────────────────────────────────────────────

local function clear_all()
    -- Clear every registered light so each screen starts from a clean slate
    -- lurek.light.clear() is the idiomatic way to tear down the whole light list
    lurek.light.clear()
    player_x, player_y = W / 2, H / 2
end

-- ── Screen Setup Functions ───────────────────────────────────────────────

local function setup_point_lights()
    clear_all()
    lurek.light.setAmbient(0.08, 0.08, 0.12, 1.0)
    -- Warm orange
    lurek.light.newLight(200, 300, 180, {
        color = {1.0, 0.6, 0.2, 1.0}, intensity = 1.2
    })
    -- Cool blue
    lurek.light.newLight(500, 200, 200, {
        color = {0.3, 0.5, 1.0, 1.0}, intensity = 1.0
    })
    -- Green
    lurek.light.newLight(750, 500, 150, {
        color = {0.2, 1.0, 0.3, 1.0}, intensity = 0.9
    })
    -- Purple
    lurek.light.newLight(350, 550, 160, {
        color = {0.8, 0.2, 1.0, 1.0}, intensity = 1.1
    })
    -- White player light
    lurek.light.newLight(player_x, player_y, 120, {
        color = {1.0, 1.0, 0.9, 1.0}, intensity = 0.8, groupId = 99
    })
end

local function setup_spot_lights()
    clear_all()
    lurek.light.setAmbient(0.05, 0.05, 0.08, 1.0)
    -- Spotlight 1: narrow cone pointing right
    lurek.light.newLight(150, 350, 300, {
        type = "spot", direction = 0, innerAngle = 0.15, outerAngle = 0.4,
        color = {1.0, 0.9, 0.5, 1.0}, intensity = 1.5
    })
    -- Spotlight 2: wide cone pointing down
    lurek.light.newLight(500, 100, 350, {
        type = "spot", direction = 1.57, innerAngle = 0.3, outerAngle = 0.8,
        color = {0.5, 0.8, 1.0, 1.0}, intensity = 1.2
    })
    -- Spotlight 3: tight cone pointing up-left
    lurek.light.newLight(800, 600, 250, {
        type = "spot", direction = -2.35, innerAngle = 0.1, outerAngle = 0.25,
        color = {1.0, 0.3, 0.3, 1.0}, intensity = 1.8
    })
end

local function setup_directional_light()
    clear_all()
    lurek.light.setAmbient(0.15, 0.15, 0.2, 1.0)
    -- Sunlight from top-left
    lurek.light.newLight(W / 2, H / 2, 600, {
        type = "directional", direction = 0.78,
        color = {1.0, 0.95, 0.8, 1.0}, intensity = 0.8
    })
    -- Moonlight from top-right (dimmer, blue)
    lurek.light.newLight(W / 2, H / 2, 500, {
        type = "directional", direction = 2.36,
        color = {0.4, 0.5, 0.8, 1.0}, intensity = 0.4
    })
    -- Player lantern
    lurek.light.newLight(player_x, player_y, 100, {
        color = {1.0, 0.8, 0.4, 1.0}, intensity = 0.6, groupId = 99
    })
end

local function setup_flicker()
    clear_all()
    lurek.light.setAmbient(0.04, 0.04, 0.06, 1.0)
    -- flickerSpeed controls oscillation frequency; flickerStrength controls amplitude
    -- Candle (slow, subtle) → Torch (medium) → Campfire (fast) → Strobe (very fast)
    -- Slow candle
    lurek.light.newLight(200, 350, 140, {
        color = {1.0, 0.7, 0.3, 1.0}, intensity = 1.0,
        flickerSpeed = 4.0, flickerStrength = 0.1
    })
    -- Medium torch
    lurek.light.newLight(450, 350, 170, {
        color = {1.0, 0.5, 0.15, 1.0}, intensity = 1.2,
        flickerSpeed = 8.0, flickerStrength = 0.2
    })
    -- Fast campfire
    lurek.light.newLight(700, 350, 200, {
        color = {1.0, 0.4, 0.1, 1.0}, intensity = 1.4,
        flickerSpeed = 15.0, flickerStrength = 0.35
    })
    -- Strobe (very fast, high strength)
    lurek.light.newLight(900, 200, 120, {
        color = {0.8, 0.8, 1.0, 1.0}, intensity = 1.0,
        flickerSpeed = 30.0, flickerStrength = 0.6
    })
end

local function setup_attenuation()
    clear_all()
    lurek.light.setAmbient(0.06, 0.06, 0.1, 1.0)
    -- No custom attenuation (default: constant=1, linear=0, quadratic=0)
    lurek.light.newLight(200, 350, 200, {
        color = {1.0, 1.0, 1.0, 1.0}, intensity = 1.0
    })
    -- Linear attenuation
    lurek.light.newLight(450, 350, 200, {
        color = {0.5, 1.0, 0.5, 1.0}, intensity = 1.0,
        attConstant = 1.0, attLinear = 0.01, attQuadratic = 0.0
    })
    -- Quadratic attenuation (realistic)
    lurek.light.newLight(700, 350, 200, {
        color = {1.0, 0.5, 0.5, 1.0}, intensity = 1.0,
        attConstant = 1.0, attLinear = 0.0, attQuadratic = 0.005
    })
    -- Mixed
    lurek.light.newLight(950, 350, 200, {
        color = {0.5, 0.5, 1.0, 1.0}, intensity = 1.0,
        attConstant = 0.5, attLinear = 0.01, attQuadratic = 0.002
    })
end

local function setup_groups()
    clear_all()
    lurek.light.setAmbient(0.05, 0.05, 0.08, 1.0)
    group1_on = true
    -- Group 1: torches (orange) — press G to toggle
    for i = 0, 3 do
        lurek.light.newLight(150 + i * 200, 250, 140, {
            color = {1.0, 0.6, 0.2, 1.0}, intensity = 1.0,
            groupId = 1, flickerSpeed = 6.0, flickerStrength = 0.12
        })
    end
    -- Group 2: overhead lights (white) — always on
    for i = 0, 2 do
        lurek.light.newLight(200 + i * 300, 550, 180, {
            color = {0.9, 0.9, 1.0, 1.0}, intensity = 0.7,
            groupId = 2
        })
    end
end

local function setup_shadows()
    clear_all()
    lurek.light.setAmbient(0.08, 0.08, 0.12, 1.0)
    -- Shadow filter: none
    lurek.light.newLight(200, 350, 200, {
        color = {1.0, 0.8, 0.5, 1.0}, intensity = 1.0,
        shadowEnabled = true, shadowFilter = "none"
    })
    -- Shadow filter: pcf5
    lurek.light.newLight(500, 350, 200, {
        color = {0.5, 0.8, 1.0, 1.0}, intensity = 1.0,
        shadowEnabled = true, shadowFilter = "pcf5"
    })
    -- Shadow filter: pcf13
    lurek.light.newLight(800, 350, 200, {
        color = {0.8, 1.0, 0.5, 1.0}, intensity = 1.0,
        shadowEnabled = true, shadowFilter = "pcf13"
    })
    -- Occluders (wall segments)
    lurek.light.newOccluder({280, 280, 320, 280, 320, 420, 280, 420})
    lurek.light.newOccluder({580, 280, 620, 280, 620, 420, 580, 420})
    lurek.light.newOccluder({880, 280, 920, 280, 920, 420, 880, 420})
end

local function setup_blend_modes()
    clear_all()
    lurek.light.setAmbient(0.1, 0.1, 0.15, 1.0)
    -- Add mode (brightens)
    lurek.light.newLight(200, 350, 180, {
        color = {1.0, 0.5, 0.2, 1.0}, intensity = 1.0, blend = "add"
    })
    -- Sub mode (darkens — creates shadows/holes)
    lurek.light.newLight(500, 350, 180, {
        color = {0.5, 0.3, 0.8, 1.0}, intensity = 1.0, blend = "sub"
    })
    -- Mix mode (tints without brightening)
    lurek.light.newLight(800, 350, 180, {
        color = {0.2, 0.8, 0.5, 1.0}, intensity = 1.0, blend = "mix"
    })
end

-- ── Screen switch table ──────────────────────────────────────────────────

local setup_fns = {
    setup_point_lights,
    setup_spot_lights,
    setup_directional_light,
    setup_flicker,
    setup_attenuation,
    setup_groups,
    setup_shadows,
    setup_blend_modes,
}

-- ── Callbacks ────────────────────────────────────────────────────────────

function lurek.init()
    setup_fns[screen]()
end

function lurek.process(dt)
    time = time + dt

    -- WASD movement for the player light (group 99)
    local dx, dy = 0, 0
    if lurek.keyboard.isDown("w") then dy = dy - 1 end
    if lurek.keyboard.isDown("s") then dy = dy + 1 end
    if lurek.keyboard.isDown("a") then dx = dx - 1 end
    if lurek.keyboard.isDown("d") then dx = dx + 1 end
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        player_x = player_x + (dx / len) * MOVE_SPEED * dt
        player_y = player_y + (dy / len) * MOVE_SPEED * dt
        -- Clamp
        player_x = math.max(0, math.min(W, player_x))
        player_y = math.max(0, math.min(H, player_y))
    end

    -- Advance flickers for screens that use them
    if screen == 4 or screen == 6 then
        lurek.light.advanceFlickers(dt)
    end
end

function lurek.render()
    -- Background
    lurek.render.clear(0.02, 0.02, 0.04)

    -- Draw a simple grid floor
    lurek.render.setColor(0.15, 0.15, 0.2, 1.0)
    for x = 0, W, 64 do
        lurek.render.line(x, 0, x, H)
    end
    for y = 0, H, 64 do
        lurek.render.line(0, y, W, y)
    end

    -- Draw occluder outlines (screen 7)
    if screen == 7 then
        lurek.render.setColor(0.4, 0.4, 0.5, 1.0)
        lurek.render.rectangle("fill", 280, 280, 40, 140)
        lurek.render.rectangle("fill", 580, 280, 40, 140)
        lurek.render.rectangle("fill", 880, 280, 40, 140)
    end

    -- Draw player dot
    lurek.render.setColor(1.0, 1.0, 0.8, 0.8)
    lurek.render.circle("fill", player_x, player_y, 6)

    -- HUD — screen title and description
    lurek.render.setColor(1.0, 1.0, 1.0, 1.0)
    local s = screens[screen]
    lurek.render.print("Screen " .. screen .. "/" .. NUM_SCREENS .. ": " .. s.title, 20, 20)
    lurek.render.setColor(0.7, 0.7, 0.8, 1.0)
    lurek.render.print(s.desc, 20, 45)

    -- Controls
    lurek.render.setColor(0.5, 0.5, 0.6, 1.0)
    lurek.render.print("Keys 1-8: switch screen  |  WASD: move light", 20, H - 30)
    if screen == 6 then
        local state_str = group1_on and "ON" or "OFF"
        lurek.render.print("G: toggle torch group (" .. state_str .. ")", 20, H - 55)
    end

    -- Per-screen labels
    if screen == 1 then
        -- Labels for each light
        lurek.render.setColor(1.0, 0.6, 0.2, 0.7)
        lurek.render.print("Warm orange", 160, 230)
        lurek.render.setColor(0.3, 0.5, 1.0, 0.7)
        lurek.render.print("Cool blue", 460, 130)
        lurek.render.setColor(0.2, 1.0, 0.3, 0.7)
        lurek.render.print("Green", 720, 430)
        lurek.render.setColor(0.8, 0.2, 1.0, 0.7)
        lurek.render.print("Purple", 310, 480)
    elseif screen == 2 then
        lurek.render.setColor(1.0, 0.9, 0.5, 0.7)
        lurek.render.print("Narrow cone ->", 50, 320)
        lurek.render.setColor(0.5, 0.8, 1.0, 0.7)
        lurek.render.print("Wide cone v", 450, 60)
        lurek.render.setColor(1.0, 0.3, 0.3, 0.7)
        lurek.render.print("Tight cone", 750, 560)
    elseif screen == 4 then
        lurek.render.setColor(0.8, 0.8, 0.8, 0.6)
        lurek.render.print("Slow candle", 155, 270)
        lurek.render.print("Medium torch", 395, 270)
        lurek.render.print("Fast campfire", 640, 270)
        lurek.render.print("Strobe", 870, 140)
    elseif screen == 5 then
        lurek.render.setColor(0.8, 0.8, 0.8, 0.6)
        lurek.render.print("Default (none)", 140, 270)
        lurek.render.print("Linear", 410, 270)
        lurek.render.print("Quadratic", 650, 270)
        lurek.render.print("Mixed", 910, 270)
    elseif screen == 7 then
        lurek.render.setColor(0.8, 0.8, 0.8, 0.6)
        lurek.render.print("No filter", 155, 230)
        lurek.render.print("PCF5", 470, 230)
        lurek.render.print("PCF13", 760, 230)
    elseif screen == 8 then
        lurek.render.setColor(0.8, 0.8, 0.8, 0.6)
        lurek.render.print("Add (brighten)", 140, 270)
        lurek.render.print("Sub (darken)", 445, 270)
        lurek.render.print("Mix (tint)", 750, 270)
    end
end

function lurek.keypressed(key)
    -- Number keys switch screens
    local num = tonumber(key)
    if num and num >= 1 and num <= NUM_SCREENS then
        screen = num
        setup_fns[screen]()
        return
    end

    -- G toggles group 1 on screen 6
    if key == "g" and screen == 6 then
        group1_on = not group1_on
        lurek.light.setGroupEnabled(1, group1_on)
    end

    -- Escape quits
    if key == "escape" then
        lurek.signal.quit()
    end
end
