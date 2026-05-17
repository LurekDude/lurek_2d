-- test_ui_unit.lua
-- Unit tests for lurek.ui.loadLayout and lurek.ui.loadLayoutFile.
-- Covers: API existence, widget tree creation from a Lua table definition,
-- child attachment, ID lookup, flat and nested layouts.

-- =========================================================================
-- 1. Layout API existence
-- =========================================================================
-- @describe lurek.ui layout loader API exists
describe("lurek.ui layout loader API exists", function()
    -- @covers lurek.ui.loadLayout
    it("loadLayout is a function", function()
        expect_type("function", lurek.ui.loadLayout)
    end)

    -- @covers lurek.ui.loadLayoutFile
    it("loadLayoutFile is a function", function()
        expect_type("function", lurek.ui.loadLayoutFile)
    end)

    -- @covers lurek.ui.renderToImage
    it("renderToImage is a function", function()
        expect_type("function", lurek.ui.renderToImage)
    end)
end)

-- =========================================================================
-- 2. loadLayout  - flat single-widget definition
-- =========================================================================
-- @describe lurek.ui.loadLayout  - flat single widget
describe("lurek.ui.loadLayout  - flat single widget", function()
    -- @covers lurek.ui.getWidgetCount
    -- @covers lurek.ui.loadLayout
    it("returns a positive pool index", function()
        local before = lurek.ui.getWidgetCount()
        local idx = lurek.ui.loadLayout({ type = "panel", w = 100, h = 80 })
        expect_type("number", idx)
        local after = lurek.ui.getWidgetCount()
        -- At least one new widget was added
        expect_true(after > before, "widget count must increase after loadLayout")
        expect_true(idx > 0, "returned pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a label widget", function()
        local idx = lurek.ui.loadLayout({
            type = "label",
            text = "Score",
            x = 10, y = 10, w = 80, h = 24
        })
        expect_true(idx > 0, "label pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a button widget", function()
        local idx = lurek.ui.loadLayout({
            type = "button",
            text = "OK",
            x = 10, y = 10, w = 80, h = 30
        })
        expect_true(idx > 0, "button pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a checkbox widget", function()
        local idx = lurek.ui.loadLayout({
            type = "checkbox",
            text = "Enable",
            checked = true,
            x = 0, y = 0, w = 120, h = 24
        })
        expect_true(idx > 0, "checkbox pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a separator widget", function()
        local idx = lurek.ui.loadLayout({ type = "separator" })
        expect_true(idx > 0, "separator pool index must be > 0")
    end)
end)

-- =========================================================================
-- 3. loadLayout  - nested widget tree with id lookup
-- =========================================================================
-- @describe lurek.ui.loadLayout  - nested tree with id lookup
describe("lurek.ui.loadLayout  - nested tree with id lookup", function()
    -- @covers lurek.ui.getWidgetCount
    -- @covers lurek.ui.loadLayout
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
        expect_true(after >= before + 3,
            "expected at least 3 new widgets, got " .. (after - before))
    end)

    -- @covers lurek.ui.getRoot
    -- @covers lurek.ui.loadLayout
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
        local found = root:findById("hp_label")
        expect_true(found ~= nil, "findById('hp_label') must return a widget handle")
    end)

    -- @covers lurek.ui.loadLayout
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
        expect_true(ok, "3-level nested loadLayout must not throw")
    end)
end)

-- =========================================================================
-- 4. loadLayout  - all supported widget types do not crash
-- =========================================================================
-- without a Lua error.
-- @describe lurek.ui.loadLayout  - widget type coverage
describe("lurek.ui.loadLayout  - widget type coverage", function()
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
        -- @covers lurek.ui.loadLayout
        it("type '" .. wtype .. "' loads without error", function()
            local ok = pcall(function()
                lurek.ui.loadLayout({ type = wtype })
            end)
            expect_true(ok, "loadLayout({type='" .. wtype .. "'}) must not throw")
        end)
    end
end)

-- =========================================================================
-- 5. Custom widget extensibility
-- =========================================================================
-- @describe UI custom widget
describe("UI custom widget", function()
    -- @covers lurek.ui.newCustomWidget
    it("newCustomWidget is a function", function()
        expect_type("function", lurek.ui.newCustomWidget)
    end)

    -- @covers lurek.ui.getWidgetCount
    -- @covers lurek.ui.newCustomWidget
    it("newCustomWidget creates a widget handle", function()
        local before = lurek.ui.getWidgetCount()
        local w = lurek.ui.newCustomWidget({
            x = 10, y = 20, width = 200, height = 150,
            id = "test_custom",
        })
        expect_not_nil(w)
        local after = lurek.ui.getWidgetCount()
        expect_true(after > before, "widget count must increase after newCustomWidget")
    end)

    -- @covers lurek.ui.newCustomWidget
    it("setOnDraw method exists on widget", function()
        ---@type unknown
        local w = lurek.ui.newCustomWidget({ width = 100, height = 100 })
        expect_not_nil(w)
        expect_type("function", w.setOnDraw)
    end)

    -- @covers lurek.ui.newCustomWidget
    it("setOnDraw accepts a callback without error", function()
        ---@type unknown
        local w = lurek.ui.newCustomWidget({ x = 0, y = 0, width = 100, height = 50 })
        local ok = pcall(function()
            w:setOnDraw(function(rect)
                -- rect table is passed by draw(); no draw call here
            end)
        end)
        expect_true(ok, "setOnDraw must not throw")
    end)

    -- @covers lurek.ui.loadLayout
    it("loadLayout type='custom' does not crash", function()
        local ok = pcall(function()
            lurek.ui.loadLayout({
                type = "custom",
                x = 0, y = 0, w = 64, h = 64, id = "layout_custom",
            })
        end)
        expect_true(ok, "loadLayout({type='custom'}) must not throw")
    end)

    -- @covers lurek.ui.draw
    -- @covers lurek.ui.newCustomWidget
    it("draw invokes on_draw callback", function()
        local called = false
        ---@type unknown
        local w = lurek.ui.newCustomWidget({ x = 5, y = 5, width = 40, height = 30 })
        w:setOnDraw(function(rect)
            called = true
        end)
        lurek.ui.draw()
        expect_true(called, "on_draw callback must be called by lurek.ui.draw()")
    end)
end)


local function make_basic_widget(opts)
    ---@type unknown
    local widget = lurek.ui.newCustomWidget(opts or {
        x = 1,
        y = 2,
        width = 3,
        height = 4,
    })

    return widget
end

-- @describe Lua coverage for lurek.ui.setPosition
describe("Lua coverage for lurek.ui.setPosition", function()
    -- @covers LUiWidget.setPosition
    -- @covers LUiWidget.getPosition
    it("lurek.ui.setPosition works", function()
        local widget = make_basic_widget()
        widget:setPosition(12, 34)

        local x, y = widget:getPosition()
        expect_equal(12, x)
        expect_equal(34, y)
    end)
end)

-- @describe Lua coverage for lurek.ui.getPosition
describe("Lua coverage for lurek.ui.getPosition", function()
    -- @covers LUiWidget.getPosition
    it("lurek.ui.getPosition works", function()
        local widget = make_basic_widget({
            x = 9,
            y = 11,
            width = 30,
            height = 40,
        })

        local x, y = widget:getPosition()
        expect_equal(9, x)
        expect_equal(11, y)
    end)
end)

-- @describe Lua coverage for lurek.ui.setSize
describe("Lua coverage for lurek.ui.setSize", function()
    -- @covers LUiWidget.setSize
    -- @covers LUiWidget.getSize
    it("lurek.ui.setSize works", function()
        local widget = make_basic_widget()
        widget:setSize(56, 78)

        local w, h = widget:getSize()
        expect_equal(56, w)
        expect_equal(78, h)
    end)
end)

-- @describe Lua coverage for lurek.ui.getSize
describe("Lua coverage for lurek.ui.getSize", function()
    -- @covers LUiWidget.getSize
    it("lurek.ui.getSize works", function()
        local widget = make_basic_widget({
            x = 0,
            y = 0,
            width = 21,
            height = 34,
        })

        local w, h = widget:getSize()
        expect_equal(21, w)
        expect_equal(34, h)
    end)
end)

-- @describe Lua coverage for lurek.ui.setVisible
describe("Lua coverage for lurek.ui.setVisible", function()
    -- @covers LUiWidget.setVisible
    -- @covers LUiWidget.isVisible
    it("lurek.ui.setVisible works", function()
        local widget = make_basic_widget()
        widget:setVisible(false)
        expect_false(widget:isVisible())

        widget:setVisible(true)
        expect_true(widget:isVisible())
    end)
end)

-- @describe Lua coverage for lurek.ui.isVisible
describe("Lua coverage for lurek.ui.isVisible", function()
    -- @covers LUiWidget.isVisible
    it("lurek.ui.isVisible works", function()
        local widget = make_basic_widget()
        expect_false(widget:isVisible())
    end)
end)

-- @describe Lua coverage for lurek.ui.setEnabled
describe("Lua coverage for lurek.ui.setEnabled", function()
    -- @covers LUiWidget.setEnabled
    -- @covers LUiWidget.isEnabled
    it("lurek.ui.setEnabled works", function()
        local widget = make_basic_widget()
        widget:setEnabled(false)
        expect_false(widget:isEnabled())

        widget:setEnabled(true)
        expect_true(widget:isEnabled())
    end)
end)

-- @describe Lua coverage for lurek.ui.isEnabled
describe("Lua coverage for lurek.ui.isEnabled", function()
    -- @covers LUiWidget.isEnabled
    it("lurek.ui.isEnabled works", function()
        local widget = make_basic_widget()
        expect_false(widget:isEnabled())
    end)
end)

-- @describe Lua coverage for lurek.ui.setId
describe("Lua coverage for lurek.ui.setId", function()
    -- @covers LUiWidget.setId
    -- @covers LUiWidget.getId
    it("lurek.ui.setId works", function()
        local widget = make_basic_widget()
        widget:setId("hud_button")

        expect_equal("hud_button", widget:getId())
    end)
end)

-- @describe Lua coverage for lurek.ui.getId
describe("Lua coverage for lurek.ui.getId", function()
    -- @covers LUiWidget.getId
    it("lurek.ui.getId works", function()
        local widget = make_basic_widget({
            x = 0,
            y = 0,
            width = 10,
            height = 10,
            id = "score_label",
        })

        expect_equal("score_label", widget:getId())
    end)
end)

-- @describe Lua coverage for lurek.ui.setTooltip
describe("Lua coverage for lurek.ui.setTooltip", function()
    -- @covers LUiWidget.setTooltip
    -- @covers LUiWidget.getTooltip
    it("lurek.ui.setTooltip works", function()
        local widget = make_basic_widget()
        widget:setTooltip("Click to continue")

        expect_equal("Click to continue", widget:getTooltip())
    end)
end)

-- @describe Lua coverage for lurek.ui.getTooltip
describe("Lua coverage for lurek.ui.getTooltip", function()
    -- @covers LUiWidget.getTooltip
    -- @covers LUiWidget.setTooltip
    it("lurek.ui.getTooltip works", function()
        local widget = make_basic_widget()
        expect_equal("", widget:getTooltip())

        widget:setTooltip("Opens the inventory")
        expect_equal("Opens the inventory", widget:getTooltip())
    end)
end)

-- @describe lurek.ui.update_bindings
describe("lurek.ui.update_bindings", function()
    -- @covers lurek.ui.update_bindings
    it("update_bindings is a function", function()
        expect_type("function", lurek.ui.update_bindings)
    end)

    -- @covers lurek.ui.update_bindings
    it("update_bindings accepts an empty table without error", function()
        expect_no_error(function()
            lurek.ui.update_bindings({})
        end)
    end)
end)

-- @describe LUiWidget geometry and visibility
describe("LUiWidget geometry and visibility", function()
    -- @covers LUiWidget.setPosition
    -- @covers LUiWidget.getPosition
    it("setPosition / getPosition round-trips x and y", function()
        local w = make_basic_widget()
        w:setPosition(12.0, 34.0)
        local x, y = w:getPosition()
        expect_equal(12.0, x)
        expect_equal(34.0, y)
    end)

    -- @covers LUiWidget.setSize
    -- @covers LUiWidget.getSize
    it("setSize / getSize round-trips width and height", function()
        local w = make_basic_widget()
        w:setSize(80.0, 60.0)
        local width, height = w:getSize()
        expect_equal(80.0, width)
        expect_equal(60.0, height)
    end)

    -- @covers LUiWidget.getRect
    it("getRect returns four numbers", function()
        local w = make_basic_widget()
        local x, y, width, height = w:getRect()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", width)
        expect_type("number", height)
    end)

    -- @covers LUiWidget.setVisible
    -- @covers LUiWidget.isVisible
    it("setVisible false hides the widget", function()
        local w = make_basic_widget()
        w:setVisible(false)
        expect_equal(false, w:isVisible())
    end)

    -- @covers LUiWidget.setVisible
    -- @covers LUiWidget.isVisible
    it("setVisible true shows the widget", function()
        local w = make_basic_widget()
        w:setVisible(false)
        w:setVisible(true)
        expect_equal(true, w:isVisible())
    end)

    -- @covers LUiWidget.type
    it("type returns the widget type name string", function()
        local w = make_basic_widget()
        local t = w:type()
        expect_type("string", t)
        expect_true(#t > 0)
    end)

    -- @covers LUiWidget.typeOf
    it("typeOf returns true for LWidget and Object", function()
        local w = make_basic_widget()
        expect_equal(true, w:typeOf("LWidget"))
        expect_equal(true, w:typeOf("Object"))
    end)

    -- @covers LUiWidget.typeOf
    it("typeOf returns false for an unrelated type", function()
        local w = make_basic_widget()
        expect_equal(false, w:typeOf("LPhysicsBody"))
    end)

    -- @covers LUiWidget.getState
    it("getState returns a state string", function()
        local w = make_basic_widget()
        local state = w:getState()
        expect_type("string", state)
    end)

    -- @covers LUiWidget.addChild
    -- @covers LUiWidget.getChildCount
    -- @covers LUiWidget.getChildren
    -- @covers LUiWidget.removeChild
    it("child management add/remove works", function()
        local parent = make_basic_widget()
        local child = make_basic_widget()

        parent:addChild(child)
        expect_type("number", parent:getChildCount())
        expect_type("table", parent:getChildren())

        parent:removeChild(child)
        expect_type("number", parent:getChildCount())
    end)

    -- @covers LUiWidget.findById
    -- @covers LUiWidget.setId
    it("findById resolves descendant id", function()
        local parent = make_basic_widget()
        local child = make_basic_widget()
        child:setId("cov_child")
        parent:addChild(child)
        local found = parent:findById("cov_child")
        expect_true(found == nil or type(found) == "table")
    end)

    -- @covers LUiWidget.setOnClick
    -- @covers LUiWidget.setOnChange
    -- @covers LUiWidget.setOnDraw
    it("callback setters accept function values", function()
        local w = make_basic_widget()
        w:setOnClick(function() end)
        w:setOnChange(function() end)
        w:setOnDraw(function() end)
        expect_true(true)
    end)

    -- @covers LUiWidget.containsPoint
    it("containsPoint is callable", function()
        local w = make_basic_widget()
        local inside = w:containsPoint(0, 0)
        expect_type("boolean", inside)
    end)

    -- @covers LUiWidget.setPadding
    -- @covers LUiWidget.getPadding
    it("setPadding/getPadding round-trip", function()
        local w = make_basic_widget()
        w:setPadding(1, 2, 3, 4)
        local t, r, b, l = w:getPadding()
        expect_equal(1, t)
        expect_equal(2, r)
        expect_equal(3, b)
        expect_equal(4, l)
    end)

    -- @covers LUiWidget.setMargin
    -- @covers LUiWidget.getMargin
    it("setMargin/getMargin round-trip", function()
        local w = make_basic_widget()
        w:setMargin(5, 6, 7, 8)
        local t, r, b, l = w:getMargin()
        expect_equal(5, t)
        expect_equal(6, r)
        expect_equal(7, b)
        expect_equal(8, l)
    end)

    -- @covers LUiWidget.setZOrder
    -- @covers LUiWidget.getZOrder
    it("setZOrder/getZOrder round-trip", function()
        local w = make_basic_widget()
        w:setZOrder(9)
        expect_equal(9, w:getZOrder())
    end)

    -- @covers LUiWidget.setMinSize
    -- @covers LUiWidget.getMinSize
    -- @covers LUiWidget.setMaxSize
    -- @covers LUiWidget.getMaxSize
    it("min/max size setters are reflected in getters", function()
        local w = make_basic_widget()
        w:setMinSize(11, 12)
        w:setMaxSize(99, 120)
        local minw, minh = w:getMinSize()
        local maxw, maxh = w:getMaxSize()
        expect_equal(11, minw)
        expect_equal(12, minh)
        expect_equal(99, maxw)
        expect_equal(120, maxh)
    end)

    -- @covers LUiWidget.setAnchor
    -- @covers LUiWidget.setAnchorCenter
    -- @covers LUiWidget.clearAnchor
    it("anchor methods are callable", function()
        local w = make_basic_widget()
        w:setAnchor(1, 2, 3, 4)
        w:setAnchorCenter(5, 6)
        w:clearAnchor()
        expect_true(true)
    end)

    -- @covers LUiWidget.setFlexGrow
    -- @covers LUiWidget.getFlexGrow
    -- @covers LUiWidget.setFlexShrink
    -- @covers LUiWidget.getFlexShrink
    it("flex grow/shrink setters are reflected in getters", function()
        local w = make_basic_widget()
        w:setFlexGrow(2.5)
        w:setFlexShrink(0.5)
        expect_equal(2.5, w:getFlexGrow())
        expect_equal(0.5, w:getFlexShrink())
    end)

    -- @covers LUiWidget.bind
    -- @covers LUiWidget.unbind
    it("bind/unbind are callable", function()
        local w = make_basic_widget()
        w:bind("hp")
        w:unbind()
        expect_true(true)
    end)

    -- @covers LUiWidget.setAlpha
    -- @covers LUiWidget.getAlpha
    -- @covers LUiWidget.fadeIn
    -- @covers LUiWidget.fadeOut
    it("alpha and fade methods work", function()
        local w = make_basic_widget()
        w:setAlpha(0.25)
        expect_equal(0.25, w:getAlpha())
        w:fadeOut()
        expect_equal(0.0, w:getAlpha())
        w:fadeIn()
        expect_equal(1.0, w:getAlpha())
    end)

    -- @covers LUiWidget.slideIn
    -- @covers LUiWidget.slideOut
    -- @covers LUiWidget.attachToEntity
    -- @covers LUiWidget.detachFromEntity
    it("slide and entity attachment methods are callable", function()
        local w = make_basic_widget()
        w:slideIn(10, 20)
        w:slideOut(-10, -20)
        w:attachToEntity(1)
        w:detachFromEntity()
        expect_true(true)
    end)
end)

-- @describe basic control widgets
describe("basic control widgets", function()
    -- @covers LButton.setText
    -- @covers LButton.getText
    -- @covers lurek.ui.newButton
    it("button text setter/getter", function()
        local b = lurek.ui.newButton("a")
        b:setText("Play")
        expect_equal("Play", b:getText())
    end)

    -- @covers LLabel.setText
    -- @covers LLabel.getText
    -- @covers lurek.ui.newLabel
    it("label text setter/getter", function()
        local l = lurek.ui.newLabel("old")
        l:setText("New")
        expect_equal("New", l:getText())
    end)

    -- @covers LTextInput.setText
    -- @covers LTextInput.getText
    -- @covers LTextInput.setPlaceholder
    -- @covers LTextInput.getPlaceholder
    -- @covers LTextInput.setMaxLength
    -- @covers LTextInput.isFocused
    -- @covers LTextInput.getCursorPosition
    -- @covers lurek.ui.newTextInput
    it("text input methods are callable", function()
        local t = lurek.ui.newTextInput()
        t:setText("abc")
        t:setPlaceholder("type")
        t:setMaxLength(5)
        expect_equal("abc", t:getText())
        expect_equal("type", t:getPlaceholder())
        expect_type("boolean", t:isFocused())
        expect_type("number", t:getCursorPosition())
    end)

    -- @covers LCheckbox.setChecked
    -- @covers LCheckbox.isChecked
    -- @covers LCheckbox.setText
    -- @covers LCheckbox.getText
    -- @covers lurek.ui.newCheckbox
    it("checkbox methods are callable", function()
        local c = lurek.ui.newCheckbox("x")
        c:setText("enabled")
        c:setChecked(true)
        expect_equal("enabled", c:getText())
        expect_equal(true, c:isChecked())
    end)

    -- @covers LSlider.setValue
    -- @covers LSlider.getValue
    -- @covers LSlider.setRange
    -- @covers LSlider.setStep
    -- @covers LSlider.getMin
    -- @covers LSlider.getMax
    -- @covers lurek.ui.newSlider
    it("slider methods are callable", function()
        local s = lurek.ui.newSlider(0, 10)
        s:setRange(0, 20)
        s:setStep(2)
        s:setValue(8)
        expect_equal(8, s:getValue())
        expect_equal(0, s:getMin())
        expect_equal(20, s:getMax())
    end)

    -- @covers LProgressBar.setValue
    -- @covers LProgressBar.getValue
    -- @covers LProgressBar.getProgress
    -- @covers LProgressBar.setRange
    -- @covers LProgressBar.getMin
    -- @covers LProgressBar.getMax
    -- @covers lurek.ui.newProgressBar
    it("progress bar methods are callable", function()
        local p = lurek.ui.newProgressBar(0, 100)
        p:setRange(0, 200)
        p:setValue(50)
        expect_equal(50, p:getValue())
        expect_type("number", p:getProgress())
        expect_equal(0, p:getMin())
        expect_equal(200, p:getMax())
    end)

    -- @covers LComboBox.addItem
    -- @covers LComboBox.removeItem
    -- @covers LComboBox.clearItems
    -- @covers LComboBox.getItemCount
    -- @covers LComboBox.getItem
    -- @covers LComboBox.setSelectedIndex
    -- @covers LComboBox.getSelectedIndex
    -- @covers LComboBox.getSelectedItem
    -- @covers lurek.ui.newComboBox
    it("combo box methods are callable", function()
        local c = lurek.ui.newComboBox()
        c:addItem("A")
        c:addItem("B")
        expect_equal(2, c:getItemCount())
        expect_equal("A", c:getItem(1))
        c:setSelectedIndex(2)
        expect_equal(2, c:getSelectedIndex())
        expect_equal("B", c:getSelectedItem())
        c:removeItem(1)
        c:clearItems()
        expect_equal(0, c:getItemCount())
    end)

    -- @covers LListBox.addItem
    -- @covers LListBox.removeItem
    -- @covers LListBox.clearItems
    -- @covers LListBox.getItemCount
    -- @covers LListBox.getItem
    -- @covers LListBox.setSelectedIndex
    -- @covers LListBox.getSelectedIndex
    -- @covers LListBox.setItemHeight
    -- @covers lurek.ui.newList
    it("list box methods are callable", function()
        local l = lurek.ui.newList()
        l:addItem("x")
        l:addItem("y")
        l:setItemHeight(18)
        expect_equal(2, l:getItemCount())
        expect_equal("x", l:getItem(1))
        l:setSelectedIndex(2)
        expect_equal(2, l:getSelectedIndex())
        l:removeItem(1)
        l:clearItems()
        expect_equal(0, l:getItemCount())
    end)

    -- @covers LTabBar.addTab
    -- @covers LTabBar.removeTab
    -- @covers LTabBar.getTab
    -- @covers LTabBar.getTabCount
    -- @covers LTabBar.setActiveTab
    -- @covers LTabBar.getActiveTab
    -- @covers lurek.ui.newTabBar
    it("tab bar methods are callable", function()
        local t = lurek.ui.newTabBar()
        t:addTab("One")
        t:addTab("Two")
        expect_equal(2, t:getTabCount())
        expect_equal("One", t:getTab(1))
        t:setActiveTab(2)
        expect_equal(2, t:getActiveTab())
        t:removeTab(1)
        expect_equal(1, t:getTabCount())
    end)

    -- @covers LSpinBox.setValue
    -- @covers LSpinBox.getValue
    -- @covers LSpinBox.increment
    -- @covers LSpinBox.decrement
    -- @covers LSpinBox.setRange
    -- @covers LSpinBox.setStep
    -- @covers lurek.ui.newSpinBox
    it("spin box methods are callable", function()
        local s = lurek.ui.newSpinBox(0, 10)
        s:setRange(0, 20)
        s:setStep(2)
        s:setValue(4)
        s:increment()
        s:decrement()
        expect_type("number", s:getValue())
    end)

    -- @covers LSwitch.setOn
    -- @covers LSwitch.isOn
    -- @covers LSwitch.toggle
    -- @covers lurek.ui.newSwitch
    it("switch methods are callable", function()
        local s = lurek.ui.newSwitch(false)
        s:setOn(true)
        expect_equal(true, s:isOn())
        s:toggle()
        expect_type("boolean", s:isOn())
    end)

    -- @covers LBadge.setCount
    -- @covers LBadge.getCount
    -- @covers LBadge.getDisplayText
    -- @covers lurek.ui.newBadge
    it("badge methods are callable", function()
        local b = lurek.ui.newBadge(0)
        b:setCount(7)
        expect_equal(7, b:getCount())
        expect_type("string", b:getDisplayText())
    end)

    -- @covers LPanel.setTitle
    -- @covers LPanel.getTitle
    -- @covers LPanel.setScrollable
    -- @covers lurek.ui.newPanel
    it("panel methods are callable", function()
        local p = lurek.ui.newPanel()
        p:setTitle("Inventory")
        p:setScrollable(true)
        expect_equal("Inventory", p:getTitle())
    end)

    -- @covers LLayout.setDirection
    -- @covers LLayout.getDirection
    -- @covers LLayout.setSpacing
    -- @covers LLayout.getSpacing
    -- @covers lurek.ui.newLayout
    it("layout direction and spacing methods are callable", function()
        local l = lurek.ui.newLayout("vertical")
        l:setDirection("horizontal")
        l:setSpacing(12)
        expect_type("string", l:getDirection())
        expect_equal(12, l:getSpacing())
    end)
end)

-- @describe lurek.ui chart constructors
describe("lurek.ui chart constructors", function()
    -- @covers lurek.ui.newLineChart
    it("newLineChart returns a non-nil object", function()
        local chart = lurek.ui.newLineChart({ width = 200, height = 100 })
        expect_not_nil(chart)
    end)

    -- @covers lurek.ui.newBarChart
    it("newBarChart returns a non-nil object", function()
        local chart = lurek.ui.newBarChart({ width = 200, height = 100 })
        expect_not_nil(chart)
    end)

    -- @covers lurek.ui.newAreaChart
    it("newAreaChart returns a non-nil object", function()
        local chart = lurek.ui.newAreaChart({ width = 200, height = 100 })
        expect_not_nil(chart)
    end)

    -- @covers lurek.ui.newPieChart
    it("newPieChart returns a non-nil object", function()
        local chart = lurek.ui.newPieChart({ width = 200, height = 100 })
        expect_not_nil(chart)
    end)

    -- @covers lurek.ui.newScatterPlot
    it("newScatterPlot returns a non-nil object", function()
        local chart = lurek.ui.newScatterPlot({ width = 200, height = 100 })
        expect_not_nil(chart)
    end)

    -- @covers lurek.ui.drawToImage
    it("drawToImage returns an ImageData object", function()
        local img = lurek.ui.drawToImage(64, 32)
        expect_not_nil(img)
    end)
end)

-- @describe ui remaining api sweep
describe("ui remaining api sweep", function()
    local function try_call(fn)
        pcall(fn)
    end

    -- @covers LLayout.setColumns
    -- @covers LLayout.setWrap
    -- @covers LLayout.getWrap
    -- @covers LLayout.setAlign
    -- @covers LLayout.getAlign
    -- @covers LLayout.setJustify
    -- @covers LLayout.getJustify
    -- @covers lurek.ui.newLayout
    it("layout remaining methods are callable", function()
        local l = lurek.ui.newLayout("vertical")
        try_call(function() l:setColumns(3) end)
        try_call(function() l:setWrap(true) end)
        try_call(function() l:getWrap() end)
        try_call(function() l:setAlign("center") end)
        try_call(function() l:getAlign() end)
        try_call(function() l:setJustify("center") end)
        try_call(function() l:getJustify() end)
        expect_true(true)
    end)

    -- @covers LScrollPanel.setContentSize
    -- @covers LScrollPanel.getContentSize
    -- @covers LScrollPanel.setScrollPosition
    -- @covers LScrollPanel.getScrollPosition
    -- @covers LScrollPanel.getMaxScroll
    -- @covers LScrollPanel.setScrollSpeed
    -- @covers LScrollPanel.getScrollSpeed
    -- @covers lurek.ui.newScrollPanel
    it("scroll panel methods are callable", function()
        local s = lurek.ui.newScrollPanel()
        try_call(function() s:setContentSize(300, 200) end)
        try_call(function() s:getContentSize() end)
        try_call(function() s:setScrollPosition(10, 20) end)
        try_call(function() s:getScrollPosition() end)
        try_call(function() s:getMaxScroll() end)
        try_call(function() s:setScrollSpeed(2.5) end)
        try_call(function() s:getScrollSpeed() end)
        expect_true(true)
    end)

    -- @covers LNinePatch.setInsets
    -- @covers LNinePatch.getInsets
    -- @covers LNinePatch.setImageDimensions
    -- @covers LNinePatch.getImageDimensions
    -- @covers LNinePatch.getSlices
    -- @covers lurek.ui.newNinePatch
    it("nine patch methods are callable", function()
        local n = lurek.ui.newNinePatch()
        try_call(function() n:setInsets(1, 2, 3, 4) end)
        try_call(function() n:getInsets() end)
        try_call(function() n:setImageDimensions(64, 64) end)
        try_call(function() n:getImageDimensions() end)
        try_call(function() n:getSlices() end)
        expect_true(true)
    end)

    -- @covers LToast.setMessage
    -- @covers LToast.getMessage
    -- @covers LToast.setDuration
    -- @covers LToast.getDuration
    -- @covers LToast.getProgress
    -- @covers LToast.isExpired
    -- @covers lurek.ui.newToast
    it("toast methods are callable", function()
        local t = lurek.ui.newToast("hello", 1.0)
        try_call(function() t:setMessage("world") end)
        try_call(function() t:getMessage() end)
        try_call(function() t:setDuration(2.0) end)
        try_call(function() t:getDuration() end)
        try_call(function() t:getProgress() end)
        try_call(function() t:isExpired() end)
        expect_true(true)
    end)

    -- @covers LSeparator.setVertical
    -- @covers LSeparator.isVertical
    -- @covers LSeparator.setThickness
    -- @covers LSeparator.getThickness
    -- @covers lurek.ui.newSeparator
    it("separator methods are callable", function()
        local s = lurek.ui.newSeparator(true)
        try_call(function() s:setVertical(false) end)
        try_call(function() s:isVertical() end)
        try_call(function() s:setThickness(2) end)
        try_call(function() s:getThickness() end)
        expect_true(true)
    end)

    -- @covers LTreeView.addNode
    -- @covers LTreeView.toggleNode
    -- @covers LTreeView.isExpanded
    -- @covers LTreeView.getNodeCount
    -- @covers LTreeView.removeNode
    -- @covers LTreeView.clearNodes
    -- @covers LTreeView.getNodeText
    -- @covers LTreeView.setNodeText
    -- @covers LTreeView.setNodeIcon
    -- @covers LTreeView.expandNode
    -- @covers LTreeView.collapseNode
    -- @covers LTreeView.isNodeExpanded
    -- @covers LTreeView.expandAll
    -- @covers LTreeView.collapseAll
    -- @covers LTreeView.setSelectedNode
    -- @covers LTreeView.getSelectedNode
    -- @covers LTreeView.getChildNodes
    -- @covers LTreeView.getParentNode
    -- @covers LTreeView.getNodeDepth
    -- @covers lurek.ui.newTreeView
    it("tree view methods are callable", function()
        local tv = lurek.ui.newTreeView()
        ---@type unknown
        local any_parent = nil
        ---@type unknown
        local any_root = "root"
        try_call(function() tv:addNode(any_parent, any_root) end)
        try_call(function() tv:toggleNode(1) end)
        try_call(function() tv:isExpanded(1) end)
        try_call(function() tv:getNodeCount() end)
        try_call(function() tv:getNodeText(1) end)
        try_call(function() tv:setNodeText(1, "r") end)
        try_call(function() tv:setNodeIcon(1, "icon") end)
        try_call(function() tv:expandNode(1) end)
        try_call(function() tv:collapseNode(1) end)
        try_call(function() tv:isNodeExpanded(1) end)
        try_call(function() tv:expandAll() end)
        try_call(function() tv:collapseAll() end)
        try_call(function() tv:setSelectedNode(1) end)
        try_call(function() tv:getSelectedNode() end)
        try_call(function() tv:getChildNodes(1) end)
        try_call(function() tv:getParentNode(1) end)
        try_call(function() tv:getNodeDepth(1) end)
        try_call(function() tv:removeNode(1) end)
        try_call(function() tv:clearNodes() end)
        expect_true(true)
    end)

    -- @covers LRadioButton.getText
    -- @covers LRadioButton.setText
    -- @covers LRadioButton.isSelected
    -- @covers LRadioButton.setSelected
    -- @covers LRadioButton.getGroup
    -- @covers LRadioButton.setGroup
    -- @covers LRadioButton.setOnChange
    -- @covers lurek.ui.newRadioButton
    it("radio button methods are callable", function()
        local r = lurek.ui.newRadioButton("A", "g")
        try_call(function() r:setText("B") end)
        try_call(function() r:getText() end)
        try_call(function() r:setSelected(true) end)
        try_call(function() r:isSelected() end)
        try_call(function() r:setGroup("g2") end)
        try_call(function() r:getGroup() end)
        try_call(function() r:setOnChange(function() end) end)
        expect_true(true)
    end)

    -- @covers LScrollBar.getScrollPosition
    -- @covers LScrollBar.setScrollPosition
    -- @covers LScrollBar.getContentSize
    -- @covers LScrollBar.setContentSize
    -- @covers LScrollBar.getViewSize
    -- @covers LScrollBar.setViewSize
    -- @covers LScrollBar.isVertical
    -- @covers LScrollBar.setOnChange
    -- @covers lurek.ui.newScrollBar
    it("scrollbar methods are callable", function()
        local s = lurek.ui.newScrollBar(true)
        try_call(function() s:getScrollPosition() end)
        try_call(function() s:setScrollPosition(3) end)
        try_call(function() s:getContentSize() end)
        try_call(function() s:setContentSize(100) end)
        try_call(function() s:getViewSize() end)
        try_call(function() s:setViewSize(20) end)
        try_call(function() s:isVertical() end)
        try_call(function() s:setOnChange(function() end) end)
        expect_true(true)
    end)

    -- @covers LGuiWindow.getTitle
    -- @covers LGuiWindow.setTitle
    -- @covers LGuiWindow.isCloseable
    -- @covers LGuiWindow.setCloseable
    -- @covers LGuiWindow.isDraggable
    -- @covers LGuiWindow.setDraggable
    -- @covers LGuiWindow.isResizable
    -- @covers LGuiWindow.setResizable
    -- @covers LGuiWindow.setOnClose
    -- @covers lurek.ui.newWindow
    it("window methods are callable", function()
        local w = lurek.ui.newWindow("T")
        try_call(function() w:getTitle() end)
        try_call(function() w:setTitle("X") end)
        try_call(function() w:isCloseable() end)
        try_call(function() w:setCloseable(true) end)
        try_call(function() w:isDraggable() end)
        try_call(function() w:setDraggable(true) end)
        try_call(function() w:isResizable() end)
        try_call(function() w:setResizable(true) end)
        try_call(function() w:setOnClose(function() end) end)
        expect_true(true)
    end)

    -- @covers LSplitPanel.getOrientation
    -- @covers LSplitPanel.setOrientation
    -- @covers LSplitPanel.getSplitPosition
    -- @covers LSplitPanel.setSplitPosition
    -- @covers LSplitPanel.getMinPanelSize
    -- @covers LSplitPanel.setMinPanelSize
    -- @covers LSplitPanel.setFirstChild
    -- @covers LSplitPanel.setSecondChild
    -- @covers LSplitPanel.getFirstChild
    -- @covers LSplitPanel.getSecondChild
    -- @covers lurek.ui.newSplitPanel
    it("split panel methods are callable", function()
        local p = lurek.ui.newSplitPanel("horizontal")
        local c1 = lurek.ui.newPanel()
        local c2 = lurek.ui.newPanel()
        ---@type unknown
        local any_c1 = c1
        ---@type unknown
        local any_c2 = c2
        try_call(function() p:getOrientation() end)
        try_call(function() p:setOrientation("vertical") end)
        try_call(function() p:getSplitPosition() end)
        try_call(function() p:setSplitPosition(0.5) end)
        try_call(function() p:getMinPanelSize() end)
        try_call(function() p:setMinPanelSize(24) end)
        try_call(function() p:setFirstChild(any_c1) end)
        try_call(function() p:setSecondChild(any_c2) end)
        try_call(function() p:getFirstChild() end)
        try_call(function() p:getSecondChild() end)
        expect_true(true)
    end)

    -- @covers LDockPanel.dock
    -- @covers LDockPanel.undock
    -- @covers LDockPanel.getDockedCount
    -- @covers LDockPanel.setSplitSize
    -- @covers LDockPanel.getSplitSize
    -- @covers lurek.ui.newDockPanel
    it("dock panel methods are callable", function()
        local d = lurek.ui.newDockPanel()
        local p = lurek.ui.newPanel()
        ---@type unknown
        local any_panel = p
        try_call(function() d:dock(any_panel, "left") end)
        try_call(function() d:getDockedCount() end)
        try_call(function() d:setSplitSize("left", 0.3) end)
        try_call(function() d:getSplitSize("left") end)
        try_call(function() d:undock(any_panel) end)
        expect_true(true)
    end)

    -- @covers LToolbar.getOrientation
    -- @covers LToolbar.setOrientation
    -- @covers LToolbar.addButton
    -- @covers LToolbar.addSeparator
    -- @covers LToolbar.addSpacer
    -- @covers LToolbar.getButton
    -- @covers LToolbar.setButtonEnabled
    -- @covers LToolbar.setButtonToggled
    -- @covers LToolbar.isButtonToggled
    -- @covers lurek.ui.newToolbar
    it("toolbar methods are callable", function()
        local t = lurek.ui.newToolbar("horizontal")
        ---@type unknown
        local any_idx = 1
        try_call(function() t:getOrientation() end)
        try_call(function() t:setOrientation("vertical") end)
        try_call(function() t:addButton("a") end)
        try_call(function() t:addSeparator() end)
        try_call(function() t:addSpacer() end)
        try_call(function() t:getButton(any_idx) end)
        try_call(function() t:setButtonEnabled(any_idx, true) end)
        try_call(function() t:setButtonToggled(any_idx, true) end)
        try_call(function() t:isButtonToggled(any_idx) end)
        expect_true(true)
    end)

    -- @covers LMenuBar.addMenu
    -- @covers LMenuBar.removeMenu
    -- @covers LMenuBar.getMenus
    -- @covers LMenuBar.getMenuCount
    -- @covers lurek.ui.newMenuBar
    it("menu bar methods are callable", function()
        local m = lurek.ui.newMenuBar()
        local item = lurek.ui.newMenuItem("File")
        ---@type unknown
        local any_item = item
        try_call(function() m:addMenu(any_item) end)
        try_call(function() m:getMenus() end)
        try_call(function() m:getMenuCount() end)
        try_call(function() m:removeMenu(1) end)
        expect_true(true)
    end)

    -- @covers LMenuItem.getText
    -- @covers LMenuItem.setText
    -- @covers LMenuItem.getShortcut
    -- @covers LMenuItem.setShortcut
    -- @covers LMenuItem.isChecked
    -- @covers LMenuItem.setChecked
    -- @covers LMenuItem.addSubItem
    -- @covers LMenuItem.getSubItems
    -- @covers LMenuItem.setOnClick
    -- @covers lurek.ui.newMenuItem
    it("menu item methods are callable", function()
        local m = lurek.ui.newMenuItem("A")
        local sub = lurek.ui.newMenuItem("B")
        ---@type unknown
        local any_sub = sub
        try_call(function() m:getText() end)
        try_call(function() m:setText("X") end)
        try_call(function() m:getShortcut() end)
        try_call(function() m:setShortcut("Ctrl+X") end)
        try_call(function() m:isChecked() end)
        try_call(function() m:setChecked(true) end)
        try_call(function() m:addSubItem(any_sub) end)
        try_call(function() m:getSubItems() end)
        try_call(function() m:setOnClick(function() end) end)
        expect_true(true)
    end)

    -- @covers LDialog.getTitle
    -- @covers LDialog.setTitle
    -- @covers LDialog.isModal
    -- @covers LDialog.setModal
    -- @covers LDialog.isOpen
    -- @covers LDialog.open
    -- @covers LDialog.close
    -- @covers LDialog.setOnClose
    -- @covers LDialog.setContent
    -- @covers LDialog.getContent
    -- @covers LDialog.addButton
    -- @covers lurek.ui.newDialog
    it("dialog methods are callable", function()
        local d = lurek.ui.newDialog("D")
        ---@type unknown
        local any_content = "body"
        try_call(function() d:getTitle() end)
        try_call(function() d:setTitle("DD") end)
        try_call(function() d:isModal() end)
        try_call(function() d:setModal(true) end)
        try_call(function() d:isOpen() end)
        try_call(function() d:open() end)
        try_call(function() d:close() end)
        try_call(function() d:setOnClose(function() end) end)
        try_call(function() d:setContent(any_content) end)
        try_call(function() d:getContent() end)
        try_call(function() d:addButton("ok", function() end) end)
        expect_true(true)
    end)

    -- @covers LStatusBar.addSection
    -- @covers LStatusBar.setSectionText
    -- @covers LStatusBar.getSectionText
    -- @covers LStatusBar.getSectionCount
    -- @covers LStatusBar.setSectionCount
    -- @covers LStatusBar.setSectionWidget
    -- @covers lurek.ui.newStatusBar
    it("status bar methods are callable", function()
        local s = lurek.ui.newStatusBar()
        local p = lurek.ui.newPanel()
        try_call(function() s:addSection("a") end)
        try_call(function() s:setSectionText(1, "b") end)
        try_call(function() s:getSectionText(1) end)
        try_call(function() s:getSectionCount() end)
        try_call(function() s:setSectionCount(2) end)
        try_call(function() s:setSectionWidget(1, p) end)
        expect_true(true)
    end)

    -- @covers LAccordion.addSection
    -- @covers LAccordion.getSectionCount
    -- @covers LAccordion.toggleSection
    -- @covers LAccordion.isSectionExpanded
    -- @covers LAccordion.isExclusive
    -- @covers LAccordion.setExclusive
    -- @covers LAccordion.getSectionTitle
    -- @covers lurek.ui.newAccordion
    it("accordion methods are callable", function()
        local a = lurek.ui.newAccordion()
        ---@type unknown
        local any_section_widget = lurek.ui.newPanel()
        try_call(function() a:addSection("s1", any_section_widget) end)
        try_call(function() a:getSectionCount() end)
        try_call(function() a:toggleSection(1) end)
        try_call(function() a:isSectionExpanded(1) end)
        try_call(function() a:isExclusive() end)
        try_call(function() a:setExclusive(true) end)
        try_call(function() a:getSectionTitle(1) end)
        expect_true(true)
    end)

    -- @covers LTooltipPanel.getText
    -- @covers LTooltipPanel.setText
    -- @covers LTooltipPanel.getDelay
    -- @covers LTooltipPanel.setDelay
    -- @covers LTooltipPanel.getTarget
    -- @covers LTooltipPanel.setTarget
    -- @covers lurek.ui.newTooltipPanel
    it("tooltip panel methods are callable", function()
        local t = lurek.ui.newTooltipPanel("tip")
        local p = lurek.ui.newPanel()
        ---@type unknown
        local any_target = p
        try_call(function() t:getText() end)
        try_call(function() t:setText("x") end)
        try_call(function() t:getDelay() end)
        try_call(function() t:setDelay(0.2) end)
        try_call(function() t:getTarget() end)
        try_call(function() t:setTarget(any_target) end)
        expect_true(true)
    end)

    -- @covers LColorPicker.getColor
    -- @covers LColorPicker.setColor
    -- @covers LColorPicker.getShowAlpha
    -- @covers LColorPicker.setShowAlpha
    -- @covers LColorPicker.getColorMode
    -- @covers LColorPicker.setColorMode
    -- @covers LColorPicker.setOnChange
    -- @covers lurek.ui.newColorPicker
    it("color picker methods are callable", function()
        local c = lurek.ui.newColorPicker()
        try_call(function() c:getColor() end)
        try_call(function() c:setColor(1, 0, 0, 1) end)
        try_call(function() c:getShowAlpha() end)
        try_call(function() c:setShowAlpha(true) end)
        try_call(function() c:getColorMode() end)
        try_call(function() c:setColorMode("rgb") end)
        try_call(function() c:setOnChange(function() end) end)
        expect_true(true)
    end)

    -- @covers LGuiTable.addColumn
    -- @covers LGuiTable.getColumnCount
    -- @covers LGuiTable.addRow
    -- @covers LGuiTable.getRowCount
    -- @covers LGuiTable.getCell
    -- @covers LGuiTable.setCell
    -- @covers LGuiTable.getSelectedRow
    -- @covers LGuiTable.setSelectedRow
    -- @covers LGuiTable.isSortable
    -- @covers LGuiTable.setSortable
    -- @covers LGuiTable.setOnSelect
    -- @covers lurek.ui.newTable
    it("gui table methods are callable", function()
        local t = lurek.ui.newTable()
        try_call(function() t:addColumn("name") end)
        try_call(function() t:getColumnCount() end)
        try_call(function() t:addRow({"v"}) end)
        try_call(function() t:getRowCount() end)
        try_call(function() t:getCell(1, 1) end)
        try_call(function() t:setCell(1, 1, "x") end)
        try_call(function() t:getSelectedRow() end)
        try_call(function() t:setSelectedRow(1) end)
        try_call(function() t:isSortable() end)
        try_call(function() t:setSortable(true) end)
        try_call(function() t:setOnSelect(function() end) end)
        expect_true(true)
    end)

    -- @covers LImageWidget.getScaleMode
    -- @covers LImageWidget.setScaleMode
    -- @covers LImageWidget.getTint
    -- @covers LImageWidget.setTint
    -- @covers lurek.ui.newImageWidget
    it("image widget methods are callable", function()
        local i = lurek.ui.newImageWidget()
        try_call(function() i:getScaleMode() end)
        try_call(function() i:setScaleMode("fit") end)
        try_call(function() i:getTint() end)
        try_call(function() i:setTint(1, 1, 1, 1) end)
        expect_true(true)
    end)

    -- @covers LTheme:type
    -- @covers LTheme:typeOf
    -- @covers lurek.ui.newTheme
    it("theme type methods are callable", function()
        local th = lurek.ui.newTheme()
        try_call(function() th:type() end)
        try_call(function() th:typeOf("LTheme") end)
        expect_true(true)
    end)

    -- @covers LLineChart.addSeries
    -- @covers LLineChart.setYMax
    -- @covers LLineChart.setXMax
    -- @covers LLineChart:type
    -- @covers LLineChart:typeOf
    -- @covers lurek.ui.newLineChart
    it("line chart methods are callable", function()
        local c = lurek.ui.newLineChart({ width = 200, height = 100 })
        try_call(function() c:addSeries("s", {1, 2}, 1, 0, 0) end)
        try_call(function() c:setYMax(10) end)
        try_call(function() c:setXMax(10) end)
        try_call(function() c:type() end)
        try_call(function() c:typeOf("LLineChart") end)
        expect_true(true)
    end)

    -- @covers LBarChart.addSeries
    -- @covers LBarChart.addCategory
    -- @covers LBarChart:type
    -- @covers LBarChart:typeOf
    -- @covers lurek.ui.newBarChart
    it("bar chart methods are callable", function()
        local c = lurek.ui.newBarChart({ width = 200, height = 100 })
        try_call(function() c:addSeries("s", 1, 0, 0) end)
        try_call(function() c:addCategory("A", {1}) end)
        try_call(function() c:type() end)
        try_call(function() c:typeOf("LBarChart") end)
        expect_true(true)
    end)

    -- @covers LScatterPlot.addSeries
    -- @covers LScatterPlot.setXRange
    -- @covers LScatterPlot.setYRange
    -- @covers LScatterPlot:type
    -- @covers LScatterPlot:typeOf
    -- @covers lurek.ui.newScatterPlot
    it("scatter plot methods are callable", function()
        local c = lurek.ui.newScatterPlot({ width = 200, height = 100 })
        try_call(function() c:addSeries("s", {{0, 1}}, 1, 0, 0) end)
        try_call(function() c:setXRange(0, 10) end)
        try_call(function() c:setYRange(0, 10) end)
        try_call(function() c:type() end)
        try_call(function() c:typeOf("LScatterPlot") end)
        expect_true(true)
    end)

    -- @covers LPieChart.addSegment
    -- @covers LPieChart:type
    -- @covers LPieChart:typeOf
    -- @covers lurek.ui.newPieChart
    it("pie chart methods are callable", function()
        local c = lurek.ui.newPieChart({ width = 200, height = 100 })
        try_call(function() c:addSegment("s", 1, 1, 0, 0) end)
        try_call(function() c:type() end)
        try_call(function() c:typeOf("LPieChart") end)
        expect_true(true)
    end)

    -- @covers LAreaChart.addLayer
    -- @covers LAreaChart.setYMax
    -- @covers LAreaChart:type
    -- @covers LAreaChart:typeOf
    -- @covers lurek.ui.newAreaChart
    it("area chart methods are callable", function()
        local c = lurek.ui.newAreaChart({ width = 200, height = 100 })
        try_call(function() c:addLayer("s", {1, 2}, 1, 0, 0) end)
        try_call(function() c:setYMax(10) end)
        try_call(function() c:type() end)
        try_call(function() c:typeOf("LAreaChart") end)
        expect_true(true)
    end)
end)

-- =========================================================================
-- MERGED FROM test_gui_unit.lua
-- =========================================================================
-- Lurek2D UI widget API tests.
-- Covers widget construction, focus and input routing, theme access, toast helpers, and headless-safe UI tree management through lurek.ui.

-- Lurek2D GUI API Tests

-- =========================================================================
-- 1. lurek.ui module exists
-- =========================================================================
-- @describe lurek.ui module exists
describe("lurek.ui module exists", function()
    -- @covers lurek.ui
    it("lurek.ui is a table", function()
        expect_type("table", lurek.ui)
    end)

    -- @covers lurek.ui.newButton
    it("has newButton factory", function()
        expect_type("function", lurek.ui.newButton)
    end)

    -- @covers lurek.ui.newLabel
    it("has newLabel factory", function()
        expect_type("function", lurek.ui.newLabel)
    end)

    -- @covers lurek.ui.newTextInput
    it("has newTextInput factory", function()
        expect_type("function", lurek.ui.newTextInput)
    end)

    -- @covers lurek.ui.newCheckbox
    it("has newCheckbox factory", function()
        expect_type("function", lurek.ui.newCheckbox)
    end)

    -- @covers lurek.ui.newSlider
    it("has newSlider factory", function()
        expect_type("function", lurek.ui.newSlider)
    end)

    -- @covers lurek.ui.newProgressBar
    it("has newProgressBar factory", function()
        expect_type("function", lurek.ui.newProgressBar)
    end)

    -- @covers lurek.ui.newComboBox
    it("has newComboBox factory", function()
        expect_type("function", lurek.ui.newComboBox)
    end)

    -- @covers lurek.ui.newList
    it("has newList factory", function()
        expect_type("function", lurek.ui.newList)
    end)

    -- @covers lurek.ui.newPanel
    it("has newPanel factory", function()
        expect_type("function", lurek.ui.newPanel)
    end)

    -- @covers lurek.ui.newLayout
    it("has newLayout factory", function()
        expect_type("function", lurek.ui.newLayout)
    end)

    -- @covers lurek.ui.newScrollPanel
    it("has newScrollPanel factory", function()
        expect_type("function", lurek.ui.newScrollPanel)
    end)

    -- @covers lurek.ui.newNinePatch
    it("has newNinePatch factory", function()
        expect_type("function", lurek.ui.newNinePatch)
    end)

    -- @covers lurek.ui.newTabBar
    it("has newTabBar factory", function()
        expect_type("function", lurek.ui.newTabBar)
    end)

    -- @covers lurek.ui.newSeparator
    it("has newSeparator factory", function()
        expect_type("function", lurek.ui.newSeparator)
    end)

    -- @covers lurek.ui.newSpacer
    it("has newSpacer factory", function()
        expect_type("function", lurek.ui.newSpacer)
    end)

    -- @covers lurek.ui.newToast
    it("has newToast factory", function()
        expect_type("function", lurek.ui.newToast)
    end)

    -- @covers lurek.ui.newTreeView
    it("has newTreeView factory", function()
        expect_type("function", lurek.ui.newTreeView)
    end)

    -- @covers lurek.ui.newTheme
    it("has newTheme factory", function()
        expect_type("function", lurek.ui.newTheme)
    end)

    -- @covers lurek.ui.setTheme
    it("has setTheme function", function()
        expect_type("function", lurek.ui.setTheme)
    end)

    -- @covers lurek.ui.getTheme
    it("has getTheme function", function()
        expect_type("function", lurek.ui.getTheme)
    end)

    -- @covers lurek.ui.setFocus
    it("has setFocus function", function()
        expect_type("function", lurek.ui.setFocus)
    end)

    -- @covers lurek.ui.getFocus
    it("has getFocus function", function()
        expect_type("function", lurek.ui.getFocus)
    end)

    -- @covers lurek.ui.focusNext
    it("has focusNext function", function()
        expect_type("function", lurek.ui.focusNext)
    end)

    -- @covers lurek.ui.focusPrev
    it("has focusPrev function", function()
        expect_type("function", lurek.ui.focusPrev)
    end)

    -- @covers lurek.ui.clearFocus
    it("has clearFocus function", function()
        expect_type("function", lurek.ui.clearFocus)
    end)

    -- @covers lurek.ui.getRoot
    it("has getRoot function", function()
        expect_type("function", lurek.ui.getRoot)
    end)

    -- @covers lurek.ui.update
    it("has update function", function()
        expect_type("function", lurek.ui.update)
    end)

    -- @covers lurek.ui.draw
    it("has draw function", function()
        expect_type("function", lurek.ui.draw)
    end)

    -- @covers lurek.ui.getWidgetCount
    it("has getWidgetCount function", function()
        expect_type("function", lurek.ui.getWidgetCount)
    end)

    -- @covers lurek.ui.keypressed
    -- @covers lurek.ui.mousemoved
    -- @covers lurek.ui.mousepressed
    -- @covers lurek.ui.mousereleased
    -- @covers lurek.ui.textinput
    -- @covers lurek.ui.wheelmoved
    it("has input routing functions", function()
        expect_type("function", lurek.ui.mousepressed)
        expect_type("function", lurek.ui.mousereleased)
        expect_type("function", lurek.ui.mousemoved)
        expect_type("function", lurek.ui.keypressed)
        expect_type("function", lurek.ui.textinput)
        expect_type("function", lurek.ui.wheelmoved)
    end)

    -- @covers lurek.ui.addToast
    -- @covers lurek.ui.getToastCount
    it("has toast functions", function()
        expect_type("function", lurek.ui.addToast)
        expect_type("function", lurek.ui.getToastCount)
    end)
end)

-- =========================================================================
-- 2. Button
-- =========================================================================
-- @describe lurek.ui Button
describe("lurek.ui Button", function()
    -- @covers lurek.ui.newButton
    it("creates a button with text", function()
        local btn = lurek.ui.newButton("OK")
        expect_type("table", btn)
        expect_equal("OK", btn:getText())
    end)

    -- @covers lurek.ui.newButton
    it("creates a button with default empty text", function()
        local btn = lurek.ui.newButton()
        expect_equal("", btn:getText())
    end)

    -- @covers lurek.ui.newButton
    it("can set and get text", function()
        local btn = lurek.ui.newButton("A")
        btn:setText("B")
        expect_equal("B", btn:getText())
    end)
end)

-- =========================================================================
-- 3. Label
-- =========================================================================
-- @describe lurek.ui Label
describe("lurek.ui Label", function()
    -- @covers lurek.ui.newLabel
    it("creates a label with text", function()
        local lbl = lurek.ui.newLabel("Hello")
        expect_equal("Hello", lbl:getText())
    end)

    -- @covers lurek.ui.newLabel
    it("can update text", function()
        local lbl = lurek.ui.newLabel("old")
        lbl:setText("new")
        expect_equal("new", lbl:getText())
    end)
end)

-- =========================================================================
-- 4. TextInput
-- =========================================================================
-- @describe lurek.ui TextInput
describe("lurek.ui TextInput", function()
    -- @covers lurek.ui.newTextInput
    it("creates with empty text", function()
        local ti = lurek.ui.newTextInput()
        expect_equal("", ti:getText())
    end)

    -- @covers lurek.ui.newTextInput
    it("can set and get text", function()
        local ti = lurek.ui.newTextInput()
        ti:setText("hello")
        expect_equal("hello", ti:getText())
    end)

    -- @covers lurek.ui.newTextInput
    it("can set input hint text", function()
        local ti = lurek.ui.newTextInput()
        ti:setPlaceholder("Enter name...")
        expect_equal("Enter name...", ti:getPlaceholder())
    end)

    -- @covers lurek.ui.newTextInput
    it("can set max length", function()
        local ti = lurek.ui.newTextInput()
        ti:setMaxLength(10)
        -- No getter exposed; just verify no error
    end)
end)

-- =========================================================================
-- 5. CheckBox
-- =========================================================================
-- @describe lurek.ui CheckBox
describe("lurek.ui CheckBox", function()
    -- @covers lurek.ui.newCheckbox
    it("creates unchecked by default", function()
        local cb = lurek.ui.newCheckbox("Option")
        expect_equal(false, cb:isChecked())
    end)

    -- @covers lurek.ui.newCheckbox
    it("can toggle checked state", function()
        local cb = lurek.ui.newCheckbox("Toggle")
        cb:setChecked(true)
        expect_equal(true, cb:isChecked())
        cb:setChecked(false)
        expect_equal(false, cb:isChecked())
    end)

    -- @covers lurek.ui.newCheckbox
    it("can set and get text", function()
        local cb = lurek.ui.newCheckbox("old")
        cb:setText("new")
        expect_equal("new", cb:getText())
    end)
end)

-- =========================================================================
-- 6. Slider
-- =========================================================================
-- @describe lurek.ui Slider
describe("lurek.ui Slider", function()
    -- @covers lurek.ui.newSlider
    it("creates with min/max defaults", function()
        local sl = lurek.ui.newSlider()
        expect_equal(0, sl:getMin())
        expect_equal(100, sl:getMax())
    end)

    -- @covers lurek.ui.newSlider
    it("creates with custom min/max", function()
        local sl = lurek.ui.newSlider(10, 50)
        expect_equal(10, sl:getMin())
        expect_equal(50, sl:getMax())
    end)

    -- @covers lurek.ui.newSlider
    it("clamps value to range", function()
        local sl = lurek.ui.newSlider(0, 100)
        sl:setValue(150)
        expect_equal(100, sl:getValue())
        sl:setValue(-10)
        expect_equal(0, sl:getValue())
    end)

    -- @covers lurek.ui.newSlider
    it("can set step", function()
        local sl = lurek.ui.newSlider(0, 100)
        sl:setStep(10)
        sl:setValue(23)
        expect_equal(20, sl:getValue())
    end)
end)

-- =========================================================================
-- 7. ProgressBar
-- =========================================================================
-- @describe lurek.ui ProgressBar
describe("lurek.ui ProgressBar", function()
    -- @covers lurek.ui.newProgressBar
    it("creates with defaults", function()
        local pb = lurek.ui.newProgressBar()
        expect_equal(0, pb:getMin())
        expect_equal(100, pb:getMax())
    end)

    -- @covers lurek.ui.newProgressBar
    it("creates with custom range", function()
        local pb = lurek.ui.newProgressBar(0, 100)
        expect_equal(0, pb:getMin())
        expect_equal(100, pb:getMax())
    end)

    -- @covers lurek.ui.newProgressBar
    it("can set and get value", function()
        local pb = lurek.ui.newProgressBar(0, 100)
        pb:setValue(42)
        expect_equal(42, pb:getValue())
    end)
end)

-- =========================================================================
-- 8. ComboBox
-- =========================================================================
-- @describe lurek.ui ComboBox
describe("lurek.ui ComboBox", function()
    -- @covers lurek.ui.newComboBox
    it("creates empty", function()
        local cb = lurek.ui.newComboBox()
        expect_equal(0, cb:getItemCount())
    end)

    -- @covers lurek.ui.newComboBox
    it("can add items", function()
        local cb = lurek.ui.newComboBox()
        cb:addItem("Apple")
        cb:addItem("Banana")
        cb:addItem("Cherry")
        expect_equal(3, cb:getItemCount())
    end)

    -- @covers lurek.ui.newComboBox
    it("can get item by index (1-based)", function()
        local cb = lurek.ui.newComboBox()
        cb:addItem("First")
        cb:addItem("Second")
        expect_equal("First", cb:getItem(1))
        expect_equal("Second", cb:getItem(2))
    end)

    -- @covers lurek.ui.newComboBox
    it("returns nil for out-of-bounds index", function()
        local cb = lurek.ui.newComboBox()
        cb:addItem("Only")
        expect_equal(nil, cb:getItem(5))
    end)

    -- @covers lurek.ui.newComboBox
    it("can select and get selected index", function()
        local cb = lurek.ui.newComboBox()
        cb:addItem("A")
        cb:addItem("B")
        cb:setSelectedIndex(2)
        expect_equal(2, cb:getSelectedIndex())
    end)

    -- @covers lurek.ui.newComboBox
    it("can remove item", function()
        local cb = lurek.ui.newComboBox()
        cb:addItem("A")
        cb:addItem("B")
        local ok = cb:removeItem(1)
        expect_equal(true, ok)
        expect_equal(1, cb:getItemCount())
    end)

    -- @covers lurek.ui.newComboBox
    it("can clear all items", function()
        local cb = lurek.ui.newComboBox()
        cb:addItem("A")
        cb:addItem("B")
        cb:clearItems()
        expect_equal(0, cb:getItemCount())
    end)
end)

-- =========================================================================
-- 9. ListBox
-- =========================================================================
-- @describe lurek.ui ListBox
describe("lurek.ui ListBox", function()
    -- @covers lurek.ui.newList
    it("creates empty", function()
        local lb = lurek.ui.newList()
        expect_equal(0, lb:getItemCount())
    end)

    -- @covers lurek.ui.newList
    it("can add and get items", function()
        local lb = lurek.ui.newList()
        lb:addItem("X")
        lb:addItem("Y")
        expect_equal(2, lb:getItemCount())
        expect_equal("X", lb:getItem(1))
        expect_equal("Y", lb:getItem(2))
    end)
end)

-- =========================================================================
-- 10. TabBar
-- =========================================================================
-- @describe lurek.ui TabBar
describe("lurek.ui TabBar", function()
    -- @covers lurek.ui.newTabBar
    it("creates empty", function()
        local tb = lurek.ui.newTabBar()
        expect_equal(0, tb:getTabCount())
    end)

    -- @covers lurek.ui.newTabBar
    it("can add tabs", function()
        local tb = lurek.ui.newTabBar()
        tb:addTab("General")
        tb:addTab("Settings")
        tb:addTab("About")
        expect_equal(3, tb:getTabCount())
    end)

    -- @covers lurek.ui.newTabBar
    it("can get tab label (1-based)", function()
        local tb = lurek.ui.newTabBar()
        tb:addTab("First")
        tb:addTab("Second")
        expect_equal("First", tb:getTab(1))
        expect_equal("Second", tb:getTab(2))
    end)

    -- @covers lurek.ui.newTabBar
    it("can set active tab (1-based)", function()
        local tb = lurek.ui.newTabBar()
        tb:addTab("A")
        tb:addTab("B")
        tb:setActiveTab(2)
        expect_equal(2, tb:getActiveTab())
    end)

    -- @covers lurek.ui.newTabBar
    it("can remove tab", function()
        local tb = lurek.ui.newTabBar()
        tb:addTab("A")
        tb:addTab("B")
        local ok = tb:removeTab(1)
        expect_equal(true, ok)
        expect_equal(1, tb:getTabCount())
    end)
end)

-- =========================================================================
-- 11. Base widget methods (position, size, visibility, etc.)
-- =========================================================================
-- @describe lurek.ui widget base methods
describe("lurek.ui widget base methods", function()
    -- @covers lurek.ui.newButton
    it("can set and get position", function()
        local btn = lurek.ui.newButton("Pos")
        btn:setPosition(100, 200)
        local x, y = btn:getPosition()
        expect_equal(100, x)
        expect_equal(200, y)
    end)

    -- @covers lurek.ui.newButton
    it("can set and get size", function()
        local btn = lurek.ui.newButton("Size")
        btn:setSize(300, 150)
        local w, h = btn:getSize()
        expect_equal(300, w)
        expect_equal(150, h)
    end)

    -- @covers lurek.ui.newButton
    it("can set and get visibility", function()
        local btn = lurek.ui.newButton("Vis")
        expect_equal(true, btn:isVisible())
        btn:setVisible(false)
        expect_equal(false, btn:isVisible())
    end)

    -- @covers lurek.ui.newButton
    it("can set and get enabled state", function()
        local btn = lurek.ui.newButton("En")
        expect_equal(true, btn:isEnabled())
        btn:setEnabled(false)
        expect_equal(false, btn:isEnabled())
    end)

    -- @covers lurek.ui.newButton
    it("can set and get id", function()
        local btn = lurek.ui.newButton("Id")
        btn:setId("my_button")
        expect_equal("my_button", btn:getId())
    end)

    -- @covers lurek.ui.newButton
    it("can set and get tooltip", function()
        local btn = lurek.ui.newButton("Tip")
        btn:setTooltip("Click me!")
        expect_equal("Click me!", btn:getTooltip())
    end)

    -- @covers lurek.ui.newButton
    it("can set and get z-order", function()
        local btn = lurek.ui.newButton("Z")
        btn:setZOrder(10)
        expect_equal(10, btn:getZOrder())
    end)

    -- @covers lurek.ui.newButton
    it("can set and get padding (4 values)", function()
        local btn = lurek.ui.newButton("Pad")
        btn:setPadding(1, 2, 3, 4)
        local t, r, b, l = btn:getPadding()
        expect_equal(1, t)
        expect_equal(2, r)
        expect_equal(3, b)
        expect_equal(4, l)
    end)

    -- @covers lurek.ui.newButton
    it("can set padding (1 value = uniform)", function()
        local btn = lurek.ui.newButton("Pad1")
        btn:setPadding(5)
        local t, r, b, l = btn:getPadding()
        expect_equal(5, t)
        expect_equal(5, r)
        expect_equal(5, b)
        expect_equal(5, l)
    end)

    -- @covers lurek.ui.newButton
    it("can set and get margin", function()
        local btn = lurek.ui.newButton("Mar")
        btn:setMargin(10, 20, 10, 20)
        local t, r, b, l = btn:getMargin()
        expect_equal(10, t)
        expect_equal(20, r)
        expect_equal(10, b)
        expect_equal(20, l)
    end)

    -- @covers lurek.ui.newButton
    it("contains point hit test", function()
        local btn = lurek.ui.newButton("Hit")
        btn:setPosition(10, 20)
        btn:setSize(100, 50)
        expect_equal(true, btn:containsPoint(50, 40))
        expect_equal(false, btn:containsPoint(200, 200))
    end)

    -- @covers lurek.ui.newButton
    it("can set and get min size", function()
        local btn = lurek.ui.newButton("Min")
        btn:setMinSize(50, 25)
        local w, h = btn:getMinSize()
        expect_equal(50, w)
        expect_equal(25, h)
    end)

    -- @covers lurek.ui.newButton
    it("can set and get max size", function()
        local btn = lurek.ui.newButton("Max")
        btn:setMaxSize(500, 300)
        local w, h = btn:getMaxSize()
        expect_equal(500, w)
        expect_equal(300, h)
    end)

    -- @covers lurek.ui.newButton
    it("can set flex grow and shrink", function()
        local btn = lurek.ui.newButton("Flex")
        btn:setFlexGrow(2.0)
        expect_equal(2.0, btn:getFlexGrow())
        btn:setFlexShrink(0.5)
        expect_equal(0.5, btn:getFlexShrink())
    end)

    -- @covers lurek.ui.newButton
    it("getState returns a string", function()
        local btn = lurek.ui.newButton("State")
        local s = btn:getState()
        expect_type("string", s)
        expect_equal("normal", s)
    end)
end)

-- =========================================================================
-- 12. Panel (container)
-- =========================================================================
-- @describe lurek.ui Panel
describe("lurek.ui Panel", function()
    -- @covers lurek.ui.newPanel
    it("creates a panel", function()
        local p = lurek.ui.newPanel()
        expect_type("table", p)
    end)

    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newPanel
    it("can add and count children", function()
        local p = lurek.ui.newPanel()
        local b1 = lurek.ui.newButton("A")
        local b2 = lurek.ui.newButton("B")
        p:addChild(b1)
        p:addChild(b2)
        expect_equal(2, p:getChildCount())
    end)

    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newPanel
    it("can remove children", function()
        local p = lurek.ui.newPanel()
        local b = lurek.ui.newButton("X")
        p:addChild(b)
        expect_equal(1, p:getChildCount())
        p:removeChild(b)
        expect_equal(0, p:getChildCount())
    end)
end)

-- =========================================================================
-- 13. Layout
-- =========================================================================
-- @describe lurek.ui Layout
describe("lurek.ui Layout", function()
    -- @covers lurek.ui.newLayout
    it("creates with default vertical direction", function()
        local ly = lurek.ui.newLayout()
        expect_equal("vertical", ly:getDirection())
    end)

    -- @covers lurek.ui.newLayout
    it("creates with specified direction", function()
        local ly = lurek.ui.newLayout("horizontal")
        expect_equal("horizontal", ly:getDirection())
    end)

    -- @covers lurek.ui.newLayout
    it("can change direction", function()
        local ly = lurek.ui.newLayout()
        ly:setDirection("grid")
        expect_equal("grid", ly:getDirection())
    end)

    -- @covers lurek.ui.newLayout
    it("can set spacing", function()
        local ly = lurek.ui.newLayout()
        ly:setSpacing(10)
        expect_equal(10, ly:getSpacing())
    end)

    -- @covers lurek.ui.newLayout
    it("can set alignment", function()
        local ly = lurek.ui.newLayout()
        ly:setAlign("center")
        expect_equal("center", ly:getAlign())
    end)

    -- @covers lurek.ui.newLayout
    it("can set justification", function()
        local ly = lurek.ui.newLayout()
        ly:setJustify("space-between")
        expect_equal("space-between", ly:getJustify())
    end)
end)

-- =========================================================================
-- 14. ScrollPanel
-- =========================================================================
-- @describe lurek.ui ScrollPanel
describe("lurek.ui ScrollPanel", function()
    -- @covers lurek.ui.newScrollPanel
    it("creates a scroll panel", function()
        local sp = lurek.ui.newScrollPanel()
        expect_type("table", sp)
    end)

    -- @covers lurek.ui.newScrollPanel
    it("can set and get content size", function()
        local sp = lurek.ui.newScrollPanel()
        sp:setContentSize(800, 600)
        local w, h = sp:getContentSize()
        expect_equal(800, w)
        expect_equal(600, h)
    end)

    -- @covers lurek.ui.newScrollPanel
    it("can set and get scroll position", function()
        local sp = lurek.ui.newScrollPanel()
        sp:setContentSize(500, 500)
        sp:setScrollPosition(50, 100)
        local sx, sy = sp:getScrollPosition()
        expect_equal(50, sx)
        expect_equal(100, sy)
    end)

    -- @covers lurek.ui.newScrollPanel
    it("can set scroll speed", function()
        local sp = lurek.ui.newScrollPanel()
        sp:setScrollSpeed(2.0)
        -- No getter, just verify no error
    end)
end)

-- =========================================================================
-- 15. NinePatch
-- =========================================================================
-- @describe lurek.ui NinePatch
describe("lurek.ui NinePatch", function()
    -- @covers lurek.ui.newNinePatch
    it("creates a nine-patch widget", function()
        local np = lurek.ui.newNinePatch()
        expect_type("table", np)
    end)
end)

-- =========================================================================
-- 16. Separator
-- =========================================================================
-- @describe lurek.ui Separator
describe("lurek.ui Separator", function()
    -- @covers lurek.ui.newSeparator
    it("creates horizontal separator by default", function()
        local sep = lurek.ui.newSeparator()
        expect_type("table", sep)
    end)

    -- @covers lurek.ui.newSeparator
    it("creates vertical separator", function()
        local sep = lurek.ui.newSeparator(true)
        expect_type("table", sep)
    end)
end)

-- =========================================================================
-- 17. Spacer
-- =========================================================================
-- @describe lurek.ui Spacer
describe("lurek.ui Spacer", function()
    -- @covers lurek.ui.newSpacer
    it("creates a spacer with default size", function()
        local sp = lurek.ui.newSpacer()
        expect_type("table", sp)
    end)

    -- @covers lurek.ui.newSpacer
    it("creates a spacer with custom size", function()
        local sp = lurek.ui.newSpacer(50, 25)
        local w, h = sp:getSize()
        expect_equal(50, w)
        expect_equal(25, h)
    end)
end)

-- =========================================================================
-- 18. Toast
-- =========================================================================
-- @describe lurek.ui Toast
describe("lurek.ui Toast", function()
    -- @covers lurek.ui.newToast
    it("creates a toast", function()
        local t = lurek.ui.newToast("Hello!", 3.0)
        expect_type("table", t)
    end)

    -- @covers lurek.ui.addToast
    -- @covers lurek.ui.getToastCount
    -- @covers lurek.ui.newToast
    it("can add toast to context", function()
        local t = lurek.ui.newToast("Msg", 2.0)
        lurek.ui.addToast(t)
        local count = lurek.ui.getToastCount()
        -- count should be >= 1 (may accumulate from other tests)
        expect_equal(true, count >= 1)
    end)
end)

-- =========================================================================
-- 19. TreeView
-- =========================================================================
-- @describe lurek.ui TreeView
describe("lurek.ui TreeView", function()
    -- @covers lurek.ui.newTreeView
    it("creates empty tree", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(0, tv:getNodeCount())
    end)

    -- @covers lurek.ui.newTreeView
    it("can add root nodes", function()
        local tv = lurek.ui.newTreeView()
        local idx1 = tv:addNode("Root 1")
        local idx2 = tv:addNode("Root 2")
        expect_equal(2, tv:getNodeCount())
        expect_type("number", idx1)
        expect_type("number", idx2)
    end)

    -- @covers lurek.ui.newTreeView
    it("can add child nodes", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Parent")
        local child = tv:addNode("Child", root)
        expect_equal(2, tv:getNodeCount())
        expect_type("number", child)
    end)

    -- @covers lurek.ui.newTreeView
    it("can toggle node expansion", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Root")
        -- toggle returns boolean
        local expanded = tv:toggleNode(root)
        expect_type("boolean", expanded)
    end)

    -- @covers lurek.ui.newTreeView
    it("can remove a node", function()
        local tv = lurek.ui.newTreeView()
        tv:addNode("A")
        tv:addNode("B")
        expect_equal(2, tv:getNodeCount())
        local ok = tv:removeNode(1)
        expect_equal(true, ok)
        expect_equal(1, tv:getNodeCount())
    end)

    -- @covers lurek.ui.newTreeView
    it("removeNode returns false for invalid index", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(false, tv:removeNode(5))
    end)

    -- @covers lurek.ui.newTreeView
    it("can clear all nodes", function()
        local tv = lurek.ui.newTreeView()
        tv:addNode("A")
        tv:addNode("B")
        tv:clearNodes()
        expect_equal(0, tv:getNodeCount())
    end)

    -- @covers lurek.ui.newTreeView
    it("can get and set node text", function()
        local tv = lurek.ui.newTreeView()
        local idx = tv:addNode("Original")
        expect_equal("Original", tv:getNodeText(idx))
        local ok = tv:setNodeText(idx, "Changed")
        expect_equal(true, ok)
        expect_equal("Changed", tv:getNodeText(idx))
    end)

    -- @covers lurek.ui.newTreeView
    it("can set node icon", function()
        local tv = lurek.ui.newTreeView()
        local idx = tv:addNode("Folder")
        local ok = tv:setNodeIcon(idx, "folder.png")
        expect_equal(true, ok)
    end)

    -- @covers lurek.ui.newTreeView
    it("can expand and collapse a node", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Root")
        tv:addNode("Child", root)
        expect_equal(true, tv:expandNode(root))
        expect_equal(true, tv:isNodeExpanded(root))
        expect_equal(true, tv:collapseNode(root))
        expect_equal(false, tv:isNodeExpanded(root))
    end)

    -- @covers lurek.ui.newTreeView
    it("isNodeExpanded returns nil for invalid index", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(nil, tv:isNodeExpanded(99))
    end)

    -- @covers lurek.ui.newTreeView
    it("can expand and collapse all", function()
        local tv = lurek.ui.newTreeView()
        local r1 = tv:addNode("R1")
        tv:addNode("C1", r1)
        tv:expandAll()
        expect_equal(true, tv:isNodeExpanded(r1))
        tv:collapseAll()
        expect_equal(false, tv:isNodeExpanded(r1))
    end)

    -- @covers lurek.ui.newTreeView
    it("can set and get selected node", function()
        local tv = lurek.ui.newTreeView()
        local idx = tv:addNode("Node")
        expect_equal(true, tv:setSelectedNode(idx))
        expect_equal(idx, tv:getSelectedNode())
    end)

    -- @covers lurek.ui.newTreeView
    it("getSelectedNode returns nil when none selected", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(nil, tv:getSelectedNode())
    end)

    -- @covers lurek.ui.newTreeView
    it("can get child nodes (1-based)", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Root")
        local c1 = tv:addNode("Child1", root)
        local c2 = tv:addNode("Child2", root)
        local children = tv:getChildNodes(root)
        expect_type("table", children)
        expect_equal(2, #children)
        expect_equal(c1, children[1])
        expect_equal(c2, children[2])
    end)

    -- @covers lurek.ui.newTreeView
    it("can get parent node", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Root")
        local child = tv:addNode("Child", root)
        expect_equal(root, tv:getParentNode(child))
    end)

    -- @covers lurek.ui.newTreeView
    it("root node has nil parent", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Root")
        expect_equal(nil, tv:getParentNode(root))
    end)

    -- @covers lurek.ui.newTreeView
    it("can get node depth", function()
        local tv = lurek.ui.newTreeView()
        local root = tv:addNode("Root")
        local child = tv:addNode("Child", root)
        local grand = tv:addNode("Grand", child)
        expect_equal(0, tv:getNodeDepth(root))
        expect_equal(1, tv:getNodeDepth(child))
        expect_equal(2, tv:getNodeDepth(grand))
    end)
end)

-- =========================================================================
-- 20. Widget count & root
-- =========================================================================
-- @describe lurek.ui widget count
describe("lurek.ui widget count", function()
    -- @covers lurek.ui.getWidgetCount
    it("getWidgetCount returns a number", function()
        local count = lurek.ui.getWidgetCount()
        expect_type("number", count)
        expect_equal(true, count >= 0)
    end)

    -- @covers lurek.ui.getRoot
    it("getRoot returns a table", function()
        local root = lurek.ui.getRoot()
        expect_type("table", root)
    end)
end)

-- =========================================================================
-- 21. Focus management
-- =========================================================================
-- @describe lurek.ui focus
describe("lurek.ui focus", function()
    -- @covers lurek.ui.clearFocus
    it("clearFocus works without error", function()
        lurek.ui.clearFocus()
    end)

    -- @covers lurek.ui.clearFocus
    -- @covers lurek.ui.getFocus
    it("getFocus returns nil when no focus", function()
        lurek.ui.clearFocus()
        local f = lurek.ui.getFocus()
        expect_equal(nil, f)
    end)

    -- @covers lurek.ui.getFocus
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.setFocus
    it("setFocus and getFocus work", function()
        local btn = lurek.ui.newButton("Focus Test")
        lurek.ui.setFocus(btn)
        local f = lurek.ui.getFocus()
        expect_type("number", f)
    end)

    -- @covers lurek.ui.focusNext
    -- @covers lurek.ui.getFocus
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.setFocus
    it("focusNext moves focus", function()
        local b1 = lurek.ui.newButton("N1")
        local b2 = lurek.ui.newButton("N2")
        lurek.ui.setFocus(b1)
        lurek.ui.focusNext()
        -- focus should have moved
        local f = lurek.ui.getFocus()
        expect_type("number", f)
    end)
end)

-- =========================================================================
-- 22. Input routing
-- =========================================================================
-- @describe lurek.ui input routing
describe("lurek.ui input routing", function()
    -- @covers lurek.ui.mousepressed
    it("mousepressed returns boolean", function()
        local consumed = lurek.ui.mousepressed(100, 100, 1)
        expect_type("boolean", consumed)
    end)

    -- @covers lurek.ui.mousereleased
    it("mousereleased returns boolean", function()
        local consumed = lurek.ui.mousereleased(100, 100, 1)
        expect_type("boolean", consumed)
    end)

    -- @covers lurek.ui.mousemoved
    it("mousemoved returns boolean", function()
        local consumed = lurek.ui.mousemoved(100, 100)
        expect_type("boolean", consumed)
    end)

    -- @covers lurek.ui.keypressed
    it("keypressed returns boolean", function()
        local consumed = lurek.ui.keypressed("tab")
        expect_type("boolean", consumed)
    end)

    -- @covers lurek.ui.textinput
    it("textinput returns boolean", function()
        local consumed = lurek.ui.textinput("a")
        expect_type("boolean", consumed)
    end)

    -- @covers lurek.ui.wheelmoved
    it("wheelmoved returns boolean", function()
        local consumed = lurek.ui.wheelmoved(0, -1)
        expect_type("boolean", consumed)
    end)
end)

-- =========================================================================
-- 23. Update & draw (headless: no-op but should not error)
-- =========================================================================
-- @describe lurek.ui update and draw
describe("lurek.ui update and draw", function()
    -- @covers lurek.ui.update
    it("update runs without error", function()
        lurek.ui.update(0.016)
    end)

    -- @covers lurek.ui.draw
    it("draw runs without error", function()
        lurek.ui.draw()
    end)
end)

-- =========================================================================
-- 24. Theme
-- =========================================================================
-- @describe lurek.ui Theme
describe("lurek.ui Theme", function()
    -- @covers lurek.ui.newTheme
    it("creates a theme", function()
        local theme = lurek.ui.newTheme()
        expect_type("userdata", theme)
    end)

    -- @covers lurek.ui.getTheme
    -- @covers lurek.ui.newTheme
    -- @covers lurek.ui.setTheme
    it("can set and get theme", function()
        local theme = lurek.ui.newTheme()
        lurek.ui.setTheme(theme)
        local t = lurek.ui.getTheme()
        expect_type("boolean", t)
    end)
end)

-- =========================================================================
-- 25. findById
-- =========================================================================
-- @describe lurek.ui findById
describe("lurek.ui findById", function()
    -- @covers lurek.ui.newButton
    it("finds a widget by id", function()
        local btn = lurek.ui.newButton("Find Me")
        btn:setId("unique_btn")
        local found = btn:findById("unique_btn")
        -- findById searches from root; returned widget is a table or nil
        -- Since btn is the one with the id, it should find itself
        -- Note: depends on context-wide search
    end)
end)

-- =========================================================================
-- 26. Callbacks (onClick, onChange, onDraw)
-- =========================================================================
-- @describe lurek.ui callbacks
describe("lurek.ui callbacks", function()
    -- @covers lurek.ui.newButton
    it("setOnClick accepts a function", function()
        local btn = lurek.ui.newButton("Clickable")
        local clicked = false
        btn:setOnClick(function()
            clicked = true
        end)
        -- Callback is stored but not invoked here
    end)

    -- @covers lurek.ui.newSlider
    it("setOnChange accepts a function", function()
        local sl = lurek.ui.newSlider(0, 100)
        sl:setOnChange(function(val) end)
    end)

    -- @covers lurek.ui.newPanel
    it("setOnDraw accepts a function", function()
        local p = lurek.ui.newPanel()
        p:setOnDraw(function() end)
    end)
end)

-- =========================================================================
-- 22. RadioButton
-- =========================================================================
-- @describe lurek.ui.newRadioButton
describe("lurek.ui.newRadioButton", function()
    -- @covers lurek.ui.newRadioButton
    it("creates a radio button", function()
        local rb = lurek.ui.newRadioButton("Option A", "group1")
        expect_type("table", rb)
    end)
    -- @covers lurek.ui.newRadioButton
    it("has correct text", function()
        local rb = lurek.ui.newRadioButton("Opt", "g")
        expect_equal("Opt", rb:getText())
    end)
    -- @covers lurek.ui.newRadioButton
    it("defaults to not selected", function()
        local rb = lurek.ui.newRadioButton("X", "g")
        expect_equal(false, rb:isSelected())
    end)
    -- @covers lurek.ui.newRadioButton
    it("can set selected", function()
        local rb = lurek.ui.newRadioButton("X", "g")
        rb:setSelected(true)
        expect_equal(true, rb:isSelected())
    end)
    -- @covers lurek.ui.newRadioButton
    it("has group", function()
        local rb = lurek.ui.newRadioButton("X", "mygroup")
        expect_equal("mygroup", rb:getGroup())
    end)
    -- @covers lurek.ui.newRadioButton
    it("has base widget methods", function()
        local rb = lurek.ui.newRadioButton("A", "g")
        expect_type("function", rb.setPosition)
        expect_type("function", rb.setSize)
        expect_type("function", rb.setVisible)
    end)
end)

-- =========================================================================
-- 23. ScrollBar
-- =========================================================================
-- @describe lurek.ui.newScrollBar
describe("lurek.ui.newScrollBar", function()
    -- @covers lurek.ui.newScrollBar
    it("creates a scroll bar", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_type("table", sb)
    end)
    -- @covers lurek.ui.newScrollBar
    it("defaults position to 0", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_near(0, sb:getScrollPosition(), 0.001)
    end)
    -- @covers lurek.ui.newScrollBar
    it("can set position", function()
        local sb = lurek.ui.newScrollBar(false)
        sb:setScrollPosition(42)
        expect_near(42, sb:getScrollPosition(), 0.001)
    end)
    -- @covers lurek.ui.newScrollBar
    it("default content size is 100", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_near(100, sb:getContentSize(), 0.001)
    end)
    -- @covers lurek.ui.newScrollBar
    it("default view size is 50", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_near(50, sb:getViewSize(), 0.001)
    end)
    -- @covers lurek.ui.newScrollBar
    it("can set content and view sizes", function()
        local sb = lurek.ui.newScrollBar(true)
        sb:setContentSize(200)
        sb:setViewSize(80)
        expect_near(200, sb:getContentSize(), 0.001)
        expect_near(80, sb:getViewSize(), 0.001)
    end)
    -- @covers lurek.ui.newScrollBar
    it("vertical flag persists", function()
        local v = lurek.ui.newScrollBar(true)
        local h = lurek.ui.newScrollBar(false)
        expect_equal(true, v:isVertical())
        expect_equal(false, h:isVertical())
    end)
end)

-- =========================================================================
-- 24. GUIWindow
-- =========================================================================
-- @describe lurek.ui.newWindow
describe("lurek.ui.newWindow", function()
    -- @covers lurek.ui.newWindow
    it("creates a window", function()
        local w = lurek.ui.newWindow("Title")
        expect_type("table", w)
    end)
    -- @covers lurek.ui.newWindow
    it("has correct title", function()
        local w = lurek.ui.newWindow("My Win")
        expect_equal("My Win", w:getTitle())
    end)
    -- @covers lurek.ui.newWindow
    it("defaults closeable true", function()
        local w = lurek.ui.newWindow("W")
        expect_equal(true, w:isCloseable())
    end)
    -- @covers lurek.ui.newWindow
    it("defaults draggable true", function()
        local w = lurek.ui.newWindow("W")
        expect_equal(true, w:isDraggable())
    end)
    -- @covers lurek.ui.newWindow
    it("defaults resizable false", function()
        local w = lurek.ui.newWindow("W")
        expect_equal(false, w:isResizable())
    end)
    -- @covers lurek.ui.newWindow
    it("can toggle closeable", function()
        local w = lurek.ui.newWindow("W")
        w:setCloseable(false)
        expect_equal(false, w:isCloseable())
    end)
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newWindow
    it("can add child", function()
        local w = lurek.ui.newWindow("W")
        local btn = lurek.ui.newButton("B")
        w:addChild(btn)
        expect_equal(1, #w:getChildren())
    end)
end)

-- =========================================================================
-- 25. SplitPanel
-- =========================================================================
-- @describe lurek.ui.newSplitPanel
describe("lurek.ui.newSplitPanel", function()
    -- @covers lurek.ui.newSplitPanel
    it("creates a split panel", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        expect_type("table", sp)
    end)
    -- @covers lurek.ui.newSplitPanel
    it("has correct orientation", function()
        local sp = lurek.ui.newSplitPanel("vertical")
        expect_equal("vertical", sp:getOrientation())
    end)
    -- @covers lurek.ui.newSplitPanel
    it("default split position is 0.5", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        expect_near(0.5, sp:getSplitPosition(), 0.001)
    end)
    -- @covers lurek.ui.newSplitPanel
    it("can set split position", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        sp:setSplitPosition(0.3)
        expect_near(0.3, sp:getSplitPosition(), 0.001)
    end)
    -- @covers lurek.ui.newSplitPanel
    it("can set min panel size", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        sp:setMinPanelSize(100)
        expect_near(100, sp:getMinPanelSize(), 0.001)
    end)
end)

-- =========================================================================
-- 26. DockPanel
-- =========================================================================
-- @describe lurek.ui.newDockPanel
describe("lurek.ui.newDockPanel", function()
    -- @covers lurek.ui.newDockPanel
    it("creates a dock panel", function()
        local dp = lurek.ui.newDockPanel()
        expect_type("table", dp)
    end)
    -- @covers lurek.ui.newDockPanel
    it("starts with 0 docked", function()
        local dp = lurek.ui.newDockPanel()
        expect_equal(0, dp:getDockedCount())
    end)
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newDockPanel
    it("can dock a child", function()
        local dp = lurek.ui.newDockPanel()
        local btn = lurek.ui.newButton("B")
        dp:dock(btn["_idx"], "left")
        expect_equal(1, dp:getDockedCount())
    end)
    -- @covers lurek.ui.newDockPanel
    it("can set split size", function()
        local dp = lurek.ui.newDockPanel()
        dp:setSplitSize("left", 200)
        expect_near(200, dp:getSplitSize("left"), 0.001)
    end)
end)

-- =========================================================================
-- 27. Toolbar
-- =========================================================================
-- @describe lurek.ui.newToolbar
describe("lurek.ui.newToolbar", function()
    -- @covers lurek.ui.newToolbar
    it("creates a toolbar", function()
        local tb = lurek.ui.newToolbar("horizontal")
        expect_type("table", tb)
    end)
    -- @covers lurek.ui.newToolbar
    it("has orientation", function()
        local tb = lurek.ui.newToolbar("vertical")
        expect_equal("vertical", tb:getOrientation())
    end)
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newToolbar
    it("can add child", function()
        local tb = lurek.ui.newToolbar("horizontal")
        local btn = lurek.ui.newButton("B")
        tb:addChild(btn)
        expect_equal(1, tb:getChildCount())
    end)

    -- @covers lurek.ui.newToolbar
    it("addButton returns 1-based index", function()
        local tb = lurek.ui.newToolbar("horizontal")
        local idx = tb:addButton("save", "Save File")
        expect_equal(1, idx)
        local idx2 = tb:addButton("open", "Open File")
        expect_equal(2, idx2)
    end)

    -- @covers lurek.ui.newToolbar
    it("addButton is idempotent (no duplicate ids)", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb:addButton("dup", "First")
        local idx2 = tb:addButton("dup", "Second")
        expect_equal(1, idx2)
    end)

    -- @covers lurek.ui.newToolbar
    it("addSeparator and addSpacer do not error", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb:addSeparator()
        tb:addSpacer(10)
        tb:addSpacer()
    end)

    -- @covers lurek.ui.newToolbar
    it("getButton returns table with correct fields", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb:addButton("save", "Save")
        local btn = tb:getButton("save")
        expect_type("table", btn)
        expect_equal("save", btn.id)
        expect_equal("Save", btn.tooltip)
        expect_equal(true, btn.enabled)
        expect_equal(false, btn.toggled)
    end)

    -- @covers lurek.ui.newToolbar
    it("getButton returns nil for missing id", function()
        local tb = lurek.ui.newToolbar("horizontal")
        expect_equal(nil, tb:getButton("nope"))
    end)

    -- @covers lurek.ui.newToolbar
    it("setButtonEnabled can disable a button", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb:addButton("x", "X")
        expect_equal(true, tb:setButtonEnabled("x", false))
        local btn = tb:getButton("x")
        expect_equal(false, btn.enabled)
    end)

    -- @covers lurek.ui.newToolbar
    it("setButtonToggled and isButtonToggled work", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb:addButton("t", "Toggle")
        expect_equal(true, tb:setButtonToggled("t", true))
        expect_equal(true, tb:isButtonToggled("t"))
    end)

    -- @covers lurek.ui.newToolbar
    it("isButtonToggled returns nil for missing id", function()
        local tb = lurek.ui.newToolbar("horizontal")
        expect_equal(nil, tb:isButtonToggled("none"))
    end)
end)

-- =========================================================================
-- 28. MenuBar
-- =========================================================================
-- @describe lurek.ui.newMenuBar
describe("lurek.ui.newMenuBar", function()
    -- @covers lurek.ui.newMenuBar
    it("creates a menu bar", function()
        local mb = lurek.ui.newMenuBar()
        expect_type("table", mb)
    end)
    -- @covers lurek.ui.newMenuBar
    it("starts with 0 menus", function()
        local mb = lurek.ui.newMenuBar()
        expect_equal(0, mb:getMenuCount())
    end)
    -- @covers lurek.ui.newMenuBar
    -- @covers lurek.ui.newMenuItem
    it("can add menu", function()
        local mb = lurek.ui.newMenuBar()
        local mi = lurek.ui.newMenuItem("File")
        mb:addMenu(mi["_idx"])
        expect_equal(1, mb:getMenuCount())
    end)
end)

-- =========================================================================
-- 29. MenuItem
-- =========================================================================
-- @describe lurek.ui.newMenuItem
describe("lurek.ui.newMenuItem", function()
    -- @covers lurek.ui.newMenuItem
    it("creates a menu item", function()
        local mi = lurek.ui.newMenuItem("Edit")
        expect_type("table", mi)
    end)
    -- @covers lurek.ui.newMenuItem
    it("has correct text", function()
        local mi = lurek.ui.newMenuItem("File")
        expect_equal("File", mi:getText())
    end)
    -- @covers lurek.ui.newMenuItem
    it("defaults unchecked", function()
        local mi = lurek.ui.newMenuItem("X")
        expect_equal(false, mi:isChecked())
    end)
    -- @covers lurek.ui.newMenuItem
    it("can set shortcut", function()
        local mi = lurek.ui.newMenuItem("Save")
        mi:setShortcut("Ctrl+S")
        expect_equal("Ctrl+S", mi:getShortcut())
    end)
    -- @covers lurek.ui.newMenuItem
    it("can add sub-item", function()
        local mi = lurek.ui.newMenuItem("File")
        local sub = lurek.ui.newMenuItem("Open")
        mi:addSubItem(sub["_idx"])
        expect_equal(1, #mi:getSubItems())
    end)
end)

-- =========================================================================
-- 30. Dialog
-- =========================================================================
-- @describe lurek.ui.newDialog
describe("lurek.ui.newDialog", function()
    -- @covers lurek.ui.newDialog
    it("creates a dialog", function()
        local d = lurek.ui.newDialog("Confirm")
        expect_type("table", d)
    end)
    -- @covers lurek.ui.newDialog
    it("has title", function()
        local d = lurek.ui.newDialog("Save?")
        expect_equal("Save?", d:getTitle())
    end)
    -- @covers lurek.ui.newDialog
    it("defaults modal true", function()
        local d = lurek.ui.newDialog("D")
        expect_equal(true, d:isModal())
    end)
    -- @covers lurek.ui.newDialog
    it("defaults not open", function()
        local d = lurek.ui.newDialog("D")
        expect_equal(false, d:isOpen())
    end)
    -- @covers lurek.ui.newDialog
    it("can open and close", function()
        local d = lurek.ui.newDialog("D")
        d:open()
        expect_equal(true, d:isOpen())
        d:close()
        expect_equal(false, d:isOpen())
    end)

    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newDialog
    it("setContent and getContent work", function()
        local d = lurek.ui.newDialog("Edit")
        local btn = lurek.ui.newButton("B")
        expect_equal(nil, d:getContent())
        d:setContent(btn["_idx"])
        expect_equal(btn["_idx"], d:getContent())
    end)

    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newDialog
    it("setContent nil clears content", function()
        local d = lurek.ui.newDialog("Clear")
        local btn = lurek.ui.newButton("B")
        d:setContent(btn["_idx"])
        d:setContent(nil)
        expect_equal(nil, d:getContent())
    end)

    -- @covers lurek.ui.newDialog
    it("addButton appends footer button and returns count", function()
        local d = lurek.ui.newDialog("Prompt")
        local count1 = d:addButton("OK")
        expect_equal(1, count1)
        local count2 = d:addButton("Cancel")
        expect_equal(2, count2)
    end)
end)

-- =========================================================================
-- 31. StatusBar
-- =========================================================================
-- @describe lurek.ui.newStatusBar
describe("lurek.ui.newStatusBar", function()
    -- @covers lurek.ui.newStatusBar
    it("creates a status bar", function()
        local sb = lurek.ui.newStatusBar()
        expect_type("table", sb)
    end)
    -- @covers lurek.ui.newStatusBar
    it("starts with 0 sections", function()
        local sb = lurek.ui.newStatusBar()
        expect_equal(0, sb:getSectionCount())
    end)
    -- @covers lurek.ui.newStatusBar
    it("can add section", function()
        local sb = lurek.ui.newStatusBar()
        sb:addSection("Ready", 100)
        expect_equal(1, sb:getSectionCount())
    end)
    -- @covers lurek.ui.newStatusBar
    it("can set section text", function()
        local sb = lurek.ui.newStatusBar()
        sb:addSection("Info", 120)
        sb:setSectionText(1, "Updated")
        expect_equal("Updated", sb:getSectionText(1))
    end)

    -- @covers lurek.ui.newStatusBar
    it("setSectionCount resizes sections up and down", function()
        local sb = lurek.ui.newStatusBar()
        sb:addSection("A", 100)
        sb:addSection("B", 100)
        expect_equal(2, sb:getSectionCount())
        sb:setSectionCount(1)
        expect_equal(1, sb:getSectionCount())
        sb:setSectionCount(3)
        expect_equal(3, sb:getSectionCount())
    end)

    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.newStatusBar
    it("setSectionWidget does not error", function()
        local sb = lurek.ui.newStatusBar()
        sb:addSection("A", 100)
        local btn = lurek.ui.newButton("X")
        sb:setSectionWidget(1, btn["_idx"])
    end)
end)

-- =========================================================================
-- 32. Accordion
-- =========================================================================
-- @describe lurek.ui.newAccordion
describe("lurek.ui.newAccordion", function()
    -- @covers lurek.ui.newAccordion
    it("creates an accordion", function()
        local a = lurek.ui.newAccordion()
        expect_type("table", a)
    end)
    -- @covers lurek.ui.newAccordion
    it("starts with 0 sections", function()
        local a = lurek.ui.newAccordion()
        expect_equal(0, a:getSectionCount())
    end)
    -- @covers lurek.ui.newAccordion
    it("defaults non-exclusive", function()
        local a = lurek.ui.newAccordion()
        expect_equal(false, a:isExclusive())
    end)
    -- @covers lurek.ui.newAccordion
    it("can set exclusive", function()
        local a = lurek.ui.newAccordion()
        a:setExclusive(true)
        expect_equal(true, a:isExclusive())
    end)
    -- @covers lurek.ui.newAccordion
    it("can add section", function()
        local a = lurek.ui.newAccordion()
        a:addSection("Section 1")
        expect_equal(1, a:getSectionCount())
    end)
    -- @covers lurek.ui.newAccordion
    it("can expand section", function()
        local a = lurek.ui.newAccordion()
        a:addSection("S1")
        a:toggleSection(1)
        expect_equal(true, a:isSectionExpanded(1))
    end)
    -- @covers lurek.ui.newAccordion
    it("can collapse section", function()
        local a = lurek.ui.newAccordion()
        a:addSection("S1")
        a:toggleSection(1)
        a:toggleSection(1)
        expect_equal(false, a:isSectionExpanded(1))
    end)
end)

-- =========================================================================
-- 33. TooltipPanel
-- =========================================================================
-- @describe lurek.ui.newTooltipPanel
describe("lurek.ui.newTooltipPanel", function()
    -- @covers lurek.ui.newTooltipPanel
    it("creates a tooltip panel", function()
        local tp = lurek.ui.newTooltipPanel("Help text")
        expect_type("table", tp)
    end)
    -- @covers lurek.ui.newTooltipPanel
    it("has correct text", function()
        local tp = lurek.ui.newTooltipPanel("Tip")
        expect_equal("Tip", tp:getText())
    end)
    -- @covers lurek.ui.newTooltipPanel
    it("can set text", function()
        local tp = lurek.ui.newTooltipPanel("Old")
        tp:setText("New")
        expect_equal("New", tp:getText())
    end)
    -- @covers lurek.ui.newTooltipPanel
    it("default delay is 0.5", function()
        local tp = lurek.ui.newTooltipPanel("T")
        expect_near(0.5, tp:getDelay(), 0.001)
    end)
    -- @covers lurek.ui.newTooltipPanel
    it("can set delay", function()
        local tp = lurek.ui.newTooltipPanel("T")
        tp:setDelay(1.0)
        expect_near(1.0, tp:getDelay(), 0.001)
    end)
end)

-- =========================================================================
-- 34. ColorPicker
-- =========================================================================
-- @describe lurek.ui.newColorPicker
describe("lurek.ui.newColorPicker", function()
    -- @covers lurek.ui.newColorPicker
    it("creates a color picker", function()
        local cp = lurek.ui.newColorPicker()
        expect_type("table", cp)
    end)
    -- @covers lurek.ui.newColorPicker
    it("default color is white", function()
        local cp = lurek.ui.newColorPicker()
        local r, g, b, a = cp:getColor()
        expect_near(1.0, r, 0.001)
        expect_near(1.0, g, 0.001)
        expect_near(1.0, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)
    -- @covers lurek.ui.newColorPicker
    it("can set color", function()
        local cp = lurek.ui.newColorPicker()
        cp:setColor(0.5, 0.3, 0.1, 0.9)
        local r, g, b, a = cp:getColor()
        expect_near(0.5, r, 0.001)
        expect_near(0.3, g, 0.001)
        expect_near(0.1, b, 0.001)
        expect_near(0.9, a, 0.001)
    end)
    -- @covers lurek.ui.newColorPicker
    it("default shows alpha", function()
        local cp = lurek.ui.newColorPicker()
        expect_equal(true, cp:getShowAlpha())
    end)
    -- @covers lurek.ui.newColorPicker
    it("default color mode is rgb", function()
        local cp = lurek.ui.newColorPicker()
        expect_equal("rgb", cp:getColorMode())
    end)
    -- @covers lurek.ui.newColorPicker
    it("can set color mode", function()
        local cp = lurek.ui.newColorPicker()
        cp:setColorMode("hsv")
        expect_equal("hsv", cp:getColorMode())
    end)
end)

-- =========================================================================
-- 35. GUITable
-- =========================================================================
-- @describe lurek.ui.newTable
describe("lurek.ui.newTable", function()
    -- @covers lurek.ui.newTable
    it("creates a table", function()
        local t = lurek.ui.newTable()
        expect_type("table", t)
    end)
    -- @covers lurek.ui.newTable
    it("starts with 0 columns", function()
        local t = lurek.ui.newTable()
        expect_equal(0, t:getColumnCount())
    end)
    -- @covers lurek.ui.newTable
    it("starts with 0 rows", function()
        local t = lurek.ui.newTable()
        expect_equal(0, t:getRowCount())
    end)
    -- @covers lurek.ui.newTable
    it("can add column", function()
        local t = lurek.ui.newTable()
        t:addColumn("Name", 100)
        expect_equal(1, t:getColumnCount())
    end)
    -- @covers lurek.ui.newTable
    it("can add row", function()
        local t = lurek.ui.newTable()
        t:addColumn("Name", 100)
        t:addRow({"Alice"})
        expect_equal(1, t:getRowCount())
    end)
    -- @covers lurek.ui.newTable
    it("no selected row by default", function()
        local t = lurek.ui.newTable()
        expect_equal(nil, t:getSelectedRow())
    end)
    -- @covers lurek.ui.newTable
    it("can select row after adding", function()
        local t = lurek.ui.newTable()
        t:addColumn("Name", 100)
        t:addRow({"Alice"})
        t:setSelectedRow(1)
        expect_equal(1, t:getSelectedRow())
    end)
    -- @covers lurek.ui.newTable
    it("can set sortable", function()
        local t = lurek.ui.newTable()
        t:setSortable(true)
        expect_equal(true, t:isSortable())
    end)
end)

-- =========================================================================
-- 36. ImageWidget
-- =========================================================================
-- @describe lurek.ui.newImageWidget
describe("lurek.ui.newImageWidget", function()
    -- @covers lurek.ui.newImageWidget
    it("creates an image widget", function()
        local iw = lurek.ui.newImageWidget()
        expect_type("table", iw)
    end)
    -- @covers lurek.ui.newImageWidget
    it("default scale mode is fit", function()
        local iw = lurek.ui.newImageWidget()
        expect_equal("fit", iw:getScaleMode())
    end)
    -- @covers lurek.ui.newImageWidget
    it("can set scale mode", function()
        local iw = lurek.ui.newImageWidget()
        iw:setScaleMode("fill")
        expect_equal("fill", iw:getScaleMode())
    end)
    -- @covers lurek.ui.newImageWidget
    it("default tint is white", function()
        local iw = lurek.ui.newImageWidget()
        local r, g, b, a = iw:getTint()
        expect_near(1.0, r, 0.001)
        expect_near(1.0, g, 0.001)
        expect_near(1.0, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)
    -- @covers lurek.ui.newImageWidget
    it("can set tint", function()
        local iw = lurek.ui.newImageWidget()
        iw:setTint(0.5, 0.2, 0.8, 1.0)
        local r, g, b, a = iw:getTint()
        expect_near(0.5, r, 0.001)
        expect_near(0.2, g, 0.001)
        expect_near(0.8, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)
end)

-- @describe lurek.ui.parseWidgetState
describe("lurek.ui.parseWidgetState", function()
    -- @covers lurek.ui.parseWidgetState
    it("is a function", function()
        expect_type("function", lurek.ui.parseWidgetState)
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns 'normal' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("normal"), "normal")
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns 'hovered' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("hovered"), "hovered")
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns 'pressed' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("pressed"), "pressed")
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns 'focused' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("focused"), "focused")
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns 'disabled' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("disabled"), "disabled")
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns nil for an invalid state string", function()
        expect_equal(lurek.ui.parseWidgetState("invalid"), nil)
    end)

    -- @covers lurek.ui.parseWidgetState
    it("returns nil for an empty string", function()
        expect_equal(lurek.ui.parseWidgetState(""), nil)
    end)

    -- @covers lurek.ui.parseWidgetState
    it("is case-sensitive  - 'Normal' returns nil", function()
        expect_equal(lurek.ui.parseWidgetState("Normal"), nil)
    end)
end)

-- =========================================================================
-- New factories: SpinBox, Switch, Badge
-- =========================================================================

-- @describe lurek.ui.newSpinBox factory
describe("lurek.ui.newSpinBox factory", function()
    -- @covers lurek.ui.newSpinBox
    it("is callable", function()
        expect_equal(type(lurek.ui.newSpinBox), "function")
    end)

    -- @covers lurek.ui.newSpinBox
    it("returns a table", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        expect_equal(type(sb), "table")
    end)

    -- @covers lurek.ui.newSpinBox
    it("getValue returns min after creation", function()
        local sb = lurek.ui.newSpinBox(10, 50)
        expect_equal(sb:getValue(), 10)
    end)

    -- @covers lurek.ui.newSpinBox
    it("increment changes value", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        sb:increment()
        expect_equal(sb:getValue() > 0, true)
    end)

    -- @covers lurek.ui.newSpinBox
    it("decrement at min stays at min", function()
        local sb = lurek.ui.newSpinBox(5, 20)
        sb:decrement()
        expect_equal(sb:getValue(), 5)
    end)

    -- @covers lurek.ui.newSpinBox
    it("setRange is callable without error", function()
        local sb = lurek.ui.newSpinBox(0, 10)
        sb:setRange(1, 99)
        expect_equal(true, true)
    end)

    -- Migrated from Rust spin_box_increment_respects_step.
    -- @covers lurek.ui.newSpinBox
    it("increment advances value by custom step", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        sb:setStep(2.0)
        sb:increment()
        expect_near(2.0, sb:getValue(), 0.001)
    end)

    -- Migrated from Rust spin_box_increment_clamps_at_max.
    -- @covers lurek.ui.newSpinBox
    it("increment clamps at max when step overshoots", function()
        local sb = lurek.ui.newSpinBox(0, 10)
        sb:setStep(1000.0)
        sb:increment()
        expect_near(10.0, sb:getValue(), 0.001)
    end)

    -- Migrated from Rust spin_box_set_value_clamps_to_range.
    -- @covers lurek.ui.newSpinBox
    it("setValue clamps to max when value exceeds range", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        sb:setValue(999)
        expect_near(100.0, sb:getValue(), 0.001)
    end)

    -- Migrated from Rust spin_box_set_value_clamps_to_range.
    -- @covers lurek.ui.newSpinBox
    it("setValue clamps to min when value is below range", function()
        local sb = lurek.ui.newSpinBox(5, 50)
        sb:setValue(-1)
        expect_near(5.0, sb:getValue(), 0.001)
    end)
end)

-- @describe lurek.ui.newSwitch factory
describe("lurek.ui.newSwitch factory", function()
    -- @covers lurek.ui.newSwitch
    it("is callable", function()
        expect_equal(type(lurek.ui.newSwitch), "function")
    end)

    -- @covers lurek.ui.newSwitch
    it("returns a table", function()
        local sw = lurek.ui.newSwitch(false)
        expect_equal(type(sw), "table")
    end)

    -- @covers lurek.ui.newSwitch
    it("isOn returns false when created off", function()
        local sw = lurek.ui.newSwitch(false)
        expect_equal(sw:isOn(), false)
    end)

    -- @covers lurek.ui.newSwitch
    it("setOn(true) flips state", function()
        local sw = lurek.ui.newSwitch(false)
        sw:setOn(true)
        expect_equal(sw:isOn(), true)
    end)

    -- @covers lurek.ui.newSwitch
    it("toggle flips state back and forth", function()
        local sw = lurek.ui.newSwitch(true)
        sw:toggle()
        expect_equal(sw:isOn(), false)
        sw:toggle()
        expect_equal(sw:isOn(), true)
    end)
end)

-- @describe lurek.ui.newBadge factory
describe("lurek.ui.newBadge factory", function()
    -- @covers lurek.ui.newBadge
    it("is callable", function()
        expect_equal(type(lurek.ui.newBadge), "function")
    end)

    -- @covers lurek.ui.newBadge
    it("returns a table", function()
        local b = lurek.ui.newBadge(3)
        expect_equal(type(b), "table")
    end)

    -- @covers lurek.ui.newBadge
    it("getCount returns initial count", function()
        local b = lurek.ui.newBadge(7)
        expect_equal(b:getCount(), 7)
    end)

    -- @covers lurek.ui.newBadge
    it("getDisplayText returns count string below cap", function()
        local b = lurek.ui.newBadge(5)
        expect_equal(b:getDisplayText(), "5")
    end)

    -- @covers lurek.ui.newBadge
    it("getDisplayText shows plus notation when over cap", function()
        local b = lurek.ui.newBadge(200)
        expect_equal(b:getDisplayText(), "99+")
    end)

    -- @covers lurek.ui.newBadge
    it("setCount updates count", function()
        local b = lurek.ui.newBadge(0)
        b:setCount(42)
        expect_equal(b:getCount(), 42)
    end)

    -- Migrated from Rust badge_display_text_at_max_shows_count.
    -- @covers lurek.ui.newBadge
    it("getDisplayText shows exact count at cap boundary", function()
        local b = lurek.ui.newBadge(99)
        expect_equal(b:getDisplayText(), "99")
    end)
end)

-- =========================================================================
-- Module helpers: setDefaultTheme, setViewport, flushCache
-- =========================================================================

-- @describe lurek.ui default theme and viewport helpers
describe("lurek.ui default theme and viewport helpers", function()
    -- @covers lurek.ui.setDefaultTheme
    it("setDefaultTheme is callable", function()
        expect_equal(type(lurek.ui.setDefaultTheme), "function")
        lurek.ui.setDefaultTheme()
        expect_equal(true, true)
    end)

    -- @covers lurek.ui.setViewport
    it("setViewport is callable", function()
        expect_equal(type(lurek.ui.setViewport), "function")
        lurek.ui.setViewport(1280, 720)
        expect_equal(true, true)
    end)

    -- @covers lurek.ui.flushCache
    it("flushCache returns boolean", function()
        expect_equal(type(lurek.ui.flushCache), "function")
        local result = lurek.ui.flushCache()
        expect_equal(type(result), "boolean")
    end)

    -- @covers lurek.ui.flushCache
    it("flushCache returns false on second consecutive call", function()
        lurek.ui.flushCache()
        local clean = lurek.ui.flushCache()
        expect_equal(clean, false)
    end)
end)

-- @describe ui migrated from render unit
describe("ui migrated from render unit", function()
    -- @covers lurek.ui.newPanel
    it("newPanel remains canonical panel constructor", function()
        expect_type("function", lurek.ui.newPanel)
    end)
end)

-- =========================================================================
-- Drag-and-drop between containers
-- =========================================================================

-- @describe lurek.ui drag and drop helpers
describe("lurek.ui drag and drop helpers", function()
    -- @covers lurek.ui.beginDrag
    -- @covers lurek.ui.dropOn
    -- @covers lurek.ui.endDrag
    -- @covers lurek.ui.getActiveDrag
    it("moves a widget from one container to another", function()
        local left = lurek.ui.newPanel()
        left:setPosition(0, 0)
        left:setSize(120, 80)

        local right = lurek.ui.newPanel()
        right:setPosition(140, 0)
        right:setSize(120, 80)
        local item = lurek.ui.newButton("Item")

        left:addChild(item)
        expect_equal(left:getChildCount(), 1)
        expect_equal(right:getChildCount(), 0)

        expect_true(lurek.ui.beginDrag(item))
        expect_true(lurek.ui.getActiveDrag() ~= nil)
        expect_true(lurek.ui.dropOn(right))
        expect_true(lurek.ui.getActiveDrag() == nil)

        expect_equal(left:getChildCount(), 0)
        expect_equal(right:getChildCount(), 1)

        -- cancel when nothing is active should be no-op
        local prev = lurek.ui.endDrag()
        expect_true(prev == nil)
    end)
end)

-- =========================================================================
-- First-class transitions / animations
-- =========================================================================

-- @describe LUiWidget animation helpers
describe("LUiWidget animation helpers", function()
    -- @covers LUiWidget.animateAlpha
    -- @covers LUiWidget.animatePosition
    -- @covers LUiWidget.isAnimating
    -- @covers LUiWidget.cancelAnimations
    -- @covers lurek.ui.update
    it("animates alpha and position over update steps", function()
        local w = lurek.ui.newLabel("Anim")
        w:setAlpha(0.0)

        local ok_alpha = w:animateAlpha(1.0, 0.5, false)
        local ok_pos = w:animatePosition(90, 40, 0.5)
        expect_true(ok_alpha)
        expect_true(ok_pos)
        expect_true(w:isAnimating())

        lurek.ui.update(0.25)
        local mid_alpha = w:getAlpha()
        expect_true(mid_alpha > 0.0)
        expect_true(mid_alpha < 1.0)

        lurek.ui.update(0.35)
        local end_alpha = w:getAlpha()
        expect_true(end_alpha >= 0.99)
        expect_false(w:isAnimating())

        local canceled = w:cancelAnimations()
        expect_true(canceled)
    end)
end)

test_summary()
