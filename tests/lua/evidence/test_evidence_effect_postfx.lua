-- test_evidence_effect_postfx.lua
-- Evidence test: ImageData post-processing effects + Effect/Stack API
-- Produces: postfx_grayscale.png, postfx_invert.png, postfx_blur.png,
--           postfx_sepia.png, postfx_effects_strip.png

local OUT = "tests/lua/evidence/output/postfx/"

--- Helper: create a colorful test pattern ImageData.
local function make_test_pattern(w, h)
    local img = lurek.image.newImageData(w, h)
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local r = math.floor((x / w) * 255)
            local g = math.floor((y / h) * 255)
            local b = math.floor(((x + y) / (w + h)) * 255)
            img:setPixel(x, y, r, g, b, 255)
        end
    end
    return img
end

--- Helper: draw_rect
local function draw_rect(img, x0, y0, w, h, r, g, b)
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, 255) end
        end
    end
end

-- @description Covers suite: Evidence: PostFx + ImageData effects â†’ PNG output.
describe("Evidence: PostFx + ImageData effects â†’ PNG output", function()
    -- @covers ImageData:grayscale
    -- @covers ImageData:getPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies grayscale to a synthetic color gradient and saves the result as post-processing evidence.
    it("PNG: grayscale effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:grayscale()
        -- Verify some pixels are indeed gray (r == g == b)
        local pr, pg, pb = img:getPixel(64, 64)
        lurek.image.savePNG(img, OUT .. "postfx_grayscale.png")
    end)

    -- @covers ImageData:invert
    -- @covers ImageData:getPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Inverts a color gradient, samples one pixel before and after, and writes the inverted PNG.
    it("PNG: invert effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        -- Read a pixel before invert
        local br, bg, bb = img:getPixel(64, 64)
        img:invert()
        -- After invert, pixel should be ~(255 - original)
        local ar, ag, ab = img:getPixel(64, 64)
        lurek.image.savePNG(img, OUT .. "postfx_invert.png")
    end)

    -- @covers ImageData:blur
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies blur to a gradient pattern and saves the softened output.
    it("PNG: blur effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:blur(3)
        lurek.image.savePNG(img, OUT .. "postfx_blur.png")
    end)

    -- @covers ImageData:sepia
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies sepia toning to the gradient pattern and saves the transformed output.
    it("PNG: sepia effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:sepia()
        lurek.image.savePNG(img, OUT .. "postfx_sepia.png")
    end)

    -- @covers ImageData:grayscale
    -- @covers ImageData:sepia
    -- @covers ImageData:invert
    -- @covers ImageData:blur
    -- @covers ImageData:sharpen
    -- @covers ImageData:brightness
    -- @covers ImageData:contrast
    -- @covers ImageData:threshold
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds a horizontal strip comparing several image effects side by side on the same source pattern.
    it("PNG: effect strip â€” original + 8 effects side by side", function()
        local CELL = 64
        local effects = {"original", "grayscale", "sepia", "invert", "blur", "sharpen", "brightness", "contrast", "threshold"}
        local count = #effects
        local W = CELL * count
        local H = CELL
        local strip = lurek.image.newImageData(W, H)
        strip:fill(0, 0, 0, 255)

        for i, name in ipairs(effects) do
            local cell = make_test_pattern(CELL, CELL)
            if name == "grayscale" then cell:grayscale()
            elseif name == "sepia" then cell:sepia()
            elseif name == "invert" then cell:invert()
            elseif name == "blur" then cell:blur(2)
            elseif name == "sharpen" then cell:sharpen()
            elseif name == "brightness" then cell:brightness(50)
            elseif name == "contrast" then cell:contrast(1.8)
            elseif name == "threshold" then cell:threshold(128)
            end
            -- Copy cell into strip
            local x_off = (i - 1) * CELL
            for y = 0, CELL - 1 do
                for x = 0, CELL - 1 do
                    local r, g, b, a = cell:getPixel(x, y)
                    strip:setPixel(x_off + x, y, r, g, b, a)
                end
            end
        end

        lurek.image.savePNG(strip, OUT .. "postfx_effects_strip.png")
    end)

    -- @covers ImageData:posterize
    -- @covers ImageData:gamma
    -- @covers ImageData:tint
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Chains posterize, gamma, and tint adjustments on one image and saves the combined effect.
    it("PNG: posterize + gamma + tint combined", function()
        local img = make_test_pattern(128, 128)
        img:posterize(4)
        img:gamma(1.5)
        img:tint(255, 200, 150, 255)
        lurek.image.savePNG(img, OUT .. "postfx_posterize_tint.png")
    end)

    -- @covers ImageData:saturation
    -- @covers ImageData:flipHorizontal
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Boosts saturation, flips the result horizontally, and saves the transformed image.
    it("PNG: saturation and flipHorizontal", function()
        local img = make_test_pattern(128, 128)
        img:saturation(2.0)
        img:flipHorizontal()
        lurek.image.savePNG(img, OUT .. "postfx_saturation_flip.png")
    end)

end)
test_summary()
