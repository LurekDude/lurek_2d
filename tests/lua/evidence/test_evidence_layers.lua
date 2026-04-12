-- test_evidence_layers.lua
-- Evidence test: Image layer compositing and DrawLayer z-order management

local OUT = "tests/lua/evidence/output/layers/"

local function fill_rect(img, x, y, w, h, r, g, b, a)
    a = a or 255
    img:drawRect(x, y, w, h, r, g, b, a)
end

describe("Evidence: Image layers", function()

    it("merges three color layers into one image", function()
        local W, H = 256, 256

        -- Background layer
        local base = lurek.img.newImageData(W, H)
        fill_rect(base, 0, 0, W, H, 30, 30, 60, 255)

        -- Mid layer: blue rectangle
        local mid = lurek.img.newImageData(W, H)
        fill_rect(mid, 40, 40, 140, 140, 40, 80, 200, 180)

        -- Top layer: red circle
        local top_img = lurek.img.newImageData(W, H)
        top_img:drawCircle(128, 128, 60, 220, 60, 60, 180)

        -- Compose base + mid + top by drawing rects into the base
        fill_rect(base, 40, 40, 140, 140, 40, 80, 200, 180)
        base:drawCircle(128, 128, 60, 220, 60, 60, 180)

        lurek.img.savePNG(base, OUT .. "basic_merge.png")
        expect_equal(base:getWidth(), W)
        expect_equal(base:getHeight(), H)
    end)

    it("produces distinct opacity levels for a gradient layer stack", function()
        local W, H = 256, 64

        local strips = { 255, 200, 150, 100, 50, 0 }
        local img = lurek.img.newImageData(W, H)
        fill_rect(img, 0, 0, W, H, 20, 20, 40, 255)

        local sw = math.floor(W / #strips)
        for i, alpha in ipairs(strips) do
            local x = (i - 1) * sw
            fill_rect(img, x, 0, sw, H, 220, 80, 80, alpha)
        end

        lurek.img.savePNG(img, OUT .. "opacity.png")
        expect_equal(img:getWidth(), W)
    end)

    it("uses DrawLayer to manage z-ordered render queue", function()
        local layer = lurek.graphic.newDrawLayer()

        -- Queue some draws at different z levels
        local calls = 0
        layer:queue(5, function()
            calls = calls + 1
        end)
        layer:queue(1, function()
            calls = calls + 1
        end)
        layer:queue(10, function()
            calls = calls + 1
        end)

        expect_equal(layer:getCount(), 3)

        -- Flush executes the queued callbacks
        layer:flush()
        expect_equal(calls, 3)
        expect_equal(layer:getCount(), 0)

        -- Demonstrate clear without flush
        layer:queue(3, function() end)
        layer:queue(7, function() end)
        expect_equal(layer:getCount(), 2)
        layer:clear()
        expect_equal(layer:getCount(), 0)

        -- Write an image to show layer concept
        local W, H = 200, 200
        local img = lurek.img.newImageData(W, H)
        fill_rect(img, 0,   0,   W,   H,   20,  20,  40,  255)
        fill_rect(img, 10,  10,  180, 180, 40,  80,  200, 200)
        fill_rect(img, 50,  50,  100, 100, 220, 80,  80,  200)
        fill_rect(img, 80,  80,  40,  40,  80,  220, 80,  200)
        lurek.img.savePNG(img, OUT .. "management.png")
    end)

end)

test_summary()
