-- content/examples/ai.lua
-- Scaffolded coverage of the lurek.ai API (240 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/ai_api.rs   (Lua binding, arg types, return shape)
--   * src/ai/                 (semantics, side effects)
--   * docs/specs/ai.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/ai.lua

-- ── lurek.ai.* functions ──

--@api-stub: lurek.ai.newWorld
-- Creates a new AI world container.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newWorld
  local _todo = "TODO: write a real lurek.ai.newWorld usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newBlackboard
-- Creates a new standalone blackboard.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newBlackboard
  local _todo = "TODO: write a real lurek.ai.newBlackboard usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newStateMachine
-- Creates a new finite state machine.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newStateMachine
  local _todo = "TODO: write a real lurek.ai.newStateMachine usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newBehaviorTree
-- Creates a new behavior tree.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newBehaviorTree
  local _todo = "TODO: write a real lurek.ai.newBehaviorTree usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newSelector
-- Creates a BT selector node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newSelector
  local _todo = "TODO: write a real lurek.ai.newSelector usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newSequence
-- Creates a BT sequence node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newSequence
  local _todo = "TODO: write a real lurek.ai.newSequence usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newParallel
-- Creates a BT parallel node with optional policies.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newParallel
  local _todo = "TODO: write a real lurek.ai.newParallel usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newInverter
-- Creates a BT inverter decorator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newInverter
  local _todo = "TODO: write a real lurek.ai.newInverter usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newRepeater
-- Creates a BT repeater decorator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newRepeater
  local _todo = "TODO: write a real lurek.ai.newRepeater usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newSucceeder
-- Creates a BT succeeder decorator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newSucceeder
  local _todo = "TODO: write a real lurek.ai.newSucceeder usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newAction
-- Creates a BT action leaf with a Lua callback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newAction
  local _todo = "TODO: write a real lurek.ai.newAction usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newCondition
-- Creates a BT condition leaf with a Lua predicate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newCondition
  local _todo = "TODO: write a real lurek.ai.newCondition usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newSteeringManager
-- Creates a new steering behavior manager.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newSteeringManager
  local _todo = "TODO: write a real lurek.ai.newSteeringManager usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newQLearner
-- Creates a tabular Q-learner.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newQLearner
  local _todo = "TODO: write a real lurek.ai.newQLearner usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newUtilityAI
-- Creates a new utility AI evaluator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newUtilityAI
  local _todo = "TODO: write a real lurek.ai.newUtilityAI usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newGOAPPlanner
-- Creates a new GOAP planning solver.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newGOAPPlanner
  local _todo = "TODO: write a real lurek.ai.newGOAPPlanner usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newInfluenceMap
-- Creates a multi-layer influence map grid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newInfluenceMap
  local _todo = "TODO: write a real lurek.ai.newInfluenceMap usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newSquad
-- Creates a named squad for formation positioning.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newSquad
  local _todo = "TODO: write a real lurek.ai.newSquad usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newCommandQueue
-- Creates an RTS-style command queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newCommandQueue
  local _todo = "TODO: write a real lurek.ai.newCommandQueue usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newTraitProfile
-- Creates a new personality trait profile.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newTraitProfile
  local _todo = "TODO: write a real lurek.ai.newTraitProfile usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newStimulusWorld
-- Creates a new stimulus perception world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newStimulusWorld
  local _todo = "TODO: write a real lurek.ai.newStimulusWorld usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newContextSteering
-- Creates a new context steering controller.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newContextSteering
  local _todo = "TODO: write a real lurek.ai.newContextSteering usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newNeedSystem
-- Creates a new motivational need system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newNeedSystem
  local _todo = "TODO: write a real lurek.ai.newNeedSystem usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newAIDirector
-- Creates a new AI pacing director with default config.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newAIDirector
  local _todo = "TODO: write a real lurek.ai.newAIDirector usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newHTNDomain
-- Creates a new Hierarchical Task Network domain.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newHTNDomain
  local _todo = "TODO: write a real lurek.ai.newHTNDomain usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newMCTSEngine
-- Creates a new Monte Carlo Tree Search engine.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newMCTSEngine
  local _todo = "TODO: write a real lurek.ai.newMCTSEngine usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newEmotionModel
-- Creates a new affective emotion model.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newEmotionModel
  local _todo = "TODO: write a real lurek.ai.newEmotionModel usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newORCASolver
-- Creates a new ORCA crowd avoidance solver.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newORCASolver
  local _todo = "TODO: write a real lurek.ai.newORCASolver usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newNeuralNet
-- Creates a new feedforward neural network (inference only).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newNeuralNet
  local _todo = "TODO: write a real lurek.ai.newNeuralNet usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newGeneticAlgorithm
-- Creates a new genetic algorithm.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newGeneticAlgorithm
  local _todo = "TODO: write a real lurek.ai.newGeneticAlgorithm usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newBandit
-- Creates a new multi-armed bandit.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newBandit
  local _todo = "TODO: write a real lurek.ai.newBandit usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newNeuroevolution
-- Creates a neuroevolution trainer (GA for neural network weights).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newNeuroevolution
  local _todo = "TODO: write a real lurek.ai.newNeuroevolution usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newStrategyAI
-- Creates a new throttled strategy AI.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newStrategyAI
  local _todo = "TODO: write a real lurek.ai.newStrategyAI usage example"
  print(_todo)
end

--@api-stub: lurek.ai.newAILod
-- Creates a new AI LOD controller with default 3-tier config.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: lurek.ai.newAILod
  local _todo = "TODO: write a real lurek.ai.newAILod usage example"
  print(_todo)
end

-- ── AIWorld methods ──

--@api-stub: AIWorld:addAgent
-- Registers a new named agent and returns its handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:addAgent
  local _todo = "TODO: write a real AIWorld:addAgent usage example"
  print(_todo)
end

--@api-stub: AIWorld:getAgent
-- Returns the agent handle for the given name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:getAgent
  local _todo = "TODO: write a real AIWorld:getAgent usage example"
  print(_todo)
end

--@api-stub: AIWorld:removeAgent
-- Removes an agent by its userdata handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:removeAgent
  local _todo = "TODO: write a real AIWorld:removeAgent usage example"
  print(_todo)
end

--@api-stub: AIWorld:getAgentCount
-- Returns the number of registered agents.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:getAgentCount
  local _todo = "TODO: write a real AIWorld:getAgentCount usage example"
  print(_todo)
end

--@api-stub: AIWorld:getGlobalBlackboard
-- Returns a snapshot of the world-level blackboard.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:getGlobalBlackboard
  local _todo = "TODO: write a real AIWorld:getGlobalBlackboard usage example"
  print(_todo)
end

--@api-stub: AIWorld:update
-- Advances all agents by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:update
  local _todo = "TODO: write a real AIWorld:update usage example"
  print(_todo)
end

--@api-stub: AIWorld:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:type
  local _todo = "TODO: write a real AIWorld:type usage example"
  print(_todo)
end

--@api-stub: AIWorld:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIWorld:typeOf
  local _todo = "TODO: write a real AIWorld:typeOf usage example"
  print(_todo)
end

-- ── Agent methods ──

--@api-stub: Agent:getName
-- Returns the agent's registered name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getName
  local _todo = "TODO: write a real Agent:getName usage example"
  print(_todo)
end

--@api-stub: Agent:setPosition
-- Sets the agent's world-space position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:setPosition
  local _todo = "TODO: write a real Agent:setPosition usage example"
  print(_todo)
end

--@api-stub: Agent:getPosition
-- Returns the agent's current position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getPosition
  local _todo = "TODO: write a real Agent:getPosition usage example"
  print(_todo)
end

--@api-stub: Agent:setVelocity
-- Sets the agent's velocity vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:setVelocity
  local _todo = "TODO: write a real Agent:setVelocity usage example"
  print(_todo)
end

--@api-stub: Agent:getVelocity
-- Returns the agent's current velocity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getVelocity
  local _todo = "TODO: write a real Agent:getVelocity usage example"
  print(_todo)
end

--@api-stub: Agent:setMaxSpeed
-- Sets the maximum speed cap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:setMaxSpeed
  local _todo = "TODO: write a real Agent:setMaxSpeed usage example"
  print(_todo)
end

--@api-stub: Agent:getMaxSpeed
-- Returns the maximum speed cap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getMaxSpeed
  local _todo = "TODO: write a real Agent:getMaxSpeed usage example"
  print(_todo)
end

--@api-stub: Agent:setMaxForce
-- Sets the maximum steering force cap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:setMaxForce
  local _todo = "TODO: write a real Agent:setMaxForce usage example"
  print(_todo)
end

--@api-stub: Agent:getMaxForce
-- Returns the maximum steering force cap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getMaxForce
  local _todo = "TODO: write a real Agent:getMaxForce usage example"
  print(_todo)
end

--@api-stub: Agent:setPriority
-- Sets the scheduling priority (higher = earlier).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:setPriority
  local _todo = "TODO: write a real Agent:setPriority usage example"
  print(_todo)
end

--@api-stub: Agent:getPriority
-- Returns the agent's scheduling priority.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getPriority
  local _todo = "TODO: write a real Agent:getPriority usage example"
  print(_todo)
end

--@api-stub: Agent:setDecisionModel
-- Sets the active decision model.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:setDecisionModel
  local _todo = "TODO: write a real Agent:setDecisionModel usage example"
  print(_todo)
end

--@api-stub: Agent:getDecisionModel
-- Returns the name of the current decision model.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getDecisionModel
  local _todo = "TODO: write a real Agent:getDecisionModel usage example"
  print(_todo)
end

--@api-stub: Agent:addTag
-- Adds a tag to this agent.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:addTag
  local _todo = "TODO: write a real Agent:addTag usage example"
  print(_todo)
end

--@api-stub: Agent:removeTag
-- Removes a tag from this agent.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:removeTag
  local _todo = "TODO: write a real Agent:removeTag usage example"
  print(_todo)
end

--@api-stub: Agent:hasTag
-- Returns true if the agent has the given tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:hasTag
  local _todo = "TODO: write a real Agent:hasTag usage example"
  print(_todo)
end

--@api-stub: Agent:getBlackboard
-- Returns the agent's local blackboard.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:getBlackboard
  local _todo = "TODO: write a real Agent:getBlackboard usage example"
  print(_todo)
end

--@api-stub: Agent:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:type
  local _todo = "TODO: write a real Agent:type usage example"
  print(_todo)
end

--@api-stub: Agent:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Agent:typeOf
  local _todo = "TODO: write a real Agent:typeOf usage example"
  print(_todo)
end

-- ── Blackboard methods ──

--@api-stub: Blackboard:setNumber
-- Stores a number under the given key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:setNumber
  local _todo = "TODO: write a real Blackboard:setNumber usage example"
  print(_todo)
end

--@api-stub: Blackboard:setBool
-- Stores a boolean under the given key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:setBool
  local _todo = "TODO: write a real Blackboard:setBool usage example"
  print(_todo)
end

--@api-stub: Blackboard:setString
-- Stores a string under the given key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:setString
  local _todo = "TODO: write a real Blackboard:setString usage example"
  print(_todo)
end

--@api-stub: Blackboard:has
-- Returns true if a value exists under the key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:has
  local _todo = "TODO: write a real Blackboard:has usage example"
  print(_todo)
end

--@api-stub: Blackboard:remove
-- Removes the entry at key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:remove
  local _todo = "TODO: write a real Blackboard:remove usage example"
  print(_todo)
end

--@api-stub: Blackboard:clear
-- Removes all local entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:clear
  local _todo = "TODO: write a real Blackboard:clear usage example"
  print(_todo)
end

--@api-stub: Blackboard:getKeys
-- Returns all local keys as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:getKeys
  local _todo = "TODO: write a real Blackboard:getKeys usage example"
  print(_todo)
end

--@api-stub: Blackboard:getSize
-- Returns the number of local entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:getSize
  local _todo = "TODO: write a real Blackboard:getSize usage example"
  print(_todo)
end

--@api-stub: Blackboard:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:type
  local _todo = "TODO: write a real Blackboard:type usage example"
  print(_todo)
end

--@api-stub: Blackboard:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Blackboard:typeOf
  local _todo = "TODO: write a real Blackboard:typeOf usage example"
  print(_todo)
end

-- ── StateMachine methods ──

--@api-stub: StateMachine:addState
-- Registers a named state with optional lifecycle callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:addState
  local _todo = "TODO: write a real StateMachine:addState usage example"
  print(_todo)
end

--@api-stub: StateMachine:setInitialState
-- Sets the FSM's initial state; must be called before the first update.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:setInitialState
  local _todo = "TODO: write a real StateMachine:setInitialState usage example"
  print(_todo)
end

--@api-stub: StateMachine:getCurrentState
-- Returns the current state name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:getCurrentState
  local _todo = "TODO: write a real StateMachine:getCurrentState usage example"
  print(_todo)
end

--@api-stub: StateMachine:forceState
-- Forces a transition to the named state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:forceState
  local _todo = "TODO: write a real StateMachine:forceState usage example"
  print(_todo)
end

--@api-stub: StateMachine:getTimeInState
-- Returns seconds spent in the current state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:getTimeInState
  local _todo = "TODO: write a real StateMachine:getTimeInState usage example"
  print(_todo)
end

--@api-stub: StateMachine:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:type
  local _todo = "TODO: write a real StateMachine:type usage example"
  print(_todo)
end

--@api-stub: StateMachine:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StateMachine:typeOf
  local _todo = "TODO: write a real StateMachine:typeOf usage example"
  print(_todo)
end

-- ── BehaviorTree methods ──

--@api-stub: BehaviorTree:setRoot
-- Sets the root node of this behavior tree.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BehaviorTree:setRoot
  local _todo = "TODO: write a real BehaviorTree:setRoot usage example"
  print(_todo)
end

--@api-stub: BehaviorTree:getLastStatus
-- Returns the status from the last tick.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BehaviorTree:getLastStatus
  local _todo = "TODO: write a real BehaviorTree:getLastStatus usage example"
  print(_todo)
end

--@api-stub: BehaviorTree:getDebugState
-- Returns a diagnostic snapshot of this behavior tree.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BehaviorTree:getDebugState
  local _todo = "TODO: write a real BehaviorTree:getDebugState usage example"
  print(_todo)
end

--@api-stub: BehaviorTree:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BehaviorTree:type
  local _todo = "TODO: write a real BehaviorTree:type usage example"
  print(_todo)
end

--@api-stub: BehaviorTree:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BehaviorTree:typeOf
  local _todo = "TODO: write a real BehaviorTree:typeOf usage example"
  print(_todo)
end

-- ── BTNode methods ──

--@api-stub: BTNode:addChild
-- Adds a child node (Selector, Sequence, or Parallel only).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:addChild
  local _todo = "TODO: write a real BTNode:addChild usage example"
  print(_todo)
end

--@api-stub: BTNode:getChildCount
-- Returns the number of direct children.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:getChildCount
  local _todo = "TODO: write a real BTNode:getChildCount usage example"
  print(_todo)
end

--@api-stub: BTNode:reset
-- Resets all running-child memos and repeater counters.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:reset
  local _todo = "TODO: write a real BTNode:reset usage example"
  print(_todo)
end

--@api-stub: BTNode:setChild
-- Sets the single child of a decorator node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:setChild
  local _todo = "TODO: write a real BTNode:setChild usage example"
  print(_todo)
end

--@api-stub: BTNode:setCount
-- Sets the repeat count for a Repeater node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:setCount
  local _todo = "TODO: write a real BTNode:setCount usage example"
  print(_todo)
end

--@api-stub: BTNode:getCount
-- Returns the repeat count, or 0 if not a Repeater.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:getCount
  local _todo = "TODO: write a real BTNode:getCount usage example"
  print(_todo)
end

--@api-stub: BTNode:setSuccessPolicy
-- Sets the success policy for a Parallel node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:setSuccessPolicy
  local _todo = "TODO: write a real BTNode:setSuccessPolicy usage example"
  print(_todo)
end

--@api-stub: BTNode:setFailurePolicy
-- Sets the failure policy for a Parallel node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:setFailurePolicy
  local _todo = "TODO: write a real BTNode:setFailurePolicy usage example"
  print(_todo)
end

--@api-stub: BTNode:getNodeType
-- Returns the node type as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:getNodeType
  local _todo = "TODO: write a real BTNode:getNodeType usage example"
  print(_todo)
end

--@api-stub: BTNode:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:type
  local _todo = "TODO: write a real BTNode:type usage example"
  print(_todo)
end

--@api-stub: BTNode:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: BTNode:typeOf
  local _todo = "TODO: write a real BTNode:typeOf usage example"
  print(_todo)
end

-- ── SteeringManager methods ──

--@api-stub: SteeringManager:getBehaviorCount
-- Returns the number of active behaviors.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:getBehaviorCount
  local _todo = "TODO: write a real SteeringManager:getBehaviorCount usage example"
  print(_todo)
end

--@api-stub: SteeringManager:setCombineMode
-- Sets the force combination mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:setCombineMode
  local _todo = "TODO: write a real SteeringManager:setCombineMode usage example"
  print(_todo)
end

--@api-stub: SteeringManager:getCombineMode
-- Returns the current combination mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:getCombineMode
  local _todo = "TODO: write a real SteeringManager:getCombineMode usage example"
  print(_todo)
end

--@api-stub: SteeringManager:getLastSteering
-- Returns the last computed steering force.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:getLastSteering
  local _todo = "TODO: write a real SteeringManager:getLastSteering usage example"
  print(_todo)
end

--@api-stub: SteeringManager:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:type
  local _todo = "TODO: write a real SteeringManager:type usage example"
  print(_todo)
end

--@api-stub: SteeringManager:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:typeOf
  local _todo = "TODO: write a real SteeringManager:typeOf usage example"
  print(_todo)
end

--@api-stub: SteeringManager:setSpatialHashCellSize
-- Sets the cell size used by the spatial-hash neighbourhood search.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:setSpatialHashCellSize
  local _todo = "TODO: write a real SteeringManager:setSpatialHashCellSize usage example"
  print(_todo)
end

--@api-stub: SteeringManager:enableSpatialHash
-- Enables or disables spatial-hash bucketing for neighbourhood queries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: SteeringManager:enableSpatialHash
  local _todo = "TODO: write a real SteeringManager:enableSpatialHash usage example"
  print(_todo)
end

-- ── QLearner methods ──

--@api-stub: QLearner:chooseAction
-- Selects an action using epsilon-greedy policy (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:chooseAction
  local _todo = "TODO: write a real QLearner:chooseAction usage example"
  print(_todo)
end

--@api-stub: QLearner:bestAction
-- Returns the greedy-best action for the state (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:bestAction
  local _todo = "TODO: write a real QLearner:bestAction usage example"
  print(_todo)
end

--@api-stub: QLearner:getQValue
-- Returns the Q-value for a state-action pair (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getQValue
  local _todo = "TODO: write a real QLearner:getQValue usage example"
  print(_todo)
end

--@api-stub: QLearner:endEpisode
-- Ends the current episode, applying epsilon decay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:endEpisode
  local _todo = "TODO: write a real QLearner:endEpisode usage example"
  print(_todo)
end

--@api-stub: QLearner:getEpisodeCount
-- Returns the number of completed episodes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getEpisodeCount
  local _todo = "TODO: write a real QLearner:getEpisodeCount usage example"
  print(_todo)
end

--@api-stub: QLearner:getStateCount
-- Returns the number of discrete states.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getStateCount
  local _todo = "TODO: write a real QLearner:getStateCount usage example"
  print(_todo)
end

--@api-stub: QLearner:getActionCount
-- Returns the number of discrete actions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getActionCount
  local _todo = "TODO: write a real QLearner:getActionCount usage example"
  print(_todo)
end

--@api-stub: QLearner:setLearningRate
-- Sets the learning rate alpha.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:setLearningRate
  local _todo = "TODO: write a real QLearner:setLearningRate usage example"
  print(_todo)
end

--@api-stub: QLearner:getLearningRate
-- Returns the current learning rate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getLearningRate
  local _todo = "TODO: write a real QLearner:getLearningRate usage example"
  print(_todo)
end

--@api-stub: QLearner:setDiscountFactor
-- Sets the discount factor gamma.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:setDiscountFactor
  local _todo = "TODO: write a real QLearner:setDiscountFactor usage example"
  print(_todo)
end

--@api-stub: QLearner:getDiscountFactor
-- Returns the current discount factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getDiscountFactor
  local _todo = "TODO: write a real QLearner:getDiscountFactor usage example"
  print(_todo)
end

--@api-stub: QLearner:setExplorationRate
-- Sets the exploration rate epsilon.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:setExplorationRate
  local _todo = "TODO: write a real QLearner:setExplorationRate usage example"
  print(_todo)
end

--@api-stub: QLearner:getExplorationRate
-- Returns the current exploration rate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getExplorationRate
  local _todo = "TODO: write a real QLearner:getExplorationRate usage example"
  print(_todo)
end

--@api-stub: QLearner:setExplorationDecay
-- Sets the epsilon decay multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:setExplorationDecay
  local _todo = "TODO: write a real QLearner:setExplorationDecay usage example"
  print(_todo)
end

--@api-stub: QLearner:getExplorationDecay
-- Returns the epsilon decay multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:getExplorationDecay
  local _todo = "TODO: write a real QLearner:getExplorationDecay usage example"
  print(_todo)
end

--@api-stub: QLearner:serialize
-- Serializes the Q-table to a JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:serialize
  local _todo = "TODO: write a real QLearner:serialize usage example"
  print(_todo)
end

--@api-stub: QLearner:deserialize
-- Restores the Q-table from a JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:deserialize
  local _todo = "TODO: write a real QLearner:deserialize usage example"
  print(_todo)
end

--@api-stub: QLearner:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:type
  local _todo = "TODO: write a real QLearner:type usage example"
  print(_todo)
end

--@api-stub: QLearner:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: QLearner:typeOf
  local _todo = "TODO: write a real QLearner:typeOf usage example"
  print(_todo)
end

-- ── UtilityAI methods ──

--@api-stub: UtilityAI:evaluate
-- Evaluates all actions and returns the best action name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: UtilityAI:evaluate
  local _todo = "TODO: write a real UtilityAI:evaluate usage example"
  print(_todo)
end

--@api-stub: UtilityAI:getActionCount
-- Returns the number of registered actions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: UtilityAI:getActionCount
  local _todo = "TODO: write a real UtilityAI:getActionCount usage example"
  print(_todo)
end

--@api-stub: UtilityAI:getLastAction
-- Returns the name of the last chosen action, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: UtilityAI:getLastAction
  local _todo = "TODO: write a real UtilityAI:getLastAction usage example"
  print(_todo)
end

--@api-stub: UtilityAI:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: UtilityAI:type
  local _todo = "TODO: write a real UtilityAI:type usage example"
  print(_todo)
end

--@api-stub: UtilityAI:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: UtilityAI:typeOf
  local _todo = "TODO: write a real UtilityAI:typeOf usage example"
  print(_todo)
end

-- ── GOAPPlanner methods ──

--@api-stub: GOAPPlanner:getActionCount
-- Returns the number of registered actions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GOAPPlanner:getActionCount
  local _todo = "TODO: write a real GOAPPlanner:getActionCount usage example"
  print(_todo)
end

--@api-stub: GOAPPlanner:getGoalCount
-- Returns the number of registered goals.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GOAPPlanner:getGoalCount
  local _todo = "TODO: write a real GOAPPlanner:getGoalCount usage example"
  print(_todo)
end

--@api-stub: GOAPPlanner:getMaxIterations
-- Returns the maximum A* planning iterations.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GOAPPlanner:getMaxIterations
  local _todo = "TODO: write a real GOAPPlanner:getMaxIterations usage example"
  print(_todo)
end

--@api-stub: GOAPPlanner:setMaxIterations
-- Sets the maximum A* planning iterations (0 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GOAPPlanner:setMaxIterations
  local _todo = "TODO: write a real GOAPPlanner:setMaxIterations usage example"
  print(_todo)
end

--@api-stub: GOAPPlanner:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GOAPPlanner:type
  local _todo = "TODO: write a real GOAPPlanner:type usage example"
  print(_todo)
end

--@api-stub: GOAPPlanner:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GOAPPlanner:typeOf
  local _todo = "TODO: write a real GOAPPlanner:typeOf usage example"
  print(_todo)
end

-- ── InfluenceMap methods ──

--@api-stub: InfluenceMap:addLayer
-- Adds a named influence layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:addLayer
  local _todo = "TODO: write a real InfluenceMap:addLayer usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:hasLayer
-- Returns true if the named layer exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:hasLayer
  local _todo = "TODO: write a real InfluenceMap:hasLayer usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:decay
-- Multiplies all influences by a decay factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:decay
  local _todo = "TODO: write a real InfluenceMap:decay usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:clearLayer
-- Clears all influence in a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:clearLayer
  local _todo = "TODO: write a real InfluenceMap:clearLayer usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:clearAll
-- Removes all influence values from every layer in the map.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:clearAll
  local _todo = "TODO: write a real InfluenceMap:clearAll usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:getMaxPosition
-- Returns the world-space position of the maximum value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:getMaxPosition
  local _todo = "TODO: write a real InfluenceMap:getMaxPosition usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:getMinPosition
-- Returns the world-space position of the minimum value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:getMinPosition
  local _todo = "TODO: write a real InfluenceMap:getMinPosition usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:getWidth
-- Returns the influence map width in grid cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:getWidth
  local _todo = "TODO: write a real InfluenceMap:getWidth usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:getHeight
-- Returns the influence map height in grid cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:getHeight
  local _todo = "TODO: write a real InfluenceMap:getHeight usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:getCellSize
-- Returns the cell size in world units.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:getCellSize
  local _todo = "TODO: write a real InfluenceMap:getCellSize usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:type
  local _todo = "TODO: write a real InfluenceMap:type usage example"
  print(_todo)
end

--@api-stub: InfluenceMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: InfluenceMap:typeOf
  local _todo = "TODO: write a real InfluenceMap:typeOf usage example"
  print(_todo)
end

-- ── Squad methods ──

--@api-stub: Squad:getName
-- Returns the unique name string assigned to this squad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getName
  local _todo = "TODO: write a real Squad:getName usage example"
  print(_todo)
end

--@api-stub: Squad:addMember
-- Adds an agent by name to this squad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:addMember
  local _todo = "TODO: write a real Squad:addMember usage example"
  print(_todo)
end

--@api-stub: Squad:removeMember
-- Removes an agent by name from this squad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:removeMember
  local _todo = "TODO: write a real Squad:removeMember usage example"
  print(_todo)
end

--@api-stub: Squad:getMemberCount
-- Returns the number of squad members.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getMemberCount
  local _todo = "TODO: write a real Squad:getMemberCount usage example"
  print(_todo)
end

--@api-stub: Squad:getMembers
-- Returns the member names as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getMembers
  local _todo = "TODO: write a real Squad:getMembers usage example"
  print(_todo)
end

--@api-stub: Squad:setLeader
-- Sets the squad leader by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:setLeader
  local _todo = "TODO: write a real Squad:setLeader usage example"
  print(_todo)
end

--@api-stub: Squad:getLeader
-- Returns the leader name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getLeader
  local _todo = "TODO: write a real Squad:getLeader usage example"
  print(_todo)
end

--@api-stub: Squad:getFormation
-- Returns the current formation type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getFormation
  local _todo = "TODO: write a real Squad:getFormation usage example"
  print(_todo)
end

--@api-stub: Squad:getFormationSpacing
-- Returns the formation spacing in world units.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getFormationSpacing
  local _todo = "TODO: write a real Squad:getFormationSpacing usage example"
  print(_todo)
end

--@api-stub: Squad:getBlackboard
-- Returns the squad's shared blackboard.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:getBlackboard
  local _todo = "TODO: write a real Squad:getBlackboard usage example"
  print(_todo)
end

--@api-stub: Squad:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:type
  local _todo = "TODO: write a real Squad:type usage example"
  print(_todo)
end

--@api-stub: Squad:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Squad:typeOf
  local _todo = "TODO: write a real Squad:typeOf usage example"
  print(_todo)
end

-- ── CommandQueue methods ──

--@api-stub: CommandQueue:cancelCurrent
-- Cancels the front command if it is interruptible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:cancelCurrent
  local _todo = "TODO: write a real CommandQueue:cancelCurrent usage example"
  print(_todo)
end

--@api-stub: CommandQueue:clear
-- Discards all queued commands.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:clear
  local _todo = "TODO: write a real CommandQueue:clear usage example"
  print(_todo)
end

--@api-stub: CommandQueue:getCount
-- Returns the number of queued commands.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:getCount
  local _todo = "TODO: write a real CommandQueue:getCount usage example"
  print(_todo)
end

--@api-stub: CommandQueue:isEmpty
-- Returns true if there are no queued commands.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:isEmpty
  local _todo = "TODO: write a real CommandQueue:isEmpty usage example"
  print(_todo)
end

--@api-stub: CommandQueue:getCurrentType
-- Returns the kind of the front command, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:getCurrentType
  local _todo = "TODO: write a real CommandQueue:getCurrentType usage example"
  print(_todo)
end

--@api-stub: CommandQueue:getCurrentTarget
-- Returns the target coordinates of the front command.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:getCurrentTarget
  local _todo = "TODO: write a real CommandQueue:getCurrentTarget usage example"
  print(_todo)
end

--@api-stub: CommandQueue:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:type
  local _todo = "TODO: write a real CommandQueue:type usage example"
  print(_todo)
end

--@api-stub: CommandQueue:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: CommandQueue:typeOf
  local _todo = "TODO: write a real CommandQueue:typeOf usage example"
  print(_todo)
end

-- ── TraitProfile methods ──

--@api-stub: TraitProfile:set
-- Sets the base value of this trait, replacing any previous base.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:set
  local _todo = "TODO: write a real TraitProfile:set usage example"
  print(_todo)
end

--@api-stub: TraitProfile:get
-- Returns the current float value of this emotion dimension.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:get
  local _todo = "TODO: write a real TraitProfile:get usage example"
  print(_todo)
end

--@api-stub: TraitProfile:getBase
-- Returns the unmodified base value of this trait before modifiers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:getBase
  local _todo = "TODO: write a real TraitProfile:getBase usage example"
  print(_todo)
end

--@api-stub: TraitProfile:removeModifiers
-- Removes the specified modifiers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:removeModifiers
  local _todo = "TODO: write a real TraitProfile:removeModifiers usage example"
  print(_todo)
end

--@api-stub: TraitProfile:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:update
  local _todo = "TODO: write a real TraitProfile:update usage example"
  print(_todo)
end

--@api-stub: TraitProfile:has
-- Returns true if a item is present.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:has
  local _todo = "TODO: write a real TraitProfile:has usage example"
  print(_todo)
end

--@api-stub: TraitProfile:traitCount
-- Returns or performs trait count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:traitCount
  local _todo = "TODO: write a real TraitProfile:traitCount usage example"
  print(_todo)
end

--@api-stub: TraitProfile:archetype
-- Returns or performs archetype.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: TraitProfile:archetype
  local _todo = "TODO: write a real TraitProfile:archetype usage example"
  print(_todo)
end

-- ── StimulusWorld methods ──

--@api-stub: StimulusWorld:remove
-- Removes the specified item.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StimulusWorld:remove
  local _todo = "TODO: write a real StimulusWorld:remove usage example"
  print(_todo)
end

--@api-stub: StimulusWorld:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StimulusWorld:update
  local _todo = "TODO: write a real StimulusWorld:update usage example"
  print(_todo)
end

--@api-stub: StimulusWorld:clear
-- Resets or clears the state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StimulusWorld:clear
  local _todo = "TODO: write a real StimulusWorld:clear usage example"
  print(_todo)
end

-- ── ContextSteering methods ──

--@api-stub: ContextSteering:addWander
-- Adds a wander behavior with jitter and weight to the context steering evaluator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ContextSteering:addWander
  local _todo = "TODO: write a real ContextSteering:addWander usage example"
  print(_todo)
end

--@api-stub: ContextSteering:addAvoidBounds
-- Registers a rectangular region this agent must avoid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ContextSteering:addAvoidBounds
  local _todo = "TODO: write a real ContextSteering:addAvoidBounds usage example"
  print(_todo)
end

--@api-stub: ContextSteering:clearBehaviors
-- Resets or clears the behaviors.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ContextSteering:clearBehaviors
  local _todo = "TODO: write a real ContextSteering:clearBehaviors usage example"
  print(_todo)
end

--@api-stub: ContextSteering:chosenMagnitude
-- Returns or performs chosen magnitude.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ContextSteering:chosenMagnitude
  local _todo = "TODO: write a real ContextSteering:chosenMagnitude usage example"
  print(_todo)
end

--@api-stub: ContextSteering:slotCount
-- Returns or performs slot count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ContextSteering:slotCount
  local _todo = "TODO: write a real ContextSteering:slotCount usage example"
  print(_todo)
end

-- ── NeedSystem methods ──

--@api-stub: NeedSystem:addNeed
-- Registers a new need with the specified name, urgency, and decay rate in the system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeedSystem:addNeed
  local _todo = "TODO: write a real NeedSystem:addNeed usage example"
  print(_todo)
end

--@api-stub: NeedSystem:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeedSystem:update
  local _todo = "TODO: write a real NeedSystem:update usage example"
  print(_todo)
end

--@api-stub: NeedSystem:mostUrgent
-- Returns or performs most urgent.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeedSystem:mostUrgent
  local _todo = "TODO: write a real NeedSystem:mostUrgent usage example"
  print(_todo)
end

--@api-stub: NeedSystem:satisfy
-- Returns or performs satisfy.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeedSystem:satisfy
  local _todo = "TODO: write a real NeedSystem:satisfy usage example"
  print(_todo)
end

--@api-stub: NeedSystem:valueOf
-- Returns or performs value of.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeedSystem:valueOf
  local _todo = "TODO: write a real NeedSystem:valueOf usage example"
  print(_todo)
end

-- ── AIDirector methods ──

--@api-stub: AIDirector:pushEvent
-- Pushes a gameplay event with the given intensity to the director for awareness analysis.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:pushEvent
  local _todo = "TODO: write a real AIDirector:pushEvent usage example"
  print(_todo)
end

--@api-stub: AIDirector:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:update
  local _todo = "TODO: write a real AIDirector:update usage example"
  print(_todo)
end

--@api-stub: AIDirector:tension
-- Returns or performs tension.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:tension
  local _todo = "TODO: write a real AIDirector:tension usage example"
  print(_todo)
end

--@api-stub: AIDirector:phase
-- Returns or performs phase.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:phase
  local _todo = "TODO: write a real AIDirector:phase usage example"
  print(_todo)
end

--@api-stub: AIDirector:spawnRateFactor
-- Returns or performs spawn rate factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:spawnRateFactor
  local _todo = "TODO: write a real AIDirector:spawnRateFactor usage example"
  print(_todo)
end

--@api-stub: AIDirector:lootFactor
-- Returns or performs loot factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:lootFactor
  local _todo = "TODO: write a real AIDirector:lootFactor usage example"
  print(_todo)
end

--@api-stub: AIDirector:ambientIntensity
-- Returns or performs ambient intensity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:ambientIntensity
  local _todo = "TODO: write a real AIDirector:ambientIntensity usage example"
  print(_todo)
end

--@api-stub: AIDirector:setTension
-- Sets the global narrative tension level (0â€“1 scale).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:setTension
  local _todo = "TODO: write a real AIDirector:setTension usage example"
  print(_todo)
end

--@api-stub: AIDirector:reset
-- Resets or clears the state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AIDirector:reset
  local _todo = "TODO: write a real AIDirector:reset usage example"
  print(_todo)
end

-- ── HTNDomain methods ──

--@api-stub: HTNDomain:addPrimitive
-- Registers a primitive HTN task with a direct operator function.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: HTNDomain:addPrimitive
  local _todo = "TODO: write a real HTNDomain:addPrimitive usage example"
  print(_todo)
end

--@api-stub: HTNDomain:taskCount
-- Returns or performs task count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: HTNDomain:taskCount
  local _todo = "TODO: write a real HTNDomain:taskCount usage example"
  print(_todo)
end

-- ── EmotionModel methods ──

--@api-stub: EmotionModel:trigger
-- Returns or performs trigger.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: EmotionModel:trigger
  local _todo = "TODO: write a real EmotionModel:trigger usage example"
  print(_todo)
end

--@api-stub: EmotionModel:get
-- Returns the current float value of this emotion dimension.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: EmotionModel:get
  local _todo = "TODO: write a real EmotionModel:get usage example"
  print(_todo)
end

--@api-stub: EmotionModel:dominant
-- Returns or performs dominant.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: EmotionModel:dominant
  local _todo = "TODO: write a real EmotionModel:dominant usage example"
  print(_todo)
end

--@api-stub: EmotionModel:isActive
-- Returns `true` if the emotion dimension is currently active and above threshold.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: EmotionModel:isActive
  local _todo = "TODO: write a real EmotionModel:isActive usage example"
  print(_todo)
end

--@api-stub: EmotionModel:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: EmotionModel:update
  local _todo = "TODO: write a real EmotionModel:update usage example"
  print(_todo)
end

--@api-stub: EmotionModel:reset
-- Resets or clears the state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: EmotionModel:reset
  local _todo = "TODO: write a real EmotionModel:reset usage example"
  print(_todo)
end

-- ── ORCASolver methods ──

--@api-stub: ORCASolver:setPosition
-- Sets the agent's current world-space position for ORCA velocity computation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ORCASolver:setPosition
  local _todo = "TODO: write a real ORCASolver:setPosition usage example"
  print(_todo)
end

--@api-stub: ORCASolver:compute
-- Computes and returns the result.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ORCASolver:compute
  local _todo = "TODO: write a real ORCASolver:compute usage example"
  print(_todo)
end

--@api-stub: ORCASolver:getSafeVelocity
-- Returns the safe velocity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ORCASolver:getSafeVelocity
  local _todo = "TODO: write a real ORCASolver:getSafeVelocity usage example"
  print(_todo)
end

--@api-stub: ORCASolver:agentCount
-- Returns or performs agent count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: ORCASolver:agentCount
  local _todo = "TODO: write a real ORCASolver:agentCount usage example"
  print(_todo)
end

-- ── NeuralNet methods ──

--@api-stub: NeuralNet:forward
-- Returns or performs forward.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeuralNet:forward
  local _todo = "TODO: write a real NeuralNet:forward usage example"
  print(_todo)
end

--@api-stub: NeuralNet:setWeights
-- Overwrites all connection weights with values from a flat table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeuralNet:setWeights
  local _todo = "TODO: write a real NeuralNet:setWeights usage example"
  print(_todo)
end

--@api-stub: NeuralNet:getWeights
-- Returns a flat table of all connection weight values in the network.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeuralNet:getWeights
  local _todo = "TODO: write a real NeuralNet:getWeights usage example"
  print(_todo)
end

--@api-stub: NeuralNet:paramCount
-- Returns or performs param count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeuralNet:paramCount
  local _todo = "TODO: write a real NeuralNet:paramCount usage example"
  print(_todo)
end

--@api-stub: NeuralNet:layerCount
-- Returns or performs layer count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: NeuralNet:layerCount
  local _todo = "TODO: write a real NeuralNet:layerCount usage example"
  print(_todo)
end

-- ── GeneticAlgorithm methods ──

--@api-stub: GeneticAlgorithm:evolve
-- Runs one generation of the evolutionary algorithm.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GeneticAlgorithm:evolve
  local _todo = "TODO: write a real GeneticAlgorithm:evolve usage example"
  print(_todo)
end

--@api-stub: GeneticAlgorithm:generation
-- Returns or performs generation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GeneticAlgorithm:generation
  local _todo = "TODO: write a real GeneticAlgorithm:generation usage example"
  print(_todo)
end

--@api-stub: GeneticAlgorithm:popSize
-- Returns or performs pop size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GeneticAlgorithm:popSize
  local _todo = "TODO: write a real GeneticAlgorithm:popSize usage example"
  print(_todo)
end

--@api-stub: GeneticAlgorithm:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GeneticAlgorithm:setFitness
  local _todo = "TODO: write a real GeneticAlgorithm:setFitness usage example"
  print(_todo)
end

--@api-stub: GeneticAlgorithm:getGenes
-- Returns the chromosome as an ordered table of gene values.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GeneticAlgorithm:getGenes
  local _todo = "TODO: write a real GeneticAlgorithm:getGenes usage example"
  print(_todo)
end

--@api-stub: GeneticAlgorithm:bestGenes
-- Returns or performs best genes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: GeneticAlgorithm:bestGenes
  local _todo = "TODO: write a real GeneticAlgorithm:bestGenes usage example"
  print(_todo)
end

-- ── Bandit methods ──

--@api-stub: Bandit:select
-- Returns or performs select.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Bandit:select
  local _todo = "TODO: write a real Bandit:select usage example"
  print(_todo)
end

--@api-stub: Bandit:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Bandit:update
  local _todo = "TODO: write a real Bandit:update usage example"
  print(_todo)
end

--@api-stub: Bandit:bestArm
-- Returns or performs best arm.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Bandit:bestArm
  local _todo = "TODO: write a real Bandit:bestArm usage example"
  print(_todo)
end

--@api-stub: Bandit:reset
-- Resets or clears the state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Bandit:reset
  local _todo = "TODO: write a real Bandit:reset usage example"
  print(_todo)
end

--@api-stub: Bandit:armCount
-- Returns or performs arm count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Bandit:armCount
  local _todo = "TODO: write a real Bandit:armCount usage example"
  print(_todo)
end

--@api-stub: Bandit:totalPulls
-- Returns or performs total pulls.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Bandit:totalPulls
  local _todo = "TODO: write a real Bandit:totalPulls usage example"
  print(_todo)
end

-- ── Neuroevolution methods ──

--@api-stub: Neuroevolution:evolve
-- Runs one generation of the evolutionary algorithm.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:evolve
  local _todo = "TODO: write a real Neuroevolution:evolve usage example"
  print(_todo)
end

--@api-stub: Neuroevolution:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:setFitness
  local _todo = "TODO: write a real Neuroevolution:setFitness usage example"
  print(_todo)
end

--@api-stub: Neuroevolution:chromosomeToNet
-- Returns or performs chromosome to net.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:chromosomeToNet
  local _todo = "TODO: write a real Neuroevolution:chromosomeToNet usage example"
  print(_todo)
end

--@api-stub: Neuroevolution:bestNetwork
-- Returns or performs best network.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:bestNetwork
  local _todo = "TODO: write a real Neuroevolution:bestNetwork usage example"
  print(_todo)
end

--@api-stub: Neuroevolution:bestFitness
-- Returns or performs best fitness.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:bestFitness
  local _todo = "TODO: write a real Neuroevolution:bestFitness usage example"
  print(_todo)
end

--@api-stub: Neuroevolution:popSize
-- Returns or performs pop size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:popSize
  local _todo = "TODO: write a real Neuroevolution:popSize usage example"
  print(_todo)
end

--@api-stub: Neuroevolution:generation
-- Returns or performs generation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: Neuroevolution:generation
  local _todo = "TODO: write a real Neuroevolution:generation usage example"
  print(_todo)
end

-- ── StrategyAI methods ──

--@api-stub: StrategyAI:addGoal
-- Adds a strategic goal with priority score to the planner for future evaluation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:addGoal
  local _todo = "TODO: write a real StrategyAI:addGoal usage example"
  print(_todo)
end

--@api-stub: StrategyAI:addTag
-- Adds a string tag to the strategy AI instance for goal filtering and categorization.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:addTag
  local _todo = "TODO: write a real StrategyAI:addTag usage example"
  print(_todo)
end

--@api-stub: StrategyAI:removeTag
-- Removes the specified tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:removeTag
  local _todo = "TODO: write a real StrategyAI:removeTag usage example"
  print(_todo)
end

--@api-stub: StrategyAI:update
-- Advances the simulation by one time step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:update
  local _todo = "TODO: write a real StrategyAI:update usage example"
  print(_todo)
end

--@api-stub: StrategyAI:forceEvaluate
-- Returns or performs force evaluate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:forceEvaluate
  local _todo = "TODO: write a real StrategyAI:forceEvaluate usage example"
  print(_todo)
end

--@api-stub: StrategyAI:activeGoal
-- Returns or performs active goal.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:activeGoal
  local _todo = "TODO: write a real StrategyAI:activeGoal usage example"
  print(_todo)
end

--@api-stub: StrategyAI:timeUntilNext
-- Returns or performs time until next.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: StrategyAI:timeUntilNext
  local _todo = "TODO: write a real StrategyAI:timeUntilNext usage example"
  print(_todo)
end

-- ── AILod methods ──

--@api-stub: AILod:shouldUpdate
-- Returns or performs should update.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AILod:shouldUpdate
  local _todo = "TODO: write a real AILod:shouldUpdate usage example"
  print(_todo)
end

--@api-stub: AILod:tierCount
-- Returns or performs tier count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AILod:tierCount
  local _todo = "TODO: write a real AILod:tierCount usage example"
  print(_todo)
end

--@api-stub: AILod:tierName
-- Returns or performs tier name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ai_api.rs and docs/specs/ai.md).
do  -- TODO: AILod:tierName
  local _todo = "TODO: write a real AILod:tierName usage example"
  print(_todo)
end

