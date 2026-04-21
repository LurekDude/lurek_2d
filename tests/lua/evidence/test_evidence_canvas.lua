-- test_evidence_canvas.lua
-- Evidence test: Canvas creation, dimensions, release + PNG visualization
-- Produces: canvas_sizes.png, canvas_lifecycle.png

local OUT = "tests/lua/evidence/output/canvas/"

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

-- @description Covers suite: Evidence: Canvas lifecycle + PNG visualization.
describe("Evidence: Canvas lifecycle + PNG visualization", function()

    -- @covers lurek.render.newCanvas
    -- @covers Canvas:getDimensions
    -- @covers Canvas:release
    -- @evidence file
    -- @description Creates canvases of several sizes and renders scaled rectangles that visualize the reported dimensions in one PNG.
    it("PNG: canvas sizes visualized as colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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
            local c = lurek.render.newCanvas(cw, ch)
            local aw, ah = c:getDimensions()
            c:release()
            local scale = math.min(240 / aw, 30 / ah)
            local dw = math.floor(aw * scale)
            local dh = math.max(math.floor(ah * scale), 4)
            draw_rect(img, 8, y_off, dw, dh, r, g, b, 255)
            draw_border(img, 8, y_off, dw, dh, 255, 255, 255)
            y_off = y_off + dh + 4
        end

        lurek.image.savePNG(img, OUT .. "canvas_sizes.png")
    end)

    -- @covers lurek.render.newCanvas
    -- @covers Canvas:getWidth
    -- @covers Canvas:release
    -- @evidence file
    -- @description Draws a simple lifecycle diagram that encodes created, active, and released canvas states into file evidence.
    it("PNG: canvas lifecycle state diagram (created/active/released)", function()
        local img = lurek.image.newImageData(128, 64)
        img:fill(30, 30, 40, 255)

        local c = lurek.render.newCanvas(64, 64)
        -- Created (green)
        draw_rect(img, 4, 4, 36, 56, 0, 200, 0, 255)
        -- Active (blue) â€” we read width to prove it's alive
        local _ = c:getWidth()
        draw_rect(img, 46, 4, 36, 56, 0, 0, 200, 255)
        -- Released (red)
        c:release()
        draw_rect(img, 88, 4, 36, 56, 200, 0, 0, 255)

        lurek.image.savePNG(img, OUT .. "canvas_lifecycle.png")
    end)

end)
test_summary()
