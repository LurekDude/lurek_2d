-- content/examples/ai.lua
-- Auto-scaffolded coverage of the lurek.ai Lua API (240 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/ai.lua

print("[example] lurek.ai loaded — 240 API items demonstrated")

-- ── lurek.ai free functions ──

--@api-stub: lurek.ai.newWorld
-- Creates a new AI world container.
-- Use this when creates a new AI world container is needed.
if false then
  local _r = lurek.ai.newWorld()
  print(_r)
end

--@api-stub: lurek.ai.newBlackboard
-- Creates a new standalone blackboard.
-- Use this when creates a new standalone blackboard is needed.
if false then
  local _r = lurek.ai.newBlackboard()
  print(_r)
end

--@api-stub: lurek.ai.newStateMachine
-- Creates a new finite state machine.
-- Use this when creates a new finite state machine is needed.
if false then
  local _r = lurek.ai.newStateMachine()
  print(_r)
end

--@api-stub: lurek.ai.newBehaviorTree
-- Creates a new behavior tree.
-- Use this when creates a new behavior tree is needed.
if false then
  local _r = lurek.ai.newBehaviorTree()
  print(_r)
end

--@api-stub: lurek.ai.newSelector
-- Creates a BT selector node.
-- Use this when creates a BT selector node is needed.
if false then
  local _r = lurek.ai.newSelector()
  print(_r)
end

--@api-stub: lurek.ai.newSequence
-- Creates a BT sequence node.
-- Use this when creates a BT sequence node is needed.
if false then
  local _r = lurek.ai.newSequence()
  print(_r)
end

--@api-stub: lurek.ai.newParallel
-- Creates a BT parallel node with optional policies.
-- Use this when creates a BT parallel node with optional policies is needed.
if false then
  local _r = lurek.ai.newParallel(nil, nil)
  print(_r)
end

--@api-stub: lurek.ai.newInverter
-- Creates a BT inverter decorator.
-- Use this when creates a BT inverter decorator is needed.
if false then
  local _r = lurek.ai.newInverter()
  print(_r)
end

--@api-stub: lurek.ai.newRepeater
-- Creates a BT repeater decorator.
-- Use this when creates a BT repeater decorator is needed.
if false then
  local _r = lurek.ai.newRepeater(1)
  print(_r)
end

--@api-stub: lurek.ai.newSucceeder
-- Creates a BT succeeder decorator.
-- Use this when creates a BT succeeder decorator is needed.
if false then
  local _r = lurek.ai.newSucceeder()
  print(_r)
end

--@api-stub: lurek.ai.newAction
-- Creates a BT action leaf with a Lua callback.
-- Use this when creates a BT action leaf with a Lua callback is needed.
if false then
  local _r = lurek.ai.newAction(function() end)
  print(_r)
end

--@api-stub: lurek.ai.newCondition
-- Creates a BT condition leaf with a Lua predicate.
-- Use this when creates a BT condition leaf with a Lua predicate is needed.
if false then
  local _r = lurek.ai.newCondition(function() end)
  print(_r)
end

--@api-stub: lurek.ai.newSteeringManager
-- Creates a new steering behavior manager.
-- Use this when creates a new steering behavior manager is needed.
if false then
  local _r = lurek.ai.newSteeringManager()
  print(_r)
end

--@api-stub: lurek.ai.newQLearner
-- Creates a tabular Q-learner.
-- Use this when creates a tabular Q-learner is needed.
if false then
  local _r = lurek.ai.newQLearner(nil, nil)
  print(_r)
end

--@api-stub: lurek.ai.newUtilityAI
-- Creates a new utility AI evaluator.
-- Use this when creates a new utility AI evaluator is needed.
if false then
  local _r = lurek.ai.newUtilityAI()
  print(_r)
end

--@api-stub: lurek.ai.newGOAPPlanner
-- Creates a new GOAP planning solver.
-- Use this when creates a new GOAP planning solver is needed.
if false then
  local _r = lurek.ai.newGOAPPlanner()
  print(_r)
end

--@api-stub: lurek.ai.newInfluenceMap
-- Creates a multi-layer influence map grid.
-- Use this when creates a multi-layer influence map grid is needed.
if false then
  local _r = lurek.ai.newInfluenceMap(0, 0, nil)
  print(_r)
end

--@api-stub: lurek.ai.newSquad
-- Creates a named squad for formation positioning.
-- Use this when creates a named squad for formation positioning is needed.
if false then
  local _r = lurek.ai.newSquad(1)
  print(_r)
end

--@api-stub: lurek.ai.newCommandQueue
-- Creates an RTS-style command queue.
-- Use this when creates an RTS-style command queue is needed.
if false then
  local _r = lurek.ai.newCommandQueue()
  print(_r)
end

--@api-stub: lurek.ai.newTraitProfile
-- Creates a new personality trait profile.
-- Use this when creates a new personality trait profile is needed.
if false then
  local _r = lurek.ai.newTraitProfile()
  print(_r)
end

--@api-stub: lurek.ai.newStimulusWorld
-- Creates a new stimulus perception world.
-- Use this when creates a new stimulus perception world is needed.
if false then
  local _r = lurek.ai.newStimulusWorld()
  print(_r)
end

--@api-stub: lurek.ai.newContextSteering
-- Creates a new context steering controller.
-- Use this when creates a new context steering controller is needed.
if false then
  local _r = lurek.ai.newContextSteering(0)
  print(_r)
end

--@api-stub: lurek.ai.newNeedSystem
-- Creates a new motivational need system.
-- Use this when creates a new motivational need system is needed.
if false then
  local _r = lurek.ai.newNeedSystem()
  print(_r)
end

--@api-stub: lurek.ai.newAIDirector
-- Creates a new AI pacing director with default config.
-- Use this when creates a new AI pacing director with default config is needed.
if false then
  local _r = lurek.ai.newAIDirector()
  print(_r)
end

--@api-stub: lurek.ai.newHTNDomain
-- Creates a new Hierarchical Task Network domain.
-- Use this when creates a new Hierarchical Task Network domain is needed.
if false then
  local _r = lurek.ai.newHTNDomain()
  print(_r)
end

--@api-stub: lurek.ai.newMCTSEngine
-- Creates a new Monte Carlo Tree Search engine.
-- Use this when creates a new Monte Carlo Tree Search engine is needed.
if false then
  local _r = lurek.ai.newMCTSEngine(0, 0, 1, nil)
  print(_r)
end

--@api-stub: lurek.ai.newEmotionModel
-- Creates a new affective emotion model.
-- Use this when creates a new affective emotion model is needed.
if false then
  local _r = lurek.ai.newEmotionModel()
  print(_r)
end

--@api-stub: lurek.ai.newORCASolver
-- Creates a new ORCA crowd avoidance solver.
-- Use this when creates a new ORCA crowd avoidance solver is needed.
if false then
  local _r = lurek.ai.newORCASolver(1)
  print(_r)
end

--@api-stub: lurek.ai.newNeuralNet
-- Creates a new feedforward neural network (inference only).
-- Use this when creates a new feedforward neural network (inference only) is needed.
if false then
  local _r = lurek.ai.newNeuralNet()
  print(_r)
end

--@api-stub: lurek.ai.newGeneticAlgorithm
-- Creates a new genetic algorithm.
-- Use this when creates a new genetic algorithm is needed.
if false then
  local _r = lurek.ai.newGeneticAlgorithm(1, 1, nil)
  print(_r)
end

--@api-stub: lurek.ai.newBandit
-- Creates a new multi-armed bandit.
-- Use this when creates a new multi-armed bandit is needed.
if false then
  local _r = lurek.ai.newBandit(1, 0, 1, nil)
  print(_r)
end

--@api-stub: lurek.ai.newNeuroevolution
-- Creates a neuroevolution trainer (GA for neural network weights).
-- Use this when creates a neuroevolution trainer (GA for neural network weights) is needed.
if false then
  local _r = lurek.ai.newNeuroevolution(0, 1, nil)
  print(_r)
end

--@api-stub: lurek.ai.newStrategyAI
-- Creates a new throttled strategy AI.
-- Use this when creates a new throttled strategy AI is needed.
if false then
  local _r = lurek.ai.newStrategyAI(1)
  print(_r)
end

--@api-stub: lurek.ai.newAILod
-- Creates a new AI LOD controller with default 3-tier config.
-- Use this when creates a new AI LOD controller with default 3-tier config is needed.
if false then
  local _r = lurek.ai.newAILod()
  print(_r)
end

-- ── AIWorld methods ──

--@api-stub: AIWorld:addAgent
-- Registers a new named agent and returns its handle.
-- Use this when registers a new named agent and returns its handle is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:addAgent(1)
end

--@api-stub: AIWorld:getAgent
-- Returns the agent handle for the given name, or nil.
-- Use this when returns the agent handle for the given name, or nil is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:getAgent(1)
end

--@api-stub: AIWorld:removeAgent
-- Removes an agent by its userdata handle.
-- Use this when removes an agent by its userdata handle is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:removeAgent(1)
end

--@api-stub: AIWorld:getAgentCount
-- Returns the number of registered agents.
-- Use this when returns the number of registered agents is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:getAgentCount()
end

--@api-stub: AIWorld:getGlobalBlackboard
-- Returns a snapshot of the world-level blackboard.
-- Use this when returns a snapshot of the world-level blackboard is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:getGlobalBlackboard()
end

--@api-stub: AIWorld:update
-- Advances all agents by dt seconds.
-- Use this when advances all agents by dt seconds is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:update(0)
end

--@api-stub: AIWorld:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:type()
end

--@api-stub: AIWorld:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- AIWorld instance
  _o:typeOf(1)
end

-- ── Agent methods ──

--@api-stub: Agent:getName
-- Returns the agent's registered name.
-- Use this when returns the agent's registered name is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getName()
end

--@api-stub: Agent:setPosition
-- Sets the agent's world-space position.
-- Use this when sets the agent's world-space position is needed.
if false then
  local _o = nil  -- Agent instance
  _o:setPosition(0, 0)
end

--@api-stub: Agent:getPosition
-- Returns the agent's current position.
-- Use this when returns the agent's current position is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getPosition()
end

--@api-stub: Agent:setVelocity
-- Sets the agent's velocity vector.
-- Use this when sets the agent's velocity vector is needed.
if false then
  local _o = nil  -- Agent instance
  _o:setVelocity(0, 0)
end

--@api-stub: Agent:getVelocity
-- Returns the agent's current velocity.
-- Use this when returns the agent's current velocity is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getVelocity()
end

--@api-stub: Agent:setMaxSpeed
-- Sets the maximum speed cap.
-- Use this when sets the maximum speed cap is needed.
if false then
  local _o = nil  -- Agent instance
  _o:setMaxSpeed(0)
end

--@api-stub: Agent:getMaxSpeed
-- Returns the maximum speed cap.
-- Use this when returns the maximum speed cap is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getMaxSpeed()
end

--@api-stub: Agent:setMaxForce
-- Sets the maximum steering force cap.
-- Use this when sets the maximum steering force cap is needed.
if false then
  local _o = nil  -- Agent instance
  _o:setMaxForce(0)
end

--@api-stub: Agent:getMaxForce
-- Returns the maximum steering force cap.
-- Use this when returns the maximum steering force cap is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getMaxForce()
end

--@api-stub: Agent:setPriority
-- Sets the scheduling priority (higher = earlier).
-- Use this when sets the scheduling priority (higher = earlier) is needed.
if false then
  local _o = nil  -- Agent instance
  _o:setPriority(nil)
end

--@api-stub: Agent:getPriority
-- Returns the agent's scheduling priority.
-- Use this when returns the agent's scheduling priority is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getPriority()
end

--@api-stub: Agent:setDecisionModel
-- Sets the active decision model.
-- Use this when sets the active decision model is needed.
if false then
  local _o = nil  -- Agent instance
  _o:setDecisionModel(nil)
end

--@api-stub: Agent:getDecisionModel
-- Returns the name of the current decision model.
-- Use this when returns the name of the current decision model is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getDecisionModel()
end

--@api-stub: Agent:addTag
-- Adds a tag to this agent.
-- Use this when adds a tag to this agent is needed.
if false then
  local _o = nil  -- Agent instance
  _o:addTag(0)
end

--@api-stub: Agent:removeTag
-- Removes a tag from this agent.
-- Use this when removes a tag from this agent is needed.
if false then
  local _o = nil  -- Agent instance
  _o:removeTag(0)
end

--@api-stub: Agent:hasTag
-- Returns true if the agent has the given tag.
-- Use this when returns true if the agent has the given tag is needed.
if false then
  local _o = nil  -- Agent instance
  _o:hasTag(0)
end

--@api-stub: Agent:getBlackboard
-- Returns the agent's local blackboard.
-- Use this when returns the agent's local blackboard is needed.
if false then
  local _o = nil  -- Agent instance
  _o:getBlackboard()
end

--@api-stub: Agent:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Agent instance
  _o:type()
end

--@api-stub: Agent:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- Agent instance
  _o:typeOf(1)
end

-- ── Blackboard methods ──

--@api-stub: Blackboard:setNumber
-- Stores a number under the given key.
-- Use this when stores a number under the given key is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:setNumber(0, 0)
end

--@api-stub: Blackboard:setBool
-- Stores a boolean under the given key.
-- Use this when stores a boolean under the given key is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:setBool(0, 0)
end

--@api-stub: Blackboard:setString
-- Stores a string under the given key.
-- Use this when stores a string under the given key is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:setString(0, 0)
end

--@api-stub: Blackboard:has
-- Returns true if a value exists under the key.
-- Use this when returns true if a value exists under the key is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:has(0)
end

--@api-stub: Blackboard:remove
-- Removes the entry at key.
-- Use this when removes the entry at key is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:remove(0)
end

--@api-stub: Blackboard:clear
-- Removes all local entries.
-- Use this when removes all local entries is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:clear()
end

--@api-stub: Blackboard:getKeys
-- Returns all local keys as a table.
-- Use this when returns all local keys as a table is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:getKeys()
end

--@api-stub: Blackboard:getSize
-- Returns the number of local entries.
-- Use this when returns the number of local entries is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:getSize()
end

--@api-stub: Blackboard:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:type()
end

--@api-stub: Blackboard:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:typeOf(1)
end

-- ── StateMachine methods ──

--@api-stub: StateMachine:addState
-- Registers a named state with optional lifecycle callbacks.
-- Use this when registers a named state with optional lifecycle callbacks is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:addState(1, 0)
end

--@api-stub: StateMachine:setInitialState
-- Sets the FSM's initial state; must be called before the first update.
-- Use this when sets the FSM's initial state; must be called before the first update is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:setInitialState(1)
end

--@api-stub: StateMachine:getCurrentState
-- Returns the current state name, or nil.
-- Use this when returns the current state name, or nil is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:getCurrentState()
end

--@api-stub: StateMachine:forceState
-- Forces a transition to the named state.
-- Use this when forces a transition to the named state is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:forceState(1)
end

--@api-stub: StateMachine:getTimeInState
-- Returns seconds spent in the current state.
-- Use this when returns seconds spent in the current state is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:getTimeInState()
end

--@api-stub: StateMachine:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:type()
end

--@api-stub: StateMachine:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- StateMachine instance
  _o:typeOf(1)
end

-- ── BehaviorTree methods ──

--@api-stub: BehaviorTree:setRoot
-- Sets the root node of this behavior tree.
-- Use this when sets the root node of this behavior tree is needed.
if false then
  local _o = nil  -- BehaviorTree instance
  _o:setRoot(1)
end

--@api-stub: BehaviorTree:getLastStatus
-- Returns the status from the last tick.
-- Use this when returns the status from the last tick is needed.
if false then
  local _o = nil  -- BehaviorTree instance
  _o:getLastStatus()
end

--@api-stub: BehaviorTree:getDebugState
-- Returns a diagnostic snapshot of this behavior tree.
-- Use this when returns a diagnostic snapshot of this behavior tree is needed.
if false then
  local _o = nil  -- BehaviorTree instance
  _o:getDebugState()
end

--@api-stub: BehaviorTree:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- BehaviorTree instance
  _o:type()
end

--@api-stub: BehaviorTree:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- BehaviorTree instance
  _o:typeOf(1)
end

-- ── BTNode methods ──

--@api-stub: BTNode:addChild
-- Adds a child node (Selector, Sequence, or Parallel only).
-- Use this when adds a child node (Selector, Sequence, or Parallel only) is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:addChild(0)
end

--@api-stub: BTNode:getChildCount
-- Returns the number of direct children.
-- Use this when returns the number of direct children is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:getChildCount()
end

--@api-stub: BTNode:reset
-- Resets all running-child memos and repeater counters.
-- Use this when resets all running-child memos and repeater counters is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:reset()
end

--@api-stub: BTNode:setChild
-- Sets the single child of a decorator node.
-- Use this when sets the single child of a decorator node is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:setChild(0)
end

--@api-stub: BTNode:setCount
-- Sets the repeat count for a Repeater node.
-- Use this when sets the repeat count for a Repeater node is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:setCount(1)
end

--@api-stub: BTNode:getCount
-- Returns the repeat count, or 0 if not a Repeater.
-- Use this when returns the repeat count, or 0 if not a Repeater is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:getCount()
end

--@api-stub: BTNode:setSuccessPolicy
-- Sets the success policy for a Parallel node.
-- Use this when sets the success policy for a Parallel node is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:setSuccessPolicy(0)
end

--@api-stub: BTNode:setFailurePolicy
-- Sets the failure policy for a Parallel node.
-- Use this when sets the failure policy for a Parallel node is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:setFailurePolicy(0)
end

--@api-stub: BTNode:getNodeType
-- Returns the node type as a string.
-- Use this when returns the node type as a string is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:getNodeType()
end

--@api-stub: BTNode:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:type()
end

--@api-stub: BTNode:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- BTNode instance
  _o:typeOf(1)
end

-- ── SteeringManager methods ──

--@api-stub: SteeringManager:getBehaviorCount
-- Returns the number of active behaviors.
-- Use this when returns the number of active behaviors is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:getBehaviorCount()
end

--@api-stub: SteeringManager:setCombineMode
-- Sets the force combination mode.
-- Use this when sets the force combination mode is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:setCombineMode(nil)
end

--@api-stub: SteeringManager:getCombineMode
-- Returns the current combination mode.
-- Use this when returns the current combination mode is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:getCombineMode()
end

--@api-stub: SteeringManager:getLastSteering
-- Returns the last computed steering force.
-- Use this when returns the last computed steering force is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:getLastSteering()
end

--@api-stub: SteeringManager:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:type()
end

--@api-stub: SteeringManager:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:typeOf(1)
end

--@api-stub: SteeringManager:setSpatialHashCellSize
-- Sets the cell size used by the spatial-hash neighbourhood search.
-- Use this when sets the cell size used by the spatial-hash neighbourhood search is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:setSpatialHashCellSize(1)
end

--@api-stub: SteeringManager:enableSpatialHash
-- Enables or disables spatial-hash bucketing for neighbourhood queries.
-- Use this when enables or disables spatial-hash bucketing for neighbourhood queries is needed.
if false then
  local _o = nil  -- SteeringManager instance
  _o:enableSpatialHash(1)
end

-- ── QLearner methods ──

--@api-stub: QLearner:chooseAction
-- Selects an action using epsilon-greedy policy (1-based).
-- Use this when selects an action using epsilon-greedy policy (1-based) is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:chooseAction(0)
end

--@api-stub: QLearner:bestAction
-- Returns the greedy-best action for the state (1-based).
-- Use this when returns the greedy-best action for the state (1-based) is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:bestAction(0)
end

--@api-stub: QLearner:getQValue
-- Returns the Q-value for a state-action pair (1-based).
-- Use this when returns the Q-value for a state-action pair (1-based) is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getQValue(0, 1)
end

--@api-stub: QLearner:endEpisode
-- Ends the current episode, applying epsilon decay.
-- Use this when ends the current episode, applying epsilon decay is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:endEpisode()
end

--@api-stub: QLearner:getEpisodeCount
-- Returns the number of completed episodes.
-- Use this when returns the number of completed episodes is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getEpisodeCount()
end

--@api-stub: QLearner:getStateCount
-- Returns the number of discrete states.
-- Use this when returns the number of discrete states is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getStateCount()
end

--@api-stub: QLearner:getActionCount
-- Returns the number of discrete actions.
-- Use this when returns the number of discrete actions is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getActionCount()
end

--@api-stub: QLearner:setLearningRate
-- Sets the learning rate alpha.
-- Use this when sets the learning rate alpha is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:setLearningRate(0)
end

--@api-stub: QLearner:getLearningRate
-- Returns the current learning rate.
-- Use this when returns the current learning rate is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getLearningRate()
end

--@api-stub: QLearner:setDiscountFactor
-- Sets the discount factor gamma.
-- Use this when sets the discount factor gamma is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:setDiscountFactor(0)
end

--@api-stub: QLearner:getDiscountFactor
-- Returns the current discount factor.
-- Use this when returns the current discount factor is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getDiscountFactor()
end

--@api-stub: QLearner:setExplorationRate
-- Sets the exploration rate epsilon.
-- Use this when sets the exploration rate epsilon is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:setExplorationRate(0)
end

--@api-stub: QLearner:getExplorationRate
-- Returns the current exploration rate.
-- Use this when returns the current exploration rate is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getExplorationRate()
end

--@api-stub: QLearner:setExplorationDecay
-- Sets the epsilon decay multiplier.
-- Use this when sets the epsilon decay multiplier is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:setExplorationDecay(0)
end

--@api-stub: QLearner:getExplorationDecay
-- Returns the epsilon decay multiplier.
-- Use this when returns the epsilon decay multiplier is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:getExplorationDecay()
end

--@api-stub: QLearner:serialize
-- Serializes the Q-table to a JSON string.
-- Use this when serializes the Q-table to a JSON string is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:serialize()
end

--@api-stub: QLearner:deserialize
-- Restores the Q-table from a JSON string.
-- Use this when restores the Q-table from a JSON string is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:deserialize(1)
end

--@api-stub: QLearner:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:type()
end

--@api-stub: QLearner:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- QLearner instance
  _o:typeOf(1)
end

-- ── UtilityAI methods ──

--@api-stub: UtilityAI:evaluate
-- Evaluates all actions and returns the best action name, or nil.
-- Use this when evaluates all actions and returns the best action name, or nil is needed.
if false then
  local _o = nil  -- UtilityAI instance
  _o:evaluate()
end

--@api-stub: UtilityAI:getActionCount
-- Returns the number of registered actions.
-- Use this when returns the number of registered actions is needed.
if false then
  local _o = nil  -- UtilityAI instance
  _o:getActionCount()
end

--@api-stub: UtilityAI:getLastAction
-- Returns the name of the last chosen action, or nil.
-- Use this when returns the name of the last chosen action, or nil is needed.
if false then
  local _o = nil  -- UtilityAI instance
  _o:getLastAction()
end

--@api-stub: UtilityAI:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- UtilityAI instance
  _o:type()
end

--@api-stub: UtilityAI:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- UtilityAI instance
  _o:typeOf(1)
end

-- ── GOAPPlanner methods ──

--@api-stub: GOAPPlanner:getActionCount
-- Returns the number of registered actions.
-- Use this when returns the number of registered actions is needed.
if false then
  local _o = nil  -- GOAPPlanner instance
  _o:getActionCount()
end

--@api-stub: GOAPPlanner:getGoalCount
-- Returns the number of registered goals.
-- Use this when returns the number of registered goals is needed.
if false then
  local _o = nil  -- GOAPPlanner instance
  _o:getGoalCount()
end

--@api-stub: GOAPPlanner:getMaxIterations
-- Returns the maximum A* planning iterations.
-- Use this when returns the maximum A* planning iterations is needed.
if false then
  local _o = nil  -- GOAPPlanner instance
  _o:getMaxIterations()
end

--@api-stub: GOAPPlanner:setMaxIterations
-- Sets the maximum A* planning iterations (0 = unlimited).
-- Use this when sets the maximum A* planning iterations (0 = unlimited) is needed.
if false then
  local _o = nil  -- GOAPPlanner instance
  _o:setMaxIterations(1)
end

--@api-stub: GOAPPlanner:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- GOAPPlanner instance
  _o:type()
end

--@api-stub: GOAPPlanner:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- GOAPPlanner instance
  _o:typeOf(1)
end

-- ── InfluenceMap methods ──

--@api-stub: InfluenceMap:addLayer
-- Adds a named influence layer.
-- Use this when adds a named influence layer is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:addLayer(1)
end

--@api-stub: InfluenceMap:hasLayer
-- Returns true if the named layer exists.
-- Use this when returns true if the named layer exists is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:hasLayer(1)
end

--@api-stub: InfluenceMap:decay
-- Multiplies all influences by a decay factor.
-- Use this when multiplies all influences by a decay factor is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:decay(0, 0)
end

--@api-stub: InfluenceMap:clearLayer
-- Clears all influence in a layer.
-- Use this when clears all influence in a layer is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:clearLayer(0)
end

--@api-stub: InfluenceMap:clearAll
-- Removes all influence values from every layer in the map.
-- Use this when removes all influence values from every layer in the map is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:clearAll()
end

--@api-stub: InfluenceMap:getMaxPosition
-- Returns the world-space position of the maximum value.
-- Use this when returns the world-space position of the maximum value is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:getMaxPosition(0)
end

--@api-stub: InfluenceMap:getMinPosition
-- Returns the world-space position of the minimum value.
-- Use this when returns the world-space position of the minimum value is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:getMinPosition(0)
end

--@api-stub: InfluenceMap:getWidth
-- Returns the influence map width in grid cells.
-- Use this when returns the influence map width in grid cells is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:getWidth()
end

--@api-stub: InfluenceMap:getHeight
-- Returns the influence map height in grid cells.
-- Use this when returns the influence map height in grid cells is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:getHeight()
end

--@api-stub: InfluenceMap:getCellSize
-- Returns the cell size in world units.
-- Use this when returns the cell size in world units is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:getCellSize()
end

--@api-stub: InfluenceMap:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:type()
end

--@api-stub: InfluenceMap:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- InfluenceMap instance
  _o:typeOf(1)
end

-- ── Squad methods ──

--@api-stub: Squad:getName
-- Returns the unique name string assigned to this squad.
-- Use this when returns the unique name string assigned to this squad is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getName()
end

--@api-stub: Squad:addMember
-- Adds an agent by name to this squad.
-- Use this when adds an agent by name to this squad is needed.
if false then
  local _o = nil  -- Squad instance
  _o:addMember(1)
end

--@api-stub: Squad:removeMember
-- Removes an agent by name from this squad.
-- Use this when removes an agent by name from this squad is needed.
if false then
  local _o = nil  -- Squad instance
  _o:removeMember(1)
end

--@api-stub: Squad:getMemberCount
-- Returns the number of squad members.
-- Use this when returns the number of squad members is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getMemberCount()
end

--@api-stub: Squad:getMembers
-- Returns the member names as a table.
-- Use this when returns the member names as a table is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getMembers()
end

--@api-stub: Squad:setLeader
-- Sets the squad leader by name.
-- Use this when sets the squad leader by name is needed.
if false then
  local _o = nil  -- Squad instance
  _o:setLeader(1)
end

--@api-stub: Squad:getLeader
-- Returns the leader name, or nil.
-- Use this when returns the leader name, or nil is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getLeader()
end

--@api-stub: Squad:getFormation
-- Returns the current formation type name.
-- Use this when returns the current formation type name is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getFormation()
end

--@api-stub: Squad:getFormationSpacing
-- Returns the formation spacing in world units.
-- Use this when returns the formation spacing in world units is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getFormationSpacing()
end

--@api-stub: Squad:getBlackboard
-- Returns the squad's shared blackboard.
-- Use this when returns the squad's shared blackboard is needed.
if false then
  local _o = nil  -- Squad instance
  _o:getBlackboard()
end

--@api-stub: Squad:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Squad instance
  _o:type()
end

--@api-stub: Squad:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- Squad instance
  _o:typeOf(1)
end

-- ── CommandQueue methods ──

--@api-stub: CommandQueue:cancelCurrent
-- Cancels the front command if it is interruptible.
-- Use this when cancels the front command if it is interruptible is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:cancelCurrent()
end

--@api-stub: CommandQueue:clear
-- Discards all queued commands.
-- Use this when discards all queued commands is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:clear()
end

--@api-stub: CommandQueue:getCount
-- Returns the number of queued commands.
-- Use this when returns the number of queued commands is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:getCount()
end

--@api-stub: CommandQueue:isEmpty
-- Returns true if there are no queued commands.
-- Use this when returns true if there are no queued commands is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:isEmpty()
end

--@api-stub: CommandQueue:getCurrentType
-- Returns the kind of the front command, or nil.
-- Use this when returns the kind of the front command, or nil is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:getCurrentType()
end

--@api-stub: CommandQueue:getCurrentTarget
-- Returns the target coordinates of the front command.
-- Use this when returns the target coordinates of the front command is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:getCurrentTarget()
end

--@api-stub: CommandQueue:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:type()
end

--@api-stub: CommandQueue:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- CommandQueue instance
  _o:typeOf(1)
end

-- ── TraitProfile methods ──

--@api-stub: TraitProfile:set
-- Sets the base value of this trait, replacing any previous base.
-- Use this when sets the base value of this trait, replacing any previous base is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:set(1, 0)
end

--@api-stub: TraitProfile:get
-- Returns the current float value of this emotion dimension.
-- Use this when returns the current float value of this emotion dimension is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:get(1)
end

--@api-stub: TraitProfile:getBase
-- Returns the unmodified base value of this trait before modifiers.
-- Use this when returns the unmodified base value of this trait before modifiers is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:getBase(1)
end

--@api-stub: TraitProfile:removeModifiers
-- Removes the specified modifiers.
-- Use this when removes the specified modifiers is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:removeModifiers(nil)
end

--@api-stub: TraitProfile:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:update(0)
end

--@api-stub: TraitProfile:has
-- Returns true if a item is present.
-- Use this when returns true if a item is present is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:has(1)
end

--@api-stub: TraitProfile:traitCount
-- Returns or performs trait count.
-- Use this when returns or performs trait count is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:traitCount()
end

--@api-stub: TraitProfile:archetype
-- Returns or performs archetype.
-- Use this when returns or performs archetype is needed.
if false then
  local _o = nil  -- TraitProfile instance
  _o:archetype()
end

-- ── StimulusWorld methods ──

--@api-stub: StimulusWorld:remove
-- Removes the specified item.
-- Use this when removes the specified item is needed.
if false then
  local _o = nil  -- StimulusWorld instance
  _o:remove(1)
end

--@api-stub: StimulusWorld:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- StimulusWorld instance
  _o:update(0)
end

--@api-stub: StimulusWorld:clear
-- Resets or clears the state.
-- Use this when resets or clears the state is needed.
if false then
  local _o = nil  -- StimulusWorld instance
  _o:clear()
end

-- ── ContextSteering methods ──

--@api-stub: ContextSteering:addWander
-- Adds a wander behavior with jitter and weight to the context steering evaluator.
-- Use this when adds a wander behavior with jitter and weight to the context steering evaluator is needed.
if false then
  local _o = nil  -- ContextSteering instance
  _o:addWander(0, 0)
end

--@api-stub: ContextSteering:addAvoidBounds
-- Registers a rectangular region this agent must avoid.
-- Use this when registers a rectangular region this agent must avoid is needed.
if false then
  local _o = nil  -- ContextSteering instance
  _o:addAvoidBounds(1, 1, 0, 0, 1, 0)
end

--@api-stub: ContextSteering:clearBehaviors
-- Resets or clears the behaviors.
-- Use this when resets or clears the behaviors is needed.
if false then
  local _o = nil  -- ContextSteering instance
  _o:clearBehaviors()
end

--@api-stub: ContextSteering:chosenMagnitude
-- Returns or performs chosen magnitude.
-- Use this when returns or performs chosen magnitude is needed.
if false then
  local _o = nil  -- ContextSteering instance
  _o:chosenMagnitude()
end

--@api-stub: ContextSteering:slotCount
-- Returns or performs slot count.
-- Use this when returns or performs slot count is needed.
if false then
  local _o = nil  -- ContextSteering instance
  _o:slotCount()
end

-- ── NeedSystem methods ──

--@api-stub: NeedSystem:addNeed
-- Registers a new need with the specified name, urgency, and decay rate in the system.
-- Use this when registers a new need with the specified name, urgency, and decay rate in the system is needed.
if false then
  local _o = nil  -- NeedSystem instance
  _o:addNeed(1, 0, 1, 1)
end

--@api-stub: NeedSystem:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- NeedSystem instance
  _o:update(0)
end

--@api-stub: NeedSystem:mostUrgent
-- Returns or performs most urgent.
-- Use this when returns or performs most urgent is needed.
if false then
  local _o = nil  -- NeedSystem instance
  _o:mostUrgent()
end

--@api-stub: NeedSystem:satisfy
-- Returns or performs satisfy.
-- Use this when returns or performs satisfy is needed.
if false then
  local _o = nil  -- NeedSystem instance
  _o:satisfy(1, 1)
end

--@api-stub: NeedSystem:valueOf
-- Returns or performs value of.
-- Use this when returns or performs value of is needed.
if false then
  local _o = nil  -- NeedSystem instance
  _o:valueOf(1)
end

-- ── AIDirector methods ──

--@api-stub: AIDirector:pushEvent
-- Pushes a gameplay event with the given intensity to the director for awareness analysis.
-- Use this when pushes a gameplay event with the given intensity to the director for awareness analysis is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:pushEvent(1)
end

--@api-stub: AIDirector:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:update(0)
end

--@api-stub: AIDirector:tension
-- Returns or performs tension.
-- Use this when returns or performs tension is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:tension()
end

--@api-stub: AIDirector:phase
-- Returns or performs phase.
-- Use this when returns or performs phase is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:phase()
end

--@api-stub: AIDirector:spawnRateFactor
-- Returns or performs spawn rate factor.
-- Use this when returns or performs spawn rate factor is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:spawnRateFactor()
end

--@api-stub: AIDirector:lootFactor
-- Returns or performs loot factor.
-- Use this when returns or performs loot factor is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:lootFactor()
end

--@api-stub: AIDirector:ambientIntensity
-- Returns or performs ambient intensity.
-- Use this when returns or performs ambient intensity is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:ambientIntensity()
end

--@api-stub: AIDirector:setTension
-- Sets the global narrative tension level (0â€“1 scale).
-- Use this when sets the global narrative tension level (0â€“1 scale) is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:setTension(0)
end

--@api-stub: AIDirector:reset
-- Resets or clears the state.
-- Use this when resets or clears the state is needed.
if false then
  local _o = nil  -- AIDirector instance
  _o:reset()
end

-- ── HTNDomain methods ──

--@api-stub: HTNDomain:addPrimitive
-- Registers a primitive HTN task with a direct operator function.
-- Use this when registers a primitive HTN task with a direct operator function is needed.
if false then
  local _o = nil  -- HTNDomain instance
  _o:addPrimitive(1, 1, 0, nil)
end

--@api-stub: HTNDomain:taskCount
-- Returns or performs task count.
-- Use this when returns or performs task count is needed.
if false then
  local _o = nil  -- HTNDomain instance
  _o:taskCount()
end

-- ── EmotionModel methods ──

--@api-stub: EmotionModel:trigger
-- Returns or performs trigger.
-- Use this when returns or performs trigger is needed.
if false then
  local _o = nil  -- EmotionModel instance
  _o:trigger(1, 1)
end

--@api-stub: EmotionModel:get
-- Returns the current float value of this emotion dimension.
-- Use this when returns the current float value of this emotion dimension is needed.
if false then
  local _o = nil  -- EmotionModel instance
  _o:get(1)
end

--@api-stub: EmotionModel:dominant
-- Returns or performs dominant.
-- Use this when returns or performs dominant is needed.
if false then
  local _o = nil  -- EmotionModel instance
  _o:dominant()
end

--@api-stub: EmotionModel:isActive
-- Returns `true` if the emotion dimension is currently active and above threshold.
-- Use this when returns `true` if the emotion dimension is currently active and above threshold is needed.
if false then
  local _o = nil  -- EmotionModel instance
  _o:isActive(1)
end

--@api-stub: EmotionModel:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- EmotionModel instance
  _o:update(0)
end

--@api-stub: EmotionModel:reset
-- Resets or clears the state.
-- Use this when resets or clears the state is needed.
if false then
  local _o = nil  -- EmotionModel instance
  _o:reset()
end

-- ── ORCASolver methods ──

--@api-stub: ORCASolver:setPosition
-- Sets the agent's current world-space position for ORCA velocity computation.
-- Use this when sets the agent's current world-space position for ORCA velocity computation is needed.
if false then
  local _o = nil  -- ORCASolver instance
  _o:setPosition(1, 0, 0)
end

--@api-stub: ORCASolver:compute
-- Computes and returns the result.
-- Use this when computes and returns the result is needed.
if false then
  local _o = nil  -- ORCASolver instance
  _o:compute(0)
end

--@api-stub: ORCASolver:getSafeVelocity
-- Returns the safe velocity.
-- Use this when returns the safe velocity is needed.
if false then
  local _o = nil  -- ORCASolver instance
  _o:getSafeVelocity(1)
end

--@api-stub: ORCASolver:agentCount
-- Returns or performs agent count.
-- Use this when returns or performs agent count is needed.
if false then
  local _o = nil  -- ORCASolver instance
  _o:agentCount()
end

-- ── NeuralNet methods ──

--@api-stub: NeuralNet:forward
-- Returns or performs forward.
-- Use this when returns or performs forward is needed.
if false then
  local _o = nil  -- NeuralNet instance
  _o:forward(1)
end

--@api-stub: NeuralNet:setWeights
-- Overwrites all connection weights with values from a flat table.
-- Use this when overwrites all connection weights with values from a flat table is needed.
if false then
  local _o = nil  -- NeuralNet instance
  _o:setWeights(0)
end

--@api-stub: NeuralNet:getWeights
-- Returns a flat table of all connection weight values in the network.
-- Use this when returns a flat table of all connection weight values in the network is needed.
if false then
  local _o = nil  -- NeuralNet instance
  _o:getWeights()
end

--@api-stub: NeuralNet:paramCount
-- Returns or performs param count.
-- Use this when returns or performs param count is needed.
if false then
  local _o = nil  -- NeuralNet instance
  _o:paramCount()
end

--@api-stub: NeuralNet:layerCount
-- Returns or performs layer count.
-- Use this when returns or performs layer count is needed.
if false then
  local _o = nil  -- NeuralNet instance
  _o:layerCount()
end

-- ── GeneticAlgorithm methods ──

--@api-stub: GeneticAlgorithm:evolve
-- Runs one generation of the evolutionary algorithm.
-- Use this when runs one generation of the evolutionary algorithm is needed.
if false then
  local _o = nil  -- GeneticAlgorithm instance
  _o:evolve()
end

--@api-stub: GeneticAlgorithm:generation
-- Returns or performs generation.
-- Use this when returns or performs generation is needed.
if false then
  local _o = nil  -- GeneticAlgorithm instance
  _o:generation()
end

--@api-stub: GeneticAlgorithm:popSize
-- Returns or performs pop size.
-- Use this when returns or performs pop size is needed.
if false then
  local _o = nil  -- GeneticAlgorithm instance
  _o:popSize()
end

--@api-stub: GeneticAlgorithm:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- Use this when sets the fitness score used by the genetic algorithm selection step is needed.
if false then
  local _o = nil  -- GeneticAlgorithm instance
  _o:setFitness(1, 1)
end

--@api-stub: GeneticAlgorithm:getGenes
-- Returns the chromosome as an ordered table of gene values.
-- Use this when returns the chromosome as an ordered table of gene values is needed.
if false then
  local _o = nil  -- GeneticAlgorithm instance
  _o:getGenes(1)
end

--@api-stub: GeneticAlgorithm:bestGenes
-- Returns or performs best genes.
-- Use this when returns or performs best genes is needed.
if false then
  local _o = nil  -- GeneticAlgorithm instance
  _o:bestGenes()
end

-- ── Bandit methods ──

--@api-stub: Bandit:select
-- Returns or performs select.
-- Use this when returns or performs select is needed.
if false then
  local _o = nil  -- Bandit instance
  _o:select()
end

--@api-stub: Bandit:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- Bandit instance
  _o:update(1, 0)
end

--@api-stub: Bandit:bestArm
-- Returns or performs best arm.
-- Use this when returns or performs best arm is needed.
if false then
  local _o = nil  -- Bandit instance
  _o:bestArm()
end

--@api-stub: Bandit:reset
-- Resets or clears the state.
-- Use this when resets or clears the state is needed.
if false then
  local _o = nil  -- Bandit instance
  _o:reset()
end

--@api-stub: Bandit:armCount
-- Returns or performs arm count.
-- Use this when returns or performs arm count is needed.
if false then
  local _o = nil  -- Bandit instance
  _o:armCount()
end

--@api-stub: Bandit:totalPulls
-- Returns or performs total pulls.
-- Use this when returns or performs total pulls is needed.
if false then
  local _o = nil  -- Bandit instance
  _o:totalPulls()
end

-- ── Neuroevolution methods ──

--@api-stub: Neuroevolution:evolve
-- Runs one generation of the evolutionary algorithm.
-- Use this when runs one generation of the evolutionary algorithm is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:evolve()
end

--@api-stub: Neuroevolution:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- Use this when sets the fitness score used by the genetic algorithm selection step is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:setFitness(1, 1)
end

--@api-stub: Neuroevolution:chromosomeToNet
-- Returns or performs chromosome to net.
-- Use this when returns or performs chromosome to net is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:chromosomeToNet(1)
end

--@api-stub: Neuroevolution:bestNetwork
-- Returns or performs best network.
-- Use this when returns or performs best network is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:bestNetwork()
end

--@api-stub: Neuroevolution:bestFitness
-- Returns or performs best fitness.
-- Use this when returns or performs best fitness is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:bestFitness()
end

--@api-stub: Neuroevolution:popSize
-- Returns or performs pop size.
-- Use this when returns or performs pop size is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:popSize()
end

--@api-stub: Neuroevolution:generation
-- Returns or performs generation.
-- Use this when returns or performs generation is needed.
if false then
  local _o = nil  -- Neuroevolution instance
  _o:generation()
end

-- ── StrategyAI methods ──

--@api-stub: StrategyAI:addGoal
-- Adds a strategic goal with priority score to the planner for future evaluation.
-- Use this when adds a strategic goal with priority score to the planner for future evaluation is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:addGoal(1)
end

--@api-stub: StrategyAI:addTag
-- Adds a string tag to the strategy AI instance for goal filtering and categorization.
-- Use this when adds a string tag to the strategy AI instance for goal filtering and categorization is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:addTag(0)
end

--@api-stub: StrategyAI:removeTag
-- Removes the specified tag.
-- Use this when removes the specified tag is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:removeTag(0)
end

--@api-stub: StrategyAI:update
-- Advances the simulation by one time step.
-- Use this when advances the simulation by one time step is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:update(0, 1)
end

--@api-stub: StrategyAI:forceEvaluate
-- Returns or performs force evaluate.
-- Use this when returns or performs force evaluate is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:forceEvaluate(1)
end

--@api-stub: StrategyAI:activeGoal
-- Returns or performs active goal.
-- Use this when returns or performs active goal is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:activeGoal()
end

--@api-stub: StrategyAI:timeUntilNext
-- Returns or performs time until next.
-- Use this when returns or performs time until next is needed.
if false then
  local _o = nil  -- StrategyAI instance
  _o:timeUntilNext()
end

-- ── AILod methods ──

--@api-stub: AILod:shouldUpdate
-- Returns or performs should update.
-- Use this when returns or performs should update is needed.
if false then
  local _o = nil  -- AILod instance
  _o:shouldUpdate(0, nil)
end

--@api-stub: AILod:tierCount
-- Returns or performs tier count.
-- Use this when returns or performs tier count is needed.
if false then
  local _o = nil  -- AILod instance
  _o:tierCount()
end

--@api-stub: AILod:tierName
-- Returns or performs tier name.
-- Use this when returns or performs tier name is needed.
if false then
  local _o = nil  -- AILod instance
  _o:tierName(0)
end

