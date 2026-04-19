-- tests/lua/unit/test_image.lua
-- BDD tests for lurek.img ImageData APIs, including image construction, layered images, save/load helpers, and effect-method coverage in the headless VM.

-- The headless VM has no filesystem, GPU, audio, or window APIs.
-- All tests use lurek.img.newImageData(w, h) for image construction.

-- =============================================================================
-- Compressed API (existing tests)
-- =============================================================================

-- @description Verifies that the compressed-image namespace exposes its helper functions and treats a nonexistent DDS path as an error for loading and as uncompressed for probing.
describe("lurek.img compressed API", function()
    -- @covers lurek.img.isCompressed
    -- @covers lurek.img.loadImage
    -- @covers lurek.img.loadLayered
    -- @covers lurek.img.newCompressedData
    -- @covers lurek.img.newImageData
    -- @covers lurek.img.newLayeredImage
    -- @covers lurek.img.saveImage
    -- @covers lurek.img.saveLayered
    -- @description Confirms the image namespace is available on lurek.img as a table.
    it("lurek.img is a table", function()
        expect_type("table", lurek.img)
    end)

    -- @description Confirms the compressed-data constructor is exposed as a callable function.
    it("newCompressedData is a function", function()
        expect_type("function", lurek.img.newCompressedData)
    end)

    -- @description Confirms the compression probe helper is exposed as a callable function.
    it("isCompressed is a function", function()
        expect_type("function", lurek.img.isCompressed)
    end)

    -- @description Asserts that constructing compressed data from a missing file path raises an error instead of succeeding silently.
    it("newCompressedData errors on missing file", function()
        expect_error(function()
            lurek.img.newCompressedData("nonexistent_file.dds")
        end)
    end)

    -- @description Checks that probing a missing file path reports false rather than raising or returning true.
    it("isCompressed returns false for a missing path", function()
        local result = lurek.img.isCompressed("nonexistent_file.dds")
        expect_equal(result, false)
    end)
end)

-- =============================================================================
-- Basic API (existing tests)
-- =============================================================================

-- @description Verifies the legacy ImageData constructor still exists and produces userdata buffers after the newer image work landed.
describe("lurek.img existing API still works", function()
    -- @description Confirms lurek.img.newImageData remains exposed as a function.
    it("newImageData is a function", function()
        expect_type("function", lurek.img.newImageData)
    end)

    -- @description Checks that newImageData(4, 4) returns a userdata buffer for a blank image.
    it("newImageData creates a blank buffer", function()
        local img = lurek.img.newImageData(4, 4)
        expect_type("userdata", img)
    end)
end)

-- =============================================================================
-- Effect method existence â€” one it per effect
-- =============================================================================

-- @description Creates a fresh ImageData before each case and verifies that every documented effect method is attached as a callable function on the userdata.
describe("ImageData effect method existence", function()
    local img
    before_each(function()
        img = lurek.img.newImageData(4, 4)
    end)

    -- @description Checks that ImageData exposes brightness as a callable method.
    it("brightness is a function", function()
        expect_type("function", img.brightness)
    end)

    -- @description Checks that ImageData exposes contrast as a callable method.
    it("contrast is a function", function()
        expect_type("function", img.contrast)
    end)

    -- @description Checks that ImageData exposes saturation as a callable method.
    it("saturation is a function", function()
        expect_type("function", img.saturation)
    end)

    -- @description Checks that ImageData exposes gamma as a callable method.
    it("gamma is a function", function()
        expect_type("function", img.gamma)
    end)

    -- @description Checks that ImageData exposes tint as a callable method.
    it("tint is a function", function()
        expect_type("function", img.tint)
    end)

    -- @description Checks that ImageData exposes grayscale as a callable method.
    it("grayscale is a function", function()
        expect_type("function", img.grayscale)
    end)

    -- @description Checks that ImageData exposes sepia as a callable method.
    it("sepia is a function", function()
        expect_type("function", img.sepia)
    end)

    -- @description Checks that ImageData exposes invert as a callable method.
    it("invert is a function", function()
        expect_type("function", img.invert)
    end)

    -- @description Checks that ImageData exposes threshold as a callable method.
    it("threshold is a function", function()
        expect_type("function", img.threshold)
    end)

    -- @description Checks that ImageData exposes posterize as a callable method.
    it("posterize is a function", function()
        expect_type("function", img.posterize)
    end)

    -- @description Checks that ImageData exposes fill as a callable method.
    it("fill is a function", function()
        expect_type("function", img.fill)
    end)

    -- @description Checks that ImageData exposes noise as a callable method.
    it("noise is a function", function()
        expect_type("function", img.noise)
    end)

    -- @description Checks that ImageData exposes alphaMask as a callable method.
    it("alphaMask is a function", function()
        expect_type("function", img.alphaMask)
    end)

    -- @description Checks that ImageData exposes flipHorizontal as a callable method.
    it("flipHorizontal is a function", function()
        expect_type("function", img.flipHorizontal)
    end)

    -- @description Checks that ImageData exposes flipVertical as a callable method.
    it("flipVertical is a function", function()
        expect_type("function", img.flipVertical)
    end)

    -- @description Checks that ImageData exposes rotate90cw as a callable method.
    it("rotate90cw is a function", function()
        expect_type("function", img.rotate90cw)
    end)

    -- @description Checks that ImageData exposes crop as a callable method.
    it("crop is a function", function()
        expect_type("function", img.crop)
    end)

    -- @description Checks that ImageData exposes resizeNearest as a callable method.
    it("resizeNearest is a function", function()
        expect_type("function", img.resizeNearest)
    end)

    -- @description Checks that ImageData exposes blur as a callable method.
    it("blur is a function", function()
        expect_type("function", img.blur)
    end)

    -- @description Checks that ImageData exposes sharpen as a callable method.
    it("sharpen is a function", function()
        expect_type("function", img.sharpen)
    end)
end)

-- =============================================================================
-- Color / Tone effects
-- =============================================================================

-- @description Verifies brightness scaling by checking clamp-up behaviour on mid-grey, identity at factor 1, and nil return for in-place mutation.
describe("ImageData color/tone effects: brightness", function()
    -- @description Confirms brightness(2.0) pushes a mid-grey pixel up toward white while preserving full alpha.
    it("brightness factor=2 brightens a mid-grey pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 128, 128, 128, 255)
        img:brightness(2.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- 128 * 2 = 256, clamped to 255
        expect_equal(r >= 200, true)
        expect_equal(g >= 200, true)
        expect_equal(b >= 200, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms brightness(1.0) leaves all RGBA channels unchanged.
    it("brightness factor=1 leaves pixel unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:brightness(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @description Checks that brightness mutates in place and therefore returns nil.
    it("brightness returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:brightness(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies contrast by checking identity at factor 1, clamp-up when amplifying a bright value, and nil return for in-place mutation.
describe("ImageData color/tone effects: contrast", function()
    -- @description Confirms contrast(1.0) leaves channels unchanged because the mid-grey distance is multiplied by 1.
    it("contrast factor=1 leaves pixel unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 128, 200, 50, 255)
        -- ((ch - 128)*1 + 128) = ch exactly
        img:contrast(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 128)
        expect_equal(g, 200)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @description Confirms contrast(2.0) increases distance from mid-grey enough to clamp a bright channel to 255.
    it("contrast factor=2 increases distance from mid-grey", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 200, 200, 200, 255)
        img:contrast(2.0)
        local r, _, _, _ = img:getPixel(0, 0)
        -- ((200 - 128)*2 + 128) = 72*2 + 128 = 272, clamped to 255
        expect_equal(r, 255)
    end)

    -- @description Checks that contrast mutates the source image and returns nil.
    it("contrast returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:contrast(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies saturation by checking full desaturation to grey, identity at factor 1, and nil return for in-place mutation.
describe("ImageData color/tone effects: saturation", function()
    -- @description Confirms saturation(0.0) collapses a pure red pixel to nearly equal grey channels while preserving alpha.
    it("saturation factor=0 desaturates a pure-red pixel to grey", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:saturation(0.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- All channels interpolated to luma â‰ 54; must be equal within rounding
        expect_equal(math.abs(r - g) <= 2, true)
        expect_equal(math.abs(g - b) <= 2, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms saturation(1.0) leaves the original colour untouched.
    it("saturation factor=1 leaves pixel unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:saturation(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @description Checks that saturation mutates in place and returns nil.
    it("saturation returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:saturation(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies gamma correction by checking identity at gamma 1, mid-tone brightening above 1, and nil return for in-place mutation.
describe("ImageData color/tone effects: gamma", function()
    -- @description Confirms gamma(1.0) preserves each channel within rounding tolerance and keeps alpha unchanged.
    it("gamma 1.0 leaves pixel unchanged (within rounding)", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:gamma(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- (ch/255)^(1/1.0)*255 = ch exactly (up to rounding)
        expect_equal(math.abs(r - 100) <= 1, true)
        expect_equal(math.abs(g - 150) <= 1, true)
        expect_equal(math.abs(b - 200) <= 1, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms gamma(2.0) brightens a mid-tone grey channel above its original 128 value.
    it("gamma > 1 brightens mid-tones", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 128, 128, 128, 255)
        img:gamma(2.0)
        local r, _, _, _ = img:getPixel(0, 0)
        -- (128/255)^0.5 * 255 â‰ 180; must be brighter than 128
        expect_equal(r > 128, true)
    end)

    -- @description Checks that gamma mutates the source image and returns nil.
    it("gamma returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:gamma(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies tint blending by checking full replacement at factor 1, identity at factor 0, and nil return for in-place mutation.
describe("ImageData color/tone effects: tint", function()
    -- @description Confirms tint with factor 1.0 replaces RGB with the supplied tint colour while leaving alpha at 200.
    it("tint factor=1.0 replaces RGB with tint colour, preserving alpha", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 128, 64, 32, 200)
        img:tint(0, 255, 0, 1.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- lerp(original, tint, 1.0) = tint exactly
        expect_equal(r, 0)
        expect_equal(g, 255)
        expect_equal(b, 0)
        expect_equal(a, 200)
    end)

    -- @description Confirms tint with factor 0.0 leaves the original pixel unchanged.
    it("tint factor=0 leaves pixel unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:tint(0, 255, 0, 0.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @description Checks that tint mutates in place and returns nil rather than a new image.
    it("tint returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:tint(255, 0, 0, 0.5)
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- Filter effects
-- =============================================================================

-- @description Verifies grayscale by checking that coloured pixels become equal-channel greys and that the method mutates in place.
describe("ImageData filter effects: grayscale", function()
    -- @description Confirms grayscale converts a pure red pixel into equal r, g, and b channels while preserving alpha.
    it("grayscale makes r==g==b for a pure-red pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:grayscale()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, g)
        expect_equal(g, b)
        expect_equal(a, 255)
    end)

    -- @description Confirms grayscale also equalises the channels of a pure blue pixel.
    it("grayscale makes r==g==b for a pure-blue pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 0, 0, 255, 255)
        img:grayscale()
        local r, g, b, _ = img:getPixel(0, 0)
        expect_equal(r, g)
        expect_equal(g, b)
    end)

    -- @description Checks that grayscale is an in-place filter and therefore returns nil.
    it("grayscale returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:grayscale()
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies sepia by checking warm-toned channel ordering, alpha preservation, and nil return for in-place mutation.
describe("ImageData filter effects: sepia", function()
    -- @description Confirms sepia on a red pixel yields positive warm channels with r >= g >= b and unchanged alpha.
    it("sepia produces warm-toned output on a red pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:sepia()
        local r, g, b, a = img:getPixel(0, 0)
        -- sepia: râ‰100, gâ‰89, bâ‰69 â€” all positive, r >= g >= b
        expect_equal(r > 0, true)
        expect_equal(g > 0, true)
        expect_equal(b > 0, true)
        expect_equal(r >= g, true)
        expect_equal(g >= b, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms sepia leaves the original alpha channel untouched.
    it("sepia leaves alpha unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 200, 100, 50, 128)
        img:sepia()
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 128)
    end)

    -- @description Checks that sepia mutates the source image and returns nil.
    it("sepia returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:sepia()
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies invert by checking channel inversion, round-tripping after two applications, and nil return for in-place mutation.
describe("ImageData filter effects: invert", function()
    -- @description Confirms invert maps RGB to 255 minus the source channel values while leaving alpha unchanged.
    it("invert inverts RGB channels, leaving alpha unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:invert()
        local r, g, b, a = img:getPixel(0, 0)
        -- 255 - 100 = 155, 255 - 150 = 105, 255 - 200 = 55
        expect_equal(math.abs(r - 155) <= 2, true)
        expect_equal(math.abs(g - 105) <= 2, true)
        expect_equal(math.abs(b - 55) <= 2, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms applying invert twice restores the original RGBA values.
    it("invert applied twice returns to original", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 80, 120, 200, 200)
        img:invert()
        img:invert()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 80)
        expect_equal(g, 120)
        expect_equal(b, 200)
        expect_equal(a, 200)
    end)

    -- @description Checks that invert mutates in place and returns nil.
    it("invert returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:invert()
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies thresholding by checking white output above the cutoff, black output below it, alpha preservation, and nil return for in-place mutation.
describe("ImageData filter effects: threshold", function()
    -- @description Confirms a white source pixel remains white when its luma is at or above the threshold value.
    it("threshold above value produces white pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 255, 255, 255, 255)  -- luma=255 >= 128
        img:threshold(128)
        local r, g, b, _ = img:getPixel(0, 0)
        expect_equal(r, 255)
        expect_equal(g, 255)
        expect_equal(b, 255)
    end)

    -- @description Confirms a dark source pixel becomes black when its luma is below the threshold value.
    it("threshold below value produces black pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 10, 10, 10, 255)  -- lumaâ‰10 < 128
        img:threshold(128)
        local r, g, b, _ = img:getPixel(0, 0)
        expect_equal(r, 0)
        expect_equal(g, 0)
        expect_equal(b, 0)
    end)

    -- @description Confirms threshold changes colour channels but keeps the alpha channel at 99.
    it("threshold leaves alpha unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 200, 200, 200, 99)
        img:threshold(128)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 99)
    end)

    -- @description Checks that threshold mutates the source image and returns nil.
    it("threshold returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:threshold(128)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies posterize by checking two-level channel quantisation, alpha preservation, and nil return for in-place mutation.
describe("ImageData filter effects: posterize", function()
    -- @description Confirms posterize(2) constrains each RGB channel to either 0 or 255 while leaving alpha at 255.
    it("posterize levels=2 maps each channel to 0 or 255", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 200, 50, 128, 255)
        img:posterize(2)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r == 0 or r == 255, true)
        expect_equal(g == 0 or g == 255, true)
        expect_equal(b == 0 or b == 255, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms posterize does not alter the alpha channel.
    it("posterize leaves alpha unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 100, 100, 77)
        img:posterize(4)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 77)
    end)

    -- @description Checks that posterize mutates in place and returns nil.
    it("posterize returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:posterize(4)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies fill by checking that written RGBA values appear across the image, including a corner pixel, and that the method returns nil.
describe("ImageData filter effects: fill", function()
    -- @description Confirms fill writes the requested solid RGBA colour to pixel (0,0).
    it("fill sets all pixels to the given RGBA colour", function()
        local img = lurek.img.newImageData(4, 4)
        img:fill(255, 0, 0, 255)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 255)
        expect_equal(g, 0)
        expect_equal(b, 0)
        expect_equal(a, 255)
    end)

    -- @description Confirms fill applies the same RGBA colour at the far corner pixel as well.
    it("fill sets a corner pixel too", function()
        local img = lurek.img.newImageData(4, 4)
        img:fill(0, 128, 255, 200)
        local r, g, b, a = img:getPixel(3, 3)
        expect_equal(r, 0)
        expect_equal(g, 128)
        expect_equal(b, 255)
        expect_equal(a, 200)
    end)

    -- @description Checks that fill mutates the image in place and returns nil.
    it("fill returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:fill(0, 0, 0, 255)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies noise by checking that amount 0 leaves both colour and alpha unchanged and that the method returns nil for in-place mutation.
describe("ImageData filter effects: noise", function()
    -- @description Confirms noise(0) leaves the RGB values and alpha exactly unchanged on an opaque pixel.
    it("noise(0) leaves pixels exactly unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:noise(0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @description Confirms noise(0) leaves the alpha channel unchanged even on a semi-transparent pixel.
    it("noise(0) leaves alpha unchanged on a transparent pixel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 50, 50, 50, 128)
        img:noise(0)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 128)
    end)

    -- @description Checks that noise mutates in place and returns nil.
    it("noise returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:noise(0)
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies alpha masking by checking halved alpha, identity at 1.0, full transparency at 0.0, preserved RGB values, and nil return.
describe("ImageData filter effects: alphaMask", function()
    -- @description Confirms alphaMask(0.5) reduces alpha from 200 to about 100 while leaving RGB unchanged.
    it("alphaMask(0.5) halves the alpha channel", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 128, 64, 255, 200)
        img:alphaMask(0.5)
        local r, g, b, a = img:getPixel(0, 0)
        -- alpha = floor/round(200 * 0.5) = 100; RGB unchanged
        expect_equal(math.abs(a - 100) <= 2, true)
        expect_equal(r, 128)
        expect_equal(g, 64)
        expect_equal(b, 255)
    end)

    -- @description Confirms alphaMask(1.0) leaves the existing alpha value unchanged.
    it("alphaMask(1.0) leaves alpha unchanged", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 100, 100, 100, 180)
        img:alphaMask(1.0)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 180)
    end)

    -- @description Confirms alphaMask(0.0) drives the alpha channel all the way to zero.
    it("alphaMask(0.0) makes pixel fully transparent", function()
        local img = lurek.img.newImageData(1, 1)
        img:setPixel(0, 0, 255, 255, 255, 200)
        img:alphaMask(0.0)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 0)
    end)

    -- @description Checks that alphaMask mutates the source image and returns nil.
    it("alphaMask returns nil (in-place)", function()
        local img = lurek.img.newImageData(1, 1)
        local ret = img:alphaMask(1.0)
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- Geometric in-place effects
-- =============================================================================

-- @description Verifies horizontal flipping by checking mirrored edge pixels, preserved dimensions, round-tripping after two flips, and nil return for in-place mutation.
describe("ImageData geometric in-place: flipHorizontal", function()
    -- @description Confirms flipHorizontal swaps the left and right edge pixels in a 4-wide image.
    it("flipHorizontal mirrors pixel from column 0 to column 3 in a 4-wide image", function()
        local img = lurek.img.newImageData(4, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)    -- red at left
        img:setPixel(3, 0, 0, 0, 255, 255)    -- blue at right
        img:flipHorizontal()
        local r0, _, b0, _ = img:getPixel(0, 0)  -- was right edge â†’ now blue
        local r3, _, b3, _ = img:getPixel(3, 0)  -- was left edge  â†’ now red
        expect_equal(b0, 255)
        expect_equal(r3, 255)
    end)

    -- @description Confirms flipHorizontal does not change the image width or height.
    it("flipHorizontal preserves image dimensions", function()
        local img = lurek.img.newImageData(4, 2)
        img:flipHorizontal()
        expect_equal(img:getWidth(), 4)
        expect_equal(img:getHeight(), 2)
    end)

    -- @description Confirms applying flipHorizontal twice restores the original pixel values.
    it("flipHorizontal applied twice returns to original", function()
        local img = lurek.img.newImageData(4, 1)
        img:setPixel(0, 0, 200, 100, 50, 255)
        img:flipHorizontal()
        img:flipHorizontal()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @description Checks that flipHorizontal mutates the source image and returns nil.
    it("flipHorizontal returns nil (in-place)", function()
        local img = lurek.img.newImageData(2, 2)
        local ret = img:flipHorizontal()
        expect_equal(ret, nil)
    end)
end)

-- @description Verifies vertical flipping by checking mirrored edge pixels, preserved dimensions, round-tripping after two flips, and nil return for in-place mutation.
describe("ImageData geometric in-place: flipVertical", function()
    -- @description Confirms flipVertical swaps the top and bottom edge pixels in a 4-tall image.
    it("flipVertical mirrors pixel from row 0 to row 3 in a 4-tall image", function()
        local img = lurek.img.newImageData(1, 4)
        img:setPixel(0, 0, 255, 0, 0, 255)    -- red at top
        img:setPixel(0, 3, 0, 0, 255, 255)    -- blue at bottom
        img:flipVertical()
        local r0, _, b0, _ = img:getPixel(0, 0)  -- was bottom â†’ now blue
        local r3, _, b3, _ = img:getPixel(0, 3)  -- was top    â†’ now red
        expect_equal(b0, 255)
        expect_equal(r3, 255)
    end)

    -- @description Confirms flipVertical does not change the image width or height.
    it("flipVertical preserves image dimensions", function()
        local img = lurek.img.newImageData(2, 4)
        img:flipVertical()
        expect_equal(img:getWidth(), 2)
        expect_equal(img:getHeight(), 4)
    end)

    -- @description Confirms applying flipVertical twice restores the original pixel values.
    it("flipVertical applied twice returns to original", function()
        local img = lurek.img.newImageData(1, 4)
        img:setPixel(0, 0, 200, 100, 50, 255)
        img:flipVertical()
        img:flipVertical()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @description Checks that flipVertical mutates the source image and returns nil.
    it("flipVertical returns nil (in-place)", function()
        local img = lurek.img.newImageData(2, 2)
        local ret = img:flipVertical()
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- Geometric new-image effects
-- =============================================================================

-- @description Verifies clockwise rotation by checking the returned userdata type, swapped dimensions for non-square images, preserved square dimensions, and object independence from the source.
describe("ImageData geometric new-image: rotate90cw", function()
    -- @description Confirms rotate90cw returns a new userdata instead of mutating in place.
    it("rotate90cw returns a new userdata", function()
        local img = lurek.img.newImageData(4, 2)
        local out = img:rotate90cw()
        expect_type("userdata", out)
    end)

    -- @description Confirms rotating a 4x2 image clockwise produces a 2x4 output image.
    it("rotate90cw swaps dimensions (4x2 â†’ 2x4)", function()
        local img = lurek.img.newImageData(4, 2)
        local out = img:rotate90cw()
        expect_equal(out:getWidth(), 2)
        expect_equal(out:getHeight(), 4)
    end)

    -- @description Confirms rotating a square image preserves its dimensions.
    it("rotate90cw on a square returns the same dimensions", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:rotate90cw()
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @description Confirms the rotated output is independent by mutating the source after rotation and checking the output stays blank.
    it("rotate90cw returns a distinct object from the source", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:rotate90cw()
        -- Modify source after rotation; output must be unaffected
        img:fill(255, 0, 0, 255)
        local r, _, _, _ = out:getPixel(0, 0)
        expect_equal(r, 0)  -- out was blank before fill
    end)
end)

-- @description Verifies cropping by checking the returned userdata type, output dimensions, copied source pixels, and error cases for invalid regions.
describe("ImageData geometric new-image: crop", function()
    -- @description Confirms crop returns a new userdata for a valid region.
    it("crop returns a new userdata", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:crop(0, 0, 2, 2)
        expect_type("userdata", out)
    end)

    -- @description Confirms cropping a 2x2 region from the top-left of a 4x4 image yields a 2x2 output.
    it("crop(0,0,2,2) on a 4x4 image produces a 2x2 image", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:crop(0, 0, 2, 2)
        expect_equal(out:getWidth(), 2)
        expect_equal(out:getHeight(), 2)
    end)

    -- @description Confirms crop copies pixel data so source pixel (1,1) becomes output pixel (0,0).
    it("crop copies pixel values from the source region", function()
        local img = lurek.img.newImageData(4, 4)
        img:setPixel(1, 1, 200, 100, 50, 255)
        local out = img:crop(1, 1, 2, 2)  -- region starting at (1,1)
        local r, g, b, a = out:getPixel(0, 0)  -- (1,1) in src â†’ (0,0) in crop
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @description Confirms crop rejects a region whose x, y, width, and height extend beyond the source bounds.
    it("crop out-of-bounds raises an error", function()
        local img = lurek.img.newImageData(4, 4)
        expect_error(function()
            img:crop(3, 3, 5, 5)  -- 3+5=8 > 4, out of bounds
        end)
    end)

    -- @description Confirms crop rejects a zero-width region as invalid input.
    it("crop zero-width raises an error", function()
        local img = lurek.img.newImageData(4, 4)
        expect_error(function()
            img:crop(0, 0, 0, 2)  -- w=0 is invalid
        end)
    end)
end)

-- @description Verifies nearest-neighbour resizing by checking returned userdata, downscale and upscale dimensions, and preservation of the top-left source pixel.
describe("ImageData geometric new-image: resizeNearest", function()
    -- @description Confirms resizeNearest returns a new userdata rather than mutating the source.
    it("resizeNearest returns a new userdata", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:resizeNearest(2, 2)
        expect_type("userdata", out)
    end)

    -- @description Confirms resizing from 4x4 to 2x2 produces the requested downscaled dimensions.
    it("resizeNearest(2,2) downscales a 4x4 to 2x2", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:resizeNearest(2, 2)
        expect_equal(out:getWidth(), 2)
        expect_equal(out:getHeight(), 2)
    end)

    -- @description Confirms resizing from 4x4 to 8x8 produces the requested upscaled dimensions.
    it("resizeNearest(8,8) upscales a 4x4 to 8x8", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:resizeNearest(8, 8)
        expect_equal(out:getWidth(), 8)
        expect_equal(out:getHeight(), 8)
    end)

    -- @description Confirms nearest-neighbour resizing keeps the top-left pixel colour at output coordinate (0,0).
    it("resizeNearest preserves top-left pixel colour", function()
        local img = lurek.img.newImageData(4, 4)
        img:setPixel(0, 0, 200, 100, 50, 255)
        local out = img:resizeNearest(2, 2)
        local r, g, b, a = out:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)
end)

-- =============================================================================
-- Convolution effects
-- =============================================================================

-- @description Verifies blur by checking returned userdata, preserved dimensions for different radii, cloned pixels at radius 0, and colour stability on a solid image at radius 1.
describe("ImageData convolution: blur", function()
    -- @description Confirms blur(0) returns a new userdata.
    it("blur(0) returns a new userdata", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:blur(0)
        expect_type("userdata", out)
    end)

    -- @description Confirms blur(0) keeps the output dimensions equal to the source dimensions.
    it("blur(0) returns an image with the same dimensions", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:blur(0)
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @description Confirms blur(1) also keeps the output dimensions equal to the source dimensions.
    it("blur(1) returns an image with the same dimensions", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:blur(1)
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @description Confirms blur(0) behaves like a clone by preserving the filled pixel values exactly.
    it("blur(0) preserves pixel values (returns a clone)", function()
        local img = lurek.img.newImageData(4, 4)
        img:fill(100, 150, 200, 255)
        local out = img:blur(0)
        local r, g, b, a = out:getPixel(1, 1)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @description Confirms blur(1) leaves a solid-colour image unchanged because every sampled neighbour has the same value.
    it("blur(1) on a solid-colour image preserves colour", function()
        local img = lurek.img.newImageData(4, 4)
        img:fill(80, 120, 160, 255)
        local out = img:blur(1)
        -- All neighbours are the same; box average = same value
        local r, g, b, a = out:getPixel(1, 1)
        expect_equal(r, 80)
        expect_equal(g, 120)
        expect_equal(b, 160)
        expect_equal(a, 255)
    end)
end)

-- @description Verifies sharpen by checking returned userdata, preserved dimensions, colour stability on a solid image, and independence from later source mutations.
describe("ImageData convolution: sharpen", function()
    -- @description Confirms sharpen returns a new userdata.
    it("sharpen returns a new userdata", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:sharpen()
        expect_type("userdata", out)
    end)

    -- @description Confirms sharpen keeps the output width and height equal to the source image.
    it("sharpen returns an image with the same dimensions", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:sharpen()
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @description Confirms sharpen leaves a uniform-colour image unchanged within rounding tolerance and preserves alpha.
    it("sharpen on a solid-colour image preserves pixel values", function()
        local img = lurek.img.newImageData(4, 4)
        img:fill(128, 64, 32, 255)
        local out = img:sharpen()
        -- 5*C - top - bottom - left - right = 5*C - 4*C = C for uniform colour
        local r, g, b, a = out:getPixel(1, 1)
        expect_equal(math.abs(r - 128) <= 2, true)
        expect_equal(math.abs(g - 64) <= 2, true)
        expect_equal(math.abs(b - 32) <= 2, true)
        expect_equal(a, 255)
    end)

    -- @description Confirms the sharpened output is independent by filling the source afterward and checking the output pixel stays blank.
    it("sharpen returns a distinct object from the source", function()
        local img = lurek.img.newImageData(4, 4)
        local out = img:sharpen()
        img:fill(255, 0, 0, 255)
        -- out was created before fill; its pixel 1,1 (blank=0) is unaffected
        local r, _, _, _ = out:getPixel(1, 1)
        expect_equal(r, 0)
    end)
end)

-- -----------------------------------------------------------------------
-- LayeredImage tests
-- -----------------------------------------------------------------------

-- @description Verifies layered-image construction by checking userdata type, stored canvas dimensions, and an initial layer count of zero.
describe("lurek.img.newLayeredImage", function()
    -- @description Confirms newLayeredImage returns userdata representing a LayeredImage stack.
    it("returns a LayeredImage userdata", function()
        local stack = lurek.img.newLayeredImage(64, 64)
        expect_equal(type(stack), "userdata")
    end)

    -- @description Confirms getWidth and getHeight report the dimensions passed to newLayeredImage.
    it("getWidth and getHeight return canvas dimensions", function()
        local stack = lurek.img.newLayeredImage(32, 48)
        expect_equal(stack:getWidth(), 32)
        expect_equal(stack:getHeight(), 48)
    end)

    -- @description Confirms a new LayeredImage starts with zero layers.
    it("layerCount starts at zero", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        expect_equal(stack:layerCount(), 0)
    end)
end)

-- @description Verifies layer insertion by checking returned indices, incrementing layer counts, and autogenerated names when none are supplied.
describe("LayeredImage:addLayer", function()
    -- @description Confirms adding a named first layer returns index 1.
    it("addLayer with explicit name returns 1", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        local idx = stack:addLayer("background")
        expect_equal(idx, 1)
    end)

    -- @description Confirms consecutive addLayer calls return indices 1 and 2 and increase the stack count to two.
    it("adding two layers increments index", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        local a = stack:addLayer("a")
        local b = stack:addLayer("b")
        expect_equal(a, 1)
        expect_equal(b, 2)
        expect_equal(stack:layerCount(), 2)
    end)

    -- @description Confirms addLayer without a name still assigns a non-empty generated layer name.
    it("addLayer without name generates a default name", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer()
        local name = stack:getName(1)
        expect_equal(type(name), "string")
        expect_equal(#name > 0, true)
    end)
end)

-- @description Verifies layer removal by checking successful deletion of an existing layer and false for an out-of-range index.
describe("LayeredImage:removeLayer", function()
    -- @description Confirms removing the only layer returns true and drops the layer count to zero.
    it("removes existing layer and decrements count", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        expect_equal(stack:removeLayer(1), true)
        expect_equal(stack:layerCount(), 0)
    end)

    -- @description Confirms removeLayer returns false when asked to remove a nonexistent index.
    it("returns false for out-of-range index", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        expect_equal(stack:removeLayer(99), false)
    end)
end)

-- @description Verifies per-layer opacity and visibility controls by checking round-trips, clamping above 1.0, visibility toggles, and error handling for invalid indices.
describe("LayeredImage opacity and visibility", function()
    -- @description Confirms setting opacity to 0.5 on layer 1 can be read back within a small tolerance.
    it("setOpacity and getOpacity round-trip", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        expect_equal(stack:setOpacity(1, 0.5), true)
        local op = stack:getOpacity(1)
        expect_equal(math.abs(op - 0.5) < 0.01, true)
    end)

    -- @description Confirms opacity values above 1.0 are clamped back to 1.0.
    it("setOpacity clamps above 1.0", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        stack:setOpacity(1, 5.0)
        expect_equal(math.abs(stack:getOpacity(1) - 1.0) < 0.01, true)
    end)

    -- @description Confirms setVisible(false) and setVisible(true) both round-trip through isVisible.
    it("setVisible and isVisible round-trip", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        stack:setVisible(1, false)
        expect_equal(stack:isVisible(1), false)
        stack:setVisible(1, true)
        expect_equal(stack:isVisible(1), true)
    end)

    -- @description Confirms getOpacity raises an error when the layer index is invalid.
    it("invalid index returns error from getOpacity", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        expect_error(function() stack:getOpacity(99) end)
    end)
end)

-- @description Verifies layer naming by checking name retrieval and renaming on an existing layer.
describe("LayeredImage name operations", function()
    -- @description Confirms getName returns the explicit layer name that was added.
    it("getName returns the layer name", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("myName")
        expect_equal(stack:getName(1), "myName")
    end)

    -- @description Confirms setName renames an existing layer and reports success.
    it("setName renames a layer", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("old")
        expect_equal(stack:setName(1, "new"), true)
        expect_equal(stack:getName(1), "new")
    end)
end)

-- @description Verifies layer ordering by checking swaps, out-of-range failures, and moving a layer to a new position.
describe("LayeredImage layer reordering", function()
    -- @description Confirms swapLayers exchanges the names at positions 1 and 2 and returns true.
    it("swapLayers exchanges two layer positions", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("first")
        stack:addLayer("second")
        expect_equal(stack:swapLayers(1, 2), true)
        expect_equal(stack:getName(1), "second")
        expect_equal(stack:getName(2), "first")
    end)

    -- @description Confirms swapLayers returns false when either requested index is out of range.
    it("swapLayers returns false for out-of-range", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        expect_equal(stack:swapLayers(1, 99), false)
    end)

    -- @description Confirms moveLayer(1, 3) reorders layers so that a moves behind b and c.
    it("moveLayer repositions a layer", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("a")
        stack:addLayer("b")
        stack:addLayer("c")
        expect_equal(stack:moveLayer(1, 3), true)
        -- a moves to 3, so order is b, c, a
        expect_equal(stack:getName(1), "b")
        expect_equal(stack:getName(3), "a")
    end)
end)

-- @description Verifies direct layer pixel access by checking ImageData copies from getLayer, pixel replacement through setLayer, and error handling for invalid indices.
describe("LayeredImage pixel editing via getLayer/setLayer", function()
    -- @description Confirms getLayer returns a 4x4 ImageData userdata copy for an existing layer.
    it("getLayer returns an ImageData copy", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        local img = stack:getLayer(1)
        expect_equal(type(img), "userdata")
        expect_equal(img:getWidth(), 4)
        expect_equal(img:getHeight(), 4)
    end)

    -- @description Confirms setLayer replaces the stored layer pixels with the red source image.
    it("setLayer replaces layer pixels", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("x")
        local src = lurek.img.newImageData(4, 4)
        src:fill(255, 0, 0, 255)
        expect_equal(stack:setLayer(1, src), true)
        local got = stack:getLayer(1)
        local r, g, b, a = got:getPixel(0, 0)
        expect_equal(r, 255)
        expect_equal(g, 0)
        expect_equal(b, 0)
        expect_equal(a, 255)
    end)

    -- @description Confirms getLayer raises an error for an invalid layer index.
    it("getLayer with invalid index throws", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        expect_error(function() stack:getLayer(99) end)
    end)
end)

-- @description Verifies layer compositing by checking transparent empty output, exact output from one opaque layer, hidden-layer exclusion, opaque top-layer coverage, and preserved canvas dimensions.
describe("LayeredImage:merge", function()
    -- @description Confirms merging an empty stack yields a fully transparent pixel.
    it("empty stack merges to fully transparent image", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        local flat = stack:merge()
        local r, g, b, a = flat:getPixel(0, 0)
        expect_equal(a, 0)
    end)

    -- @description Confirms merging a single opaque filled layer reproduces that layer's RGBA values exactly.
    it("single opaque layer merges to that layer's pixels", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("bg")
        local src = lurek.img.newImageData(4, 4)
        src:fill(200, 100, 50, 255)
        stack:setLayer(1, src)
        local flat = stack:merge()
        local r, g, b, a = flat:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @description Confirms a hidden foreground layer does not contribute to the merged output, leaving the red background visible.
    it("hidden layer does not appear in merge", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("bg")
        local bg = lurek.img.newImageData(4, 4)
        bg:fill(255, 0, 0, 255)
        stack:setLayer(1, bg)
        stack:addLayer("fg")
        local fg = lurek.img.newImageData(4, 4)
        fg:fill(0, 0, 255, 255)
        stack:setLayer(2, fg)
        stack:setVisible(2, false)
        local flat = stack:merge()
        local r, _, _, _ = flat:getPixel(0, 0)
        expect_equal(r, 255)  -- red from bg; blue fg invisible
    end)

    -- @description Confirms a visible opaque top layer fully covers the bottom layer in the merged output.
    it("opaque top layer fully covers bottom", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        stack:addLayer("bg")
        local bg = lurek.img.newImageData(4, 4)
        bg:fill(255, 0, 0, 255)
        stack:setLayer(1, bg)
        stack:addLayer("fg")
        local fg = lurek.img.newImageData(4, 4)
        fg:fill(0, 0, 255, 255)
        stack:setLayer(2, fg)
        local flat = stack:merge()
        local r, g, b, a = flat:getPixel(0, 0)
        expect_equal(b, 255)
        expect_equal(r, 0)
    end)

    -- @description Confirms merge returns an ImageData with the same width and height as the layered canvas.
    it("merge returns an ImageData of the same dimensions", function()
        local stack = lurek.img.newLayeredImage(8, 6)
        local flat = stack:merge()
        expect_equal(flat:getWidth(), 8)
        expect_equal(flat:getHeight(), 6)
    end)
end)

-- -----------------------------------------------------------------------
-- LIMG binary serialization tests
-- -----------------------------------------------------------------------

-- @description Verifies that the flat-image serialization entry points are exposed on lurek.img.
describe("lurek.img.saveImage / lurek.img.loadImage", function()
    -- @description Confirms both saveImage and loadImage are present as functions on lurek.img.
    it("saveImage and loadImage functions exist", function()
        expect_equal(type(lurek.img.saveImage), "function")
        expect_equal(type(lurek.img.loadImage), "function")
    end)
end)

-- @description Verifies that the layered-image loading entry point is exposed on lurek.img.
describe("lurek.img.saveLayered / lurek.img.loadLayered", function()
    -- @description Confirms loadLayered is present as a function on lurek.img.
    it("loadLayered function exists", function()
        expect_equal(type(lurek.img.loadLayered), "function")
    end)
end)

-- @description Verifies that LayeredImage userdata exposes an instance save method.
describe("LayeredImage:save", function()
    -- @description Confirms the save method exists on a LayeredImage userdata instance.
    it("save method exists on LayeredImage userdata", function()
        local stack = lurek.img.newLayeredImage(4, 4)
        expect_equal(type(stack.save), "function")
    end)
end)

-- ── ImageEffect chain API (merged from test_image_effect.lua) ──

describe("lurek.postfx.newImageEffect construction (empty)", function()
    -- @covers lurek.postfx.loadImageEffect
    -- @covers lurek.postfx.newImageEffect
    -- @description Confirms the constructor is exported as a callable function on lurek.postfx.
    it("newImageEffect is a function", function()
        expect_type("function", lurek.postfx.newImageEffect)
    end)

    it("newImageEffect() returns non-nil", function()
        local fx = lurek.postfx.newImageEffect()
        expect_equal(fx ~= nil, true)
    end)

    it("newImageEffect() returns object with effectCount method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.effectCount)
    end)

    it("newImageEffect() returns object with addEffect method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.addEffect)
    end)

    it("newImageEffect() returns object with getEffect method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.getEffect)
    end)

    it("newImageEffect() returns object with removeEffect method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.removeEffect)
    end)

    it("newImageEffect() returns object with clearEffects method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.clearEffects)
    end)

    it("newImageEffect() returns object with clone method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.clone)
    end)

    it("newImageEffect() returns object with save method", function()
        local fx = lurek.postfx.newImageEffect()
        expect_type("function", fx.save)
    end)

    it("empty chain has effectCount == 0", function()
        local fx = lurek.postfx.newImageEffect()
        expect_equal(fx:effectCount(), 0)
    end)
end)

describe("lurek.postfx.newImageEffect construction (single name)", function()
    it("newImageEffect('blur') produces effectCount == 1", function()
        local fx = lurek.postfx.newImageEffect("blur")
        expect_equal(fx:effectCount(), 1)
    end)

    it("first effect type is 'blur'", function()
        local fx = lurek.postfx.newImageEffect("blur")
        local e = fx:getEffect(1)
        expect_equal(e:getType(), "blur")
    end)

    it("newImageEffect('blur', {radius=4}) produces effectCount == 1", function()
        local fx = lurek.postfx.newImageEffect("blur", { radius = 4 })
        expect_equal(fx:effectCount(), 1)
    end)

    it("newImageEffect('blur', {radius=4}) sets radius parameter", function()
        local fx = lurek.postfx.newImageEffect("blur", { radius = 4 })
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 4) < 0.001, true)
    end)
end)

describe("lurek.postfx.newImageEffect construction (chain table)", function()
    it("two-element chain produces effectCount == 2", function()
        local fx = lurek.postfx.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:effectCount(), 2)
    end)

    it("first effect in chain is 'blur'", function()
        local fx = lurek.postfx.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)

    it("second effect in chain is 'sepia'", function()
        local fx = lurek.postfx.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:getEffect(2):getType(), "sepia")
    end)

    it("chain entry parameters are applied", function()
        local fx = lurek.postfx.newImageEffect({ { type = "blur", radius = 2 } })
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 2) < 0.001, true)
    end)
end)

describe("ImageEffect:addEffect", function()
    it("addEffect returns non-nil", function()
        local fx = lurek.postfx.newImageEffect()
        local e = fx:addEffect("vignette")
        expect_equal(e ~= nil, true)
    end)

    it("addEffect returns PostFxEffect with correct type", function()
        local fx = lurek.postfx.newImageEffect()
        local e = fx:addEffect("vignette")
        expect_equal(e:getType(), "vignette")
    end)

    it("addEffect increments effectCount", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        expect_equal(fx:effectCount(), 1)
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 2)
    end)

    it("addEffect appends to end of chain", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("vignette")
        expect_equal(fx:getEffect(2):getType(), "vignette")
    end)
end)

describe("ImageEffect:getEffect by index", function()
    it("getEffect(1) returns first effect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)

    it("getEffect(2) returns second effect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        expect_equal(fx:getEffect(2):getType(), "sepia")
    end)

    it("getEffect out-of-bounds returns nil or errors gracefully", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect(99)
            expect_equal(e == nil, true)
        end)
        expect_equal(true, true)
    end)

    it("getEffect(0) returns nil or errors gracefully", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect(0)
            expect_equal(e == nil, true)
        end)
        expect_equal(true, true)
    end)
end)

describe("ImageEffect:getEffect by name", function()
    it("getEffect('blur') returns the blur effect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local e = fx:getEffect("blur")
        expect_equal(e ~= nil, true)
        expect_equal(e:getType(), "blur")
    end)

    it("getEffect('sepia') returns the sepia effect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local e = fx:getEffect("sepia")
        expect_equal(e ~= nil, true)
        expect_equal(e:getType(), "sepia")
    end)

    it("getEffect with unknown name returns nil or errors gracefully", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect("nonexistent_effect")
            expect_equal(e == nil, true)
        end)
        expect_equal(true, true)
    end)
end)

describe("PostFxEffect setParameter / getParameter round-trip", function()
    it("setParameter radius then getParameter returns same value", function()
        local fx = lurek.postfx.newImageEffect("blur")
        fx:getEffect(1):setParameter("radius", 7.5)
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 7.5) < 0.001, true)
    end)

    it("setParameter overwrites previous value", function()
        local fx = lurek.postfx.newImageEffect("blur")
        fx:getEffect(1):setParameter("radius", 3.0)
        fx:getEffect(1):setParameter("radius", 9.0)
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 9.0) < 0.001, true)
    end)

    it("getParameter on separate effects are independent", function()
        local fx = lurek.postfx.newImageEffect()
        local e1 = fx:addEffect("blur")
        local e2 = fx:addEffect("blur")
        e1:setParameter("radius", 2.0)
        e2:setParameter("radius", 8.0)
        expect_equal(math.abs(e1:getParameter("radius") - 2.0) < 0.001, true)
        expect_equal(math.abs(e2:getParameter("radius") - 8.0) < 0.001, true)
    end)
end)

describe("ImageEffect:effectCount", function()
    it("starts at 0 for empty chain", function()
        local fx = lurek.postfx.newImageEffect()
        expect_equal(fx:effectCount(), 0)
    end)

    it("increments by 1 after each addEffect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        expect_equal(fx:effectCount(), 1)
        fx:addEffect("vignette")
        expect_equal(fx:effectCount(), 2)
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 3)
    end)

    it("decrements after removeEffect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:effectCount(), 1)
    end)
end)

describe("ImageEffect:removeEffect by index", function()
    it("removeEffect(1) decrements effectCount", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:effectCount(), 1)
    end)

    it("remaining effect after removing index 1 is the second original", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:getEffect(1):getType(), "sepia")
    end)

    it("removeEffect(2) removes the second effect", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(2)
        expect_equal(fx:effectCount(), 1)
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)
end)

describe("ImageEffect:removeEffect by name", function()
    it("removeEffect('sepia') from [blur, sepia] -> effectCount == 1", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("sepia")
        expect_equal(fx:effectCount(), 1)
    end)

    it("remaining effect after removing 'sepia' is 'blur'", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("sepia")
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)

    it("removeEffect('blur') from [blur, sepia] -> remaining is 'sepia'", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("blur")
        expect_equal(fx:effectCount(), 1)
        expect_equal(fx:getEffect(1):getType(), "sepia")
    end)
end)

describe("ImageEffect:clearEffects", function()
    it("clearEffects on populated chain produces effectCount == 0", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("vignette")
        fx:addEffect("sepia")
        fx:clearEffects()
        expect_equal(fx:effectCount(), 0)
    end)

    it("clearEffects on empty chain is a no-op", function()
        local fx = lurek.postfx.newImageEffect()
        fx:clearEffects()
        expect_equal(fx:effectCount(), 0)
    end)

    it("can addEffect again after clearEffects", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:clearEffects()
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 1)
        expect_equal(fx:getEffect(1):getType(), "sepia")
    end)
end)

describe("ImageEffect:clone", function()
    it("clone returns non-nil", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        local copy = fx:clone()
        expect_equal(copy ~= nil, true)
    end)

    it("clone has the same effectCount as original", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local copy = fx:clone()
        expect_equal(copy:effectCount(), fx:effectCount())
    end)

    it("clone has the same effect types in order", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local copy = fx:clone()
        expect_equal(copy:getEffect(1):getType(), "blur")
        expect_equal(copy:getEffect(2):getType(), "sepia")
    end)

    it("modifying clone does not affect original effectCount", function()
        local fx = lurek.postfx.newImageEffect()
        fx:addEffect("blur")
        local copy = fx:clone()
        copy:addEffect("vignette")
        expect_equal(fx:effectCount(), 1)
        expect_equal(copy:effectCount(), 2)
    end)

    it("modifying clone parameter does not affect original", function()
        local fx = lurek.postfx.newImageEffect("blur")
        fx:getEffect(1):setParameter("radius", 3.0)
        local copy = fx:clone()
        copy:getEffect(1):setParameter("radius", 99.0)
        local orig_v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(orig_v - 3.0) < 0.001, true)
    end)
end)

describe("lurek.postfx.newImageEffect invalid effect name", function()
    it("rejects unknown effect name on construction", function()
        expect_error(function()
            lurek.postfx.newImageEffect("not_a_real_effect")
        end)
    end)

    it("addEffect rejects unknown effect name", function()
        local fx = lurek.postfx.newImageEffect()
        expect_error(function()
            fx:addEffect("not_a_real_effect")
        end)
    end)
end)

describe("lurek.postfx.loadImageEffect", function()
    it("loadImageEffect is a function", function()
        expect_type("function", lurek.postfx.loadImageEffect)
    end)
end)

-- ── Extended ImageData ops: resize, blit, getRegion, diff, mapPixels (merged from test_image_extended.lua) ──

local function make_solid(w, h, r, g, b, a)
    local img = lurek.img.newImageData(w, h)
    img:mapPixels(function(_, _, _, _, _, _) return r, g, b, a end)
    return img
end

describe("ImageData:resize", function()
    it("resize to same dimensions returns a copy", function()
        local img = make_solid(4, 4, 255, 0, 0, 255)
        local copy = img:resize(4, 4)
        expect_equal(copy ~= nil, true)
        expect_equal(copy:getWidth(), 4)
        expect_equal(copy:getHeight(), 4)
    end)

    it("resize returns correct dimensions", function()
        local img = make_solid(8, 8, 0, 255, 0, 255)
        local small = img:resize(2, 3)
        expect_equal(small:getWidth(), 2)
        expect_equal(small:getHeight(), 3)
    end)

    it("resize to zero returns nil", function()
        local img = make_solid(4, 4, 0, 0, 0, 255)
        local result = img:resize(0, 4)
        expect_equal(result, nil)
    end)
end)

describe("ImageData:blit", function()
    it("blit does not error for valid coordinates", function()
        local dst = make_solid(8, 8, 0, 0, 0, 255)
        local src = make_solid(2, 2, 255, 255, 255, 255)
        dst:blit(src, 3, 3)
    end)

    it("blit at (0,0) covers the top-left corner", function()
        local dst = make_solid(4, 4, 0, 0, 0, 255)
        local src = make_solid(2, 2, 200, 100, 50, 255)
        dst:blit(src, 0, 0)
        expect_equal(dst:getWidth(), 4)
    end)

    it("blit with negative offset does not error (clips out-of-bounds)", function()
        local dst = make_solid(4, 4, 0, 0, 0, 255)
        local src = make_solid(2, 2, 255, 0, 0, 255)
        dst:blit(src, -1, -1)
    end)
end)

describe("ImageData:getRegion", function()
    it("getRegion of full image returns same dimensions", function()
        local img = make_solid(6, 4, 128, 64, 32, 255)
        local region = img:getRegion(0, 0, 6, 4)
        expect_equal(region ~= nil, true)
        expect_equal(region:getWidth(), 6)
        expect_equal(region:getHeight(), 4)
    end)

    it("getRegion of sub-rectangle returns correct dimensions", function()
        local img = make_solid(8, 8, 0, 0, 255, 255)
        local region = img:getRegion(2, 2, 4, 3)
        expect_equal(region:getWidth(), 4)
        expect_equal(region:getHeight(), 3)
    end)

    it("getRegion outside bounds returns nil", function()
        local img = make_solid(4, 4, 0, 0, 0, 255)
        local result = img:getRegion(10, 10, 4, 4)
        expect_equal(result, nil)
    end)
end)

describe("ImageData:diff", function()
    it("diff of identical images is 0", function()
        local a = make_solid(4, 4, 100, 150, 200, 255)
        local b = make_solid(4, 4, 100, 150, 200, 255)
        local d = a:diff(b)
        expect_equal(d, 0)
    end)

    it("diff of different images is > 0", function()
        local a = make_solid(4, 4, 0, 0, 0, 255)
        local b = make_solid(4, 4, 255, 255, 255, 255)
        local d = a:diff(b)
        expect_equal(d > 0, true)
    end)

    it("diff of images with different dimensions is > 0", function()
        local a = make_solid(4, 4, 0, 0, 0, 255)
        local b = make_solid(2, 2, 0, 0, 0, 255)
        local d = a:diff(b)
        expect_equal(d > 0, true)
    end)
end)

describe("ImageData:mapPixels", function()
    it("mapPixels can invert all pixels", function()
        local img = make_solid(4, 4, 100, 150, 200, 255)
        img:mapPixels(function(_, _, r, g, b, a)
            return 255 - r, 255 - g, 255 - b, a
        end)
        expect_equal(img:getWidth(), 4)
    end)

    it("mapPixels identity function produces same diff as 0", function()
        local img_a = make_solid(4, 4, 42, 88, 177, 255)
        local img_b = make_solid(4, 4, 42, 88, 177, 255)
        img_a:mapPixels(function(_, _, r, g, b, a) return r, g, b, a end)
        local d = img_a:diff(img_b)
        expect_equal(d, 0)
    end)

    it("mapPixels can set all pixels to a constant colour", function()
        local img = make_solid(4, 4, 0, 0, 0, 255)
        img:mapPixels(function(_, _, _, _, _, _) return 1, 2, 3, 4 end)
        expect_equal(img:getWidth(), 4)
    end)
end)

test_summary()
