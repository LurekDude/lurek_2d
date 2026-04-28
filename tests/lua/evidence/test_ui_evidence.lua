-- test_ui_evidence.lua
-- Canonical file. Merged from multiple sources.

-- test_evidence_ui_layout_render.lua
-- Evidence test: lurek.ui.loadLayout + lurek.ui.renderToImage
--
-- This test MUST call the layout-loader domain code to produce its output.
-- Evidence contract: if src/ui/layout_loader.rs were deleted, the PNG
-- output would NOT be produced — satisfying the litmus test.
--
-- Produces:
--   tests/output/ui_layout/simple_hud.png
--   tests/output/ui_layout/nested_panel.png

local OUT = "tests/output/ui_layout/"

-- @description Evidence tests for lurek.ui.loadLayout + renderToImage.
describe("Evidence: lurek.ui layout loader renderToImage", function()

    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.renderToImage
    -- @evidence file
    -- @description Renders a simple HUD-style layout (label + button + progress
    -- bar) to PNG via renderToImage to prove the layout loader produces visible
    -- widget rectangles.
    it("PNG: simple_hud.png -- label, button, progressbar via loadLayout", function()
        local W, H = 320, 120
        lurek.ui.loadLayout({
            type    = "panel",
            x = 0, y = 0, w = W, h = H,
            children = {
                { type = "label",       text = "HP",       x = 10,  y = 10, w = 80,  h = 24 },
                { type = "progressbar", min = 0, max = 100, value = 75,
                  x = 100, y = 10, w = 200, h = 24 },
                { type = "label",       text = "MP",       x = 10,  y = 46, w = 80,  h = 24 },
                { type = "progressbar", min = 0, max = 100, value = 40,
                  x = 100, y = 46, w = 200, h = 24 },
                { type = "button",      text = "Attack",   x = 10,  y = 82, w = 100, h = 28 },
                { type = "button",      text = "Defend",   x = 120, y = 82, w = 100, h = 28 },
            }
        })
        lurek.ui.renderToImage(W, H, OUT .. "simple_hud.png")
        expect_evidence_created(OUT .. "simple_hud.png")
    end)

    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.renderToImage
    -- @evidence file
    -- @description Renders a nested-panel layout (panel with label, slider, and checkbox),
    -- slider, and checkbox) to PNG to prove recursive child loading works
    -- end-to-end through renderToImage.
    it("PNG: nested_panel.png -- nested panel with slider and checkbox", function()
        local W, H = 280, 200
        lurek.ui.loadLayout({
            type = "panel",
            x = 0, y = 0, w = W, h = H,
            children = {
                {
                    type = "panel",
                    x = 10, y = 10, w = 260, h = 170,
                    children = {
                        { type = "label",    text = "Volume",  x = 10, y = 10, w = 80,  h = 22 },
                        { type = "slider",   min = 0, max = 100, value = 60,
                          x = 100, y = 10, w = 140, h = 22 },
                        { type = "label",    text = "Mute",    x = 10, y = 50, w = 80,  h = 22 },
                        { type = "checkbox", text = "Mute",    checked = false,
                          x = 100, y = 50, w = 100, h = 22 },
                        { type = "button",   text = "Apply",   x = 10, y = 100, w = 100, h = 30 },
                    }
                }
            }
        })
        lurek.ui.renderToImage(W, H, OUT .. "nested_panel.png")
        expect_evidence_created(OUT .. "nested_panel.png")
    end)

end)




-- ================================================================
-- Merged from: test_evidence_ui_layout_render.lua
-- ================================================================

-- test_evidence_ui_layout_render.lua
-- Evidence test: lurek.ui.loadLayout + lurek.ui.renderToImage
--
-- This test MUST call the layout-loader domain code to produce its output.
-- Evidence contract: if src/ui/layout_loader.rs were deleted, the PNG
-- output would NOT be produced — satisfying the litmus test.
--
-- Produces:
--   tests/output/ui_layout/simple_hud.png
--   tests/output/ui_layout/nested_panel.png

local OUT = "tests/output/ui_layout/"

-- @description Evidence tests for lurek.ui.loadLayout + renderToImage.
describe("Evidence: lurek.ui layout loader renderToImage", function()

    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.renderToImage
    -- @evidence file
    -- @description Renders a simple HUD-style layout (label + button + progress
    -- bar) to PNG via renderToImage to prove the layout loader produces visible
    -- widget rectangles.
    it("PNG: simple_hud.png -- label, button, progressbar via loadLayout", function()
        local W, H = 320, 120
        lurek.ui.loadLayout({
            type    = "panel",
            x = 0, y = 0, w = W, h = H,
            children = {
                { type = "label",       text = "HP",       x = 10,  y = 10, w = 80,  h = 24 },
                { type = "progressbar", min = 0, max = 100, value = 75,
                  x = 100, y = 10, w = 200, h = 24 },
                { type = "label",       text = "MP",       x = 10,  y = 46, w = 80,  h = 24 },
                { type = "progressbar", min = 0, max = 100, value = 40,
                  x = 100, y = 46, w = 200, h = 24 },
                { type = "button",      text = "Attack",   x = 10,  y = 82, w = 100, h = 28 },
                { type = "button",      text = "Defend",   x = 120, y = 82, w = 100, h = 28 },
            }
        })
        lurek.ui.renderToImage(W, H, OUT .. "simple_hud.png")
        expect_evidence_created(OUT .. "simple_hud.png")
    end)

    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.renderToImage
    -- @evidence file
    -- @description Renders a nested-panel layout (panel with label, slider, and checkbox),
    -- slider, and checkbox) to PNG to prove recursive child loading works
    -- end-to-end through renderToImage.
    it("PNG: nested_panel.png -- nested panel with slider and checkbox", function()
        local W, H = 280, 200
        lurek.ui.loadLayout({
            type = "panel",
            x = 0, y = 0, w = W, h = H,
            children = {
                {
                    type = "panel",
                    x = 10, y = 10, w = 260, h = 170,
                    children = {
                        { type = "label",    text = "Volume",  x = 10, y = 10, w = 80,  h = 22 },
                        { type = "slider",   min = 0, max = 100, value = 60,
                          x = 100, y = 10, w = 140, h = 22 },
                        { type = "label",    text = "Mute",    x = 10, y = 50, w = 80,  h = 22 },
                        { type = "checkbox", text = "Mute",    checked = false,
                          x = 100, y = 50, w = 100, h = 22 },
                        { type = "button",   text = "Apply",   x = 10, y = 100, w = 100, h = 30 },
                    }
                }
            }
        })
        lurek.ui.renderToImage(W, H, OUT .. "nested_panel.png")
        expect_evidence_created(OUT .. "nested_panel.png")
    end)

end)

-- ================================================================
-- Merged from: test_charts_evidence.lua
-- ================================================================

-- test_evidence_charts.lua
-- Evidence test: Chart rendering (line, bar, scatter, pie, area)

local OUT = "tests/output/charts/"

-- @description Covers suite: Evidence: Charts.
describe("Evidence: Charts", function()

    -- @covers lurek.ui.newLineChart
    -- @covers LineChart:setYMax
    -- @covers LineChart:setXMax
    -- @covers LineChart:addSeries
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @covers lurek.ui.newBarChart
    -- @covers lurek.ui.newScatterPlot
    -- @covers lurek.ui.newPieChart
    -- @covers lurek.ui.newAreaChart
    -- @description Builds a two-series line chart with explicit axis limits, rasterizes it into image data, and saves a PNG so the generated polyline and legend output can be inspected visually.
    it("renders a line chart", function()
        local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Monthly Sales" })
        chart:setYMax(100)
        chart:setXMax(5)
        chart:addSeries("SALES", { {0, 20}, {1, 45}, {2, 35}, {3, 60}, {4, 80}, {5, 55} }, 0.86, 0.24, 0.24)
        chart:addSeries("COSTS", { {0, 10}, {1, 20}, {2, 25}, {3, 30}, {4, 35}, {5, 28} }, 0.24, 0.49, 0.86)
        local img = lurek.image.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "line_chart.png")
    end)

    -- @covers lurek.ui.newBarChart
    -- @covers BarChart:addSeries
    -- @covers BarChart:addCategory
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Creates a grouped bar chart with two yearly series and four quarter buckets, then exports the rendered chart image to verify bar placement, category spacing, and color assignment.
    it("renders a bar chart", function()
        local chart = lurek.ui.newBarChart({ width = 400, height = 300, title = "Quarterly Revenue" })
        chart:addSeries("2023", 0.22, 0.63, 0.87)
        chart:addSeries("2024", 0.87, 0.53, 0.22)
        chart:addCategory("Q1", { 65, 80 })
        chart:addCategory("Q2", { 40, 60 })
        chart:addCategory("Q3", { 75, 90 })
        chart:addCategory("Q4", { 55, 70 })
        local img = lurek.image.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "bar_chart.png")
    end)

    -- @covers lurek.ui.newScatterPlot
    -- @covers ScatterPlot:setXRange
    -- @covers ScatterPlot:setYRange
    -- @covers ScatterPlot:addSeries
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Populates two synthetic point clusters with different trigonometric distributions, renders them as a scatter plot, and saves the image to confirm point plotting and axis scaling.
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
        local img = lurek.image.newImageData(400, 400)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "scatter_plot.png")
    end)

    -- @covers lurek.ui.newPieChart
    -- @covers PieChart:addSegment
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Assembles a pie chart from four named market-share slices and exports the render so the slice angles, ordering, and palette can be checked from file evidence.
    it("renders a pie chart", function()
        local chart = lurek.ui.newPieChart({ width = 400, height = 400, title = "Market Share" })
        chart:addSegment("Alpha",   35, 0.22, 0.63, 0.87)
        chart:addSegment("Beta",    28, 0.87, 0.35, 0.22)
        chart:addSegment("Gamma",   20, 0.35, 0.75, 0.35)
        chart:addSegment("Delta",   17, 0.75, 0.22, 0.75)
        local img = lurek.image.newImageData(400, 400)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "pie_chart.png")
    end)

    -- @covers lurek.ui.newAreaChart
    -- @covers AreaChart:setYMax
    -- @covers AreaChart:addLayer
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds a stacked area chart with three layers over seven samples, renders the composite fill output, and saves the PNG to capture layer accumulation behavior.
    it("renders an area chart", function()
        local chart = lurek.ui.newAreaChart({ width = 400, height = 300, title = "Stacked Area" })
        chart:setYMax(100)
        chart:addLayer("Layer A", { 20, 25, 30, 28, 32, 35, 30 }, 0.22, 0.63, 0.87)
        chart:addLayer("Layer B", { 15, 18, 22, 20, 25, 28, 24 }, 0.87, 0.35, 0.22)
        chart:addLayer("Layer C", { 10, 12, 15, 13, 18, 20, 16 }, 0.35, 0.75, 0.35)
        local img = lurek.image.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "area_chart.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_charts.lua
-- ================================================================

-- test_evidence_charts.lua
-- Evidence test: Chart rendering (line, bar, scatter, pie, area)

local OUT = "tests/output/charts/"

-- @description Covers suite: Evidence: Charts.
describe("Evidence: Charts", function()

    -- @covers lurek.ui.newLineChart
    -- @covers LineChart:setYMax
    -- @covers LineChart:setXMax
    -- @covers LineChart:addSeries
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @covers lurek.ui.newBarChart
    -- @covers lurek.ui.newScatterPlot
    -- @covers lurek.ui.newPieChart
    -- @covers lurek.ui.newAreaChart
    -- @description Builds a two-series line chart with explicit axis limits, rasterizes it into image data, and saves a PNG so the generated polyline and legend output can be inspected visually.
    it("renders a line chart", function()
        local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Monthly Sales" })
        chart:setYMax(100)
        chart:setXMax(5)
        chart:addSeries("SALES", { {0, 20}, {1, 45}, {2, 35}, {3, 60}, {4, 80}, {5, 55} }, 0.86, 0.24, 0.24)
        chart:addSeries("COSTS", { {0, 10}, {1, 20}, {2, 25}, {3, 30}, {4, 35}, {5, 28} }, 0.24, 0.49, 0.86)
        local img = lurek.image.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "line_chart.png")
    end)

    -- @covers lurek.ui.newBarChart
    -- @covers BarChart:addSeries
    -- @covers BarChart:addCategory
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Creates a grouped bar chart with two yearly series and four quarter buckets, then exports the rendered chart image to verify bar placement, category spacing, and color assignment.
    it("renders a bar chart", function()
        local chart = lurek.ui.newBarChart({ width = 400, height = 300, title = "Quarterly Revenue" })
        chart:addSeries("2023", 0.22, 0.63, 0.87)
        chart:addSeries("2024", 0.87, 0.53, 0.22)
        chart:addCategory("Q1", { 65, 80 })
        chart:addCategory("Q2", { 40, 60 })
        chart:addCategory("Q3", { 75, 90 })
        chart:addCategory("Q4", { 55, 70 })
        local img = lurek.image.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "bar_chart.png")
    end)

    -- @covers lurek.ui.newScatterPlot
    -- @covers ScatterPlot:setXRange
    -- @covers ScatterPlot:setYRange
    -- @covers ScatterPlot:addSeries
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Populates two synthetic point clusters with different trigonometric distributions, renders them as a scatter plot, and saves the image to confirm point plotting and axis scaling.
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
        local img = lurek.image.newImageData(400, 400)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "scatter_plot.png")
    end)

    -- @covers lurek.ui.newPieChart
    -- @covers PieChart:addSegment
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Assembles a pie chart from four named market-share slices and exports the render so the slice angles, ordering, and palette can be checked from file evidence.
    it("renders a pie chart", function()
        local chart = lurek.ui.newPieChart({ width = 400, height = 400, title = "Market Share" })
        chart:addSegment("Alpha",   35, 0.22, 0.63, 0.87)
        chart:addSegment("Beta",    28, 0.87, 0.35, 0.22)
        chart:addSegment("Gamma",   20, 0.35, 0.75, 0.35)
        chart:addSegment("Delta",   17, 0.75, 0.22, 0.75)
        local img = lurek.image.newImageData(400, 400)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "pie_chart.png")
    end)

    -- @covers lurek.ui.newAreaChart
    -- @covers AreaChart:setYMax
    -- @covers AreaChart:addLayer
    -- @covers Chart:drawToImage
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds a stacked area chart with three layers over seven samples, renders the composite fill output, and saves the PNG to capture layer accumulation behavior.
    it("renders an area chart", function()
        local chart = lurek.ui.newAreaChart({ width = 400, height = 300, title = "Stacked Area" })
        chart:setYMax(100)
        chart:addLayer("Layer A", { 20, 25, 30, 28, 32, 35, 30 }, 0.22, 0.63, 0.87)
        chart:addLayer("Layer B", { 15, 18, 22, 20, 25, 28, 24 }, 0.87, 0.35, 0.22)
        chart:addLayer("Layer C", { 10, 12, 15, 13, 18, 20, 16 }, 0.35, 0.75, 0.35)
        local img = lurek.image.newImageData(400, 300)
        chart:drawToImage(img)
        lurek.image.savePNG(img, OUT .. "area_chart.png")
    end)

end)

-- ================================================================
-- Merged from: test_gui_evidence.lua
-- ================================================================

-- test_evidence_gui.lua
-- Evidence test: lurek.ui widget system rendered via drawToImage
-- Produces: button_states.png, panel_layout.png, hud_bars.png
--
-- NOTE: UI widgets are plain Lua tables (not UserData), so all method
-- calls use DOT syntax (widget.method(args)) rather than colon syntax.

local OUT = "tests/output/gui/"

-- @description Test suite for Evidence: lurek.ui widgets via drawToImage
describe("Evidence: lurek.ui widgets via drawToImage", function()
    -- PNG evidence ---------------------------------------------------------

    -- @covers lurek.ui.drawToImage
    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newLabel
    -- @evidence file
    -- @description Renders enabled and disabled buttons with a label into one PNG to prove the widget tree rasterizes through drawToImage.
    it("PNG: button_states.png -- button and label widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 300, 80

        local b1 = lurek.ui.newButton("Normal")
        b1.setPosition(10, 10)
        b1.setSize(120, 28)
        root.addChild(b1)

        local b2 = lurek.ui.newButton("Disabled")
        b2.setPosition(160, 10)
        b2.setSize(120, 28)
        b2.setEnabled(false)
        root.addChild(b2)

        local lbl = lurek.ui.newLabel("UI button widget evidence")
        lbl.setPosition(10, 50)
        lbl.setSize(280, 20)
        root.addChild(lbl)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "button_states.png")
        expect_evidence_created(OUT .. "button_states.png")

        root.removeChild(lbl)
        root.removeChild(b2)
        root.removeChild(b1)
    end)
    -- @covers lurek.ui.drawToImage
    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.newProgressBar
    -- @evidence file
    -- @description Renders three progress bars at different fill levels to produce HUD-style bar evidence in one PNG.
    it("PNG: hud_bars.png -- progress bar widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 220, 90

        local hp = lurek.ui.newProgressBar(0, 100)
		hp.setValue(80)
        hp.setPosition(10, 10)
        hp.setSize(200, 18)
        hp.setValue(80)
        root.addChild(hp)

        local mp = lurek.ui.newProgressBar(0, 100)
        mp.setPosition(10, 36)
        mp.setSize(200, 18)
        mp.setValue(55)
        root.addChild(mp)

        local sp = lurek.ui.newProgressBar(0, 100)
        sp.setPosition(10, 62)
        sp.setSize(200, 18)
        sp.setValue(30)
        root.addChild(sp)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "hud_bars.png")
        expect_evidence_created(OUT .. "hud_bars.png")

        root.removeChild(sp)
        root.removeChild(mp)
        root.removeChild(hp)
    end)

    -- @covers lurek.ui.drawToImage
    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newLabel
    -- @covers lurek.ui.newPanel
    -- @covers lurek.ui.newSlider
    -- @evidence file
    -- @description Builds a nested panel layout with several child widget types and saves the composed UI tree as PNG evidence.
    it("PNG: panel_layout.png -- panel with nested button, label, slider", function()
        local root = lurek.ui.getRoot()
        local W, H = 210, 160

        local panel = lurek.ui.newPanel()
        panel.setPosition(10, 10)
        panel.setSize(190, 140)
        root.addChild(panel)

        local title = lurek.ui.newLabel("Panel Layout")
        title.setPosition(20, 20)
        title.setSize(150, 22)
        panel.addChild(title)

        local btn = lurek.ui.newButton("Action")
        btn.setPosition(20, 50)
        btn.setSize(140, 28)
        panel.addChild(btn)

        local slider = lurek.ui.newSlider(0, 100)
        slider.setPosition(20, 90)
        slider.setSize(140, 22)
        slider.setValue(60)
        panel.addChild(slider)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "panel_layout.png")
        expect_evidence_created(OUT .. "panel_layout.png")

        root.removeChild(panel)
    end)

end)



-- ================================================================
-- Merged from: test_evidence_gui.lua
-- ================================================================

-- test_evidence_gui.lua
-- Evidence test: lurek.ui widget system rendered via drawToImage
-- Produces: button_states.png, panel_layout.png, hud_bars.png
--
-- NOTE: UI widgets are plain Lua tables (not UserData), so all method
-- calls use DOT syntax (widget.method(args)) rather than colon syntax.

local OUT = "tests/output/gui/"

-- @description Test suite for Evidence: lurek.ui widgets via drawToImage
describe("Evidence: lurek.ui widgets via drawToImage", function()
    -- PNG evidence ---------------------------------------------------------

    -- @covers lurek.ui.drawToImage
    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newLabel
    -- @evidence file
    -- @description Renders enabled and disabled buttons with a label into one PNG to prove the widget tree rasterizes through drawToImage.
    it("PNG: button_states.png -- button and label widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 300, 80

        local b1 = lurek.ui.newButton("Normal")
        b1.setPosition(10, 10)
        b1.setSize(120, 28)
        root.addChild(b1)

        local b2 = lurek.ui.newButton("Disabled")
        b2.setPosition(160, 10)
        b2.setSize(120, 28)
        b2.setEnabled(false)
        root.addChild(b2)

        local lbl = lurek.ui.newLabel("UI button widget evidence")
        lbl.setPosition(10, 50)
        lbl.setSize(280, 20)
        root.addChild(lbl)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "button_states.png")
        expect_evidence_created(OUT .. "button_states.png")

        root.removeChild(lbl)
        root.removeChild(b2)
        root.removeChild(b1)
    end)
    -- @covers lurek.ui.drawToImage
    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.newProgressBar
    -- @evidence file
    -- @description Renders three progress bars at different fill levels to produce HUD-style bar evidence in one PNG.
    it("PNG: hud_bars.png -- progress bar widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 220, 90

        local hp = lurek.ui.newProgressBar(0, 100)
        hp.setPosition(10, 10)
        hp.setSize(200, 18)
        hp.setValue(80)
        root.addChild(hp)

        local mp = lurek.ui.newProgressBar(0, 100)
        mp.setPosition(10, 36)
        mp.setSize(200, 18)
        mp.setValue(55)
        root.addChild(mp)

        local sp = lurek.ui.newProgressBar(0, 100)
        sp.setPosition(10, 62)
        sp.setSize(200, 18)
        sp.setValue(30)
        root.addChild(sp)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "hud_bars.png")
        expect_evidence_created(OUT .. "hud_bars.png")

        root.removeChild(sp)
        root.removeChild(mp)
        root.removeChild(hp)
    end)

    -- @covers lurek.ui.drawToImage
    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newLabel
    -- @covers lurek.ui.newPanel
    -- @covers lurek.ui.newSlider
    -- @evidence file
    -- @description Builds a nested panel layout with several child widget types and saves the composed UI tree as PNG evidence.
    it("PNG: panel_layout.png -- panel with nested button, label, slider", function()
        local root = lurek.ui.getRoot()
        local W, H = 210, 160

        local panel = lurek.ui.newPanel()
        panel.setPosition(10, 10)
        panel.setSize(190, 140)
        root.addChild(panel)

        local title = lurek.ui.newLabel("Panel Layout")
        title.setPosition(20, 20)
        title.setSize(150, 22)
        panel.addChild(title)

        local btn = lurek.ui.newButton("Action")
        btn.setPosition(20, 50)
        btn.setSize(140, 28)
        panel.addChild(btn)

        local slider = lurek.ui.newSlider(0, 100)
        slider.setPosition(20, 90)
        slider.setSize(140, 22)
        slider.setValue(60)
        panel.addChild(slider)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "panel_layout.png")
        expect_evidence_created(OUT .. "panel_layout.png")

        root.removeChild(panel)
    end)

end)

test_summary()
