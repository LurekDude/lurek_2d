-- tests/lua/unit/test_ai.lua
describe("lurek.ai FSM", function()
    it("transitions from patrol to alert when condition fires", function()
        local w   = lurek.ai.newWorld()
        local a   = w:newAgent("guard", 0, 0)
        local fsm = a:useFsm()
        fsm:addState("patrol", nil, nil, nil)
        fsm:addState("alert",  nil, nil, nil)

        local triggered = false
        fsm:addTransition("patrol", "alert", 1, function() return triggered end)
        fsm:setState("patrol")

        w:update(0.016)
        expect_equal("patrol", a:getState())

        triggered = true
        w:update(0.016)
        expect_equal("alert", a:getState())
    end)
end)
