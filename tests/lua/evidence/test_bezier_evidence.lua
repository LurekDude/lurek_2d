-- Evidence tests: bezier module
-- Produces PNG artifacts from lurek.math.newBezierCurve curve evaluation.

describe("evidence: bezier", function()
    before_each(function()
        ensure_evidence_dir("bezier")
    end)

    -- @evidence file
    it("plots a quadratic Bezier curve PNG", function()
        local dir  = evidence_output_dir("bezier")
        local path = dir .. "bezier_quadratic.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(245, 245, 245, 255)

        -- control points (flat: x1,y1,x2,y2,x3,y3)
        local curve = lurek.math.newBezierCurve({ 20, 180, 100, 20, 180, 180 })
        expect_true(curve:getControlPointCount() == 3, "quadratic curve must have 3 control points")

        -- draw control polygon
        local function cp(i) return curve:getControlPoint(i) end
        local cx1,cy1 = cp(1) ; local cx2,cy2 = cp(2) ; local cx3,cy3 = cp(3)
        img:drawLine(cx1, cy1, cx2, cy2, 180, 180, 180, 255)
        img:drawLine(cx2, cy2, cx3, cy3, 180, 180, 180, 255)
        img:drawCircle(cx1, cy1, 4, 180, 60, 60, 255)
        img:drawCircle(cx2, cy2, 4, 60, 180, 60, 255)
        img:drawCircle(cx3, cy3, 4, 60, 60, 180, 255)

        -- plot curve
        local steps = 80
        for i = 0, steps do
            local t = i / steps
            local px, py = curve:evaluate(t)
            px = math.floor(px + 0.5)
            py = math.floor(py + 0.5)
            px = math.max(0, math.min(W - 1, px))
            py = math.max(0, math.min(H - 1, py))
            img:setPixel(px, py, 40, 100, 220, 255)
        end

        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("plots a cubic Bezier curve with tangents PNG", function()
        local dir  = evidence_output_dir("bezier")
        local path = dir .. "bezier_cubic.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(250, 250, 250, 255)

        local curve = lurek.math.newBezierCurve({ 20, 170, 60, 20, 140, 20, 180, 170 })
        expect_true(curve:getControlPointCount() == 4, "cubic curve must have 4 control points")

        -- plot the curve
        local steps = 100
        local prev_x, prev_y
        for i = 0, steps do
            local t = i / steps
            local px, py = curve:evaluate(t)
            px = math.floor(px + 0.5)
            py = math.floor(py + 0.5)
            px = math.max(0, math.min(W - 1, px))
            py = math.max(0, math.min(H - 1, py))
            if prev_x then
                img:drawLine(prev_x, prev_y, px, py, 50, 120, 220, 255)
            end
            prev_x, prev_y = px, py
        end

        -- draw tangent at t=0.5: getDerivative() returns the derivative BezierCurve
        local tx, ty = curve:evaluate(0.5)
        local deriv = curve:getDerivative()
        local dx, dy = deriv:evaluate(0.5)
        local scale = 30 / math.max(1, math.sqrt(dx * dx + dy * dy))
        local ex = math.floor(tx + dx * scale + 0.5)
        local ey = math.floor(ty + dy * scale + 0.5)
        img:drawLine(math.floor(tx), math.floor(ty), ex, ey, 220, 80, 50, 255)

        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
