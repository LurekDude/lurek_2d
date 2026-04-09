local DialogRunner = require("engine.dialog_runner")

local dialog

function lurek.init()
    dialog = DialogRunner.new({
        { speaker = "Luna", text = "Welcome to the Lurek2D visual novel template!" },
        { speaker = "Luna", text = "Press SPACE or click to advance the dialog." },
        { speaker = "Luna", text = "You can add choices, branching, and more." },
        { speaker = "???",  text = "The story is yours to write..." },
    })
end

function lurek.process(dt)
    dialog:update(dt)
end

function lurek.render()
    lurek.gfx.clear(0.08, 0.06, 0.12)
    -- Background area
    lurek.gfx.setColor(0.15, 0.1, 0.2, 1)
    lurek.gfx.rectangle("fill", 0, 0, 800, 400)
    -- Dialog box
    dialog:draw()
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "space" or key == "return" then
        dialog:advance()
    end
end

function lurek.mousepressed(x, y, btn)
    if btn == 1 then
        dialog:advance()
    end
end
