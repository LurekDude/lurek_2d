local Grid = require("entities.grid")

local grid
local moves = 0
local won = false

function lurek.init()
    grid = Grid.new(8, 8, 60)
end

function lurek.process(dt)
    -- Puzzle logic runs on input, not per-frame
end

function lurek.render()
    lurek.gfx.clear(0.12, 0.12, 0.18)
    grid:draw()
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Moves: " .. moves, 10, 10)
    if won then
        lurek.gfx.print("You Win!", 250, 280)
    end
end

function lurek.mousepressed(x, y, btn)
    if won then return end
    if btn == 1 then
        local changed = grid:click(x, y)
        if changed then
            moves = moves + 1
            won = grid:checkWin()
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then
        grid = Grid.new(8, 8, 60)
        moves = 0
        won = false
    end
end
