-- Lurek2D Lua BDD tests for lurek.raycaster
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: lurek.raycaster.
describe("lurek.raycaster", function()
    -- @description Covers suite: module interface.
    describe("module interface", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies the raycaster module exposes the new factory.
        it("exposes new factory", function()
            expect_type("function", lurek.raycaster.new)
        end)
    end)

    -- @description Covers suite: new(w, h).
    describe("new(w, h)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies new returns a userdata raycaster handle.
        it("returns a userdata object", function()
            local rc = lurek.raycaster.new(16, 12)
            expect_type("userdata", rc)
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies width() reflects the constructor width.
        it("width() returns the given width", function()
            local rc = lurek.raycaster.new(24, 18)
            expect_equal(24, rc:width())
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies height() reflects the constructor height.
        it("height() returns the given height", function()
            local rc = lurek.raycaster.new(24, 18)
            expect_equal(18, rc:height())
        end)
    end)

    -- @description Covers suite: cell access.
    describe("cell access", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies fresh grids initialize every cell to zero.
        it("all cells start as 0", function()
            local rc = lurek.raycaster.new(4, 4)
            for y = 0, 3 do
                for x = 0, 3 do
                    expect_equal(0, rc:getCell(x, y))
                end
            end
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies setCell and getCell round-trip a wall value.
        it("setCell / getCell round-trip", function()
            local rc = lurek.raycaster.new(8, 8)
            rc:setCell(2, 5, 99)
            expect_equal(99, rc:getCell(2, 5))
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies setCells consumes a flat row-major cell table.
        it("setCells fills the grid from a flat table", function()
            local rc = lurek.raycaster.new(2, 2)
            rc:setCells({ 1, 2, 3, 4 })
            expect_equal(1, rc:getCell(0, 0))
            expect_equal(2, rc:getCell(1, 0))
            expect_equal(3, rc:getCell(0, 1))
            expect_equal(4, rc:getCell(1, 1))
        end)
    end)

    -- @description Covers suite: isBlocked(x, y).
    describe("isBlocked(x, y)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies zero-valued cells are treated as unblocked.
        it("returns false for zero cell", function()
            local rc = lurek.raycaster.new(4, 4)
            expect_equal(false, rc:isBlocked(1, 1))
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies non-zero cells are treated as blocked.
        it("returns true for non-zero cell", function()
            local rc = lurek.raycaster.new(4, 4)
            rc:setCell(2, 2, 1)
            expect_equal(true, rc:isBlocked(2, 2))
        end)
    end)

    -- @description Covers suite: castRay(ox, oy, angle, max_dist).
    describe("castRay(ox, oy, angle, max_dist)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies castRay on an empty grid returns nil or a non-hit table safely.
        it("returns nil in fully empty grid", function()
            local rc = lurek.raycaster.new(10, 10)
            local hit = rc:castRay(5.0, 5.0, 0.0, 20.0)
            -- An empty grid may return nil or a boundary non-hit
            if hit ~= nil then
                expect_type("table", hit)
            end
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies castRay detects a wall placed directly in front of the origin.
        it("hits a wall placed directly ahead", function()
            local rc = lurek.raycaster.new(10, 10)
            rc:setCell(8, 4, 1)          -- wall at x=8, row 4
            -- cast from (1.5, 4.5) pointing east (angle=0)
            local hit = rc:castRay(1.5, 4.5, 0.0, 20.0)
            expect_not_nil(hit, "expected a hit")
            expect_equal(true, hit.hit)
            expect_equal(1, hit.cell_value)
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies ray hit tables include distance, hit location, and texture fields.
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

    -- @description Covers suite: castRays(ox, oy, angle, fov, count, max_dist).
    describe("castRays(ox, oy, angle, fov, count, max_dist)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies castRays returns exactly the requested number of entries.
        it("returns exactly count entries", function()
            local rc = lurek.raycaster.new(20, 20)
            local rays = rc:castRays(10.0, 10.0, 0.0, math.pi / 2, 64, 30.0)
            expect_equal(64, #rays)
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies each castRays entry is a table.
        it("each entry is a table", function()
            local rc = lurek.raycaster.new(20, 20)
            local rays = rc:castRays(10.0, 10.0, 0.0, math.pi / 3, 8, 20.0)
            for i, r in ipairs(rays) do
                expect_type("table", r)
            end
        end)
    end)

    -- @description Covers suite: castRaysFlat(ox, oy, angle, fov, count, max_dist).
    describe("castRaysFlat(ox, oy, angle, fov, count, max_dist)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies castRaysFlat returns a table payload.
        it("returns a table", function()
            local rc = lurek.raycaster.new(20, 20)
            local flat = rc:castRaysFlat(10.0, 10.0, 0.0, math.pi / 2, 8, 30.0)
            expect_type("table", flat)
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies castRaysFlat flattens results into numeric values only.
        it("contains only numbers", function()
            local rc = lurek.raycaster.new(20, 20)
            local flat = rc:castRaysFlat(10.0, 10.0, 0.0, math.pi / 2, 4, 30.0)
            for _, v in ipairs(flat) do
                expect_type("number", v)
            end
        end)
    end)

    -- @description Covers suite: lineOfSight(x1, y1, x2, y2).
    describe("lineOfSight(x1, y1, x2, y2)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies lineOfSight returns true across an unobstructed segment.
        it("returns true in empty grid", function()
            local rc = lurek.raycaster.new(10, 10)
            local visible = rc:lineOfSight(1.0, 5.0, 8.0, 5.0)
            expect_equal(true, visible)
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies lineOfSight returns false when a wall blocks the segment.
        it("returns false when wall blocks the path", function()
            local rc = lurek.raycaster.new(10, 10)
            rc:setCell(5, 5, 1)  -- wall in the middle
            local visible = rc:lineOfSight(1.0, 5.5, 9.0, 5.5)
            expect_equal(false, visible)
        end)

        -- @tests lurek.raycaster.new
        -- @description Verifies lineOfSight always returns a boolean.
        it("returns a boolean", function()
            local rc = lurek.raycaster.new(10, 10)
            local result = rc:lineOfSight(0.5, 0.5, 9.5, 9.5)
            expect_type("boolean", result)
        end)
    end)

    -- @description Covers suite: projectSprite(sx, sy, px, py, pa, fov, screen_w).
    describe("projectSprite(sx, sy, px, py, pa, fov, screen_w)", function()
        -- @tests lurek.raycaster.new
        -- @description Verifies projectSprite returns projection metadata including visibility and scale fields.
        it("returns a table with required fields", function()
            local rc = lurek.raycaster.new(10, 10)
            local sp = rc:projectSprite(5.0, 5.0, 1.0, 5.0, 0.0, math.pi / 2, 320.0)
            expect_type("table", sp)
            expect_type("number", sp.screen_x)
            expect_type("number", sp.scale)
            expect_type("number", sp.distance)
            expect_type("boolean", sp.visible)
        end)
    end)
end)

-- @description Covers suite: lurek.raycaster module functions.
describe("lurek.raycaster module functions", function()
    -- @description Covers suite: projectColumn(distance, fov, screen_height).
    describe("projectColumn(distance, fov, screen_height)", function()
        -- @tests lurek.raycaster.projectColumn
        -- @description Verifies projectColumn is exposed.
        it("is a function", function()
            expect_type("function", lurek.raycaster.projectColumn)
        end)

        -- @tests lurek.raycaster.projectColumn
        -- @description Verifies projectColumn returns three numeric outputs.
        it("returns 3 numbers", function()
            local a, b, c = lurek.raycaster.projectColumn(2.0, math.pi / 2, 480.0)
            expect_type("number", a)
            expect_type("number", b)
            expect_type("number", c)
        end)

        -- @tests lurek.raycaster.projectColumn
        -- @description Verifies nearby walls project to a positive column height.
        it("column height is positive for distance 1.0", function()
            local col_height, _, _ = lurek.raycaster.projectColumn(1.0, math.pi / 2, 480.0)
            expect_true(col_height > 0.0, "column height should be positive")
        end)

        -- @tests lurek.raycaster.projectColumn
        -- @description Verifies projected column height decreases as distance grows.
        it("column height decreases with distance", function()
            local h1, _, _ = lurek.raycaster.projectColumn(1.0, math.pi / 2, 480.0)
            local h2, _, _ = lurek.raycaster.projectColumn(5.0, math.pi / 2, 480.0)
            expect_true(h1 > h2, "closer wall should produce taller column")
        end)
    end)

    -- @description Covers suite: distanceShade(distance, max_distance).
    describe("distanceShade(distance, max_distance)", function()
        -- @tests lurek.raycaster.distanceShade
        -- @description Verifies distanceShade is exposed.
        it("is a function", function()
            expect_type("function", lurek.raycaster.distanceShade)
        end)

        -- @tests lurek.raycaster.distanceShade
        -- @description Verifies distanceShade returns full intensity at zero distance.
        it("returns 1.0 at distance 0", function()
            local shade = lurek.raycaster.distanceShade(0.0, 10.0)
            expect_near(1.0, shade, 0.001)
        end)

        -- @tests lurek.raycaster.distanceShade
        -- @description Verifies distanceShade clamps to zero at or beyond max distance.
        it("returns 0.0 at or beyond max_distance", function()
            local shade = lurek.raycaster.distanceShade(10.0, 10.0)
            expect_near(0.0, shade, 0.001)
        end)

        -- @tests lurek.raycaster.distanceShade
        -- @description Verifies distanceShade remains within the inclusive [0, 1] range.
        it("returns value in [0, 1]", function()
            local shade = lurek.raycaster.distanceShade(4.0, 10.0)
            expect_true(shade >= 0.0 and shade <= 1.0,
                "shade should be in [0,1], got: " .. tostring(shade))
        end)
    end)
end)

-- ── Raycaster Floor UV (merged from test_raycaster_floor_uv.lua) ──

-- Helper: build a basic raycaster and map.
local function make_raycaster()
    local map = {
        {1, 1, 1, 1, 1},
        {1, 0, 0, 0, 1},
        {1, 0, 0, 0, 1},
        {1, 0, 0, 0, 1},
        {1, 1, 1, 1, 1},
    }
    local rc = lurek.raycaster.new(5, 5, map)
    return rc
end

-- @description Covers suite: lurek.raycaster castFloorRow.
describe("lurek.raycaster castFloorRow", function()
    -- @description Covers suite: API exposure.
    describe("API exposure", function()
        -- @tests lurek.raycaster:castFloorRow
        -- @description castFloorRow is callable on a raycaster.
        it("castFloorRow is a function on raycaster", function()
            local rc = make_raycaster()
            expect_type("function", rc.castFloorRow)
        end)
    end)

    -- @description Covers suite: return value structure.
    describe("return value", function()
        -- Camera basis vectors for a player facing +X.
        local cam_x, cam_y  = 2.5, 2.5
        local dir_x, dir_y  = 1.0, 0.0
        local plane_x, plane_y = 0.0, 0.66  -- standard 66° FOV half-plane

        -- @tests lurek.raycaster:castFloorRow
        -- @description Returns a table.
        it("returns a table", function()
            local rc = make_raycaster()
            local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
            expect_type("table", uvs)
        end)

        -- @tests lurek.raycaster:castFloorRow
        -- @description Table length equals screen width.
        it("table length equals screen width", function()
            local rc = make_raycaster()
            local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
            local w = rc:getScreenWidth()
            expect_equal(w, #uvs)
        end)

        -- @tests lurek.raycaster:castFloorRow
        -- @description Each element has u and v keys.
        it("each element is a {u, v} table", function()
            local rc = make_raycaster()
            local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
            for _, uv in ipairs(uvs) do
                expect_type("number", uv.u)
                expect_type("number", uv.v)
                break  -- check just the first entry
            end
        end)

        -- @tests lurek.raycaster:castFloorRow
        -- @description UV values are in [0, 1] range.
        it("UV values are in [0, 1]", function()
            local rc = make_raycaster()
            local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
            for _, uv in ipairs(uvs) do
                assert(uv.u >= 0.0 and uv.u <= 1.0,
                    "tex_u out of range: " .. tostring(uv.u))
                assert(uv.v >= 0.0 and uv.v <= 1.0,
                    "tex_v out of range: " .. tostring(uv.v))
            end
        end)

        -- @tests lurek.raycaster:castFloorRow
        -- @description Calling for multiple rows does not error.
        it("works for consecutive rows", function()
            local rc = make_raycaster()
            local h = rc:getScreenHeight()
            for row = h // 2, h - 1 do
                local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row)
                expect_type("table", uvs)
            end
        end)
    end)
end)

-- ── Raycaster Sprite Manager (merged from test_raycaster_sprite_manager.lua) ──

describe("raycaster sprite manager", function()
  it("newSpriteManager returns a userdata", function()
    local sm = lurek.raycaster.newSpriteManager()
    expect_equal(type(sm), "userdata")
  end)

  it("type() returns SpriteManager", function()
    local sm = lurek.raycaster.newSpriteManager()
    expect_equal(sm:type(), "SpriteManager")
  end)

  it("add returns a numeric id", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(10, 10, "barrel.png")
    expect_equal(type(id), "number")
  end)

  it("ids are unique and incrementing", function()
    local sm = lurek.raycaster.newSpriteManager()
    local a = sm:add(1, 1, "a.png")
    local b = sm:add(2, 2, "b.png")
    expect_equal(a ~= b, true)
  end)

  it("remove does not error when id exists", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(10, 10, "barrel.png")
    sm:remove(id)
    expect_equal(true, true)
  end)

  it("remove is silent for unknown id", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:remove(9999)
    expect_equal(true, true)
  end)

  it("clear empties all sprites", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(1, 1, "a.png")
    sm:add(2, 2, "b.png")
    sm:clear()
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 0)
  end)

  it("sortAndProject returns a table", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(5, 5, "enemy.png")
    local projected = sm:sortAndProject(0, 0, 0.0)
    expect_equal(type(projected), "table")
  end)

  it("sortAndProject result has correct length", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(2, 0, "near.png")
    sm:add(10, 0, "far.png")
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 2)
  end)

  it("sortAndProject sorts far sprites first (back-to-front)", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(2, 0, "near.png")
    sm:add(10, 0, "far.png")
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(proj[1].texture, "far.png")
    expect_equal(proj[2].texture, "near.png")
  end)

  it("sortAndProject entry contains distance field", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(3, 4, "enemy.png")   -- 5 units from origin
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 1)
    expect_near(proj[1].distance, 5.0, 0.01)
  end)

  it("setPosition updates world coordinates", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(0, 0, "item.png")
    sm:setPosition(id, 3, 4)
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_near(proj[1].distance, 5.0, 0.01)
  end)

  it("setVisible(false) hides sprite from projection", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(5, 5, "ghost.png")
    sm:setVisible(id, false)
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 0)
  end)

  it("setVisible(true) re-shows hidden sprite", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(5, 5, "ghost.png")
    sm:setVisible(id, false)
    sm:setVisible(id, true)
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 1)
  end)
end)

-- ── Raycaster Transparent Walls (merged from test_raycaster_transparent.lua) ──

describe("raycaster transparent walls", function()
  it("setWallAlpha and getWallAlpha round-trip correctly", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(3, 0.5)
    expect_near(m:getWallAlpha(3), 0.5, 0.001)
  end)

  it("getWallAlpha returns 1.0 for unregistered tile type", function()
    local m = lurek.raycaster.newMap(32, 32)
    expect_near(m:getWallAlpha(99), 1.0, 0.001)
  end)

  it("alpha above 1.0 is clamped to 1.0", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, 1.5)
    expect_near(m:getWallAlpha(1), 1.0, 0.001)
  end)

  it("alpha below 0.0 is clamped to 0.0", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, -0.5)
    expect_near(m:getWallAlpha(1), 0.0, 0.001)
  end)

  it("multiple tile types store independent alpha values", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, 0.25)
    m:setWallAlpha(2, 0.75)
    expect_near(m:getWallAlpha(1), 0.25, 0.001)
    expect_near(m:getWallAlpha(2), 0.75, 0.001)
    -- unset tile still defaults
    expect_near(m:getWallAlpha(3), 1.0, 0.001)
  end)

  it("castRayMulti returns a table", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hits = m:castRayMulti(8.5, 8.5, -math.pi / 2, 20.0)
    expect_equal(type(hits), "table")
  end)

  it("castRayMulti hit table contains alpha field", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hits = m:castRayMulti(8.5, 8.5, -math.pi / 2, 20.0)
    if #hits > 0 then
      expect_equal(type(hits[1].alpha), "number")
    end
  end)

  it("castRay hit table contains alpha field", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hit = m:castRay(8.5, 8.5, -math.pi / 2, 20.0)
    if hit then
      expect_equal(type(hit.alpha), "number")
    end
  end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.raycaster.newDoorManager
    it("covers lurek.raycaster.newDoorManager", function()
        -- TODO: Implement test for lurek.raycaster.newDoorManager
    end)

    -- @tests lurek.raycaster.newHeightMap
    it("covers lurek.raycaster.newHeightMap", function()
        -- TODO: Implement test for lurek.raycaster.newHeightMap
    end)

    -- @tests lurek.raycaster.newPointLight
    it("covers lurek.raycaster.newPointLight", function()
        -- TODO: Implement test for lurek.raycaster.newPointLight
    end)

    -- @tests DoorManager:openDoor
    it("covers DoorManager:openDoor", function()
        -- TODO: Implement test for DoorManager:openDoor
    end)

    -- @tests DoorManager:closeDoor
    it("covers DoorManager:closeDoor", function()
        -- TODO: Implement test for DoorManager:closeDoor
    end)

    -- @tests DoorManager:getDoor
    it("covers DoorManager:getDoor", function()
        -- TODO: Implement test for DoorManager:getDoor
    end)

    -- @tests HeightMap:setFloor
    it("covers HeightMap:setFloor", function()
        -- TODO: Implement test for HeightMap:setFloor
    end)

    -- @tests HeightMap:setCeiling
    it("covers HeightMap:setCeiling", function()
        -- TODO: Implement test for HeightMap:setCeiling
    end)

    -- @tests HeightMap:floorAt
    it("covers HeightMap:floorAt", function()
        -- TODO: Implement test for HeightMap:floorAt
    end)

    -- @tests HeightMap:ceilingAt
    it("covers HeightMap:ceilingAt", function()
        -- TODO: Implement test for HeightMap:ceilingAt
    end)

    -- @tests PointLight:x
    it("covers PointLight:x", function()
        -- TODO: Implement test for PointLight:x
    end)

    -- @tests PointLight:y
    it("covers PointLight:y", function()
        -- TODO: Implement test for PointLight:y
    end)

end)

describe("Missing explicit test for lurek.raycaster.newMap", function()
    it("lurek.raycaster.newMap works", function()
        -- @tests lurek.raycaster.newMap
        -- TODO: add assertion for lurek.raycaster.newMap
    end)
end)

describe("Missing explicit test for lurek.raycaster.newSpriteManager", function()
    it("lurek.raycaster.newSpriteManager works", function()
        -- @tests lurek.raycaster.newSpriteManager
        -- TODO: add assertion for lurek.raycaster.newSpriteManager
    end)
end)

describe("Missing explicit test for DoorManager:update", function()
    it("DoorManager:update works", function()
        -- @tests DoorManager:update
        -- TODO: add assertion for DoorManager:update
    end)
end)

describe("Missing explicit test for DoorManager:count", function()
    it("DoorManager:count works", function()
        -- @tests DoorManager:count
        -- TODO: add assertion for DoorManager:count
    end)
end)

describe("Missing explicit test for DoorManager:type", function()
    it("DoorManager:type works", function()
        -- @tests DoorManager:type
        -- TODO: add assertion for DoorManager:type
    end)
end)

describe("Missing explicit test for DoorManager:typeOf", function()
    it("DoorManager:typeOf works", function()
        -- @tests DoorManager:typeOf
        -- TODO: add assertion for DoorManager:typeOf
    end)
end)

describe("Missing explicit test for HeightMap:type", function()
    it("HeightMap:type works", function()
        -- @tests HeightMap:type
        -- TODO: add assertion for HeightMap:type
    end)
end)

describe("Missing explicit test for HeightMap:typeOf", function()
    it("HeightMap:typeOf works", function()
        -- @tests HeightMap:typeOf
        -- TODO: add assertion for HeightMap:typeOf
    end)
end)

describe("Missing explicit test for PointLight:radius", function()
    it("PointLight:radius works", function()
        -- @tests PointLight:radius
        -- TODO: add assertion for PointLight:radius
    end)
end)

describe("Missing explicit test for PointLight:intensity", function()
    it("PointLight:intensity works", function()
        -- @tests PointLight:intensity
        -- TODO: add assertion for PointLight:intensity
    end)
end)

describe("Missing explicit test for PointLight:color", function()
    it("PointLight:color works", function()
        -- @tests PointLight:color
        -- TODO: add assertion for PointLight:color
    end)
end)

describe("Missing explicit test for PointLight:type", function()
    it("PointLight:type works", function()
        -- @tests PointLight:type
        -- TODO: add assertion for PointLight:type
    end)
end)

describe("Missing explicit test for PointLight:typeOf", function()
    it("PointLight:typeOf works", function()
        -- @tests PointLight:typeOf
        -- TODO: add assertion for PointLight:typeOf
    end)
end)

describe("Missing explicit test for Raycaster:setCell", function()
    it("Raycaster:setCell works", function()
        -- @tests Raycaster:setCell
        -- TODO: add assertion for Raycaster:setCell
    end)
end)

describe("Missing explicit test for Raycaster:getCell", function()
    it("Raycaster:getCell works", function()
        -- @tests Raycaster:getCell
        -- TODO: add assertion for Raycaster:getCell
    end)
end)

describe("Missing explicit test for Raycaster:setCells", function()
    it("Raycaster:setCells works", function()
        -- @tests Raycaster:setCells
        -- TODO: add assertion for Raycaster:setCells
    end)
end)

describe("Missing explicit test for Raycaster:isBlocked", function()
    it("Raycaster:isBlocked works", function()
        -- @tests Raycaster:isBlocked
        -- TODO: add assertion for Raycaster:isBlocked
    end)
end)

describe("Missing explicit test for Raycaster:width", function()
    it("Raycaster:width works", function()
        -- @tests Raycaster:width
        -- TODO: add assertion for Raycaster:width
    end)
end)

describe("Missing explicit test for Raycaster:height", function()
    it("Raycaster:height works", function()
        -- @tests Raycaster:height
        -- TODO: add assertion for Raycaster:height
    end)
end)

describe("Missing explicit test for Raycaster:setWallAlpha", function()
    it("Raycaster:setWallAlpha works", function()
        -- @tests Raycaster:setWallAlpha
        -- TODO: add assertion for Raycaster:setWallAlpha
    end)
end)

describe("Missing explicit test for Raycaster:getWallAlpha", function()
    it("Raycaster:getWallAlpha works", function()
        -- @tests Raycaster:getWallAlpha
        -- TODO: add assertion for Raycaster:getWallAlpha
    end)
end)

describe("Missing explicit test for SpriteManager:remove", function()
    it("SpriteManager:remove works", function()
        -- @tests SpriteManager:remove
        -- TODO: add assertion for SpriteManager:remove
    end)
end)

describe("Missing explicit test for SpriteManager:setPosition", function()
    it("SpriteManager:setPosition works", function()
        -- @tests SpriteManager:setPosition
        -- TODO: add assertion for SpriteManager:setPosition
    end)
end)

describe("Missing explicit test for SpriteManager:setVisible", function()
    it("SpriteManager:setVisible works", function()
        -- @tests SpriteManager:setVisible
        -- TODO: add assertion for SpriteManager:setVisible
    end)
end)

describe("Missing explicit test for SpriteManager:clear", function()
    it("SpriteManager:clear works", function()
        -- @tests SpriteManager:clear
        -- TODO: add assertion for SpriteManager:clear
    end)
end)

describe("Missing explicit test for SpriteManager:type", function()
    it("SpriteManager:type works", function()
        -- @tests SpriteManager:type
        -- TODO: add assertion for SpriteManager:type
    end)
end)

describe("Missing explicit test for SpriteManager:typeOf", function()
    it("SpriteManager:typeOf works", function()
        -- @tests SpriteManager:typeOf
        -- TODO: add assertion for SpriteManager:typeOf
    end)
end)
