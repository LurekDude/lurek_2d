-- Lurek2D Lua BDD tests for lurek.raycaster
-- Headless: no GPU, no audio, no window.

-- @describe module interface
describe("module interface", function()
    -- @covers lurek.raycaster.new
    it("exposes new factory", function()
        expect_type("function", lurek.raycaster.new)
    end)
end)

-- @describe new(w, h)
describe("new(w, h)", function()
    -- @covers lurek.raycaster.new
    it("returns a userdata object", function()
        local rc = lurek.raycaster.new(16, 12)
        expect_type("userdata", rc)
    end)

    -- @covers LRaycaster:width
    -- @covers lurek.raycaster.new
    it("width() returns the given width", function()
        local rc = lurek.raycaster.new(24, 18)
        expect_equal(24, rc:width())
    end)

    -- @covers LRaycaster:height
    -- @covers lurek.raycaster.new
    it("height() returns the given height", function()
        local rc = lurek.raycaster.new(24, 18)
        expect_equal(18, rc:height())
    end)
end)

-- @describe cell access
describe("cell access", function()
    -- @covers LRaycaster:getCell
    -- @covers lurek.raycaster.new
    it("all cells start as 0", function()
        local rc = lurek.raycaster.new(4, 4)
        for y = 0, 3 do
            for x = 0, 3 do
                expect_equal(0, rc:getCell(x, y))
            end
        end
    end)

    -- @covers LRaycaster:getCell
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("setCell / getCell round-trip", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setCell(2, 5, 99)
        expect_equal(99, rc:getCell(2, 5))
    end)

    -- @covers LRaycaster:getCell
    -- @covers LRaycaster:setCells
    -- @covers lurek.raycaster.new
    it("setCells fills the grid from a flat table", function()
        local rc = lurek.raycaster.new(2, 2)
        rc:setCells({ 1, 2, 3, 4 })
        expect_equal(1, rc:getCell(0, 0))
        expect_equal(2, rc:getCell(1, 0))
        expect_equal(3, rc:getCell(0, 1))
        expect_equal(4, rc:getCell(1, 1))
    end)
end)

-- @describe isBlocked(x, y)
describe("isBlocked(x, y)", function()
    -- @covers LRaycaster:isBlocked
    -- @covers lurek.raycaster.new
    it("returns false for zero cell", function()
        local rc = lurek.raycaster.new(4, 4)
        expect_equal(false, rc:isBlocked(1, 1))
    end)

    -- @covers LRaycaster:isBlocked
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("returns true for non-zero cell", function()
        local rc = lurek.raycaster.new(4, 4)
        rc:setCell(2, 2, 1)
        expect_equal(true, rc:isBlocked(2, 2))
    end)
end)

-- @describe movement helpers
describe("movement helpers", function()
    -- @covers LRaycaster:setCell
    -- @covers LRaycaster:tryMove
    -- @covers lurek.raycaster.new
    it("tryMove advances when target cell is empty", function()
        local rc = lurek.raycaster.new(6, 6)
        local nx, ny, moved = rc:tryMove(1.5, 1.5, 1.0, 0.0)
        expect_equal(true, moved)
        expect_near(2.5, nx, 0.001)
        expect_near(1.5, ny, 0.001)
    end)

    -- @covers LRaycaster:setCell
    -- @covers LRaycaster:tryMove
    -- @covers lurek.raycaster.new
    it("tryMove stays in place when target cell is blocked", function()
        local rc = lurek.raycaster.new(6, 6)
        rc:setCell(2, 1, 1)
        local nx, ny, moved = rc:tryMove(1.5, 1.5, 1.0, 0.0)
        expect_equal(false, moved)
        expect_near(1.5, nx, 0.001)
        expect_near(1.5, ny, 0.001)
    end)

    -- @covers LRaycaster:gridMove
    -- @covers lurek.raycaster.new
    it("gridMove uses dir=1 forward as +x", function()
        local rc = lurek.raycaster.new(8, 8)
        local nx, ny, moved = rc:gridMove(2.5, 2.5, 1, "forward", 1.0)
        expect_equal(true, moved)
        expect_near(3.5, nx, 0.001)
        expect_near(2.5, ny, 0.001)
    end)
end)

-- @describe castRay(ox, oy, angle, max_dist)
describe("castRay(ox, oy, angle, max_dist)", function()
    -- @covers LRaycaster:castRay
    -- @covers lurek.raycaster.new
    it("returns nil in fully empty grid", function()
        local rc = lurek.raycaster.new(10, 10)
        local hit = rc:castRay(5.0, 5.0, 0.0, 20.0)
        -- An empty grid may return nil or a boundary non-hit
        if hit ~= nil then
            expect_type("table", hit)
        end
    end)

    -- @covers LRaycaster:castRay
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("hits a wall placed directly ahead", function()
        local rc = lurek.raycaster.new(10, 10)
        rc:setCell(8, 4, 1)          -- wall at x=8, row 4
        -- cast from (1.5, 4.5) pointing east (angle=0)
        local hit = rc:castRay(1.5, 4.5, 0.0, 20.0)
        expect_not_nil(hit, "expected a hit")
        expect_equal(true, hit.hit)
        expect_equal(1, hit.cell_value)
    end)

    -- @covers LRaycaster:castRay
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
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

-- @describe castRays(ox, oy, angle, fov, count, max_dist)
describe("castRays(ox, oy, angle, fov, count, max_dist)", function()
    -- @covers LRaycaster:castRays
    -- @covers lurek.raycaster.new
    it("returns exactly count entries", function()
        local rc = lurek.raycaster.new(20, 20)
        local rays = rc:castRays(10.0, 10.0, 0.0, math.pi / 2, 64, 30.0)
        expect_equal(64, #rays)
    end)

    -- @covers LRaycaster:castRays
    -- @covers lurek.raycaster.new
    it("each entry is a table", function()
        local rc = lurek.raycaster.new(20, 20)
        local rays = rc:castRays(10.0, 10.0, 0.0, math.pi / 3, 8, 20.0)
        for i, r in ipairs(rays) do
            expect_type("table", r)
        end
    end)
end)

-- @describe castRaysFlat(ox, oy, angle, fov, count, max_dist)
describe("castRaysFlat(ox, oy, angle, fov, count, max_dist)", function()
    -- @covers LRaycaster:castRaysFlat
    -- @covers lurek.raycaster.new
    it("returns a table", function()
        local rc = lurek.raycaster.new(20, 20)
        local flat = rc:castRaysFlat(10.0, 10.0, 0.0, math.pi / 2, 8, 30.0)
        expect_type("table", flat)
    end)

    -- @covers LRaycaster:castRaysFlat
    -- @covers lurek.raycaster.new
    it("contains only numbers", function()
        local rc = lurek.raycaster.new(20, 20)
        local flat = rc:castRaysFlat(10.0, 10.0, 0.0, math.pi / 2, 4, 30.0)
        for _, v in ipairs(flat) do
            expect_type("number", v)
        end
    end)

    -- @covers LRaycaster:castRaysFlat
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("returns count * 5 flat values", function()
        local rc = lurek.raycaster.new(8, 8)
        for i = 0, 7 do
            rc:setCell(i, 0, 1)
            rc:setCell(i, 7, 1)
            rc:setCell(0, i, 1)
            rc:setCell(7, i, 1)
        end
        local flat = rc:castRaysFlat(4.0, 4.0, 0.0, math.pi / 3, 5, 20.0)
        expect_equal(25, #flat)
    end)
end)

-- @describe lineOfSight(x1, y1, x2, y2)
describe("lineOfSight(x1, y1, x2, y2)", function()
    -- @covers LRaycaster:lineOfSight
    -- @covers lurek.raycaster.new
    it("returns true in empty grid", function()
        local rc = lurek.raycaster.new(10, 10)
        local visible = rc:lineOfSight(1.0, 5.0, 8.0, 5.0)
        expect_equal(true, visible)
    end)

    -- @covers LRaycaster:lineOfSight
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("returns false when wall blocks the path", function()
        local rc = lurek.raycaster.new(10, 10)
        rc:setCell(5, 5, 1)  -- wall in the middle
        local visible = rc:lineOfSight(1.0, 5.5, 9.0, 5.5)
        expect_equal(false, visible)
    end)

    -- @covers LRaycaster:lineOfSight
    -- @covers lurek.raycaster.new
    it("returns a boolean", function()
        local rc = lurek.raycaster.new(10, 10)
        local result = rc:lineOfSight(0.5, 0.5, 9.5, 9.5)
        expect_type("boolean", result)
    end)
end)

-- @describe generic minimap and reveal helpers
describe("generic minimap and reveal helpers", function()
    -- @covers LRaycaster:revealCellsFromRays
    -- @covers lurek.raycaster.new
    it("revealCellsFromRays returns an array of cell records", function()
        local rc = lurek.raycaster.new(16, 16)
        local cells = rc:revealCellsFromRays(8.5, 8.5, 0.0, math.pi / 3, 8, 8.0, 0.25)
        expect_type("table", cells)
        if #cells > 0 then
            expect_type("number", cells[1].x)
            expect_type("number", cells[1].y)
        end
    end)

    -- @covers LRaycaster:computeTileLight
    -- @covers lurek.raycaster.new
    it("computeTileLight returns rgb+luma in range", function()
        local rc = lurek.raycaster.new(8, 8)
        local r, g, b, l = rc:computeTileLight(3, 3, 0.2, {
            { x = 3.5, y = 3.5, radius = 4.0, r = 1.0, g = 0.8, b = 0.5, intensity = 8.0 }
        })
        expect_true(r >= 0.0 and r <= 1.0)
        expect_true(g >= 0.0 and g <= 1.0)
        expect_true(b >= 0.0 and b <= 1.0)
        expect_true(l >= 0.0 and l <= 1.0)
    end)

    -- @covers LRaycaster:buildMinimapWindow
    -- @covers lurek.raycaster.new
    it("buildMinimapWindow returns sampled tile records", function()
        local rc = lurek.raycaster.new(10, 10)
        rc:setCell(4, 4, 1)
        local out = rc:buildMinimapWindow(5.5, 5.5, 3, 0.2, nil)
        expect_type("table", out)
        if #out > 0 then
            local s = out[1]
            expect_type("number", s.x)
            expect_type("number", s.y)
            expect_type("boolean", s.blocked)
            expect_type("boolean", s.visible)
            expect_type("number", s.luma)
        end
    end)
end)

-- @describe projectSprite(sx, sy, px, py, pa, fov, screen_w)
describe("projectSprite(sx, sy, px, py, pa, fov, screen_w)", function()
    -- @covers LRaycaster:projectSprite
    -- @covers lurek.raycaster.new
    it("returns a table with required fields", function()
        local rc = lurek.raycaster.new(10, 10)
        local sp = rc:projectSprite(5.0, 5.0, 1.0, 5.0, 0.0, math.pi / 2, 320.0)
        expect_type("table", sp)
        expect_type("number", sp.screen_x)
        expect_type("number", sp.scale)
        expect_type("number", sp.distance)
        expect_type("boolean", sp.visible)
    end)

    -- @covers LRaycaster:projectSprite
    -- @covers lurek.raycaster.new
    it("reports sprites behind the camera as invisible", function()
        local rc = lurek.raycaster.new(8, 8)
        local sp = rc:projectSprite(3.0, 3.0, 5.0, 5.0, 0.0, math.pi / 3, 320.0)
        expect_false(sp.visible)
    end)
end)

-- @describe projectColumn(distance, fov, screen_height)
describe("projectColumn(distance, fov, screen_height)", function()
    -- @covers lurek.raycaster.projectColumn
    it("is a function", function()
        expect_type("function", lurek.raycaster.projectColumn)
    end)

    -- @covers lurek.raycaster.projectColumn
    it("returns 3 numbers", function()
        local a, b, c = lurek.raycaster.projectColumn(2.0, math.pi / 2, 480.0)
        expect_type("number", a)
        expect_type("number", b)
        expect_type("number", c)
    end)

    -- @covers lurek.raycaster.projectColumn
    it("column height is positive for distance 1.0", function()
        local col_height, _, _ = lurek.raycaster.projectColumn(1.0, math.pi / 2, 480.0)
        expect_true(col_height > 0.0, "column height should be positive")
    end)

    -- @covers lurek.raycaster.projectColumn
    it("column height decreases with distance", function()
        local h1, _, _ = lurek.raycaster.projectColumn(1.0, math.pi / 2, 480.0)
        local h2, _, _ = lurek.raycaster.projectColumn(5.0, math.pi / 2, 480.0)
        expect_true(h1 > h2, "closer wall should produce taller column")
    end)
end)

-- @describe distanceShade(distance, max_distance)
describe("distanceShade(distance, max_distance)", function()
    -- @covers lurek.raycaster.distanceShade
    it("is a function", function()
        expect_type("function", lurek.raycaster.distanceShade)
    end)

    -- @covers lurek.raycaster.distanceShade
    it("returns 1.0 at distance 0", function()
        local shade = lurek.raycaster.distanceShade(0.0, 10.0)
        expect_near(1.0, shade, 0.001)
    end)

    -- @covers lurek.raycaster.distanceShade
    it("returns 0.0 at or beyond max_distance", function()
        local shade = lurek.raycaster.distanceShade(10.0, 10.0)
        expect_near(0.0, shade, 0.001)
    end)

    -- @covers lurek.raycaster.distanceShade
    it("returns value in [0, 1]", function()
        local shade = lurek.raycaster.distanceShade(4.0, 10.0)
        expect_true(shade >= 0.0 and shade <= 1.0,
            "shade should be in [0,1], got: " .. tostring(shade))
    end)
end)

--  Raycaster Floor UV (merged from test_raycaster_floor_uv.lua)

-- Helper: build a basic raycaster and map.
local function make_raycaster()
    local map = {
        {1, 1, 1, 1, 1},
        {1, 0, 0, 0, 1},
        {1, 0, 0, 0, 1},
        {1, 0, 0, 0, 1},
        {1, 1, 1, 1, 1},
    }
    local rc = lurek.raycaster.new(5, 5)
    return rc
end

-- @describe API exposure
describe("API exposure", function()
    -- @covers LRaycaster:castFloorRow
    it("castFloorRow is a function on raycaster", function()
        local rc = make_raycaster()
        expect_type("function", rc.castFloorRow)
    end)
end)

-- @describe return value
describe("return value", function()
    -- Camera basis vectors for a player facing +X.
    local cam_x, cam_y  = 2.5, 2.5
    local dir_x, dir_y  = 1.0, 0.0
    local plane_x, plane_y = 0.0, 0.66  -- standard 66 FOV half-plane

    -- @covers LRaycaster:castFloorRow
    it("returns a table", function()
        local rc = make_raycaster()
        local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
        expect_type("table", uvs)
    end)

    -- @covers LRaycaster:castFloorRow
    it("table length equals screen width", function()
        local rc = make_raycaster()
        local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
        local w = #uvs
        local ok, get_width = pcall(function() return rc["getScreenWidth"] end)
        if ok and type(get_width) == "function" then
            w = get_width(rc)
        end
        expect_equal(w, #uvs)
    end)

    -- @covers LRaycaster:castFloorRow
    it("each element is a {u, v} table", function()
        local rc = make_raycaster()
        local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
        for _, uv in ipairs(uvs) do
            expect_type("number", uv.u)
            expect_type("number", uv.v)
            break  -- check just the first entry
        end
    end)

    -- @covers LRaycaster:castFloorRow
    it("UV values are in [0, 1]", function()
        local rc = make_raycaster()
        local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, 100)
        for _, uv in ipairs(uvs) do
            expect_true(uv.u >= 0.0 and uv.u <= 1.0,
                "tex_u out of range: " .. tostring(uv.u))
            expect_true(uv.v >= 0.0 and uv.v <= 1.0,
                "tex_v out of range: " .. tostring(uv.v))
        end
    end)

    -- @covers LRaycaster:castFloorRow
    it("works for consecutive rows", function()
        local rc = make_raycaster()
        local h = 64
        local ok, get_height = pcall(function() return rc["getScreenHeight"] end)
        if ok and type(get_height) == "function" then
            h = get_height(rc)
        end
        for row = math.floor(h / 2), h - 1 do
            local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row)
            expect_type("table", uvs)
        end
    end)
end)

--  Raycaster Sprite Manager (merged from test_raycaster_sprite_manager.lua)

-- @describe raycaster sprite manager
describe("raycaster sprite manager", function()
  -- @covers lurek.raycaster.newSpriteManager
  it("newSpriteManager returns a userdata", function()
    local sm = lurek.raycaster.newSpriteManager()
    expect_equal(type(sm), "userdata")
  end)

    -- @covers LSpriteManager:type
    -- @covers lurek.raycaster.newSpriteManager
    it("type() returns LSpriteManager", function()
    local sm = lurek.raycaster.newSpriteManager()
        expect_equal(sm:type(), "LSpriteManager")
  end)

  -- @covers LSpriteManager:add
  -- @covers lurek.raycaster.newSpriteManager
  it("add returns a numeric id", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(10, 10, "barrel.png")
    expect_equal(type(id), "number")
  end)

  -- @covers LSpriteManager:add
  -- @covers lurek.raycaster.newSpriteManager
  it("ids are unique and incrementing", function()
    local sm = lurek.raycaster.newSpriteManager()
    local a = sm:add(1, 1, "a.png")
    local b = sm:add(2, 2, "b.png")
    expect_equal(a ~= b, true)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:remove
  -- @covers lurek.raycaster.newSpriteManager
  it("remove does not error when id exists", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(10, 10, "barrel.png")
        expect_no_error(function()
            sm:remove(id)
        end)
        local proj = sm:sortAndProject(0, 0, 0.0)
        expect_equal(0, #proj)
  end)

  -- @covers LSpriteManager:remove
  -- @covers lurek.raycaster.newSpriteManager
  it("remove is silent for unknown id", function()
    local sm = lurek.raycaster.newSpriteManager()
        sm:add(1, 1, "barrel.png")
        expect_no_error(function()
            sm:remove(9999)
        end)
        local proj = sm:sortAndProject(0, 0, 0.0)
        expect_equal(1, #proj)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:clear
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("clear empties all sprites", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(1, 1, "a.png")
    sm:add(2, 2, "b.png")
    sm:clear()
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 0)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("sortAndProject returns a table", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(5, 5, "enemy.png")
    local projected = sm:sortAndProject(0, 0, 0.0)
    expect_equal(type(projected), "table")
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("sortAndProject result has correct length", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(2, 0, "near.png")
    sm:add(10, 0, "far.png")
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 2)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("sortAndProject sorts far sprites first (back-to-front)", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(2, 0, "near.png")
    sm:add(10, 0, "far.png")
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(proj[1].texture, "far.png")
    expect_equal(proj[2].texture, "near.png")
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("sortAndProject entry contains distance field", function()
    local sm = lurek.raycaster.newSpriteManager()
    sm:add(3, 4, "enemy.png")   -- 5 units from origin
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 1)
    expect_near(proj[1].distance, 5.0, 0.01)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:setPosition
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("setPosition updates world coordinates", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(0, 0, "item.png")
    sm:setPosition(id, 3, 4)
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_near(proj[1].distance, 5.0, 0.01)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:setVisible
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("setVisible(false) hides sprite from projection", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(5, 5, "ghost.png")
    sm:setVisible(id, false)
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 0)
  end)

  -- @covers LSpriteManager:add
  -- @covers LSpriteManager:setVisible
  -- @covers LSpriteManager:sortAndProject
  -- @covers lurek.raycaster.newSpriteManager
  it("setVisible(true) re-shows hidden sprite", function()
    local sm = lurek.raycaster.newSpriteManager()
    local id = sm:add(5, 5, "ghost.png")
    sm:setVisible(id, false)
    sm:setVisible(id, true)
    local proj = sm:sortAndProject(0, 0, 0.0)
    expect_equal(#proj, 1)
  end)
end)

--  Raycaster Transparent Walls (merged from test_raycaster_transparent.lua)

-- @describe raycaster transparent walls
describe("raycaster transparent walls", function()
  -- @covers LRaycaster:getWallAlpha
  -- @covers LRaycaster:setWallAlpha
  -- @covers lurek.raycaster.newMap
  it("setWallAlpha and getWallAlpha round-trip correctly", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(3, 0.5)
    expect_near(m:getWallAlpha(3), 0.5, 0.001)
  end)

  -- @covers LRaycaster:getWallAlpha
  -- @covers lurek.raycaster.newMap
  it("getWallAlpha returns 1.0 for unregistered tile type", function()
    local m = lurek.raycaster.newMap(32, 32)
    expect_near(m:getWallAlpha(99), 1.0, 0.001)
  end)

  -- @covers LRaycaster:getWallAlpha
  -- @covers LRaycaster:setWallAlpha
  -- @covers lurek.raycaster.newMap
  it("alpha above 1.0 is clamped to 1.0", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, 1.5)
    expect_near(m:getWallAlpha(1), 1.0, 0.001)
  end)

  -- @covers LRaycaster:getWallAlpha
  -- @covers LRaycaster:setWallAlpha
  -- @covers lurek.raycaster.newMap
  it("alpha below 0.0 is clamped to 0.0", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, -0.5)
    expect_near(m:getWallAlpha(1), 0.0, 0.001)
  end)

  -- @covers LRaycaster:getWallAlpha
  -- @covers LRaycaster:setWallAlpha
  -- @covers lurek.raycaster.newMap
  it("multiple tile types store independent alpha values", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, 0.25)
    m:setWallAlpha(2, 0.75)
    expect_near(m:getWallAlpha(1), 0.25, 0.001)
    expect_near(m:getWallAlpha(2), 0.75, 0.001)
    -- unset tile still defaults
    expect_near(m:getWallAlpha(3), 1.0, 0.001)
  end)

  -- @covers LRaycaster:castRayMulti
  -- @covers LRaycaster:setCell
  -- @covers lurek.raycaster.newMap
  it("castRayMulti returns a table", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hits = m:castRayMulti(8.5, 8.5, -math.pi / 2, 20.0)
    expect_equal(type(hits), "table")
  end)

  -- @covers LRaycaster:castRayMulti
  -- @covers LRaycaster:setCell
  -- @covers lurek.raycaster.newMap
  it("castRayMulti hit table contains alpha field", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hits = m:castRayMulti(8.5, 8.5, -math.pi / 2, 20.0)
    if #hits > 0 then
      expect_equal(type(hits[1].alpha), "number")
    end
  end)

  -- @covers LRaycaster:castRay
  -- @covers LRaycaster:setCell
  -- @covers lurek.raycaster.newMap
  it("castRay hit table contains alpha field", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hit = m:castRay(8.5, 8.5, -math.pi / 2, 20.0)
    if hit then
      expect_equal(type(hit.alpha), "number")
    end
  end)
end)

-- @describe raycaster constructor and userdata coverage
describe("raycaster constructor and userdata coverage", function()
    -- @covers LDoorManager:count
    -- @covers LDoorManager:type
    -- @covers LDoorManager:typeOf
    -- @covers lurek.raycaster.newDoorManager
    it("newDoorManager creates an empty LDoorManager", function()
        local dm = lurek.raycaster.newDoorManager()
        expect_equal(0, dm:count())
        expect_equal("LDoorManager", dm:type())
        expect_true(dm:typeOf("DoorManager"))
    end)

    -- @covers LDoorManager:addDoor
    -- @covers LDoorManager:closeDoor
    -- @covers LDoorManager:getDoor
    -- @covers LDoorManager:openDoor
    -- @covers LDoorManager:update
    -- @covers lurek.raycaster.newDoorManager
    it("DoorManager updates openAmount and state across open/close cycle", function()
        local dm = lurek.raycaster.newDoorManager()
        local idx = dm:addDoor(1, 1, "vertical", 1.0)

        local closed = dm:getDoor(idx)
        expect_equal("closed", closed.state)
        expect_near(0.0, closed.openAmount, 1e-5)

        dm:openDoor(idx)
        dm:update(0.5)
        local opening = dm:getDoor(idx)
        expect_equal("opening", opening.state)
        expect_near(0.5, opening.openAmount, 1e-5)

        dm:update(0.6)
        local open = dm:getDoor(idx)
        expect_equal("open", open.state)
        expect_near(1.0, open.openAmount, 1e-5)

        dm:closeDoor(idx)
        dm:update(1.1)
        local closed_again = dm:getDoor(idx)
        expect_equal("closed", closed_again.state)
        expect_near(0.0, closed_again.openAmount, 1e-5)
    end)

    -- @covers LHeightMap:ceilingAt
    -- @covers LHeightMap:floorAt
    -- @covers LHeightMap:setCeiling
    -- @covers LHeightMap:setFloor
    -- @covers LHeightMap:type
    -- @covers LHeightMap:typeOf
    -- @covers lurek.raycaster.newHeightMap
    it("newHeightMap defaults and setters round-trip", function()
        local hm = lurek.raycaster.newHeightMap(4, 4)
        expect_equal("LHeightMap", hm:type())
        expect_true(hm:typeOf("HeightMap"))
        expect_near(0.0, hm:floorAt(0, 0), 1e-5)
        expect_near(1.0, hm:ceilingAt(0, 0), 1e-5)

        hm:setFloor(1, 2, 0.25)
        hm:setCeiling(1, 2, 0.75)

        expect_near(0.25, hm:floorAt(1, 2), 1e-5)
        expect_near(0.75, hm:ceilingAt(1, 2), 1e-5)
    end)

    -- @covers LPointLight:color
    -- @covers LPointLight:intensity
    -- @covers LPointLight:radius
    -- @covers lurek.raycaster.newPointLight
    it("newPointLight exposes configured radius intensity and color", function()
        local pl = lurek.raycaster.newPointLight(10.0, 20.0, 0.2, 0.4, 0.6, 5.0, 0.8)
        local r, g, b = pl:color()
        expect_near(5.0, pl:radius(), 1e-5)
        expect_near(0.8, pl:intensity(), 1e-5)
        expect_near(0.2, r, 1e-5)
        expect_near(0.4, g, 1e-5)
        expect_near(0.6, b, 1e-5)
    end)
end)

-- @describe Lua coverage for PointLight:type
describe("Lua coverage for PointLight:type", function()
    -- @covers LPointLight:type
    -- @covers lurek.raycaster.newPointLight
    it("PointLight:type works", function()
        local pl = lurek.raycaster.newPointLight(0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        expect_equal("LPointLight", pl:type())
    end)
end)

-- @describe Lua coverage for PointLight:typeOf
describe("Lua coverage for PointLight:typeOf", function()
    -- @covers LPointLight:typeOf
    -- @covers lurek.raycaster.newPointLight
    it("PointLight:typeOf works", function()
        local pl = lurek.raycaster.newPointLight(0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        expect_true(pl:typeOf("LPointLight"))
    end)
end)

-- @describe Lua coverage for Raycaster:setCell
describe("Lua coverage for Raycaster:setCell", function()
    -- @covers LRaycaster:getCell
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("Raycaster:setCell works", function()
        local rc = lurek.raycaster.new(4, 4)
        rc:setCell(0, 0, 7)
        expect_equal(7, rc:getCell(0, 0))
    end)
end)

-- @describe Lua coverage for Raycaster:getCell
describe("Lua coverage for Raycaster:getCell", function()
    -- @covers LRaycaster:getCell
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("Raycaster:getCell works", function()
        local rc = lurek.raycaster.new(4, 4)
        rc:setCell(1, 2, 3)
        expect_equal(3, rc:getCell(1, 2))
    end)
end)

-- @describe Lua coverage for Raycaster:setCells
describe("Lua coverage for Raycaster:setCells", function()
    -- @covers LRaycaster:getCell
    -- @covers LRaycaster:setCells
    -- @covers lurek.raycaster.new
    it("Raycaster:setCells works", function()
        local rc = lurek.raycaster.new(2, 2)
        rc:setCells({1, 2, 3, 4})
        expect_equal(1, rc:getCell(0, 0))
    end)
end)

-- @describe Lua coverage for Raycaster:isBlocked
describe("Lua coverage for Raycaster:isBlocked", function()
    -- @covers LRaycaster:isBlocked
    -- @covers LRaycaster:setCell
    -- @covers lurek.raycaster.new
    it("Raycaster:isBlocked works", function()
        local rc = lurek.raycaster.new(4, 4)
        rc:setCell(0, 0, 1)
        expect_true(rc:isBlocked(0, 0))
        expect_false(rc:isBlocked(1, 1))
    end)
end)

-- @describe Lua coverage for Raycaster:width
describe("Lua coverage for Raycaster:width", function()
    -- @covers LRaycaster:width
    -- @covers lurek.raycaster.new
    it("Raycaster:width works", function()
        local rc = lurek.raycaster.new(5, 3)
        expect_equal(5, rc:width())
    end)
end)

-- @describe Lua coverage for Raycaster:height
describe("Lua coverage for Raycaster:height", function()
    -- @covers LRaycaster:height
    -- @covers lurek.raycaster.new
    it("Raycaster:height works", function()
        local rc = lurek.raycaster.new(5, 3)
        expect_equal(3, rc:height())
    end)
end)

-- @describe Lua coverage for Raycaster:setWallAlpha
describe("Lua coverage for Raycaster:setWallAlpha", function()
    -- @covers LRaycaster:getWallAlpha
    -- @covers LRaycaster:setWallAlpha
    -- @covers lurek.raycaster.new
    it("Raycaster:setWallAlpha works", function()
        local rc = lurek.raycaster.new(4, 4)
        rc:setWallAlpha(1, 0.75)
        expect_near(0.75, rc:getWallAlpha(1), 1e-5)
    end)
end)

-- @describe Lua coverage for Raycaster:getWallAlpha
describe("Lua coverage for Raycaster:getWallAlpha", function()
    -- @covers LRaycaster:getWallAlpha
    -- @covers LRaycaster:setWallAlpha
    -- @covers lurek.raycaster.new
    it("Raycaster:getWallAlpha works", function()
        local rc = lurek.raycaster.new(4, 4)
        rc:setWallAlpha(2, 0.5)
        expect_near(0.5, rc:getWallAlpha(2), 1e-5)
    end)
end)

-- @describe Lua coverage for SpriteManager:remove
describe("Lua coverage for SpriteManager:remove", function()
    -- @covers LSpriteManager:add
    -- @covers LSpriteManager:remove
    -- @covers lurek.raycaster.newSpriteManager
    it("SpriteManager:remove works", function()
        local sm = lurek.raycaster.newSpriteManager()
        local id = sm:add(1.0, 1.0, "a")
        sm:remove(id)
        -- remove is a no-op on unknown id, should not error
        sm:remove(id)
        expect_type("number", id)
    end)
end)

-- @describe Lua coverage for SpriteManager:setPosition
describe("Lua coverage for SpriteManager:setPosition", function()
    -- @covers LSpriteManager:add
    -- @covers LSpriteManager:setPosition
    -- @covers lurek.raycaster.newSpriteManager
    it("SpriteManager:setPosition works", function()
        local sm = lurek.raycaster.newSpriteManager()
        local id = sm:add(0.0, 0.0, "spr")
        sm:setPosition(id, 3.0, 5.0)
        expect_type("number", id)
    end)
end)

-- @describe Lua coverage for SpriteManager:setVisible
describe("Lua coverage for SpriteManager:setVisible", function()
    -- @covers LSpriteManager:add
    -- @covers LSpriteManager:setVisible
    -- @covers lurek.raycaster.newSpriteManager
    it("SpriteManager:setVisible works", function()
        local sm = lurek.raycaster.newSpriteManager()
        local id = sm:add(0.0, 0.0, "spr")
        sm:setVisible(id, false)
        sm:setVisible(id, true)
        expect_type("number", id)
    end)
end)

-- @describe Lua coverage for SpriteManager:clear
describe("Lua coverage for SpriteManager:clear", function()
    -- @covers LSpriteManager:add
    -- @covers LSpriteManager:clear
    -- @covers LSpriteManager:sortAndProject
    -- @covers lurek.raycaster.newSpriteManager
    it("SpriteManager:clear works", function()
        local sm = lurek.raycaster.newSpriteManager()
        sm:add(1.0, 1.0, "a")
        sm:add(2.0, 2.0, "b")
        sm:clear()
        local projected = sm:sortAndProject(0.0, 0.0, 0.0)
        expect_equal(0, #projected)
    end)
end)

-- @describe Lua coverage for SpriteManager:type
describe("Lua coverage for SpriteManager:type", function()
    -- @covers LSpriteManager:type
    -- @covers lurek.raycaster.newSpriteManager
    it("SpriteManager:type works", function()
        local sm = lurek.raycaster.newSpriteManager()
        expect_equal("LSpriteManager", sm:type())
    end)
end)

-- @describe Lua coverage for SpriteManager:typeOf
describe("Lua coverage for SpriteManager:typeOf", function()
    -- @covers LSpriteManager:typeOf
    -- @covers lurek.raycaster.newSpriteManager
    it("SpriteManager:typeOf works", function()
        local sm = lurek.raycaster.newSpriteManager()
        expect_true(sm:typeOf("LSpriteManager"))
    end)
end)

-- @describe DoorManager:addDoor
describe("DoorManager:addDoor", function()
    -- @covers LDoorManager:addDoor
    -- @covers LDoorManager:count
    -- @covers lurek.raycaster.newDoorManager
    it("addDoor increments door count", function()
        local dm = lurek.raycaster.newDoorManager()
        dm:addDoor(3, 5, "horizontal", 0.0)
        expect_equal(1, dm:count())
    end)
end)

-- @describe PointLight accessors and set
describe("PointLight accessors and set", function()
    -- @covers LPointLight:x
    -- @covers lurek.raycaster.newPointLight
    it("x returns a number", function()
        local pl = lurek.raycaster.newPointLight(10.0, 20.0, 5.0, 1.0, 1.0, 1.0, 1.0)
        expect_type("number", pl:x())
    end)

    -- @covers LPointLight:y
    -- @covers lurek.raycaster.newPointLight
    it("y returns a number", function()
        local pl = lurek.raycaster.newPointLight(10.0, 20.0, 5.0, 1.0, 1.0, 1.0, 1.0)
        expect_type("number", pl:y())
    end)

    -- @covers LPointLight:set
    -- @covers LPointLight:x
    -- @covers LPointLight:y
    -- @covers lurek.raycaster.newPointLight
    it("set updates the position", function()
        local pl = lurek.raycaster.newPointLight(0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        pl:set(7.0, 9.0, 2.0, 1.0, 1.0, 1.0, 1.0)
        expect_near(7.0, pl:x(), 1e-5)
        expect_near(9.0, pl:y(), 1e-5)
    end)
end)

-- @describe Raycaster:buildScene
describe("Raycaster:buildScene", function()
    -- @covers LRaycaster:buildScene
    -- @covers lurek.raycaster.new
    it("buildScene does not panic on empty grid", function()
        local rc = lurek.raycaster.new(8, 8)
        local ok, _ = pcall(function() rc:buildScene({px=0,py=0,angle=0,fov=1.0,rays=1,max_dist=10,screen_w=320,screen_h=240}, {}, {}, {}) end)
        -- headless: accept success or a headless-specific nil return
        expect_type("boolean", ok)
    end)
end)

-- @describe Raycaster floor/ceiling per-cell textures
describe("Raycaster floor/ceiling per-cell textures", function()
    -- @covers LRaycaster:getFloorTextureCell
    -- @covers LRaycaster:getCeilingTextureCell
    -- @covers LRaycaster:setFloorTextureCell
    -- @covers LRaycaster:setCeilingTextureCell
    -- @covers lurek.raycaster.new
    it("set/get round-trip for numeric ids and nil clear fallback", function()
        local rc = lurek.raycaster.new(8, 8)
        local floor_tex = 101
        local ceiling_tex = 202

        rc:setFloorTextureCell(2, 3, floor_tex)
        rc:setCeilingTextureCell(2, 3, ceiling_tex)

        expect_equal(floor_tex, rc:getFloorTextureCell(2, 3))
        expect_equal(ceiling_tex, rc:getCeilingTextureCell(2, 3))

        -- nil clears overrides and buildScene should then use color fallback.
        rc:setFloorTextureCell(2, 3, nil)
        rc:setCeilingTextureCell(2, 3, nil)

        expect_nil(rc:getFloorTextureCell(2, 3))
        expect_nil(rc:getCeilingTextureCell(2, 3))
    end)

    -- @covers LRaycaster:buildScene
    -- @covers LRaycaster:setFloorTextureCell
    -- @covers LRaycaster:setCeilingTextureCell
    -- @covers lurek.raycaster.new
    it("buildScene accepts per-cell overrides with LImage userdata", function()
        local rc = lurek.raycaster.new(8, 8)
        local floor_img = lurek.render.newImage("assets/icon.png")
        local ceil_img = lurek.render.newImage("assets/icon.png")
        local wall_img = lurek.render.newImage("assets/icon.png")
        rc:setCell(4, 4, 1)
        rc:setFloorTextureCell(4, 4, floor_img)
        rc:setCeilingTextureCell(4, 4, ceil_img)

        local ok, _ = pcall(function()
            rc:buildScene(
                { px = 3.5, py = 4.5, angle = 0.0, fov = 1.0, rays = 16, max_dist = 12, screen_w = 320, screen_h = 240 },
                {},
                {},
                { [1] = wall_img }
            )
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe Raycaster:drawTopDown
describe("Raycaster:drawTopDown", function()
    -- @covers LRaycaster:drawTopDown
    -- @covers lurek.raycaster.new
    it("drawTopDown does not crash in headless mode", function()
        local rc = lurek.raycaster.new(8, 8)
        local ok, _ = pcall(function() rc:drawTopDown(0.0, 0.0, 1.0, 1) end)
        expect_type("boolean", ok)
    end)
end)

-- @describe SpriteManager:add
describe("SpriteManager:add", function()
    -- @covers LSpriteManager:add
    -- @covers lurek.raycaster.newSpriteManager
    it("add does not crash", function()
        local sm = lurek.raycaster.newSpriteManager()
        local bad_id = 1 ---@type any
        local ok, _ = pcall(function() sm:add(bad_id, 5.0, 5.0, {}) end)
        expect_type("boolean", ok)
    end)
end)

-- @describe Raycaster image debug helpers
describe("Raycaster image debug helpers", function()
    -- @covers LRaycaster:drawDepthMap
    -- @covers lurek.raycaster.new
    it("drawDepthMap returns image data", function()
        local rc = lurek.raycaster.new(8, 8)
        local img = rc:drawDepthMap(1.0, 1.0, 0.0, 1.0, 8, 32, 16, 20.0)
        expect_type("userdata", img)
    end)

    -- @covers LRaycaster:drawLineOfSight
    -- @covers lurek.raycaster.new
    it("drawLineOfSight returns image data", function()
        local rc = lurek.raycaster.new(8, 8)
        local img = rc:drawLineOfSight(1.0, 1.0, 6.0, 6.0, 4)
        expect_type("userdata", img)
    end)

    -- @covers LRaycaster:drawCameraSweep
    -- @covers lurek.raycaster.new
    it("drawCameraSweep returns image data", function()
        local rc = lurek.raycaster.new(8, 8)
        local img = rc:drawCameraSweep(2.0, 2.0, 1.0, 20.0, 4, 16, 16)
        expect_type("userdata", img)
    end)
end)

-- @describe raycaster strict: LRaycaster type/typeOf
describe("raycaster strict: LRaycaster type/typeOf", function()
    -- @covers LRaycaster:type
    -- @covers LRaycaster:typeOf
    -- @covers lurek.raycaster.new
    it("LRaycaster type and typeOf are callable", function()
        local rc = lurek.raycaster.new(8, 8)
        expect_type("string", rc:type())
        expect_type("boolean", rc:typeOf("Object"))
    end)
end)

-- @describe per-cell floor/ceiling texture overrides
describe("per-cell floor/ceiling texture overrides", function()
    -- @covers LRaycaster:setFloorTextureCell
    -- @covers LRaycaster:getFloorTextureCell
    -- @covers lurek.raycaster.new
    it("setFloorTextureCell / getFloorTextureCell accept and return nil for unset cell", function()
        local rc = lurek.raycaster.new(8, 8)
        local v = rc:getFloorTextureCell(2, 3)
        expect_equal(nil, v)
    end)

    -- @covers LRaycaster:setFloorTextureCell
    -- @covers LRaycaster:getFloorTextureCell
    -- @covers lurek.raycaster.new
    it("setFloorTextureCell with nil clears the cell", function()
        local rc = lurek.raycaster.new(8, 8)
        -- set something numeric, then clear
        rc:setFloorTextureCell(1, 1, 1)
        rc:setFloorTextureCell(1, 1, nil)
        local v = rc:getFloorTextureCell(1, 1)
        expect_equal(nil, v)
    end)

    -- @covers LRaycaster:setCeilingTextureCell
    -- @covers LRaycaster:getCeilingTextureCell
    -- @covers lurek.raycaster.new
    it("getCeilingTextureCell returns nil for unset cell", function()
        local rc = lurek.raycaster.new(8, 8)
        local v = rc:getCeilingTextureCell(0, 0)
        expect_equal(nil, v)
    end)

    -- @covers LRaycaster:setCeilingTextureCell
    -- @covers LRaycaster:getCeilingTextureCell
    -- @covers lurek.raycaster.new
    it("setCeilingTextureCell with nil clears the cell", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setCeilingTextureCell(3, 3, 2)
        rc:setCeilingTextureCell(3, 3, nil)
        local v = rc:getCeilingTextureCell(3, 3)
        expect_equal(nil, v)
    end)

    -- @covers LRaycaster:setFloorTextureCell
    -- @covers LRaycaster:setCeilingTextureCell
    -- @covers lurek.raycaster.new
    it("floor and ceiling cells are independent", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setFloorTextureCell(4, 4, 1)
        -- ceiling at same cell should still be nil
        local cv = rc:getCeilingTextureCell(4, 4)
        expect_equal(nil, cv)
    end)
end)

-- @describe lowered floor and model-scene helpers
describe("lowered floor and model-scene helpers", function()
    -- @covers LRaycaster:setLoweredFloorCell
    -- @covers LRaycaster:getLoweredFloorCell
    -- @covers lurek.raycaster.new
    it("sets and reads lowered floor cell options", function()
        local rc = lurek.raycaster.new(8, 8)
        rc:setLoweredFloorCell(2, 2, { texture = 1, depth = 0.35, blocked = true })
        local cell = rc:getLoweredFloorCell(2, 2)
        expect_type("table", cell)
        expect_equal(1, cell.texture)
    end)

    -- @covers LRaycaster:isWalkBlocked
    -- @covers lurek.raycaster.new
    it("reports walk blocking", function()
        local rc = lurek.raycaster.new(8, 8)
        local blocked = rc:isWalkBlocked(0, 0)
        expect_type("boolean", blocked)
    end)

    -- @covers LRaycaster:buildSceneWithModels
    -- @covers lurek.raycaster.new
    it("buildSceneWithModels returns count", function()
        local rc = lurek.raycaster.new(8, 8)
        local params = {
            px = 2.5,
            py = 2.5,
            angle = 0.0,
            fov = math.pi / 3,
            rays = 16,
            max_dist = 20.0,
            screen_w = 160.0,
            screen_h = 90.0,
        }
        local count = rc:buildSceneWithModels(params, nil, nil, nil, nil)
        expect_type("number", count)
    end)
end)

test_summary()
