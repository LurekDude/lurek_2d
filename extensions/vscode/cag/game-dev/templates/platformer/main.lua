local Player = require("entities.player")
local Camera = require("lib.camera")

local player, camera

function lurek.init()
    player = Player.new(100, 300)
    camera = Camera.new()
end

function lurek.process(dt)
    player:update(dt)
    camera:follow(player, dt)
end

function lurek.render()
    lurek.gfx.clear(0.2, 0.6, 0.9)
    camera:apply()
    player:draw()
    camera:reset()
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    player:keypressed(key)
end
