local DialogRunner = require("engine.dialog_runner")

local dialog

function luna.load()
    dialog = DialogRunner.new({
        { speaker = "Luna", text = "Welcome to the Luna2D visual novel template!" },
        { speaker = "Luna", text = "Press SPACE or click to advance the dialog." },
        { speaker = "Luna", text = "You can add choices, branching, and more." },
        { speaker = "???",  text = "The story is yours to write..." },
    })
end

function luna.update(dt)
    dialog:update(dt)
end

function luna.draw()
    luna.graphics.clear(0.08, 0.06, 0.12)
    -- Background area
    luna.graphics.setColor(0.15, 0.1, 0.2, 1)
    luna.graphics.rectangle("fill", 0, 0, 800, 400)
    -- Dialog box
    dialog:draw()
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "space" or key == "return" then
        dialog:advance()
    end
end

function luna.mousepressed(x, y, btn)
    if btn == 1 then
        dialog:advance()
    end
end
