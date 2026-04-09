-- Module availability guard (added by fix script)
-- Run with: cargo run -- demos/showcase/nine_slice_demo
if not luna.gfx.newNineSlice then
    function luna.init()
        luna.gfx.setBackgroundColor(0.15, 0.15, 0.25)
        luna.gfx.print("luna.gfx.newNineSlice not available", 180, 270)
        luna.gfx.print("Nine-Slice Demo  --  placeholder screenshot", 200, 310)
    end
    return
end

-- Nine-Slice (9-patch) Demo for Luna2D
--
-- Demonstrates luna.gfx.newNineSlice / drawNineSlice for
-- building scalable UI panels, buttons, and dialog boxes.
-- Corners preserve their size while edges and center stretch.

local panel
local button
local sizes = {
    { w = 200, h = 100, label = "Small" },
    { w = 400, h = 150, label = "Medium" },
    { w = 600, h = 250, label = "Large" },
}
local current = 1
local timer = 0

function luna.init()
    luna.window.setTitle("Nine-Slice Demo - Luna2D")
    luna.gfx.setBackgroundColor(0.15, 0.15, 0.25)

    -- Load the icon as our nine-slice source image.
    -- Border insets define the non-stretching corner/edge regions (pixels).
    local img = luna.gfx.newImage("assets/icon.png")
    panel = luna.gfx.newNineSlice(img, 32, 32, 32, 32)
    button = luna.gfx.newNineSlice(img, 16, 16, 16, 16)
end

function luna.process(dt)
    timer = timer + dt
    -- Cycle through sizes every 2 seconds
    if timer >= 2.0 then
        timer = timer - 2.0
        current = current % #sizes + 1
    end
end

function luna.render()
    local screenW, screenH = luna.gfx.getDimensions()
    local size = sizes[current]

    -- Title
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("Nine-Slice (9-patch) Demo", 20, 20, 2.5)

    -- Draw the panel centered on screen
    local px = (screenW - size.w) / 2
    local py = (screenH - size.h) / 2

    -- Panel background with tint
    luna.gfx.setColor(0.3, 0.5, 0.9, 0.8)
    luna.gfx.drawNineSlice(panel, px, py, size.w, size.h)

    -- Label inside the panel
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print(size.label .. " panel (" .. size.w .. "x" .. size.h .. ")",
        px + 40, py + 20, 2)

    -- Draw three buttons below the panel using the method syntax
    luna.gfx.setColor(0.9, 0.4, 0.2, 0.9)
    local btnY = py + size.h + 30
    for i = 1, 3 do
        local btnW = 100 + i * 30
        local btnX = px + (i - 1) * (btnW + 20)
        button:draw(btnX, btnY, btnW, 50)

        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Btn " .. i, btnX + 15, btnY + 12, 1.5)
        luna.gfx.setColor(0.9, 0.4, 0.2, 0.9)
    end

    -- Info text
    luna.gfx.setColor(0.6, 0.6, 0.6)
    luna.gfx.print("Cycles every 2s — corners stay fixed, center stretches", 20, screenH - 40, 1.5)

    -- FPS
    luna.gfx.setColor(0.5, 0.5, 0.5)
    local fps = math.floor(luna.time.getFPS())
    luna.gfx.print("FPS: " .. tostring(fps), screenW - 120, 10, 1.5)
end

function luna.keypressed(key)
    if key == "escape" then
        luna.quit()
    elseif key == "space" then
        current = current % #sizes + 1
    end
end
