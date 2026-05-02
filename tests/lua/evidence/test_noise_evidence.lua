-- Evidence tests: noise module
-- Produces PNG artifacts from lurek.math noise generation functions.

describe("evidence: noise", function()
    before_each(function()
        ensure_evidence_dir("noise")
    end)

    -- @evidence file
    it("renders a Perlin noise field PNG", function()
        local dir  = evidence_output_dir("noise")
        local path = dir .. "perlin_field.png"
        local W, H = 64, 64
        local img = lurek.image.newImageData(W, H)
        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local v = lurek.math.perlin2d(x * 0.08, y * 0.08)
                local c = math.floor((v + 1) * 0.5 * 255)
                c = math.max(0, math.min(255, c))
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders a Simplex noise field PNG", function()
        local dir  = evidence_output_dir("noise")
        local path = dir .. "simplex_field.png"
        local W, H = 64, 64
        local img = lurek.image.newImageData(W, H)
        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local v = lurek.math.simplex2d(x * 0.10, y * 0.10)
                local c = math.floor((v + 1) * 0.5 * 255)
                c = math.max(0, math.min(255, c))
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders a seeded NoiseGenerator PNG", function()
        local dir  = evidence_output_dir("noise")
        local path = dir .. "noise_generator_seeded.png"
        local W, H = 64, 64
        local ng  = lurek.math.newNoiseGenerator(42)
        local img = lurek.image.newImageData(W, H)
        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local v = ng:perlin2d(x * 0.12, y * 0.12)
                local c = math.floor((v + 1) * 0.5 * 255)
                c = math.max(0, math.min(255, c))
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders an fBm noise field PNG", function()
        local dir  = evidence_output_dir("noise")
        local path = dir .. "fbm_field.png"
        local W, H = 64, 64
        local img = lurek.image.newImageData(W, H)
        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local ok, v = pcall(lurek.math.fbm, x * 0.06, y * 0.06)
                if ok then
                    local c = math.floor((v + 1) * 0.5 * 255)
                    c = math.max(0, math.min(255, c))
                    img:setPixel(x, y, c, c, c, 255)
                end
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
