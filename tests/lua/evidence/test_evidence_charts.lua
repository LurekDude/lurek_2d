-- test_evidence_charts.lua
-- Evidence test: Chart rendering (line, bar, scatter, pie, area)

local OUT = "tests/lua/evidence/output/charts/"

describe("Evidence: Charts", function()

    it("renders a line chart", function()
        local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Monthly Sales" })
        chart:setYMax(100)
        chart:setXMax(5)
        chart:addSeries("SALES", { {0, 20}, {1, 45}, {2, 35}, {3, 60}, {4, 80}, {5, 55} }, 0.86, 0.24, 0.24)
        chart:addSeries("COSTS", { {0, 10}, {1, 20}, {2, 25}, {3, 30}, {4, 35}, {5, 28} }, 0.24, 0.49, 0.86)
        local img = lurek.img.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.img.savePNG(img, OUT .. "line_chart.png")
        expect_equal(true, true)
    end)

    it("renders a bar chart", function()
        local chart = lurek.ui.newBarChart({ width = 400, height = 300, title = "Quarterly Revenue" })
        chart:addSeries("2023", 0.22, 0.63, 0.87)
        chart:addSeries("2024", 0.87, 0.53, 0.22)
        chart:addCategory("Q1", { 65, 80 })
        chart:addCategory("Q2", { 40, 60 })
        chart:addCategory("Q3", { 75, 90 })
        chart:addCategory("Q4", { 55, 70 })
        local img = lurek.img.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.img.savePNG(img, OUT .. "bar_chart.png")
        expect_equal(true, true)
    end)

    it("renders a scatter plot", function()
        local chart = lurek.ui.newScatterPlot({ width = 400, height = 400, title = "Data Clusters" })
        chart:setXRange(0, 10)
        chart:setYRange(0, 10)
        local pts_a = {}
        local pts_b = {}
        for i = 1, 20 do
            table.insert(pts_a, { i * 0.4 + 0.5, math.sin(i * 0.6) * 2 + 3 })
            table.insert(pts_b, { i * 0.35 + 0.2, math.cos(i * 0.5) * 2 + 7 })
        end
        chart:addSeries("Cluster A", pts_a, 0.22, 0.63, 0.87)
        chart:addSeries("Cluster B", pts_b, 0.87, 0.35, 0.22)
        local img = lurek.img.newImageData(400, 400)
        chart:drawToImage(img)
        lurek.img.savePNG(img, OUT .. "scatter_plot.png")
        expect_equal(true, true)
    end)

    it("renders a pie chart", function()
        local chart = lurek.ui.newPieChart({ width = 400, height = 400, title = "Market Share" })
        chart:addSegment("Alpha",   35, 0.22, 0.63, 0.87)
        chart:addSegment("Beta",    28, 0.87, 0.35, 0.22)
        chart:addSegment("Gamma",   20, 0.35, 0.75, 0.35)
        chart:addSegment("Delta",   17, 0.75, 0.22, 0.75)
        local img = lurek.img.newImageData(400, 400)
        chart:drawToImage(img)
        lurek.img.savePNG(img, OUT .. "pie_chart.png")
        expect_equal(true, true)
    end)

    it("renders an area chart", function()
        local chart = lurek.ui.newAreaChart({ width = 400, height = 300, title = "Stacked Area" })
        chart:setYMax(100)
        chart:addLayer("Layer A", { 20, 25, 30, 28, 32, 35, 30 }, 0.22, 0.63, 0.87)
        chart:addLayer("Layer B", { 15, 18, 22, 20, 25, 28, 24 }, 0.87, 0.35, 0.22)
        chart:addLayer("Layer C", { 10, 12, 15, 13, 18, 20, 16 }, 0.35, 0.75, 0.35)
        local img = lurek.img.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.img.savePNG(img, OUT .. "area_chart.png")
        expect_equal(true, true)
    end)

end)

test_summary()
