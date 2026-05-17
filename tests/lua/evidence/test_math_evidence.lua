-- test_math_evidence.lua
-- Clean evidence suite for lurek.math with PNG-only outputs.

local OUT = "tests/output/math/"

local function clamp255(v)
    if v < 0 then return 0 end
    if v > 255 then return 255 end
    return math.floor(v)
end

local function to_px(x, y, w, h, scale)
    local cx = math.floor(w * 0.5)
    local cy = math.floor(h * 0.5)
    return math.floor(cx + x * scale + 0.5), math.floor(cy - y * scale + 0.5)
end

-- @describe Evidence: lurek.math visual scenarios
describe("Evidence: lurek.math visual scenarios", function()
    before_each(function()
        ensure_evidence_dir("math")
    end)

    -- @evidence file
    it("PNG: math_vec2_unit_circle.png -- normalized vectors on unit circle", function()
        local w, h = 240, 240
        local img = lurek.image.newImageData(w, h)
        img:fill(240, 244, 250, 255)
        img:drawCircle(120, 120, 92, 160, 170, 190, 255)

        for i = 0, 95 do
            local a = i / 96 * math.pi * 2
            local v = lurek.math.vec2(math.cos(a), math.sin(a))
            local n = v:normalize()
            local x, y = to_px(n.x, n.y, w, h, 92)
            img:drawRect(x - 1, y - 1, 3, 3, 60, 110, 220, 255)
        end

        local path = OUT .. "math_vec2_unit_circle.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_distance_heatmap.png -- radial distance map", function()
        local w, h = 256, 192
        local img = lurek.image.newImageData(w, h)

        local cx, cy = 128, 96
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                local d = lurek.math.distance(x, y, cx, cy)
                local t = lurek.math.clamp(1.0 - d / 130.0, 0.0, 1.0)
                img:setPixel(x, y, clamp255(40 + t * 180), clamp255(40 + t * 120), clamp255(80 + t * 140), 255)
            end
        end

        local path = OUT .. "math_distance_heatmap.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_perlin2d_map.png -- seeded perlin field", function()
        local w, h = 256, 192
        local img = lurek.image.newImageData(w, h)

        for y = 0, h - 1 do
            for x = 0, w - 1 do
                local n = lurek.math.perlin2d(x * 0.05, y * 0.05, 1337)
                local t = (n + 1.0) * 0.5
                img:setPixel(x, y, clamp255(20 + t * 220), clamp255(30 + t * 170), clamp255(60 + t * 150), 255)
            end
        end

        local path = OUT .. "math_perlin2d_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_simplex2d_map.png -- simplex field", function()
        local w, h = 256, 192
        local img = lurek.image.newImageData(w, h)

        for y = 0, h - 1 do
            for x = 0, w - 1 do
                local n = lurek.math.simplex2d(x * 0.05, y * 0.05, 7)
                local t = (n + 1.0) * 0.5
                img:setPixel(x, y, clamp255(30 + t * 160), clamp255(20 + t * 200), clamp255(40 + t * 220), 255)
            end
        end

        local path = OUT .. "math_simplex2d_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_fbm_terrain.png -- fBm terrain shades", function()
        local w, h = 256, 192
        local img = lurek.image.newImageData(w, h)

        for y = 0, h - 1 do
            for x = 0, w - 1 do
                local n = lurek.math.fbm(x * 0.022, y * 0.022, 17, 5, 2.0, 0.5)
                local t = lurek.math.clamp((n + 1.0) * 0.5, 0.0, 1.0)
                local r, g, b = 25, 30, 60
                if t < 0.38 then
                    r, g, b = 28, 70, 140
                elseif t < 0.56 then
                    r, g, b = 198, 183, 125
                else
                    r, g, b = 78, 142, 84
                end
                img:setPixel(x, y, clamp255(r * (0.6 + t * 0.5)), clamp255(g * (0.6 + t * 0.5)), clamp255(b * (0.6 + t * 0.5)), 255)
            end
        end

        local path = OUT .. "math_fbm_terrain.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_easing_curves.png -- multiple easing function curves", function()
        local w, h = 300, 200
        local img = lurek.image.newImageData(w, h)
        img:fill(242, 244, 248, 255)
        img:drawRect(20, 20, 260, 160, 220, 224, 232, 255)

        local easings = {
            { "linear", 230, 80, 80 },
            { "inOutQuad", 90, 170, 230 },
            { "outBounce", 70, 190, 120 },
            { "outElastic", 180, 120, 240 },
        }

        for _, e in ipairs(easings) do
            local name, r, g, b = e[1], e[2], e[3], e[4]
            local px, py = nil, nil
            for i = 0, 220 do
                local t = i / 220
                local v = lurek.math.applyEasing(name, t)
                local x = 30 + i
                local y = 170 - math.floor(v * 140)
                if px ~= nil and py ~= nil then
                    img:drawLine(px, py, x, y, r, g, b, 255)
                end
                px, py = x, y
            end
        end

        local path = OUT .. "math_easing_curves.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_segment_intersections.png -- segment intersection grid", function()
        local w, h = 300, 220
        local img = lurek.image.newImageData(w, h)
        img:fill(18, 22, 30, 255)

        for i = 0, 9 do
            local y = 20 + i * 18
            img:drawLine(20, y, 280, y, 50, 60, 80, 255)
        end

        for i = 0, 8 do
            local x1 = 30 + i * 28
            local y1 = 34
            local x2 = 270 - i * 20
            local y2 = 190
            img:drawLine(x1, y1, x2, y2, 110, 180, 255, 255)

            local hit, ix, iy = lurek.math.segmentIntersectsSegment(x1, y1, x2, y2, 30, 150, 280, 70)
            if hit and ix and iy then
                img:drawCircle(ix --[[@as number]], iy --[[@as number]], 3, 255, 210, 100, 255)
            end
        end
        img:drawLine(30, 150, 280, 70, 255, 120, 120, 255)

        local path = OUT .. "math_segment_intersections.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_polygon_metrics.png -- area, centroid and inside test map", function()
        local w, h = 300, 220
        local img = lurek.image.newImageData(w, h)
        img:fill(242, 246, 252, 255)

        local poly = { 40, 170, 110, 52, 220, 44, 266, 132, 198, 184, 96, 198 }

        local area = lurek.math.polygonArea(poly)
        local cx, cy = lurek.math.polygonCentroid(poly)

        for y = 0, h - 1, 3 do
            for x = 0, w - 1, 3 do
                if lurek.math.pointInPolygon(poly, x, y) then
                    img:drawRect(x, y, 2, 2, 145, 205, 255, 220)
                end
            end
        end

        for i = 1, #poly, 2 do
            local j = i + 2
            if j > #poly then j = 1 end
            img:drawLine(poly[i], poly[i + 1], poly[j], poly[j + 1], 50, 90, 140, 255)
        end

        img:drawCircle(cx, cy, 4, 255, 130, 80, 255)
        img:drawRect(12, 12, math.min(120, math.floor(math.abs(area) * 0.2)), 10, 110, 170, 240, 255)

        local path = OUT .. "math_polygon_metrics.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_hsl_gradient.png -- HSL to RGB conversion gradient", function()
        local w, h = 320, 96
        local img = lurek.image.newImageData(w, h)

        for x = 0, w - 1 do
            local hval = x / (w - 1) * 360.0
            local r, g, b = lurek.math.hslToRgb(hval, 0.78, 0.52)
            local rr = clamp255(r * 255)
            local gg = clamp255(g * 255)
            local bb = clamp255(b * 255)
            img:drawRect(x, 0, 1, h, rr, gg, bb, 255)
        end

        local path = OUT .. "math_hsl_gradient.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: math_bresenham_rays.png -- raster rays from center", function()
        local w, h = 256, 256
        local img = lurek.image.newImageData(w, h)
        img:fill(12, 14, 20, 255)

        local cx, cy = 128, 128
        for i = 0, 31 do
            local a = i / 32 * math.pi * 2
            local ex = math.floor(cx + math.cos(a) * 112)
            local ey = math.floor(cy + math.sin(a) * 112)
            local pts = lurek.math.bresenham(cx, cy, ex, ey)
            for _, p in ipairs(pts) do
                local t = lurek.math.distance(cx, cy, p[1], p[2]) / 112
                img:setPixel(p[1], p[2], clamp255(80 + 140 * t), clamp255(130 + 100 * (1.0 - t)), 255, 255)
            end
        end

        local path = OUT .. "math_bresenham_rays.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)

test_summary()
