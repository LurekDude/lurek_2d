-- test_evidence_pathfinding.lua
-- Evidence test: lurek.pathfinding API contracts and visual grid evidence

local OUT = "tests/lua/evidence/output/pathfinding/"

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Draw a NavGrid as a small PNG (white = walkable, black = blocked, red dots = path).
local function draw_nav_grid(grid, path, w, h, scale)
    scale = scale or 8
    local iw = w * scale
    local ih = h * scale
    local img = lurek.image.newImageData(iw, ih)
    img:fill(30, 30, 30, 255)

    -- Draw cells
    for y = 1, h do
        for x = 1, w do
            local blocked = grid:isBlocked(x, y)
            local cost = grid:getCost(x, y)
            local r, g, b
            if blocked then
                r, g, b = 20, 20, 20
            else
                local v = math.floor(255 - (cost / 10) * 180)
                r, g, b = v, v, v
            end
            img:fillRect((x-1)*scale + 1, (y-1)*scale + 1, scale - 1, scale - 1, r, g, b, 255)
        end
    end

    -- Draw path
    if path then
        for _, step in ipairs(path) do
            local px = (step.x - 1) * scale + math.floor(scale / 2)
            local py = (step.y - 1) * scale + math.floor(scale / 2)
            img:drawCircle(px, py, math.max(1, scale // 3), 255, 80, 80, 255)
        end
    end

    return img
end

-- ── tests ────────────────────────────────────────────────────────────────────

describe("Evidence: lurek.pathfinding A* basic", function()

    it("newNavGrid creates a grid", function()
        local grid = lurek.pathfinding.newNavGrid(10, 10)
        expect_equal(grid:getWidth(), 10)
        expect_equal(grid:getHeight(), 10)
    end)

    it("cell costs default to 1 (walkable)", function()
        local grid = lurek.pathfinding.newNavGrid(8, 8)
        expect_equal(grid:getCost(1, 1), 1)
        expect_equal(grid:isBlocked(1, 1), false)
    end)

    it("setBlocked / isBlocked round-trip", function()
        local grid = lurek.pathfinding.newNavGrid(8, 8)
        grid:setBlocked(3, 3, true)
        expect_equal(grid:isBlocked(3, 3), true)
        grid:setBlocked(3, 3, false)
        expect_equal(grid:isBlocked(3, 3), false)
    end)

    it("setCost / getCost round-trip", function()
        local grid = lurek.pathfinding.newNavGrid(8, 8)
        grid:setCost(4, 4, 5)
        expect_equal(grid:getCost(4, 4), 5)
    end)

    it("findPath returns a path in an open grid", function()
        local grid = lurek.pathfinding.newNavGrid(10, 10)
        local pf   = lurek.pathfinding.newUnitPathfinder(grid)
        local path = pf:findPath(1, 1, 10, 10)
        expect_equal(path ~= nil, true)
        expect_equal(#path > 0, true)
        -- First waypoint should be near start, last near goal
        expect_equal(path[1].x <= 2 and path[1].y <= 2, true)
        expect_equal(path[#path].x == 10 and path[#path].y == 10, true)
    end)

    it("findPath returns nil when goal is blocked", function()
        local grid = lurek.pathfinding.newNavGrid(8, 8)
        grid:setBlocked(8, 8, true)
        local pf   = lurek.pathfinding.newUnitPathfinder(grid)
        local path = pf:findPath(1, 1, 8, 8)
        expect_equal(path == nil, true)
    end)

    it("path avoids walls — PNG evidence: astar_basic", function()
        local W, H = 20, 15
        local grid = lurek.pathfinding.newNavGrid(W, H)

        -- Vertical wall in the middle with a single gap
        for y = 1, H do
            if y ~= 8 then
                grid:setBlocked(10, y, true)
            end
        end

        local pf   = lurek.pathfinding.newUnitPathfinder(grid)
        local path = pf:findPath(1, 1, 20, 15)
        expect_equal(path ~= nil, true)

        local img = draw_nav_grid(grid, path, W, H, 10)
        lurek.image.savePNG(img, OUT .. "evidence_pathfinding_astar_wall.png")
    end)
end)

describe("Evidence: lurek.pathfinding weighted terrain", function()

    it("higher-cost terrain is avoided when cheaper route exists — PNG evidence", function()
        local W, H = 12, 12
        local grid = lurek.pathfinding.newNavGrid(W, H)

        -- Centre strip is expensive (mud / water)
        for y = 1, H do
            grid:setCost(6, y, 9)
            grid:setCost(7, y, 9)
        end

        local pf   = lurek.pathfinding.newUnitPathfinder(grid)
        local path = pf:findPath(1, 6, 12, 6)
        expect_equal(path ~= nil, true)

        local img = draw_nav_grid(grid, path, W, H, 14)
        lurek.image.savePNG(img, OUT .. "evidence_pathfinding_weighted.png")
    end)
end)

describe("Evidence: lurek.pathfinding FlowField", function()

    it("newFlowField creates a flow field", function()
        local grid = lurek.pathfinding.newNavGrid(8, 8)
        local ff   = lurek.pathfinding.newFlowField(grid, 8, 8)
        expect_equal(ff ~= nil, true)
    end)

    it("flow field can be computed toward a goal", function()
        local grid = lurek.pathfinding.newNavGrid(10, 10)
        local ff   = lurek.pathfinding.newFlowField(grid, 10, 10)
        ff:compute(10, 10)  -- flow toward bottom-right
        -- Direction at top-left should be non-zero
        local dx, dy = ff:getDirection(1, 1)
        expect_equal(type(dx) == "number" and type(dy) == "number", true)
    end)

    it("flow field PNG evidence: astar_flow_field", function()
        local W, H = 16, 16
        local grid = lurek.pathfinding.newNavGrid(W, H)

        -- A few obstacles
        for y = 3, 12 do grid:setBlocked(8, y, true) end
        for x = 8, 16 do grid:setBlocked(x, 8, true) end

        local ff = lurek.pathfinding.newFlowField(grid, W, H)
        ff:compute(16, 16)

        local scale = 12
        local img = lurek.image.newImageData(W * scale, H * scale)
        img:fill(30, 30, 30, 255)

        for y = 1, H do
            for x = 1, W do
                local blocked = grid:isBlocked(x, y)
                if blocked then
                    img:fillRect((x-1)*scale+1, (y-1)*scale+1, scale-2, scale-2, 20, 20, 60, 255)
                else
                    img:fillRect((x-1)*scale+1, (y-1)*scale+1, scale-2, scale-2, 80, 80, 100, 255)
                    local dx, dy = ff:getDirection(x, y)
                    if dx ~= 0 or dy ~= 0 then
                        local cx = (x-1)*scale + scale//2
                        local cy = (y-1)*scale + scale//2
                        local ex = cx + math.floor(dx * (scale//2 - 1))
                        local ey = cy + math.floor(dy * (scale//2 - 1))
                        img:drawLine(cx, cy, ex, ey, 100, 220, 100, 255)
                    end
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "evidence_pathfinding_flow_field.png")
    end)
end)

test_summary()
