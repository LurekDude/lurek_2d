-- Signal Demo — Luna2D example
-- Demonstrates the pub-sub Signal system for decoupled event handling.

local events = luna.event.newSignal()
local log = {}
local score = 0
local combo = 0

-- Register listeners for game events
events:register("score", function(points)
    score = score + points
    table.insert(log, "Scored " .. points .. " points!")
end)

events:register("score", function(points)
    combo = combo + 1
    if combo >= 3 then
        table.insert(log, "COMBO x" .. combo .. "!")
    end
end)

events:register("reset", function()
    score = 0
    combo = 0
    table.insert(log, "Score reset!")
end)

events:register("hit", function(target)
    table.insert(log, "Hit: " .. target)
    events:emit("score", 10)
end)

function luna.load()
    luna.window.setTitle("Signal Demo")

    -- Simulate some game events
    events:emit("hit", "enemy_A")
    events:emit("hit", "enemy_B")
    events:emit("hit", "enemy_C")
    events:emit("score", 50)
end

function luna.update(dt)
    -- Keep log from growing too large
    while #log > 20 do
        table.remove(log, 1)
    end
end

function luna.draw()
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("Signal Demo — Press SPACE for hit, R to reset", 20, 20)
    luna.graphics.print("Score: " .. score, 20, 50)
    luna.graphics.print("Combo: " .. combo, 20, 70)
    luna.graphics.print("Listeners: " .. events:getTotalCount(), 20, 90)

    luna.graphics.setColor(0.7, 0.9, 0.7)
    for i, msg in ipairs(log) do
        luna.graphics.print(msg, 30, 110 + (i - 1) * 18)
    end
end

function luna.keypressed(key)
    if key == "space" then
        events:emit("hit", "target_" .. math.random(1, 9))
    elseif key == "r" then
        events:emit("reset")
    elseif key == "escape" then
        luna.event.quit()
    end
end
