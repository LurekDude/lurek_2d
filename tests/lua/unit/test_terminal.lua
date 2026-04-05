-- tests/lua/unit/test_terminal.lua
-- BDD tests for the luna.terminal.* API.

require("tests/lua/init")

local function click_cell(term, col, row, button)
    local cell_w, cell_h = term:getCellSize()
    term:mousepressed((col - 1) * cell_w + 1, (row - 1) * cell_h + 1, button or 1)
end

describe("luna.terminal module", function()
    it("exposes terminal constructors", function()
        expect_type("table", luna.terminal)
        expect_type("function", luna.terminal.newTerminal)
        expect_type("function", luna.terminal.newLabel)
        expect_type("function", luna.terminal.newButton)
        expect_type("function", luna.terminal.newTextBox)
        expect_type("function", luna.terminal.newList)
        expect_type("function", luna.terminal.newBorder)
        expect_type("function", luna.terminal.newPanel)
    end)
end)

describe("terminal handles", function()
    it("creates terminal userdata and accepts colon or explicit self syntax", function()
        local term = luna.terminal.newTerminal(40, 20)
        expect_equal("userdata", type(term))

        local cols1, rows1 = term:getDimensions()
        local cols2, rows2 = term.getDimensions(term)
        expect_equal(40, cols1)
        expect_equal(20, rows1)
        expect_equal(40, cols2)
        expect_equal(20, rows2)
    end)

    it("reports the default cell size through colon and explicit self syntax", function()
        local term = luna.terminal.newTerminal(10, 5)
        local cell_w1, cell_h1 = term:getCellSize()
        local cell_w2, cell_h2 = term.getCellSize(term)

        expect_near(8.0, cell_w1, 0.001)
        expect_near(14.0, cell_h1, 0.001)
        expect_near(8.0, cell_w2, 0.001)
        expect_near(14.0, cell_h2, 0.001)
    end)

    it("sets and gets cells with colon syntax", function()
        local term = luna.terminal.newTerminal(10, 5)
        term:set(2, 3, "A", 1, 0.5, 0, 1)

        local ch, fr, fg, fb, fa = term:get(2, 3)
        expect_equal(string.byte("A"), ch)
        expect_near(1.0, fr, 0.01)
        expect_near(0.5, fg, 0.01)
        expect_near(0.0, fb, 0.01)
        expect_near(1.0, fa, 0.01)
    end)

    it("clears cells back to defaults", function()
        local term = luna.terminal.newTerminal(10, 5)
        term:set(2, 2, "X", 1, 0, 0, 1)
        term:clear()

        local ch = term:get(2, 2)
        expect_equal(string.byte(" "), ch)
    end)

    it("supports explicit self syntax on widget handles", function()
        local label = luna.terminal.newLabel(1, 1, "Hello")
        expect_equal("Hello", label.getText(label))

        label.setText(label, "Updated")
        expect_equal("Updated", label:getText())
    end)
end)

describe("widget attachment and focus", function()
    it("attaches detached widgets to a terminal", function()
        local term = luna.terminal.newTerminal(20, 10)
        local label = luna.terminal.newLabel(2, 3, "Status")

        expect_equal(0, term:getWidgetCount())
        term:addWidget(label)
        expect_equal(1, term:getWidgetCount())

        local col, row = label:getPosition()
        expect_equal(2, col)
        expect_equal(3, row)
    end)

    it("removeWidget detaches the handle and clears focus for the removed widget", function()
        local term = luna.terminal.newTerminal(20, 10)
        local button = luna.terminal.newButton(2, 2, 8, 1, "Play")

        term:addWidget(button)
        term:setFocus(button)
        term:removeWidget(button)

        expect_equal(0, term:getWidgetCount())
        expect_nil(term:getFocused())

        button:setText("Detached")
        expect_equal("Detached", button:getText())
    end)

    it("clearWidgets detaches all handles and clears focus", function()
        local term = luna.terminal.newTerminal(20, 10)
        local label = luna.terminal.newLabel(1, 1, "HUD")
        local input = luna.terminal.newTextBox(1, 2, 10)

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

    it("setFocus and getFocused work with attached widget handles", function()
        local term = luna.terminal.newTerminal(20, 10)
        local input = luna.terminal.newTextBox(1, 1, 10)

        term:addWidget(input)
        term:setFocus(input)

        local focused = term:getFocused()
        expect_equal("userdata", type(focused))

        focused:setText("Hero")
        expect_equal("Hero", input:getText())
    end)

    it("panel addChild auto-attaches detached children when the panel is attached", function()
        local term = luna.terminal.newTerminal(30, 12)
        local panel = luna.terminal.newPanel(1, 1, 20, 8)
        local child = luna.terminal.newLabel(2, 2, "Child")

        term:addWidget(panel)
        panel:addChild(child)

        expect_equal(2, term:getWidgetCount())
        expect_equal(1, panel:getChildCount())
        expect_equal("Child", panel:getChild(1):getText())
    end)

    it("mousepressed miss clears focus", function()
        local term = luna.terminal.newTerminal(20, 10)
        local button = luna.terminal.newButton(3, 2, 8, 1, "OK")

        term:addWidget(button)
        term:setFocus(button)
        term:mousepressed(1, 1, 1)

        expect_nil(term:getFocused())
    end)
end)

describe("widget property helpers", function()
    it("supports visibility, enabled, and tag helpers on attached widgets", function()
        local term = luna.terminal.newTerminal(20, 10)
        local label = luna.terminal.newLabel(1, 1, "Status")

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

    it("supports setColor and getColor on labels and borders", function()
        local label = luna.terminal.newLabel(1, 1, "Info")
        local border = luna.terminal.newBorder(1, 2, 12, 4)

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

    it("supports setText and getText on buttons and text boxes", function()
        local button = luna.terminal.newButton(1, 1, 8, 1, "Old")
        local textbox = luna.terminal.newTextBox(1, 2, 10)

        button:setText("Launch")
        textbox.setText(textbox, "Updated")

        expect_equal("Launch", button:getText())
        expect_equal("Updated", textbox.getText(textbox))
    end)

    it("supports setMaxLength and getMaxLength on text boxes", function()
        local textbox = luna.terminal.newTextBox(1, 1, 10)

        textbox:setMaxLength(4)
        textbox:setText("abcdef")

        expect_equal(4, textbox:getMaxLength())
        expect_equal("abcd", textbox:getText())
    end)

    it("supports list item management helpers", function()
        local list = luna.terminal.newList(1, 1, 20, 5)
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

    it("supports panel child management helpers", function()
        local term = luna.terminal.newTerminal(30, 12)
        local panel = luna.terminal.newPanel(1, 1, 20, 8)
        local child1 = luna.terminal.newLabel(2, 2, "One")
        local child2 = luna.terminal.newLabel(2, 3, "Two")

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

    it("supports border style and title updates", function()
        local border = luna.terminal.newBorder(1, 1, 12, 5)
        border:setStyle("double")
        border:setTitle("Menu")

        expect_equal("double", border:getStyle())
        expect_equal("Menu", border:getTitle())
    end)
end)

describe("button callbacks", function()
    it("keeps onClick callbacks working after attachment and reattachment", function()
        local term = luna.terminal.newTerminal(20, 10)
        local button = luna.terminal.newButton(3, 2, 8, 1, "OK")
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

describe("text box callbacks", function()
    it("fires onChange for setText, textinput, backspace, and delete", function()
        local term = luna.terminal.newTerminal(30, 10)
        local input = luna.terminal.newTextBox(1, 1, 12)
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

describe("list callbacks", function()
    it("fires onSelect for setSelected, keyboard navigation, and mouse presses", function()
        local term = luna.terminal.newTerminal(30, 12)
        local list = luna.terminal.newList(1, 1, 12, 4)
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

test_summary()
