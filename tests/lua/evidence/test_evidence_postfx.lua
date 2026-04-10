-- test_evidence_postfx.lua
-- Evidence test: ImageData post-processing effects + Effect/Stack API
-- Produces: postfx_grayscale.png, postfx_invert.png, postfx_blur.png,
--           postfx_sepia.png, postfx_effects_strip.png

local OUT = "tests/lua/evidence/output/"

--- Helper: create a colorful test pattern ImageData.
local function make_test_pattern(w, h)
    local img = lurek.img.newImageData(w, h)
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

describe("Evidence: PostFx + ImageData effects → PNG output", function()

    it("newEffect creates an effect without error", function()
        local fx = lurek.postfx.newEffect("bloom")
        expect_equal(fx:type(), "PostFxEffect")
    end)

    it("newStack creates a stack with correct dimensions", function()
        local stack = lurek.postfx.newStack(320, 240)
        expect_equal(stack:getWidth(), 320)
        expect_equal(stack:getHeight(), 240)
    end)

    it("newImageEffect creates an effect", function()
        local fx = lurek.postfx.newImageEffect("grayscale")
        expect_equal(fx:type(), "ImageEffect")
    end)

    it("stack isEmpty initially", function()
        local stack = lurek.postfx.newStack(64, 64)
        expect_equal(stack:isEmpty(), true)
    end)

    it("stack len is 0 initially", function()
        local stack = lurek.postfx.newStack(64, 64)
        expect_equal(stack:len(), 0)
    end)

    it("effect isEnabled by default", function()
        local fx = lurek.postfx.newEffect("bloom")
        expect_equal(fx:isEnabled(), true)
    end)

    it("effect getTypeName returns the type string", function()
        local fx = lurek.postfx.newEffect("bloom")
        local name = fx:getTypeName()
        expect_equal(type(name), "string")
    end)

    it("PNG: grayscale effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:grayscale()
        -- Verify some pixels are indeed gray (r == g == b)
        local pr, pg, pb = img:getPixel(64, 64)
        expect_equal(pr, pg)
        expect_equal(pg, pb)
        lurek.img.savePNG(img, OUT .. "postfx_grayscale.png")
    end)

    it("PNG: invert effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        -- Read a pixel before invert
        local br, bg, bb = img:getPixel(64, 64)
        img:invert()
        -- After invert, pixel should be ~(255 - original)
        local ar, ag, ab = img:getPixel(64, 64)
        expect_near(ar, 255 - br, 2)
        expect_near(ag, 255 - bg, 2)
        lurek.img.savePNG(img, OUT .. "postfx_invert.png")
    end)

    it("PNG: blur effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:blur(3)
        lurek.img.savePNG(img, OUT .. "postfx_blur.png")
        expect_equal(true, true)
    end)

    it("PNG: sepia effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:sepia()
        lurek.img.savePNG(img, OUT .. "postfx_sepia.png")
        expect_equal(true, true)
    end)

    it("PNG: effect strip — original + 8 effects side by side", function()
        local CELL = 64
        local effects = {"original", "grayscale", "sepia", "invert", "blur", "sharpen", "brightness", "contrast", "threshold"}
        local count = #effects
        local W = CELL * count
        local H = CELL
        local strip = lurek.img.newImageData(W, H)
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

        lurek.img.savePNG(strip, OUT .. "postfx_effects_strip.png")
        expect_equal(true, true)
    end)

    it("PNG: posterize + gamma + tint combined", function()
        local img = make_test_pattern(128, 128)
        img:posterize(4)
        img:gamma(1.5)
        img:tint(255, 200, 150, 255)
        lurek.img.savePNG(img, OUT .. "postfx_posterize_tint.png")
        expect_equal(true, true)
    end)

    it("PNG: saturation and flipHorizontal", function()
        local img = make_test_pattern(128, 128)
        img:saturation(2.0)
        img:flipHorizontal()
        lurek.img.savePNG(img, OUT .. "postfx_saturation_flip.png")
        expect_equal(true, true)
    end)

end)

test_summary()
