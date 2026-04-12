-- test_evidence_image_drawing.lua
-- Evidence test: ImageData drawing methods (drawRect, drawLine, drawCircle)

local OUT = "tests/lua/evidence/output/image/"

describe("Evidence: ImageData drawing methods", function()

    it("drawRect - grid of colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local colors = {
            {255, 0, 0},     {0, 255, 0},   {0, 0, 255},   {255, 255, 0},
            {255, 0, 255},   {0, 255, 255}, {255, 128, 0},  {128, 0, 255},
            {0, 128, 0},     {128, 128, 0}, {0, 128, 128},  {128, 0, 128},
            {200, 100, 50},  {50, 100, 200},{100, 200, 50}, {200, 50, 100},
        }
        local cols, rows = 4, 4
        local rw = math.floor(W / cols)
        local rh = math.floor(H / rows)
        local ci = 1
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                local c = colors[ci]
                img:drawRect(col * rw + 2, row * rh + 2, rw - 4, rh - 4, c[1], c[2], c[3], 255)
                ci = ci + 1
            end
        end

        lurek.img.savePNG(img, OUT .. "drawing_rects.png")
        -- Verify a drawn pixel
        local r, g, b, a = img:getPixel(3, 3)
    end)

    it("drawLine - star pattern from center", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        local cx, cy = 128, 128
        local numRays = 24
        for i = 0, numRays - 1 do
            local angle = (i / numRays) * math.pi * 2
            local ex = cx + math.floor(math.cos(angle) * 120)
            local ey = cy + math.floor(math.sin(angle) * 120)
            local hue = math.floor(i / numRays * 255)
            img:drawLine(cx, cy, ex, ey, hue, 255 - hue, 128, 255)
        end

        lurek.img.savePNG(img, OUT .. "drawing_lines.png")
        -- Center pixel should have been drawn
        local r, g, b, a = img:getPixel(128, 128)
    end)

    it("drawCircle - concentric circles", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        local cx, cy = 128, 128
        local colors = {
            {255, 50, 50},  {255, 150, 50},  {255, 255, 50},
            {50, 255, 50},  {50, 150, 255},  {100, 50, 255},
        }
        local radii = {120, 100, 80, 60, 40, 20}
        for i, radius in ipairs(radii) do
            local c = colors[i]
            img:drawCircle(cx, cy, radius, c[1], c[2], c[3], 255)
        end

        lurek.img.savePNG(img, OUT .. "drawing_circles.png")
        -- Center pixel should be the innermost circle color
        local r, g, b, a = img:getPixel(128, 128)
    end)

    it("combined scene with all drawing methods", function()
        local W, H = 512, 512
        local img = lurek.img.newImageData(W, H)

        -- Sky gradient background
        for y = 0, H - 1 do
            local t = y / H
            local r = math.floor(30 + t * 20)
            local g = math.floor(30 + t * 40)
            local b = math.floor(80 + (1 - t) * 100)
            for x = 0, W - 1 do
                img:setPixel(x, y, r, g, b, 255)
            end
        end

        -- Ground
        img:drawRect(0, 380, W, H - 380, 40, 80, 30, 255)

        -- Sun
        img:drawCircle(400, 100, 50, 255, 220, 50, 255)
        -- Sun rays
        for i = 0, 11 do
            local angle = (i / 12) * math.pi * 2
            local sx = 400 + math.floor(math.cos(angle) * 60)
            local sy = 100 + math.floor(math.sin(angle) * 60)
            local ex = 400 + math.floor(math.cos(angle) * 80)
            local ey = 100 + math.floor(math.sin(angle) * 80)
            img:drawLine(sx, sy, ex, ey, 255, 220, 50, 255)
        end

        -- House
        img:drawRect(100, 300, 150, 100, 180, 80, 60, 255)
        -- Roof (triangle approximation with lines)
        for i = 0, 74 do
            img:drawLine(100 + i, 300 - i, 250 - i, 300 - i, 160, 50, 40, 255)
        end
        -- Door
        img:drawRect(155, 340, 40, 60, 100, 60, 30, 255)
        -- Window
        img:drawRect(115, 320, 30, 25, 150, 200, 255, 255)

        -- Tree trunk
        img:drawRect(350, 320, 20, 60, 100, 70, 30, 255)
        -- Tree top
        img:drawCircle(360, 300, 35, 30, 140, 30, 255)

        -- Fence
        for i = 0, 5 do
            local fx = 50 + i * 30
            img:drawRect(fx, 370, 5, 20, 160, 140, 100, 255)
        end
        img:drawLine(50, 380, 200, 380, 160, 140, 100, 255)
        img:drawLine(50, 375, 200, 375, 160, 140, 100, 255)

        lurek.img.savePNG(img, OUT .. "drawing_combined.png")
    end)

end)

test_summary()
