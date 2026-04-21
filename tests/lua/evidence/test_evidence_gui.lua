-- test_evidence_gui.lua
-- Evidence test: lurek.ui widget system rendered via drawToImage
-- Produces: button_states.png, panel_layout.png, hud_bars.png
--
-- NOTE: UI widgets are plain Lua tables (not UserData), so all method
-- calls use DOT syntax (widget.method(args)) rather than colon syntax.

local OUT = "tests/lua/evidence/output/gui/"

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
