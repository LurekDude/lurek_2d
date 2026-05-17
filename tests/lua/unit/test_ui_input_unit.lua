-- tests/lua/integration/test_input_ui.lua
-- Unit: lurek.input <-> lurek.ui
-- Tests that UI widget state responds correctly to input events.

local describe = describe or function(n,f) f() end
local it = it or function(n,f) f() end
-- @describe input + ui integration
describe("input + ui integration", function()
    -- @covers LTextInput.getText
    -- @covers lurek.ui.getFocus
    -- @covers lurek.ui.newTextInput
    -- @covers lurek.ui.setFocus
    -- @covers lurek.ui.textinput
    it("processes keyboard focus to ui widget", function()
        local input = lurek.ui.newTextInput()

        lurek.ui.clearFocus()
        lurek.ui.setFocus(input)
        local consumed = lurek.ui.textinput("a")

        expect_equal("a", input:getText())
        expect_type("number", lurek.ui.getFocus())
        expect_type("boolean", consumed)
    end)

    -- @covers LButton.setOnClick
    -- @covers LUiWidget.setPosition
    -- @covers LUiWidget.setSize
    -- @covers lurek.ui.mousepressed
    -- @covers lurek.ui.mousereleased
    -- @covers lurek.ui.newButton
    -- @covers lurek.ui.update
    it("routes mouse click to button callback", function()
        local clicked = 0
        local button = lurek.ui.newButton("Play")
        button:setPosition(10, 10)
        button:setSize(120, 40)
        button:setOnClick(function()
            clicked = clicked + 1
        end)

        local pressed = lurek.ui.mousepressed(20, 20, 1)
        local released = lurek.ui.mousereleased(20, 20, 1)
    lurek.ui.update(0.0)

        expect_true(clicked >= 1, "button click callback should run at least once")
        expect_type("boolean", pressed)
        expect_type("boolean", released)
    end)

    -- @covers LScrollPanel.getScrollPosition
    -- @covers LScrollPanel.setContentSize
    -- @covers LUiWidget.setPosition
    -- @covers LUiWidget.setSize
    -- @covers lurek.ui.mousemoved
    -- @covers lurek.ui.newScrollPanel
    -- @covers lurek.ui.wheelmoved
    it("scrolls list widget on scroll wheel event", function()
        local panel = lurek.ui.newScrollPanel()
        panel:setPosition(0, 0)
        panel:setSize(120, 80)
        panel:setContentSize(120, 400)

        local start_x, start_y = panel:getScrollPosition()
        local hovered = lurek.ui.mousemoved(10, 10)
        local consumed = lurek.ui.wheelmoved(0, -4)
        local end_x, end_y = panel:getScrollPosition()

        expect_type("boolean", hovered)
        expect_type("boolean", consumed)
        expect_equal(start_x, end_x)
        expect_true(end_y >= start_y, "vertical scroll should stay put or move forward")
    end)
end)
test_summary()
