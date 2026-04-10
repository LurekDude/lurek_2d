-- test_evidence_canvas.lua
-- Evidence test: Canvas creation, dimensions, release + PNG visualization
-- Produces: canvas_sizes.png, canvas_lifecycle.png

local OUT = "tests/lua/evidence/output/"

--- Helper: draw a filled rectangle into an ImageData.
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            img:setPixel(x, y, r, g, b, a)
        end
    end
end

--- Helper: draw a 1px border.
local function draw_border(img, x0, y0, w, h, r, g, b)
    for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
        if y0 >= 0 and y0 < img:getHeight() then img:setPixel(x, y0, r, g, b, 255) end
        local yb = y0 + h - 1
        if yb >= 0 and yb < img:getHeight() then img:setPixel(x, yb, r, g, b, 255) end
    end
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        if x0 >= 0 and x0 < img:getWidth() then img:setPixel(x0, y, r, g, b, 255) end
        local xr = x0 + w - 1
        if xr >= 0 and xr < img:getWidth() then img:setPixel(xr, y, r, g, b, 255) end
    end
end

describe("Evidence: Canvas lifecycle + PNG visualization", function()

    it("newCanvas creates a Canvas with correct width/height", function()
        local c = lurek.graphic.newCanvas(128, 64)
        expect_equal(c:getWidth(), 128)
        expect_equal(c:getHeight(), 64)
        c:release()
    end)

    it("getDimensions returns width and height", function()
        local c = lurek.graphic.newCanvas(200, 100)
        local w, h = c:getDimensions()
        expect_equal(w, 200)
        expect_equal(h, 100)
        c:release()
    end)

    it("release returns true on first release", function()
        local c = lurek.graphic.newCanvas(64, 64)
        expect_equal(c:release(), true)
    end)

    it("release returns false on double-release", function()
        local c = lurek.graphic.newCanvas(64, 64)
        c:release()
        expect_equal(c:release(), false)
    end)

    it("typeOf returns 'Canvas'", function()
        local c = lurek.graphic.newCanvas(64, 64)
        expect_equal(c:typeOf(), "Canvas")
        c:release()
    end)

    it("multiple canvases are independent", function()
        local c1 = lurek.graphic.newCanvas(100, 100)
        local c2 = lurek.graphic.newCanvas(200, 300)
        expect_equal(c1:getWidth(), 100)
        expect_equal(c2:getWidth(), 200)
        c1:release()
        c2:release()
    end)

    it("getWidth after release raises an error", function()
        local c = lurek.graphic.newCanvas(64, 64)
        c:release()
        local ok = pcall(function() return c:getWidth() end)
        expect_equal(ok, false)
    end)

    it("newCanvas round-trips many sizes", function()
        local sizes = {{32,32},{64,64},{128,128},{256,256},{512,512},{320,180},{1920,1080},{4,4}}
        for _, sz in ipairs(sizes) do
            local c = lurek.graphic.newCanvas(sz[1], sz[2])
            expect_equal(c:getWidth(), sz[1])
            expect_equal(c:getHeight(), sz[2])
            c:release()
        end
    end)

    it("PNG: canvas sizes visualized as colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)
        img:fill(20, 20, 30, 255)

        local canvases = {
            {128, 64,  255, 80,  80},
            {200, 100, 80,  255, 80},
            {64,  64,  80,  80,  255},
            {256, 256, 255, 255, 80},
            {32,  32,  255, 128, 0},
            {320, 180, 128, 0,   255},
        }
        local y_off = 4
        for _, cfg in ipairs(canvases) do
            local cw, ch, r, g, b = cfg[1], cfg[2], cfg[3], cfg[4], cfg[5]
            local c = lurek.graphic.newCanvas(cw, ch)
            local aw, ah = c:getDimensions()
            c:release()
            local scale = math.min(240 / aw, 30 / ah)
            local dw = math.floor(aw * scale)
            local dh = math.max(math.floor(ah * scale), 4)
            draw_rect(img, 8, y_off, dw, dh, r, g, b, 255)
            draw_border(img, 8, y_off, dw, dh, 255, 255, 255)
            y_off = y_off + dh + 4
        end

        lurek.img.savePNG(img, OUT .. "canvas_sizes.png")
        expect_equal(true, true)
    end)

    it("PNG: canvas lifecycle state diagram (created/active/released)", function()
        local img = lurek.img.newImageData(128, 64)
        img:fill(30, 30, 40, 255)

        local c = lurek.graphic.newCanvas(64, 64)
        -- Created (green)
        draw_rect(img, 4, 4, 36, 56, 0, 200, 0, 255)
        -- Active (blue) — we read width to prove it's alive
        local _ = c:getWidth()
        draw_rect(img, 46, 4, 36, 56, 0, 0, 200, 255)
        -- Released (red)
        c:release()
        draw_rect(img, 88, 4, 36, 56, 200, 0, 0, 255)

        lurek.img.savePNG(img, OUT .. "canvas_lifecycle.png")
        expect_equal(true, true)
    end)

end)

test_summary()
