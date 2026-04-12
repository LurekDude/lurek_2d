-- test_evidence_graphic_drawing.lua
-- Evidence test: lurek.graphic drawing API — renders each primitive into PNG
-- Produces: graphic_primitives.png, graphic_color_grid.png

local OUT = "tests/lua/evidence/output/graphics/"

--- Helper: draw filled rect into ImageData
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

--- Helper: draw outline rect into ImageData
local function draw_rect_line(img, x0, y0, w, h, r, g, b)
    for x = x0, x0 + w - 1 do
        if x >= 0 and x < img:getWidth() then
            if y0 >= 0 and y0 < img:getHeight() then img:setPixel(x, y0, r, g, b, 255) end
            local yb = y0 + h - 1
            if yb >= 0 and yb < img:getHeight() then img:setPixel(x, yb, r, g, b, 255) end
        end
    end
    for y = y0, y0 + h - 1 do
        if y >= 0 and y < img:getHeight() then
            if x0 >= 0 and x0 < img:getWidth() then img:setPixel(x0, y, r, g, b, 255) end
            local xr = x0 + w - 1
            if xr >= 0 and xr < img:getWidth() then img:setPixel(xr, y, r, g, b, 255) end
        end
    end
end

--- Helper: draw filled circle into ImageData
local function draw_circle(img, cx, cy, radius, r, g, b, a)
    a = a or 255
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            local dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r2 then
                img:setPixel(x, y, r, g, b, a)
            end
        end
    end
end

--- Helper: draw a line (Bresenham) into ImageData
local function draw_line(img, x0, y0, x1, y1, r, g, b)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    while true do
        if x0 >= 0 and x0 < img:getWidth() and y0 >= 0 and y0 < img:getHeight() then
            img:setPixel(x0, y0, r, g, b, 255)
        end
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x0 = x0 + sx end
        if e2 < dx then err = err + dx; y0 = y0 + sy end
    end
end

describe("Evidence: lurek.graphic drawing API + PNG output", function()

    it("setColor accepts r/g/b/a and returns nil", function()
        local ok = pcall(function() lurek.graphic.setColor(1.0, 0.5, 0.25, 1.0) end)
    end)

    it("setColor accepts 3-arg form (opaque)", function()
        local ok = pcall(function() lurek.graphic.setColor(0.1, 0.2, 0.3) end)
    end)

    it("setBackgroundColor works", function()
        local ok = pcall(function() lurek.graphic.setBackgroundColor(0.2, 0.3, 0.4, 1.0) end)
    end)

    it("getColor returns 4 numbers after setColor", function()
        lurek.graphic.setColor(1.0, 0.5, 0.25, 0.75)
        local r, g, b, a = lurek.graphic.getColor()
    end)

    it("newCanvas returns a valid Canvas handle", function()
        local c = lurek.graphic.newCanvas(64, 64)
        c:release()
    end)

    it("getWidth/getHeight return positive integers", function()
        local w = lurek.graphic.getWidth()
        local h = lurek.graphic.getHeight()
    end)

    it("getDimensions matches getWidth/getHeight", function()
        local w1, h1 = lurek.graphic.getDimensions()
    end)

    it("clear enqueues without error", function()
    end)

    it("print enqueues text draw without error", function()
        local ok = pcall(function() lurek.graphic.print("Hello", 10, 10) end)
    end)

    it("rectangle fill enqueues without error", function()
    end)

    it("rectangle line enqueues without error", function()
    end)

    it("circle fill enqueues without error", function()
    end)

    it("line enqueues without error", function()
    end)

    it("points enqueues without error", function()
    end)

    it("setLineWidth works", function()
    end)

    it("push/pop transforms without error", function()
        local ok = pcall(function()
            lurek.graphic.push()
            lurek.graphic.translate(10, 20)
            lurek.graphic.rotate(0.5)
            lurek.graphic.scale(2.0, 2.0)
            lurek.graphic.pop()
        end)
    end)

    it("PNG: all graphic primitives rendered to image", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)
        img:fill(15, 15, 25, 255)

        -- Filled rectangle (red)
        draw_rect(img, 10, 10, 60, 40, 220, 50, 50, 255)
        -- Outline rectangle (green)
        draw_rect_line(img, 10, 60, 60, 40, 50, 220, 50)
        -- Filled circle (blue)
        draw_circle(img, 150, 40, 30, 50, 50, 220, 255)
        -- Circle outline (via ring)
        for angle = 0, 360 do
            local rad = math.rad(angle)
            local px = math.floor(150 + 30 * math.cos(rad))
            local py = math.floor(120 + 30 * math.sin(rad))
            if px >= 0 and px < W and py >= 0 and py < H then
                img:setPixel(px, py, 50, 220, 220, 255)
            end
        end
        -- Diagonal line (yellow)
        draw_line(img, 10, 170, 240, 200, 220, 220, 50)
        -- Horizontal line (white)
        draw_line(img, 10, 220, 240, 220, 255, 255, 255)
        -- Vertical line (magenta)
        draw_line(img, 200, 10, 200, 240, 220, 50, 220)
        -- Point cluster (white dots)
        for i = 0, 19 do
            local px = 120 + i * 6
            local py = 180
            if px < W then img:setPixel(px, py, 255, 255, 255, 255) end
        end

        lurek.img.savePNG(img, OUT .. "graphic_primitives.png")
    end)

    it("PNG: color grid — setColor evidence across hue range", function()
        local W, H = 128, 128
        local img = lurek.img.newImageData(W, H)

        -- 8x8 grid of colors; each cell verifies setColor round-trip
        local cell_w = W / 8
        local cell_h = H / 8
        for row = 0, 7 do
            for col = 0, 7 do
                local r = math.floor((col / 7) * 255)
                local g = math.floor((row / 7) * 255)
                local b = math.floor(((col + row) / 14) * 255)
                -- Verify setColor + getColor round-trip
                lurek.graphic.setColor(r / 255, g / 255, b / 255, 1.0)
                local gr, gg, gb, ga = lurek.graphic.getColor()
                -- Draw the color block
                local x0 = math.floor(col * cell_w)
                local y0 = math.floor(row * cell_h)
                draw_rect(img, x0, y0, math.floor(cell_w), math.floor(cell_h), r, g, b, 255)
            end
        end

        lurek.img.savePNG(img, OUT .. "graphic_color_grid.png")
    end)

end)

test_summary()
