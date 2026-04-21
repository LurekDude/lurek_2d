local Class  = require("lib.class")
local Events = require("lib.events")

function lurek.init()
    Events.emit("game:start")
end

function lurek.process(dt)
    Events.emit("game:update", dt)
end

function lurek.render()
    lurek.render.clear(0.1, 0.1, 0.15)
    Events.emit("game:draw")
end

function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
    Events.emit("input:keypressed", key)
end
