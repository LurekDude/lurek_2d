-- test_evidence_shapes.lua
-- Evidence test: 2D shape drawing using lurek.img primitives

local OUT = "tests/lua/evidence/output/shapes/"

-- Helper: draw a regular polygon centred at (cx, cy)
local function draw_polygon(img, cx, cy, radius, sides, r, g, b, a)
    a = a or 255
    local prev_x, prev_y
    for i = 0, sides do
        local angle = (i / sides) * 2 * math.pi - math.pi / 2
        local nx = math.floor(cx + radius * math.cos(angle))
        local ny = math.floor(cy + radius * math.sin(angle))
        if prev_x then
            img:drawLine(prev_x, prev_y, nx, ny, r, g, b, a)
        end
        prev_x, prev_y = nx, ny
    end
end

-- Helper: draw a spiral
local function draw_spiral(img, cx, cy, turns, r, g, b)
    local steps = turns * 60
    local prev_x, prev_y
    for i = 0, steps do
        local t  = i / steps
        local angle  = t * turns * 2 * math.pi
        local rad    = t * 80
        local nx = math.floor(cx + rad * math.cos(angle))
        local ny = math.floor(cy + rad * math.sin(angle))
        if prev_x then
            img:drawLine(prev_x, prev_y, nx, ny, r, g, b, 255)
        end
        prev_x, prev_y = nx, ny
    end
end

describe("Evidence: Shapes", function()

    it("renders a polygon gallery", function()
        local W, H = 512, 256
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        -- Row of polygons: triangle, square, pentagon, hexagon, octagon, circle
        local configs = {
            { sides = 3,  cx = 48,  label = "tri"  },
            { sides = 4,  cx = 128, label = "quad" },
            { sides = 5,  cx = 208, label = "pent" },
            { sides = 6,  cx = 288, label = "hex"  },
            { sides = 8,  cx = 368, label = "oct"  },
            { sides = 32, cx = 448, label = "circ" },
        }
        for _, c in ipairs(configs) do
            draw_polygon(img, c.cx, 80, 36, c.sides, 80, 160, 255, 255)
            draw_polygon(img, c.cx, 80, 36, c.sides, 80, 160, 255, 255)
        end

        -- Second row: filled circles
        for i, c in ipairs(configs) do
            local hue_r = math.floor(40 + (i - 1) * 35)
            img:drawCircle(c.cx, 180, 28, hue_r, 120, 200, 200)
        end

        lurek.img.savePNG(img, OUT .. "polygon_gallery.png")
    end)

    it("renders filled primitive shapes", function()
        local W, H = 400, 400
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 15, 15, 25, 255)

        -- Filled rectangles
        img:drawRect(20,  20,  120, 80,  200, 80,  80,  200)
        img:drawRect(160, 20,  120, 80,  80,  200, 80,  200)
        img:drawRect(300, 20,  80,  80,  80,  80,  200, 200)

        -- Filled circles
        img:drawCircle(60,  200, 50, 220, 120, 40,  200)
        img:drawCircle(200, 200, 50, 40,  180, 220, 200)
        img:drawCircle(340, 200, 50, 180, 40,  220, 200)

        -- Diagonal lines
        for i = 0, 7 do
            local x = i * 50
            img:drawLine(x, 300, x + 40, 380, 200, 200, 40, 200)
        end

        lurek.img.savePNG(img, OUT .. "filled_primitives.png")
    end)

    it("renders a spiral gallery", function()
        local W, H = 400, 300
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        draw_spiral(img, 70,  150, 3, 220, 80,  80)
        draw_spiral(img, 200, 150, 4, 80,  220, 80)
        draw_spiral(img, 330, 150, 5, 80,  80,  220)

        lurek.img.savePNG(img, OUT .. "spirals.png")
    end)

    it("renders concentric shape rings", function()
        local W, H = 300, 300
        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        local cx, cy = 150, 150
        for i = 1, 8 do
            local r = i * 16
            local col = math.floor(20 + i * 28)
            local inv = math.max(0, 220 - col)
            img:drawCircle(cx, cy, r, col, 120, inv, 180)
        end
        for i = 1, 5 do
            local r = i * 20
            draw_polygon(img, cx, cy, r, 6, 255, 200, 50, 200)
        end

        lurek.img.savePNG(img, OUT .. "concentric_rings.png")
    end)

end)

test_summary()
