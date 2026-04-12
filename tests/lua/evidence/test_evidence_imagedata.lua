-- Evidence test: ImageData pixel creation, manipulation, and PNG save
-- Produces: imagedata_basic.png, imagedata_fill.png, imagedata_mapped.png,
--           imagedata_cropped.png, imagedata_resized.png, imagedata_flipped.png,
--           imagedata_rotated.png
-- @evidence file
-- @covers lurek.img.newImageData
-- @covers lurek.img.savePNG
-- @covers ImageData:setPixel
-- @covers ImageData:fill
-- @covers ImageData:mapPixel
-- @covers ImageData:crop
-- @covers ImageData:resizeNearest
-- @covers ImageData:flipHorizontal
-- @covers ImageData:rotate90cw

describe("evidence: imagedata creation and manipulation", function()
    local OUT

    before_each(function()
        ensure_evidence_dir("image")
        OUT = evidence_output_dir("image")
    end)

    it("creates basic pixel-painted image", function()
        local img = lurek.img.newImageData(16, 16)
        img:setPixel(0,  0,  255, 0,   0,   255)
        img:setPixel(1,  0,  0,   255, 0,   255)
        img:setPixel(2,  0,  0,   0,   255, 255)
        img:setPixel(15, 15, 128, 64,  32,  200)
        local path = OUT .. "imagedata_basic.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates fill image", function()
        local img = lurek.img.newImageData(16, 16)
        img:fill(100, 150, 200, 255)
        local path = OUT .. "imagedata_fill.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates mapPixel inverted image", function()
        local img = lurek.img.newImageData(16, 16)
        img:fill(50, 100, 150, 255)
        img:mapPixel(function(x, y, r, g, b, a)
            return 255 - r, 255 - g, 255 - b, a
        end)
        local path = OUT .. "imagedata_mapped.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates cropped sub-image", function()
        local img = lurek.img.newImageData(16, 16)
        img:fill(200, 100, 50, 255)
        local sub = img:crop(4, 4, 6, 6)
        local path = OUT .. "imagedata_cropped.png"
        lurek.img.savePNG(sub, path)
        expect_evidence_created(path)
    end)

    it("creates resized image", function()
        local img = lurek.img.newImageData(4, 4)
        img:fill(255, 0, 0, 255)
        local big = img:resizeNearest(16, 16)
        local path = OUT .. "imagedata_resized.png"
        lurek.img.savePNG(big, path)
        expect_evidence_created(path)
    end)

    it("creates horizontally flipped image", function()
        local img = lurek.img.newImageData(8, 8)
        img:fill(0, 0, 0, 255)
        -- left half red, right half blue
        for y = 0, 7 do
            for x = 0, 3 do img:setPixel(x, y, 255, 0, 0, 255) end
            for x = 4, 7 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        img:flipHorizontal()
        local path = OUT .. "imagedata_flipped.png"
        lurek.img.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("creates rotated image", function()
        local img = lurek.img.newImageData(4, 8)
        img:fill(255, 128, 0, 255)
        local rotated = img:rotate90cw()
        local path = OUT .. "imagedata_rotated.png"
        lurek.img.savePNG(rotated, path)
        expect_evidence_created(path)
    end)
end)

test_summary()
