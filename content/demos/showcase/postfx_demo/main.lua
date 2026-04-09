-- Module availability guard (added by fix_nil_module_demos.py)
-- Run with: cargo run -- content/demos/showcase/postfx_demo
if not lurek.postfx then
    function lurek.init()
        lurek.gfx.setBackgroundColor(0.08, 0.08, 0.12)
        lurek.gfx.print("lurek.postfx is not available - use lurek.postfx instead", 180, 270)
    end
    return
end

-- PostFX Demo — Lurek2D post-processing effects demonstration
-- Shows how to create effects, add them to a stack, toggle them,
-- and tweak parameters at runtime using keyboard controls.

-- State
local effects = {}
local stack = nil
local current_effect = 1
local effect_names = {
    "bloom", "blur", "crt", "godrays", "vignette", "colourgrade", "chromatic",
    "pixelate", "sepia", "grayscale", "invert", "scanlines", "edgedetect", "hueshift", "noise"
}
local active = {}  -- tracks which effects are active in the stack

function lurek.init()
    lurek.window.setTitle("PostFX Demo - Lurek2D")
    lurek.gfx.setBackgroundColor(0.05, 0.05, 0.1)

    -- Create a stack at window resolution
    stack = lurek.postfx.newStack(800, 600)

    -- Create one of each built-in effect
    for i, name in ipairs(effect_names) do
        effects[i] = lurek.postfx.newEffect(name)
        active[i] = false
    end

    -- Enable bloom by default for a nice starting look
    stack:add(effects[1])
    active[1] = true
end

function lurek.process(dt)
    -- Nothing to update — all interaction is via keypressed
end

function lurek.render()
    -- Capture the scene into the PostFX stack so effects are applied
    stack:beginCapture()

    -- Draw a colourful scene to show effects on
    -- Background shapes
    lurek.gfx.setColor(0.2, 0.1, 0.4)
    lurek.gfx.rectangle("fill", 0, 0, 800, 600)

    -- Bright circles (good for bloom)
    lurek.gfx.setColor(1.0, 0.8, 0.2)
    lurek.gfx.circle("fill", 200, 200, 60)

    lurek.gfx.setColor(0.2, 0.8, 1.0)
    lurek.gfx.circle("fill", 500, 300, 80)

    lurek.gfx.setColor(1.0, 0.3, 0.5)
    lurek.gfx.circle("fill", 350, 450, 50)

    -- Grid lines (good for CRT / chromatic aberration)
    lurek.gfx.setColor(0.3, 0.3, 0.5)
    for x = 0, 800, 50 do
        lurek.gfx.line(x, 0, x, 600)
    end
    for y = 0, 600, 50 do
        lurek.gfx.line(0, y, 800, y)
    end

    -- Bright star pattern (good for godrays)
    lurek.gfx.setColor(1.0, 1.0, 0.9)
    for angle = 0, 360, 30 do
        local rad = math.rad(angle)
        local cx, cy = 400, 300
        local len = 100
        lurek.gfx.line(cx, cy, cx + math.cos(rad) * len, cy + math.sin(rad) * len)
    end

    -- HUD — drawn after apply() so it renders on top of the post-processed scene
    stack:endCapture()
    stack:apply()

    -- HUD — show effect info
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("PostFX Demo", 10, 10, 2)

    local fps = math.floor(lurek.time.getFPS())
    lurek.gfx.print("FPS: " .. tostring(fps), 700, 10, 1.5)

    -- Show effect list
    local y = 50
    for i, name in ipairs(effect_names) do
        if i == current_effect then
            lurek.gfx.setColor(1, 1, 0)
            lurek.gfx.print("> ", 10, y, 1.5)
        else
            lurek.gfx.setColor(0.6, 0.6, 0.6)
        end

        local status = active[i] and "[ON]" or "[off]"
        lurek.gfx.print(name .. " " .. status, 30, y, 1.5)

        -- Show key parameters for the current effect
        if i == current_effect then
            local params = effects[i]:getParameterNames()
            local param_str = ""
            for _, pname in ipairs(params) do
                local val = effects[i]:getParameter(pname)
                param_str = param_str .. pname .. "=" .. string.format("%.2f", val) .. " "
            end
            if #param_str > 0 then
                lurek.gfx.setColor(0.5, 0.8, 1.0)
                lurek.gfx.print("  " .. param_str, 30, y + 18, 1)
            end
        end

        y = y + 30
    end

    -- Controls
    lurek.gfx.setColor(0.7, 0.7, 0.7)
    lurek.gfx.print("Controls:", 500, 50, 1.5)
    lurek.gfx.print("Up/Down = select effect", 500, 75, 1)
    lurek.gfx.print("Space = toggle effect on/off", 500, 95, 1)
    lurek.gfx.print("Left/Right = adjust first parameter", 500, 115, 1)
    lurek.gfx.print("Stack effects: " .. stack:getEffectCount(), 500, 140, 1.2)
end

function lurek.keypressed(key)
    if key == "up" then
        current_effect = current_effect - 1
        if current_effect < 1 then current_effect = #effect_names end
    elseif key == "down" then
        current_effect = current_effect + 1
        if current_effect > #effect_names then current_effect = 1 end
    elseif key == "space" then
        -- Toggle current effect on/off in the stack
        if active[current_effect] then
            stack:remove(effects[current_effect])
            active[current_effect] = false
        else
            stack:add(effects[current_effect])
            active[current_effect] = true
        end
    elseif key == "left" or key == "right" then
        -- Adjust the first parameter of the current effect
        local params = effects[current_effect]:getParameterNames()
        if #params > 0 then
            local pname = params[1]
            local val = effects[current_effect]:getParameter(pname)
            local delta = key == "right" and 0.1 or -0.1
            effects[current_effect]:setParameter(pname, math.max(0, val + delta))
        end
    elseif key == "escape" then
        lurek.signal.quit()
    end
end
