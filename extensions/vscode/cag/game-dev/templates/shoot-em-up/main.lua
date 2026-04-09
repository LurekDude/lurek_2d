local Player     = require("entities.player")
local BulletPool = require("entities.bullet_pool")

local player, bullets
local score = 0

function luna.init()
    player  = Player.new(240, 560)
    bullets = BulletPool.new(200)
end

function luna.process(dt)
    player:update(dt, bullets)
    bullets:update(dt)
end

function luna.render()
    luna.gfx.clear(0.05, 0.05, 0.1)
    player:draw()
    bullets:draw()
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Score: " .. score, 10, 10)
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
end
