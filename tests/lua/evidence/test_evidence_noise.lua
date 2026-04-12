-- test_evidence_noise.lua
-- Evidence test: Noise functions visualised as grayscale images

local OUT = "tests/lua/evidence/output/noise/"

local function noise_to_byte(v)
    -- Map [-1, 1] → [0, 255]
    local clamped = math.max(-1, math.min(1, v))
    return math.floor((clamped + 1) * 0.5 * 255 + 0.5)
end

describe("Evidence: Noise generation", function()

    it("generates Perlin 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.img.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:perlin2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.img.savePNG(img, OUT .. "noise_perlin2d.png")
    end)

    it("generates Simplex 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.img.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:simplex2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.img.savePNG(img, OUT .. "noise_simplex2d.png")
    end)

    it("generates FBM noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.img.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:fbm(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.img.savePNG(img, OUT .. "noise_fbm.png")
    end)

    it("generates Worley 2D noise image", function()
        local size = 256
        local scale = 30
        local img = lurek.img.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:worley2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.img.savePNG(img, OUT .. "noise_worley2d.png")
    end)

    it("generates Ridged noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.img.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:ridged(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.img.savePNG(img, OUT .. "noise_ridged.png")
    end)

    it("generates Turbulence noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.img.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:turbulence(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.img.savePNG(img, OUT .. "noise_turbulence.png")
    end)

end)

test_summary()
