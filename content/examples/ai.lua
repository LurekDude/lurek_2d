-- content/examples/ai.lua
-- Practical usage examples for the lurek.ai API (240 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.ai.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/ai.lua

print("[example] lurek.ai — 240 API entries")

-- ── lurek.ai.* free functions ──

--@api-stub: lurek.ai.newWorld
-- Creates a new AI world container.
-- Call when you need to create a new world.
local ok, obj = pcall(function() return lurek.ai.newWorld() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newWorld ok=", ok)

--@api-stub: lurek.ai.newBlackboard
-- Creates a new standalone blackboard.
-- Call when you need to create a new blackboard.
local ok, obj = pcall(function() return lurek.ai.newBlackboard() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newBlackboard ok=", ok)

--@api-stub: lurek.ai.newStateMachine
-- Creates a new finite state machine.
-- Call when you need to create a new state machine.
local ok, obj = pcall(function() return lurek.ai.newStateMachine() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newStateMachine ok=", ok)

--@api-stub: lurek.ai.newBehaviorTree
-- Creates a new behavior tree.
-- Call when you need to create a new behavior tree.
local ok, obj = pcall(function() return lurek.ai.newBehaviorTree() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newBehaviorTree ok=", ok)

--@api-stub: lurek.ai.newSelector
-- Creates a BT selector node.
-- Call when you need to create a new selector.
local ok, obj = pcall(function() return lurek.ai.newSelector() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newSelector ok=", ok)

--@api-stub: lurek.ai.newSequence
-- Creates a BT sequence node.
-- Call when you need to create a new sequence.
local ok, obj = pcall(function() return lurek.ai.newSequence() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newSequence ok=", ok)

--@api-stub: lurek.ai.newParallel
-- Creates a BT parallel node with optional policies.
-- Call when you need to create a new parallel.
local ok, obj = pcall(function() return lurek.ai.newParallel(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newParallel ok=", ok)

--@api-stub: lurek.ai.newInverter
-- Creates a BT inverter decorator.
-- Call when you need to create a new inverter.
local ok, obj = pcall(function() return lurek.ai.newInverter() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newInverter ok=", ok)

--@api-stub: lurek.ai.newRepeater
-- Creates a BT repeater decorator.
-- Call when you need to create a new repeater.
local ok, obj = pcall(function() return lurek.ai.newRepeater(10) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newRepeater ok=", ok)

--@api-stub: lurek.ai.newSucceeder
-- Creates a BT succeeder decorator.
-- Call when you need to create a new succeeder.
local ok, obj = pcall(function() return lurek.ai.newSucceeder() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newSucceeder ok=", ok)

--@api-stub: lurek.ai.newAction
-- Creates a BT action leaf with a Lua callback.
-- Call when you need to create a new action.
local ok, obj = pcall(function() return lurek.ai.newAction(function() end) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newAction ok=", ok)

--@api-stub: lurek.ai.newCondition
-- Creates a BT condition leaf with a Lua predicate.
-- Call when you need to create a new condition.
local ok, obj = pcall(function() return lurek.ai.newCondition(function() end) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newCondition ok=", ok)

--@api-stub: lurek.ai.newSteeringManager
-- Creates a new steering behavior manager.
-- Call when you need to create a new steering manager.
local ok, obj = pcall(function() return lurek.ai.newSteeringManager() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newSteeringManager ok=", ok)

--@api-stub: lurek.ai.newQLearner
-- Creates a tabular Q-learner.
-- Call when you need to create a new q learner.
local ok, obj = pcall(function() return lurek.ai.newQLearner(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newQLearner ok=", ok)

--@api-stub: lurek.ai.newUtilityAI
-- Creates a new utility AI evaluator.
-- Call when you need to create a new utility a i.
local ok, obj = pcall(function() return lurek.ai.newUtilityAI() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newUtilityAI ok=", ok)

--@api-stub: lurek.ai.newGOAPPlanner
-- Creates a new GOAP planning solver.
-- Call when you need to create a new g o a p planner.
local ok, obj = pcall(function() return lurek.ai.newGOAPPlanner() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newGOAPPlanner ok=", ok)

--@api-stub: lurek.ai.newInfluenceMap
-- Creates a multi-layer influence map grid.
-- Call when you need to create a new influence map.
local ok, obj = pcall(function() return lurek.ai.newInfluenceMap(100, 100, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newInfluenceMap ok=", ok)

--@api-stub: lurek.ai.newSquad
-- Creates a named squad for formation positioning.
-- Call when you need to create a new squad.
local ok, obj = pcall(function() return lurek.ai.newSquad("name") end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newSquad ok=", ok)

--@api-stub: lurek.ai.newCommandQueue
-- Creates an RTS-style command queue.
-- Call when you need to create a new command queue.
local ok, obj = pcall(function() return lurek.ai.newCommandQueue() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newCommandQueue ok=", ok)

--@api-stub: lurek.ai.newTraitProfile
-- Creates a new personality trait profile.
-- Call when you need to create a new trait profile.
local ok, obj = pcall(function() return lurek.ai.newTraitProfile() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newTraitProfile ok=", ok)

--@api-stub: lurek.ai.newStimulusWorld
-- Creates a new stimulus perception world.
-- Call when you need to create a new stimulus world.
local ok, obj = pcall(function() return lurek.ai.newStimulusWorld() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newStimulusWorld ok=", ok)

--@api-stub: lurek.ai.newContextSteering
-- Creates a new context steering controller.
-- Call when you need to create a new context steering.
local ok, obj = pcall(function() return lurek.ai.newContextSteering(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newContextSteering ok=", ok)

--@api-stub: lurek.ai.newNeedSystem
-- Creates a new motivational need system.
-- Call when you need to create a new need system.
local ok, obj = pcall(function() return lurek.ai.newNeedSystem() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newNeedSystem ok=", ok)

--@api-stub: lurek.ai.newAIDirector
-- Creates a new AI pacing director with default config.
-- Call when you need to create a new a i director.
local ok, obj = pcall(function() return lurek.ai.newAIDirector() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newAIDirector ok=", ok)

--@api-stub: lurek.ai.newHTNDomain
-- Creates a new Hierarchical Task Network domain.
-- Call when you need to create a new h t n domain.
local ok, obj = pcall(function() return lurek.ai.newHTNDomain() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newHTNDomain ok=", ok)

--@api-stub: lurek.ai.newMCTSEngine
-- Creates a new Monte Carlo Tree Search engine.
-- Call when you need to create a new m c t s engine.
local ok, obj = pcall(function() return lurek.ai.newMCTSEngine(nil, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newMCTSEngine ok=", ok)

--@api-stub: lurek.ai.newEmotionModel
-- Creates a new affective emotion model.
-- Call when you need to create a new emotion model.
local ok, obj = pcall(function() return lurek.ai.newEmotionModel() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newEmotionModel ok=", ok)

--@api-stub: lurek.ai.newORCASolver
-- Creates a new ORCA crowd avoidance solver.
-- Call when you need to create a new o r c a solver.
local ok, obj = pcall(function() return lurek.ai.newORCASolver(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newORCASolver ok=", ok)

--@api-stub: lurek.ai.newNeuralNet
-- Creates a new feedforward neural network (inference only).
-- Call when you need to create a new neural net.
local ok, obj = pcall(function() return lurek.ai.newNeuralNet() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newNeuralNet ok=", ok)

--@api-stub: lurek.ai.newGeneticAlgorithm
-- Creates a new genetic algorithm.
-- Call when you need to create a new genetic algorithm.
local ok, obj = pcall(function() return lurek.ai.newGeneticAlgorithm(nil, 10, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newGeneticAlgorithm ok=", ok)

--@api-stub: lurek.ai.newBandit
-- Creates a new multi-armed bandit.
-- Call when you need to create a new bandit.
local ok, obj = pcall(function() return lurek.ai.newBandit(10, "strategy value", nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newBandit ok=", ok)

--@api-stub: lurek.ai.newNeuroevolution
-- Creates a neuroevolution trainer (GA for neural network weights).
-- Call when you need to create a new neuroevolution.
local ok, obj = pcall(function() return lurek.ai.newNeuroevolution(nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newNeuroevolution ok=", ok)

--@api-stub: lurek.ai.newStrategyAI
-- Creates a new throttled strategy AI.
-- Call when you need to create a new strategy a i.
local ok, obj = pcall(function() return lurek.ai.newStrategyAI(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newStrategyAI ok=", ok)

--@api-stub: lurek.ai.newAILod
-- Creates a new AI LOD controller with default 3-tier config.
-- Call when you need to create a new a i lod.
local ok, obj = pcall(function() return lurek.ai.newAILod() end)
if ok and obj then print("created:", obj) end
print("lurek.ai.newAILod ok=", ok)

-- ── AIWorld methods ──

--@api-stub: AIWorld:addAgent
-- Registers a new named agent and returns its handle.
-- Call when you need to add agent.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:addAgent("name") end)
  print("AIWorld:addAgent ->", ok, result)
end

--@api-stub: AIWorld:getAgent
-- Returns the agent handle for the given name, or nil.
-- Call when you need to read agent.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getAgent("name") end)
  print("AIWorld:getAgent ->", ok, result)
end

--@api-stub: AIWorld:removeAgent
-- Removes an agent by its userdata handle.
-- Call when you need to remove agent.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:removeAgent(nil) end)
  print("AIWorld:removeAgent ->", ok, result)
end

--@api-stub: AIWorld:getAgentCount
-- Returns the number of registered agents.
-- Call when you need to read agent count.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getAgentCount() end)
  print("AIWorld:getAgentCount ->", ok, result)
end

--@api-stub: AIWorld:getGlobalBlackboard
-- Returns a snapshot of the world-level blackboard.
-- Call when you need to read global blackboard.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getGlobalBlackboard() end)
  print("AIWorld:getGlobalBlackboard ->", ok, result)
end

--@api-stub: AIWorld:update
-- Advances all agents by dt seconds.
-- Call when you need to invoke update.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("AIWorld:update ->", ok, result)
end

--@api-stub: AIWorld:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("AIWorld:type ->", ok, result)
end

--@api-stub: AIWorld:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a AIWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIWorld(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("AIWorld:typeOf ->", ok, result)
end

-- ── Agent methods ──

--@api-stub: Agent:getName
-- Returns the agent's registered name.
-- Call when you need to read name.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Agent:getName ->", ok, result)
end

--@api-stub: Agent:setPosition
-- Sets the agent's world-space position.
-- Call when you need to assign position.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("Agent:setPosition ->", ok, result)
end

--@api-stub: Agent:getPosition
-- Returns the agent's current position.
-- Call when you need to read position.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("Agent:getPosition ->", ok, result)
end

--@api-stub: Agent:setVelocity
-- Sets the agent's velocity vector.
-- Call when you need to assign velocity.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:setVelocity(0, 0) end)
  print("Agent:setVelocity ->", ok, result)
end

--@api-stub: Agent:getVelocity
-- Returns the agent's current velocity.
-- Call when you need to read velocity.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getVelocity() end)
  print("Agent:getVelocity ->", ok, result)
end

--@api-stub: Agent:setMaxSpeed
-- Sets the maximum speed cap.
-- Call when you need to assign max speed.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:setMaxSpeed(nil) end)
  print("Agent:setMaxSpeed ->", ok, result)
end

--@api-stub: Agent:getMaxSpeed
-- Returns the maximum speed cap.
-- Call when you need to read max speed.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getMaxSpeed() end)
  print("Agent:getMaxSpeed ->", ok, result)
end

--@api-stub: Agent:setMaxForce
-- Sets the maximum steering force cap.
-- Call when you need to assign max force.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:setMaxForce(nil) end)
  print("Agent:setMaxForce ->", ok, result)
end

--@api-stub: Agent:getMaxForce
-- Returns the maximum steering force cap.
-- Call when you need to read max force.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getMaxForce() end)
  print("Agent:getMaxForce ->", ok, result)
end

--@api-stub: Agent:setPriority
-- Sets the scheduling priority (higher = earlier).
-- Call when you need to assign priority.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:setPriority(nil) end)
  print("Agent:setPriority ->", ok, result)
end

--@api-stub: Agent:getPriority
-- Returns the agent's scheduling priority.
-- Call when you need to read priority.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getPriority() end)
  print("Agent:getPriority ->", ok, result)
end

--@api-stub: Agent:setDecisionModel
-- Sets the active decision model.
-- Call when you need to assign decision model.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:setDecisionModel(nil) end)
  print("Agent:setDecisionModel ->", ok, result)
end

--@api-stub: Agent:getDecisionModel
-- Returns the name of the current decision model.
-- Call when you need to read decision model.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getDecisionModel() end)
  print("Agent:getDecisionModel ->", ok, result)
end

--@api-stub: Agent:addTag
-- Adds a tag to this agent.
-- Call when you need to add tag.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:addTag("tag") end)
  print("Agent:addTag ->", ok, result)
end

--@api-stub: Agent:removeTag
-- Removes a tag from this agent.
-- Call when you need to remove tag.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:removeTag("tag") end)
  print("Agent:removeTag ->", ok, result)
end

--@api-stub: Agent:hasTag
-- Returns true if the agent has the given tag.
-- Call when you need to check has tag.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:hasTag("tag") end)
  print("Agent:hasTag ->", ok, result)
end

--@api-stub: Agent:getBlackboard
-- Returns the agent's local blackboard.
-- Call when you need to read blackboard.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:getBlackboard() end)
  print("Agent:getBlackboard ->", ok, result)
end

--@api-stub: Agent:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Agent:type ->", ok, result)
end

--@api-stub: Agent:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Agent via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAgent(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Agent:typeOf ->", ok, result)
end

-- ── Blackboard methods ──

--@api-stub: Blackboard:setNumber
-- Stores a number under the given key.
-- Call when you need to assign number.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:setNumber("key", nil) end)
  print("Blackboard:setNumber ->", ok, result)
end

--@api-stub: Blackboard:setBool
-- Stores a boolean under the given key.
-- Call when you need to assign bool.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:setBool("key", nil) end)
  print("Blackboard:setBool ->", ok, result)
end

--@api-stub: Blackboard:setString
-- Stores a string under the given key.
-- Call when you need to assign string.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:setString("key", nil) end)
  print("Blackboard:setString ->", ok, result)
end

--@api-stub: Blackboard:has
-- Returns true if a value exists under the key.
-- Call when you need to invoke has.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:has("key") end)
  print("Blackboard:has ->", ok, result)
end

--@api-stub: Blackboard:remove
-- Removes the entry at key.
-- Call when you need to invoke remove.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:remove("key") end)
  print("Blackboard:remove ->", ok, result)
end

--@api-stub: Blackboard:clear
-- Removes all local entries.
-- Call when you need to invoke clear.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Blackboard:clear ->", ok, result)
end

--@api-stub: Blackboard:getKeys
-- Returns all local keys as a table.
-- Call when you need to read keys.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:getKeys() end)
  print("Blackboard:getKeys ->", ok, result)
end

--@api-stub: Blackboard:getSize
-- Returns the number of local entries.
-- Call when you need to read size.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("Blackboard:getSize ->", ok, result)
end

--@api-stub: Blackboard:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Blackboard:type ->", ok, result)
end

--@api-stub: Blackboard:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Blackboard via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Blackboard:typeOf ->", ok, result)
end

-- ── StateMachine methods ──

--@api-stub: StateMachine:addState
-- Registers a named state with optional lifecycle callbacks.
-- Call when you need to add state.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:addState("name", {}) end)
  print("StateMachine:addState ->", ok, result)
end

--@api-stub: StateMachine:setInitialState
-- Sets the FSM's initial state; must be called before the first update.
-- Call when you need to assign initial state.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:setInitialState("name") end)
  print("StateMachine:setInitialState ->", ok, result)
end

--@api-stub: StateMachine:getCurrentState
-- Returns the current state name, or nil.
-- Call when you need to read current state.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrentState() end)
  print("StateMachine:getCurrentState ->", ok, result)
end

--@api-stub: StateMachine:forceState
-- Forces a transition to the named state.
-- Call when you need to invoke force state.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:forceState("name") end)
  print("StateMachine:forceState ->", ok, result)
end

--@api-stub: StateMachine:getTimeInState
-- Returns seconds spent in the current state.
-- Call when you need to read time in state.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:getTimeInState() end)
  print("StateMachine:getTimeInState ->", ok, result)
end

--@api-stub: StateMachine:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("StateMachine:type ->", ok, result)
end

--@api-stub: StateMachine:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a StateMachine via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("StateMachine:typeOf ->", ok, result)
end

-- ── BehaviorTree methods ──

--@api-stub: BehaviorTree:setRoot
-- Sets the root node of this behavior tree.
-- Call when you need to assign root.
-- Build a BehaviorTree via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBehaviorTree(...)
if instance then
  local ok, result = pcall(function() return instance:setRoot(nil) end)
  print("BehaviorTree:setRoot ->", ok, result)
end

--@api-stub: BehaviorTree:getLastStatus
-- Returns the status from the last tick.
-- Call when you need to read last status.
-- Build a BehaviorTree via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBehaviorTree(...)
if instance then
  local ok, result = pcall(function() return instance:getLastStatus() end)
  print("BehaviorTree:getLastStatus ->", ok, result)
end

--@api-stub: BehaviorTree:getDebugState
-- Returns a diagnostic snapshot of this behavior tree.
-- Call when you need to read debug state.
-- Build a BehaviorTree via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBehaviorTree(...)
if instance then
  local ok, result = pcall(function() return instance:getDebugState() end)
  print("BehaviorTree:getDebugState ->", ok, result)
end

--@api-stub: BehaviorTree:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a BehaviorTree via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBehaviorTree(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("BehaviorTree:type ->", ok, result)
end

--@api-stub: BehaviorTree:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a BehaviorTree via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBehaviorTree(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("BehaviorTree:typeOf ->", ok, result)
end

-- ── BTNode methods ──

--@api-stub: BTNode:addChild
-- Adds a child node (Selector, Sequence, or Parallel only).
-- Call when you need to add child.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:addChild(nil) end)
  print("BTNode:addChild ->", ok, result)
end

--@api-stub: BTNode:getChildCount
-- Returns the number of direct children.
-- Call when you need to read child count.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:getChildCount() end)
  print("BTNode:getChildCount ->", ok, result)
end

--@api-stub: BTNode:reset
-- Resets all running-child memos and repeater counters.
-- Call when you need to invoke reset.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("BTNode:reset ->", ok, result)
end

--@api-stub: BTNode:setChild
-- Sets the single child of a decorator node.
-- Call when you need to assign child.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:setChild(nil) end)
  print("BTNode:setChild ->", ok, result)
end

--@api-stub: BTNode:setCount
-- Sets the repeat count for a Repeater node.
-- Call when you need to assign count.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:setCount(10) end)
  print("BTNode:setCount ->", ok, result)
end

--@api-stub: BTNode:getCount
-- Returns the repeat count, or 0 if not a Repeater.
-- Call when you need to read count.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("BTNode:getCount ->", ok, result)
end

--@api-stub: BTNode:setSuccessPolicy
-- Sets the success policy for a Parallel node.
-- Call when you need to assign success policy.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:setSuccessPolicy(nil) end)
  print("BTNode:setSuccessPolicy ->", ok, result)
end

--@api-stub: BTNode:setFailurePolicy
-- Sets the failure policy for a Parallel node.
-- Call when you need to assign failure policy.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:setFailurePolicy(nil) end)
  print("BTNode:setFailurePolicy ->", ok, result)
end

--@api-stub: BTNode:getNodeType
-- Returns the node type as a string.
-- Call when you need to read node type.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:getNodeType() end)
  print("BTNode:getNodeType ->", ok, result)
end

--@api-stub: BTNode:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("BTNode:type ->", ok, result)
end

--@api-stub: BTNode:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a BTNode via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBTNode(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("BTNode:typeOf ->", ok, result)
end

-- ── SteeringManager methods ──

--@api-stub: SteeringManager:getBehaviorCount
-- Returns the number of active behaviors.
-- Call when you need to read behavior count.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:getBehaviorCount() end)
  print("SteeringManager:getBehaviorCount ->", ok, result)
end

--@api-stub: SteeringManager:setCombineMode
-- Sets the force combination mode.
-- Call when you need to assign combine mode.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:setCombineMode(nil) end)
  print("SteeringManager:setCombineMode ->", ok, result)
end

--@api-stub: SteeringManager:getCombineMode
-- Returns the current combination mode.
-- Call when you need to read combine mode.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:getCombineMode() end)
  print("SteeringManager:getCombineMode ->", ok, result)
end

--@api-stub: SteeringManager:getLastSteering
-- Returns the last computed steering force.
-- Call when you need to read last steering.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:getLastSteering() end)
  print("SteeringManager:getLastSteering ->", ok, result)
end

--@api-stub: SteeringManager:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("SteeringManager:type ->", ok, result)
end

--@api-stub: SteeringManager:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("SteeringManager:typeOf ->", ok, result)
end

--@api-stub: SteeringManager:setSpatialHashCellSize
-- Sets the cell size used by the spatial-hash neighbourhood search.
-- Call when you need to assign spatial hash cell size.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:setSpatialHashCellSize(10) end)
  print("SteeringManager:setSpatialHashCellSize ->", ok, result)
end

--@api-stub: SteeringManager:enableSpatialHash
-- Enables or disables spatial-hash bucketing for neighbourhood queries.
-- Call when you need to invoke enable spatial hash.
-- Build a SteeringManager via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSteeringManager(...)
if instance then
  local ok, result = pcall(function() return instance:enableSpatialHash(nil) end)
  print("SteeringManager:enableSpatialHash ->", ok, result)
end

-- ── QLearner methods ──

--@api-stub: QLearner:chooseAction
-- Selects an action using epsilon-greedy policy (1-based).
-- Call when you need to invoke choose action.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:chooseAction(nil) end)
  print("QLearner:chooseAction ->", ok, result)
end

--@api-stub: QLearner:bestAction
-- Returns the greedy-best action for the state (1-based).
-- Call when you need to invoke best action.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:bestAction(nil) end)
  print("QLearner:bestAction ->", ok, result)
end

--@api-stub: QLearner:getQValue
-- Returns the Q-value for a state-action pair (1-based).
-- Call when you need to read q value.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getQValue(nil, nil) end)
  print("QLearner:getQValue ->", ok, result)
end

--@api-stub: QLearner:endEpisode
-- Ends the current episode, applying epsilon decay.
-- Call when you need to invoke end episode.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:endEpisode() end)
  print("QLearner:endEpisode ->", ok, result)
end

--@api-stub: QLearner:getEpisodeCount
-- Returns the number of completed episodes.
-- Call when you need to read episode count.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getEpisodeCount() end)
  print("QLearner:getEpisodeCount ->", ok, result)
end

--@api-stub: QLearner:getStateCount
-- Returns the number of discrete states.
-- Call when you need to read state count.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getStateCount() end)
  print("QLearner:getStateCount ->", ok, result)
end

--@api-stub: QLearner:getActionCount
-- Returns the number of discrete actions.
-- Call when you need to read action count.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getActionCount() end)
  print("QLearner:getActionCount ->", ok, result)
end

--@api-stub: QLearner:setLearningRate
-- Sets the learning rate alpha.
-- Call when you need to assign learning rate.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:setLearningRate(nil) end)
  print("QLearner:setLearningRate ->", ok, result)
end

--@api-stub: QLearner:getLearningRate
-- Returns the current learning rate.
-- Call when you need to read learning rate.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getLearningRate() end)
  print("QLearner:getLearningRate ->", ok, result)
end

--@api-stub: QLearner:setDiscountFactor
-- Sets the discount factor gamma.
-- Call when you need to assign discount factor.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:setDiscountFactor(nil) end)
  print("QLearner:setDiscountFactor ->", ok, result)
end

--@api-stub: QLearner:getDiscountFactor
-- Returns the current discount factor.
-- Call when you need to read discount factor.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getDiscountFactor() end)
  print("QLearner:getDiscountFactor ->", ok, result)
end

--@api-stub: QLearner:setExplorationRate
-- Sets the exploration rate epsilon.
-- Call when you need to assign exploration rate.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:setExplorationRate(nil) end)
  print("QLearner:setExplorationRate ->", ok, result)
end

--@api-stub: QLearner:getExplorationRate
-- Returns the current exploration rate.
-- Call when you need to read exploration rate.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getExplorationRate() end)
  print("QLearner:getExplorationRate ->", ok, result)
end

--@api-stub: QLearner:setExplorationDecay
-- Sets the epsilon decay multiplier.
-- Call when you need to assign exploration decay.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:setExplorationDecay(nil) end)
  print("QLearner:setExplorationDecay ->", ok, result)
end

--@api-stub: QLearner:getExplorationDecay
-- Returns the epsilon decay multiplier.
-- Call when you need to read exploration decay.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:getExplorationDecay() end)
  print("QLearner:getExplorationDecay ->", ok, result)
end

--@api-stub: QLearner:serialize
-- Serializes the Q-table to a JSON string.
-- Call when you need to invoke serialize.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:serialize() end)
  print("QLearner:serialize ->", ok, result)
end

--@api-stub: QLearner:deserialize
-- Restores the Q-table from a JSON string.
-- Call when you need to invoke deserialize.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:deserialize(nil) end)
  print("QLearner:deserialize ->", ok, result)
end

--@api-stub: QLearner:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("QLearner:type ->", ok, result)
end

--@api-stub: QLearner:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a QLearner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newQLearner(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("QLearner:typeOf ->", ok, result)
end

-- ── UtilityAI methods ──

--@api-stub: UtilityAI:evaluate
-- Evaluates all actions and returns the best action name, or nil.
-- Call when you need to invoke evaluate.
-- Build a UtilityAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newUtilityAI(...)
if instance then
  local ok, result = pcall(function() return instance:evaluate() end)
  print("UtilityAI:evaluate ->", ok, result)
end

--@api-stub: UtilityAI:getActionCount
-- Returns the number of registered actions.
-- Call when you need to read action count.
-- Build a UtilityAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newUtilityAI(...)
if instance then
  local ok, result = pcall(function() return instance:getActionCount() end)
  print("UtilityAI:getActionCount ->", ok, result)
end

--@api-stub: UtilityAI:getLastAction
-- Returns the name of the last chosen action, or nil.
-- Call when you need to read last action.
-- Build a UtilityAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newUtilityAI(...)
if instance then
  local ok, result = pcall(function() return instance:getLastAction() end)
  print("UtilityAI:getLastAction ->", ok, result)
end

--@api-stub: UtilityAI:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a UtilityAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newUtilityAI(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("UtilityAI:type ->", ok, result)
end

--@api-stub: UtilityAI:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a UtilityAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newUtilityAI(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("UtilityAI:typeOf ->", ok, result)
end

-- ── GOAPPlanner methods ──

--@api-stub: GOAPPlanner:getActionCount
-- Returns the number of registered actions.
-- Call when you need to read action count.
-- Build a GOAPPlanner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGOAPPlanner(...)
if instance then
  local ok, result = pcall(function() return instance:getActionCount() end)
  print("GOAPPlanner:getActionCount ->", ok, result)
end

--@api-stub: GOAPPlanner:getGoalCount
-- Returns the number of registered goals.
-- Call when you need to read goal count.
-- Build a GOAPPlanner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGOAPPlanner(...)
if instance then
  local ok, result = pcall(function() return instance:getGoalCount() end)
  print("GOAPPlanner:getGoalCount ->", ok, result)
end

--@api-stub: GOAPPlanner:getMaxIterations
-- Returns the maximum A* planning iterations.
-- Call when you need to read max iterations.
-- Build a GOAPPlanner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGOAPPlanner(...)
if instance then
  local ok, result = pcall(function() return instance:getMaxIterations() end)
  print("GOAPPlanner:getMaxIterations ->", ok, result)
end

--@api-stub: GOAPPlanner:setMaxIterations
-- Sets the maximum A* planning iterations (0 = unlimited).
-- Call when you need to assign max iterations.
-- Build a GOAPPlanner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGOAPPlanner(...)
if instance then
  local ok, result = pcall(function() return instance:setMaxIterations(10) end)
  print("GOAPPlanner:setMaxIterations ->", ok, result)
end

--@api-stub: GOAPPlanner:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a GOAPPlanner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGOAPPlanner(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("GOAPPlanner:type ->", ok, result)
end

--@api-stub: GOAPPlanner:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a GOAPPlanner via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGOAPPlanner(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("GOAPPlanner:typeOf ->", ok, result)
end

-- ── InfluenceMap methods ──

--@api-stub: InfluenceMap:addLayer
-- Adds a named influence layer.
-- Call when you need to add layer.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:addLayer("name") end)
  print("InfluenceMap:addLayer ->", ok, result)
end

--@api-stub: InfluenceMap:hasLayer
-- Returns true if the named layer exists.
-- Call when you need to check has layer.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:hasLayer("name") end)
  print("InfluenceMap:hasLayer ->", ok, result)
end

--@api-stub: InfluenceMap:decay
-- Multiplies all influences by a decay factor.
-- Call when you need to invoke decay.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:decay(nil, 1) end)
  print("InfluenceMap:decay ->", ok, result)
end

--@api-stub: InfluenceMap:clearLayer
-- Clears all influence in a layer.
-- Call when you need to invoke clear layer.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:clearLayer(nil) end)
  print("InfluenceMap:clearLayer ->", ok, result)
end

--@api-stub: InfluenceMap:clearAll
-- Removes all influence values from every layer in the map.
-- Call when you need to invoke clear all.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("InfluenceMap:clearAll ->", ok, result)
end

--@api-stub: InfluenceMap:getMaxPosition
-- Returns the world-space position of the maximum value.
-- Call when you need to read max position.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:getMaxPosition(nil) end)
  print("InfluenceMap:getMaxPosition ->", ok, result)
end

--@api-stub: InfluenceMap:getMinPosition
-- Returns the world-space position of the minimum value.
-- Call when you need to read min position.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:getMinPosition(nil) end)
  print("InfluenceMap:getMinPosition ->", ok, result)
end

--@api-stub: InfluenceMap:getWidth
-- Returns the influence map width in grid cells.
-- Call when you need to read width.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("InfluenceMap:getWidth ->", ok, result)
end

--@api-stub: InfluenceMap:getHeight
-- Returns the influence map height in grid cells.
-- Call when you need to read height.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("InfluenceMap:getHeight ->", ok, result)
end

--@api-stub: InfluenceMap:getCellSize
-- Returns the cell size in world units.
-- Call when you need to read cell size.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:getCellSize() end)
  print("InfluenceMap:getCellSize ->", ok, result)
end

--@api-stub: InfluenceMap:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("InfluenceMap:type ->", ok, result)
end

--@api-stub: InfluenceMap:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a InfluenceMap via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newInfluenceMap(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("InfluenceMap:typeOf ->", ok, result)
end

-- ── Squad methods ──

--@api-stub: Squad:getName
-- Returns the unique name string assigned to this squad.
-- Call when you need to read name.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Squad:getName ->", ok, result)
end

--@api-stub: Squad:addMember
-- Adds an agent by name to this squad.
-- Call when you need to add member.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:addMember("name") end)
  print("Squad:addMember ->", ok, result)
end

--@api-stub: Squad:removeMember
-- Removes an agent by name from this squad.
-- Call when you need to remove member.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:removeMember("name") end)
  print("Squad:removeMember ->", ok, result)
end

--@api-stub: Squad:getMemberCount
-- Returns the number of squad members.
-- Call when you need to read member count.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getMemberCount() end)
  print("Squad:getMemberCount ->", ok, result)
end

--@api-stub: Squad:getMembers
-- Returns the member names as a table.
-- Call when you need to read members.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getMembers() end)
  print("Squad:getMembers ->", ok, result)
end

--@api-stub: Squad:setLeader
-- Sets the squad leader by name.
-- Call when you need to assign leader.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:setLeader("name") end)
  print("Squad:setLeader ->", ok, result)
end

--@api-stub: Squad:getLeader
-- Returns the leader name, or nil.
-- Call when you need to read leader.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getLeader() end)
  print("Squad:getLeader ->", ok, result)
end

--@api-stub: Squad:getFormation
-- Returns the current formation type name.
-- Call when you need to read formation.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getFormation() end)
  print("Squad:getFormation ->", ok, result)
end

--@api-stub: Squad:getFormationSpacing
-- Returns the formation spacing in world units.
-- Call when you need to read formation spacing.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getFormationSpacing() end)
  print("Squad:getFormationSpacing ->", ok, result)
end

--@api-stub: Squad:getBlackboard
-- Returns the squad's shared blackboard.
-- Call when you need to read blackboard.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:getBlackboard() end)
  print("Squad:getBlackboard ->", ok, result)
end

--@api-stub: Squad:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Squad:type ->", ok, result)
end

--@api-stub: Squad:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Squad via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newSquad(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Squad:typeOf ->", ok, result)
end

-- ── CommandQueue methods ──

--@api-stub: CommandQueue:cancelCurrent
-- Cancels the front command if it is interruptible.
-- Call when you need to invoke cancel current.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:cancelCurrent() end)
  print("CommandQueue:cancelCurrent ->", ok, result)
end

--@api-stub: CommandQueue:clear
-- Discards all queued commands.
-- Call when you need to invoke clear.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("CommandQueue:clear ->", ok, result)
end

--@api-stub: CommandQueue:getCount
-- Returns the number of queued commands.
-- Call when you need to read count.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("CommandQueue:getCount ->", ok, result)
end

--@api-stub: CommandQueue:isEmpty
-- Returns true if there are no queued commands.
-- Call when you need to check is empty.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("CommandQueue:isEmpty ->", ok, result)
end

--@api-stub: CommandQueue:getCurrentType
-- Returns the kind of the front command, or nil.
-- Call when you need to read current type.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrentType() end)
  print("CommandQueue:getCurrentType ->", ok, result)
end

--@api-stub: CommandQueue:getCurrentTarget
-- Returns the target coordinates of the front command.
-- Call when you need to read current target.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrentTarget() end)
  print("CommandQueue:getCurrentTarget ->", ok, result)
end

--@api-stub: CommandQueue:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("CommandQueue:type ->", ok, result)
end

--@api-stub: CommandQueue:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a CommandQueue via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newCommandQueue(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("CommandQueue:typeOf ->", ok, result)
end

-- ── TraitProfile methods ──

--@api-stub: TraitProfile:set
-- Sets the base value of this trait, replacing any previous base.
-- Call when you need to invoke set.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:set("name", nil) end)
  print("TraitProfile:set ->", ok, result)
end

--@api-stub: TraitProfile:get
-- Returns the current float value of this emotion dimension.
-- Call when you need to invoke get.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:get("name") end)
  print("TraitProfile:get ->", ok, result)
end

--@api-stub: TraitProfile:getBase
-- Returns the unmodified base value of this trait before modifiers.
-- Call when you need to read base.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:getBase("name") end)
  print("TraitProfile:getBase ->", ok, result)
end

--@api-stub: TraitProfile:removeModifiers
-- Removes the specified modifiers.
-- Call when you need to remove modifiers.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:removeModifiers(nil) end)
  print("TraitProfile:removeModifiers ->", ok, result)
end

--@api-stub: TraitProfile:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("TraitProfile:update ->", ok, result)
end

--@api-stub: TraitProfile:has
-- Returns true if a item is present.
-- Call when you need to invoke has.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:has("name") end)
  print("TraitProfile:has ->", ok, result)
end

--@api-stub: TraitProfile:traitCount
-- Returns or performs trait count.
-- Call when you need to invoke trait count.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:traitCount() end)
  print("TraitProfile:traitCount ->", ok, result)
end

--@api-stub: TraitProfile:archetype
-- Returns or performs archetype.
-- Call when you need to invoke archetype.
-- Build a TraitProfile via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newTraitProfile(...)
if instance then
  local ok, result = pcall(function() return instance:archetype() end)
  print("TraitProfile:archetype ->", ok, result)
end

-- ── StimulusWorld methods ──

--@api-stub: StimulusWorld:remove
-- Removes the specified item.
-- Call when you need to invoke remove.
-- Build a StimulusWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStimulusWorld(...)
if instance then
  local ok, result = pcall(function() return instance:remove(1) end)
  print("StimulusWorld:remove ->", ok, result)
end

--@api-stub: StimulusWorld:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a StimulusWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStimulusWorld(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("StimulusWorld:update ->", ok, result)
end

--@api-stub: StimulusWorld:clear
-- Resets or clears the state.
-- Call when you need to invoke clear.
-- Build a StimulusWorld via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStimulusWorld(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("StimulusWorld:clear ->", ok, result)
end

-- ── ContextSteering methods ──

--@api-stub: ContextSteering:addWander
-- Adds a wander behavior with jitter and weight to the context steering evaluator.
-- Call when you need to add wander.
-- Build a ContextSteering via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newContextSteering(...)
if instance then
  local ok, result = pcall(function() return instance:addWander(nil, nil) end)
  print("ContextSteering:addWander ->", ok, result)
end

--@api-stub: ContextSteering:addAvoidBounds
-- Registers a rectangular region this agent must avoid.
-- Call when you need to add avoid bounds.
-- Build a ContextSteering via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newContextSteering(...)
if instance then
  local ok, result = pcall(function() return instance:addAvoidBounds(nil, nil, nil, nil, nil, nil) end)
  print("ContextSteering:addAvoidBounds ->", ok, result)
end

--@api-stub: ContextSteering:clearBehaviors
-- Resets or clears the behaviors.
-- Call when you need to invoke clear behaviors.
-- Build a ContextSteering via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newContextSteering(...)
if instance then
  local ok, result = pcall(function() return instance:clearBehaviors() end)
  print("ContextSteering:clearBehaviors ->", ok, result)
end

--@api-stub: ContextSteering:chosenMagnitude
-- Returns or performs chosen magnitude.
-- Call when you need to invoke chosen magnitude.
-- Build a ContextSteering via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newContextSteering(...)
if instance then
  local ok, result = pcall(function() return instance:chosenMagnitude() end)
  print("ContextSteering:chosenMagnitude ->", ok, result)
end

--@api-stub: ContextSteering:slotCount
-- Returns or performs slot count.
-- Call when you need to invoke slot count.
-- Build a ContextSteering via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newContextSteering(...)
if instance then
  local ok, result = pcall(function() return instance:slotCount() end)
  print("ContextSteering:slotCount ->", ok, result)
end

-- ── NeedSystem methods ──

--@api-stub: NeedSystem:addNeed
-- Registers a new need with the specified name, urgency, and decay rate in the system.
-- Call when you need to add need.
-- Build a NeedSystem via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeedSystem(...)
if instance then
  local ok, result = pcall(function() return instance:addNeed("name", nil, nil, nil) end)
  print("NeedSystem:addNeed ->", ok, result)
end

--@api-stub: NeedSystem:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a NeedSystem via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeedSystem(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("NeedSystem:update ->", ok, result)
end

--@api-stub: NeedSystem:mostUrgent
-- Returns or performs most urgent.
-- Call when you need to invoke most urgent.
-- Build a NeedSystem via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeedSystem(...)
if instance then
  local ok, result = pcall(function() return instance:mostUrgent() end)
  print("NeedSystem:mostUrgent ->", ok, result)
end

--@api-stub: NeedSystem:satisfy
-- Returns or performs satisfy.
-- Call when you need to invoke satisfy.
-- Build a NeedSystem via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeedSystem(...)
if instance then
  local ok, result = pcall(function() return instance:satisfy("name", nil) end)
  print("NeedSystem:satisfy ->", ok, result)
end

--@api-stub: NeedSystem:valueOf
-- Returns or performs value of.
-- Call when you need to invoke value of.
-- Build a NeedSystem via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeedSystem(...)
if instance then
  local ok, result = pcall(function() return instance:valueOf("name") end)
  print("NeedSystem:valueOf ->", ok, result)
end

-- ── AIDirector methods ──

--@api-stub: AIDirector:pushEvent
-- Pushes a gameplay event with the given intensity to the director for awareness analysis.
-- Call when you need to invoke push event.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:pushEvent(nil) end)
  print("AIDirector:pushEvent ->", ok, result)
end

--@api-stub: AIDirector:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("AIDirector:update ->", ok, result)
end

--@api-stub: AIDirector:tension
-- Returns or performs tension.
-- Call when you need to invoke tension.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:tension() end)
  print("AIDirector:tension ->", ok, result)
end

--@api-stub: AIDirector:phase
-- Returns or performs phase.
-- Call when you need to invoke phase.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:phase() end)
  print("AIDirector:phase ->", ok, result)
end

--@api-stub: AIDirector:spawnRateFactor
-- Returns or performs spawn rate factor.
-- Call when you need to invoke spawn rate factor.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:spawnRateFactor() end)
  print("AIDirector:spawnRateFactor ->", ok, result)
end

--@api-stub: AIDirector:lootFactor
-- Returns or performs loot factor.
-- Call when you need to invoke loot factor.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:lootFactor() end)
  print("AIDirector:lootFactor ->", ok, result)
end

--@api-stub: AIDirector:ambientIntensity
-- Returns or performs ambient intensity.
-- Call when you need to invoke ambient intensity.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:ambientIntensity() end)
  print("AIDirector:ambientIntensity ->", ok, result)
end

--@api-stub: AIDirector:setTension
-- Sets the global narrative tension level (0â€“1 scale).
-- Call when you need to assign tension.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:setTension(nil) end)
  print("AIDirector:setTension ->", ok, result)
end

--@api-stub: AIDirector:reset
-- Resets or clears the state.
-- Call when you need to invoke reset.
-- Build a AIDirector via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAIDirector(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("AIDirector:reset ->", ok, result)
end

-- ── HTNDomain methods ──

--@api-stub: HTNDomain:addPrimitive
-- Registers a primitive HTN task with a direct operator function.
-- Call when you need to add primitive.
-- Build a HTNDomain via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newHTNDomain(...)
if instance then
  local ok, result = pcall(function() return instance:addPrimitive("name", nil, nil, nil) end)
  print("HTNDomain:addPrimitive ->", ok, result)
end

--@api-stub: HTNDomain:taskCount
-- Returns or performs task count.
-- Call when you need to invoke task count.
-- Build a HTNDomain via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newHTNDomain(...)
if instance then
  local ok, result = pcall(function() return instance:taskCount() end)
  print("HTNDomain:taskCount ->", ok, result)
end

-- ── EmotionModel methods ──

--@api-stub: EmotionModel:trigger
-- Returns or performs trigger.
-- Call when you need to invoke trigger.
-- Build a EmotionModel via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newEmotionModel(...)
if instance then
  local ok, result = pcall(function() return instance:trigger("name", nil) end)
  print("EmotionModel:trigger ->", ok, result)
end

--@api-stub: EmotionModel:get
-- Returns the current float value of this emotion dimension.
-- Call when you need to invoke get.
-- Build a EmotionModel via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newEmotionModel(...)
if instance then
  local ok, result = pcall(function() return instance:get("name") end)
  print("EmotionModel:get ->", ok, result)
end

--@api-stub: EmotionModel:dominant
-- Returns or performs dominant.
-- Call when you need to invoke dominant.
-- Build a EmotionModel via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newEmotionModel(...)
if instance then
  local ok, result = pcall(function() return instance:dominant() end)
  print("EmotionModel:dominant ->", ok, result)
end

--@api-stub: EmotionModel:isActive
-- Returns `true` if the emotion dimension is currently active and above threshold.
-- Call when you need to check is active.
-- Build a EmotionModel via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newEmotionModel(...)
if instance then
  local ok, result = pcall(function() return instance:isActive("name") end)
  print("EmotionModel:isActive ->", ok, result)
end

--@api-stub: EmotionModel:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a EmotionModel via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newEmotionModel(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("EmotionModel:update ->", ok, result)
end

--@api-stub: EmotionModel:reset
-- Resets or clears the state.
-- Call when you need to invoke reset.
-- Build a EmotionModel via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newEmotionModel(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("EmotionModel:reset ->", ok, result)
end

-- ── ORCASolver methods ──

--@api-stub: ORCASolver:setPosition
-- Sets the agent's current world-space position for ORCA velocity computation.
-- Call when you need to assign position.
-- Build a ORCASolver via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newORCASolver(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(1, 0, 0) end)
  print("ORCASolver:setPosition ->", ok, result)
end

--@api-stub: ORCASolver:compute
-- Computes and returns the result.
-- Call when you need to invoke compute.
-- Build a ORCASolver via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newORCASolver(...)
if instance then
  local ok, result = pcall(function() return instance:compute(1.0) end)
  print("ORCASolver:compute ->", ok, result)
end

--@api-stub: ORCASolver:getSafeVelocity
-- Returns the safe velocity.
-- Call when you need to read safe velocity.
-- Build a ORCASolver via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newORCASolver(...)
if instance then
  local ok, result = pcall(function() return instance:getSafeVelocity(1) end)
  print("ORCASolver:getSafeVelocity ->", ok, result)
end

--@api-stub: ORCASolver:agentCount
-- Returns or performs agent count.
-- Call when you need to invoke agent count.
-- Build a ORCASolver via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newORCASolver(...)
if instance then
  local ok, result = pcall(function() return instance:agentCount() end)
  print("ORCASolver:agentCount ->", ok, result)
end

-- ── NeuralNet methods ──

--@api-stub: NeuralNet:forward
-- Returns or performs forward.
-- Call when you need to invoke forward.
-- Build a NeuralNet via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuralNet(...)
if instance then
  local ok, result = pcall(function() return instance:forward(nil) end)
  print("NeuralNet:forward ->", ok, result)
end

--@api-stub: NeuralNet:setWeights
-- Overwrites all connection weights with values from a flat table.
-- Call when you need to assign weights.
-- Build a NeuralNet via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuralNet(...)
if instance then
  local ok, result = pcall(function() return instance:setWeights(nil) end)
  print("NeuralNet:setWeights ->", ok, result)
end

--@api-stub: NeuralNet:getWeights
-- Returns a flat table of all connection weight values in the network.
-- Call when you need to read weights.
-- Build a NeuralNet via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuralNet(...)
if instance then
  local ok, result = pcall(function() return instance:getWeights() end)
  print("NeuralNet:getWeights ->", ok, result)
end

--@api-stub: NeuralNet:paramCount
-- Returns or performs param count.
-- Call when you need to invoke param count.
-- Build a NeuralNet via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuralNet(...)
if instance then
  local ok, result = pcall(function() return instance:paramCount() end)
  print("NeuralNet:paramCount ->", ok, result)
end

--@api-stub: NeuralNet:layerCount
-- Returns or performs layer count.
-- Call when you need to invoke layer count.
-- Build a NeuralNet via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuralNet(...)
if instance then
  local ok, result = pcall(function() return instance:layerCount() end)
  print("NeuralNet:layerCount ->", ok, result)
end

-- ── GeneticAlgorithm methods ──

--@api-stub: GeneticAlgorithm:evolve
-- Runs one generation of the evolutionary algorithm.
-- Call when you need to invoke evolve.
-- Build a GeneticAlgorithm via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGeneticAlgorithm(...)
if instance then
  local ok, result = pcall(function() return instance:evolve() end)
  print("GeneticAlgorithm:evolve ->", ok, result)
end

--@api-stub: GeneticAlgorithm:generation
-- Returns or performs generation.
-- Call when you need to invoke generation.
-- Build a GeneticAlgorithm via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGeneticAlgorithm(...)
if instance then
  local ok, result = pcall(function() return instance:generation() end)
  print("GeneticAlgorithm:generation ->", ok, result)
end

--@api-stub: GeneticAlgorithm:popSize
-- Returns or performs pop size.
-- Call when you need to invoke pop size.
-- Build a GeneticAlgorithm via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGeneticAlgorithm(...)
if instance then
  local ok, result = pcall(function() return instance:popSize() end)
  print("GeneticAlgorithm:popSize ->", ok, result)
end

--@api-stub: GeneticAlgorithm:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- Call when you need to assign fitness.
-- Build a GeneticAlgorithm via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGeneticAlgorithm(...)
if instance then
  local ok, result = pcall(function() return instance:setFitness(1, nil) end)
  print("GeneticAlgorithm:setFitness ->", ok, result)
end

--@api-stub: GeneticAlgorithm:getGenes
-- Returns the chromosome as an ordered table of gene values.
-- Call when you need to read genes.
-- Build a GeneticAlgorithm via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGeneticAlgorithm(...)
if instance then
  local ok, result = pcall(function() return instance:getGenes(1) end)
  print("GeneticAlgorithm:getGenes ->", ok, result)
end

--@api-stub: GeneticAlgorithm:bestGenes
-- Returns or performs best genes.
-- Call when you need to invoke best genes.
-- Build a GeneticAlgorithm via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newGeneticAlgorithm(...)
if instance then
  local ok, result = pcall(function() return instance:bestGenes() end)
  print("GeneticAlgorithm:bestGenes ->", ok, result)
end

-- ── Bandit methods ──

--@api-stub: Bandit:select
-- Returns or performs select.
-- Call when you need to invoke select.
-- Build a Bandit via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBandit(...)
if instance then
  local ok, result = pcall(function() return instance:select() end)
  print("Bandit:select ->", ok, result)
end

--@api-stub: Bandit:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a Bandit via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBandit(...)
if instance then
  local ok, result = pcall(function() return instance:update(1, nil) end)
  print("Bandit:update ->", ok, result)
end

--@api-stub: Bandit:bestArm
-- Returns or performs best arm.
-- Call when you need to invoke best arm.
-- Build a Bandit via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBandit(...)
if instance then
  local ok, result = pcall(function() return instance:bestArm() end)
  print("Bandit:bestArm ->", ok, result)
end

--@api-stub: Bandit:reset
-- Resets or clears the state.
-- Call when you need to invoke reset.
-- Build a Bandit via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBandit(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("Bandit:reset ->", ok, result)
end

--@api-stub: Bandit:armCount
-- Returns or performs arm count.
-- Call when you need to invoke arm count.
-- Build a Bandit via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBandit(...)
if instance then
  local ok, result = pcall(function() return instance:armCount() end)
  print("Bandit:armCount ->", ok, result)
end

--@api-stub: Bandit:totalPulls
-- Returns or performs total pulls.
-- Call when you need to invoke total pulls.
-- Build a Bandit via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newBandit(...)
if instance then
  local ok, result = pcall(function() return instance:totalPulls() end)
  print("Bandit:totalPulls ->", ok, result)
end

-- ── Neuroevolution methods ──

--@api-stub: Neuroevolution:evolve
-- Runs one generation of the evolutionary algorithm.
-- Call when you need to invoke evolve.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:evolve() end)
  print("Neuroevolution:evolve ->", ok, result)
end

--@api-stub: Neuroevolution:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- Call when you need to assign fitness.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:setFitness(1, nil) end)
  print("Neuroevolution:setFitness ->", ok, result)
end

--@api-stub: Neuroevolution:chromosomeToNet
-- Returns or performs chromosome to net.
-- Call when you need to invoke chromosome to net.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:chromosomeToNet(1) end)
  print("Neuroevolution:chromosomeToNet ->", ok, result)
end

--@api-stub: Neuroevolution:bestNetwork
-- Returns or performs best network.
-- Call when you need to invoke best network.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:bestNetwork() end)
  print("Neuroevolution:bestNetwork ->", ok, result)
end

--@api-stub: Neuroevolution:bestFitness
-- Returns or performs best fitness.
-- Call when you need to invoke best fitness.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:bestFitness() end)
  print("Neuroevolution:bestFitness ->", ok, result)
end

--@api-stub: Neuroevolution:popSize
-- Returns or performs pop size.
-- Call when you need to invoke pop size.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:popSize() end)
  print("Neuroevolution:popSize ->", ok, result)
end

--@api-stub: Neuroevolution:generation
-- Returns or performs generation.
-- Call when you need to invoke generation.
-- Build a Neuroevolution via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newNeuroevolution(...)
if instance then
  local ok, result = pcall(function() return instance:generation() end)
  print("Neuroevolution:generation ->", ok, result)
end

-- ── StrategyAI methods ──

--@api-stub: StrategyAI:addGoal
-- Adds a strategic goal with priority score to the planner for future evaluation.
-- Call when you need to add goal.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:addGoal("name") end)
  print("StrategyAI:addGoal ->", ok, result)
end

--@api-stub: StrategyAI:addTag
-- Adds a string tag to the strategy AI instance for goal filtering and categorization.
-- Call when you need to add tag.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:addTag("tag") end)
  print("StrategyAI:addTag ->", ok, result)
end

--@api-stub: StrategyAI:removeTag
-- Removes the specified tag.
-- Call when you need to remove tag.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:removeTag("tag") end)
  print("StrategyAI:removeTag ->", ok, result)
end

--@api-stub: StrategyAI:update
-- Advances the simulation by one time step.
-- Call when you need to invoke update.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0, function() end) end)
  print("StrategyAI:update ->", ok, result)
end

--@api-stub: StrategyAI:forceEvaluate
-- Returns or performs force evaluate.
-- Call when you need to invoke force evaluate.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:forceEvaluate(function() end) end)
  print("StrategyAI:forceEvaluate ->", ok, result)
end

--@api-stub: StrategyAI:activeGoal
-- Returns or performs active goal.
-- Call when you need to invoke active goal.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:activeGoal() end)
  print("StrategyAI:activeGoal ->", ok, result)
end

--@api-stub: StrategyAI:timeUntilNext
-- Returns or performs time until next.
-- Call when you need to invoke time until next.
-- Build a StrategyAI via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newStrategyAI(...)
if instance then
  local ok, result = pcall(function() return instance:timeUntilNext() end)
  print("StrategyAI:timeUntilNext ->", ok, result)
end

-- ── AILod methods ──

--@api-stub: AILod:shouldUpdate
-- Returns or performs should update.
-- Call when you need to invoke should update.
-- Build a AILod via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAILod(...)
if instance then
  local ok, result = pcall(function() return instance:shouldUpdate(nil, nil) end)
  print("AILod:shouldUpdate ->", ok, result)
end

--@api-stub: AILod:tierCount
-- Returns or performs tier count.
-- Call when you need to invoke tier count.
-- Build a AILod via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAILod(...)
if instance then
  local ok, result = pcall(function() return instance:tierCount() end)
  print("AILod:tierCount ->", ok, result)
end

--@api-stub: AILod:tierName
-- Returns or performs tier name.
-- Call when you need to invoke tier name.
-- Build a AILod via the appropriate lurek.ai.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ai.newAILod(...)
if instance then
  local ok, result = pcall(function() return instance:tierName(nil) end)
  print("AILod:tierName ->", ok, result)
end

