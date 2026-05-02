-- Evidence tests: easing module
-- Produces PNG artifacts visualising easing curves.

describe("evidence: easing", function()
    before_each(function()
        ensure_evidence_dir("easing")
    end)

    -- @evidence file
    it("plots quad easing curves to PNG", function()
        local dir  = evidence_output_dir("easing")
        local path = dir .. "easing_quad.png"
        local W, H = 400, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(245, 245, 245, 255)
        -- grid lines
        for x = 0, W - 1 do img:setPixel(x, math.floor(H / 2), 210, 210, 210, 255) end
        for y = 0, H - 1 do img:setPixel(math.floor(W / 2), y, 210, 210, 210, 255) end

        local funcs = {
            { fn = lurek.math.linear,    r = 100, g = 100, b = 100 },
            { fn = lurek.math.inQuad,    r = 220, g = 60,  b = 60  },
            { fn = lurek.math.outQuad,   r = 60,  g = 160, b = 60  },
            { fn = lurek.math.inOutQuad, r = 60,  g = 60,  b = 220 },
        }
        for _, e in ipairs(funcs) do
            for i = 0, W - 1 do
                local t  = i / (W - 1)
                local v  = e.fn(t)
                local px = i
                local py = math.floor((1 - v) * (H - 1) + 0.5)
                py = math.max(0, math.min(H - 1, py))
                img:setPixel(px, py, e.r, e.g, e.b, 255)
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("plots cubic and bounce easing curves to PNG", function()
        local dir  = evidence_output_dir("easing")
        local path = dir .. "easing_cubic_bounce.png"
        local W, H = 400, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(250, 250, 250, 255)
        local funcs = {
            { fn = lurek.math.inCubic,   r = 200, g = 80,  b = 80  },
            { fn = lurek.math.outCubic,  r = 80,  g = 180, b = 80  },
            { fn = lurek.math.outBounce, r = 80,  g = 80,  b = 200 },
        }
        for _, e in ipairs(funcs) do
            for i = 0, W - 1 do
                local t  = i / (W - 1)
                local v  = e.fn(t)
                local px = i
                local py = math.floor((1 - v) * (H - 1) + 0.5)
                py = math.max(0, math.min(H - 1, py))
                img:setPixel(px, py, e.r, e.g, e.b, 255)
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("applyEasing covers all standard names evidence heatmap PNG", function()
        local dir  = evidence_output_dir("easing")
        local path = dir .. "easing_values.png"
        local names = {
            "linear", "inQuad", "outQuad", "inOutQuad",
            "inCubic", "outCubic", "inOutCubic",
            "inSine", "outSine", "inOutSine",
            "inExpo", "outExpo", "inOutExpo",
            "outBounce", "inBounce",
        }
        local W = 100
        local H = #names
        local img = lurek.image.newImageData(W, H)
        for row, name in ipairs(names) do
            for col = 0, W - 1 do
                local t = col / (W - 1)
                local ok, v = pcall(lurek.math.applyEasing, name, t)
                local bright = ok and math.max(0, math.min(255, math.floor(v * 255))) or 128
                img:setPixel(col, row - 1, bright, math.floor(bright * 0.5), 255 - bright, 255)
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
