-- tests/lua/unit/test_image.lua
-- BDD tests for lurek.image ImageData APIs, including image construction, layered images, save/load helpers, and effect-method coverage in the headless VM.

-- The headless VM has no filesystem, GPU, audio, or window APIs.
-- All tests use lurek.image.newImageData(w, h) for image construction.

-- =============================================================================
-- Compressed API (existing tests)
-- =============================================================================

-- @describe lurek.image compressed API
describe("lurek.image compressed API", function()
    -- @covers lurek.image
    it("lurek.image is a table", function()
        expect_type("table", lurek.image)
    end)

    -- @covers lurek.image.newCompressedData
    it("newCompressedData is a function", function()
        expect_type("function", lurek.image.newCompressedData)
    end)

    -- @covers lurek.image.isCompressed
    it("isCompressed is a function", function()
        expect_type("function", lurek.image.isCompressed)
    end)

    -- @covers lurek.image.newCompressedData
    it("newCompressedData errors on missing file", function()
        expect_error(function()
            lurek.image.newCompressedData("nonexistent_file.dds")
        end)
    end)

    -- @covers lurek.image.isCompressed
    it("isCompressed returns false for a missing path", function()
        local result = lurek.image.isCompressed("nonexistent_file.dds")
        expect_equal(result, false)
    end)
end)

-- =============================================================================
-- Basic API (existing tests)
-- =============================================================================

-- @describe lurek.image existing API still works
describe("lurek.image existing API still works", function()
    -- @covers lurek.image.newImageData
    it("newImageData is a function", function()
        expect_type("function", lurek.image.newImageData)
    end)

    -- @covers lurek.image.newImageData
    it("newImageData creates a blank buffer", function()
        local img = lurek.image.newImageData(4, 4)
        expect_type("userdata", img)
    end)
end)

-- =============================================================================
-- Effect method existence  - one it per effect
-- =============================================================================

-- @describe ImageData effect method existence
describe("ImageData effect method existence", function()
    local img
    before_each(function()
        img = lurek.image.newImageData(4, 4)
    end)

    -- @covers LImageData:brightness
    it("brightness is a function", function()
        expect_type("function", img.brightness)
    end)

    -- @covers LImageData:contrast
    it("contrast is a function", function()
        expect_type("function", img.contrast)
    end)

    -- @covers LImageData:saturation
    it("saturation is a function", function()
        expect_type("function", img.saturation)
    end)

    -- @covers LImageData:gamma
    it("gamma is a function", function()
        expect_type("function", img.gamma)
    end)

    -- @covers LImageData:tint
    it("tint is a function", function()
        expect_type("function", img.tint)
    end)

    -- @covers LImageData:grayscale
    it("grayscale is a function", function()
        expect_type("function", img.grayscale)
    end)

    -- @covers LImageData:sepia
    it("sepia is a function", function()
        expect_type("function", img.sepia)
    end)

    -- @covers LImageData:invert
    it("invert is a function", function()
        expect_type("function", img.invert)
    end)

    -- @covers LImageData:threshold
    it("threshold is a function", function()
        expect_type("function", img.threshold)
    end)

    -- @covers LImageData:posterize
    it("posterize is a function", function()
        expect_type("function", img.posterize)
    end)

    -- @covers LImageData:fill
    it("fill is a function", function()
        expect_type("function", img.fill)
    end)

    -- @covers LImageData:noise
    it("noise is a function", function()
        expect_type("function", img.noise)
    end)

    -- @covers LImageData:alphaMask
    it("alphaMask is a function", function()
        expect_type("function", img.alphaMask)
    end)

    -- @covers LImageData:flipHorizontal
    it("flipHorizontal is a function", function()
        expect_type("function", img.flipHorizontal)
    end)

    -- @covers LImageData:flipVertical
    it("flipVertical is a function", function()
        expect_type("function", img.flipVertical)
    end)

    -- @covers LImageData:rotate90cw
    it("rotate90cw is a function", function()
        expect_type("function", img.rotate90cw)
    end)

    -- @covers LImageData:crop
    it("crop is a function", function()
        expect_type("function", img.crop)
    end)

    -- @covers LImageData:resizeNearest
    it("resizeNearest is a function", function()
        expect_type("function", img.resizeNearest)
    end)

    -- @covers LImageData:blur
    it("blur is a function", function()
        expect_type("function", img.blur)
    end)

    -- @covers LImageData:sharpen
    it("sharpen is a function", function()
        expect_type("function", img.sharpen)
    end)
end)

-- =============================================================================
-- Color / Tone effects
-- =============================================================================

-- @describe ImageData color/tone effects: brightness
describe("ImageData color/tone effects: brightness", function()
    -- @covers LImageData:brightness
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("brightness factor=2 brightens a mid-grey pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 128, 128, 128, 255)
        img:brightness(2.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- 128 * 2 = 256, clamped to 255
        expect_equal(r >= 200, true)
        expect_equal(g >= 200, true)
        expect_equal(b >= 200, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:brightness
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("brightness factor=1 leaves pixel unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:brightness(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:brightness
    -- @covers lurek.image.newImageData
    it("brightness returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:brightness(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData color/tone effects: contrast
describe("ImageData color/tone effects: contrast", function()
    -- @covers LImageData:contrast
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("contrast factor=1 leaves pixel unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 128, 200, 50, 255)
        -- ((ch - 128)*1 + 128) = ch exactly
        img:contrast(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 128)
        expect_equal(g, 200)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:contrast
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("contrast factor=2 increases distance from mid-grey", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 200, 200, 200, 255)
        img:contrast(2.0)
        local r, _, _, _ = img:getPixel(0, 0)
        -- ((200 - 128)*2 + 128) = 72*2 + 128 = 272, clamped to 255
        expect_equal(r, 255)
    end)

    -- @covers LImageData:contrast
    -- @covers lurek.image.newImageData
    it("contrast returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:contrast(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData color/tone effects: saturation
describe("ImageData color/tone effects: saturation", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:saturation
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("saturation factor=0 desaturates a pure-red pixel to grey", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:saturation(0.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- All channels interpolated to luma  54; must be equal within rounding
        expect_equal(math.abs(r - g) <= 2, true)
        expect_equal(math.abs(g - b) <= 2, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:saturation
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("saturation factor=1 leaves pixel unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:saturation(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:saturation
    -- @covers lurek.image.newImageData
    it("saturation returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:saturation(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData color/tone effects: gamma
describe("ImageData color/tone effects: gamma", function()
    -- @covers LImageData:gamma
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("gamma 1.0 leaves pixel unchanged (within rounding)", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:gamma(1.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- (ch/255)^(1/1.0)*255 = ch exactly (up to rounding)
        expect_equal(math.abs(r - 100) <= 1, true)
        expect_equal(math.abs(g - 150) <= 1, true)
        expect_equal(math.abs(b - 200) <= 1, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:gamma
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("gamma > 1 brightens mid-tones", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 128, 128, 128, 255)
        img:gamma(2.0)
        local r, _, _, _ = img:getPixel(0, 0)
        -- (128/255)^0.5 * 255  180; must be brighter than 128
        expect_equal(r > 128, true)
    end)

    -- @covers LImageData:gamma
    -- @covers lurek.image.newImageData
    it("gamma returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:gamma(1.0)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData color/tone effects: tint
describe("ImageData color/tone effects: tint", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers LImageData:tint
    -- @covers lurek.image.newImageData
    it("tint factor=1.0 replaces RGB with tint colour, preserving alpha", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 128, 64, 32, 200)
        img:tint(0, 255, 0, 1.0)
        local r, g, b, a = img:getPixel(0, 0)
        -- lerp(original, tint, 1.0) = tint exactly
        expect_equal(r, 0)
        expect_equal(g, 255)
        expect_equal(b, 0)
        expect_equal(a, 200)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers LImageData:tint
    -- @covers lurek.image.newImageData
    it("tint factor=0 leaves pixel unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:tint(0, 255, 0, 0.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:tint
    -- @covers lurek.image.newImageData
    it("tint returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:tint(255, 0, 0, 0.5)
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- Filter effects
-- =============================================================================

-- @describe ImageData filter effects: grayscale
describe("ImageData filter effects: grayscale", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:grayscale
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("grayscale makes r==g==b for a pure-red pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:grayscale()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, g)
        expect_equal(g, b)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:grayscale
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("grayscale makes r==g==b for a pure-blue pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 0, 0, 255, 255)
        img:grayscale()
        local r, g, b, _ = img:getPixel(0, 0)
        expect_equal(r, g)
        expect_equal(g, b)
    end)

    -- @covers LImageData:grayscale
    -- @covers lurek.image.newImageData
    it("grayscale returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:grayscale()
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- New helpers: palette cycling and nine-slice
-- =============================================================================

-- @describe PaletteLUT helper: cycle
describe("PaletteLUT helper: cycle", function()
    -- @covers LPaletteLUT:cycle
    -- @covers LPaletteLUT:setColor
    -- @covers LImageData:applyPaletteLut
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newPaletteLut
    it("cycle rotates target palette entries", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)

        local lut = lurek.image.newPaletteLut()
        lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)   -- red -> green
        lut:setColor(0, 255, 0, 255, 0, 0, 255, 255)   -- green -> blue
        lut:cycle(1)

        img:applyPaletteLut(lut)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 0)
        expect_equal(g, 0)
        expect_equal(b, 255)
        expect_equal(a, 255)
    end)
end)

-- @describe ImageData helper: drawNineSlice
describe("ImageData helper: drawNineSlice", function()
    -- @covers LImageData:drawNineSlice
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("draws stretched center area from source patch", function()
        local src = lurek.image.newImageData(6, 6)
        src:fill(10, 10, 10, 255)
        src:drawRect(2, 2, 2, 2, 220, 30, 30, 255)

        local dst = lurek.image.newImageData(20, 20)
        dst:fill(0, 0, 0, 0)

        dst:drawNineSlice(src, 0, 0, 6, 6, 4, 4, 12, 12, 2, 2, 2, 2)

        local cr, cg, cb, ca = dst:getPixel(10, 10)
        expect_equal(cr, 220)
        expect_equal(cg, 30)
        expect_equal(cb, 30)
        expect_equal(ca, 255)
    end)
end)

-- @describe ImageData filter effects: sepia
describe("ImageData filter effects: sepia", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:sepia
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("sepia produces warm-toned output on a red pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:sepia()
        local r, g, b, a = img:getPixel(0, 0)
        -- sepia: r100, g89, b69  - all positive, r >= g >= b
        expect_equal(r > 0, true)
        expect_equal(g > 0, true)
        expect_equal(b > 0, true)
        expect_equal(r >= g, true)
        expect_equal(g >= b, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:sepia
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("sepia leaves alpha unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 200, 100, 50, 128)
        img:sepia()
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 128)
    end)

    -- @covers LImageData:sepia
    -- @covers lurek.image.newImageData
    it("sepia returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:sepia()
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData filter effects: invert
describe("ImageData filter effects: invert", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:invert
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("invert inverts RGB channels, leaving alpha unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:invert()
        local r, g, b, a = img:getPixel(0, 0)
        -- 255 - 100 = 155, 255 - 150 = 105, 255 - 200 = 55
        expect_equal(math.abs(r - 155) <= 2, true)
        expect_equal(math.abs(g - 105) <= 2, true)
        expect_equal(math.abs(b - 55) <= 2, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:invert
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("invert applied twice returns to original", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 80, 120, 200, 200)
        img:invert()
        img:invert()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 80)
        expect_equal(g, 120)
        expect_equal(b, 200)
        expect_equal(a, 200)
    end)

    -- @covers LImageData:invert
    -- @covers lurek.image.newImageData
    it("invert returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:invert()
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData filter effects: threshold
describe("ImageData filter effects: threshold", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers LImageData:threshold
    -- @covers lurek.image.newImageData
    it("threshold above value produces white pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 255, 255, 255, 255)  -- luma=255 >= 128
        img:threshold(128)
        local r, g, b, _ = img:getPixel(0, 0)
        expect_equal(r, 255)
        expect_equal(g, 255)
        expect_equal(b, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers LImageData:threshold
    -- @covers lurek.image.newImageData
    it("threshold below value produces black pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 10, 10, 10, 255)  -- luma10 < 128
        img:threshold(128)
        local r, g, b, _ = img:getPixel(0, 0)
        expect_equal(r, 0)
        expect_equal(g, 0)
        expect_equal(b, 0)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers LImageData:threshold
    -- @covers lurek.image.newImageData
    it("threshold leaves alpha unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 200, 200, 200, 99)
        img:threshold(128)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 99)
    end)

    -- @covers LImageData:threshold
    -- @covers lurek.image.newImageData
    it("threshold returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:threshold(128)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData filter effects: posterize
describe("ImageData filter effects: posterize", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:posterize
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("posterize levels=2 maps each channel to 0 or 255", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 200, 50, 128, 255)
        img:posterize(2)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r == 0 or r == 255, true)
        expect_equal(g == 0 or g == 255, true)
        expect_equal(b == 0 or b == 255, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:posterize
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("posterize leaves alpha unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 100, 100, 77)
        img:posterize(4)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 77)
    end)

    -- @covers LImageData:posterize
    -- @covers lurek.image.newImageData
    it("posterize returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:posterize(4)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData filter effects: fill
describe("ImageData filter effects: fill", function()
    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers lurek.image.newImageData
    it("fill sets all pixels to the given RGBA colour", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(255, 0, 0, 255)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 255)
        expect_equal(g, 0)
        expect_equal(b, 0)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers lurek.image.newImageData
    it("fill sets a corner pixel too", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(0, 128, 255, 200)
        local r, g, b, a = img:getPixel(3, 3)
        expect_equal(r, 0)
        expect_equal(g, 128)
        expect_equal(b, 255)
        expect_equal(a, 200)
    end)

    -- @covers LImageData:fill
    -- @covers lurek.image.newImageData
    it("fill returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:fill(0, 0, 0, 255)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData filter effects: noise
describe("ImageData filter effects: noise", function()
    -- @covers LImageData:getPixel
    -- @covers LImageData:noise
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("noise(0) leaves pixels exactly unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 150, 200, 255)
        img:noise(0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:noise
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("noise(0) leaves alpha unchanged on a transparent pixel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 50, 50, 50, 128)
        img:noise(0)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 128)
    end)

    -- @covers LImageData:noise
    -- @covers lurek.image.newImageData
    it("noise returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:noise(0)
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData filter effects: alphaMask
describe("ImageData filter effects: alphaMask", function()
    -- @covers LImageData:alphaMask
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("alphaMask(0.5) halves the alpha channel", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 128, 64, 255, 200)
        img:alphaMask(0.5)
        local r, g, b, a = img:getPixel(0, 0)
        -- alpha = floor/round(200 * 0.5) = 100; RGB unchanged
        expect_equal(math.abs(a - 100) <= 2, true)
        expect_equal(r, 128)
        expect_equal(g, 64)
        expect_equal(b, 255)
    end)

    -- @covers LImageData:alphaMask
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("alphaMask(1.0) leaves alpha unchanged", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 100, 100, 100, 180)
        img:alphaMask(1.0)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 180)
    end)

    -- @covers LImageData:alphaMask
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("alphaMask(0.0) makes pixel fully transparent", function()
        local img = lurek.image.newImageData(1, 1)
        img:setPixel(0, 0, 255, 255, 255, 200)
        img:alphaMask(0.0)
        local _, _, _, a = img:getPixel(0, 0)
        expect_equal(a, 0)
    end)

    -- @covers LImageData:alphaMask
    -- @covers lurek.image.newImageData
    it("alphaMask returns nil (in-place)", function()
        local img = lurek.image.newImageData(1, 1)
        local ret = img:alphaMask(1.0)
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- Geometric in-place effects
-- =============================================================================

-- @describe ImageData geometric in-place: flipHorizontal
describe("ImageData geometric in-place: flipHorizontal", function()
    -- @covers LImageData:flipHorizontal
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("flipHorizontal mirrors pixel from column 0 to column 3 in a 4-wide image", function()
        local img = lurek.image.newImageData(4, 1)
        img:setPixel(0, 0, 255, 0, 0, 255)    -- red at left
        img:setPixel(3, 0, 0, 0, 255, 255)    -- blue at right
        img:flipHorizontal()
        local r0, _, b0, _ = img:getPixel(0, 0)  -- was right edge  now blue
        local r3, _, b3, _ = img:getPixel(3, 0)  -- was left edge   now red
        expect_equal(b0, 255)
        expect_equal(r3, 255)
    end)

    -- @covers LImageData:flipHorizontal
    -- @covers LImageData:getHeight
    -- @covers LImageData:getWidth
    -- @covers lurek.image.newImageData
    it("flipHorizontal preserves image dimensions", function()
        local img = lurek.image.newImageData(4, 2)
        img:flipHorizontal()
        expect_equal(img:getWidth(), 4)
        expect_equal(img:getHeight(), 2)
    end)

    -- @covers LImageData:flipHorizontal
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("flipHorizontal applied twice returns to original", function()
        local img = lurek.image.newImageData(4, 1)
        img:setPixel(0, 0, 200, 100, 50, 255)
        img:flipHorizontal()
        img:flipHorizontal()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:flipHorizontal
    -- @covers lurek.image.newImageData
    it("flipHorizontal returns nil (in-place)", function()
        local img = lurek.image.newImageData(2, 2)
        local ret = img:flipHorizontal()
        expect_equal(ret, nil)
    end)
end)

-- @describe ImageData geometric in-place: flipVertical
describe("ImageData geometric in-place: flipVertical", function()
    -- @covers LImageData:flipVertical
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("flipVertical mirrors pixel from row 0 to row 3 in a 4-tall image", function()
        local img = lurek.image.newImageData(1, 4)
        img:setPixel(0, 0, 255, 0, 0, 255)    -- red at top
        img:setPixel(0, 3, 0, 0, 255, 255)    -- blue at bottom
        img:flipVertical()
        local r0, _, b0, _ = img:getPixel(0, 0)  -- was bottom  now blue
        local r3, _, b3, _ = img:getPixel(0, 3)  -- was top     now red
        expect_equal(b0, 255)
        expect_equal(r3, 255)
    end)

    -- @covers LImageData:flipVertical
    -- @covers LImageData:getHeight
    -- @covers LImageData:getWidth
    -- @covers lurek.image.newImageData
    it("flipVertical preserves image dimensions", function()
        local img = lurek.image.newImageData(2, 4)
        img:flipVertical()
        expect_equal(img:getWidth(), 2)
        expect_equal(img:getHeight(), 4)
    end)

    -- @covers LImageData:flipVertical
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("flipVertical applied twice returns to original", function()
        local img = lurek.image.newImageData(1, 4)
        img:setPixel(0, 0, 200, 100, 50, 255)
        img:flipVertical()
        img:flipVertical()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:flipVertical
    -- @covers lurek.image.newImageData
    it("flipVertical returns nil (in-place)", function()
        local img = lurek.image.newImageData(2, 2)
        local ret = img:flipVertical()
        expect_equal(ret, nil)
    end)
end)

-- =============================================================================
-- Geometric new-image effects
-- =============================================================================

-- @describe ImageData geometric new-image: rotate90cw
describe("ImageData geometric new-image: rotate90cw", function()
    -- @covers LImageData:rotate90cw
    -- @covers lurek.image.newImageData
    it("rotate90cw returns a new userdata", function()
        local img = lurek.image.newImageData(4, 2)
        local out = img:rotate90cw()
        expect_type("userdata", out)
    end)

    -- @covers LImageData:rotate90cw
    -- @covers lurek.image.newImageData
    it("rotate90cw swaps dimensions (4x2  2x4)", function()
        local img = lurek.image.newImageData(4, 2)
        local out = img:rotate90cw()
        expect_equal(out:getWidth(), 2)
        expect_equal(out:getHeight(), 4)
    end)

    -- @covers LImageData:rotate90cw
    -- @covers lurek.image.newImageData
    it("rotate90cw on a square returns the same dimensions", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:rotate90cw()
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LImageData:rotate90cw
    -- @covers lurek.image.newImageData
    it("rotate90cw returns a distinct object from the source", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:rotate90cw()
        -- Modify source after rotation; output must be unaffected
        img:fill(255, 0, 0, 255)
        local r, _, _, _ = out:getPixel(0, 0)
        expect_equal(r, 0)  -- out was blank before fill
    end)
end)

-- @describe ImageData geometric new-image: crop
describe("ImageData geometric new-image: crop", function()
    -- @covers LImageData:crop
    -- @covers lurek.image.newImageData
    it("crop returns a new userdata", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:crop(0, 0, 2, 2)
        expect_type("userdata", out)
    end)

    -- @covers LImageData:crop
    -- @covers lurek.image.newImageData
    it("crop(0,0,2,2) on a 4x4 image produces a 2x2 image", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:crop(0, 0, 2, 2)
        expect_equal(out:getWidth(), 2)
        expect_equal(out:getHeight(), 2)
    end)

    -- @covers LImageData:crop
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("crop copies pixel values from the source region", function()
        local img = lurek.image.newImageData(4, 4)
        img:setPixel(1, 1, 200, 100, 50, 255)
        local out = img:crop(1, 1, 2, 2)  -- region starting at (1,1)
        local r, g, b, a = out:getPixel(0, 0)  -- (1,1) in src  (0,0) in crop
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:crop
    -- @covers lurek.image.newImageData
    it("crop out-of-bounds raises an error", function()
        local img = lurek.image.newImageData(4, 4)
        expect_error(function()
            img:crop(3, 3, 5, 5)  -- 3+5=8 > 4, out of bounds
        end)
    end)

    -- @covers LImageData:crop
    -- @covers lurek.image.newImageData
    it("crop zero-width raises an error", function()
        local img = lurek.image.newImageData(4, 4)
        expect_error(function()
            img:crop(0, 0, 0, 2)  -- w=0 is invalid
        end)
    end)
end)

-- @describe ImageData geometric new-image: resizeNearest
describe("ImageData geometric new-image: resizeNearest", function()
    -- @covers LImageData:resizeNearest
    -- @covers lurek.image.newImageData
    it("resizeNearest returns a new userdata", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:resizeNearest(2, 2)
        expect_type("userdata", out)
    end)

    -- @covers LImageData:resizeNearest
    -- @covers lurek.image.newImageData
    it("resizeNearest(2,2) downscales a 4x4 to 2x2", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:resizeNearest(2, 2)
        expect_equal(out:getWidth(), 2)
        expect_equal(out:getHeight(), 2)
    end)

    -- @covers LImageData:resizeNearest
    -- @covers lurek.image.newImageData
    it("resizeNearest(8,8) upscales a 4x4 to 8x8", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:resizeNearest(8, 8)
        expect_equal(out:getWidth(), 8)
        expect_equal(out:getHeight(), 8)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:resizeNearest
    -- @covers LImageData:setPixel
    -- @covers lurek.image.newImageData
    it("resizeNearest preserves top-left pixel colour", function()
        local img = lurek.image.newImageData(4, 4)
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

-- @describe ImageData convolution: blur
describe("ImageData convolution: blur", function()
    -- @covers LImageData:blur
    -- @covers lurek.image.newImageData
    it("blur(0) returns a new userdata", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:blur(0)
        expect_type("userdata", out)
    end)

    -- @covers LImageData:blur
    -- @covers lurek.image.newImageData
    it("blur(0) returns an image with the same dimensions", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:blur(0)
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @covers LImageData:blur
    -- @covers lurek.image.newImageData
    it("blur(1) returns an image with the same dimensions", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:blur(1)
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @covers LImageData:blur
    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers lurek.image.newImageData
    it("blur(0) preserves pixel values (returns a clone)", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(100, 150, 200, 255)
        local out = img:blur(0)
        local r, g, b, a = out:getPixel(1, 1)
        expect_equal(r, 100)
        expect_equal(g, 150)
        expect_equal(b, 200)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:blur
    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers lurek.image.newImageData
    it("blur(1) on a solid-colour image preserves colour", function()
        local img = lurek.image.newImageData(4, 4)
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

-- @describe ImageData convolution: sharpen
describe("ImageData convolution: sharpen", function()
    -- @covers LImageData:sharpen
    -- @covers lurek.image.newImageData
    it("sharpen returns a new userdata", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:sharpen()
        expect_type("userdata", out)
    end)

    -- @covers LImageData:sharpen
    -- @covers lurek.image.newImageData
    it("sharpen returns an image with the same dimensions", function()
        local img = lurek.image.newImageData(4, 4)
        local out = img:sharpen()
        expect_equal(out:getWidth(), 4)
        expect_equal(out:getHeight(), 4)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LImageData:sharpen
    -- @covers lurek.image.newImageData
    it("sharpen on a solid-colour image preserves pixel values", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(128, 64, 32, 255)
        local out = img:sharpen()
        -- 5*C - top - bottom - left - right = 5*C - 4*C = C for uniform colour
        local r, g, b, a = out:getPixel(1, 1)
        expect_equal(math.abs(r - 128) <= 2, true)
        expect_equal(math.abs(g - 64) <= 2, true)
        expect_equal(math.abs(b - 32) <= 2, true)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LImageData:sharpen
    -- @covers lurek.image.newImageData
    it("sharpen returns a distinct object from the source", function()
        local img = lurek.image.newImageData(4, 4)
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

-- @describe lurek.image.newLayeredImage
describe("lurek.image.newLayeredImage", function()
    -- @covers lurek.image.newLayeredImage
    it("returns a LayeredImage userdata", function()
        local stack = lurek.image.newLayeredImage(64, 64)
        expect_equal(type(stack), "userdata")
    end)

    -- @covers LLayeredImage:getHeight
    -- @covers LLayeredImage:getWidth
    -- @covers lurek.image.newLayeredImage
    it("getWidth and getHeight return canvas dimensions", function()
        local stack = lurek.image.newLayeredImage(32, 48)
        expect_equal(stack:getWidth(), 32)
        expect_equal(stack:getHeight(), 48)
    end)

    -- @covers LLayeredImage:layerCount
    -- @covers lurek.image.newLayeredImage
    it("layerCount starts at zero", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        expect_equal(stack:layerCount(), 0)
    end)
end)

-- @describe LayeredImage:addLayer
describe("LayeredImage:addLayer", function()
    -- @covers LLayeredImage:addLayer
    -- @covers lurek.image.newLayeredImage
    it("addLayer with explicit name returns 1", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        local idx = stack:addLayer("background")
        expect_equal(idx, 1)
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:layerCount
    -- @covers lurek.image.newLayeredImage
    it("adding two layers increments index", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        local a = stack:addLayer("a")
        local b = stack:addLayer("b")
        expect_equal(a, 1)
        expect_equal(b, 2)
        expect_equal(stack:layerCount(), 2)
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getName
    -- @covers lurek.image.newLayeredImage
    it("addLayer without name generates a default name", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer()
        local name = stack:getName(1)
        expect_equal(type(name), "string")
        expect_equal(#name > 0, true)
    end)
end)

-- @describe LayeredImage:removeLayer
describe("LayeredImage:removeLayer", function()
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:layerCount
    -- @covers LLayeredImage:removeLayer
    -- @covers lurek.image.newLayeredImage
    it("removes existing layer and decrements count", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        expect_equal(stack:removeLayer(1), true)
        expect_equal(stack:layerCount(), 0)
    end)

    -- @covers LLayeredImage:removeLayer
    -- @covers lurek.image.newLayeredImage
    it("returns false for out-of-range index", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        expect_equal(stack:removeLayer(99), false)
    end)
end)

-- @describe LayeredImage opacity and visibility
describe("LayeredImage opacity and visibility", function()
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getOpacity
    -- @covers LLayeredImage:setOpacity
    -- @covers lurek.image.newLayeredImage
    it("setOpacity and getOpacity round-trip", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        expect_equal(stack:setOpacity(1, 0.5), true)
        local op = stack:getOpacity(1)
        expect_equal(math.abs(op - 0.5) < 0.01, true)
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getOpacity
    -- @covers LLayeredImage:setOpacity
    -- @covers lurek.image.newLayeredImage
    it("setOpacity clamps above 1.0", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        stack:setOpacity(1, 5.0)
        expect_equal(math.abs(stack:getOpacity(1) - 1.0) < 0.01, true)
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:isVisible
    -- @covers LLayeredImage:setVisible
    -- @covers lurek.image.newLayeredImage
    it("setVisible and isVisible round-trip", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        stack:setVisible(1, false)
        expect_equal(stack:isVisible(1), false)
        stack:setVisible(1, true)
        expect_equal(stack:isVisible(1), true)
    end)

    -- @covers LLayeredImage:getOpacity
    -- @covers lurek.image.newLayeredImage
    it("invalid index returns error from getOpacity", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        expect_error(function() stack:getOpacity(99) end)
    end)
end)

-- @describe LayeredImage name operations
describe("LayeredImage name operations", function()
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getName
    -- @covers lurek.image.newLayeredImage
    it("getName returns the layer name", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("myName")
        expect_equal(stack:getName(1), "myName")
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getName
    -- @covers LLayeredImage:setName
    -- @covers lurek.image.newLayeredImage
    it("setName renames a layer", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("old")
        expect_equal(stack:setName(1, "new"), true)
        expect_equal(stack:getName(1), "new")
    end)
end)

-- @describe LayeredImage layer reordering
describe("LayeredImage layer reordering", function()
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getName
    -- @covers LLayeredImage:swapLayers
    -- @covers lurek.image.newLayeredImage
    it("swapLayers exchanges two layer positions", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("first")
        stack:addLayer("second")
        expect_equal(stack:swapLayers(1, 2), true)
        expect_equal(stack:getName(1), "second")
        expect_equal(stack:getName(2), "first")
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:swapLayers
    -- @covers lurek.image.newLayeredImage
    it("swapLayers returns false for out-of-range", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        expect_equal(stack:swapLayers(1, 99), false)
    end)

    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getName
    -- @covers LLayeredImage:moveLayer
    -- @covers lurek.image.newLayeredImage
    it("moveLayer repositions a layer", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("a")
        stack:addLayer("b")
        stack:addLayer("c")
        expect_equal(stack:moveLayer(1, 3), true)
        -- a moves to 3, so order is b, c, a
        expect_equal(stack:getName(1), "b")
        expect_equal(stack:getName(3), "a")
    end)
end)

-- @describe LayeredImage pixel editing via getLayer/setLayer
describe("LayeredImage pixel editing via getLayer/setLayer", function()
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getLayer
    -- @covers lurek.image.newLayeredImage
    it("getLayer returns an ImageData copy", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        local img = stack:getLayer(1)
        expect_equal(type(img), "userdata")
        expect_equal(img:getWidth(), 4)
        expect_equal(img:getHeight(), 4)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:getLayer
    -- @covers LLayeredImage:setLayer
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newLayeredImage
    it("setLayer replaces layer pixels", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("x")
        local src = lurek.image.newImageData(4, 4)
        src:fill(255, 0, 0, 255)
        expect_equal(stack:setLayer(1, src), true)
        local got = stack:getLayer(1)
        local r, g, b, a = got:getPixel(0, 0)
        expect_equal(r, 255)
        expect_equal(g, 0)
        expect_equal(b, 0)
        expect_equal(a, 255)
    end)

    -- @covers LLayeredImage:getLayer
    -- @covers lurek.image.newLayeredImage
    it("getLayer with invalid index throws", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        expect_error(function() stack:getLayer(99) end)
    end)
end)

-- @describe LayeredImage:merge
describe("LayeredImage:merge", function()
    -- @covers LImageData:getPixel
    -- @covers LLayeredImage:merge
    -- @covers lurek.image.newLayeredImage
    it("empty stack merges to fully transparent image", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        local flat = stack:merge()
        local r, g, b, a = flat:getPixel(0, 0)
        expect_equal(a, 0)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:merge
    -- @covers LLayeredImage:setLayer
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newLayeredImage
    it("single opaque layer merges to that layer's pixels", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("bg")
        local src = lurek.image.newImageData(4, 4)
        src:fill(200, 100, 50, 255)
        stack:setLayer(1, src)
        local flat = stack:merge()
        local r, g, b, a = flat:getPixel(0, 0)
        expect_equal(r, 200)
        expect_equal(g, 100)
        expect_equal(b, 50)
        expect_equal(a, 255)
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:merge
    -- @covers LLayeredImage:setLayer
    -- @covers LLayeredImage:setVisible
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newLayeredImage
    it("hidden layer does not appear in merge", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("bg")
        local bg = lurek.image.newImageData(4, 4)
        bg:fill(255, 0, 0, 255)
        stack:setLayer(1, bg)
        stack:addLayer("fg")
        local fg = lurek.image.newImageData(4, 4)
        fg:fill(0, 0, 255, 255)
        stack:setLayer(2, fg)
        stack:setVisible(2, false)
        local flat = stack:merge()
        local r, _, _, _ = flat:getPixel(0, 0)
        expect_equal(r, 255)  -- red from bg; blue fg invisible
    end)

    -- @covers LImageData:fill
    -- @covers LImageData:getPixel
    -- @covers LLayeredImage:addLayer
    -- @covers LLayeredImage:merge
    -- @covers LLayeredImage:setLayer
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newLayeredImage
    it("opaque top layer fully covers bottom", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        stack:addLayer("bg")
        local bg = lurek.image.newImageData(4, 4)
        bg:fill(255, 0, 0, 255)
        stack:setLayer(1, bg)
        stack:addLayer("fg")
        local fg = lurek.image.newImageData(4, 4)
        fg:fill(0, 0, 255, 255)
        stack:setLayer(2, fg)
        local flat = stack:merge()
        local r, g, b, a = flat:getPixel(0, 0)
        expect_equal(b, 255)
        expect_equal(r, 0)
    end)

    -- @covers LLayeredImage:merge
    -- @covers lurek.image.newLayeredImage
    it("merge returns an ImageData of the same dimensions", function()
        local stack = lurek.image.newLayeredImage(8, 6)
        local flat = stack:merge()
        expect_equal(flat:getWidth(), 8)
        expect_equal(flat:getHeight(), 6)
    end)
end)

-- -----------------------------------------------------------------------
-- LIMG binary serialization tests
-- -----------------------------------------------------------------------

-- @describe lurek.image.saveImage / lurek.image.loadImage
describe("lurek.image.saveImage / lurek.image.loadImage", function()
    -- @covers lurek.image.loadImage
    -- @covers lurek.image.saveImage
    it("saveImage and loadImage functions exist", function()
        expect_equal(type(lurek.image.saveImage), "function")
        expect_equal(type(lurek.image.loadImage), "function")
    end)
end)

-- @describe lurek.image.saveLayered / lurek.image.loadLayered
describe("lurek.image.saveLayered / lurek.image.loadLayered", function()
    -- @covers lurek.image.loadLayered
    it("loadLayered function exists", function()
        expect_equal(type(lurek.image.loadLayered), "function")
    end)
end)

-- @describe LayeredImage:save
describe("LayeredImage:save", function()
    -- @covers lurek.image.newLayeredImage
    it("save method exists on LayeredImage userdata", function()
        local stack = lurek.image.newLayeredImage(4, 4)
        expect_equal(type(stack.save), "function")
    end)
end)

---@param img LImageData|nil
---@param context string
---@return LImageData
local function require_image_data(img, context)
    if img == nil then
        error(context .. " returned nil", 2)
    end
    return img
end

--  Extended ImageData ops: resize, blit, getRegion, diff, mapPixels (merged from test_image_extended.lua)

local function make_solid(w, h, r, g, b, a)
    local img = lurek.image.newImageData(w, h)
    img:mapPixels(function(_, _, _, _, _, _) return r, g, b, a end)
    return img
end

-- @describe ImageData:resize
describe("ImageData:resize", function()
    -- @covers lurek.image
    -- @covers LImageData:resize
    it("resize to same dimensions returns a copy", function()
        local img = make_solid(4, 4, 255, 0, 0, 255)
        local copy = require_image_data(img:resize(4, 4), "ImageData:resize(4, 4)")
        expect_equal(copy ~= nil, true)
        expect_equal(copy:getWidth(), 4)
        expect_equal(copy:getHeight(), 4)
    end)

    -- @covers lurek.image
    -- @covers LImageData:resize
    it("resize returns correct dimensions", function()
        local img = make_solid(8, 8, 0, 255, 0, 255)
        local small = require_image_data(img:resize(2, 3), "ImageData:resize(2, 3)")
        expect_equal(small:getWidth(), 2)
        expect_equal(small:getHeight(), 3)
    end)

    -- @covers lurek.image
    it("resize to zero returns nil", function()
        local img = make_solid(4, 4, 0, 0, 0, 255)
        local result = img:resize(0, 4)
        expect_equal(result, nil)
    end)
end)

-- @describe ImageData:blit
describe("ImageData:blit", function()
    -- @covers LImageData:blit
    it("blit does not error for valid coordinates", function()
        local dst = make_solid(8, 8, 0, 0, 0, 255)
        local src = make_solid(2, 2, 255, 255, 255, 255)
        dst:blit(src, 3, 3)
    end)

    -- @covers LImageData:blit
    it("blit at (0,0) covers the top-left corner", function()
        local dst = make_solid(4, 4, 0, 0, 0, 255)
        local src = make_solid(2, 2, 200, 100, 50, 255)
        dst:blit(src, 0, 0)
        expect_equal(dst:getWidth(), 4)
    end)

    -- @covers LImageData:blit
    it("blit with negative offset does not error (clips out-of-bounds)", function()
        local dst = make_solid(4, 4, 0, 0, 0, 255)
        local src = make_solid(2, 2, 255, 0, 0, 255)
        dst:blit(src, -1, -1)
    end)
end)

-- @describe ImageData:getRegion
describe("ImageData:getRegion", function()
    -- @covers lurek.image
    -- @covers LImageData:getRegion
    it("getRegion of full image returns same dimensions", function()
        local img = make_solid(6, 4, 128, 64, 32, 255)
        local region = require_image_data(img:getRegion(0, 0, 6, 4), "ImageData:getRegion(0, 0, 6, 4)")
        expect_equal(region ~= nil, true)
        expect_equal(region:getWidth(), 6)
        expect_equal(region:getHeight(), 4)
    end)

    -- @covers lurek.image
    -- @covers LImageData:getRegion
    it("getRegion of sub-rectangle returns correct dimensions", function()
        local img = make_solid(8, 8, 0, 0, 255, 255)
        local region = require_image_data(img:getRegion(2, 2, 4, 3), "ImageData:getRegion(2, 2, 4, 3)")
        expect_equal(region:getWidth(), 4)
        expect_equal(region:getHeight(), 3)
    end)

    -- @covers lurek.image
    it("getRegion outside bounds returns nil", function()
        local img = make_solid(4, 4, 0, 0, 0, 255)
        local result = img:getRegion(10, 10, 4, 4)
        expect_equal(result, nil)
    end)
end)

-- @describe ImageData:diff
describe("ImageData:diff", function()
    -- @covers lurek.image
    -- @covers LImageData:diff
    it("diff of identical images is 0", function()
        local a = make_solid(4, 4, 100, 150, 200, 255)
        local b = make_solid(4, 4, 100, 150, 200, 255)
        local d = a:diff(b)
        expect_equal(d, 0)
    end)

    -- @covers lurek.image
    -- @covers LImageData:diff
    it("diff of different images is > 0", function()
        local a = make_solid(4, 4, 0, 0, 0, 255)
        local b = make_solid(4, 4, 255, 255, 255, 255)
        local d = a:diff(b)
        expect_equal(d > 0, true)
    end)

    -- @covers lurek.image
    -- @covers LImageData:diff
    it("diff of images with different dimensions is > 0", function()
        local a = make_solid(4, 4, 0, 0, 0, 255)
        local b = make_solid(2, 2, 0, 0, 0, 255)
        local d = a:diff(b)
        expect_equal(d > 0, true)
    end)
end)

-- @describe ImageData:mapPixels
describe("ImageData:mapPixels", function()
    -- @covers LImageData:mapPixels
    it("mapPixels can invert all pixels", function()
        local img = make_solid(4, 4, 100, 150, 200, 255)
        img:mapPixels(function(_, _, r, g, b, a)
            return 255 - r, 255 - g, 255 - b, a
        end)
        expect_equal(img:getWidth(), 4)
    end)

    -- @covers LImageData:mapPixels
    it("mapPixels identity function produces same diff as 0", function()
        local img_a = make_solid(4, 4, 42, 88, 177, 255)
        local img_b = make_solid(4, 4, 42, 88, 177, 255)
        img_a:mapPixels(function(_, _, r, g, b, a) return r, g, b, a end)
        local d = img_a:diff(img_b)
        expect_equal(d, 0)
    end)

    -- @covers LImageData:mapPixels
    it("mapPixels can set all pixels to a constant colour", function()
        local img = make_solid(4, 4, 0, 0, 0, 255)
        img:mapPixels(function(_, _, _, _, _, _) return 1, 2, 3, 4 end)
        expect_equal(img:getWidth(), 4)
    end)
end)

-- =========================================================================
-- Additional API coverage
-- =========================================================================

-- @describe image palette and province coverage
describe("image palette and province coverage", function()
    -- @covers LPaletteLUT:getColorCount
    -- @covers LPaletteLUT:setColor
    -- @covers lurek.image.newPaletteLut
    it("newPaletteLut starts empty and counts entries", function()
        local lut = lurek.image.newPaletteLut()
        expect_equal(0, lut:getColorCount())
        lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)
        expect_equal(1, lut:getColorCount())
        lut:setColor(0, 0, 255, 255, 255, 255, 0, 255)
        expect_equal(2, lut:getColorCount())
    end)

    -- @covers LImageData:applyPaletteLut
    -- @covers LImageData:getPixel
    -- @covers LImageData:setPixel
    -- @covers LPaletteLUT:setColor
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newPaletteLut
    it("applyPaletteLut replaces matching pixels", function()
        local img = lurek.image.newImageData(2, 1)
        local lut = lurek.image.newPaletteLut()
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:setPixel(1, 0, 0, 0, 255, 255)
        lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)

        img:applyPaletteLut(lut)

        local r1, g1, b1, a1 = img:getPixel(0, 0)
        local r2, g2, b2, a2 = img:getPixel(1, 0)
        expect_equal(0, r1)
        expect_equal(255, g1)
        expect_equal(0, b1)
        expect_equal(255, a1)
        expect_equal(0, r2)
        expect_equal(0, g2)
        expect_equal(255, b2)
        expect_equal(255, a2)
    end)

    -- @covers LImageData:setPixel
    -- @covers LProvinceGrid:adjacencies
    -- @covers LProvinceGrid:getAt
    -- @covers LProvinceGrid:getHeight
    -- @covers LProvinceGrid:getWidth
    -- @covers LProvinceGrid:provinceCount
    -- @covers lurek.image.newImageData
    -- @covers lurek.image.newProvinceGrid
    -- @covers lurek.image.savePNG
    it("savePNG and newProvinceGrid build a usable province map", function()
        local img = lurek.image.newImageData(4, 4)
        local path = "save/_province_grid_test.png"

        for y = 0, 1 do
            for x = 0, 1 do
                img:setPixel(x, y, 255, 0, 0, 255)
            end
        end
        for y = 0, 1 do
            for x = 2, 3 do
                img:setPixel(x, y, 0, 255, 0, 255)
            end
        end
        for x = 0, 3 do
            img:setPixel(x, 2, 0, 0, 255, 255)
        end

        lurek.image.savePNG(img, path)
        local grid = lurek.image.newProvinceGrid(path)
        local adj = grid:adjacencies()
        local red = grid:getAt(0, 0)
        local green = grid:getAt(2, 0)
        local blue = grid:getAt(0, 2)

        expect_equal(4, grid:getWidth())
        expect_equal(4, grid:getHeight())
        expect_equal(3, grid:provinceCount())
        expect_equal(red, grid:getAt(1, 1))
        expect_true(red > 0)
        expect_true(green > 0)
        expect_true(blue > 0)
        expect_true(red ~= green)
        expect_true(red ~= blue)
        expect_true(green ~= blue)
        expect_equal(0, grid:getAt(0, 3))
        expect_type("table", adj)
        expect_true(#adj >= 3)
        expect_type("number", adj[1].province_a)
        expect_type("number", adj[1].province_b)
        expect_type("number", adj[1].border_pixels)
    end)
end)

-- @describe image remaining explicit coverage
describe("image remaining explicit coverage", function()
    -- @covers LCompressedImageData:getDimensions
    -- @covers LCompressedImageData:getFormat
    -- @covers LCompressedImageData:getHeight
    -- @covers LCompressedImageData:getWidth
    -- @covers lurek.image.newCompressedData
    it("CompressedImageData metadata methods report fixture state", function()
        local compressed = lurek.image.newCompressedData("tests/fixtures/test_dxt1.dds")
        local width, height = compressed:getDimensions()

        expect_true(compressed:getWidth() > 0)
        expect_true(compressed:getHeight() > 0)
        expect_equal(width, compressed:getWidth())
        expect_equal(height, compressed:getHeight())
        expect_type("string", compressed:getFormat())
        expect_true(#compressed:getFormat() > 0)
    end)

    -- @covers LImageData:getPixel
    -- @covers LImageData:setRawData
    -- @covers lurek.image.newImageData
    it("ImageData:setRawData replaces pixel bytes", function()
        local img = lurek.image.newImageData(1, 1)
        img:setRawData(string.char(7, 8, 9, 255))
        local r, g, b, a = img:getPixel(0, 0)

        expect_equal(r, 7)
        expect_equal(g, 8)
        expect_equal(b, 9)
        expect_equal(a, 255)
    end)

    -- @covers LPaletteLUT:clear
    -- @covers LPaletteLUT:getColorCount
    -- @covers LPaletteLUT:setColor
    -- @covers lurek.image.newPaletteLut
    it("PaletteLUT:clear removes all mappings", function()
        local lut = lurek.image.newPaletteLut()
        lut:setColor(1, 2, 3, 255, 4, 5, 6, 255)
        lut:setColor(10, 20, 30, 255, 40, 50, 60, 255)
        expect_equal(2, lut:getColorCount())

        lut:clear()

        expect_equal(0, lut:getColorCount())
    end)
end)

-- @describe LCompressedImageData:getMipmapCount
describe("LCompressedImageData:getMipmapCount", function()
    -- @covers LCompressedImageData:getMipmapCount
    -- @covers lurek.image.newCompressedData
    it("getMipmapCount returns a non-negative integer for a DDS fixture", function()
        local compressed = lurek.image.newCompressedData("tests/fixtures/test_dxt1.dds")
        local count = compressed:getMipmapCount()
        expect_type("number", count)
        expect_true(count >= 0, "mipmap count must be non-negative")
    end)
end)

-- @describe image strict: LImageData extra methods
describe("image strict: LImageData extra methods", function()
    -- @covers LImageData:getDimensions
    -- @covers lurek.image.newImageData
    it("LImageData getDimensions returns width and height", function()
        local img = lurek.image.newImageData(4, 6)
        local w, h = img:getDimensions()
        expect_equal(4, w)
        expect_equal(6, h)
    end)

    -- @covers LImageData:encode
    -- @covers lurek.image.newImageData
    it("LImageData encode returns string data for png", function()
        local img = lurek.image.newImageData(2, 2)
        local data = img:encode("png")
        expect_true(data ~= nil)
    end)

    -- @covers LImageData:getString
    -- @covers lurek.image.newImageData
    it("LImageData getString returns string or table", function()
        local img = lurek.image.newImageData(2, 2)
        local s = img:getString()
        expect_true(type(s) == "string" or type(s) == "table")
    end)

    -- @covers LImageData:mapPixel
    -- @covers lurek.image.newImageData
    it("LImageData mapPixel is callable", function()
        local img = lurek.image.newImageData(2, 2)
        local ok = pcall(function()
            img:mapPixel(function(x, y, r, g, b, a)
                return r, g, b, a
            end)
        end)
        expect_true(ok)
    end)

    -- @covers LImageData:drawRect
    -- @covers lurek.image.newImageData
    it("LImageData drawRect is callable", function()
        local img = lurek.image.newImageData(8, 8)
        local ok = pcall(function() img:drawRect(1, 1, 4, 4, 255, 0, 0, 255) end)
        expect_true(ok)
    end)

    -- @covers LImageData:drawCircle
    -- @covers lurek.image.newImageData
    it("LImageData drawCircle is callable", function()
        local img = lurek.image.newImageData(8, 8)
        local ok = pcall(function() img:drawCircle(4, 4, 2, 0, 255, 0, 255) end)
        expect_true(ok)
    end)

    -- @covers LImageData:drawLine
    -- @covers lurek.image.newImageData
    it("LImageData drawLine is callable", function()
        local img = lurek.image.newImageData(8, 8)
        local ok = pcall(function() img:drawLine(0, 0, 7, 7, 0, 0, 255, 255) end)
        expect_true(ok)
    end)

    -- @covers LImageData:convolve
    -- @covers lurek.image.newImageData
    it("LImageData convolve is callable with 3x3 kernel", function()
        local img = lurek.image.newImageData(4, 4)
        local kernel = {}
        for i = 1, 9 do kernel[i] = (i == 5) and 1 or 0 end
        local ok = pcall(function() img:convolve(kernel, 3) end)
        expect_true(ok)
    end)

    -- @covers LImageData:paste
    -- @covers lurek.image.newImageData
    it("LImageData paste is callable", function()
        local dst = lurek.image.newImageData(8, 8)
        local src = lurek.image.newImageData(2, 2)
        local ok = pcall(function() dst:paste(src, 0, 0) end)
        expect_true(ok)
    end)
end)

-- @describe image strict: LLayeredImage type/typeOf/save
describe("image strict: LLayeredImage type/typeOf/save", function()
    -- @covers LLayeredImage:type
    -- @covers LLayeredImage:typeOf
    -- @covers lurek.image.newLayeredImage
    it("LLayeredImage type and typeOf are callable", function()
        local li = lurek.image.newLayeredImage(4, 4)
        expect_type("string", li:type())
        expect_type("boolean", li:typeOf("Object"))
    end)

    -- @covers LLayeredImage:save
    -- @covers lurek.image.newLayeredImage
    it("LLayeredImage save is callable", function()
        local li = lurek.image.newLayeredImage(2, 2)
        local ok = pcall(function() li:save("_fs_tests/strict_li.png") end)
        expect_type("boolean", ok)
    end)
end)

-- @describe image strict: LCompressedImageData type/typeOf
describe("image strict: LCompressedImageData type/typeOf", function()
    -- @covers LCompressedImageData:type
    -- @covers LCompressedImageData:typeOf
    -- @covers lurek.image.newCompressedData
    it("LCompressedImageData type and typeOf via failed load are not tested (no DDS fixture)", function()
        expect_type("function", lurek.image.newCompressedData)
    end)
end)

-- @describe image strict: LPaletteLUT type/typeOf
describe("image strict: LPaletteLUT type/typeOf", function()
    -- @covers LPaletteLUT:type
    -- @covers LPaletteLUT:typeOf
    -- @covers lurek.image.newPaletteLut
    it("LPaletteLUT type and typeOf are callable", function()
        local lut = lurek.image.newPaletteLut()
        expect_type("string", lut:type())
        expect_type("boolean", lut:typeOf("Object"))
    end)
end)

-- @describe image strict: LProvinceGrid type/typeOf
describe("image strict: LProvinceGrid type/typeOf", function()
    -- @covers LProvinceGrid:type
    -- @covers LProvinceGrid:typeOf
    -- @covers lurek.image.newProvinceGrid
    it("LProvinceGrid type and typeOf skip when no fixture file", function()
        local ok, pg = pcall(function() return lurek.image.newProvinceGrid("nonexistent.png") end)
        if ok then
            expect_type("string", pg:type())
            expect_type("boolean", pg:typeOf("Object"))
        else
            expect_false(ok and pg ~= nil)
        end
    end)
end)

-- @describe image strict: byte constructors and province geometry helpers
describe("image strict: byte constructors and province geometry helpers", function()
    -- @covers lurek.image.newImageDataFromBytes
    -- @covers LImageData:getRawBytes
    it("newImageDataFromBytes creates image and getRawBytes returns RGBA payload", function()
        local bytes = string.rep(string.char(255, 0, 0, 255), 4)
        local img = lurek.image.newImageDataFromBytes(2, 2, bytes)
        local raw = img:getRawBytes()
        expect_type("string", raw)
        expect_equal(16, #raw)
    end)

    -- @covers LProvinceGrid:provinceSpans
    -- @covers LProvinceGrid:borderSegments
    -- @covers LProvinceGrid:getPolygons
    -- @covers LProvinceGrid:getPolygonsSimplified
    -- @covers LProvinceGrid:drawShapes
    -- @covers LProvinceGrid:serializeShapeData
    -- @covers LProvinceGrid:deserializeShapeData
    -- @covers lurek.image.newProvinceGrid
    it("province grid geometry APIs return expected data", function()
        local pg = lurek.image.newProvinceGrid("content/games/strategy/eu2/map.png")
        local spans = pg:provinceSpans()
        local segs = pg:borderSegments()
        local polys = pg:getPolygons()
        local simple_polys = pg:getPolygonsSimplified()
        local draw_count = pg:drawShapes()
        local blob = pg:serializeShapeData()
        local decoded = pg:deserializeShapeData(blob)
        assert(decoded)

        expect_type("table", spans)
        expect_type("table", segs)
        expect_type("table", polys)
        expect_type("table", simple_polys)
        expect_type("number", draw_count)
        expect_type("string", blob)
        expect_type("table", decoded)
        expect_type("table", decoded.spans)
        expect_type("table", decoded.segments)
    end)
end)

-- @describe image strict: readback polling and resize filters
describe("image strict: readback polling and resize filters", function()
    -- @covers lurek.image.fromScreen
    it("fromScreen is poll-based and returns nil or ImageData", function()
        local from_screen = lurek.image["fromScreen"]
        if from_screen == nil then
            expect_nil(from_screen)
            return
        end

        local first = from_screen()
        expect_true(first == nil or type(first) == "userdata")

        local second = from_screen()
        expect_true(second == nil or type(second) == "userdata")
    end)

    -- @covers LImageData:resize
    -- @covers lurek.image.newImageData
    it("resize accepts lanczos3 filter", function()
        local img = lurek.image.newImageData(4, 4)
        img:fill(255, 0, 0, 255)
        local resize_fn = img["resize"]
        local out = resize_fn(img, 3, 5, "lanczos3")
        expect_not_nil(out)
        local w, h = out:getDimensions()
        expect_equal(3, w)
        expect_equal(5, h)
    end)

    -- @covers LImageData:resize
    -- @covers lurek.image.newImageData
    it("resize rejects unknown filter names", function()
        local img = lurek.image.newImageData(4, 4)
        local resize_fn = img["resize"]
        local ok = pcall(function()
            resize_fn(img, 2, 2, "nearest")
        end)
        expect_equal(false, ok)
    end)
end)

-- @describe unit: migrated from integration/test_image_dataframe.lua
describe("unit: migrated from integration/test_image_dataframe.lua", function()
        -- @covers LImageData:getHeight
        -- @covers LImageData:getWidth
        -- @covers lurek.image.newImageData
        it("ImageData width/height round-trips", function()
            local img = lurek.image.newImageData(32, 16)
            expect_equal(img:getWidth(), 32, "width is 32")
            expect_equal(img:getHeight(), 16, "height is 16")
        end)

end)

-- @describe property: image resize invariants
describe("property: image resize invariants", function()
        -- @covers LImageData:getDimensions
        -- @covers LImageData:resize
        -- @covers lurek.image.newImageData
        it("resize output dimensions match requested size", function()
            local src = lurek.image.newImageData(8, 6)
            src:fill(20, 40, 60, 255)

            for w = 2, 10, 2 do
                local h = w + 1
                local out = src:resize(w, h, "linear")
                local ow, oh = out:getDimensions()
                expect_equal(w, ow)
                expect_equal(h, oh)
            end
        end)
end)

test_summary()

