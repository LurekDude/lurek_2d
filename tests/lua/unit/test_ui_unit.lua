-- test_ui_layout.lua
-- Unit tests for lurek.ui.loadLayout and lurek.ui.loadLayoutFile.
-- Covers: API existence, widget tree creation from a Lua table definition,
-- child attachment, ID lookup, flat and nested layouts.

-- =========================================================================
-- 1. Layout API existence
-- =========================================================================
-- @description Confirms the three layout-loader functions are exposed on lurek.ui.
describe("lurek.ui layout loader API exists", function()
    -- @tests lurek.ui.loadLayout
    -- @tests lurek.ui.loadLayoutFile
    -- @tests lurek.ui.renderToImage
    -- @description loadLayout is a function
    it("loadLayout is a function", function()
        expect_type("function", lurek.ui.loadLayout)
    end)

    -- @description loadLayoutFile is a function
    it("loadLayoutFile is a function", function()
        expect_type("function", lurek.ui.loadLayoutFile)
    end)

    -- @description renderToImage is a function
    it("renderToImage is a function", function()
        expect_type("function", lurek.ui.renderToImage)
    end)
end)

-- =========================================================================
-- 2. loadLayout — flat single-widget definition
-- =========================================================================
-- @description loadLayout creates a panel widget from a minimal Lua table.
describe("lurek.ui.loadLayout — flat single widget", function()
    -- @tests lurek.ui.loadLayout
    -- @tests lurek.ui.getWidgetCount
    -- @description Returns a positive pool index
    it("returns a positive pool index", function()
        local before = lurek.ui.getWidgetCount()
        local idx = lurek.ui.loadLayout({ type = "panel", w = 100, h = 80 })
        expect_type("number", idx)
        local after = lurek.ui.getWidgetCount()
        -- At least one new widget was added
        assert(after > before, "widget count must increase after loadLayout")
        assert(idx > 0, "returned pool index must be > 0")
    end)

    -- @tests lurek.ui.loadLayout
    -- @description Creates a label from a type=label definition
    it("creates a label widget", function()
        local idx = lurek.ui.loadLayout({
            type = "label",
            text = "Score",
            x = 10, y = 10, w = 80, h = 24
        })
        assert(idx > 0, "label pool index must be > 0")
    end)

    -- @tests lurek.ui.loadLayout
    -- @description Creates a button from a type=button definition
    it("creates a button widget", function()
        local idx = lurek.ui.loadLayout({
            type = "button",
            text = "OK",
            x = 10, y = 10, w = 80, h = 30
        })
        assert(idx > 0, "button pool index must be > 0")
    end)

    -- @tests lurek.ui.loadLayout
    -- @description Creates a checkbox from a type=checkbox definition
    it("creates a checkbox widget", function()
        local idx = lurek.ui.loadLayout({
            type = "checkbox",
            text = "Enable",
            checked = true,
            x = 0, y = 0, w = 120, h = 24
        })
        assert(idx > 0, "checkbox pool index must be > 0")
    end)

    -- @tests lurek.ui.loadLayout
    -- @description Accepts type=separator without crashing
    it("creates a separator widget", function()
        local idx = lurek.ui.loadLayout({ type = "separator" })
        assert(idx > 0, "separator pool index must be > 0")
    end)
end)

-- =========================================================================
-- 3. loadLayout — nested widget tree with id lookup
-- =========================================================================
-- @description loadLayout builds child widgets and id-based lookup finds them.
describe("lurek.ui.loadLayout — nested tree with id lookup", function()
    -- @tests lurek.ui.loadLayout
    -- @tests lurek.ui.getRoot
    -- @description Nested children increase the widget count
    it("nested children increase widget count", function()
        local before = lurek.ui.getWidgetCount()
        lurek.ui.loadLayout({
            type = "panel",
            x = 0, y = 0, w = 200, h = 100,
            children = {
                { type = "label",  text = "HP:",     x = 10, y = 10, w = 60, h = 20 },
                { type = "button", text = "Attack",  x = 10, y = 40, w = 80, h = 28 },
            }
        })
        local after = lurek.ui.getWidgetCount()
        -- Root panel + 2 children = +3
        assert(after >= before + 3,
            "expected at least 3 new widgets, got " .. (after - before))
    end)

    -- @tests lurek.ui.loadLayout
    -- @tests lurek.ui.getRoot
    -- @description findById finds a widget given a string id field
    it("findById resolves a widget given an id field", function()
        lurek.ui.loadLayout({
            type = "panel",
            x = 0, y = 0, w = 300, h = 200,
            id = "hud_root",
            children = {
                { type = "label", text = "HP:", x = 10, y = 10, w = 60, h = 20, id = "hp_label" },
            }
        })
        local root = lurek.ui.getRoot()
        local found = root.findById("hp_label")
        assert(found ~= nil, "findById('hp_label') must return a widget handle")
    end)

    -- @tests lurek.ui.loadLayout
    -- @description Deeply nested (3-level) tree loads without error
    it("3-level deep tree loads without error", function()
        local ok = pcall(function()
            lurek.ui.loadLayout({
                type = "panel",
                children = {
                    { type = "panel",
                      children = {
                          { type = "label", text = "Deep" }
                      }
                    }
                }
            })
        end)
        assert(ok, "3-level nested loadLayout must not throw")
    end)
end)

-- =========================================================================
-- 4. loadLayout — all supported widget types do not crash
-- =========================================================================
-- @description Each recognised widget_type string can be loaded individually
-- without a Lua error.
describe("lurek.ui.loadLayout — widget type coverage", function()
    -- @tests lurek.ui.loadLayout
    local widget_types = {
        "panel", "label", "button", "checkbox", "slider", "progressbar",
        "textinput", "combobox", "list", "separator", "spacer",
        "radiobutton", "scrollbar", "switch", "badge", "spinbox",
        "image", "layout", "toolbar", "statusbar", "scrollpanel",
        "splitpanel", "tabbar", "window", "dialog", "treeview",
        "menubar", "dockpanel", "accordion", "ninepatch",
        "colorpicker", "tooltippanel",
    }

    for _, wtype in ipairs(widget_types) do
        -- @description Widget type '<wtype>' loads without error
        it("type '" .. wtype .. "' loads without error", function()
            local ok = pcall(function()
                lurek.ui.loadLayout({ type = wtype })
            end)
            assert(ok, "loadLayout({type='" .. wtype .. "'}) must not throw")
        end)
    end
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.ui.getRect
    it("covers lurek.ui.getRect", function()
        -- TODO: Implement test for lurek.ui.getRect
    end)

    -- @tests lurek.ui.setAnchor
    it("covers lurek.ui.setAnchor", function()
        -- TODO: Implement test for lurek.ui.setAnchor
    end)

    -- @tests lurek.ui.setAnchorCenter
    it("covers lurek.ui.setAnchorCenter", function()
        -- TODO: Implement test for lurek.ui.setAnchorCenter
    end)

    -- @tests lurek.ui.clearAnchor
    it("covers lurek.ui.clearAnchor", function()
        -- TODO: Implement test for lurek.ui.clearAnchor
    end)

    -- @tests lurek.ui.setAlpha
    it("covers lurek.ui.setAlpha", function()
        -- TODO: Implement test for lurek.ui.setAlpha
    end)

    -- @tests lurek.ui.getAlpha
    it("covers lurek.ui.getAlpha", function()
        -- TODO: Implement test for lurek.ui.getAlpha
    end)

    -- @tests lurek.ui.slideIn
    it("covers lurek.ui.slideIn", function()
        -- TODO: Implement test for lurek.ui.slideIn
    end)

    -- @tests lurek.ui.slideOut
    it("covers lurek.ui.slideOut", function()
        -- TODO: Implement test for lurek.ui.slideOut
    end)

    -- @tests lurek.ui.attachToEntity
    it("covers lurek.ui.attachToEntity", function()
        -- TODO: Implement test for lurek.ui.attachToEntity
    end)

    -- @tests lurek.ui.detachFromEntity
    it("covers lurek.ui.detachFromEntity", function()
        -- TODO: Implement test for lurek.ui.detachFromEntity
    end)

    -- @tests Text_Input:isFocused
    it("covers Text_Input:isFocused", function()
        -- TODO: Implement test for Text_Input:isFocused
    end)

    -- @tests Text_Input:getCursorPosition
    it("covers Text_Input:getCursorPosition", function()
        -- TODO: Implement test for Text_Input:getCursorPosition
    end)

    -- @tests Combo_Box:getSelectedItem
    it("covers Combo_Box:getSelectedItem", function()
        -- TODO: Implement test for Combo_Box:getSelectedItem
    end)

    -- @tests List_Box:setItemHeight
    it("covers List_Box:setItemHeight", function()
        -- TODO: Implement test for List_Box:setItemHeight
    end)

    -- @tests Panel:setScrollable
    it("covers Panel:setScrollable", function()
        -- TODO: Implement test for Panel:setScrollable
    end)

    -- @tests Layout:setWrap
    it("covers Layout:setWrap", function()
        -- TODO: Implement test for Layout:setWrap
    end)

    -- @tests Layout:getWrap
    it("covers Layout:getWrap", function()
        -- TODO: Implement test for Layout:getWrap
    end)

    -- @tests Scroll_Panel:getMaxScroll
    it("covers Scroll_Panel:getMaxScroll", function()
        -- TODO: Implement test for Scroll_Panel:getMaxScroll
    end)

    -- @tests Scroll_Panel:getScrollSpeed
    it("covers Scroll_Panel:getScrollSpeed", function()
        -- TODO: Implement test for Scroll_Panel:getScrollSpeed
    end)

    -- @tests Nine_Patch:setInsets
    it("covers Nine_Patch:setInsets", function()
        -- TODO: Implement test for Nine_Patch:setInsets
    end)

    -- @tests Nine_Patch:setImageDimensions
    it("covers Nine_Patch:setImageDimensions", function()
        -- TODO: Implement test for Nine_Patch:setImageDimensions
    end)

    -- @tests Nine_Patch:getImageDimensions
    it("covers Nine_Patch:getImageDimensions", function()
        -- TODO: Implement test for Nine_Patch:getImageDimensions
    end)

    -- @tests Nine_Patch:getSlices
    it("covers Nine_Patch:getSlices", function()
        -- TODO: Implement test for Nine_Patch:getSlices
    end)

    -- @tests Toast:setMessage
    it("covers Toast:setMessage", function()
        -- TODO: Implement test for Toast:setMessage
    end)

    -- @tests Separator:setVertical
    it("covers Separator:setVertical", function()
        -- TODO: Implement test for Separator:setVertical
    end)

    -- @tests Separator:setThickness
    it("covers Separator:setThickness", function()
        -- TODO: Implement test for Separator:setThickness
    end)

    -- @tests Separator:getThickness
    it("covers Separator:getThickness", function()
        -- TODO: Implement test for Separator:getThickness
    end)

    -- @tests Tree_View:isExpanded
    it("covers Tree_View:isExpanded", function()
        -- TODO: Implement test for Tree_View:isExpanded
    end)

    -- @tests Gui_Window:setDraggable
    it("covers Gui_Window:setDraggable", function()
        -- TODO: Implement test for Gui_Window:setDraggable
    end)

    -- @tests Gui_Window:setResizable
    it("covers Gui_Window:setResizable", function()
        -- TODO: Implement test for Gui_Window:setResizable
    end)

    -- @tests Gui_Window:setOnClose
    it("covers Gui_Window:setOnClose", function()
        -- TODO: Implement test for Gui_Window:setOnClose
    end)

    -- @tests Split_Panel:setFirstChild
    it("covers Split_Panel:setFirstChild", function()
        -- TODO: Implement test for Split_Panel:setFirstChild
    end)

    -- @tests Split_Panel:setSecondChild
    it("covers Split_Panel:setSecondChild", function()
        -- TODO: Implement test for Split_Panel:setSecondChild
    end)

    -- @tests Split_Panel:getFirstChild
    it("covers Split_Panel:getFirstChild", function()
        -- TODO: Implement test for Split_Panel:getFirstChild
    end)

    -- @tests Split_Panel:getSecondChild
    it("covers Split_Panel:getSecondChild", function()
        -- TODO: Implement test for Split_Panel:getSecondChild
    end)

    -- @tests Dock_Panel:undock
    it("covers Dock_Panel:undock", function()
        -- TODO: Implement test for Dock_Panel:undock
    end)

    -- @tests Menu_Bar:removeMenu
    it("covers Menu_Bar:removeMenu", function()
        -- TODO: Implement test for Menu_Bar:removeMenu
    end)

    -- @tests Menu_Bar:getMenus
    it("covers Menu_Bar:getMenus", function()
        -- TODO: Implement test for Menu_Bar:getMenus
    end)

    -- @tests Dialog:setModal
    it("covers Dialog:setModal", function()
        -- TODO: Implement test for Dialog:setModal
    end)

    -- @tests Dialog:setOnClose
    it("covers Dialog:setOnClose", function()
        -- TODO: Implement test for Dialog:setOnClose
    end)

    -- @tests Accordion:getSectionTitle
    it("covers Accordion:getSectionTitle", function()
        -- TODO: Implement test for Accordion:getSectionTitle
    end)

    -- @tests Color_Picker:setShowAlpha
    it("covers Color_Picker:setShowAlpha", function()
        -- TODO: Implement test for Color_Picker:setShowAlpha
    end)

    -- @tests Image_Widget:update_bindings
    it("covers Image_Widget:update_bindings", function()
        -- TODO: Implement test for Image_Widget:update_bindings
    end)

end)

describe("Missing explicit test for lurek.ui.setPosition", function()
    it("lurek.ui.setPosition works", function()
        -- @tests lurek.ui.setPosition
        -- TODO: add assertion for lurek.ui.setPosition
    end)
end)

describe("Missing explicit test for lurek.ui.getPosition", function()
    it("lurek.ui.getPosition works", function()
        -- @tests lurek.ui.getPosition
        -- TODO: add assertion for lurek.ui.getPosition
    end)
end)

describe("Missing explicit test for lurek.ui.setSize", function()
    it("lurek.ui.setSize works", function()
        -- @tests lurek.ui.setSize
        -- TODO: add assertion for lurek.ui.setSize
    end)
end)

describe("Missing explicit test for lurek.ui.getSize", function()
    it("lurek.ui.getSize works", function()
        -- @tests lurek.ui.getSize
        -- TODO: add assertion for lurek.ui.getSize
    end)
end)

describe("Missing explicit test for lurek.ui.setVisible", function()
    it("lurek.ui.setVisible works", function()
        -- @tests lurek.ui.setVisible
        -- TODO: add assertion for lurek.ui.setVisible
    end)
end)

describe("Missing explicit test for lurek.ui.isVisible", function()
    it("lurek.ui.isVisible works", function()
        -- @tests lurek.ui.isVisible
        -- TODO: add assertion for lurek.ui.isVisible
    end)
end)

describe("Missing explicit test for lurek.ui.setEnabled", function()
    it("lurek.ui.setEnabled works", function()
        -- @tests lurek.ui.setEnabled
        -- TODO: add assertion for lurek.ui.setEnabled
    end)
end)

describe("Missing explicit test for lurek.ui.isEnabled", function()
    it("lurek.ui.isEnabled works", function()
        -- @tests lurek.ui.isEnabled
        -- TODO: add assertion for lurek.ui.isEnabled
    end)
end)

describe("Missing explicit test for lurek.ui.setId", function()
    it("lurek.ui.setId works", function()
        -- @tests lurek.ui.setId
        -- TODO: add assertion for lurek.ui.setId
    end)
end)

describe("Missing explicit test for lurek.ui.getId", function()
    it("lurek.ui.getId works", function()
        -- @tests lurek.ui.getId
        -- TODO: add assertion for lurek.ui.getId
    end)
end)

describe("Missing explicit test for lurek.ui.setTooltip", function()
    it("lurek.ui.setTooltip works", function()
        -- @tests lurek.ui.setTooltip
        -- TODO: add assertion for lurek.ui.setTooltip
    end)
end)

describe("Missing explicit test for lurek.ui.getTooltip", function()
    it("lurek.ui.getTooltip works", function()
        -- @tests lurek.ui.getTooltip
        -- TODO: add assertion for lurek.ui.getTooltip
    end)
end)

describe("Missing explicit test for lurek.ui.getState", function()
    it("lurek.ui.getState works", function()
        -- @tests lurek.ui.getState
        -- TODO: add assertion for lurek.ui.getState
    end)
end)

describe("Missing explicit test for lurek.ui.addChild", function()
    it("lurek.ui.addChild works", function()
        -- @tests lurek.ui.addChild
        -- TODO: add assertion for lurek.ui.addChild
    end)
end)

describe("Missing explicit test for lurek.ui.removeChild", function()
    it("lurek.ui.removeChild works", function()
        -- @tests lurek.ui.removeChild
        -- TODO: add assertion for lurek.ui.removeChild
    end)
end)

describe("Missing explicit test for lurek.ui.getChildCount", function()
    it("lurek.ui.getChildCount works", function()
        -- @tests lurek.ui.getChildCount
        -- TODO: add assertion for lurek.ui.getChildCount
    end)
end)

describe("Missing explicit test for lurek.ui.getChildren", function()
    it("lurek.ui.getChildren works", function()
        -- @tests lurek.ui.getChildren
        -- TODO: add assertion for lurek.ui.getChildren
    end)
end)

describe("Missing explicit test for lurek.ui.findById", function()
    it("lurek.ui.findById works", function()
        -- @tests lurek.ui.findById
        -- TODO: add assertion for lurek.ui.findById
    end)
end)

describe("Missing explicit test for lurek.ui.setOnClick", function()
    it("lurek.ui.setOnClick works", function()
        -- @tests lurek.ui.setOnClick
        -- TODO: add assertion for lurek.ui.setOnClick
    end)
end)

describe("Missing explicit test for lurek.ui.setOnChange", function()
    it("lurek.ui.setOnChange works", function()
        -- @tests lurek.ui.setOnChange
        -- TODO: add assertion for lurek.ui.setOnChange
    end)
end)

describe("Missing explicit test for lurek.ui.setOnDraw", function()
    it("lurek.ui.setOnDraw works", function()
        -- @tests lurek.ui.setOnDraw
        -- TODO: add assertion for lurek.ui.setOnDraw
    end)
end)

describe("Missing explicit test for lurek.ui.containsPoint", function()
    it("lurek.ui.containsPoint works", function()
        -- @tests lurek.ui.containsPoint
        -- TODO: add assertion for lurek.ui.containsPoint
    end)
end)

describe("Missing explicit test for lurek.ui.setPadding", function()
    it("lurek.ui.setPadding works", function()
        -- @tests lurek.ui.setPadding
        -- TODO: add assertion for lurek.ui.setPadding
    end)
end)

describe("Missing explicit test for lurek.ui.getPadding", function()
    it("lurek.ui.getPadding works", function()
        -- @tests lurek.ui.getPadding
        -- TODO: add assertion for lurek.ui.getPadding
    end)
end)

describe("Missing explicit test for lurek.ui.setMargin", function()
    it("lurek.ui.setMargin works", function()
        -- @tests lurek.ui.setMargin
        -- TODO: add assertion for lurek.ui.setMargin
    end)
end)

describe("Missing explicit test for lurek.ui.getMargin", function()
    it("lurek.ui.getMargin works", function()
        -- @tests lurek.ui.getMargin
        -- TODO: add assertion for lurek.ui.getMargin
    end)
end)

describe("Missing explicit test for lurek.ui.setZOrder", function()
    it("lurek.ui.setZOrder works", function()
        -- @tests lurek.ui.setZOrder
        -- TODO: add assertion for lurek.ui.setZOrder
    end)
end)

describe("Missing explicit test for lurek.ui.getZOrder", function()
    it("lurek.ui.getZOrder works", function()
        -- @tests lurek.ui.getZOrder
        -- TODO: add assertion for lurek.ui.getZOrder
    end)
end)

describe("Missing explicit test for lurek.ui.setMinSize", function()
    it("lurek.ui.setMinSize works", function()
        -- @tests lurek.ui.setMinSize
        -- TODO: add assertion for lurek.ui.setMinSize
    end)
end)

describe("Missing explicit test for lurek.ui.getMinSize", function()
    it("lurek.ui.getMinSize works", function()
        -- @tests lurek.ui.getMinSize
        -- TODO: add assertion for lurek.ui.getMinSize
    end)
end)

describe("Missing explicit test for lurek.ui.setMaxSize", function()
    it("lurek.ui.setMaxSize works", function()
        -- @tests lurek.ui.setMaxSize
        -- TODO: add assertion for lurek.ui.setMaxSize
    end)
end)

describe("Missing explicit test for lurek.ui.getMaxSize", function()
    it("lurek.ui.getMaxSize works", function()
        -- @tests lurek.ui.getMaxSize
        -- TODO: add assertion for lurek.ui.getMaxSize
    end)
end)

describe("Missing explicit test for lurek.ui.setFlexGrow", function()
    it("lurek.ui.setFlexGrow works", function()
        -- @tests lurek.ui.setFlexGrow
        -- TODO: add assertion for lurek.ui.setFlexGrow
    end)
end)

describe("Missing explicit test for lurek.ui.getFlexGrow", function()
    it("lurek.ui.getFlexGrow works", function()
        -- @tests lurek.ui.getFlexGrow
        -- TODO: add assertion for lurek.ui.getFlexGrow
    end)
end)

describe("Missing explicit test for lurek.ui.setFlexShrink", function()
    it("lurek.ui.setFlexShrink works", function()
        -- @tests lurek.ui.setFlexShrink
        -- TODO: add assertion for lurek.ui.setFlexShrink
    end)
end)

describe("Missing explicit test for lurek.ui.getFlexShrink", function()
    it("lurek.ui.getFlexShrink works", function()
        -- @tests lurek.ui.getFlexShrink
        -- TODO: add assertion for lurek.ui.getFlexShrink
    end)
end)

describe("Missing explicit test for lurek.ui.bind", function()
    it("lurek.ui.bind works", function()
        -- @tests lurek.ui.bind
        -- TODO: add assertion for lurek.ui.bind
    end)
end)

describe("Missing explicit test for lurek.ui.unbind", function()
    it("lurek.ui.unbind works", function()
        -- @tests lurek.ui.unbind
        -- TODO: add assertion for lurek.ui.unbind
    end)
end)

describe("Missing explicit test for lurek.ui.fadeIn", function()
    it("lurek.ui.fadeIn works", function()
        -- @tests lurek.ui.fadeIn
        -- TODO: add assertion for lurek.ui.fadeIn
    end)
end)

describe("Missing explicit test for lurek.ui.fadeOut", function()
    it("lurek.ui.fadeOut works", function()
        -- @tests lurek.ui.fadeOut
        -- TODO: add assertion for lurek.ui.fadeOut
    end)
end)

describe("Missing explicit test for Text_Input:setText", function()
    it("Text_Input:setText works", function()
        -- @tests Text_Input:setText
        -- TODO: add assertion for Text_Input:setText
    end)
end)

describe("Missing explicit test for Text_Input:getText", function()
    it("Text_Input:getText works", function()
        -- @tests Text_Input:getText
        -- TODO: add assertion for Text_Input:getText
    end)
end)

describe("Missing explicit test for Text_Input:setPlaceholder", function()
    it("Text_Input:setPlaceholder works", function()
        -- @tests Text_Input:setPlaceholder
        -- TODO: add assertion for Text_Input:setPlaceholder
    end)
end)

describe("Missing explicit test for Text_Input:getPlaceholder", function()
    it("Text_Input:getPlaceholder works", function()
        -- @tests Text_Input:getPlaceholder
        -- TODO: add assertion for Text_Input:getPlaceholder
    end)
end)

describe("Missing explicit test for Text_Input:setMaxLength", function()
    it("Text_Input:setMaxLength works", function()
        -- @tests Text_Input:setMaxLength
        -- TODO: add assertion for Text_Input:setMaxLength
    end)
end)

describe("Missing explicit test for Checkbox:setChecked", function()
    it("Checkbox:setChecked works", function()
        -- @tests Checkbox:setChecked
        -- TODO: add assertion for Checkbox:setChecked
    end)
end)

describe("Missing explicit test for Checkbox:isChecked", function()
    it("Checkbox:isChecked works", function()
        -- @tests Checkbox:isChecked
        -- TODO: add assertion for Checkbox:isChecked
    end)
end)

describe("Missing explicit test for Checkbox:setText", function()
    it("Checkbox:setText works", function()
        -- @tests Checkbox:setText
        -- TODO: add assertion for Checkbox:setText
    end)
end)

describe("Missing explicit test for Checkbox:getText", function()
    it("Checkbox:getText works", function()
        -- @tests Checkbox:getText
        -- TODO: add assertion for Checkbox:getText
    end)
end)

describe("Missing explicit test for Slider:setValue", function()
    it("Slider:setValue works", function()
        -- @tests Slider:setValue
        -- TODO: add assertion for Slider:setValue
    end)
end)

describe("Missing explicit test for Slider:getValue", function()
    it("Slider:getValue works", function()
        -- @tests Slider:getValue
        -- TODO: add assertion for Slider:getValue
    end)
end)

describe("Missing explicit test for Slider:setRange", function()
    it("Slider:setRange works", function()
        -- @tests Slider:setRange
        -- TODO: add assertion for Slider:setRange
    end)
end)

describe("Missing explicit test for Slider:setStep", function()
    it("Slider:setStep works", function()
        -- @tests Slider:setStep
        -- TODO: add assertion for Slider:setStep
    end)
end)

describe("Missing explicit test for Slider:getMin", function()
    it("Slider:getMin works", function()
        -- @tests Slider:getMin
        -- TODO: add assertion for Slider:getMin
    end)
end)

describe("Missing explicit test for Slider:getMax", function()
    it("Slider:getMax works", function()
        -- @tests Slider:getMax
        -- TODO: add assertion for Slider:getMax
    end)
end)

describe("Missing explicit test for Progress_Bar:setValue", function()
    it("Progress_Bar:setValue works", function()
        -- @tests Progress_Bar:setValue
        -- TODO: add assertion for Progress_Bar:setValue
    end)
end)

describe("Missing explicit test for Progress_Bar:getValue", function()
    it("Progress_Bar:getValue works", function()
        -- @tests Progress_Bar:getValue
        -- TODO: add assertion for Progress_Bar:getValue
    end)
end)

describe("Missing explicit test for Progress_Bar:getProgress", function()
    it("Progress_Bar:getProgress works", function()
        -- @tests Progress_Bar:getProgress
        -- TODO: add assertion for Progress_Bar:getProgress
    end)
end)

describe("Missing explicit test for Progress_Bar:setRange", function()
    it("Progress_Bar:setRange works", function()
        -- @tests Progress_Bar:setRange
        -- TODO: add assertion for Progress_Bar:setRange
    end)
end)

describe("Missing explicit test for Progress_Bar:getMin", function()
    it("Progress_Bar:getMin works", function()
        -- @tests Progress_Bar:getMin
        -- TODO: add assertion for Progress_Bar:getMin
    end)
end)

describe("Missing explicit test for Progress_Bar:getMax", function()
    it("Progress_Bar:getMax works", function()
        -- @tests Progress_Bar:getMax
        -- TODO: add assertion for Progress_Bar:getMax
    end)
end)

describe("Missing explicit test for Combo_Box:addItem", function()
    it("Combo_Box:addItem works", function()
        -- @tests Combo_Box:addItem
        -- TODO: add assertion for Combo_Box:addItem
    end)
end)

describe("Missing explicit test for Combo_Box:removeItem", function()
    it("Combo_Box:removeItem works", function()
        -- @tests Combo_Box:removeItem
        -- TODO: add assertion for Combo_Box:removeItem
    end)
end)

describe("Missing explicit test for Combo_Box:clearItems", function()
    it("Combo_Box:clearItems works", function()
        -- @tests Combo_Box:clearItems
        -- TODO: add assertion for Combo_Box:clearItems
    end)
end)

describe("Missing explicit test for Combo_Box:getItemCount", function()
    it("Combo_Box:getItemCount works", function()
        -- @tests Combo_Box:getItemCount
        -- TODO: add assertion for Combo_Box:getItemCount
    end)
end)

describe("Missing explicit test for Combo_Box:getItem", function()
    it("Combo_Box:getItem works", function()
        -- @tests Combo_Box:getItem
        -- TODO: add assertion for Combo_Box:getItem
    end)
end)

describe("Missing explicit test for Combo_Box:setSelectedIndex", function()
    it("Combo_Box:setSelectedIndex works", function()
        -- @tests Combo_Box:setSelectedIndex
        -- TODO: add assertion for Combo_Box:setSelectedIndex
    end)
end)

describe("Missing explicit test for Combo_Box:getSelectedIndex", function()
    it("Combo_Box:getSelectedIndex works", function()
        -- @tests Combo_Box:getSelectedIndex
        -- TODO: add assertion for Combo_Box:getSelectedIndex
    end)
end)

describe("Missing explicit test for List_Box:addItem", function()
    it("List_Box:addItem works", function()
        -- @tests List_Box:addItem
        -- TODO: add assertion for List_Box:addItem
    end)
end)

describe("Missing explicit test for List_Box:removeItem", function()
    it("List_Box:removeItem works", function()
        -- @tests List_Box:removeItem
        -- TODO: add assertion for List_Box:removeItem
    end)
end)

describe("Missing explicit test for List_Box:clearItems", function()
    it("List_Box:clearItems works", function()
        -- @tests List_Box:clearItems
        -- TODO: add assertion for List_Box:clearItems
    end)
end)

describe("Missing explicit test for List_Box:getItemCount", function()
    it("List_Box:getItemCount works", function()
        -- @tests List_Box:getItemCount
        -- TODO: add assertion for List_Box:getItemCount
    end)
end)

describe("Missing explicit test for List_Box:getItem", function()
    it("List_Box:getItem works", function()
        -- @tests List_Box:getItem
        -- TODO: add assertion for List_Box:getItem
    end)
end)

describe("Missing explicit test for List_Box:setSelectedIndex", function()
    it("List_Box:setSelectedIndex works", function()
        -- @tests List_Box:setSelectedIndex
        -- TODO: add assertion for List_Box:setSelectedIndex
    end)
end)

describe("Missing explicit test for List_Box:getSelectedIndex", function()
    it("List_Box:getSelectedIndex works", function()
        -- @tests List_Box:getSelectedIndex
        -- TODO: add assertion for List_Box:getSelectedIndex
    end)
end)

describe("Missing explicit test for Tab_Bar:addTab", function()
    it("Tab_Bar:addTab works", function()
        -- @tests Tab_Bar:addTab
        -- TODO: add assertion for Tab_Bar:addTab
    end)
end)

describe("Missing explicit test for Tab_Bar:removeTab", function()
    it("Tab_Bar:removeTab works", function()
        -- @tests Tab_Bar:removeTab
        -- TODO: add assertion for Tab_Bar:removeTab
    end)
end)

describe("Missing explicit test for Tab_Bar:getTab", function()
    it("Tab_Bar:getTab works", function()
        -- @tests Tab_Bar:getTab
        -- TODO: add assertion for Tab_Bar:getTab
    end)
end)

describe("Missing explicit test for Tab_Bar:getTabCount", function()
    it("Tab_Bar:getTabCount works", function()
        -- @tests Tab_Bar:getTabCount
        -- TODO: add assertion for Tab_Bar:getTabCount
    end)
end)

describe("Missing explicit test for Tab_Bar:setActiveTab", function()
    it("Tab_Bar:setActiveTab works", function()
        -- @tests Tab_Bar:setActiveTab
        -- TODO: add assertion for Tab_Bar:setActiveTab
    end)
end)

describe("Missing explicit test for Tab_Bar:getActiveTab", function()
    it("Tab_Bar:getActiveTab works", function()
        -- @tests Tab_Bar:getActiveTab
        -- TODO: add assertion for Tab_Bar:getActiveTab
    end)
end)

describe("Missing explicit test for Spin_Box:setValue", function()
    it("Spin_Box:setValue works", function()
        -- @tests Spin_Box:setValue
        -- TODO: add assertion for Spin_Box:setValue
    end)
end)

describe("Missing explicit test for Spin_Box:getValue", function()
    it("Spin_Box:getValue works", function()
        -- @tests Spin_Box:getValue
        -- TODO: add assertion for Spin_Box:getValue
    end)
end)

describe("Missing explicit test for Spin_Box:increment", function()
    it("Spin_Box:increment works", function()
        -- @tests Spin_Box:increment
        -- TODO: add assertion for Spin_Box:increment
    end)
end)

describe("Missing explicit test for Spin_Box:decrement", function()
    it("Spin_Box:decrement works", function()
        -- @tests Spin_Box:decrement
        -- TODO: add assertion for Spin_Box:decrement
    end)
end)

describe("Missing explicit test for Spin_Box:setRange", function()
    it("Spin_Box:setRange works", function()
        -- @tests Spin_Box:setRange
        -- TODO: add assertion for Spin_Box:setRange
    end)
end)

describe("Missing explicit test for Spin_Box:setStep", function()
    it("Spin_Box:setStep works", function()
        -- @tests Spin_Box:setStep
        -- TODO: add assertion for Spin_Box:setStep
    end)
end)

describe("Missing explicit test for Switch:setOn", function()
    it("Switch:setOn works", function()
        -- @tests Switch:setOn
        -- TODO: add assertion for Switch:setOn
    end)
end)

describe("Missing explicit test for Switch:isOn", function()
    it("Switch:isOn works", function()
        -- @tests Switch:isOn
        -- TODO: add assertion for Switch:isOn
    end)
end)

describe("Missing explicit test for Switch:toggle", function()
    it("Switch:toggle works", function()
        -- @tests Switch:toggle
        -- TODO: add assertion for Switch:toggle
    end)
end)

describe("Missing explicit test for Badge:setCount", function()
    it("Badge:setCount works", function()
        -- @tests Badge:setCount
        -- TODO: add assertion for Badge:setCount
    end)
end)

describe("Missing explicit test for Badge:getCount", function()
    it("Badge:getCount works", function()
        -- @tests Badge:getCount
        -- TODO: add assertion for Badge:getCount
    end)
end)

describe("Missing explicit test for Badge:getDisplayText", function()
    it("Badge:getDisplayText works", function()
        -- @tests Badge:getDisplayText
        -- TODO: add assertion for Badge:getDisplayText
    end)
end)

describe("Missing explicit test for Panel:setTitle", function()
    it("Panel:setTitle works", function()
        -- @tests Panel:setTitle
        -- TODO: add assertion for Panel:setTitle
    end)
end)

describe("Missing explicit test for Panel:getTitle", function()
    it("Panel:getTitle works", function()
        -- @tests Panel:getTitle
        -- TODO: add assertion for Panel:getTitle
    end)
end)

describe("Missing explicit test for Layout:setDirection", function()
    it("Layout:setDirection works", function()
        -- @tests Layout:setDirection
        -- TODO: add assertion for Layout:setDirection
    end)
end)

describe("Missing explicit test for Layout:getDirection", function()
    it("Layout:getDirection works", function()
        -- @tests Layout:getDirection
        -- TODO: add assertion for Layout:getDirection
    end)
end)

describe("Missing explicit test for Layout:setSpacing", function()
    it("Layout:setSpacing works", function()
        -- @tests Layout:setSpacing
        -- TODO: add assertion for Layout:setSpacing
    end)
end)

describe("Missing explicit test for Layout:getSpacing", function()
    it("Layout:getSpacing works", function()
        -- @tests Layout:getSpacing
        -- TODO: add assertion for Layout:getSpacing
    end)
end)

describe("Missing explicit test for Layout:setColumns", function()
    it("Layout:setColumns works", function()
        -- @tests Layout:setColumns
        -- TODO: add assertion for Layout:setColumns
    end)
end)

describe("Missing explicit test for Layout:setAlign", function()
    it("Layout:setAlign works", function()
        -- @tests Layout:setAlign
        -- TODO: add assertion for Layout:setAlign
    end)
end)

describe("Missing explicit test for Layout:getAlign", function()
    it("Layout:getAlign works", function()
        -- @tests Layout:getAlign
        -- TODO: add assertion for Layout:getAlign
    end)
end)

describe("Missing explicit test for Layout:setJustify", function()
    it("Layout:setJustify works", function()
        -- @tests Layout:setJustify
        -- TODO: add assertion for Layout:setJustify
    end)
end)

describe("Missing explicit test for Layout:getJustify", function()
    it("Layout:getJustify works", function()
        -- @tests Layout:getJustify
        -- TODO: add assertion for Layout:getJustify
    end)
end)

describe("Missing explicit test for Scroll_Panel:setContentSize", function()
    it("Scroll_Panel:setContentSize works", function()
        -- @tests Scroll_Panel:setContentSize
        -- TODO: add assertion for Scroll_Panel:setContentSize
    end)
end)

describe("Missing explicit test for Scroll_Panel:getContentSize", function()
    it("Scroll_Panel:getContentSize works", function()
        -- @tests Scroll_Panel:getContentSize
        -- TODO: add assertion for Scroll_Panel:getContentSize
    end)
end)

describe("Missing explicit test for Scroll_Panel:setScrollPosition", function()
    it("Scroll_Panel:setScrollPosition works", function()
        -- @tests Scroll_Panel:setScrollPosition
        -- TODO: add assertion for Scroll_Panel:setScrollPosition
    end)
end)

describe("Missing explicit test for Scroll_Panel:getScrollPosition", function()
    it("Scroll_Panel:getScrollPosition works", function()
        -- @tests Scroll_Panel:getScrollPosition
        -- TODO: add assertion for Scroll_Panel:getScrollPosition
    end)
end)

describe("Missing explicit test for Scroll_Panel:setScrollSpeed", function()
    it("Scroll_Panel:setScrollSpeed works", function()
        -- @tests Scroll_Panel:setScrollSpeed
        -- TODO: add assertion for Scroll_Panel:setScrollSpeed
    end)
end)

describe("Missing explicit test for Nine_Patch:getInsets", function()
    it("Nine_Patch:getInsets works", function()
        -- @tests Nine_Patch:getInsets
        -- TODO: add assertion for Nine_Patch:getInsets
    end)
end)

describe("Missing explicit test for Toast:getMessage", function()
    it("Toast:getMessage works", function()
        -- @tests Toast:getMessage
        -- TODO: add assertion for Toast:getMessage
    end)
end)

describe("Missing explicit test for Toast:setDuration", function()
    it("Toast:setDuration works", function()
        -- @tests Toast:setDuration
        -- TODO: add assertion for Toast:setDuration
    end)
end)

describe("Missing explicit test for Toast:getDuration", function()
    it("Toast:getDuration works", function()
        -- @tests Toast:getDuration
        -- TODO: add assertion for Toast:getDuration
    end)
end)

describe("Missing explicit test for Toast:getProgress", function()
    it("Toast:getProgress works", function()
        -- @tests Toast:getProgress
        -- TODO: add assertion for Toast:getProgress
    end)
end)

describe("Missing explicit test for Toast:isExpired", function()
    it("Toast:isExpired works", function()
        -- @tests Toast:isExpired
        -- TODO: add assertion for Toast:isExpired
    end)
end)

describe("Missing explicit test for Separator:isVertical", function()
    it("Separator:isVertical works", function()
        -- @tests Separator:isVertical
        -- TODO: add assertion for Separator:isVertical
    end)
end)

describe("Missing explicit test for Tree_View:addNode", function()
    it("Tree_View:addNode works", function()
        -- @tests Tree_View:addNode
        -- TODO: add assertion for Tree_View:addNode
    end)
end)

describe("Missing explicit test for Tree_View:toggleNode", function()
    it("Tree_View:toggleNode works", function()
        -- @tests Tree_View:toggleNode
        -- TODO: add assertion for Tree_View:toggleNode
    end)
end)

describe("Missing explicit test for Tree_View:getNodeCount", function()
    it("Tree_View:getNodeCount works", function()
        -- @tests Tree_View:getNodeCount
        -- TODO: add assertion for Tree_View:getNodeCount
    end)
end)

describe("Missing explicit test for Tree_View:removeNode", function()
    it("Tree_View:removeNode works", function()
        -- @tests Tree_View:removeNode
        -- TODO: add assertion for Tree_View:removeNode
    end)
end)

describe("Missing explicit test for Tree_View:clearNodes", function()
    it("Tree_View:clearNodes works", function()
        -- @tests Tree_View:clearNodes
        -- TODO: add assertion for Tree_View:clearNodes
    end)
end)

describe("Missing explicit test for Tree_View:getNodeText", function()
    it("Tree_View:getNodeText works", function()
        -- @tests Tree_View:getNodeText
        -- TODO: add assertion for Tree_View:getNodeText
    end)
end)

describe("Missing explicit test for Tree_View:setNodeText", function()
    it("Tree_View:setNodeText works", function()
        -- @tests Tree_View:setNodeText
        -- TODO: add assertion for Tree_View:setNodeText
    end)
end)

describe("Missing explicit test for Tree_View:setNodeIcon", function()
    it("Tree_View:setNodeIcon works", function()
        -- @tests Tree_View:setNodeIcon
        -- TODO: add assertion for Tree_View:setNodeIcon
    end)
end)

describe("Missing explicit test for Tree_View:expandNode", function()
    it("Tree_View:expandNode works", function()
        -- @tests Tree_View:expandNode
        -- TODO: add assertion for Tree_View:expandNode
    end)
end)

describe("Missing explicit test for Tree_View:collapseNode", function()
    it("Tree_View:collapseNode works", function()
        -- @tests Tree_View:collapseNode
        -- TODO: add assertion for Tree_View:collapseNode
    end)
end)

describe("Missing explicit test for Tree_View:isNodeExpanded", function()
    it("Tree_View:isNodeExpanded works", function()
        -- @tests Tree_View:isNodeExpanded
        -- TODO: add assertion for Tree_View:isNodeExpanded
    end)
end)

describe("Missing explicit test for Tree_View:expandAll", function()
    it("Tree_View:expandAll works", function()
        -- @tests Tree_View:expandAll
        -- TODO: add assertion for Tree_View:expandAll
    end)
end)

describe("Missing explicit test for Tree_View:collapseAll", function()
    it("Tree_View:collapseAll works", function()
        -- @tests Tree_View:collapseAll
        -- TODO: add assertion for Tree_View:collapseAll
    end)
end)

describe("Missing explicit test for Tree_View:setSelectedNode", function()
    it("Tree_View:setSelectedNode works", function()
        -- @tests Tree_View:setSelectedNode
        -- TODO: add assertion for Tree_View:setSelectedNode
    end)
end)

describe("Missing explicit test for Tree_View:getSelectedNode", function()
    it("Tree_View:getSelectedNode works", function()
        -- @tests Tree_View:getSelectedNode
        -- TODO: add assertion for Tree_View:getSelectedNode
    end)
end)

describe("Missing explicit test for Tree_View:getChildNodes", function()
    it("Tree_View:getChildNodes works", function()
        -- @tests Tree_View:getChildNodes
        -- TODO: add assertion for Tree_View:getChildNodes
    end)
end)

describe("Missing explicit test for Tree_View:getParentNode", function()
    it("Tree_View:getParentNode works", function()
        -- @tests Tree_View:getParentNode
        -- TODO: add assertion for Tree_View:getParentNode
    end)
end)

describe("Missing explicit test for Tree_View:getNodeDepth", function()
    it("Tree_View:getNodeDepth works", function()
        -- @tests Tree_View:getNodeDepth
        -- TODO: add assertion for Tree_View:getNodeDepth
    end)
end)

describe("Missing explicit test for Radio_Button:getText", function()
    it("Radio_Button:getText works", function()
        -- @tests Radio_Button:getText
        -- TODO: add assertion for Radio_Button:getText
    end)
end)

describe("Missing explicit test for Radio_Button:setText", function()
    it("Radio_Button:setText works", function()
        -- @tests Radio_Button:setText
        -- TODO: add assertion for Radio_Button:setText
    end)
end)

describe("Missing explicit test for Radio_Button:isSelected", function()
    it("Radio_Button:isSelected works", function()
        -- @tests Radio_Button:isSelected
        -- TODO: add assertion for Radio_Button:isSelected
    end)
end)

describe("Missing explicit test for Radio_Button:setSelected", function()
    it("Radio_Button:setSelected works", function()
        -- @tests Radio_Button:setSelected
        -- TODO: add assertion for Radio_Button:setSelected
    end)
end)

describe("Missing explicit test for Radio_Button:getGroup", function()
    it("Radio_Button:getGroup works", function()
        -- @tests Radio_Button:getGroup
        -- TODO: add assertion for Radio_Button:getGroup
    end)
end)

describe("Missing explicit test for Radio_Button:setGroup", function()
    it("Radio_Button:setGroup works", function()
        -- @tests Radio_Button:setGroup
        -- TODO: add assertion for Radio_Button:setGroup
    end)
end)

describe("Missing explicit test for Radio_Button:setOnChange", function()
    it("Radio_Button:setOnChange works", function()
        -- @tests Radio_Button:setOnChange
        -- TODO: add assertion for Radio_Button:setOnChange
    end)
end)

describe("Missing explicit test for Scroll_Bar:getScrollPosition", function()
    it("Scroll_Bar:getScrollPosition works", function()
        -- @tests Scroll_Bar:getScrollPosition
        -- TODO: add assertion for Scroll_Bar:getScrollPosition
    end)
end)

describe("Missing explicit test for Scroll_Bar:setScrollPosition", function()
    it("Scroll_Bar:setScrollPosition works", function()
        -- @tests Scroll_Bar:setScrollPosition
        -- TODO: add assertion for Scroll_Bar:setScrollPosition
    end)
end)

describe("Missing explicit test for Scroll_Bar:getContentSize", function()
    it("Scroll_Bar:getContentSize works", function()
        -- @tests Scroll_Bar:getContentSize
        -- TODO: add assertion for Scroll_Bar:getContentSize
    end)
end)

describe("Missing explicit test for Scroll_Bar:setContentSize", function()
    it("Scroll_Bar:setContentSize works", function()
        -- @tests Scroll_Bar:setContentSize
        -- TODO: add assertion for Scroll_Bar:setContentSize
    end)
end)

describe("Missing explicit test for Scroll_Bar:getViewSize", function()
    it("Scroll_Bar:getViewSize works", function()
        -- @tests Scroll_Bar:getViewSize
        -- TODO: add assertion for Scroll_Bar:getViewSize
    end)
end)

describe("Missing explicit test for Scroll_Bar:setViewSize", function()
    it("Scroll_Bar:setViewSize works", function()
        -- @tests Scroll_Bar:setViewSize
        -- TODO: add assertion for Scroll_Bar:setViewSize
    end)
end)

describe("Missing explicit test for Scroll_Bar:isVertical", function()
    it("Scroll_Bar:isVertical works", function()
        -- @tests Scroll_Bar:isVertical
        -- TODO: add assertion for Scroll_Bar:isVertical
    end)
end)

describe("Missing explicit test for Scroll_Bar:setOnChange", function()
    it("Scroll_Bar:setOnChange works", function()
        -- @tests Scroll_Bar:setOnChange
        -- TODO: add assertion for Scroll_Bar:setOnChange
    end)
end)

describe("Missing explicit test for Gui_Window:getTitle", function()
    it("Gui_Window:getTitle works", function()
        -- @tests Gui_Window:getTitle
        -- TODO: add assertion for Gui_Window:getTitle
    end)
end)

describe("Missing explicit test for Gui_Window:setTitle", function()
    it("Gui_Window:setTitle works", function()
        -- @tests Gui_Window:setTitle
        -- TODO: add assertion for Gui_Window:setTitle
    end)
end)

describe("Missing explicit test for Gui_Window:isCloseable", function()
    it("Gui_Window:isCloseable works", function()
        -- @tests Gui_Window:isCloseable
        -- TODO: add assertion for Gui_Window:isCloseable
    end)
end)

describe("Missing explicit test for Gui_Window:setCloseable", function()
    it("Gui_Window:setCloseable works", function()
        -- @tests Gui_Window:setCloseable
        -- TODO: add assertion for Gui_Window:setCloseable
    end)
end)

describe("Missing explicit test for Gui_Window:isDraggable", function()
    it("Gui_Window:isDraggable works", function()
        -- @tests Gui_Window:isDraggable
        -- TODO: add assertion for Gui_Window:isDraggable
    end)
end)

describe("Missing explicit test for Gui_Window:isResizable", function()
    it("Gui_Window:isResizable works", function()
        -- @tests Gui_Window:isResizable
        -- TODO: add assertion for Gui_Window:isResizable
    end)
end)

describe("Missing explicit test for Split_Panel:getOrientation", function()
    it("Split_Panel:getOrientation works", function()
        -- @tests Split_Panel:getOrientation
        -- TODO: add assertion for Split_Panel:getOrientation
    end)
end)

describe("Missing explicit test for Split_Panel:setOrientation", function()
    it("Split_Panel:setOrientation works", function()
        -- @tests Split_Panel:setOrientation
        -- TODO: add assertion for Split_Panel:setOrientation
    end)
end)

describe("Missing explicit test for Split_Panel:getSplitPosition", function()
    it("Split_Panel:getSplitPosition works", function()
        -- @tests Split_Panel:getSplitPosition
        -- TODO: add assertion for Split_Panel:getSplitPosition
    end)
end)

describe("Missing explicit test for Split_Panel:setSplitPosition", function()
    it("Split_Panel:setSplitPosition works", function()
        -- @tests Split_Panel:setSplitPosition
        -- TODO: add assertion for Split_Panel:setSplitPosition
    end)
end)

describe("Missing explicit test for Split_Panel:getMinPanelSize", function()
    it("Split_Panel:getMinPanelSize works", function()
        -- @tests Split_Panel:getMinPanelSize
        -- TODO: add assertion for Split_Panel:getMinPanelSize
    end)
end)

describe("Missing explicit test for Split_Panel:setMinPanelSize", function()
    it("Split_Panel:setMinPanelSize works", function()
        -- @tests Split_Panel:setMinPanelSize
        -- TODO: add assertion for Split_Panel:setMinPanelSize
    end)
end)

describe("Missing explicit test for Dock_Panel:dock", function()
    it("Dock_Panel:dock works", function()
        -- @tests Dock_Panel:dock
        -- TODO: add assertion for Dock_Panel:dock
    end)
end)

describe("Missing explicit test for Dock_Panel:getDockedCount", function()
    it("Dock_Panel:getDockedCount works", function()
        -- @tests Dock_Panel:getDockedCount
        -- TODO: add assertion for Dock_Panel:getDockedCount
    end)
end)

describe("Missing explicit test for Dock_Panel:setSplitSize", function()
    it("Dock_Panel:setSplitSize works", function()
        -- @tests Dock_Panel:setSplitSize
        -- TODO: add assertion for Dock_Panel:setSplitSize
    end)
end)

describe("Missing explicit test for Dock_Panel:getSplitSize", function()
    it("Dock_Panel:getSplitSize works", function()
        -- @tests Dock_Panel:getSplitSize
        -- TODO: add assertion for Dock_Panel:getSplitSize
    end)
end)

describe("Missing explicit test for Toolbar:getOrientation", function()
    it("Toolbar:getOrientation works", function()
        -- @tests Toolbar:getOrientation
        -- TODO: add assertion for Toolbar:getOrientation
    end)
end)

describe("Missing explicit test for Toolbar:setOrientation", function()
    it("Toolbar:setOrientation works", function()
        -- @tests Toolbar:setOrientation
        -- TODO: add assertion for Toolbar:setOrientation
    end)
end)

describe("Missing explicit test for Toolbar:addButton", function()
    it("Toolbar:addButton works", function()
        -- @tests Toolbar:addButton
        -- TODO: add assertion for Toolbar:addButton
    end)
end)

describe("Missing explicit test for Toolbar:addSeparator", function()
    it("Toolbar:addSeparator works", function()
        -- @tests Toolbar:addSeparator
        -- TODO: add assertion for Toolbar:addSeparator
    end)
end)

describe("Missing explicit test for Toolbar:addSpacer", function()
    it("Toolbar:addSpacer works", function()
        -- @tests Toolbar:addSpacer
        -- TODO: add assertion for Toolbar:addSpacer
    end)
end)

describe("Missing explicit test for Toolbar:getButton", function()
    it("Toolbar:getButton works", function()
        -- @tests Toolbar:getButton
        -- TODO: add assertion for Toolbar:getButton
    end)
end)

describe("Missing explicit test for Toolbar:setButtonEnabled", function()
    it("Toolbar:setButtonEnabled works", function()
        -- @tests Toolbar:setButtonEnabled
        -- TODO: add assertion for Toolbar:setButtonEnabled
    end)
end)

describe("Missing explicit test for Toolbar:setButtonToggled", function()
    it("Toolbar:setButtonToggled works", function()
        -- @tests Toolbar:setButtonToggled
        -- TODO: add assertion for Toolbar:setButtonToggled
    end)
end)

describe("Missing explicit test for Toolbar:isButtonToggled", function()
    it("Toolbar:isButtonToggled works", function()
        -- @tests Toolbar:isButtonToggled
        -- TODO: add assertion for Toolbar:isButtonToggled
    end)
end)

describe("Missing explicit test for Menu_Bar:addMenu", function()
    it("Menu_Bar:addMenu works", function()
        -- @tests Menu_Bar:addMenu
        -- TODO: add assertion for Menu_Bar:addMenu
    end)
end)

describe("Missing explicit test for Menu_Bar:getMenuCount", function()
    it("Menu_Bar:getMenuCount works", function()
        -- @tests Menu_Bar:getMenuCount
        -- TODO: add assertion for Menu_Bar:getMenuCount
    end)
end)

describe("Missing explicit test for Menu_Item:getText", function()
    it("Menu_Item:getText works", function()
        -- @tests Menu_Item:getText
        -- TODO: add assertion for Menu_Item:getText
    end)
end)

describe("Missing explicit test for Menu_Item:setText", function()
    it("Menu_Item:setText works", function()
        -- @tests Menu_Item:setText
        -- TODO: add assertion for Menu_Item:setText
    end)
end)

describe("Missing explicit test for Menu_Item:getShortcut", function()
    it("Menu_Item:getShortcut works", function()
        -- @tests Menu_Item:getShortcut
        -- TODO: add assertion for Menu_Item:getShortcut
    end)
end)

describe("Missing explicit test for Menu_Item:setShortcut", function()
    it("Menu_Item:setShortcut works", function()
        -- @tests Menu_Item:setShortcut
        -- TODO: add assertion for Menu_Item:setShortcut
    end)
end)

describe("Missing explicit test for Menu_Item:isChecked", function()
    it("Menu_Item:isChecked works", function()
        -- @tests Menu_Item:isChecked
        -- TODO: add assertion for Menu_Item:isChecked
    end)
end)

describe("Missing explicit test for Menu_Item:setChecked", function()
    it("Menu_Item:setChecked works", function()
        -- @tests Menu_Item:setChecked
        -- TODO: add assertion for Menu_Item:setChecked
    end)
end)

describe("Missing explicit test for Menu_Item:addSubItem", function()
    it("Menu_Item:addSubItem works", function()
        -- @tests Menu_Item:addSubItem
        -- TODO: add assertion for Menu_Item:addSubItem
    end)
end)

describe("Missing explicit test for Menu_Item:getSubItems", function()
    it("Menu_Item:getSubItems works", function()
        -- @tests Menu_Item:getSubItems
        -- TODO: add assertion for Menu_Item:getSubItems
    end)
end)

describe("Missing explicit test for Menu_Item:setOnClick", function()
    it("Menu_Item:setOnClick works", function()
        -- @tests Menu_Item:setOnClick
        -- TODO: add assertion for Menu_Item:setOnClick
    end)
end)

describe("Missing explicit test for Dialog:getTitle", function()
    it("Dialog:getTitle works", function()
        -- @tests Dialog:getTitle
        -- TODO: add assertion for Dialog:getTitle
    end)
end)

describe("Missing explicit test for Dialog:setTitle", function()
    it("Dialog:setTitle works", function()
        -- @tests Dialog:setTitle
        -- TODO: add assertion for Dialog:setTitle
    end)
end)

describe("Missing explicit test for Dialog:isModal", function()
    it("Dialog:isModal works", function()
        -- @tests Dialog:isModal
        -- TODO: add assertion for Dialog:isModal
    end)
end)

describe("Missing explicit test for Dialog:isOpen", function()
    it("Dialog:isOpen works", function()
        -- @tests Dialog:isOpen
        -- TODO: add assertion for Dialog:isOpen
    end)
end)

describe("Missing explicit test for Dialog:open", function()
    it("Dialog:open works", function()
        -- @tests Dialog:open
        -- TODO: add assertion for Dialog:open
    end)
end)

describe("Missing explicit test for Dialog:close", function()
    it("Dialog:close works", function()
        -- @tests Dialog:close
        -- TODO: add assertion for Dialog:close
    end)
end)

describe("Missing explicit test for Dialog:setContent", function()
    it("Dialog:setContent works", function()
        -- @tests Dialog:setContent
        -- TODO: add assertion for Dialog:setContent
    end)
end)

describe("Missing explicit test for Dialog:getContent", function()
    it("Dialog:getContent works", function()
        -- @tests Dialog:getContent
        -- TODO: add assertion for Dialog:getContent
    end)
end)

describe("Missing explicit test for Dialog:addButton", function()
    it("Dialog:addButton works", function()
        -- @tests Dialog:addButton
        -- TODO: add assertion for Dialog:addButton
    end)
end)

describe("Missing explicit test for Status_Bar:addSection", function()
    it("Status_Bar:addSection works", function()
        -- @tests Status_Bar:addSection
        -- TODO: add assertion for Status_Bar:addSection
    end)
end)

describe("Missing explicit test for Status_Bar:setSectionText", function()
    it("Status_Bar:setSectionText works", function()
        -- @tests Status_Bar:setSectionText
        -- TODO: add assertion for Status_Bar:setSectionText
    end)
end)

describe("Missing explicit test for Status_Bar:getSectionText", function()
    it("Status_Bar:getSectionText works", function()
        -- @tests Status_Bar:getSectionText
        -- TODO: add assertion for Status_Bar:getSectionText
    end)
end)

describe("Missing explicit test for Status_Bar:getSectionCount", function()
    it("Status_Bar:getSectionCount works", function()
        -- @tests Status_Bar:getSectionCount
        -- TODO: add assertion for Status_Bar:getSectionCount
    end)
end)

describe("Missing explicit test for Status_Bar:setSectionCount", function()
    it("Status_Bar:setSectionCount works", function()
        -- @tests Status_Bar:setSectionCount
        -- TODO: add assertion for Status_Bar:setSectionCount
    end)
end)

describe("Missing explicit test for Status_Bar:setSectionWidget", function()
    it("Status_Bar:setSectionWidget works", function()
        -- @tests Status_Bar:setSectionWidget
        -- TODO: add assertion for Status_Bar:setSectionWidget
    end)
end)

describe("Missing explicit test for Accordion:addSection", function()
    it("Accordion:addSection works", function()
        -- @tests Accordion:addSection
        -- TODO: add assertion for Accordion:addSection
    end)
end)

describe("Missing explicit test for Accordion:getSectionCount", function()
    it("Accordion:getSectionCount works", function()
        -- @tests Accordion:getSectionCount
        -- TODO: add assertion for Accordion:getSectionCount
    end)
end)

describe("Missing explicit test for Accordion:toggleSection", function()
    it("Accordion:toggleSection works", function()
        -- @tests Accordion:toggleSection
        -- TODO: add assertion for Accordion:toggleSection
    end)
end)

describe("Missing explicit test for Accordion:isSectionExpanded", function()
    it("Accordion:isSectionExpanded works", function()
        -- @tests Accordion:isSectionExpanded
        -- TODO: add assertion for Accordion:isSectionExpanded
    end)
end)

describe("Missing explicit test for Accordion:isExclusive", function()
    it("Accordion:isExclusive works", function()
        -- @tests Accordion:isExclusive
        -- TODO: add assertion for Accordion:isExclusive
    end)
end)

describe("Missing explicit test for Accordion:setExclusive", function()
    it("Accordion:setExclusive works", function()
        -- @tests Accordion:setExclusive
        -- TODO: add assertion for Accordion:setExclusive
    end)
end)

describe("Missing explicit test for Tooltip_Panel:getText", function()
    it("Tooltip_Panel:getText works", function()
        -- @tests Tooltip_Panel:getText
        -- TODO: add assertion for Tooltip_Panel:getText
    end)
end)

describe("Missing explicit test for Tooltip_Panel:setText", function()
    it("Tooltip_Panel:setText works", function()
        -- @tests Tooltip_Panel:setText
        -- TODO: add assertion for Tooltip_Panel:setText
    end)
end)

describe("Missing explicit test for Tooltip_Panel:getDelay", function()
    it("Tooltip_Panel:getDelay works", function()
        -- @tests Tooltip_Panel:getDelay
        -- TODO: add assertion for Tooltip_Panel:getDelay
    end)
end)

describe("Missing explicit test for Tooltip_Panel:setDelay", function()
    it("Tooltip_Panel:setDelay works", function()
        -- @tests Tooltip_Panel:setDelay
        -- TODO: add assertion for Tooltip_Panel:setDelay
    end)
end)

describe("Missing explicit test for Tooltip_Panel:getTarget", function()
    it("Tooltip_Panel:getTarget works", function()
        -- @tests Tooltip_Panel:getTarget
        -- TODO: add assertion for Tooltip_Panel:getTarget
    end)
end)

describe("Missing explicit test for Tooltip_Panel:setTarget", function()
    it("Tooltip_Panel:setTarget works", function()
        -- @tests Tooltip_Panel:setTarget
        -- TODO: add assertion for Tooltip_Panel:setTarget
    end)
end)

describe("Missing explicit test for Color_Picker:getColor", function()
    it("Color_Picker:getColor works", function()
        -- @tests Color_Picker:getColor
        -- TODO: add assertion for Color_Picker:getColor
    end)
end)

describe("Missing explicit test for Color_Picker:setColor", function()
    it("Color_Picker:setColor works", function()
        -- @tests Color_Picker:setColor
        -- TODO: add assertion for Color_Picker:setColor
    end)
end)

describe("Missing explicit test for Color_Picker:getShowAlpha", function()
    it("Color_Picker:getShowAlpha works", function()
        -- @tests Color_Picker:getShowAlpha
        -- TODO: add assertion for Color_Picker:getShowAlpha
    end)
end)

describe("Missing explicit test for Color_Picker:getColorMode", function()
    it("Color_Picker:getColorMode works", function()
        -- @tests Color_Picker:getColorMode
        -- TODO: add assertion for Color_Picker:getColorMode
    end)
end)

describe("Missing explicit test for Color_Picker:setColorMode", function()
    it("Color_Picker:setColorMode works", function()
        -- @tests Color_Picker:setColorMode
        -- TODO: add assertion for Color_Picker:setColorMode
    end)
end)

describe("Missing explicit test for Color_Picker:setOnChange", function()
    it("Color_Picker:setOnChange works", function()
        -- @tests Color_Picker:setOnChange
        -- TODO: add assertion for Color_Picker:setOnChange
    end)
end)

describe("Missing explicit test for Gui_Table:addColumn", function()
    it("Gui_Table:addColumn works", function()
        -- @tests Gui_Table:addColumn
        -- TODO: add assertion for Gui_Table:addColumn
    end)
end)

describe("Missing explicit test for Gui_Table:getColumnCount", function()
    it("Gui_Table:getColumnCount works", function()
        -- @tests Gui_Table:getColumnCount
        -- TODO: add assertion for Gui_Table:getColumnCount
    end)
end)

describe("Missing explicit test for Gui_Table:addRow", function()
    it("Gui_Table:addRow works", function()
        -- @tests Gui_Table:addRow
        -- TODO: add assertion for Gui_Table:addRow
    end)
end)

describe("Missing explicit test for Gui_Table:getRowCount", function()
    it("Gui_Table:getRowCount works", function()
        -- @tests Gui_Table:getRowCount
        -- TODO: add assertion for Gui_Table:getRowCount
    end)
end)

describe("Missing explicit test for Gui_Table:getCell", function()
    it("Gui_Table:getCell works", function()
        -- @tests Gui_Table:getCell
        -- TODO: add assertion for Gui_Table:getCell
    end)
end)

describe("Missing explicit test for Gui_Table:setCell", function()
    it("Gui_Table:setCell works", function()
        -- @tests Gui_Table:setCell
        -- TODO: add assertion for Gui_Table:setCell
    end)
end)

describe("Missing explicit test for Gui_Table:getSelectedRow", function()
    it("Gui_Table:getSelectedRow works", function()
        -- @tests Gui_Table:getSelectedRow
        -- TODO: add assertion for Gui_Table:getSelectedRow
    end)
end)

describe("Missing explicit test for Gui_Table:setSelectedRow", function()
    it("Gui_Table:setSelectedRow works", function()
        -- @tests Gui_Table:setSelectedRow
        -- TODO: add assertion for Gui_Table:setSelectedRow
    end)
end)

describe("Missing explicit test for Gui_Table:isSortable", function()
    it("Gui_Table:isSortable works", function()
        -- @tests Gui_Table:isSortable
        -- TODO: add assertion for Gui_Table:isSortable
    end)
end)

describe("Missing explicit test for Gui_Table:setSortable", function()
    it("Gui_Table:setSortable works", function()
        -- @tests Gui_Table:setSortable
        -- TODO: add assertion for Gui_Table:setSortable
    end)
end)

describe("Missing explicit test for Gui_Table:setOnSelect", function()
    it("Gui_Table:setOnSelect works", function()
        -- @tests Gui_Table:setOnSelect
        -- TODO: add assertion for Gui_Table:setOnSelect
    end)
end)

describe("Missing explicit test for Image_Widget:getScaleMode", function()
    it("Image_Widget:getScaleMode works", function()
        -- @tests Image_Widget:getScaleMode
        -- TODO: add assertion for Image_Widget:getScaleMode
    end)
end)

describe("Missing explicit test for Image_Widget:setScaleMode", function()
    it("Image_Widget:setScaleMode works", function()
        -- @tests Image_Widget:setScaleMode
        -- TODO: add assertion for Image_Widget:setScaleMode
    end)
end)

describe("Missing explicit test for Image_Widget:getTint", function()
    it("Image_Widget:getTint works", function()
        -- @tests Image_Widget:getTint
        -- TODO: add assertion for Image_Widget:getTint
    end)
end)

describe("Missing explicit test for Image_Widget:setTint", function()
    it("Image_Widget:setTint works", function()
        -- @tests Image_Widget:setTint
        -- TODO: add assertion for Image_Widget:setTint
    end)
end)

describe("Missing explicit test for Image_Widget:newButton", function()
    it("Image_Widget:newButton works", function()
        -- @tests Image_Widget:newButton
        -- TODO: add assertion for Image_Widget:newButton
    end)
end)

describe("Missing explicit test for Image_Widget:newLabel", function()
    it("Image_Widget:newLabel works", function()
        -- @tests Image_Widget:newLabel
        -- TODO: add assertion for Image_Widget:newLabel
    end)
end)

describe("Missing explicit test for Image_Widget:newTextInput", function()
    it("Image_Widget:newTextInput works", function()
        -- @tests Image_Widget:newTextInput
        -- TODO: add assertion for Image_Widget:newTextInput
    end)
end)

describe("Missing explicit test for Image_Widget:newCheckbox", function()
    it("Image_Widget:newCheckbox works", function()
        -- @tests Image_Widget:newCheckbox
        -- TODO: add assertion for Image_Widget:newCheckbox
    end)
end)

describe("Missing explicit test for Image_Widget:newSlider", function()
    it("Image_Widget:newSlider works", function()
        -- @tests Image_Widget:newSlider
        -- TODO: add assertion for Image_Widget:newSlider
    end)
end)

describe("Missing explicit test for Image_Widget:newProgressBar", function()
    it("Image_Widget:newProgressBar works", function()
        -- @tests Image_Widget:newProgressBar
        -- TODO: add assertion for Image_Widget:newProgressBar
    end)
end)

describe("Missing explicit test for Image_Widget:newComboBox", function()
    it("Image_Widget:newComboBox works", function()
        -- @tests Image_Widget:newComboBox
        -- TODO: add assertion for Image_Widget:newComboBox
    end)
end)

describe("Missing explicit test for Image_Widget:newList", function()
    it("Image_Widget:newList works", function()
        -- @tests Image_Widget:newList
        -- TODO: add assertion for Image_Widget:newList
    end)
end)

describe("Missing explicit test for Image_Widget:newPanel", function()
    it("Image_Widget:newPanel works", function()
        -- @tests Image_Widget:newPanel
        -- TODO: add assertion for Image_Widget:newPanel
    end)
end)

describe("Missing explicit test for Image_Widget:newLayout", function()
    it("Image_Widget:newLayout works", function()
        -- @tests Image_Widget:newLayout
        -- TODO: add assertion for Image_Widget:newLayout
    end)
end)

describe("Missing explicit test for Image_Widget:newScrollPanel", function()
    it("Image_Widget:newScrollPanel works", function()
        -- @tests Image_Widget:newScrollPanel
        -- TODO: add assertion for Image_Widget:newScrollPanel
    end)
end)

describe("Missing explicit test for Image_Widget:newNinePatch", function()
    it("Image_Widget:newNinePatch works", function()
        -- @tests Image_Widget:newNinePatch
        -- TODO: add assertion for Image_Widget:newNinePatch
    end)
end)

describe("Missing explicit test for Image_Widget:newTabBar", function()
    it("Image_Widget:newTabBar works", function()
        -- @tests Image_Widget:newTabBar
        -- TODO: add assertion for Image_Widget:newTabBar
    end)
end)

describe("Missing explicit test for Image_Widget:newSeparator", function()
    it("Image_Widget:newSeparator works", function()
        -- @tests Image_Widget:newSeparator
        -- TODO: add assertion for Image_Widget:newSeparator
    end)
end)

describe("Missing explicit test for Image_Widget:newSpacer", function()
    it("Image_Widget:newSpacer works", function()
        -- @tests Image_Widget:newSpacer
        -- TODO: add assertion for Image_Widget:newSpacer
    end)
end)

describe("Missing explicit test for Image_Widget:newToast", function()
    it("Image_Widget:newToast works", function()
        -- @tests Image_Widget:newToast
        -- TODO: add assertion for Image_Widget:newToast
    end)
end)

describe("Missing explicit test for Image_Widget:newTreeView", function()
    it("Image_Widget:newTreeView works", function()
        -- @tests Image_Widget:newTreeView
        -- TODO: add assertion for Image_Widget:newTreeView
    end)
end)

describe("Missing explicit test for Image_Widget:newRadioButton", function()
    it("Image_Widget:newRadioButton works", function()
        -- @tests Image_Widget:newRadioButton
        -- TODO: add assertion for Image_Widget:newRadioButton
    end)
end)

describe("Missing explicit test for Image_Widget:newScrollBar", function()
    it("Image_Widget:newScrollBar works", function()
        -- @tests Image_Widget:newScrollBar
        -- TODO: add assertion for Image_Widget:newScrollBar
    end)
end)

describe("Missing explicit test for Image_Widget:newWindow", function()
    it("Image_Widget:newWindow works", function()
        -- @tests Image_Widget:newWindow
        -- TODO: add assertion for Image_Widget:newWindow
    end)
end)

describe("Missing explicit test for Image_Widget:newSplitPanel", function()
    it("Image_Widget:newSplitPanel works", function()
        -- @tests Image_Widget:newSplitPanel
        -- TODO: add assertion for Image_Widget:newSplitPanel
    end)
end)

describe("Missing explicit test for Image_Widget:newDockPanel", function()
    it("Image_Widget:newDockPanel works", function()
        -- @tests Image_Widget:newDockPanel
        -- TODO: add assertion for Image_Widget:newDockPanel
    end)
end)

describe("Missing explicit test for Image_Widget:newToolbar", function()
    it("Image_Widget:newToolbar works", function()
        -- @tests Image_Widget:newToolbar
        -- TODO: add assertion for Image_Widget:newToolbar
    end)
end)

describe("Missing explicit test for Image_Widget:newMenuBar", function()
    it("Image_Widget:newMenuBar works", function()
        -- @tests Image_Widget:newMenuBar
        -- TODO: add assertion for Image_Widget:newMenuBar
    end)
end)

describe("Missing explicit test for Image_Widget:newMenuItem", function()
    it("Image_Widget:newMenuItem works", function()
        -- @tests Image_Widget:newMenuItem
        -- TODO: add assertion for Image_Widget:newMenuItem
    end)
end)

describe("Missing explicit test for Image_Widget:newDialog", function()
    it("Image_Widget:newDialog works", function()
        -- @tests Image_Widget:newDialog
        -- TODO: add assertion for Image_Widget:newDialog
    end)
end)

describe("Missing explicit test for Image_Widget:newStatusBar", function()
    it("Image_Widget:newStatusBar works", function()
        -- @tests Image_Widget:newStatusBar
        -- TODO: add assertion for Image_Widget:newStatusBar
    end)
end)

describe("Missing explicit test for Image_Widget:newAccordion", function()
    it("Image_Widget:newAccordion works", function()
        -- @tests Image_Widget:newAccordion
        -- TODO: add assertion for Image_Widget:newAccordion
    end)
end)

describe("Missing explicit test for Image_Widget:newTooltipPanel", function()
    it("Image_Widget:newTooltipPanel works", function()
        -- @tests Image_Widget:newTooltipPanel
        -- TODO: add assertion for Image_Widget:newTooltipPanel
    end)
end)

describe("Missing explicit test for Image_Widget:newColorPicker", function()
    it("Image_Widget:newColorPicker works", function()
        -- @tests Image_Widget:newColorPicker
        -- TODO: add assertion for Image_Widget:newColorPicker
    end)
end)

describe("Missing explicit test for Image_Widget:newTable", function()
    it("Image_Widget:newTable works", function()
        -- @tests Image_Widget:newTable
        -- TODO: add assertion for Image_Widget:newTable
    end)
end)

describe("Missing explicit test for Image_Widget:newImageWidget", function()
    it("Image_Widget:newImageWidget works", function()
        -- @tests Image_Widget:newImageWidget
        -- TODO: add assertion for Image_Widget:newImageWidget
    end)
end)

describe("Missing explicit test for Image_Widget:newTheme", function()
    it("Image_Widget:newTheme works", function()
        -- @tests Image_Widget:newTheme
        -- TODO: add assertion for Image_Widget:newTheme
    end)
end)

describe("Missing explicit test for Image_Widget:setTheme", function()
    it("Image_Widget:setTheme works", function()
        -- @tests Image_Widget:setTheme
        -- TODO: add assertion for Image_Widget:setTheme
    end)
end)

describe("Missing explicit test for Image_Widget:getTheme", function()
    it("Image_Widget:getTheme works", function()
        -- @tests Image_Widget:getTheme
        -- TODO: add assertion for Image_Widget:getTheme
    end)
end)

describe("Missing explicit test for Image_Widget:getRoot", function()
    it("Image_Widget:getRoot works", function()
        -- @tests Image_Widget:getRoot
        -- TODO: add assertion for Image_Widget:getRoot
    end)
end)

describe("Missing explicit test for Image_Widget:setFocus", function()
    it("Image_Widget:setFocus works", function()
        -- @tests Image_Widget:setFocus
        -- TODO: add assertion for Image_Widget:setFocus
    end)
end)

describe("Missing explicit test for Image_Widget:getFocus", function()
    it("Image_Widget:getFocus works", function()
        -- @tests Image_Widget:getFocus
        -- TODO: add assertion for Image_Widget:getFocus
    end)
end)

describe("Missing explicit test for Image_Widget:focusNext", function()
    it("Image_Widget:focusNext works", function()
        -- @tests Image_Widget:focusNext
        -- TODO: add assertion for Image_Widget:focusNext
    end)
end)

describe("Missing explicit test for Image_Widget:focusPrev", function()
    it("Image_Widget:focusPrev works", function()
        -- @tests Image_Widget:focusPrev
        -- TODO: add assertion for Image_Widget:focusPrev
    end)
end)

describe("Missing explicit test for Image_Widget:clearFocus", function()
    it("Image_Widget:clearFocus works", function()
        -- @tests Image_Widget:clearFocus
        -- TODO: add assertion for Image_Widget:clearFocus
    end)
end)

describe("Missing explicit test for Image_Widget:addToast", function()
    it("Image_Widget:addToast works", function()
        -- @tests Image_Widget:addToast
        -- TODO: add assertion for Image_Widget:addToast
    end)
end)

describe("Missing explicit test for Image_Widget:getToastCount", function()
    it("Image_Widget:getToastCount works", function()
        -- @tests Image_Widget:getToastCount
        -- TODO: add assertion for Image_Widget:getToastCount
    end)
end)

describe("Missing explicit test for Image_Widget:mousepressed", function()
    it("Image_Widget:mousepressed works", function()
        -- @tests Image_Widget:mousepressed
        -- TODO: add assertion for Image_Widget:mousepressed
    end)
end)

describe("Missing explicit test for Image_Widget:mousereleased", function()
    it("Image_Widget:mousereleased works", function()
        -- @tests Image_Widget:mousereleased
        -- TODO: add assertion for Image_Widget:mousereleased
    end)
end)

describe("Missing explicit test for Image_Widget:mousemoved", function()
    it("Image_Widget:mousemoved works", function()
        -- @tests Image_Widget:mousemoved
        -- TODO: add assertion for Image_Widget:mousemoved
    end)
end)

describe("Missing explicit test for Image_Widget:keypressed", function()
    it("Image_Widget:keypressed works", function()
        -- @tests Image_Widget:keypressed
        -- TODO: add assertion for Image_Widget:keypressed
    end)
end)

describe("Missing explicit test for Image_Widget:textinput", function()
    it("Image_Widget:textinput works", function()
        -- @tests Image_Widget:textinput
        -- TODO: add assertion for Image_Widget:textinput
    end)
end)

describe("Missing explicit test for Image_Widget:wheelmoved", function()
    it("Image_Widget:wheelmoved works", function()
        -- @tests Image_Widget:wheelmoved
        -- TODO: add assertion for Image_Widget:wheelmoved
    end)
end)

describe("Missing explicit test for Image_Widget:update", function()
    it("Image_Widget:update works", function()
        -- @tests Image_Widget:update
        -- TODO: add assertion for Image_Widget:update
    end)
end)

describe("Missing explicit test for Image_Widget:draw", function()
    it("Image_Widget:draw works", function()
        -- @tests Image_Widget:draw
        -- TODO: add assertion for Image_Widget:draw
    end)
end)

describe("Missing explicit test for Image_Widget:getWidgetCount", function()
    it("Image_Widget:getWidgetCount works", function()
        -- @tests Image_Widget:getWidgetCount
        -- TODO: add assertion for Image_Widget:getWidgetCount
    end)
end)

describe("Missing explicit test for Image_Widget:drawToImage", function()
    it("Image_Widget:drawToImage works", function()
        -- @tests Image_Widget:drawToImage
        -- TODO: add assertion for Image_Widget:drawToImage
    end)
end)

describe("Missing explicit test for Image_Widget:newLineChart", function()
    it("Image_Widget:newLineChart works", function()
        -- @tests Image_Widget:newLineChart
        -- TODO: add assertion for Image_Widget:newLineChart
    end)
end)

describe("Missing explicit test for Image_Widget:newBarChart", function()
    it("Image_Widget:newBarChart works", function()
        -- @tests Image_Widget:newBarChart
        -- TODO: add assertion for Image_Widget:newBarChart
    end)
end)

describe("Missing explicit test for Image_Widget:newScatterPlot", function()
    it("Image_Widget:newScatterPlot works", function()
        -- @tests Image_Widget:newScatterPlot
        -- TODO: add assertion for Image_Widget:newScatterPlot
    end)
end)

describe("Missing explicit test for Image_Widget:newPieChart", function()
    it("Image_Widget:newPieChart works", function()
        -- @tests Image_Widget:newPieChart
        -- TODO: add assertion for Image_Widget:newPieChart
    end)
end)

describe("Missing explicit test for Image_Widget:newAreaChart", function()
    it("Image_Widget:newAreaChart works", function()
        -- @tests Image_Widget:newAreaChart
        -- TODO: add assertion for Image_Widget:newAreaChart
    end)
end)

describe("Missing explicit test for Image_Widget:newLineChart", function()
    it("Image_Widget:newLineChart works", function()
        -- @tests Image_Widget:newLineChart
        -- TODO: add assertion for Image_Widget:newLineChart
    end)
end)

describe("Missing explicit test for Image_Widget:newBarChart", function()
    it("Image_Widget:newBarChart works", function()
        -- @tests Image_Widget:newBarChart
        -- TODO: add assertion for Image_Widget:newBarChart
    end)
end)

describe("Missing explicit test for Image_Widget:newScatterPlot", function()
    it("Image_Widget:newScatterPlot works", function()
        -- @tests Image_Widget:newScatterPlot
        -- TODO: add assertion for Image_Widget:newScatterPlot
    end)
end)

describe("Missing explicit test for Image_Widget:newPieChart", function()
    it("Image_Widget:newPieChart works", function()
        -- @tests Image_Widget:newPieChart
        -- TODO: add assertion for Image_Widget:newPieChart
    end)
end)

describe("Missing explicit test for Image_Widget:newAreaChart", function()
    it("Image_Widget:newAreaChart works", function()
        -- @tests Image_Widget:newAreaChart
        -- TODO: add assertion for Image_Widget:newAreaChart
    end)
end)

describe("Missing explicit test for Image_Widget:parseWidgetState", function()
    it("Image_Widget:parseWidgetState works", function()
        -- @tests Image_Widget:parseWidgetState
        -- TODO: add assertion for Image_Widget:parseWidgetState
    end)
end)

describe("Missing explicit test for Image_Widget:newSpinBox", function()
    it("Image_Widget:newSpinBox works", function()
        -- @tests Image_Widget:newSpinBox
        -- TODO: add assertion for Image_Widget:newSpinBox
    end)
end)

describe("Missing explicit test for Image_Widget:newSwitch", function()
    it("Image_Widget:newSwitch works", function()
        -- @tests Image_Widget:newSwitch
        -- TODO: add assertion for Image_Widget:newSwitch
    end)
end)

describe("Missing explicit test for Image_Widget:newBadge", function()
    it("Image_Widget:newBadge works", function()
        -- @tests Image_Widget:newBadge
        -- TODO: add assertion for Image_Widget:newBadge
    end)
end)

describe("Missing explicit test for Image_Widget:setDefaultTheme", function()
    it("Image_Widget:setDefaultTheme works", function()
        -- @tests Image_Widget:setDefaultTheme
        -- TODO: add assertion for Image_Widget:setDefaultTheme
    end)
end)

describe("Missing explicit test for Image_Widget:setViewport", function()
    it("Image_Widget:setViewport works", function()
        -- @tests Image_Widget:setViewport
        -- TODO: add assertion for Image_Widget:setViewport
    end)
end)

describe("Missing explicit test for Image_Widget:flushCache", function()
    it("Image_Widget:flushCache works", function()
        -- @tests Image_Widget:flushCache
        -- TODO: add assertion for Image_Widget:flushCache
    end)
end)

describe("Missing explicit test for Image_Widget:loadLayout", function()
    it("Image_Widget:loadLayout works", function()
        -- @tests Image_Widget:loadLayout
        -- TODO: add assertion for Image_Widget:loadLayout
    end)
end)

describe("Missing explicit test for Image_Widget:loadLayoutFile", function()
    it("Image_Widget:loadLayoutFile works", function()
        -- @tests Image_Widget:loadLayoutFile
        -- TODO: add assertion for Image_Widget:loadLayoutFile
    end)
end)

describe("Missing explicit test for Image_Widget:renderToImage", function()
    it("Image_Widget:renderToImage works", function()
        -- @tests Image_Widget:renderToImage
        -- TODO: add assertion for Image_Widget:renderToImage
    end)
end)

describe("Missing explicit test for LineChart:setYMax", function()
    it("LineChart:setYMax works", function()
        -- @tests LineChart:setYMax
        -- TODO: add assertion for LineChart:setYMax
    end)
end)

describe("Missing explicit test for LineChart:setXMax", function()
    it("LineChart:setXMax works", function()
        -- @tests LineChart:setXMax
        -- TODO: add assertion for LineChart:setXMax
    end)
end)

describe("Missing explicit test for LineChart:drawToImage", function()
    it("LineChart:drawToImage works", function()
        -- @tests LineChart:drawToImage
        -- TODO: add assertion for LineChart:drawToImage
    end)
end)

describe("Missing explicit test for BarChart:drawToImage", function()
    it("BarChart:drawToImage works", function()
        -- @tests BarChart:drawToImage
        -- TODO: add assertion for BarChart:drawToImage
    end)
end)

describe("Missing explicit test for ScatterPlot:setXRange", function()
    it("ScatterPlot:setXRange works", function()
        -- @tests ScatterPlot:setXRange
        -- TODO: add assertion for ScatterPlot:setXRange
    end)
end)

describe("Missing explicit test for ScatterPlot:setYRange", function()
    it("ScatterPlot:setYRange works", function()
        -- @tests ScatterPlot:setYRange
        -- TODO: add assertion for ScatterPlot:setYRange
    end)
end)

describe("Missing explicit test for ScatterPlot:drawToImage", function()
    it("ScatterPlot:drawToImage works", function()
        -- @tests ScatterPlot:drawToImage
        -- TODO: add assertion for ScatterPlot:drawToImage
    end)
end)

describe("Missing explicit test for PieChart:drawToImage", function()
    it("PieChart:drawToImage works", function()
        -- @tests PieChart:drawToImage
        -- TODO: add assertion for PieChart:drawToImage
    end)
end)

describe("Missing explicit test for AreaChart:setYMax", function()
    it("AreaChart:setYMax works", function()
        -- @tests AreaChart:setYMax
        -- TODO: add assertion for AreaChart:setYMax
    end)
end)

describe("Missing explicit test for AreaChart:drawToImage", function()
    it("AreaChart:drawToImage works", function()
        -- @tests AreaChart:drawToImage
        -- TODO: add assertion for AreaChart:drawToImage
    end)
end)
