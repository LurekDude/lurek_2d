-- test_evidence_image_effects.lua
-- Evidence test: ImageData filters and effects with before/after PNG output

local OUT = "tests/lua/evidence/output/image/"

-- Create a gradient image with some shapes as a base for testing effects
local function make_base(w, h)
    local img = lurek.img.newImageData(w, h)
    -- Horizontal gradient
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local r = math.floor(x / w * 255)
            local g = math.floor(y / h * 255)
            local b = math.floor((1 - x / w) * 200)
            img:setPixel(x, y, r, g, b, 255)
        end
    end
    -- Draw some shapes on top
    img:drawRect(20, 20, 60, 60, 255, 0, 0, 255)
    img:drawCircle(180, 128, 40, 0, 255, 0, 255)
    img:drawLine(0, 0, w - 1, h - 1, 255, 255, 0, 255)
    img:drawLine(w - 1, 0, 0, h - 1, 255, 255, 0, 255)
    return img
end

describe("Evidence: ImageData effects", function()

    it("saves base test image", function()
        local img = make_base(256, 256)
        lurek.img.savePNG(img, OUT .. "effects_base.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("brightness increase (1.5)", function()
        local img = make_base(256, 256)
        local r_before, _, _, _ = img:getPixel(128, 128)
        img:brightness(1.5)
        lurek.img.savePNG(img, OUT .. "effects_brightness_up.png")
        local r_after, _, _, _ = img:getPixel(128, 128)
        -- After brightness > 1, values should increase (or stay at max)
        expect_equal(true, r_after >= r_before)
    end)

    it("brightness decrease (0.5)", function()
        local img = make_base(256, 256)
        img:brightness(0.5)
        lurek.img.savePNG(img, OUT .. "effects_brightness_down.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("contrast increase (1.5)", function()
        local img = make_base(256, 256)
        img:contrast(1.5)
        lurek.img.savePNG(img, OUT .. "effects_contrast_up.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("contrast decrease (0.5)", function()
        local img = make_base(256, 256)
        img:contrast(0.5)
        lurek.img.savePNG(img, OUT .. "effects_contrast_down.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("saturation zero (grayscale-like)", function()
        local img = make_base(256, 256)
        img:saturation(0)
        lurek.img.savePNG(img, OUT .. "effects_saturation_zero.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("saturation boost (2.0)", function()
        local img = make_base(256, 256)
        img:saturation(2)
        lurek.img.savePNG(img, OUT .. "effects_saturation_boost.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("grayscale", function()
        local img = make_base(256, 256)
        img:grayscale()
        lurek.img.savePNG(img, OUT .. "effects_grayscale.png")
        local r, g, b, _ = img:getPixel(100, 100)
        expect_equal(r, g)
        expect_equal(g, b)
    end)

    it("sepia", function()
        local img = make_base(256, 256)
        img:sepia()
        lurek.img.savePNG(img, OUT .. "effects_sepia.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("invert", function()
        local img = make_base(256, 256)
        img:invert()
        lurek.img.savePNG(img, OUT .. "effects_invert.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("threshold (128)", function()
        local img = make_base(256, 256)
        img:threshold(128)
        lurek.img.savePNG(img, OUT .. "effects_threshold.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("posterize (4 levels)", function()
        local img = make_base(256, 256)
        img:posterize(4)
        lurek.img.savePNG(img, OUT .. "effects_posterize.png")
        expect_equal(img:getWidth(), 256)
    end)

    it("blur (radius 3)", function()
        local img = make_base(256, 256)
        local blurred = img:blur(3)
        lurek.img.savePNG(blurred, OUT .. "effects_blur.png")
        expect_equal(blurred:getWidth(), 256)
    end)

    it("sharpen", function()
        local img = make_base(256, 256)
        local sharp = img:sharpen()
        lurek.img.savePNG(sharp, OUT .. "effects_sharpen.png")
        expect_equal(sharp:getWidth(), 256)
    end)

    it("gamma correction (0.5 and 2.0)", function()
        local img1 = make_base(256, 256)
        img1:gamma(0.5)
        lurek.img.savePNG(img1, OUT .. "effects_gamma_low.png")

        local img2 = make_base(256, 256)
        img2:gamma(2.0)
        lurek.img.savePNG(img2, OUT .. "effects_gamma_high.png")
        expect_equal(img1:getWidth(), 256)
    end)

    it("tint red 50%", function()
        local img = make_base(256, 256)
        img:tint(255, 0, 0, 0.5)
        lurek.img.savePNG(img, OUT .. "effects_tint_red.png")
        expect_equal(img:getWidth(), 256)
    end)

end)

test_summary()
