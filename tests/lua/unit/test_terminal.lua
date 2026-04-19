-- tests/lua/unit/test_terminal.lua
-- BDD tests for the lurek.terminal.* API, covering terminal widgets, layout helpers, input-driven interactions, and headless terminal state updates.

-- @covers lurek.terminal.newBorder
-- @covers lurek.terminal.newButton
-- @covers lurek.terminal.newLabel
-- @covers lurek.terminal.newList
-- @covers lurek.terminal.newPanel
-- @covers lurek.terminal.newTerminal
-- @covers lurek.terminal.newTextBox

require("tests/lua/init")

local function click_cell(term, col, row, button)
    local cell_w, cell_h = term:getCellSize()
    term:mousepressed((col - 1) * cell_w + 1, (row - 1) * cell_h + 1, button or 1)
end

-- @description Covers suite: lurek.terminal module.
describe("lurek.terminal module", function()
    -- @covers lurek.terminal.newTerminal
    -- @covers lurek.terminal.newLabel
    -- @covers lurek.terminal.newButton
    -- @covers lurek.terminal.newTextBox
    -- @covers lurek.terminal.newList
    -- @covers lurek.terminal.newBorder
    -- @covers lurek.terminal.newPanel
    -- @description Verifies the terminal module exposes the expected terminal and widget constructor functions.
    it("exposes terminal constructors", function()
        expect_type("table", lurek.terminal)
        expect_type("function", lurek.terminal.newTerminal)
        expect_type("function", lurek.terminal.newLabel)
        expect_type("function", lurek.terminal.newButton)
        expect_type("function", lurek.terminal.newTextBox)
        expect_type("function", lurek.terminal.newList)
        expect_type("function", lurek.terminal.newBorder)
        expect_type("function", lurek.terminal.newPanel)
    end)
end)

-- @description Covers suite: terminal handles.
describe("terminal handles", function()
    -- @covers lurek.terminal.newTerminal
    -- @covers Terminal:getDimensions
    -- @description Verifies newTerminal() returns userdata and its methods accept both colon syntax and explicit self calls.
    it("creates terminal userdata and accepts colon or explicit self syntax", function()
        local term = lurek.terminal.newTerminal(40, 20)
        expect_equal("userdata", type(term))

        local cols1, rows1 = term:getDimensions()
        local cols2, rows2 = term.getDimensions(term)
        expect_equal(40, cols1)
        expect_equal(20, rows1)
        expect_equal(40, cols2)
        expect_equal(20, rows2)
    end)

    -- @covers Terminal:getCellSize
    -- @description Verifies getCellSize() reports the default cell size through both colon and explicit self syntax.
    it("reports the default cell size through colon and explicit self syntax", function()
        local term = lurek.terminal.newTerminal(10, 5)
        local cell_w1, cell_h1 = term:getCellSize()
        local cell_w2, cell_h2 = term.getCellSize(term)

        expect_near(8.0, cell_w1, 0.001)
        expect_near(14.0, cell_h1, 0.001)
        expect_near(8.0, cell_w2, 0.001)
        expect_near(14.0, cell_h2, 0.001)
    end)

    -- @covers Terminal:set
    -- @covers Terminal:get
    -- @description Verifies set() writes a cell's character and foreground color data and get() reads the stored values back.
    it("sets and gets cells with colon syntax", function()
        local term = lurek.terminal.newTerminal(10, 5)
        term:set(2, 3, "A", 1, 0.5, 0, 1)

        local ch, fr, fg, fb, fa = term:get(2, 3)
        expect_equal(string.byte("A"), ch)
        expect_near(1.0, fr, 0.01)
        expect_near(0.5, fg, 0.01)
        expect_near(0.0, fb, 0.01)
        expect_near(1.0, fa, 0.01)
    end)

    -- @covers Terminal:clear
    -- @covers Terminal:get
    -- @description Verifies clear() resets previously written cells back to their default blank state.
    it("clears cells back to defaults", function()
        local term = lurek.terminal.newTerminal(10, 5)
        term:set(2, 2, "X", 1, 0, 0, 1)
        term:clear()

        local ch = term:get(2, 2)
        expect_equal(string.byte(" "), ch)
    end)

    -- @covers lurek.terminal.newLabel
    -- @covers Label:getText
    -- @covers Label:setText
    -- @description Verifies widget handles support both colon syntax and explicit self calls for text accessors.
    it("supports explicit self syntax on widget handles", function()
        local label = lurek.terminal.newLabel(1, 1, "Hello")
        expect_equal("Hello", label.getText(label))

        label.setText(label, "Updated")
        expect_equal("Updated", label:getText())
    end)
end)

-- @description Covers suite: widget attachment and focus.
describe("widget attachment and focus", function()
    -- @covers Terminal:addWidget
    -- @covers Terminal:getWidgetCount
    -- @covers Label:getPosition
    -- @description Verifies addWidget() attaches a detached widget to the terminal without changing its position.
    it("attaches detached widgets to a terminal", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local label = lurek.terminal.newLabel(2, 3, "Status")

        expect_equal(0, term:getWidgetCount())
        term:addWidget(label)
        expect_equal(1, term:getWidgetCount())

        local col, row = label:getPosition()
        expect_equal(2, col)
        expect_equal(3, row)
    end)

    -- @covers Terminal:removeWidget
    -- @covers Terminal:setFocus
    -- @covers Terminal:getFocused
    -- @covers Terminal:getWidgetCount
    -- @covers Button:setText
    -- @covers Button:getText
    -- @description Verifies removeWidget() detaches the widget, clears focus, and leaves the detached handle usable.
    it("removeWidget detaches the handle and clears focus for the removed widget", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local button = lurek.terminal.newButton(2, 2, 8, 1, "Play")

        term:addWidget(button)
        term:setFocus(button)
        term:removeWidget(button)

        expect_equal(0, term:getWidgetCount())
        expect_nil(term:getFocused())

        button:setText("Detached")
        expect_equal("Detached", button:getText())
    end)

    -- @covers Terminal:clearWidgets
    -- @covers Terminal:setFocus
    -- @covers Terminal:getFocused
    -- @covers Terminal:getWidgetCount
    -- @description Verifies clearWidgets() detaches all widgets, clears focus, and preserves detached widget usability.
    it("clearWidgets detaches all handles and clears focus", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local label = lurek.terminal.newLabel(1, 1, "HUD")
        local input = lurek.terminal.newTextBox(1, 2, 10)

        term:addWidget(label)
        term:addWidget(input)
        term:setFocus(input)
        term:clearWidgets()

        expect_equal(0, term:getWidgetCount())
        expect_nil(term:getFocused())

        label:setText("Detached HUD")
        input:setText("after-clear")
        expect_equal("Detached HUD", label:getText())
        expect_equal("after-clear", input:getText())
    end)

    -- @covers Terminal:setFocus
    -- @covers Terminal:getFocused
    -- @covers TextBox:setText
    -- @covers TextBox:getText
    -- @description Verifies setFocus() and getFocused() round-trip an attached widget handle that remains fully usable.
    it("setFocus and getFocused work with attached widget handles", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local input = lurek.terminal.newTextBox(1, 1, 10)

        term:addWidget(input)
        term:setFocus(input)

        local focused = term:getFocused()
        expect_equal("userdata", type(focused))

        focused:setText("Hero")
        expect_equal("Hero", input:getText())
    end)

    -- @covers Terminal:addWidget
    -- @covers Panel:addChild
    -- @covers Panel:getChildCount
    -- @covers Panel:getChild
    -- @description Verifies attaching a panel auto-attaches detached child widgets added through addChild().
    it("panel addChild auto-attaches detached children when the panel is attached", function()
        local term = lurek.terminal.newTerminal(30, 12)
        local panel = lurek.terminal.newPanel(1, 1, 20, 8)
        local child = lurek.terminal.newLabel(2, 2, "Child")

        term:addWidget(panel)
        panel:addChild(child)

        expect_equal(2, term:getWidgetCount())
        expect_equal(1, panel:getChildCount())
        expect_equal("Child", panel:getChild(1):getText())
    end)

    -- @covers Terminal:mousepressed
    -- @covers Terminal:setFocus
    -- @covers Terminal:getFocused
    -- @description Verifies a mouse press that misses every widget clears the current terminal focus.
    it("mousepressed miss clears focus", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local button = lurek.terminal.newButton(3, 2, 8, 1, "OK")

        term:addWidget(button)
        term:setFocus(button)
        term:mousepressed(1, 1, 1)

        expect_nil(term:getFocused())
    end)
end)

-- @description Covers suite: widget property helpers.
describe("widget property helpers", function()
    -- @covers Label:setVisible
    -- @covers Label:isVisible
    -- @covers Label:setEnabled
    -- @covers Label:isEnabled
    -- @covers Label:setTag
    -- @covers Label:getTag
    -- @description Verifies attached widgets expose visibility, enabled-state, and tag helper methods.
    it("supports visibility, enabled, and tag helpers on attached widgets", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local label = lurek.terminal.newLabel(1, 1, "Status")

        term:addWidget(label)

        label:setVisible(false)
        expect_false(label:isVisible())
        label:setVisible(true)
        expect_true(label:isVisible())

        label:setEnabled(false)
        expect_false(label:isEnabled())
        label:setEnabled(true)
        expect_true(label:isEnabled())

        label:setTag("hud.status")
        expect_equal("hud.status", label:getTag())
    end)

    -- @covers Label:setColor
    -- @covers Label:getColor
    -- @covers Border:setColor
    -- @covers Border:getColor
    -- @description Verifies labels and borders round-trip RGBA color state through their color helper methods.
    it("supports setColor and getColor on labels and borders", function()
        local label = lurek.terminal.newLabel(1, 1, "Info")
        local border = lurek.terminal.newBorder(1, 2, 12, 4)

        label:setColor(0.25, 0.5, 0.75, 0.9)
        border:setColor(1.0, 0.2, 0.1, 0.8)

        local lr, lg, lb, la = label:getColor()
        local br, bg, bb, ba = border:getColor()

        expect_near(0.25, lr, 0.001)
        expect_near(0.5, lg, 0.001)
        expect_near(0.75, lb, 0.001)
        expect_near(0.9, la, 0.001)

        expect_near(1.0, br, 0.001)
        expect_near(0.2, bg, 0.001)
        expect_near(0.1, bb, 0.001)
        expect_near(0.8, ba, 0.001)
    end)

    -- @covers Button:setText
    -- @covers Button:getText
    -- @covers TextBox:setText
    -- @covers TextBox:getText
    -- @description Verifies buttons and text boxes update and expose their text content through the widget text helpers.
    it("supports setText and getText on buttons and text boxes", function()
        local button = lurek.terminal.newButton(1, 1, 8, 1, "Old")
        local textbox = lurek.terminal.newTextBox(1, 2, 10)

        button:setText("Launch")
        textbox.setText(textbox, "Updated")

        expect_equal("Launch", button:getText())
        expect_equal("Updated", textbox.getText(textbox))
    end)

    -- @covers TextBox:setMaxLength
    -- @covers TextBox:getMaxLength
    -- @covers TextBox:setText
    -- @covers TextBox:getText
    -- @description Verifies text box max-length constraints are stored and enforced when text is assigned.
    it("supports setMaxLength and getMaxLength on text boxes", function()
        local textbox = lurek.terminal.newTextBox(1, 1, 10)

        textbox:setMaxLength(4)
        textbox:setText("abcdef")

        expect_equal(4, textbox:getMaxLength())
        expect_equal("abcd", textbox:getText())
    end)

    -- @covers List:addItem
    -- @covers List:getItemCount
    -- @covers List:getItem
    -- @covers List:removeItem
    -- @covers List:clearItems
    -- @description Verifies list widgets support adding, removing, querying, and clearing items.
    it("supports list item management helpers", function()
        local list = lurek.terminal.newList(1, 1, 20, 5)
        list:addItem("Alpha")
        list:addItem("Beta")
        list:addItem("Gamma")

        expect_equal(3, list:getItemCount())
        expect_equal("Beta", list:getItem(2))

        list:removeItem(2)
        expect_equal(2, list:getItemCount())
        expect_equal("Gamma", list:getItem(2))

        list:clearItems()
        expect_equal(0, list:getItemCount())
        expect_equal("", list:getItem(1))
    end)

    -- @covers Panel:addChild
    -- @covers Panel:getChildCount
    -- @covers Panel:getChild
    -- @covers Panel:removeChild
    -- @covers Panel:clearChildren
    -- @description Verifies panels support adding, removing, querying, and clearing child widget handles.
    it("supports panel child management helpers", function()
        local term = lurek.terminal.newTerminal(30, 12)
        local panel = lurek.terminal.newPanel(1, 1, 20, 8)
        local child1 = lurek.terminal.newLabel(2, 2, "One")
        local child2 = lurek.terminal.newLabel(2, 3, "Two")

        term:addWidget(panel)
        panel:addChild(child1)
        panel:addChild(child2)

        expect_equal(2, panel:getChildCount())
        expect_equal("One", panel:getChild(1):getText())
        expect_equal("Two", panel:getChild(2):getText())

        panel:removeChild(child1)
        expect_equal(1, panel:getChildCount())
        expect_equal("Two", panel:getChild(1):getText())

        panel:clearChildren()
        expect_equal(0, panel:getChildCount())
        expect_nil(panel:getChild(1))
    end)

    -- @covers Border:setStyle
    -- @covers Border:getStyle
    -- @covers Border:setTitle
    -- @covers Border:getTitle
    -- @description Verifies border widgets update and report their style and title metadata.
    it("supports border style and title updates", function()
        local border = lurek.terminal.newBorder(1, 1, 12, 5)
        border:setStyle("double")
        border:setTitle("Menu")

        expect_equal("double", border:getStyle())
        expect_equal("Menu", border:getTitle())
    end)
end)

-- @description Covers suite: button callbacks.
describe("button callbacks", function()
    -- @covers Button:setOnClick
    -- @covers Terminal:keypressed
    -- @covers Terminal:removeWidget
    -- @covers Terminal:addWidget
    -- @covers Terminal:mousepressed
    -- @description Verifies button onClick callbacks still fire after keyboard activation, detachment, and reattachment.
    it("keeps onClick callbacks working after attachment and reattachment", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local button = lurek.terminal.newButton(3, 2, 8, 1, "OK")
        local clicks = 0

        button:setOnClick(function()
            clicks = clicks + 1
        end)

        term:addWidget(button)
        term:setFocus(button)

        expect_equal(true, term:keypressed("return"))
        expect_equal(1, clicks)

        term:removeWidget(button)
        expect_equal(0, term:getWidgetCount())

        term:addWidget(button)
        term:setFocus(button)
        click_cell(term, 3, 2)
        expect_equal(2, clicks)

        expect_equal(true, term:keypressed("space"))
        expect_equal(3, clicks)
    end)
end)

-- @description Covers suite: text box callbacks.
describe("text box callbacks", function()
    -- @covers TextBox:setOnChange
    -- @covers TextBox:setText
    -- @covers TextBox:getText
    -- @covers Terminal:textinput
    -- @covers Terminal:keypressed
    -- @description Verifies text box onChange callbacks fire for direct text assignment and keyboard editing operations.
    it("fires onChange for setText, textinput, backspace, and delete", function()
        local term = lurek.terminal.newTerminal(30, 10)
        local input = lurek.terminal.newTextBox(1, 1, 12)
        local changes = 0

        input:setOnChange(function()
            changes = changes + 1
        end)

        term:addWidget(input)
        term:setFocus(input)

        input:setText("abc")
        expect_equal(1, changes)

        expect_equal(true, term:textinput("d"))
        expect_equal("abcd", input:getText())
        expect_equal(2, changes)

        expect_equal(true, term:keypressed("backspace"))
        expect_equal("abc", input:getText())
        expect_equal(3, changes)

        expect_equal(true, term:keypressed("home"))
        expect_equal(true, term:keypressed("delete"))
        expect_equal("bc", input:getText())
        expect_equal(4, changes)
    end)
end)

-- @description Covers suite: list callbacks.
describe("list callbacks", function()
    -- @covers List:setOnSelect
    -- @covers List:setSelected
    -- @covers List:getSelected
    -- @covers Terminal:keypressed
    -- @covers Terminal:mousepressed
    -- @description Verifies list selection callbacks fire for direct selection changes, keyboard navigation, and mouse clicks.
    it("fires onSelect for setSelected, keyboard navigation, and mouse presses", function()
        local term = lurek.terminal.newTerminal(30, 12)
        local list = lurek.terminal.newList(1, 1, 12, 4)
        local selections = {}

        list:addItem("One")
        list:addItem("Two")
        list:addItem("Three")
        list:setOnSelect(function()
            selections[#selections + 1] = list:getSelected()
        end)

        term:addWidget(list)
        list:setSelected(2)

        term:setFocus(list)
        expect_equal(true, term:keypressed("down"))
        click_cell(term, 1, 1)

        expect_equal(3, #selections)
        expect_equal(2, selections[1])
        expect_equal(3, selections[2])
        expect_equal(1, selections[3])
    end)
end)

-- @description Covers suite: terminal low-level cell methods (RS parity).
describe("terminal low-level cell methods (RS parity)", function()
    -- @covers Terminal:get
    -- @description Verifies untouched cells start as spaces with an opaque white foreground color.
    it("default cell has space char and opaque white foreground", function()
        local term = lurek.terminal.newTerminal(10, 5)
        local ch, fr, fg, fb, fa = term:get(1, 1)
        expect_equal(string.byte(" "), ch)
        expect_near(1.0, fr, 0.01)
        expect_near(1.0, fg, 0.01)
        expect_near(1.0, fb, 0.01)
        expect_near(1.0, fa, 0.01)
    end)

    -- @covers lurek.terminal.newTerminal
    -- @covers Terminal:getDimensions
    -- @description Verifies terminal dimensions are clamped to a minimum 1x1 grid.
    it("clamped dimensions enforce minimum 1x1", function()
        local term = lurek.terminal.newTerminal(0, -5)
        local cols, rows = term:getDimensions()
        expect_true(cols >= 1)
        expect_true(rows >= 1)
    end)

    -- @covers Terminal:set
    -- @covers Terminal:setChar
    -- @covers Terminal:get
    -- @description Verifies setChar() changes the stored glyph without overwriting the existing foreground colors.
    it("setChar replaces character but preserves colors", function()
        local term = lurek.terminal.newTerminal(10, 5)
        term:set(3, 2, "A", 0.5, 0.1, 0.2, 1.0)
        term:setChar(3, 2, "Z")
        local ch, fr, fg, fb = term:get(3, 2)
        expect_equal(string.byte("Z"), ch)
        expect_near(0.5, fr, 0.01)
        expect_near(0.1, fg, 0.01)
        expect_near(0.2, fb, 0.01)
    end)

    -- @covers Terminal:set
    -- @covers Terminal:setFg
    -- @covers Terminal:get
    -- @description Verifies setFg() updates foreground color data while preserving the stored character.
    it("setFg replaces foreground but preserves character", function()
        local term = lurek.terminal.newTerminal(10, 5)
        term:set(2, 2, "B", 1.0, 0.0, 0.0, 1.0)
        term:setFg(2, 2, 0.0, 0.5, 1.0, 1.0)
        local ch = term:get(2, 2)
        expect_equal(string.byte("B"), ch)
    end)

    -- @covers Terminal:set
    -- @covers Terminal:setBg
    -- @covers Terminal:get
    -- @description Verifies setBg() accepts a background update without corrupting the stored character.
    it("setBg does not error and preserves character", function()
        local term = lurek.terminal.newTerminal(10, 5)
        term:set(2, 2, "C", 1.0, 0.0, 0.0, 1.0)
        expect_no_error(function() term:setBg(2, 2, 0.2, 0.3, 0.4, 1.0) end)
        local ch = term:get(2, 2)
        expect_equal(string.byte("C"), ch)
    end)

    -- @covers Terminal:print
    -- @covers Terminal:get
    -- @description Verifies print() writes text left-to-right and clips output at the terminal boundary.
    it("print writes characters left-to-right and clips at edge", function()
        local term = lurek.terminal.newTerminal(5, 3)
        term:print(1, 1, "Hello World")
        local ch1 = term:get(1, 1)
        local ch5 = term:get(5, 1)
        expect_equal(string.byte("H"), ch1)
        expect_equal(string.byte("o"), ch5)
    end)

    -- @covers Terminal:setCursor
    -- @covers Terminal:getCursor
    -- @description Verifies setCursor() and getCursor() round-trip the cursor position.
    it("getCursor and setCursor round-trip", function()
        local term = lurek.terminal.newTerminal(20, 10)
        term:setCursor(5, 3)
        local col, row = term:getCursor()
        expect_equal(5, col)
        expect_equal(3, row)
    end)

    -- @covers Terminal:resize
    -- @covers Terminal:getDimensions
    -- @covers Terminal:get
    -- @description Verifies resizing larger preserves existing cell contents within the overlapping region.
    it("resize preserves content in the overlap region", function()
        local term = lurek.terminal.newTerminal(10, 5)
        term:set(2, 2, "R", 1, 0, 0, 1)
        term:resize(20, 8)
        local cols, rows = term:getDimensions()
        expect_equal(20, cols)
        expect_equal(8, rows)
        local ch = term:get(2, 2)
        expect_equal(string.byte("R"), ch)
    end)

    -- @covers Terminal:resize
    -- @covers Terminal:setCursor
    -- @covers Terminal:getCursor
    -- @description Verifies resizing smaller clamps the cursor position to the new terminal bounds.
    it("resize to smaller clamps cursor inside new bounds", function()
        local term = lurek.terminal.newTerminal(20, 10)
        term:setCursor(15, 8)
        term:resize(10, 5)
        local col, row = term:getCursor()
        expect_true(col <= 10)
        expect_true(row <= 5)
    end)
end)

-- @description Covers suite: terminal widget lookup helpers (RS parity).
describe("terminal widget lookup helpers (RS parity)", function()
    -- @covers Terminal:getWidget
    -- @description Verifies getWidget() returns an attached widget handle by 1-based index.
    it("getWidget returns widget by 1-based index", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local lbl = lurek.terminal.newLabel(1, 1, "Hi")
        term:addWidget(lbl)
        local w = term:getWidget(1)
        expect_equal("userdata", type(w))
        w:setText("Changed")
        expect_equal("Changed", lbl:getText())
    end)

    -- @covers Label:setTag
    -- @covers Terminal:findByTag
    -- @description Verifies findByTag() resolves tagged widgets and returns nil for unknown tags.
    it("findByTag returns the matching widget or nil", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local lbl = lurek.terminal.newLabel(1, 1, "HealthBar")
        lbl:setTag("hud.health")
        term:addWidget(lbl)
        local found = term:findByTag("hud.health")
        expect_equal("userdata", type(found))
        expect_nil(term:findByTag("nonexistent.tag"))
    end)

    -- @covers Terminal:keypressed
    -- @description Verifies keypressed() returns false when the terminal has no focused widget.
    it("keypressed returns false when no widget has focus", function()
        local term = lurek.terminal.newTerminal(20, 10)
        local btn = lurek.terminal.newButton(1, 1, 8, 1, "OK")
        term:addWidget(btn)
        local r = term:keypressed("return")
        expect_false(r)
    end)
end)

-- =========================================================================
-- terminal max dimensions (PR-7)
-- =========================================================================

-- @description Covers suite: lurek.terminal queryable max dimensions.
describe("lurek.terminal max dimensions", function()
    -- @covers lurek.terminal.getMaxCols
    -- @description Verifies getMaxCols is exported as a callable function on the terminal namespace.
    it("getMaxCols_is_a_function", function()
        expect_type("function", lurek.terminal.getMaxCols)
    end)

    -- @covers lurek.terminal.getMaxRows
    -- @description Verifies getMaxRows is exported as a callable function on the terminal namespace.
    it("getMaxRows_is_a_function", function()
        expect_type("function", lurek.terminal.getMaxRows)
    end)

    -- @covers lurek.terminal.getMaxCols
    -- @description Confirms the engine-wide maximum column count constant is 512.
    it("getMaxCols_returns_512", function()
        expect_equal(512, lurek.terminal.getMaxCols())
    end)

    -- @covers lurek.terminal.getMaxRows
    -- @description Confirms the engine-wide maximum row count constant is 256.
    it("getMaxRows_returns_256", function()
        expect_equal(256, lurek.terminal.getMaxRows())
    end)

    -- @covers lurek.terminal.getMaxCols
    -- @description Confirms getMaxCols returns a number type.
    it("getMaxCols_return_type_is_number", function()
        expect_type("number", lurek.terminal.getMaxCols())
    end)

    -- @covers lurek.terminal.getMaxRows
    -- @description Confirms getMaxRows returns a number type.
    it("getMaxRows_return_type_is_number", function()
        expect_type("number", lurek.terminal.getMaxRows())
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_terminal_ansi_completion.lua
-- ═══════════════════════════════════════════════════════════════════════

describe("terminal.stripAnsi", function()

    it("stripAnsi exists in lurek.terminal", function()
        expect_equal(type(lurek.terminal.stripAnsi), "function")
    end)

    it("strips a simple red color code", function()
        local result = lurek.terminal.stripAnsi("\27[31mHello\27[0m world")
        expect_equal(result, "Hello world")
    end)

    it("strips empty ESC sequence", function()
        local result = lurek.terminal.stripAnsi("\27[mText")
        expect_equal(result, "Text")
    end)

    it("returns plain text unchanged", function()
        local result = lurek.terminal.stripAnsi("no escape codes here")
        expect_equal(result, "no escape codes here")
    end)

    it("strips multiple sequences", function()
        local result = lurek.terminal.stripAnsi("\27[1m\27[32mBold Green\27[0m")
        expect_equal(result, "Bold Green")
    end)

end)

describe("terminal.parseAnsi", function()

    it("parseAnsi exists in lurek.terminal", function()
        expect_equal(type(lurek.terminal.parseAnsi), "function")
    end)

    it("returns a table for plain text", function()
        local spans = lurek.terminal.parseAnsi("hello")
        expect_equal(type(spans), "table")
        expect_equal(#spans, 1)
        expect_equal(spans[1].text, "hello")
    end)

    it("span has bold=false for plain text", function()
        local spans = lurek.terminal.parseAnsi("plain")
        expect_equal(spans[1].bold, false)
    end)

    it("bold flag is set for ESC[1m", function()
        local spans = lurek.terminal.parseAnsi("\27[1mBold\27[0m")
        local bold_span = nil
        for _, s in ipairs(spans) do
            if s.text == "Bold" then bold_span = s end
        end
        expect_equal(bold_span ~= nil, true)
        expect_equal(bold_span.bold, true)
    end)

    it("fg color set for ESC[31m (red)", function()
        local spans = lurek.terminal.parseAnsi("\27[31mred\27[0m")
        local red_span = nil
        for _, s in ipairs(spans) do
            if s.text == "red" then red_span = s end
        end
        expect_equal(red_span ~= nil, true)
        expect_equal(type(red_span.fg), "table")
        expect_equal(red_span.fg.r > 0, true)
    end)

    it("reset clears color", function()
        local spans = lurek.terminal.parseAnsi("\27[31mred\27[0mnormal")
        local normal = nil
        for _, s in ipairs(spans) do
            if s.text == "normal" then normal = s end
        end
        expect_equal(normal ~= nil, true)
        expect_equal(normal.fg, nil)
    end)

end)

describe("terminal.completion", function()

    it("addCompletion and getCompletions work", function()
        lurek.terminal.clearCompletions()
        lurek.terminal.addCompletion("help")
        lurek.terminal.addCompletion("hello")
        lurek.terminal.addCompletion("quit")
        local results = lurek.terminal.getCompletions("hel")
        expect_equal(type(results), "table")
        expect_equal(#results, 2)
    end)

    it("getCompletions returns empty for no match", function()
        lurek.terminal.clearCompletions()
        lurek.terminal.addCompletion("world")
        local results = lurek.terminal.getCompletions("xyz")
        expect_equal(#results, 0)
    end)

    it("nextCompletion returns a string for matching prefix", function()
        lurek.terminal.clearCompletions()
        lurek.terminal.addCompletion("help")
        local result = lurek.terminal.nextCompletion("hel")
        expect_equal(result, "help")
    end)

    it("nextCompletion returns nil for no match", function()
        lurek.terminal.clearCompletions()
        local result = lurek.terminal.nextCompletion("xyz")
        expect_equal(result, nil)
    end)

    it("nextCompletion cycles on repeated calls", function()
        lurek.terminal.clearCompletions()
        lurek.terminal.addCompletion("hello")
        lurek.terminal.addCompletion("help")
        local first  = lurek.terminal.nextCompletion("hel")
        local second = lurek.terminal.nextCompletion("hel")
        expect_equal(first ~= second, true)
    end)

    it("resetCompletion resets cycle", function()
        lurek.terminal.clearCompletions()
        lurek.terminal.addCompletion("hello")
        lurek.terminal.addCompletion("help")
        lurek.terminal.nextCompletion("hel")  -- advance cycle
        lurek.terminal.resetCompletion()
        local after_reset = lurek.terminal.nextCompletion("hel")
        -- After reset, should return first candidate again
        expect_equal(after_reset ~= nil, true)
    end)

    it("removeCompletion removes a candidate", function()
        lurek.terminal.clearCompletions()
        lurek.terminal.addCompletion("help")
        lurek.terminal.addCompletion("hello")
        lurek.terminal.removeCompletion("help")
        local results = lurek.terminal.getCompletions("hel")
        expect_equal(#results, 1)
        expect_equal(results[1], "hello")
    end)

    it("clearCompletions empties the list", function()
        lurek.terminal.addCompletion("anything")
        lurek.terminal.clearCompletions()
        local results = lurek.terminal.getCompletions("")
        expect_equal(#results, 0)
    end)

end)

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_terminal_cell_size.lua
-- ═══════════════════════════════════════════════════════════════════════

describe("terminal:setCellSize type guards", function()
  it("setCellSize is a function", function()
    local t = lurek.terminal.new(20, 10)
    expect_type("function", t.setCellSize)
  end)

  it("resetCellSize is a function", function()
    local t = lurek.terminal.new(20, 10)
    expect_type("function", t.resetCellSize)
  end)

  it("getCellSize is a function", function()
    local t = lurek.terminal.new(20, 10)
    expect_type("function", t.getCellSize)
  end)
end)

describe("terminal getCellSize default", function()
  it("getCellSize returns nil before any override is set", function()
    local t = lurek.terminal.new(20, 10)
    local result = t:getCellSize()
    expect_equal(nil, result)
  end)
end)

describe("terminal setCellSize / getCellSize roundtrip", function()
  it("getCellSize returns set values after setCellSize", function()
    local t = lurek.terminal.new(20, 10)
    t:setCellSize(12, 20)
    local cs = t:getCellSize()
    expect_type("table", cs)
    expect_near(12.0, cs.w, 0.001)
    expect_near(20.0, cs.h, 0.001)
  end)

  it("setCellSize clamps values below 1 to 1", function()
    local t = lurek.terminal.new(20, 10)
    t:setCellSize(0, -5)
    local cs = t:getCellSize()
    expect_type("table", cs)
    expect_equal(true, cs.w >= 1.0)
    expect_equal(true, cs.h >= 1.0)
  end)

  it("setCellSize with large values is stored correctly", function()
    local t = lurek.terminal.new(20, 10)
    t:setCellSize(64, 128)
    local cs = t:getCellSize()
    expect_near(64.0, cs.w, 0.001)
    expect_near(128.0, cs.h, 0.001)
  end)
end)

describe("terminal resetCellSize", function()
  it("getCellSize returns nil after resetCellSize", function()
    local t = lurek.terminal.new(20, 10)
    t:setCellSize(10, 18)
    t:resetCellSize()
    local cs = t:getCellSize()
    expect_equal(nil, cs)
  end)

  it("override can be set again after reset", function()
    local t = lurek.terminal.new(20, 10)
    t:setCellSize(10, 18)
    t:resetCellSize()
    t:setCellSize(5, 9)
    local cs = t:getCellSize()
    expect_type("table", cs)
    expect_near(5.0, cs.w, 0.001)
    expect_near(9.0, cs.h, 0.001)
  end)
end)

test_summary()
