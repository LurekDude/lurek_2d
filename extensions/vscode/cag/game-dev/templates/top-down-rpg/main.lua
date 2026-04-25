local Player = require("entities.player")
local HUD    = require("ui.hud")

local scene = "title"
local player, hud

function lurek.init()
    player = Player.new(400, 300)
    hud    = HUD.new(player)
end

function lurek.process(dt)
    if scene == "title" then
        -- Press enter to start
    elseif scene == "game" then
        player:update(dt)
    end
end

function lurek.draw()
    lurek.render.clear(0.15, 0.2, 0.1)
    if scene == "title" then
        lurek.render.print("Press ENTER to start", 300, 280)
    elseif scene == "game" then
        player:draw()
        hud:draw()
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
    if key == "return" and scene == "title" then
        scene = "game"
    end
end
