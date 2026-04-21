-- test_evidence_bezier.lua
-- Evidence test: BezierCurve creation, evaluation, and visualisation

local OUT = "tests/lua/evidence/output/bezier/"

local function plot_point(img, x, y, r, g, b, size)
    size = size or 2
    local ix = math.floor(x)
    local iy = math.floor(y)
    img:drawRect(ix - math.floor(size / 2), iy - math.floor(size / 2), size, size, r, g, b, 255)
end

local function plot_control_points(img, curve)
    local count = curve:getControlPointCount()
    for i = 1, count do
        local cx, cy = curve:getControlPoint(i)
        if cx then
            img:drawCircle(math.floor(cx), math.floor(cy), 4, 255, 0, 0, 255)
        end
    end
end

-- @description Covers suite: Evidence: Bezier curves.
describe("Evidence: Bezier curves", function()

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @covers BezierCurve:getControlPointCount
    -- @covers BezierCurve:getControlPoint
    -- @evidence file
    -- @description Samples a quadratic Bezier and saves a PNG showing both the curve and its control polygon.
    it("quadratic bezier (3 control points)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({50, 250, 200, 30, 350, 250})

        -- Plot curve
        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 100, 200, 255, 3)
        end

        -- Plot control points
        plot_control_points(img, curve)

        -- Draw control polygon
        img:drawLine(50, 250, 200, 30, 80, 80, 80, 255)
        img:drawLine(200, 30, 350, 250, 80, 80, 80, 255)

        lurek.image.savePNG(img, OUT .. "bezier_quadratic.png")
    end)

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @covers BezierCurve:getControlPointCount
    -- @covers BezierCurve:getControlPoint
    -- @evidence file
    -- @description Samples a cubic Bezier and exports a PNG showing how four control points shape the final curve.
    it("cubic bezier (4 control points)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({30, 250, 100, 30, 300, 30, 370, 250})

        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 255, 180, 50, 3)
        end

        plot_control_points(img, curve)

        -- Control polygon
        img:drawLine(30, 250, 100, 30, 80, 80, 80, 255)
        img:drawLine(100, 30, 300, 30, 80, 80, 80, 255)
        img:drawLine(300, 30, 370, 250, 80, 80, 80, 255)

        lurek.image.savePNG(img, OUT .. "bezier_cubic.png")
    end)

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @covers BezierCurve:getControlPointCount
    -- @covers BezierCurve:getControlPoint
    -- @evidence file
    -- @description Draws a higher-order Bezier curve with seven control points to prove complex paths evaluate and render correctly.
    it("complex bezier (7 control points)", function()
        local W, H = 500, 400
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({
            30, 350,
            80, 50,
            180, 350,
            250, 50,
            320, 350,
            400, 50,
            470, 350,
        })

        local steps = 300
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 50, 255, 100, 3)
        end

        plot_control_points(img, curve)

        -- Control polygon
        local count = curve:getControlPointCount()
        for i = 1, count - 1 do
            local x1, y1 = curve:getControlPoint(i)
            local x2, y2 = curve:getControlPoint(i + 1)
            if x1 and x2 then
                img:drawLine(
                    math.floor(x1), math.floor(y1),
                    math.floor(x2), math.floor(y2),
                    60, 60, 60, 255
                )
            end
        end

        lurek.image.savePNG(img, OUT .. "bezier_complex.png")
    end)

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:getDerivative
    -- @covers BezierCurve:evaluate
    -- @evidence file
    -- @description Evaluates the derivative curve to render tangent vectors at multiple points along a cubic Bezier.
    it("derivative visualisation (tangent lines)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({30, 250, 100, 30, 300, 30, 370, 250})
        local deriv = curve:getDerivative()

        -- Plot the original curve
        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 100, 200, 255, 2)
        end

        -- Plot tangent lines at regular intervals
        local tangent_steps = 10
        local tangent_len = 30
        for i = 0, tangent_steps do
            local t = i / tangent_steps
            local px, py = curve:evaluate(t)
            local dx, dy = deriv:evaluate(t)
            -- Normalize the tangent
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.001 then
                dx = dx / len * tangent_len
                dy = dy / len * tangent_len
                img:drawLine(
                    math.floor(px), math.floor(py),
                    math.floor(px + dx), math.floor(py + dy),
                    255, 100, 100, 255
                )
            end
            -- Mark the point
            img:drawCircle(math.floor(px), math.floor(py), 3, 255, 255, 0, 255)
        end

        plot_control_points(img, curve)

        lurek.image.savePNG(img, OUT .. "bezier_tangents.png")
    end)

end)
test_summary()
