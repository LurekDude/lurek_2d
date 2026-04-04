local Player = require("entities.player")
local HUD    = require("ui.hud")

local scene = "title"
local player, hud

function luna.load()
    player = Player.new(400, 300)
    hud    = HUD.new(player)
end

function luna.update(dt)
    if scene == "title" then
        -- Press enter to start
    elseif scene == "game" then
        player:update(dt)
    end
end

function luna.draw()
    luna.graphics.clear(0.15, 0.2, 0.1)
    if scene == "title" then
        luna.graphics.print("Press ENTER to start", 300, 280)
    elseif scene == "game" then
        player:draw()
        hud:draw()
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "return" and scene == "title" then
        scene = "game"
    end
end
