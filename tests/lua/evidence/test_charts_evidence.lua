-- Evidence tests: charts module
-- Produces PNG artifacts for each chart type (line, bar, scatter, pie, area).

-- @describe evidence: charts
describe("evidence: charts", function()
    before_each(function()
        ensure_evidence_dir("charts")
    end)

    -- @evidence file
    it("produces a line chart PNG", function()
        local dir = evidence_output_dir("charts")
        local path = dir .. "line_chart.png"
        local img = lurek.image.newImageData(400, 300)
        img:fill(240, 240, 240, 255)
        local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Sine Wave" })
        local pts = {}
        for i = 0, 20 do
            local t = i / 20
            pts[#pts + 1] = { x = t, y = (math.sin(t * math.pi * 2) + 1) / 2 }
        end
        chart:addSeries("sin", pts, 0.2, 0.5, 0.9)
        chart:setYMax(1.0)
        chart:drawToImage(img)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a bar chart PNG", function()
        local dir = evidence_output_dir("charts")
        local path = dir .. "bar_chart.png"
        local img = lurek.image.newImageData(400, 300)
        img:fill(245, 245, 250, 255)
        local chart = lurek.ui.newBarChart({ width = 400, height = 300, title = "Monthly" })
        chart:addSeries("A", 0.8, 0.2, 0.2)
        chart:addSeries("B", 0.2, 0.6, 0.9)
        chart:addCategory("Jan", { 30, 45 })
        chart:addCategory("Feb", { 55, 35 })
        chart:addCategory("Mar", { 70, 60 })
        chart:addCategory("Apr", { 40, 80 })
        chart:drawToImage(img)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a scatter plot PNG", function()
        local dir = evidence_output_dir("charts")
        local path = dir .. "scatter_plot.png"
        local img = lurek.image.newImageData(400, 300)
        img:fill(250, 250, 250, 255)
        local chart = lurek.ui.newScatterPlot({ width = 400, height = 300, title = "Points" })
        local pts1, pts2 = {}, {}
        for i = 1, 20 do
            pts1[i] = { x = i * 0.05, y = i * 0.04 + (i % 3) * 0.1 }
            pts2[i] = { x = i * 0.05, y = (21 - i) * 0.04 }
        end
        chart:addSeries("rising",  pts1, 0.9, 0.3, 0.2)
        chart:addSeries("falling", pts2, 0.2, 0.5, 0.9)
        chart:setXRange(0, 1.1)
        chart:setYRange(0, 1.1)
        chart:drawToImage(img)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a pie chart PNG", function()
        local dir = evidence_output_dir("charts")
        local path = dir .. "pie_chart.png"
        local img = lurek.image.newImageData(400, 300)
        img:fill(255, 255, 255, 255)
        local chart = lurek.ui.newPieChart({ width = 400, height = 300, title = "Budget" })
        chart:addSegment("Rent",      40, 0.8, 0.2, 0.2)
        chart:addSegment("Food",      25, 0.2, 0.7, 0.3)
        chart:addSegment("Transport", 20, 0.2, 0.4, 0.9)
        chart:addSegment("Other",     15, 0.8, 0.6, 0.1)
        chart:drawToImage(img)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces an area chart PNG", function()
        local dir = evidence_output_dir("charts")
        local path = dir .. "area_chart.png"
        local img = lurek.image.newImageData(400, 300)
        img:fill(245, 248, 255, 255)
        local chart = lurek.ui.newAreaChart({ width = 400, height = 300, title = "Stack" })
        chart:addLayer("A", { 10, 20, 35, 30, 25, 40 }, 0.9, 0.3, 0.3)
        chart:addLayer("B", { 20, 15, 10, 20, 30, 15 }, 0.3, 0.7, 0.4)
        chart:setYMax(70)
        chart:drawToImage(img)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("produces a dual-series trend line PNG", function()
        local dir = evidence_output_dir("charts")
        local path = dir .. "trend_dual_series.png"
        local img = lurek.image.newImageData(480, 300)
        img:fill(238, 242, 250, 255)
        local chart = lurek.ui.newLineChart({ width = 480, height = 300, title = "Quarterly Trend" })
        chart:setYMax(140)
        chart:setXMax(7)
        chart:addSeries("Revenue", {
            {0, 22}, {1, 34}, {2, 44}, {3, 52},
            {4, 68}, {5, 79}, {6, 95}, {7, 118},
        }, 0.15, 0.45, 0.85)
        chart:addSeries("Cost", {
            {0, 18}, {1, 29}, {2, 38}, {3, 50},
            {4, 58}, {5, 74}, {6, 80}, {7, 92},
        }, 0.85, 0.35, 0.2)
        chart:addSeries("Forecast", {
            {0, 20}, {1, 31}, {2, 40}, {3, 55},
            {4, 72}, {5, 86}, {6, 103}, {7, 126},
        }, 0.25, 0.65, 0.35)
        chart:drawToImage(img)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
