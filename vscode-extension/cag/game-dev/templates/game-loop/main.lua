local Class  = require("lib.class")
local Events = require("lib.events")

function luna.load()
    Events.emit("game:start")
end

function luna.update(dt)
    Events.emit("game:update", dt)
end

function luna.draw()
    luna.graphics.clear(0.1, 0.1, 0.15)
    Events.emit("game:draw")
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    Events.emit("input:keypressed", key)
end
