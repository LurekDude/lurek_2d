-- Lurek2D UI widget API tests.
-- Covers widget construction, focus and input routing, theme access, toast helpers, and headless-safe UI tree management through lurek.ui.

-- Lurek2D GUI API Tests

-- =========================================================================
-- 1. lurek.ui module exists
-- =========================================================================
-- @description Verifies that the lurek.ui namespace exists and exposes every tested factory, focus helper, root accessor, theme helper, routing entry point, toast helper, update hook, and draw hook.
describe("lurek.ui module exists", function()
    -- @tests lurek.ui.addToast
    -- @tests lurek.ui.clearFocus
    -- @tests lurek.ui.draw
    -- @tests lurek.ui.focusNext
    -- @tests lurek.ui.focusPrev
    -- @tests lurek.ui.getFocus
    -- @tests lurek.ui.getRoot
    -- @tests lurek.ui.getTheme
    -- @tests lurek.ui.getToastCount
    -- @tests lurek.ui.getWidgetCount
    -- @tests lurek.ui.keypressed
    -- @tests lurek.ui.mousemoved
    -- @tests lurek.ui.mousepressed
    -- @tests lurek.ui.mousereleased
    -- @tests lurek.ui.newAccordion
    -- @tests lurek.ui.newButton
    -- @tests lurek.ui.newCheckbox
    -- @tests lurek.ui.newColorPicker
    -- @tests lurek.ui.newComboBox
    -- @tests lurek.ui.newDialog
    -- @tests lurek.ui.newDockPanel
    -- @tests lurek.ui.newImageWidget
    -- @tests lurek.ui.newLabel
    -- @tests lurek.ui.newLayout
    -- @tests lurek.ui.newList
    -- @tests lurek.ui.newMenuBar
    -- @tests lurek.ui.newMenuItem
    -- @tests lurek.ui.newNinePatch
    -- @tests lurek.ui.newPanel
    -- @tests lurek.ui.newProgressBar
    -- @tests lurek.ui.newRadioButton
    -- @tests lurek.ui.newScrollBar
    -- @tests lurek.ui.newScrollPanel
    -- @tests lurek.ui.newSeparator
    -- @tests lurek.ui.newSlider
    -- @tests lurek.ui.newSpacer
    -- @tests lurek.ui.newSplitPanel
    -- @tests lurek.ui.newStatusBar
    -- @tests lurek.ui.newTabBar
    -- @tests lurek.ui.newTable
    -- @tests lurek.ui.newTextInput
    -- @tests lurek.ui.newTheme
    -- @tests lurek.ui.newToast
    -- @tests lurek.ui.newToolbar
    -- @tests lurek.ui.newTooltipPanel
    -- @tests lurek.ui.newTreeView
    -- @tests lurek.ui.newWindow
    -- @tests lurek.ui.setFocus
    -- @tests lurek.ui.setTheme
    -- @tests lurek.ui.textinput
    -- @tests lurek.ui.update
    -- @tests lurek.ui.wheelmoved
    -- @description Confirms the top-level lurek.ui namespace is a Lua table.
    it("lurek.ui is a table", function()
        expect_type("table", lurek.ui)
    end)

    -- @description Confirms the button factory is exposed as a function.
    it("has newButton factory", function()
        expect_type("function", lurek.ui.newButton)
    end)

    -- @description Confirms the label factory is exposed as a function.
    it("has newLabel factory", function()
        expect_type("function", lurek.ui.newLabel)
    end)

    -- @description Confirms the text input factory is exposed as a function.
    it("has newTextInput factory", function()
        expect_type("function", lurek.ui.newTextInput)
    end)

    -- @description Confirms the checkbox factory is exposed as a function.
    it("has newCheckbox factory", function()
        expect_type("function", lurek.ui.newCheckbox)
    end)

    -- @description Confirms the slider factory is exposed as a function.
    it("has newSlider factory", function()
        expect_type("function", lurek.ui.newSlider)
    end)

    -- @description Confirms the progress bar factory is exposed as a function.
    it("has newProgressBar factory", function()
        expect_type("function", lurek.ui.newProgressBar)
    end)

    -- @description Confirms the combo box factory is exposed as a function.
    it("has newComboBox factory", function()
        expect_type("function", lurek.ui.newComboBox)
    end)

    -- @description Confirms the list factory is exposed as a function.
    it("has newList factory", function()
        expect_type("function", lurek.ui.newList)
    end)

    -- @description Confirms the panel factory is exposed as a function.
    it("has newPanel factory", function()
        expect_type("function", lurek.ui.newPanel)
    end)

    -- @description Confirms the layout factory is exposed as a function.
    it("has newLayout factory", function()
        expect_type("function", lurek.ui.newLayout)
    end)

    -- @description Confirms the scroll panel factory is exposed as a function.
    it("has newScrollPanel factory", function()
        expect_type("function", lurek.ui.newScrollPanel)
    end)

    -- @description Confirms the nine-patch factory is exposed as a function.
    it("has newNinePatch factory", function()
        expect_type("function", lurek.ui.newNinePatch)
    end)

    -- @description Confirms the tab bar factory is exposed as a function.
    it("has newTabBar factory", function()
        expect_type("function", lurek.ui.newTabBar)
    end)

    -- @description Confirms the separator factory is exposed as a function.
    it("has newSeparator factory", function()
        expect_type("function", lurek.ui.newSeparator)
    end)

    -- @description Confirms the spacer factory is exposed as a function.
    it("has newSpacer factory", function()
        expect_type("function", lurek.ui.newSpacer)
    end)

    -- @description Confirms the toast factory is exposed as a function.
    it("has newToast factory", function()
        expect_type("function", lurek.ui.newToast)
    end)

    -- @description Confirms the tree view factory is exposed as a function.
    it("has newTreeView factory", function()
        expect_type("function", lurek.ui.newTreeView)
    end)

    -- @description Confirms the theme factory is exposed as a function.
    it("has newTheme factory", function()
        expect_type("function", lurek.ui.newTheme)
    end)

    -- @description Confirms the global theme setter is exposed as a function.
    it("has setTheme function", function()
        expect_type("function", lurek.ui.setTheme)
    end)

    -- @description Confirms the global theme getter is exposed as a function.
    it("has getTheme function", function()
        expect_type("function", lurek.ui.getTheme)
    end)

    -- @description Confirms the focus setter is exposed as a function.
    it("has setFocus function", function()
        expect_type("function", lurek.ui.setFocus)
    end)

    -- @description Confirms the focus getter is exposed as a function.
    it("has getFocus function", function()
        expect_type("function", lurek.ui.getFocus)
    end)

    -- @description Confirms the forward focus traversal helper is exposed as a function.
    it("has focusNext function", function()
        expect_type("function", lurek.ui.focusNext)
    end)

    -- @description Confirms the backward focus traversal helper is exposed as a function.
    it("has focusPrev function", function()
        expect_type("function", lurek.ui.focusPrev)
    end)

    -- @description Confirms the focus clearing helper is exposed as a function.
    it("has clearFocus function", function()
        expect_type("function", lurek.ui.clearFocus)
    end)

    -- @description Confirms the root widget accessor is exposed as a function.
    it("has getRoot function", function()
        expect_type("function", lurek.ui.getRoot)
    end)

    -- @description Confirms the UI update hook is exposed as a function.
    it("has update function", function()
        expect_type("function", lurek.ui.update)
    end)

    -- @description Confirms the UI draw hook is exposed as a function.
    it("has draw function", function()
        expect_type("function", lurek.ui.draw)
    end)

    -- @description Confirms the widget count accessor is exposed as a function.
    it("has getWidgetCount function", function()
        expect_type("function", lurek.ui.getWidgetCount)
    end)

    -- @description Confirms all mouse, keyboard, text, and wheel routing entry points are exposed as functions.
    it("has input routing functions", function()
        expect_type("function", lurek.ui.mousepressed)
        expect_type("function", lurek.ui.mousereleased)
        expect_type("function", lurek.ui.mousemoved)
        expect_type("function", lurek.ui.keypressed)
        expect_type("function", lurek.ui.textinput)
        expect_type("function", lurek.ui.wheelmoved)
    end)

    -- @description Confirms both toast insertion and toast count access are exposed as functions.
    it("has toast functions", function()
        expect_type("function", lurek.ui.addToast)
        expect_type("function", lurek.ui.getToastCount)
    end)
end)

-- =========================================================================
-- 2. Button
-- =========================================================================
-- @description Covers button creation, the default empty label, and text mutation through setText/getText.
describe("lurek.ui Button", function()
    -- @description Verifies newButton("OK") returns a table whose text reads back as "OK".
    it("creates a button with text", function()
        local btn = lurek.ui.newButton("OK")
        expect_type("table", btn)
        expect_equal("OK", btn.getText())
    end)

    -- @description Verifies calling newButton() with no argument yields an empty string label.
    it("creates a button with default empty text", function()
        local btn = lurek.ui.newButton()
        expect_equal("", btn.getText())
    end)

    -- @description Verifies setText replaces the initial label "A" with "B".
    it("can set and get text", function()
        local btn = lurek.ui.newButton("A")
        btn.setText("B")
        expect_equal("B", btn.getText())
    end)
end)

-- =========================================================================
-- 3. Label
-- =========================================================================
-- @description Covers label creation from an initial string and subsequent text replacement.
describe("lurek.ui Label", function()
    -- @description Verifies newLabel("Hello") returns a label whose text is "Hello".
    it("creates a label with text", function()
        local lbl = lurek.ui.newLabel("Hello")
        expect_equal("Hello", lbl.getText())
    end)

    -- @description Verifies setText changes a label from "old" to "new".
    it("can update text", function()
        local lbl = lurek.ui.newLabel("old")
        lbl.setText("new")
        expect_equal("new", lbl.getText())
    end)
end)

-- =========================================================================
-- 4. TextInput
-- =========================================================================
-- @description Covers text input defaults, text storage, placeholder storage, and max length acceptance.
describe("lurek.ui TextInput", function()
    -- @description Verifies a fresh text input starts with an empty string.
    it("creates with empty text", function()
        local ti = lurek.ui.newTextInput()
        expect_equal("", ti.getText())
    end)

    -- @description Verifies setText stores "hello" and getText returns the same string.
    it("can set and get text", function()
        local ti = lurek.ui.newTextInput()
        ti.setText("hello")
        expect_equal("hello", ti.getText())
    end)

    -- @description Verifies setPlaceholder stores "Enter name..." and getPlaceholder returns it verbatim.
    it("can set placeholder", function()
        local ti = lurek.ui.newTextInput()
        ti.setPlaceholder("Enter name...")
        expect_equal("Enter name...", ti.getPlaceholder())
    end)

    -- @description Verifies setMaxLength accepts the value 10 without raising an error.
    it("can set max length", function()
        local ti = lurek.ui.newTextInput()
        ti.setMaxLength(10)
        -- No getter exposed; just verify no error
    end)
end)

-- =========================================================================
-- 5. CheckBox
-- =========================================================================
-- @description Covers checkbox default selection, explicit checked state changes, and label mutation.
describe("lurek.ui CheckBox", function()
    -- @description Verifies a new checkbox starts unchecked.
    it("creates unchecked by default", function()
        local cb = lurek.ui.newCheckbox("Option")
        expect_equal(false, cb.isChecked())
    end)

    -- @description Verifies setChecked flips the checkbox to true and then back to false.
    it("can toggle checked state", function()
        local cb = lurek.ui.newCheckbox("Toggle")
        cb.setChecked(true)
        expect_equal(true, cb.isChecked())
        cb.setChecked(false)
        expect_equal(false, cb.isChecked())
    end)

    -- @description Verifies setText replaces the checkbox label "old" with "new".
    it("can set and get text", function()
        local cb = lurek.ui.newCheckbox("old")
        cb.setText("new")
        expect_equal("new", cb.getText())
    end)
end)

-- =========================================================================
-- 6. Slider
-- =========================================================================
-- @description Covers slider default range, custom range, value clamping, and step snapping behavior.
describe("lurek.ui Slider", function()
    -- @description Verifies a default slider reports min 0 and max 100.
    it("creates with min/max defaults", function()
        local sl = lurek.ui.newSlider()
        expect_equal(0, sl.getMin())
        expect_equal(100, sl.getMax())
    end)

    -- @description Verifies newSlider(10, 50) reports the exact custom range 10 through 50.
    it("creates with custom min/max", function()
        local sl = lurek.ui.newSlider(10, 50)
        expect_equal(10, sl.getMin())
        expect_equal(50, sl.getMax())
    end)

    -- @description Verifies setValue clamps 150 down to 100 and -10 up to 0 for a 0..100 slider.
    it("clamps value to range", function()
        local sl = lurek.ui.newSlider(0, 100)
        sl.setValue(150)
        expect_equal(100, sl.getValue())
        sl.setValue(-10)
        expect_equal(0, sl.getValue())
    end)

    -- @description Verifies a step of 10 snaps an assigned value of 23 down to 20.
    it("can set step", function()
        local sl = lurek.ui.newSlider(0, 100)
        sl.setStep(10)
        sl.setValue(23)
        expect_equal(20, sl.getValue())
    end)
end)

-- =========================================================================
-- 7. ProgressBar
-- =========================================================================
-- @description Covers progress bar default range, explicit range construction, and value storage.
describe("lurek.ui ProgressBar", function()
    -- @description Verifies a default progress bar reports min 0 and max 100.
    it("creates with defaults", function()
        local pb = lurek.ui.newProgressBar()
        expect_equal(0, pb.getMin())
        expect_equal(100, pb.getMax())
    end)

    -- @description Verifies newProgressBar(0, 100) preserves the provided bounds.
    it("creates with custom range", function()
        local pb = lurek.ui.newProgressBar(0, 100)
        expect_equal(0, pb.getMin())
        expect_equal(100, pb.getMax())
    end)

    -- @description Verifies setValue stores 42 and getValue returns 42.
    it("can set and get value", function()
        local pb = lurek.ui.newProgressBar(0, 100)
        pb.setValue(42)
        expect_equal(42, pb.getValue())
    end)
end)

-- =========================================================================
-- 8. ComboBox
-- =========================================================================
-- @description Covers combo box item management, 1-based lookup, selection state, removal, and clearing.
describe("lurek.ui ComboBox", function()
    -- @description Verifies a new combo box starts with zero items.
    it("creates empty", function()
        local cb = lurek.ui.newComboBox()
        expect_equal(0, cb.getItemCount())
    end)

    -- @description Verifies adding Apple, Banana, and Cherry increases the item count to 3.
    it("can add items", function()
        local cb = lurek.ui.newComboBox()
        cb.addItem("Apple")
        cb.addItem("Banana")
        cb.addItem("Cherry")
        expect_equal(3, cb.getItemCount())
    end)

    -- @description Verifies 1-based item lookup returns "First" at index 1 and "Second" at index 2.
    it("can get item by index (1-based)", function()
        local cb = lurek.ui.newComboBox()
        cb.addItem("First")
        cb.addItem("Second")
        expect_equal("First", cb.getItem(1))
        expect_equal("Second", cb.getItem(2))
    end)

    -- @description Verifies out-of-bounds lookup returns nil when only one item exists.
    it("returns nil for out-of-bounds index", function()
        local cb = lurek.ui.newComboBox()
        cb.addItem("Only")
        expect_equal(nil, cb.getItem(5))
    end)

    -- @description Verifies selecting index 2 stores that selection and getSelectedIndex returns 2.
    it("can select and get selected index", function()
        local cb = lurek.ui.newComboBox()
        cb.addItem("A")
        cb.addItem("B")
        cb.setSelectedIndex(2)
        expect_equal(2, cb.getSelectedIndex())
    end)

    -- @description Verifies removing the first item succeeds and leaves exactly one item.
    it("can remove item", function()
        local cb = lurek.ui.newComboBox()
        cb.addItem("A")
        cb.addItem("B")
        local ok = cb.removeItem(1)
        expect_equal(true, ok)
        expect_equal(1, cb.getItemCount())
    end)

    -- @description Verifies clearItems empties the combo box back to an item count of 0.
    it("can clear all items", function()
        local cb = lurek.ui.newComboBox()
        cb.addItem("A")
        cb.addItem("B")
        cb.clearItems()
        expect_equal(0, cb.getItemCount())
    end)
end)

-- =========================================================================
-- 9. ListBox
-- =========================================================================
-- @description Covers list creation and 1-based retrieval after inserting items.
describe("lurek.ui ListBox", function()
    -- @description Verifies a new list starts with zero items.
    it("creates empty", function()
        local lb = lurek.ui.newList()
        expect_equal(0, lb.getItemCount())
    end)

    -- @description Verifies adding X and Y stores both items and keeps 1-based retrieval order.
    it("can add and get items", function()
        local lb = lurek.ui.newList()
        lb.addItem("X")
        lb.addItem("Y")
        expect_equal(2, lb.getItemCount())
        expect_equal("X", lb.getItem(1))
        expect_equal("Y", lb.getItem(2))
    end)
end)

-- =========================================================================
-- 10. TabBar
-- =========================================================================
-- @description Covers tab bar creation, tab insertion, 1-based label lookup, active tab state, and removal.
describe("lurek.ui TabBar", function()
    -- @description Verifies a new tab bar starts with zero tabs.
    it("creates empty", function()
        local tb = lurek.ui.newTabBar()
        expect_equal(0, tb.getTabCount())
    end)

    -- @description Verifies adding General, Settings, and About produces a tab count of 3.
    it("can add tabs", function()
        local tb = lurek.ui.newTabBar()
        tb.addTab("General")
        tb.addTab("Settings")
        tb.addTab("About")
        expect_equal(3, tb.getTabCount())
    end)

    -- @description Verifies 1-based tab lookup returns "First" and "Second" at indices 1 and 2.
    it("can get tab label (1-based)", function()
        local tb = lurek.ui.newTabBar()
        tb.addTab("First")
        tb.addTab("Second")
        expect_equal("First", tb.getTab(1))
        expect_equal("Second", tb.getTab(2))
    end)

    -- @description Verifies setActiveTab(2) makes tab 2 the active tab.
    it("can set active tab (1-based)", function()
        local tb = lurek.ui.newTabBar()
        tb.addTab("A")
        tb.addTab("B")
        tb.setActiveTab(2)
        expect_equal(2, tb.getActiveTab())
    end)

    -- @description Verifies removing the first tab succeeds and leaves one remaining tab.
    it("can remove tab", function()
        local tb = lurek.ui.newTabBar()
        tb.addTab("A")
        tb.addTab("B")
        local ok = tb.removeTab(1)
        expect_equal(true, ok)
        expect_equal(1, tb.getTabCount())
    end)
end)

-- =========================================================================
-- 11. Base widget methods (position, size, visibility, etc.)
-- =========================================================================
-- @description Covers common widget APIs for geometry, visibility, enablement, identity, padding, margins, hit testing, size constraints, flex values, and state reporting.
describe("lurek.ui widget base methods", function()
    -- @description Verifies setPosition(100, 200) is returned exactly by getPosition().
    it("can set and get position", function()
        local btn = lurek.ui.newButton("Pos")
        btn.setPosition(100, 200)
        local x, y = btn.getPosition()
        expect_equal(100, x)
        expect_equal(200, y)
    end)

    -- @description Verifies setSize(300, 150) is returned exactly by getSize().
    it("can set and get size", function()
        local btn = lurek.ui.newButton("Size")
        btn.setSize(300, 150)
        local w, h = btn.getSize()
        expect_equal(300, w)
        expect_equal(150, h)
    end)

    -- @description Verifies widgets start visible and report false after setVisible(false).
    it("can set and get visibility", function()
        local btn = lurek.ui.newButton("Vis")
        expect_equal(true, btn.isVisible())
        btn.setVisible(false)
        expect_equal(false, btn.isVisible())
    end)

    -- @description Verifies widgets start enabled and report false after setEnabled(false).
    it("can set and get enabled state", function()
        local btn = lurek.ui.newButton("En")
        expect_equal(true, btn.isEnabled())
        btn.setEnabled(false)
        expect_equal(false, btn.isEnabled())
    end)

    -- @description Verifies setId stores "my_button" and getId returns it.
    it("can set and get id", function()
        local btn = lurek.ui.newButton("Id")
        btn.setId("my_button")
        expect_equal("my_button", btn.getId())
    end)

    -- @description Verifies setTooltip stores "Click me!" and getTooltip returns it.
    it("can set and get tooltip", function()
        local btn = lurek.ui.newButton("Tip")
        btn.setTooltip("Click me!")
        expect_equal("Click me!", btn.getTooltip())
    end)

    -- @description Verifies setZOrder stores the integer z-order 10.
    it("can set and get z-order", function()
        local btn = lurek.ui.newButton("Z")
        btn.setZOrder(10)
        expect_equal(10, btn.getZOrder())
    end)

    -- @description Verifies four-value padding stores top 1, right 2, bottom 3, and left 4.
    it("can set and get padding (4 values)", function()
        local btn = lurek.ui.newButton("Pad")
        btn.setPadding(1, 2, 3, 4)
        local t, r, b, l = btn.getPadding()
        expect_equal(1, t)
        expect_equal(2, r)
        expect_equal(3, b)
        expect_equal(4, l)
    end)

    -- @description Verifies single-value padding of 5 is expanded uniformly to all four sides.
    it("can set padding (1 value = uniform)", function()
        local btn = lurek.ui.newButton("Pad1")
        btn.setPadding(5)
        local t, r, b, l = btn.getPadding()
        expect_equal(5, t)
        expect_equal(5, r)
        expect_equal(5, b)
        expect_equal(5, l)
    end)

    -- @description Verifies four-value margins store 10, 20, 10, and 20 in top, right, bottom, left order.
    it("can set and get margin", function()
        local btn = lurek.ui.newButton("Mar")
        btn.setMargin(10, 20, 10, 20)
        local t, r, b, l = btn.getMargin()
        expect_equal(10, t)
        expect_equal(20, r)
        expect_equal(10, b)
        expect_equal(20, l)
    end)

    -- @description Verifies hit testing returns true inside a 10,20,100,50 button and false for a far outside point.
    it("contains point hit test", function()
        local btn = lurek.ui.newButton("Hit")
        btn.setPosition(10, 20)
        btn.setSize(100, 50)
        expect_equal(true, btn.containsPoint(50, 40))
        expect_equal(false, btn.containsPoint(200, 200))
    end)

    -- @description Verifies setMinSize(50, 25) is returned exactly by getMinSize().
    it("can set and get min size", function()
        local btn = lurek.ui.newButton("Min")
        btn.setMinSize(50, 25)
        local w, h = btn.getMinSize()
        expect_equal(50, w)
        expect_equal(25, h)
    end)

    -- @description Verifies setMaxSize(500, 300) is returned exactly by getMaxSize().
    it("can set and get max size", function()
        local btn = lurek.ui.newButton("Max")
        btn.setMaxSize(500, 300)
        local w, h = btn.getMaxSize()
        expect_equal(500, w)
        expect_equal(300, h)
    end)

    -- @description Verifies flex grow stores 2.0 and flex shrink stores 0.5.
    it("can set flex grow and shrink", function()
        local btn = lurek.ui.newButton("Flex")
        btn.setFlexGrow(2.0)
        expect_equal(2.0, btn.getFlexGrow())
        btn.setFlexShrink(0.5)
        expect_equal(0.5, btn.getFlexShrink())
    end)

    -- @description Verifies getState returns a string and the initial state is exactly "normal".
    it("getState returns a string", function()
        local btn = lurek.ui.newButton("State")
        local s = btn.getState()
        expect_type("string", s)
        expect_equal("normal", s)
    end)
end)

-- =========================================================================
-- 12. Panel (container)
-- =========================================================================
-- @description Covers panel construction plus child insertion, counting, and removal.
describe("lurek.ui Panel", function()
    -- @description Verifies newPanel returns a panel table.
    it("creates a panel", function()
        local p = lurek.ui.newPanel()
        expect_type("table", p)
    end)

    -- @description Verifies adding two buttons makes the panel report two children.
    it("can add and count children", function()
        local p = lurek.ui.newPanel()
        local b1 = lurek.ui.newButton("A")
        local b2 = lurek.ui.newButton("B")
        p.addChild(b1)
        p.addChild(b2)
        expect_equal(2, p.getChildCount())
    end)

    -- @description Verifies removing an added child drops the panel child count from 1 back to 0.
    it("can remove children", function()
        local p = lurek.ui.newPanel()
        local b = lurek.ui.newButton("X")
        p.addChild(b)
        expect_equal(1, p.getChildCount())
        p.removeChild(b)
        expect_equal(0, p.getChildCount())
    end)
end)

-- =========================================================================
-- 13. Layout
-- =========================================================================
-- @description Covers layout direction defaults, direction changes, spacing, alignment, and justification.
describe("lurek.ui Layout", function()
    -- @description Verifies a default layout starts with the direction "vertical".
    it("creates with default vertical direction", function()
        local ly = lurek.ui.newLayout()
        expect_equal("vertical", ly.getDirection())
    end)

    -- @description Verifies newLayout("horizontal") preserves the horizontal direction.
    it("creates with specified direction", function()
        local ly = lurek.ui.newLayout("horizontal")
        expect_equal("horizontal", ly.getDirection())
    end)

    -- @description Verifies setDirection can change the layout direction to "grid".
    it("can change direction", function()
        local ly = lurek.ui.newLayout()
        ly.setDirection("grid")
        expect_equal("grid", ly.getDirection())
    end)

    -- @description Verifies setSpacing stores the integer spacing value 10.
    it("can set spacing", function()
        local ly = lurek.ui.newLayout()
        ly.setSpacing(10)
        expect_equal(10, ly.getSpacing())
    end)

    -- @description Verifies setAlign stores the alignment string "center".
    it("can set alignment", function()
        local ly = lurek.ui.newLayout()
        ly.setAlign("center")
        expect_equal("center", ly.getAlign())
    end)

    -- @description Verifies setJustify stores the justification string "space-between".
    it("can set justification", function()
        local ly = lurek.ui.newLayout()
        ly.setJustify("space-between")
        expect_equal("space-between", ly.getJustify())
    end)
end)

-- =========================================================================
-- 14. ScrollPanel
-- =========================================================================
-- @description Covers scroll panel construction, content sizing, scroll position storage, and scroll speed acceptance.
describe("lurek.ui ScrollPanel", function()
    -- @description Verifies newScrollPanel returns a panel table.
    it("creates a scroll panel", function()
        local sp = lurek.ui.newScrollPanel()
        expect_type("table", sp)
    end)

    -- @description Verifies setContentSize(800, 600) is returned exactly by getContentSize().
    it("can set and get content size", function()
        local sp = lurek.ui.newScrollPanel()
        sp.setContentSize(800, 600)
        local w, h = sp.getContentSize()
        expect_equal(800, w)
        expect_equal(600, h)
    end)

    -- @description Verifies setScrollPosition(50, 100) is returned exactly by getScrollPosition().
    it("can set and get scroll position", function()
        local sp = lurek.ui.newScrollPanel()
        sp.setContentSize(500, 500)
        sp.setScrollPosition(50, 100)
        local sx, sy = sp.getScrollPosition()
        expect_equal(50, sx)
        expect_equal(100, sy)
    end)

    -- @description Verifies setScrollSpeed accepts the numeric value 2.0 without raising an error.
    it("can set scroll speed", function()
        local sp = lurek.ui.newScrollPanel()
        sp.setScrollSpeed(2.0)
        -- No getter, just verify no error
    end)
end)

-- =========================================================================
-- 15. NinePatch
-- =========================================================================
-- @description Covers nine-patch widget construction.
describe("lurek.ui NinePatch", function()
    -- @description Verifies newNinePatch returns a widget table.
    it("creates a nine-patch widget", function()
        local np = lurek.ui.newNinePatch()
        expect_type("table", np)
    end)
end)

-- =========================================================================
-- 16. Separator
-- =========================================================================
-- @description Covers separator construction for both the default horizontal case and the explicit vertical case.
describe("lurek.ui Separator", function()
    -- @description Verifies a default separator can be created and returns a table.
    it("creates horizontal separator by default", function()
        local sep = lurek.ui.newSeparator()
        expect_type("table", sep)
    end)

    -- @description Verifies newSeparator(true) creates a vertical separator and returns a table.
    it("creates vertical separator", function()
        local sep = lurek.ui.newSeparator(true)
        expect_type("table", sep)
    end)
end)

-- =========================================================================
-- 17. Spacer
-- =========================================================================
-- @description Covers spacer construction with default dimensions and explicit custom dimensions.
describe("lurek.ui Spacer", function()
    -- @description Verifies a default spacer can be created and returns a table.
    it("creates a spacer with default size", function()
        local sp = lurek.ui.newSpacer()
        expect_type("table", sp)
    end)

    -- @description Verifies newSpacer(50, 25) reports width 50 and height 25.
    it("creates a spacer with custom size", function()
        local sp = lurek.ui.newSpacer(50, 25)
        local w, h = sp.getSize()
        expect_equal(50, w)
        expect_equal(25, h)
    end)
end)

-- =========================================================================
-- 18. Toast
-- =========================================================================
-- @description Covers toast construction and registration with the global toast context.
describe("lurek.ui Toast", function()
    -- @description Verifies newToast("Hello!", 3.0) returns a toast table.
    it("creates a toast", function()
        local t = lurek.ui.newToast("Hello!", 3.0)
        expect_type("table", t)
    end)

    -- @description Verifies addToast increases the global toast count to at least 1 after adding a toast.
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
-- @description Covers tree view node insertion, hierarchy, selection, expansion, text mutation, icon assignment, removal, clearing, and ancestry queries.
describe("lurek.ui TreeView", function()
    -- @description Verifies a new tree view starts with zero nodes.
    it("creates empty tree", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(0, tv.getNodeCount())
    end)

    -- @description Verifies adding two root nodes returns numeric indices and increases the node count to 2.
    it("can add root nodes", function()
        local tv = lurek.ui.newTreeView()
        local idx1 = tv.addNode("Root 1")
        local idx2 = tv.addNode("Root 2")
        expect_equal(2, tv.getNodeCount())
        expect_type("number", idx1)
        expect_type("number", idx2)
    end)

    -- @description Verifies adding a child under a root node increases the node count to 2 and returns a numeric child index.
    it("can add child nodes", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Parent")
        local child = tv.addNode("Child", root)
        expect_equal(2, tv.getNodeCount())
        expect_type("number", child)
    end)

    -- @description Verifies toggleNode returns a boolean when toggling a root node.
    it("can toggle node expansion", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Root")
        -- toggle returns boolean
        local expanded = tv.toggleNode(root)
        expect_type("boolean", expanded)
    end)

    -- @description Verifies removing node 1 succeeds and reduces the node count from 2 to 1.
    it("can remove a node", function()
        local tv = lurek.ui.newTreeView()
        tv.addNode("A")
        tv.addNode("B")
        expect_equal(2, tv.getNodeCount())
        local ok = tv.removeNode(1)
        expect_equal(true, ok)
        expect_equal(1, tv.getNodeCount())
    end)

    -- @description Verifies removeNode returns false for an invalid index when the tree is empty.
    it("removeNode returns false for invalid index", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(false, tv.removeNode(5))
    end)

    -- @description Verifies clearNodes removes all nodes and resets the count to 0.
    it("can clear all nodes", function()
        local tv = lurek.ui.newTreeView()
        tv.addNode("A")
        tv.addNode("B")
        tv.clearNodes()
        expect_equal(0, tv.getNodeCount())
    end)

    -- @description Verifies node text can be read as "Original", changed to "Changed", and read back again.
    it("can get and set node text", function()
        local tv = lurek.ui.newTreeView()
        local idx = tv.addNode("Original")
        expect_equal("Original", tv.getNodeText(idx))
        local ok = tv.setNodeText(idx, "Changed")
        expect_equal(true, ok)
        expect_equal("Changed", tv.getNodeText(idx))
    end)

    -- @description Verifies assigning the icon path "folder.png" to a node returns true.
    it("can set node icon", function()
        local tv = lurek.ui.newTreeView()
        local idx = tv.addNode("Folder")
        local ok = tv.setNodeIcon(idx, "folder.png")
        expect_equal(true, ok)
    end)

    -- @description Verifies expandNode marks a root expanded, collapseNode marks it collapsed, and both calls return true.
    it("can expand and collapse a node", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Root")
        tv.addNode("Child", root)
        expect_equal(true, tv.expandNode(root))
        expect_equal(true, tv.isNodeExpanded(root))
        expect_equal(true, tv.collapseNode(root))
        expect_equal(false, tv.isNodeExpanded(root))
    end)

    -- @description Verifies isNodeExpanded returns nil for an out-of-range node index.
    it("isNodeExpanded returns nil for invalid index", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(nil, tv.isNodeExpanded(99))
    end)

    -- @description Verifies expandAll marks a parent expanded and collapseAll clears that expanded state again.
    it("can expand and collapse all", function()
        local tv = lurek.ui.newTreeView()
        local r1 = tv.addNode("R1")
        tv.addNode("C1", r1)
        tv.expandAll()
        expect_equal(true, tv.isNodeExpanded(r1))
        tv.collapseAll()
        expect_equal(false, tv.isNodeExpanded(r1))
    end)

    -- @description Verifies setSelectedNode accepts a valid node index and getSelectedNode returns the same index.
    it("can set and get selected node", function()
        local tv = lurek.ui.newTreeView()
        local idx = tv.addNode("Node")
        expect_equal(true, tv.setSelectedNode(idx))
        expect_equal(idx, tv.getSelectedNode())
    end)

    -- @description Verifies getSelectedNode returns nil when no node has been selected.
    it("getSelectedNode returns nil when none selected", function()
        local tv = lurek.ui.newTreeView()
        expect_equal(nil, tv.getSelectedNode())
    end)

    -- @description Verifies getChildNodes returns a table containing the two child indices in insertion order.
    it("can get child nodes (1-based)", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Root")
        local c1 = tv.addNode("Child1", root)
        local c2 = tv.addNode("Child2", root)
        local children = tv.getChildNodes(root)
        expect_type("table", children)
        expect_equal(2, #children)
        expect_equal(c1, children[1])
        expect_equal(c2, children[2])
    end)

    -- @description Verifies getParentNode returns the root index for a direct child node.
    it("can get parent node", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Root")
        local child = tv.addNode("Child", root)
        expect_equal(root, tv.getParentNode(child))
    end)

    -- @description Verifies a root node reports nil as its parent.
    it("root node has nil parent", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Root")
        expect_equal(nil, tv.getParentNode(root))
    end)

    -- @description Verifies node depth reports 0 for the root, 1 for its child, and 2 for its grandchild.
    it("can get node depth", function()
        local tv = lurek.ui.newTreeView()
        local root = tv.addNode("Root")
        local child = tv.addNode("Child", root)
        local grand = tv.addNode("Grand", child)
        expect_equal(0, tv.getNodeDepth(root))
        expect_equal(1, tv.getNodeDepth(child))
        expect_equal(2, tv.getNodeDepth(grand))
    end)
end)

-- =========================================================================
-- 20. Widget count & root
-- =========================================================================
-- @description Covers the global widget count accessor and root widget accessor.
describe("lurek.ui widget count", function()
    -- @description Verifies getWidgetCount returns a non-negative number.
    it("getWidgetCount returns a number", function()
        local count = lurek.ui.getWidgetCount()
        expect_type("number", count)
        expect_equal(true, count >= 0)
    end)

    -- @description Verifies getRoot returns a table representing the UI root.
    it("getRoot returns a table", function()
        local root = lurek.ui.getRoot()
        expect_type("table", root)
    end)
end)

-- =========================================================================
-- 21. Focus management
-- =========================================================================
-- @description Covers clearing focus, reading empty focus, setting focus to a widget, and moving focus forward.
describe("lurek.ui focus", function()
    -- @description Verifies clearFocus can be called directly without raising an error.
    it("clearFocus works without error", function()
        lurek.ui.clearFocus()
    end)

    -- @description Verifies getFocus returns nil immediately after focus is cleared.
    it("getFocus returns nil when no focus", function()
        lurek.ui.clearFocus()
        local f = lurek.ui.getFocus()
        expect_equal(nil, f)
    end)

    -- @description Verifies setting focus to a new button makes getFocus return a numeric handle.
    it("setFocus and getFocus work", function()
        local btn = lurek.ui.newButton("Focus Test")
        lurek.ui.setFocus(btn)
        local f = lurek.ui.getFocus()
        expect_type("number", f)
    end)

    -- @description Verifies focusNext can advance focus from one button to another and still yields a numeric focus handle.
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
-- @description Covers the boolean return contract for all tested mouse, keyboard, text, and wheel routing calls.
describe("lurek.ui input routing", function()
    -- @description Verifies mousepressed(100, 100, 1) returns a boolean consumed flag.
    it("mousepressed returns boolean", function()
        local consumed = lurek.ui.mousepressed(100, 100, 1)
        expect_type("boolean", consumed)
    end)

    -- @description Verifies mousereleased(100, 100, 1) returns a boolean consumed flag.
    it("mousereleased returns boolean", function()
        local consumed = lurek.ui.mousereleased(100, 100, 1)
        expect_type("boolean", consumed)
    end)

    -- @description Verifies mousemoved(100, 100, 0, 0) returns a boolean consumed flag.
    it("mousemoved returns boolean", function()
        local consumed = lurek.ui.mousemoved(100, 100)
        expect_type("boolean", consumed)
    end)

    -- @description Verifies keypressed("tab") returns a boolean consumed flag.
    it("keypressed returns boolean", function()
        local consumed = lurek.ui.keypressed("tab")
        expect_type("boolean", consumed)
    end)

    -- @description Verifies textinput("a") returns a boolean consumed flag.
    it("textinput returns boolean", function()
        local consumed = lurek.ui.textinput("a")
        expect_type("boolean", consumed)
    end)

    -- @description Verifies wheelmoved(0, -1) returns a boolean consumed flag.
    it("wheelmoved returns boolean", function()
        local consumed = lurek.ui.wheelmoved(0, -1)
        expect_type("boolean", consumed)
    end)
end)

-- =========================================================================
-- 23. Update & draw (headless: no-op but should not error)
-- =========================================================================
-- @description Covers headless-safe update and draw calls to ensure both entry points can be invoked without assertions failing.
describe("lurek.ui update and draw", function()
    -- @description Verifies update accepts a frame delta of 0.016 without raising an error.
    it("update runs without error", function()
        lurek.ui.update(0.016)
    end)

    -- @description Verifies draw can be called in the test harness without raising an error.
    it("draw runs without error", function()
        lurek.ui.draw()
    end)
end)

-- =========================================================================
-- 24. Theme
-- =========================================================================
-- @description Covers theme construction and the global setTheme/getTheme interaction as currently exposed.
describe("lurek.ui Theme", function()
    -- @description Verifies newTheme returns userdata.
    it("creates a theme", function()
        local theme = lurek.ui.newTheme()
        expect_type("userdata", theme)
    end)

    -- @description Verifies setTheme accepts a new theme and getTheme currently returns a boolean.
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
-- @description Exercises findById after assigning a unique widget id, without asserting the exact returned object.
describe("lurek.ui findById", function()
    -- @description Creates a button with id "unique_btn" and calls findById on that id to cover the lookup path.
    it("finds a widget by id", function()
        local btn = lurek.ui.newButton("Find Me")
        btn.setId("unique_btn")
        local found = btn.findById("unique_btn")
        -- findById searches from root; returned widget is a table or nil
        -- Since btn is the one with the id, it should find itself
        -- Note: depends on context-wide search
    end)
end)

-- =========================================================================
-- 26. Callbacks (onClick, onChange, onDraw)
-- =========================================================================
-- @description Covers registering click, change, and draw callbacks without invoking them.
describe("lurek.ui callbacks", function()
    -- @description Verifies setOnClick accepts a closure that would flip the clicked flag if invoked.
    it("setOnClick accepts a function", function()
        local btn = lurek.ui.newButton("Clickable")
        local clicked = false
        btn.setOnClick(function()
            clicked = true
        end)
        -- Callback is stored but not invoked here
    end)

    -- @description Verifies setOnChange accepts a function taking the changed slider value.
    it("setOnChange accepts a function", function()
        local sl = lurek.ui.newSlider(0, 100)
        sl.setOnChange(function(val) end)
    end)

    -- @description Verifies setOnDraw accepts a draw callback on a panel.
    xit("setOnDraw accepts a function", function()
        local p = lurek.ui.newPanel()
        p.setOnDraw(function() end)
    end)
end)

-- =========================================================================
-- 22. RadioButton
-- =========================================================================
-- @description Covers radio button creation, label text, selection state, group storage, and inherited widget methods.
describe("lurek.ui.newRadioButton", function()
    -- @description Verifies newRadioButton("Option A", "group1") returns a table.
    it("creates a radio button", function()
        local rb = lurek.ui.newRadioButton("Option A", "group1")
        expect_type("table", rb)
    end)
    -- @description Verifies the radio button text is stored as "Opt".
    it("has correct text", function()
        local rb = lurek.ui.newRadioButton("Opt", "g")
        expect_equal("Opt", rb.getText())
    end)
    -- @description Verifies a new radio button starts unselected.
    it("defaults to not selected", function()
        local rb = lurek.ui.newRadioButton("X", "g")
        expect_equal(false, rb.isSelected())
    end)
    -- @description Verifies setSelected(true) makes the radio button report selected.
    it("can set selected", function()
        local rb = lurek.ui.newRadioButton("X", "g")
        rb.setSelected(true)
        expect_equal(true, rb.isSelected())
    end)
    -- @description Verifies the provided group name "mygroup" is returned by getGroup().
    it("has group", function()
        local rb = lurek.ui.newRadioButton("X", "mygroup")
        expect_equal("mygroup", rb.getGroup())
    end)
    -- @description Verifies radio buttons expose base widget methods such as setPosition, setSize, and setVisible.
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
-- @description Covers scroll bar creation, default scroll metrics, position updates, size updates, and orientation persistence.
describe("lurek.ui.newScrollBar", function()
    -- @description Verifies newScrollBar(true) returns a table.
    it("creates a scroll bar", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_type("table", sb)
    end)
    -- @description Verifies a new scroll bar starts at scroll position 0.
    it("defaults position to 0", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_near(0, sb.getScrollPosition(), 0.001)
    end)
    -- @description Verifies setScrollPosition(42) is returned approximately by getScrollPosition().
    it("can set position", function()
        local sb = lurek.ui.newScrollBar(false)
        sb.setScrollPosition(42)
        expect_near(42, sb.getScrollPosition(), 0.001)
    end)
    -- @description Verifies the default content size is approximately 100.
    it("default content size is 100", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_near(100, sb.getContentSize(), 0.001)
    end)
    -- @description Verifies the default view size is approximately 50.
    it("default view size is 50", function()
        local sb = lurek.ui.newScrollBar(true)
        expect_near(50, sb.getViewSize(), 0.001)
    end)
    -- @description Verifies content size 200 and view size 80 are stored and read back approximately.
    it("can set content and view sizes", function()
        local sb = lurek.ui.newScrollBar(true)
        sb.setContentSize(200)
        sb.setViewSize(80)
        expect_near(200, sb.getContentSize(), 0.001)
        expect_near(80, sb.getViewSize(), 0.001)
    end)
    -- @description Verifies the vertical flag remains true for one scrollbar and false for another.
    it("vertical flag persists", function()
        local v = lurek.ui.newScrollBar(true)
        local h = lurek.ui.newScrollBar(false)
        expect_equal(true, v.isVertical())
        expect_equal(false, h.isVertical())
    end)
end)

-- =========================================================================
-- 24. GUIWindow
-- =========================================================================
-- @description Covers window construction, default window flags, title storage, and child insertion by widget index.
describe("lurek.ui.newWindow", function()
    -- @description Verifies newWindow("Title") returns a table.
    it("creates a window", function()
        local w = lurek.ui.newWindow("Title")
        expect_type("table", w)
    end)
    -- @description Verifies the title "My Win" is returned by getTitle().
    it("has correct title", function()
        local w = lurek.ui.newWindow("My Win")
        expect_equal("My Win", w.getTitle())
    end)
    -- @description Verifies windows default to closeable = true.
    it("defaults closeable true", function()
        local w = lurek.ui.newWindow("W")
        expect_equal(true, w.isCloseable())
    end)
    -- @description Verifies windows default to draggable = true.
    it("defaults draggable true", function()
        local w = lurek.ui.newWindow("W")
        expect_equal(true, w.isDraggable())
    end)
    -- @description Verifies windows default to resizable = false.
    it("defaults resizable false", function()
        local w = lurek.ui.newWindow("W")
        expect_equal(false, w.isResizable())
    end)
    -- @description Verifies setCloseable(false) makes isCloseable() return false.
    it("can toggle closeable", function()
        local w = lurek.ui.newWindow("W")
        w.setCloseable(false)
        expect_equal(false, w.isCloseable())
    end)
    -- @description Verifies adding a button child by index produces exactly one child entry.
    it("can add child", function()
        local w = lurek.ui.newWindow("W")
        local btn = lurek.ui.newButton("B")
        w.addChild(btn._idx)
        expect_equal(1, #w.getChildren())
    end)
end)

-- =========================================================================
-- 25. SplitPanel
-- =========================================================================
-- @description Covers split panel creation, orientation, default split ratio, split ratio updates, and minimum panel size updates.
describe("lurek.ui.newSplitPanel", function()
    -- @description Verifies newSplitPanel("horizontal") returns a table.
    it("creates a split panel", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        expect_type("table", sp)
    end)
    -- @description Verifies the orientation string "vertical" is preserved.
    it("has correct orientation", function()
        local sp = lurek.ui.newSplitPanel("vertical")
        expect_equal("vertical", sp.getOrientation())
    end)
    -- @description Verifies a new split panel starts with a split position of approximately 0.5.
    it("default split position is 0.5", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        expect_near(0.5, sp.getSplitPosition(), 0.001)
    end)
    -- @description Verifies setSplitPosition(0.3) is returned approximately by getSplitPosition().
    it("can set split position", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        sp.setSplitPosition(0.3)
        expect_near(0.3, sp.getSplitPosition(), 0.001)
    end)
    -- @description Verifies setMinPanelSize(100) is returned approximately by getMinPanelSize().
    it("can set min panel size", function()
        local sp = lurek.ui.newSplitPanel("horizontal")
        sp.setMinPanelSize(100)
        expect_near(100, sp.getMinPanelSize(), 0.001)
    end)
end)

-- =========================================================================
-- 26. DockPanel
-- =========================================================================
-- @description Covers dock panel creation, dock count defaults, docking a child, and split size storage.
describe("lurek.ui.newDockPanel", function()
    -- @description Verifies newDockPanel returns a table.
    it("creates a dock panel", function()
        local dp = lurek.ui.newDockPanel()
        expect_type("table", dp)
    end)
    -- @description Verifies a new dock panel starts with zero docked widgets.
    it("starts with 0 docked", function()
        local dp = lurek.ui.newDockPanel()
        expect_equal(0, dp.getDockedCount())
    end)
    -- @description Verifies docking a button on the left increases the docked count to 1.
    it("can dock a child", function()
        local dp = lurek.ui.newDockPanel()
        local btn = lurek.ui.newButton("B")
        dp.dock(btn._idx, "left")
        expect_equal(1, dp.getDockedCount())
    end)
    -- @description Verifies setSplitSize("left", 200) is returned approximately by getSplitSize("left").
    it("can set split size", function()
        local dp = lurek.ui.newDockPanel()
        dp.setSplitSize("left", 200)
        expect_near(200, dp.getSplitSize("left"), 0.001)
    end)
end)

-- =========================================================================
-- 27. Toolbar
-- =========================================================================
-- @description Covers toolbar construction, orientation, child insertion, button registry behavior, separators, spacers, and button state helpers.
describe("lurek.ui.newToolbar", function()
    -- @description Verifies newToolbar("horizontal") returns a table.
    it("creates a toolbar", function()
        local tb = lurek.ui.newToolbar("horizontal")
        expect_type("table", tb)
    end)
    -- @description Verifies a vertical toolbar reports the orientation string "vertical".
    it("has orientation", function()
        local tb = lurek.ui.newToolbar("vertical")
        expect_equal("vertical", tb.getOrientation())
    end)
    -- @description Verifies adding a button child by index increases the child count to 1.
    it("can add child", function()
        local tb = lurek.ui.newToolbar("horizontal")
        local btn = lurek.ui.newButton("B")
        tb.addChild(btn._idx)
        expect_equal(1, tb.getChildCount())
    end)

    -- @description Verifies addButton returns 1 for the first button and 2 for the second button.
    it("addButton returns 1-based index", function()
        local tb = lurek.ui.newToolbar("horizontal")
        local idx = tb.addButton("save", "Save File")
        expect_equal(1, idx)
        local idx2 = tb.addButton("open", "Open File")
        expect_equal(2, idx2)
    end)

    -- @description Verifies adding the same button id twice returns the original index instead of creating a duplicate.
    it("addButton is idempotent (no duplicate ids)", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb.addButton("dup", "First")
        local idx2 = tb.addButton("dup", "Second")
        expect_equal(1, idx2)
    end)

    -- @description Verifies addSeparator, addSpacer(10), and addSpacer() all execute without error.
    it("addSeparator and addSpacer do not error", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb.addSeparator()
        tb.addSpacer(10)
        tb.addSpacer()
    end)

    -- @description Verifies getButton returns a table with id "save", tooltip "Save", enabled true, and toggled false.
    it("getButton returns table with correct fields", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb.addButton("save", "Save")
        local btn = tb.getButton("save")
        expect_type("table", btn)
        expect_equal("save", btn.id)
        expect_equal("Save", btn.tooltip)
        expect_equal(true, btn.enabled)
        expect_equal(false, btn.toggled)
    end)

    -- @description Verifies getButton returns nil for a missing button id.
    it("getButton returns nil for missing id", function()
        local tb = lurek.ui.newToolbar("horizontal")
        expect_equal(nil, tb.getButton("nope"))
    end)

    -- @description Verifies setButtonEnabled("x", false) succeeds and updates the stored button state to enabled = false.
    it("setButtonEnabled can disable a button", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb.addButton("x", "X")
        expect_equal(true, tb.setButtonEnabled("x", false))
        local btn = tb.getButton("x")
        expect_equal(false, btn.enabled)
    end)

    -- @description Verifies setButtonToggled("t", true) succeeds and isButtonToggled("t") returns true.
    it("setButtonToggled and isButtonToggled work", function()
        local tb = lurek.ui.newToolbar("horizontal")
        tb.addButton("t", "Toggle")
        expect_equal(true, tb.setButtonToggled("t", true))
        expect_equal(true, tb.isButtonToggled("t"))
    end)

    -- @description Verifies isButtonToggled returns nil for a missing button id.
    it("isButtonToggled returns nil for missing id", function()
        local tb = lurek.ui.newToolbar("horizontal")
        expect_equal(nil, tb.isButtonToggled("none"))
    end)
end)

-- =========================================================================
-- 28. MenuBar
-- =========================================================================
-- @description Covers menu bar construction, empty-state count, and adding a menu item by index.
describe("lurek.ui.newMenuBar", function()
    -- @description Verifies newMenuBar returns a table.
    it("creates a menu bar", function()
        local mb = lurek.ui.newMenuBar()
        expect_type("table", mb)
    end)
    -- @description Verifies a new menu bar starts with zero menus.
    it("starts with 0 menus", function()
        local mb = lurek.ui.newMenuBar()
        expect_equal(0, mb.getMenuCount())
    end)
    -- @description Verifies adding a single menu item by index increases the menu count to 1.
    it("can add menu", function()
        local mb = lurek.ui.newMenuBar()
        local mi = lurek.ui.newMenuItem("File")
        mb.addMenu(mi._idx)
        expect_equal(1, mb.getMenuCount())
    end)
end)

-- =========================================================================
-- 29. MenuItem
-- =========================================================================
-- @description Covers menu item construction, label text, checked default, shortcut storage, and submenu insertion.
describe("lurek.ui.newMenuItem", function()
    -- @description Verifies newMenuItem("Edit") returns a table.
    it("creates a menu item", function()
        local mi = lurek.ui.newMenuItem("Edit")
        expect_type("table", mi)
    end)
    -- @description Verifies the menu item text "File" is returned by getText().
    it("has correct text", function()
        local mi = lurek.ui.newMenuItem("File")
        expect_equal("File", mi.getText())
    end)
    -- @description Verifies a new menu item starts unchecked.
    it("defaults unchecked", function()
        local mi = lurek.ui.newMenuItem("X")
        expect_equal(false, mi.isChecked())
    end)
    -- @description Verifies setShortcut stores "Ctrl+S" and getShortcut returns it.
    it("can set shortcut", function()
        local mi = lurek.ui.newMenuItem("Save")
        mi.setShortcut("Ctrl+S")
        expect_equal("Ctrl+S", mi.getShortcut())
    end)
    -- @description Verifies adding one submenu item makes getSubItems() contain exactly one entry.
    it("can add sub-item", function()
        local mi = lurek.ui.newMenuItem("File")
        local sub = lurek.ui.newMenuItem("Open")
        mi.addSubItem(sub._idx)
        expect_equal(1, #mi.getSubItems())
    end)
end)

-- =========================================================================
-- 30. Dialog
-- =========================================================================
-- @description Covers dialog construction, title, modal and open defaults, open/close behavior, content slot storage, and footer button insertion.
describe("lurek.ui.newDialog", function()
    -- @description Verifies newDialog("Confirm") returns a table.
    it("creates a dialog", function()
        local d = lurek.ui.newDialog("Confirm")
        expect_type("table", d)
    end)
    -- @description Verifies the dialog title "Save?" is returned by getTitle().
    it("has title", function()
        local d = lurek.ui.newDialog("Save?")
        expect_equal("Save?", d.getTitle())
    end)
    -- @description Verifies dialogs default to modal = true.
    it("defaults modal true", function()
        local d = lurek.ui.newDialog("D")
        expect_equal(true, d.isModal())
    end)
    -- @description Verifies dialogs start closed with isOpen() returning false.
    it("defaults not open", function()
        local d = lurek.ui.newDialog("D")
        expect_equal(false, d.isOpen())
    end)
    -- @description Verifies open() sets isOpen() to true and close() sets it back to false.
    it("can open and close", function()
        local d = lurek.ui.newDialog("D")
        d.open()
        expect_equal(true, d.isOpen())
        d.close()
        expect_equal(false, d.isOpen())
    end)

    -- @description Verifies getContent starts nil, setContent stores a button index, and getContent returns that same index.
    it("setContent and getContent work", function()
        local d = lurek.ui.newDialog("Edit")
        local btn = lurek.ui.newButton("B")
        expect_equal(nil, d.getContent())
        d.setContent(btn._idx)
        expect_equal(btn._idx, d.getContent())
    end)

    -- @description Verifies setting content to nil after assigning a button clears the content slot.
    it("setContent nil clears content", function()
        local d = lurek.ui.newDialog("Clear")
        local btn = lurek.ui.newButton("B")
        d.setContent(btn._idx)
        d.setContent(nil)
        expect_equal(nil, d.getContent())
    end)

    -- @description Verifies addButton returns counts 1 and 2 as footer buttons are appended.
    it("addButton appends footer button and returns count", function()
        local d = lurek.ui.newDialog("Prompt")
        local count1 = d.addButton("OK")
        expect_equal(1, count1)
        local count2 = d.addButton("Cancel")
        expect_equal(2, count2)
    end)
end)

-- =========================================================================
-- 31. StatusBar
-- =========================================================================
-- @description Covers status bar construction, section counting, text updates, section resizing, and widget attachment.
describe("lurek.ui.newStatusBar", function()
    -- @description Verifies newStatusBar returns a table.
    it("creates a status bar", function()
        local sb = lurek.ui.newStatusBar()
        expect_type("table", sb)
    end)
    -- @description Verifies a new status bar starts with zero sections.
    it("starts with 0 sections", function()
        local sb = lurek.ui.newStatusBar()
        expect_equal(0, sb.getSectionCount())
    end)
    -- @description Verifies adding one section increases the section count to 1.
    it("can add section", function()
        local sb = lurek.ui.newStatusBar()
        sb.addSection("Ready", 100)
        expect_equal(1, sb.getSectionCount())
    end)
    -- @description Verifies setting section 1 text to "Updated" is returned by getSectionText(1).
    it("can set section text", function()
        local sb = lurek.ui.newStatusBar()
        sb.addSection("Info", 120)
        sb.setSectionText(1, "Updated")
        expect_equal("Updated", sb.getSectionText(1))
    end)

    -- @description Verifies setSectionCount can shrink from 2 to 1 and then grow from 1 to 3.
    it("setSectionCount resizes sections up and down", function()
        local sb = lurek.ui.newStatusBar()
        sb.addSection("A", 100)
        sb.addSection("B", 100)
        expect_equal(2, sb.getSectionCount())
        sb.setSectionCount(1)
        expect_equal(1, sb.getSectionCount())
        sb.setSectionCount(3)
        expect_equal(3, sb.getSectionCount())
    end)

    -- @description Verifies setSectionWidget accepts a button widget index for section 1 without raising an error.
    it("setSectionWidget does not error", function()
        local sb = lurek.ui.newStatusBar()
        sb.addSection("A", 100)
        local btn = lurek.ui.newButton("X")
        sb.setSectionWidget(1, btn._idx)
    end)
end)

-- =========================================================================
-- 32. Accordion
-- =========================================================================
-- @description Covers accordion construction, section counting, exclusivity, and section expansion toggling.
describe("lurek.ui.newAccordion", function()
    -- @description Verifies newAccordion returns a table.
    it("creates an accordion", function()
        local a = lurek.ui.newAccordion()
        expect_type("table", a)
    end)
    -- @description Verifies a new accordion starts with zero sections.
    it("starts with 0 sections", function()
        local a = lurek.ui.newAccordion()
        expect_equal(0, a.getSectionCount())
    end)
    -- @description Verifies accordions default to exclusive = false.
    it("defaults non-exclusive", function()
        local a = lurek.ui.newAccordion()
        expect_equal(false, a.isExclusive())
    end)
    -- @description Verifies setExclusive(true) makes isExclusive() return true.
    it("can set exclusive", function()
        local a = lurek.ui.newAccordion()
        a.setExclusive(true)
        expect_equal(true, a.isExclusive())
    end)
    -- @description Verifies addSection("Section 1") increases the section count to 1.
    it("can add section", function()
        local a = lurek.ui.newAccordion()
        a.addSection("Section 1")
        expect_equal(1, a.getSectionCount())
    end)
    -- @description Verifies toggling section 1 after creation marks it expanded.
    it("can expand section", function()
        local a = lurek.ui.newAccordion()
        a.addSection("S1")
        a.toggleSection(1)
        expect_equal(true, a.isSectionExpanded(1))
    end)
    -- @description Verifies toggling the same section twice returns it to the collapsed state.
    it("can collapse section", function()
        local a = lurek.ui.newAccordion()
        a.addSection("S1")
        a.toggleSection(1)
        a.toggleSection(1)
        expect_equal(false, a.isSectionExpanded(1))
    end)
end)

-- =========================================================================
-- 33. TooltipPanel
-- =========================================================================
-- @description Covers tooltip panel construction, text mutation, default delay, and custom delay storage.
describe("lurek.ui.newTooltipPanel", function()
    -- @description Verifies newTooltipPanel("Help text") returns a table.
    it("creates a tooltip panel", function()
        local tp = lurek.ui.newTooltipPanel("Help text")
        expect_type("table", tp)
    end)
    -- @description Verifies the initial tooltip text "Tip" is returned by getText().
    it("has correct text", function()
        local tp = lurek.ui.newTooltipPanel("Tip")
        expect_equal("Tip", tp.getText())
    end)
    -- @description Verifies setText replaces "Old" with "New".
    it("can set text", function()
        local tp = lurek.ui.newTooltipPanel("Old")
        tp.setText("New")
        expect_equal("New", tp.getText())
    end)
    -- @description Verifies the default tooltip delay is approximately 0.5 seconds.
    it("default delay is 0.5", function()
        local tp = lurek.ui.newTooltipPanel("T")
        expect_near(0.5, tp.getDelay(), 0.001)
    end)
    -- @description Verifies setDelay(1.0) is returned approximately by getDelay().
    it("can set delay", function()
        local tp = lurek.ui.newTooltipPanel("T")
        tp.setDelay(1.0)
        expect_near(1.0, tp.getDelay(), 0.001)
    end)
end)

-- =========================================================================
-- 34. ColorPicker
-- =========================================================================
-- @description Covers color picker construction, default RGBA values, explicit RGBA updates, alpha visibility, and color mode changes.
describe("lurek.ui.newColorPicker", function()
    -- @description Verifies newColorPicker returns a table.
    it("creates a color picker", function()
        local cp = lurek.ui.newColorPicker()
        expect_type("table", cp)
    end)
    -- @description Verifies the default color is opaque white with all RGBA channels at approximately 1.0.
    it("default color is white", function()
        local cp = lurek.ui.newColorPicker()
        local r, g, b, a = cp.getColor()
        expect_near(1.0, r, 0.001)
        expect_near(1.0, g, 0.001)
        expect_near(1.0, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)
    -- @description Verifies setColor(0.5, 0.3, 0.1, 0.9) is returned approximately by getColor().
    it("can set color", function()
        local cp = lurek.ui.newColorPicker()
        cp.setColor(0.5, 0.3, 0.1, 0.9)
        local r, g, b, a = cp.getColor()
        expect_near(0.5, r, 0.001)
        expect_near(0.3, g, 0.001)
        expect_near(0.1, b, 0.001)
        expect_near(0.9, a, 0.001)
    end)
    -- @description Verifies the picker shows alpha by default.
    it("default shows alpha", function()
        local cp = lurek.ui.newColorPicker()
        expect_equal(true, cp.getShowAlpha())
    end)
    -- @description Verifies the default color mode string is "rgb".
    it("default color mode is rgb", function()
        local cp = lurek.ui.newColorPicker()
        expect_equal("rgb", cp.getColorMode())
    end)
    -- @description Verifies setColorMode("hsv") changes the stored mode to "hsv".
    it("can set color mode", function()
        local cp = lurek.ui.newColorPicker()
        cp.setColorMode("hsv")
        expect_equal("hsv", cp.getColorMode())
    end)
end)

-- =========================================================================
-- 35. GUITable
-- =========================================================================
-- @description Covers table construction, empty row and column counts, row and column insertion, row selection, and sortable state.
describe("lurek.ui.newTable", function()
    -- @description Verifies newTable returns a table.
    it("creates a table", function()
        local t = lurek.ui.newTable()
        expect_type("table", t)
    end)
    -- @description Verifies a new table starts with zero columns.
    it("starts with 0 columns", function()
        local t = lurek.ui.newTable()
        expect_equal(0, t.getColumnCount())
    end)
    -- @description Verifies a new table starts with zero rows.
    it("starts with 0 rows", function()
        local t = lurek.ui.newTable()
        expect_equal(0, t.getRowCount())
    end)
    -- @description Verifies adding one column increases the column count to 1.
    it("can add column", function()
        local t = lurek.ui.newTable()
        t.addColumn("Name", 100)
        expect_equal(1, t.getColumnCount())
    end)
    -- @description Verifies adding one row after a column increases the row count to 1.
    it("can add row", function()
        local t = lurek.ui.newTable()
        t.addColumn("Name", 100)
        t.addRow({"Alice"})
        expect_equal(1, t.getRowCount())
    end)
    -- @description Verifies no row is selected by default, so getSelectedRow() returns nil.
    it("no selected row by default", function()
        local t = lurek.ui.newTable()
        expect_equal(nil, t.getSelectedRow())
    end)
    -- @description Verifies setSelectedRow(1) selects the first row after it has been added.
    it("can select row after adding", function()
        local t = lurek.ui.newTable()
        t.addColumn("Name", 100)
        t.addRow({"Alice"})
        t.setSelectedRow(1)
        expect_equal(1, t.getSelectedRow())
    end)
    -- @description Verifies setSortable(true) makes isSortable() return true.
    it("can set sortable", function()
        local t = lurek.ui.newTable()
        t.setSortable(true)
        expect_equal(true, t.isSortable())
    end)
end)

-- =========================================================================
-- 36. ImageWidget
-- =========================================================================
-- @description Covers image widget construction, scale mode defaults and updates, and tint defaults and updates.
describe("lurek.ui.newImageWidget", function()
    -- @description Verifies newImageWidget returns a table.
    it("creates an image widget", function()
        local iw = lurek.ui.newImageWidget()
        expect_type("table", iw)
    end)
    -- @description Verifies the default scale mode string is "fit".
    it("default scale mode is fit", function()
        local iw = lurek.ui.newImageWidget()
        expect_equal("fit", iw.getScaleMode())
    end)
    -- @description Verifies setScaleMode("fill") changes the stored scale mode to "fill".
    it("can set scale mode", function()
        local iw = lurek.ui.newImageWidget()
        iw.setScaleMode("fill")
        expect_equal("fill", iw.getScaleMode())
    end)
    -- @description Verifies the default tint is opaque white with all RGBA channels at approximately 1.0.
    it("default tint is white", function()
        local iw = lurek.ui.newImageWidget()
        local r, g, b, a = iw.getTint()
        expect_near(1.0, r, 0.001)
        expect_near(1.0, g, 0.001)
        expect_near(1.0, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)
    -- @description Verifies setTint(0.5, 0.2, 0.8, 1.0) is returned approximately by getTint().
    it("can set tint", function()
        local iw = lurek.ui.newImageWidget()
        iw.setTint(0.5, 0.2, 0.8, 1.0)
        local r, g, b, a = iw.getTint()
        expect_near(0.5, r, 0.001)
        expect_near(0.2, g, 0.001)
        expect_near(0.8, b, 0.001)
        expect_near(1.0, a, 0.001)
    end)
end)

-- @description Covers widget state parsing for all supported state strings plus invalid, empty, and case-mismatched input.
describe("lurek.ui.parseWidgetState", function()
    -- @description Verifies parseWidgetState is exposed as a function.
    it("is a function", function()
        expect_type("function", lurek.ui.parseWidgetState)
    end)

    -- @description Verifies passing "normal" returns the exact string "normal".
    it("returns 'normal' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("normal"), "normal")
    end)

    -- @description Verifies passing "hovered" returns the exact string "hovered".
    it("returns 'hovered' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("hovered"), "hovered")
    end)

    -- @description Verifies passing "pressed" returns the exact string "pressed".
    it("returns 'pressed' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("pressed"), "pressed")
    end)

    -- @description Verifies passing "focused" returns the exact string "focused".
    it("returns 'focused' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("focused"), "focused")
    end)

    -- @description Verifies passing "disabled" returns the exact string "disabled".
    it("returns 'disabled' for valid input", function()
        expect_equal(lurek.ui.parseWidgetState("disabled"), "disabled")
    end)

    -- @description Verifies an unsupported state string returns nil.
    it("returns nil for an invalid state string", function()
        expect_equal(lurek.ui.parseWidgetState("invalid"), nil)
    end)

    -- @description Verifies an empty string returns nil.
    it("returns nil for an empty string", function()
        expect_equal(lurek.ui.parseWidgetState(""), nil)
    end)

    -- @description Verifies parsing is case-sensitive by returning nil for "Normal".
    it("is case-sensitive â€” 'Normal' returns nil", function()
        expect_equal(lurek.ui.parseWidgetState("Normal"), nil)
    end)
end)

-- =========================================================================
-- New factories: SpinBox, Switch, Badge
-- =========================================================================

describe("lurek.ui.newSpinBox factory", function()
    -- @tests lurek.ui.newSpinBox
    -- @description Verifies newSpinBox is exposed on the lurek.ui table.
    it("is callable", function()
        expect_equal(type(lurek.ui.newSpinBox), "function")
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description newSpinBox returns a table with the expected methods.
    it("returns a table", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        expect_equal(type(sb), "table")
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description getValue returns min after creation.
    it("getValue returns min after creation", function()
        local sb = lurek.ui.newSpinBox(10, 50)
        expect_equal(sb.getValue(), 10)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description increment advances value.
    it("increment changes value", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        sb.increment()
        expect_equal(sb.getValue() > 0, true)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description decrement at min stays at min.
    it("decrement at min stays at min", function()
        local sb = lurek.ui.newSpinBox(5, 20)
        sb.decrement()
        expect_equal(sb.getValue(), 5)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description setRange is callable without error.
    it("setRange is callable without error", function()
        local sb = lurek.ui.newSpinBox(0, 10)
        sb.setRange(1, 99)
        expect_equal(true, true)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description increment advances value by the step amount set via setStep.
    -- Migrated from Rust spin_box_increment_respects_step.
    it("increment advances value by custom step", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        sb.setStep(2.0)
        sb.increment()
        expect_near(2.0, sb.getValue(), 0.001)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description increment clamps at max when step overshoots the upper bound.
    -- Migrated from Rust spin_box_increment_clamps_at_max.
    it("increment clamps at max when step overshoots", function()
        local sb = lurek.ui.newSpinBox(0, 10)
        sb.setStep(1000.0)
        sb.increment()
        expect_near(10.0, sb.getValue(), 0.001)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description setValue clamps to max when the supplied value exceeds the range.
    -- Migrated from Rust spin_box_set_value_clamps_to_range.
    it("setValue clamps to max when value exceeds range", function()
        local sb = lurek.ui.newSpinBox(0, 100)
        sb.setValue(999)
        expect_near(100.0, sb.getValue(), 0.001)
    end)

    -- @tests lurek.ui.newSpinBox
    -- @description setValue clamps to min when the supplied value is below the range.
    -- Migrated from Rust spin_box_set_value_clamps_to_range.
    it("setValue clamps to min when value is below range", function()
        local sb = lurek.ui.newSpinBox(5, 50)
        sb.setValue(-1)
        expect_near(5.0, sb.getValue(), 0.001)
    end)
end)

describe("lurek.ui.newSwitch factory", function()
    -- @tests lurek.ui.newSwitch
    -- @description Verifies newSwitch is exposed on the lurek.ui table.
    it("is callable", function()
        expect_equal(type(lurek.ui.newSwitch), "function")
    end)

    -- @tests lurek.ui.newSwitch
    -- @description newSwitch returns a table.
    it("returns a table", function()
        local sw = lurek.ui.newSwitch(false)
        expect_equal(type(sw), "table")
    end)

    -- @tests lurek.ui.newSwitch
    -- @description isOn returns false when created off.
    it("isOn returns false when created off", function()
        local sw = lurek.ui.newSwitch(false)
        expect_equal(sw.isOn(), false)
    end)

    -- @tests lurek.ui.newSwitch
    -- @description setOn(true) flips state.
    it("setOn(true) flips state", function()
        local sw = lurek.ui.newSwitch(false)
        sw.setOn(true)
        expect_equal(sw.isOn(), true)
    end)

    -- @tests lurek.ui.newSwitch
    -- @description toggle flips on -> off -> on.
    it("toggle flips state back and forth", function()
        local sw = lurek.ui.newSwitch(true)
        sw.toggle()
        expect_equal(sw.isOn(), false)
        sw.toggle()
        expect_equal(sw.isOn(), true)
    end)
end)

describe("lurek.ui.newBadge factory", function()
    -- @tests lurek.ui.newBadge
    -- @description Verifies newBadge is exposed on the lurek.ui table.
    it("is callable", function()
        expect_equal(type(lurek.ui.newBadge), "function")
    end)

    -- @tests lurek.ui.newBadge
    -- @description newBadge returns a table.
    it("returns a table", function()
        local b = lurek.ui.newBadge(3)
        expect_equal(type(b), "table")
    end)

    -- @tests lurek.ui.newBadge
    -- @description getCount returns the initial count.
    it("getCount returns initial count", function()
        local b = lurek.ui.newBadge(7)
        expect_equal(b.getCount(), 7)
    end)

    -- @tests lurek.ui.newBadge
    -- @description getDisplayText returns count string below cap.
    it("getDisplayText returns count string below cap", function()
        local b = lurek.ui.newBadge(5)
        expect_equal(b.getDisplayText(), "5")
    end)

    -- @tests lurek.ui.newBadge
    -- @description getDisplayText shows plus notation when over cap.
    it("getDisplayText shows plus notation when over cap", function()
        local b = lurek.ui.newBadge(200)
        expect_equal(b.getDisplayText(), "99+")
    end)

    -- @tests lurek.ui.newBadge
    -- @description setCount updates count.
    it("setCount updates count", function()
        local b = lurek.ui.newBadge(0)
        b.setCount(42)
        expect_equal(b.getCount(), 42)
    end)

    -- @tests lurek.ui.newBadge
    -- @description getDisplayText shows exact count at the cap boundary (99 → "99", not "99+").
    -- Migrated from Rust badge_display_text_at_max_shows_count.
    it("getDisplayText shows exact count at cap boundary", function()
        local b = lurek.ui.newBadge(99)
        expect_equal(b.getDisplayText(), "99")
    end)
end)

-- =========================================================================
-- Module helpers: setDefaultTheme, setViewport, flushCache
-- =========================================================================

describe("lurek.ui default theme and viewport helpers", function()
    -- @tests lurek.ui.setDefaultTheme
    -- @description setDefaultTheme is callable without error.
    it("setDefaultTheme is callable", function()
        expect_equal(type(lurek.ui.setDefaultTheme), "function")
        lurek.ui.setDefaultTheme()
        expect_equal(true, true)
    end)

    -- @tests lurek.ui.setViewport
    -- @description setViewport is callable without error.
    it("setViewport is callable", function()
        expect_equal(type(lurek.ui.setViewport), "function")
        lurek.ui.setViewport(1280, 720)
        expect_equal(true, true)
    end)

    -- @tests lurek.ui.flushCache
    -- @description flushCache returns a boolean.
    it("flushCache returns boolean", function()
        expect_equal(type(lurek.ui.flushCache), "function")
        local result = lurek.ui.flushCache()
        expect_equal(type(result), "boolean")
    end)

    -- @tests lurek.ui.flushCache
    -- @description flushCache returns false on second consecutive call.
    it("flushCache returns false on second consecutive call", function()
        lurek.ui.flushCache()
        local clean = lurek.ui.flushCache()
        expect_equal(clean, false)
    end)
end)

test_summary()
