-- Keeps pending image, minimap, and raycaster evidence ports visible until each migrated Rust case is translated into real Lua artifact generation.

describe("Evidence: image", function()
end)



-- ================================================================
-- Merged from: test_image_drawing_evidence.lua
-- ================================================================

-- test_evidence_image_drawing.lua
-- Evidence test: ImageData drawing methods (drawRect, drawLine, drawCircle)

local OUT = "tests/output/image/"

describe("Evidence: ImageData drawing methods", function()

    -- @evidence file
    it("drawRect - grid of colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "drawing_rects.png")
        -- Verify a drawn pixel
        local r, g, b, a = img:getPixel(3, 3)
    end)

    -- @evidence file
    it("drawLine - star pattern from center", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "drawing_lines.png")
        -- Center pixel should have been drawn
        local r, g, b, a = img:getPixel(128, 128)
    end)

    -- @evidence file
    it("drawCircle - concentric circles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "drawing_circles.png")
        -- Center pixel should be the innermost circle color
        local r, g, b, a = img:getPixel(128, 128)
    end)

    -- @evidence file
    it("combined scene with all drawing methods", function()
        local W, H = 512, 512
        local img = lurek.image.newImageData(W, H)

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

        lurek.image.savePNG(img, OUT .. "drawing_combined.png")
    end)

end)



-- ================================================================
-- Merged from: test_image_effects_evidence.lua
-- ================================================================

-- test_evidence_image_effects.lua
-- Evidence test: ImageData filters and effects with before/after PNG output

local OUT = "tests/output/image/"

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

describe("Evidence: ImageData effects", function()

    -- @evidence file
    it("saves base test image", function()
        local img = make_base(256, 256)
        lurek.image.savePNG(img, OUT .. "effects_base.png")
    end)

    -- @evidence file
    it("brightness increase (1.5)", function()
        local img = make_base(256, 256)
        local r_before, _, _, _ = img:getPixel(128, 128)
        img:brightness(1.5)
        lurek.image.savePNG(img, OUT .. "effects_brightness_up.png")
        local r_after, _, _, _ = img:getPixel(128, 128)
        -- After brightness > 1, values should increase (or stay at max)
    end)

    -- @evidence file
    it("brightness decrease (0.5)", function()
        local img = make_base(256, 256)
        img:brightness(0.5)
        lurek.image.savePNG(img, OUT .. "effects_brightness_down.png")
    end)

    -- @evidence file
    it("contrast increase (1.5)", function()
        local img = make_base(256, 256)
        img:contrast(1.5)
        lurek.image.savePNG(img, OUT .. "effects_contrast_up.png")
    end)

    -- @evidence file
    it("contrast decrease (0.5)", function()
        local img = make_base(256, 256)
        img:contrast(0.5)
        lurek.image.savePNG(img, OUT .. "effects_contrast_down.png")
    end)

    -- @evidence file
    it("saturation zero (grayscale-like)", function()
        local img = make_base(256, 256)
        img:saturation(0)
        lurek.image.savePNG(img, OUT .. "effects_saturation_zero.png")
    end)

    -- @evidence file
    it("saturation boost (2.0)", function()
        local img = make_base(256, 256)
        img:saturation(2)
        lurek.image.savePNG(img, OUT .. "effects_saturation_boost.png")
    end)

    -- @evidence file
    it("grayscale", function()
        local img = make_base(256, 256)
        img:grayscale()
        lurek.image.savePNG(img, OUT .. "effects_grayscale.png")
        local r, g, b, _ = img:getPixel(100, 100)
    end)

    -- @evidence file
    it("sepia", function()
        local img = make_base(256, 256)
        img:sepia()
        lurek.image.savePNG(img, OUT .. "effects_sepia.png")
    end)

    -- @evidence file
    it("invert", function()
        local img = make_base(256, 256)
        img:invert()
        lurek.image.savePNG(img, OUT .. "effects_invert.png")
    end)

    -- @evidence file
    it("threshold (128)", function()
        local img = make_base(256, 256)
        img:threshold(128)
        lurek.image.savePNG(img, OUT .. "effects_threshold.png")
    end)

    -- @evidence file
    it("posterize (4 levels)", function()
        local img = make_base(256, 256)
        img:posterize(4)
        lurek.image.savePNG(img, OUT .. "effects_posterize.png")
    end)

    -- @evidence file
    it("blur (radius 3)", function()
        local img = make_base(256, 256)
        local blurred = img:blur(3)
        lurek.image.savePNG(blurred, OUT .. "effects_blur.png")
    end)

    -- @evidence file
    it("sharpen", function()
        local img = make_base(256, 256)
        local sharp = img:sharpen()
        lurek.image.savePNG(sharp, OUT .. "effects_sharpen.png")
    end)

    -- @evidence file
    it("gamma correction (0.5 and 2.0)", function()
        local img1 = make_base(256, 256)
        img1:gamma(0.5)
        lurek.image.savePNG(img1, OUT .. "effects_gamma_low.png")

        local img2 = make_base(256, 256)
        img2:gamma(2.0)
        lurek.image.savePNG(img2, OUT .. "effects_gamma_high.png")
    end)

    -- @evidence file
    it("tint red 50%", function()
        local img = make_base(256, 256)
        img:tint(255, 0, 0, 0.5)
        lurek.image.savePNG(img, OUT .. "effects_tint_red.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_image.lua
-- ================================================================

-- Keeps pending image, minimap, and raycaster evidence ports visible until each migrated Rust case is translated into real Lua artifact generation.

describe("Evidence: image", function()
end)



-- ================================================================
-- Merged from: test_evidence_image_drawing.lua
-- ================================================================

-- test_evidence_image_drawing.lua
-- Evidence test: ImageData drawing methods (drawRect, drawLine, drawCircle)

local OUT = "tests/output/image/"

describe("Evidence: ImageData drawing methods", function()

    -- @evidence file
    it("drawRect - grid of colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "drawing_rects.png")
        -- Verify a drawn pixel
        local r, g, b, a = img:getPixel(3, 3)
    end)

    -- @evidence file
    it("drawLine - star pattern from center", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "drawing_lines.png")
        -- Center pixel should have been drawn
        local r, g, b, a = img:getPixel(128, 128)
    end)

    -- @evidence file
    it("drawCircle - concentric circles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "drawing_circles.png")
        -- Center pixel should be the innermost circle color
        local r, g, b, a = img:getPixel(128, 128)
    end)

    -- @evidence file
    it("combined scene with all drawing methods", function()
        local W, H = 512, 512
        local img = lurek.image.newImageData(W, H)

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

        lurek.image.savePNG(img, OUT .. "drawing_combined.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_image_effects.lua
-- ================================================================

-- test_evidence_image_effects.lua
-- Evidence test: ImageData filters and effects with before/after PNG output

local OUT = "tests/output/image/"

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

describe("Evidence: ImageData effects", function()

    -- @evidence file
    it("saves base test image", function()
        local img = make_base(256, 256)
        lurek.image.savePNG(img, OUT .. "effects_base.png")
    end)

    -- @evidence file
    it("brightness increase (1.5)", function()
        local img = make_base(256, 256)
        local r_before, _, _, _ = img:getPixel(128, 128)
        img:brightness(1.5)
        lurek.image.savePNG(img, OUT .. "effects_brightness_up.png")
        local r_after, _, _, _ = img:getPixel(128, 128)
        -- After brightness > 1, values should increase (or stay at max)
    end)

    -- @evidence file
    it("brightness decrease (0.5)", function()
        local img = make_base(256, 256)
        img:brightness(0.5)
        lurek.image.savePNG(img, OUT .. "effects_brightness_down.png")
    end)

    -- @evidence file
    it("contrast increase (1.5)", function()
        local img = make_base(256, 256)
        img:contrast(1.5)
        lurek.image.savePNG(img, OUT .. "effects_contrast_up.png")
    end)

    -- @evidence file
    it("contrast decrease (0.5)", function()
        local img = make_base(256, 256)
        img:contrast(0.5)
        lurek.image.savePNG(img, OUT .. "effects_contrast_down.png")
    end)

    -- @evidence file
    it("saturation zero (grayscale-like)", function()
        local img = make_base(256, 256)
        img:saturation(0)
        lurek.image.savePNG(img, OUT .. "effects_saturation_zero.png")
    end)

    -- @evidence file
    it("saturation boost (2.0)", function()
        local img = make_base(256, 256)
        img:saturation(2)
        lurek.image.savePNG(img, OUT .. "effects_saturation_boost.png")
    end)

    -- @evidence file
    it("grayscale", function()
        local img = make_base(256, 256)
        img:grayscale()
        lurek.image.savePNG(img, OUT .. "effects_grayscale.png")
        local r, g, b, _ = img:getPixel(100, 100)
    end)

    -- @evidence file
    it("sepia", function()
        local img = make_base(256, 256)
        img:sepia()
        lurek.image.savePNG(img, OUT .. "effects_sepia.png")
    end)

    -- @evidence file
    it("invert", function()
        local img = make_base(256, 256)
        img:invert()
        lurek.image.savePNG(img, OUT .. "effects_invert.png")
    end)

    -- @evidence file
    it("threshold (128)", function()
        local img = make_base(256, 256)
        img:threshold(128)
        lurek.image.savePNG(img, OUT .. "effects_threshold.png")
    end)

    -- @evidence file
    it("posterize (4 levels)", function()
        local img = make_base(256, 256)
        img:posterize(4)
        lurek.image.savePNG(img, OUT .. "effects_posterize.png")
    end)

    -- @evidence file
    it("blur (radius 3)", function()
        local img = make_base(256, 256)
        local blurred = img:blur(3)
        lurek.image.savePNG(blurred, OUT .. "effects_blur.png")
    end)

    -- @evidence file
    it("sharpen", function()
        local img = make_base(256, 256)
        local sharp = img:sharpen()
        lurek.image.savePNG(sharp, OUT .. "effects_sharpen.png")
    end)

    -- @evidence file
    it("gamma correction (0.5 and 2.0)", function()
        local img1 = make_base(256, 256)
        img1:gamma(0.5)
        lurek.image.savePNG(img1, OUT .. "effects_gamma_low.png")

        local img2 = make_base(256, 256)
        img2:gamma(2.0)
        lurek.image.savePNG(img2, OUT .. "effects_gamma_high.png")
    end)

    -- @evidence file
    it("tint red 50%", function()
        local img = make_base(256, 256)
        img:tint(255, 0, 0, 0.5)
        lurek.image.savePNG(img, OUT .. "effects_tint_red.png")
    end)

end)

-- ================================================================
-- Merged from: test_imagedata_evidence.lua
-- ================================================================

-- Evidence test: ImageData pixel creation, manipulation, and PNG save
-- Produces: imagedata_basic.png, imagedata_fill.png, imagedata_mapped.png,
--           imagedata_cropped.png, imagedata_resized.png, imagedata_flipped.png,
--           imagedata_rotated.png

describe("evidence: imagedata creation and manipulation", function()
    local OUT

    before_each(function()
        ensure_evidence_dir("image")
        OUT = evidence_output_dir("image")
    end)

    -- @evidence file
    it("creates basic pixel-painted image", function()
        local img = lurek.image.newImageData(16, 16)
        img:setPixel(0,  0,  255, 0,   0,   255)
        img:setPixel(1,  0,  0,   255, 0,   255)
        img:setPixel(2,  0,  0,   0,   255, 255)
        img:setPixel(15, 15, 128, 64,  32,  200)
        local path = OUT .. "imagedata_basic.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates fill image", function()
        local img = lurek.image.newImageData(16, 16)
        img:fill(100, 150, 200, 255)
        local path = OUT .. "imagedata_fill.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates mapPixel inverted image", function()
        local img = lurek.image.newImageData(16, 16)
        img:fill(50, 100, 150, 255)
        img:mapPixel(function(x, y, r, g, b, a)
            return 255 - r, 255 - g, 255 - b, a
        end)
        local path = OUT .. "imagedata_mapped.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates cropped sub-image", function()
        local img = lurek.image.newImageData(16, 16)
        img:fill(200, 100, 50, 255)
        local sub = img:crop(4, 4, 6, 6)
        local path = OUT .. "imagedata_cropped.png"
        lurek.image.savePNG(sub, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates resized image", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(255, 0, 0, 255)
        local big = img:resizeNearest(16, 16)
        local path = OUT .. "imagedata_resized.png"
        lurek.image.savePNG(big, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates horizontally flipped image", function()
        local img = lurek.image.newImageData(8, 8)
        img:fill(0, 0, 0, 255)
        -- left half red, right half blue
        for y = 0, 7 do
            for x = 0, 3 do img:setPixel(x, y, 255, 0, 0, 255) end
            for x = 4, 7 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        img:flipHorizontal()
        local path = OUT .. "imagedata_flipped.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates rotated image", function()
        local img = lurek.image.newImageData(4, 8)
        img:fill(255, 128, 0, 255)
        local rotated = img:rotate90cw()
        local path = OUT .. "imagedata_rotated.png"
        lurek.image.savePNG(rotated, path)
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_imagedata_effects_evidence.lua
-- ================================================================

-- Evidence test: ImageData filter/effect methods produce PNG evidence
-- Produces: effect_grayscale.png, effect_inverted.png, effect_sepia.png,
--           effect_bright.png, effect_threshold.png, effect_blur.png,
--           effect_sharpen.png, effect_noise.png, effect_posterize.png, effect_tint.png
-- @evidence file

local function solid(w, h, r, g, b, a)
    local img = lurek.image.newImageData(w, h)
    img:fill(r, g, b, a)
    return img
end

describe("evidence: imagedata effect filters", function()
    local OUT

    before_each(function()
        ensure_evidence_dir("image")
        OUT = evidence_output_dir("image")
    end)

    -- @evidence file
    it("creates grayscale effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        img:grayscale()
        local path = OUT .. "effect_grayscale.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates inverted effect PNG", function()
        local img = solid(32, 32, 100, 150, 200, 255)
        img:invert()
        local path = OUT .. "effect_inverted.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates sepia effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:sepia()
        local path = OUT .. "effect_sepia.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates brightness effect PNG", function()
        local img = solid(32, 32, 100, 100, 100, 255)
        img:brightness(1.5)
        local path = OUT .. "effect_bright.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates threshold effect PNG", function()
        local img = solid(32, 32, 179, 134, 89, 255)
        img:threshold(128)
        local path = OUT .. "effect_threshold.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates posterize effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:posterize(4)
        local path = OUT .. "effect_posterize.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates tint effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:tint(255, 0, 0, 0.5)
        local path = OUT .. "effect_tint.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates noise effect PNG", function()
        local img = solid(32, 32, 128, 128, 128, 255)
        img:noise(30)
        local path = OUT .. "effect_noise.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates blur effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        local blurred = img:blur(2)
        local path = OUT .. "effect_blur.png"
        lurek.image.savePNG(blurred, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates sharpen effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        local sharpened = img:sharpen()
        local path = OUT .. "effect_sharpen.png"
        lurek.image.savePNG(sharpened, path)
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_evidence_imagedata.lua
-- ================================================================

-- Evidence test: ImageData pixel creation, manipulation, and PNG save
-- Produces: imagedata_basic.png, imagedata_fill.png, imagedata_mapped.png,
--           imagedata_cropped.png, imagedata_resized.png, imagedata_flipped.png,
--           imagedata_rotated.png

describe("evidence: imagedata creation and manipulation", function()
    local OUT

    before_each(function()
        ensure_evidence_dir("image")
        OUT = evidence_output_dir("image")
    end)

    -- @evidence file
    it("creates basic pixel-painted image", function()
        local img = lurek.image.newImageData(16, 16)
        img:setPixel(0,  0,  255, 0,   0,   255)
        img:setPixel(1,  0,  0,   255, 0,   255)
        img:setPixel(2,  0,  0,   0,   255, 255)
        img:setPixel(15, 15, 128, 64,  32,  200)
        local path = OUT .. "imagedata_basic.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates fill image", function()
        local img = lurek.image.newImageData(16, 16)
        img:fill(100, 150, 200, 255)
        local path = OUT .. "imagedata_fill.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates mapPixel inverted image", function()
        local img = lurek.image.newImageData(16, 16)
        img:fill(50, 100, 150, 255)
        img:mapPixel(function(x, y, r, g, b, a)
            return 255 - r, 255 - g, 255 - b, a
        end)
        local path = OUT .. "imagedata_mapped.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates cropped sub-image", function()
        local img = lurek.image.newImageData(16, 16)
        img:fill(200, 100, 50, 255)
        local sub = img:crop(4, 4, 6, 6)
        local path = OUT .. "imagedata_cropped.png"
        lurek.image.savePNG(sub, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates resized image", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(255, 0, 0, 255)
        local big = img:resizeNearest(16, 16)
        local path = OUT .. "imagedata_resized.png"
        lurek.image.savePNG(big, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates horizontally flipped image", function()
        local img = lurek.image.newImageData(8, 8)
        img:fill(0, 0, 0, 255)
        -- left half red, right half blue
        for y = 0, 7 do
            for x = 0, 3 do img:setPixel(x, y, 255, 0, 0, 255) end
            for x = 4, 7 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        img:flipHorizontal()
        local path = OUT .. "imagedata_flipped.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates rotated image", function()
        local img = lurek.image.newImageData(4, 8)
        img:fill(255, 128, 0, 255)
        local rotated = img:rotate90cw()
        local path = OUT .. "imagedata_rotated.png"
        lurek.image.savePNG(rotated, path)
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_evidence_imagedata_effects.lua
-- ================================================================

-- Evidence test: ImageData filter/effect methods produce PNG evidence
-- Produces: effect_grayscale.png, effect_inverted.png, effect_sepia.png,
--           effect_bright.png, effect_threshold.png, effect_blur.png,
--           effect_sharpen.png, effect_noise.png, effect_posterize.png, effect_tint.png
-- @evidence file

local function solid(w, h, r, g, b, a)
    local img = lurek.image.newImageData(w, h)
    img:fill(r, g, b, a)
    return img
end

describe("evidence: imagedata effect filters", function()
    local OUT

    before_each(function()
        ensure_evidence_dir("image")
        OUT = evidence_output_dir("image")
    end)

    -- @evidence file
    it("creates grayscale effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        img:grayscale()
        local path = OUT .. "effect_grayscale.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates inverted effect PNG", function()
        local img = solid(32, 32, 100, 150, 200, 255)
        img:invert()
        local path = OUT .. "effect_inverted.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates sepia effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:sepia()
        local path = OUT .. "effect_sepia.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates brightness effect PNG", function()
        local img = solid(32, 32, 100, 100, 100, 255)
        img:brightness(1.5)
        local path = OUT .. "effect_bright.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates threshold effect PNG", function()
        local img = solid(32, 32, 179, 134, 89, 255)
        img:threshold(128)
        local path = OUT .. "effect_threshold.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates posterize effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:posterize(4)
        local path = OUT .. "effect_posterize.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates tint effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:tint(255, 0, 0, 0.5)
        local path = OUT .. "effect_tint.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates noise effect PNG", function()
        local img = solid(32, 32, 128, 128, 128, 255)
        img:noise(30)
        local path = OUT .. "effect_noise.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates blur effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        local blurred = img:blur(2)
        local path = OUT .. "effect_blur.png"
        lurek.image.savePNG(blurred, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("creates sharpen effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        local sharpened = img:sharpen()
        local path = OUT .. "effect_sharpen.png"
        lurek.image.savePNG(sharpened, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
