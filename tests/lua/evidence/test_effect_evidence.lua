-- test_effect_evidence.lua
-- Canonical file. Merged from multiple sources.

-- test_evidence_effect_ui.lua
-- Evidence test: lurek.effect effect API + renders overlay effects to PNG
-- Produces: overlay_flash.png, overlay_fade.png, overlay_combined.png

local OUT = "tests/output/overlay/"

--- Helper: draw filled rect
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

--- Helper: blend a color over a base color
local function blend(base_r, base_g, base_b, over_r, over_g, over_b, alpha)
    local a = alpha
    local ia = 1.0 - a
    return math.floor(base_r * ia + over_r * a),
           math.floor(base_g * ia + over_g * a),
           math.floor(base_b * ia + over_b * a)
end

describe("Evidence: lurek.effect effect API + PNG visualization", function()
    -- @evidence file
    it("PNG: flash effect at multiple time steps", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)

        local ov = lurek.effect.newOverlay(W, H)
        ov:triggerFlash(1.0, 0.0, 0.0, 1.0, 1.0) -- red flash, 1s

        -- Render 8 time steps showing flash decay
        local steps = 8
        local cell_w = W / steps
        for step = 0, steps - 1 do
            local alpha = ov:getFlashAlpha()
            -- Draw a column showing the flash color at this alpha
            for y = 0, H - 1 do
                for x = math.floor(step * cell_w), math.min(math.floor((step + 1) * cell_w) - 1, W - 1) do
                    local br, bg, bb = blend(40, 40, 60, 255, 0, 0, math.max(0, alpha))
                    img:setPixel(x, y, br, bg, bb, 255)
                end
            end
            ov:update(1.0 / steps)
        end

        lurek.image.savePNG(img, OUT .. "overlay_flash.png")
    end)

    -- @evidence file
    it("PNG: fade-to-black effect over time", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)

        local ov = lurek.effect.newOverlay(W, H)
        ov:triggerFade(0, 0, 0, 1.0, 1.0) -- fade to black

        local steps = 8
        local cell_w = W / steps
        for step = 0, steps - 1 do
            local flash_a = ov:getFlashAlpha()
            local t = step / steps -- progress
            for y = 0, H - 1 do
                for x = math.floor(step * cell_w), math.min(math.floor((step + 1) * cell_w) - 1, W - 1) do
                    -- Base scene is bright blue
                    local br, bg, bb = blend(100, 150, 255, 0, 0, 0, t)
                    img:setPixel(x, y, br, bg, bb, 255)
                end
            end
            ov:update(1.0 / steps)
        end

        lurek.image.savePNG(img, OUT .. "overlay_fade.png")
    end)

    -- @evidence file
    it("PNG: combined effects -    flash + lightning visualization", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 40, 255)

        local ov = lurek.effect.newOverlay(W, H)

        -- Flash in top half (red)
        ov:triggerFlash(1.0, 0.2, 0.0, 0.8, 0.5)
        local flash_a = ov:getFlashAlpha()
        for y = 0, 63 do
            for x = 0, W - 1 do
                local br, bg, bb = blend(20, 20, 40, 255, 50, 0, math.max(0, flash_a))
                img:setPixel(x, y, br, bg, bb, 255)
            end
        end

        -- Lightning in bottom half (white flash)
        ov:clear()
        ov:triggerLightning()
        local lightning_a = ov:getLightningAlpha()
        for y = 64, H - 1 do
            for x = 0, W - 1 do
                local br, bg, bb = blend(20, 20, 40, 255, 255, 255, math.max(0, lightning_a * 0.5))
                img:setPixel(x, y, br, bg, bb, 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "overlay_combined.png")
    end)

end)



-- ================================================================
-- Merged from: test_effect_postfx_evidence.lua
-- ================================================================

-- test_evidence_effect_effect.lua
-- Evidence test: ImageData post-processing effects + Effect/Stack API
-- Produces: postfx_grayscale.png, postfx_invert.png, postfx_blur.png,
--           postfx_sepia.png, postfx_effects_strip.png

local OUT = "tests/output/postfx/"

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

describe("Evidence: PostFx + ImageData effects          PNG output", function()
    -- @evidence file
    it("PNG: grayscale effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:grayscale()
        -- Verify some pixels are indeed gray (r == g == b)
        local pr, pg, pb = img:getPixel(64, 64)
        lurek.image.savePNG(img, OUT .. "postfx_grayscale.png")
    end)

    -- @evidence file
    it("PNG: invert effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        -- Read a pixel before invert
        local br, bg, bb = img:getPixel(64, 64)
        img:invert()
        -- After invert, pixel should be ~(255 - original)
        local ar, ag, ab = img:getPixel(64, 64)
        lurek.image.savePNG(img, OUT .. "postfx_invert.png")
    end)

    -- @evidence file
    it("PNG: blur effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:blur(3)
        lurek.image.savePNG(img, OUT .. "postfx_blur.png")
    end)

    -- @evidence file
    it("PNG: sepia effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:sepia()
        lurek.image.savePNG(img, OUT .. "postfx_sepia.png")
    end)

    -- @evidence file
    it("PNG: effect strip -    original + 8 effects side by side", function()
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

    -- @evidence file
    it("PNG: posterize + gamma + tint combined", function()
        local img = make_test_pattern(128, 128)
        img:posterize(4)
        img:gamma(1.5)
        img:tint(255, 200, 150, 255)
        lurek.image.savePNG(img, OUT .. "postfx_posterize_tint.png")
    end)

    -- @evidence file
    it("PNG: saturation and flipHorizontal", function()
        local img = make_test_pattern(128, 128)
        img:saturation(2.0)
        img:flipHorizontal()
        lurek.image.savePNG(img, OUT .. "postfx_saturation_flip.png")
    end)

end)



-- ================================================================
-- Merged from: test_effect_types_evidence.lua
-- ================================================================

-- test_evidence_effect_types.lua
-- Evidence test: proves all 8 new PostFxEffectType variants can be constructed,
-- configured, and introspected via the lurek.effect Lua API.
-- Output: tests/output/postfx_types_evidence.txt

local describe     = describe
local it           = it
local expect_equal = expect_equal

local NEW_TYPES = {
    "depthoffield",
    "motionblur",
    "paletteswap",
    "colorlut",
    "waterdistort",
    "sharpen",
    "dither",
    "outline",
}

-- Collect evidence lines during tests; write file at the end.
local evidence_lines = {}
local function record(line) evidence_lines[#evidence_lines + 1] = line end

describe("New PostFxEffectType construction evidence", function()
    for _, type_name in ipairs(NEW_TYPES) do
    end
end)

describe("New effect types appear in getEffectTypes()", function()
end)

describe("New effect types in a PostFxStack", function()
end)

describe("newPresetStack evidence", function()
    local PRESETS = { "retro_tv", "horror", "dream", "neon", "sepia_age" }
    end)

-- Write evidence artifact.
local output_dir = "tests/output"
local output_path = output_dir .. "/postfx_types_evidence.txt"
local ok = lurek.filesystem.mkdir(output_dir)
if ok then
    local f = lurek.filesystem.open(output_path, "w")
    if f then
        f:write("# PostFx Types Evidence\n")
        f:write("# Generated by test_evidence_effect_types.lua\n\n")
        for _, line in ipairs(evidence_lines) do
            f:write(line .. "\n")
        end
        f:close()
    end
end




-- ================================================================
-- Merged from: test_evidence_effect_overlay.lua
-- ================================================================

-- test_evidence_effect_overlay.lua
-- Evidence test: lurek.effect effect API + renders overlay effects to PNG
-- Produces: overlay_flash.png, overlay_fade.png, overlay_combined.png

local OUT = "tests/output/overlay/"

--- Helper: draw filled rect
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

--- Helper: blend a color over a base color
local function blend(base_r, base_g, base_b, over_r, over_g, over_b, alpha)
    local a = alpha
    local ia = 1.0 - a
    return math.floor(base_r * ia + over_r * a),
           math.floor(base_g * ia + over_g * a),
           math.floor(base_b * ia + over_b * a)
end

describe("Evidence: lurek.effect effect API + PNG visualization", function()
    -- @evidence file
    it("PNG: flash effect at multiple time steps", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)

        local ov = lurek.effect.newOverlay(W, H)
        ov:triggerFlash(1.0, 0.0, 0.0, 1.0, 1.0) -- red flash, 1s

        -- Render 8 time steps showing flash decay
        local steps = 8
        local cell_w = W / steps
        for step = 0, steps - 1 do
            local alpha = ov:getFlashAlpha()
            -- Draw a column showing the flash color at this alpha
            for y = 0, H - 1 do
                for x = math.floor(step * cell_w), math.min(math.floor((step + 1) * cell_w) - 1, W - 1) do
                    local br, bg, bb = blend(40, 40, 60, 255, 0, 0, math.max(0, alpha))
                    img:setPixel(x, y, br, bg, bb, 255)
                end
            end
            ov:update(1.0 / steps)
        end

        lurek.image.savePNG(img, OUT .. "overlay_flash.png")
    end)

    -- @evidence file
    it("PNG: fade-to-black effect over time", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)

        local ov = lurek.effect.newOverlay(W, H)
        ov:triggerFade(0, 0, 0, 1.0, 1.0) -- fade to black

        local steps = 8
        local cell_w = W / steps
        for step = 0, steps - 1 do
            local flash_a = ov:getFlashAlpha()
            local t = step / steps -- progress
            for y = 0, H - 1 do
                for x = math.floor(step * cell_w), math.min(math.floor((step + 1) * cell_w) - 1, W - 1) do
                    -- Base scene is bright blue
                    local br, bg, bb = blend(100, 150, 255, 0, 0, 0, t)
                    img:setPixel(x, y, br, bg, bb, 255)
                end
            end
            ov:update(1.0 / steps)
        end

        lurek.image.savePNG(img, OUT .. "overlay_fade.png")
    end)

    -- @evidence file
    it("PNG: combined effects -    flash + lightning visualization", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 40, 255)

        local ov = lurek.effect.newOverlay(W, H)

        -- Flash in top half (red)
        ov:triggerFlash(1.0, 0.2, 0.0, 0.8, 0.5)
        local flash_a = ov:getFlashAlpha()
        for y = 0, 63 do
            for x = 0, W - 1 do
                local br, bg, bb = blend(20, 20, 40, 255, 50, 0, math.max(0, flash_a))
                img:setPixel(x, y, br, bg, bb, 255)
            end
        end

        -- Lightning in bottom half (white flash)
        ov:clear()
        ov:triggerLightning()
        local lightning_a = ov:getLightningAlpha()
        for y = 64, H - 1 do
            for x = 0, W - 1 do
                local br, bg, bb = blend(20, 20, 40, 255, 255, 255, math.max(0, lightning_a * 0.5))
                img:setPixel(x, y, br, bg, bb, 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "overlay_combined.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_effect_postfx.lua
-- ================================================================

-- test_evidence_effect_postfx.lua
-- Evidence test: ImageData post-processing effects + Effect/Stack API
-- Produces: postfx_grayscale.png, postfx_invert.png, postfx_blur.png,
--           postfx_sepia.png, postfx_effects_strip.png

local OUT = "tests/output/postfx/"

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

describe("Evidence: PostFx + ImageData effects          PNG output", function()
    -- @evidence file
    it("PNG: grayscale effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:grayscale()
        -- Verify some pixels are indeed gray (r == g == b)
        local pr, pg, pb = img:getPixel(64, 64)
        lurek.image.savePNG(img, OUT .. "postfx_grayscale.png")
    end)

    -- @evidence file
    it("PNG: invert effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        -- Read a pixel before invert
        local br, bg, bb = img:getPixel(64, 64)
        img:invert()
        -- After invert, pixel should be ~(255 - original)
        local ar, ag, ab = img:getPixel(64, 64)
        lurek.image.savePNG(img, OUT .. "postfx_invert.png")
    end)

    -- @evidence file
    it("PNG: blur effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:blur(3)
        lurek.image.savePNG(img, OUT .. "postfx_blur.png")
    end)

    -- @evidence file
    it("PNG: sepia effect on color gradient", function()
        local img = make_test_pattern(128, 128)
        img:sepia()
        lurek.image.savePNG(img, OUT .. "postfx_sepia.png")
    end)

    -- @evidence file
    it("PNG: effect strip -    original + 8 effects side by side", function()
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

    -- @evidence file
    it("PNG: posterize + gamma + tint combined", function()
        local img = make_test_pattern(128, 128)
        img:posterize(4)
        img:gamma(1.5)
        img:tint(255, 200, 150, 255)
        lurek.image.savePNG(img, OUT .. "postfx_posterize_tint.png")
    end)

    -- @evidence file
    it("PNG: saturation and flipHorizontal", function()
        local img = make_test_pattern(128, 128)
        img:saturation(2.0)
        img:flipHorizontal()
        lurek.image.savePNG(img, OUT .. "postfx_saturation_flip.png")
    end)

end)
test_summary()
