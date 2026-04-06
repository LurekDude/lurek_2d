-- examples/tween_demo/main.lua
-- Demonstrates luna.math.newTween() with multiple easing curves.
-- Press R to reset all tweens. Press SPACE to pause/resume.

local tweens = {}
local paused = false
local easings = {
    "linear",
    "inQuad",
    "outQuad",
    "inOutQuad",
    "inCubic",
    "outCubic",
    "inSine",
    "outSine",
    "inExpo",
    "outExpo",
}

local duration = 3.0
local start_x  = 150
local end_x    = 700

function luna.load()
    reset_tweens()
end

function reset_tweens()
    tweens = {}
    for _, name in ipairs(easings) do
        local tw = luna.math.newTween(duration, name)
        tw:addValue(start_x, end_x) -- x position
        table.insert(tweens, { tween = tw, easing = name })
    end
end

function luna.update(dt)
    if paused then return end
    for _, entry in ipairs(tweens) do
        entry.tween:update(dt)
    end
end

function luna.draw()
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Tween Demo — Easing Curves", 20, 15)
    luna.graphics.print("R = reset   SPACE = " .. (paused and "resume" or "pause"), 20, 38)

    local y = 80
    local row_h = 48
    local ball_r = 10

    for _, entry in ipairs(tweens) do
        local x = entry.tween:getValue(1)

        -- Label
        luna.graphics.setColor(0.7, 0.7, 0.7, 1)
        luna.graphics.print(entry.easing, 10, y + 2)

        -- Track line
        luna.graphics.setColor(0.3, 0.3, 0.3, 1)
        luna.graphics.rectangle("fill", start_x, y + ball_r - 1, end_x - start_x, 2)

        -- Ball
        local complete = entry.tween:isComplete()
        if complete then
            luna.graphics.setColor(0.2, 0.9, 0.2, 1)
        else
            luna.graphics.setColor(1, 0.5, 0.1, 1)
        end
        luna.graphics.circle("fill", x, y + ball_r, ball_r)

        y = y + row_h
    end
end

function luna.keypressed(key)
    if key == "r" then
        reset_tweens()
        paused = false
    elseif key == "space" then
        paused = not paused
    elseif key == "escape" then
        luna.event.quit()
    end
end
