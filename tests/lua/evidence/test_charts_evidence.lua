-- Evidence tests: charts module
-- Produces PNG artifacts for each chart type (line, bar, scatter, pie, area).

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
end)
test_summary()
