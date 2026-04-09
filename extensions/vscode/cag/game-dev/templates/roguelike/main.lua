local Dungeon = require("generator.dungeon")

local TILE = 16
local map
local player = { gx = 5, gy = 5 }
local turn = 0

function lurek.init()
    map = Dungeon.generate(50, 38)
    -- Place player in first open cell
    for y = 1, #map do
        for x = 1, #map[1] do
            if map[y][x] == 0 then
                player.gx, player.gy = x, y
                return
            end
        end
    end
end

function lurek.process(dt)
    -- Turn-based: logic runs in keypressed
end

function lurek.render()
    lurek.gfx.clear(0.05, 0.05, 0.08)
    -- Draw map
    for y = 1, #map do
        for x = 1, #map[1] do
            if map[y][x] == 1 then
                lurek.gfx.setColor(0.3, 0.3, 0.35, 1)
                lurek.gfx.rectangle("fill", (x - 1) * TILE, (y - 1) * TILE, TILE, TILE)
            end
        end
    end
    -- Draw player
    lurek.gfx.setColor(0.2, 0.8, 0.4, 1)
    lurek.gfx.rectangle("fill", (player.gx - 1) * TILE, (player.gy - 1) * TILE, TILE, TILE)
    -- UI
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Turn: " .. turn, 10, 580)
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    local dx, dy = 0, 0
    if key == "left"  or key == "a" then dx = -1 end
    if key == "right" or key == "d" then dx =  1 end
    if key == "up"    or key == "w" then dy = -1 end
    if key == "down"  or key == "s" then dy =  1 end

    if dx ~= 0 or dy ~= 0 then
        local nx, ny = player.gx + dx, player.gy + dy
        if map[ny] and map[ny][nx] == 0 then
            player.gx, player.gy = nx, ny
            turn = turn + 1
        end
    end
end
