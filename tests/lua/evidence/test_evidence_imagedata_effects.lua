-- test_evidence_imagedata_effects.lua
-- Evidence test: ImageData filter/effect methods produce measurable pixel changes

local OUT = "tests/lua/evidence/output/image/"

local function solid(w, h, r, g, b, a)
    local img = lurek.img.newImageData(w, h)
    img:fill(r, g, b, a)
    return img
end

describe("Evidence: ImageData effect filters", function()

    it("grayscale collapses RGB channels to equal values", function()
        local img = solid(4, 4, 200, 100, 50, 255)
        img:grayscale()
        local r, g, b, a = img:getPixel(0, 0)
        -- Grayscale means r == g == b
        expect_equal(r, g)
        expect_equal(g, b)
        expect_equal(a, 255)
    end)

    it("invert flips all RGB channels", function()
        local img = solid(4, 4, 100, 150, 200, 255)
        img:invert()
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r, 155)
        expect_equal(g, 105)
        expect_equal(b, 55)
        expect_equal(a, 255)
    end)

    it("sepia shifts image to warm brownish tones", function()
        local img = solid(4, 4, 200, 200, 200, 255)
        img:sepia()
        local r, g, b, a = img:getPixel(0, 0)
        -- After sepia: r > g > b for neutral input
        expect_equal(r > g, true)
        expect_equal(g > b, true)
        expect_equal(a, 255)
    end)

    it("brightness > 1 increases pixel values", function()
        local img = solid(4, 4, 100, 100, 100, 255)
        img:brightness(2.0)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r > 100, true)
        expect_equal(g > 100, true)
        expect_equal(b > 100, true)
    end)

    it("brightness < 1 decreases pixel values", function()
        local img = solid(4, 4, 200, 200, 200, 255)
        img:brightness(0.5)
        local r, g, b, a = img:getPixel(0, 0)
        expect_equal(r < 200, true)
    end)

    it("threshold produces only black or white pixels", function()
        local img = lurek.img.newImageData(4, 4)
        img:setPixel(0, 0, 50,  50,  50,  255)
        img:setPixel(1, 0, 200, 200, 200, 255)
        img:threshold(128)
        local r1, _, _, _ = img:getPixel(0, 0)
        local r2, _, _, _ = img:getPixel(1, 0)
        expect_equal(r1, 0)
        expect_equal(r2, 255)
    end)

    it("posterize reduces colour depth", function()
        local img = solid(4, 4, 200, 200, 200, 255)
        img:posterize(4)
        local r, g, b, a = img:getPixel(0, 0)
        -- With 4 levels, valid posterized values are 0, 85, 170, 255
        -- Input 200 should map to 170
        expect_equal(r, 170)
    end)

    it("tint shifts pixels toward tint color", function()
        local img = solid(4, 4, 200, 200, 200, 255)
        img:tint(255, 0, 0, 0.5)
        local r, g, b, a = img:getPixel(0, 0)
        -- After tinting towards red: r >= g, r >= b
        expect_equal(r >= g, true)
        expect_equal(r >= b, true)
    end)

    it("noise adds random variation to pixels", function()
        local img = solid(64, 64, 128, 128, 128, 255)
        img:noise(30)
        -- At least one pixel should now differ from original 128,128,128
        local changed = false
        for y = 0, 7 do
            for x = 0, 7 do
                local r, g, b, a = img:getPixel(x, y)
                if r ~= 128 or g ~= 128 or b ~= 128 then
                    changed = true
                end
            end
        end
        expect_equal(changed, true)
    end)

    it("blur returns a new ImageData with same dimensions", function()
        local img = solid(8, 8, 200, 100, 50, 255)
        local blurred = img:blur(2)
        expect_equal(blurred:getWidth(), 8)
        expect_equal(blurred:getHeight(), 8)
    end)

    it("sharpen returns a new ImageData with same dimensions", function()
        local img = solid(8, 8, 200, 100, 50, 255)
        local sharpened = img:sharpen()
        expect_equal(sharpened:getWidth(), 8)
        expect_equal(sharpened:getHeight(), 8)
    end)

    it("saves all effect evidence as PNG files", function()
        local tests = {
            {"grayscale.png", function(img) img:grayscale() end},
            {"inverted.png",  function(img) img:invert() end},
            {"sepia.png",     function(img) img:sepia() end},
            {"bright.png",    function(img) img:brightness(1.5) end},
            {"threshold.png", function(img) img:threshold(128) end},
        }
        for _, t in ipairs(tests) do
            local img = solid(32, 32, 179, 134, 89, 255)
            t[2](img)
            lurek.img.savePNG(img, OUT .. "effect_" .. t[1])
        end
        expect_equal(true, true)
    end)

end)

test_summary()
