-- Migrated 15 tests from Rust evidence
local OUT = "tests/lua/evidence/output/migrated_15/"

-- @description Covers suite: evidence: migrated 15.
describe("evidence: migrated 15", function()
    before_each(function()
        ensure_evidence_dir("migrated_15")
    end)

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Creates a blank 64x64 image and saves it as baseline evidence for empty image allocation.
    it("evidence_image_new_blank", function()
        local img = lurek.image.newImageData(64, 64)
        local path = OUT .. "new_blank_64x64.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Fills a small image with solid orange and saves the result as simple fill evidence.
    it("evidence_image_fill_solid", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(255, 128, 0, 255)
        local path = OUT .. "fill_orange.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:setPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Paints crossing diagonal pixel patterns into an image and saves the result.
    it("evidence_image_set_pixel_pattern", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(0, 0, 0, 255)
        for i = 0, 63 do
            img:setPixel(i, i, 255, 255, 0, 255)
            if i < 63 then
                img:setPixel(63 - i, i, 0, 255, 255, 255)
            end
        end
        local path = OUT .. "diagonal_cross.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:drawLine
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawCircle
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds a multi-shape scene from primitive drawing calls and saves the composed result.
    it("evidence_image_draw_shapes_combined", function()
        local img = lurek.image.newImageData(256, 256)
        img:fill(20, 20, 40, 255)
        for i = 0, 255, 16 do
            img:drawLine(i, 0, i, 255, 40, 40, 60, 255)
            img:drawLine(0, i, 255, i, 40, 40, 60, 255)
        end
        img:drawRect(60, 140, 80, 80, 180, 120, 60, 255)
        img:drawRect(85, 180, 30, 40, 100, 60, 30, 255)
        img:drawRect(70, 155, 20, 20, 150, 200, 255, 255)
        img:drawRect(110, 155, 20, 20, 150, 200, 255, 255)
        img:drawLine(55, 140, 100, 90, 200, 50, 50, 255)
        img:drawLine(100, 90, 145, 140, 200, 50, 50, 255)
        img:drawLine(55, 140, 145, 140, 200, 50, 50, 255)
        img:drawCircle(200, 50, 25, 255, 220, 50, 255)
        for angle_deg = 0, 359, 45 do
            local angle = math.rad(angle_deg)
            local sx, sy = 200 + 30 * math.cos(angle), 50 + 30 * math.sin(angle)
            local ex, ey = 200 + 45 * math.cos(angle), 50 + 45 * math.sin(angle)
            img:drawLine(sx, sy, ex, ey, 255, 220, 50, 255)
        end
        img:drawRect(0, 220, 256, 36, 40, 120, 40, 255)
        local path = OUT .. "shapes_combined_scene.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:drawCircle
    -- @covers ImageData:paste
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Composites one sprite image onto a background several times and saves the resulting paste test.
    it("evidence_image_paste_composite", function()
        local bg = lurek.image.newImageData(128, 128)
        bg:fill(40, 40, 80, 255)
        local sprite = lurek.image.newImageData(32, 32)
        sprite:drawCircle(16, 16, 14, 255, 200, 0, 255)
        bg:paste(sprite, 10, 10)
        bg:paste(sprite, 50, 30)
        bg:paste(sprite, 80, 70)
        local path = OUT .. "paste_composite.png"
        lurek.image.savePNG(bg, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:crop
    -- @covers ImageData:noise
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Copies an image and applies noise to the copy before saving the noisy variant.
    it("evidence_effect_noise", function()
        local img = lurek.image.newImageData(128, 128)
        img:fill(128, 128, 128, 255)
        local noisy = img:crop(0, 0, 128, 128)
        noisy:noise(80)
        local path = OUT .. "noise_after.png"
        lurek.image.savePNG(noisy, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @covers ImageData:crop
    -- @covers ImageData:flipHorizontal
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds a two-color image, flips it horizontally, and writes the mirrored result.
    it("evidence_effect_flip_horizontal", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 31 do img:setPixel(x, y, 255, 0, 0, 255) end
            for x = 32, 63 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        local flipped = img:crop(0, 0, 64, 64)
        flipped:flipHorizontal()
        local path = OUT .. "flip_h_after.png"
        lurek.image.savePNG(flipped, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @covers ImageData:crop
    -- @covers ImageData:flipVertical
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds a two-color image, flips it vertically, and writes the mirrored result.
    it("evidence_effect_flip_vertical", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 31 do
            for x = 0, 63 do img:setPixel(x, y, 255, 0, 0, 255) end
        end
        for y = 32, 63 do
            for x = 0, 63 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        local flipped = img:crop(0, 0, 64, 64)
        flipped:flipVertical()
        local path = OUT .. "flip_v_after.png"
        lurek.image.savePNG(flipped, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:rotate90cw
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Rotates a rectangular image clockwise and saves the rotated artifact.
    it("evidence_effect_rotate", function()
        local img = lurek.image.newImageData(64, 32)
        img:fill(255, 255, 0, 255)
        local rotated = img:rotate90cw()
        local path = OUT .. "rotate_90cw.png"
        lurek.image.savePNG(rotated, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:drawRect
    -- @covers ImageData:crop
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Crops the central red square from a larger image and writes the cropped output.
    it("evidence_effect_crop", function()
        local img = lurek.image.newImageData(128, 128)
        img:fill(200, 200, 200, 255)
        img:drawRect(32, 32, 64, 64, 255, 0, 0, 255)
        local cropped = img:crop(32, 32, 64, 64)
        local path = OUT .. "crop_center.png"
        lurek.image.savePNG(cropped, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:drawCircle
    -- @covers ImageData:resizeNearest
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Upscales a small magenta image with a dark circle using nearest-neighbor resizing.
    it("evidence_effect_resize", function()
        local img = lurek.image.newImageData(32, 32)
        img:fill(255, 0, 255, 255)
        img:drawCircle(16, 16, 10, 0, 0, 0, 255)
        local big = img:resizeNearest(128, 128)
        local path = OUT .. "resize_upscaled_128.png"
        lurek.image.savePNG(big, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:crop
    -- @covers ImageData:mapPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies an alpha mask through mapPixel and saves the masked output.
    it("evidence_effect_alpha_mask", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(0, 255, 0, 255)
        local mask = lurek.image.newImageData(64, 64)
        mask:fill(128, 128, 128, 128) -- 50% opacity
        local masked = img:crop(0, 0, 64, 64)
        -- missing specific multiply_alpha, we assume mapPixel
        masked:mapPixel(function(x, y, r, g, b, a)
            local _, _, _, ma = mask:getPixel(x, y)
            return r, g, b, (a * ma) / 255
        end)
        local path = OUT .. "alpha_mask_50pct.png"
        lurek.image.savePNG(masked, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:drawCircle
    -- @covers ImageData:crop
    -- @covers ImageData:blur
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Applies a blur stage to a simple image-processing pipeline and saves the intermediate output.
    it("evidence_effect_pipeline", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(100, 100, 100, 255)
        img:drawCircle(32, 32, 20, 200, 50, 50, 255)
        local blurred = img:crop(0, 0, 64, 64)
        blurred:blur(2.0)
        local path = OUT .. "pipeline_05_blur.png"
        lurek.image.savePNG(blurred, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.math.perlinFast
    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Colors Perlin noise into terrain bands and saves the resulting terrain map.
    it("evidence_math_noise_colored_terrain", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local n = math.min(1, math.max(0, (lurek.math.perlinFast(x * 0.1, y * 0.1) + 1.0) * 0.5))
                local r, g, b = 0, 0, 0
                if n < 0.4 then r, g, b = 0, 0, 150
                elseif n < 0.6 then r, g, b = 200, 200, 100
                else r, g, b = 50, 150, 50 end
                img:setPixel(x, y, r, g, b, 255)
            end
        end
        local path = OUT .. "noise_terrain_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @covers lurek.math.simplex
    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples simplex noise into a grayscale heightmap and writes the generated map image.
    it("evidence_math_generate_map", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local n = lurek.math.simplex(x * 0.1, y * 0.1)
                local v = math.floor((n + 1.0) * 127)
                img:setPixel(x, y, v, v, v, 255)
            end
        end
        local path = OUT .. "generate_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
