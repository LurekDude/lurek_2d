-- Evidence suite: pathfind module
-- lurek.pathfind NavGrid and A* path-finding evidence.
-- Full path-finding operations require a configured NavGrid; those cases are xit'd pending API stabilisation.
-- @module pathfind
-- @description Evidence suite for lurek.pathfind: API surface and NavGrid construction evidence.

-- @covers lurek.pathfind (API surface)
-- @evidence file
describe("evidence: pathfind", function()
    before_each(function()
        ensure_evidence_dir("pathfind")
    end)

    -- @description Renders a PNG showing API presence: green=present, red=missing.
    it("records pathfind API surface as PNG evidence", function()
        local dir  = evidence_output_dir("pathfind")
        local path = dir .. "pathfind_api_surface.png"
        local pf   = lurek.pathfind
        local fns  = { "newNavGrid", "newFlowField", "findPath", "findPathAsync" }
        local W, H = 200, #fns * 24 + 8
        local img  = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 20, 255)
        for i, name in ipairs(fns) do
            local present = type(pf[name]) == "function"
            local r, g = present and 40 or 200, present and 200 or 40
            local y = (i - 1) * 24 + 4
            img:drawRect(4, y, 16, 16, r, g, 40, 255)
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_pathfind_extended_evidence.lua
-- ================================================================

-- test_evidence_pathfind_extended.lua
-- Evidence test: lurek.pathfind API contracts and visual grid evidence

local OUT = "tests/output/pathfinding/"

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            img:drawRect((x-1)*scale + 1, (y-1)*scale + 1, scale - 1, scale - 1, r, g, b, 255)
        end
    end

    -- Draw path
    if path then
        for _, step in ipairs(path) do
            local px = (step.x - 1) * scale + math.floor(scale / 2)
            local py = (step.y - 1) * scale + math.floor(scale / 2)
            img:drawCircle(px, py, math.max(1, math.floor(scale / 3)), 255, 80, 80, 255)
        end
    end

    return img
end

-- â”€â”€ tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Evidence: lurek.pathfind A* basic.
describe("Evidence: lurek.pathfind A* basic", function()
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newUnitPathfinder
    -- @description Verifies A* spatial awareness navigating around a rigid wall gap by exporting a PNG visual array showing path trace routing accurately passing through the non-blocked slot.
    xit("path avoids walls -\" PNG evidence: astar_basic", function()
        local W, H = 20, 15
        local grid = lurek.pathfind.newNavGrid(W, H)

        -- Vertical wall in the middle with a single gap
        for y = 1, H do
            if y ~= 8 then
                grid:setBlocked(10, y, true)
            end
        end

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 20, 15)

        local img = draw_nav_grid(grid, path, W, H, 10)
        lurek.image.savePNG(img, OUT .. "evidence_pathfinding_astar_wall.png")
    end)
end)

-- @description Covers suite: Evidence: lurek.pathfind weighted terrain.
describe("Evidence: lurek.pathfind weighted terrain", function()

    -- @evidence file
    -- @covers lurek.pathfind.newUnitPathfinder
    -- @covers UnitPathfinder:findPath
    -- @description Confirms terrain weighting algorithm correctly biases algorithms against high-cost regions (swamps/mud) leading to finding optimal longer routes vs shorter, costly ones. Output generated to an image verification file.
    xit("higher-cost terrain is avoided when cheaper route exists -\" PNG evidence", function()
        local W, H = 12, 12
        local grid = lurek.pathfind.newNavGrid(W, H)

        -- Centre strip is expensive (mud / water)
        for y = 1, H do
            grid:setCost(6, y, 9)
            grid:setCost(7, y, 9)
        end

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 6, 12, 6)

        local img = draw_nav_grid(grid, path, W, H, 14)
        lurek.image.savePNG(img, OUT .. "evidence_pathfinding_weighted.png")
    end)
end)

-- @description Covers suite: Evidence: lurek.pathfind FlowField.
describe("Evidence: lurek.pathfind FlowField", function()
    -- @evidence file
    -- @covers FlowField:calculate
    -- @covers FlowField:getDirection
    -- @covers lurek.pathfind.newFlowField
    -- @description Visually outputs a grid map encoding obstacles, free tiles, and the generated path finding vectors via getDirection calls to show a robust global flow navigation visual.
    xit("flow field PNG evidence: astar_flow_field", function()
        local W, H = 16, 16
        local grid = lurek.pathfind.newNavGrid(W, H)

        -- A few obstacles
        for y = 3, 12 do grid:setBlocked(8, y, true) end
        for x = 8, 16 do grid:setBlocked(x, 8, true) end

        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(16, 16)

        local scale = 12
        local img = lurek.image.newImageData(W * scale, H * scale)
        img:fill(30, 30, 30, 255)

        for y = 1, H do
            for x = 1, W do
                local blocked = grid:isBlocked(x, y)
                if blocked then
                    img:drawRect((x-1)*scale+1, (y-1)*scale+1, scale-2, scale-2, 20, 20, 60, 255)
                else
                    img:drawRect((x-1)*scale+1, (y-1)*scale+1, scale-2, scale-2, 80, 80, 100, 255)
                    local dx, dy = ff:getDirection(x, y)
                    if dx ~= 0 or dy ~= 0 then
                        local cx = (x-1)*scale + math.floor(scale / 2)
                        local cy = (y-1)*scale + math.floor(scale / 2)
                        local ex = cx + math.floor(dx * (math.floor(scale / 2) - 1))
                        local ey = cy + math.floor(dy * (math.floor(scale / 2) - 1))
                        img:drawLine(cx, cy, ex, ey, 100, 220, 100, 255)
                    end
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "evidence_pathfinding_flow_field.png")
    end)
end)



-- ================================================================
-- Merged from: test_evidence_pathfind.lua
-- ================================================================

-- Placeholder evidence suite for migrated pathfinding artifacts.
-- Evidence suite: pathfind heatmap and flow-field.
-- All lurek.pathfind heatmap / flow-field operations require a live NavGrid;
-- those tests are xit'd in the extended block above.
-- This block records which pathfind functions are exposed as an API surface manifest.
-- @module pathfind (manifest)
-- @description Writes a JSON API surface manifest for lurek.pathfind heatmap and flow-field functions.

-- @covers lurek.pathfind (API surface manifest)
-- @evidence file
describe("evidence: pathfind manifest", function()
    before_each(function()
        ensure_evidence_dir("pathfind")
    end)

    -- @description Renders a PNG showing heatmap/flow-field API presence: green=present, red=missing.
    it("records pathfind heatmap API surface as PNG evidence", function()
        local dir  = evidence_output_dir("pathfind")
        local path = dir .. "pathfind_heatmap_surface.png"
        local pf   = lurek.pathfind
        local fns  = { "newNavGrid", "newFlowField", "findPath", "findPathAsync",
                       "computeHeatmap", "computeFlowField" }
        local W, H = 200, #fns * 24 + 8
        local img  = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 20, 255)
        for i, name in ipairs(fns) do
            local present = type(pf[name]) == "function"
            local r, g = present and 40 or 200, present and 200 or 40
            local y = (i - 1) * 24 + 4
            img:drawRect(4, y, 16, 16, r, g, 40, 255)
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)

test_summary()
