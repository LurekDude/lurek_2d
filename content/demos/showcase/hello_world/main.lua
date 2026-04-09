-- Hello World example for Lurek2D
-- Phase 12: simplex noise available via lurek.math.simplex2d(x, y) or lurek.math.simplex2d(x, y, z)
-- Run with: cargo run -- content/demos/showcase/hello_world

function lurek.init()
    lurek.window.setTitle("Hello World - Lurek2D")
    lurek.gfx.setBackgroundColor(0.1, 0.1, 0.2)
end

function lurek.process(dt)
    -- Nothing to update
end

function lurek.render()
    -- Draw some shapes
    lurek.gfx.setColor(0.3, 0.5, 1.0)
    lurek.gfx.rectangle("fill", 100, 100, 200, 150)

    lurek.gfx.setColor(1.0, 0.4, 0.2)
    lurek.gfx.circle("fill", 500, 250, 60)

    lurek.gfx.setColor(0.2, 0.9, 0.3)
    lurek.gfx.line(50, 400, 750, 400)

    -- Draw text
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Hello, Lurek2D!", 300, 50, 3)

    -- Show FPS
    lurek.gfx.setColor(0.7, 0.7, 0.7)
    local fps = math.floor(lurek.time.getFPS())
    lurek.gfx.print("FPS: " .. tostring(fps), 10, 10, 2)
end

function lurek.keypressed(key)
    if key == "space" then
        lurek.gfx.setBackgroundColor(
            math.random(),
            math.random(),
            math.random()
        )
    end

    -- Press S to capture a screenshot (stub: receives a blank ImageData)
    if key == "s" then
        local ok, err = pcall(lurek.gfx.captureScreenshot, function(img)
            local w, h = img:getDimensions()
            lurek.log.info("Screenshot captured: " .. w .. "x" .. h .. " pixels")
        end)
        if not ok then
            lurek.log.warn("captureScreenshot failed: " .. tostring(err))
        end
    end
end
