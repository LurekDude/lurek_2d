-- test_evidence_image_effects.lua
-- Evidence test: ImageData filters and effects with before/after PNG output

local OUT = "tests/lua/evidence/output/image/"

-- Create a gradient image with some shapes as a base for testing effects
local function make_base(w, h)
    local img = lurek.image.newImageData(w, h)
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

-- @description Covers suite: Evidence: ImageData effects.
describe("Evidence: ImageData effects", function()

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Saves the unmodified baseline image used as the control for all subsequent effect evidence.
    it("saves base test image", function()
        local img = make_base(256, 256)
        lurek.image.savePNG(img, OUT .. "effects_base.png")
    end)

    -- @covers ImageData:brightness
    -- @covers ImageData:getPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Brightens the baseline image and saves the result to document positive brightness scaling.
    it("brightness increase (1.5)", function()
        local img = make_base(256, 256)
        local r_before, _, _, _ = img:getPixel(128, 128)
        img:brightness(1.5)
        lurek.image.savePNG(img, OUT .. "effects_brightness_up.png")
        local r_after, _, _, _ = img:getPixel(128, 128)
        -- After brightness > 1, values should increase (or stay at max)
    end)

    -- @covers ImageData:brightness
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Darkens the baseline image and saves the result to document brightness reduction.
    it("brightness decrease (0.5)", function()
        local img = make_base(256, 256)
        img:brightness(0.5)
        lurek.image.savePNG(img, OUT .. "effects_brightness_down.png")
    end)

    -- @covers ImageData:contrast
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Increases image contrast and writes the result so the expanded tonal separation can be inspected.
    it("contrast increase (1.5)", function()
        local img = make_base(256, 256)
        img:contrast(1.5)
        lurek.image.savePNG(img, OUT .. "effects_contrast_up.png")
    end)

    -- @covers ImageData:contrast
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Reduces image contrast and saves the flatter result for comparison against the baseline.
    it("contrast decrease (0.5)", function()
        local img = make_base(256, 256)
        img:contrast(0.5)
        lurek.image.savePNG(img, OUT .. "effects_contrast_down.png")
    end)

    -- @covers ImageData:saturation
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Removes saturation entirely to produce a grayscale-like control image.
    it("saturation zero (grayscale-like)", function()
        local img = make_base(256, 256)
        img:saturation(0)
        lurek.image.savePNG(img, OUT .. "effects_saturation_zero.png")
    end)

    -- @covers ImageData:saturation
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Boosts saturation above 1.0 and saves the intensified color output.
    it("saturation boost (2.0)", function()
        local img = make_base(256, 256)
        img:saturation(2)
        lurek.image.savePNG(img, OUT .. "effects_saturation_boost.png")
    end)

    -- @covers ImageData:grayscale
    -- @covers ImageData:getPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies the grayscale effect and reads one pixel to confirm the transformed image can still be sampled.
    it("grayscale", function()
        local img = make_base(256, 256)
        img:grayscale()
        lurek.image.savePNG(img, OUT .. "effects_grayscale.png")
        local r, g, b, _ = img:getPixel(100, 100)
    end)

    -- @covers ImageData:sepia
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies sepia toning and writes the output as visual evidence.
    it("sepia", function()
        local img = make_base(256, 256)
        img:sepia()
        lurek.image.savePNG(img, OUT .. "effects_sepia.png")
    end)

    -- @covers ImageData:invert
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Inverts the baseline image and saves the result for manual inspection.
    it("invert", function()
        local img = make_base(256, 256)
        img:invert()
        lurek.image.savePNG(img, OUT .. "effects_invert.png")
    end)

    -- @covers ImageData:threshold
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies a binary threshold to the baseline image and saves the high-contrast result.
    it("threshold (128)", function()
        local img = make_base(256, 256)
        img:threshold(128)
        lurek.image.savePNG(img, OUT .. "effects_threshold.png")
    end)

    -- @covers ImageData:posterize
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Reduces the image to four color levels and saves the posterized result.
    it("posterize (4 levels)", function()
        local img = make_base(256, 256)
        img:posterize(4)
        lurek.image.savePNG(img, OUT .. "effects_posterize.png")
    end)

    -- @covers ImageData:blur
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Blurs the baseline image with radius 3 and saves the softened output.
    it("blur (radius 3)", function()
        local img = make_base(256, 256)
        local blurred = img:blur(3)
        lurek.image.savePNG(blurred, OUT .. "effects_blur.png")
    end)

    -- @covers ImageData:sharpen
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Sharpens the baseline image and writes the result for visual comparison with the blurred output.
    it("sharpen", function()
        local img = make_base(256, 256)
        local sharp = img:sharpen()
        lurek.image.savePNG(sharp, OUT .. "effects_sharpen.png")
    end)

    -- @covers ImageData:gamma
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Saves low- and high-gamma variants of the same base image to document gamma correction behavior.
    it("gamma correction (0.5 and 2.0)", function()
        local img1 = make_base(256, 256)
        img1:gamma(0.5)
        lurek.image.savePNG(img1, OUT .. "effects_gamma_low.png")

        local img2 = make_base(256, 256)
        img2:gamma(2.0)
        lurek.image.savePNG(img2, OUT .. "effects_gamma_high.png")
    end)

    -- @covers ImageData:tint
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies a semi-transparent red tint over the baseline image and saves the result.
    it("tint red 50%", function()
        local img = make_base(256, 256)
        img:tint(255, 0, 0, 0.5)
        lurek.image.savePNG(img, OUT .. "effects_tint_red.png")
    end)

end)
test_summary()
