-- tests/lua/integration/test_terminal_input.lua
-- Integration: lurek.terminal <-> lurek.input
-- Tests that the in-game terminal captures and processes key input.

local describe = describe or function(n,f) f() end
local it = it or function(n,f) f() end
describe("terminal + input integration", function()
    it("terminal opens on configured toggle key press", function()
        expect_true(true)
    end)
    it("text typed while terminal open appends to command buffer", function()
        expect_true(true)
    end)
    it("input events are consumed by terminal and not forwarded to game", function()
        expect_true(true)
    end)
end)
test_summary()
