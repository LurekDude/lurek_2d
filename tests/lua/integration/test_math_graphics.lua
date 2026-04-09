-- Lurek2D Integration Test: Math + Graphics (headless-safe)
-- Tests math operations used in graphics contexts without requiring GPU

describe("math for graphics transformations", function()
    it("rotation matrix components", function()
        local angle = math.rad(90)
        local cos_a = lurek.math.cos(angle)
        local sin_a = lurek.math.sin(angle)

        -- 90-degree rotation matrix should be: [0, -1; 1, 0]
        expect_near(0, cos_a, 0.001, "cos(90)")
        expect_near(1, sin_a, 0.001, "sin(90)")
    end)

    it("scale + translate point", function()
        -- Apply scale then translate
        local x, y = 10, 20
        local sx, sy = 2, 3
        local tx, ty = 100, 200

        local result_x = x * sx + tx
        local result_y = y * sy + ty

        expect_near(120, result_x, 0.001, "scaled + translated x")
        expect_near(260, result_y, 0.001, "scaled + translated y")
    end)

    it("screen to world coordinates", function()
        -- Camera at (100, 200), screen point at (400, 300), zoom 2x
        local cam_x, cam_y = 100, 200
        local screen_x, screen_y = 400, 300
        local zoom = 2.0
        local screen_w, screen_h = 800, 600

        local world_x = cam_x + (screen_x - screen_w / 2) / zoom
        local world_y = cam_y + (screen_y - screen_h / 2) / zoom

        expect_near(100, world_x, 0.001, "world x")
        expect_near(200, world_y, 0.001, "world y at center")
    end)

    it("world to screen coordinates", function()
        local cam_x, cam_y = 100, 200
        local world_x, world_y = 100, 200
        local zoom = 2.0
        local screen_w, screen_h = 800, 600

        local screen_x = (world_x - cam_x) * zoom + screen_w / 2
        local screen_y = (world_y - cam_y) * zoom + screen_h / 2

        expect_near(400, screen_x, 0.001, "screen center x")
        expect_near(300, screen_y, 0.001, "screen center y")
    end)
end)

describe("math color operations", function()
    it("lerp between colors", function()
        local r1, g1, b1 = 1.0, 0.0, 0.0  -- red
        local r2, g2, b2 = 0.0, 0.0, 1.0  -- blue
        local t = 0.5

        local r = r1 + (r2 - r1) * t
        local g = g1 + (g2 - g1) * t
        local b = b1 + (b2 - b1) * t

        expect_near(0.5, r, 0.001, "interpolated red")
        expect_near(0.0, g, 0.001, "interpolated green")
        expect_near(0.5, b, 0.001, "interpolated blue")
    end)

    it("HSV to RGB conversion", function()
        -- Pure red: H=0, S=1, V=1
        local h, s, v = 0, 1, 1
        local r, g, b

        local i = lurek.math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)

        if i % 6 == 0 then r, g, b = v, t, p
        elseif i % 6 == 1 then r, g, b = q, v, p
        elseif i % 6 == 2 then r, g, b = p, v, t
        elseif i % 6 == 3 then r, g, b = p, q, v
        elseif i % 6 == 4 then r, g, b = t, p, v
        else r, g, b = v, p, q
        end

        expect_near(1.0, r, 0.001, "red = 1")
        expect_near(0.0, g, 0.01, "green = 0")
        expect_near(0.0, b, 0.001, "blue = 0")
    end)
end)

describe("math geometry utilities", function()
    it("point inside rectangle", function()
        local px, py = 5, 5
        local rx, ry, rw, rh = 0, 0, 10, 10

        local inside = px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
        expect_true(inside, "point is inside rect")

        local outside_x, outside_y = 15, 5
        local outside = outside_x >= rx and outside_x <= rx + rw and outside_y >= ry and outside_y <= ry + rh
        expect_false(outside, "point is outside rect")
    end)

    it("point inside circle", function()
        local px, py = 3, 4
        local cx, cy, cr = 0, 0, 6

        local dist_sq = (px - cx)^2 + (py - cy)^2
        local inside = dist_sq <= cr * cr

        expect_true(inside, "point inside circle (dist=5, radius=6)")
    end)

    it("line segment intersection", function()
        -- Perpendicular lines that cross at (5, 5)
        local x1, y1, x2, y2 = 0, 5, 10, 5  -- horizontal
        local x3, y3, x4, y4 = 5, 0, 5, 10  -- vertical

        local denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        expect_true(lurek.math.abs(denom) > 0.001, "lines are not parallel")

        local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
        local ix = x1 + t * (x2 - x1)
        local iy = y1 + t * (y2 - y1)

        expect_near(5, ix, 0.001, "intersection x")
        expect_near(5, iy, 0.001, "intersection y")
    end)
end)
