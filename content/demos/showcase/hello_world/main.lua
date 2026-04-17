-- Hello World example for Lurek2D
-- Phase 12: simplex noise available via lurek.math.simplex2d(x, y) or lurek.math.simplex2d(x, y, z)
-- Run with: cargo run -- content/demos/showcase/hello_world

function lurek.init()
    lurek.window.setTitle("Hello World - Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.2)
end

function lurek.process(dt)
    -- Nothing to update
end

function lurek.render()
    -- Draw some shapes
    lurek.render.setColor(0.3, 0.5, 1.0)
    lurek.render.rectangle("fill", 100, 100, 200, 150)

    lurek.render.setColor(1.0, 0.4, 0.2)
    lurek.render.circle("fill", 500, 250, 60)

    lurek.render.setColor(0.2, 0.9, 0.3)
    lurek.render.line(50, 400, 750, 400)

    -- Draw text
    lurek.render.setColor(1, 1, 1)
    lurek.render.print("Hello, Lurek2D!", 300, 50, 3)

    -- Show FPS
    lurek.render.setColor(0.7, 0.7, 0.7)
    local fps = math.floor(lurek.time.getFPS())
    lurek.render.print("FPS: " .. tostring(fps), 10, 10, 2)
end

function lurek.keypressed(key)
    if key == "space" then
        lurek.render.setBackgroundColor(
            math.random(),
            math.random(),
            math.random()
        )
    end

    -- Press S to capture a screenshot (stub: receives a blank ImageData)
    if key == "s" then
        local ok, err = pcall(lurek.render.captureScreenshot, function(img)
            local w, h = img:getDimensions()
            lurek.log.info("Screenshot captured: " .. w .. "x" .. h .. " pixels")
        end)
        if not ok then
            lurek.log.warn("captureScreenshot failed: " .. tostring(err))
        end
    end
end
