local Player = require("entities.player")
local Camera = require("lib.camera")

local player, camera

function luna.init()
    player = Player.new(100, 300)
    camera = Camera.new()
end

function luna.process(dt)
    player:update(dt)
    camera:follow(player, dt)
end

function luna.render()
    luna.gfx.clear(0.2, 0.6, 0.9)
    camera:apply()
    player:draw()
    camera:reset()
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    player:keypressed(key)
end
