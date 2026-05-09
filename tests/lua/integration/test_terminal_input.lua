-- Integration: in-game terminal widget capturing keyboard text input
describe("terminal + input integration", function()
    -- @integration lurek.input.keyboard.hasTextInput
    -- @integration lurek.input.keyboard.setTextInput
    -- @integration LTerminal:addWidget
    -- @integration LTerminal:getFocused
    -- @integration LTerminal:setFocus
    -- @integration LTerminal:textinput
    -- @integration LWidget:getText
    -- @integration lurek.terminal.newTerminal
    -- @integration lurek.terminal.newTextBox
    it("focused terminal text box accepts text while keyboard text input mode is enabled", function()
        local term = lurek.terminal.newTerminal(40, 12)
        local input = lurek.terminal.newTextBox(2, 2, 18)

        lurek.input.keyboard.setTextInput(false)
        expect_false(lurek.input.keyboard.hasTextInput())

        term:addWidget(input)
        term:setFocus(input)
        expect_equal("userdata", type(term:getFocused()))

        lurek.input.keyboard.setTextInput(true)
        expect_true(lurek.input.keyboard.hasTextInput())

        expect_true(term:textinput("r"))
        expect_equal("r", input:getText())

        lurek.input.keyboard.setTextInput(false)
        expect_false(lurek.input.keyboard.hasTextInput())
    end)

    -- @integration lurek.input.keyboard.isDown
    -- @integration LTerminal:addWidget
    -- @integration LTerminal:keypressed
    -- @integration LTerminal:setFocus
    -- @integration LWidget:setOnClick
    -- @integration lurek.terminal.newButton
    -- @integration lurek.terminal.newTerminal
    it("terminal-consumed key events do not mutate global keyboard down state", function()
        local term = lurek.terminal.newTerminal(30, 10)
        local button = lurek.terminal.newButton(2, 2, 10, 1, "Run")
        local clicks = 0

        button:setOnClick(function()
            clicks = clicks + 1
        end)

        term:addWidget(button)
        term:setFocus(button)

        expect_false(lurek.input.keyboard.isDown("return"))
        expect_true(term:keypressed("return"))
        expect_equal(1, clicks)
        expect_false(lurek.input.keyboard.isDown("return"))
    end)
end)
test_summary()

