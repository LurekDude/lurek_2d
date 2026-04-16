-- Lurek2D AI API Tests

-- =========================================================================
-- 1. lurek.ai module exists
-- =========================================================================

-- @description Verifies the AI namespace exposes every documented world, planner, decision-model, behavior-tree, and pathfinding factory needed by the Lua API.
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
    -- @covers lurek.pathfinding.newPathFlowField
    -- @covers lurek.pathfinding.newPathGrid
    -- @description Checks that the AI namespace itself is registered as a Lua table.
    it("lurek.ai is a table", function()
        expect_type("table", lurek.ai)
    end)

    -- @description Confirms the AI world factory is exported as a function.
    it("has newWorld factory", function()
        expect_type("function", lurek.ai.newWorld)
    end)

    -- @description Confirms the blackboard factory is exported as a function.
    it("has newBlackboard factory", function()
        expect_type("function", lurek.ai.newBlackboard)
    end)

    -- @description Confirms the finite-state-machine factory is exported as a function.
    it("has newStateMachine factory", function()
        expect_type("function", lurek.ai.newStateMachine)
    end)

    -- @description Confirms the behavior-tree factory is exported as a function.
    it("has newBehaviorTree factory", function()
        expect_type("function", lurek.ai.newBehaviorTree)
    end)

    -- @description Confirms the steering manager factory is exported as a function.
    it("has newSteeringManager factory", function()
        expect_type("function", lurek.ai.newSteeringManager)
    end)

    -- @description Verifies path-grid creation lives under lurek.pathfinding rather than the AI namespace.
    it("has no newPathGrid factory (moved to pathfinding)", function()
        expect_type("function", lurek.pathfinding.newPathGrid)
    end)

    -- @description Verifies flow-field creation lives under lurek.pathfinding rather than the AI namespace.
    it("has no newFlowField factory (moved to pathfinding)", function()
        expect_type("function", lurek.pathfinding.newPathFlowField)
    end)

    -- @description Confirms the Q-learning factory is exported as a function.
    it("has newQLearner factory", function()
        expect_type("function", lurek.ai.newQLearner)
    end)

    -- @description Confirms the utility-AI factory is exported as a function.
    it("has newUtilityAI factory", function()
        expect_type("function", lurek.ai.newUtilityAI)
    end)

    -- @description Confirms the GOAP planner factory is exported as a function.
    it("has newGOAPPlanner factory", function()
        expect_type("function", lurek.ai.newGOAPPlanner)
    end)

    -- @description Confirms the influence-map factory is exported as a function.
    it("has newInfluenceMap factory", function()
        expect_type("function", lurek.ai.newInfluenceMap)
    end)

    -- @description Confirms the squad factory is exported as a function.
    it("has newSquad factory", function()
        expect_type("function", lurek.ai.newSquad)
    end)

    -- @description Confirms the command-queue factory is exported as a function.
    it("has newCommandQueue factory", function()
        expect_type("function", lurek.ai.newCommandQueue)
    end)

    -- @description Verifies every behavior-tree node constructor used by the Lua API is exposed.
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
-- @description Exercises AI world creation, agent registration and removal, duplicate-name rejection, movement updates, and global blackboard access.
describe("lurek.ai AIWorld", function()
    -- @description Creates an AI world and verifies the returned userdata reports the expected type.
    it("creates a new world", function()
        local w = lurek.ai.newWorld()
        expect_not_nil(w, "world exists")
        expect_equal("AIWorld", w:type(), "type check")
    end)

    -- @description Adds a named agent to the world and verifies the agent count increments.
    it("adds agents by name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        expect_not_nil(a, "agent returned")
        expect_equal(1, w:getAgentCount(), "agent count")
    end)

    -- @description Retrieves an agent by its registered name and verifies the correct agent is returned.
    it("gets agent by name", function()
        local w = lurek.ai.newWorld()
        w:addAgent("hero")
        local a = w:getAgent("hero")
        expect_not_nil(a, "found agent")
        expect_equal("hero", a:getName())
    end)

    -- @description Verifies getAgent returns nil for names that are not present in the world.
    it("returns nil for unknown agent", function()
        local w = lurek.ai.newWorld()
        expect_nil(w:getAgent("nonexistent"))
    end)

    -- @description Removes an existing agent and verifies the world count drops back to zero.
    it("removes agents", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        w:removeAgent(a)
        expect_equal(0, w:getAgentCount())
    end)

    -- @description Applies velocity over half a second and verifies the world update moves the agent position by the expected amount.
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

    -- @description Verifies adding a second agent with the same name raises an error instead of silently replacing the first.
    it("errors on duplicate agent name", function()
        local w = lurek.ai.newWorld()
        w:addAgent("hero")
        expect_error(function() w:addAgent("hero") end, "duplicate agent")
    end)

    -- @description Confirms each world exposes a shared global blackboard userdata.
    it("provides global blackboard", function()
        local w = lurek.ai.newWorld()
        local bb = w:getGlobalBlackboard()
        expect_not_nil(bb, "global bb exists")
        expect_equal("Blackboard", bb:type())
    end)

    -- @description Verifies a world can hold multiple simultaneously registered agents.
    it("supports multiple agents", function()
        local w = lurek.ai.newWorld()
        w:addAgent("alpha")
        w:addAgent("beta")
        w:addAgent("gamma")
        expect_equal(3, w:getAgentCount())
    end)

    -- @description Adds and removes agents in sequence to verify the world count reflects the current roster accurately.
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
-- @description Verifies individual agent userdata supports naming, movement state, priorities, decision-model selection, tag management, and per-agent blackboards.
describe("lurek.ai Agent", function()
    -- @description Confirms agent userdata reports the expected runtime type string.
    it("type returns Agent", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("hero")
        expect_equal("Agent", a:type())
    end)

    -- @description Verifies an agent returns the exact name it was created with.
    it("getName returns name", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("warrior")
        expect_equal("warrior", a:getName())
    end)

    -- @description Sets a position and verifies both coordinates round-trip without drift.
    it("setPosition / getPosition roundtrip", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setPosition(100, 200)
        local x, y = a:getPosition()
        expect_near(100, x, 0.01)
        expect_near(200, y, 0.01)
    end)

    -- @description Sets a velocity vector and verifies both components round-trip correctly.
    it("setVelocity / getVelocity roundtrip", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setVelocity(5, -3)
        local vx, vy = a:getVelocity()
        expect_near(5, vx, 0.01)
        expect_near(-3, vy, 0.01)
    end)

    -- @description Verifies custom max-speed values persist through setter and getter calls.
    it("setMaxSpeed / getMaxSpeed", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setMaxSpeed(250)
        expect_near(250, a:getMaxSpeed(), 0.01)
    end)

    -- @description Verifies custom max-force values persist through setter and getter calls.
    it("setMaxForce / getMaxForce", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setMaxForce(500)
        expect_near(500, a:getMaxForce(), 0.01)
    end)

    -- @description Verifies integer agent priority values persist through setter and getter calls.
    it("setPriority / getPriority", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setPriority(7)
        expect_equal(7, a:getPriority())
    end)

    -- @description Switches the agent to FSM decision mode and verifies the selected model is stored.
    it("setDecisionModel / getDecisionModel for fsm", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("fsm")
        expect_equal("fsm", a:getDecisionModel())
    end)

    -- @description Switches the agent to behavior-tree decision mode and verifies the selected model is stored.
    it("setDecisionModel / getDecisionModel for bt", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("bt")
        expect_equal("bt", a:getDecisionModel())
    end)

    -- @description Switches the agent to steering decision mode and verifies the selected model is stored.
    it("setDecisionModel / getDecisionModel for steering", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:setDecisionModel("steering")
        expect_equal("steering", a:getDecisionModel())
    end)

    -- @description Adds and removes a tag to verify tag membership queries update as expected.
    it("addTag / hasTag / removeTag", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        expect_false(a:hasTag("enemy"), "no tag initially")
        a:addTag("enemy")
        expect_true(a:hasTag("enemy"), "tag added")
        a:removeTag("enemy")
        expect_false(a:hasTag("enemy"), "tag removed")
    end)

    -- @description Verifies an agent can hold multiple tags simultaneously while absent tags still report false.
    it("multiple tags", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        a:addTag("fast")
        a:addTag("flying")
        expect_true(a:hasTag("fast"))
        expect_true(a:hasTag("flying"))
        expect_false(a:hasTag("slow"))
    end)

    -- @description Confirms each agent exposes its own blackboard userdata.
    it("getBlackboard returns Blackboard", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("a")
        local bb = a:getBlackboard()
        expect_not_nil(bb)
        expect_equal("Blackboard", bb:type())
    end)

    -- @description Verifies newly created agents start at the origin by default.
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
-- @description Covers typed blackboard storage for numbers, booleans, and strings plus key existence, removal, clearing, sizing, and key enumeration.
describe("lurek.ai Blackboard", function()
    -- @description Confirms blackboard userdata reports the expected runtime type string.
    it("type returns Blackboard", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("Blackboard", bb:type())
    end)

    -- @description Stores a numeric value and verifies it round-trips through the blackboard.
    it("setNumber / getNumber roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("health", 42.5)
        expect_near(42.5, bb:getNumber("health"), 0.001)
    end)

    -- @description Verifies missing numeric keys return the caller-provided default value.
    it("getNumber returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_near(99, bb:getNumber("missing", 99), 0.001)
    end)

    -- @description Verifies missing numeric keys default to zero when no fallback is supplied.
    it("getNumber returns 0 without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_near(0, bb:getNumber("missing"), 0.001)
    end)

    -- @description Stores a boolean value and verifies it round-trips through the blackboard.
    it("setBool / getBool roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setBool("alive", true)
        expect_true(bb:getBool("alive"))
    end)

    -- @description Verifies missing boolean keys return the caller-provided default value.
    it("getBool returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_true(bb:getBool("missing", true))
    end)

    -- @description Verifies missing boolean keys default to false when no fallback is supplied.
    it("getBool returns false without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_false(bb:getBool("missing"))
    end)

    -- @description Stores a string value and verifies it round-trips through the blackboard.
    it("setString / getString roundtrip", function()
        local bb = lurek.ai.newBlackboard()
        bb:setString("name", "hero")
        expect_equal("hero", bb:getString("name"))
    end)

    -- @description Verifies missing string keys return the caller-provided fallback value.
    it("getString returns default when key missing", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("none", bb:getString("missing", "none"))
    end)

    -- @description Verifies missing string keys default to the empty string when no fallback is supplied.
    it("getString returns empty without explicit default", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal("", bb:getString("missing"))
    end)

    -- @description Confirms has reports true for keys that were previously stored.
    it("has returns true when key exists", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        expect_true(bb:has("hp"))
    end)

    -- @description Confirms has reports false for keys that were never stored.
    it("has returns false when key absent", function()
        local bb = lurek.ai.newBlackboard()
        expect_false(bb:has("missing"))
    end)

    -- @description Removes a stored key and verifies it no longer exists afterwards.
    it("remove deletes a key", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("hp", 10)
        bb:remove("hp")
        expect_false(bb:has("hp"))
    end)

    -- @description Clears a populated blackboard and verifies the size returns to zero.
    it("clear removes all keys", function()
        local bb = lurek.ai.newBlackboard()
        bb:setNumber("a", 1)
        bb:setBool("b", true)
        bb:setString("c", "x")
        bb:clear()
        expect_equal(0, bb:getSize())
    end)

    -- @description Verifies the reported key count tracks inserted values across multiple types.
    it("getSize returns count", function()
        local bb = lurek.ai.newBlackboard()
        expect_equal(0, bb:getSize())
        bb:setNumber("a", 1)
        expect_equal(1, bb:getSize())
        bb:setBool("b", true)
        expect_equal(2, bb:getSize())
    end)

    -- @description Verifies key enumeration returns all stored names in a Lua table.
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
-- @description Verifies finite-state-machine construction, state registration, initial-state selection, forced transitions, timers, and transition definitions.
describe("lurek.ai StateMachine", function()
    -- @description Confirms state-machine userdata reports the expected runtime type string.
    it("type returns StateMachine", function()
        local fsm = lurek.ai.newStateMachine()
        expect_equal("StateMachine", fsm:type())
    end)

    -- @description Adds a minimal state and verifies the operation succeeds without errors.
    it("addState does not error", function()
        local fsm = lurek.ai.newStateMachine()
        expect_no_error(function()
            fsm:addState("idle", { onEnter = function() end })
        end)
    end)

    -- @description Adds a state with enter, update, and exit callbacks to verify the full callback table is accepted.
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

    -- @description Sets an initial state and verifies it becomes the current state immediately.
    it("setInitialState sets current state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        expect_equal("idle", fsm:getCurrentState())
    end)

    -- @description Verifies current state is nil until an initial state is selected.
    it("getCurrentState returns nil before setting", function()
        local fsm = lurek.ai.newStateMachine()
        expect_nil(fsm:getCurrentState())
    end)

    -- @description Forces a transition to another state and verifies the current-state query updates accordingly.
    it("forceState changes state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("attack", {})
        fsm:setInitialState("idle")
        fsm:forceState("attack")
        expect_equal("attack", fsm:getCurrentState())
    end)

    -- @description Verifies forcing a state resets the time-in-state counter to zero.
    it("getTimeInState starts at zero after forceState", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:setInitialState("idle")
        fsm:forceState("idle")
        expect_near(0, fsm:getTimeInState(), 0.01)
    end)

    -- @description Adds an unconditional transition between states and verifies the definition call succeeds.
    it("addTransition does not error", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("walk", {})
        expect_no_error(function()
            fsm:addTransition("idle", "walk", nil, 0)
        end)
    end)

    -- @description Adds a guarded transition and verifies the FSM accepts guard callbacks in transition definitions.
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
-- @description Covers behavior-tree construction, default execution status, and root-node assignment.
describe("lurek.ai BehaviorTree", function()
    -- @description Confirms behavior-tree userdata reports the expected runtime type string.
    it("type returns BehaviorTree", function()
        local bt = lurek.ai.newBehaviorTree()
        expect_equal("BehaviorTree", bt:type())
    end)

    -- @description Verifies a fresh behavior tree starts with a success status before any execution occurs.
    it("getLastStatus returns success initially", function()
        local bt = lurek.ai.newBehaviorTree()
        expect_equal("success", bt:getLastStatus())
    end)

    -- @description Assigns a selector node as the tree root and verifies the operation succeeds without errors.
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
-- @description Verifies behavior-tree node factories, node-type introspection, child-management rules, decorator child assignment, and repeater count handling.
describe("lurek.ai BTNode", function()
    -- @description Confirms selector factories return BTNode userdata.
    it("newSelector returns BTNode type", function()
        local n = lurek.ai.newSelector()
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms sequence factories return BTNode userdata.
    it("newSequence returns BTNode type", function()
        local n = lurek.ai.newSequence()
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms parallel factories return BTNode userdata.
    it("newParallel returns BTNode type", function()
        local n = lurek.ai.newParallel()
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms inverter factories return BTNode userdata.
    it("newInverter returns BTNode type", function()
        local n = lurek.ai.newInverter()
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms repeater factories return BTNode userdata.
    it("newRepeater returns BTNode type", function()
        local n = lurek.ai.newRepeater()
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms succeeder factories return BTNode userdata.
    it("newSucceeder returns BTNode type", function()
        local n = lurek.ai.newSucceeder()
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms action-node factories return BTNode userdata.
    it("newAction returns BTNode type", function()
        local n = lurek.ai.newAction(function() return "success" end)
        expect_equal("BTNode", n:type())
    end)

    -- @description Confirms condition-node factories return BTNode userdata.
    it("newCondition returns BTNode type", function()
        local n = lurek.ai.newCondition(function() return true end)
        expect_equal("BTNode", n:type())
    end)

    -- @description Verifies selector nodes report the correct node-type identifier.
    it("getNodeType returns selector", function()
        expect_equal("selector", lurek.ai.newSelector():getNodeType())
    end)

    -- @description Verifies sequence nodes report the correct node-type identifier.
    it("getNodeType returns sequence", function()
        expect_equal("sequence", lurek.ai.newSequence():getNodeType())
    end)

    -- @description Verifies parallel nodes report the correct node-type identifier.
    it("getNodeType returns parallel", function()
        expect_equal("parallel", lurek.ai.newParallel():getNodeType())
    end)

    -- @description Verifies inverter nodes report the correct node-type identifier.
    it("getNodeType returns inverter", function()
        expect_equal("inverter", lurek.ai.newInverter():getNodeType())
    end)

    -- @description Verifies repeater nodes report the correct node-type identifier.
    it("getNodeType returns repeater", function()
        expect_equal("repeater", lurek.ai.newRepeater():getNodeType())
    end)

    -- @description Verifies succeeder nodes report the correct node-type identifier.
    it("getNodeType returns succeeder", function()
        expect_equal("succeeder", lurek.ai.newSucceeder():getNodeType())
    end)

    -- @description Verifies action nodes report the correct node-type identifier.
    it("getNodeType returns action", function()
        expect_equal("action", lurek.ai.newAction(function() end):getNodeType())
    end)

    -- @description Verifies condition nodes report the correct node-type identifier.
    it("getNodeType returns condition", function()
        expect_equal("condition", lurek.ai.newCondition(function() end):getNodeType())
    end)

    -- @description Adds a child to a selector and verifies the child count increments.
    it("addChild on Selector increases child count", function()
        local sel = lurek.ai.newSelector()
        expect_equal(0, sel:getChildCount())
        local act = lurek.ai.newAction(function() end)
        sel:addChild(act)
        expect_equal(1, sel:getChildCount())
    end)

    -- @description Adds multiple children to a sequence and verifies the total child count matches.
    it("addChild on Sequence increases child count", function()
        local seq = lurek.ai.newSequence()
        local a1 = lurek.ai.newAction(function() end)
        local a2 = lurek.ai.newAction(function() end)
        seq:addChild(a1)
        seq:addChild(a2)
        expect_equal(2, seq:getChildCount())
    end)

    -- @description Adds a child to a parallel node and verifies the child count increments.
    it("addChild on Parallel increases child count", function()
        local par = lurek.ai.newParallel()
        par:addChild(lurek.ai.newAction(function() end))
        expect_equal(1, par:getChildCount())
    end)

    -- @description Verifies leaf action nodes reject child insertion instead of behaving like composites.
    it("addChild on Action errors", function()
        local act = lurek.ai.newAction(function() end)
        local child = lurek.ai.newAction(function() end)
        expect_error(function()
            act:addChild(child)
        end, "addChild on Action should error")
    end)

    -- @description Verifies leaf condition nodes reject child insertion instead of behaving like composites.
    it("addChild on Condition errors", function()
        local cond = lurek.ai.newCondition(function() return true end)
        local child = lurek.ai.newAction(function() end)
        expect_error(function()
            cond:addChild(child)
        end, "addChild on Condition should error")
    end)

    -- @description Assigns a child to an inverter decorator and verifies the call succeeds.
    it("setChild on Inverter", function()
        local inv = lurek.ai.newInverter()
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            inv:setChild(act)
        end)
    end)

    -- @description Assigns a child to a repeater decorator and verifies the call succeeds.
    it("setChild on Repeater", function()
        local rep = lurek.ai.newRepeater(3)
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            rep:setChild(act)
        end)
    end)

    -- @description Assigns a child to a succeeder decorator and verifies the call succeeds.
    it("setChild on Succeeder", function()
        local suc = lurek.ai.newSucceeder()
        local act = lurek.ai.newAction(function() end)
        expect_no_error(function()
            suc:setChild(act)
        end)
    end)

    -- @description Verifies repeater nodes expose mutable repeat counts through setters and getters.
    it("setCount / getCount on Repeater", function()
        local rep = lurek.ai.newRepeater(5)
        expect_equal(5, rep:getCount())
        rep:setCount(10)
        expect_equal(10, rep:getCount())
    end)

    -- @description Verifies non-repeater nodes report zero when queried for repeat count.
    it("getCount on non-Repeater returns 0", function()
        local sel = lurek.ai.newSelector()
        expect_equal(0, sel:getCount())
    end)

    -- @description Verifies parallel nodes accept success-policy configuration without error.
    it("setSuccessPolicy on Parallel does not error", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setSuccessPolicy("require_all")
        end)
    end)

    -- @description Verifies parallel nodes accept failure-policy configuration without error.
    it("setFailurePolicy on Parallel does not error", function()
        local par = lurek.ai.newParallel()
        expect_no_error(function()
            par:setFailurePolicy("require_all")
        end)
    end)

    -- @description Confirms action and condition leaf nodes always report zero children.
    it("getChildCount returns 0 for leaf nodes", function()
        expect_equal(0, lurek.ai.newAction(function() end):getChildCount())
        expect_equal(0, lurek.ai.newCondition(function() end):getChildCount())
    end)
end)

-- =========================================================================
-- 8. SteeringManager
-- =========================================================================
-- @description Covers steering-manager construction, behavior registration, combine-mode selection, and steering-vector calculation results.
describe("lurek.ai SteeringManager", function()
    -- @description Confirms steering-manager userdata reports the expected runtime type string.
    it("type returns SteeringManager", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal("SteeringManager", sm:type())
    end)

    -- @description Adds a seek behavior and verifies the registered behavior count increments from zero to one.
    it("addSeek increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        expect_equal(0, sm:getBehaviorCount())
        sm:addSeek(100, 200)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Adds a flee behavior and verifies the registered behavior count increments.
    it("addFlee increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addFlee(0, 0)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Adds an arrive behavior and verifies the registered behavior count increments.
    it("addArrive increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addArrive(50, 50)
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Adds a wander behavior and verifies the registered behavior count increments.
    it("addWander increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addWander()
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Adds a pursue behavior and verifies the registered behavior count increments.
    it("addPursue increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addPursue("target")
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Adds an evade behavior and verifies the registered behavior count increments.
    it("addEvade increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addEvade("threat")
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Adds a flock behavior and verifies the registered behavior count increments.
    it("addFlock increases behavior count", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addFlock()
        expect_equal(1, sm:getBehaviorCount())
    end)

    -- @description Registers multiple steering behaviors and verifies the manager retains all of them simultaneously.
    it("multiple behaviors accumulate", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:addFlee(0, 0)
        sm:addWander()
        expect_equal(3, sm:getBehaviorCount())
    end)

    -- @description Switches combine modes and verifies each selected policy round-trips through the getter.
    it("setCombineMode / getCombineMode", function()
        local sm = lurek.ai.newSteeringManager()
        sm:setCombineMode("priority")
        expect_equal("priority", sm:getCombineMode())
        sm:setCombineMode("weighted")
        expect_equal("weighted", sm:getCombineMode())
    end)

    -- @description Calculates steering from a seek behavior and verifies both force components are numeric.
    it("calculate returns two numbers", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        local fx, fy = sm:calculate(0, 0, 0, 0, 100, 200, 1/60)
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    -- @description Reuses the last steering result and verifies the cached X and Y components are numeric.
    it("getLastSteering returns two numbers", function()
        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(100, 100)
        sm:calculate(0, 0, 0, 0, 100, 200, 1/60)
        local fx, fy = sm:getLastSteering()
        expect_type("number", fx)
        expect_type("number", fy)
    end)

    -- @description Adds a weighted seek behavior and verifies optional weight arguments are accepted without error.
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
-- @description Verifies path-grid geometry, walkability and cost mutation, and both normal and smoothed pathfinding results.
describe("lurek.ai PathGrid", function()
    -- @description Confirms path-grid userdata reports the expected runtime type string.
    it("type returns PathGrid", function()
        local g = lurek.pathfinding.newPathGrid(10, 10, 32)
        expect_equal("PathGrid", g:type())
    end)

    -- @description Verifies width, height, and cell-size accessors reflect the constructor arguments.
    it("getWidth / getHeight / getCellSize", function()
        local g = lurek.pathfinding.newPathGrid(8, 6, 16)
        expect_equal(8, g:getWidth())
        expect_equal(6, g:getHeight())
        expect_near(16, g:getCellSize(), 0.01)
    end)

    -- @description Verifies a newly created path grid starts with every cell walkable.
    it("all cells walkable by default", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        expect_true(g:isWalkable(1, 1))
        expect_true(g:isWalkable(5, 5))
    end)

    -- @description Toggles walkability for a single cell and verifies both the blocked and restored states round-trip correctly.
    it("setWalkable / isWalkable (1-based)", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        g:setWalkable(3, 3, false)
        expect_false(g:isWalkable(3, 3))
        g:setWalkable(3, 3, true)
        expect_true(g:isWalkable(3, 3))
    end)

    -- @description Writes a custom traversal cost into one cell and verifies it round-trips through the getter.
    it("setCost / getCost (1-based)", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        g:setCost(2, 2, 3.5)
        expect_near(3.5, g:getCost(2, 2), 0.01)
    end)

    -- @description Requests a path across an open grid and verifies the result is a non-empty waypoint table.
    it("findPath returns a table for open grid", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 5, 5)
        expect_not_nil(path, "path should exist")
        expect_type("table", path)
        expect_true(#path > 0, "path should have waypoints")
    end)

    -- @description Verifies each returned waypoint exposes x and y fields for coordinate access.
    it("findPath entries have x and y fields", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 3, 3)
        expect_not_nil(path)
        local first = path[1]
        expect_not_nil(first.x, "x field")
        expect_not_nil(first.y, "y field")
    end)

    -- @description Blocks the only middle cell in a corridor and verifies pathfinding returns nil when no route exists.
    it("findPath returns nil for blocked path", function()
        local g = lurek.pathfinding.newPathGrid(3, 1, 10)
        g:setWalkable(2, 1, false)
        local path = g:findPath(1, 1, 3, 1)
        expect_nil(path, "blocked path should be nil")
    end)

    -- @description Verifies smoothed pathfinding returns a table on an open grid.
    it("findPathSmoothed returns a table", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local path = g:findPathSmoothed(1, 1, 5, 5)
        expect_not_nil(path)
        expect_type("table", path)
    end)

    -- @description Verifies asking for a path from a cell to itself still returns a valid path object.
    it("findPath same start and goal", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local path = g:findPath(3, 3, 3, 3)
        expect_not_nil(path)
    end)
end)

-- =========================================================================
-- 10. FlowField
-- =========================================================================
-- @description Covers flow-field creation from a path grid, goal assignment, direction and distance queries, and default goal state.
describe("lurek.ai FlowField", function()
    -- @description Confirms flow-field userdata reports the expected runtime type string.
    it("type returns FlowField", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        expect_equal("FlowField", ff:type())
    end)

    -- @description Verifies flow-field dimensions mirror those of the underlying grid.
    it("getWidth / getHeight", function()
        local g = lurek.pathfinding.newPathGrid(8, 6, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        expect_equal(8, ff:getWidth())
        expect_equal(6, ff:getHeight())
    end)

    -- @description Verifies new flow fields start without a goal set.
    it("hasGoal returns false initially", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        expect_false(ff:hasGoal())
    end)

    -- @description Sets a goal and verifies both the hasGoal flag and returned goal coordinates update correctly.
    it("setGoal / hasGoal / getGoal (1-based)", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        ff:setGoal(3, 4)
        expect_true(ff:hasGoal())
        local gx, gy = ff:getGoal()
        expect_equal(3, gx)
        expect_equal(4, gy)
    end)

    -- @description Queries a directional vector after setting a goal and verifies both components are numeric.
    it("getDirection returns two numbers", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        ff:setGoal(3, 3)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @description Queries flow-field distance after setting a goal and verifies the returned distance is numeric.
    it("getDistance returns a number", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(1, 1)
        expect_type("number", d)
    end)

    -- @description Verifies goal queries return nil values before any goal has been configured.
    it("getGoal returns nil before setGoal", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        local gx, gy = ff:getGoal()
        expect_nil(gx)
        expect_nil(gy)
    end)

    -- @description Verifies the computed distance at the goal cell itself is approximately zero.
    it("distance at goal is zero", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        local ff = lurek.pathfinding.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(3, 3)
        expect_near(0, d, 0.01)
    end)
end)

-- =========================================================================
-- 11. QLearner
-- =========================================================================
-- @description Verifies Q-learner dimensions, action selection, value mutation, learning, hyperparameter setters, episode tracking, and serialization round-trips.
describe("lurek.ai QLearner", function()
    -- @description Confirms Q-learner userdata reports the expected runtime type string.
    it("type returns QLearner", function()
        local q = lurek.ai.newQLearner(4, 3)
        expect_equal("QLearner", q:type())
    end)

    -- @description Verifies state and action counts round-trip from the constructor arguments.
    it("getStateCount / getActionCount", function()
        local q = lurek.ai.newQLearner(4, 3)
        expect_equal(4, q:getStateCount())
        expect_equal(3, q:getActionCount())
    end)

    -- @description Verifies exploratory action selection returns a valid 1-based action index.
    it("chooseAction returns 1-based action", function()
        local q = lurek.ai.newQLearner(2, 3)
        local a = q:chooseAction(1)
        expect_true(a >= 1 and a <= 3, "action in range")
    end)

    -- @description Verifies best-action selection returns a valid 1-based action index.
    it("bestAction returns 1-based action", function()
        local q = lurek.ai.newQLearner(2, 3)
        local a = q:bestAction(1)
        expect_true(a >= 1 and a <= 3, "best action in range")
    end)

    -- @description Writes a Q value into the table and verifies it can be read back from the same state-action slot.
    it("setQValue / getQValue (1-based)", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setQValue(1, 2, 5.0)
        expect_near(5.0, q:getQValue(1, 2), 0.001)
    end)

    -- @description Performs a learning step with positive reward and verifies the updated Q value increases above zero.
    it("learn updates Q values", function()
        local q = lurek.ai.newQLearner(3, 2)
        q:setExplorationRate(0)
        q:setQValue(1, 1, 0)
        q:learn(1, 1, 10.0, 2)
        local after = q:getQValue(1, 1)
        expect_true(after > 0, "Q value should increase after positive reward")
    end)

    -- @description Verifies learning-rate configuration round-trips through setter and getter calls.
    it("setLearningRate / getLearningRate", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setLearningRate(0.5)
        expect_near(0.5, q:getLearningRate(), 0.001)
    end)

    -- @description Verifies discount-factor configuration round-trips through setter and getter calls.
    it("setDiscountFactor / getDiscountFactor", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setDiscountFactor(0.8)
        expect_near(0.8, q:getDiscountFactor(), 0.001)
    end)

    -- @description Verifies exploration-rate configuration round-trips through setter and getter calls.
    it("setExplorationRate / getExplorationRate", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationRate(0.1)
        expect_near(0.1, q:getExplorationRate(), 0.001)
    end)

    -- @description Verifies exploration-decay configuration round-trips through setter and getter calls.
    it("setExplorationDecay / getExplorationDecay", function()
        local q = lurek.ai.newQLearner(2, 2)
        q:setExplorationDecay(0.99)
        expect_near(0.99, q:getExplorationDecay(), 0.001)
    end)

    -- @description Ends multiple episodes and verifies the episode counter increments each time.
    it("endEpisode / getEpisodeCount", function()
        local q = lurek.ai.newQLearner(2, 2)
        expect_equal(0, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(1, q:getEpisodeCount())
        q:endEpisode()
        expect_equal(2, q:getEpisodeCount())
    end)

    -- @description Serializes a populated Q table, deserializes it into a fresh learner, and verifies key values survive the round-trip.
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

    -- @description Seeds one state with distinct Q values and verifies bestAction chooses the highest-valued action.
    it("bestAction returns consistent results for same Q table", function()
        local q = lurek.ai.newQLearner(2, 3)
        q:setQValue(1, 1, 1.0)
        q:setQValue(1, 2, 5.0)
        q:setQValue(1, 3, 2.0)
        local best = q:bestAction(1)
        expect_equal(2, best, "action 2 has highest Q")
    end)

    -- @description Verifies all Q-table entries start at zero in a newly created learner.
    it("Q values start at zero", function()
        local q = lurek.ai.newQLearner(3, 3)
        expect_near(0, q:getQValue(1, 1), 0.001)
        expect_near(0, q:getQValue(3, 3), 0.001)
    end)
end)

-- =========================================================================
-- 12. UtilityAI
-- =========================================================================
-- @description Covers utility-AI construction, weighted action registration, action evaluation, and last-action tracking.
describe("lurek.ai UtilityAI", function()
    -- @description Confirms utility-AI userdata reports the expected runtime type string.
    it("type returns UtilityAI", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal("UtilityAI", u:type())
    end)

    -- @description Adds one scored action and verifies the action count increments.
    it("addAction increases action count", function()
        local u = lurek.ai.newUtilityAI()
        expect_equal(0, u:getActionCount())
        u:addAction("eat", function() return 0.5 end)
        expect_equal(1, u:getActionCount())
    end)

    -- @description Registers multiple actions with different utility scores and verifies evaluation selects the highest-scoring action name.
    it("evaluate returns best action name", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("eat", function() return 0.3 end)
        u:addAction("sleep", function() return 0.9 end)
        u:addAction("fight", function() return 0.1 end)
        local best = u:evaluate()
        expect_equal("sleep", best)
    end)

    -- @description Verifies evaluating an empty utility-AI returns nil rather than a fabricated action.
    it("evaluate returns nil with no actions", function()
        local u = lurek.ai.newUtilityAI()
        local result = u:evaluate()
        expect_nil(result)
    end)

    -- @description Evaluates one action and verifies getLastAction reports the name of the chosen action afterwards.
    it("getLastAction returns last evaluated action", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("patrol", function() return 1.0 end)
        u:evaluate()
        expect_equal("patrol", u:getLastAction())
    end)

    -- @description Verifies getLastAction stays nil until at least one evaluation has been performed.
    it("getLastAction returns nil before evaluate", function()
        local u = lurek.ai.newUtilityAI()
        u:addAction("idle", function() return 1.0 end)
        expect_nil(u:getLastAction())
    end)

    -- @description Verifies action registration accepts an explicit weight parameter without error.
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
-- @description Verifies GOAP planner action and goal registration, preconditions, effects, planning output, and optional action callbacks.
describe("lurek.ai GOAPPlanner", function()
    -- @description Confirms GOAP planner userdata reports the expected runtime type string.
    it("type returns GOAPPlanner", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal("GOAPPlanner", g:type())
    end)

    -- @description Adds one action and verifies the planner action count increments.
    it("addAction increases action count", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getActionCount())
        g:addAction("gather_wood", 1.0)
        expect_equal(1, g:getActionCount())
    end)

    -- @description Verifies preconditions can be attached to an existing action without errors.
    it("setPrecondition does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("chop", 1.0)
        expect_no_error(function()
            g:setPrecondition("chop", "has_axe", true)
        end)
    end)

    -- @description Verifies effects can be attached to an existing action without errors.
    it("setEffect does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addAction("chop", 1.0)
        expect_no_error(function()
            g:setEffect("chop", "has_wood", true)
        end)
    end)

    -- @description Adds one goal and verifies the planner goal count increments.
    it("addGoal increases goal count", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(0, g:getGoalCount())
        g:addGoal("build_house", 1.0)
        expect_equal(1, g:getGoalCount())
    end)

    -- @description Verifies goal-state requirements can be attached to an existing goal without errors.
    it("setGoalState does not error", function()
        local g = lurek.ai.newGOAPPlanner()
        g:addGoal("build_house", 1.0)
        expect_no_error(function()
            g:setGoalState("build_house", "has_house", true)
        end)
    end)

    -- @description Builds a tiny action graph and verifies planning produces a non-empty action sequence that can satisfy the goal state.
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

    -- @description Verifies planning returns an empty table when the supplied world state already satisfies the goal.
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

    -- @description Verifies action registration accepts an optional callback function without errors.
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
-- @description Covers influence-map geometry, layer creation, influence mutation, propagation, decay, clearing, extrema queries, rectangular queries, and blending.
describe("lurek.ai InfluenceMap", function()
    -- @description Confirms influence-map userdata reports the expected runtime type string.
    it("type returns InfluenceMap", function()
        local im = lurek.ai.newInfluenceMap(10, 10, 32)
        expect_equal("InfluenceMap", im:type())
    end)

    -- @description Verifies width, height, and cell-size accessors reflect the constructor arguments.
    it("getWidth / getHeight / getCellSize", function()
        local im = lurek.ai.newInfluenceMap(8, 6, 16)
        expect_equal(8, im:getWidth())
        expect_equal(6, im:getHeight())
        expect_near(16, im:getCellSize(), 0.01)
    end)

    -- @description Adds a named layer and verifies the layer-presence query updates accordingly.
    it("addLayer / hasLayer", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        expect_false(im:hasLayer("threat"))
        im:addLayer("threat")
        expect_true(im:hasLayer("threat"))
    end)

    -- @description Writes an influence value into one cell of a named layer and verifies it round-trips through the getter.
    it("setInfluence / getInfluence (1-based)", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("danger")
        im:setInfluence("danger", 2, 3, 0.75)
        expect_near(0.75, im:getInfluence("danger", 2, 3), 0.01)
    end)

    -- @description Seeds one cell in a layer and verifies propagation can run without raising an error.
    it("propagate does not error", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("heat")
        im:setInfluence("heat", 3, 3, 1.0)
        expect_no_error(function()
            im:propagate("heat", 0.5)
        end)
    end)

    -- @description Applies decay to a stored influence value and verifies the value is reduced by the expected multiplier.
    it("decay reduces values", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("scent")
        im:setInfluence("scent", 1, 1, 1.0)
        im:decay("scent", 0.5)
        local val = im:getInfluence("scent", 1, 1)
        expect_near(0.5, val, 0.01)
    end)

    -- @description Clears one layer and verifies previously written cell values are reset to zero.
    it("clearLayer resets all values", function()
        local im = lurek.ai.newInfluenceMap(3, 3, 10)
        im:addLayer("fog")
        im:setInfluence("fog", 1, 1, 1.0)
        im:setInfluence("fog", 2, 2, 0.5)
        im:clearLayer("fog")
        expect_near(0, im:getInfluence("fog", 1, 1), 0.01)
        expect_near(0, im:getInfluence("fog", 2, 2), 0.01)
    end)

    -- @description Clears all layers at once and verifies each populated layer is reset to zero values.
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

    -- @description Queries the position of the maximum value in a layer and verifies numeric coordinates are returned.
    it("getMaxPosition returns two numbers", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("test")
        im:setInfluence("test", 3, 4, 1.0)
        local mx, my = im:getMaxPosition("test")
        expect_type("number", mx)
        expect_type("number", my)
    end)

    -- @description Queries the position of the minimum value in a layer and verifies numeric coordinates are returned.
    it("getMinPosition returns two numbers", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("test")
        im:setInfluence("test", 2, 2, -1.0)
        local mx, my = im:getMinPosition("test")
        expect_type("number", mx)
        expect_type("number", my)
    end)

    -- @description Queries a rectangular region of a layer and verifies the aggregate result is numeric.
    it("queryRect returns a number", function()
        local im = lurek.ai.newInfluenceMap(5, 5, 10)
        im:addLayer("zone")
        im:setInfluence("zone", 1, 1, 1.0)
        local sum = im:queryRect("zone", 0, 0, 50, 50)
        expect_type("number", sum)
    end)

    -- @description Blends two populated layers into a destination layer and verifies the result contains a positive combined value.
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
-- @description Verifies squad construction, membership management, leader selection, formation configuration, formation-position queries, and shared squad blackboards.
describe("lurek.ai Squad", function()
    -- @description Confirms squad userdata reports the expected runtime type string.
    it("type returns Squad", function()
        local sq = lurek.ai.newSquad("alpha")
        expect_equal("Squad", sq:type())
    end)

    -- @description Verifies a squad returns the exact name it was created with.
    it("getName returns squad name", function()
        local sq = lurek.ai.newSquad("bravo")
        expect_equal("bravo", sq:getName())
    end)

    -- @description Adds members in sequence and verifies the reported member count updates accordingly.
    it("addMember / getMemberCount", function()
        local sq = lurek.ai.newSquad("team")
        expect_equal(0, sq:getMemberCount())
        sq:addMember("soldier1")
        expect_equal(1, sq:getMemberCount())
        sq:addMember("soldier2")
        expect_equal(2, sq:getMemberCount())
    end)

    -- @description Removes one member from a populated squad and verifies the member count decreases.
    it("removeMember decreases count", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("a")
        sq:addMember("b")
        sq:removeMember("a")
        expect_equal(1, sq:getMemberCount())
    end)

    -- @description Retrieves the member list and verifies it contains the expected number of names.
    it("getMembers returns table of names", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("x")
        sq:addMember("y")
        local members = sq:getMembers()
        expect_type("table", members)
        expect_equal(2, #members)
    end)

    -- @description Sets a squad leader and verifies the same member name is returned afterwards.
    it("setLeader / getLeader", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("leader1")
        sq:setLeader("leader1")
        expect_equal("leader1", sq:getLeader())
    end)

    -- @description Verifies new squads do not have a leader assigned by default.
    it("getLeader returns nil by default", function()
        local sq = lurek.ai.newSquad("team")
        expect_nil(sq:getLeader())
    end)

    -- @description Configures formation type and spacing and verifies both values round-trip through the getters.
    it("setFormation / getFormation / getFormationSpacing", function()
        local sq = lurek.ai.newSquad("team")
        sq:setFormation("wedge", 50)
        expect_equal("wedge", sq:getFormation())
        expect_near(50, sq:getFormationSpacing(), 0.01)
    end)

    -- @description Requests a formation position for a member index and verifies numeric coordinates are returned.
    it("getFormationPosition returns two numbers (1-based index)", function()
        local sq = lurek.ai.newSquad("team")
        sq:addMember("a")
        sq:addMember("b")
        local x, y = sq:getFormationPosition(1, 100, 200)
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @description Confirms squads expose a blackboard userdata for shared squad state.
    it("getBlackboard returns Blackboard", function()
        local sq = lurek.ai.newSquad("team")
        local bb = sq:getBlackboard()
        expect_not_nil(bb)
        expect_equal("Blackboard", bb:type())
    end)
end)

-- =========================================================================
-- 16. CommandQueue
-- =========================================================================
-- @description Covers command-queue construction, emptiness and count queries, enqueue variants, cancellation, clearing, and replacement behavior.
describe("lurek.ai CommandQueue", function()
    -- @description Confirms command-queue userdata reports the expected runtime type string.
    it("type returns CommandQueue", function()
        local cq = lurek.ai.newCommandQueue()
        expect_equal("CommandQueue", cq:type())
    end)

    -- @description Verifies a fresh command queue reports empty state.
    it("isEmpty returns true initially", function()
        local cq = lurek.ai.newCommandQueue()
        expect_true(cq:isEmpty())
    end)

    -- @description Verifies a fresh command queue reports zero queued commands.
    it("getCount returns 0 initially", function()
        local cq = lurek.ai.newCommandQueue()
        expect_equal(0, cq:getCount())
    end)

    -- @description Enqueues one command and verifies the count increments while emptiness flips to false.
    it("enqueue increases count", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end)
        expect_equal(1, cq:getCount())
        expect_false(cq:isEmpty())
    end)

    -- @description Enqueues one command and verifies current-type inspection returns the head command name.
    it("getCurrentType returns first command type", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("attack", function() end)
        expect_equal("attack", cq:getCurrentType())
    end)

    -- @description Verifies current-type inspection returns nil on an empty queue.
    it("getCurrentType returns nil when empty", function()
        local cq = lurek.ai.newCommandQueue()
        expect_nil(cq:getCurrentType())
    end)

    -- @description Cancels the head command in a multi-command queue and verifies one command remains.
    it("cancelCurrent removes head", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("move", function() end)
        cq:enqueue("attack", function() end)
        cq:cancelCurrent()
        expect_equal(1, cq:getCount())
    end)

    -- @description Clears a populated queue and verifies both the count and emptiness state reset.
    it("clear removes all commands", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("a", function() end)
        cq:enqueue("b", function() end)
        cq:enqueue("c", function() end)
        cq:clear()
        expect_equal(0, cq:getCount())
        expect_true(cq:isEmpty())
    end)

    -- @description Pushes one command to the front of the queue and verifies it becomes the current command.
    it("pushFront inserts at front", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("second", function() end)
        cq:pushFront("first", function() end)
        expect_equal("first", cq:getCurrentType())
    end)

    -- @description Replaces multiple queued commands with one new command and verifies the queue collapses to that single head entry.
    it("replace replaces all with single command", function()
        local cq = lurek.ai.newCommandQueue()
        cq:enqueue("a", function() end)
        cq:enqueue("b", function() end)
        cq:replace("only", function() end)
        expect_equal(1, cq:getCount())
        expect_equal("only", cq:getCurrentType())
    end)

    -- @description Enqueues a command with an options table and verifies the queue accepts richer command payloads without error.
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
-- @description Verifies runtime type and typeOf identity reporting across the major AI userdata types exposed to Lua.
describe("lurek.ai type system", function()
    -- @description Confirms AIWorld userdata returns the correct type string.
    it("AIWorld:type() returns AIWorld", function()
        expect_equal("AIWorld", lurek.ai.newWorld():type())
    end)

    -- @description Confirms Blackboard userdata returns the correct type string.
    it("Blackboard:type() returns Blackboard", function()
        expect_equal("Blackboard", lurek.ai.newBlackboard():type())
    end)

    -- @description Confirms StateMachine userdata returns the correct type string.
    it("StateMachine:type() returns StateMachine", function()
        expect_equal("StateMachine", lurek.ai.newStateMachine():type())
    end)

    -- @description Confirms BehaviorTree userdata returns the correct type string.
    it("BehaviorTree:type() returns BehaviorTree", function()
        expect_equal("BehaviorTree", lurek.ai.newBehaviorTree():type())
    end)

    -- @description Confirms BTNode userdata returns the correct type string.
    it("BTNode:type() returns BTNode", function()
        expect_equal("BTNode", lurek.ai.newSelector():type())
    end)

    -- @description Confirms SteeringManager userdata returns the correct type string.
    it("SteeringManager:type() returns SteeringManager", function()
        expect_equal("SteeringManager", lurek.ai.newSteeringManager():type())
    end)

    -- @description Confirms PathGrid userdata returns the correct type string.
    it("PathGrid:type() returns PathGrid", function()
        expect_equal("PathGrid", lurek.pathfinding.newPathGrid(5, 5, 10):type())
    end)

    -- @description Confirms FlowField userdata returns the correct type string.
    it("FlowField:type() returns FlowField", function()
        local g = lurek.pathfinding.newPathGrid(5, 5, 10)
        expect_equal("FlowField", lurek.pathfinding.newPathFlowField(g):type())
    end)

    -- @description Confirms QLearner userdata returns the correct type string.
    it("QLearner:type() returns QLearner", function()
        expect_equal("QLearner", lurek.ai.newQLearner(2, 2):type())
    end)

    -- @description Confirms UtilityAI userdata returns the correct type string.
    it("UtilityAI:type() returns UtilityAI", function()
        expect_equal("UtilityAI", lurek.ai.newUtilityAI():type())
    end)

    -- @description Confirms GOAPPlanner userdata returns the correct type string.
    it("GOAPPlanner:type() returns GOAPPlanner", function()
        expect_equal("GOAPPlanner", lurek.ai.newGOAPPlanner():type())
    end)

    -- @description Confirms InfluenceMap userdata returns the correct type string.
    it("InfluenceMap:type() returns InfluenceMap", function()
        expect_equal("InfluenceMap", lurek.ai.newInfluenceMap(5, 5, 10):type())
    end)

    -- @description Confirms Squad userdata returns the correct type string.
    it("Squad:type() returns Squad", function()
        expect_equal("Squad", lurek.ai.newSquad("s"):type())
    end)

    -- @description Confirms CommandQueue userdata returns the correct type string.
    it("CommandQueue:type() returns CommandQueue", function()
        expect_equal("CommandQueue", lurek.ai.newCommandQueue():type())
    end)

    -- @description Verifies AIWorld participates in the shared Object type hierarchy.
    it("AIWorld:typeOf Object returns true", function()
        expect_true(lurek.ai.newWorld():typeOf("Object"))
    end)

    -- @description Verifies Agent participates in the shared Object type hierarchy.
    it("Agent:typeOf Object returns true", function()
        local w = lurek.ai.newWorld()
        local a = w:addAgent("x")
        expect_true(a:typeOf("Object"))
    end)

    -- @description Verifies Blackboard participates in the shared Object type hierarchy.
    it("Blackboard:typeOf Object returns true", function()
        expect_true(lurek.ai.newBlackboard():typeOf("Object"))
    end)

    -- @description Verifies BTNode participates in the shared Object type hierarchy.
    it("BTNode:typeOf Object returns true", function()
        expect_true(lurek.ai.newSelector():typeOf("Object"))
    end)
end)

-- =========================================================================
-- GOAPPlanner maxIterations configurability (PR-10)
-- =========================================================================

-- @description Covers suite: lurek.ai GOAPPlanner maxIterations configurability.
describe("lurek.ai GOAPPlanner maxIterations configurability", function()
    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:getMaxIterations
    -- @description Confirms the default A* iteration cap for a freshly-created GOAP planner is 10000.
    it("goap_getMaxIterations_default_is_10000", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(10000, g:getMaxIterations())
    end)

    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:setMaxIterations
    -- @covers GOAPPlanner:getMaxIterations
    -- @description Sets a new iteration cap and reads it back to verify round-trip fidelity.
    it("goap_setMaxIterations_roundtrips_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(500)
        expect_equal(500, g:getMaxIterations())
    end)

    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:setMaxIterations
    -- @covers GOAPPlanner:getMaxIterations
    -- @description Sets the iteration cap to 1 to verify extreme low values are accepted.
    it("goap_setMaxIterations_accepts_small_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(1)
        expect_equal(1, g:getMaxIterations())
    end)

    -- @covers lurek.ai.newGOAPPlanner
    -- @covers GOAPPlanner:setMaxIterations
    -- @covers GOAPPlanner:getMaxIterations
    -- @description Sets a very large iteration cap to confirm there is no hard upper bound that silently truncates.
    it("goap_setMaxIterations_accepts_large_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(100000)
        expect_equal(100000, g:getMaxIterations())
    end)
end)

-- Print summary
test_summary()
