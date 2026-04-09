function lurek.init()
    -- Load resources here
end

function lurek.process(dt)
    -- Game logic here
end

function lurek.render()
    lurek.gfx.clear(0.1, 0.1, 0.15)
    lurek.gfx.print("Hello, Lurek2D!", 320, 280)
end

function lurek.keypressed(key)
    if key == "escape" then
        lurek.signal.quit()
    end
end
