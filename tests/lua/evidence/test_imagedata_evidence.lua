-- Evidence tests: imagedata module
-- Produces PNG artifacts from lurek.image.newImageData pixel manipulation.

describe("evidence: imagedata", function()
    before_each(function()
        ensure_evidence_dir("imagedata")
    end)

    -- @evidence file
    it("produces a pixel-grid PNG from setPixel", function()
        local dir  = evidence_output_dir("imagedata")
        local path = dir .. "pixel_grid.png"
        local W, H = 64, 64
        local CELL = 8
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 20, 255)
        for row = 0, math.floor(W / CELL) - 1 do
            for col = 0, math.floor(H / CELL) - 1 do
                local r = math.floor((row / 7) * 200) + 55
                local g = math.floor((col / 7) * 200) + 55
                local b = 180
                for dy = 1, CELL - 2 do
                    for dx = 1, CELL - 2 do
                        img:setPixel(col * CELL + dx, row * CELL + dy, r, g, b, 255)
                    end
                end
            end
        end
        local r, g, b, a = img:getPixel(CELL + 1, 1)
        expect_true(a == 255, "pixel alpha must be 255")
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a shapes PNG from drawRect, drawCircle, drawLine", function()
        local dir  = evidence_output_dir("imagedata")
        local path = dir .. "shapes.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(240, 240, 240, 255)
        img:drawRect(10, 10, 80, 60, 200, 60, 60, 255)
        img:drawRect(110, 10, 80, 60, 60, 60, 200, 255)
        img:drawCircle(100, 130, 50, 60, 180, 60, 255)
        img:drawLine(10, 180, 190, 20, 180, 100, 20, 255)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a filtered images PNG", function()
        local dir  = evidence_output_dir("imagedata")
        -- Save four variations side-by-side in separate files for clarity
        local function make_base()
            local img = lurek.image.newImageData(100, 100)
            img:fill(80, 130, 200, 255)
            img:drawRect(20, 20, 60, 60, 220, 80, 50, 255)
            img:drawCircle(50, 50, 25, 255, 220, 50, 255)
            return img
        end

        local blurred = make_base()
        blurred:blur(3)
        local p1 = dir .. "filter_blur.png"
        lurek.image.savePNG(blurred, p1)
        expect_evidence_created(p1)

        local bright = make_base()
        bright:brightness(1.4)
        local p2 = dir .. "filter_brightness.png"
        lurek.image.savePNG(bright, p2)
        expect_evidence_created(p2)

        local grey = make_base()
        grey:grayscale()
        local p3 = dir .. "filter_grayscale.png"
        lurek.image.savePNG(grey, p3)
        expect_evidence_created(p3)
    end)

    -- @evidence file
    it("produces a cropped image PNG", function()
        local dir  = evidence_output_dir("imagedata")
        local path = dir .. "cropped.png"
        local img = lurek.image.newImageData(200, 200)
        img:fill(60, 80, 180, 255)
        img:drawRect(50, 50, 100, 100, 220, 100, 50, 255)
        local w, h = img:getDimensions()
        expect_true(w == 200 and h == 200, "dimensions must be 200x200")
        local cropped = img:crop(40, 40, 120, 120)
        lurek.image.savePNG(cropped, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
