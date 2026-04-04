local M = {}

local time = 0

function M.update(dt)
    time = time + dt
end

function M.draw()
    luna.graphics.print("Scene 2: Shapes", 10, 10)

    -- Rotating rectangles
    for i = 1, 6 do
        local angle = time + i * 1.047
        local cx = 400 + math.cos(angle) * 150
        local cy = 300 + math.sin(angle) * 150
        luna.graphics.setColor(0.2 + i * 0.1, 0.4, 0.8, 0.8)
        luna.graphics.rectangle("fill", cx - 20, cy - 20, 40, 40)
    end

    -- Center circle
    luna.graphics.setColor(1, 0.8, 0.2, 1)
    luna.graphics.circle("fill", 400, 300, 30)
    luna.graphics.setColor(1, 1, 1, 1)
end

return M
