-- Lurek2D Stress Test: Image Operations
-- Measures image creation and pixel operation throughput.
-- @stress lurek.image.newImage
-- @stress lurek.image.getPixel
-- @stress lurek.image.setPixel

describe("stress: image creation throughput", function()
    it("create 100 images (64×64) without error: <10s", function()
        local COUNT  = 100
        local images = {}

        local elapsed = measure("image.newImage 64x64 x" .. COUNT, COUNT, function()
            local img = lurek.image.newImage(64, 64)
            images[#images + 1] = img
        end)

        expect_true(elapsed < 10.0, "image creation budget: " .. elapsed .. "s")
        expect_equal(COUNT, #images, "all images created")
    end)

    it("pixel read 10000 times on single image: <5s", function()
        local img   = lurek.image.newImage(64, 64)
        local COUNT = 10000

        local elapsed = measure("image:getPixel x" .. COUNT, COUNT, function()
            local _ = img:getPixel(math.random(0, 63), math.random(0, 63))
        end)

        expect_true(elapsed < 5.0, "pixel read budget: " .. elapsed .. "s")
    end)

    it("pixel write 10000 times on single image: <5s", function()
        local img   = lurek.image.newImage(64, 64)
        local COUNT = 10000

        local elapsed = measure("image:setPixel x" .. COUNT, COUNT, function()
            img:setPixel(math.random(0, 63), math.random(0, 63),
                math.random(), math.random(), math.random(), 1.0)
        end)

        expect_true(elapsed < 5.0, "pixel write budget: " .. elapsed .. "s")
    end)
end)

test_summary()
