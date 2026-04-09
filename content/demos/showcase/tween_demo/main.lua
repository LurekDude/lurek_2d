-- examples/tween_demo/main.lua
-- Demonstrates lurek.math.newTween() with multiple easing curves.
-- Press R to reset all tweens. Press SPACE to pause/resume.
-- Run with: cargo run -- content/demos/showcase/tween_demo

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

function lurek.init()
    reset_tweens()
end

function reset_tweens()
    tweens = {}
    for _, name in ipairs(easings) do
        local tw = lurek.math.newTween(duration, name)
        tw:addValue(start_x, end_x) -- x position
        table.insert(tweens, { tween = tw, easing = name })
    end
end

function lurek.process(dt)
    if paused then return end
    for _, entry in ipairs(tweens) do
        entry.tween:update(dt)
    end
end

function lurek.render()
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Tween Demo — Easing Curves", 20, 15)
    lurek.gfx.print("R = reset   SPACE = " .. (paused and "resume" or "pause"), 20, 38)

    local y = 80
    local row_h = 48
    local ball_r = 10

    for _, entry in ipairs(tweens) do
        local x = entry.tween:getValue(1)

        -- Label
        lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
        lurek.gfx.print(entry.easing, 10, y + 2)

        -- Track line
        lurek.gfx.setColor(0.3, 0.3, 0.3, 1)
        lurek.gfx.rectangle("fill", start_x, y + ball_r - 1, end_x - start_x, 2)

        -- Ball
        local complete = entry.tween:isComplete()
        if complete then
            lurek.gfx.setColor(0.2, 0.9, 0.2, 1)
        else
            lurek.gfx.setColor(1, 0.5, 0.1, 1)
        end
        lurek.gfx.circle("fill", x, y + ball_r, ball_r)

        y = y + row_h
    end
end

function lurek.keypressed(key)
    if key == "r" then
        reset_tweens()
        paused = false
    elseif key == "space" then
        paused = not paused
    elseif key == "escape" then
        lurek.signal.quit()
    end
end
