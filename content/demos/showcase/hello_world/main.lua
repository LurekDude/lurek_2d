-- Hello World example for Luna2D
-- Phase 12: simplex noise available via luna.math.simplex2d(x, y) or luna.math.simplex2d(x, y, z)
-- Run with: cargo run -- demos/showcase/hello_world

function luna.init()
    luna.window.setTitle("Hello World - Luna2D")
    luna.gfx.setBackgroundColor(0.1, 0.1, 0.2)
end

function luna.process(dt)
    -- Nothing to update
end

function luna.render()
    -- Draw some shapes
    luna.gfx.setColor(0.3, 0.5, 1.0)
    luna.gfx.rectangle("fill", 100, 100, 200, 150)

    luna.gfx.setColor(1.0, 0.4, 0.2)
    luna.gfx.circle("fill", 500, 250, 60)

    luna.gfx.setColor(0.2, 0.9, 0.3)
    luna.gfx.line(50, 400, 750, 400)

    -- Draw text
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("Hello, Luna2D!", 300, 50, 3)

    -- Show FPS
    luna.gfx.setColor(0.7, 0.7, 0.7)
    local fps = math.floor(luna.time.getFPS())
    luna.gfx.print("FPS: " .. tostring(fps), 10, 10, 2)
end

function luna.keypressed(key)
    if key == "space" then
        luna.gfx.setBackgroundColor(
            math.random(),
            math.random(),
            math.random()
        )
    end

    -- Press S to capture a screenshot (stub: receives a blank ImageData)
    if key == "s" then
        local ok, err = pcall(luna.gfx.captureScreenshot, function(img)
            local w, h = img:getDimensions()
            luna.log.info("Screenshot captured: " .. w .. "x" .. h .. " pixels")
        end)
        if not ok then
            luna.log.warn("captureScreenshot failed: " .. tostring(err))
        end
    end
end
