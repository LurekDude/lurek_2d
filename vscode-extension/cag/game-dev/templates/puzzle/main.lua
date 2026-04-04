local Grid = require("entities.grid")

local grid
local moves = 0
local won = false

function luna.load()
    grid = Grid.new(8, 8, 60)
end

function luna.update(dt)
    -- Puzzle logic runs on input, not per-frame
end

function luna.draw()
    luna.graphics.clear(0.12, 0.12, 0.18)
    grid:draw()
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Moves: " .. moves, 10, 10)
    if won then
        luna.graphics.print("You Win!", 250, 280)
    end
end

function luna.mousepressed(x, y, btn)
    if won then return end
    if btn == 1 then
        local changed = grid:click(x, y)
        if changed then
            moves = moves + 1
            won = grid:checkWin()
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then
        grid = Grid.new(8, 8, 60)
        moves = 0
        won = false
    end
end
