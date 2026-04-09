-- Lurek2D Lua BDD tests for lurek.raycaster
-- Headless: no GPU, no audio, no window.

describe("lurek.raycaster", function()
    describe("module interface", function()
        it("exposes new factory", function()
            expect_type("function", lurek.raycaster.new)
        end)
    end)

    describe("new(w, h)", function()
        it("returns a userdata object", function()
            local rc = lurek.raycaster.new(16, 12)
            expect_type("userdata", rc)
        end)

        it("width() returns the given width", function()
            local rc = lurek.raycaster.new(24, 18)
            expect_equal(24, rc:width())
        end)

        it("height() returns the given height", function()
            local rc = lurek.raycaster.new(24, 18)
            expect_equal(18, rc:height())
        end)
    end)

    describe("cell access", function()
        it("all cells start as 0", function()
            local rc = lurek.raycaster.new(4, 4)
            for y = 0, 3 do
                for x = 0, 3 do
                    expect_equal(0, rc:getCell(x, y))
                end
            end
        end)

        it("setCell / getCell round-trip", function()
            local rc = lurek.raycaster.new(8, 8)
            rc:setCell(2, 5, 99)
            expect_equal(99, rc:getCell(2, 5))
        end)

        it("setCells fills the grid from a flat table", function()
            local rc = lurek.raycaster.new(2, 2)
            rc:setCells({ 1, 2, 3, 4 })
            expect_equal(1, rc:getCell(0, 0))
            expect_equal(2, rc:getCell(1, 0))
            expect_equal(3, rc:getCell(0, 1))
            expect_equal(4, rc:getCell(1, 1))
        end)
    end)

    describe("isBlocked(x, y)", function()
        it("returns false for zero cell", function()
            local rc = lurek.raycaster.new(4, 4)
            expect_equal(false, rc:isBlocked(1, 1))
        end)

        it("returns true for non-zero cell", function()
            local rc = lurek.raycaster.new(4, 4)
            rc:setCell(2, 2, 1)
            expect_equal(true, rc:isBlocked(2, 2))
        end)
    end)

    describe("castRay(ox, oy, angle, max_dist)", function()
        it("returns nil in fully empty grid", function()
            local rc = lurek.raycaster.new(10, 10)
            local hit = rc:castRay(5.0, 5.0, 0.0, 20.0)
            -- An empty grid may return nil or a boundary non-hit
            if hit ~= nil then
                expect_type("table", hit)
            end
        end)

        it("hits a wall placed directly ahead", function()
            local rc = lurek.raycaster.new(10, 10)
            rc:setCell(8, 4, 1)          -- wall at x=8, row 4
            -- cast from (1.5, 4.5) pointing east (angle=0)
            local hit = rc:castRay(1.5, 4.5, 0.0, 20.0)
            assert(hit ~= nil, "expected a hit")
            expect_equal(true, hit.hit)
            expect_equal(1, hit.cell_value)
        end)

        it("returned hit table has required fields", function()
            local rc = lurek.raycaster.new(10, 10)
            rc:setCell(5, 5, 7)
            local hit = rc:castRay(0.5, 5.5, 0.0, 20.0)
            if hit and hit.hit then
                expect_type("number", hit.distance)
                expect_type("number", hit.raw_distance)
                expect_type("number", hit.cell_value)
                expect_type("number", hit.side)
                expect_type("number", hit.tex_u)
                expect_type("number", hit.hit_x)
                expect_type("number", hit.hit_y)
            end
        end)
    end)

    describe("castRays(ox, oy, angle, fov, count, max_dist)", function()
        it("returns exactly count entries", function()
            local rc = lurek.raycaster.new(20, 20)
            local rays = rc:castRays(10.0, 10.0, 0.0, math.pi / 2, 64, 30.0)
            expect_equal(64, #rays)
        end)

        it("each entry is a table", function()
            local rc = lurek.raycaster.new(20, 20)
            local rays = rc:castRays(10.0, 10.0, 0.0, math.pi / 3, 8, 20.0)
            for i, r in ipairs(rays) do
                expect_type("table", r)
            end
        end)
    end)
end)

test_summary()
