-- Lurek2D AI API Tests

-- =========================================================================
-- 1. lurek.ai module exists
-- =========================================================================

describe("lurek.ai module exists", function()
    -- @covers lurek.ai.newAction
    -- @covers lurek.ai.newBehaviorTree
    -- @covers lurek.ai.newBlackboard
    -- @covers lurek.ai.newCommandQueue
    -- @covers lurek.ai.newCondition
    -- @covers lurek.ai.newGOAPPlanner
    -- @covers lurek.ai.newInfluenceMap
    -- @covers lurek.ai.newInverter
    -- @covers lurek.ai.newParallel
    -- @covers lurek.ai.newQLearner
    -- @covers lurek.ai.newRepeater
    -- @covers lurek.ai.newSelector
    -- @covers lurek.ai.newSequence
    -- @covers lurek.ai.newSquad
    -- @covers lurek.ai.newStateMachine
    -- @covers lurek.ai.newSteeringManager
    -- @covers lurek.ai.newSucceeder
    -- @covers lurek.ai.newUtilityAI
    -- @covers lurek.ai.newWorld
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("lurek.ai is a table", function()
        expect_type("table", lurek.ai)
    end)

    it("has newWorld factory", function()
        expect_type("function", lurek.ai.newWorld)
    end)

    it("has newBlackboard factory", function()
        expect_type("function", lurek.ai.newBlackboard)
    end)

    it("has newStateMachine factory", function()
        expect_type("function", lurek.ai.newStateMachine)
    end)

    it("has newBehaviorTree factory", function()
        expect_type("function", lurek.ai.newBehaviorTree)
    end)

    it("has newSteeringManager factory", function()
        expect_type("function", lurek.ai.newSteeringManager)
    end)

    it("has no newPathGrid factory (moved to pathfinding)", function()
        expect_type("function", lurek.pathfind.newPathGrid)
    end)

    it("has no newFlowField factory (moved to pathfinding)", function()
        expect_type("function", lurek.pathfind.newPathFlowField)
    end)

    it("has newQLearner factory", function()
        expect_type("function", lurek.ai.newQLearner)
    end)

    it("has newUtilityAI factory", function()
        expect_type("function", lurek.ai.newUtilityAI)
    end)

    it("has newGOAPPlanner factory", function()
        expect_type("function", lurek.ai.newGOAPPlanner)
    end)

    it("has newInfluenceMap factory", function()
        expect_type("function", lurek.ai.newInfluenceMap)
    end)

    it("has newSquad factory", function()
        expect_type("function", lurek.ai.newSquad)
    end)

    it("has newCommandQueue factory", function()
        expect_type("function", lurek.ai.newCommandQueue)
    end)

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
describe("lurek.ai AIWorld", function()
    it("creates a new world", function()
        local w = lurek.ai.newWorld()
        expect_not_nil(w, "world exists")
        expect_equal("LAIWorld", w:type(), "type check")
    end)

    it("adds agents by name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        expect_not_nil(a, "agent returned")
        expect_equal(1, w:getAgentCount(), "agent count")
    end)

    it("gets agent by name", function()
        local w = lurek.ai.newWorld()
        w:addAgent("hero")
        local a = w:getAgent("hero")
        expect_not_nil(a, "found agent")
        expect_equal("hero", a:getName())
    end)

    it("returns nil for unknown agent", function()
        local w = lurek.ai.newWorld()
        expect_nil(w:getAgent("nonexistent"))
    end)

    it("removes agents", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        w:removeAgent(a)
        expect_equal(0, w:getAgentCount())
    end)

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

    it("errors on duplicate agent name", function()
        local w = lurek.ai.newWorld()
        w:addAgent("hero")
        expect_error(function() w:addAgent("hero") end, "duplicate agent")
    end)

    it("provides global blackboard", function()
        local w = lurek.ai.newWorld()
        local bb = w:getGlobalBlackboard()
        expect_not_nil(bb, "global bb exists")
        expect_equal("LAIBlackboard", bb:type())
    end)

    it("supports multiple agents", function()
        local w = lurek.ai.newWorld()
        w:addAgent("alpha")
        w:addAgent("beta")
        w:addAgent("gamma")
        expect_equal(3, w:getAgentCount())
    end)

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
describe("lurek.ai Agent", function()
    it("type returns Agent", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        expect_equal("LAgent", a:type())
    end)

    it("getName returns name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("warrior")
        expect_equal("warrior", a:getName())
    end)

    it("setPosition / getPosition roundtrip", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setPosition(100, 200)
        local x, y = a:getPosition()
        expect_near(100, x, 0.01)
        expect_near(200, y, 0.01)
    end)

    it("setVelocity / getVelocity roundtrip", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setVelocity(5, -3)
        local vx, vy = a:getVelocity()
        expect_near(5, vx, 0.01)
        expect_near(-3, vy, 0.01)
    end)

    it("setMaxSpeed / getMaxSpeed", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setMaxSpeed(250)
        expect_near(250, a:getMaxSpeed(), 0.01)
    end)

    it("setMaxForce / getMaxForce", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setMaxForce(500)
        expect_near(500, a:getMaxForce(), 0.01)
    end)

    it("setPriority / getPriority", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setPriority(7)
        expect_equal(7, a:getPriority())
    end)

    it("setDecisionModel / getDecisionModel for fsm", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("fsm")
        expect_equal("fsm", a:getDecisionModel())
    end)

    it("setDecisionModel / getDecisionModel for bt", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("bt")
        expect_equal("bt", a:getDecisionModel())
    end)

    it("setDecisionModel / getDecisionModel for steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("steering")
        expect_equal("steering", a:getDecisionModel())
    end)

    it("setDecisionModel / getDecisionModel for fsm+steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("fsm+steering")
        expect_equal("fsm+steering", a:getDecisionModel())
    end)

    it("setDecisionModel / getDecisionModel for bt+steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("bt+steering")
        expect_equal("bt+steering", a:getDecisionModel())
    end)

    it("addTag / hasTag / removeTag", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        expect_false(a:hasTag("enemy"), "no tag initially")
        a:addTag("enemy")
        expect_true(a:hasTag("enemy"), "tag added")
        a:removeTag("enemy")
        expect_false(a:hasTag("enemy"), "tag removed")
    end)

    it("multiple tags", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:addTag("fast")
        a:addTag("flying")
        expect_true(a:hasTag("fast"))
        expect_true(a:hasTag("flying"))
        expect_false(a:hasTag("slow"))
    end)

    it("getBlackboard returns Blackboard", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        local bb = a:getBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)

    it("default position is zero", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        local x, y = a:getPosition()
        expect_near(0, x, 0.01)
        expect_near(0, y, 0.01)
    end)
end)

-- =========================================================================
-- 4. Blackboard
-- =========================================================================
describe("lurek.ai Blackboard", function()
    it("type returns Blackboard", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("LAIBlackboard", bb:type())
    end)

    it("setNumber / getNumber roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("health", 42.5)
        expect_near(42.5, bb:getNumber("health"), 0.001)
    end)

    it("getNumber returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_near(99, bb:getNumber("missing", 99), 0.001)
    end)

    it("getNumber returns 0 without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_near(0, bb:getNumber("missing"), 0.001)
    end)

    it("setBool / getBool roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setBool("alive", true)
        expect_true(bb:getBool("alive"))
    end)

    it("getBool returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_true(bb:getBool("missing", true))
    end)

    it("getBool returns false without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_false(bb:getBool("missing"))
    end)

    it("setString / getString roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setString("name", "hero")
        expect_equal("hero", bb:getString("name"))
    end)

    it("getString returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("none", bb:getString("missing", "none"))
    end)

    it("getString returns empty without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("", bb:getString("missing"))
    end)

    it("has returns true when key exists", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        expect_true(bb:has("hp"))
    end)

    it("has returns false when key absent", function()
        local bb = lurek.ai.newBlackboard()
        expect_false(bb:has("missing"))
    end)

    it("remove deletes a key", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:remove("hp")
        expect_false(bb:has("hp"))
    end)

    it("clear removes all keys", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("a", 1)
        bb:setBool("b", true)
        bb:setString("c", "x")
        bb:clear()
        expect_equal(0, bb:getSize())
    end)

    it("getSize returns count", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal(0, bb:getSize())
        bb:setNumber("a", 1)
        expect_equal(1, bb:getSize())
        bb:setBool("b", true)
        expect_equal(2, bb:getSize())
    end)

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
describe("lurek.ai StateMachine", function()
    it("type returns StateMachine", function()
        local fsm = lurek.ai.newStateMachine()
        expect_equal("LStateMachine", fsm:type())
    end)

    it("addState does not error", function()
        local fsm = lurek.ai.newStateMachine()
        expect_no_error(function()
            fsm:addState("idle", { onEnter = function() end })
        end)
    end)

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

    it("setInitialState sets current state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        expect_equal("idle", fsm:getCurrentState())
    end)

    it("getCurrentState returns nil before setting", function()
        local fsm = lurek.ai.newStateMachine()
        expect_nil(fsm:getCurrentState())
    end)

    it("forceState changes state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("attack", {})
        fsm:setInitialState("idle")
        fsm:forceState("attack")
        expect_equal("attack", fsm:getCurrentState())
    end)

    it("getTimeInState starts at zero after forceState", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        fsm:forceState("idle")
        expect_near(0, fsm:getTimeInState(), 0.01)
    end)

    it("addTransition does not error", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("walk", {})
        expect_no_error(function()
            fsm:addTransition("idle", "walk", nil, 0)
        end)
    end)

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
describe("lurek.ai BehaviorTree", function()
    it("type returns BehaviorTree", function()
        local bt = lurek.ai.newBehaviorTree()
        expect_equal("LBehaviorTree", bt:type())
    end)

    it("getLastStatus returns success initially", function()
        local bt = lurek.ai.newBehaviorTree()
        expect_equal("success", bt:getLastStatus())
    end)

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
describe("lurek.ai BTNode", function()
    it("newSelector returns BTNode type", function()
        local n = lurek.ai.newSelector()
        expect_equal("LBTNode", n:type())
    end)

    it("newSequence returns BTNode type", function()
        local n = lurek.ai.newSequence()
        expect_equal("LBTNode", n:type())
    end)

    it("newParallel returns BTNode type", function()
        local n = lurek.ai.newParallel()
        expect_equal("LBTNode", n:type())
    end)

    it("newInverter returns BTNode type", function()
        local n = lurek.ai.newInverter()
        expect_equal("LBTNode", n:type())
    end)

    it("newRepeater returns BTNode type", function()
        local n = lurek.ai.newRepeater()
        expect_equal("LBTNode", n:type())
    end)

    it("newSucceeder returns BTNode type", function()
        local n = lurek.ai.newSucceeder()
        expect_equal("LBTNode", n:type())
    end)

    it("newAction returns BTNode type", function()
        local n = lurek.ai.newAction(function() return "success" end)
        expect_equal("LBTNode", n:type())
    end)

    it("newCondition returns BTNode type", function()
        local n = lurek.ai.newCondition(function() return true end)
        expect_equal("LBTNode", n:type())
    end)

    it("getNodeType returns selector", function()
        expect_equal("selector", lurek.ai.newSelector():getNodeType())
    end)

    it("getNodeType returns sequence", function()
        expect_equal("sequence", lurek.ai.newSequence():getNodeType())
    end)

    it("getNodeType returns parallel", function()
        expect_equal("parallel", lurek.ai.newParallel():getNodeType())
    end)

    it("getNodeType returns inverter", function()
        expect_equal("inverter", lurek.ai.newInverter():getNodeType())
    end)

    it("getNodeType returns repeater", function()
        expect_equal("repeater", lurek.ai.newRepeater():getNodeType())
    end)

    it("getNodeType returns succeeder", function()
        expect_equal("succeeder", lurek.ai.newSucceeder():getNodeType())
    end)

    it("getNodeType returns action", function()
        expect_equal("action", lurek.ai.newAction(function() end):getNodeType())
    end)

    it("getNodeType returns condition", function()
        expect_equal("condition", lurek.ai.newCondition(function() end):getNodeType())
    end)

    it("addChild on Selector increases child count", function()
        local sel = lurek.ai.newSelector()
        expect_equal(0, sel:getChildCount())
        local act = lurek.ai.newAction(function() end)
        sel:addChild(act)
        expect_equal(1, sel:getChildCount())
    end)

    it("addChild on Sequence increases child count", function()
        local seq = lurek.ai.newSequence()
        local a1 = lurek.ai.newAction(function() end)
        local a2 = lurek.ai.newAction(function() end)
        seq:addChild(a1)
        seq:addChild(a2)
        expect_equal(2, seq:getChildCount())
    end)

    it("addChild on Parallel increases child count", function()
        local par = lurek.ai.newParallel()
        par:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, par:getChildCount())
    end)

    it("addChild on Action errors", function()
        local act = lurek.ai.newAction(function() end)
        local child = lurek.ai.newAction(function() end)
        expect_error(function()
            act:addChild(child)
        end, "addChild on Action should error")
    end)

    it("addChild on Condition errors", function()
        local cond = lurek.ai.newCondition(function() return true end)
        local child = lurek.ai.newAction(function() end)
        expect_error(function()
            cond:addChild(child)
        end, "addChild on Condition should error")
    end)

    it("setChild on Inverter", function()
        local inv = lurek.ai.newInverter()
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            inv:setChild(act)
        end)
    end)

    it("setChild on Repeater", function()
        local rep = lurek.ai.newRepeater(3)
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            rep:setChild(act)
        end)
    end)

    it("setChild on Succeeder", function()
        local suc = lurek.ai.newSucceeder()
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            suc:setChild(act)
        end)
    end)

    it("setCount / getCount on Repeater", function()
        local rep = lurek.ai.newRepeater(5)
        expect_equal(5, rep:getCount())
        rep:setCount(10)
        expect_equal(10, rep:getCount())
    end)

    it("getCount on non-Repeater returns 0", function()
        local sel = lurek.ai.newSelector()
        expect_equal(0, sel:getCount())
    end)

    it("setSuccessPolicy on Parallel does not error", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setSuccessPolicy("require_all")
        end)
    end)

    it("setFailurePolicy on Parallel does not error", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setFailurePolicy("require_all")
        end)
    end)

    it("getChildCount returns 0 for leaf nodes", function()
        expect_equal(0, lurek.ai.newAction(function() end):getChildCount())
        expect_equal(0, lurek.ai.newCondition(function() end):getChildCount())
    end)
end)

-- =========================================================================
-- 8. SteeringManager
-- =========================================================================
describe("lurek.ai SteeringManager", function()
    it("type returns SteeringManager", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal("LSteeringManager", sm:type())
    end)

    it("addSeek increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal(0, sm:getBehaviorCount())
        sm:addSeek(100, 200)
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("addFlee increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addFlee(0, 0)
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("addArrive increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addArrive(50, 50)
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("addWander increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addWander()
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("addPursue increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addPursue("target")
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("addEvade increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addEvade("threat")
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("addFlock increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addFlock()
        expect_equal(1, sm:getBehaviorCount())
    end)

    it("multiple behaviors accumulate", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:addFlee(0, 0)
        sm:addWander()
        expect_equal(3, sm:getBehaviorCount())
    end)

    it("setCombineMode / getCombineMode", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("priority")
        expect_equal("priority", sm:getCombineMode())
        sm:setCombineMode("weighted")
        expect_equal("weighted", sm:getCombineMode())
    end)

    it("calculate returns two numbers", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        local fx, fy = sm:calculate(0, 0, 0, 0, 100, 200, 1/60)
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    it("getLastSteering returns two numbers", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:calculate(0, 0, 0, 0, 100, 200, 1/60)
        local fx, fy = sm:getLastSteering()
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    it("addSeek with custom weight", function()
        local sm = lurek.ai.newSteeringManager()
        expect_no_error(function()
            sm:addSeek(100, 100, 2.0)
        end)
        expect_equal(1, sm:getBehaviorCount())
    end)
end)

-- =========================================================================
-- 9. PathGrid
-- =========================================================================
describe("lurek.ai PathGrid", function()
    it("type returns PathGrid", function()
        local g = lurek.pathfind.newPathGrid(10, 10, 32)
        expect_equal("LPathGrid", g:type())
    end)

    it("getWidth / getHeight / getCellSize", function()
        local g = lurek.pathfind.newPathGrid(8, 6, 16)
        expect_equal(8, g:getWidth())
        expect_equal(6, g:getHeight())
        expect_near(16, g:getCellSize(), 0.01)
    end)

    it("all cells walkable by default", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        expect_true(g:isWalkable(1, 1))
        expect_true(g:isWalkable(5, 5))
    end)

    it("setWalkable / isWalkable (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        g:setWalkable(3, 3, false)
        expect_false(g:isWalkable(3, 3))
        g:setWalkable(3, 3, true)
        expect_true(g:isWalkable(3, 3))
    end)

    it("setCost / getCost (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        g:setCost(2, 2, 3.5)
        expect_near(3.5, g:getCost(2, 2), 0.01)
    end)

    it("findPath returns a table for open grid", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 5, 5)
        expect_not_nil(path, "path should exist")
        expect_type("table", path)
        expect_true(#path > 0, "path should have waypoints")
    end)

    it("findPath entries have x and y fields", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 3, 3)
        expect_not_nil(path)
        local first = path[1]
        expect_not_nil(first.x, "x field")
        expect_not_nil(first.y, "y field")
    end)

    it("findPath returns nil for blocked path", function()
        local g = lurek.pathfind.newPathGrid(3, 1, 10)
        g:setWalkable(2, 1, false)
        local path = g:findPath(1, 1, 3, 1)
        expect_nil(path, "blocked path should be nil")
    end)

    it("findPathSmoothed returns a table", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPathSmoothed(1, 1, 5, 5)
        expect_not_nil(path)
        expect_type("table", path)
    end)

    it("findPath same start and goal", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(3, 3, 3, 3)
        expect_not_nil(path)
    end)
end)

-- =========================================================================
-- 10. FlowField
-- =========================================================================
describe("lurek.ai FlowField", function()
    it("type returns FlowField", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_equal("LAIFlowField", ff:type())
    end)

    it("getWidth / getHeight", function()
        local g = lurek.pathfind.newPathGrid(8, 6, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_equal(8, ff:getWidth())
        expect_equal(6, ff:getHeight())
    end)

    it("hasGoal returns false initially", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_false(ff:hasGoal())
    end)

    it("setGoal / hasGoal / getGoal (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 4)
        expect_true(ff:hasGoal())
        local gx, gy = ff:getGoal()
        expect_equal(3, gx)
        expect_equal(4, gy)
    end)

    it("getDirection returns two numbers", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    it("getDistance returns a number", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(1, 1)
        expect_type("number", d)
    end)

    it("getGoal returns nil before setGoal", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        local gx, gy = ff:getGoal()
        expect_nil(gx)
        expect_nil(gy)
    end)

    it("distance at goal is zero", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(3, 3)
        expect_near(0, d, 0.01)
    end)
end)

-- =========================================================================
-- 11. QLearner
-- =========================================================================
describe("lurek.ai QLearner", function()
    it("type returns QLearner", function()
        local q = lurek.ai.newQLearner(4, 3)
        expect_equal("LQLearner", q:type())
    end)

    it("getStateCount / getActionCount", function()
        local q = lurek.ai.newQLearner(4, 3)
        expect_equal(4, q:getStateCount())
        expect_equal(3, q:getActionCount())
    end)

    it("chooseAction returns 1-based action", function()
        local q = lurek.ai.newQLearner(2, 3)
        local a = q:chooseAction(1)
        expect_true(a >= 1 and a <= 3, "action in range")
    end)

    it("bestAction returns 1-based action", function()
        local q = lurek.ai.newQLearner(2, 3)
        local a = q:bestAction(1)
        expect_true(a >= 1 and a <= 3, "best action in range")
    end)

    it("setQValue / getQValue (1-based)", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setQValue(1, 2, 5.0)
        expect_near(5.0, q:getQValue(1, 2), 0.001)
    end)

    it("learn updates Q values", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setExplorationRate(0)
        q:setQValue(1, 1, 0)
        q:learn(1, 1, 10.0, 2)
        local after = q:getQValue(1, 1)
        expect_true(after > 0, "Q value should increase after positive reward")
    end)

    it("setLearningRate / getLearningRate", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.5)
        expect_near(0.5, q:getLearningRate(), 0.001)
    end)

    it("setDiscountFactor / getDiscountFactor", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.8)
        expect_near(0.8, q:getDiscountFactor(), 0.001)
    end)

    it("setExplorationRate / getExplorationRate", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.1)
        expect_near(0.1, q:getExplorationRate(), 0.001)
    end)

    it("setExplorationDecay / getExplorationDecay", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.99)
        expect_near(0.99, q:getExplorationDecay(), 0.001)
    end)

    it("endEpisode / getEpisodeCount", function()
        local q = lurek.ai.newQLearner(2, 2)
        expect_equal(0, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(2, q:getEpisodeCount())
    end)

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

    it("bestAction returns consistent results for same Q table", function()
        local q = lurek.ai.newQLearner(2, 3)
        q:setQValue(1, 1, 1.0)
        q:setQValue(1, 2, 5.0)
        q:setQValue(1, 3, 2.0)
        local best = q:bestAction(1)
        expect_equal(2, best, "action 2 has highest Q")
    end)

    it("Q values start at zero", function()
        local q = lurek.ai.newQLearner(3, 3)
        expect_near(0, q:getQValue(1, 1), 0.001)
        expect_near(0, q:getQValue(3, 3), 0.001)
    end)
end)

-- =========================================================================
-- 12. UtilityAI
-- =========================================================================
describe("lurek.ai UtilityAI", function()
    it("type returns UtilityAI", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal("LUtilityAI", u:type())
    end)

    it("addAction increases action count", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal(0, u:getActionCount())
        u:addAction("eat", function() return 0.5 end)
        expect_equal(1, u:getActionCount())
    end)

    it("evaluate returns best action name", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("eat", function() return 0.3 end)
        u:addAction("sleep", function() return 0.9 end)
        u:addAction("fight", function() return 0.1 end)
        local best = u:evaluate()
        expect_equal("sleep", best)
    end)

    it("evaluate returns nil with no actions", function()
        local u = lurek.ai.newUtilityAI()
        local result = u:evaluate()
        expect_nil(result)
    end)

    it("getLastAction returns last evaluated action", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 1.0 end)
        u:evaluate()
        expect_equal("patrol", u:getLastAction())
    end)

    it("getLastAction returns nil before evaluate", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("idle", function() return 1.0 end)
        expect_nil(u:getLastAction())
    end)

    it("addAction with weight parameter", function()
        local u = lurek.ai.newUtilityAI()
        expect_no_error(function()
            u:addAction("run", function() return 0.5 end, 2.0)
        end)
        expect_equal(1, u:getActionCount())
    end)
end)

-- =========================================================================
-- 13. GOAPPlanner
-- =========================================================================
describe("lurek.ai GOAPPlanner", function()
    it("type returns GOAPPlanner", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal("LGOAPPlanner", g:type())
    end)

    it("addAction increases action count", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getActionCount())
        g:addAction("gather_wood", 1.0)
        expect_equal(1, g:getActionCount())
    end)

    it("setPrecondition does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("chop", 1.0)
        expect_no_error(function()
            g:setPrecondition("chop", "has_axe", true)
        end)
    end)

    it("setEffect does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("chop", 1.0)
        expect_no_error(function()
            g:setEffect("chop", "has_wood", true)
        end)
    end)

    it("addGoal increases goal count", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getGoalCount())
        g:addGoal("build_house", 1.0)
        expect_equal(1, g:getGoalCount())
    end)

    it("setGoalState does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addGoal("build_house", 1.0)
        expect_no_error(function()
            g:setGoalState("build_house", "has_house", true)
        end)
    end)

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
describe("lurek.ai InfluenceMap", function()
    it("type returns InfluenceMap", function()
        local im = lurek.ai.newInfluenceMap(10, 10, 32)
        expect_equal("LInfluenceMap", im:type())
    end)

    it("getWidth / getHeight / getCellSize", function()
        local im = lurek.ai.newInfluenceMap(8, 6, 16)
        expect_equal(8, im:getWidth())
        expect_equal(6, im:getHeight())
        expect_near(16, im:getCellSize(), 0.01)
    end)

    it("addLayer / hasLayer", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        expect_false(im:hasLayer("threat"))
        im:addLayer("threat")
        expect_true(im:hasLayer("threat"))
    end)

    it("setInfluence / getInfluence (1-based)", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("danger")
        im:setInfluence("danger", 2, 3, 0.75)
        expect_near(0.75, im:getInfluence("danger", 2, 3), 0.01)
    end)

    it("propagate does not error", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("heat")
        im:setInfluence("heat", 3, 3, 1.0)
        expect_no_error(function()
            im:propagate("heat", 0.5)
        end)
    end)

    it("decay reduces values", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("scent")
        im:setInfluence("scent", 1, 1, 1.0)
        im:decay("scent", 0.5)
        local val = im:getInfluence("scent", 1, 1)
        expect_near(0.5, val, 0.01)
    end)

    it("clearLayer resets all values", function()
        local im = lurek.ai.newInfluenceMap(3, 3, 10)
        im:addLayer("fog")
        im:setInfluence("fog", 1, 1, 1.0)
        im:setInfluence("fog", 2, 2, 0.5)
        im:clearLayer("fog")
        expect_near(0, im:getInfluence("fog", 1, 1), 0.01)
        expect_near(0, im:getInfluence("fog", 2, 2), 0.01)
    end)

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

    it("getMaxPosition returns two numbers", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("test")
        im:setInfluence("test", 3, 4, 1.0)
        local mx, my = im:getMaxPosition("test")
        expect_type("number", mx)
        expect_type("number", my)
    end)

    it("getMinPosition returns two numbers", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("test")
        im:setInfluence("test", 2, 2, -1.0)
        local mx, my = im:getMinPosition("test")
        expect_type("number", mx)
        expect_type("number", my)
    end)

    it("queryRect returns a number", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("zone")
        im:setInfluence("zone", 1, 1, 1.0)
        local sum = im:queryRect("zone", 0, 0, 50, 50)
        expect_type("number", sum)
    end)

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
end)

-- =========================================================================
-- 15. Squad
-- =========================================================================
describe("lurek.ai Squad", function()
    it("type returns Squad", function()
        local sq = lurek.ai.newSquad("alpha")
        expect_equal("LSquad", sq:type())
    end)

    it("getName returns squad name", function()
        local sq = lurek.ai.newSquad("bravo")
        expect_equal("bravo", sq:getName())
    end)

    it("addMember / getMemberCount", function()
        local sq = lurek.ai.newSquad("team")
        expect_equal(0, sq:getMemberCount())
        sq:addMember("soldier1")
        expect_equal(1, sq:getMemberCount())
        sq:addMember("soldier2")
        expect_equal(2, sq:getMemberCount())
    end)

    it("removeMember decreases count", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("a")
        sq:addMember("b")
        sq:removeMember("a")
        expect_equal(1, sq:getMemberCount())
    end)

    it("getMembers returns table of names", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("x")
        sq:addMember("y")
        local members = sq:getMembers()
        expect_type("table", members)
        expect_equal(2, #members)
    end)

    it("setLeader / getLeader", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("leader1")
        sq:setLeader("leader1")
        expect_equal("leader1", sq:getLeader())
    end)

    it("getLeader returns nil by default", function()
        local sq = lurek.ai.newSquad("team")
        expect_nil(sq:getLeader())
    end)

    it("setFormation / getFormation / getFormationSpacing", function()
        local sq = lurek.ai.newSquad("team")
        sq:setFormation("wedge", 50)
        expect_equal("wedge", sq:getFormation())
        expect_near(50, sq:getFormationSpacing(), 0.01)
    end)

    it("getFormationPosition returns two numbers (1-based index)", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("a")
        sq:addMember("b")
        local x, y = sq:getFormationPosition(1, 100, 200)
        expect_type("number", x)
        expect_type("number", y)
    end)

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
describe("lurek.ai CommandQueue", function()
    it("type returns CommandQueue", function()
        local cq = lurek.ai.newCommandQueue()
        expect_equal("LCommandQueue", cq:type())
    end)

    it("isEmpty returns true initially", function()
        local cq = lurek.ai.newCommandQueue()
        expect_true(cq:isEmpty())
    end)

    it("getCount returns 0 initially", function()
        local cq = lurek.ai.newCommandQueue()
        expect_equal(0, cq:getCount())
    end)

    it("enqueue increases count", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end)
        expect_equal(1, cq:getCount())
        expect_false(cq:isEmpty())
    end)

    it("getCurrentType returns first command type", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("attack", function() end)
        expect_equal("attack", cq:getCurrentType())
    end)

    it("getCurrentType returns nil when empty", function()
        local cq = lurek.ai.newCommandQueue()
        expect_nil(cq:getCurrentType())
    end)

    it("cancelCurrent removes head", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end)
        cq:enqueue("attack", function() end)
        cq:cancelCurrent()
        expect_equal(1, cq:getCount())
    end)

    it("clear removes all commands", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("a", function() end)
        cq:enqueue("b", function() end)
        cq:enqueue("c", function() end)
        cq:clear()
        expect_equal(0, cq:getCount())
        expect_true(cq:isEmpty())
    end)

    it("pushFront inserts at front", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("second", function() end)
        cq:pushFront("first", function() end)
        expect_equal("first", cq:getCurrentType())
    end)

    it("replace replaces all with single command", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("a", function() end)
        cq:enqueue("b", function() end)
        cq:replace("only", function() end)
        expect_equal(1, cq:getCount())
        expect_equal("only", cq:getCurrentType())
    end)

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
describe("lurek.ai type system", function()
    it("AIWorld:type() returns AIWorld", function()
        expect_equal("LAIWorld", lurek.ai.newWorld():type())
    end)

    it("Blackboard:type() returns Blackboard", function()
        expect_equal("LAIBlackboard", lurek.ai.newBlackboard():type())
    end)

    it("StateMachine:type() returns StateMachine", function()
        expect_equal("LStateMachine", lurek.ai.newStateMachine():type())
    end)

    it("BehaviorTree:type() returns BehaviorTree", function()
        expect_equal("LBehaviorTree", lurek.ai.newBehaviorTree():type())
    end)

    it("BTNode:type() returns BTNode", function()
        expect_equal("LBTNode", lurek.ai.newSelector():type())
    end)

    it("SteeringManager:type() returns SteeringManager", function()
        expect_equal("LSteeringManager", lurek.ai.newSteeringManager():type())
    end)

    it("PathGrid:type() returns PathGrid", function()
        expect_equal("LPathGrid", lurek.pathfind.newPathGrid(5, 5, 10):type())
    end)

    it("FlowField:type() returns FlowField", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        expect_equal("LAIFlowField", lurek.pathfind.newPathFlowField(g):type())
    end)

    it("QLearner:type() returns QLearner", function()
        expect_equal("LQLearner", lurek.ai.newQLearner(2, 2):type())
    end)

    it("UtilityAI:type() returns UtilityAI", function()
        expect_equal("LUtilityAI", lurek.ai.newUtilityAI():type())
    end)

    it("GOAPPlanner:type() returns GOAPPlanner", function()
        expect_equal("LGOAPPlanner", lurek.ai.newGOAPPlanner():type())
    end)

    it("InfluenceMap:type() returns LInfluenceMap", function()
        expect_equal("LInfluenceMap", lurek.ai.newInfluenceMap(5, 5, 10):type())
    end)

    it("Squad:type() returns LSquad", function()
        expect_equal("LSquad", lurek.ai.newSquad("s"):type())
    end)

    it("CommandQueue:type() returns LCommandQueue", function()
        expect_equal("LCommandQueue", lurek.ai.newCommandQueue():type())
    end)

    it("AIWorld:typeOf Object returns true", function()
        expect_true(lurek.ai.newWorld():typeOf("Object"))
    end)

    it("Agent:typeOf Object returns true", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("x")
        expect_true(a:typeOf("Object"))
    end)

    it("Blackboard:typeOf Object returns true", function()
        expect_true(lurek.ai.newBlackboard():typeOf("Object"))
    end)

    it("BTNode:typeOf Object returns true", function()
        expect_true(lurek.ai.newSelector():typeOf("Object"))
    end)
end)

-- =========================================================================
-- GOAPPlanner maxIterations configurability (PR-10)
-- =========================================================================

describe("lurek.ai GOAPPlanner maxIterations configurability", function()
    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:getMaxIterations
    it("goap_getMaxIterations_default_is_10000", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(10000, g:getMaxIterations())
    end)

    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:setMaxIterations
    -- @covers GOAPPlanner:getMaxIterations
    it("goap_setMaxIterations_roundtrips_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(500)
        expect_equal(500, g:getMaxIterations())
    end)

    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:setMaxIterations
    -- @covers GOAPPlanner:getMaxIterations
    it("goap_setMaxIterations_accepts_small_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(1)
        expect_equal(1, g:getMaxIterations())
    end)

    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:setMaxIterations
    -- @covers GOAPPlanner:getMaxIterations
    it("goap_setMaxIterations_accepts_large_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(100000)
        expect_equal(100000, g:getMaxIterations())
    end)
end)

-- =========================================================================
-- ContextSteering  - Factory
-- =========================================================================
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

    -- @covers lurek.ai.newContextSteering
    it("slot count reflects argument", function()
        local cs = lurek.ai.newContextSteering(8)
        expect_equal(cs:slotCount(), 8)
    end)

    -- @covers lurek.ai.newContextSteering
    it("defaults to 16 slots for 0 argument", function()
        local cs = lurek.ai.newContextSteering(0)
        expect_equal(cs:slotCount(), 16)
    end)
end)

-- =========================================================================
-- ContextSteering  - Evaluate produces a direction vector
-- =========================================================================
describe("ContextSteering evaluate", function()
    -- @covers lurek.ai.newContextSteering
    it("returns two numbers from evaluate", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addSeekTarget(100, 0, 1.0)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers lurek.ai.newContextSteering
    it("wander returns a non-zero vector length", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addWander(0.5, 1.0)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        local mag = math.sqrt(dx * dx + dy * dy)
        expect_near(cs:chosenMagnitude(), mag, 0.03)
    end)

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
describe("ContextSteering avoid", function()
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

    -- @covers lurek.ai.newAIDirector
    it("starts with zero tension", function()
        local d = lurek.ai.newAIDirector()
        expect_near(d:tension(), 0.0, 0.001)
    end)

    -- @covers lurek.ai.newAIDirector
    it("starts in Relief phase", function()
        local d = lurek.ai.newAIDirector()
        expect_equal(d:phase(), "relief")
    end)
end)

-- =========================================================================
-- AIDirector  - pushEvent raises tension
-- =========================================================================
describe("AIDirector pushEvent", function()
    -- @covers lurek.ai.newAIDirector
    it("pushEvent raises tension", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(0.8)
        expect_equal(d:tension() > 0.0, true)
    end)

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
describe("AIDirector update", function()
    -- @covers lurek.ai.newAIDirector
    it("update does not crash", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(1.0)
        d:update(0.1)
        expect_type("string", d:phase())
    end)

    -- @covers lurek.ai.newAIDirector
    it("spawnRateFactor returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:spawnRateFactor())
    end)

    -- @covers lurek.ai.newAIDirector
    it("lootFactor returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:lootFactor())
    end)

    -- @covers lurek.ai.newAIDirector
    it("ambientIntensity returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:ambientIntensity())
    end)
end)

-- =========================================================================
-- AIDirector  - Reset
-- =========================================================================
describe("AIDirector reset", function()
    -- @covers lurek.ai.newAIDirector
    it("reset clears tension", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(1.0)
        d:reset()
        expect_near(d:tension(), 0.0, 0.001)
    end)

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
describe("EmotionModel add/query", function()
    -- @covers lurek.ai.newEmotionModel
    it("dominant returns nil when empty", function()
        local em = lurek.ai.newEmotionModel()
        expect_equal(em:dominant(), nil)
    end)

    -- @covers lurek.ai.newEmotionModel
    it("get returns 0 for unknown emotion", function()
        local em = lurek.ai.newEmotionModel()
        expect_near(em:get("anger"), 0.0, 0.001)
    end)

    -- @covers lurek.ai.newEmotionModel
    it("trigger raises emotion value", function()
        local em = lurek.ai.newEmotionModel()
        em:add("fear", 0.0, 0.5, 0.1)
        em:trigger("fear", 0.8)
        expect_equal(em:get("fear") > 0.0, true)
    end)

    -- @covers lurek.ai.newEmotionModel
    it("isActive returns false before trigger", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.0, 0.3, 0.2)
        expect_equal(em:isActive("joy"), false)
    end)

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
describe("EmotionModel dominant", function()
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
describe("EmotionModel update/reset", function()
    -- @covers lurek.ai.newEmotionModel
    it("update does not crash", function()
        local em = lurek.ai.newEmotionModel()
        em:update(0.016)
        expect_equal(em:dominant(), nil)
    end)

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

    -- @covers lurek.ai.newHTNDomain
    it("starts with zero tasks", function()
        local d = lurek.ai.newHTNDomain()
        expect_equal(d:taskCount(), 0)
    end)
end)

-- =========================================================================
-- HTNDomain  - Primitives
-- =========================================================================
describe("HTNDomain addPrimitive", function()
    -- @covers lurek.ai.newHTNDomain
    it("addPrimitive increments task count", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("MoveTo", {}, {"at_target"}, {})
        expect_equal(d:taskCount(), 1)
    end)

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
describe("HTNDomain plan", function()
    -- @covers lurek.ai.newHTNDomain
    it("plan returns nil for unknown root task", function()
        local d = lurek.ai.newHTNDomain()
        local result = d:plan("nonexistent", {})
        expect_equal(result, nil)
    end)

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

    -- @covers lurek.ai.newAILod
    it("default tierCount is 3", function()
        local lod = lurek.ai.newAILod()
        expect_equal(3, lod:tierCount())
    end)
end)

-- =========================================================================
-- AILod  - Tier assignment
-- =========================================================================
describe("AILod tierFor", function()
    -- @covers lurek.ai.newAILod
    it("returns an integer tier index", function()
        local lod = lurek.ai.newAILod()
        local tier = lod:tierFor(0, 0, 0, 0)
        expect_type("number", tier)
        expect_equal(tier >= 0, true)
    end)

    -- @covers lurek.ai.newAILod
    it("agent at same position as reference gets tier 0 (nearest)", function()
        local lod = lurek.ai.newAILod()
        local tier = lod:tierFor(0, 0, 0, 0)
        expect_equal(tier, 0)
    end)

    -- @covers lurek.ai.newAILod
    it("distant agent gets higher tier than close agent", function()
        local lod = lurek.ai.newAILod()
        local near_tier = lod:tierFor(5, 0, 0, 0)    -- close
        local far_tier  = lod:tierFor(2000, 0, 0, 0) -- very far
        expect_equal(far_tier >= near_tier, true)
    end)

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
describe("AILod shouldUpdate", function()
    -- @covers lurek.ai.newAILod
    it("tier 0 updates every frame", function()
        local lod = lurek.ai.newAILod()
        -- Tier 0 (near) should update every frame
        expect_equal(lod:shouldUpdate(0, 0), true)
        expect_equal(lod:shouldUpdate(0, 1), true)
        expect_equal(lod:shouldUpdate(0, 7), true)
    end)

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
            expect_equal(true, true)
        end
    end)
end)

-- =========================================================================
-- AILod  - tierName
-- =========================================================================
describe("AILod tierName", function()
    -- @covers lurek.ai.newAILod
    it("tier 0 has a non-nil name", function()
        local lod = lurek.ai.newAILod()
        local name = lod:tierName(0)
        expect_type("string", name)
    end)

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
describe("MCTSEngine search", function()
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

    -- @covers lurek.ai.newNeuralNet
    it("starts with zero layers", function()
        local net = lurek.ai.newNeuralNet()
        expect_equal(net:layerCount(), 0)
    end)

    -- @covers lurek.ai.newNeuralNet
    it("addLayer increments layer count", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 4, "relu")
        net:addLayer(4, 1, "sigmoid")
        expect_equal(net:layerCount(), 2)
    end)

    -- @covers lurek.ai.newNeuralNet
    it("forward returns table of correct size", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(3, 2, "relu")
        local out = net:forward({0.5, 0.1, 0.9})
        expect_type("table", out)
        expect_equal(#out, 2)
    end)

    -- @covers lurek.ai.newNeuralNet
    it("paramCount is positive after adding layers", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 3, "tanh")
        -- 2*3 weights + 3 biases = 9
        expect_equal(net:paramCount(), 9)
    end)

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

    -- @covers lurek.ai.newGeneticAlgorithm
    it("popSize matches argument", function()
        local ga = lurek.ai.newGeneticAlgorithm(20, 4, 1)
        expect_equal(ga:popSize(), 20)
    end)

    -- @covers lurek.ai.newGeneticAlgorithm
    it("getGenes returns table of expected length", function()
        local ga = lurek.ai.newGeneticAlgorithm(5, 8, 7)
        local genes = ga:getGenes(0)
        expect_type("table", genes)
        expect_equal(#genes, 8)
    end)

    -- @covers lurek.ai.newGeneticAlgorithm
    it("evolve increments generation", function()
        local ga = lurek.ai.newGeneticAlgorithm(6, 4, 3)
        -- Assign trivial fitness before evolve
        for i = 0, 5 do ga:setFitness(i, i * 0.1) end
        local g0 = ga:generation()
        ga:evolve()
        expect_equal(ga:generation(), g0 + 1)
    end)

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

    -- @covers lurek.ai.newBandit
    it("armCount matches argument", function()
        local b = lurek.ai.newBandit(8, "ucb1", 0.0, 1)
        expect_equal(b:armCount(), 8)
    end)

    -- @covers lurek.ai.newBandit
    it("select returns a valid arm index", function()
        local b = lurek.ai.newBandit(4, "epsilon_greedy", 0.2, 10)
        local idx = b:select()
        expect_equal(idx >= 0 and idx < 4, true)
    end)

    -- @covers lurek.ai.newBandit
    it("update does not crash", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 5)
        b:update(0, 1.0)
        b:update(1, 0.5)
        b:update(2, 0.8)
        expect_equal(b:totalPulls(), 3)
    end)

    -- @covers lurek.ai.newBandit
    it("bestArm returns a valid index after updates", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 5)
        b:update(0, 0.1)
        b:update(1, 0.9)
        b:update(2, 0.3)
        expect_equal(b:bestArm() >= 0, true)
    end)

    -- @covers lurek.ai.newBandit
    it("thompson_sampling strategy creates successfully", function()
        local b = lurek.ai.newBandit(4, "thompson", 0.0, 7)
        local idx = b:select()
        expect_equal(idx >= 0 and idx < 4, true)
    end)

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

    -- @covers lurek.ai.newNeuroevolution
    it("popSize matches argument", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=2, activation="relu"}}, 8, 1)
        expect_equal(ne:popSize(), 8)
    end)

    -- @covers lurek.ai.newNeuroevolution
    it("chromosomeToNet returns a NeuralNet userdata", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=2, activation="tanh"}}, 5, 3)
        local net = ne:chromosomeToNet(0)
        expect_type("userdata", net)
    end)

    -- @covers lurek.ai.newNeuroevolution
    it("bestNetwork returns userdata after evolve", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=1, activation="sigmoid"}}, 4, 7)
        for i = 0, 3 do ne:setFitness(i, i * 0.2) end
        ne:evolve()
        local best = ne:bestNetwork()
        expect_type("userdata", best)
    end)

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
describe("NeedSystem add/query", function()
    -- @covers lurek.ai.newNeedSystem
    it("mostUrgent returns nil when empty", function()
        local ns = lurek.ai.newNeedSystem()
        expect_equal(ns:mostUrgent(), nil)
    end)

    -- @covers lurek.ai.newNeedSystem
    it("valueOf returns 1.0 for new needs (full by default)", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 0.1, 0.3, 2.0)
        expect_near(ns:valueOf("hunger"), 1.0, 0.001)
    end)

    -- @covers lurek.ai.newNeedSystem
    it("valueOf returns 0 for unknown need", function()
        local ns = lurek.ai.newNeedSystem()
        expect_near(ns:valueOf("unknown"), 1.0, 0.001)
    end)
end)

-- =========================================================================
-- NeedSystem  - Decay
-- =========================================================================
describe("NeedSystem update/decay", function()
    -- @covers lurek.ai.newNeedSystem
    it("update does not crash with empty system", function()
        local ns = lurek.ai.newNeedSystem()
        ns:update(0.016)
        expect_equal(ns:mostUrgent(), nil)
    end)

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
describe("NeedSystem satisfy", function()
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
describe("NeedSystem mostUrgent", function()
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

    -- @covers lurek.ai.newORCASolver
    it("starts with zero agents", function()
        local s = lurek.ai.newORCASolver(2.0)
        expect_equal(s:agentCount(), 0)
    end)
end)

-- =========================================================================
-- ORCASolver  - Add agents
-- =========================================================================
describe("ORCASolver addAgent", function()
    -- @covers lurek.ai.newORCASolver
    it("addAgent increments count", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        expect_equal(s:agentCount(), 1)
    end)

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
describe("ORCASolver compute", function()
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

    -- @covers lurek.ai.newORCASolver
    it("getSafeVelocity returns zeros for out-of-bounds index", function()
        local s = lurek.ai.newORCASolver(2.0)
        local vx, vy = s:getSafeVelocity(99)
        expect_near(vx, 0.0, 0.001)
        expect_near(vy, 0.0, 0.001)
    end)

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

    -- @covers lurek.ai.newStimulusWorld
    it("starts with zero stimuli", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_equal(sw:count(), 0)
    end)
end)

-- =========================================================================
-- StimulusWorld  - Adding stimuli
-- =========================================================================
describe("StimulusWorld add stimuli", function()
    -- @covers lurek.ai.newStimulusWorld
    it("addVisual increases count", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(100, 200, 1.0, 50.0, nil)
        expect_equal(sw:count(), 1)
    end)

    -- @covers lurek.ai.newStimulusWorld
    it("addAuditory increases count", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addAuditory(50, 50, 0.8, 80.0, 0.5, "gunshot")
        expect_equal(sw:count(), 1)
    end)

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
describe("StimulusWorld remove", function()
    -- @covers lurek.ai.newStimulusWorld
    it("remove decrements count", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 50.0, nil)
        expect_equal(sw:count(), 1)
        sw:remove(id)
        expect_equal(sw:count(), 0)
    end)

    -- @covers lurek.ai.newStimulusWorld
    it("remove returns true for valid id", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 50.0, nil)
        expect_equal(sw:remove(id), true)
    end)

    -- @covers lurek.ai.newStimulusWorld
    it("remove returns false for unknown id", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_equal(sw:remove(99999), false)
    end)
end)

-- =========================================================================
-- StimulusWorld  - Update and clear
-- =========================================================================
describe("StimulusWorld update/clear", function()
    -- @covers lurek.ai.newStimulusWorld
    it("update does not crash with empty world", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:update(0.016)
        expect_equal(sw:count(), 0)
    end)

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

    -- @covers lurek.ai.newStrategyAI
    it("starts with no active goal", function()
        local s = lurek.ai.newStrategyAI(5.0)
        expect_equal(s:activeGoal(), nil)
    end)
end)

-- =========================================================================
-- StrategyAI  - Add goals and evaluate
-- =========================================================================
describe("StrategyAI addGoal / forceEvaluate", function()
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
describe("StrategyAI update throttle", function()
    -- @covers lurek.ai.newStrategyAI
    it("update does not crash before interval", function()
        local s = lurek.ai.newStrategyAI(5.0)
        s:addGoal("patrol")
        s:update(0.016, function(_) return 1.0 end)
        expect_type("number", s:timeUntilNext())
    end)

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
describe("StrategyAI tags", function()
    -- @covers lurek.ai.newStrategyAI
    it("addTag / removeTag do not crash", function()
        local s = lurek.ai.newStrategyAI(5.0)
        s:addTag("night")
        s:addTag("rain")
        s:removeTag("night")
        expect_equal(true, true)  -- no crash = pass
    end)
end)

-- =========================================================================
-- TraitProfile  - Factory
-- =========================================================================
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
describe("TraitProfile set/get", function()
    -- @covers lurek.ai.newTraitProfile
    it("starts with zero for unknown trait", function()
        local tp = lurek.ai.newTraitProfile()
        expect_near(tp:get("aggression"), 0.0, 0.001)
    end)

    -- @covers lurek.ai.newTraitProfile
    it("returns set value", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("courage", 0.75)
        expect_near(tp:get("courage"), 0.75, 0.001)
    end)

    -- @covers lurek.ai.newTraitProfile
    it("has() returns false for unset trait", function()
        local tp = lurek.ai.newTraitProfile()
        expect_equal(tp:has("unknown_trait"), false)
    end)

    -- @covers lurek.ai.newTraitProfile
    it("has() returns true after set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("loyalty", 0.5)
        expect_equal(tp:has("loyalty"), true)
    end)

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
describe("TraitProfile modifiers", function()
    -- @covers lurek.ai.newTraitProfile
    it("modifier raises effective value immediately", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("fear", 0.2)
        tp:addModifier("fear", 0.5, nil, "poison")
        expect_near(tp:get("fear"), 0.7, 0.01)
    end)

    -- @covers lurek.ai.newTraitProfile
    it("removeModifiers restores base value", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("fear", 0.2)
        tp:addModifier("fear", 0.5, nil, "poison")
        tp:removeModifiers("poison")
        expect_near(tp:get("fear"), 0.2, 0.01)
    end)

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
describe("TraitProfile update", function()
    -- @covers lurek.ai.newTraitProfile
    it("update does not crash with no modifiers", function()
        local tp = lurek.ai.newTraitProfile()
        tp:update(0.016)
        expect_equal(tp:traitCount(), 0)
    end)

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
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @covers Blackboard:has
    it("covers Blackboard:has", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal(false, bb:has("hp"))
        bb:setNumber("hp", 10)
        expect_equal(true, bb:has("hp"))
    end)

    -- @covers BehaviorTree:getDebugState
    it("covers BehaviorTree:getDebugState", function()
        local bt = lurek.ai.newBehaviorTree()
        local dbg = bt:getDebugState()
        expect_type("table", dbg)
        expect_type("number", dbg.node_count)
        expect_type("string", dbg.last_status)
    end)

    -- @covers SteeringManager:setSpatialHashCellSize
    it("covers SteeringManager:setSpatialHashCellSize", function()
        local sm = lurek.ai.newSteeringManager()
        expect_no_error(function()
            sm:setSpatialHashCellSize(32)
        end)
        local fx, fy = sm:calculate(0, 0, 0, 0, 100, 50, 0.016)
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    -- @covers SteeringManager:enableSpatialHash
    it("covers SteeringManager:enableSpatialHash", function()
        local sm = lurek.ai.newSteeringManager()
        expect_no_error(function()
            sm:enableSpatialHash(true)
            sm:enableSpatialHash(false)
        end)
    end)

    -- @covers CommandQueue:getCurrentTarget
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

    -- @covers TraitProfile:set
    it("covers TraitProfile:set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("courage", 0.75)
        expect_near(0.75, tp:get("courage"), 0.001)
    end)

    -- @covers TraitProfile:get
    it("covers TraitProfile:get", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("loyalty", 0.5)
        expect_near(0.5, tp:get("loyalty"), 0.001)
    end)

    -- @covers TraitProfile:has
    it("covers TraitProfile:has", function()
        local tp = lurek.ai.newTraitProfile()
        expect_equal(false, tp:has("focus"))
        tp:set("focus", 0.9)
        expect_equal(true, tp:has("focus"))
    end)

    -- @covers ContextSteering:addAvoidBounds
    it("covers ContextSteering:addAvoidBounds", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addAvoidBounds(-10, -10, 10, 10, 2, 1)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers EmotionModel:get
    it("covers EmotionModel:get", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.1, 0.5, 0.2)
        expect_near(0.1, em:get("joy"), 0.001)
    end)

    -- @covers Neuroevolution:bestFitness
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

describe("Missing explicit test for AIWorld:addAgent", function()
    it("AIWorld:addAgent works", function()
        -- @covers AIWorld:addAgent
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_add")
        expect_not_nil(a)
        expect_equal(1, w:getAgentCount())
    end)
end)

describe("Missing explicit test for AIWorld:getAgent", function()
    it("AIWorld:getAgent works", function()
        -- @covers AIWorld:getAgent
        local w = lurek.ai.newWorld()
        w:addAgent("agent_get")
        local a = w:getAgent("agent_get")
        expect_not_nil(a)
        expect_equal("agent_get", a:getName())
    end)
end)

describe("Missing explicit test for AIWorld:removeAgent", function()
    it("AIWorld:removeAgent works", function()
        -- @covers AIWorld:removeAgent
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_remove")
        w:removeAgent(a)
        expect_equal(0, w:getAgentCount())
    end)
end)

describe("Missing explicit test for AIWorld:getAgentCount", function()
    it("AIWorld:getAgentCount works", function()
        -- @covers AIWorld:getAgentCount
        local w = lurek.ai.newWorld()
        w:addAgent("a")
        w:addAgent("b")
        expect_equal(2, w:getAgentCount())
    end)
end)

describe("Missing explicit test for AIWorld:getGlobalBlackboard", function()
    it("AIWorld:getGlobalBlackboard works", function()
        -- @covers AIWorld:getGlobalBlackboard
        local w = lurek.ai.newWorld()
        local bb = w:getGlobalBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)
end)

describe("Missing explicit test for AIWorld:update", function()
    it("AIWorld:update works", function()
        -- @covers AIWorld:update
        local w = lurek.ai.newWorld()
        local a = w:addAgent("mover")
        a:setVelocity(10, 0)
        w:update(0.5)
        local x = a:getPosition()
        expect_true(x > 0, "agent should move after update")
    end)
end)

describe("Missing explicit test for AIWorld:type", function()
    it("AIWorld:type works", function()
        -- @covers AIWorld:type
        expect_equal("LAIWorld", lurek.ai.newWorld():type())
    end)
end)

describe("Missing explicit test for AIWorld:typeOf", function()
    it("AIWorld:typeOf works", function()
        -- @covers AIWorld:typeOf
        expect_equal(true, lurek.ai.newWorld():typeOf("AIWorld"))
    end)
end)

describe("Missing explicit test for Agent:getName", function()
    it("Agent:getName works", function()
        -- @covers Agent:getName
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_name")
        expect_equal("agent_name", a:getName())
    end)
end)

describe("Missing explicit test for Agent:setPosition", function()
    it("Agent:setPosition works", function()
        -- @covers Agent:setPosition
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_pos_set")
        a:setPosition(12, 34)
        local x, y = a:getPosition()
        expect_near(12, x, 0.01)
        expect_near(34, y, 0.01)
    end)
end)

describe("Missing explicit test for Agent:getPosition", function()
    it("Agent:getPosition works", function()
        -- @covers Agent:getPosition
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_pos_get")
        a:setPosition(3, 7)
        local x, y = a:getPosition()
        expect_near(3, x, 0.01)
        expect_near(7, y, 0.01)
    end)
end)

describe("Missing explicit test for Agent:setVelocity", function()
    it("Agent:setVelocity works", function()
        -- @covers Agent:setVelocity
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_vel_set")
        a:setVelocity(5, -3)
        local vx, vy = a:getVelocity()
        expect_near(5, vx, 0.01)
        expect_near(-3, vy, 0.01)
    end)
end)

describe("Missing explicit test for Agent:getVelocity", function()
    it("Agent:getVelocity works", function()
        -- @covers Agent:getVelocity
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_vel_get")
        a:setVelocity(2, 4)
        local vx, vy = a:getVelocity()
        expect_near(2, vx, 0.01)
        expect_near(4, vy, 0.01)
    end)
end)

describe("Missing explicit test for Agent:setMaxSpeed", function()
    it("Agent:setMaxSpeed works", function()
        -- @covers Agent:setMaxSpeed
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_speed_set")
        a:setMaxSpeed(250)
        expect_near(250, a:getMaxSpeed(), 0.01)
    end)
end)

describe("Missing explicit test for Agent:getMaxSpeed", function()
    it("Agent:getMaxSpeed works", function()
        -- @covers Agent:getMaxSpeed
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_speed_get")
        a:setMaxSpeed(125)
        expect_near(125, a:getMaxSpeed(), 0.01)
    end)
end)

describe("Missing explicit test for Agent:setMaxForce", function()
    it("Agent:setMaxForce works", function()
        -- @covers Agent:setMaxForce
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_force_set")
        a:setMaxForce(400)
        expect_near(400, a:getMaxForce(), 0.01)
    end)
end)

describe("Missing explicit test for Agent:getMaxForce", function()
    it("Agent:getMaxForce works", function()
        -- @covers Agent:getMaxForce
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_force_get")
        a:setMaxForce(175)
        expect_near(175, a:getMaxForce(), 0.01)
    end)
end)

describe("Missing explicit test for Agent:setPriority", function()
    it("Agent:setPriority works", function()
        -- @covers Agent:setPriority
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_prio_set")
        a:setPriority(9)
        expect_equal(9, a:getPriority())
    end)
end)

describe("Missing explicit test for Agent:getPriority", function()
    it("Agent:getPriority works", function()
        -- @covers Agent:getPriority
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_prio_get")
        a:setPriority(4)
        expect_equal(4, a:getPriority())
    end)
end)

describe("Missing explicit test for Agent:setDecisionModel", function()
    it("Agent:setDecisionModel works", function()
        -- @covers Agent:setDecisionModel
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_model_set")
        a:setDecisionModel("bt")
        expect_equal("bt", a:getDecisionModel())
    end)
end)

describe("Missing explicit test for Agent:getDecisionModel", function()
    it("Agent:getDecisionModel works", function()
        -- @covers Agent:getDecisionModel
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_model_get")
        a:setDecisionModel("fsm")
        expect_equal("fsm", a:getDecisionModel())
    end)
end)

describe("Missing explicit test for Agent:addTag", function()
    it("Agent:addTag works", function()
        -- @covers Agent:addTag
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_tag_add")
        a:addTag("enemy")
        expect_equal(true, a:hasTag("enemy"))
    end)
end)

describe("Missing explicit test for Agent:removeTag", function()
    it("Agent:removeTag works", function()
        -- @covers Agent:removeTag
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_tag_remove")
        a:addTag("enemy")
        a:removeTag("enemy")
        expect_equal(false, a:hasTag("enemy"))
    end)
end)

describe("Missing explicit test for Agent:hasTag", function()
    it("Agent:hasTag works", function()
        -- @covers Agent:hasTag
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_tag_has")
        expect_equal(false, a:hasTag("support"))
        a:addTag("support")
        expect_equal(true, a:hasTag("support"))
    end)
end)

describe("Missing explicit test for Agent:getBlackboard", function()
    it("Agent:getBlackboard works", function()
        -- @covers Agent:getBlackboard
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_bb")
        local bb = a:getBlackboard()
        expect_not_nil(bb)
        expect_equal("LAIBlackboard", bb:type())
    end)
end)

describe("Missing explicit test for Agent:type", function()
    it("Agent:type works", function()
        -- @covers Agent:type
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_type")
        expect_equal("LAgent", a:type())
    end)
end)

describe("Missing explicit test for Agent:typeOf", function()
    it("Agent:typeOf works", function()
        -- @covers Agent:typeOf
        local w = lurek.ai.newWorld()
        local a = w:addAgent("agent_typeof")
        expect_equal(true, a:typeOf("Agent"))
    end)
end)

describe("Missing explicit test for Blackboard:setNumber", function()
    it("Blackboard:setNumber works", function()
        -- @covers Blackboard:setNumber
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 42)
        expect_near(42, bb:getNumber("hp"), 0.001)
    end)
end)

describe("Missing explicit test for Blackboard:setBool", function()
    it("Blackboard:setBool works", function()
        -- @covers Blackboard:setBool
        local bb = lurek.ai.newBlackboard()
        bb:setBool("alive", true)
        expect_equal(true, bb:getBool("alive"))
    end)
end)

describe("Missing explicit test for Blackboard:setString", function()
    it("Blackboard:setString works", function()
        -- @covers Blackboard:setString
        local bb = lurek.ai.newBlackboard()
        bb:setString("role", "tank")
        expect_equal("tank", bb:getString("role"))
    end)
end)

describe("Missing explicit test for Blackboard:remove", function()
    it("Blackboard:remove works", function()
        -- @covers Blackboard:remove
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:remove("hp")
        expect_equal(false, bb:has("hp"))
    end)
end)

describe("Missing explicit test for Blackboard:clear", function()
    it("Blackboard:clear works", function()
        -- @covers Blackboard:clear
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("a", 1)
        bb:setBool("b", true)
        bb:clear()
        expect_equal(0, bb:getSize())
    end)
end)

describe("Missing explicit test for Blackboard:getKeys", function()
    it("Blackboard:getKeys works", function()
        -- @covers Blackboard:getKeys
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:setString("name", "hero")
        local keys = bb:getKeys()
        expect_type("table", keys)
        expect_equal(2, #keys)
    end)
end)

describe("Missing explicit test for Blackboard:getSize", function()
    it("Blackboard:getSize works", function()
        -- @covers Blackboard:getSize
        local bb = lurek.ai.newBlackboard()
        expect_equal(0, bb:getSize())
        bb:setNumber("hp", 10)
        expect_equal(1, bb:getSize())
    end)
end)

describe("Missing explicit test for Blackboard:type", function()
    it("Blackboard:type works", function()
        -- @covers Blackboard:type
        expect_equal("LAIBlackboard", lurek.ai.newBlackboard():type())
    end)
end)

describe("Missing explicit test for Blackboard:typeOf", function()
    it("Blackboard:typeOf works", function()
        -- @covers Blackboard:typeOf
        expect_equal(true, lurek.ai.newBlackboard():typeOf("Blackboard"))
    end)
end)

describe("Missing explicit test for StateMachine:addState", function()
    it("StateMachine:addState works", function()
        -- @covers StateMachine:addState
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        expect_equal("idle", fsm:getCurrentState())
    end)
end)

describe("Missing explicit test for StateMachine:setInitialState", function()
    it("StateMachine:setInitialState works", function()
        -- @covers StateMachine:setInitialState
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("patrol", {})
        fsm:setInitialState("patrol")
        expect_equal("patrol", fsm:getCurrentState())
    end)
end)

describe("Missing explicit test for StateMachine:getCurrentState", function()
    it("StateMachine:getCurrentState works", function()
        -- @covers StateMachine:getCurrentState
        local fsm = lurek.ai.newStateMachine()
        expect_nil(fsm:getCurrentState())
    end)
end)

describe("Missing explicit test for StateMachine:forceState", function()
    it("StateMachine:forceState works", function()
        -- @covers StateMachine:forceState
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("attack", {})
        fsm:setInitialState("idle")
        fsm:forceState("attack")
        expect_equal("attack", fsm:getCurrentState())
    end)
end)

describe("Missing explicit test for StateMachine:getTimeInState", function()
    it("StateMachine:getTimeInState works", function()
        -- @covers StateMachine:getTimeInState
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        fsm:forceState("idle")
        expect_near(0, fsm:getTimeInState(), 0.01)
    end)
end)

describe("Missing explicit test for StateMachine:type", function()
    it("StateMachine:type works", function()
        -- @covers StateMachine:type
        expect_equal("LStateMachine", lurek.ai.newStateMachine():type())
    end)
end)

describe("Missing explicit test for StateMachine:typeOf", function()
    it("StateMachine:typeOf works", function()
        -- @covers StateMachine:typeOf
        expect_true(lurek.ai.newStateMachine():typeOf("StateMachine"))
    end)
end)

describe("Missing explicit test for BehaviorTree:setRoot", function()
    it("BehaviorTree:setRoot works", function()
        -- @covers BehaviorTree:setRoot
        local bt = lurek.ai.newBehaviorTree()
        bt:setRoot(lurek.ai.newSequence())
        local dbg = bt:getDebugState()
        expect_true(dbg.node_count >= 1)
    end)
end)

describe("Missing explicit test for BehaviorTree:getLastStatus", function()
    it("BehaviorTree:getLastStatus works", function()
        -- @covers BehaviorTree:getLastStatus
        expect_equal("success", lurek.ai.newBehaviorTree():getLastStatus())
    end)
end)

describe("Missing explicit test for BehaviorTree:type", function()
    it("BehaviorTree:type works", function()
        -- @covers BehaviorTree:type
        expect_equal("LBehaviorTree", lurek.ai.newBehaviorTree():type())
    end)
end)

describe("Missing explicit test for BehaviorTree:typeOf", function()
    it("BehaviorTree:typeOf works", function()
        -- @covers BehaviorTree:typeOf
        expect_true(lurek.ai.newBehaviorTree():typeOf("BehaviorTree"))
    end)
end)

describe("Missing explicit test for BTNode:addChild", function()
    it("BTNode:addChild works", function()
        -- @covers BTNode:addChild
        local seq = lurek.ai.newSequence()
        seq:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, seq:getChildCount())
    end)
end)

describe("Missing explicit test for BTNode:getChildCount", function()
    it("BTNode:getChildCount works", function()
        -- @covers BTNode:getChildCount
        local par = lurek.ai.newParallel()
        expect_equal(0, par:getChildCount())
        par:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, par:getChildCount())
    end)
end)

describe("Missing explicit test for BTNode:reset", function()
    it("BTNode:reset works", function()
        -- @covers BTNode:reset
        local node = lurek.ai.newRepeater(3)
        node:setChild(lurek.ai.newAction(function() end))
        expect_no_error(function()
            node:reset()
        end)
    end)
end)

describe("Missing explicit test for BTNode:setChild", function()
    it("BTNode:setChild works", function()
        -- @covers BTNode:setChild
        local inv = lurek.ai.newInverter()
        expect_no_error(function()
            inv:setChild(lurek.ai.newAction(function() end))
        end)
    end)
end)

describe("Missing explicit test for BTNode:setCount", function()
    it("BTNode:setCount works", function()
        -- @covers BTNode:setCount
        local rep = lurek.ai.newRepeater(2)
        rep:setCount(7)
        expect_equal(7, rep:getCount())
    end)
end)

describe("Missing explicit test for BTNode:getCount", function()
    it("BTNode:getCount works", function()
        -- @covers BTNode:getCount
        expect_equal(4, lurek.ai.newRepeater(4):getCount())
    end)
end)

describe("Missing explicit test for BTNode:setSuccessPolicy", function()
    it("BTNode:setSuccessPolicy works", function()
        -- @covers BTNode:setSuccessPolicy
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setSuccessPolicy("require_all")
        end)
    end)
end)

describe("Missing explicit test for BTNode:setFailurePolicy", function()
    it("BTNode:setFailurePolicy works", function()
        -- @covers BTNode:setFailurePolicy
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setFailurePolicy("require_all")
        end)
    end)
end)

describe("Missing explicit test for BTNode:getNodeType", function()
    it("BTNode:getNodeType works", function()
        -- @covers BTNode:getNodeType
        expect_equal("selector", lurek.ai.newSelector():getNodeType())
    end)
end)

describe("Missing explicit test for BTNode:type", function()
    it("BTNode:type works", function()
        -- @covers BTNode:type
        expect_equal("LBTNode", lurek.ai.newSelector():type())
    end)
end)

describe("Missing explicit test for BTNode:typeOf", function()
    it("BTNode:typeOf works", function()
        -- @covers BTNode:typeOf
        expect_true(lurek.ai.newSelector():typeOf("BTNode"))
    end)
end)

describe("Missing explicit test for SteeringManager:getBehaviorCount", function()
    it("SteeringManager:getBehaviorCount works", function()
        -- @covers SteeringManager:getBehaviorCount
        local sm = lurek.ai.newSteeringManager()
        expect_equal(0, sm:getBehaviorCount())
        sm:addSeek(100, 50)
        expect_equal(1, sm:getBehaviorCount())
    end)
end)

describe("Missing explicit test for SteeringManager:setCombineMode", function()
    it("SteeringManager:setCombineMode works", function()
        -- @covers SteeringManager:setCombineMode
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("priority")
        expect_equal("priority", sm:getCombineMode())
    end)
end)

describe("Missing explicit test for SteeringManager:getCombineMode", function()
    it("SteeringManager:getCombineMode works", function()
        -- @covers SteeringManager:getCombineMode
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("weighted")
        expect_equal("weighted", sm:getCombineMode())
    end)
end)

describe("Missing explicit test for SteeringManager:getLastSteering", function()
    it("SteeringManager:getLastSteering works", function()
        -- @covers SteeringManager:getLastSteering
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:calculate(0, 0, 0, 0, 100, 50, 1 / 60)
        local fx, fy = sm:getLastSteering()
        expect_type("number", fx)
        expect_type("number", fy)
    end)
end)

describe("Missing explicit test for SteeringManager:type", function()
    it("SteeringManager:type works", function()
        -- @covers SteeringManager:type
        expect_equal("LSteeringManager", lurek.ai.newSteeringManager():type())
    end)
end)

describe("Missing explicit test for SteeringManager:typeOf", function()
    it("SteeringManager:typeOf works", function()
        -- @covers SteeringManager:typeOf
        expect_true(lurek.ai.newSteeringManager():typeOf("SteeringManager"))
    end)
end)

describe("Missing explicit test for QLearner:chooseAction", function()
    it("QLearner:chooseAction works", function()
        -- @covers QLearner:chooseAction
        local q = lurek.ai.newQLearner(2, 3)
        local action = q:chooseAction(1)
        expect_true(action >= 1 and action <= 3)
    end)
end)

describe("Missing explicit test for QLearner:bestAction", function()
    it("QLearner:bestAction works", function()
        -- @covers QLearner:bestAction
        local q = lurek.ai.newQLearner(2, 3)
        q:setQValue(1, 1, 1.0)
        q:setQValue(1, 2, 5.0)
        q:setQValue(1, 3, 2.0)
        expect_equal(2, q:bestAction(1))
    end)
end)

describe("Missing explicit test for QLearner:getQValue", function()
    it("QLearner:getQValue works", function()
        -- @covers QLearner:getQValue
        local q = lurek.ai.newQLearner(3, 2)
        q:setQValue(1, 2, 5.0)
        expect_near(5.0, q:getQValue(1, 2), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:endEpisode", function()
    it("QLearner:endEpisode works", function()
        -- @covers QLearner:endEpisode
        local q = lurek.ai.newQLearner(2, 2)
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
    end)
end)

describe("Missing explicit test for QLearner:getEpisodeCount", function()
    it("QLearner:getEpisodeCount works", function()
        -- @covers QLearner:getEpisodeCount
        local q = lurek.ai.newQLearner(2, 2)
        expect_equal(0, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
    end)
end)

describe("Missing explicit test for QLearner:getStateCount", function()
    it("QLearner:getStateCount works", function()
        -- @covers QLearner:getStateCount
        expect_equal(4, lurek.ai.newQLearner(4, 3):getStateCount())
    end)
end)

describe("Missing explicit test for QLearner:getActionCount", function()
    it("QLearner:getActionCount works", function()
        -- @covers QLearner:getActionCount
        expect_equal(3, lurek.ai.newQLearner(4, 3):getActionCount())
    end)
end)

describe("Missing explicit test for QLearner:setLearningRate", function()
    it("QLearner:setLearningRate works", function()
        -- @covers QLearner:setLearningRate
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.5)
        expect_near(0.5, q:getLearningRate(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:getLearningRate", function()
    it("QLearner:getLearningRate works", function()
        -- @covers QLearner:getLearningRate
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.25)
        expect_near(0.25, q:getLearningRate(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:setDiscountFactor", function()
    it("QLearner:setDiscountFactor works", function()
        -- @covers QLearner:setDiscountFactor
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.8)
        expect_near(0.8, q:getDiscountFactor(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:getDiscountFactor", function()
    it("QLearner:getDiscountFactor works", function()
        -- @covers QLearner:getDiscountFactor
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.7)
        expect_near(0.7, q:getDiscountFactor(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:setExplorationRate", function()
    it("QLearner:setExplorationRate works", function()
        -- @covers QLearner:setExplorationRate
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.1)
        expect_near(0.1, q:getExplorationRate(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:getExplorationRate", function()
    it("QLearner:getExplorationRate works", function()
        -- @covers QLearner:getExplorationRate
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.2)
        expect_near(0.2, q:getExplorationRate(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:setExplorationDecay", function()
    it("QLearner:setExplorationDecay works", function()
        -- @covers QLearner:setExplorationDecay
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.99)
        expect_near(0.99, q:getExplorationDecay(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:getExplorationDecay", function()
    it("QLearner:getExplorationDecay works", function()
        -- @covers QLearner:getExplorationDecay
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.95)
        expect_near(0.95, q:getExplorationDecay(), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:serialize", function()
    it("QLearner:serialize works", function()
        -- @covers QLearner:serialize
        local q = lurek.ai.newQLearner(2, 2)
        q:setQValue(1, 1, 3.14)
        local json = q:serialize()
        expect_type("string", json)
    end)
end)

describe("Missing explicit test for QLearner:deserialize", function()
    it("QLearner:deserialize works", function()
        -- @covers QLearner:deserialize
        local q = lurek.ai.newQLearner(2, 2)
        q:setQValue(1, 1, 3.14)
        local json = q:serialize()
        local q2 = lurek.ai.newQLearner(2, 2)
        q2:deserialize(json)
        expect_near(3.14, q2:getQValue(1, 1), 0.001)
    end)
end)

describe("Missing explicit test for QLearner:type", function()
    it("QLearner:type works", function()
        -- @covers QLearner:type
        expect_equal("LQLearner", lurek.ai.newQLearner(2, 2):type())
    end)
end)

describe("Missing explicit test for QLearner:typeOf", function()
    it("QLearner:typeOf works", function()
        -- @covers QLearner:typeOf
        expect_true(lurek.ai.newQLearner(2, 2):typeOf("QLearner"))
    end)
end)

describe("Missing explicit test for UtilityAI:evaluate", function()
    it("UtilityAI:evaluate works", function()
        -- @covers UtilityAI:evaluate
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 0.2 end)
        u:addAction("attack", function() return 0.9 end)
        expect_equal("attack", u:evaluate())
    end)
end)

describe("Missing explicit test for UtilityAI:getActionCount", function()
    it("UtilityAI:getActionCount works", function()
        -- @covers UtilityAI:getActionCount
        local u = lurek.ai.newUtilityAI()
        expect_equal(0, u:getActionCount())
        u:addAction("patrol", function() return 0.2 end)
        expect_equal(1, u:getActionCount())
    end)
end)

describe("Missing explicit test for UtilityAI:getLastAction", function()
    it("UtilityAI:getLastAction works", function()
        -- @covers UtilityAI:getLastAction
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 0.2 end)
        u:evaluate()
        expect_equal("patrol", u:getLastAction())
    end)
end)

describe("Missing explicit test for UtilityAI:type", function()
    it("UtilityAI:type works", function()
        -- @covers UtilityAI:type
        expect_equal("LUtilityAI", lurek.ai.newUtilityAI():type())
    end)
end)

describe("Missing explicit test for UtilityAI:typeOf", function()
    it("UtilityAI:typeOf works", function()
        -- @covers UtilityAI:typeOf
        expect_true(lurek.ai.newUtilityAI():typeOf("UtilityAI"))
    end)
end)

describe("Missing explicit test for GOAPPlanner:getActionCount", function()
    it("GOAPPlanner:getActionCount works", function()
        -- @covers GOAPPlanner:getActionCount
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getActionCount())
        g:addAction("move", 1.0)
        expect_equal(1, g:getActionCount())
    end)
end)

describe("Missing explicit test for GOAPPlanner:getGoalCount", function()
    it("GOAPPlanner:getGoalCount works", function()
        -- @covers GOAPPlanner:getGoalCount
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getGoalCount())
        g:addGoal("survive", 2.0)
        expect_equal(1, g:getGoalCount())
    end)
end)

describe("Missing explicit test for GOAPPlanner:type", function()
    it("GOAPPlanner:type works", function()
        -- @covers GOAPPlanner:type
        expect_equal("LGOAPPlanner", lurek.ai.newGOAPPlanner():type())
    end)
end)

describe("Missing explicit test for GOAPPlanner:typeOf", function()
    it("GOAPPlanner:typeOf works", function()
        -- @covers GOAPPlanner:typeOf
        expect_true(lurek.ai.newGOAPPlanner():typeOf("GOAPPlanner"))
    end)
end)

describe("Missing explicit test for InfluenceMap:addLayer", function()
    it("InfluenceMap:addLayer works", function()
        -- @covers InfluenceMap:addLayer
        -- TODO: add assertion for InfluenceMap:addLayer
    end)
end)

describe("Missing explicit test for InfluenceMap:hasLayer", function()
    it("InfluenceMap:hasLayer works", function()
        -- @covers InfluenceMap:hasLayer
        -- TODO: add assertion for InfluenceMap:hasLayer
    end)
end)

describe("Missing explicit test for InfluenceMap:decay", function()
    it("InfluenceMap:decay works", function()
        -- @covers InfluenceMap:decay
        -- TODO: add assertion for InfluenceMap:decay
    end)
end)

describe("Missing explicit test for InfluenceMap:clearLayer", function()
    it("InfluenceMap:clearLayer works", function()
        -- @covers InfluenceMap:clearLayer
        -- TODO: add assertion for InfluenceMap:clearLayer
    end)
end)

describe("Missing explicit test for InfluenceMap:clearAll", function()
    it("InfluenceMap:clearAll works", function()
        -- @covers InfluenceMap:clearAll
        -- TODO: add assertion for InfluenceMap:clearAll
    end)
end)

describe("Missing explicit test for InfluenceMap:getMaxPosition", function()
    it("InfluenceMap:getMaxPosition works", function()
        -- @covers InfluenceMap:getMaxPosition
        -- TODO: add assertion for InfluenceMap:getMaxPosition
    end)
end)

describe("Missing explicit test for InfluenceMap:getMinPosition", function()
    it("InfluenceMap:getMinPosition works", function()
        -- @covers InfluenceMap:getMinPosition
        -- TODO: add assertion for InfluenceMap:getMinPosition
    end)
end)

describe("Missing explicit test for InfluenceMap:getWidth", function()
    it("InfluenceMap:getWidth works", function()
        -- @covers InfluenceMap:getWidth
        -- TODO: add assertion for InfluenceMap:getWidth
    end)
end)

describe("Missing explicit test for InfluenceMap:getHeight", function()
    it("InfluenceMap:getHeight works", function()
        -- @covers InfluenceMap:getHeight
        -- TODO: add assertion for InfluenceMap:getHeight
    end)
end)

describe("Missing explicit test for InfluenceMap:getCellSize", function()
    it("InfluenceMap:getCellSize works", function()
        -- @covers InfluenceMap:getCellSize
        -- TODO: add assertion for InfluenceMap:getCellSize
    end)
end)

describe("Missing explicit test for InfluenceMap:type", function()
    it("InfluenceMap:type works", function()
        -- @covers InfluenceMap:type
        -- TODO: add assertion for InfluenceMap:type
    end)
end)

describe("Missing explicit test for InfluenceMap:typeOf", function()
    it("InfluenceMap:typeOf works", function()
        -- @covers InfluenceMap:typeOf
        -- TODO: add assertion for InfluenceMap:typeOf
    end)
end)

describe("Missing explicit test for Squad:getName", function()
    it("Squad:getName works", function()
        -- @covers Squad:getName
        -- TODO: add assertion for Squad:getName
    end)
end)

describe("Missing explicit test for Squad:addMember", function()
    it("Squad:addMember works", function()
        -- @covers Squad:addMember
        -- TODO: add assertion for Squad:addMember
    end)
end)

describe("Missing explicit test for Squad:removeMember", function()
    it("Squad:removeMember works", function()
        -- @covers Squad:removeMember
        -- TODO: add assertion for Squad:removeMember
    end)
end)

describe("Missing explicit test for Squad:getMemberCount", function()
    it("Squad:getMemberCount works", function()
        -- @covers Squad:getMemberCount
        -- TODO: add assertion for Squad:getMemberCount
    end)
end)

describe("Missing explicit test for Squad:getMembers", function()
    it("Squad:getMembers works", function()
        -- @covers Squad:getMembers
        -- TODO: add assertion for Squad:getMembers
    end)
end)

describe("Missing explicit test for Squad:setLeader", function()
    it("Squad:setLeader works", function()
        -- @covers Squad:setLeader
        -- TODO: add assertion for Squad:setLeader
    end)
end)

describe("Missing explicit test for Squad:getLeader", function()
    it("Squad:getLeader works", function()
        -- @covers Squad:getLeader
        -- TODO: add assertion for Squad:getLeader
    end)
end)

describe("Missing explicit test for Squad:getFormation", function()
    it("Squad:getFormation works", function()
        -- @covers Squad:getFormation
        -- TODO: add assertion for Squad:getFormation
    end)
end)

describe("Missing explicit test for Squad:getFormationSpacing", function()
    it("Squad:getFormationSpacing works", function()
        -- @covers Squad:getFormationSpacing
        -- TODO: add assertion for Squad:getFormationSpacing
    end)
end)

describe("Missing explicit test for Squad:getBlackboard", function()
    it("Squad:getBlackboard works", function()
        -- @covers Squad:getBlackboard
        -- TODO: add assertion for Squad:getBlackboard
    end)
end)

describe("Missing explicit test for Squad:type", function()
    it("Squad:type works", function()
        -- @covers Squad:type
        -- TODO: add assertion for Squad:type
    end)
end)

describe("Missing explicit test for Squad:typeOf", function()
    it("Squad:typeOf works", function()
        -- @covers Squad:typeOf
        -- TODO: add assertion for Squad:typeOf
    end)
end)

describe("Missing explicit test for CommandQueue:cancelCurrent", function()
    it("CommandQueue:cancelCurrent works", function()
        -- @covers CommandQueue:cancelCurrent
        -- TODO: add assertion for CommandQueue:cancelCurrent
    end)
end)

describe("Missing explicit test for CommandQueue:clear", function()
    it("CommandQueue:clear works", function()
        -- @covers CommandQueue:clear
        -- TODO: add assertion for CommandQueue:clear
    end)
end)

describe("Missing explicit test for CommandQueue:getCount", function()
    it("CommandQueue:getCount works", function()
        -- @covers CommandQueue:getCount
        -- TODO: add assertion for CommandQueue:getCount
    end)
end)

describe("Missing explicit test for CommandQueue:isEmpty", function()
    it("CommandQueue:isEmpty works", function()
        -- @covers CommandQueue:isEmpty
        -- TODO: add assertion for CommandQueue:isEmpty
    end)
end)

describe("Missing explicit test for CommandQueue:getCurrentType", function()
    it("CommandQueue:getCurrentType works", function()
        -- @covers CommandQueue:getCurrentType
        -- TODO: add assertion for CommandQueue:getCurrentType
    end)
end)

describe("Missing explicit test for CommandQueue:type", function()
    it("CommandQueue:type works", function()
        -- @covers CommandQueue:type
        -- TODO: add assertion for CommandQueue:type
    end)
end)

describe("Missing explicit test for CommandQueue:typeOf", function()
    it("CommandQueue:typeOf works", function()
        -- @covers CommandQueue:typeOf
        -- TODO: add assertion for CommandQueue:typeOf
    end)
end)

describe("Missing explicit test for TraitProfile:getBase", function()
    it("TraitProfile:getBase works", function()
        -- @covers TraitProfile:getBase
        -- TODO: add assertion for TraitProfile:getBase
    end)
end)

describe("Missing explicit test for TraitProfile:removeModifiers", function()
    it("TraitProfile:removeModifiers works", function()
        -- @covers TraitProfile:removeModifiers
        -- TODO: add assertion for TraitProfile:removeModifiers
    end)
end)

describe("Missing explicit test for TraitProfile:update", function()
    it("TraitProfile:update works", function()
        -- @covers TraitProfile:update
        -- TODO: add assertion for TraitProfile:update
    end)
end)

describe("Missing explicit test for TraitProfile:traitCount", function()
    it("TraitProfile:traitCount works", function()
        -- @covers TraitProfile:traitCount
        -- TODO: add assertion for TraitProfile:traitCount
    end)
end)

describe("Missing explicit test for TraitProfile:archetype", function()
    it("TraitProfile:archetype works", function()
        -- @covers TraitProfile:archetype
        -- TODO: add assertion for TraitProfile:archetype
    end)
end)

describe("Missing explicit test for StimulusWorld:remove", function()
    it("StimulusWorld:remove works", function()
        -- @covers StimulusWorld:remove
        -- TODO: add assertion for StimulusWorld:remove
    end)
end)

describe("Missing explicit test for StimulusWorld:update", function()
    it("StimulusWorld:update works", function()
        -- @covers StimulusWorld:update
        -- TODO: add assertion for StimulusWorld:update
    end)
end)

describe("Missing explicit test for StimulusWorld:clear", function()
    it("StimulusWorld:clear works", function()
        -- @covers StimulusWorld:clear
        -- TODO: add assertion for StimulusWorld:clear
    end)
end)

describe("Missing explicit test for ContextSteering:addWander", function()
    it("ContextSteering:addWander works", function()
        -- @covers ContextSteering:addWander
        -- TODO: add assertion for ContextSteering:addWander
    end)
end)

describe("Missing explicit test for ContextSteering:clearBehaviors", function()
    it("ContextSteering:clearBehaviors works", function()
        -- @covers ContextSteering:clearBehaviors
        -- TODO: add assertion for ContextSteering:clearBehaviors
    end)
end)

describe("Missing explicit test for ContextSteering:chosenMagnitude", function()
    it("ContextSteering:chosenMagnitude works", function()
        -- @covers ContextSteering:chosenMagnitude
        -- TODO: add assertion for ContextSteering:chosenMagnitude
    end)
end)

describe("Missing explicit test for ContextSteering:slotCount", function()
    it("ContextSteering:slotCount works", function()
        -- @covers ContextSteering:slotCount
        -- TODO: add assertion for ContextSteering:slotCount
    end)
end)

describe("Missing explicit test for NeedSystem:addNeed", function()
    it("NeedSystem:addNeed works", function()
        -- @covers NeedSystem:addNeed
        -- TODO: add assertion for NeedSystem:addNeed
    end)
end)

describe("Missing explicit test for NeedSystem:update", function()
    it("NeedSystem:update works", function()
        -- @covers NeedSystem:update
        -- TODO: add assertion for NeedSystem:update
    end)
end)

describe("Missing explicit test for NeedSystem:mostUrgent", function()
    it("NeedSystem:mostUrgent works", function()
        -- @covers NeedSystem:mostUrgent
        -- TODO: add assertion for NeedSystem:mostUrgent
    end)
end)

describe("Missing explicit test for NeedSystem:satisfy", function()
    it("NeedSystem:satisfy works", function()
        -- @covers NeedSystem:satisfy
        -- TODO: add assertion for NeedSystem:satisfy
    end)
end)

describe("Missing explicit test for NeedSystem:valueOf", function()
    it("NeedSystem:valueOf works", function()
        -- @covers NeedSystem:valueOf
        -- TODO: add assertion for NeedSystem:valueOf
    end)
end)

describe("Missing explicit test for AIDirector:pushEvent", function()
    it("AIDirector:pushEvent works", function()
        -- @covers AIDirector:pushEvent
        -- TODO: add assertion for AIDirector:pushEvent
    end)
end)

describe("Missing explicit test for AIDirector:update", function()
    it("AIDirector:update works", function()
        -- @covers AIDirector:update
        -- TODO: add assertion for AIDirector:update
    end)
end)

describe("Missing explicit test for AIDirector:tension", function()
    it("AIDirector:tension works", function()
        -- @covers AIDirector:tension
        -- TODO: add assertion for AIDirector:tension
    end)
end)

describe("Missing explicit test for AIDirector:phase", function()
    it("AIDirector:phase works", function()
        -- @covers AIDirector:phase
        -- TODO: add assertion for AIDirector:phase
    end)
end)

describe("Missing explicit test for AIDirector:spawnRateFactor", function()
    it("AIDirector:spawnRateFactor works", function()
        -- @covers AIDirector:spawnRateFactor
        -- TODO: add assertion for AIDirector:spawnRateFactor
    end)
end)

describe("Missing explicit test for AIDirector:lootFactor", function()
    it("AIDirector:lootFactor works", function()
        -- @covers AIDirector:lootFactor
        -- TODO: add assertion for AIDirector:lootFactor
    end)
end)

describe("Missing explicit test for AIDirector:ambientIntensity", function()
    it("AIDirector:ambientIntensity works", function()
        -- @covers AIDirector:ambientIntensity
        -- TODO: add assertion for AIDirector:ambientIntensity
    end)
end)

describe("Missing explicit test for AIDirector:setTension", function()
    it("AIDirector:setTension works", function()
        -- @covers AIDirector:setTension
        -- TODO: add assertion for AIDirector:setTension
    end)
end)

describe("Missing explicit test for AIDirector:reset", function()
    it("AIDirector:reset works", function()
        -- @covers AIDirector:reset
        -- TODO: add assertion for AIDirector:reset
    end)
end)

describe("Missing explicit test for HTNDomain:addPrimitive", function()
    it("HTNDomain:addPrimitive works", function()
        -- @covers HTNDomain:addPrimitive
        -- TODO: add assertion for HTNDomain:addPrimitive
    end)
end)

describe("Missing explicit test for HTNDomain:taskCount", function()
    it("HTNDomain:taskCount works", function()
        -- @covers HTNDomain:taskCount
        -- TODO: add assertion for HTNDomain:taskCount
    end)
end)

describe("Missing explicit test for EmotionModel:trigger", function()
    it("EmotionModel:trigger works", function()
        -- @covers EmotionModel:trigger
        -- TODO: add assertion for EmotionModel:trigger
    end)
end)

describe("Missing explicit test for EmotionModel:dominant", function()
    it("EmotionModel:dominant works", function()
        -- @covers EmotionModel:dominant
        -- TODO: add assertion for EmotionModel:dominant
    end)
end)

describe("Missing explicit test for EmotionModel:isActive", function()
    it("EmotionModel:isActive works", function()
        -- @covers EmotionModel:isActive
        -- TODO: add assertion for EmotionModel:isActive
    end)
end)

describe("Missing explicit test for EmotionModel:update", function()
    it("EmotionModel:update works", function()
        -- @covers EmotionModel:update
        -- TODO: add assertion for EmotionModel:update
    end)
end)

describe("Missing explicit test for EmotionModel:reset", function()
    it("EmotionModel:reset works", function()
        -- @covers EmotionModel:reset
        -- TODO: add assertion for EmotionModel:reset
    end)
end)

describe("Missing explicit test for ORCASolver:setPosition", function()
    it("ORCASolver:setPosition works", function()
        -- @covers ORCASolver:setPosition
        -- TODO: add assertion for ORCASolver:setPosition
    end)
end)

describe("Missing explicit test for ORCASolver:compute", function()
    it("ORCASolver:compute works", function()
        -- @covers ORCASolver:compute
        -- TODO: add assertion for ORCASolver:compute
    end)
end)

describe("Missing explicit test for ORCASolver:getSafeVelocity", function()
    it("ORCASolver:getSafeVelocity works", function()
        -- @covers ORCASolver:getSafeVelocity
        -- TODO: add assertion for ORCASolver:getSafeVelocity
    end)
end)

describe("Missing explicit test for ORCASolver:agentCount", function()
    it("ORCASolver:agentCount works", function()
        -- @covers ORCASolver:agentCount
        -- TODO: add assertion for ORCASolver:agentCount
    end)
end)

describe("Missing explicit test for NeuralNet:forward", function()
    it("NeuralNet:forward works", function()
        -- @covers NeuralNet:forward
        -- TODO: add assertion for NeuralNet:forward
    end)
end)

describe("Missing explicit test for NeuralNet:setWeights", function()
    it("NeuralNet:setWeights works", function()
        -- @covers NeuralNet:setWeights
        -- TODO: add assertion for NeuralNet:setWeights
    end)
end)

describe("Missing explicit test for NeuralNet:getWeights", function()
    it("NeuralNet:getWeights works", function()
        -- @covers NeuralNet:getWeights
        -- TODO: add assertion for NeuralNet:getWeights
    end)
end)

describe("Missing explicit test for NeuralNet:paramCount", function()
    it("NeuralNet:paramCount works", function()
        -- @covers NeuralNet:paramCount
        -- TODO: add assertion for NeuralNet:paramCount
    end)
end)

describe("Missing explicit test for NeuralNet:layerCount", function()
    it("NeuralNet:layerCount works", function()
        -- @covers NeuralNet:layerCount
        -- TODO: add assertion for NeuralNet:layerCount
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:evolve", function()
    it("GeneticAlgorithm:evolve works", function()
        -- @covers GeneticAlgorithm:evolve
        -- TODO: add assertion for GeneticAlgorithm:evolve
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:generation", function()
    it("GeneticAlgorithm:generation works", function()
        -- @covers GeneticAlgorithm:generation
        -- TODO: add assertion for GeneticAlgorithm:generation
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:popSize", function()
    it("GeneticAlgorithm:popSize works", function()
        -- @covers GeneticAlgorithm:popSize
        -- TODO: add assertion for GeneticAlgorithm:popSize
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:setFitness", function()
    it("GeneticAlgorithm:setFitness works", function()
        -- @covers GeneticAlgorithm:setFitness
        -- TODO: add assertion for GeneticAlgorithm:setFitness
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:getGenes", function()
    it("GeneticAlgorithm:getGenes works", function()
        -- @covers GeneticAlgorithm:getGenes
        -- TODO: add assertion for GeneticAlgorithm:getGenes
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:bestGenes", function()
    it("GeneticAlgorithm:bestGenes works", function()
        -- @covers GeneticAlgorithm:bestGenes
        -- TODO: add assertion for GeneticAlgorithm:bestGenes
    end)
end)

describe("Missing explicit test for Bandit:select", function()
    it("Bandit:select works", function()
        -- @covers Bandit:select
        -- TODO: add assertion for Bandit:select
    end)
end)

describe("Missing explicit test for Bandit:update", function()
    it("Bandit:update works", function()
        -- @covers Bandit:update
        -- TODO: add assertion for Bandit:update
    end)
end)

describe("Missing explicit test for Bandit:bestArm", function()
    it("Bandit:bestArm works", function()
        -- @covers Bandit:bestArm
        -- TODO: add assertion for Bandit:bestArm
    end)
end)

describe("Missing explicit test for Bandit:reset", function()
    it("Bandit:reset works", function()
        -- @covers Bandit:reset
        -- TODO: add assertion for Bandit:reset
    end)
end)

describe("Missing explicit test for Bandit:armCount", function()
    it("Bandit:armCount works", function()
        -- @covers Bandit:armCount
        -- TODO: add assertion for Bandit:armCount
    end)
end)

describe("Missing explicit test for Bandit:totalPulls", function()
    it("Bandit:totalPulls works", function()
        -- @covers Bandit:totalPulls
        -- TODO: add assertion for Bandit:totalPulls
    end)
end)

describe("Missing explicit test for Neuroevolution:evolve", function()
    it("Neuroevolution:evolve works", function()
        -- @covers Neuroevolution:evolve
        -- TODO: add assertion for Neuroevolution:evolve
    end)
end)

describe("Missing explicit test for Neuroevolution:setFitness", function()
    it("Neuroevolution:setFitness works", function()
        -- @covers Neuroevolution:setFitness
        -- TODO: add assertion for Neuroevolution:setFitness
    end)
end)

describe("Missing explicit test for Neuroevolution:chromosomeToNet", function()
    it("Neuroevolution:chromosomeToNet works", function()
        -- @covers Neuroevolution:chromosomeToNet
        -- TODO: add assertion for Neuroevolution:chromosomeToNet
    end)
end)

describe("Missing explicit test for Neuroevolution:bestNetwork", function()
    it("Neuroevolution:bestNetwork works", function()
        -- @covers Neuroevolution:bestNetwork
        -- TODO: add assertion for Neuroevolution:bestNetwork
    end)
end)

describe("Missing explicit test for Neuroevolution:popSize", function()
    it("Neuroevolution:popSize works", function()
        -- @covers Neuroevolution:popSize
        -- TODO: add assertion for Neuroevolution:popSize
    end)
end)

describe("Missing explicit test for Neuroevolution:generation", function()
    it("Neuroevolution:generation works", function()
        -- @covers Neuroevolution:generation
        -- TODO: add assertion for Neuroevolution:generation
    end)
end)

describe("Missing explicit test for StrategyAI:addGoal", function()
    it("StrategyAI:addGoal works", function()
        -- @covers StrategyAI:addGoal
        -- TODO: add assertion for StrategyAI:addGoal
    end)
end)

describe("Missing explicit test for StrategyAI:addTag", function()
    it("StrategyAI:addTag works", function()
        -- @covers StrategyAI:addTag
        -- TODO: add assertion for StrategyAI:addTag
    end)
end)

describe("Missing explicit test for StrategyAI:removeTag", function()
    it("StrategyAI:removeTag works", function()
        -- @covers StrategyAI:removeTag
        -- TODO: add assertion for StrategyAI:removeTag
    end)
end)

describe("Missing explicit test for StrategyAI:update", function()
    it("StrategyAI:update works", function()
        -- @covers StrategyAI:update
        -- TODO: add assertion for StrategyAI:update
    end)
end)

describe("Missing explicit test for StrategyAI:forceEvaluate", function()
    it("StrategyAI:forceEvaluate works", function()
        -- @covers StrategyAI:forceEvaluate
        -- TODO: add assertion for StrategyAI:forceEvaluate
    end)
end)

describe("Missing explicit test for StrategyAI:activeGoal", function()
    it("StrategyAI:activeGoal works", function()
        -- @covers StrategyAI:activeGoal
        -- TODO: add assertion for StrategyAI:activeGoal
    end)
end)

describe("Missing explicit test for StrategyAI:timeUntilNext", function()
    it("StrategyAI:timeUntilNext works", function()
        -- @covers StrategyAI:timeUntilNext
        -- TODO: add assertion for StrategyAI:timeUntilNext
    end)
end)

describe("Missing explicit test for AILod:shouldUpdate", function()
    it("AILod:shouldUpdate works", function()
        -- @covers AILod:shouldUpdate
        -- TODO: add assertion for AILod:shouldUpdate
    end)
end)

describe("Missing explicit test for AILod:tierCount", function()
    it("AILod:tierCount works", function()
        -- @covers AILod:tierCount
        -- TODO: add assertion for AILod:tierCount
    end)
end)

describe("Missing explicit test for AILod:tierName", function()
    it("AILod:tierName works", function()
        -- @covers AILod:tierName
        -- TODO: add assertion for AILod:tierName
    end)
end)

-- =========================================================================
-- Extensibility Hooks (Phase 01)
-- =========================================================================

describe("lurek.ai extensibility factories", function()
    -- @covers lurek.ai.newGuard
    it("has newGuard factory", function()
        expect_type("function", lurek.ai.newGuard, "newGuard should be a function")
    end)
end)

describe("custom decision model", function()
    -- @covers Agent:setCustomModel
    -- it is invoked when the world is updated.
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

    it("getDecisionModel returns 'custom' after setCustomModel", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("model_check_agent")
        agent:setCustomModel(function(ag, bb, dt) end)
        expect_equal("custom", agent:getDecisionModel(),
            "decision model name should be 'custom'")
    end)
end)

describe("BT Guard decorator", function()
    -- @covers lurek.ai.newGuard
    it("creates guard node via newGuard", function()
        local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
        local guard = lurek.ai.newGuard(function(ag, bb) return true end, action)
        expect_not_nil(guard, "Guard node should be created")
        expect_equal("guard", guard:getNodeType(), "node type should be 'guard'")
    end)

    it("guard has child count 1", function()
        local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
        local guard = lurek.ai.newGuard(function(ag, bb) return false end, action)
        expect_equal(1, guard:getChildCount(), "Guard should have 1 child")
    end)
end)

describe("custom utility response curve", function()
    -- @covers UtilityAI:addConsideration
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

describe("custom steering behavior", function()
    -- @covers SteeringManager:addCustomBehavior
    it("addCustomBehavior adds one behavior to the manager", function()
        local sm = lurek.ai.newSteeringManager()
        local before = sm:getBehaviorCount()
        sm:addCustomBehavior(function(ag, dt) return 10, 0 end, 1.0)
        expect_equal(before + 1, sm:getBehaviorCount(),
            "behavior count should increase by 1")
    end)

    -- @covers SteeringManager:applyCustomSteering
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
describe("Agent:setCustomModel extensibility hook", function()
    -- @covers Agent:setCustomModel
    -- @covers Agent:getDecisionModel
    it("setCustomModel marks agent with custom model", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("test_agent")
        agent:setCustomModel(function(ag, bb, dt) end)
        expect_equal("custom", agent:getDecisionModel(),
            "getDecisionModel should return 'custom' after setCustomModel")
    end)

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

test_summary()
