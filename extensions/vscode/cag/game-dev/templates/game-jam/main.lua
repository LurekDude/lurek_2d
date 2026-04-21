local state = {
    load   = function() end,
    update = function(dt) end,
    draw   = function() end,
}

function lurek.init()     state.load()     end
function lurek.process(dt) state.update(dt) end
function lurek.render()     state.draw()     end

function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
end
