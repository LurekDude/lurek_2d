-- test_evidence_geometry.lua
-- Evidence test: geometry shapes, intersection tests, and Delaunay triangulation
-- @evidence file

require("tests/lua/init")

local OUT = "tests/lua/evidence/output/geometry/"

local function draw_dot(img, cx, cy, radius, r, g, b)
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2 then
                img:setPixel(x, y, r, g, b, 255)
            end
        end
    end
end

-- @description Test suite for Evidence: geometry shapes and queries
describe("Evidence: geometry shapes and queries", function()

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a gallery of polygon outlines so basic vertex stepping and PNG export can be inspected visually.
    it("polygon gallery (triangle, quad, pentagon, hexagon)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 30, 255)
        -- Draw regular polygons
        local shapes = {
            {cx=64,  cy=64,  r=40, sides=3,  color={255,100,100}},
            {cx=192, cy=64,  r=40, sides=4,  color={100,255,100}},
            {cx=64,  cy=192, r=40, sides=5,  color={100,100,255}},
            {cx=192, cy=192, r=40, sides=6,  color={255,255,100}},
        }
        for _, s in ipairs(shapes) do
            for i = 0, s.sides - 1 do
                local a1 = (2 * math.pi * i / s.sides) - math.pi/2
                local a2 = (2 * math.pi * (i+1) / s.sides) - math.pi/2
                local x1 = math.floor(s.cx + s.r * math.cos(a1))
                local y1 = math.floor(s.cy + s.r * math.sin(a1))
                local x2 = math.floor(s.cx + s.r * math.cos(a2))
                local y2 = math.floor(s.cy + s.r * math.sin(a2))
                -- Draw line segment
                for t = 0, 1, 0.005 do
                    local px = math.floor(x1 + (x2 - x1) * t)
                    local py = math.floor(y1 + (y2 - y1) * t)
                    if px >= 0 and px < W and py >= 0 and py < H then
                        img:setPixel(px, py, s.color[1], s.color[2], s.color[3], 255)
                    end
                end
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_polygon_gallery.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Paints filled circles and rectangles into one PNG to document simple raster-shape composition.
    it("filled primitives (circles and rectangles)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(15, 15, 25, 255)
        -- Filled circles
        draw_dot(img, 64, 64, 30, 255, 80, 80)
        draw_dot(img, 192, 64, 25, 80, 255, 80)
        draw_dot(img, 128, 192, 35, 80, 80, 255)
        -- Filled rects
        for y = 100, 140 do
            for x = 20, 80 do
                img:setPixel(x, y, 255, 200, 50, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_filled_primitives.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Renders an Archimedean spiral into a PNG so the generated parametric shape can be reviewed manually.
    it("spirals (Archimedean spiral)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(10, 10, 20, 255)
        local cx, cy = 128, 128
        for i = 0, 1000 do
            local t = i * 0.01
            local r = t * 8
            local x = math.floor(cx + r * math.cos(t * 2))
            local y = math.floor(cy + r * math.sin(t * 2))
            if x >= 0 and x < W and y >= 0 and y < H then
                local c = math.floor(255 * (1 - t / 10))
                img:setPixel(x, y, c, math.floor(c * 0.6), 255, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_spirals.png")
    end)
        end)
    end)
end)
test_summary()
