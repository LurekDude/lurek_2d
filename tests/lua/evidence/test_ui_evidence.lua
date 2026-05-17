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

-- @describe Evidence: lurek.ui layout loader renderToImage
describe("Evidence: lurek.ui layout loader renderToImage", function()

    -- bar) to PNG via renderToImage to prove the layout loader produces visible
    -- widget rectangles.
    -- @evidence file
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

    -- slider, and checkbox) to PNG to prove recursive child loading works
    -- end-to-end through renderToImage.
    -- @evidence file
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

-- @describe Evidence: lurek.ui layout loader renderToImage
describe("Evidence: lurek.ui layout loader renderToImage", function()

    -- bar) to PNG via renderToImage to prove the layout loader produces visible
    -- widget rectangles.
    -- @evidence file
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

    -- slider, and checkbox) to PNG to prove recursive child loading works
    -- end-to-end through renderToImage.
    -- @evidence file
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

-- @describe Evidence: Charts
describe("Evidence: Charts", function()

    -- @evidence file
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

    -- @evidence file
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

    -- @evidence file
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

    -- @evidence file
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

    -- @evidence file
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

-- @describe Evidence: Charts
describe("Evidence: Charts", function()

    -- @evidence file
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

    -- @evidence file
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

    -- @evidence file
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

    -- @evidence file
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

    -- @evidence file
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

local OUT = "tests/output/gui/"

-- @describe Evidence: lurek.ui widgets via drawToImage
describe("Evidence: lurek.ui widgets via drawToImage", function()
    -- PNG evidence ---------------------------------------------------------

    -- @evidence file
    it("PNG: button_states.png -- button and label widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 300, 80

        local b1 = lurek.ui.newButton("Normal")
        b1:setPosition(10, 10)
        b1:setSize(120, 28)
        root:addChild(b1)

        local b2 = lurek.ui.newButton("Disabled")
        b2:setPosition(160, 10)
        b2:setSize(120, 28)
        b2:setEnabled(false)
        root:addChild(b2)

        local lbl = lurek.ui.newLabel("UI button widget evidence")
        lbl:setPosition(10, 50)
        lbl:setSize(280, 20)
        root:addChild(lbl)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "button_states.png")
        expect_evidence_created(OUT .. "button_states.png")

        root:removeChild(lbl)
        root:removeChild(b2)
        root:removeChild(b1)
    end)
    -- @evidence file
    it("PNG: hud_bars.png -- progress bar widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 220, 90

        local hp = lurek.ui.newProgressBar(0, 100)
		hp:setValue(80)
        hp:setPosition(10, 10)
        hp:setSize(200, 18)
        hp:setValue(80)
        root:addChild(hp)

        local mp = lurek.ui.newProgressBar(0, 100)
        mp:setPosition(10, 36)
        mp:setSize(200, 18)
        mp:setValue(55)
        root:addChild(mp)

        local sp = lurek.ui.newProgressBar(0, 100)
        sp:setPosition(10, 62)
        sp:setSize(200, 18)
        sp:setValue(30)
        root:addChild(sp)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "hud_bars.png")
        expect_evidence_created(OUT .. "hud_bars.png")

        root:removeChild(sp)
        root:removeChild(mp)
        root:removeChild(hp)
    end)

    -- @evidence file
    it("PNG: panel_layout.png -- panel with nested button, label, slider", function()
        local root = lurek.ui.getRoot()
        local W, H = 210, 160

        local panel = lurek.ui.newPanel()
        panel:setPosition(10, 10)
        panel:setSize(190, 140)
        root:addChild(panel)

        local title = lurek.ui.newLabel("Panel Layout")
        title:setPosition(20, 20)
        title:setSize(150, 22)
        panel:addChild(title)

        local btn = lurek.ui.newButton("Action")
        btn:setPosition(20, 50)
        btn:setSize(140, 28)
        panel:addChild(btn)

        local slider = lurek.ui.newSlider(0, 100)
        slider:setPosition(20, 90)
        slider:setSize(140, 22)
        slider:setValue(60)
        panel:addChild(slider)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "panel_layout.png")
        expect_evidence_created(OUT .. "panel_layout.png")

        root:removeChild(panel)
    end)

end)



-- ================================================================
-- Merged from: test_evidence_gui.lua
-- ================================================================

-- @describe Evidence: lurek.ui widgets via drawToImage
describe("Evidence: lurek.ui widgets via drawToImage", function()
    -- PNG evidence ---------------------------------------------------------

    -- @evidence file
    it("PNG: button_states.png -- button and label widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 300, 80

        local b1 = lurek.ui.newButton("Normal")
        b1:setPosition(10, 10)
        b1:setSize(120, 28)
        root:addChild(b1)

        local b2 = lurek.ui.newButton("Disabled")
        b2:setPosition(160, 10)
        b2:setSize(120, 28)
        b2:setEnabled(false)
        root:addChild(b2)

        local lbl = lurek.ui.newLabel("UI button widget evidence")
        lbl:setPosition(10, 50)
        lbl:setSize(280, 20)
        root:addChild(lbl)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "button_states.png")
        expect_evidence_created(OUT .. "button_states.png")

        root:removeChild(lbl)
        root:removeChild(b2)
        root:removeChild(b1)
    end)
    -- @evidence file
    it("PNG: hud_bars.png -- progress bar widgets via drawToImage", function()
        local root = lurek.ui.getRoot()
        local W, H = 220, 90

        local hp = lurek.ui.newProgressBar(0, 100)
        hp:setPosition(10, 10)
        hp:setSize(200, 18)
        hp:setValue(80)
        root:addChild(hp)

        local mp = lurek.ui.newProgressBar(0, 100)
        mp:setPosition(10, 36)
        mp:setSize(200, 18)
        mp:setValue(55)
        root:addChild(mp)

        local sp = lurek.ui.newProgressBar(0, 100)
        sp:setPosition(10, 62)
        sp:setSize(200, 18)
        sp:setValue(30)
        root:addChild(sp)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "hud_bars.png")
        expect_evidence_created(OUT .. "hud_bars.png")

        root:removeChild(sp)
        root:removeChild(mp)
        root:removeChild(hp)
    end)

    -- @evidence file
    it("PNG: panel_layout.png -- panel with nested button, label, slider", function()
        local root = lurek.ui.getRoot()
        local W, H = 210, 160

        local panel = lurek.ui.newPanel()
        panel:setPosition(10, 10)
        panel:setSize(190, 140)
        root:addChild(panel)

        local title = lurek.ui.newLabel("Panel Layout")
        title:setPosition(20, 20)
        title:setSize(150, 22)
        panel:addChild(title)

        local btn = lurek.ui.newButton("Action")
        btn:setPosition(20, 50)
        btn:setSize(140, 28)
        panel:addChild(btn)

        local slider = lurek.ui.newSlider(0, 100)
        slider:setPosition(20, 90)
        slider:setSize(140, 22)
        slider:setValue(60)
        panel:addChild(slider)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "panel_layout.png")
        expect_evidence_created(OUT .. "panel_layout.png")

        root:removeChild(panel)
    end)

    -- @evidence file
    it("PNG: controls_layout.png -- complex controls panel (max 5 widgets)", function()
        lurek.ui.setDefaultTheme()
        local root = lurek.ui.getRoot()
        local W, H = 360, 220

        -- Max 5 widgets: panel + textinput + slider + progressbar + switch
        local panel = lurek.ui.newPanel()
        panel:setPosition(10, 10)
        panel:setSize(340, 200)
        root:addChild(panel)

        local ti = lurek.ui.newTextInput()
        ti:setPosition(16, 22)
        ti:setSize(220, 28)
        panel:addChild(ti)

        local slider = lurek.ui.newSlider(0, 100)
        slider:setPosition(16, 66)
        slider:setSize(300, 24)
        slider:setValue(68)
        panel:addChild(slider)

        local pb = lurek.ui.newProgressBar(0, 100)
        pb:setPosition(16, 100)
        pb:setSize(300, 20)
        pb:setValue(68)
        panel:addChild(pb)

        local sw = lurek.ui.newSwitch()
        sw:setPosition(16, 136)
        sw:setSize(76, 28)
        sw:setOn(true)
        panel:addChild(sw)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "controls_layout.png")
        expect_evidence_created(OUT .. "controls_layout.png")
        root:removeChild(panel)
    end)

    -- @evidence file
    it("PNG: selection_widgets.png -- complex selection widgets (max 5 widgets)", function()
        local root = lurek.ui.getRoot()
        local W, H = 420, 240

        -- Max 5 widgets: combobox + listbox + tabbar + scrollbar + badge
        local combo = lurek.ui.newComboBox()
        combo:addItem("Option A")
        combo:addItem("Option B")
        combo:addItem("Option C")
        combo:setSelectedIndex(1)
        combo:setPosition(12, 12)
        combo:setSize(220, 28)
        root:addChild(combo)

        local lb = lurek.ui.newList()
        lb:addItem("Resolution: 1920x1080")
        lb:addItem("VSync: On")
        lb:addItem("AA: 4x")
        lb:addItem("Shadows: High")
        lb:setSelectedIndex(2)
        lb:setPosition(12, 50)
        lb:setSize(260, 126)
        root:addChild(lb)

        local tabs = lurek.ui.newTabBar()
        tabs:addTab("Graphics")
        tabs:addTab("Audio")
        tabs:addTab("Input")
        tabs:setActiveTab(1)
        tabs:setPosition(244, 12)
        tabs:setSize(164, 30)
        root:addChild(tabs)

        local sb = lurek.ui.newScrollBar(true)
        sb:setContentSize(540)
        sb:setViewSize(126)
        sb:setPosition(278, 50)
        sb:setSize(16, 126)
        root:addChild(sb)

        local badge = lurek.ui.newBadge(12)
        badge:setPosition(380, 12)
        badge:setSize(28, 20)
        root:addChild(badge)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "selection_widgets.png")
        expect_evidence_created(OUT .. "selection_widgets.png")

        root:removeChild(badge)
        root:removeChild(sb)
        root:removeChild(tabs)
        root:removeChild(lb)
        root:removeChild(combo)
    end)
    -- @evidence file
    it("PNG: chrome_widgets.png -- complex chrome widgets (max 5 widgets)", function()
        local root = lurek.ui.getRoot()
        local W, H = 480, 320

        -- Max 5 widgets: window + dialog + statusbar + accordion + tooltip
        local win = lurek.ui.newWindow("My Window")
        win:setCloseable(true)
        win:setPosition(10, 10)
        win:setSize(220, 130)
        root:addChild(win)

        local dlg = lurek.ui.newDialog("Confirm Action")
        dlg:addButton("OK")
        dlg:addButton("Cancel")
        dlg:setPosition(240, 10)
        dlg:setSize(230, 130)
        root:addChild(dlg)

        local sbar = lurek.ui.newStatusBar()
        sbar:addSection("Ready", 140)
        sbar:addSection("row 42, col 8", 150)
        sbar:setPosition(10, 150)
        sbar:setSize(460, 20)
        root:addChild(sbar)

        local acc = lurek.ui.newAccordion()
        acc:addSection("Physics")
        acc:addSection("Rendering")
        acc:toggleSection(2)
        acc:addSection("Audio")
        acc:setPosition(10, 178)
        acc:setSize(300, 130)
        root:addChild(acc)

        local ttp = lurek.ui.newTooltipPanel("UI refresh: 16.6 ms")
        ttp:setPosition(320, 178)
        ttp:setSize(150, 44)
        root:addChild(ttp)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "chrome_widgets.png")
        expect_evidence_created(OUT .. "chrome_widgets.png")

        root:removeChild(ttp)
        root:removeChild(acc)
        root:removeChild(sbar)
        root:removeChild(dlg)
        root:removeChild(win)
    end)

    -- @evidence file
    it("PNG: data_widgets.png -- complex data widgets (max 5 widgets)", function()
        local root = lurek.ui.getRoot()
        local W, H = 480, 300

        -- Max 5 widgets: table + treeview + colorpicker + imagewidget + separator
        local tbl = lurek.ui.newTable()
        tbl:addColumn("Name", 120)
        tbl:addColumn("Value", 80)
        tbl:addColumn("Type", 80)
        tbl:addRow({"position", "3.14", "float"})
        tbl:addRow({"velocity", "1.0", "float"})
        tbl:addRow({"alive", "true", "bool"})
        tbl:setSelectedRow(1)
        tbl:setPosition(10, 10)
        tbl:setSize(290, 120)
        root:addChild(tbl)

        local tv = lurek.ui.newTreeView()
        local n1 = tv:addNode("Scene")
        local n2 = tv:addNode("Player", n1)
        tv:addNode("Camera", n1)
        tv:expandNode(n1)
        tv:setSelectedNode(n2)
        tv:setPosition(310, 10)
        tv:setSize(160, 120)
        root:addChild(tv)

        local cp = lurek.ui.newColorPicker()
        cp:setColor(0.28, 0.58, 0.92)
        cp:setPosition(10, 142)
        cp:setSize(170, 148)
        root:addChild(cp)

        local iw = lurek.ui.newImageWidget()
        iw:setPosition(190, 152)
        iw:setSize(90, 90)
        root:addChild(iw)

        local sep = lurek.ui.newSeparator(false)
        sep:setPosition(190, 248)
        sep:setSize(280, 8)
        root:addChild(sep)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "data_widgets.png")
        expect_evidence_created(OUT .. "data_widgets.png")

        root:removeChild(sep)
        root:removeChild(iw)
        root:removeChild(cp)
        root:removeChild(tv)
        root:removeChild(tbl)
    end)

    -- @evidence file
    it("PNG: toolbar_menu_tooltip.png -- complex toolbar/menu scene (max 5 widgets)", function()
        local root = lurek.ui.getRoot()
        local W, H = 480, 200

        -- Max 5 widgets: menubar + menuitem + toolbar + splitpanel + toast
        local mbar = lurek.ui.newMenuBar()
        local m1 = lurek.ui.newMenuItem("File")
        m1:setChecked(true)
        mbar:setPosition(0, 0)
        mbar:setSize(W, 24)
        mbar:addMenu(m1._idx)
        root:addChild(mbar)

        local tb = lurek.ui.newToolbar("horizontal")
        tb:addButton("new", "New file")
        tb:addButton("open", "Open")
        tb:addButton("save", "Save")
        tb:setButtonToggled("save", true)
        tb:setPosition(0, 28)
        tb:setSize(W, 32)
        root:addChild(tb)

        local split = lurek.ui.newSplitPanel("horizontal")
        split:setSplitPosition(0.62)
        split:setPosition(10, 74)
        split:setSize(460, 84)
        root:addChild(split)

        local toast = lurek.ui.newToast("Settings saved!", 3.0)
        toast:setPosition(10, 164)
        toast:setSize(300, 28)
        root:addChild(toast)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "toolbar_menu_tooltip.png")
        expect_evidence_created(OUT .. "toolbar_menu_tooltip.png")

        root:removeChild(toast)
        root:removeChild(split)
        root:removeChild(tb)
        root:removeChild(mbar)
    end)

    -- @evidence file
    it("PNG: form_missing_widgets.png -- checkbox/radio/spin/custom (max 5 widgets)", function()
        local root = lurek.ui.getRoot()
        local W, H = 360, 200

        -- Max 5 widgets: panel + checkbox + radio + spinbox + custom
        local panel = lurek.ui.newPanel()
        panel:setPosition(10, 10)
        panel:setSize(340, 180)
        root:addChild(panel)

        local cb = lurek.ui.newCheckbox("Enable shadows")
        cb:setChecked(true)
        cb:setPosition(18, 20)
        cb:setSize(170, 24)
        panel:addChild(cb)

        local rb = lurek.ui.newRadioButton("Quality High", "gfx")
        rb:setSelected(true)
        rb:setPosition(18, 54)
        rb:setSize(170, 24)
        panel:addChild(rb)

        local sb = lurek.ui.newSpinBox(0, 16)
        sb:setValue(4)
        sb:setPosition(18, 88)
        sb:setSize(130, 28)
        panel:addChild(sb)

        local custom = lurek.ui.newCustomWidget({
            x = 190,
            y = 20,
            width = 132,
            height = 96,
        })
        panel:addChild(custom)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "form_missing_widgets.png")
        expect_evidence_created(OUT .. "form_missing_widgets.png")

        root:removeChild(panel)
    end)

    -- @evidence file
    it("PNG: containers_missing_widgets.png -- layout/scroll/ninepatch/spacer/dock (max 5 widgets)", function()
        local root = lurek.ui.getRoot()
        local W, H = 520, 220

        -- Max 5 widgets: layout + scrollpanel + ninepatch + spacer + dockpanel
        local layout = lurek.ui.newLayout("horizontal")
        layout:setPosition(10, 10)
        layout:setSize(500, 200)
        root:addChild(layout)

        local scroll = lurek.ui.newScrollPanel()
        scroll:setPosition(20, 24)
        scroll:setSize(140, 160)
        root:addChild(scroll)

        local nine = lurek.ui.newNinePatch()
        nine:setPosition(174, 24)
        nine:setSize(140, 160)
        root:addChild(nine)

        local spacer = lurek.ui.newSpacer(24, 160)
        root:addChild(spacer)

        local dock = lurek.ui.newDockPanel()
        dock:setPosition(366, 24)
        dock:setSize(140, 160)
        root:addChild(dock)

        local img = lurek.ui.drawToImage(W, H)
        lurek.image.savePNG(img, OUT .. "containers_missing_widgets.png")
        expect_evidence_created(OUT .. "containers_missing_widgets.png")

        root:removeChild(dock)
        root:removeChild(spacer)
        root:removeChild(nine)
        root:removeChild(scroll)
        root:removeChild(layout)
    end)

end)
test_summary()
