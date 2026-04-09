local Class  = require("lib.class")
local Events = require("lib.events")

function luna.init()
    Events.emit("game:start")
end

function luna.process(dt)
    Events.emit("game:update", dt)
end

function luna.render()
    luna.gfx.clear(0.1, 0.1, 0.15)
    Events.emit("game:draw")
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    Events.emit("input:keypressed", key)
end
