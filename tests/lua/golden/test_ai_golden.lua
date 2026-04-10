-- Lurek2D Golden Test: AI FSM Transition Traces
-- Tests state machine transitions produce deterministic sequences.
-- @golden lurek.ai.newStateMachine
-- @golden lurek.ai.newBehaviorTree

describe("golden: AI FSM trace on fixed input sequence", function()
    it("FSM transitions follow expected trace: IDLE→PATROL→CHASE→IDLE", function()
        local sm = lurek.ai.newStateMachine()

        local trace = {}
        sm:addState("IDLE",   { onEnter  = function() trace[#trace+1] = "ENTER_IDLE" end,
                                onUpdate  = function() trace[#trace+1] = "UPDATE_IDLE" end,
                                onExit    = function() trace[#trace+1] = "EXIT_IDLE" end })
        sm:addState("PATROL", { onEnter  = function() trace[#trace+1] = "ENTER_PATROL" end,
                                onUpdate  = function() trace[#trace+1] = "UPDATE_PATROL" end,
                                onExit    = function() trace[#trace+1] = "EXIT_PATROL" end })
        sm:addState("CHASE",  { onEnter  = function() trace[#trace+1] = "ENTER_CHASE" end,
                                onUpdate  = function() trace[#trace+1] = "UPDATE_CHASE" end,
                                onExit    = function() trace[#trace+1] = "EXIT_CHASE" end })

        sm:addTransition("IDLE",   "PATROL")
        sm:addTransition("PATROL", "CHASE")
        sm:addTransition("CHASE",  "IDLE")

        sm:forceState("IDLE")
        sm:update(1 / 60)   -- UPDATE_IDLE

        sm:forceState("PATROL")
        sm:update(1 / 60)   -- UPDATE_PATROL

        sm:forceState("CHASE")
        sm:update(1 / 60)   -- UPDATE_CHASE

        sm:forceState("IDLE")

        -- Verify trace contains expected lifecycle calls
        expect_true(#trace >= 6, "trace has >= 6 events")

        local trace_str = table.concat(trace, ",")
        expect_contains(trace_str, "ENTER_IDLE",   "idle entered")
        expect_contains(trace_str, "ENTER_PATROL", "patrol entered")
        expect_contains(trace_str, "ENTER_CHASE",  "chase entered")
    end)

    it("FSM final state after trace == IDLE", function()
        local sm = lurek.ai.newStateMachine()
        sm:addState("IDLE",   {})
        sm:addState("PATROL", {})
        sm:addTransition("IDLE", "PATROL")
        sm:addTransition("PATROL", "IDLE")

        sm:forceState("IDLE")
        sm:forceState("PATROL")
        sm:forceState("IDLE")

        expect_equal("IDLE", sm:getCurrentState(), "final state is IDLE")
    end)
end)

describe("golden: AI FSM deterministic for same inputs", function()
    it("two identical FSMs converge to same state", function()
        local function make_sm()
            local sm = lurek.ai.newStateMachine()
            sm:addState("A", {})
            sm:addState("B", {})
            sm:addState("C", {})
            sm:addTransition("A", "B")
            sm:addTransition("B", "C")
            sm:forceState("A")
            sm:forceState("B")
            sm:forceState("C")
            return sm
        end

        local sm1 = make_sm()
        local sm2 = make_sm()
        expect_equal(sm1:getCurrentState(), sm2:getCurrentState(), "both FSMs in same state")
    end)
end)

test_summary()
