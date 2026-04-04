local state = {
    load   = function() end,
    update = function(dt) end,
    draw   = function() end,
}

function luna.load()     state.load()     end
function luna.update(dt) state.update(dt) end
function luna.draw()     state.draw()     end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
end
