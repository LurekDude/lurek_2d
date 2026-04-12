-- Evidence test: ImageData filter/effect methods produce PNG evidence
-- Produces: effect_grayscale.png, effect_inverted.png, effect_sepia.png,
--           effect_bright.png, effect_threshold.png, effect_blur.png,
--           effect_sharpen.png, effect_noise.png, effect_posterize.png, effect_tint.png
-- @evidence file
-- @covers ImageData:grayscale
-- @covers ImageData:invert
-- @covers ImageData:sepia
-- @covers ImageData:brightness
-- @covers ImageData:threshold
-- @covers ImageData:posterize
-- @covers ImageData:tint
-- @covers ImageData:noise
-- @covers ImageData:blur
-- @covers ImageData:sharpen

local function solid(w, h, r, g, b, a)
    local img = lurek.img.newImageData(w, h)
    img:fill(r, g, b, a)
    return img
end

describe("evidence: imagedata effect filters", function()
    local OUT

    before_each(function()
        ensure_evidence_dir("image")
        OUT = evidence_output_dir("image")
    end)

    it("creates grayscale effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        img:grayscale()
        local path = OUT .. "effect_grayscale.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates inverted effect PNG", function()
        local img = solid(32, 32, 100, 150, 200, 255)
        img:invert()
        local path = OUT .. "effect_inverted.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates sepia effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:sepia()
        local path = OUT .. "effect_sepia.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates brightness effect PNG", function()
        local img = solid(32, 32, 100, 100, 100, 255)
        img:brightness(1.5)
        local path = OUT .. "effect_bright.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates threshold effect PNG", function()
        local img = solid(32, 32, 179, 134, 89, 255)
        img:threshold(128)
        local path = OUT .. "effect_threshold.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates posterize effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:posterize(4)
        local path = OUT .. "effect_posterize.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates tint effect PNG", function()
        local img = solid(32, 32, 200, 200, 200, 255)
        img:tint(255, 0, 0, 0.5)
        local path = OUT .. "effect_tint.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates noise effect PNG", function()
        local img = solid(32, 32, 128, 128, 128, 255)
        img:noise(30)
        local path = OUT .. "effect_noise.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates blur effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        local blurred = img:blur(2)
        local path = OUT .. "effect_blur.png"
        lurek.img.savePNG(blurred, path)
        expect_evidence_created(path)
    end)

    it("creates sharpen effect PNG", function()
        local img = solid(32, 32, 200, 100, 50, 255)
        local sharpened = img:sharpen()
        local path = OUT .. "effect_sharpen.png"
        lurek.img.savePNG(sharpened, path)
        expect_evidence_created(path)
    end)
end)

test_summary()
