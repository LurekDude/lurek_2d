-- Hello World example for Luna2D
-- Phase 12: simplex noise available via luna.math.simplex2d(x, y) or luna.math.simplex2d(x, y, z)

function luna.load()
    luna.window.setTitle("Hello World - Luna2D")
    luna.graphics.setBackgroundColor(0.1, 0.1, 0.2)
end

function luna.update(dt)
    -- Nothing to update
end

function luna.draw()
    -- Draw some shapes
    luna.graphics.setColor(0.3, 0.5, 1.0)
    luna.graphics.rectangle("fill", 100, 100, 200, 150)

    luna.graphics.setColor(1.0, 0.4, 0.2)
    luna.graphics.circle("fill", 500, 250, 60)

    luna.graphics.setColor(0.2, 0.9, 0.3)
    luna.graphics.line(50, 400, 750, 400)

    -- Draw text
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("Hello, Luna2D!", 300, 50, 3)

    -- Show FPS
    luna.graphics.setColor(0.7, 0.7, 0.7)
    local fps = math.floor(luna.timer.getFPS())
    luna.graphics.print("FPS: " .. tostring(fps), 10, 10, 2)
end

function luna.keypressed(key)
    if key == "space" then
        luna.graphics.setBackgroundColor(
            math.random(),
            math.random(),
            math.random()
        )
    end

    -- Press S to capture a screenshot (stub: receives a blank ImageData)
    if key == "s" then
        local ok, err = pcall(luna.graphics.captureScreenshot, function(img)
            local w, h = img:getDimensions()
            luna.log.info("Screenshot captured: " .. w .. "x" .. h .. " pixels")
        end)
        if not ok then
            luna.log.warn("captureScreenshot failed: " .. tostring(err))
        end
    end
end
