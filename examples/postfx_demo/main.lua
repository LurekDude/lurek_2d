-- PostFX Demo — Luna2D post-processing effects demonstration
-- Shows how to create effects, add them to a stack, toggle them,
-- and tweak parameters at runtime using keyboard controls.

-- State
local effects = {}
local stack = nil
local current_effect = 1
local effect_names = { "bloom", "blur", "crt", "godrays", "vignette", "colourgrade", "chromatic" }
local active = {}  -- tracks which effects are active in the stack

function luna.load()
    luna.window.setTitle("PostFX Demo - Luna2D")
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.1)

    -- Create a stack at window resolution
    stack = luna.postfx.newStack(800, 600)

    -- Create one of each built-in effect
    for i, name in ipairs(effect_names) do
        effects[i] = luna.postfx.newEffect(name)
        active[i] = false
    end

    -- Enable bloom by default for a nice starting look
    stack:add(effects[1])
    active[1] = true
end

function luna.update(dt)
    -- Nothing to update — all interaction is via keypressed
end

function luna.draw()
    -- Draw a colourful scene to show effects on
    -- Background shapes
    luna.graphics.setColor(0.2, 0.1, 0.4)
    luna.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Bright circles (good for bloom)
    luna.graphics.setColor(1.0, 0.8, 0.2)
    luna.graphics.circle("fill", 200, 200, 60)

    luna.graphics.setColor(0.2, 0.8, 1.0)
    luna.graphics.circle("fill", 500, 300, 80)

    luna.graphics.setColor(1.0, 0.3, 0.5)
    luna.graphics.circle("fill", 350, 450, 50)

    -- Grid lines (good for CRT / chromatic aberration)
    luna.graphics.setColor(0.3, 0.3, 0.5)
    for x = 0, 800, 50 do
        luna.graphics.line(x, 0, x, 600)
    end
    for y = 0, 600, 50 do
        luna.graphics.line(0, y, 800, y)
    end

    -- Bright star pattern (good for godrays)
    luna.graphics.setColor(1.0, 1.0, 0.9)
    for angle = 0, 360, 30 do
        local rad = math.rad(angle)
        local cx, cy = 400, 300
        local len = 100
        luna.graphics.line(cx, cy, cx + math.cos(rad) * len, cy + math.sin(rad) * len)
    end

    -- HUD — show effect info
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("PostFX Demo", 10, 10, 2)

    local fps = luna.math.floor(luna.timer.getFPS())
    luna.graphics.print("FPS: " .. tostring(fps), 700, 10, 1.5)

    -- Show effect list
    local y = 50
    for i, name in ipairs(effect_names) do
        if i == current_effect then
            luna.graphics.setColor(1, 1, 0)
            luna.graphics.print("> ", 10, y, 1.5)
        else
            luna.graphics.setColor(0.6, 0.6, 0.6)
        end

        local status = active[i] and "[ON]" or "[off]"
        luna.graphics.print(name .. " " .. status, 30, y, 1.5)

        -- Show key parameters for the current effect
        if i == current_effect then
            local params = effects[i]:getParameterNames()
            local param_str = ""
            for _, pname in ipairs(params) do
                local val = effects[i]:getParameter(pname)
                param_str = param_str .. pname .. "=" .. string.format("%.2f", val) .. " "
            end
            if #param_str > 0 then
                luna.graphics.setColor(0.5, 0.8, 1.0)
                luna.graphics.print("  " .. param_str, 30, y + 18, 1)
            end
        end

        y = y + 35
    end

    -- Controls
    luna.graphics.setColor(0.7, 0.7, 0.7)
    luna.graphics.print("Controls:", 10, 370, 1.5)
    luna.graphics.print("Up/Down = select effect", 10, 395, 1)
    luna.graphics.print("Space = toggle effect on/off", 10, 415, 1)
    luna.graphics.print("Left/Right = adjust first parameter", 10, 435, 1)
    luna.graphics.print("Stack effects: " .. stack:getEffectCount(), 10, 465, 1.2)
end

function luna.keypressed(key)
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
        luna.event.quit()
    end
end
