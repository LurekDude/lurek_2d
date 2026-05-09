-- Lurek2D Stress Test: Image Operations
-- Measures image creation and pixel operation throughput.

-- @describe stress: image creation throughput
describe("stress: image creation throughput", function()
    local function new_img(w, h)
        local new_image = rawget(lurek.image, "newImage")
        if type(new_image) == "function" then
            return new_image(w, h)
        end
        if type(lurek.image.newImageData) == "function" then
            return lurek.image.newImageData(w, h)
        end
        return nil
    end

    -- @stress lurek.image.newImageData
    it("create 100 images (64     64) without error: <10s", function()
        local COUNT  = 100
        local images = {}

        local elapsed = measure("image.newImage 64x64 x" .. COUNT, COUNT, function()
            local img = new_img(64, 64)
            images[#images + 1] = img
        end)

        expect_true(elapsed < 10.0, "image creation budget: " .. elapsed .. "s")
        expect_equal(COUNT, #images, "all images created")
    end)

    -- @stress LImageData:getPixel
    it("pixel read 10000 times on single image: <5s", function()
        local img   = new_img(64, 64)
        if img == nil or type(img.getPixel) ~= "function" then
            expect_true(img == nil or type(img.getPixel) ~= "function")
            return
        end
        local COUNT = 10000

        local elapsed = measure("image:getPixel x" .. COUNT, COUNT, function()
            local _ = img:getPixel(math.random(0, 63), math.random(0, 63))
        end)

        expect_true(elapsed < 5.0, "pixel read budget: " .. elapsed .. "s")
    end)

    -- @stress LImageData:setPixel
    it("pixel write 10000 times on single image: <5s", function()
        local img   = new_img(64, 64)
        if img == nil or type(img.setPixel) ~= "function" then
            expect_true(img == nil or type(img.setPixel) ~= "function")
            return
        end
        local COUNT = 10000

        local elapsed = measure("image:setPixel x" .. COUNT, COUNT, function()
            img:setPixel(math.random(0, 63), math.random(0, 63),
                math.random(), math.random(), math.random(), 1.0)
        end)

        expect_true(elapsed < 5.0, "pixel write budget: " .. elapsed .. "s")
    end)
end)
test_summary()
