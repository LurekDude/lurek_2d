function luna.init()
    -- Load resources here
end

function luna.process(dt)
    -- Game logic here
end

function luna.render()
    luna.gfx.clear(0.1, 0.1, 0.15)
    luna.gfx.print("Hello, Luna2D!", 320, 280)
end

function luna.keypressed(key)
    if key == "escape" then
        luna.signal.quit()
    end
end
