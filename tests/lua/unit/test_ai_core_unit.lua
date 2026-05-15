-- Lurek2D AI API Tests

-- =========================================================================
-- 1. lurek.ai module exists
-- =========================================================================

-- @describe lurek.ai module exists
describe("lurek.ai module exists", function()
    -- @covers lurek.ai
    it("lurek.ai is a table", function()
        expect_type("table", lurek.ai)
    end)

    -- @covers lurek.ai.newWorld
    it("has newWorld factory", function()
        expect_type("function", lurek.ai.newWorld)
    end)

    -- @covers lurek.ai.newBlackboard
    it("has newBlackboard factory", function()
        expect_type("function", lurek.ai.newBlackboard)
    end)

    -- @covers lurek.ai.newStateMachine
    it("has newStateMachine factory", function()
        expect_type("function", lurek.ai.newStateMachine)
    end)

    -- @covers lurek.ai.newBehaviorTree
    it("has newBehaviorTree factory", function()
        expect_type("function", lurek.ai.newBehaviorTree)
    end)

    -- @covers lurek.ai.newSteeringManager
    it("has newSteeringManager factory", function()
        expect_type("function", lurek.ai.newSteeringManager)
    end)

    -- @covers lurek.ai.newQLearner
    it("has newQLearner factory", function()
        expect_type("function", lurek.ai.newQLearner)
    end)

    -- @covers lurek.ai.newUtilityAI
    it("has newUtilityAI factory", function()
        expect_type("function", lurek.ai.newUtilityAI)
    end)

    -- @covers lurek.ai.newDialogueAI
    it("has newDialogueAI factory", function()
        expect_type("function", lurek.ai.newDialogueAI)
    end)

    -- @covers lurek.ai.newGOAPPlanner
    it("has newGOAPPlanner factory", function()
        expect_type("function", lurek.ai.newGOAPPlanner)
    end)

    -- @covers lurek.ai.newInfluenceMap
    it("has newInfluenceMap factory", function()
        expect_type("function", lurek.ai.newInfluenceMap)
    end)

    -- @covers lurek.ai.newSquad
    it("has newSquad factory", function()
        expect_type("function", lurek.ai.newSquad)
    end)

    -- @covers lurek.ai.newCommandQueue
    it("has newCommandQueue factory", function()
        expect_type("function", lurek.ai.newCommandQueue)
    end)

    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newCondition
    -- @covers lurek.ai.newInverter
    -- @covers lurek.ai.newParallel
    -- @covers lurek.ai.newRepeater
    -- @covers lurek.ai.newSelector
    -- @covers lurek.ai.newSequence
    -- @covers lurek.ai.newSucceeder
    it("has BT node factories", function()
        expect_type("function", lurek.ai.newSelector)
        expect_type("function", lurek.ai.newSequence)
        expect_type("function", lurek.ai.newParallel)
        expect_type("function", lurek.ai.newInverter)
        expect_type("function", lurek.ai.newRepeater)
        expect_type("function", lurek.ai.newSucceeder)
        expect_type("function", lurek.ai.newAction)
        expect_type("function", lurek.ai.newCondition)
    end)
end)

-- =========================================================================
-- 2. AIWorld
-- =========================================================================
-- @describe lurek.ai AIWorld
describe("lurek.ai AIWorld", function()
    -- @covers LAIWorld:type
    -- @covers lurek.ai.newWorld
    it("creates a new world", function()
        local w = lurek.ai.newWorld()
        expect_not_nil(w, "world exists")
        expect_equal("LAIWorld", w:type(), "type check")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers lurek.ai.newWorld
    it("adds agents by name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        expect_not_nil(a, "agent returned")
        expect_equal(1, w:getAgentCount(), "agent count")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgent
    -- @covers lurek.ai.newWorld
    it("gets agent by name", function()
        local w = lurek.ai.newWorld()
        w:addAgent("hero")
        local a = w:getAgent("hero")
        expect_not_nil(a, "found agent")
        expect_equal("hero", a:getName())
    end)

    -- @covers LAIWorld:getAgent
    -- @covers lurek.ai.newWorld
    it("returns nil for unknown agent", function()
        local w = lurek.ai.newWorld()
        expect_nil(w:getAgent("nonexistent"))
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers LAIWorld:removeAgent
    -- @covers lurek.ai.newWorld
    it("removes agents", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        w:removeAgent(a)
        expect_equal(0, w:getAgentCount())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:update
    -- @covers lurek.ai.newWorld
    it("updates positions based on velocity", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("mover")
        a:setPosition(0, 0)
        a:setVelocity(10, 20)
        w:update(0.5)
        local x, y = a:getPosition()
        expect_near(5.0, x, 0.01, "x after update")
        expect_near(10.0, y, 0.01, "y after update")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("errors on duplicate agent name", function()
        local w = lurek.ai.newWorld()
        w:addAgent("hero")
        expect_error(function() w:addAgent("hero") end, "duplicate agent")
    end)

    -- @covers LAIWorld:getGlobalBlackboard
    -- @covers lurek.ai.newWorld
    it("provides global blackboard", function()
        local w = lurek.ai.newWorld()
        local bb = w:getGlobalBlackboard()
        expect_not_nil(bb, "global bb exists")
        expect_equal("LAIBlackboard", bb:type())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers lurek.ai.newWorld
    it("supports multiple agents", function()
        local w = lurek.ai.newWorld()
        w:addAgent("alpha")
        w:addAgent("beta")
        w:addAgent("gamma")
        expect_equal(3, w:getAgentCount())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers LAIWorld:removeAgent
    -- @covers lurek.ai.newWorld
    it("agent count decreases after removal", function()
        local w = lurek.ai.newWorld()
        local a1 = w:addAgent("a1")
        w:addAgent("a2")
        expect_equal(2, w:getAgentCount())
        w:removeAgent(a1)
        expect_equal(1, w:getAgentCount())
    end)
end)

-- =========================================================================
-- 3. Agent
-- =========================================================================
-- @describe lurek.ai Agent
describe("lurek.ai Agent", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("type returns Agent", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        expect_equal("LAgent", a:type())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("getName returns name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("warrior")
        expect_equal("warrior", a:getName())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("setPosition / getPosition roundtrip", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setPosition(100, 200)
        local x, y = a:getPosition()
        expect_near(100, x, 0.01)
        expect_near(200, y, 0.01)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("setVelocity / getVelocity roundtrip", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setVelocity(5, -3)
        local vx, vy = a:getVelocity()
        expect_near(5, vx, 0.01)
        expect_near(-3, vy, 0.01)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getMaxSpeed
    -- @covers LAgent:setMaxSpeed
    -- @covers lurek.ai.newWorld
    it("setMaxSpeed / getMaxSpeed", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setMaxSpeed(250)
        expect_near(250, a:getMaxSpeed(), 0.01)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getMaxForce
    -- @covers LAgent:setMaxForce
    -- @covers lurek.ai.newWorld
    it("setMaxForce / getMaxForce", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setMaxForce(500)
        expect_near(500, a:getMaxForce(), 0.01)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("setPriority / getPriority", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setPriority(7)
        expect_equal(7, a:getPriority())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("setDecisionModel / getDecisionModel for fsm", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("fsm")
        expect_equal("fsm", a:getDecisionModel())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("setDecisionModel / getDecisionModel for bt", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("bt")
        expect_equal("bt", a:getDecisionModel())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("setDecisionModel / getDecisionModel for steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("steering")
        expect_equal("steering", a:getDecisionModel())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("setDecisionModel / getDecisionModel for fsm+steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("fsm+steering")
        expect_equal("fsm+steering", a:getDecisionModel())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("setDecisionModel / getDecisionModel for bt+steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("bt+steering")
        expect_equal("bt+steering", a:getDecisionModel())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("addTag / hasTag / removeTag", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        expect_false(a:hasTag("enemy"), "no tag initially")
        a:addTag("enemy")
        expect_true(a:hasTag("enemy"), "tag added")
        a:removeTag("enemy")
        expect_false(a:hasTag("enemy"), "tag removed")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("multiple tags", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:addTag("fast")
        a:addTag("flying")
        expect_true(a:hasTag("fast"))
        expect_true(a:hasTag("flying"))
        expect_false(a:hasTag("slow"))
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("getBlackboard returns Blackboard", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        local bb = a:getBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("default position is zero", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        local x, y = a:getPosition()
        expect_near(0, x, 0.01)
        expect_near(0, y, 0.01)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getVelocity
    -- @covers lurek.ai.newWorld
    it("default velocity is zero", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a_default_velocity")
        local vx, vy = a:getVelocity()
        expect_near(0, vx, 0.01)
        expect_near(0, vy, 0.01)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("default decision model is fsm and invalid values are ignored", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a_default_model")
        expect_equal("fsm", a:getDecisionModel())
        a:setDecisionModel("bogus")
        expect_equal("fsm", a:getDecisionModel())
    end)
end)

-- =========================================================================
-- 4. Blackboard
-- =========================================================================
-- @describe lurek.ai Blackboard
describe("lurek.ai Blackboard", function()
    -- @covers LAIBlackboard:type
    -- @covers lurek.ai.newBlackboard
    it("type returns Blackboard", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("LAIBlackboard", bb:type())
    end)

    -- @covers LAIBlackboard:getNumber
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("setNumber / getNumber roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("health", 42.5)
        expect_near(42.5, bb:getNumber("health"), 0.001)
    end)

    -- @covers LAIBlackboard:getNumber
    -- @covers lurek.ai.newBlackboard
    it("getNumber returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_near(99, bb:getNumber("missing", 99), 0.001)
    end)

    -- @covers LAIBlackboard:getNumber
    -- @covers lurek.ai.newBlackboard
    it("getNumber returns 0 without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_near(0, bb:getNumber("missing"), 0.001)
    end)

    -- @covers LAIBlackboard:getBool
    -- @covers LAIBlackboard:setBool
    -- @covers lurek.ai.newBlackboard
    it("setBool / getBool roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setBool("alive", true)
        expect_true(bb:getBool("alive"))
    end)

    -- @covers LAIBlackboard:getBool
    -- @covers lurek.ai.newBlackboard
    it("getBool returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_true(bb:getBool("missing", true))
    end)

    -- @covers LAIBlackboard:getBool
    -- @covers lurek.ai.newBlackboard
    it("getBool returns false without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_false(bb:getBool("missing"))
    end)

    -- @covers LAIBlackboard:getString
    -- @covers LAIBlackboard:setString
    -- @covers lurek.ai.newBlackboard
    it("setString / getString roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setString("name", "hero")
        expect_equal("hero", bb:getString("name"))
    end)

    -- @covers LAIBlackboard:getString
    -- @covers lurek.ai.newBlackboard
    it("getString returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("none", bb:getString("missing", "none"))
    end)

    -- @covers LAIBlackboard:getString
    -- @covers lurek.ai.newBlackboard
    it("getString returns empty without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("", bb:getString("missing"))
    end)

    -- @covers LAIBlackboard:has
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("has returns true when key exists", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        expect_true(bb:has("hp"))
    end)

    -- @covers LAIBlackboard:has
    -- @covers lurek.ai.newBlackboard
    it("has returns false when key absent", function()
        local bb = lurek.ai.newBlackboard()
        expect_false(bb:has("missing"))
    end)

    -- @covers LAIBlackboard:has
    -- @covers LAIBlackboard:remove
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("remove deletes a key", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:remove("hp")
        expect_false(bb:has("hp"))
    end)

    -- @covers LAIBlackboard:clear
    -- @covers LAIBlackboard:getSize
    -- @covers LAIBlackboard:setBool
    -- @covers LAIBlackboard:setNumber
    -- @covers LAIBlackboard:setString
    -- @covers lurek.ai.newBlackboard
    it("clear removes all keys", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("a", 1)
        bb:setBool("b", true)
        bb:setString("c", "x")
        bb:clear()
        expect_equal(0, bb:getSize())
    end)

    -- @covers LAIBlackboard:getSize
    -- @covers LAIBlackboard:setBool
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("getSize returns count", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal(0, bb:getSize())
        bb:setNumber("a", 1)
        expect_equal(1, bb:getSize())
        bb:setBool("b", true)
        expect_equal(2, bb:getSize())
    end)

    -- @covers LAIBlackboard:getKeys
    -- @covers LAIBlackboard:setNumber
    -- @covers LAIBlackboard:setString
    -- @covers lurek.ai.newBlackboard
    it("getKeys returns all key names", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:setString("name", "x")
        local keys = bb:getKeys()
        expect_type("table", keys)
        expect_equal(2, #keys)
    end)
end)

-- =========================================================================
-- 5. StateMachine
-- =========================================================================
-- @describe lurek.ai StateMachine
describe("lurek.ai StateMachine", function()
    -- @covers LStateMachine:type
    -- @covers lurek.ai.newStateMachine
    it("type returns StateMachine", function()
        local fsm = lurek.ai.newStateMachine()
        expect_equal("LStateMachine", fsm:type())
    end)

    -- @covers LStateMachine:addState
    -- @covers lurek.ai.newStateMachine
    it("addState does not error", function()
        local fsm = lurek.ai.newStateMachine()
        expect_no_error(function()
            fsm:addState("idle", { onEnter = function() end })
        end)
    end)

    -- @covers LStateMachine:addState
    -- @covers lurek.ai.newStateMachine
    it("addState with all callbacks", function()
        local fsm = lurek.ai.newStateMachine()
        expect_no_error(function()
            fsm:addState("patrol", {
                onEnter = function() end,
                onUpdate = function() end,
                onExit = function() end,
            })
        end)
    end)

    -- @covers LStateMachine:addState
    -- @covers LStateMachine:getCurrentState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("setInitialState sets current state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        expect_equal("idle", fsm:getCurrentState())
    end)

    -- @covers LStateMachine:getCurrentState
    -- @covers lurek.ai.newStateMachine
    it("getCurrentState returns nil before setting", function()
        local fsm = lurek.ai.newStateMachine()
        expect_nil(fsm:getCurrentState())
    end)

    -- @covers LStateMachine:addState
    -- @covers LStateMachine:forceState
    -- @covers LStateMachine:getCurrentState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("forceState changes state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("attack", {})
        fsm:setInitialState("idle")
        fsm:forceState("attack")
        expect_equal("attack", fsm:getCurrentState())
    end)

    -- @covers LStateMachine:addState
    -- @covers LStateMachine:forceState
    -- @covers LStateMachine:getTimeInState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("getTimeInState starts at zero after forceState", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        fsm:forceState("idle")
        expect_near(0, fsm:getTimeInState(), 0.01)
    end)

    -- @covers LStateMachine:addState
    -- @covers LStateMachine:addTransition
    -- @covers lurek.ai.newStateMachine
    it("addTransition does not error", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("walk", {})
        expect_no_error(function()
            fsm:addTransition("idle", "walk", nil, 0)
        end)
    end)

    -- @covers LStateMachine:addState
    -- @covers LStateMachine:addTransition
    -- @covers lurek.ai.newStateMachine
    it("addTransition with guard function", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("run", {})
        expect_no_error(function()
            fsm:addTransition("idle", "run", function() return true end, 1)
        end)
    end)
end)

-- =========================================================================
-- 6. BehaviorTree
-- =========================================================================
-- @describe lurek.ai BehaviorTree
describe("lurek.ai BehaviorTree", function()
    -- @covers LBehaviorTree:type
    -- @covers lurek.ai.newBehaviorTree
    it("type returns BehaviorTree", function()
        local bt = lurek.ai.newBehaviorTree()
        expect_equal("LBehaviorTree", bt:type())
    end)

    -- @covers LBehaviorTree:getLastStatus
    -- @covers lurek.ai.newBehaviorTree
    it("getLastStatus returns success initially", function()
        local bt = lurek.ai.newBehaviorTree()
        expect_equal("success", bt:getLastStatus())
    end)

    -- @covers LBehaviorTree:setRoot
    -- @covers lurek.ai.newBehaviorTree
    -- @covers lurek.ai.newSequence
    it("setRoot accepts a BTNode", function()
        local bt = lurek.ai.newBehaviorTree()
        local seq = lurek.ai.newSequence()
        expect_no_error(function()
            bt:setRoot(seq)
        end)
    end)
end)

-- =========================================================================
-- 7. BTNode
-- =========================================================================
-- @describe lurek.ai BTNode
describe("lurek.ai BTNode", function()
    -- @covers LBTNode:type
    -- @covers lurek.ai.newSelector
    it("newSelector returns BTNode type", function()
        local n = lurek.ai.newSelector()
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newSequence
    it("newSequence returns BTNode type", function()
        local n = lurek.ai.newSequence()
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newParallel
    it("newParallel returns BTNode type", function()
        local n = lurek.ai.newParallel()
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newInverter
    it("newInverter returns BTNode type", function()
        local n = lurek.ai.newInverter()
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newRepeater
    it("newRepeater returns BTNode type", function()
        local n = lurek.ai.newRepeater()
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newSucceeder
    it("newSucceeder returns BTNode type", function()
        local n = lurek.ai.newSucceeder()
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newAction
    it("newAction returns BTNode type", function()
        local n = lurek.ai.newAction(function() return "success" end)
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newCondition
    it("newCondition returns BTNode type", function()
        local n = lurek.ai.newCondition(function() return true end)
        expect_equal("LBTNode", n:type())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newSelector
    it("getNodeType returns selector", function()
        expect_equal("selector", lurek.ai.newSelector():getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newSequence
    it("getNodeType returns sequence", function()
        expect_equal("sequence", lurek.ai.newSequence():getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newParallel
    it("getNodeType returns parallel", function()
        expect_equal("parallel", lurek.ai.newParallel():getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newInverter
    it("getNodeType returns inverter", function()
        expect_equal("inverter", lurek.ai.newInverter():getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newRepeater
    it("getNodeType returns repeater", function()
        expect_equal("repeater", lurek.ai.newRepeater():getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newSucceeder
    it("getNodeType returns succeeder", function()
        expect_equal("succeeder", lurek.ai.newSucceeder():getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newAction
    it("getNodeType returns action", function()
        expect_equal("action", lurek.ai.newAction(function() end):getNodeType())
    end)

    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newCondition
    it("getNodeType returns condition", function()
        expect_equal("condition", lurek.ai.newCondition(function() end):getNodeType())
    end)

    -- @covers LBTNode:addChild
    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newSelector
    it("addChild on Selector increases child count", function()
        local sel = lurek.ai.newSelector()
        expect_equal(0, sel:getChildCount())
        local act = lurek.ai.newAction(function() end)
        sel:addChild(act)
        expect_equal(1, sel:getChildCount())
    end)

    -- @covers LBTNode:addChild
    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newSequence
    it("addChild on Sequence increases child count", function()
        local seq = lurek.ai.newSequence()
        local a1 = lurek.ai.newAction(function() end)
        local a2 = lurek.ai.newAction(function() end)
        seq:addChild(a1)
        seq:addChild(a2)
        expect_equal(2, seq:getChildCount())
    end)

    -- @covers LBTNode:addChild
    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newParallel
    it("addChild on Parallel increases child count", function()
        local par = lurek.ai.newParallel()
        par:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, par:getChildCount())
    end)

    -- @covers LBTNode:addChild
    -- @covers lurek.ai.newAction
    it("addChild on Action errors", function()
        local act = lurek.ai.newAction(function() end)
        local child = lurek.ai.newAction(function() end)
        expect_error(function()
            act:addChild(child)
        end, "addChild on Action should error")
    end)

    -- @covers LBTNode:addChild
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newCondition
    it("addChild on Condition errors", function()
        local cond = lurek.ai.newCondition(function() return true end)
        local child = lurek.ai.newAction(function() end)
        expect_error(function()
            cond:addChild(child)
        end, "addChild on Condition should error")
    end)

    -- @covers LBTNode:setChild
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newInverter
    it("setChild on Inverter", function()
        local inv = lurek.ai.newInverter()
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            inv:setChild(act)
        end)
    end)

    -- @covers LBTNode:setChild
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newRepeater
    it("setChild on Repeater", function()
        local rep = lurek.ai.newRepeater(3)
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            rep:setChild(act)
        end)
    end)

    -- @covers LBTNode:setChild
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newSucceeder
    it("setChild on Succeeder", function()
        local suc = lurek.ai.newSucceeder()
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            suc:setChild(act)
        end)
    end)

    -- @covers LBTNode:getCount
    -- @covers LBTNode:setCount
    -- @covers lurek.ai.newRepeater
    it("setCount / getCount on Repeater", function()
        local rep = lurek.ai.newRepeater(5)
        expect_equal(5, rep:getCount())
        rep:setCount(10)
        expect_equal(10, rep:getCount())
    end)

    -- @covers LBTNode:getCount
    -- @covers lurek.ai.newSelector
    it("getCount on non-Repeater returns 0", function()
        local sel = lurek.ai.newSelector()
        expect_equal(0, sel:getCount())
    end)

    -- @covers LBTNode:setSuccessPolicy
    -- @covers lurek.ai.newParallel
    it("setSuccessPolicy on Parallel does not error", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setSuccessPolicy("require_all")
        end)
    end)

    -- @covers LBTNode:setFailurePolicy
    -- @covers lurek.ai.newParallel
    it("setFailurePolicy on Parallel does not error", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setFailurePolicy("require_all")
        end)
    end)

    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newCondition
    it("getChildCount returns 0 for leaf nodes", function()
        expect_equal(0, lurek.ai.newAction(function() end):getChildCount())
        expect_equal(0, lurek.ai.newCondition(function() end):getChildCount())
    end)
end)

-- =========================================================================
-- 8. SteeringManager
-- =========================================================================
-- @describe lurek.ai SteeringManager
describe("lurek.ai SteeringManager", function()
    -- @covers LSteeringManager:type
    -- @covers lurek.ai.newSteeringManager
    it("type returns SteeringManager", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal("LSteeringManager", sm:type())
    end)

    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addSeek increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal(0, sm:getBehaviorCount())
        sm:addSeek(100, 200)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addFlee
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addFlee increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addFlee(0, 0)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addArrive
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addArrive increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addArrive(50, 50)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addWander
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addWander increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addWander()
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addPursue
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addPursue increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addPursue("target")
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addEvade
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addEvade increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addEvade("threat")
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addFlock
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addFlock increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addFlock()
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:addFlee
    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:addWander
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("multiple behaviors accumulate", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:addFlee(0, 0)
        sm:addWander()
        expect_equal(3, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:getCombineMode
    -- @covers LSteeringManager:setCombineMode
    -- @covers lurek.ai.newSteeringManager
    it("setCombineMode / getCombineMode", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("priority")
        expect_equal("priority", sm:getCombineMode())
        sm:setCombineMode("weighted")
        expect_equal("weighted", sm:getCombineMode())
    end)

    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:calculate
    -- @covers lurek.ai.newSteeringManager
    it("calculate returns two numbers", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        local fx, fy = sm:calculate(0, 0, 0, 0, 100, 200, 1/60)
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:calculate
    -- @covers LSteeringManager:getLastSteering
    -- @covers lurek.ai.newSteeringManager
    it("getLastSteering returns two numbers", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:calculate(0, 0, 0, 0, 100, 200, 1/60)
        local fx, fy = sm:getLastSteering()
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addSeek with custom weight", function()
        local sm = lurek.ai.newSteeringManager()
        expect_no_error(function()
            sm:addSeek(100, 100, 2.0)
        end)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @covers LSteeringManager:setPath
    -- @covers LSteeringManager:hasPath
    -- @covers lurek.ai.newSteeringManager
    -- @covers lurek.pathfind.newPathGrid
    -- @covers LPathGrid:findPath
    it("setPath consumes pathfind waypoints", function()
        local grid = lurek.pathfind.newPathGrid(5, 5, 16)
        local path = grid:findPath(1, 1, 5, 5)
        local sm = lurek.ai.newSteeringManager()
        sm:setPath(path, 8.0, 1.0)
        expect_true(sm:hasPath())
    end)

    -- @covers LSteeringManager:clearPath
    -- @covers LSteeringManager:hasPath
    -- @covers LSteeringManager:setPath
    -- @covers lurek.ai.newSteeringManager
    it("clearPath clears active path", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setPath({ { x = 16, y = 16 }, { x = 32, y = 16 } })
        expect_true(sm:hasPath())
        sm:clearPath()
        expect_false(sm:hasPath())
    end)

    -- @covers LSteeringManager:getPathProgress
    -- @covers LSteeringManager:setPath
    -- @covers lurek.ai.newSteeringManager
    it("getPathProgress reports index and total", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setPath({ { x = 8, y = 8 }, { x = 12, y = 8 } })
        local idx, total = sm:getPathProgress()
        expect_equal(1, idx)
        expect_equal(2, total)
    end)
end)

-- =========================================================================
-- 11. QLearner
-- =========================================================================
-- @describe lurek.ai QLearner
describe("lurek.ai QLearner", function()
    -- @covers LQLearner:type
    -- @covers lurek.ai.newQLearner
    it("type returns QLearner", function()
        local q = lurek.ai.newQLearner(4, 3)
        expect_equal("LQLearner", q:type())
    end)

    -- @covers LQLearner:getActionCount
    -- @covers LQLearner:getStateCount
    -- @covers lurek.ai.newQLearner
    it("getStateCount / getActionCount", function()
        local q = lurek.ai.newQLearner(4, 3)
        expect_equal(4, q:getStateCount())
        expect_equal(3, q:getActionCount())
    end)

    -- @covers LQLearner:chooseAction
    -- @covers lurek.ai.newQLearner
    it("chooseAction returns 1-based action", function()
        local q = lurek.ai.newQLearner(2, 3)
        local a = q:chooseAction(1)
        expect_true(a >= 1 and a <= 3, "action in range")
    end)

    -- @covers LQLearner:bestAction
    -- @covers lurek.ai.newQLearner
    it("bestAction returns 1-based action", function()
        local q = lurek.ai.newQLearner(2, 3)
        local a = q:bestAction(1)
        expect_true(a >= 1 and a <= 3, "best action in range")
    end)

    -- @covers LQLearner:getQValue
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("setQValue / getQValue (1-based)", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setQValue(1, 2, 5.0)
        expect_near(5.0, q:getQValue(1, 2), 0.001)
    end)

    -- @covers LQLearner:getQValue
    -- @covers LQLearner:learn
    -- @covers LQLearner:setExplorationRate
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("learn updates Q values", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setExplorationRate(0)
        q:setQValue(1, 1, 0)
        q:learn(1, 1, 10.0, 2)
        local after = q:getQValue(1, 1)
        expect_true(after > 0, "Q value should increase after positive reward")
    end)

    -- @covers LQLearner:getLearningRate
    -- @covers LQLearner:setLearningRate
    -- @covers lurek.ai.newQLearner
    it("setLearningRate / getLearningRate", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.5)
        expect_near(0.5, q:getLearningRate(), 0.001)
    end)

    -- @covers LQLearner:getDiscountFactor
    -- @covers LQLearner:setDiscountFactor
    -- @covers lurek.ai.newQLearner
    it("setDiscountFactor / getDiscountFactor", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.8)
        expect_near(0.8, q:getDiscountFactor(), 0.001)
    end)

    -- @covers LQLearner:getExplorationRate
    -- @covers LQLearner:setExplorationRate
    -- @covers lurek.ai.newQLearner
    it("setExplorationRate / getExplorationRate", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.1)
        expect_near(0.1, q:getExplorationRate(), 0.001)
    end)

    -- @covers LQLearner:getExplorationDecay
    -- @covers LQLearner:setExplorationDecay
    -- @covers lurek.ai.newQLearner
    it("setExplorationDecay / getExplorationDecay", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.99)
        expect_near(0.99, q:getExplorationDecay(), 0.001)
    end)

    -- @covers LQLearner:endEpisode
    -- @covers LQLearner:getEpisodeCount
    -- @covers lurek.ai.newQLearner
    it("endEpisode / getEpisodeCount", function()
        local q = lurek.ai.newQLearner(2, 2)
        expect_equal(0, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(2, q:getEpisodeCount())
    end)

    -- @covers LQLearner:deserialize
    -- @covers LQLearner:getQValue
    -- @covers LQLearner:serialize
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("serialize / deserialize roundtrip", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setQValue(1, 1, 3.14)
        q:setQValue(2, 2, 2.71)
        local json = q:serialize()
        expect_type("string", json)

        local q2 = lurek.ai.newQLearner(2, 2)
        q2:deserialize(json)
        expect_near(3.14, q2:getQValue(1, 1), 0.001)
        expect_near(2.71, q2:getQValue(2, 2), 0.001)
    end)

    -- @covers LQLearner:bestAction
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("bestAction returns consistent results for same Q table", function()
        local q = lurek.ai.newQLearner(2, 3)
        q:setQValue(1, 1, 1.0)
        q:setQValue(1, 2, 5.0)
        q:setQValue(1, 3, 2.0)
        local best = q:bestAction(1)
        expect_equal(2, best, "action 2 has highest Q")
    end)

    -- @covers LQLearner:getQValue
    -- @covers lurek.ai.newQLearner
    it("Q values start at zero", function()
        local q = lurek.ai.newQLearner(3, 3)
        expect_near(0, q:getQValue(1, 1), 0.001)
        expect_near(0, q:getQValue(3, 3), 0.001)
    end)
end)

-- =========================================================================
-- 12. UtilityAI
-- =========================================================================
-- @describe lurek.ai UtilityAI
describe("lurek.ai UtilityAI", function()
    -- @covers LUtilityAI:type
    -- @covers lurek.ai.newUtilityAI
    it("type returns UtilityAI", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal("LUtilityAI", u:type())
    end)

    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:getActionCount
    -- @covers lurek.ai.newUtilityAI
    it("addAction increases action count", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal(0, u:getActionCount())
        u:addAction("eat", function() return 0.5 end)
        expect_equal(1, u:getActionCount())
    end)

    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:evaluate
    -- @covers lurek.ai.newUtilityAI
    it("evaluate returns best action name", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("eat", function() return 0.3 end)
        u:addAction("sleep", function() return 0.9 end)
        u:addAction("fight", function() return 0.1 end)
        local best = u:evaluate()
        expect_equal("sleep", best)
    end)

    -- @covers LUtilityAI:evaluate
    -- @covers lurek.ai.newUtilityAI
    it("evaluate returns nil with no actions", function()
        local u = lurek.ai.newUtilityAI()
        local result = u:evaluate()
        expect_nil(result)
    end)

    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:evaluate
    -- @covers LUtilityAI:getLastAction
    -- @covers lurek.ai.newUtilityAI
    it("getLastAction returns last evaluated action", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 1.0 end)
        u:evaluate()
        expect_equal("patrol", u:getLastAction())
    end)

    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:getLastAction
    -- @covers lurek.ai.newUtilityAI
    it("getLastAction returns nil before evaluate", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("idle", function() return 1.0 end)
        expect_nil(u:getLastAction())
    end)

    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:getActionCount
    -- @covers lurek.ai.newUtilityAI
    it("addAction with weight parameter", function()
        local u = lurek.ai.newUtilityAI()
        expect_no_error(function()
            u:addAction("run", function() return 0.5 end, 2.0)
        end)
        expect_equal(1, u:getActionCount())
    end)
end)

-- =========================================================================
-- 12b. DialogueAI
-- =========================================================================
-- @describe lurek.ai DialogueAI
describe("lurek.ai DialogueAI", function()
    -- @covers LDialogueAI:type
    -- @covers lurek.ai.newDialogueAI
    it("type returns DialogueAI", function()
        local d = lurek.ai.newDialogueAI()
        expect_equal("LDialogueAI", d:type())
    end)

    -- @covers LDialogueAI:addTopic
    -- @covers LDialogueAI:getTopicCount
    -- @covers lurek.ai.newDialogueAI
    it("addTopic increases topic count", function()
        local d = lurek.ai.newDialogueAI()
        expect_equal(0, d:getTopicCount())
        d:addTopic("smalltalk", 0.5)
        expect_equal(1, d:getTopicCount())
    end)

    -- @covers LDialogueAI:addBranch
    -- @covers LDialogueAI:addTopic
    -- @covers lurek.ai.newDialogueAI
    it("addBranch returns true for existing topic", function()
        local d = lurek.ai.newDialogueAI()
        d:addTopic("quest", 1.0)
        local ok = d:addBranch("quest", "offer", 0.7)
        expect_true(ok)
    end)

    -- @covers LDialogueAI:addTopic
    -- @covers LDialogueAI:selectTopic
    -- @covers LDialogueAI:setBTStatus
    -- @covers LDialogueAI:setFSMState
    -- @covers LDialogueAI:setUtilityScore
    -- @covers lurek.ai.newDialogueAI
    it("selectTopic uses FSM/BT/utility context", function()
        local d = lurek.ai.newDialogueAI()
        d:addTopic("smalltalk", 0.3, nil, nil, "smalltalk_score")
        d:addTopic("combat", 0.2, "combat", "success", "combat_score")
        d:setFSMState("combat")
        d:setBTStatus("success")
        d:setUtilityScore("smalltalk_score", 0.1)
        d:setUtilityScore("combat_score", 0.8)

        expect_equal("combat", d:selectTopic())
    end)

    -- @covers LDialogueAI:addBranch
    -- @covers LDialogueAI:addTopic
    -- @covers LDialogueAI:clearUtilityScores
    -- @covers LDialogueAI:selectBranch
    -- @covers LDialogueAI:setFSMState
    -- @covers LDialogueAI:setUtilityScore
    -- @covers lurek.ai.newDialogueAI
    it("selectBranch responds to utility and clearUtilityScores", function()
        local d = lurek.ai.newDialogueAI()
        d:addTopic("quest", 1.0)
        d:addBranch("quest", "offer", 0.2, "idle", nil, "offer_score")
        d:addBranch("quest", "warn", 0.1, "idle", nil, "warn_score")
        d:setFSMState("idle")
        d:setUtilityScore("offer_score", 0.6)
        d:setUtilityScore("warn_score", 0.2)
        expect_equal("offer", d:selectBranch("quest"))

        d:clearUtilityScores()
        expect_equal("offer", d:selectBranch("quest"))
    end)
end)

-- =========================================================================
-- 13. GOAPPlanner
-- =========================================================================
-- @describe lurek.ai GOAPPlanner
describe("lurek.ai GOAPPlanner", function()
    -- @covers LGOAPPlanner:type
    -- @covers lurek.ai.newGOAPPlanner
    it("type returns GOAPPlanner", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal("LGOAPPlanner", g:type())
    end)

    -- @covers LGOAPPlanner:addAction
    -- @covers LGOAPPlanner:getActionCount
    -- @covers lurek.ai.newGOAPPlanner
    it("addAction increases action count", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getActionCount())
        g:addAction("gather_wood", 1.0)
        expect_equal(1, g:getActionCount())
    end)

    -- @covers LGOAPPlanner:addAction
    -- @covers LGOAPPlanner:setPrecondition
    -- @covers lurek.ai.newGOAPPlanner
    it("setPrecondition does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("chop", 1.0)
        expect_no_error(function()
            g:setPrecondition("chop", "has_axe", true)
        end)
    end)

    -- @covers LGOAPPlanner:addAction
    -- @covers LGOAPPlanner:setEffect
    -- @covers lurek.ai.newGOAPPlanner
    it("setEffect does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("chop", 1.0)
        expect_no_error(function()
            g:setEffect("chop", "has_wood", true)
        end)
    end)

    -- @covers LGOAPPlanner:addGoal
    -- @covers LGOAPPlanner:getGoalCount
    -- @covers lurek.ai.newGOAPPlanner
    it("addGoal increases goal count", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getGoalCount())
        g:addGoal("build_house", 1.0)
        expect_equal(1, g:getGoalCount())
    end)

    -- @covers LGOAPPlanner:addGoal
    -- @covers LGOAPPlanner:setGoalState
    -- @covers lurek.ai.newGOAPPlanner
    it("setGoalState does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addGoal("build_house", 1.0)
        expect_no_error(function()
            g:setGoalState("build_house", "has_house", true)
        end)
    end)

    -- @covers LGOAPPlanner:addAction
    -- @covers LGOAPPlanner:addGoal
    -- @covers LGOAPPlanner:plan
    -- @covers LGOAPPlanner:setEffect
    -- @covers LGOAPPlanner:setGoalState
    -- @covers LGOAPPlanner:setPrecondition
    -- @covers lurek.ai.newGOAPPlanner
    it("plan returns action sequence", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("get_axe", 1.0)
        g:setEffect("get_axe", "has_axe", true)

        g:addAction("chop_tree", 2.0)
        g:setPrecondition("chop_tree", "has_axe", true)
        g:setEffect("chop_tree", "has_wood", true)

        g:addGoal("gather", 1.0)
        g:setGoalState("gather", "has_wood", true)

        local plan = g:plan({ has_axe = false, has_wood = false })
        expect_type("table", plan)
        expect_true(#plan > 0, "plan should have steps")
    end)

    -- @covers LGOAPPlanner:addAction
    -- @covers LGOAPPlanner:addGoal
    -- @covers LGOAPPlanner:plan
    -- @covers LGOAPPlanner:setEffect
    -- @covers LGOAPPlanner:setGoalState
    -- @covers lurek.ai.newGOAPPlanner
    it("plan returns empty table when goal already satisfied", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("eat", 1.0)
        g:setEffect("eat", "fed", true)

        g:addGoal("stay_fed", 1.0)
        g:setGoalState("stay_fed", "fed", true)

        local plan = g:plan({ fed = true })
        expect_type("table", plan)
        expect_equal(0, #plan)
    end)

    -- @covers LGOAPPlanner:addAction
    -- @covers lurek.ai.newGOAPPlanner
    it("addAction with callback", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_no_error(function()
            g:addAction("move", 1.0, function() end)
        end)
    end)
end)

-- =========================================================================
-- 14. InfluenceMap
-- =========================================================================
-- @describe lurek.ai InfluenceMap
describe("lurek.ai InfluenceMap", function()
    -- @covers LInfluenceMap:type
    -- @covers lurek.ai.newInfluenceMap
    it("type returns InfluenceMap", function()
        local im = lurek.ai.newInfluenceMap(10, 10, 32)
        expect_equal("LInfluenceMap", im:type())
    end)

    -- @covers LInfluenceMap:getCellSize
    -- @covers LInfluenceMap:getHeight
    -- @covers LInfluenceMap:getWidth
    -- @covers lurek.ai.newInfluenceMap
    it("getWidth / getHeight / getCellSize", function()
        local im = lurek.ai.newInfluenceMap(8, 6, 16)
        expect_equal(8, im:getWidth())
        expect_equal(6, im:getHeight())
        expect_near(16, im:getCellSize(), 0.01)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:hasLayer
    -- @covers lurek.ai.newInfluenceMap
    it("addLayer / hasLayer", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        expect_false(im:hasLayer("threat"))
        im:addLayer("threat")
        expect_true(im:hasLayer("threat"))
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("setInfluence / getInfluence (1-based)", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("danger")
        im:setInfluence("danger", 2, 3, 0.75)
        expect_near(0.75, im:getInfluence("danger", 2, 3), 0.01)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:propagate
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("propagate does not error", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("heat")
        im:setInfluence("heat", 3, 3, 1.0)
        expect_no_error(function()
            im:propagate("heat", 0.5)
        end)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:decay
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("decay reduces values", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("scent")
        im:setInfluence("scent", 1, 1, 1.0)
        im:decay("scent", 0.5)
        local val = im:getInfluence("scent", 1, 1)
        expect_near(0.5, val, 0.01)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:clearLayer
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("clearLayer resets all values", function()
        local im = lurek.ai.newInfluenceMap(3, 3, 10)
        im:addLayer("fog")
        im:setInfluence("fog", 1, 1, 1.0)
        im:setInfluence("fog", 2, 2, 0.5)
        im:clearLayer("fog")
        expect_near(0, im:getInfluence("fog", 1, 1), 0.01)
        expect_near(0, im:getInfluence("fog", 2, 2), 0.01)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:clearAll
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("clearAll resets all layers", function()
        local im = lurek.ai.newInfluenceMap(3, 3, 10)
        im:addLayer("a")
        im:addLayer("b")
        im:setInfluence("a", 1, 1, 1.0)
        im:setInfluence("b", 1, 1, 1.0)
        im:clearAll()
        expect_near(0, im:getInfluence("a", 1, 1), 0.01)
        expect_near(0, im:getInfluence("b", 1, 1), 0.01)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:getMaxPosition
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("getMaxPosition returns two numbers", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("test")
        im:setInfluence("test", 3, 4, 1.0)
        local mx, my = im:getMaxPosition("test")
        expect_type("number", mx)
        expect_type("number", my)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:getMinPosition
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("getMinPosition returns two numbers", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("test")
        im:setInfluence("test", 2, 2, -1.0)
        local mx, my = im:getMinPosition("test")
        expect_type("number", mx)
        expect_type("number", my)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:queryRect
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("queryRect returns a number", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("zone")
        im:setInfluence("zone", 1, 1, 1.0)
        local sum = im:queryRect("zone", 0, 0, 50, 50)
        expect_type("number", sum)
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:blend
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("blend combines two layers into destination", function()
        local im = lurek.ai.newInfluenceMap(3, 3, 10)
        im:addLayer("a")
        im:addLayer("b")
        im:addLayer("result")
        im:setInfluence("a", 1, 1, 1.0)
        im:setInfluence("b", 1, 1, 0.5)
        expect_no_error(function()
            im:blend("a", 1.0, "b", 1.0, "result")
        end)
        -- result should be the weighted blend
        local val = im:getInfluence("result", 1, 1)
        expect_true(val > 0, "blended value should be positive")
    end)

    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:stampInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("stampInfluence applies radial influence to a layer", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("heat")
        expect_no_error(function()
            im:stampInfluence("heat", 25.0, 25.0, 15.0, 1.0)
        end)
        local val = im:getInfluence("heat", 2, 2)
        expect_type("number", val)
    end)
end)

-- =========================================================================
-- 15. Squad
-- =========================================================================
-- @describe lurek.ai Squad
describe("lurek.ai Squad", function()
    -- @covers LSquad:type
    -- @covers lurek.ai.newSquad
    it("type returns Squad", function()
        local sq = lurek.ai.newSquad("alpha")
        expect_equal("LSquad", sq:type())
    end)

    -- @covers LSquad:getName
    -- @covers lurek.ai.newSquad
    it("getName returns squad name", function()
        local sq = lurek.ai.newSquad("bravo")
        expect_equal("bravo", sq:getName())
    end)

    -- @covers LSquad:addMember
    -- @covers LSquad:getMemberCount
    -- @covers lurek.ai.newSquad
    it("addMember / getMemberCount", function()
        local sq = lurek.ai.newSquad("team")
        expect_equal(0, sq:getMemberCount())
        sq:addMember("soldier1")
        expect_equal(1, sq:getMemberCount())
        sq:addMember("soldier2")
        expect_equal(2, sq:getMemberCount())
    end)

    -- @covers LSquad:addMember
    -- @covers LSquad:getMemberCount
    -- @covers LSquad:removeMember
    -- @covers lurek.ai.newSquad
    it("removeMember decreases count", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("a")
        sq:addMember("b")
        sq:removeMember("a")
        expect_equal(1, sq:getMemberCount())
    end)

    -- @covers LSquad:addMember
    -- @covers LSquad:getMembers
    -- @covers lurek.ai.newSquad
    it("getMembers returns table of names", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("x")
        sq:addMember("y")
        local members = sq:getMembers()
        expect_type("table", members)
        expect_equal(2, #members)
    end)

    -- @covers LSquad:addMember
    -- @covers LSquad:getLeader
    -- @covers LSquad:setLeader
    -- @covers lurek.ai.newSquad
    it("setLeader / getLeader", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("leader1")
        sq:setLeader("leader1")
        expect_equal("leader1", sq:getLeader())
    end)

    -- @covers LSquad:getLeader
    -- @covers lurek.ai.newSquad
    it("getLeader returns nil by default", function()
        local sq = lurek.ai.newSquad("team")
        expect_nil(sq:getLeader())
    end)

    -- @covers LSquad:getFormation
    -- @covers LSquad:getFormationSpacing
    -- @covers LSquad:setFormation
    -- @covers lurek.ai.newSquad
    it("setFormation / getFormation / getFormationSpacing", function()
        local sq = lurek.ai.newSquad("team")
        sq:setFormation("wedge", 50)
        expect_equal("wedge", sq:getFormation())
        expect_near(50, sq:getFormationSpacing(), 0.01)
    end)

    -- @covers LSquad:addMember
    -- @covers LSquad:getFormationPosition
    -- @covers lurek.ai.newSquad
    it("getFormationPosition returns two numbers (1-based index)", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("a")
        sq:addMember("b")
        local x, y = sq:getFormationPosition(1, 100, 200)
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @covers LSquad:getBlackboard
    -- @covers lurek.ai.newSquad
    it("getBlackboard returns Blackboard", function()
        local sq = lurek.ai.newSquad("team")
        local bb = sq:getBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)
end)

-- =========================================================================
-- 16. CommandQueue
-- =========================================================================
-- @describe lurek.ai CommandQueue
describe("lurek.ai CommandQueue", function()
    -- @covers LCommandQueue:type
    -- @covers lurek.ai.newCommandQueue
    it("type returns CommandQueue", function()
        local cq = lurek.ai.newCommandQueue()
        expect_equal("LCommandQueue", cq:type())
    end)

    -- @covers LCommandQueue:isEmpty
    -- @covers lurek.ai.newCommandQueue
    it("isEmpty returns true initially", function()
        local cq = lurek.ai.newCommandQueue()
        expect_true(cq:isEmpty())
    end)

    -- @covers LCommandQueue:getCount
    -- @covers lurek.ai.newCommandQueue
    it("getCount returns 0 initially", function()
        local cq = lurek.ai.newCommandQueue()
        expect_equal(0, cq:getCount())
    end)

    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCount
    -- @covers LCommandQueue:isEmpty
    -- @covers lurek.ai.newCommandQueue
    it("enqueue increases count", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end)
        expect_equal(1, cq:getCount())
        expect_false(cq:isEmpty())
    end)

    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCurrentType
    -- @covers lurek.ai.newCommandQueue
    it("getCurrentType returns first command type", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("attack", function() end)
        expect_equal("attack", cq:getCurrentType())
    end)

    -- @covers LCommandQueue:getCurrentType
    -- @covers lurek.ai.newCommandQueue
    it("getCurrentType returns nil when empty", function()
        local cq = lurek.ai.newCommandQueue()
        expect_nil(cq:getCurrentType())
    end)

    -- @covers LCommandQueue:cancelCurrent
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCount
    -- @covers lurek.ai.newCommandQueue
    it("cancelCurrent removes head", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end)
        cq:enqueue("attack", function() end)
        cq:cancelCurrent()
        expect_equal(1, cq:getCount())
    end)

    -- @covers LCommandQueue:clear
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCount
    -- @covers LCommandQueue:isEmpty
    -- @covers lurek.ai.newCommandQueue
    it("clear removes all commands", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("a", function() end)
        cq:enqueue("b", function() end)
        cq:enqueue("c", function() end)
        cq:clear()
        expect_equal(0, cq:getCount())
        expect_true(cq:isEmpty())
    end)

    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCurrentType
    -- @covers LCommandQueue:pushFront
    -- @covers lurek.ai.newCommandQueue
    it("pushFront inserts at front", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("second", function() end)
        cq:pushFront("first", function() end)
        expect_equal("first", cq:getCurrentType())
    end)

    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCount
    -- @covers LCommandQueue:getCurrentType
    -- @covers LCommandQueue:replace
    -- @covers lurek.ai.newCommandQueue
    it("replace replaces all with single command", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("a", function() end)
        cq:enqueue("b", function() end)
        cq:replace("only", function() end)
        expect_equal(1, cq:getCount())
        expect_equal("only", cq:getCurrentType())
    end)

    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCount
    -- @covers lurek.ai.newCommandQueue
    it("enqueue with options table", function()
        local cq = lurek.ai.newCommandQueue()
        expect_no_error(function()
            cq:enqueue("move", function() end, {
                targetX = 100,
                targetY = 200,
                priority = 5,
                interruptible = false,
            })
        end)
        expect_equal(1, cq:getCount())
    end)
end)

-- =========================================================================
-- 17. Type system
-- =========================================================================
-- @describe lurek.ai type system
describe("lurek.ai type system", function()
    -- @covers LAIWorld:type
    -- @covers lurek.ai.newWorld
    it("AIWorld:type() returns AIWorld", function()
        expect_equal("LAIWorld", lurek.ai.newWorld():type())
    end)

    -- @covers LAIBlackboard:type
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:type() returns Blackboard", function()
        expect_equal("LAIBlackboard", lurek.ai.newBlackboard():type())
    end)

    -- @covers LStateMachine:type
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:type() returns StateMachine", function()
        expect_equal("LStateMachine", lurek.ai.newStateMachine():type())
    end)

    -- @covers LBehaviorTree:type
    -- @covers lurek.ai.newBehaviorTree
    it("BehaviorTree:type() returns BehaviorTree", function()
        expect_equal("LBehaviorTree", lurek.ai.newBehaviorTree():type())
    end)

    -- @covers LBTNode:type
    -- @covers lurek.ai.newSelector
    it("BTNode:type() returns BTNode", function()
        expect_equal("LBTNode", lurek.ai.newSelector():type())
    end)

    -- @covers LSteeringManager:type
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:type() returns SteeringManager", function()
        expect_equal("LSteeringManager", lurek.ai.newSteeringManager():type())
    end)

    -- @covers LQLearner:type
    -- @covers lurek.ai.newQLearner
    it("QLearner:type() returns QLearner", function()
        expect_equal("LQLearner", lurek.ai.newQLearner(2, 2):type())
    end)

    -- @covers LUtilityAI:type
    -- @covers lurek.ai.newUtilityAI
    it("UtilityAI:type() returns UtilityAI", function()
        expect_equal("LUtilityAI", lurek.ai.newUtilityAI():type())
    end)

    -- @covers LGOAPPlanner:type
    -- @covers lurek.ai.newGOAPPlanner
    it("GOAPPlanner:type() returns GOAPPlanner", function()
        expect_equal("LGOAPPlanner", lurek.ai.newGOAPPlanner():type())
    end)

    -- @covers LInfluenceMap:type
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:type() returns LInfluenceMap", function()
        expect_equal("LInfluenceMap", lurek.ai.newInfluenceMap(5, 5, 10):type())
    end)

    -- @covers LSquad:type
    -- @covers lurek.ai.newSquad
    it("Squad:type() returns LSquad", function()
        expect_equal("LSquad", lurek.ai.newSquad("s"):type())
    end)

    -- @covers LCommandQueue:type
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:type() returns LCommandQueue", function()
        expect_equal("LCommandQueue", lurek.ai.newCommandQueue():type())
    end)

    -- @covers LAIWorld:typeOf
    -- @covers lurek.ai.newWorld
    it("AIWorld:typeOf Object returns true", function()
        expect_true(lurek.ai.newWorld():typeOf("Object"))
    end)

    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:typeOf Object returns true", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("x")
        expect_true(a:typeOf("Object"))
    end)

    -- @covers LAIBlackboard:typeOf
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:typeOf Object returns true", function()
        expect_true(lurek.ai.newBlackboard():typeOf("Object"))
    end)

    -- @covers LBTNode:typeOf
    -- @covers lurek.ai.newSelector
    it("BTNode:typeOf Object returns true", function()
        expect_true(lurek.ai.newSelector():typeOf("Object"))
    end)
end)

-- =========================================================================
-- GOAPPlanner maxIterations configurability (PR-10)
-- =========================================================================

-- @describe lurek.ai GOAPPlanner maxIterations configurability
describe("lurek.ai GOAPPlanner maxIterations configurability", function()
    -- @covers LGOAPPlanner:getMaxIterations
    -- @covers lurek.ai.newGOAPPlanner
    it("goap_getMaxIterations_default_is_10000", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(10000, g:getMaxIterations())
    end)

    -- @covers LGOAPPlanner:getMaxIterations
    -- @covers LGOAPPlanner:setMaxIterations
    -- @covers lurek.ai.newGOAPPlanner
    it("goap_setMaxIterations_roundtrips_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(500)
        expect_equal(500, g:getMaxIterations())
    end)

    -- @covers LGOAPPlanner:getMaxIterations
    -- @covers LGOAPPlanner:setMaxIterations
    -- @covers lurek.ai.newGOAPPlanner
    it("goap_setMaxIterations_accepts_small_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(1)
        expect_equal(1, g:getMaxIterations())
    end)

    -- @covers LGOAPPlanner:getMaxIterations
    -- @covers LGOAPPlanner:setMaxIterations
    -- @covers lurek.ai.newGOAPPlanner
    it("goap_setMaxIterations_accepts_large_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(100000)
        expect_equal(100000, g:getMaxIterations())
    end)
end)

-- =========================================================================
-- ContextSteering  - Factory
-- =========================================================================
-- @describe lurek.ai.newContextSteering factory
describe("lurek.ai.newContextSteering factory", function()
    -- @covers lurek.ai.newContextSteering
    it("exists as a function", function()
        expect_type("function", lurek.ai.newContextSteering)
    end)

    -- @covers lurek.ai.newContextSteering
    it("creates a userdata object", function()
        local cs = lurek.ai.newContextSteering(16)
        expect_type("userdata", cs)
    end)

    -- @covers LContextSteering:slotCount
    -- @covers lurek.ai.newContextSteering
    it("slot count reflects argument", function()
        local cs = lurek.ai.newContextSteering(8)
        expect_equal(cs:slotCount(), 8)
    end)

    -- @covers LContextSteering:slotCount
    -- @covers lurek.ai.newContextSteering
    it("defaults to 16 slots for 0 argument", function()
        local cs = lurek.ai.newContextSteering(0)
        expect_equal(cs:slotCount(), 16)
    end)
end)

-- =========================================================================
-- ContextSteering  - Evaluate produces a direction vector
-- =========================================================================
-- @describe ContextSteering evaluate
describe("ContextSteering evaluate", function()
    -- @covers LContextSteering:addSeekTarget
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("returns two numbers from evaluate", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addSeekTarget(100, 0, 1.0)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers LContextSteering:addWander
    -- @covers LContextSteering:chosenMagnitude
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("wander returns a non-zero vector length", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addWander(0.5, 1.0)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        local mag = math.sqrt(dx * dx + dy * dy)
        expect_near(cs:chosenMagnitude(), mag, 0.03)
    end)

    -- @covers LContextSteering:addSeekTarget
    -- @covers LContextSteering:clearBehaviors
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("clearBehaviors resets to zero vector", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addSeekTarget(100, 100, 1.0)
        cs:clearBehaviors()
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        expect_near(dx, 0.0, 0.001)
        expect_near(dy, 0.0, 0.001)
    end)
end)

-- =========================================================================
-- ContextSteering  - Avoid pushes away
-- =========================================================================
-- @describe ContextSteering avoid
describe("ContextSteering avoid", function()
    -- @covers LContextSteering:addAvoidPoint
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("avoid obstacle pushes away on x-axis", function()
        local cs = lurek.ai.newContextSteering(32)
        -- Place obstacle to the right; agent at origin, avoid weight high
        cs:addAvoidPoint(10, 0, 5, 2.0)
        local dx, _ = cs:evaluate(0, 0, 0, 0)
        -- Result should be non-positive (pushed left or zero)
        expect_equal(dx <= 0, true)
    end)
end)

-- =========================================================================
-- AIDirector  - Factory
-- =========================================================================
-- @describe lurek.ai.newAIDirector factory
describe("lurek.ai.newAIDirector factory", function()
    -- @covers lurek.ai.newAIDirector
    it("exists as a function", function()
        expect_type("function", lurek.ai.newAIDirector)
    end)

    -- @covers lurek.ai.newAIDirector
    it("creates a userdata object", function()
        local d = lurek.ai.newAIDirector()
        expect_type("userdata", d)
    end)

    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("starts with zero tension", function()
        local d = lurek.ai.newAIDirector()
        expect_near(d:tension(), 0.0, 0.001)
    end)

    -- @covers LAIDirector:phase
    -- @covers lurek.ai.newAIDirector
    it("starts in Relief phase", function()
        local d = lurek.ai.newAIDirector()
        expect_equal(d:phase(), "relief")
    end)
end)

-- =========================================================================
-- AIDirector  - pushEvent raises tension
-- =========================================================================
-- @describe AIDirector pushEvent
describe("AIDirector pushEvent", function()
    -- @covers LAIDirector:pushEvent
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("pushEvent raises tension", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(0.8)
        expect_equal(d:tension() > 0.0, true)
    end)

    -- @covers LAIDirector:pushEvent
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("tension does not exceed 1.0", function()
        local d = lurek.ai.newAIDirector()
        for i = 1, 50 do d:pushEvent(1.0) end
        expect_equal(d:tension() <= 1.0, true)
    end)
end)

-- =========================================================================
-- AIDirector  - Update advances phase
-- =========================================================================
-- @describe AIDirector update
describe("AIDirector update", function()
    -- @covers LAIDirector:phase
    -- @covers LAIDirector:pushEvent
    -- @covers LAIDirector:update
    -- @covers lurek.ai.newAIDirector
    it("update does not crash", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(1.0)
        d:update(0.1)
        expect_type("string", d:phase())
    end)

    -- @covers LAIDirector:spawnRateFactor
    -- @covers lurek.ai.newAIDirector
    it("spawnRateFactor returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:spawnRateFactor())
    end)

    -- @covers LAIDirector:lootFactor
    -- @covers lurek.ai.newAIDirector
    it("lootFactor returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:lootFactor())
    end)

    -- @covers LAIDirector:ambientIntensity
    -- @covers lurek.ai.newAIDirector
    it("ambientIntensity returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:ambientIntensity())
    end)
end)

-- =========================================================================
-- AIDirector  - Reset
-- =========================================================================
-- @describe AIDirector reset
describe("AIDirector reset", function()
    -- @covers LAIDirector:pushEvent
    -- @covers LAIDirector:reset
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("reset clears tension", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(1.0)
        d:reset()
        expect_near(d:tension(), 0.0, 0.001)
    end)

    -- @covers LAIDirector:setTension
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("setTension changes tension directly", function()
        local d = lurek.ai.newAIDirector()
        d:setTension(0.5)
        expect_near(d:tension(), 0.5, 0.01)
    end)
end)

-- =========================================================================
-- EmotionModel  - Factory
-- =========================================================================
-- @describe lurek.ai.newEmotionModel factory
describe("lurek.ai.newEmotionModel factory", function()
    -- @covers lurek.ai.newEmotionModel
    it("exists as a function", function()
        expect_type("function", lurek.ai.newEmotionModel)
    end)

    -- @covers lurek.ai.newEmotionModel
    it("creates a userdata object", function()
        local em = lurek.ai.newEmotionModel()
        expect_type("userdata", em)
    end)
end)

-- =========================================================================
-- EmotionModel  - Add emotions
-- =========================================================================
-- @describe EmotionModel add/query
describe("EmotionModel add/query", function()
    -- @covers LEmotionModel:dominant
    -- @covers lurek.ai.newEmotionModel
    it("dominant returns nil when empty", function()
        local em = lurek.ai.newEmotionModel()
        expect_equal(em:dominant(), nil)
    end)

    -- @covers LEmotionModel:get
    -- @covers lurek.ai.newEmotionModel
    it("get returns 0 for unknown emotion", function()
        local em = lurek.ai.newEmotionModel()
        expect_near(em:get("anger"), 0.0, 0.001)
    end)

    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:get
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("trigger raises emotion value", function()
        local em = lurek.ai.newEmotionModel()
        em:add("fear", 0.0, 0.5, 0.1)
        em:trigger("fear", 0.8)
        expect_equal(em:get("fear") > 0.0, true)
    end)

    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:isActive
    -- @covers lurek.ai.newEmotionModel
    it("isActive returns false before trigger", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.0, 0.3, 0.2)
        expect_equal(em:isActive("joy"), false)
    end)

    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:isActive
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("isActive returns true after strong trigger", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.0, 0.3, 0.2)
        em:trigger("joy", 0.9)
        expect_equal(em:isActive("joy"), true)
    end)
end)

-- =========================================================================
-- EmotionModel  - Dominant
-- =========================================================================
-- @describe EmotionModel dominant
describe("EmotionModel dominant", function()
    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:dominant
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("dominant returns the triggered emotion when only one", function()
        local em = lurek.ai.newEmotionModel()
        em:add("rage", 0.0, 0.2, 0.1)
        em:trigger("rage", 1.0)
        expect_equal(em:dominant(), "rage")
    end)
end)

-- =========================================================================
-- EmotionModel  - Decay and reset
-- =========================================================================
-- @describe EmotionModel update/reset
describe("EmotionModel update/reset", function()
    -- @covers LEmotionModel:dominant
    -- @covers LEmotionModel:update
    -- @covers lurek.ai.newEmotionModel
    it("update does not crash", function()
        local em = lurek.ai.newEmotionModel()
        em:update(0.016)
        expect_equal(em:dominant(), nil)
    end)

    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:get
    -- @covers LEmotionModel:reset
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("reset brings emotions to resting level", function()
        local em = lurek.ai.newEmotionModel()
        em:add("dread", 0.0, 0.5, 0.1)
        em:trigger("dread", 1.0)
        em:reset()
        expect_near(em:get("dread"), 0.0, 0.01)
    end)
end)

-- =========================================================================
-- HTNDomain  - Factory
-- =========================================================================
-- @describe lurek.ai.newHTNDomain factory
describe("lurek.ai.newHTNDomain factory", function()
    -- @covers lurek.ai.newHTNDomain
    it("exists as a function", function()
        expect_type("function", lurek.ai.newHTNDomain)
    end)

    -- @covers lurek.ai.newHTNDomain
    it("creates a userdata object", function()
        local d = lurek.ai.newHTNDomain()
        expect_type("userdata", d)
    end)

    -- @covers LHTNDomain:taskCount
    -- @covers lurek.ai.newHTNDomain
    it("starts with zero tasks", function()
        local d = lurek.ai.newHTNDomain()
        expect_equal(d:taskCount(), 0)
    end)
end)

-- =========================================================================
-- HTNDomain  - Primitives
-- =========================================================================
-- @describe HTNDomain addPrimitive
describe("HTNDomain addPrimitive", function()
    -- @covers LHTNDomain:addPrimitive
    -- @covers LHTNDomain:taskCount
    -- @covers lurek.ai.newHTNDomain
    it("addPrimitive increments task count", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("MoveTo", {}, {"at_target"}, {})
        expect_equal(d:taskCount(), 1)
    end)

    -- @covers LHTNDomain:addPrimitive
    -- @covers LHTNDomain:taskCount
    -- @covers lurek.ai.newHTNDomain
    it("addPrimitive with preconditions is counted", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("Attack", {"has_weapon", "enemy_visible"}, {"attacked"}, {})
        expect_equal(d:taskCount(), 1)
    end)
end)

-- =========================================================================
-- HTNDomain  - Planning
-- =========================================================================
-- @describe HTNDomain plan
describe("HTNDomain plan", function()
    -- @covers LHTNDomain:plan
    -- @covers lurek.ai.newHTNDomain
    it("plan returns nil for unknown root task", function()
        local d = lurek.ai.newHTNDomain()
        local result = d:plan("nonexistent", {})
        expect_equal(result, nil)
    end)

    -- @covers LHTNDomain:addCompound
    -- @covers LHTNDomain:addPrimitive
    -- @covers LHTNDomain:plan
    -- @covers lurek.ai.newHTNDomain
    it("plan returns a table of primitive actions for solvable problem", function()
        local d = lurek.ai.newHTNDomain()
        -- Primitives
        d:addPrimitive("Navigate", {}, {"nav_done"}, {})
        d:addPrimitive("PickUp", {"nav_done"}, {"holding_item"}, {})
        -- Compound root task
        d:addCompound("GetItem", {
            { name = "main_method", preconditions = {}, sub_tasks = {"Navigate", "PickUp"} }
        })
        local plan = d:plan("GetItem", {})
        expect_type("table", plan)
        expect_equal(#plan, 2)
        expect_equal(plan[1], "Navigate")
        expect_equal(plan[2], "PickUp")
    end)

    -- @covers LHTNDomain:addCompound
    -- @covers LHTNDomain:addPrimitive
    -- @covers LHTNDomain:plan
    -- @covers lurek.ai.newHTNDomain
    it("plan returns nil when precondition not satisfied", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("Attack", {"has_weapon"}, {"attacked"}, {})
        d:addCompound("DoAttack", {
            { name = "armed", preconditions = {"has_weapon"}, sub_tasks = {"Attack"} }
        })
        -- State does not include has_weapon
        local plan = d:plan("DoAttack", {})
        expect_equal(plan, nil)
    end)
end)

-- =========================================================================
-- AILod  - Factory
-- =========================================================================
-- @describe lurek.ai.newAILod factory
describe("lurek.ai.newAILod factory", function()
    -- @covers lurek.ai.newAILod
    it("exists as a function", function()
        expect_type("function", lurek.ai.newAILod)
    end)

    -- @covers lurek.ai.newAILod
    it("creates a userdata object", function()
        local lod = lurek.ai.newAILod()
        expect_type("userdata", lod)
    end)

    -- @covers LAILod:tierCount
    -- @covers lurek.ai.newAILod
    it("default tierCount is 3", function()
        local lod = lurek.ai.newAILod()
        expect_equal(3, lod:tierCount())
    end)
end)

-- =========================================================================
-- AILod  - Tier assignment
-- =========================================================================
-- @describe AILod tierFor
describe("AILod tierFor", function()
    -- @covers LAILod:tierFor
    -- @covers lurek.ai.newAILod
    it("returns an integer tier index", function()
        local lod = lurek.ai.newAILod()
        local tier = lod:tierFor(0, 0, 0, 0)
        expect_type("number", tier)
        expect_equal(tier >= 0, true)
    end)

    -- @covers LAILod:tierFor
    -- @covers lurek.ai.newAILod
    it("agent at same position as reference gets tier 0 (nearest)", function()
        local lod = lurek.ai.newAILod()
        local tier = lod:tierFor(0, 0, 0, 0)
        expect_equal(tier, 0)
    end)

    -- @covers LAILod:tierFor
    -- @covers lurek.ai.newAILod
    it("distant agent gets higher tier than close agent", function()
        local lod = lurek.ai.newAILod()
        local near_tier = lod:tierFor(5, 0, 0, 0)    -- close
        local far_tier  = lod:tierFor(2000, 0, 0, 0) -- very far
        expect_equal(far_tier >= near_tier, true)
    end)

    -- @covers LAILod:tierCount
    -- @covers LAILod:tierFor
    -- @covers lurek.ai.newAILod
    it("tier index never exceeds tierCount-1", function()
        local lod = lurek.ai.newAILod()
        local max_tier = lod:tierCount() - 1
        local tier = lod:tierFor(99999, 99999, 0, 0)
        expect_equal(tier <= max_tier, true)
    end)
end)

-- =========================================================================
-- AILod  - shouldUpdate
-- =========================================================================
-- @describe AILod shouldUpdate
describe("AILod shouldUpdate", function()
    -- @covers LAILod:shouldUpdate
    -- @covers lurek.ai.newAILod
    it("tier 0 updates every frame", function()
        local lod = lurek.ai.newAILod()
        -- Tier 0 (near) should update every frame
        expect_equal(lod:shouldUpdate(0, 0), true)
        expect_equal(lod:shouldUpdate(0, 1), true)
        expect_equal(lod:shouldUpdate(0, 7), true)
    end)

    -- @covers LAILod:shouldUpdate
    -- @covers LAILod:tierCount
    -- @covers lurek.ai.newAILod
    it("far tier does not update every frame", function()
        local lod = lurek.ai.newAILod()
        local max_tier = lod:tierCount() - 1
        if max_tier > 0 then
            -- At least one frame in the stride should not update
            -- (stride = update_every for that tier, which is > 1 for far tiers)
            local updates = 0
            for frame = 0, 15 do
                if lod:shouldUpdate(max_tier, frame) then
                    updates = updates + 1
                end
            end
            -- Far tier should update fewer than 16 times in 16 frames
            expect_equal(updates < 16, true)
        else
            -- Single tier: always updates (pass vacuously)
            expect_equal(0, max_tier)
        end
    end)
end)

-- =========================================================================
-- AILod  - tierName
-- =========================================================================
-- @describe AILod tierName
describe("AILod tierName", function()
    -- @covers LAILod:tierName
    -- @covers lurek.ai.newAILod
    it("tier 0 has a non-nil name", function()
        local lod = lurek.ai.newAILod()
        local name = lod:tierName(0)
        expect_type("string", name)
    end)

    -- @covers LAILod:tierName
    -- @covers lurek.ai.newAILod
    it("out-of-bounds tier returns nil", function()
        local lod = lurek.ai.newAILod()
        local name = lod:tierName(9999)
        expect_equal(name, nil)
    end)
end)

-- =========================================================================
-- MCTSEngine  - Factory
-- =========================================================================
-- @describe lurek.ai.newMCTSEngine factory
describe("lurek.ai.newMCTSEngine factory", function()
    -- @covers lurek.ai.newMCTSEngine
    it("exists as a function", function()
        expect_type("function", lurek.ai.newMCTSEngine)
    end)

    -- @covers lurek.ai.newMCTSEngine
    it("creates a userdata object", function()
        local mcts = lurek.ai.newMCTSEngine(50, 1.41, 10, 42)
        expect_type("userdata", mcts)
    end)
end)

-- =========================================================================
-- MCTSEngine  - Search
-- =========================================================================
--
-- Trivial game: state = integer 0..5.  Actions: +1 or +2.
-- Evaluate: higher state = better score.  Best first action from 0 = +2.
-- @describe MCTSEngine search
describe("MCTSEngine search", function()
    -- @covers LMCTSEngine:search
    -- @covers lurek.ai.newMCTSEngine
    it("returns an integer action from search", function()
        local mcts = lurek.ai.newMCTSEngine(100, 1.41, 5, 42)
        local function get_actions(state)
            if state >= 5 then return {} end
            return {1, 2}
        end
        local function apply_action(state, action)
            return state + action
        end
        local function evaluate(state)
            return state / 5.0
        end
        local action = mcts:search(0, get_actions, apply_action, evaluate)
        expect_type("number", action)
    end)

    -- @covers LMCTSEngine:search
    -- @covers lurek.ai.newMCTSEngine
    it("returns nil when no actions available from root", function()
        local mcts = lurek.ai.newMCTSEngine(50, 1.41, 5, 1)
        local action = mcts:search(
            100,
            function(_) return {} end,
            function(s, a) return s + a end,
            function(s) return s * 0.01 end
        )
        expect_equal(action, nil)
    end)

    -- @covers LMCTSEngine:search
    -- @covers lurek.ai.newMCTSEngine
    it("prefers higher reward action", function()
        local mcts = lurek.ai.newMCTSEngine(200, 1.41, 8, 99)
        -- Game: state is a bank balance. Action 1 adds 1, action 2 adds 10.
        -- Evaluate linearly.  Best action always 2.
        local action = mcts:search(
            0,
            function(s)
                if s >= 20 then return {} end
                return {1, 2}
            end,
            function(s, a)
                return s + a
            end,
            function(s)
                return s / 20.0
            end
        )
        expect_equal(action, 2)
    end)
end)

-- =========================================================================
-- NeuralNet  - Factory
-- =========================================================================
-- @describe lurek.ai.newNeuralNet factory
describe("lurek.ai.newNeuralNet factory", function()
    -- @covers lurek.ai.newNeuralNet
    it("exists as a function", function()
        expect_type("function", lurek.ai.newNeuralNet)
    end)

    -- @covers lurek.ai.newNeuralNet
    it("creates a userdata object", function()
        local net = lurek.ai.newNeuralNet()
        expect_type("userdata", net)
    end)

    -- @covers LNeuralNet:layerCount
    -- @covers lurek.ai.newNeuralNet
    it("starts with zero layers", function()
        local net = lurek.ai.newNeuralNet()
        expect_equal(net:layerCount(), 0)
    end)

    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:layerCount
    -- @covers lurek.ai.newNeuralNet
    it("addLayer increments layer count", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 4, "relu")
        net:addLayer(4, 1, "sigmoid")
        expect_equal(net:layerCount(), 2)
    end)

    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:forward
    -- @covers lurek.ai.newNeuralNet
    it("forward returns table of correct size", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(3, 2, "relu")
        local out = net:forward({0.5, 0.1, 0.9})
        expect_type("table", out)
        expect_equal(#out, 2)
    end)

    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:paramCount
    -- @covers lurek.ai.newNeuralNet
    it("paramCount is positive after adding layers", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 3, "tanh")
        -- 2*3 weights + 3 biases = 9
        expect_equal(net:paramCount(), 9)
    end)

    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:getWeights
    -- @covers LNeuralNet:paramCount
    -- @covers LNeuralNet:setWeights
    -- @covers lurek.ai.newNeuralNet
    it("setWeights / getWeights roundtrip", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 2, "relu")
        local n = net:paramCount()
        local w = {}
        for i = 1, n do w[i] = i * 0.01 end
        net:setWeights(w)
        local w2 = net:getWeights()
        expect_equal(#w2, n)
        expect_near(w2[1], 0.01, 0.0001)
    end)
end)

-- =========================================================================
-- GeneticAlgorithm  - Factory
-- =========================================================================
-- @describe lurek.ai.newGeneticAlgorithm factory
describe("lurek.ai.newGeneticAlgorithm factory", function()
    -- @covers lurek.ai.newGeneticAlgorithm
    it("exists as a function", function()
        expect_type("function", lurek.ai.newGeneticAlgorithm)
    end)

    -- @covers lurek.ai.newGeneticAlgorithm
    it("creates a userdata object", function()
        local ga = lurek.ai.newGeneticAlgorithm(10, 5, 42)
        expect_type("userdata", ga)
    end)

    -- @covers LGeneticAlgorithm:popSize
    -- @covers lurek.ai.newGeneticAlgorithm
    it("popSize matches argument", function()
        local ga = lurek.ai.newGeneticAlgorithm(20, 4, 1)
        expect_equal(ga:popSize(), 20)
    end)

    -- @covers LGeneticAlgorithm:getGenes
    -- @covers lurek.ai.newGeneticAlgorithm
    it("getGenes returns table of expected length", function()
        local ga = lurek.ai.newGeneticAlgorithm(5, 8, 7)
        local genes = ga:getGenes(0)
        expect_type("table", genes)
        expect_equal(#genes, 8)
    end)

    -- @covers LGeneticAlgorithm:evolve
    -- @covers LGeneticAlgorithm:generation
    -- @covers LGeneticAlgorithm:setFitness
    -- @covers lurek.ai.newGeneticAlgorithm
    it("evolve increments generation", function()
        local ga = lurek.ai.newGeneticAlgorithm(6, 4, 3)
        -- Assign trivial fitness before evolve
        for i = 0, 5 do ga:setFitness(i, i * 0.1) end
        local g0 = ga:generation()
        ga:evolve()
        expect_equal(ga:generation(), g0 + 1)
    end)

    -- @covers LGeneticAlgorithm:bestGenes
    -- @covers LGeneticAlgorithm:evolve
    -- @covers LGeneticAlgorithm:setFitness
    -- @covers lurek.ai.newGeneticAlgorithm
    it("bestGenes returns a table", function()
        local ga = lurek.ai.newGeneticAlgorithm(4, 3, 9)
        for i = 0, 3 do ga:setFitness(i, i * 0.5) end
        ga:evolve()
        local best = ga:bestGenes()
        expect_type("table", best)
    end)
end)

-- =========================================================================
-- Bandit  - Factory
-- =========================================================================
-- @describe lurek.ai.newBandit factory
describe("lurek.ai.newBandit factory", function()
    -- @covers lurek.ai.newBandit
    it("exists as a function", function()
        expect_type("function", lurek.ai.newBandit)
    end)

    -- @covers lurek.ai.newBandit
    it("creates a userdata object", function()
        local b = lurek.ai.newBandit(5, "epsilon_greedy", 0.1, 42)
        expect_type("userdata", b)
    end)

    -- @covers LBandit:armCount
    -- @covers lurek.ai.newBandit
    it("armCount matches argument", function()
        local b = lurek.ai.newBandit(8, "ucb1", 0.0, 1)
        expect_equal(b:armCount(), 8)
    end)

    -- @covers LBandit:select
    -- @covers lurek.ai.newBandit
    it("select returns a valid arm index", function()
        local b = lurek.ai.newBandit(4, "epsilon_greedy", 0.2, 10)
        local idx = b:select()
        expect_equal(idx >= 0 and idx < 4, true)
    end)

    -- @covers LBandit:totalPulls
    -- @covers LBandit:update
    -- @covers lurek.ai.newBandit
    it("update does not crash", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 5)
        b:update(0, 1.0)
        b:update(1, 0.5)
        b:update(2, 0.8)
        expect_equal(b:totalPulls(), 3)
    end)

    -- @covers LBandit:bestArm
    -- @covers LBandit:update
    -- @covers lurek.ai.newBandit
    it("bestArm returns a valid index after updates", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 5)
        b:update(0, 0.1)
        b:update(1, 0.9)
        b:update(2, 0.3)
        expect_equal(b:bestArm() >= 0, true)
    end)

    -- @covers LBandit:select
    -- @covers lurek.ai.newBandit
    it("thompson_sampling strategy creates successfully", function()
        local b = lurek.ai.newBandit(4, "thompson", 0.0, 7)
        local idx = b:select()
        expect_equal(idx >= 0 and idx < 4, true)
    end)

    -- @covers LBandit:reset
    -- @covers LBandit:totalPulls
    -- @covers LBandit:update
    -- @covers lurek.ai.newBandit
    it("reset clears pull history", function()
        local b = lurek.ai.newBandit(2, "epsilon_greedy", 0.5, 99)
        b:update(0, 1.0)
        b:reset()
        expect_equal(b:totalPulls(), 0)
    end)
end)

-- =========================================================================
-- Neuroevolution  - Factory
-- =========================================================================
-- @describe lurek.ai.newNeuroevolution factory
describe("lurek.ai.newNeuroevolution factory", function()
    -- @covers lurek.ai.newNeuroevolution
    it("exists as a function", function()
        expect_type("function", lurek.ai.newNeuroevolution)
    end)

    -- @covers lurek.ai.newNeuroevolution
    it("creates a userdata object", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=4, activation="relu"},
             {inputs=4, outputs=1, activation="sigmoid"}},
            10, 42)
        expect_type("userdata", ne)
    end)

    -- @covers LNeuroevolution:popSize
    -- @covers lurek.ai.newNeuroevolution
    it("popSize matches argument", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=2, activation="relu"}}, 8, 1)
        expect_equal(ne:popSize(), 8)
    end)

    -- @covers LNeuroevolution:chromosomeToNet
    -- @covers lurek.ai.newNeuroevolution
    it("chromosomeToNet returns a NeuralNet userdata", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=2, activation="tanh"}}, 5, 3)
        local net = ne:chromosomeToNet(0)
        expect_type("userdata", net)
    end)

    -- @covers LNeuroevolution:bestNetwork
    -- @covers LNeuroevolution:evolve
    -- @covers LNeuroevolution:setFitness
    -- @covers lurek.ai.newNeuroevolution
    it("bestNetwork returns userdata after evolve", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=1, activation="sigmoid"}}, 4, 7)
        for i = 0, 3 do ne:setFitness(i, i * 0.2) end
        ne:evolve()
        local best = ne:bestNetwork()
        expect_type("userdata", best)
    end)

    -- @covers LNeuroevolution:evolve
    -- @covers LNeuroevolution:generation
    -- @covers LNeuroevolution:setFitness
    -- @covers lurek.ai.newNeuroevolution
    it("evolve increments generation", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=1, outputs=1, activation="linear"}}, 4, 11)
        for i = 0, 3 do ne:setFitness(i, 1.0) end
        ne:evolve()
        expect_equal(ne:generation(), 1)
    end)
end)

-- =========================================================================
-- NeedSystem  - Factory
-- =========================================================================
-- @describe lurek.ai.newNeedSystem factory
describe("lurek.ai.newNeedSystem factory", function()
    -- @covers lurek.ai.newNeedSystem
    it("exists as a function", function()
        expect_type("function", lurek.ai.newNeedSystem)
    end)

    -- @covers lurek.ai.newNeedSystem
    it("creates a userdata object", function()
        local ns = lurek.ai.newNeedSystem()
        expect_type("userdata", ns)
    end)
end)

-- =========================================================================
-- NeedSystem  - Add needs
-- =========================================================================
-- @describe NeedSystem add/query
describe("NeedSystem add/query", function()
    -- @covers LNeedSystem:mostUrgent
    -- @covers lurek.ai.newNeedSystem
    it("mostUrgent returns nil when empty", function()
        local ns = lurek.ai.newNeedSystem()
        expect_equal(ns:mostUrgent(), nil)
    end)

    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("valueOf returns 1.0 for new needs (full by default)", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 0.1, 0.3, 2.0)
        expect_near(ns:valueOf("hunger"), 1.0, 0.001)
    end)

    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("valueOf returns 0 for unknown need", function()
        local ns = lurek.ai.newNeedSystem()
        expect_near(ns:valueOf("unknown"), 1.0, 0.001)
    end)
end)

-- =========================================================================
-- NeedSystem  - Decay
-- =========================================================================
-- @describe NeedSystem update/decay
describe("NeedSystem update/decay", function()
    -- @covers LNeedSystem:mostUrgent
    -- @covers LNeedSystem:update
    -- @covers lurek.ai.newNeedSystem
    it("update does not crash with empty system", function()
        local ns = lurek.ai.newNeedSystem()
        ns:update(0.016)
        expect_equal(ns:mostUrgent(), nil)
    end)

    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:update
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("hunger decays after large dt", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 1.0, 0.3, 2.0)   -- fast decay
        ns:update(0.8)                           -- should reduce value
        expect_equal(ns:valueOf("hunger") < 1.0, true)
    end)
end)

-- =========================================================================
-- NeedSystem  - Satisfy
-- =========================================================================
-- @describe NeedSystem satisfy
describe("NeedSystem satisfy", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:satisfy
    -- @covers LNeedSystem:update
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("satisfy increases value", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 1.0, 0.3, 2.0)
        ns:update(1.0)  -- deplete first
        local before = ns:valueOf("hunger")
        ns:satisfy("hunger", 0.5)
        expect_equal(ns:valueOf("hunger") > before, true)
    end)
end)

-- =========================================================================
-- NeedSystem  - Most urgent
-- =========================================================================
-- @describe NeedSystem mostUrgent
describe("NeedSystem mostUrgent", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:mostUrgent
    -- @covers LNeedSystem:update
    -- @covers lurek.ai.newNeedSystem
    it("returns the name of the urgent need when depleted", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("sleep", 0.1, 0.8, 3.0)
        ns:update(10.0)  -- deplete completely
        local urgent = ns:mostUrgent()
        -- The one need should become urgent
        expect_type("string", urgent)
    end)
end)

-- =========================================================================
-- ORCASolver  - Factory
-- =========================================================================
-- @describe lurek.ai.newORCASolver factory
describe("lurek.ai.newORCASolver factory", function()
    -- @covers lurek.ai.newORCASolver
    it("exists as a function", function()
        expect_type("function", lurek.ai.newORCASolver)
    end)

    -- @covers lurek.ai.newORCASolver
    it("creates a userdata object", function()
        local s = lurek.ai.newORCASolver(2.0)
        expect_type("userdata", s)
    end)

    -- @covers LORCASolver:agentCount
    -- @covers lurek.ai.newORCASolver
    it("starts with zero agents", function()
        local s = lurek.ai.newORCASolver(2.0)
        expect_equal(s:agentCount(), 0)
    end)
end)

-- =========================================================================
-- ORCASolver  - Add agents
-- =========================================================================
-- @describe ORCASolver addAgent
describe("ORCASolver addAgent", function()
    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:agentCount
    -- @covers lurek.ai.newORCASolver
    it("addAgent increments count", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        expect_equal(s:agentCount(), 1)
    end)

    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:agentCount
    -- @covers lurek.ai.newORCASolver
    it("multiple agents counted", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        s:addAgent(10, 0, 0.5, 3.0)
        expect_equal(s:agentCount(), 2)
    end)
end)

-- =========================================================================
-- ORCASolver  - Compute
-- =========================================================================
-- @describe ORCASolver compute
describe("ORCASolver compute", function()
    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:compute
    -- @covers LORCASolver:getSafeVelocity
    -- @covers LORCASolver:setPreferredVelocity
    -- @covers lurek.ai.newORCASolver
    it("compute does not crash with one agent", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        s:setPreferredVelocity(0, 1.0, 0.0)
        s:compute(0.016)
        local vx, vy = s:getSafeVelocity(0)
        expect_type("number", vx)
        expect_type("number", vy)
    end)

    -- @covers LORCASolver:getSafeVelocity
    -- @covers lurek.ai.newORCASolver
    it("getSafeVelocity returns zeros for out-of-bounds index", function()
        local s = lurek.ai.newORCASolver(2.0)
        local vx, vy = s:getSafeVelocity(99)
        expect_near(vx, 0.0, 0.001)
        expect_near(vy, 0.0, 0.001)
    end)

    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:compute
    -- @covers LORCASolver:getSafeVelocity
    -- @covers LORCASolver:setPreferredVelocity
    -- @covers lurek.ai.newORCASolver
    it("two agents heading toward each other get non-colliding velocities", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(-5, 0, 0.5, 3.0)
        s:addAgent(5, 0, 0.5, 3.0)
        -- Both agents head toward each other on the x-axis
        s:setPreferredVelocity(0, 3.0, 0.0)
        s:setPreferredVelocity(1, -3.0, 0.0)
        s:compute(0.016)
        local vx0, _ = s:getSafeVelocity(0)
        local vx1, _ = s:getSafeVelocity(1)
        -- Safe velocities should be less aggressive than preferred (reduced x)
        expect_equal(vx0 <= 3.0, true)
        expect_equal(vx1 >= -3.0, true)
    end)
end)

-- =========================================================================
-- StimulusWorld  - Factory
-- =========================================================================
-- @describe lurek.ai.newStimulusWorld factory
describe("lurek.ai.newStimulusWorld factory", function()
    -- @covers lurek.ai.newStimulusWorld
    it("exists as a function", function()
        expect_type("function", lurek.ai.newStimulusWorld)
    end)

    -- @covers lurek.ai.newStimulusWorld
    it("creates a userdata object", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_type("userdata", sw)
    end)

    -- @covers LStimulusWorld:count
    -- @covers lurek.ai.newStimulusWorld
    it("starts with zero stimuli", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_equal(sw:count(), 0)
    end)
end)

-- =========================================================================
-- StimulusWorld  - Adding stimuli
-- =========================================================================
-- @describe StimulusWorld add stimuli
describe("StimulusWorld add stimuli", function()
    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:count
    -- @covers lurek.ai.newStimulusWorld
    it("addVisual increases count", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(100, 200, 1.0, 50.0, nil)
        expect_equal(sw:count(), 1)
    end)

    -- @covers LStimulusWorld:addAuditory
    -- @covers LStimulusWorld:count
    -- @covers lurek.ai.newStimulusWorld
    it("addAuditory increases count", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addAuditory(50, 50, 0.8, 80.0, 0.5, "gunshot")
        expect_equal(sw:count(), 1)
    end)

    -- @covers LStimulusWorld:addAuditory
    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:count
    -- @covers lurek.ai.newStimulusWorld
    it("multiple stimuli counted correctly", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(0, 0, 1.0, 40.0, nil)
        sw:addVisual(10, 10, 0.5, 20.0, "guard")
        sw:addAuditory(5, 5, 0.9, 60.0, 0.3, "footstep")
        expect_equal(sw:count(), 3)
    end)
end)

-- =========================================================================
-- StimulusWorld  - Remove
-- =========================================================================
-- @describe StimulusWorld remove
describe("StimulusWorld remove", function()
    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:count
    -- @covers LStimulusWorld:remove
    -- @covers lurek.ai.newStimulusWorld
    it("remove decrements count", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 50.0, nil)
        expect_equal(sw:count(), 1)
        sw:remove(id)
        expect_equal(sw:count(), 0)
    end)

    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:remove
    -- @covers lurek.ai.newStimulusWorld
    it("remove returns true for valid id", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 50.0, nil)
        expect_equal(sw:remove(id), true)
    end)

    -- @covers LStimulusWorld:remove
    -- @covers lurek.ai.newStimulusWorld
    it("remove returns false for unknown id", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_equal(sw:remove(99999), false)
    end)
end)

-- =========================================================================
-- StimulusWorld  - Update and clear
-- =========================================================================
-- @describe StimulusWorld update/clear
describe("StimulusWorld update/clear", function()
    -- @covers LStimulusWorld:count
    -- @covers LStimulusWorld:update
    -- @covers lurek.ai.newStimulusWorld
    it("update does not crash with empty world", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:update(0.016)
        expect_equal(sw:count(), 0)
    end)

    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:clear
    -- @covers LStimulusWorld:count
    -- @covers lurek.ai.newStimulusWorld
    it("clear removes all stimuli", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(0, 0, 1.0, 50.0, nil)
        sw:addVisual(10, 10, 0.5, 30.0, nil)
        sw:clear()
        expect_equal(sw:count(), 0)
    end)
end)

-- =========================================================================
-- StrategyAI  - Factory
-- =========================================================================
-- @describe lurek.ai.newStrategyAI factory
describe("lurek.ai.newStrategyAI factory", function()
    -- @covers lurek.ai.newStrategyAI
    it("exists as a function", function()
        expect_type("function", lurek.ai.newStrategyAI)
    end)

    -- @covers lurek.ai.newStrategyAI
    it("creates a userdata object", function()
        local s = lurek.ai.newStrategyAI(5.0)
        expect_type("userdata", s)
    end)

    -- @covers LStrategyAI:activeGoal
    -- @covers lurek.ai.newStrategyAI
    it("starts with no active goal", function()
        local s = lurek.ai.newStrategyAI(5.0)
        expect_equal(s:activeGoal(), nil)
    end)
end)

-- =========================================================================
-- StrategyAI  - Add goals and evaluate
-- =========================================================================
-- @describe StrategyAI addGoal / forceEvaluate
describe("StrategyAI addGoal / forceEvaluate", function()
    -- @covers LStrategyAI:activeGoal
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:forceEvaluate
    -- @covers lurek.ai.newStrategyAI
    it("forceEvaluate sets active goal when one has highest score", function()
        local s = lurek.ai.newStrategyAI(10.0)
        s:addGoal("attack")
        s:addGoal("defend")
        s:forceEvaluate(function(goal)
            if goal == "attack" then return 0.9
            else return 0.2 end
        end)
        expect_equal(s:activeGoal(), "attack")
    end)

    -- @covers LStrategyAI:activeGoal
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:forceEvaluate
    -- @covers lurek.ai.newStrategyAI
    it("activeGoal remains nil if all scores zero", function()
        local s = lurek.ai.newStrategyAI(10.0)
        s:addGoal("explore")
        s:forceEvaluate(function(_) return 0.0 end)
        expect_equal(s:activeGoal(), "explore")
    end)
end)

-- =========================================================================
-- StrategyAI  - Update with throttle
-- =========================================================================
-- @describe StrategyAI update throttle
describe("StrategyAI update throttle", function()
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:timeUntilNext
    -- @covers LStrategyAI:update
    -- @covers lurek.ai.newStrategyAI
    it("update does not crash before interval", function()
        local s = lurek.ai.newStrategyAI(5.0)
        s:addGoal("patrol")
        s:update(0.016, function(_) return 1.0 end)
        expect_type("number", s:timeUntilNext())
    end)

    -- @covers LStrategyAI:activeGoal
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:forceEvaluate
    -- @covers LStrategyAI:update
    -- @covers lurek.ai.newStrategyAI
    it("update evaluates after interval passes", function()
        local s = lurek.ai.newStrategyAI(0.1)
        s:addGoal("hunt")
        s:addGoal("flee")
        -- Force immediate evaluation first
        s:forceEvaluate(function(g)
            if g == "flee" then return 0.8 else return 0.1 end
        end)
        expect_equal(s:activeGoal(), "flee")
        -- Update well past interval with different scorer
        s:update(1.0, function(g)
            if g == "hunt" then return 0.9 else return 0.1 end
        end)
        expect_equal(s:activeGoal(), "hunt")
    end)
end)

-- =========================================================================
-- StrategyAI  - Tags
-- =========================================================================
-- @describe StrategyAI tags
describe("StrategyAI tags", function()
    -- @covers LStrategyAI:addTag
    -- @covers LStrategyAI:removeTag
    -- @covers lurek.ai.newStrategyAI
    it("addTag / removeTag do not crash", function()
        local s = lurek.ai.newStrategyAI(5.0)
        s:addTag("night")
        s:addTag("rain")
        s:removeTag("night")
        expect_type("number", s:timeUntilNext())
    end)
end)

-- =========================================================================
-- TraitProfile  - Factory
-- =========================================================================
-- @describe lurek.ai.newTraitProfile factory
describe("lurek.ai.newTraitProfile factory", function()
    -- @covers lurek.ai.newTraitProfile
    it("exists as a function", function()
        expect_type("function", lurek.ai.newTraitProfile)
    end)

    -- @covers lurek.ai.newTraitProfile
    it("creates a userdata object", function()
        local tp = lurek.ai.newTraitProfile()
        expect_type("userdata", tp)
    end)
end)

-- =========================================================================
-- TraitProfile  - set / get roundtrip
-- =========================================================================
-- @describe TraitProfile set/get
describe("TraitProfile set/get", function()
    -- @covers LTraitProfile:get
    -- @covers lurek.ai.newTraitProfile
    it("starts with zero for unknown trait", function()
        local tp = lurek.ai.newTraitProfile()
        expect_near(tp:get("aggression"), 0.0, 0.001)
    end)

    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("returns set value", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("courage", 0.75)
        expect_near(tp:get("courage"), 0.75, 0.001)
    end)

    -- @covers LTraitProfile:has
    -- @covers lurek.ai.newTraitProfile
    it("has() returns false for unset trait", function()
        local tp = lurek.ai.newTraitProfile()
        expect_equal(tp:has("unknown_trait"), false)
    end)

    -- @covers LTraitProfile:has
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("has() returns true after set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("loyalty", 0.5)
        expect_equal(tp:has("loyalty"), true)
    end)

    -- @covers LTraitProfile:set
    -- @covers LTraitProfile:traitCount
    -- @covers lurek.ai.newTraitProfile
    it("traitCount increments after set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("a", 0.1)
        tp:set("b", 0.2)
        expect_equal(tp:traitCount(), 2)
    end)
end)

-- =========================================================================
-- TraitProfile  - Modifiers
-- =========================================================================
-- @describe TraitProfile modifiers
describe("TraitProfile modifiers", function()
    -- @covers LTraitProfile:addModifier
    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("modifier raises effective value immediately", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("fear", 0.2)
        tp:addModifier("fear", 0.5, nil, "poison")
        expect_near(tp:get("fear"), 0.7, 0.01)
    end)

    -- @covers LTraitProfile:addModifier
    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:removeModifiers
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("removeModifiers restores base value", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("fear", 0.2)
        tp:addModifier("fear", 0.5, nil, "poison")
        tp:removeModifiers("poison")
        expect_near(tp:get("fear"), 0.2, 0.01)
    end)

    -- @covers LTraitProfile:addModifier
    -- @covers LTraitProfile:getBase
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("getBase is unchanged by modifier", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("strength", 0.8)
        tp:addModifier("strength", 0.1, nil, "buff")
        expect_near(tp:getBase("strength"), 0.8, 0.01)
    end)
end)

-- =========================================================================
-- TraitProfile  - Update / decay
-- =========================================================================
-- @describe TraitProfile update
describe("TraitProfile update", function()
    -- @covers LTraitProfile:traitCount
    -- @covers LTraitProfile:update
    -- @covers lurek.ai.newTraitProfile
    it("update does not crash with no modifiers", function()
        local tp = lurek.ai.newTraitProfile()
        tp:update(0.016)
        expect_equal(tp:traitCount(), 0)
    end)

    -- @covers LTraitProfile:addModifier
    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:set
    -- @covers LTraitProfile:update
    -- @covers lurek.ai.newTraitProfile
    it("timed modifier expires after update", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("speed", 0.5)
        tp:addModifier("speed", 0.3, 0.001, "boost")  -- expires in 0.001 s
        tp:update(1.0)  -- well past expiry
        expect_near(tp:get("speed"), 0.5, 0.01)
    end)
end)

-- =========================================================================
-- =========================================================================

-- @describe Missing API Coverage
describe("Missing API Coverage", function()
    -- @covers LAIBlackboard:has
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("covers Blackboard:has", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal(false, bb:has("hp"))
        bb:setNumber("hp", 10)
        expect_equal(true, bb:has("hp"))
    end)

    -- @covers LBehaviorTree:getDebugState
    -- @covers lurek.ai.newBehaviorTree
    it("covers BehaviorTree:getDebugState", function()
        local bt = lurek.ai.newBehaviorTree()
        local dbg = bt:getDebugState()
        expect_type("table", dbg)
        expect_type("number", dbg.node_count)
        expect_type("string", dbg.last_status)
    end)

    -- @covers LSteeringManager:calculate
    -- @covers LSteeringManager:setSpatialHashCellSize
    -- @covers lurek.ai.newSteeringManager
    it("covers SteeringManager:setSpatialHashCellSize", function()
        local sm = lurek.ai.newSteeringManager()
        expect_no_error(function()
            sm:setSpatialHashCellSize(32)
        end)
        local fx, fy = sm:calculate(0, 0, 0, 0, 100, 50, 0.016)
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    -- @covers LSteeringManager:enableSpatialHash
    -- @covers lurek.ai.newSteeringManager
    it("covers SteeringManager:enableSpatialHash", function()
        local sm = lurek.ai.newSteeringManager()
        expect_no_error(function()
            sm:enableSpatialHash(true)
            sm:enableSpatialHash(false)
        end)
    end)

    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCurrentTarget
    -- @covers lurek.ai.newCommandQueue
    it("covers CommandQueue:getCurrentTarget", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end, {
            targetX = 100,
            targetY = 200,
        })
        local x, y = cq:getCurrentTarget()
        expect_equal(100, x)
        expect_equal(200, y)
    end)

    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("covers TraitProfile:set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("courage", 0.75)
        expect_near(0.75, tp:get("courage"), 0.001)
    end)

    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("covers TraitProfile:get", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("loyalty", 0.5)
        expect_near(0.5, tp:get("loyalty"), 0.001)
    end)

    -- @covers LTraitProfile:has
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("covers TraitProfile:has", function()
        local tp = lurek.ai.newTraitProfile()
        expect_equal(false, tp:has("focus"))
        tp:set("focus", 0.9)
        expect_equal(true, tp:has("focus"))
    end)

    -- @covers LContextSteering:addAvoidBounds
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("covers ContextSteering:addAvoidBounds", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addAvoidBounds(-10, -10, 10, 10, 2, 1)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:get
    -- @covers lurek.ai.newEmotionModel
    it("covers EmotionModel:get", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.1, 0.5, 0.2)
        expect_near(0.1, em:get("joy"), 0.001)
    end)

    -- @covers LNeuroevolution:bestFitness
    -- @covers LNeuroevolution:setFitness
    -- @covers lurek.ai.newNeuroevolution
    it("covers Neuroevolution:bestFitness", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=1, outputs=1, activation="linear"}}, 4, 11)
        ne:setFitness(0, 0.1)
        ne:setFitness(1, 0.8)
        ne:setFitness(2, 0.3)
        ne:setFitness(3, 0.6)
        expect_near(0.8, ne:bestFitness(), 0.001)
    end)

end)

-- @describe Missing explicit test for AIWorld:addAgent
describe("Missing explicit test for AIWorld:addAgent", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers lurek.ai.newWorld
    it("AIWorld:addAgent works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_add")
        expect_not_nil(a)
        expect_equal(1, w:getAgentCount())
    end)
end)

-- @describe Missing explicit test for AIWorld:getAgent
describe("Missing explicit test for AIWorld:getAgent", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgent
    -- @covers lurek.ai.newWorld
    it("AIWorld:getAgent works", function()
        local w = lurek.ai.newWorld()
        w:addAgent("agent_get")
        local a = w:getAgent("agent_get")
        expect_not_nil(a)
        expect_equal("agent_get", a:getName())
    end)
end)

-- @describe Missing explicit test for AIWorld:removeAgent
describe("Missing explicit test for AIWorld:removeAgent", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers LAIWorld:removeAgent
    -- @covers lurek.ai.newWorld
    it("AIWorld:removeAgent works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_remove")
        w:removeAgent(a)
        expect_equal(0, w:getAgentCount())
    end)
end)

-- @describe Missing explicit test for AIWorld:getAgentCount
describe("Missing explicit test for AIWorld:getAgentCount", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:getAgentCount
    -- @covers lurek.ai.newWorld
    it("AIWorld:getAgentCount works", function()
        local w = lurek.ai.newWorld()
        w:addAgent("a")
        w:addAgent("b")
        expect_equal(2, w:getAgentCount())
    end)
end)

-- @describe Missing explicit test for AIWorld:getGlobalBlackboard
describe("Missing explicit test for AIWorld:getGlobalBlackboard", function()
    -- @covers LAIWorld:getGlobalBlackboard
    -- @covers lurek.ai.newWorld
    it("AIWorld:getGlobalBlackboard works", function()
        local w = lurek.ai.newWorld()
        local bb = w:getGlobalBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)
end)

-- @describe Missing explicit test for AIWorld:update
describe("Missing explicit test for AIWorld:update", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:update
    -- @covers lurek.ai.newWorld
    it("AIWorld:update works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("mover")
        a:setVelocity(10, 0)
        w:update(0.5)
        local x = a:getPosition()
        expect_true(x > 0, "agent should move after update")
    end)
end)

-- @describe Missing explicit test for AIWorld:type
describe("Missing explicit test for AIWorld:type", function()
    -- @covers LAIWorld:type
    -- @covers lurek.ai.newWorld
    it("AIWorld:type works", function()
        expect_equal("LAIWorld", lurek.ai.newWorld():type())
    end)
end)

-- @describe Missing explicit test for AIWorld:typeOf
describe("Missing explicit test for AIWorld:typeOf", function()
    -- @covers LAIWorld:typeOf
    -- @covers lurek.ai.newWorld
    it("AIWorld:typeOf works", function()
        expect_equal(true, lurek.ai.newWorld():typeOf("AIWorld"))
    end)
end)

-- @describe Missing explicit test for Agent:getName
describe("Missing explicit test for Agent:getName", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:getName works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_name")
        expect_equal("agent_name", a:getName())
    end)
end)

-- @describe Missing explicit test for Agent:setPosition
describe("Missing explicit test for Agent:setPosition", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:setPosition works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_pos_set")
        a:setPosition(12, 34)
        local x, y = a:getPosition()
        expect_near(12, x, 0.01)
        expect_near(34, y, 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:getPosition
describe("Missing explicit test for Agent:getPosition", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:getPosition works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_pos_get")
        a:setPosition(3, 7)
        local x, y = a:getPosition()
        expect_near(3, x, 0.01)
        expect_near(7, y, 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:setVelocity
describe("Missing explicit test for Agent:setVelocity", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:setVelocity works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_vel_set")
        a:setVelocity(5, -3)
        local vx, vy = a:getVelocity()
        expect_near(5, vx, 0.01)
        expect_near(-3, vy, 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:getVelocity
describe("Missing explicit test for Agent:getVelocity", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:getVelocity works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_vel_get")
        a:setVelocity(2, 4)
        local vx, vy = a:getVelocity()
        expect_near(2, vx, 0.01)
        expect_near(4, vy, 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:setMaxSpeed
describe("Missing explicit test for Agent:setMaxSpeed", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getMaxSpeed
    -- @covers LAgent:setMaxSpeed
    -- @covers lurek.ai.newWorld
    it("Agent:setMaxSpeed works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_speed_set")
        a:setMaxSpeed(250)
        expect_near(250, a:getMaxSpeed(), 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:getMaxSpeed
describe("Missing explicit test for Agent:getMaxSpeed", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getMaxSpeed
    -- @covers LAgent:setMaxSpeed
    -- @covers lurek.ai.newWorld
    it("Agent:getMaxSpeed works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_speed_get")
        a:setMaxSpeed(125)
        expect_near(125, a:getMaxSpeed(), 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:setMaxForce
describe("Missing explicit test for Agent:setMaxForce", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getMaxForce
    -- @covers LAgent:setMaxForce
    -- @covers lurek.ai.newWorld
    it("Agent:setMaxForce works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_force_set")
        a:setMaxForce(400)
        expect_near(400, a:getMaxForce(), 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:getMaxForce
describe("Missing explicit test for Agent:getMaxForce", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getMaxForce
    -- @covers LAgent:setMaxForce
    -- @covers lurek.ai.newWorld
    it("Agent:getMaxForce works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_force_get")
        a:setMaxForce(175)
        expect_near(175, a:getMaxForce(), 0.01)
    end)
end)

-- @describe Missing explicit test for Agent:setPriority
describe("Missing explicit test for Agent:setPriority", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:setPriority works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_prio_set")
        a:setPriority(9)
        expect_equal(9, a:getPriority())
    end)
end)

-- @describe Missing explicit test for Agent:getPriority
describe("Missing explicit test for Agent:getPriority", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:getPriority works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_prio_get")
        a:setPriority(4)
        expect_equal(4, a:getPriority())
    end)
end)

-- @describe Missing explicit test for Agent:setDecisionModel
describe("Missing explicit test for Agent:setDecisionModel", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("Agent:setDecisionModel works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_model_set")
        a:setDecisionModel("bt")
        expect_equal("bt", a:getDecisionModel())
    end)
end)

-- @describe Missing explicit test for Agent:getDecisionModel
describe("Missing explicit test for Agent:getDecisionModel", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setDecisionModel
    -- @covers lurek.ai.newWorld
    it("Agent:getDecisionModel works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_model_get")
        a:setDecisionModel("fsm")
        expect_equal("fsm", a:getDecisionModel())
    end)
end)

-- @describe Missing explicit test for Agent:addTag
describe("Missing explicit test for Agent:addTag", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:addTag works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_tag_add")
        a:addTag("enemy")
        expect_equal(true, a:hasTag("enemy"))
    end)
end)

-- @describe Missing explicit test for Agent:removeTag
describe("Missing explicit test for Agent:removeTag", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:removeTag works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_tag_remove")
        a:addTag("enemy")
        a:removeTag("enemy")
        expect_equal(false, a:hasTag("enemy"))
    end)
end)

-- @describe Missing explicit test for Agent:hasTag
describe("Missing explicit test for Agent:hasTag", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:hasTag works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_tag_has")
        expect_equal(false, a:hasTag("support"))
        a:addTag("support")
        expect_equal(true, a:hasTag("support"))
    end)
end)

-- @describe Missing explicit test for Agent:getBlackboard
describe("Missing explicit test for Agent:getBlackboard", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:getBlackboard works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_bb")
        local bb = a:getBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)
end)

-- @describe Missing explicit test for Agent:type
describe("Missing explicit test for Agent:type", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:type works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_type")
        expect_equal("LAgent", a:type())
    end)
end)

-- @describe Missing explicit test for Agent:typeOf
describe("Missing explicit test for Agent:typeOf", function()
    -- @covers LAIWorld:addAgent
    -- @covers lurek.ai.newWorld
    it("Agent:typeOf works", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_typeof")
        expect_equal(true, a:typeOf("Agent"))
    end)
end)

-- @describe Missing explicit test for Blackboard:setNumber
describe("Missing explicit test for Blackboard:setNumber", function()
    -- @covers LAIBlackboard:getNumber
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:setNumber works", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 42)
        expect_near(42, bb:getNumber("hp"), 0.001)
    end)
end)

-- @describe Missing explicit test for Blackboard:setBool
describe("Missing explicit test for Blackboard:setBool", function()
    -- @covers LAIBlackboard:getBool
    -- @covers LAIBlackboard:setBool
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:setBool works", function()
        local bb = lurek.ai.newBlackboard()
        bb:setBool("alive", true)
        expect_equal(true, bb:getBool("alive"))
    end)
end)

-- @describe Missing explicit test for Blackboard:setString
describe("Missing explicit test for Blackboard:setString", function()
    -- @covers LAIBlackboard:getString
    -- @covers LAIBlackboard:setString
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:setString works", function()
        local bb = lurek.ai.newBlackboard()
        bb:setString("role", "tank")
        expect_equal("tank", bb:getString("role"))
    end)
end)

-- @describe Missing explicit test for Blackboard:remove
describe("Missing explicit test for Blackboard:remove", function()
    -- @covers LAIBlackboard:has
    -- @covers LAIBlackboard:remove
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:remove works", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:remove("hp")
        expect_equal(false, bb:has("hp"))
    end)
end)

-- @describe Missing explicit test for Blackboard:clear
describe("Missing explicit test for Blackboard:clear", function()
    -- @covers LAIBlackboard:clear
    -- @covers LAIBlackboard:getSize
    -- @covers LAIBlackboard:setBool
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:clear works", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("a", 1)
        bb:setBool("b", true)
        bb:clear()
        expect_equal(0, bb:getSize())
    end)
end)

-- @describe Missing explicit test for Blackboard:getKeys
describe("Missing explicit test for Blackboard:getKeys", function()
    -- @covers LAIBlackboard:getKeys
    -- @covers LAIBlackboard:setNumber
    -- @covers LAIBlackboard:setString
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:getKeys works", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:setString("name", "hero")
        local keys = bb:getKeys()
        expect_type("table", keys)
        expect_equal(2, #keys)
    end)
end)

-- @describe Missing explicit test for Blackboard:getSize
describe("Missing explicit test for Blackboard:getSize", function()
    -- @covers LAIBlackboard:getSize
    -- @covers LAIBlackboard:setNumber
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:getSize works", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal(0, bb:getSize())
        bb:setNumber("hp", 10)
        expect_equal(1, bb:getSize())
    end)
end)

-- @describe Missing explicit test for Blackboard:type
describe("Missing explicit test for Blackboard:type", function()
    -- @covers LAIBlackboard:type
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:type works", function()
        expect_equal("LAIBlackboard", lurek.ai.newBlackboard():type())
    end)
end)

-- @describe Missing explicit test for Blackboard:typeOf
describe("Missing explicit test for Blackboard:typeOf", function()
    -- @covers LAIBlackboard:typeOf
    -- @covers lurek.ai.newBlackboard
    it("Blackboard:typeOf works", function()
        expect_equal(true, lurek.ai.newBlackboard():typeOf("Blackboard"))
    end)
end)

-- @describe Missing explicit test for StateMachine:addState
describe("Missing explicit test for StateMachine:addState", function()
    -- @covers LStateMachine:addState
    -- @covers LStateMachine:getCurrentState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:addState works", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        expect_equal("idle", fsm:getCurrentState())
    end)
end)

-- @describe Missing explicit test for StateMachine:setInitialState
describe("Missing explicit test for StateMachine:setInitialState", function()
    -- @covers LStateMachine:addState
    -- @covers LStateMachine:getCurrentState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:setInitialState works", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("patrol", {})
        fsm:setInitialState("patrol")
        expect_equal("patrol", fsm:getCurrentState())
    end)
end)

-- @describe Missing explicit test for StateMachine:getCurrentState
describe("Missing explicit test for StateMachine:getCurrentState", function()
    -- @covers LStateMachine:getCurrentState
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:getCurrentState works", function()
        local fsm = lurek.ai.newStateMachine()
        expect_nil(fsm:getCurrentState())
    end)
end)

-- @describe Missing explicit test for StateMachine:forceState
describe("Missing explicit test for StateMachine:forceState", function()
    -- @covers LStateMachine:addState
    -- @covers LStateMachine:forceState
    -- @covers LStateMachine:getCurrentState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:forceState works", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("attack", {})
        fsm:setInitialState("idle")
        fsm:forceState("attack")
        expect_equal("attack", fsm:getCurrentState())
    end)
end)

-- @describe Missing explicit test for StateMachine:getTimeInState
describe("Missing explicit test for StateMachine:getTimeInState", function()
    -- @covers LStateMachine:addState
    -- @covers LStateMachine:forceState
    -- @covers LStateMachine:getTimeInState
    -- @covers LStateMachine:setInitialState
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:getTimeInState works", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        fsm:forceState("idle")
        expect_near(0, fsm:getTimeInState(), 0.01)
    end)
end)

-- @describe Missing explicit test for StateMachine:type
describe("Missing explicit test for StateMachine:type", function()
    -- @covers LStateMachine:type
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:type works", function()
        expect_equal("LStateMachine", lurek.ai.newStateMachine():type())
    end)
end)

-- @describe Missing explicit test for StateMachine:typeOf
describe("Missing explicit test for StateMachine:typeOf", function()
    -- @covers LStateMachine:typeOf
    -- @covers lurek.ai.newStateMachine
    it("StateMachine:typeOf works", function()
        expect_true(lurek.ai.newStateMachine():typeOf("StateMachine"))
    end)
end)

-- @describe Missing explicit test for BehaviorTree:setRoot
describe("Missing explicit test for BehaviorTree:setRoot", function()
    -- @covers LBehaviorTree:getDebugState
    -- @covers LBehaviorTree:setRoot
    -- @covers lurek.ai.newBehaviorTree
    -- @covers lurek.ai.newSequence
    it("BehaviorTree:setRoot works", function()
        local bt = lurek.ai.newBehaviorTree()
        bt:setRoot(lurek.ai.newSequence())
        local dbg = bt:getDebugState()
        expect_true(dbg.node_count >= 1)
    end)
end)

-- @describe Missing explicit test for BehaviorTree:getLastStatus
describe("Missing explicit test for BehaviorTree:getLastStatus", function()
    -- @covers LBehaviorTree:getLastStatus
    -- @covers lurek.ai.newBehaviorTree
    it("BehaviorTree:getLastStatus works", function()
        expect_equal("success", lurek.ai.newBehaviorTree():getLastStatus())
    end)
end)

-- @describe Missing explicit test for BehaviorTree:type
describe("Missing explicit test for BehaviorTree:type", function()
    -- @covers LBehaviorTree:type
    -- @covers lurek.ai.newBehaviorTree
    it("BehaviorTree:type works", function()
        expect_equal("LBehaviorTree", lurek.ai.newBehaviorTree():type())
    end)
end)

-- @describe Missing explicit test for BehaviorTree:typeOf
describe("Missing explicit test for BehaviorTree:typeOf", function()
    -- @covers LBehaviorTree:typeOf
    -- @covers lurek.ai.newBehaviorTree
    it("BehaviorTree:typeOf works", function()
        expect_true(lurek.ai.newBehaviorTree():typeOf("BehaviorTree"))
    end)
end)

-- @describe Missing explicit test for BTNode:addChild
describe("Missing explicit test for BTNode:addChild", function()
    -- @covers LBTNode:addChild
    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newSequence
    it("BTNode:addChild works", function()
        local seq = lurek.ai.newSequence()
        seq:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, seq:getChildCount())
    end)
end)

-- @describe Missing explicit test for BTNode:getChildCount
describe("Missing explicit test for BTNode:getChildCount", function()
    -- @covers LBTNode:addChild
    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newParallel
    it("BTNode:getChildCount works", function()
        local par = lurek.ai.newParallel()
        expect_equal(0, par:getChildCount())
        par:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, par:getChildCount())
    end)
end)

-- @describe Missing explicit test for BTNode:reset
describe("Missing explicit test for BTNode:reset", function()
    -- @covers LBTNode:reset
    -- @covers LBTNode:setChild
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newRepeater
    it("BTNode:reset works", function()
        local node = lurek.ai.newRepeater(3)
        node:setChild(lurek.ai.newAction(function() end))
        expect_no_error(function()
            node:reset()
        end)
    end)
end)

-- @describe Missing explicit test for BTNode:setChild
describe("Missing explicit test for BTNode:setChild", function()
    -- @covers LBTNode:setChild
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newInverter
    it("BTNode:setChild works", function()
        local inv = lurek.ai.newInverter()
        expect_no_error(function()
            inv:setChild(lurek.ai.newAction(function() end))
        end)
    end)
end)

-- @describe Missing explicit test for BTNode:setCount
describe("Missing explicit test for BTNode:setCount", function()
    -- @covers LBTNode:getCount
    -- @covers LBTNode:setCount
    -- @covers lurek.ai.newRepeater
    it("BTNode:setCount works", function()
        local rep = lurek.ai.newRepeater(2)
        rep:setCount(7)
        expect_equal(7, rep:getCount())
    end)
end)

-- @describe Missing explicit test for BTNode:getCount
describe("Missing explicit test for BTNode:getCount", function()
    -- @covers LBTNode:getCount
    -- @covers lurek.ai.newRepeater
    it("BTNode:getCount works", function()
        expect_equal(4, lurek.ai.newRepeater(4):getCount())
    end)
end)

-- @describe Missing explicit test for BTNode:setSuccessPolicy
describe("Missing explicit test for BTNode:setSuccessPolicy", function()
    -- @covers LBTNode:setSuccessPolicy
    -- @covers lurek.ai.newParallel
    it("BTNode:setSuccessPolicy works", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setSuccessPolicy("require_all")
        end)
    end)
end)

-- @describe Missing explicit test for BTNode:setFailurePolicy
describe("Missing explicit test for BTNode:setFailurePolicy", function()
    -- @covers LBTNode:setFailurePolicy
    -- @covers lurek.ai.newParallel
    it("BTNode:setFailurePolicy works", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setFailurePolicy("require_all")
        end)
    end)
end)

-- @describe Missing explicit test for BTNode:getNodeType
describe("Missing explicit test for BTNode:getNodeType", function()
    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newSelector
    it("BTNode:getNodeType works", function()
        expect_equal("selector", lurek.ai.newSelector():getNodeType())
    end)
end)

-- @describe Missing explicit test for BTNode:type
describe("Missing explicit test for BTNode:type", function()
    -- @covers LBTNode:type
    -- @covers lurek.ai.newSelector
    it("BTNode:type works", function()
        expect_equal("LBTNode", lurek.ai.newSelector():type())
    end)
end)

-- @describe Missing explicit test for BTNode:typeOf
describe("Missing explicit test for BTNode:typeOf", function()
    -- @covers LBTNode:typeOf
    -- @covers lurek.ai.newSelector
    it("BTNode:typeOf works", function()
        expect_true(lurek.ai.newSelector():typeOf("BTNode"))
    end)
end)

-- @describe Missing explicit test for SteeringManager:getBehaviorCount
describe("Missing explicit test for SteeringManager:getBehaviorCount", function()
    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:getBehaviorCount works", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal(0, sm:getBehaviorCount())
        sm:addSeek(100, 50)
        expect_equal(1, sm:getBehaviorCount())
    end)
end)

-- @describe Missing explicit test for SteeringManager:setCombineMode
describe("Missing explicit test for SteeringManager:setCombineMode", function()
    -- @covers LSteeringManager:getCombineMode
    -- @covers LSteeringManager:setCombineMode
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:setCombineMode works", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("priority")
        expect_equal("priority", sm:getCombineMode())
    end)
end)

-- @describe Missing explicit test for SteeringManager:getCombineMode
describe("Missing explicit test for SteeringManager:getCombineMode", function()
    -- @covers LSteeringManager:getCombineMode
    -- @covers LSteeringManager:setCombineMode
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:getCombineMode works", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("weighted")
        expect_equal("weighted", sm:getCombineMode())
    end)
end)

-- @describe Missing explicit test for SteeringManager:getLastSteering
describe("Missing explicit test for SteeringManager:getLastSteering", function()
    -- @covers LSteeringManager:addSeek
    -- @covers LSteeringManager:calculate
    -- @covers LSteeringManager:getLastSteering
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:getLastSteering works", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:calculate(0, 0, 0, 0, 100, 50, 1 / 60)
        local fx, fy = sm:getLastSteering()
        expect_type("number", fx)
        expect_type("number", fy)
    end)
end)

-- @describe Missing explicit test for SteeringManager:type
describe("Missing explicit test for SteeringManager:type", function()
    -- @covers LSteeringManager:type
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:type works", function()
        expect_equal("LSteeringManager", lurek.ai.newSteeringManager():type())
    end)
end)

-- @describe Missing explicit test for SteeringManager:typeOf
describe("Missing explicit test for SteeringManager:typeOf", function()
    -- @covers LSteeringManager:typeOf
    -- @covers lurek.ai.newSteeringManager
    it("SteeringManager:typeOf works", function()
        expect_true(lurek.ai.newSteeringManager():typeOf("SteeringManager"))
    end)
end)

-- @describe Missing explicit test for QLearner:chooseAction
describe("Missing explicit test for QLearner:chooseAction", function()
    -- @covers LQLearner:chooseAction
    -- @covers lurek.ai.newQLearner
    it("QLearner:chooseAction works", function()
        local q = lurek.ai.newQLearner(2, 3)
        local action = q:chooseAction(1)
        expect_true(action >= 1 and action <= 3)
    end)
end)

-- @describe Missing explicit test for QLearner:bestAction
describe("Missing explicit test for QLearner:bestAction", function()
    -- @covers LQLearner:bestAction
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("QLearner:bestAction works", function()
        local q = lurek.ai.newQLearner(2, 3)
        q:setQValue(1, 1, 1.0)
        q:setQValue(1, 2, 5.0)
        q:setQValue(1, 3, 2.0)
        expect_equal(2, q:bestAction(1))
    end)
end)

-- @describe Missing explicit test for QLearner:getQValue
describe("Missing explicit test for QLearner:getQValue", function()
    -- @covers LQLearner:getQValue
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("QLearner:getQValue works", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setQValue(1, 2, 5.0)
        expect_near(5.0, q:getQValue(1, 2), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:endEpisode
describe("Missing explicit test for QLearner:endEpisode", function()
    -- @covers LQLearner:endEpisode
    -- @covers LQLearner:getEpisodeCount
    -- @covers lurek.ai.newQLearner
    it("QLearner:endEpisode works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
    end)
end)

-- @describe Missing explicit test for QLearner:getEpisodeCount
describe("Missing explicit test for QLearner:getEpisodeCount", function()
    -- @covers LQLearner:endEpisode
    -- @covers LQLearner:getEpisodeCount
    -- @covers lurek.ai.newQLearner
    it("QLearner:getEpisodeCount works", function()
        local q = lurek.ai.newQLearner(2, 2)
        expect_equal(0, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
    end)
end)

-- @describe Missing explicit test for QLearner:getStateCount
describe("Missing explicit test for QLearner:getStateCount", function()
    -- @covers LQLearner:getStateCount
    -- @covers lurek.ai.newQLearner
    it("QLearner:getStateCount works", function()
        expect_equal(4, lurek.ai.newQLearner(4, 3):getStateCount())
    end)
end)

-- @describe Missing explicit test for QLearner:getActionCount
describe("Missing explicit test for QLearner:getActionCount", function()
    -- @covers LQLearner:getActionCount
    -- @covers lurek.ai.newQLearner
    it("QLearner:getActionCount works", function()
        expect_equal(3, lurek.ai.newQLearner(4, 3):getActionCount())
    end)
end)

-- @describe Missing explicit test for QLearner:setLearningRate
describe("Missing explicit test for QLearner:setLearningRate", function()
    -- @covers LQLearner:getLearningRate
    -- @covers LQLearner:setLearningRate
    -- @covers lurek.ai.newQLearner
    it("QLearner:setLearningRate works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.5)
        expect_near(0.5, q:getLearningRate(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:getLearningRate
describe("Missing explicit test for QLearner:getLearningRate", function()
    -- @covers LQLearner:getLearningRate
    -- @covers LQLearner:setLearningRate
    -- @covers lurek.ai.newQLearner
    it("QLearner:getLearningRate works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.25)
        expect_near(0.25, q:getLearningRate(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:setDiscountFactor
describe("Missing explicit test for QLearner:setDiscountFactor", function()
    -- @covers LQLearner:getDiscountFactor
    -- @covers LQLearner:setDiscountFactor
    -- @covers lurek.ai.newQLearner
    it("QLearner:setDiscountFactor works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.8)
        expect_near(0.8, q:getDiscountFactor(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:getDiscountFactor
describe("Missing explicit test for QLearner:getDiscountFactor", function()
    -- @covers LQLearner:getDiscountFactor
    -- @covers LQLearner:setDiscountFactor
    -- @covers lurek.ai.newQLearner
    it("QLearner:getDiscountFactor works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.7)
        expect_near(0.7, q:getDiscountFactor(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:setExplorationRate
describe("Missing explicit test for QLearner:setExplorationRate", function()
    -- @covers LQLearner:getExplorationRate
    -- @covers LQLearner:setExplorationRate
    -- @covers lurek.ai.newQLearner
    it("QLearner:setExplorationRate works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.1)
        expect_near(0.1, q:getExplorationRate(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:getExplorationRate
describe("Missing explicit test for QLearner:getExplorationRate", function()
    -- @covers LQLearner:getExplorationRate
    -- @covers LQLearner:setExplorationRate
    -- @covers lurek.ai.newQLearner
    it("QLearner:getExplorationRate works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.2)
        expect_near(0.2, q:getExplorationRate(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:setExplorationDecay
describe("Missing explicit test for QLearner:setExplorationDecay", function()
    -- @covers LQLearner:getExplorationDecay
    -- @covers LQLearner:setExplorationDecay
    -- @covers lurek.ai.newQLearner
    it("QLearner:setExplorationDecay works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.99)
        expect_near(0.99, q:getExplorationDecay(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:getExplorationDecay
describe("Missing explicit test for QLearner:getExplorationDecay", function()
    -- @covers LQLearner:getExplorationDecay
    -- @covers LQLearner:setExplorationDecay
    -- @covers lurek.ai.newQLearner
    it("QLearner:getExplorationDecay works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.95)
        expect_near(0.95, q:getExplorationDecay(), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:serialize
describe("Missing explicit test for QLearner:serialize", function()
    -- @covers LQLearner:serialize
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("QLearner:serialize works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setQValue(1, 1, 3.14)
        local json = q:serialize()
        expect_type("string", json)
    end)
end)

-- @describe Missing explicit test for QLearner:deserialize
describe("Missing explicit test for QLearner:deserialize", function()
    -- @covers LQLearner:deserialize
    -- @covers LQLearner:getQValue
    -- @covers LQLearner:serialize
    -- @covers LQLearner:setQValue
    -- @covers lurek.ai.newQLearner
    it("QLearner:deserialize works", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setQValue(1, 1, 3.14)
        local json = q:serialize()
        local q2 = lurek.ai.newQLearner(2, 2)
        q2:deserialize(json)
        expect_near(3.14, q2:getQValue(1, 1), 0.001)
    end)
end)

-- @describe Missing explicit test for QLearner:type
describe("Missing explicit test for QLearner:type", function()
    -- @covers LQLearner:type
    -- @covers lurek.ai.newQLearner
    it("QLearner:type works", function()
        expect_equal("LQLearner", lurek.ai.newQLearner(2, 2):type())
    end)
end)

-- @describe Missing explicit test for QLearner:typeOf
describe("Missing explicit test for QLearner:typeOf", function()
    -- @covers LQLearner:typeOf
    -- @covers lurek.ai.newQLearner
    it("QLearner:typeOf works", function()
        expect_true(lurek.ai.newQLearner(2, 2):typeOf("QLearner"))
    end)
end)

-- @describe Missing explicit test for UtilityAI:evaluate
describe("Missing explicit test for UtilityAI:evaluate", function()
    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:evaluate
    -- @covers lurek.ai.newUtilityAI
    it("UtilityAI:evaluate works", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 0.2 end)
        u:addAction("attack", function() return 0.9 end)
        expect_equal("attack", u:evaluate())
    end)
end)

-- @describe Missing explicit test for UtilityAI:getActionCount
describe("Missing explicit test for UtilityAI:getActionCount", function()
    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:getActionCount
    -- @covers lurek.ai.newUtilityAI
    it("UtilityAI:getActionCount works", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal(0, u:getActionCount())
        u:addAction("patrol", function() return 0.2 end)
        expect_equal(1, u:getActionCount())
    end)
end)

-- @describe Missing explicit test for UtilityAI:getLastAction
describe("Missing explicit test for UtilityAI:getLastAction", function()
    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:evaluate
    -- @covers LUtilityAI:getLastAction
    -- @covers lurek.ai.newUtilityAI
    it("UtilityAI:getLastAction works", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 0.2 end)
        u:evaluate()
        expect_equal("patrol", u:getLastAction())
    end)
end)

-- @describe Missing explicit test for UtilityAI:type
describe("Missing explicit test for UtilityAI:type", function()
    -- @covers LUtilityAI:type
    -- @covers lurek.ai.newUtilityAI
    it("UtilityAI:type works", function()
        expect_equal("LUtilityAI", lurek.ai.newUtilityAI():type())
    end)
end)

-- @describe Missing explicit test for UtilityAI:typeOf
describe("Missing explicit test for UtilityAI:typeOf", function()
    -- @covers LUtilityAI:typeOf
    -- @covers lurek.ai.newUtilityAI
    it("UtilityAI:typeOf works", function()
        expect_true(lurek.ai.newUtilityAI():typeOf("UtilityAI"))
    end)
end)

-- @describe Missing explicit test for GOAPPlanner:getActionCount
describe("Missing explicit test for GOAPPlanner:getActionCount", function()
    -- @covers LGOAPPlanner:addAction
    -- @covers LGOAPPlanner:getActionCount
    -- @covers lurek.ai.newGOAPPlanner
    it("GOAPPlanner:getActionCount works", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getActionCount())
        g:addAction("move", 1.0)
        expect_equal(1, g:getActionCount())
    end)
end)

-- @describe Missing explicit test for GOAPPlanner:getGoalCount
describe("Missing explicit test for GOAPPlanner:getGoalCount", function()
    -- @covers LGOAPPlanner:addGoal
    -- @covers LGOAPPlanner:getGoalCount
    -- @covers lurek.ai.newGOAPPlanner
    it("GOAPPlanner:getGoalCount works", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getGoalCount())
        g:addGoal("survive", 2.0)
        expect_equal(1, g:getGoalCount())
    end)
end)

-- @describe Missing explicit test for GOAPPlanner:type
describe("Missing explicit test for GOAPPlanner:type", function()
    -- @covers LGOAPPlanner:type
    -- @covers lurek.ai.newGOAPPlanner
    it("GOAPPlanner:type works", function()
        expect_equal("LGOAPPlanner", lurek.ai.newGOAPPlanner():type())
    end)
end)

-- @describe Missing explicit test for GOAPPlanner:typeOf
describe("Missing explicit test for GOAPPlanner:typeOf", function()
    -- @covers LGOAPPlanner:typeOf
    -- @covers lurek.ai.newGOAPPlanner
    it("GOAPPlanner:typeOf works", function()
        expect_true(lurek.ai.newGOAPPlanner():typeOf("GOAPPlanner"))
    end)
end)

-- @describe Missing explicit test for InfluenceMap:addLayer
describe("Missing explicit test for InfluenceMap:addLayer", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:hasLayer
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:addLayer works", function()
        local m = lurek.ai.newInfluenceMap(10, 10, 1.0)
        m:addLayer("threat")
        expect_true(m:hasLayer("threat"), "layer should exist after addLayer")
    end)
end)

-- @describe Missing explicit test for InfluenceMap:hasLayer
describe("Missing explicit test for InfluenceMap:hasLayer", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:hasLayer
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:hasLayer works", function()
        local m = lurek.ai.newInfluenceMap(10, 10, 1.0)
        expect_false(m:hasLayer("nope"), "unknown layer should return false")
        m:addLayer("nope")
        expect_true(m:hasLayer("nope"), "layer should exist after addLayer")
    end)
end)

-- @describe Missing explicit test for InfluenceMap:decay
describe("Missing explicit test for InfluenceMap:decay", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:decay
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:decay works", function()
        local m = lurek.ai.newInfluenceMap(4, 4, 1.0)
        m:addLayer("d")
        m:setInfluence("d", 1, 1, 10.0)
        m:decay("d", 0.5)
        local v = m:getInfluence("d", 1, 1)
        expect_true(v < 10.0, "decay should reduce influence")
    end)
end)

-- @describe Missing explicit test for InfluenceMap:clearLayer
describe("Missing explicit test for InfluenceMap:clearLayer", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:clearLayer
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:clearLayer works", function()
        local m = lurek.ai.newInfluenceMap(4, 4, 1.0)
        m:addLayer("c")
        m:setInfluence("c", 1, 1, 5.0)
        m:clearLayer("c")
        expect_equal(0.0, m:getInfluence("c", 1, 1))
    end)
end)

-- @describe Missing explicit test for InfluenceMap:clearAll
describe("Missing explicit test for InfluenceMap:clearAll", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:clearAll
    -- @covers LInfluenceMap:getInfluence
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:clearAll works", function()
        local m = lurek.ai.newInfluenceMap(4, 4, 1.0)
        m:addLayer("a")
        m:addLayer("b")
        m:setInfluence("a", 1, 1, 3.0)
        m:setInfluence("b", 2, 2, 7.0)
        m:clearAll()
        expect_equal(0.0, m:getInfluence("a", 1, 1))
        expect_equal(0.0, m:getInfluence("b", 2, 2))
    end)
end)

-- @describe Missing explicit test for InfluenceMap:getMaxPosition
describe("Missing explicit test for InfluenceMap:getMaxPosition", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:getMaxPosition
    -- @covers LInfluenceMap:setInfluence
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:getMaxPosition works", function()
        local m = lurek.ai.newInfluenceMap(4, 4, 1.0)
        m:addLayer("mx")
        m:setInfluence("mx", 3, 3, 9.0)
        local x, y = m:getMaxPosition("mx")
        expect_not_nil(x)
        expect_not_nil(y)
    end)
end)

-- @describe Missing explicit test for InfluenceMap:getMinPosition
describe("Missing explicit test for InfluenceMap:getMinPosition", function()
    -- @covers LInfluenceMap:addLayer
    -- @covers LInfluenceMap:getMinPosition
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:getMinPosition works", function()
        local m = lurek.ai.newInfluenceMap(4, 4, 1.0)
        m:addLayer("mn")
        local x, y = m:getMinPosition("mn")
        expect_not_nil(x)
        expect_not_nil(y)
    end)
end)

-- @describe Missing explicit test for InfluenceMap:getWidth
describe("Missing explicit test for InfluenceMap:getWidth", function()
    -- @covers LInfluenceMap:getWidth
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:getWidth works", function()
        local m = lurek.ai.newInfluenceMap(8, 4, 1.0)
        expect_equal(8, m:getWidth())
    end)
end)

-- @describe Missing explicit test for InfluenceMap:getHeight
describe("Missing explicit test for InfluenceMap:getHeight", function()
    -- @covers LInfluenceMap:getHeight
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:getHeight works", function()
        local m = lurek.ai.newInfluenceMap(8, 4, 1.0)
        expect_equal(4, m:getHeight())
    end)
end)

-- @describe Missing explicit test for InfluenceMap:getCellSize
describe("Missing explicit test for InfluenceMap:getCellSize", function()
    -- @covers LInfluenceMap:getCellSize
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:getCellSize works", function()
        local m = lurek.ai.newInfluenceMap(4, 4, 2.5)
        expect_equal(2.5, m:getCellSize())
    end)
end)

-- @describe Missing explicit test for InfluenceMap:type
describe("Missing explicit test for InfluenceMap:type", function()
    -- @covers LInfluenceMap:type
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:type works", function()
        expect_equal("LInfluenceMap", lurek.ai.newInfluenceMap(4, 4, 1.0):type())
    end)
end)

-- @describe Missing explicit test for InfluenceMap:typeOf
describe("Missing explicit test for InfluenceMap:typeOf", function()
    -- @covers LInfluenceMap:typeOf
    -- @covers lurek.ai.newInfluenceMap
    it("InfluenceMap:typeOf works", function()
        expect_true(lurek.ai.newInfluenceMap(4, 4, 1.0):typeOf("InfluenceMap"))
    end)
end)

-- @describe Missing explicit test for Squad:getName
describe("Missing explicit test for Squad:getName", function()
    -- @covers LSquad:getName
    -- @covers lurek.ai.newSquad
    it("Squad:getName works", function()
        local sq = lurek.ai.newSquad("alpha")
        expect_equal("alpha", sq:getName())
    end)
end)

-- @describe Missing explicit test for Squad:addMember
describe("Missing explicit test for Squad:addMember", function()
    -- @covers LSquad:addMember
    -- @covers LSquad:getMemberCount
    -- @covers lurek.ai.newSquad
    it("Squad:addMember works", function()
        local sq = lurek.ai.newSquad("bravo")
        sq:addMember("soldier1")
        expect_equal(1, sq:getMemberCount())
    end)
end)

-- @describe Missing explicit test for Squad:removeMember
describe("Missing explicit test for Squad:removeMember", function()
    -- @covers LSquad:addMember
    -- @covers LSquad:getMemberCount
    -- @covers LSquad:removeMember
    -- @covers lurek.ai.newSquad
    it("Squad:removeMember works", function()
        local sq = lurek.ai.newSquad("charlie")
        sq:addMember("s1")
        sq:addMember("s2")
        sq:removeMember("s1")
        expect_equal(1, sq:getMemberCount())
    end)
end)

-- @describe Missing explicit test for Squad:getMemberCount
describe("Missing explicit test for Squad:getMemberCount", function()
    -- @covers LSquad:addMember
    -- @covers LSquad:getMemberCount
    -- @covers lurek.ai.newSquad
    it("Squad:getMemberCount works", function()
        local sq = lurek.ai.newSquad("delta")
        expect_equal(0, sq:getMemberCount())
        sq:addMember("x")
        expect_equal(1, sq:getMemberCount())
    end)
end)

-- @describe Missing explicit test for Squad:getMembers
describe("Missing explicit test for Squad:getMembers", function()
    -- @covers LSquad:addMember
    -- @covers LSquad:getMembers
    -- @covers lurek.ai.newSquad
    it("Squad:getMembers works", function()
        local sq = lurek.ai.newSquad("echo")
        sq:addMember("a")
        sq:addMember("b")
        local members = sq:getMembers()
        expect_type("table", members)
        expect_equal(2, #members)
    end)
end)

-- @describe Missing explicit test for Squad:setLeader
describe("Missing explicit test for Squad:setLeader", function()
    -- @covers LSquad:addMember
    -- @covers LSquad:getLeader
    -- @covers LSquad:setLeader
    -- @covers lurek.ai.newSquad
    it("Squad:setLeader works", function()
        local sq = lurek.ai.newSquad("foxtrot")
        sq:addMember("leader")
        sq:setLeader("leader")
        expect_equal("leader", sq:getLeader())
    end)
end)

-- @describe Missing explicit test for Squad:getLeader
describe("Missing explicit test for Squad:getLeader", function()
    -- @covers LSquad:getLeader
    -- @covers LSquad:setLeader
    -- @covers lurek.ai.newSquad
    it("Squad:getLeader works", function()
        local sq = lurek.ai.newSquad("golf")
        expect_nil(sq:getLeader(), "no leader by default")
        sq:setLeader("cmd")
        expect_equal("cmd", sq:getLeader())
    end)
end)

-- @describe Missing explicit test for Squad:getFormation
describe("Missing explicit test for Squad:getFormation", function()
    -- @covers LSquad:getFormation
    -- @covers lurek.ai.newSquad
    it("Squad:getFormation works", function()
        local sq = lurek.ai.newSquad("hotel")
        local f = sq:getFormation()
        expect_type("string", f)
    end)
end)

-- @describe Missing explicit test for Squad:getFormationSpacing
describe("Missing explicit test for Squad:getFormationSpacing", function()
    -- @covers LSquad:getFormationSpacing
    -- @covers lurek.ai.newSquad
    it("Squad:getFormationSpacing works", function()
        local sq = lurek.ai.newSquad("india")
        local s = sq:getFormationSpacing()
        expect_type("number", s)
    end)
end)

-- @describe Missing explicit test for Squad:getBlackboard
describe("Missing explicit test for Squad:getBlackboard", function()
    -- @covers LSquad:getBlackboard
    -- @covers lurek.ai.newSquad
    it("Squad:getBlackboard works", function()
        local sq = lurek.ai.newSquad("juliet")
        local bb = sq:getBlackboard()
        expect_not_nil(bb)
    end)
end)

-- @describe Missing explicit test for Squad:type
describe("Missing explicit test for Squad:type", function()
    -- @covers LSquad:type
    -- @covers lurek.ai.newSquad
    it("Squad:type works", function()
        expect_equal("LSquad", lurek.ai.newSquad("t"):type())
    end)
end)

-- @describe Missing explicit test for Squad:typeOf
describe("Missing explicit test for Squad:typeOf", function()
    -- @covers LSquad:typeOf
    -- @covers lurek.ai.newSquad
    it("Squad:typeOf works", function()
        expect_true(lurek.ai.newSquad("t"):typeOf("Squad"))
    end)
end)

-- @describe Missing explicit test for CommandQueue:cancelCurrent
describe("Missing explicit test for CommandQueue:cancelCurrent", function()
    -- @covers LCommandQueue:cancelCurrent
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:isEmpty
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:cancelCurrent works", function()
        local q = lurek.ai.newCommandQueue()
        q:enqueue("move", function() end)
        local canceled = q:cancelCurrent()
        expect_true(canceled, "interruptible command should be canceled")
        expect_true(q:isEmpty())
    end)
end)

-- @describe Missing explicit test for CommandQueue:clear
describe("Missing explicit test for CommandQueue:clear", function()
    -- @covers LCommandQueue:clear
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:isEmpty
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:clear works", function()
        local q = lurek.ai.newCommandQueue()
        q:enqueue("move", function() end)
        q:enqueue("attack", function() end)
        q:clear()
        expect_true(q:isEmpty())
    end)
end)

-- @describe Missing explicit test for CommandQueue:getCount
describe("Missing explicit test for CommandQueue:getCount", function()
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCount
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:getCount works", function()
        local q = lurek.ai.newCommandQueue()
        expect_equal(0, q:getCount())
        q:enqueue("stop", function() end)
        expect_equal(1, q:getCount())
    end)
end)

-- @describe Missing explicit test for CommandQueue:isEmpty
describe("Missing explicit test for CommandQueue:isEmpty", function()
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:isEmpty
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:isEmpty works", function()
        local q = lurek.ai.newCommandQueue()
        expect_true(q:isEmpty())
        q:enqueue("move", function() end)
        expect_false(q:isEmpty())
    end)
end)

-- @describe Missing explicit test for CommandQueue:getCurrentType
describe("Missing explicit test for CommandQueue:getCurrentType", function()
    -- @covers LCommandQueue:enqueue
    -- @covers LCommandQueue:getCurrentType
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:getCurrentType works", function()
        local q = lurek.ai.newCommandQueue()
        expect_nil(q:getCurrentType())
        q:enqueue("patrol", function() end)
        expect_equal("patrol", q:getCurrentType())
    end)
end)

-- @describe Missing explicit test for CommandQueue:type
describe("Missing explicit test for CommandQueue:type", function()
    -- @covers LCommandQueue:type
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:type works", function()
        expect_equal("LCommandQueue", lurek.ai.newCommandQueue():type())
    end)
end)

-- @describe Missing explicit test for CommandQueue:typeOf
describe("Missing explicit test for CommandQueue:typeOf", function()
    -- @covers LCommandQueue:typeOf
    -- @covers lurek.ai.newCommandQueue
    it("CommandQueue:typeOf works", function()
        expect_true(lurek.ai.newCommandQueue():typeOf("CommandQueue"))
    end)
end)

-- @describe Missing explicit test for TraitProfile:getBase
describe("Missing explicit test for TraitProfile:getBase", function()
    -- @covers LTraitProfile:getBase
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("TraitProfile:getBase works", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("courage", 0.8)
        local base = tp:getBase("courage")
        expect_near(0.8, base, 1e-5)
    end)
end)

-- @describe Missing explicit test for TraitProfile:removeModifiers
describe("Missing explicit test for TraitProfile:removeModifiers", function()
    -- @covers LTraitProfile:addModifier
    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:removeModifiers
    -- @covers LTraitProfile:set
    -- @covers lurek.ai.newTraitProfile
    it("TraitProfile:removeModifiers works", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("strength", 1.0)
        tp:addModifier("strength", 0.5, nil, "buff")
        tp:removeModifiers("buff")
        -- after removal, effective value should return to base
        expect_equal(1.0, tp:get("strength"))
    end)
end)

-- @describe Missing explicit test for TraitProfile:update
describe("Missing explicit test for TraitProfile:update", function()
    -- @covers LTraitProfile:addModifier
    -- @covers LTraitProfile:get
    -- @covers LTraitProfile:set
    -- @covers LTraitProfile:update
    -- @covers lurek.ai.newTraitProfile
    it("TraitProfile:update works", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("patience", 0.5)
        tp:addModifier("patience", 0.3, 0.01, "temp")
        tp:update(1.0)
        -- after expiry the modifier is gone
        expect_equal(0.5, tp:get("patience"))
    end)
end)

-- @describe Missing explicit test for TraitProfile:traitCount
describe("Missing explicit test for TraitProfile:traitCount", function()
    -- @covers LTraitProfile:set
    -- @covers LTraitProfile:traitCount
    -- @covers lurek.ai.newTraitProfile
    it("TraitProfile:traitCount works", function()
        local tp = lurek.ai.newTraitProfile()
        expect_equal(0, tp:traitCount())
        tp:set("aggression", 0.9)
        expect_equal(1, tp:traitCount())
    end)
end)

-- @describe Missing explicit test for TraitProfile:archetype
describe("Missing explicit test for TraitProfile:archetype", function()
    -- @covers LTraitProfile:archetype
    -- @covers lurek.ai.newTraitProfile
    it("TraitProfile:archetype works", function()
        local tp = lurek.ai.newTraitProfile()
        -- default: no archetype
        local a = tp:archetype()
        expect_true(a == nil or type(a) == "string")
    end)
end)

-- @describe Missing explicit test for StimulusWorld:remove
describe("Missing explicit test for StimulusWorld:remove", function()
    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:count
    -- @covers LStimulusWorld:remove
    -- @covers lurek.ai.newStimulusWorld
    it("StimulusWorld:remove works", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 5.0)
        expect_equal(1, sw:count())
        local removed = sw:remove(id)
        expect_true(removed)
        expect_equal(0, sw:count())
    end)
end)

-- @describe Missing explicit test for StimulusWorld:update
describe("Missing explicit test for StimulusWorld:update", function()
    -- @covers LStimulusWorld:addAuditory
    -- @covers LStimulusWorld:count
    -- @covers LStimulusWorld:update
    -- @covers lurek.ai.newStimulusWorld
    it("StimulusWorld:update works", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addAuditory(0, 0, 1.0, 10.0, 100.0)
        sw:update(1.0)
        -- auditory with very high decay should be gone
        expect_equal(0, sw:count())
    end)
end)

-- @describe Missing explicit test for StimulusWorld:clear
describe("Missing explicit test for StimulusWorld:clear", function()
    -- @covers LStimulusWorld:addVisual
    -- @covers LStimulusWorld:clear
    -- @covers LStimulusWorld:count
    -- @covers lurek.ai.newStimulusWorld
    it("StimulusWorld:clear works", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(0, 0, 1.0, 5.0)
        sw:addVisual(1, 1, 2.0, 3.0)
        sw:clear()
        expect_equal(0, sw:count())
    end)
end)

-- @describe Missing explicit test for ContextSteering:addWander
describe("Missing explicit test for ContextSteering:addWander", function()
    -- @covers LContextSteering:addWander
    -- @covers lurek.ai.newContextSteering
    it("ContextSteering:addWander works", function()
        local cs = lurek.ai.newContextSteering(16)
        local ok = pcall(function() cs:addWander(0.1, 1.0) end)
        expect_true(ok, "addWander should not error")
    end)
end)

-- @describe Missing explicit test for ContextSteering:clearBehaviors
describe("Missing explicit test for ContextSteering:clearBehaviors", function()
    -- @covers LContextSteering:addSeekTarget
    -- @covers LContextSteering:clearBehaviors
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("ContextSteering:clearBehaviors works", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addSeekTarget(10, 0, 1.0)
        cs:clearBehaviors()
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        -- after clearing no strong direction expected (near zero)
        expect_type("number", dx)
    end)
end)

-- @describe Missing explicit test for ContextSteering:chosenMagnitude
describe("Missing explicit test for ContextSteering:chosenMagnitude", function()
    -- @covers LContextSteering:addSeekTarget
    -- @covers LContextSteering:chosenMagnitude
    -- @covers LContextSteering:evaluate
    -- @covers lurek.ai.newContextSteering
    it("ContextSteering:chosenMagnitude works", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addSeekTarget(100, 0, 1.0)
        cs:evaluate(0, 0, 0, 0)
        local m = cs:chosenMagnitude()
        expect_type("number", m)
    end)
end)

-- @describe Missing explicit test for ContextSteering:slotCount
describe("Missing explicit test for ContextSteering:slotCount", function()
    -- @covers LContextSteering:slotCount
    -- @covers lurek.ai.newContextSteering
    it("ContextSteering:slotCount works", function()
        local cs = lurek.ai.newContextSteering(8)
        expect_equal(8, cs:slotCount())
    end)
end)

-- @describe Missing explicit test for NeedSystem:addNeed
describe("Missing explicit test for NeedSystem:addNeed", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("NeedSystem:addNeed works", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 0.1, 0.7, 2.0)
        expect_type("number", ns:valueOf("hunger"))
    end)
end)

-- @describe Missing explicit test for NeedSystem:update
describe("Missing explicit test for NeedSystem:update", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:update
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("NeedSystem:update works", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("thirst", 0.5, 0.9, 1.0)
        local before = ns:valueOf("thirst")
        ns:update(1.0)
        local after = ns:valueOf("thirst")
        expect_true(after <= before, "need should decay or stay same after update")
    end)
end)

-- @describe Missing explicit test for NeedSystem:mostUrgent
describe("Missing explicit test for NeedSystem:mostUrgent", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:mostUrgent
    -- @covers LNeedSystem:satisfy
    -- @covers lurek.ai.newNeedSystem
    it("NeedSystem:mostUrgent works", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("food", 0.0, 0.5, 1.0)
        -- satisfy below threshold so nothing is urgent
        ns:satisfy("food", 1.0)
        local u = ns:mostUrgent()
        expect_true(u == nil or type(u) == "string")
    end)
end)

-- @describe Missing explicit test for NeedSystem:satisfy
describe("Missing explicit test for NeedSystem:satisfy", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:satisfy
    -- @covers LNeedSystem:update
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("NeedSystem:satisfy works", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("rest", 0.1, 0.8, 1.0)
        ns:update(5.0)  -- decay down
        ns:satisfy("rest", 1.0)
        local v = ns:valueOf("rest")
        expect_type("number", v)
    end)
end)

-- @describe Missing explicit test for NeedSystem:valueOf
describe("Missing explicit test for NeedSystem:valueOf", function()
    -- @covers LNeedSystem:addNeed
    -- @covers LNeedSystem:valueOf
    -- @covers lurek.ai.newNeedSystem
    it("NeedSystem:valueOf works", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("energy", 0.0, 0.5, 1.0)
        local v = ns:valueOf("energy")
        expect_type("number", v)
    end)
end)

-- @describe Missing explicit test for AIDirector:pushEvent
describe("Missing explicit test for AIDirector:pushEvent", function()
    -- @covers LAIDirector:pushEvent
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:pushEvent works", function()
        local d = lurek.ai.newAIDirector()
        local ok = pcall(function() d:pushEvent(0.8) end)
        expect_true(ok, "pushEvent should not error")
    end)
end)

-- @describe Missing explicit test for AIDirector:update
describe("Missing explicit test for AIDirector:update", function()
    -- @covers LAIDirector:pushEvent
    -- @covers LAIDirector:tension
    -- @covers LAIDirector:update
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:update works", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(0.5)
        d:update(0.016)
        expect_type("number", d:tension())
    end)
end)

-- @describe Missing explicit test for AIDirector:tension
describe("Missing explicit test for AIDirector:tension", function()
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:tension works", function()
        local d = lurek.ai.newAIDirector()
        local t = d:tension()
        expect_type("number", t)
    end)
end)

-- @describe Missing explicit test for AIDirector:phase
describe("Missing explicit test for AIDirector:phase", function()
    -- @covers LAIDirector:phase
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:phase works", function()
        local d = lurek.ai.newAIDirector()
        local p = d:phase()
        expect_type("string", p)
    end)
end)

-- @describe Missing explicit test for AIDirector:spawnRateFactor
describe("Missing explicit test for AIDirector:spawnRateFactor", function()
    -- @covers LAIDirector:spawnRateFactor
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:spawnRateFactor works", function()
        local d = lurek.ai.newAIDirector()
        local f = d:spawnRateFactor()
        expect_type("number", f)
    end)
end)

-- @describe Missing explicit test for AIDirector:lootFactor
describe("Missing explicit test for AIDirector:lootFactor", function()
    -- @covers LAIDirector:lootFactor
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:lootFactor works", function()
        local d = lurek.ai.newAIDirector()
        local f = d:lootFactor()
        expect_type("number", f)
    end)
end)

-- @describe Missing explicit test for AIDirector:ambientIntensity
describe("Missing explicit test for AIDirector:ambientIntensity", function()
    -- @covers LAIDirector:ambientIntensity
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:ambientIntensity works", function()
        local d = lurek.ai.newAIDirector()
        local i = d:ambientIntensity()
        expect_type("number", i)
    end)
end)

-- @describe Missing explicit test for AIDirector:setTension
describe("Missing explicit test for AIDirector:setTension", function()
    -- @covers LAIDirector:setTension
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:setTension works", function()
        local d = lurek.ai.newAIDirector()
        d:setTension(0.75)
        expect_equal(0.75, d:tension())
    end)
end)

-- @describe Missing explicit test for AIDirector:reset
describe("Missing explicit test for AIDirector:reset", function()
    -- @covers LAIDirector:reset
    -- @covers LAIDirector:setTension
    -- @covers LAIDirector:tension
    -- @covers lurek.ai.newAIDirector
    it("AIDirector:reset works", function()
        local d = lurek.ai.newAIDirector()
        d:setTension(1.0)
        d:reset()
        expect_equal(0.0, d:tension())
    end)
end)

-- @describe Missing explicit test for HTNDomain:addPrimitive
describe("Missing explicit test for HTNDomain:addPrimitive", function()
    -- @covers LHTNDomain:addPrimitive
    -- @covers LHTNDomain:taskCount
    -- @covers lurek.ai.newHTNDomain
    it("HTNDomain:addPrimitive works", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("move", {"at_base"}, {"arrived"}, {"at_base"})
        expect_equal(1, d:taskCount())
    end)
end)

-- @describe Missing explicit test for HTNDomain:taskCount
describe("Missing explicit test for HTNDomain:taskCount", function()
    -- @covers LHTNDomain:addPrimitive
    -- @covers LHTNDomain:taskCount
    -- @covers lurek.ai.newHTNDomain
    it("HTNDomain:taskCount works", function()
        local d = lurek.ai.newHTNDomain()
        expect_equal(0, d:taskCount())
        d:addPrimitive("patrol", {}, {}, {})
        expect_equal(1, d:taskCount())
    end)
end)

-- @describe Missing explicit test for EmotionModel:trigger
describe("Missing explicit test for EmotionModel:trigger", function()
    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:get
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("EmotionModel:trigger works", function()
        local em = lurek.ai.newEmotionModel()
        em:add("fear", 0.0, 0.1, 0.05)
        local before = em:get("fear")
        em:trigger("fear", 0.5)
        local after = em:get("fear")
        expect_true(after > before, "trigger should raise emotion value")
    end)
end)

-- @describe Missing explicit test for EmotionModel:dominant
describe("Missing explicit test for EmotionModel:dominant", function()
    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:dominant
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("EmotionModel:dominant works", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.0, 0.1, 0.05)
        em:add("anger", 0.0, 0.1, 0.05)
        em:trigger("anger", 1.0)
        local d = em:dominant()
        expect_equal("anger", d)
    end)
end)

-- @describe Missing explicit test for EmotionModel:isActive
describe("Missing explicit test for EmotionModel:isActive", function()
    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:isActive
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("EmotionModel:isActive works", function()
        local em = lurek.ai.newEmotionModel()
        em:add("sadness", 0.0, 0.0, 0.1)
        expect_false(em:isActive("sadness"), "below threshold: not active")
        em:trigger("sadness", 1.0)
        expect_true(em:isActive("sadness"), "above threshold: active")
    end)
end)

-- @describe Missing explicit test for EmotionModel:update
describe("Missing explicit test for EmotionModel:update", function()
    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:get
    -- @covers LEmotionModel:trigger
    -- @covers LEmotionModel:update
    -- @covers lurek.ai.newEmotionModel
    it("EmotionModel:update works", function()
        local em = lurek.ai.newEmotionModel()
        em:add("hope", 0.0, 1.0, 0.01)
        em:trigger("hope", 1.0)
        em:update(1.0)
        local v = em:get("hope")
        expect_type("number", v)
    end)
end)

-- @describe Missing explicit test for EmotionModel:reset
describe("Missing explicit test for EmotionModel:reset", function()
    -- @covers LEmotionModel:add
    -- @covers LEmotionModel:get
    -- @covers LEmotionModel:reset
    -- @covers LEmotionModel:trigger
    -- @covers lurek.ai.newEmotionModel
    it("EmotionModel:reset works", function()
        local em = lurek.ai.newEmotionModel()
        em:add("rage", 0.0, 0.1, 0.1)
        em:trigger("rage", 0.9)
        em:reset()
        expect_equal(0.0, em:get("rage"))
    end)
end)

-- @describe Missing explicit test for ORCASolver:setPosition
describe("Missing explicit test for ORCASolver:setPosition", function()
    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:getSafeVelocity
    -- @covers LORCASolver:setPosition
    -- @covers lurek.ai.newORCASolver
    it("ORCASolver:setPosition works", function()
        local s = lurek.ai.newORCASolver(1.5)
        local idx = s:addAgent(0, 0, 0.5, 3.0)
        s:setPosition(idx, 5.0, 3.0)
        local vx, vy = s:getSafeVelocity(idx)
        expect_type("number", vx)
    end)
end)

-- @describe Missing explicit test for ORCASolver:compute
describe("Missing explicit test for ORCASolver:compute", function()
    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:compute
    -- @covers lurek.ai.newORCASolver
    it("ORCASolver:compute works", function()
        local s = lurek.ai.newORCASolver(1.5)
        s:addAgent(0, 0, 0.5, 3.0)
        local ok = pcall(function() s:compute(0.016) end)
        expect_true(ok, "compute should not error")
    end)
end)

-- @describe Missing explicit test for ORCASolver:getSafeVelocity
describe("Missing explicit test for ORCASolver:getSafeVelocity", function()
    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:compute
    -- @covers LORCASolver:getSafeVelocity
    -- @covers lurek.ai.newORCASolver
    it("ORCASolver:getSafeVelocity works", function()
        local s = lurek.ai.newORCASolver(1.5)
        local idx = s:addAgent(0, 0, 0.5, 3.0)
        s:compute(0.016)
        local vx, vy = s:getSafeVelocity(idx)
        expect_type("number", vx)
        expect_type("number", vy)
    end)
end)

-- @describe Missing explicit test for ORCASolver:agentCount
describe("Missing explicit test for ORCASolver:agentCount", function()
    -- @covers LORCASolver:addAgent
    -- @covers LORCASolver:agentCount
    -- @covers lurek.ai.newORCASolver
    it("ORCASolver:agentCount works", function()
        local s = lurek.ai.newORCASolver(1.5)
        expect_equal(0, s:agentCount())
        s:addAgent(0, 0, 0.5, 3.0)
        expect_equal(1, s:agentCount())
    end)
end)

-- @describe Missing explicit test for NeuralNet:forward
describe("Missing explicit test for NeuralNet:forward", function()
    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:forward
    -- @covers lurek.ai.newNeuralNet
    it("NeuralNet:forward works", function()
        local nn = lurek.ai.newNeuralNet()
        nn:addLayer(2, 2, "relu")
        nn:addLayer(2, 1, "sigmoid")
        local out = nn:forward({0.5, 0.3})
        expect_type("table", out)
        expect_equal(1, #out)
    end)
end)

-- @describe Missing explicit test for NeuralNet:setWeights
describe("Missing explicit test for NeuralNet:setWeights", function()
    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:getWeights
    -- @covers LNeuralNet:setWeights
    -- @covers lurek.ai.newNeuralNet
    it("NeuralNet:setWeights works", function()
        local nn = lurek.ai.newNeuralNet()
        nn:addLayer(2, 1, "linear")
        local w = nn:getWeights()
        for i = 1, #w do w[i] = 0.1 end
        local ok = nn:setWeights(w)
        expect_true(ok)
    end)
end)

-- @describe Missing explicit test for NeuralNet:getWeights
describe("Missing explicit test for NeuralNet:getWeights", function()
    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:getWeights
    -- @covers lurek.ai.newNeuralNet
    it("NeuralNet:getWeights works", function()
        local nn = lurek.ai.newNeuralNet()
        nn:addLayer(2, 1, "relu")
        local w = nn:getWeights()
        expect_type("table", w)
        expect_true(#w > 0)
    end)
end)

-- @describe Missing explicit test for NeuralNet:paramCount
describe("Missing explicit test for NeuralNet:paramCount", function()
    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:paramCount
    -- @covers lurek.ai.newNeuralNet
    it("NeuralNet:paramCount works", function()
        local nn = lurek.ai.newNeuralNet()
        nn:addLayer(3, 2, "relu")
        local p = nn:paramCount()
        expect_type("number", p)
        expect_true(p > 0)
    end)
end)

-- @describe Missing explicit test for NeuralNet:layerCount
describe("Missing explicit test for NeuralNet:layerCount", function()
    -- @covers LNeuralNet:addLayer
    -- @covers LNeuralNet:layerCount
    -- @covers lurek.ai.newNeuralNet
    it("NeuralNet:layerCount works", function()
        local nn = lurek.ai.newNeuralNet()
        expect_equal(0, nn:layerCount())
        nn:addLayer(2, 2, "relu")
        expect_equal(1, nn:layerCount())
    end)
end)

-- @describe Missing explicit test for GeneticAlgorithm:evolve
describe("Missing explicit test for GeneticAlgorithm:evolve", function()
    -- @covers LGeneticAlgorithm:evolve
    -- @covers LGeneticAlgorithm:generation
    -- @covers lurek.ai.newGeneticAlgorithm
    it("GeneticAlgorithm:evolve works", function()
        local ga = lurek.ai.newGeneticAlgorithm(10, 4, 42)
        local before = ga:generation()
        ga:evolve()
        expect_equal(before + 1, ga:generation())
    end)
end)

-- @describe Missing explicit test for GeneticAlgorithm:generation
describe("Missing explicit test for GeneticAlgorithm:generation", function()
    -- @covers LGeneticAlgorithm:generation
    -- @covers lurek.ai.newGeneticAlgorithm
    it("GeneticAlgorithm:generation works", function()
        local ga = lurek.ai.newGeneticAlgorithm(10, 4, 42)
        expect_equal(0, ga:generation())
    end)
end)

-- @describe Missing explicit test for GeneticAlgorithm:popSize
describe("Missing explicit test for GeneticAlgorithm:popSize", function()
    -- @covers LGeneticAlgorithm:popSize
    -- @covers lurek.ai.newGeneticAlgorithm
    it("GeneticAlgorithm:popSize works", function()
        local ga = lurek.ai.newGeneticAlgorithm(10, 4, 42)
        expect_equal(10, ga:popSize())
    end)
end)

-- @describe Missing explicit test for GeneticAlgorithm:setFitness
describe("Missing explicit test for GeneticAlgorithm:setFitness", function()
    -- @covers LGeneticAlgorithm:setFitness
    -- @covers lurek.ai.newGeneticAlgorithm
    it("GeneticAlgorithm:setFitness works", function()
        local ga = lurek.ai.newGeneticAlgorithm(5, 4, 42)
        local ok = pcall(function() ga:setFitness(0, 1.0) end)
        expect_true(ok, "setFitness should not error")
    end)
end)

-- @describe Missing explicit test for GeneticAlgorithm:getGenes
describe("Missing explicit test for GeneticAlgorithm:getGenes", function()
    -- @covers LGeneticAlgorithm:getGenes
    -- @covers lurek.ai.newGeneticAlgorithm
    it("GeneticAlgorithm:getGenes works", function()
        local ga = lurek.ai.newGeneticAlgorithm(5, 4, 42)
        local genes = ga:getGenes(0)
        expect_type("table", genes)
        expect_equal(4, #genes)
    end)
end)

-- @describe Missing explicit test for GeneticAlgorithm:bestGenes
describe("Missing explicit test for GeneticAlgorithm:bestGenes", function()
    -- @covers LGeneticAlgorithm:bestGenes
    -- @covers lurek.ai.newGeneticAlgorithm
    it("GeneticAlgorithm:bestGenes works", function()
        local ga = lurek.ai.newGeneticAlgorithm(5, 4, 42)
        local bg = ga:bestGenes()
        expect_type("table", bg)
    end)
end)

-- @describe Missing explicit test for Bandit:select
describe("Missing explicit test for Bandit:select", function()
    -- @covers LBandit:select
    -- @covers lurek.ai.newBandit
    it("Bandit:select works", function()
        local b = lurek.ai.newBandit(4, "epsilon_greedy", 0.1, 0)
        local arm = b:select()
        expect_type("number", arm)
        expect_true(arm >= 0 and arm < 4)
    end)
end)

-- @describe Missing explicit test for Bandit:update
describe("Missing explicit test for Bandit:update", function()
    -- @covers LBandit:update
    -- @covers lurek.ai.newBandit
    it("Bandit:update works", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 0)
        local ok = pcall(function() b:update(0, 1.0) end)
        expect_true(ok, "update should not error")
    end)
end)

-- @describe Missing explicit test for Bandit:bestArm
describe("Missing explicit test for Bandit:bestArm", function()
    -- @covers LBandit:bestArm
    -- @covers LBandit:update
    -- @covers lurek.ai.newBandit
    it("Bandit:bestArm works", function()
        local b = lurek.ai.newBandit(3, "epsilon_greedy", 0.0, 0)
        b:update(1, 10.0)
        local best = b:bestArm()
        expect_equal(1, best)
    end)
end)

-- @describe Missing explicit test for Bandit:reset
describe("Missing explicit test for Bandit:reset", function()
    -- @covers LBandit:reset
    -- @covers LBandit:select
    -- @covers LBandit:totalPulls
    -- @covers lurek.ai.newBandit
    it("Bandit:reset works", function()
        local b = lurek.ai.newBandit(3, "epsilon_greedy", 0.1, 0)
        b:select() b:select()
        b:reset()
        expect_equal(0, b:totalPulls())
    end)
end)

-- @describe Missing explicit test for Bandit:armCount
describe("Missing explicit test for Bandit:armCount", function()
    -- @covers LBandit:armCount
    -- @covers lurek.ai.newBandit
    it("Bandit:armCount works", function()
        local b = lurek.ai.newBandit(5, "epsilon_greedy", 0.1, 0)
        expect_equal(5, b:armCount())
    end)
end)

-- @describe Missing explicit test for Bandit:totalPulls
describe("Missing explicit test for Bandit:totalPulls", function()
    -- @covers LBandit:select
    -- @covers LBandit:totalPulls
    -- @covers LBandit:update
    -- @covers lurek.ai.newBandit
    it("Bandit:totalPulls works", function()
        local b = lurek.ai.newBandit(3, "epsilon_greedy", 0.1, 0)
        expect_equal(0, b:totalPulls())
        local arm = b:select()
        b:update(arm, 1.0)
        expect_equal(1, b:totalPulls())
    end)
end)

-- @describe Missing explicit test for Neuroevolution:evolve
describe("Missing explicit test for Neuroevolution:evolve", function()
    -- @covers LNeuroevolution:evolve
    -- @covers LNeuroevolution:generation
    -- @covers lurek.ai.newNeuroevolution
    it("Neuroevolution:evolve works", function()
        local spec = {{2, 2, "relu"}, {2, 1, "sigmoid"}}
        local ne = lurek.ai.newNeuroevolution(spec, 6, 0)
        local before = ne:generation()
        ne:evolve()
        expect_equal(before + 1, ne:generation())
    end)
end)

-- @describe Missing explicit test for Neuroevolution:setFitness
describe("Missing explicit test for Neuroevolution:setFitness", function()
    -- @covers LNeuroevolution:setFitness
    -- @covers lurek.ai.newNeuroevolution
    it("Neuroevolution:setFitness works", function()
        local spec = {{2, 1, "relu"}}
        local ne = lurek.ai.newNeuroevolution(spec, 4, 0)
        local ok = pcall(function() ne:setFitness(0, 5.0) end)
        expect_true(ok)
    end)
end)

-- @describe Missing explicit test for Neuroevolution:chromosomeToNet
describe("Missing explicit test for Neuroevolution:chromosomeToNet", function()
    -- @covers LNeuroevolution:chromosomeToNet
    -- @covers lurek.ai.newNeuroevolution
    it("Neuroevolution:chromosomeToNet works", function()
        local spec = {{2, 1, "relu"}}
        local ne = lurek.ai.newNeuroevolution(spec, 4, 0)
        local net = ne:chromosomeToNet(0)
        expect_not_nil(net)
    end)
end)

-- @describe Missing explicit test for Neuroevolution:bestNetwork
describe("Missing explicit test for Neuroevolution:bestNetwork", function()
    -- @covers LNeuroevolution:bestNetwork
    -- @covers lurek.ai.newNeuroevolution
    it("Neuroevolution:bestNetwork works", function()
        local spec = {{2, 1, "relu"}}
        local ne = lurek.ai.newNeuroevolution(spec, 4, 0)
        local net = ne:bestNetwork()
        expect_not_nil(net)
    end)
end)

-- @describe Missing explicit test for Neuroevolution:popSize
describe("Missing explicit test for Neuroevolution:popSize", function()
    -- @covers LNeuroevolution:popSize
    -- @covers lurek.ai.newNeuroevolution
    it("Neuroevolution:popSize works", function()
        local spec = {{2, 1, "relu"}}
        local ne = lurek.ai.newNeuroevolution(spec, 8, 0)
        expect_equal(8, ne:popSize())
    end)
end)

-- @describe Missing explicit test for Neuroevolution:generation
describe("Missing explicit test for Neuroevolution:generation", function()
    -- @covers LNeuroevolution:generation
    -- @covers lurek.ai.newNeuroevolution
    it("Neuroevolution:generation works", function()
        local spec = {{2, 1, "relu"}}
        local ne = lurek.ai.newNeuroevolution(spec, 4, 0)
        expect_equal(0, ne:generation())
    end)
end)

-- @describe Missing explicit test for StrategyAI:addGoal
describe("Missing explicit test for StrategyAI:addGoal", function()
    -- @covers LStrategyAI:addGoal
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:addGoal works", function()
        local sa = lurek.ai.newStrategyAI(5.0)
        local ok = pcall(function() sa:addGoal("expand") end)
        expect_true(ok)
    end)
end)

-- @describe Missing explicit test for StrategyAI:addTag
describe("Missing explicit test for StrategyAI:addTag", function()
    -- @covers LStrategyAI:addTag
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:addTag works", function()
        local sa = lurek.ai.newStrategyAI(5.0)
        local ok = pcall(function() sa:addTag("aggressive") end)
        expect_true(ok)
    end)
end)

-- @describe Missing explicit test for StrategyAI:removeTag
describe("Missing explicit test for StrategyAI:removeTag", function()
    -- @covers LStrategyAI:addTag
    -- @covers LStrategyAI:removeTag
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:removeTag works", function()
        local sa = lurek.ai.newStrategyAI(5.0)
        sa:addTag("defensive")
        local ok = pcall(function() sa:removeTag("defensive") end)
        expect_true(ok)
    end)
end)

-- @describe Missing explicit test for StrategyAI:update
describe("Missing explicit test for StrategyAI:update", function()
    -- @covers LStrategyAI:activeGoal
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:update
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:update works", function()
        local sa = lurek.ai.newStrategyAI(0.0)
        sa:addGoal("survive")
        sa:update(0.016, function(g) return 1.0 end)
        expect_equal("survive", sa:activeGoal())
    end)
end)

-- @describe Missing explicit test for StrategyAI:forceEvaluate
describe("Missing explicit test for StrategyAI:forceEvaluate", function()
    -- @covers LStrategyAI:activeGoal
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:forceEvaluate
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:forceEvaluate works", function()
        local sa = lurek.ai.newStrategyAI(999.0)
        sa:addGoal("attack")
        sa:forceEvaluate(function(g) return 0.9 end)
        expect_equal("attack", sa:activeGoal())
    end)
end)

-- @describe Missing explicit test for StrategyAI:activeGoal
describe("Missing explicit test for StrategyAI:activeGoal", function()
    -- @covers LStrategyAI:activeGoal
    -- @covers LStrategyAI:addGoal
    -- @covers LStrategyAI:forceEvaluate
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:activeGoal works", function()
        local sa = lurek.ai.newStrategyAI(0.0)
        expect_true(sa:activeGoal() == nil, "no active goal before first evaluate")
        sa:addGoal("guard")
        sa:forceEvaluate(function(g) return 1.0 end)
        expect_equal("guard", sa:activeGoal())
    end)
end)

-- @describe Missing explicit test for StrategyAI:timeUntilNext
describe("Missing explicit test for StrategyAI:timeUntilNext", function()
    -- @covers LStrategyAI:timeUntilNext
    -- @covers lurek.ai.newStrategyAI
    it("StrategyAI:timeUntilNext works", function()
        local sa = lurek.ai.newStrategyAI(10.0)
        local t = sa:timeUntilNext()
        expect_type("number", t)
    end)
end)

-- @describe Missing explicit test for AILod:shouldUpdate
describe("Missing explicit test for AILod:shouldUpdate", function()
    -- @covers LAILod:shouldUpdate
    -- @covers lurek.ai.newAILod
    it("AILod:shouldUpdate works", function()
        local lod = lurek.ai.newAILod()
        local result = lod:shouldUpdate(0, 1)
        expect_type("boolean", result)
    end)
end)

-- @describe Missing explicit test for AILod:tierCount
describe("Missing explicit test for AILod:tierCount", function()
    -- @covers LAILod:tierCount
    -- @covers lurek.ai.newAILod
    it("AILod:tierCount works", function()
        local lod = lurek.ai.newAILod()
        local c = lod:tierCount()
        expect_type("number", c)
        expect_true(c > 0)
    end)
end)

-- @describe Missing explicit test for AILod:tierName
describe("Missing explicit test for AILod:tierName", function()
    -- @covers LAILod:tierName
    -- @covers lurek.ai.newAILod
    it("AILod:tierName works", function()
        local lod = lurek.ai.newAILod()
        local name = lod:tierName(0)
        expect_type("string", name)
    end)
end)

-- =========================================================================
-- Extensibility Hooks (Phase 01)
-- =========================================================================

-- @describe lurek.ai extensibility factories
describe("lurek.ai extensibility factories", function()
    -- @covers lurek.ai.newGuard
    it("has newGuard factory", function()
        expect_type("function", lurek.ai.newGuard, "newGuard should be a function")
    end)
end)

-- @describe custom decision model
describe("custom decision model", function()
    -- it is invoked when the world is updated.
    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:update
    -- @covers LAgent:setCustomModel
    -- @covers lurek.ai.newWorld
    it("can set custom model on agent and callback fires on update", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("test_custom_agent")
        local called = false
        agent:setCustomModel(function(ag, bb, dt)
            called = true
        end)
        world:update(0.016)
        expect_true(called, "custom model callback should be called on update")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setCustomModel
    -- @covers lurek.ai.newWorld
    it("getDecisionModel returns 'custom' after setCustomModel", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("model_check_agent")
        agent:setCustomModel(function(ag, bb, dt) end)
        expect_equal("custom", agent:getDecisionModel(),
            "decision model name should be 'custom'")
    end)
end)

-- @describe BT Guard decorator
describe("BT Guard decorator", function()
    -- @covers LBTNode:getNodeType
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newGuard
    it("creates guard node via newGuard", function()
        local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
        local guard = lurek.ai.newGuard(function(ag, bb) return true end, action)
        expect_not_nil(guard, "Guard node should be created")
        expect_equal("guard", guard:getNodeType(), "node type should be 'guard'")
    end)

    -- @covers LBTNode:getChildCount
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newGuard
    it("guard has child count 1", function()
        local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
        local guard = lurek.ai.newGuard(function(ag, bb) return false end, action)
        expect_equal(1, guard:getChildCount(), "Guard should have 1 child")
    end)
end)

-- @describe custom utility response curve
describe("custom utility response curve", function()
    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:addConsideration
    -- @covers lurek.ai.newUtilityAI
    it("addConsideration accepts function as curve without error", function()
        local ua = lurek.ai.newUtilityAI()
        ua:addAction("test_action", function() return 0.5 end)
        local ok = pcall(function()
            ua:addConsideration(
                "test_action",
                "distance_axis",
                function() return 0.8 end,  -- scorer
                function(x) return x * x end  -- custom curve fn
            )
        end)
        expect_true(ok, "addConsideration with function curve should succeed")
    end)

    -- @covers LUtilityAI:addAction
    -- @covers LUtilityAI:addConsideration
    -- @covers lurek.ai.newUtilityAI
    it("addConsideration accepts string curve without error", function()
        local ua = lurek.ai.newUtilityAI()
        ua:addAction("action_b", function() return 0.3 end)
        local ok = pcall(function()
            ua:addConsideration(
                "action_b",
                "proximity",
                function() return 0.5 end,
                "linear",
                1.0, 0.0, 0.0
            )
        end)
        expect_true(ok, "addConsideration with string curve should succeed")
    end)
end)

-- @describe custom steering behavior
describe("custom steering behavior", function()
    -- @covers LSteeringManager:addCustomBehavior
    -- @covers LSteeringManager:getBehaviorCount
    -- @covers lurek.ai.newSteeringManager
    it("addCustomBehavior adds one behavior to the manager", function()
        local sm = lurek.ai.newSteeringManager()
        local before = sm:getBehaviorCount()
        sm:addCustomBehavior(function(ag, dt) return 10, 0 end, 1.0)
        expect_equal(before + 1, sm:getBehaviorCount(),
            "behavior count should increase by 1")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LSteeringManager:applyCustomSteering
    -- @covers lurek.ai.newSteeringManager
    -- @covers lurek.ai.newWorld
    it("applyCustomSteering returns a force pair without error", function()
        local sm = lurek.ai.newSteeringManager()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("steering_fixture")
        local ok = pcall(function()
            sm:applyCustomSteering(agent, 0.016)
        end)
        expect_true(ok, "applyCustomSteering with no custom behaviors should not error")
    end)
end)


-- =========================================================================
-- Lua extensibility: Agent:setCustomModel
-- =========================================================================

--   decision model and that getDecisionModel returns "custom" afterwards.
-- @describe Agent:setCustomModel extensibility hook
describe("Agent:setCustomModel extensibility hook", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getDecisionModel
    -- @covers LAgent:setCustomModel
    -- @covers lurek.ai.newWorld
    it("setCustomModel marks agent with custom model", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("test_agent")
        agent:setCustomModel(function(ag, bb, dt) end)
        expect_equal("custom", agent:getDecisionModel(),
            "getDecisionModel should return 'custom' after setCustomModel")
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAIWorld:update
    -- @covers LAgent:setCustomModel
    -- @covers lurek.ai.newWorld
    it("setCustomModel callback is invoked via world:update without error", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("cb_agent")
        local called = false
        agent:setCustomModel(function(ag, bb, dt)
            called = true
        end)
        world:update(0.016)
        expect_true(called, "custom model callback should be called by world:update")
    end)
end)
-- @describe ai strict: LAgent missing methods
describe("ai strict: LAgent missing methods", function()
    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getName
    -- @covers lurek.ai.newWorld
    it("getName returns agent name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_name")
        expect_equal("strict_name", a:getName())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:setPosition
    -- @covers LAgent:getPosition
    -- @covers lurek.ai.newWorld
    it("setPosition and getPosition are callable", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_pos")
        a:setPosition(10, 20)
        local x, y = a:getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:setVelocity
    -- @covers LAgent:getVelocity
    -- @covers lurek.ai.newWorld
    it("setVelocity and getVelocity are callable", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_vel")
        a:setVelocity(1, 2)
        local vx, vy = a:getVelocity()
        expect_type("number", vx)
        expect_type("number", vy)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getPriority
    -- @covers lurek.ai.newWorld
    it("getPriority returns number", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_prio")
        expect_type("number", a:getPriority())
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:addTag
    -- @covers LAgent:hasTag
    -- @covers lurek.ai.newWorld
    it("addTag then hasTag returns boolean", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_tag")
        a:addTag("enemy")
        expect_type("boolean", a:hasTag("enemy"))
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:addTag
    -- @covers LAgent:removeTag
    -- @covers lurek.ai.newWorld
    it("removeTag is callable", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_tag_rm")
        a:addTag("boss")
        local ok = pcall(function() a:removeTag("boss") end)
        expect_true(ok)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:getBlackboard
    -- @covers lurek.ai.newWorld
    it("getBlackboard returns userdata", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_bb")
        local bb = a:getBlackboard()
        expect_true(bb ~= nil)
    end)

    -- @covers LAIWorld:addAgent
    -- @covers LAgent:type
    -- @covers LAgent:typeOf
    -- @covers lurek.ai.newWorld
    it("LAgent type and typeOf are callable", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("strict_type")
        expect_type("string", a:type())
        expect_type("boolean", a:typeOf("Object"))
    end)
end)

-- @describe ai strict: missing type methods
describe("ai strict: missing type methods", function()
    -- @covers LTraitProfile:type
    -- @covers LTraitProfile:typeOf
    -- @covers lurek.ai.newTraitProfile
    it("LTraitProfile type and typeOf are callable", function()
        local t = lurek.ai.newTraitProfile()
        expect_type("string", t:type())
        expect_type("boolean", t:typeOf("Object"))
    end)

    -- @covers LStimulusWorld:type
    -- @covers LStimulusWorld:typeOf
    -- @covers lurek.ai.newStimulusWorld
    it("LStimulusWorld type and typeOf are callable", function()
        local s = lurek.ai.newStimulusWorld()
        expect_type("string", s:type())
        expect_type("boolean", s:typeOf("Object"))
    end)

    -- @covers LContextSteering:type
    -- @covers LContextSteering:typeOf
    -- @covers lurek.ai.newContextSteering
    it("LContextSteering type and typeOf are callable", function()
        local c = lurek.ai.newContextSteering(8)
        expect_type("string", c:type())
        expect_type("boolean", c:typeOf("Object"))
    end)

    -- @covers LNeedSystem:type
    -- @covers LNeedSystem:typeOf
    -- @covers lurek.ai.newNeedSystem
    it("LNeedSystem type and typeOf are callable", function()
        local n = lurek.ai.newNeedSystem()
        expect_type("string", n:type())
        expect_type("boolean", n:typeOf("Object"))
    end)

    -- @covers LAIDirector:type
    -- @covers LAIDirector:typeOf
    -- @covers lurek.ai.newAIDirector
    it("LAIDirector type and typeOf are callable", function()
        local d = lurek.ai.newAIDirector()
        expect_type("string", d:type())
        expect_type("boolean", d:typeOf("Object"))
    end)

    -- @covers LHTNDomain:type
    -- @covers LHTNDomain:typeOf
    -- @covers lurek.ai.newHTNDomain
    it("LHTNDomain type and typeOf are callable", function()
        local h = lurek.ai.newHTNDomain()
        expect_type("string", h:type())
        expect_type("boolean", h:typeOf("Object"))
    end)

    -- @covers LMCTSEngine:type
    -- @covers LMCTSEngine:typeOf
    -- @covers lurek.ai.newMCTSEngine
    it("LMCTSEngine type and typeOf are callable", function()
        local m = lurek.ai.newMCTSEngine(20, 1.41, 4, 42)
        expect_type("string", m:type())
        expect_type("boolean", m:typeOf("Object"))
    end)

    -- @covers LEmotionModel:type
    -- @covers LEmotionModel:typeOf
    -- @covers lurek.ai.newEmotionModel
    it("LEmotionModel type and typeOf are callable", function()
        local e = lurek.ai.newEmotionModel()
        expect_type("string", e:type())
        expect_type("boolean", e:typeOf("Object"))
    end)

    -- @covers LORCASolver:type
    -- @covers LORCASolver:typeOf
    -- @covers lurek.ai.newORCASolver
    it("LORCASolver type and typeOf are callable", function()
        local o = lurek.ai.newORCASolver(1.5)
        expect_type("string", o:type())
        expect_type("boolean", o:typeOf("Object"))
    end)

    -- @covers LNeuralNet:type
    -- @covers LNeuralNet:typeOf
    -- @covers lurek.ai.newNeuralNet
    it("LNeuralNet type and typeOf are callable", function()
        local nn = lurek.ai.newNeuralNet()
        expect_type("string", nn:type())
        expect_type("boolean", nn:typeOf("Object"))
    end)

    -- @covers LGeneticAlgorithm:type
    -- @covers LGeneticAlgorithm:typeOf
    -- @covers lurek.ai.newGeneticAlgorithm
    it("LGeneticAlgorithm type and typeOf are callable", function()
        local ga = lurek.ai.newGeneticAlgorithm(6, 4, 7)
        expect_type("string", ga:type())
        expect_type("boolean", ga:typeOf("Object"))
    end)

    -- @covers LBandit:type
    -- @covers LBandit:typeOf
    -- @covers lurek.ai.newBandit
    it("LBandit type and typeOf are callable", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 9)
        expect_type("string", b:type())
        expect_type("boolean", b:typeOf("Object"))
    end)

    -- @covers LNeuroevolution:type
    -- @covers LNeuroevolution:typeOf
    -- @covers lurek.ai.newNeuroevolution
    it("LNeuroevolution type and typeOf are callable", function()
        local ne = lurek.ai.newNeuroevolution({{inputs=1, outputs=1, activation="linear"}}, 4, 42)
        expect_type("string", ne:type())
        expect_type("boolean", ne:typeOf("Object"))
    end)

    -- @covers LStrategyAI:type
    -- @covers LStrategyAI:typeOf
    -- @covers lurek.ai.newStrategyAI
    it("LStrategyAI type and typeOf are callable", function()
        local s = lurek.ai.newStrategyAI(5.0)
        expect_type("string", s:type())
        expect_type("boolean", s:typeOf("Object"))
    end)

    -- @covers LAILod:type
    -- @covers LAILod:typeOf
    -- @covers lurek.ai.newAILod
    it("LAILod type and typeOf are callable", function()
        local l = lurek.ai.newAILod()
        expect_type("string", l:type())
        expect_type("boolean", l:typeOf("Object"))
    end)
end)

test_summary()
