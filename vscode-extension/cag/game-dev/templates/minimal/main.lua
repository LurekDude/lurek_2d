function luna.load()
    -- Load resources here
end

function luna.update(dt)
    -- Game logic here
end

function luna.draw()
    luna.graphics.clear(0.1, 0.1, 0.15)
    luna.graphics.print("Hello, Luna2D!", 320, 280)
end

function luna.keypressed(key)
    if key == "escape" then
        luna.event.quit()
    end
end
