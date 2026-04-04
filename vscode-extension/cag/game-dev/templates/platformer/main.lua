local Player = require("entities.player")
local Camera = require("lib.camera")

local player, camera

function luna.load()
    player = Player.new(100, 300)
    camera = Camera.new()
end

function luna.update(dt)
    player:update(dt)
    camera:follow(player, dt)
end

function luna.draw()
    luna.graphics.clear(0.2, 0.6, 0.9)
    camera:apply()
    player:draw()
    camera:reset()
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    player:keypressed(key)
end
