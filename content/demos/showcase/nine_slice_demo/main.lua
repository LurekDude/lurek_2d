-- Module availability guard (added by fix script)
-- Run with: cargo run -- content/demos/showcase/nine_slice_demo
if not lurek.render.newNineSlice then
    function lurek.init()
        lurek.render.setBackgroundColor(0.15, 0.15, 0.25)
        lurek.render.print("lurek.render.newNineSlice not available", 180, 270)
        lurek.render.print("Nine-Slice Demo  --  placeholder screenshot", 200, 310)
    end
    return
end

-- Nine-Slice (9-patch) Demo for Lurek2D
--
-- Demonstrates lurek.render.newNineSlice / drawNineSlice for
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

function lurek.init()
    lurek.window.setTitle("Nine-Slice Demo - Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.15, 0.25)

    -- Load the icon as our nine-slice source image.
    -- Border insets define the non-stretching corner/edge regions (pixels).
    local img = lurek.render.newImage("assets/icon.png")
    panel = lurek.render.newNineSlice(img, 32, 32, 32, 32)
    button = lurek.render.newNineSlice(img, 16, 16, 16, 16)
end

function lurek.process(dt)
    timer = timer + dt
    -- Cycle through sizes every 2 seconds
    if timer >= 2.0 then
        timer = timer - 2.0
        current = current % #sizes + 1
    end
end

function lurek.render()
    local screenW, screenH = lurek.render.getDimensions()
    local size = sizes[current]

    -- Title
    lurek.render.setColor(1, 1, 1)
    lurek.render.print("Nine-Slice (9-patch) Demo", 20, 20, 2.5)

    -- Draw the panel centered on screen
    local px = (screenW - size.w) / 2
    local py = (screenH - size.h) / 2

    -- Panel background with tint
    lurek.render.setColor(0.3, 0.5, 0.9, 0.8)
    lurek.render.drawNineSlice(panel, px, py, size.w, size.h)

    -- Label inside the panel
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(size.label .. " panel (" .. size.w .. "x" .. size.h .. ")",
        px + 40, py + 20, 2)

    -- Draw three buttons below the panel using the method syntax
    lurek.render.setColor(0.9, 0.4, 0.2, 0.9)
    local btnY = py + size.h + 30
    for i = 1, 3 do
        local btnW = 100 + i * 30
        local btnX = px + (i - 1) * (btnW + 20)
        button:draw(btnX, btnY, btnW, 50)

        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Btn " .. i, btnX + 15, btnY + 12, 1.5)
        lurek.render.setColor(0.9, 0.4, 0.2, 0.9)
    end

    -- Info text
    lurek.render.setColor(0.6, 0.6, 0.6)
    lurek.render.print("Cycles every 2s — corners stay fixed, center stretches", 20, screenH - 40, 1.5)

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.5)
    local fps = math.floor(lurek.time.getFPS())
    lurek.render.print("FPS: " .. tostring(fps), screenW - 120, 10, 1.5)
end

function lurek.keypressed(key)
    if key == "escape" then
        lurek.quit()
    elseif key == "space" then
        current = current % #sizes + 1
    end
end
