-- test_evidence_raycaster.lua
-- Evidence test: lurek.raycaster API contracts and pixel-level PNG evidence

-- The raycaster casts rays through a 2D grid and returns hit data.
-- Tests verify correctness of ray geometry and render results to a PNG
-- "depth buffer" image so the output can be visually inspected.

local OUT = "tests/lua/evidence/output/raycaster/"

-- @description Covers suite: Evidence: lurek.raycaster API contracts.
describe("Evidence: lurek.raycaster API contracts", function()
    end)
    end)
        for y = 0, 15 do
            rc:setCell(0, y, 1)
            rc:setCell(15, y, 1)
        end
        local rays = rc:castRays(8.0, 8.0, 0.0, math.pi / 2, 60, 30)
    end)
    -- @covers Raycaster:setCell
    -- @covers Raycaster:castRaysFlat
    -- @covers lurek.raycaster.distanceShade
    -- @covers lurek.raycaster.projectColumn
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Casts a full ray fan across a boxed room and saves the resulting depth buffer visualization as PNG evidence.
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

        local img = lurek.image.newImageData(W, H)
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

        lurek.image.savePNG(img, OUT .. "raycaster_depth.png")
    end)

end)
test_summary()
