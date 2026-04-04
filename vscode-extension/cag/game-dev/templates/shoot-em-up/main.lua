local Player     = require("entities.player")
local BulletPool = require("entities.bullet_pool")

local player, bullets
local score = 0

function luna.load()
    player  = Player.new(240, 560)
    bullets = BulletPool.new(200)
end

function luna.update(dt)
    player:update(dt, bullets)
    bullets:update(dt)
end

function luna.draw()
    luna.graphics.clear(0.05, 0.05, 0.1)
    player:draw()
    bullets:draw()
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Score: " .. score, 10, 10)
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
end
