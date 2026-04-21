-- test_evidence_noise.lua
-- Evidence test: Noise functions visualised as grayscale images

local OUT = "tests/lua/evidence/output/noise/"

local function noise_to_byte(v)
    -- Map [-1, 1] â†’ [0, 255]
    local clamped = math.max(-1, math.min(1, v))
    return math.floor((clamped + 1) * 0.5 * 255 + 0.5)
end

-- @description Covers suite: Evidence: Noise generation.
describe("Evidence: Noise generation", function()

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:perlin2d
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples Perlin noise over a 2D grid and writes the grayscale field to a PNG.
    it("generates Perlin 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:perlin2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_perlin2d.png")
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:simplex2d
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples Simplex noise over a 2D grid and writes the grayscale field to a PNG.
    it("generates Simplex 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:simplex2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_simplex2d.png")
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:fbm
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples FBM noise with multiple octaves and writes the grayscale field to a PNG.
    it("generates FBM noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:fbm(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_fbm.png")
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:worley2d
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples Worley noise and writes the resulting cell-like structure to a PNG.
    it("generates Worley 2D noise image", function()
        local size = 256
        local scale = 30
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:worley2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_worley2d.png")
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:ridged
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples ridged noise and writes the high-contrast ridge pattern to a PNG.
    it("generates Ridged noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:ridged(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_ridged.png")
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:turbulence
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples turbulence noise and writes the resulting warped grayscale field to a PNG.
    it("generates Turbulence noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:turbulence(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_turbulence.png")
    end)

end)
test_summary()
