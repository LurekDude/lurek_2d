local state = {
    load   = function() end,
    update = function(dt) end,
    draw   = function() end,
}

function luna.init()     state.load()     end
function luna.process(dt) state.update(dt) end
function luna.render()     state.draw()     end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
end
