-- Evidence tests: shapes module
-- Produces PNG artifacts from ImageData shape drawing primitives.

describe("evidence: shapes", function()
    before_each(function()
        ensure_evidence_dir("shapes")
    end)

    -- @evidence file
    it("draws a colour rectangle grid PNG", function()
        local dir  = evidence_output_dir("shapes")
        local path = dir .. "rect_grid.png"
        local W, H = 200, 200
        local CELL = 50
        local img = lurek.image.newImageData(W, H)
        img:fill(30, 30, 30, 255)
        local colours = {
            { 220, 60,  60  },
            { 60,  180, 60  },
            { 60,  60,  220 },
            { 220, 180, 60  },
            { 180, 60,  180 },
            { 60,  180, 180 },
            { 220, 120, 60  },
            { 120, 60,  220 },
            { 60,  220, 120 },
            { 220, 220, 60  },
            { 60,  220, 220 },
            { 220, 60,  120 },
            { 120, 220, 60  },
            { 180, 180, 180 },
            { 220, 100, 100 },
            { 100, 100, 220 },
        }
        local ci = 1
        for row = 0, math.floor(W / CELL) - 1 do
            for col = 0, math.floor(H / CELL) - 1 do
                local c = colours[ci]
                img:drawRect(col * CELL + 2, row * CELL + 2, CELL - 4, CELL - 4, c[1], c[2], c[3], 255)
                ci = (ci % #colours) + 1
            end
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("draws concentric circles PNG", function()
        local dir  = evidence_output_dir("shapes")
        local path = dir .. "circles.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 40, 255)
        local radii = { 90, 72, 54, 36, 18 }
        local cs = {
            { 220, 50,  50  },
            { 220, 150, 50  },
            { 50,  200, 80  },
            { 50,  120, 220 },
            { 180, 50,  220 },
        }
        for i, r in ipairs(radii) do
            local c = cs[i]
            img:drawCircle(100, 100, r, c[1], c[2], c[3], 255)
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("draws radiating lines PNG", function()
        local dir  = evidence_output_dir("shapes")
        local path = dir .. "radiating_lines.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(15, 15, 30, 255)
        local cx, cy = 100, 100
        local steps = 36
        for i = 0, steps - 1 do
            local angle = (i / steps) * math.pi * 2
            local ex = math.floor(cx + math.cos(angle) * 90 + 0.5)
            local ey = math.floor(cy + math.sin(angle) * 90 + 0.5)
            local r = math.floor((math.cos(angle) + 1) * 0.5 * 200) + 55
            local g = math.floor((math.sin(angle) + 1) * 0.5 * 200) + 55
            local b = math.floor(255 - r * 0.5)
            img:drawLine(cx, cy, ex, ey, r, g, b, 220)
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a paste composite PNG", function()
        local dir  = evidence_output_dir("shapes")
        local path = dir .. "paste_composite.png"
        local base = lurek.image.newImageData(200, 200)
        base:fill(60, 100, 160, 255)
        base:drawRect(10, 10, 180, 180, 80, 120, 200, 255)

        local stamp = lurek.image.newImageData(60, 60)
        stamp:fill(0, 0, 0, 0)
        stamp:drawCircle(30, 30, 28, 220, 80, 50, 255)

        base:paste(stamp, 70, 70)
        lurek.image.savePNG(base, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
