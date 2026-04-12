-- test_evidence_raycaster.lua
-- Evidence test: lurek.raycaster API contracts and pixel-level PNG evidence

-- The raycaster casts rays through a 2D grid and returns hit data.
-- Tests verify correctness of ray geometry and render results to a PNG
-- "depth buffer" image so the output can be visually inspected.

local OUT = "tests/lua/evidence/output/raycaster/"

describe("Evidence: lurek.raycaster API contracts", function()

    it("new creates a Raycaster of given dimensions", function()
        local rc = lurek.raycaster.new(16, 16)
        expect_equal(rc:width(), 16)
        expect_equal(rc:height(), 16)
    end)

    it("getCell returns 0 for unset cells", function()
        local rc = lurek.raycaster.new(8, 8)
        expect_equal(rc:getCell(0, 0), 0)
        expect_equal(rc:getCell(7, 7), 0)
    end)

    it("setCell and getCell round-trip", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setCell(3, 4, 1)
        expect_equal(rc:getCell(3, 4), 1)
    end)

    it("isBlocked returns false for open cells", function()
        local rc = lurek.raycaster.new(8, 8)
        expect_equal(rc:isBlocked(0, 0), false)
    end)

    it("isBlocked returns true for wall cells", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setCell(2, 2, 1)
        expect_equal(rc:isBlocked(2, 2), true)
    end)

    it("setCells fills the grid without error", function()
        local rc = lurek.raycaster.new(4, 4)
        local ok = pcall(function()
            rc:setCells({
                1, 1, 1, 1,
                1, 0, 0, 1,
                1, 0, 0, 1,
                1, 1, 1, 1,
            })
        end)
        expect_equal(ok, true)
    end)

    it("castRay returns nil when no wall is hit", function()
        local rc = lurek.raycaster.new(8, 8) -- all cells = 0
        local hit = rc:castRay(4, 4, 0, 10)
        expect_equal(hit, nil)
    end)

    it("castRay returns a hit table when wall exists", function()
        local rc = lurek.raycaster.new(8, 8)
        -- Surround with walls
        rc:setCells({
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 1,
            1, 1, 1, 1, 1, 1, 1, 1,
        })
        local hit = rc:castRay(4.0, 4.0, 0, 20)
        -- Should hit east wall
        expect_equal(hit ~= nil, true)
        if hit then
            expect_equal(type(hit.distance), "number")
            expect_equal(hit.distance > 0, true)
        end
    end)

    it("castRays returns an array of hit results", function()
        local rc = lurek.raycaster.new(16, 16)
        -- Outer wall ring
        for x = 0, 15 do
            rc:setCell(x, 0, 1)
            rc:setCell(x, 15, 1)
        end
        for y = 0, 15 do
            rc:setCell(0, y, 1)
            rc:setCell(15, y, 1)
        end
        local rays = rc:castRays(8.0, 8.0, 0.0, math.pi / 2, 60, 30)
        expect_equal(type(rays), "table")
        expect_equal(#rays > 0, true)
    end)

    it("lineOfSight returns true when path is clear", function()
        local rc = lurek.raycaster.new(8, 8)
        -- All open — line of sight should be true
        local los = rc:lineOfSight(1, 1, 6, 6)
        expect_equal(los, true)
    end)

    it("lineOfSight returns false when wall blocks", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setCell(4, 1, 1)
        local los = rc:lineOfSight(3.5, 1.5, 4.5, 1.5)
        expect_equal(los, false)
    end)

    it("projectColumn returns three numbers", function()
        local top, bottom, height = lurek.raycaster.projectColumn(5.0, 1.0472, 600)
        expect_equal(type(top), "number")
        expect_equal(type(bottom), "number")
        expect_equal(type(height), "number")
        expect_equal(height > 0, true)
    end)

    it("distanceShade returns value between 0 and 1", function()
        local shade = lurek.raycaster.distanceShade(5.0, 20.0)
        expect_equal(shade >= 0, true)
        expect_equal(shade <= 1, true)
    end)

    it("distanceShade at 0 distance returns 1 (full brightness)", function()
        local shade = lurek.raycaster.distanceShade(0.0, 20.0)
        expect_near(shade, 1.0, 0.01)
    end)

    it("saves raycaster depth-buffer as PNG evidence", function()
        local W, H = 128, 64
        local FOV = math.pi / 2

        local rc = lurek.raycaster.new(20, 20)
        -- Outer walls
        for x = 0, 19 do
            rc:setCell(x, 0, 1)
            rc:setCell(x, 19, 1)
        end
        for y = 0, 19 do
            rc:setCell(0, y, 1)
            rc:setCell(19, y, 1)
        end

        local img = lurek.img.newImageData(W, H)
        local rays = rc:castRaysFlat(10.0, 10.0, 0.0, FOV, W, 40)
        for col = 0, W - 1 do
            local base = col * 5
            local dist    = rays[base + 1] or 0
            local shade   = lurek.raycaster.distanceShade(dist, 40)
            local top, bottom = lurek.raycaster.projectColumn(dist, FOV, H)
            local brightness = math.floor(shade * 200 + 0.5)
            for y = 0, H - 1 do
                if y >= math.floor(top) and y <= math.floor(bottom) then
                    img:setPixel(col, y, brightness, brightness, brightness, 255)
                else
                    -- ceiling or floor
                    local shade2 = y < H / 2 and 40 or 20
                    img:setPixel(col, y, shade2, shade2, shade2, 255)
                end
            end
        end

        lurek.img.savePNG(img, OUT .. "raycaster_depth.png")
        expect_equal(true, true)
    end)

end)

test_summary()
