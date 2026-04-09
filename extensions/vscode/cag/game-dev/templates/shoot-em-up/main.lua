local Player     = require("entities.player")
local BulletPool = require("entities.bullet_pool")

local player, bullets
local score = 0

function lurek.init()
    player  = Player.new(240, 560)
    bullets = BulletPool.new(200)
end

function lurek.process(dt)
    player:update(dt, bullets)
    bullets:update(dt)
end

function lurek.render()
    lurek.gfx.clear(0.05, 0.05, 0.1)
    player:draw()
    bullets:draw()
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Score: " .. score, 10, 10)
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
end
