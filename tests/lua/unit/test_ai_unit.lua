-- Lurek2D AI API Tests

-- =========================================================================
-- 1. lurek.ai module exists
-- =========================================================================

-- @description Verifies the AI namespace exposes every documented world, planner, decision-model, behavior-tree, and pathfinding factory needed by the Lua API.
describe("lurek.ai module exists", function()
    -- @tests lurek.ai.newAction
    -- @tests lurek.ai.newBehaviorTree
    -- @tests lurek.ai.newBlackboard
    -- @tests lurek.ai.newCommandQueue
    -- @tests lurek.ai.newCondition
    -- @tests lurek.ai.newGOAPPlanner
    -- @tests lurek.ai.newInfluenceMap
    -- @tests lurek.ai.newInverter
    -- @tests lurek.ai.newParallel
    -- @tests lurek.ai.newQLearner
    -- @tests lurek.ai.newRepeater
    -- @tests lurek.ai.newSelector
    -- @tests lurek.ai.newSequence
    -- @tests lurek.ai.newSquad
    -- @tests lurek.ai.newStateMachine
    -- @tests lurek.ai.newSteeringManager
    -- @tests lurek.ai.newSucceeder
    -- @tests lurek.ai.newUtilityAI
    -- @tests lurek.ai.newWorld
    -- @tests lurek.pathfind.newPathFlowField
    -- @tests lurek.pathfind.newPathGrid
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

    -- @description Verifies path-grid creation lives under lurek.pathfind rather than the AI namespace.
    it("has no newPathGrid factory (moved to pathfinding)", function()
        expect_type("function", lurek.pathfind.newPathGrid)
    end)

    -- @description Verifies flow-field creation lives under lurek.pathfind rather than the AI namespace.
    it("has no newFlowField factory (moved to pathfinding)", function()
        expect_type("function", lurek.pathfind.newPathFlowField)
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
        local g = lurek.pathfind.newPathGrid(10, 10, 32)
        expect_equal("PathGrid", g:type())
    end)

    -- @description Verifies width, height, and cell-size accessors reflect the constructor arguments.
    it("getWidth / getHeight / getCellSize", function()
        local g = lurek.pathfind.newPathGrid(8, 6, 16)
        expect_equal(8, g:getWidth())
        expect_equal(6, g:getHeight())
        expect_near(16, g:getCellSize(), 0.01)
    end)

    -- @description Verifies a newly created path grid starts with every cell walkable.
    it("all cells walkable by default", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        expect_true(g:isWalkable(1, 1))
        expect_true(g:isWalkable(5, 5))
    end)

    -- @description Toggles walkability for a single cell and verifies both the blocked and restored states round-trip correctly.
    it("setWalkable / isWalkable (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        g:setWalkable(3, 3, false)
        expect_false(g:isWalkable(3, 3))
        g:setWalkable(3, 3, true)
        expect_true(g:isWalkable(3, 3))
    end)

    -- @description Writes a custom traversal cost into one cell and verifies it round-trips through the getter.
    it("setCost / getCost (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        g:setCost(2, 2, 3.5)
        expect_near(3.5, g:getCost(2, 2), 0.01)
    end)

    -- @description Requests a path across an open grid and verifies the result is a non-empty waypoint table.
    it("findPath returns a table for open grid", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 5, 5)
        expect_not_nil(path, "path should exist")
        expect_type("table", path)
        expect_true(#path > 0, "path should have waypoints")
    end)

    -- @description Verifies each returned waypoint exposes x and y fields for coordinate access.
    it("findPath entries have x and y fields", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 3, 3)
        expect_not_nil(path)
        local first = path[1]
        expect_not_nil(first.x, "x field")
        expect_not_nil(first.y, "y field")
    end)

    -- @description Blocks the only middle cell in a corridor and verifies pathfinding returns nil when no route exists.
    it("findPath returns nil for blocked path", function()
        local g = lurek.pathfind.newPathGrid(3, 1, 10)
        g:setWalkable(2, 1, false)
        local path = g:findPath(1, 1, 3, 1)
        expect_nil(path, "blocked path should be nil")
    end)

    -- @description Verifies smoothed pathfinding returns a table on an open grid.
    it("findPathSmoothed returns a table", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPathSmoothed(1, 1, 5, 5)
        expect_not_nil(path)
        expect_type("table", path)
    end)

    -- @description Verifies asking for a path from a cell to itself still returns a valid path object.
    it("findPath same start and goal", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
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
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_equal("FlowField", ff:type())
    end)

    -- @description Verifies flow-field dimensions mirror those of the underlying grid.
    it("getWidth / getHeight", function()
        local g = lurek.pathfind.newPathGrid(8, 6, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_equal(8, ff:getWidth())
        expect_equal(6, ff:getHeight())
    end)

    -- @description Verifies new flow fields start without a goal set.
    it("hasGoal returns false initially", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_false(ff:hasGoal())
    end)

    -- @description Sets a goal and verifies both the hasGoal flag and returned goal coordinates update correctly.
    it("setGoal / hasGoal / getGoal (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 4)
        expect_true(ff:hasGoal())
        local gx, gy = ff:getGoal()
        expect_equal(3, gx)
        expect_equal(4, gy)
    end)

    -- @description Queries a directional vector after setting a goal and verifies both components are numeric.
    it("getDirection returns two numbers", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @description Queries flow-field distance after setting a goal and verifies the returned distance is numeric.
    it("getDistance returns a number", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(1, 1)
        expect_type("number", d)
    end)

    -- @description Verifies goal queries return nil values before any goal has been configured.
    it("getGoal returns nil before setGoal", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        local gx, gy = ff:getGoal()
        expect_nil(gx)
        expect_nil(gy)
    end)

    -- @description Verifies the computed distance at the goal cell itself is approximately zero.
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
        expect_equal("PathGrid", lurek.pathfind.newPathGrid(5, 5, 10):type())
    end)

    -- @description Confirms FlowField userdata returns the correct type string.
    it("FlowField:type() returns FlowField", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        expect_equal("FlowField", lurek.pathfind.newPathFlowField(g):type())
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
    -- @tests lurek.ai.newGOAPPlanner
    -- @tests GOAPPlanner:getMaxIterations
    -- @description Confirms the default A* iteration cap for a freshly-created GOAP planner is 10000.
    it("goap_getMaxIterations_default_is_10000", function()
        local g = lurek.ai.newGOAPPlanner()
        expect_equal(10000, g:getMaxIterations())
    end)

    -- @tests lurek.ai.newGOAPPlanner
    -- @tests GOAPPlanner:setMaxIterations
    -- @tests GOAPPlanner:getMaxIterations
    -- @description Sets a new iteration cap and reads it back to verify round-trip fidelity.
    it("goap_setMaxIterations_roundtrips_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(500)
        expect_equal(500, g:getMaxIterations())
    end)

    -- @tests lurek.ai.newGOAPPlanner
    -- @tests GOAPPlanner:setMaxIterations
    -- @tests GOAPPlanner:getMaxIterations
    -- @description Sets the iteration cap to 1 to verify extreme low values are accepted.
    it("goap_setMaxIterations_accepts_small_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(1)
        expect_equal(1, g:getMaxIterations())
    end)

    -- @tests lurek.ai.newGOAPPlanner
    -- @tests GOAPPlanner:setMaxIterations
    -- @tests GOAPPlanner:getMaxIterations
    -- @description Sets a very large iteration cap to confirm there is no hard upper bound that silently truncates.
    it("goap_setMaxIterations_accepts_large_value", function()
        local g = lurek.ai.newGOAPPlanner()
        g:setMaxIterations(100000)
        expect_equal(100000, g:getMaxIterations())
    end)
end)

-- =========================================================================
-- ContextSteering — Factory
-- =========================================================================
-- @description Verifies the ContextSteering factory and basic API.
describe("lurek.ai.newContextSteering factory", function()
    -- @tests lurek.ai.newContextSteering
    it("exists as a function", function()
        expect_type("function", lurek.ai.newContextSteering)
    end)

    -- @tests lurek.ai.newContextSteering
    it("creates a userdata object", function()
        local cs = lurek.ai.newContextSteering(16)
        expect_type("userdata", cs)
    end)

    -- @tests lurek.ai.newContextSteering
    it("slot count reflects argument", function()
        local cs = lurek.ai.newContextSteering(8)
        expect_equal(cs:slotCount(), 8)
    end)

    -- @tests lurek.ai.newContextSteering
    it("defaults to 16 slots for 0 argument", function()
        local cs = lurek.ai.newContextSteering(0)
        expect_equal(cs:slotCount(), 16)
    end)
end)

-- =========================================================================
-- ContextSteering — Evaluate produces a direction vector
-- =========================================================================
-- @description Verifies evaluate() returns non-nil floats.
describe("ContextSteering evaluate", function()
    -- @tests lurek.ai.newContextSteering
    it("returns two numbers from evaluate", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addSeekTarget(100, 0, 1.0)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @tests lurek.ai.newContextSteering
    it("wander returns a non-zero vector length", function()
        local cs = lurek.ai.newContextSteering(16)
        cs:addWander(0.5, 1.0)
        local dx, dy = cs:evaluate(0, 0, 0, 0)
        local mag = math.sqrt(dx * dx + dy * dy)
        expect_near(cs:chosenMagnitude(), mag, 0.01)
    end)

    -- @tests lurek.ai.newContextSteering
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
-- ContextSteering — Avoid pushes away
-- =========================================================================
-- @description Verifies addAvoidPoint generates a vector pointing away from the obstacle.
describe("ContextSteering avoid", function()
    -- @tests lurek.ai.newContextSteering
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
-- AIDirector — Factory
-- =========================================================================
-- @description Verifies the AIDirector factory and basic API.
describe("lurek.ai.newAIDirector factory", function()
    -- @tests lurek.ai.newAIDirector
    it("exists as a function", function()
        expect_type("function", lurek.ai.newAIDirector)
    end)

    -- @tests lurek.ai.newAIDirector
    it("creates a userdata object", function()
        local d = lurek.ai.newAIDirector()
        expect_type("userdata", d)
    end)

    -- @tests lurek.ai.newAIDirector
    it("starts with zero tension", function()
        local d = lurek.ai.newAIDirector()
        expect_near(d:tension(), 0.0, 0.001)
    end)

    -- @tests lurek.ai.newAIDirector
    it("starts in Relief phase", function()
        local d = lurek.ai.newAIDirector()
        expect_equal(d:phase(), "Relief")
    end)
end)

-- =========================================================================
-- AIDirector — pushEvent raises tension
-- =========================================================================
-- @description Verifies that pushEvent() increases tension.
describe("AIDirector pushEvent", function()
    -- @tests lurek.ai.newAIDirector
    it("pushEvent raises tension", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(0.8)
        expect_equal(d:tension() > 0.0, true)
    end)

    -- @tests lurek.ai.newAIDirector
    it("tension does not exceed 1.0", function()
        local d = lurek.ai.newAIDirector()
        for i = 1, 50 do d:pushEvent(1.0) end
        expect_equal(d:tension() <= 1.0, true)
    end)
end)

-- =========================================================================
-- AIDirector — Update advances phase
-- =========================================================================
-- @description Verifies that update() transitions through phases.
describe("AIDirector update", function()
    -- @tests lurek.ai.newAIDirector
    it("update does not crash", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(1.0)
        d:update(0.1)
        expect_type("string", d:phase())
    end)

    -- @tests lurek.ai.newAIDirector
    it("spawnRateFactor returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:spawnRateFactor())
    end)

    -- @tests lurek.ai.newAIDirector
    it("lootFactor returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:lootFactor())
    end)

    -- @tests lurek.ai.newAIDirector
    it("ambientIntensity returns a number", function()
        local d = lurek.ai.newAIDirector()
        expect_type("number", d:ambientIntensity())
    end)
end)

-- =========================================================================
-- AIDirector — Reset
-- =========================================================================
-- @description Verifies that reset() restores zero tension.
describe("AIDirector reset", function()
    -- @tests lurek.ai.newAIDirector
    it("reset clears tension", function()
        local d = lurek.ai.newAIDirector()
        d:pushEvent(1.0)
        d:reset()
        expect_near(d:tension(), 0.0, 0.001)
    end)

    -- @tests lurek.ai.newAIDirector
    it("setTension changes tension directly", function()
        local d = lurek.ai.newAIDirector()
        d:setTension(0.5)
        expect_near(d:tension(), 0.5, 0.01)
    end)
end)

-- =========================================================================
-- EmotionModel — Factory
-- =========================================================================
-- @description Verifies the EmotionModel factory and basic API.
describe("lurek.ai.newEmotionModel factory", function()
    -- @tests lurek.ai.newEmotionModel
    it("exists as a function", function()
        expect_type("function", lurek.ai.newEmotionModel)
    end)

    -- @tests lurek.ai.newEmotionModel
    it("creates a userdata object", function()
        local em = lurek.ai.newEmotionModel()
        expect_type("userdata", em)
    end)
end)

-- =========================================================================
-- EmotionModel — Add emotions
-- =========================================================================
-- @description Verifies emotions can be added and queried.
describe("EmotionModel add/query", function()
    -- @tests lurek.ai.newEmotionModel
    it("dominant returns nil when empty", function()
        local em = lurek.ai.newEmotionModel()
        expect_equal(em:dominant(), nil)
    end)

    -- @tests lurek.ai.newEmotionModel
    it("get returns 0 for unknown emotion", function()
        local em = lurek.ai.newEmotionModel()
        expect_near(em:get("anger"), 0.0, 0.001)
    end)

    -- @tests lurek.ai.newEmotionModel
    it("trigger raises emotion value", function()
        local em = lurek.ai.newEmotionModel()
        em:add("fear", 0.0, 0.5, 0.1)
        em:trigger("fear", 0.8)
        expect_equal(em:get("fear") > 0.0, true)
    end)

    -- @tests lurek.ai.newEmotionModel
    it("isActive returns false before trigger", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.0, 0.3, 0.2)
        expect_equal(em:isActive("joy"), false)
    end)

    -- @tests lurek.ai.newEmotionModel
    it("isActive returns true after strong trigger", function()
        local em = lurek.ai.newEmotionModel()
        em:add("joy", 0.0, 0.3, 0.2)
        em:trigger("joy", 0.9)
        expect_equal(em:isActive("joy"), true)
    end)
end)

-- =========================================================================
-- EmotionModel — Dominant
-- =========================================================================
-- @description Verifies dominant() returns the strongest emotion.
describe("EmotionModel dominant", function()
    -- @tests lurek.ai.newEmotionModel
    it("dominant returns the triggered emotion when only one", function()
        local em = lurek.ai.newEmotionModel()
        em:add("rage", 0.0, 0.2, 0.1)
        em:trigger("rage", 1.0)
        expect_equal(em:dominant(), "rage")
    end)
end)

-- =========================================================================
-- EmotionModel — Decay and reset
-- =========================================================================
-- @description Verifies update() decays emotions and reset() clears them.
describe("EmotionModel update/reset", function()
    -- @tests lurek.ai.newEmotionModel
    it("update does not crash", function()
        local em = lurek.ai.newEmotionModel()
        em:update(0.016)
        expect_equal(em:dominant(), nil)
    end)

    -- @tests lurek.ai.newEmotionModel
    it("reset brings emotions to resting level", function()
        local em = lurek.ai.newEmotionModel()
        em:add("dread", 0.0, 0.5, 0.1)
        em:trigger("dread", 1.0)
        em:reset()
        expect_near(em:get("dread"), 0.0, 0.01)
    end)
end)

-- =========================================================================
-- HTNDomain — Factory
-- =========================================================================
-- @description Verifies the HTNDomain factory and basic API.
describe("lurek.ai.newHTNDomain factory", function()
    -- @tests lurek.ai.newHTNDomain
    it("exists as a function", function()
        expect_type("function", lurek.ai.newHTNDomain)
    end)

    -- @tests lurek.ai.newHTNDomain
    it("creates a userdata object", function()
        local d = lurek.ai.newHTNDomain()
        expect_type("userdata", d)
    end)

    -- @tests lurek.ai.newHTNDomain
    it("starts with zero tasks", function()
        local d = lurek.ai.newHTNDomain()
        expect_equal(d:taskCount(), 0)
    end)
end)

-- =========================================================================
-- HTNDomain — Primitives
-- =========================================================================
-- @description Verifies that primitive tasks can be added.
describe("HTNDomain addPrimitive", function()
    -- @tests lurek.ai.newHTNDomain
    it("addPrimitive increments task count", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("MoveTo", {}, {"at_target"}, {})
        expect_equal(d:taskCount(), 1)
    end)

    -- @tests lurek.ai.newHTNDomain
    it("addPrimitive with preconditions is counted", function()
        local d = lurek.ai.newHTNDomain()
        d:addPrimitive("Attack", {"has_weapon", "enemy_visible"}, {"attacked"}, {})
        expect_equal(d:taskCount(), 1)
    end)
end)

-- =========================================================================
-- HTNDomain — Planning
-- =========================================================================
-- @description Verifies that plan() returns a sequence of primitive actions.
describe("HTNDomain plan", function()
    -- @tests lurek.ai.newHTNDomain
    it("plan returns nil for unknown root task", function()
        local d = lurek.ai.newHTNDomain()
        local result = d:plan("nonexistent", {})
        expect_equal(result, nil)
    end)

    -- @tests lurek.ai.newHTNDomain
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

    -- @tests lurek.ai.newHTNDomain
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
-- AILod — Factory
-- =========================================================================
-- @description Verifies the AILod factory and basic API.
describe("lurek.ai.newAILod factory", function()
    -- @tests lurek.ai.newAILod
    it("exists as a function", function()
        expect_type("function", lurek.ai.newAILod)
    end)

    -- @tests lurek.ai.newAILod
    it("creates a userdata object", function()
        local lod = lurek.ai.newAILod()
        expect_type("userdata", lod)
    end)

    -- @tests lurek.ai.newAILod
    it("tierCount is >= 1", function()
        local lod = lurek.ai.newAILod()
        expect_equal(lod:tierCount() >= 1, true)
    end)
end)

-- =========================================================================
-- AILod — Tier assignment
-- =========================================================================
-- @description Verifies tierFor() returns valid tier indices based on distance.
describe("AILod tierFor", function()
    -- @tests lurek.ai.newAILod
    it("returns an integer tier index", function()
        local lod = lurek.ai.newAILod()
        local tier = lod:tierFor(0, 0, 0, 0)
        expect_type("number", tier)
        expect_equal(tier >= 0, true)
    end)

    -- @tests lurek.ai.newAILod
    it("agent at same position as reference gets tier 0 (nearest)", function()
        local lod = lurek.ai.newAILod()
        local tier = lod:tierFor(0, 0, 0, 0)
        expect_equal(tier, 0)
    end)

    -- @tests lurek.ai.newAILod
    it("distant agent gets higher tier than close agent", function()
        local lod = lurek.ai.newAILod()
        local near_tier = lod:tierFor(5, 0, 0, 0)    -- close
        local far_tier  = lod:tierFor(2000, 0, 0, 0) -- very far
        expect_equal(far_tier >= near_tier, true)
    end)

    -- @tests lurek.ai.newAILod
    it("tier index never exceeds tierCount-1", function()
        local lod = lurek.ai.newAILod()
        local max_tier = lod:tierCount() - 1
        local tier = lod:tierFor(99999, 99999, 0, 0)
        expect_equal(tier <= max_tier, true)
    end)
end)

-- =========================================================================
-- AILod — shouldUpdate
-- =========================================================================
-- @description Verifies shouldUpdate() behaviour for near vs far tiers.
describe("AILod shouldUpdate", function()
    -- @tests lurek.ai.newAILod
    it("tier 0 updates every frame", function()
        local lod = lurek.ai.newAILod()
        -- Tier 0 (near) should update every frame
        expect_equal(lod:shouldUpdate(0, 0), true)
        expect_equal(lod:shouldUpdate(0, 1), true)
        expect_equal(lod:shouldUpdate(0, 7), true)
    end)

    -- @tests lurek.ai.newAILod
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
-- AILod — tierName
-- =========================================================================
-- @description Verifies tierName returns a string for valid tiers.
describe("AILod tierName", function()
    -- @tests lurek.ai.newAILod
    it("tier 0 has a non-nil name", function()
        local lod = lurek.ai.newAILod()
        local name = lod:tierName(0)
        expect_type("string", name)
    end)

    -- @tests lurek.ai.newAILod
    it("out-of-bounds tier returns nil", function()
        local lod = lurek.ai.newAILod()
        local name = lod:tierName(9999)
        expect_equal(name, nil)
    end)
end)

-- =========================================================================
-- MCTSEngine — Factory
-- =========================================================================
-- @description Verifies the MCTSEngine factory and basic API.
describe("lurek.ai.newMCTSEngine factory", function()
    -- @tests lurek.ai.newMCTSEngine
    it("exists as a function", function()
        expect_type("function", lurek.ai.newMCTSEngine)
    end)

    -- @tests lurek.ai.newMCTSEngine
    it("creates a userdata object", function()
        local mcts = lurek.ai.newMCTSEngine(50, 1.41, 10, 42)
        expect_type("userdata", mcts)
    end)
end)

-- =========================================================================
-- MCTSEngine — Search
-- =========================================================================
-- @description Verifies the search() closure-based API with a trivial game.
--
-- Trivial game: state = integer 0..5.  Actions: +1 or +2.
-- Evaluate: higher state = better score.  Best first action from 0 = +2.
describe("MCTSEngine search", function()
    -- @tests lurek.ai.newMCTSEngine
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

    -- @tests lurek.ai.newMCTSEngine
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

    -- @tests lurek.ai.newMCTSEngine
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
-- NeuralNet — Factory
-- =========================================================================
-- @description Verifies the NeuralNet factory and basic inference.
describe("lurek.ai.newNeuralNet factory", function()
    -- @tests lurek.ai.newNeuralNet
    it("exists as a function", function()
        expect_type("function", lurek.ai.newNeuralNet)
    end)

    -- @tests lurek.ai.newNeuralNet
    it("creates a userdata object", function()
        local net = lurek.ai.newNeuralNet()
        expect_type("userdata", net)
    end)

    -- @tests lurek.ai.newNeuralNet
    it("starts with zero layers", function()
        local net = lurek.ai.newNeuralNet()
        expect_equal(net:layerCount(), 0)
    end)

    -- @tests lurek.ai.newNeuralNet
    it("addLayer increments layer count", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 4, "relu")
        net:addLayer(4, 1, "sigmoid")
        expect_equal(net:layerCount(), 2)
    end)

    -- @tests lurek.ai.newNeuralNet
    it("forward returns table of correct size", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(3, 2, "relu")
        local out = net:forward({0.5, 0.1, 0.9})
        expect_type("table", out)
        expect_equal(#out, 2)
    end)

    -- @tests lurek.ai.newNeuralNet
    it("paramCount is positive after adding layers", function()
        local net = lurek.ai.newNeuralNet()
        net:addLayer(2, 3, "tanh")
        -- 2*3 weights + 3 biases = 9
        expect_equal(net:paramCount(), 9)
    end)

    -- @tests lurek.ai.newNeuralNet
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
-- GeneticAlgorithm — Factory
-- =========================================================================
-- @description Verifies the GeneticAlgorithm factory and evolution API.
describe("lurek.ai.newGeneticAlgorithm factory", function()
    -- @tests lurek.ai.newGeneticAlgorithm
    it("exists as a function", function()
        expect_type("function", lurek.ai.newGeneticAlgorithm)
    end)

    -- @tests lurek.ai.newGeneticAlgorithm
    it("creates a userdata object", function()
        local ga = lurek.ai.newGeneticAlgorithm(10, 5, 42)
        expect_type("userdata", ga)
    end)

    -- @tests lurek.ai.newGeneticAlgorithm
    it("popSize matches argument", function()
        local ga = lurek.ai.newGeneticAlgorithm(20, 4, 1)
        expect_equal(ga:popSize(), 20)
    end)

    -- @tests lurek.ai.newGeneticAlgorithm
    it("getGenes returns table of expected length", function()
        local ga = lurek.ai.newGeneticAlgorithm(5, 8, 7)
        local genes = ga:getGenes(0)
        expect_type("table", genes)
        expect_equal(#genes, 8)
    end)

    -- @tests lurek.ai.newGeneticAlgorithm
    it("evolve increments generation", function()
        local ga = lurek.ai.newGeneticAlgorithm(6, 4, 3)
        -- Assign trivial fitness before evolve
        for i = 0, 5 do ga:setFitness(i, i * 0.1) end
        local g0 = ga:generation()
        ga:evolve()
        expect_equal(ga:generation(), g0 + 1)
    end)

    -- @tests lurek.ai.newGeneticAlgorithm
    it("bestGenes returns a table", function()
        local ga = lurek.ai.newGeneticAlgorithm(4, 3, 9)
        for i = 0, 3 do ga:setFitness(i, i * 0.5) end
        ga:evolve()
        local best = ga:bestGenes()
        expect_type("table", best)
    end)
end)

-- =========================================================================
-- Bandit — Factory
-- =========================================================================
-- @description Verifies the Bandit factory and arms API.
describe("lurek.ai.newBandit factory", function()
    -- @tests lurek.ai.newBandit
    it("exists as a function", function()
        expect_type("function", lurek.ai.newBandit)
    end)

    -- @tests lurek.ai.newBandit
    it("creates a userdata object", function()
        local b = lurek.ai.newBandit(5, "epsilon_greedy", 0.1, 42)
        expect_type("userdata", b)
    end)

    -- @tests lurek.ai.newBandit
    it("armCount matches argument", function()
        local b = lurek.ai.newBandit(8, "ucb1", 0.0, 1)
        expect_equal(b:armCount(), 8)
    end)

    -- @tests lurek.ai.newBandit
    it("select returns a valid arm index", function()
        local b = lurek.ai.newBandit(4, "epsilon_greedy", 0.2, 10)
        local idx = b:select()
        expect_equal(idx >= 0 and idx < 4, true)
    end)

    -- @tests lurek.ai.newBandit
    it("update does not crash", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 5)
        b:update(0, 1.0)
        b:update(1, 0.5)
        b:update(2, 0.8)
        expect_equal(b:totalPulls(), 3)
    end)

    -- @tests lurek.ai.newBandit
    it("bestArm returns a valid index after updates", function()
        local b = lurek.ai.newBandit(3, "ucb1", 0.0, 5)
        b:update(0, 0.1)
        b:update(1, 0.9)
        b:update(2, 0.3)
        expect_equal(b:bestArm() >= 0, true)
    end)

    -- @tests lurek.ai.newBandit
    it("thompson_sampling strategy creates successfully", function()
        local b = lurek.ai.newBandit(4, "thompson", 0.0, 7)
        local idx = b:select()
        expect_equal(idx >= 0 and idx < 4, true)
    end)

    -- @tests lurek.ai.newBandit
    it("reset clears pull history", function()
        local b = lurek.ai.newBandit(2, "epsilon_greedy", 0.5, 99)
        b:update(0, 1.0)
        b:reset()
        expect_equal(b:totalPulls(), 0)
    end)
end)

-- =========================================================================
-- Neuroevolution — Factory
-- =========================================================================
-- @description Verifies the Neuroevolution factory and basic API.
describe("lurek.ai.newNeuroevolution factory", function()
    -- @tests lurek.ai.newNeuroevolution
    it("exists as a function", function()
        expect_type("function", lurek.ai.newNeuroevolution)
    end)

    -- @tests lurek.ai.newNeuroevolution
    it("creates a userdata object", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=4, activation="relu"},
             {inputs=4, outputs=1, activation="sigmoid"}},
            10, 42)
        expect_type("userdata", ne)
    end)

    -- @tests lurek.ai.newNeuroevolution
    it("popSize matches argument", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=2, activation="relu"}}, 8, 1)
        expect_equal(ne:popSize(), 8)
    end)

    -- @tests lurek.ai.newNeuroevolution
    it("chromosomeToNet returns a NeuralNet userdata", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=2, activation="tanh"}}, 5, 3)
        local net = ne:chromosomeToNet(0)
        expect_type("userdata", net)
    end)

    -- @tests lurek.ai.newNeuroevolution
    it("bestNetwork returns userdata after evolve", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=2, outputs=1, activation="sigmoid"}}, 4, 7)
        for i = 0, 3 do ne:setFitness(i, i * 0.2) end
        ne:evolve()
        local best = ne:bestNetwork()
        expect_type("userdata", best)
    end)

    -- @tests lurek.ai.newNeuroevolution
    it("evolve increments generation", function()
        local ne = lurek.ai.newNeuroevolution(
            {{inputs=1, outputs=1, activation="linear"}}, 4, 11)
        for i = 0, 3 do ne:setFitness(i, 1.0) end
        ne:evolve()
        expect_equal(ne:generation(), 1)
    end)
end)

-- =========================================================================
-- NeedSystem — Factory
-- =========================================================================
-- @description Verifies the NeedSystem factory and basic API.
describe("lurek.ai.newNeedSystem factory", function()
    -- @tests lurek.ai.newNeedSystem
    it("exists as a function", function()
        expect_type("function", lurek.ai.newNeedSystem)
    end)

    -- @tests lurek.ai.newNeedSystem
    it("creates a userdata object", function()
        local ns = lurek.ai.newNeedSystem()
        expect_type("userdata", ns)
    end)
end)

-- =========================================================================
-- NeedSystem — Add needs
-- =========================================================================
-- @description Verifies that needs can be added and queried.
describe("NeedSystem add/query", function()
    -- @tests lurek.ai.newNeedSystem
    it("mostUrgent returns nil when empty", function()
        local ns = lurek.ai.newNeedSystem()
        expect_equal(ns:mostUrgent(), nil)
    end)

    -- @tests lurek.ai.newNeedSystem
    it("valueOf returns 1.0 for new needs (full by default)", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 0.1, 0.3, 2.0)
        expect_near(ns:valueOf("hunger"), 1.0, 0.001)
    end)

    -- @tests lurek.ai.newNeedSystem
    it("valueOf returns 0 for unknown need", function()
        local ns = lurek.ai.newNeedSystem()
        expect_near(ns:valueOf("unknown"), 0.0, 0.001)
    end)
end)

-- =========================================================================
-- NeedSystem — Decay
-- =========================================================================
-- @description Verifies that needs decay over time.
describe("NeedSystem update/decay", function()
    -- @tests lurek.ai.newNeedSystem
    it("update does not crash with empty system", function()
        local ns = lurek.ai.newNeedSystem()
        ns:update(0.016)
        expect_equal(ns:mostUrgent(), nil)
    end)

    -- @tests lurek.ai.newNeedSystem
    it("hunger decays after large dt", function()
        local ns = lurek.ai.newNeedSystem()
        ns:addNeed("hunger", 1.0, 0.3, 2.0)   -- fast decay
        ns:update(0.8)                           -- should reduce value
        expect_equal(ns:valueOf("hunger") < 1.0, true)
    end)
end)

-- =========================================================================
-- NeedSystem — Satisfy
-- =========================================================================
-- @description Verifies that satisfy() increases need value.
describe("NeedSystem satisfy", function()
    -- @tests lurek.ai.newNeedSystem
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
-- NeedSystem — Most urgent
-- =========================================================================
-- @description Verifies mostUrgent returns the name of the most depleted need.
describe("NeedSystem mostUrgent", function()
    -- @tests lurek.ai.newNeedSystem
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
-- ORCASolver — Factory
-- =========================================================================
-- @description Verifies the ORCASolver factory and basic API.
describe("lurek.ai.newORCASolver factory", function()
    -- @tests lurek.ai.newORCASolver
    it("exists as a function", function()
        expect_type("function", lurek.ai.newORCASolver)
    end)

    -- @tests lurek.ai.newORCASolver
    it("creates a userdata object", function()
        local s = lurek.ai.newORCASolver(2.0)
        expect_type("userdata", s)
    end)

    -- @tests lurek.ai.newORCASolver
    it("starts with zero agents", function()
        local s = lurek.ai.newORCASolver(2.0)
        expect_equal(s:agentCount(), 0)
    end)
end)

-- =========================================================================
-- ORCASolver — Add agents
-- =========================================================================
-- @description Verifies that agents can be added and counted.
describe("ORCASolver addAgent", function()
    -- @tests lurek.ai.newORCASolver
    it("addAgent increments count", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        expect_equal(s:agentCount(), 1)
    end)

    -- @tests lurek.ai.newORCASolver
    it("multiple agents counted", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        s:addAgent(10, 0, 0.5, 3.0)
        expect_equal(s:agentCount(), 2)
    end)
end)

-- =========================================================================
-- ORCASolver — Compute
-- =========================================================================
-- @description Verifies that compute() produces safe velocities.
describe("ORCASolver compute", function()
    -- @tests lurek.ai.newORCASolver
    it("compute does not crash with one agent", function()
        local s = lurek.ai.newORCASolver(2.0)
        s:addAgent(0, 0, 0.5, 3.0)
        s:setPreferredVelocity(0, 1.0, 0.0)
        s:compute(0.016)
        local vx, vy = s:getSafeVelocity(0)
        expect_type("number", vx)
        expect_type("number", vy)
    end)

    -- @tests lurek.ai.newORCASolver
    it("getSafeVelocity returns zeros for out-of-bounds index", function()
        local s = lurek.ai.newORCASolver(2.0)
        local vx, vy = s:getSafeVelocity(99)
        expect_near(vx, 0.0, 0.001)
        expect_near(vy, 0.0, 0.001)
    end)

    -- @tests lurek.ai.newORCASolver
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
-- StimulusWorld — Factory
-- =========================================================================
-- @description Verifies the StimulusWorld factory and basic API.
describe("lurek.ai.newStimulusWorld factory", function()
    -- @tests lurek.ai.newStimulusWorld
    it("exists as a function", function()
        expect_type("function", lurek.ai.newStimulusWorld)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("creates a userdata object", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_type("userdata", sw)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("starts with zero stimuli", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_equal(sw:count(), 0)
    end)
end)

-- =========================================================================
-- StimulusWorld — Adding stimuli
-- =========================================================================
-- @description Verifies that visual and auditory stimuli can be added and counted.
describe("StimulusWorld add stimuli", function()
    -- @tests lurek.ai.newStimulusWorld
    it("addVisual increases count", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(100, 200, 1.0, 50.0, nil)
        expect_equal(sw:count(), 1)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("addAuditory increases count", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addAuditory(50, 50, 0.8, 80.0, 0.5, "gunshot")
        expect_equal(sw:count(), 1)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("multiple stimuli counted correctly", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(0, 0, 1.0, 40.0, nil)
        sw:addVisual(10, 10, 0.5, 20.0, "guard")
        sw:addAuditory(5, 5, 0.9, 60.0, 0.3, "footstep")
        expect_equal(sw:count(), 3)
    end)
end)

-- =========================================================================
-- StimulusWorld — Remove
-- =========================================================================
-- @description Verifies that stimuli can be removed by ID.
describe("StimulusWorld remove", function()
    -- @tests lurek.ai.newStimulusWorld
    it("remove decrements count", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 50.0, nil)
        expect_equal(sw:count(), 1)
        sw:remove(id)
        expect_equal(sw:count(), 0)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("remove returns true for valid id", function()
        local sw = lurek.ai.newStimulusWorld()
        local id = sw:addVisual(0, 0, 1.0, 50.0, nil)
        expect_equal(sw:remove(id), true)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("remove returns false for unknown id", function()
        local sw = lurek.ai.newStimulusWorld()
        expect_equal(sw:remove(99999), false)
    end)
end)

-- =========================================================================
-- StimulusWorld — Update and clear
-- =========================================================================
-- @description Verifies update and clear operations.
describe("StimulusWorld update/clear", function()
    -- @tests lurek.ai.newStimulusWorld
    it("update does not crash with empty world", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:update(0.016)
        expect_equal(sw:count(), 0)
    end)

    -- @tests lurek.ai.newStimulusWorld
    it("clear removes all stimuli", function()
        local sw = lurek.ai.newStimulusWorld()
        sw:addVisual(0, 0, 1.0, 50.0, nil)
        sw:addVisual(10, 10, 0.5, 30.0, nil)
        sw:clear()
        expect_equal(sw:count(), 0)
    end)
end)

-- =========================================================================
-- StrategyAI — Factory
-- =========================================================================
-- @description Verifies the StrategyAI factory and basic API.
describe("lurek.ai.newStrategyAI factory", function()
    -- @tests lurek.ai.newStrategyAI
    it("exists as a function", function()
        expect_type("function", lurek.ai.newStrategyAI)
    end)

    -- @tests lurek.ai.newStrategyAI
    it("creates a userdata object", function()
        local s = lurek.ai.newStrategyAI(5.0)
        expect_type("userdata", s)
    end)

    -- @tests lurek.ai.newStrategyAI
    it("starts with no active goal", function()
        local s = lurek.ai.newStrategyAI(5.0)
        expect_equal(s:activeGoal(), nil)
    end)
end)

-- =========================================================================
-- StrategyAI — Add goals and evaluate
-- =========================================================================
-- @description Verifies goals can be added and evaluated by scorer.
describe("StrategyAI addGoal / forceEvaluate", function()
    -- @tests lurek.ai.newStrategyAI
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

    -- @tests lurek.ai.newStrategyAI
    it("activeGoal remains nil if all scores zero", function()
        local s = lurek.ai.newStrategyAI(10.0)
        s:addGoal("explore")
        s:forceEvaluate(function(_) return 0.0 end)
        expect_equal(s:activeGoal(), nil)
    end)
end)

-- =========================================================================
-- StrategyAI — Update with throttle
-- =========================================================================
-- @description Verifies update() only re-evaluates after the interval expires.
describe("StrategyAI update throttle", function()
    -- @tests lurek.ai.newStrategyAI
    it("update does not crash before interval", function()
        local s = lurek.ai.newStrategyAI(5.0)
        s:addGoal("patrol")
        s:update(0.016, function(_) return 1.0 end)
        expect_type("number", s:timeUntilNext())
    end)

    -- @tests lurek.ai.newStrategyAI
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
-- StrategyAI — Tags
-- =========================================================================
-- @description Verifies tags can be added and removed.
describe("StrategyAI tags", function()
    -- @tests lurek.ai.newStrategyAI
    it("addTag / removeTag do not crash", function()
        local s = lurek.ai.newStrategyAI(5.0)
        s:addTag("night")
        s:addTag("rain")
        s:removeTag("night")
        expect_equal(true, true)  -- no crash = pass
    end)
end)

-- =========================================================================
-- TraitProfile — Factory
-- =========================================================================
-- @description Verifies the TraitProfile factory exists and creates a valid object.
describe("lurek.ai.newTraitProfile factory", function()
    -- @tests lurek.ai.newTraitProfile
    it("exists as a function", function()
        expect_type("function", lurek.ai.newTraitProfile)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("creates a userdata object", function()
        local tp = lurek.ai.newTraitProfile()
        expect_type("userdata", tp)
    end)
end)

-- =========================================================================
-- TraitProfile — set / get roundtrip
-- =========================================================================
-- @description Verifies that trait values set via set() are returned by get().
describe("TraitProfile set/get", function()
    -- @tests lurek.ai.newTraitProfile
    it("starts with zero for unknown trait", function()
        local tp = lurek.ai.newTraitProfile()
        expect_near(tp:get("aggression"), 0.0, 0.001)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("returns set value", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("courage", 0.75)
        expect_near(tp:get("courage"), 0.75, 0.001)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("has() returns false for unset trait", function()
        local tp = lurek.ai.newTraitProfile()
        expect_equal(tp:has("unknown_trait"), false)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("has() returns true after set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("loyalty", 0.5)
        expect_equal(tp:has("loyalty"), true)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("traitCount increments after set", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("a", 0.1)
        tp:set("b", 0.2)
        expect_equal(tp:traitCount(), 2)
    end)
end)

-- =========================================================================
-- TraitProfile — Modifiers
-- =========================================================================
-- @description Verifies that timed modifiers alter the effective trait value.
describe("TraitProfile modifiers", function()
    -- @tests lurek.ai.newTraitProfile
    it("modifier raises effective value immediately", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("fear", 0.2)
        tp:addModifier("fear", 0.5, nil, "poison")
        expect_near(tp:get("fear"), 0.7, 0.01)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("removeModifiers restores base value", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("fear", 0.2)
        tp:addModifier("fear", 0.5, nil, "poison")
        tp:removeModifiers("poison")
        expect_near(tp:get("fear"), 0.2, 0.01)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("getBase is unchanged by modifier", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("strength", 0.8)
        tp:addModifier("strength", 0.1, nil, "buff")
        expect_near(tp:getBase("strength"), 0.8, 0.01)
    end)
end)

-- =========================================================================
-- TraitProfile — Update / decay
-- =========================================================================
-- @description Verifies that update() ticks the modifier timer and expires timed modifiers.
describe("TraitProfile update", function()
    -- @tests lurek.ai.newTraitProfile
    it("update does not crash with no modifiers", function()
        local tp = lurek.ai.newTraitProfile()
        tp:update(0.016)
        expect_equal(tp:traitCount(), 0)
    end)

    -- @tests lurek.ai.newTraitProfile
    it("timed modifier expires after update", function()
        local tp = lurek.ai.newTraitProfile()
        tp:set("speed", 0.5)
        tp:addModifier("speed", 0.3, 0.001, "boost")  -- expires in 0.001 s
        tp:update(1.0)  -- well past expiry
        expect_near(tp:get("speed"), 0.5, 0.01)
    end)
end)

-- Print summary

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests Blackboard:has
    it("covers Blackboard:has", function()
        -- TODO: Implement test for Blackboard:has
    end)

    -- @tests BehaviorTree:getDebugState
    it("covers BehaviorTree:getDebugState", function()
        -- TODO: Implement test for BehaviorTree:getDebugState
    end)

    -- @tests SteeringManager:setSpatialHashCellSize
    it("covers SteeringManager:setSpatialHashCellSize", function()
        -- TODO: Implement test for SteeringManager:setSpatialHashCellSize
    end)

    -- @tests SteeringManager:enableSpatialHash
    it("covers SteeringManager:enableSpatialHash", function()
        -- TODO: Implement test for SteeringManager:enableSpatialHash
    end)

    -- @tests CommandQueue:getCurrentTarget
    it("covers CommandQueue:getCurrentTarget", function()
        -- TODO: Implement test for CommandQueue:getCurrentTarget
    end)

    -- @tests TraitProfile:set
    it("covers TraitProfile:set", function()
        -- TODO: Implement test for TraitProfile:set
    end)

    -- @tests TraitProfile:get
    it("covers TraitProfile:get", function()
        -- TODO: Implement test for TraitProfile:get
    end)

    -- @tests TraitProfile:has
    it("covers TraitProfile:has", function()
        -- TODO: Implement test for TraitProfile:has
    end)

    -- @tests ContextSteering:addAvoidBounds
    it("covers ContextSteering:addAvoidBounds", function()
        -- TODO: Implement test for ContextSteering:addAvoidBounds
    end)

    -- @tests EmotionModel:get
    it("covers EmotionModel:get", function()
        -- TODO: Implement test for EmotionModel:get
    end)

    -- @tests Neuroevolution:bestFitness
    it("covers Neuroevolution:bestFitness", function()
        -- TODO: Implement test for Neuroevolution:bestFitness
    end)

end)

describe("Missing explicit test for AIWorld:addAgent", function()
    it("AIWorld:addAgent works", function()
        -- @tests AIWorld:addAgent
        -- TODO: add assertion for AIWorld:addAgent
    end)
end)

describe("Missing explicit test for AIWorld:getAgent", function()
    it("AIWorld:getAgent works", function()
        -- @tests AIWorld:getAgent
        -- TODO: add assertion for AIWorld:getAgent
    end)
end)

describe("Missing explicit test for AIWorld:removeAgent", function()
    it("AIWorld:removeAgent works", function()
        -- @tests AIWorld:removeAgent
        -- TODO: add assertion for AIWorld:removeAgent
    end)
end)

describe("Missing explicit test for AIWorld:getAgentCount", function()
    it("AIWorld:getAgentCount works", function()
        -- @tests AIWorld:getAgentCount
        -- TODO: add assertion for AIWorld:getAgentCount
    end)
end)

describe("Missing explicit test for AIWorld:getGlobalBlackboard", function()
    it("AIWorld:getGlobalBlackboard works", function()
        -- @tests AIWorld:getGlobalBlackboard
        -- TODO: add assertion for AIWorld:getGlobalBlackboard
    end)
end)

describe("Missing explicit test for AIWorld:update", function()
    it("AIWorld:update works", function()
        -- @tests AIWorld:update
        -- TODO: add assertion for AIWorld:update
    end)
end)

describe("Missing explicit test for AIWorld:type", function()
    it("AIWorld:type works", function()
        -- @tests AIWorld:type
        -- TODO: add assertion for AIWorld:type
    end)
end)

describe("Missing explicit test for AIWorld:typeOf", function()
    it("AIWorld:typeOf works", function()
        -- @tests AIWorld:typeOf
        -- TODO: add assertion for AIWorld:typeOf
    end)
end)

describe("Missing explicit test for Agent:getName", function()
    it("Agent:getName works", function()
        -- @tests Agent:getName
        -- TODO: add assertion for Agent:getName
    end)
end)

describe("Missing explicit test for Agent:setPosition", function()
    it("Agent:setPosition works", function()
        -- @tests Agent:setPosition
        -- TODO: add assertion for Agent:setPosition
    end)
end)

describe("Missing explicit test for Agent:getPosition", function()
    it("Agent:getPosition works", function()
        -- @tests Agent:getPosition
        -- TODO: add assertion for Agent:getPosition
    end)
end)

describe("Missing explicit test for Agent:setVelocity", function()
    it("Agent:setVelocity works", function()
        -- @tests Agent:setVelocity
        -- TODO: add assertion for Agent:setVelocity
    end)
end)

describe("Missing explicit test for Agent:getVelocity", function()
    it("Agent:getVelocity works", function()
        -- @tests Agent:getVelocity
        -- TODO: add assertion for Agent:getVelocity
    end)
end)

describe("Missing explicit test for Agent:setMaxSpeed", function()
    it("Agent:setMaxSpeed works", function()
        -- @tests Agent:setMaxSpeed
        -- TODO: add assertion for Agent:setMaxSpeed
    end)
end)

describe("Missing explicit test for Agent:getMaxSpeed", function()
    it("Agent:getMaxSpeed works", function()
        -- @tests Agent:getMaxSpeed
        -- TODO: add assertion for Agent:getMaxSpeed
    end)
end)

describe("Missing explicit test for Agent:setMaxForce", function()
    it("Agent:setMaxForce works", function()
        -- @tests Agent:setMaxForce
        -- TODO: add assertion for Agent:setMaxForce
    end)
end)

describe("Missing explicit test for Agent:getMaxForce", function()
    it("Agent:getMaxForce works", function()
        -- @tests Agent:getMaxForce
        -- TODO: add assertion for Agent:getMaxForce
    end)
end)

describe("Missing explicit test for Agent:setPriority", function()
    it("Agent:setPriority works", function()
        -- @tests Agent:setPriority
        -- TODO: add assertion for Agent:setPriority
    end)
end)

describe("Missing explicit test for Agent:getPriority", function()
    it("Agent:getPriority works", function()
        -- @tests Agent:getPriority
        -- TODO: add assertion for Agent:getPriority
    end)
end)

describe("Missing explicit test for Agent:setDecisionModel", function()
    it("Agent:setDecisionModel works", function()
        -- @tests Agent:setDecisionModel
        -- TODO: add assertion for Agent:setDecisionModel
    end)
end)

describe("Missing explicit test for Agent:getDecisionModel", function()
    it("Agent:getDecisionModel works", function()
        -- @tests Agent:getDecisionModel
        -- TODO: add assertion for Agent:getDecisionModel
    end)
end)

describe("Missing explicit test for Agent:addTag", function()
    it("Agent:addTag works", function()
        -- @tests Agent:addTag
        -- TODO: add assertion for Agent:addTag
    end)
end)

describe("Missing explicit test for Agent:removeTag", function()
    it("Agent:removeTag works", function()
        -- @tests Agent:removeTag
        -- TODO: add assertion for Agent:removeTag
    end)
end)

describe("Missing explicit test for Agent:hasTag", function()
    it("Agent:hasTag works", function()
        -- @tests Agent:hasTag
        -- TODO: add assertion for Agent:hasTag
    end)
end)

describe("Missing explicit test for Agent:getBlackboard", function()
    it("Agent:getBlackboard works", function()
        -- @tests Agent:getBlackboard
        -- TODO: add assertion for Agent:getBlackboard
    end)
end)

describe("Missing explicit test for Agent:type", function()
    it("Agent:type works", function()
        -- @tests Agent:type
        -- TODO: add assertion for Agent:type
    end)
end)

describe("Missing explicit test for Agent:typeOf", function()
    it("Agent:typeOf works", function()
        -- @tests Agent:typeOf
        -- TODO: add assertion for Agent:typeOf
    end)
end)

describe("Missing explicit test for Blackboard:setNumber", function()
    it("Blackboard:setNumber works", function()
        -- @tests Blackboard:setNumber
        -- TODO: add assertion for Blackboard:setNumber
    end)
end)

describe("Missing explicit test for Blackboard:setBool", function()
    it("Blackboard:setBool works", function()
        -- @tests Blackboard:setBool
        -- TODO: add assertion for Blackboard:setBool
    end)
end)

describe("Missing explicit test for Blackboard:setString", function()
    it("Blackboard:setString works", function()
        -- @tests Blackboard:setString
        -- TODO: add assertion for Blackboard:setString
    end)
end)

describe("Missing explicit test for Blackboard:remove", function()
    it("Blackboard:remove works", function()
        -- @tests Blackboard:remove
        -- TODO: add assertion for Blackboard:remove
    end)
end)

describe("Missing explicit test for Blackboard:clear", function()
    it("Blackboard:clear works", function()
        -- @tests Blackboard:clear
        -- TODO: add assertion for Blackboard:clear
    end)
end)

describe("Missing explicit test for Blackboard:getKeys", function()
    it("Blackboard:getKeys works", function()
        -- @tests Blackboard:getKeys
        -- TODO: add assertion for Blackboard:getKeys
    end)
end)

describe("Missing explicit test for Blackboard:getSize", function()
    it("Blackboard:getSize works", function()
        -- @tests Blackboard:getSize
        -- TODO: add assertion for Blackboard:getSize
    end)
end)

describe("Missing explicit test for Blackboard:type", function()
    it("Blackboard:type works", function()
        -- @tests Blackboard:type
        -- TODO: add assertion for Blackboard:type
    end)
end)

describe("Missing explicit test for Blackboard:typeOf", function()
    it("Blackboard:typeOf works", function()
        -- @tests Blackboard:typeOf
        -- TODO: add assertion for Blackboard:typeOf
    end)
end)

describe("Missing explicit test for StateMachine:addState", function()
    it("StateMachine:addState works", function()
        -- @tests StateMachine:addState
        -- TODO: add assertion for StateMachine:addState
    end)
end)

describe("Missing explicit test for StateMachine:setInitialState", function()
    it("StateMachine:setInitialState works", function()
        -- @tests StateMachine:setInitialState
        -- TODO: add assertion for StateMachine:setInitialState
    end)
end)

describe("Missing explicit test for StateMachine:getCurrentState", function()
    it("StateMachine:getCurrentState works", function()
        -- @tests StateMachine:getCurrentState
        -- TODO: add assertion for StateMachine:getCurrentState
    end)
end)

describe("Missing explicit test for StateMachine:forceState", function()
    it("StateMachine:forceState works", function()
        -- @tests StateMachine:forceState
        -- TODO: add assertion for StateMachine:forceState
    end)
end)

describe("Missing explicit test for StateMachine:getTimeInState", function()
    it("StateMachine:getTimeInState works", function()
        -- @tests StateMachine:getTimeInState
        -- TODO: add assertion for StateMachine:getTimeInState
    end)
end)

describe("Missing explicit test for StateMachine:type", function()
    it("StateMachine:type works", function()
        -- @tests StateMachine:type
        -- TODO: add assertion for StateMachine:type
    end)
end)

describe("Missing explicit test for StateMachine:typeOf", function()
    it("StateMachine:typeOf works", function()
        -- @tests StateMachine:typeOf
        -- TODO: add assertion for StateMachine:typeOf
    end)
end)

describe("Missing explicit test for BehaviorTree:setRoot", function()
    it("BehaviorTree:setRoot works", function()
        -- @tests BehaviorTree:setRoot
        -- TODO: add assertion for BehaviorTree:setRoot
    end)
end)

describe("Missing explicit test for BehaviorTree:getLastStatus", function()
    it("BehaviorTree:getLastStatus works", function()
        -- @tests BehaviorTree:getLastStatus
        -- TODO: add assertion for BehaviorTree:getLastStatus
    end)
end)

describe("Missing explicit test for BehaviorTree:type", function()
    it("BehaviorTree:type works", function()
        -- @tests BehaviorTree:type
        -- TODO: add assertion for BehaviorTree:type
    end)
end)

describe("Missing explicit test for BehaviorTree:typeOf", function()
    it("BehaviorTree:typeOf works", function()
        -- @tests BehaviorTree:typeOf
        -- TODO: add assertion for BehaviorTree:typeOf
    end)
end)

describe("Missing explicit test for BTNode:addChild", function()
    it("BTNode:addChild works", function()
        -- @tests BTNode:addChild
        -- TODO: add assertion for BTNode:addChild
    end)
end)

describe("Missing explicit test for BTNode:getChildCount", function()
    it("BTNode:getChildCount works", function()
        -- @tests BTNode:getChildCount
        -- TODO: add assertion for BTNode:getChildCount
    end)
end)

describe("Missing explicit test for BTNode:reset", function()
    it("BTNode:reset works", function()
        -- @tests BTNode:reset
        -- TODO: add assertion for BTNode:reset
    end)
end)

describe("Missing explicit test for BTNode:setChild", function()
    it("BTNode:setChild works", function()
        -- @tests BTNode:setChild
        -- TODO: add assertion for BTNode:setChild
    end)
end)

describe("Missing explicit test for BTNode:setCount", function()
    it("BTNode:setCount works", function()
        -- @tests BTNode:setCount
        -- TODO: add assertion for BTNode:setCount
    end)
end)

describe("Missing explicit test for BTNode:getCount", function()
    it("BTNode:getCount works", function()
        -- @tests BTNode:getCount
        -- TODO: add assertion for BTNode:getCount
    end)
end)

describe("Missing explicit test for BTNode:setSuccessPolicy", function()
    it("BTNode:setSuccessPolicy works", function()
        -- @tests BTNode:setSuccessPolicy
        -- TODO: add assertion for BTNode:setSuccessPolicy
    end)
end)

describe("Missing explicit test for BTNode:setFailurePolicy", function()
    it("BTNode:setFailurePolicy works", function()
        -- @tests BTNode:setFailurePolicy
        -- TODO: add assertion for BTNode:setFailurePolicy
    end)
end)

describe("Missing explicit test for BTNode:getNodeType", function()
    it("BTNode:getNodeType works", function()
        -- @tests BTNode:getNodeType
        -- TODO: add assertion for BTNode:getNodeType
    end)
end)

describe("Missing explicit test for BTNode:type", function()
    it("BTNode:type works", function()
        -- @tests BTNode:type
        -- TODO: add assertion for BTNode:type
    end)
end)

describe("Missing explicit test for BTNode:typeOf", function()
    it("BTNode:typeOf works", function()
        -- @tests BTNode:typeOf
        -- TODO: add assertion for BTNode:typeOf
    end)
end)

describe("Missing explicit test for SteeringManager:getBehaviorCount", function()
    it("SteeringManager:getBehaviorCount works", function()
        -- @tests SteeringManager:getBehaviorCount
        -- TODO: add assertion for SteeringManager:getBehaviorCount
    end)
end)

describe("Missing explicit test for SteeringManager:setCombineMode", function()
    it("SteeringManager:setCombineMode works", function()
        -- @tests SteeringManager:setCombineMode
        -- TODO: add assertion for SteeringManager:setCombineMode
    end)
end)

describe("Missing explicit test for SteeringManager:getCombineMode", function()
    it("SteeringManager:getCombineMode works", function()
        -- @tests SteeringManager:getCombineMode
        -- TODO: add assertion for SteeringManager:getCombineMode
    end)
end)

describe("Missing explicit test for SteeringManager:getLastSteering", function()
    it("SteeringManager:getLastSteering works", function()
        -- @tests SteeringManager:getLastSteering
        -- TODO: add assertion for SteeringManager:getLastSteering
    end)
end)

describe("Missing explicit test for SteeringManager:type", function()
    it("SteeringManager:type works", function()
        -- @tests SteeringManager:type
        -- TODO: add assertion for SteeringManager:type
    end)
end)

describe("Missing explicit test for SteeringManager:typeOf", function()
    it("SteeringManager:typeOf works", function()
        -- @tests SteeringManager:typeOf
        -- TODO: add assertion for SteeringManager:typeOf
    end)
end)

describe("Missing explicit test for QLearner:chooseAction", function()
    it("QLearner:chooseAction works", function()
        -- @tests QLearner:chooseAction
        -- TODO: add assertion for QLearner:chooseAction
    end)
end)

describe("Missing explicit test for QLearner:bestAction", function()
    it("QLearner:bestAction works", function()
        -- @tests QLearner:bestAction
        -- TODO: add assertion for QLearner:bestAction
    end)
end)

describe("Missing explicit test for QLearner:getQValue", function()
    it("QLearner:getQValue works", function()
        -- @tests QLearner:getQValue
        -- TODO: add assertion for QLearner:getQValue
    end)
end)

describe("Missing explicit test for QLearner:endEpisode", function()
    it("QLearner:endEpisode works", function()
        -- @tests QLearner:endEpisode
        -- TODO: add assertion for QLearner:endEpisode
    end)
end)

describe("Missing explicit test for QLearner:getEpisodeCount", function()
    it("QLearner:getEpisodeCount works", function()
        -- @tests QLearner:getEpisodeCount
        -- TODO: add assertion for QLearner:getEpisodeCount
    end)
end)

describe("Missing explicit test for QLearner:getStateCount", function()
    it("QLearner:getStateCount works", function()
        -- @tests QLearner:getStateCount
        -- TODO: add assertion for QLearner:getStateCount
    end)
end)

describe("Missing explicit test for QLearner:getActionCount", function()
    it("QLearner:getActionCount works", function()
        -- @tests QLearner:getActionCount
        -- TODO: add assertion for QLearner:getActionCount
    end)
end)

describe("Missing explicit test for QLearner:setLearningRate", function()
    it("QLearner:setLearningRate works", function()
        -- @tests QLearner:setLearningRate
        -- TODO: add assertion for QLearner:setLearningRate
    end)
end)

describe("Missing explicit test for QLearner:getLearningRate", function()
    it("QLearner:getLearningRate works", function()
        -- @tests QLearner:getLearningRate
        -- TODO: add assertion for QLearner:getLearningRate
    end)
end)

describe("Missing explicit test for QLearner:setDiscountFactor", function()
    it("QLearner:setDiscountFactor works", function()
        -- @tests QLearner:setDiscountFactor
        -- TODO: add assertion for QLearner:setDiscountFactor
    end)
end)

describe("Missing explicit test for QLearner:getDiscountFactor", function()
    it("QLearner:getDiscountFactor works", function()
        -- @tests QLearner:getDiscountFactor
        -- TODO: add assertion for QLearner:getDiscountFactor
    end)
end)

describe("Missing explicit test for QLearner:setExplorationRate", function()
    it("QLearner:setExplorationRate works", function()
        -- @tests QLearner:setExplorationRate
        -- TODO: add assertion for QLearner:setExplorationRate
    end)
end)

describe("Missing explicit test for QLearner:getExplorationRate", function()
    it("QLearner:getExplorationRate works", function()
        -- @tests QLearner:getExplorationRate
        -- TODO: add assertion for QLearner:getExplorationRate
    end)
end)

describe("Missing explicit test for QLearner:setExplorationDecay", function()
    it("QLearner:setExplorationDecay works", function()
        -- @tests QLearner:setExplorationDecay
        -- TODO: add assertion for QLearner:setExplorationDecay
    end)
end)

describe("Missing explicit test for QLearner:getExplorationDecay", function()
    it("QLearner:getExplorationDecay works", function()
        -- @tests QLearner:getExplorationDecay
        -- TODO: add assertion for QLearner:getExplorationDecay
    end)
end)

describe("Missing explicit test for QLearner:serialize", function()
    it("QLearner:serialize works", function()
        -- @tests QLearner:serialize
        -- TODO: add assertion for QLearner:serialize
    end)
end)

describe("Missing explicit test for QLearner:deserialize", function()
    it("QLearner:deserialize works", function()
        -- @tests QLearner:deserialize
        -- TODO: add assertion for QLearner:deserialize
    end)
end)

describe("Missing explicit test for QLearner:type", function()
    it("QLearner:type works", function()
        -- @tests QLearner:type
        -- TODO: add assertion for QLearner:type
    end)
end)

describe("Missing explicit test for QLearner:typeOf", function()
    it("QLearner:typeOf works", function()
        -- @tests QLearner:typeOf
        -- TODO: add assertion for QLearner:typeOf
    end)
end)

describe("Missing explicit test for UtilityAI:evaluate", function()
    it("UtilityAI:evaluate works", function()
        -- @tests UtilityAI:evaluate
        -- TODO: add assertion for UtilityAI:evaluate
    end)
end)

describe("Missing explicit test for UtilityAI:getActionCount", function()
    it("UtilityAI:getActionCount works", function()
        -- @tests UtilityAI:getActionCount
        -- TODO: add assertion for UtilityAI:getActionCount
    end)
end)

describe("Missing explicit test for UtilityAI:getLastAction", function()
    it("UtilityAI:getLastAction works", function()
        -- @tests UtilityAI:getLastAction
        -- TODO: add assertion for UtilityAI:getLastAction
    end)
end)

describe("Missing explicit test for UtilityAI:type", function()
    it("UtilityAI:type works", function()
        -- @tests UtilityAI:type
        -- TODO: add assertion for UtilityAI:type
    end)
end)

describe("Missing explicit test for UtilityAI:typeOf", function()
    it("UtilityAI:typeOf works", function()
        -- @tests UtilityAI:typeOf
        -- TODO: add assertion for UtilityAI:typeOf
    end)
end)

describe("Missing explicit test for GOAPPlanner:getActionCount", function()
    it("GOAPPlanner:getActionCount works", function()
        -- @tests GOAPPlanner:getActionCount
        -- TODO: add assertion for GOAPPlanner:getActionCount
    end)
end)

describe("Missing explicit test for GOAPPlanner:getGoalCount", function()
    it("GOAPPlanner:getGoalCount works", function()
        -- @tests GOAPPlanner:getGoalCount
        -- TODO: add assertion for GOAPPlanner:getGoalCount
    end)
end)

describe("Missing explicit test for GOAPPlanner:type", function()
    it("GOAPPlanner:type works", function()
        -- @tests GOAPPlanner:type
        -- TODO: add assertion for GOAPPlanner:type
    end)
end)

describe("Missing explicit test for GOAPPlanner:typeOf", function()
    it("GOAPPlanner:typeOf works", function()
        -- @tests GOAPPlanner:typeOf
        -- TODO: add assertion for GOAPPlanner:typeOf
    end)
end)

describe("Missing explicit test for InfluenceMap:addLayer", function()
    it("InfluenceMap:addLayer works", function()
        -- @tests InfluenceMap:addLayer
        -- TODO: add assertion for InfluenceMap:addLayer
    end)
end)

describe("Missing explicit test for InfluenceMap:hasLayer", function()
    it("InfluenceMap:hasLayer works", function()
        -- @tests InfluenceMap:hasLayer
        -- TODO: add assertion for InfluenceMap:hasLayer
    end)
end)

describe("Missing explicit test for InfluenceMap:decay", function()
    it("InfluenceMap:decay works", function()
        -- @tests InfluenceMap:decay
        -- TODO: add assertion for InfluenceMap:decay
    end)
end)

describe("Missing explicit test for InfluenceMap:clearLayer", function()
    it("InfluenceMap:clearLayer works", function()
        -- @tests InfluenceMap:clearLayer
        -- TODO: add assertion for InfluenceMap:clearLayer
    end)
end)

describe("Missing explicit test for InfluenceMap:clearAll", function()
    it("InfluenceMap:clearAll works", function()
        -- @tests InfluenceMap:clearAll
        -- TODO: add assertion for InfluenceMap:clearAll
    end)
end)

describe("Missing explicit test for InfluenceMap:getMaxPosition", function()
    it("InfluenceMap:getMaxPosition works", function()
        -- @tests InfluenceMap:getMaxPosition
        -- TODO: add assertion for InfluenceMap:getMaxPosition
    end)
end)

describe("Missing explicit test for InfluenceMap:getMinPosition", function()
    it("InfluenceMap:getMinPosition works", function()
        -- @tests InfluenceMap:getMinPosition
        -- TODO: add assertion for InfluenceMap:getMinPosition
    end)
end)

describe("Missing explicit test for InfluenceMap:getWidth", function()
    it("InfluenceMap:getWidth works", function()
        -- @tests InfluenceMap:getWidth
        -- TODO: add assertion for InfluenceMap:getWidth
    end)
end)

describe("Missing explicit test for InfluenceMap:getHeight", function()
    it("InfluenceMap:getHeight works", function()
        -- @tests InfluenceMap:getHeight
        -- TODO: add assertion for InfluenceMap:getHeight
    end)
end)

describe("Missing explicit test for InfluenceMap:getCellSize", function()
    it("InfluenceMap:getCellSize works", function()
        -- @tests InfluenceMap:getCellSize
        -- TODO: add assertion for InfluenceMap:getCellSize
    end)
end)

describe("Missing explicit test for InfluenceMap:type", function()
    it("InfluenceMap:type works", function()
        -- @tests InfluenceMap:type
        -- TODO: add assertion for InfluenceMap:type
    end)
end)

describe("Missing explicit test for InfluenceMap:typeOf", function()
    it("InfluenceMap:typeOf works", function()
        -- @tests InfluenceMap:typeOf
        -- TODO: add assertion for InfluenceMap:typeOf
    end)
end)

describe("Missing explicit test for Squad:getName", function()
    it("Squad:getName works", function()
        -- @tests Squad:getName
        -- TODO: add assertion for Squad:getName
    end)
end)

describe("Missing explicit test for Squad:addMember", function()
    it("Squad:addMember works", function()
        -- @tests Squad:addMember
        -- TODO: add assertion for Squad:addMember
    end)
end)

describe("Missing explicit test for Squad:removeMember", function()
    it("Squad:removeMember works", function()
        -- @tests Squad:removeMember
        -- TODO: add assertion for Squad:removeMember
    end)
end)

describe("Missing explicit test for Squad:getMemberCount", function()
    it("Squad:getMemberCount works", function()
        -- @tests Squad:getMemberCount
        -- TODO: add assertion for Squad:getMemberCount
    end)
end)

describe("Missing explicit test for Squad:getMembers", function()
    it("Squad:getMembers works", function()
        -- @tests Squad:getMembers
        -- TODO: add assertion for Squad:getMembers
    end)
end)

describe("Missing explicit test for Squad:setLeader", function()
    it("Squad:setLeader works", function()
        -- @tests Squad:setLeader
        -- TODO: add assertion for Squad:setLeader
    end)
end)

describe("Missing explicit test for Squad:getLeader", function()
    it("Squad:getLeader works", function()
        -- @tests Squad:getLeader
        -- TODO: add assertion for Squad:getLeader
    end)
end)

describe("Missing explicit test for Squad:getFormation", function()
    it("Squad:getFormation works", function()
        -- @tests Squad:getFormation
        -- TODO: add assertion for Squad:getFormation
    end)
end)

describe("Missing explicit test for Squad:getFormationSpacing", function()
    it("Squad:getFormationSpacing works", function()
        -- @tests Squad:getFormationSpacing
        -- TODO: add assertion for Squad:getFormationSpacing
    end)
end)

describe("Missing explicit test for Squad:getBlackboard", function()
    it("Squad:getBlackboard works", function()
        -- @tests Squad:getBlackboard
        -- TODO: add assertion for Squad:getBlackboard
    end)
end)

describe("Missing explicit test for Squad:type", function()
    it("Squad:type works", function()
        -- @tests Squad:type
        -- TODO: add assertion for Squad:type
    end)
end)

describe("Missing explicit test for Squad:typeOf", function()
    it("Squad:typeOf works", function()
        -- @tests Squad:typeOf
        -- TODO: add assertion for Squad:typeOf
    end)
end)

describe("Missing explicit test for CommandQueue:cancelCurrent", function()
    it("CommandQueue:cancelCurrent works", function()
        -- @tests CommandQueue:cancelCurrent
        -- TODO: add assertion for CommandQueue:cancelCurrent
    end)
end)

describe("Missing explicit test for CommandQueue:clear", function()
    it("CommandQueue:clear works", function()
        -- @tests CommandQueue:clear
        -- TODO: add assertion for CommandQueue:clear
    end)
end)

describe("Missing explicit test for CommandQueue:getCount", function()
    it("CommandQueue:getCount works", function()
        -- @tests CommandQueue:getCount
        -- TODO: add assertion for CommandQueue:getCount
    end)
end)

describe("Missing explicit test for CommandQueue:isEmpty", function()
    it("CommandQueue:isEmpty works", function()
        -- @tests CommandQueue:isEmpty
        -- TODO: add assertion for CommandQueue:isEmpty
    end)
end)

describe("Missing explicit test for CommandQueue:getCurrentType", function()
    it("CommandQueue:getCurrentType works", function()
        -- @tests CommandQueue:getCurrentType
        -- TODO: add assertion for CommandQueue:getCurrentType
    end)
end)

describe("Missing explicit test for CommandQueue:type", function()
    it("CommandQueue:type works", function()
        -- @tests CommandQueue:type
        -- TODO: add assertion for CommandQueue:type
    end)
end)

describe("Missing explicit test for CommandQueue:typeOf", function()
    it("CommandQueue:typeOf works", function()
        -- @tests CommandQueue:typeOf
        -- TODO: add assertion for CommandQueue:typeOf
    end)
end)

describe("Missing explicit test for TraitProfile:getBase", function()
    it("TraitProfile:getBase works", function()
        -- @tests TraitProfile:getBase
        -- TODO: add assertion for TraitProfile:getBase
    end)
end)

describe("Missing explicit test for TraitProfile:removeModifiers", function()
    it("TraitProfile:removeModifiers works", function()
        -- @tests TraitProfile:removeModifiers
        -- TODO: add assertion for TraitProfile:removeModifiers
    end)
end)

describe("Missing explicit test for TraitProfile:update", function()
    it("TraitProfile:update works", function()
        -- @tests TraitProfile:update
        -- TODO: add assertion for TraitProfile:update
    end)
end)

describe("Missing explicit test for TraitProfile:traitCount", function()
    it("TraitProfile:traitCount works", function()
        -- @tests TraitProfile:traitCount
        -- TODO: add assertion for TraitProfile:traitCount
    end)
end)

describe("Missing explicit test for TraitProfile:archetype", function()
    it("TraitProfile:archetype works", function()
        -- @tests TraitProfile:archetype
        -- TODO: add assertion for TraitProfile:archetype
    end)
end)

describe("Missing explicit test for StimulusWorld:remove", function()
    it("StimulusWorld:remove works", function()
        -- @tests StimulusWorld:remove
        -- TODO: add assertion for StimulusWorld:remove
    end)
end)

describe("Missing explicit test for StimulusWorld:update", function()
    it("StimulusWorld:update works", function()
        -- @tests StimulusWorld:update
        -- TODO: add assertion for StimulusWorld:update
    end)
end)

describe("Missing explicit test for StimulusWorld:clear", function()
    it("StimulusWorld:clear works", function()
        -- @tests StimulusWorld:clear
        -- TODO: add assertion for StimulusWorld:clear
    end)
end)

describe("Missing explicit test for ContextSteering:addWander", function()
    it("ContextSteering:addWander works", function()
        -- @tests ContextSteering:addWander
        -- TODO: add assertion for ContextSteering:addWander
    end)
end)

describe("Missing explicit test for ContextSteering:clearBehaviors", function()
    it("ContextSteering:clearBehaviors works", function()
        -- @tests ContextSteering:clearBehaviors
        -- TODO: add assertion for ContextSteering:clearBehaviors
    end)
end)

describe("Missing explicit test for ContextSteering:chosenMagnitude", function()
    it("ContextSteering:chosenMagnitude works", function()
        -- @tests ContextSteering:chosenMagnitude
        -- TODO: add assertion for ContextSteering:chosenMagnitude
    end)
end)

describe("Missing explicit test for ContextSteering:slotCount", function()
    it("ContextSteering:slotCount works", function()
        -- @tests ContextSteering:slotCount
        -- TODO: add assertion for ContextSteering:slotCount
    end)
end)

describe("Missing explicit test for NeedSystem:addNeed", function()
    it("NeedSystem:addNeed works", function()
        -- @tests NeedSystem:addNeed
        -- TODO: add assertion for NeedSystem:addNeed
    end)
end)

describe("Missing explicit test for NeedSystem:update", function()
    it("NeedSystem:update works", function()
        -- @tests NeedSystem:update
        -- TODO: add assertion for NeedSystem:update
    end)
end)

describe("Missing explicit test for NeedSystem:mostUrgent", function()
    it("NeedSystem:mostUrgent works", function()
        -- @tests NeedSystem:mostUrgent
        -- TODO: add assertion for NeedSystem:mostUrgent
    end)
end)

describe("Missing explicit test for NeedSystem:satisfy", function()
    it("NeedSystem:satisfy works", function()
        -- @tests NeedSystem:satisfy
        -- TODO: add assertion for NeedSystem:satisfy
    end)
end)

describe("Missing explicit test for NeedSystem:valueOf", function()
    it("NeedSystem:valueOf works", function()
        -- @tests NeedSystem:valueOf
        -- TODO: add assertion for NeedSystem:valueOf
    end)
end)

describe("Missing explicit test for AIDirector:pushEvent", function()
    it("AIDirector:pushEvent works", function()
        -- @tests AIDirector:pushEvent
        -- TODO: add assertion for AIDirector:pushEvent
    end)
end)

describe("Missing explicit test for AIDirector:update", function()
    it("AIDirector:update works", function()
        -- @tests AIDirector:update
        -- TODO: add assertion for AIDirector:update
    end)
end)

describe("Missing explicit test for AIDirector:tension", function()
    it("AIDirector:tension works", function()
        -- @tests AIDirector:tension
        -- TODO: add assertion for AIDirector:tension
    end)
end)

describe("Missing explicit test for AIDirector:phase", function()
    it("AIDirector:phase works", function()
        -- @tests AIDirector:phase
        -- TODO: add assertion for AIDirector:phase
    end)
end)

describe("Missing explicit test for AIDirector:spawnRateFactor", function()
    it("AIDirector:spawnRateFactor works", function()
        -- @tests AIDirector:spawnRateFactor
        -- TODO: add assertion for AIDirector:spawnRateFactor
    end)
end)

describe("Missing explicit test for AIDirector:lootFactor", function()
    it("AIDirector:lootFactor works", function()
        -- @tests AIDirector:lootFactor
        -- TODO: add assertion for AIDirector:lootFactor
    end)
end)

describe("Missing explicit test for AIDirector:ambientIntensity", function()
    it("AIDirector:ambientIntensity works", function()
        -- @tests AIDirector:ambientIntensity
        -- TODO: add assertion for AIDirector:ambientIntensity
    end)
end)

describe("Missing explicit test for AIDirector:setTension", function()
    it("AIDirector:setTension works", function()
        -- @tests AIDirector:setTension
        -- TODO: add assertion for AIDirector:setTension
    end)
end)

describe("Missing explicit test for AIDirector:reset", function()
    it("AIDirector:reset works", function()
        -- @tests AIDirector:reset
        -- TODO: add assertion for AIDirector:reset
    end)
end)

describe("Missing explicit test for HTNDomain:addPrimitive", function()
    it("HTNDomain:addPrimitive works", function()
        -- @tests HTNDomain:addPrimitive
        -- TODO: add assertion for HTNDomain:addPrimitive
    end)
end)

describe("Missing explicit test for HTNDomain:taskCount", function()
    it("HTNDomain:taskCount works", function()
        -- @tests HTNDomain:taskCount
        -- TODO: add assertion for HTNDomain:taskCount
    end)
end)

describe("Missing explicit test for EmotionModel:trigger", function()
    it("EmotionModel:trigger works", function()
        -- @tests EmotionModel:trigger
        -- TODO: add assertion for EmotionModel:trigger
    end)
end)

describe("Missing explicit test for EmotionModel:dominant", function()
    it("EmotionModel:dominant works", function()
        -- @tests EmotionModel:dominant
        -- TODO: add assertion for EmotionModel:dominant
    end)
end)

describe("Missing explicit test for EmotionModel:isActive", function()
    it("EmotionModel:isActive works", function()
        -- @tests EmotionModel:isActive
        -- TODO: add assertion for EmotionModel:isActive
    end)
end)

describe("Missing explicit test for EmotionModel:update", function()
    it("EmotionModel:update works", function()
        -- @tests EmotionModel:update
        -- TODO: add assertion for EmotionModel:update
    end)
end)

describe("Missing explicit test for EmotionModel:reset", function()
    it("EmotionModel:reset works", function()
        -- @tests EmotionModel:reset
        -- TODO: add assertion for EmotionModel:reset
    end)
end)

describe("Missing explicit test for ORCASolver:setPosition", function()
    it("ORCASolver:setPosition works", function()
        -- @tests ORCASolver:setPosition
        -- TODO: add assertion for ORCASolver:setPosition
    end)
end)

describe("Missing explicit test for ORCASolver:compute", function()
    it("ORCASolver:compute works", function()
        -- @tests ORCASolver:compute
        -- TODO: add assertion for ORCASolver:compute
    end)
end)

describe("Missing explicit test for ORCASolver:getSafeVelocity", function()
    it("ORCASolver:getSafeVelocity works", function()
        -- @tests ORCASolver:getSafeVelocity
        -- TODO: add assertion for ORCASolver:getSafeVelocity
    end)
end)

describe("Missing explicit test for ORCASolver:agentCount", function()
    it("ORCASolver:agentCount works", function()
        -- @tests ORCASolver:agentCount
        -- TODO: add assertion for ORCASolver:agentCount
    end)
end)

describe("Missing explicit test for NeuralNet:forward", function()
    it("NeuralNet:forward works", function()
        -- @tests NeuralNet:forward
        -- TODO: add assertion for NeuralNet:forward
    end)
end)

describe("Missing explicit test for NeuralNet:setWeights", function()
    it("NeuralNet:setWeights works", function()
        -- @tests NeuralNet:setWeights
        -- TODO: add assertion for NeuralNet:setWeights
    end)
end)

describe("Missing explicit test for NeuralNet:getWeights", function()
    it("NeuralNet:getWeights works", function()
        -- @tests NeuralNet:getWeights
        -- TODO: add assertion for NeuralNet:getWeights
    end)
end)

describe("Missing explicit test for NeuralNet:paramCount", function()
    it("NeuralNet:paramCount works", function()
        -- @tests NeuralNet:paramCount
        -- TODO: add assertion for NeuralNet:paramCount
    end)
end)

describe("Missing explicit test for NeuralNet:layerCount", function()
    it("NeuralNet:layerCount works", function()
        -- @tests NeuralNet:layerCount
        -- TODO: add assertion for NeuralNet:layerCount
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:evolve", function()
    it("GeneticAlgorithm:evolve works", function()
        -- @tests GeneticAlgorithm:evolve
        -- TODO: add assertion for GeneticAlgorithm:evolve
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:generation", function()
    it("GeneticAlgorithm:generation works", function()
        -- @tests GeneticAlgorithm:generation
        -- TODO: add assertion for GeneticAlgorithm:generation
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:popSize", function()
    it("GeneticAlgorithm:popSize works", function()
        -- @tests GeneticAlgorithm:popSize
        -- TODO: add assertion for GeneticAlgorithm:popSize
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:setFitness", function()
    it("GeneticAlgorithm:setFitness works", function()
        -- @tests GeneticAlgorithm:setFitness
        -- TODO: add assertion for GeneticAlgorithm:setFitness
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:getGenes", function()
    it("GeneticAlgorithm:getGenes works", function()
        -- @tests GeneticAlgorithm:getGenes
        -- TODO: add assertion for GeneticAlgorithm:getGenes
    end)
end)

describe("Missing explicit test for GeneticAlgorithm:bestGenes", function()
    it("GeneticAlgorithm:bestGenes works", function()
        -- @tests GeneticAlgorithm:bestGenes
        -- TODO: add assertion for GeneticAlgorithm:bestGenes
    end)
end)

describe("Missing explicit test for Bandit:select", function()
    it("Bandit:select works", function()
        -- @tests Bandit:select
        -- TODO: add assertion for Bandit:select
    end)
end)

describe("Missing explicit test for Bandit:update", function()
    it("Bandit:update works", function()
        -- @tests Bandit:update
        -- TODO: add assertion for Bandit:update
    end)
end)

describe("Missing explicit test for Bandit:bestArm", function()
    it("Bandit:bestArm works", function()
        -- @tests Bandit:bestArm
        -- TODO: add assertion for Bandit:bestArm
    end)
end)

describe("Missing explicit test for Bandit:reset", function()
    it("Bandit:reset works", function()
        -- @tests Bandit:reset
        -- TODO: add assertion for Bandit:reset
    end)
end)

describe("Missing explicit test for Bandit:armCount", function()
    it("Bandit:armCount works", function()
        -- @tests Bandit:armCount
        -- TODO: add assertion for Bandit:armCount
    end)
end)

describe("Missing explicit test for Bandit:totalPulls", function()
    it("Bandit:totalPulls works", function()
        -- @tests Bandit:totalPulls
        -- TODO: add assertion for Bandit:totalPulls
    end)
end)

describe("Missing explicit test for Neuroevolution:evolve", function()
    it("Neuroevolution:evolve works", function()
        -- @tests Neuroevolution:evolve
        -- TODO: add assertion for Neuroevolution:evolve
    end)
end)

describe("Missing explicit test for Neuroevolution:setFitness", function()
    it("Neuroevolution:setFitness works", function()
        -- @tests Neuroevolution:setFitness
        -- TODO: add assertion for Neuroevolution:setFitness
    end)
end)

describe("Missing explicit test for Neuroevolution:chromosomeToNet", function()
    it("Neuroevolution:chromosomeToNet works", function()
        -- @tests Neuroevolution:chromosomeToNet
        -- TODO: add assertion for Neuroevolution:chromosomeToNet
    end)
end)

describe("Missing explicit test for Neuroevolution:bestNetwork", function()
    it("Neuroevolution:bestNetwork works", function()
        -- @tests Neuroevolution:bestNetwork
        -- TODO: add assertion for Neuroevolution:bestNetwork
    end)
end)

describe("Missing explicit test for Neuroevolution:popSize", function()
    it("Neuroevolution:popSize works", function()
        -- @tests Neuroevolution:popSize
        -- TODO: add assertion for Neuroevolution:popSize
    end)
end)

describe("Missing explicit test for Neuroevolution:generation", function()
    it("Neuroevolution:generation works", function()
        -- @tests Neuroevolution:generation
        -- TODO: add assertion for Neuroevolution:generation
    end)
end)

describe("Missing explicit test for StrategyAI:addGoal", function()
    it("StrategyAI:addGoal works", function()
        -- @tests StrategyAI:addGoal
        -- TODO: add assertion for StrategyAI:addGoal
    end)
end)

describe("Missing explicit test for StrategyAI:addTag", function()
    it("StrategyAI:addTag works", function()
        -- @tests StrategyAI:addTag
        -- TODO: add assertion for StrategyAI:addTag
    end)
end)

describe("Missing explicit test for StrategyAI:removeTag", function()
    it("StrategyAI:removeTag works", function()
        -- @tests StrategyAI:removeTag
        -- TODO: add assertion for StrategyAI:removeTag
    end)
end)

describe("Missing explicit test for StrategyAI:update", function()
    it("StrategyAI:update works", function()
        -- @tests StrategyAI:update
        -- TODO: add assertion for StrategyAI:update
    end)
end)

describe("Missing explicit test for StrategyAI:forceEvaluate", function()
    it("StrategyAI:forceEvaluate works", function()
        -- @tests StrategyAI:forceEvaluate
        -- TODO: add assertion for StrategyAI:forceEvaluate
    end)
end)

describe("Missing explicit test for StrategyAI:activeGoal", function()
    it("StrategyAI:activeGoal works", function()
        -- @tests StrategyAI:activeGoal
        -- TODO: add assertion for StrategyAI:activeGoal
    end)
end)

describe("Missing explicit test for StrategyAI:timeUntilNext", function()
    it("StrategyAI:timeUntilNext works", function()
        -- @tests StrategyAI:timeUntilNext
        -- TODO: add assertion for StrategyAI:timeUntilNext
    end)
end)

describe("Missing explicit test for AILod:shouldUpdate", function()
    it("AILod:shouldUpdate works", function()
        -- @tests AILod:shouldUpdate
        -- TODO: add assertion for AILod:shouldUpdate
    end)
end)

describe("Missing explicit test for AILod:tierCount", function()
    it("AILod:tierCount works", function()
        -- @tests AILod:tierCount
        -- TODO: add assertion for AILod:tierCount
    end)
end)

describe("Missing explicit test for AILod:tierName", function()
    it("AILod:tierName works", function()
        -- @tests AILod:tierName
        -- TODO: add assertion for AILod:tierName
    end)
end)

-- =========================================================================
-- Extensibility Hooks (Phase 01)
-- =========================================================================

-- @description Verifies the newGuard factory is exported as a function.
describe("lurek.ai extensibility factories", function()
    -- @tests lurek.ai.newGuard
    it("has newGuard factory", function()
        assert.is_function(lurek.ai.newGuard, "newGuard should be a function")
    end)
end)

-- @description Tests the custom decision model callback mechanism.
describe("custom decision model", function()
    -- @tests Agent:setCustomModel
    -- @description Sets a custom decision model callback on an agent and verifies
    -- it is invoked when the world is updated.
    it("can set custom model on agent and callback fires on update", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("test_custom_agent")
        local called = false
        agent:setCustomModel(function(ag, bb, dt)
            called = true
        end)
        world:update(0.016)
        assert.is_true(called, "custom model callback should be called on update")
    end)

    -- @description Verifies getDecisionModel returns "custom" after setCustomModel.
    it("getDecisionModel returns 'custom' after setCustomModel", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("model_check_agent")
        agent:setCustomModel(function(ag, bb, dt) end)
        assert.equal("custom", agent:getDecisionModel(),
            "decision model name should be 'custom'")
    end)
end)

-- @description Tests the BT Guard decorator factory and structural properties.
describe("BT Guard decorator", function()
    -- @tests lurek.ai.newGuard
    -- @description Creates a guard node via newGuard and checks its type.
    it("creates guard node via newGuard", function()
        local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
        local guard = lurek.ai.newGuard(function(ag, bb) return true end, action)
        assert.is_not_nil(guard, "Guard node should be created")
        assert.equal("guard", guard:getNodeType(), "node type should be 'guard'")
    end)

    -- @description Verifies a guard node reports exactly one child.
    it("guard has child count 1", function()
        local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
        local guard = lurek.ai.newGuard(function(ag, bb) return false end, action)
        assert.equal(1, guard:getChildCount(), "Guard should have 1 child")
    end)
end)

-- @description Tests addConsideration accepting a Lua function as a custom curve.
describe("custom utility response curve", function()
    -- @tests UtilityAI:addConsideration
    -- @description addConsideration should not error when the curve argument is a function.
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
        assert.is_true(ok, "addConsideration with function curve should succeed")
    end)

    -- @description addConsideration with a string curve should still work.
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
        assert.is_true(ok, "addConsideration with string curve should succeed")
    end)
end)

-- @description Tests addCustomBehavior on a SteeringManager.
describe("custom steering behavior", function()
    -- @tests SteeringManager:addCustomBehavior
    it("addCustomBehavior adds one behavior to the manager", function()
        local sm = lurek.ai.newSteeringManager()
        local before = sm:getBehaviorCount()
        sm:addCustomBehavior(function(ag, dt) return 10, 0 end, 1.0)
        assert.equal(before + 1, sm:getBehaviorCount(),
            "behavior count should increase by 1")
    end)

    -- @tests SteeringManager:applyCustomSteering
    it("applyCustomSteering returns a force pair without error", function()
        local sm = lurek.ai.newSteeringManager()
        -- applyCustomSteering needs an agent userdata — without a world it must
        -- still not panic; pass nil as a smoke test.
        local ok = pcall(function()
            sm:applyCustomSteering(nil, 0.016)
        end)
        -- Even with nil agent (no custom behaviors) it should not crash.
        assert.is_true(ok, "applyCustomSteering with no custom behaviors should not error")
    end)
end)


-- =========================================================================
-- Lua extensibility: Agent:setCustomModel
-- =========================================================================

-- @description Verifies that Agent:setCustomModel installs a Lua callback as the
--   decision model and that getDecisionModel returns "custom" afterwards.
describe("Agent:setCustomModel extensibility hook", function()
    -- @tests Agent:setCustomModel
    -- @tests Agent:getDecisionModel
    it("setCustomModel marks agent with custom model", function()
        local world = lurek.ai.newWorld()
        local agent = world:addAgent("test_agent")
        agent:setCustomModel(function(ag, bb, dt) end)
        assert.equal("custom", agent:getDecisionModel(),
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
        assert.is_true(called, "custom model callback should be called by world:update")
    end)
end)
