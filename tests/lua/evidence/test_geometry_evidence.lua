-- Evidence tests: geometry module
-- Produces PNG and JSON artifacts from lurek.math geometry functions.

describe("evidence: geometry", function()
    before_each(function()
        ensure_evidence_dir("geometry")
    end)

    -- @evidence file
    it("plots line intersection to PNG", function()
        local dir  = evidence_output_dir("geometry")
        local path = dir .. "line_intersect.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(245, 245, 245, 255)
        -- Line 1: (20,20)→(180,180)  Line 2: (20,180)→(180,20)
        local x1,y1,x2,y2 = 20,20,180,180
        local x3,y3,x4,y4 = 20,180,180,20
        img:drawLine(x1, y1, x2, y2, 60, 100, 200, 255)
        img:drawLine(x3, y3, x4, y4, 200, 80, 60, 255)
        local ix, iy = lurek.math.lineIntersect(x1,y1,x2,y2,x3,y3,x4,y4)
        expect_true(ix ~= nil, "lines must intersect")
        local px, py = math.floor(ix + 0.5), math.floor(iy + 0.5)
        img:drawCircle(px, py, 5, 220, 50, 220, 255)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders pointInPolygon classification PNG", function()
        local dir  = evidence_output_dir("geometry")
        local path = dir .. "point_in_polygon.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(245, 245, 245, 255)
        -- Triangle polygon (flat coords): (40,160),(160,160),(100,40)
        local poly = { 40,160, 160,160, 100,40 }
        img:drawLine(poly[1],poly[2], poly[3],poly[4], 60,100,180,255)
        img:drawLine(poly[3],poly[4], poly[5],poly[6], 60,100,180,255)
        img:drawLine(poly[5],poly[6], poly[1],poly[2], 60,100,180,255)
        local test_pts = {
            { x=100, y=120 },  -- inside
            { x=50,  y=50  },  -- outside
            { x=130, y=150 },  -- inside
            { x=170, y=170 },  -- outside
        }
        for _, pt in ipairs(test_pts) do
            local inside = lurek.math.pointInPolygon(poly, pt.x, pt.y)
            local r,g,b = inside and 60 or 200, inside and 180 or 60, 60
            img:drawCircle(pt.x, pt.y, 4, r, g, b, 255)
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders polygon area and centroid as PNG evidence", function()
        local dir  = evidence_output_dir("geometry")
        local path = dir .. "polygon_metrics.png"
        local W, H = 256, 256
        local img  = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 30, 30, 30, 255)  -- dark background

        -- square polygon
        local poly1 = { 20,20, 120,20, 120,120, 20,120 }
        local area1 = lurek.math.polygonArea(poly1)
        local cx1, cy1 = lurek.math.polygonCentroid(poly1)
        expect_true(math.abs(area1 - 10000) < 1, "square area must be ~10000, got " .. tostring(area1))
        img:drawRect(20, 20, 100, 100, 60, 140, 220, 255)   -- blue square
        -- cross at centroid
        img:drawLine(math.floor(cx1)-6, math.floor(cy1), math.floor(cx1)+6, math.floor(cy1), 255,255,0,255)
        img:drawLine(math.floor(cx1), math.floor(cy1)-6, math.floor(cx1), math.floor(cy1)+6, 255,255,0,255)

        -- triangle polygon
        local poly2 = { 140,20, 240,20, 190,120 }
        local area2 = lurek.math.polygonArea(poly2)
        local cx2, cy2 = lurek.math.polygonCentroid(poly2)
        -- draw triangle edges
        img:drawLine(140,20, 240,20, 80,200,80,255)
        img:drawLine(240,20, 190,120, 80,200,80,255)
        img:drawLine(190,120, 140,20, 80,200,80,255)
        -- cross at centroid
        img:drawLine(math.floor(cx2)-6, math.floor(cy2), math.floor(cx2)+6, math.floor(cy2), 255,255,0,255)
        img:drawLine(math.floor(cx2), math.floor(cy2)-6, math.floor(cx2), math.floor(cy2)+6, 255,255,0,255)

        expect_true(area2 > 0, "triangle area must be positive")
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
